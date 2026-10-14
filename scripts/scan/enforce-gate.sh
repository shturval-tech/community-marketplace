#!/usr/bin/env bash
# Fail CI if scan reports violate SCAN_FAIL_SEVERITY gate (after reports are uploaded).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCAN_DIR="${1:-${ROOT}/dist/scan}"
FAIL_ON="${SCAN_FAIL_SEVERITY:-CRITICAL}"
FIXED_ONLY="${SCAN_GATE_FIXED_ONLY:-1}"

exec python3 "${ROOT}/scripts/scan/write-pages.py" \
  --scan-dir "${SCAN_DIR}" \
  --out-dir "${SCAN_DIR}/.gate-check" \
  --report-md "${SCAN_DIR}/REPORT.md" \
  --trivyignore "${ROOT}/security/.trivyignore" \
  --fail-on "${FAIL_ON}" \
  --pages-url "https://example.invalid/" \
  --enforce-gate-only
