#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STRIMZI_VERSION="${STRIMZI_VERSION:-1.3.0}"
MINIO_OPERATOR_VERSION="${MINIO_OPERATOR_VERSION:-v7.1.1}"

vendor_strimzi() {
  local chart="${ROOT}/charts/strimzi-operator"
  echo "==> vendoring strimzi ${STRIMZI_VERSION} from GitHub"
  rm -rf "${chart}/charts/strimzi-kafka-operator" "${chart}/charts"/strimzi-kafka-operator-*.tgz
  local tmp pkg
  tmp=$(mktemp -d)
  git clone --depth 1 --branch "${STRIMZI_VERSION}" https://github.com/strimzi/strimzi-kafka-operator.git "$tmp/s"
  mkdir -p "${chart}/charts"
  pkg=$(helm package "$tmp/s/helm-charts/helm3/strimzi-kafka-operator" -d "$tmp" | awk '{print $NF}')
  tar -xzf "$pkg" -C "${chart}/charts"
  rm -rf "$tmp"
}

vendor_minio_operator() {
  local chart="${ROOT}/charts/minio-operator"
  echo "==> vendoring minio operator ${MINIO_OPERATOR_VERSION} from GitHub"
  rm -f "${chart}/charts"/minio-operator-*.tgz "${chart}/charts"/operator-*.tgz
  local tmp
  tmp=$(mktemp -d)
  git clone --depth 1 --branch "${MINIO_OPERATOR_VERSION}" https://github.com/minio/operator.git "$tmp/o"
  helm package "$tmp/o/helm/operator" -d "${chart}/charts"
  rm -rf "${chart}/charts/operator"
  tar -xzf "${chart}/charts/operator-${MINIO_OPERATOR_VERSION#v}.tgz" -C "${chart}/charts" 2>/dev/null || \
    tar -xzf "${chart}/charts/operator-7.1.1.tgz" -C "${chart}/charts"
  rm -rf "$tmp"
  (cd "$chart" && helm dependency update)
}

for chart in charts/*/; do
  name=$(basename "$chart")
  if [[ "$name" == "strimzi-operator" ]]; then
    vendor_strimzi
    continue
  fi
  if [[ "$name" == "minio-operator" ]]; then
    vendor_minio_operator
    continue
  fi
  if grep -q '^dependencies:' "${chart}Chart.yaml" 2>/dev/null; then
    echo "==> vendoring $name"
    (cd "$chart" && helm dependency update) || echo "warn: $name dependency update failed"
  fi
done
