# Закрытый контур (air-gap)

Инструкция для инженера **без интернета** с рабочей станции: внутренние Harbor/Nexus и кластер Штурвала. Термины: [glossary.md](glossary.md). Когда собирается бандл в CI: [ci.md](ci.md).

## Коротко

1. Скачать архив из [GitHub Releases](https://github.com/shturval-tech/community-marketplace/releases) (`airgap-latest` или `airgap-<версия>-<YYYYMMDD>`).
2. Собрать `airgap-bundle.tar.gz` из частей при необходимости, проверить `sha256sum -c airgap-bundle.sha256`.
3. Распаковать, задать `REGISTRY` и `HELM_REPO_URL`, выполнить `./push-offline.sh`.
4. `kubectl apply -f shturvalrepoconfig.yaml` (или overlay).
5. Установить сервисы через SSC — [deploy/examples/ssc/README.md](../deploy/examples/ssc/README.md).

## 1. Получить архив

**Релиз:** `airgap-latest` — последняя сборка; версионные теги `airgap-*` (кроме `-latest`) — фиксированные сборки, в Releases хранятся **3 последних**. Файлы: `airgap-bundle.tar.gz` или `part-*`, `airgap-bundle.sha256`, `build-fingerprint.txt`.

Сборка в CI описана в [ci.md](ci.md). Отдельные packages в GHCR — для online pull; для контура нужен **один бандл**, не per-chart Releases.

**Сборка на машине с интернетом:**

```bash
git clone https://github.com/shturval-tech/community-marketplace.git
cd community-marketplace
make package index
make bundle WITH_SCAN_DB=1
```

Перенесите `dist/airgap-bundle.tar.gz` в контур.

## 2. Загрузить в реестры

На станции **внутри контура** (`crane`, `skopeo` или `docker` + `helm`):

### Переменные `push-offline.sh`

| Переменная | Обязательно | По умолчанию | Назначение |
|------------|-------------|--------------|------------|
| `REGISTRY` | да | — | Префикс container registry (`registry.internal/project`) |
| `HELM_REPO_URL` | да | — | Базовый URL Helm-репозитория (HTTP index или OCI) |
| `HELM_PUSH_MODE` | нет | `auto` | `auto` / `http` / `oci` — как загружать чарты |
| `HELM_USERNAME` | нет | — | Basic auth для HTTP chart repo |
| `HELM_PASSWORD` | нет | — | Пароль / token |
| `REPO_NAME` | нет | `community` | `metadata.name` в `shturvalrepoconfig.yaml` |
| `SKIP_IMAGES` | нет | `0` | `1` — не загружать образы |
| `BUNDLE_ROOT` | нет | каталог распаковки | Корень с `images/`, `packages/` |
| `SOURCE_REGISTRY` | нет | `ghcr.io/shturval-tech/community-marketplace` | Откуда переписываются пути в values |

```bash
tar -xzf airgap-bundle.tar.gz
cd community-marketplace   # или каталог после распаковки
export BUNDLE_ROOT="$(pwd)"
export REGISTRY=registry.internal/community-marketplace
export HELM_REPO_URL=https://nexus.internal/repository/helm-community
./push-offline.sh
```

**Скрипт:** загружает образы из `images/*.tar`; переписывает `ghcr.io/shturval-tech/community-marketplace` → `REGISTRY` в values чартов; публикует `.tgz` и `index.yaml`; создаёт `shturvalrepoconfig.yaml`.

**Проверка:** образы видны в project registry; `curl …/index.yaml` (HTTP) или `helm pull oci://…` (OCI); файл `shturvalrepoconfig.yaml` создан.

Эквивалент из git-клона: `make push-offline REGISTRY=… HELM_REPO_URL=…`.

## Если у вас Harbor

| Ситуация | Что использовать |
|----------|------------------|
| Есть **ChartMuseum** (или legacy Harbor с chartmuseum) | HTTP: `HELM_REPO_URL=https://registry…/chartrepo/<project>` |
| Harbor **2.8+** без ChartMuseum | **OCI:** чарты в `oci://registry…/project/charts`, без HTTP index |
| Nexus hosted Helm | `https://nexus…/repository/helm-hosted` |
| GitVerse Packages | например `https://gitverse.ru/api/packages/<owner>/helm` |

Путь `/chartrepo/` в типовой установ Harbor **2.8+** часто отдаёт UI, а не Helm API — см. [Частые проблемы](#частые-проблемы).

**ShturvalRepoConfig для OCI** (после `push-offline` без HTTP chartrepo):

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

В UI Штурвала список чартов для OCI может не подгружаться — укажите `spec.chart` в SSC вручную ([примеры](../deploy/examples/ssc/)). `reponame` = `metadata.name` репозитория.

При `HELM_PUSH_MODE=auto` URL с `chartrepo` пробует HTTP; иначе чарты уходят в OCI.

## 3. ShturvalRepoConfig

```bash
kubectl apply -f shturvalrepoconfig.yaml
# или:
kubectl apply -k deploy/repoconfig/overlays/airgap
```

## 4. Установка SSC

Примеры: [deploy/examples/ssc/](../deploy/examples/ssc/). После `push-offline.sh` образы в values уже указывают на внутренний registry.

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| В Release несколько `airgap-bundle.tar.gz.part-*` | `cat airgap-bundle.tar.gz.part-* > airgap-bundle.tar.gz` |
| `push-offline.sh` не находит `images/` или `packages/` | Запускать из каталога распаковки: `export BUNDLE_ROOT=$(pwd)` |
| Нет Docker socket | Использовать **crane** / **skopeo** (скрипт поддерживает crane) |
| Robot Harbor `robot$project+name` не логинится | Не экранировать `$` в YAML/`kubectl`; в shell — одинарные кавычки для пароля |
| `/chartrepo/…` возвращает HTML | Нет ChartMuseum — перейти на OCI или Nexus/GitVerse HTTP ([раздел Harbor](#если-у-вас-harbor)) |

## Что не требует интернета

| Действие | Интернет |
|----------|----------|
| `make package` / vendored deps | нет |
| `./push-offline.sh` из бандла | нет |
| Установка SSC из внутреннего index | нет |
| Pull образов в кластере после push-offline | нет |
| `make vendor-deps` | **да** |
| `make push` (legacy, копирование с ghcr.io) | **да** — не использовать в контуре |

## Сканирование в контуре

Если в бандле есть `scan-db/`:

```bash
export TRIVY_DB_REPOSITORY=registry.internal/trivy-db:2
export TRIVY_JAVA_DB_REPOSITORY=registry.internal/trivy-java-db:1
export BDU_LOCAL_FILE=./scan-db/vulxml.xml
make scan-all
```

[security-scanning.md](security-scanning.md).

## Argo CD

Application на git-mirror внутри контура; path `deploy/repoconfig/overlays/airgap`.
