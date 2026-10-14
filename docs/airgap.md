# Закрытый контур (air-gap)

Сценарий для инженера **без доступа в интернет** с рабочей станции: только внутренние Nexus/Harbor и кластер Штурвала.

## 1. Получить бандл (вне контура или из mirror GitHub)

Скачайте архив из [GitHub Releases](https://github.com/shturval-tech/community-marketplace/releases): **`airgap-latest`** (последняя сборка) или версионный **`airgap-<версия>-<YYYYMMDD>`** (в Releases хранятся **3** последних таких тега). Файлы: `airgap-bundle.tar.gz` + `airgap-bundle.sha256` (+ `build-fingerprint.txt` для CI).

Сборка: после успешных **Release Charts** / **Mirror Images**, после **Nightly Rebuild** (если изменились исходники или upstream-образы), либо вручную (**Air-gap Bundle Release**).

> **Не путать с GHCR Packages:** в реестре `ghcr.io/shturval-tech/community-marketplace` по-прежнему отдельный OCI-package на каждый образ/чарт — это для online pull. Для закрытого контура нужен только **`airgap-bundle.tar.gz`**, не перечисление releases по каждому чарту (per-chart GitHub Releases отключены; index — на gh-pages).

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
# Harbor chartrepo / GitVerse / Nexus hosted — HTTP index (не OCI):
# export HELM_PUSH_MODE=http
# export HELM_USERNAME=... HELM_PASSWORD=...
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

### Harbor и HTTP `index.yaml` (ChartMuseum)

**Образы** после `push-offline.sh` можно пушить в Harbor как обычно (`REGISTRY=registry.example.com/project`).

Для **Штурвала с HTTP** (`spec.url: …/index.yaml`, список чартов в UI) нужен **Helm chart repository с ChartMuseum** (или аналог: Nexus hosted, GitVerse Packages и т.п.), который отдаёт `index.yaml` и `.tgz` по URL из index.

> **Важно:** в Harbor **2.8+** встроенный ChartMuseum **снят**; путь `/chartrepo/<project>/` в типовой установке **не** является рабочим Helm repo (часто отдаётся UI registry). `push-offline.sh` с `HELM_REPO_URL=https://…/chartrepo/…` сработает только если у вас **развёрнут ChartMuseum** (отдельный pod/ingress или legacy full Harbor chart с `chartmuseum.enabled`) и API `POST /api/chartrepo/<project>/charts` доступен.

Без ChartMuseum для Harbor используйте один из вариантов:

| Вариант | `HELM_REPO_URL` / ShturvalRepoConfig |
|---------|----------------------------------------|
| Harbor **OCI** (чарты уже в registry) | `oci://registry.example.com/project/charts` — без `index.yaml` |
| **Nexus** hosted Helm | `https://nexus…/repository/helm-hosted` |
| **GitVerse** и др. HTTP registry | например `https://gitverse.ru/api/packages/<owner>/helm` |
| **Отдельный ChartMuseum** | свой URL с `index.yaml` |

По умолчанию `push-offline.sh` при `HELM_PUSH_MODE=auto` для URL с `chartrepo` пытается **HTTP**-загрузку; иначе чарты уходят в **OCI** (`oci://${REGISTRY}/charts`), а `shturvalrepoconfig.yaml` генерируется под OCI.

## 3. ShturvalRepoConfig

```bash
kubectl apply -f shturvalrepoconfig.yaml
# или overlay:
kubectl apply -k deploy/repoconfig/overlays/airgap
```

**Harbor / private OCI** (после `push-offline` без HTTP chartrepo):

```yaml
apiVersion: ops.shturval.tech/v1beta2
kind: ShturvalRepoConfig
metadata:
  name: community
spec:
  url: oci://registry.example.com/project/charts
  username: robot$project+pull
  password: <secret>
```

В UI список чартов для OCI может не подгружаться — имя чарта задаётся в SSC вручную (`spec.chart`, как в [deploy/examples/ssc/](../deploy/examples/ssc/)). `reponame: community` должен совпадать с `metadata.name` репозитория.

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
