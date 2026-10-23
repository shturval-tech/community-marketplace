# Миграция: MinIO Operator 4.x → 7.x (marketplace 0.1.7+)

## Что изменилось в marketplace

- Subchart: **`operator` 7.1.1** (не `minio-operator` 4.x).
- Values key: **`operator.operator.*`** (см. [`charts/minio-operator/values.yaml`](../charts/minio-operator/values.yaml)).
- **Console/UI** из operator chart **убран** — отдельное зеркало `minio-console` только для **minio-tenant** UI.
- Образ operator: **GHCR**, сборка из `minio/operator` **v7.1.1**.

## Предусловия

- Kubernetes **≥ 1.32**.
- CRD **Tenants** актуальной версии operator 7.x (устанавливаются чартом).

## Порядок (высокий уровень)

1. Прочитать [release notes MinIO Operator 7.x](https://github.com/minio/operator/releases).
2. Обновить SSC / Helm release **minio-operator** до **0.1.7+**.
3. Проверить `Tenant` CR и STS-related настройки (`OPERATOR_STS_ENABLED` включён в values по умолчанию).
4. Обновить **minio-tenant** при необходимости (operand server — отдельный чарт **0.1.6+**).

## Совместимость

- Существующие `Tenant` с API 4.x могут требовать пошагового обновления CRD и operator — тестируйте на staging.
- Не смешивайте operator 4.x и 7.x в одном кластере.

## SSC

```yaml
spec:
  chart: minio-operator
  version: "0.1.7"
```
