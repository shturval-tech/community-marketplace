# redis-operator

Оператор Redis (Opstree): standalone, replication и Sentinel в Kubernetes.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/redis-operator.yaml
```

**Основные параметры:** `global.imageRegistry`, образы оператора в `values.yaml`.

**Upstream:** [OT-CONTAINER-KIT Redis Operator](https://github.com/OT-CONTAINER-KIT/redis-operator)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
