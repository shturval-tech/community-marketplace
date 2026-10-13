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

echo "Bundle ready under ${DIST}/"
