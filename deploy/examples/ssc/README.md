# Примеры ShturvalServiceConfig

Готовые SSC для чартов community-marketplace. Сначала подключите репозиторий: [README.md](../../../README.md#быстрый-старт) (`kubectl apply -k deploy/repoconfig/base`).

## Общие правила

- `spec.reponame` = `community` (как `metadata.name` у ShturvalRepoConfig).
- `spec.version` = `version` из `charts/<chart>/Chart.yaml`.
- `spec.dependency` — имена **других SSC** (не Helm-зависимостей), которые должны быть установлены раньше.

## Порядок установки

1. **Операторы** (без dependency в SSC):
   - `cnpg-operator.yaml`
   - `mariadb-operator.yaml`
   - `redis-operator.yaml`
   - `rabbitmq-operator.yaml`
   - `strimzi-operator.yaml`
   - `minio-operator.yaml`

2. **Экземпляры** (после соответствующего оператора):
   - `cnpg-cluster.yaml` → нужен SSC `cnpg-operator`
   - `mariadb.yaml` → `mariadb-operator`
   - `redis.yaml` → `redis-operator`
   - `rabbitmq.yaml` → `rabbitmq-operator`
   - `kafka.yaml` → `strimzi-operator`
   - `minio-tenant.yaml` → `minio-operator`

3. **Самостоятельные чарты** (оператор не требуется):
   - `keycloak.yaml`, `authentik.yaml`, `proxmox-csi.yaml`, `nextcloud-aio.yaml`

```bash
kubectl apply -f deploy/examples/ssc/cnpg-operator.yaml
kubectl apply -f deploy/examples/ssc/cnpg-cluster.yaml
```

Соглашения: [docs/chart-conventions.md](../../../docs/chart-conventions.md).
