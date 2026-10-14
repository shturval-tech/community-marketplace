#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT}"

PAGES_URL="${PAGES_URL:-https://shturval-tech.github.io/community-marketplace/security/}"
WORKFLOW_URL="${WORKFLOW_URL:-}"
SOURCE="${SCAN_SOURCE:-ci}"
FAIL_ON="${SCAN_FAIL_SEVERITY:-CRITICAL}"

chmod +x scripts/scan/*.sh

if [[ ! -f dist/scan/REPORT.md ]]; then
  ./scripts/scan/aggregate-report.sh
fi

python3 scripts/scan/write-pages.py \
  --scan-dir dist/scan \
  --out-dir dist/scan/pages \
  --report-md dist/scan/REPORT.md \
  --trivyignore security/.trivyignore \
  --fail-on "${FAIL_ON}" \
  --pages-url "${PAGES_URL}" \
  --workflow-url "${WORKFLOW_URL}" \
  --source "${SOURCE}"

echo "Ready to deploy dist/scan/pages -> gh-pages/security/"
