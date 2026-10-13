# Ручная настройка GitHub

Выполняет владелец организации **shturval-tech** один раз (или при смене политики).

## 1. Public repository

Репозиторий должен быть **public**, чтобы GitHub Pages отдавал Helm index без аутентификации (SSC/UI Штурвала).

Settings → General → Danger Zone → Change visibility → Public.

## 2. GitHub Pages

Settings → Pages:

- **Source**: Deploy from a branch
- **Branch**: `gh-pages` / `/ (root)`

Ветка `gh-pages` создаётся автоматически workflow **Release Charts** (chart-releaser).

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

Packages → Package settings для `community-marketplace`:

- Visibility: public (для community pull без auth)
- Actions: разрешить push из этого репозитория

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
