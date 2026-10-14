# redis

Redis — in-memory хранилище для кэша, сессий и очередей; инстанс через CR оператора.

**Требует:** SSC `redis-operator`.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/redis.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, `redisStandalone` / replication в `values.yaml`.

**Upstream:** [OT-CONTAINER-KIT Redis Operator](https://github.com/OT-CONTAINER-KIT/redis-operator)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
