# AGENTS — community-marketplace

Инструкции для AI-агентов и automation в репозитории **shturval-tech/community-marketplace**.

## Контекст платформы

- **ShturvalRepoConfig** (`ops.shturval.tech/v1beta2`, cluster-scoped): `spec.url` — http/https/oci; для OCI список чартов в UI не подгружается → приоритет **HTTPS index.yaml** (GitHub Pages). Harbor без ChartMuseum — OCI ([docs/airgap.md](docs/airgap.md#если-у-вас-harbor)).
- **ShturvalServiceConfig (SSC)**: `spec.chart`, `spec.version`, `spec.namespace`, `spec.reponame`, `spec.dependency[]`, `spec.customvalues`.
- Имена чартов: `^[a-z0-9]([-a-z0-9]*[a-z0-9])?$`.

## Структура репозитория

| Путь | Назначение |
|------|------------|
| `charts/` | Helm-чарты (wrapper / custom / vendored) |
| `images/` | Dockerfile-зеркала upstream → ghcr.io |
| `deploy/repoconfig/` | Kustomize: ShturvalRepoConfig |
| `deploy/argocd/` | Argo CD Application |
| `deploy/examples/ssc/` | Примеры SSC |
| `scripts/` | airgap, list-images, sync-upstream, vendor deps |
| `scripts/scan/` | Trivy + обогащение БДУ ФСТЭК |
| `security/` | `.trivyignore` для CI |
| `docs/chart-conventions.md` | Обязательные соглашения |

## Команды

```bash
make lint              # ct lint всех чартов
make lint-chart CHART=x
make package           # helm package → dist/packages/
make index             # helm repo index → dist/index.yaml
make bundle            # charts + images/*.tar + push-offline.sh + airgap-bundle.tar.gz
make push-offline      # из dist/ без интернета (после распаковки бандла)
make push HELM_REPO_URL=... REGISTRY=...  # legacy: crane copy с ghcr.io
make verify-images     # все образы в render -> ghcr.io/.../community-marketplace
make test              # ct lint + ct install (kind)
make vendor-deps       # helm dependency update во всех charts/
make sync-values       # merge subchart values.yaml → wrapper (для UI Штурвала)
make bdu-fetch         # выгрузка БДУ vulxml для локального scan
make scan IMAGE=...    # Trivy + BDU для одного образа
make scan-all          # все образы из images/images.yaml
make scan-test         # pytest tests/scan/
```

Перед PR: `make lint` и bump `Chart.yaml` version.

## Правила изменений

- DRY/KISS: минимальный diff, не тянуть Bitnami-чарты для новых сервисов.
- Wrapper: vendored `charts/*.tgz` + `Chart.lock` в git (офлайн/ air-gap).
- Values: `global.imageRegistry`, `global.storageClass`, `global.ingress.className`.
- Каждый новый чарт → `ci/test-values.yaml` + `deploy/examples/ssc/<name>.yaml`.
- Секреты только через placeholders / external secrets, не в git.

## CI

Полное описание workflow, nightly, бандлы: **[docs/ci.md](docs/ci.md)**.

Кратко:

- scan не блокирует push образов; `scan-gate` — отдельный job; Nightly Rebuild пропускает gate.
- **Publish Security Pages** — только ручной перезапуск отчёта.
- Отпечаток исходников (`build-fingerprint.sh`) — не включает CVE.

## Ссылки

- [README.md](README.md) — обзор и каталог
- [docs/glossary.md](docs/glossary.md) — термины
- [docs/ci.md](docs/ci.md) — GitHub Actions
- [docs/manual-setup.md](docs/manual-setup.md) — public repo, Pages, packages
- [docs/airgap.md](docs/airgap.md) — закрытый контур
- [docs/security-scanning.md](docs/security-scanning.md) — Trivy и БДУ в CI
- Навык Shturval API (монорепо Projects): `.cursor/skills/shturval-api/SKILL.md`

## Безопасность

- Не коммитить токены, kubeconfig, реальные пароли в values.
- DELETE ресурсов в production-кластерах — только с подтверждением пользователя.
