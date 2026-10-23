# Baseline сканирования (до обновления образов)

Источник: [отчёт на GitHub Pages](https://shturval-tech.github.io/community-marketplace/security/), снимок **2026-10-22 08:34 UTC**, commit образов `ce881b8ef93a1408c03445f24a6921de010d4a73`.

Порог CI: **CRITICAL** с непустым **FixedVersion** (Trivy ∪ БДУ ФСТЭК).

## Блокирующие находки по образам (уникальные CVE на образ)

| Образ | Уникальных блокирующих CVE |
| --- | ---: |
| alpine | 1 |
| authentik | 3 |
| csi-attacher | 3 |
| csi-livenessprobe | 3 |
| csi-node-driver-registrar | 3 |
| csi-provisioner | 3 |
| csi-resizer | 3 |
| keycloak | 2 |
| mariadb | 1 |
| mariadb-operator | 7 |
| minio | 12 |
| minio-console | 59 |
| minio-operator | 57 |
| postgres | 18 |
| proxmox-csi-controller | 3 |
| proxmox-csi-node | 6 |
| rabbitmq-operator | 2 |
| rabbitmq-server | 2 |
| redis | 16 |
| strimzi-kafka | 20 |
| strimzi-operator | 9 |

**Сумма по образам (без дедупликации между образами): 233.**

## Целевая матрица безопасной волны (Kubernetes ≥ 1.32)

| Компонент | Было | Станет |
| --- | --- | --- |
| alpine | 3.17 | 3.21 |
| authentik | 2026.8.3 | 2026.8.5 |
| keycloak | 26.7.4 | 26.8.1 |
| postgres (CNPG operand) | 16.4 | 16.15 |
| redis | 7.2.5 | 7.2.16 |
| rabbitmq-server | 3.13-management | 3.13.7-management |
| rabbitmq-operator | 2.12.0 | 2.19.2 (последний тег на Docker Hub) |
| minio (server) | RELEASE.2025-04-08… | RELEASE.2025-10-15T17-29-55Z |
| minio Dockerfile base | alpine:3.19 | alpine:3.21 |
| csi-attacher | v4.7.0 | v4.8.1 |
| csi-provisioner | v5.1.0 | v5.2.0 |
| csi-resizer | v1.12.0 | v1.13.2 |
| csi-livenessprobe | v2.14.0 | v2.15.0 |
| csi-node-driver-registrar | v2.12.0 | v2.13.0 |

Вне scope этой волны: Strimzi/Kafka 0.45, MinIO Operator/Console 4.x, Proxmox CSI plugin 0.10, MariaDB Operator (уже 26.10.1).
