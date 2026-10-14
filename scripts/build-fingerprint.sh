#!/usr/bin/env bash
# Fingerprint build inputs: git trees (charts/, images/) + upstream image digests (not CVE/scan).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/dist/build-fingerprint.txt}"

mkdir -p "$(dirname "${OUT}")"
tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

{
  echo "tree.charts=$(git -C "${ROOT}" rev-parse HEAD:charts)"
  echo "tree.images=$(git -C "${ROOT}" rev-parse HEAD:images)"
} >> "${tmp}"

for dockerfile in "${ROOT}"/images/*/Dockerfile; do
  [[ -f "${dockerfile}" ]] || continue
  name="$(basename "$(dirname "${dockerfile}")")"
  version=""
  if grep -qE '^ARG VERSION=' "${dockerfile}" 2>/dev/null; then
    version=$(grep -E '^ARG VERSION=' "${dockerfile}" | head -1 | sed 's/^ARG VERSION=//')
  fi
  from_line=$(grep -E '^FROM ' "${dockerfile}" | head -1 | sed 's/^FROM //')
  ref="${from_line}"
  ref="${ref//\$\{VERSION\}/${version}}"
  ref="${ref//\$VERSION/${version}}"
  digest="unknown"
  if command -v crane >/dev/null 2>&1; then
    if d="$(crane digest "${ref}" 2>/dev/null)"; then
      digest="${d}"
    else
      echo "build-fingerprint: warn: cannot digest ${ref} (${name})" >&2
    fi
  else
    echo "build-fingerprint: warn: crane not found, upstream.${name}=unknown" >&2
  fi
  echo "upstream.${name}=${digest}"
done >> "${tmp}"

sort "${tmp}" > "${OUT}"
sha256sum "${OUT}" | awk '{print $1}'
