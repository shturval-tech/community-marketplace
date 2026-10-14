# mariadb

MariaDB — СУБД, совместимая с MySQL; инстанс через CR оператора MariaDB.

**Требует:** SSC `mariadb-operator`.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/mariadb.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, параметры CR MariaDB в `values.yaml`.

**Upstream:** [MariaDB Operator](https://mariadb.com/k8s/)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
