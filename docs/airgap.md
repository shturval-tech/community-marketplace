# Закрытый контур (air-gap)

Сценарий: сборка артефактов на машине с доступом в интернет, перенос в изолированную сеть, публикация во внутренний Nexus/Harbor и подключение к кластеру Штурвала.

## 1. Сборка бандла

На build-хосте с `helm`, `docker`/`crane`/`skopeo`:

```bash
git clone https://github.com/shturval-tech/community-marketplace.git
cd community-marketplace
make vendor-deps    # если .tgz ещё не в git
make bundle
```

Результат в `dist/`:

- `packages/*.tgz` — упакованные чарты
- `index.yaml` — Helm index
- `images/images.yaml` — список образов для зеркалирования
- `images/oci-layout/` — при наличии crane/skopeo (образы)
- `scan-db/` — при `WITH_SCAN_DB=1`: OCI-базы Trivy (`trivy-db:2`, `trivy-java-db:1`) и `vulxml.xml.gz` (БДУ ФСТЭК)

```bash
make bundle WITH_SCAN_DB=1
```

Архивируйте `dist/` и перенесите в контур.

## 2. Загрузка во внутренние реестры

```bash
export HELM_REPO_URL=https://nexus.internal/repository/helm-community
export REGISTRY=registry.internal/community-marketplace
make push
```

`scripts/airgap-push.sh` использует `helm push` / `helm cm-push` (если установлен plugin) и `crane copy` для образов.

## 3. ShturvalRepoConfig в контуре

```bash
kubectl apply -k deploy/repoconfig/overlays/airgap
```

Патч overlay задаёт `spec.url` через kustomize (`COMMUNITY_HELM_REPO_URL` в `configMapGenerator` или patch — см. `deploy/repoconfig/overlays/airgap/kustomization.yaml`).

## 4. Образы в чартах

При установке SSC переопределите registry в `customvalues`:

```yaml
spec:
  customvalues:
    global:
      imageRegistry: registry.internal/community-marketplace
```

Или используйте **ShturvalServicePatch** на уровне платформы (если принят в вашей инсталляции).

## 5. Argo CD

Application указывает на git mirror внутри контура; path `deploy/repoconfig/overlays/airgap`.

## 6. Сканирование уязвимостей в контуре

На build-хосте с Trivy и доступом к зеркалам образов:

```bash
export TRIVY_DB_REPOSITORY=registry.internal/trivy-db:2
export TRIVY_JAVA_DB_REPOSITORY=registry.internal/trivy-java-db:1
export BDU_LOCAL_FILE=/path/from/dist/scan-db/vulxml.xml
make scan-all
```

См. [security-scanning.md](security-scanning.md).
