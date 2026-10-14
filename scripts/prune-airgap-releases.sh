#!/usr/bin/env bash
# Keep the N most recent versioned air-gap releases (airgap-* except airgap-latest).
set -euo pipefail

KEEP="${1:-3}"
REPO="${GITHUB_REPOSITORY:-}"

if [[ -z "${REPO}" ]]; then
  echo "prune-airgap-releases: GITHUB_REPOSITORY not set" >&2
  exit 1
fi
command -v gh >/dev/null || { echo "prune-airgap-releases: gh not found" >&2; exit 1; }

mapfile -t tags < <(
  gh release list -R "${REPO}" --limit 200 --json tagName,createdAt \
    --jq '.[] | select(.tagName | test("^airgap-")) | select(.tagName != "airgap-latest") | [.createdAt, .tagName] | @tsv' \
    | sort -r \
    | cut -f2
)

if ((${#tags[@]} <= KEEP)); then
  echo "prune-airgap-releases: ${#tags[@]} versioned release(s), nothing to prune (keep ${KEEP})"
  exit 0
fi

to_delete=("${tags[@]:KEEP}")
for tag in "${to_delete[@]}"; do
  echo "prune-airgap-releases: deleting ${tag}"
  gh release delete "${tag}" -R "${REPO}" --yes --cleanup-tag 2>/dev/null || \
    gh release delete "${tag}" -R "${REPO}" --yes
done

echo "prune-airgap-releases: kept ${KEEP}, removed ${#to_delete[@]}"
