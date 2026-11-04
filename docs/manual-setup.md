# Ручная настройка GitHub

Выполняет владелец организации **shturval-tech** один раз (или при смене политики).

## 1. Public repository

Репозиторий должен быть **public**, чтобы GitHub Pages отдавал Helm index без аутентификации (SSC/UI Штурвала).

Settings → General → Danger Zone → Change visibility → Public.

## 2. GitHub Pages

Settings → Pages:

- **Source**: Deploy from a branch (не «GitHub Actions» — index публикует chart-releaser в ветку `gh-pages`)
- **Branch**: `gh-pages` / `/ (root)`

Ветка `gh-pages` создаётся workflow **Release Charts** при первом успешном релизе (шаг *Bootstrap gh-pages branch*).

Проверка после первого релиза:

```bash
curl -sS "https://shturval-tech.github.io/community-marketplace/index.yaml" | head
```

## 3. Permissions для Actions

Settings → Actions → General:

- Workflow permissions: **Read and write permissions**
- Allow GitHub Actions to create and approve pull requests (по желанию)

Settings → Actions → General → **Workflow permissions** должны позволять `GITHUB_TOKEN` публиковать packages и pushes в `gh-pages`.

## 4. GitHub Container Registry

Каждый зеркальный образ — **отдельный** container package в org: `community-marketplace/<image>` (например `community-marketplace/cloudnative-pg`, `community-marketplace/postgres`). Публичный git-репозиторий **не** делает эти пакеты публичными автоматически.

Предусловие: org **Settings → Packages** разрешает публичные пакеты.

После первого **Mirror Images** (или если в кластере `401 Unauthorized` на анонимный pull):

1. **Открыть существующие private-пакеты** — org policy «public для новых» не меняет старые. Варианты:

   - PAT с `write:packages`: `./scripts/ghcr-set-public.sh`
   - **Снести и пересобрать** (если образы нигде не используются): Actions → **Reset GHCR Mirrors** (нужен `GHCR_PACKAGES_TOKEN` с `delete:packages`, иначе `GITHUB_TOKEN` org admin), или локально:

   ```bash
   export GH_TOKEN=<PAT with read:packages, delete:packages>
   CONFIRM=1 make ghcr-delete-mirrors
   gh workflow run "Mirror Images" -R shturval-tech/community-marketplace
   ```

   Либо в org UI: **Packages** → каждый `community-marketplace/*` → **Delete package**, затем Mirror Images.

2. Проверка (ожидается 200 на все образы из `images/images.yaml`):

   ```bash
   make verify-ghcr-anonymous
   ```

Симптом закрытых пакетов: `failed to fetch anonymous token` / HTTP 401 на `https://ghcr.io/token?scope=repository:shturval-tech/community-marketplace/...` — обычно для **всего** каталога, не одного тега.

Workflow **Mirror Images** пытается выставить `visibility=public` после push (шаг некритичный). Обычно `GITHUB_TOKEN` **не может** менять visibility org-пакетов (HTTP 404 без прав org admin) — тогда обязателен `./scripts/ghcr-set-public.sh`. Опционально: repo secret **`GHCR_PACKAGES_TOKEN`** (PAT org admin + `write:packages`) для автоматизации в CI.

- Actions: разрешить push packages из этого репозитория

## 5. ShturvalRepoConfig URL

После Pages:

```yaml
spec:
  url: https://shturval-tech.github.io/community-marketplace
```

Для OCI (дополнительно):

```yaml
spec:
  url: oci://ghcr.io/shturval-tech/community-marketplace
  username: <github-user>
  password: <PAT with read:packages>
```

Для OCI в UI нужно вручную вводить имя чарта — предпочитайте HTTPS index.

## 6. Renovate (опционально)

Установите GitHub App [Renovate](https://github.com/apps/renovate) для org и включите репозиторий — конфиг: [renovate.json](../.github/renovate.json).

## 7. Проверить, что всё работает

После первого **Release Charts**:

```bash
curl -sS "https://shturval-tech.github.io/community-marketplace/index.yaml" | head
curl -sS "https://shturval-tech.github.io/community-marketplace/security/badge.json"
make verify-ghcr-anonymous
```

Подключение репозитория в кластере — [README.md](../README.md#быстрый-старт). Автоматизация CI — [ci.md](ci.md).
