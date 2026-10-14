#!/usr/bin/env bash
# Подставляет html_url упавших matrix jobs в scan-meta/*.json (нужен gh + actions:read).
set -euo pipefail

REPO="${1:?owner/repo}"
RUN_ID="${2:?run id}"
SCAN_DIR="${3:-dist/scan}"
META_DIR="${SCAN_DIR}/scan-meta"

[[ -d "${META_DIR}" ]] || exit 0
command -v gh >/dev/null || { echo "resolve-job-links: gh not found, skip"; exit 0; }
command -v jq >/dev/null || exit 0

jobs_json="$(gh api "/repos/${REPO}/actions/runs/${RUN_ID}/jobs" --paginate 2>/dev/null)" || {
  echo "resolve-job-links: cannot list jobs for run ${RUN_ID}" >&2
  exit 0
}

shopt -s nullglob
for meta in "${META_DIR}"/*.json; do
  outcome="$(jq -r '.scan_outcome // "unknown"' "${meta}")"
  [[ "${outcome}" == "success" ]] && continue
  image="$(jq -r '.image' "${meta}")"
  job_url="$(jq -r --arg img "${image}" '
    .jobs[]
    | select(.name | test("scan \\(" + $img + ","))
    | .html_url
  ' <<< "${jobs_json}" | head -1)"
  if [[ -z "${job_url}" ]]; then
    job_url="$(jq -r --arg img "${image}" '
      .jobs[]
      | select(.name | contains($img))
      | .html_url
    ' <<< "${jobs_json}" | head -1)"
  fi
  if [[ -n "${job_url}" ]]; then
    tmp="$(mktemp)"
    jq --arg url "${job_url}" '.job_url = $url' "${meta}" > "${tmp}"
    mv "${tmp}" "${meta}"
    echo "resolve-job-links: ${image} -> ${job_url}"
  fi
done
