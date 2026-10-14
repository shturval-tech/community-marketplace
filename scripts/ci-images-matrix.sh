#!/usr/bin/env bash
# Outputs GitHub Actions matrix JSON: {"include":[{"name":"...","context":"images/..."}, ...]}
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
first=1
printf '{"include":['
while IFS= read -r line; do
  [[ "$line" =~ name:\ (.+) ]] || continue
  name="${BASH_REMATCH[1]}"
  if [[ "$first" -eq 0 ]]; then printf ','; fi
  first=0
  printf '{"name":"%s","context":"images/%s"}' "$name" "$name"
done < "${ROOT}/images/images.yaml"
printf ']}'
