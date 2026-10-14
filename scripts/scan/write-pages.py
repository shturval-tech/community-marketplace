#!/usr/bin/env python3
"""Готовит security/badge.json и index.html для GitHub Pages."""
from __future__ import annotations

import argparse
import html
import importlib.util
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

_bdu_path = Path(__file__).resolve().parent / "bdu-enrich.py"
_spec = importlib.util.spec_from_file_location("bdu_enrich", _bdu_path)
assert _spec and _spec.loader
_bdu = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = _bdu
_spec.loader.exec_module(_bdu)
SEVERITY_ORDER = _bdu.SEVERITY_ORDER
effective_severity = _bdu.effective_severity
is_ignored = _bdu.is_ignored
load_ignore = _bdu.load_ignore


def collect_rows(scan_dir: Path) -> list[dict]:
    rows: list[dict] = []
    for report_path in sorted(scan_dir.glob("*/report.bdu.json")):
        image = report_path.parent.name
        data = json.loads(report_path.read_text(encoding="utf-8"))
        for result in data.get("Results") or []:
            for vuln in result.get("Vulnerabilities") or []:
                bdu = vuln.get("BDU") or {}
                bdu_ids = bdu.get("ids") or []
                rows.append(
                    {
                        "image": image,
                        "cve": (vuln.get("VulnerabilityID") or "").upper(),
                        "bdu": ", ".join(bdu_ids) if bdu_ids else "—",
                        "trivy_severity": vuln.get("Severity") or "",
                        "bdu_level": bdu.get("level") or "UNKNOWN",
                        "effective": effective_severity(
                            vuln.get("Severity") or "", bdu.get("level") or "UNKNOWN"
                        ),
                        "fixed": vuln.get("FixedVersion") or "",
                    }
                )
    return rows


def gate_failures(
    rows: list[dict], ignored: set[str], fail_on: str, fixed_only: bool
) -> int:
    threshold = SEVERITY_ORDER.get(fail_on.upper(), 4)
    count = 0
    for r in rows:
        if is_ignored(r, ignored):
            continue
        if fixed_only and not r["fixed"]:
            continue
        if SEVERITY_ORDER.get(r["effective"], 0) >= threshold:
            count += 1
    return count


def md_to_simple_html(md: str) -> str:
    out: list[str] = []
    in_table = False
    for line in md.splitlines():
        if line.startswith("# "):
            out.append(f"<h1>{html.escape(line[2:])}</h1>")
        elif line.startswith("## "):
            out.append(f"<h2>{html.escape(line[3:])}</h2>")
        elif line.startswith("|"):
            if not in_table:
                out.append("<table>")
                in_table = True
            cells = [c.strip() for c in line.strip("|").split("|")]
            if all(set(c) <= set("- :") for c in cells):
                continue
            tag = "th" if out[-1] == "<table>" else "td"
            out.append(
                "<tr>"
                + "".join(f"<{tag}>{html.escape(c)}</{tag}>" for c in cells)
                + "</tr>"
            )
        else:
            if in_table:
                out.append("</table>")
                in_table = False
            if line.strip():
                out.append(f"<p>{html.escape(line)}</p>")
            else:
                out.append("<br/>")
    if in_table:
        out.append("</table>")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scan-dir", type=Path, default=Path("dist/scan"))
    parser.add_argument("--out-dir", type=Path, default=Path("dist/scan/pages"))
    parser.add_argument("--report-md", type=Path, default=Path("dist/scan/REPORT.md"))
    parser.add_argument("--trivyignore", type=Path, default=Path("security/.trivyignore"))
    parser.add_argument("--fail-on", default="CRITICAL")
    parser.add_argument("--fixed-only", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--pages-url", required=True)
    parser.add_argument("--workflow-url", default="")
    parser.add_argument("--source", default="ci")
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    rows = collect_rows(args.scan_dir)
    ignored = load_ignore(args.trivyignore if args.trivyignore.is_file() else None)
    failures = gate_failures(rows, ignored, args.fail_on, args.fixed_only)
    total = len(rows)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    has_blocking = failures > 0
    if has_blocking:
        badge = {
            "schemaVersion": 1,
            "label": "сканирование",
            "message": f"есть ({failures} крит.)",
            "color": "red",
        }
    else:
        badge = {
            "schemaVersion": 1,
            "label": "сканирование",
            "message": "нет критич. с fix",
            "color": "brightgreen",
        }

    (args.out_dir / "badge.json").write_text(
        json.dumps(badge, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    status = {
        "updated_at": now,
        "source": args.source,
        "pages_url": args.pages_url,
        "workflow_url": args.workflow_url,
        "total_vulnerabilities": total,
        "gate_failures": failures,
        "fail_on": args.fail_on,
        "fixed_only": args.fixed_only,
        "has_blocking_vulnerabilities": has_blocking,
    }
    (args.out_dir / "status.json").write_text(
        json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    if args.report_md.is_file():
        report_md = args.report_md.read_text(encoding="utf-8")
    else:
        report_md = f"# Отчёт сканирования\n\nЗаписей: {total}\n"

    (args.out_dir / "report.md").write_text(report_md, encoding="utf-8")
    body_html = md_to_simple_html(report_md)

    workflow_link = ""
    if args.workflow_url:
        workflow_link = (
            f'<p><a href="{html.escape(args.workflow_url)}">Запуск workflow в GitHub Actions</a></p>'
        )

    index_html = f"""<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Сканирование — Community Marketplace</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.min.css"/>
  <style>
    body {{ box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 24px; }}
    .header {{ text-align: center; margin-bottom: 24px; }}
    .meta {{ color: #57606a; font-size: 14px; margin-bottom: 16px; }}
    table {{ border-collapse: collapse; width: 100%; font-size: 13px; }}
    th, td {{ border: 1px solid #d0d7de; padding: 6px 8px; text-align: left; }}
    th {{ background: #f6f8fa; }}
  </style>
</head>
<body>
  <div class="header">
    <a href="https://shturval.tech"><img src="https://raw.githubusercontent.com/shturval-tech/community-marketplace/main/docs/assets/shturval-logo.svg" alt="Штурвал" width="200"/></a>
    <h1>Отчёт сканирования образов</h1>
    <p class="meta">Обновлено: {html.escape(now)} · записей: {total} · порог: {html.escape(args.fail_on)} с fix</p>
    {workflow_link}
  </div>
  <article class="markdown-body">
    {body_html}
  </article>
</body>
</html>
"""
    (args.out_dir / "index.html").write_text(index_html, encoding="utf-8")
    print(f"Pages written to {args.out_dir} (gate_failures={failures}, total={total})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
