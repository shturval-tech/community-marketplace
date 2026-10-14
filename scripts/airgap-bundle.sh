#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
PACKAGES="${DIST}/packages"

"${ROOT}/scripts/list-images.sh"

mkdir -p "${DIST}/images"
cp -f "${ROOT}/images/images.yaml" "${DIST}/images/images.yaml"

if command -v crane >/dev/null 2>&1; then
  mkdir -p "${DIST}/images/oci-layout"
  while IFS= read -r line; do
    [[ "$line" =~ name:\ (.+) ]] || continue
    img="ghcr.io/shturval-tech/community-marketplace/${BASH_REMATCH[1]}:latest"
    echo "pull $img (optional, may fail offline-build host without prior push)"
    crane pull "$img" "${DIST}/images/oci-layout/${BASH_REMATCH[1]}.tar" 2>/dev/null || true
  done < "${DIST}/images/images.yaml"
else
  echo "crane not found; skipping image pull (charts only in dist/)"
fi

if [[ "${WITH_SCAN_DB:-0}" == "1" ]]; then
  SCAN_DB="${DIST}/scan-db"
  mkdir -p "${SCAN_DB}"
  if command -v oras >/dev/null 2>&1; then
    oras pull public.shturval.tech/trivy-db:2 -o "${SCAN_DB}/trivy-db" || echo "skip trivy-db pull"
    oras pull public.shturval.tech/trivy-java-db:1 -o "${SCAN_DB}/trivy-java-db" || echo "skip trivy-java-db pull"
  else
    echo "oras not found; skip OCI trivy-db (install oras for WITH_SCAN_DB=1)"
  fi
  BDU_CACHE_DIR="${SCAN_DB}" BDU_FORCE_FETCH=1 "${ROOT}/scripts/scan/bdu-fetch.sh" 2>/dev/null || \
    curl -fsSL "${BDU_SOURCE_URL:-https://github.com/velvetway/bdu-fstec-mirror/raw/main/data/vulxml.xml.gz}" \
      -o "${SCAN_DB}/vulxml.xml.gz" || echo "skip BDU vulxml"
  chmod +x "${ROOT}/scripts/scan/"*.sh 2>/dev/null || true
fi

echo "Bundle ready under ${DIST}/"
