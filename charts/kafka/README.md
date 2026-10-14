# kafka

Apache Kafka для потоковой передачи событий и интеграций (Strimzi, KRaft).

**Требует:** SSC `strimzi-operator`.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/kafka.yaml
```

**Основные параметры:** `global.imageRegistry`, `name`, `replicas`, `kafkaVersion`, `kafkaImageTag`.

**Upstream:** [Strimzi](https://strimzi.io)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
