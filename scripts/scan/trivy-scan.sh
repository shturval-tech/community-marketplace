#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCAN_DIR="${ROOT}/dist/scan"
FAIL_ON="${SCAN_FAIL_SEVERITY:-CRITICAL}"
TRIVY_JAVA_DB_REPOSITORY="${TRIVY_JAVA_DB_REPOSITORY:-public.shturval.tech/trivy-java-db:1}"
IGNORE_FILE="${ROOT}/security/.trivyignore"

source_db() {
  while IFS= read -r line; do
    case "${line}" in
      TRIVY_DB_REPOSITORY=*) export TRIVY_DB_REPOSITORY="${line#TRIVY_DB_REPOSITORY=}" ;;
    esac
  done < <("${ROOT}/scripts/scan/verify-trivy-db.sh")
}

fetch_bdu() {
  while IFS= read -r line; do
    case "${line}" in
      BDU_VULXML=*) export BDU_VULXML="${line#BDU_VULXML=}" ;;
      BDU_SNAPSHOT=*) export BDU_SNAPSHOT="${line#BDU_SNAPSHOT=}" ;;
    esac
  done < <("${ROOT}/scripts/scan/bdu-fetch.sh")
}

scan_one() {
  local ref="$1"
  local name="${2:-}"
  if [[ -z "${name}" ]]; then
    name="$(basename "${ref%%:*}")"
  fi
  local out="${SCAN_DIR}/${name}"
  mkdir -p "${out}"

  echo "Scanning ${ref} -> ${out}"
  trivy image "${ref}" \
    --db-repository "${TRIVY_DB_REPOSITORY}" \
    --java-db-repository "${TRIVY_JAVA_DB_REPOSITORY}" \
    --scanners vuln \
    --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL \
    --format json \
    --output "${out}/report.json"

  trivy image "${ref}" \
    --db-repository "${TRIVY_DB_REPOSITORY}" \
    --java-db-repository "${TRIVY_JAVA_DB_REPOSITORY}" \
    --scanners vuln \
    --skip-db-update \
    --skip-java-db-update \
    --format sarif \
    --output "${out}/report.sarif"

  trivy image "${ref}" \
    --db-repository "${TRIVY_DB_REPOSITORY}" \
    --java-db-repository "${TRIVY_JAVA_DB_REPOSITORY}" \
    --scanners vuln \
    --skip-db-update \
    --skip-java-db-update \
    --format cyclonedx \
    --output "${out}/report.cyclonedx.json"

  local enrich_args=(
    --trivy-json "${out}/report.json"
    --vulxml "${BDU_VULXML}"
    --out-json "${out}/report.bdu.json"
    --out-md "${out}/report.bdu.md"
    --image-label "${name} (${ref})"
    --bdu-snapshot "${BDU_SNAPSHOT:-unknown}"
    --trivyignore "${IGNORE_FILE}"
    --fail-on "${FAIL_ON}"
    --fixed-only
  )
  if [[ "${SCAN_ENFORCE_GATE:-1}" == "0" ]]; then
    enrich_args+=(--no-fail)
  fi
  python3 "${ROOT}/scripts/scan/bdu-enrich.py" "${enrich_args[@]}"
}

scan_all() {
  local registry
  registry="$(grep '^registry:' "${ROOT}/images/images.yaml" | awk '{print $2}')"
  local failed=0
  while IFS= read -r line; do
    [[ "${line}" =~ name:\ (.+) ]] || continue
    local img="${BASH_REMATCH[1]}"
    if ! scan_one "${registry}/${img}:latest" "${img}"; then
      failed=1
    fi
  done < "${ROOT}/images/images.yaml"

  {
    echo "# Сводный отчёт сканирования"
    echo ""
    echo "БД Trivy: \`${TRIVY_DB_REPOSITORY}\`"
    echo "Снимок БДУ: **${BDU_SNAPSHOT:-unknown}**"
    echo ""
    for md in "${SCAN_DIR}"/*/report.bdu.md; do
      [[ -f "${md}" ]] || continue
      cat "${md}"
      echo ""
    done
  } > "${SCAN_DIR}/REPORT.md"

  return "${failed}"
}

usage() {
  echo "Usage: $0 <image-ref>|all"
  exit 1
}

[[ $# -ge 1 ]] || usage
source_db
fetch_bdu

if [[ "$1" == "all" ]]; then
  scan_all
else
  scan_one "$1" "${2:-}"
fi
