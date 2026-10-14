#!/usr/bin/env bash
# Push air-gap bundle to internal registries (no internet required).
# Harbor: container images via REGISTRY; HTTP Helm index.yaml needs ChartMuseum (see docs/airgap.md).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "${SCRIPT_DIR}/packages" && -d "${SCRIPT_DIR}/images" ]]; then
  BUNDLE_ROOT="${BUNDLE_ROOT:-${SCRIPT_DIR}}"
elif [[ -d "${SCRIPT_DIR}/../dist/packages" ]]; then
  BUNDLE_ROOT="${BUNDLE_ROOT:-${SCRIPT_DIR}/../dist}"
else
  BUNDLE_ROOT="${BUNDLE_ROOT:-${SCRIPT_DIR}/..}"
fi

REGISTRY="${REGISTRY:?set REGISTRY (e.g. registry.internal/community-marketplace)}"
HELM_REPO_URL="${HELM_REPO_URL:?set HELM_REPO_URL (base URL for index.yaml)}"
SOURCE_REGISTRY="${SOURCE_REGISTRY:-ghcr.io/shturval-tech/community-marketplace}"
REPO_NAME="${REPO_NAME:-community}"
HELM_PUSH_MODE="${HELM_PUSH_MODE:-auto}"
SKIP_IMAGES="${SKIP_IMAGES:-0}"
HELM_USERNAME="${HELM_USERNAME:-}"
HELM_PASSWORD="${HELM_PASSWORD:-}"

PACKAGES="${BUNDLE_ROOT}/packages"
IMAGES="${BUNDLE_ROOT}/images"
SCAN_DB="${BUNDLE_ROOT}/scan-db"
STAGING="${BUNDLE_ROOT}/.push-staging"

rm -rf "${STAGING}"
mkdir -p "${STAGING}/packages"

helm_http_upload_chart() {
  local pkg="$1"
  local base url host project api auth=()
  base="${HELM_REPO_URL%/}"
  if [[ -n "${HELM_USERNAME}" && -n "${HELM_PASSWORD}" ]]; then
    auth=(-u "${HELM_USERNAME}:${HELM_PASSWORD}")
  fi
  if [[ "${base}" == *gitverse.ru* ]]; then
    url="${base}/api/charts"
    curl -sfS "${auth[@]}" -X POST --upload-file "${pkg}" "${url}"
    return
  fi
  if [[ "${base}" == *"/chartrepo/"* ]]; then
    host="${base#*://}"
    host="${host%%/*}"
    project="${base#*/chartrepo/}"
    project="${project%%/*}"
    api="https://${host}/api/chartrepo/${project}/charts"
    curl -sfS "${auth[@]}" -X POST --form "chart=@${pkg}" "${api}"
    return
  fi
  if [[ "${base}" == *"/repository/"* ]]; then
    curl -sfS "${auth[@]}" --upload-file "${pkg}" "${base}/$(basename "${pkg}")"
    return
  fi
  echo "unsupported HELM_REPO_URL for HTTP push: ${HELM_REPO_URL}" >&2
  return 1
}

verify_helm_http_index() {
  local base auth=()
  base="${HELM_REPO_URL%/}/index.yaml"
  if [[ -n "${HELM_USERNAME}" && -n "${HELM_PASSWORD}" ]]; then
    auth=(-u "${HELM_USERNAME}:${HELM_PASSWORD}")
  fi
  if ! curl -sfS "${auth[@]}" "${base}" | head -1 | grep -q '^apiVersion:'; then
    echo "error: ${base} is not a Helm index (enable ChartMuseum/Nexus hosted repo or use GitVerse HTTP helm)" >&2
    return 1
  fi
  echo "Helm HTTP index OK: ${base}"
}

use_helm_http=0
case "${HELM_PUSH_MODE}" in
  http) use_helm_http=1 ;;
  oci) use_helm_http=0 ;;
  auto)
    if [[ "${HELM_REPO_URL}" == *chartrepo* || "${HELM_REPO_URL}" == *gitverse.ru* || "${HELM_REPO_URL}" == */repository/* ]]; then
      use_helm_http=1
    fi
    ;;
esac

if [[ "${SKIP_IMAGES}" != "1" ]]; then
echo "==> Push container images from ${IMAGES}/*.tar to ${REGISTRY}"
shopt -s nullglob
for tarfile in "${IMAGES}"/*.tar; do
  name=$(basename "${tarfile}" .tar)
  meta="${IMAGES}/${name}.meta.yaml"
  tag="latest"
  if [[ -f "${meta}" ]]; then
    tag=$(grep '^tag:' "${meta}" | awk '{print $2}' | tr -d '"')
  elif [[ -f "${BUNDLE_ROOT}/images/images.yaml" ]]; then
    tag=$(awk -v n="$name" '$1=="-" && $2=="name:" && $3==n {getline; if ($1=="tag:") print $2}' "${BUNDLE_ROOT}/images/images.yaml" | tr -d '"')
  fi
  dst="${REGISTRY}/${name}:${tag}"
  echo "  ${name} -> ${dst}"
  if command -v crane >/dev/null 2>&1; then
    crane push "${tarfile}" "${dst}"
    if [[ "${tag}" != "latest" ]]; then
      crane copy "${dst}" "${REGISTRY}/${name}:latest" 2>/dev/null || crane tag "${dst}" latest || true
    fi
  elif command -v skopeo >/dev/null 2>&1; then
    skopeo copy "docker-archive:${tarfile}" "docker://${dst}"
  elif command -v docker >/dev/null 2>&1; then
    loaded=$(docker load -i "${tarfile}" | awk '/Loaded image:/ {print $3; exit}')
    docker tag "${loaded}" "${dst}"
    docker push "${dst}"
  else
    echo "install crane, skopeo, or docker to push images"
    exit 1
  fi
done
fi

echo "==> Rewrite chart default registry ${SOURCE_REGISTRY} -> ${REGISTRY}"
for pkg in "${PACKAGES}"/*.tgz; do
  base=$(basename "${pkg}" .tgz)
  work="${STAGING}/work-${base}"
  rm -rf "${work}"
  mkdir -p "${work}"
  tar -xzf "${pkg}" -C "${work}"
  chartdir=$(find "${work}" -mindepth 1 -maxdepth 1 -type d | head -1)
  while IFS= read -r vf; do
    sed -i "s|${SOURCE_REGISTRY}|${REGISTRY}|g" "${vf}"
  done < <(find "${chartdir}" -name 'values.yaml' -print)
  helm package "${chartdir}" -d "${STAGING}/packages" --dependency-update=false
done

echo "==> helm repo index for ${HELM_REPO_URL}"
helm repo index "${STAGING}/packages" --url "${HELM_REPO_URL}"

echo "==> Upload charts (mode=$([[ ${use_helm_http} -eq 1 ]] && echo http || echo oci))"
for pkg in "${STAGING}/packages"/*.tgz; do
  if [[ ${use_helm_http} -eq 1 ]]; then
    echo "  HTTP $(basename "$pkg")"
    helm_http_upload_chart "${pkg}"
  elif helm push "${pkg}" "oci://${REGISTRY}/charts" 2>/dev/null; then
    echo "  OCI pushed $(basename "$pkg")"
  elif command -v helm-cm-push >/dev/null 2>&1; then
    helm cm-push "${pkg}" "${HELM_REPO_URL}"
  else
    echo "  upload manually: ${pkg} -> ${HELM_REPO_URL}"
  fi
done
if [[ ${use_helm_http} -eq 1 ]]; then
  verify_helm_http_index
fi

if [[ -d "${SCAN_DB}" ]] && command -v oras >/dev/null 2>&1; then
  echo "==> Push scan DB artifacts (optional)"
  for artifact in trivy-db trivy-java-db; do
    tag="2"
    [[ "${artifact}" == "trivy-java-db" ]] && tag="1"
    if [[ -d "${SCAN_DB}/${artifact}" ]]; then
      oras push "${REGISTRY}/${artifact}:${tag}" "${SCAN_DB}/${artifact}/:application/vnd.aquasec.trivy.config.v1+json" \
        || echo "  oras push ${artifact} manually"
    fi
  done
fi

repo_url="${HELM_REPO_URL%/}/index.yaml"
if [[ ${use_helm_http} -eq 0 ]]; then
  repo_url="oci://${REGISTRY}/charts"
fi
{
  echo "apiVersion: ops.shturval.tech/v1beta2"
  echo "kind: ShturvalRepoConfig"
  echo "metadata:"
  echo "  name: ${REPO_NAME}"
  echo "spec:"
  echo "  url: ${repo_url}"
  if [[ -n "${HELM_USERNAME}" && -n "${HELM_PASSWORD}" ]]; then
    echo "  username: ${HELM_USERNAME}"
    echo "  password: ${HELM_PASSWORD}"
  fi
} > "${BUNDLE_ROOT}/shturvalrepoconfig.yaml"

echo "Done. Apply: kubectl apply -f ${BUNDLE_ROOT}/shturvalrepoconfig.yaml"
