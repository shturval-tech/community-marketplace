# rabbitmq-operator

Cluster Operator для RabbitMQ — управление кластерами очередей и обмена сообщениями.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/rabbitmq-operator.yaml
```

**Основные параметры:** `global.imageRegistry`, настройки cluster-operator в `values.yaml`.

**Upstream:** [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
