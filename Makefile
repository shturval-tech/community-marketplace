SHELL := /usr/bin/env bash
CHARTS_DIR := charts
DIST_DIR := dist
PACKAGES_DIR := $(DIST_DIR)/packages
HELM_REPO_URL ?= https://shturval-tech.github.io/community-marketplace
REGISTRY ?= ghcr.io/shturval-tech/community-marketplace
TRIVY_DB_REPOSITORY ?= public.shturval.tech/trivy-db:2
TRIVY_JAVA_DB_REPOSITORY ?= public.shturval.tech/trivy-java-db:1
BDU_SOURCE_URL ?= https://github.com/velvetway/bdu-fstec-mirror/raw/main/data/vulxml.xml.gz
SCAN_FAIL_SEVERITY ?= CRITICAL
IMAGE ?=
CHART ?=

.PHONY: lint lint-chart package index vendor-deps sync-values test bundle push push-offline images-list verify-images bdu-fetch scan scan-all scan-test help

help:
	@echo "Targets: lint, lint-chart CHART=x, package, index, vendor-deps, sync-values, test, bundle, push, push-offline"
	@echo "         verify-images, bdu-fetch, scan IMAGE=ref, scan-all, scan-test"

vendor-deps:
	@./scripts/vendor-chart-deps.sh

sync-values:
	@python3 ./scripts/sync-chart-values.py

lint:
	@command -v ct >/dev/null || { echo "install chart-testing (ct)"; exit 1; }
	ct lint --config ct.yaml

lint-chart:
	@test -n "$(CHART)" || { echo "usage: make lint-chart CHART=name"; exit 1; }
	helm lint "$(CHARTS_DIR)/$(CHART)"
	helm template test "$(CHARTS_DIR)/$(CHART)" -f "$(CHARTS_DIR)/$(CHART)/ci/test-values.yaml" >/dev/null

package:
	@mkdir -p "$(PACKAGES_DIR)"
	@for d in $(CHARTS_DIR)/*/; do \
		name=$$(basename "$$d"); \
		helm package "$$d" -d "$(PACKAGES_DIR)" --dependency-update=false; \
	done

verify-images:
	@chmod +x scripts/verify-images.sh
	@./scripts/verify-images.sh

index: package
	@helm repo index "$(PACKAGES_DIR)"

test: lint
	@command -v kind >/dev/null || { echo "skip ct install: kind not found"; exit 0; }
	ct install --config ct.yaml --target-branch main

bundle: package index
	@./scripts/airgap-bundle.sh

push:
	@HELM_REPO_URL="$(HELM_REPO_URL)" REGISTRY="$(REGISTRY)" ./scripts/airgap-push.sh

push-offline:
	@test -d "$(DIST_DIR)" || { echo "run make bundle first or set BUNDLE_ROOT to unpacked archive"; exit 1; }
	@chmod +x scripts/airgap-push-offline.sh
	@BUNDLE_ROOT="$(DIST_DIR)" REGISTRY="$(REGISTRY)" HELM_REPO_URL="$(HELM_REPO_URL)" ./scripts/airgap-push-offline.sh

images-list:
	@./scripts/list-images.sh

bdu-fetch:
	@chmod +x scripts/scan/*.sh
	@./scripts/scan/bdu-fetch.sh

scan-test:
	@python3 -m pytest tests/scan/ -q

scan:
	@test -n "$(IMAGE)" || { echo "usage: make scan IMAGE=ghcr.io/.../name:tag"; exit 1; }
	@chmod +x scripts/scan/*.sh
	@TRIVY_DB_REPOSITORY="$(TRIVY_DB_REPOSITORY)" \
	 TRIVY_JAVA_DB_REPOSITORY="$(TRIVY_JAVA_DB_REPOSITORY)" \
	 SCAN_FAIL_SEVERITY="$(SCAN_FAIL_SEVERITY)" \
	 BDU_SOURCE_URL="$(BDU_SOURCE_URL)" \
	 ./scripts/scan/trivy-scan.sh "$(IMAGE)"

scan-all:
	@chmod +x scripts/scan/*.sh
	@TRIVY_DB_REPOSITORY="$(TRIVY_DB_REPOSITORY)" \
	 TRIVY_JAVA_DB_REPOSITORY="$(TRIVY_JAVA_DB_REPOSITORY)" \
	 SCAN_FAIL_SEVERITY="$(SCAN_FAIL_SEVERITY)" \
	 BDU_SOURCE_URL="$(BDU_SOURCE_URL)" \
	 ./scripts/scan/trivy-scan.sh all
