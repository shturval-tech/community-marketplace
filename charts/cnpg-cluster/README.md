# cnpg-cluster

Готовый кластер PostgreSQL (CloudNativePG) для приложений платформы.

**Требует:** SSC оператора `cnpg-operator`.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/cnpg-cluster.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, `cluster.instances`, `cluster.storage.size`.

**Upstream:** [CloudNativePG](https://cloudnative-pg.io)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
