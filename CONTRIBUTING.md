# Как участвовать

Спасибо за интерес к community marketplace для Штурвала. Перед PR — [Code of Conduct](CODE_OF_CONDUCT.md).

## Новый чарт

1. Issue по шаблону **New chart** или согласование в существующем issue.
2. Каталог `charts/<name>/` по [docs/chart-conventions.md](docs/chart-conventions.md).
3. `ci/test-values.yaml` для `chart-testing install` в kind.
4. Пример SSC в `deploy/examples/ssc/<name>.yaml`.
5. README чарта по [шаблону](docs/chart-conventions.md#readme-чарта) (вручную, на русском).
6. Таблица каталога в [README.md](README.md) при новой категории/чарте.
7. Bump `version` в `Chart.yaml` (semver).

## Чарт-обёртка над upstream

```bash
cd charts/my-chart
helm dependency update   # закоммитьте charts/*.tgz и Chart.lock
make lint-chart CHART=my-chart
```

## Pull request

Чеклист — в [шаблоне PR](.github/pull_request_template.md). Кратко:

- `make lint` / зелёный CI
- версия в `Chart.yaml` увеличена
- README чарта и SSC-пример актуальны
- нет секретов в values

## Commits

Понятные сообщения на английском или русском.

## Для мейнтейнеров

Релизы, nightly, бандлы и workflow — [docs/ci.md](docs/ci.md).
