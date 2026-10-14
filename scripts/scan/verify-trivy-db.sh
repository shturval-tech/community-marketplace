#!/usr/bin/env bash
# Проверяет, что Trivy может скачать базу; при ошибке переключается на upstream ghcr.io.
set -euo pipefail

PRIMARY="${TRIVY_DB_REPOSITORY:-public.shturval.tech/trivy-db:2}"
FALLBACK="${TRIVY_DB_FALLBACK:-ghcr.io/aquasecurity/trivy-db:2}"

try_db() {
  local repo="$1"
  if trivy image --download-db-only --db-repository "${repo}" --quiet 2>/dev/null; then
    echo "${repo}"
    return 0
  fi
  return 1
}

if selected="$(try_db "${PRIMARY}")"; then
  echo "Using Trivy DB: ${selected}"
  echo "TRIVY_DB_REPOSITORY=${selected}"
else
  echo "Primary DB ${PRIMARY} unavailable, falling back to ${FALLBACK}" >&2
  try_db "${FALLBACK}" >/dev/null
  echo "Using Trivy DB: ${FALLBACK}"
  echo "TRIVY_DB_REPOSITORY=${FALLBACK}"
fi
