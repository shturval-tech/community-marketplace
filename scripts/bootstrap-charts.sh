#!/usr/bin/env bash
# One-time scaffold helper (charts are committed; re-run only when adding charts).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NOTES='Thank you for installing {{ .Chart.Name }} from the Shturval Community Marketplace.'

mk_wrapper() {
  local name=$1 category=$2 dep_name=$3 dep_ver=$4 dep_repo=$5 serviceclass=${6:-}
  local dir="${ROOT}/charts/${name}"
  mkdir -p "${dir}/ci" "${dir}/templates"
  cat > "${dir}/Chart.yaml" <<EOF
apiVersion: v2
name: ${name}
description: Shturval community marketplace wrapper for ${dep_name}
type: application
version: 0.1.0
appVersion: "${dep_ver}"
annotations:
  shturval.tech/category: ${category}
  artifacthub.io/license: Apache-2.0
dependencies:
  - name: ${dep_name}
    version: ${dep_ver}
    repository: ${dep_repo}
EOF
  if [[ -n "$serviceclass" ]]; then
    echo "  shturval.tech/serviceclass: ${serviceclass}" >> "${dir}/Chart.yaml"
  fi
  cat > "${dir}/values.yaml" <<EOF
global:
  imageRegistry: ghcr.io/shturval-tech/community-marketplace
  storageClass: ""
  ingress:
    className: ""

${dep_name}: {}
EOF
  echo '{}' > "${dir}/ci/test-values.yaml"
  echo "$NOTES" > "${dir}/templates/NOTES.txt"
  cat > "${dir}/README.md" <<EOF
# ${name}

Wrapper chart. Upstream: \`${dep_name}\` ${dep_ver}.

See [chart conventions](../../docs/chart-conventions.md).
EOF
}

mk_wrapper cnpg-operator database cloudnative-pg 0.29.1 https://cloudnative-pg.github.io/charts
mk_wrapper cnpg-cluster database cluster 0.9.0 https://cloudnative-pg.github.io/charts postgres
mk_wrapper mariadb-operator database mariadb-operator 26.10.1 https://helm.mariadb.com/mariadb-operator
mk_wrapper strimzi-operator messaging strimzi-kafka-operator 0.45.0 https://strimzi.io/charts/
mk_wrapper minio-operator storage minio-operator 4.3.7 https://operator.min.io/
mk_wrapper minio-tenant storage tenant 7.1.1 https://operator.min.io/
mk_wrapper keycloak identity keycloakx 7.3.2 https://codecentric.github.io/helm-charts
mk_wrapper authentik identity authentik 2026.8.3 https://charts.goauthentik.io
mk_wrapper proxmox-csi infra proxmox-csi 0.3.0 https://sergelogvinov.github.io/proxmox-csi-plugin/
mk_wrapper redis-operator database redis-operator 0.27.0 https://ot-container-kit.github.io/helm-charts/

echo "bootstrap wrappers done"
