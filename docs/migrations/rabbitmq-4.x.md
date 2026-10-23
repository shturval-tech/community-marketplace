# Миграция: RabbitMQ 3.13 → 4.4 (marketplace 0.1.7+)

## Контекст

Зеркало **rabbitmq-server** и чарт **rabbitmq** marketplace переведены на **`4.4.0-management`** (Docker Official Image) для снижения CVE в CI. Это **major** относительно **3.13.x**.

## Зависимости

- **rabbitmq-operator** marketplace **0.1.6+** (образ **2.19.2** — последний тег `rabbitmqoperator/cluster-operator` на Docker Hub на момент обновления; **2.23.x** недоступен).
- Проверьте [матрицу совместимости RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview) для вашей версии operator и RabbitMQ **4.x**.

## Рекомендуемый порядок

1. Staging: operator → обновление `RabbitmqCluster` image на GHCR **`rabbitmq-server:4.4.0-management`**.
2. Проверить политики, definitions, плагины management, версии протокола клиентов.
3. Production: maintenance window, backup definitions и persistent volumes.

## Откат

- Зафиксируйте предыдущий тег образа (`3.13.7-management`) в SSC/values до миграции.
- Marketplace **0.1.6** и старше — RabbitMQ 3.13; **0.1.7+** — 4.4.

## SSC

```yaml
spec:
  chart: rabbitmq
  version: "0.1.7"
```

Operator (без смены major образа server):

```yaml
spec:
  chart: rabbitmq-operator
  version: "0.1.6"
```
