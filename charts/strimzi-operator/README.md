# strimzi-operator

Strimzi управляет Kafka, топиками, Connect и пользователями в Kubernetes (режим KRaft).

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/strimzi-operator.yaml
```

**Основные параметры:** `global.imageRegistry`, `strimzi-kafka-operator` (subchart) в `values.yaml`.

**Upstream:** [Strimzi](https://strimzi.io)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
