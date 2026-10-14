# Contributing

Спасибо за интерес к community marketplace для Штурвала. Перед PR ознакомьтесь с [Code of Conduct](CODE_OF_CONDUCT.md).

## Новый чарт

1. Откройте issue по шаблону **New chart** или согласуйте в существующем issue.
2. Создайте каталог `charts/<name>/` по [docs/chart-conventions.md](docs/chart-conventions.md).
3. Добавьте `ci/test-values.yaml` для `chart-testing install` в kind.
4. Добавьте пример SSC в `deploy/examples/ssc/<name>.yaml`.
5. Обновите таблицу каталога в [README.md](README.md).
6. Bump `version` в `Chart.yaml` (semver).

## Wrapper с upstream dependency

```bash
cd charts/my-chart
helm dependency update   # затем закоммитьте charts/*.tgz и Chart.lock
make lint-chart CHART=my-chart
```

## Pull request checklist

- [ ] `make lint` проходит для изменённых чартов
- [ ] `version` в `Chart.yaml` увеличена
- [ ] README чарта (helm-docs) актуален
- [ ] Нет секретов в values / примерах
- [ ] SSC-пример добавлен или обновлён

## Commits

Используйте понятные сообщения коммитов на английском или русском. DCO не требуется, если иное не попросит maintainers.

## Maintainer notes

Релиз чартов на `main` при изменении `charts/**`: [chart-releaser](https://github.com/helm/chart-releaser) обновляет **gh-pages** (`index.yaml`), без отдельного GitHub Release на каждый чарт. Образы — **Mirror Images**. Offline-архив — **`airgap-latest`** + версионные **`airgap-<ver>-<date>`** (ретеншн 3), workflow **Air-gap Bundle Release**; ночная пересборка — **Nightly Rebuild** после scheduled **Security Scan** (только при изменении fingerprint, не CVE).
