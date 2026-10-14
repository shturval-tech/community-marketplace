#!/usr/bin/env python3
"""Обогащает JSON-отчёт Trivy данными БДУ ФСТЭК (CVE → BDU)."""
from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Any

SEVERITY_ORDER = {"UNKNOWN": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}


@dataclass
class BduRecord:
    bdu_id: str
    severity_text: str
    cvss_score: str | None
    level: str


def fstec_level(severity_text: str) -> str:
    t = severity_text.lower()
    if "критическ" in t:
        return "CRITICAL"
    if "высок" in t:
        return "HIGH"
    if "средн" in t:
        return "MEDIUM"
    if "низк" in t:
        return "LOW"
    return "UNKNOWN"


def parse_vulxml(path: Path) -> dict[str, list[BduRecord]]:
    cve_map: dict[str, list[BduRecord]] = {}
    for _event, elem in ET.iterparse(path, events=("end",)):
        if elem.tag != "vul":
            continue
        bdu_id = (elem.findtext("identifier") or "").strip()
        severity_text = (elem.findtext("severity") or "").strip()
        cvss_score = None
        cvss3 = elem.find("cvss3/vector")
        cvss2 = elem.find("cvss/vector")
        if cvss3 is not None and cvss3.get("score"):
            cvss_score = cvss3.get("score")
        elif cvss2 is not None and cvss2.get("score"):
            cvss_score = cvss2.get("score")
        level = fstec_level(severity_text)
        rec = BduRecord(bdu_id=bdu_id, severity_text=severity_text, cvss_score=cvss_score, level=level)
        for ident in elem.findall("./identifiers/identifier"):
            if ident.get("type") != "CVE":
                continue
            cve = (ident.text or "").strip().upper()
            if not cve.startswith("CVE-"):
                continue
            cve_map.setdefault(cve, []).append(rec)
        elem.clear()
    return cve_map


def load_ignore(path: Path | None) -> set[str]:
    ignored: set[str] = set()
    if path is None or not path.is_file():
        return ignored
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        ignored.add(line.upper())
        ignored.add(line)
    return ignored


def effective_severity(trivy_sev: str, bdu_level: str) -> str:
    t = (trivy_sev or "UNKNOWN").upper()
    b = (bdu_level or "UNKNOWN").upper()
    if SEVERITY_ORDER.get(b, 0) > SEVERITY_ORDER.get(t, 0):
        return b
    return t


def enrich_report(
    report: dict[str, Any],
    cve_map: dict[str, list[BduRecord]],
    image_label: str,
    bdu_snapshot: str,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    rows: list[dict[str, Any]] = []
    for result in report.get("Results") or []:
        target = result.get("Target") or ""
        for vuln in result.get("Vulnerabilities") or []:
            cve = (vuln.get("VulnerabilityID") or "").upper()
            bdu_list = cve_map.get(cve, [])
            bdu_ids = [r.bdu_id for r in bdu_list if r.bdu_id]
            bdu_level = "UNKNOWN"
            bdu_severity_text = ""
            bdu_cvss = None
            if bdu_list:
                bdu_level = max((r.level for r in bdu_list), key=lambda x: SEVERITY_ORDER.get(x, 0))
                primary = bdu_list[0]
                bdu_severity_text = primary.severity_text
                bdu_cvss = primary.cvss_score
            vuln["BDU"] = {
                "ids": bdu_ids,
                "severity_text": bdu_severity_text,
                "cvss": bdu_cvss,
                "level": bdu_level,
            }
            rows.append(
                {
                    "image": image_label,
                    "target": target,
                    "pkg": vuln.get("PkgName") or "",
                    "cve": cve,
                    "bdu": ", ".join(bdu_ids) if bdu_ids else "—",
                    "trivy_severity": vuln.get("Severity") or "",
                    "bdu_level": bdu_level,
                    "effective": effective_severity(vuln.get("Severity") or "", bdu_level),
                    "fixed": vuln.get("FixedVersion") or "",
                }
            )
    report.setdefault("Metadata", {})["BDU"] = {"snapshot": bdu_snapshot}
    return report, rows


def write_markdown(path: Path, rows: list[dict[str, Any]], image_label: str, bdu_snapshot: str) -> None:
    lines = [
        f"## {image_label}",
        "",
        f"Снимок БДУ: **{bdu_snapshot or 'unknown'}**",
        "",
        "| Пакет | CVE | BDU | Trivy | ФСТЭК | Fixed |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for r in sorted(rows, key=lambda x: (-SEVERITY_ORDER.get(x["effective"], 0), x["cve"])):
        lines.append(
            f"| {r['pkg']} | {r['cve']} | {r['bdu']} | {r['trivy_severity']} | {r['bdu_level']} | {r['fixed'] or '—'} |"
        )
    if not rows:
        lines.append("| — | — | — | — | — | — |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def is_ignored(row: dict[str, Any], ignored: set[str]) -> bool:
    cve = row["cve"]
    if cve in ignored or cve.upper() in ignored:
        return True
    if row["bdu"] == "—":
        return False
    for bid in row["bdu"].split(","):
        bid = bid.strip()
        if bid and (bid in ignored or bid.upper() in ignored):
            return True
    return False


def should_fail(
    rows: list[dict[str, Any]],
    ignored: set[str],
    fail_on: str,
    fixed_only: bool,
) -> bool:
    threshold = SEVERITY_ORDER.get(fail_on.upper(), 4)
    for r in rows:
        if is_ignored(r, ignored):
            continue
        if fixed_only and not r["fixed"]:
            continue
        if SEVERITY_ORDER.get(r["effective"], 0) >= threshold:
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Enrich Trivy JSON with BDU FSTEC data")
    parser.add_argument("--trivy-json", type=Path, required=True)
    parser.add_argument("--vulxml", type=Path, required=True)
    parser.add_argument("--out-json", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    parser.add_argument("--image-label", default="")
    parser.add_argument("--bdu-snapshot", default="")
    parser.add_argument("--trivyignore", type=Path, default=None)
    parser.add_argument("--fail-on", default="CRITICAL")
    parser.add_argument("--fixed-only", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--no-fail", action="store_true", help="Never exit non-zero")
    args = parser.parse_args()

    cve_map = parse_vulxml(args.vulxml)
    report = json.loads(args.trivy_json.read_text(encoding="utf-8"))
    image_label = args.image_label or report.get("ArtifactName") or args.trivy_json.stem
    enriched, rows = enrich_report(report, cve_map, image_label, args.bdu_snapshot)
    args.out_json.write_text(json.dumps(enriched, ensure_ascii=False, indent=2), encoding="utf-8")
    write_markdown(args.out_md, rows, image_label, args.bdu_snapshot)

    ignored = load_ignore(args.trivyignore)
    if args.no_fail:
        return 0
    if should_fail(rows, ignored, args.fail_on, args.fixed_only):
        print(f"Scan gate failed: {args.fail_on}+ with fix (see {args.out_md})", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
