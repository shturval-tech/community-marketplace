# nextcloud-aio

Nextcloud — частное облако для файлов, календаря, контактов и офисных документов (All-in-One).

**Статус:** placeholder-чарт (`placeholder.enabled: true`). Зеркало AIO **14.4.1** (pull upstream `:latest` с ghcr.io/nextcloud-releases/all-in-one, релиз v14.4.1); полная интеграция — после `scripts/sync-upstream.sh`.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/nextcloud-aio.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, `global.ingress.className`, домен и тома AIO в `values.yaml`.

**Upstream:** [Nextcloud All-in-One](https://github.com/nextcloud/all-in-one)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
