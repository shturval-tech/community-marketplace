#!/usr/bin/env bash
# Sync vendored Nextcloud AIO kompose chart from upstream (run on networked host).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="${UPSTREAM:-https://github.com/nextcloud/all-in-one.git}"
REF="${REF:-main}"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

git clone --depth 1 --branch "$REF" "$UPSTREAM" "$WORKDIR/aio"
CHART_SRC="$WORKDIR/aio/helm-chart"
DEST="${ROOT}/charts/nextcloud-aio"

if [[ ! -d "$CHART_SRC" ]]; then
  echo "helm-chart not found in $UPSTREAM at $REF" >&2
  exit 1
fi

rsync -a --delete \
  --exclude charts \
  "$CHART_SRC/" "$DEST/upstream/"
echo "Synced upstream into charts/nextcloud-aio/upstream — merge templates/values manually if needed."
