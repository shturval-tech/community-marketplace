#!/usr/bin/env bash
# Set visibility=public on all org container packages for mirrored images.
# Requires GH_TOKEN (or gh auth) with write:packages and org admin on packages.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YAML="${ROOT}/images/images.yaml"
ORG="${GHCR_ORG:-shturval-tech}"
PREFIX="${GHCR_IMAGE_PREFIX:-community-marketplace}"

if [[ ! -f "$YAML" ]]; then
  echo "missing ${YAML}" >&2
  exit 1
fi

if ! command -v gh >/dev/null; then
  echo "install GitHub CLI (gh)" >&2
  exit 1
fi

if [[ -z "${GH_TOKEN:-}" ]] && ! gh auth status >/dev/null 2>&1; then
  echo "authenticate: export GH_TOKEN=<PAT with write:packages> or gh auth login" >&2
  exit 1
fi

fail=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  pkg="${PREFIX}%2F${name}"
  echo "Setting public: ${ORG}/${PREFIX}/${name}"
  if gh api --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/orgs/${ORG}/packages/container/${pkg}/visibility" \
    -f visibility=public; then
    :
  else
    echo "FAIL: ${PREFIX}/${name}" >&2
    fail=1
  fi
done < <(grep -E '^\s+- name:' "$YAML" | sed -E 's/^\s+- name:\s*//')

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Done. Verify: make verify-ghcr-anonymous"
