#!/usr/bin/env bash
# Записывает исход scan job для образа (для отчёта на Pages при failure).
set -euo pipefail

IMAGE="${1:?image name}"
OUTCOME="${2:?success|failure|cancelled|skipped}"
WORKFLOW_RUN_URL="${3:-}"
RUN_ID="${4:-}"
JOB_NAME="${5:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
META_DIR="${6:-${ROOT}/dist/scan/scan-meta}"

mkdir -p "${META_DIR}"
jq -n \
  --arg image "${IMAGE}" \
  --arg scan_outcome "${OUTCOME}" \
  --arg workflow_run_url "${WORKFLOW_RUN_URL}" \
  --arg run_id "${RUN_ID}" \
  --arg job_name "${JOB_NAME}" \
  --arg job_url "" \
  '{image: $image, scan_outcome: $scan_outcome, workflow_run_url: $workflow_run_url, run_id: $run_id, job_name: $job_name, job_url: $job_url}' \
  > "${META_DIR}/${IMAGE}.json"
