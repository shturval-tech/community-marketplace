#!/usr/bin/env bash
# Fail if any mirrored image cannot obtain an anonymous GHCR pull token.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YAML="${ROOT}/images/images.yaml"
ORG="${GHCR_ORG:-shturval-tech}"
PREFIX="${GHCR_IMAGE_PREFIX:-community-marketplace}"

if [[ ! -f "$YAML" ]]; then
  echo "missing ${YAML}; run scripts/list-images.sh" >&2
  exit 1
fi

fail=0
ok=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  scope="repository:${ORG}/${PREFIX}/${name}:pull"
  encoded_scope="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$scope")"
  code="$(curl -sS -o /dev/null -w "%{http_code}" \
    "https://ghcr.io/token?scope=${encoded_scope}&service=ghcr.io")"
  if [[ "$code" == "200" ]]; then
    echo "OK: ${PREFIX}/${name} (anonymous token)"
    ok=$((ok + 1))
  else
    echo "FAIL: ${PREFIX}/${name} anonymous token HTTP ${code} (package likely private)"
    fail=1
  fi
done < <(grep -E '^\s+- name:' "$YAML" | sed -E 's/^\s+- name:\s*//')

echo "---"
echo "anonymous token OK: ${ok}"
if [[ "$fail" -ne 0 ]]; then
  echo "Run scripts/ghcr-set-public.sh with GH_TOKEN (write:packages) or set visibility in GitHub UI." >&2
  exit 1
fi
