#!/usr/bin/env bash
# Delete all org container packages for mirrored images (see images/images.yaml).
# Requires GH_TOKEN (or gh auth) with read:packages and delete:packages.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YAML="${ROOT}/images/images.yaml"
ORG="${GHCR_ORG:-shturval-tech}"
PREFIX="${GHCR_IMAGE_PREFIX:-community-marketplace}"

if [[ ! -f "$YAML" ]]; then
  echo "missing ${YAML}" >&2
  exit 1
fi

if [[ "${1:-}" != "--yes" && "${CONFIRM:-}" != "1" ]]; then
  echo "This deletes every GHCR package ${ORG}/${PREFIX}/<image> listed in images/images.yaml." >&2
  echo "Re-run with: CONFIRM=1 $0 --yes" >&2
  exit 1
fi

if ! command -v gh >/dev/null; then
  echo "install GitHub CLI (gh)" >&2
  exit 1
fi

if [[ -z "${GH_TOKEN:-}" ]] && ! gh auth status >/dev/null 2>&1; then
  echo "authenticate: export GH_TOKEN=<PAT with read:packages, delete:packages>" >&2
  exit 1
fi

fail=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  pkg="${PREFIX}%2F${name}"
  echo "Deleting package: ${ORG}/${PREFIX}/${name}"
  set +e
  out="$(gh api --method DELETE \
    -H "Accept: application/vnd.github+json" \
    "/orgs/${ORG}/packages/container/${pkg}" 2>&1)"
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    continue
  fi
  if grep -qE 'HTTP 404|Not Found' <<<"$out"; then
    echo "  (not found, skip)"
  else
    echo "FAIL: ${PREFIX}/${name}: $out" >&2
    fail=1
  fi
done < <(grep -E '^\s+- name:' "$YAML" | sed -E 's/^\s+- name:\s*//')

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Done. Rebuild: gh workflow run \"Mirror Images\" -R shturval-tech/community-marketplace"
echo "Then: make verify-ghcr-anonymous"
