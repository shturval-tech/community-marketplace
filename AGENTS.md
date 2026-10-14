# AGENTS — community-marketplace

Инструкции для AI-агентов и автomation в репозитории **shturval-tech/community-marketplace**.

## Контекст платформы

- **ShturvalRepoConfig** (`ops.shturval.tech/v1beta2`, cluster-scoped): `spec.url` — http/https/oci; для OCI список чартов в UI Штурвала не подгружается → приоритет **HTTPS index.yaml** (GitHub Pages).
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
make bundle            # charts + images manifest для air-gap
make push HELM_REPO_URL=... REGISTRY=...
make test              # ct lint + ct install (kind)
make vendor-deps       # helm dependency update во всех charts/
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

- PR: `.github/workflows/lint-test.yaml` — ct lint, kubeconform, ct install.
- main + `charts/**`: `release-charts.yaml` — chart-releaser → gh-pages, OCI push.
- main + `images/**`: `images.yaml` — buildx push, job `scan` (Trivy + БДУ, SARIF).
- schedule / manual: `security-scan.yaml` — полный scan `:latest`.
- after scan workflows: `publish-security-pages.yaml` — отчёт и `badge.json` на gh-pages (`/security/`).
- PR/main: `lint-test.yaml` — trivy config (информационно), pytest `tests/scan/`.

## Ссылки

- [README.md](README.md) — обзор и каталог
- [docs/manual-setup.md](docs/manual-setup.md) — public repo, Pages, packages
- [docs/airgap.md](docs/airgap.md) — закрытый контур
- [docs/security-scanning.md](docs/security-scanning.md) — Trivy и БДУ в CI
- Навык Shturval API (в монорепо Projects): `.cursor/skills/shturval-api/SKILL.md`

## Безопасность

- Не коммитить токены, kubeconfig, реальные пароли в values.
- DELETE ресурсов в production-кластерах — только с подтверждением пользователя.
