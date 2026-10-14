# Закрытый контур (air-gap)

Сценарий для инженера **без доступа в интернет** с рабочей станции: только внутренние Nexus/Harbor и кластер Штурвала.

## 1. Получить бандл (вне контура или из mirror GitHub)

Скачайте готовый архив из [GitHub Releases](https://github.com/shturval-tech/community-marketplace/releases) (`airgap-latest` → `airgap-bundle.tar.gz` + `airgap-bundle.sha256`).

Либо соберите на машине с интернетом:

```bash
git clone https://github.com/shturval-tech/community-marketplace.git
cd community-marketplace
make package index          # офлайн-упаковка, без helm dependency update
make bundle WITH_SCAN_DB=1  # pull образов в dist/images/*.tar
```

Перенесите `airgap-bundle.tar.gz` в закрытый контур.

## 2. Распаковка и загрузка во внутренние реестры

На рабочей станции **только внутри контура** (нужен `crane`, `skopeo` или `docker` + `helm`):

```bash
tar -xzf airgap-bundle.tar.gz
export REGISTRY=registry.internal/community-marketplace
export HELM_REPO_URL=https://nexus.internal/repository/helm-community
./push-offline.sh
```

Скрипт `push-offline.sh` (копия [scripts/airgap-push-offline.sh](../scripts/airgap-push-offline.sh)):

- пушит образы из `images/*.tar` в `REGISTRY` (без обращений наружу);
- переписывает дефолтный префикс `ghcr.io/shturval-tech/community-marketplace` → `REGISTRY` во всех `values.yaml` чартов;
- генерирует `index.yaml` для `HELM_REPO_URL` и загружает `.tgz` чартов;
- создаёт `shturvalrepoconfig.yaml` с вашим URL.

Эквивалент из git-клона после `make bundle`:

```bash
make push-offline REGISTRY=registry.internal/community-marketplace HELM_REPO_URL=https://nexus.internal/repository/helm-community
```

## 3. ShturvalRepoConfig

```bash
kubectl apply -f shturvalrepoconfig.yaml
# или overlay:
kubectl apply -k deploy/repoconfig/overlays/airgap
```

## 4. Установка SSC

Примеры: [deploy/examples/ssc/](../deploy/examples/ssc/). Версия чартов в примерах — актуальная (`0.1.3+`).

После `push-offline.sh` чарты уже указывают на **внутренний** registry; дополнительный `global.imageRegistry` в `customvalues` не обязателен, но можно использовать для переопределения.

## 5. Что не требует интернета

| Действие | Интернет |
|----------|----------|
| `make package` / `helm package --dependency-update=false` | нет (зависимости vendored в git) |
| `./push-offline.sh` из бандла | нет |
| Установка SSC из внутреннего Helm index | нет |
| Pull образов в кластере после push-offline | нет (только `REGISTRY`) |
| `make vendor-deps` | **да** (обновление upstream .tgz) |
| `make push` (legacy [airgap-push.sh](../scripts/airgap-push.sh)) | **да** (`crane copy` с ghcr.io) |

## 6. Сканирование в контуре

Если в бандле есть `scan-db/`:

```bash
export TRIVY_DB_REPOSITORY=registry.internal/trivy-db:2
export TRIVY_JAVA_DB_REPOSITORY=registry.internal/trivy-java-db:1
export BDU_LOCAL_FILE=./scan-db/vulxml.xml
make scan-all
```

См. [security-scanning.md](security-scanning.md).

## 7. Argo CD

Application на git-mirror внутри контура; path `deploy/repoconfig/overlays/airgap`.
