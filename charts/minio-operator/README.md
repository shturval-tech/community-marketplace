# minio-operator

Оператор MinIO для S3-совместимых бакетов и политик хранения в кластере.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/minio-operator.yaml
```

**Основные параметры:** `global.imageRegistry`, настройки operator subchart в `values.yaml`.

**Upstream:** [MinIO Operator](https://min.io/docs/minio/kubernetes/upstream/)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
