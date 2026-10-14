#!/usr/bin/env bash
# Push air-gap bundle to internal registries (no internet required).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ROOT="${BUNDLE_ROOT:-${ROOT}}"

REGISTRY="${REGISTRY:?set REGISTRY (e.g. registry.internal/community-marketplace)}"
HELM_REPO_URL="${HELM_REPO_URL:?set HELM_REPO_URL (base URL for index.yaml)}"
SOURCE_REGISTRY="${SOURCE_REGISTRY:-ghcr.io/shturval-tech/community-marketplace}"
REPO_NAME="${REPO_NAME:-community}"

PACKAGES="${BUNDLE_ROOT}/packages"
IMAGES="${BUNDLE_ROOT}/images"
SCAN_DB="${BUNDLE_ROOT}/scan-db"
STAGING="${BUNDLE_ROOT}/.push-staging"

rm -rf "${STAGING}"
mkdir -p "${STAGING}/packages"

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

echo "==> Upload charts"
for pkg in "${STAGING}/packages"/*.tgz; do
  if helm push "${pkg}" "oci://${REGISTRY}/charts" 2>/dev/null; then
    echo "  OCI pushed $(basename "$pkg")"
  elif command -v helm-cm-push >/dev/null 2>&1; then
    helm cm-push "${pkg}" "${HELM_REPO_URL}"
  else
    echo "  upload manually: ${pkg} -> ${HELM_REPO_URL}"
  fi
done
if command -v curl >/dev/null 2>&1; then
  curl -sfT "${STAGING}/packages/index.yaml" "${HELM_REPO_URL%/}/index.yaml" \
    || echo "  upload index.yaml manually to ${HELM_REPO_URL}"
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

cat > "${BUNDLE_ROOT}/shturvalrepoconfig.yaml" <<EOF
apiVersion: ops.shturval.tech/v1beta2
kind: ShturvalRepoConfig
metadata:
  name: ${REPO_NAME}
spec:
  url: ${HELM_REPO_URL%/}/index.yaml
EOF

echo "Done. Apply: kubectl apply -f ${BUNDLE_ROOT}/shturvalrepoconfig.yaml"
