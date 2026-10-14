#!/usr/bin/env bash
# Normalize downloaded GitHub Actions artifacts into dist/scan/ for publish-pages.sh
set -euo pipefail

ARTIFACT_DIR="${1:?artifact directory}"
OUT="${2:-dist/scan}"

mkdir -p "${OUT}"

if [[ -d "${ARTIFACT_DIR}/dist/scan" ]]; then
  cp -a "${ARTIFACT_DIR}/dist/scan/." "${OUT}/"
fi

while IFS= read -r -d '' f; do
  name=$(basename "$(dirname "$f")")
  mkdir -p "${OUT}/${name}"
  cp -f "$f" "${OUT}/${name}/"
  base=$(dirname "$f")
  for extra in report.bdu.md report.json; do
    [[ -f "${base}/${extra}" ]] && cp -f "${base}/${extra}" "${OUT}/${name}/"
  done
done < <(find "${ARTIFACT_DIR}" -name 'report.bdu.json' -print0)

find "${ARTIFACT_DIR}" -name 'REPORT.md' -exec cp -f {} "${OUT}/REPORT.md" \; 2>/dev/null || true

if find "${OUT}" -name 'report.bdu.json' | grep -q .; then
  echo "prepare-dist-scan: OK ($(find "${OUT}" -name 'report.bdu.json' | wc -l) reports)"
else
  echo "prepare-dist-scan: no report.bdu.json found under ${ARTIFACT_DIR}" >&2
  exit 1
fi
