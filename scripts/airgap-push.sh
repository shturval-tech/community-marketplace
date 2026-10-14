#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist/packages"
HELM_REPO_URL="${HELM_REPO_URL:?set HELM_REPO_URL}"
REGISTRY="${REGISTRY:?set REGISTRY}"

shopt -s nullglob
for pkg in "${DIST}"/*.tgz; do
  if helm push "$pkg" "oci://${REGISTRY}/charts" 2>/dev/null; then
    echo "pushed $pkg to OCI"
  elif command -v helm-cm-push >/dev/null 2>&1; then
    helm cm-push "$pkg" "$HELM_REPO_URL"
  else
    echo "install helm-push or chartmuseum plugin; copying metadata only"
    curl -sfT "$pkg" "${HELM_REPO_URL}/" || echo "upload $pkg manually to ${HELM_REPO_URL}"
  fi
done

if command -v crane >/dev/null 2>&1; then
  while IFS= read -r line; do
    [[ "$line" =~ name:\ (.+) ]] || continue
    src="ghcr.io/shturval-tech/community-marketplace/${BASH_REMATCH[1]}:latest"
    dst="${REGISTRY}/${BASH_REMATCH[1]}:latest"
    crane copy "$src" "$dst" || echo "skip $dst"
  done < "${ROOT}/images/images.yaml"
fi

SCAN_DB="${ROOT}/dist/scan-db"
if [[ -d "${SCAN_DB}" ]] && command -v oras >/dev/null 2>&1; then
  for artifact in trivy-db trivy-java-db; do
    if [[ -d "${SCAN_DB}/${artifact}" ]]; then
      tag="2"
      [[ "${artifact}" == "trivy-java-db" ]] && tag="1"
      oras push "${REGISTRY}/${artifact}:${tag}" "${SCAN_DB}/${artifact}/:application/vnd.aquasec.trivy.config.v1+json" 2>/dev/null || \
        echo "oras push ${artifact} manually to ${REGISTRY}/${artifact}:${tag}"
    fi
  done
  if [[ -f "${SCAN_DB}/vulxml.xml.gz" ]]; then
    echo "BDU vulxml at ${SCAN_DB}/vulxml.xml.gz — copy to build host for BDU_LOCAL_FILE"
  fi
fi

echo "Done. Apply ShturvalRepoConfig with url=${HELM_REPO_URL}"
