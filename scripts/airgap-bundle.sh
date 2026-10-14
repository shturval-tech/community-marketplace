#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
PACKAGES="${DIST}/packages"

"${ROOT}/scripts/list-images.sh"

mkdir -p "${DIST}/images"
cp -f "${ROOT}/images/images.yaml" "${DIST}/images/images.yaml"

registry=$(grep '^registry:' "${DIST}/images/images.yaml" | awk '{print $2}')

if command -v crane >/dev/null 2>&1; then
  while IFS= read -r line; do
    [[ "$line" =~ name:\ (.+) ]] || continue
    name="${BASH_REMATCH[1]}"
    tag="latest"
    # read next lines for tag - simplified: parse with awk
    tag=$(awk -v n="$name" '
      $1=="-" && $2=="name:" && $3==n {found=1; next}
      found && $1=="tag:" {gsub(/"/,"",$2); print $2; exit}
    ' "${DIST}/images/images.yaml")
    ref="${registry}/${name}:${tag}"
    echo "pull ${ref} -> ${DIST}/images/${name}.tar"
    if crane pull "${ref}" "${DIST}/images/${name}.tar"; then
      echo "tag: \"${tag}\"" > "${DIST}/images/${name}.meta.yaml"
    else
      echo "warn: failed to pull ${ref} (offline host: copy tars manually)"
    fi
  done < "${DIST}/images/images.yaml"
else
  echo "crane not found; skipping image pull (place *.tar under dist/images/ manually)"
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

mkdir -p "${DIST}/packages"
if [[ -d "${PACKAGES}" ]] && ls "${PACKAGES}"/*.tgz >/dev/null 2>&1; then
  cp -a "${PACKAGES}/." "${DIST}/packages/"
fi
if [[ -f "${DIST}/index.yaml" ]]; then
  cp -f "${DIST}/index.yaml" "${DIST}/packages/index.yaml" 2>/dev/null || cp -f "${DIST}/index.yaml" "${DIST}/"
fi

cp -f "${ROOT}/scripts/airgap-push-offline.sh" "${DIST}/push-offline.sh"
chmod +x "${DIST}/push-offline.sh"

ARCHIVE="${DIST}/airgap-bundle.tar.gz"
tar -czf "${ARCHIVE}" -C "${DIST}" \
  packages \
  images \
  push-offline.sh \
  $([[ -d "${DIST}/scan-db" ]] && echo scan-db) \
  $([[ -f "${DIST}/index.yaml" ]] && echo index.yaml) \
  2>/dev/null || tar -czf "${ARCHIVE}" -C "${DIST}" packages images push-offline.sh

if command -v sha256sum >/dev/null 2>&1; then
  (cd "${DIST}" && sha256sum "$(basename "${ARCHIVE}")" > airgap-bundle.sha256)
fi

echo "Bundle ready: ${ARCHIVE}"
