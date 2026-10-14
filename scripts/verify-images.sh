#!/usr/bin/env bash
# Fail if helm template renders container images outside the community marketplace registry.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REG="${VERIFY_IMAGE_REGISTRY:-ghcr.io/shturval-tech/community-marketplace}"
fail=0

while IFS= read -r img; do
  [[ -z "$img" ]] && continue
  case "$img" in
    "${REG}"/*) ;;
    *)
      echo "FAIL: image not under ${REG}: ${img}"
      fail=1
      ;;
  esac
done < <(
  for chart in "${ROOT}"/charts/*/; do
    [[ -f "${chart}/Chart.yaml" ]] || continue
    name=$(basename "$chart")
    [[ "$name" == "strimzi-kafka-operator" ]] && continue
    vals="${chart}/ci/test-values.yaml"
    extra=()
    [[ -f "$vals" ]] && extra=(-f "$vals")
    helm template "verify-${name}" "$chart" "${extra[@]}" --skip-tests 2>/dev/null \
      | rg -o 'image:\s*["'"'"']?[^"'"'"'\s]+' \
      | sed -E 's/^image:\s*//' \
      | tr -d '"' \
      | sort -u
  done
)

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
echo "OK: all rendered images use prefix ${REG}/"
