#!/usr/bin/env bash
# Собирает dist/scan/REPORT.md из report.bdu.md по каждому образу.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCAN_DIR="${ROOT}/dist/scan"
REPORT="${SCAN_DIR}/REPORT.md"

{
  echo "# Сводный отчёт сканирования"
  echo ""
  echo "Дата сборки отчёта: $(date -u +"%Y-%m-%d %H:%M UTC")"
  echo ""
  shopt -s nullglob
  for md in "${SCAN_DIR}"/*/report.bdu.md; do
    cat "${md}"
    echo ""
  done
} > "${REPORT}"

echo "Wrote ${REPORT}"
