# n8n

n8n — конструктор сценариев: вебхуки, интеграции и запуск по расписанию.

**Требует:** нет. Перед установкой создайте Secret с ключом шифрования:

```bash
kubectl -n n8n create secret generic n8n-encryption \
  --from-literal=N8N_ENCRYPTION_KEY="$(openssl rand -base64 32)"
```

Потеря или смена ключа делает сохранённые учётные данные нечитаемыми.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/n8n.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, `httpRoute`, `n8n.persistence`.

По умолчанию один pod и SQLite на PVC (`n8n.queueMode.enabled: false`, `n8n.database.type: sqlite`). Ingress выключен. Чарт не создаёт Gateway: при `httpRoute.enabled: true` рисуется HTTPRoute на уже существующий Gateway. В `parentRefs` укажите его имя, namespace и listener. Рядом задайте публичные URL и число прокси, chart 1.x сам их из маршрута не выводит:

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: shturval-gateway
      namespace: gateway-system
      sectionName: https
  hostnames:
    - n8n.example.com
n8n:
  editor:
    url: https://n8n.example.com
  webhook:
    url: https://n8n.example.com
  config:
    extraEnv:
      - name: N8N_PROXY_HOPS
        value: "1"
```

`N8N_PROXY_HOPS` равен числу прокси перед n8n. Для одного Gateway это `1`. Listener Gateway должен принимать HTTPRoute из namespace установки.

Отдельный хост вебхуков — `httpRoute.webhook.hostnames` и при необходимости свои `parentRefs`. При `n8n.webhookProcessor.enabled` (только вместе с queue mode) префиксы `/webhook/`, `/webhook-waiting/`, `/form/`, `/form-waiting/` и `/mcp/` идут на webhook processor. Тестовые пути остаются на main.

Queue mode — внешние PostgreSQL и Redis, чарт их не ставит:

```yaml
n8n:
  queueMode:
    enabled: true
  database:
    type: postgresdb
    useExternal: true
    host: <cnpg-rw>.<namespace>.svc
    passwordSecret:
      name: n8n-db
      key: password
  redis:
    host: <redis>.<namespace>.svc
```

**Upstream:** [n8n Helm chart](https://github.com/n8n-io/n8n-hosting/tree/release/n8n-2.x/charts/n8n)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
