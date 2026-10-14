# rabbitmq

RabbitMQ — брокер сообщений (AMQP) для асинхронного взаимодействия сервисов.

**Требует:** SSC `rabbitmq-operator`.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/rabbitmq.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, `replicas`, `persistence` в `values.yaml`.

**Upstream:** [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
