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
    tag="latest"
    if grep -qE '^ARG VERSION=' "${d}Dockerfile" 2>/dev/null; then
      tag=$(grep -E '^ARG VERSION=' "${d}Dockerfile" | head -1 | sed 's/^ARG VERSION=//')
    fi
    echo "  - name: ${name}"
    echo "    tag: \"${tag}\""
  done
} > "$OUT"
cat "$OUT"
