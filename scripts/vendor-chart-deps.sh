#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

vendor_strimzi() {
  local chart="${ROOT}/charts/strimzi-operator"
  local tgz="${chart}/charts/strimzi-kafka-operator-0.1.1.tgz"
  if [[ -f "$tgz" ]]; then
    return 0
  fi
  echo "==> vendoring strimzi from GitHub (strimzi.io unreachable)"
  local tmp
  tmp=$(mktemp -d)
  git clone --depth 1 --branch 0.45.0 https://github.com/strimzi/strimzi-kafka-operator.git "$tmp/s"
  mkdir -p "${chart}/charts"
  helm package "$tmp/s/helm-charts/helm3/strimzi-kafka-operator" -d "${chart}/charts"
  rm -rf "$tmp"
}

for chart in charts/*/; do
  name=$(basename "$chart")
  if [[ "$name" == "strimzi-operator" ]]; then
    vendor_strimzi
    continue
  fi
  if grep -q '^dependencies:' "${chart}Chart.yaml" 2>/dev/null; then
    echo "==> vendoring $name"
    (cd "$chart" && helm dependency update) || echo "warn: $name dependency update failed"
  fi
done
