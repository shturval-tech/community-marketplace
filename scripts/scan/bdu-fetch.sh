#!/usr/bin/env bash
# Скачивает выгрузку БДУ ФСТЭК (vulxml) для обогащения отчётов Trivy.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE_DIR="${BDU_CACHE_DIR:-${ROOT}/.cache/bdu}"
BDU_SOURCE_URL="${BDU_SOURCE_URL:-https://github.com/velvetway/bdu-fstec-mirror/raw/main/data/vulxml.xml.gz}"
STATS_URL="${BDU_STATS_URL:-https://github.com/velvetway/bdu-fstec-mirror/raw/main/data/stats.json}"
VULXML_GZ="${CACHE_DIR}/vulxml.xml.gz"
VULXML="${CACHE_DIR}/vulxml.xml"

mkdir -p "${CACHE_DIR}"

if [[ -n "${BDU_LOCAL_FILE:-}" ]]; then
  if [[ "${BDU_LOCAL_FILE}" == *.gz ]]; then
    cp -f "${BDU_LOCAL_FILE}" "${VULXML_GZ}"
    gunzip -c "${VULXML_GZ}" > "${VULXML}"
  else
    cp -f "${BDU_LOCAL_FILE}" "${VULXML}"
  fi
  echo "BDU source: local file ${BDU_LOCAL_FILE}"
  echo "BDU_VULXML=${VULXML}"
  exit 0
fi

if [[ ! -f "${VULXML_GZ}" ]] || [[ "${BDU_FORCE_FETCH:-0}" == "1" ]]; then
  echo "Fetching BDU vulxml from ${BDU_SOURCE_URL} ..."
  curl -fsSL "${BDU_SOURCE_URL}" -o "${VULXML_GZ}"
fi

gunzip -c "${VULXML_GZ}" > "${VULXML}"

snapshot=""
if stats="$(curl -fsSL "${STATS_URL}" 2>/dev/null)"; then
  snapshot="$(echo "${stats}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('snapshot_date', d.get('updated', '')))" 2>/dev/null || true)"
fi
echo "BDU vulxml: ${VULXML} (snapshot: ${snapshot:-unknown})"
echo "BDU_SNAPSHOT=${snapshot}"
echo "BDU_VULXML=${VULXML}"
