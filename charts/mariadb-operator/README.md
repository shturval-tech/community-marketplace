# mariadb-operator

Kubernetes-оператор MariaDB: автоматизация развёртывания, масштабирования и резервного копирования.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/mariadb-operator.yaml
```

**Основные параметры:** `global.imageRegistry`, `mariadb-operator` (subchart) в `values.yaml`.

**Upstream:** [MariaDB Operator](https://mariadb.com/k8s/)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
