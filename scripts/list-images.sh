#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/images/images.yaml"

mkdir -p "$(dirname "$OUT")"
{
  echo "# Generated list of mirrored images (see images/*/Dockerfile)"
  echo "registry: ghcr.io/shturval-tech/community-marketplace"
  echo "images:"
  for d in "$ROOT"/images/*/; do
    [[ -f "${d}Dockerfile" ]] || continue
    name=$(basename "$d")
    echo "  - name: ${name}"
    echo "    tag: latest"
  done
} > "$OUT"
cat "$OUT"
