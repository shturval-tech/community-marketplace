#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

vendor_strimzi() {
  local chart="${ROOT}/charts/strimzi-operator"
  local sub="${chart}/charts/strimzi-kafka-operator"
  if [[ -d "$sub" ]]; then
    return 0
  fi
  echo "==> vendoring strimzi from GitHub (strimzi.io unreachable)"
  local tmp pkg
  tmp=$(mktemp -d)
  git clone --depth 1 --branch 0.45.0 https://github.com/strimzi/strimzi-kafka-operator.git "$tmp/s"
  mkdir -p "${chart}/charts"
  pkg=$(helm package "$tmp/s/helm-charts/helm3/strimzi-kafka-operator" -d "$tmp" | awk '{print $NF}')
  tar -xzf "$pkg" -C "${chart}/charts"
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
