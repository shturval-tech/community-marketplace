# minio-tenant

MinIO Tenant — выделенное объектное хранилище с API Amazon S3.

**Требует:** SSC `minio-operator`.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/minio-tenant.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, pools и `volumeClaimTemplate` в `values.yaml`.

**Upstream:** [MinIO Operator](https://min.io/docs/minio/kubernetes/upstream/)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
