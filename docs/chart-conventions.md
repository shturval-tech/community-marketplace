# Соглашения по Helm-чартам

Чарты в этом репозитории предназначены для установки через **ShturvalServiceConfig (SSC)** из репозитория, подключённого **ShturvalRepoConfig**.

## Именование

- Имя чарта (`Chart.yaml` → `name`) должно соответствовать правилам SSC: `^[a-z0-9]([-a-z0-9]*[a-z0-9])?$`.
- Версия чарта (`version`) — semver маркетплейса; не обязана совпадать с `appVersion` upstream.
- Оператор и инстанс — отдельные чарты (`cnpg-operator` / `cnpg-cluster`).

## Типы чартов

| Тип | Когда использовать |
|-----|-------------------|
| Wrapper | Есть официальный Helm-чарт upstream → dependency + vendored `.tgz` в `charts/` |
| Custom | CR инстанса (MariaDB, Kafka, RabbitmqCluster) или оператор без Helm |
| Vendored | Нет Helm-репозитория (Nextcloud AIO) → `scripts/sync-upstream.sh` |

Зависимости upstream **коммитятся** в `charts/<chart>/charts/*.tgz` и `Chart.lock`, чтобы `helm package` работал офлайн.

## Описание продукта

- Поле `description` в `Chart.yaml` — **на русском**, одна строка: что это за продукт и зачем он нужен (попадает в Helm index и UI Штурвала).
- `README.md` чарта — по [шаблону](#readme-чарта), на русском; без формулировок «wrapper chart».
- Аннотация `shturval.tech/description` — при необходимости чуть подробнее, чем `description`.

## Annotations (`Chart.yaml`)

```yaml
annotations:
  shturval.tech/category: database          # database | messaging | storage | identity | infra
  shturval.tech/description: Краткое описание продукта на русском
  shturval.tech/serviceclass: postgres      # необязательно; для dependencyclass других SSC
  shturval.tech/dependencyclass: ""         # если чарт реализует класс
  artifacthub.io/license: Apache-2.0
  artifacthub.io/links: |
    - name: Upstream
      url: https://...
```

## Values

Обязательные ключи верхнего уровня (или `global`):

- `global.imageRegistry` — по умолчанию `ghcr.io/shturval-tech/community-marketplace`
- `global.storageClass` — пусто = default StorageClass кластера
- `global.ingress.className` — класс Ingress платформы (например `nginx`, `traefik`)

Образы в values должны учитывать `global.imageRegistry` (через helper или явные поля `image.repository`).

**UI Штурвала (параметры по умолчанию):** backend отдаёт только корневой `values.yaml` из `.tgz` репозитория ([GetChartValues](https://github.com/shturval-tech/community-marketplace)). Для wrapper-чартов полное дерево defaults под ключом dependency (`authentik:`, `cluster:`, …) должно лежать в корневом `values.yaml` — после обновления vendored subchart запускайте `make sync-values`. В `index.yaml` на gh-pages URLs чартов **относительные** (`authentik-0.1.5.tgz`), иначе sh-backend не скачает пакет.

Не используем Bitnami-чарты для новых сервисов (лицензирование образов с 2025).

## Файлы каждого чарта

```
charts/<name>/
  Chart.yaml
  values.yaml
  values.schema.json   # по возможности
  README.md            # вручную, см. шаблон ниже
  ci/test-values.yaml  # для ct install в kind
  templates/           # для custom; для pure wrapper может быть только NOTES.txt
  charts/*.tgz         # vendored dependencies
```

## README чарта

Единый шаблон (см. [charts/redis/README.md](../charts/redis/README.md)):

- кратко — что за продукт;
- **Требует** — SSC оператора или «нет»;
- **Установка** — `kubectl apply -f deploy/examples/ssc/<chart>.yaml`;
- **Основные параметры** — `global.imageRegistry`, `global.storageClass`, ключи чарта;
- **Upstream** — ссылка из `artifacthub.io/links` или документация upstream.

## SSC

Примеры манифестов: [deploy/examples/ssc/](../deploy/examples/ssc/).

- `spec.reponame`: `community` (имя ShturvalRepoConfig)
- `spec.dependency`: имена других SSC (оператор перед инстансом)
- `spec.serviceclass` / `spec.dependencyclass` — согласованы с annotations чарта

## Проверки перед PR

```bash
make lint-chart CHART=cnpg-operator
make test          # ct lint + install (kind)
```

Bump `version` в `Chart.yaml` при любом изменении, попадающем в релиз.
