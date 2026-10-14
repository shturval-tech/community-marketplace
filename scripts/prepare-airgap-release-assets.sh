#!/usr/bin/env bash
# Split airgap-bundle.tar.gz for GitHub Releases (max asset size 2 GiB).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE="${ROOT}/dist/airgap-bundle.tar.gz"
PART_PREFIX="${ROOT}/dist/airgap-bundle.tar.gz.part-"
MAX_BYTES=$((1900 * 1024 * 1024))

if [[ ! -f "${ARCHIVE}" ]]; then
  echo "missing ${ARCHIVE}" >&2
  exit 1
fi

size=$(stat -c%s "${ARCHIVE}")
if (( size <= MAX_BYTES )); then
  echo "release asset OK (${size} bytes, single file)"
  exit 0
fi

echo "splitting ${ARCHIVE} (${size} bytes) into ${MAX_BYTES}-byte parts"
rm -f "${PART_PREFIX}"*
split -b "${MAX_BYTES}" -d -a 2 "${ARCHIVE}" "${PART_PREFIX}"
rm -f "${ARCHIVE}"
ls -la "${ROOT}/dist"/airgap-bundle.tar.gz.part-* > "${ROOT}/dist/airgap-bundle.parts.txt"
echo "parts:"; cat "${ROOT}/dist/airgap-bundle.parts.txt"
