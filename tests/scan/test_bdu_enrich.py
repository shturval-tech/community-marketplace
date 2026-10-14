import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIX = Path(__file__).resolve().parent / "fixtures"
SCRIPT = ROOT / "scripts" / "scan" / "bdu-enrich.py"


def run_enrich(tmp_path: Path, extra: list[str] | None = None) -> subprocess.CompletedProcess:
    out_json = tmp_path / "out.bdu.json"
    out_md = tmp_path / "out.bdu.md"
    cmd = [
        sys.executable,
        str(SCRIPT),
        "--trivy-json",
        str(FIX / "sample-trivy.json"),
        "--vulxml",
        str(FIX / "sample-vul.xml"),
        "--out-json",
        str(out_json),
        "--out-md",
        str(out_md),
        "--image-label",
        "test-image",
        "--bdu-snapshot",
        "2026-04-18",
        "--no-fail",
    ]
    if extra:
        cmd.extend(extra)
    return subprocess.run(cmd, capture_output=True, text=True, check=False)


def test_enrich_adds_bdu_ids(tmp_path: Path) -> None:
    result = run_enrich(tmp_path)
    assert result.returncode == 0, result.stderr
    data = json.loads((tmp_path / "out.bdu.json").read_text(encoding="utf-8"))
    vulns = data["Results"][0]["Vulnerabilities"]
    by_cve = {v["VulnerabilityID"]: v for v in vulns}
    assert by_cve["CVE-2020-TEST01"]["BDU"]["ids"] == ["BDU:2020-00099"]
    assert by_cve["CVE-2020-TEST01"]["BDU"]["level"] == "CRITICAL"
    assert by_cve["CVE-2099-NOBdu"]["BDU"]["ids"] == []


def test_gate_fails_on_critical_with_fix(tmp_path: Path) -> None:
    cmd = [
        sys.executable,
        str(SCRIPT),
        "--trivy-json",
        str(FIX / "sample-trivy.json"),
        "--vulxml",
        str(FIX / "sample-vul.xml"),
        "--out-json",
        str(tmp_path / "out.bdu.json"),
        "--out-md",
        str(tmp_path / "out.bdu.md"),
        "--fail-on",
        "CRITICAL",
        "--fixed-only",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    # CVE-2020-TEST01: effective CRITICAL (BDU) + fix -> fail
    # CVE-2099-NOBdu: CRITICAL + fix but no BDU mapping -> fail
    assert result.returncode == 1


def test_ignore_cve(tmp_path: Path) -> None:
    ignore = tmp_path / "ignore"
    ignore.write_text("CVE-2099-NOBdu\n", encoding="utf-8")
    cmd = [
        sys.executable,
        str(SCRIPT),
        "--trivy-json",
        str(FIX / "sample-trivy.json"),
        "--vulxml",
        str(FIX / "sample-vul.xml"),
        "--out-json",
        str(tmp_path / "out.bdu.json"),
        "--out-md",
        str(tmp_path / "out.bdu.md"),
        "--trivyignore",
        str(ignore),
        "--fail-on",
        "CRITICAL",
        "--fixed-only",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    assert result.returncode == 1  # still CVE-2020-TEST01
