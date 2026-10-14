#!/usr/bin/env bash
# Exit 0 if fingerprints match (ignoring new upstream.*=unknown vs prior digest — registry flakes).
set -euo pipefail

NEW="${1:?new fingerprint file}"
OLD="${2:?old fingerprint file}"

if [[ ! -f "${OLD}" ]]; then
  echo "compare-build-fingerprints: no baseline (missing ${OLD})"
  exit 1
fi

normalize() {
  local src="$1"
  local other="$2"
  local out
  out="$(mktemp)"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    key="${line%%=*}"
    val="${line#*=}"
    if [[ "${key}" == upstream.* && "${val}" == unknown ]]; then
      prev="$(grep -F "${key}=" "${other}" 2>/dev/null | head -1 || true)"
      if [[ -n "${prev}" && "${prev}" != *"=unknown" ]]; then
        echo "${prev}"
        continue
      fi
    fi
    echo "${line}"
  done < "${src}" | sort > "${out}"
  cat "${out}"
  rm -f "${out}"
}

norm_new="$(mktemp)"
norm_old="$(mktemp)"
trap 'rm -f "${norm_new}" "${norm_old}"' EXIT

normalize "${NEW}" "${OLD}" > "${norm_new}"
normalize "${OLD}" "${NEW}" > "${norm_old}"

if diff -q "${norm_new}" "${norm_old}" >/dev/null; then
  echo "compare-build-fingerprints: unchanged"
  exit 0
fi

echo "compare-build-fingerprints: changed"
diff -u "${norm_old}" "${norm_new}" || true
exit 1
