# Миграция: Strimzi 1.3 и Kafka 4.x (marketplace 0.1.7+)

Документ для администраторов кластера. **Marketplace только поставляет чарты и образы** — выполняйте в maintenance window.

## Предусловия

- Kubernetes **≥ 1.32** (целевая версия платформы Штурвал).
- Установлен **strimzi-operator** marketplace **≥ 0.1.7** (operand **1.3.0**).
- Чарт **kafka** **≥ 0.1.7** (Kafka **4.2.2**, metadata **4.2-IV0**).

## CRD API: v1beta2 → v1

Strimzi **1.3** использует `kafka.strimzi.io/v1`. Существующие ресурсы `v1beta2` нужно мигрировать по [официальной документации Strimzi](https://strimzi.io/docs/operators/latest/deploying.html#assembly-crd-api-conversion-str).

Краткий порядок:

1. Обновить CRD (чарт operator).
2. Дождаться conversion / применить миграционные шаги Strimzi для вашей версии.
3. Обновить манифесты `Kafka`, `KafkaNodePool`, `KafkaTopic`, `KafkaUser` на **v1**.
4. Проверить статус `Kafka` и rolling update broker.

## Обновление Kafka version

- С **3.x** на **4.x** — major; проверьте [inter-broker protocol / metadata version](https://strimzi.io/docs/operators/latest/deploying.html#con-kafka-versions-str).
- Marketplace values задают **4.2.2** и образ **`1.3.0-kafka-4.2.2`** (GHCR mirror).

## Откат

- Держите backup метаданных и snapshot PVC.
- Откат operator/Kafka ниже 1.3 после миграции CR **v1** может быть невозможен без восстановления CRD и бэкапа.

## SSC

```yaml
spec:
  chart: strimzi-operator
  version: "0.1.7"
```

```yaml
spec:
  chart: kafka
  version: "0.1.7"
```

См. `deploy/examples/ssc/strimzi-operator.yaml` и `deploy/examples/ssc/kafka.yaml`.
