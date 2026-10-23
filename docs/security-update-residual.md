# Остаточные риски после волн 0.1.6 и 0.1.7

См. [baseline](security-update-baseline.md) и [сканирование](security-scanning.md).

## Что обновлено в 0.1.6

| Чарт marketplace | Образ / компонент |
| --- | --- |
| authentik | 2026.8.5 |
| keycloak | 26.8.1 |
| cnpg-cluster | postgres operand 16.15 |
| redis | 7.2.16 |
| rabbitmq | 3.13.7-management |
| rabbitmq-operator | 2.19.2 (актуальный тег на Docker Hub; 2.23.x в registry пока недоступен) |
| minio-tenant | MinIO RELEASE.2025-10-15T17-29-55Z (сборка `go install`, т.к. upstream без бинарников), base Alpine 3.21 |
| proxmox-csi | CSI sidecars (первая волна) |
| зеркало alpine | 3.21 |

## Что обновлено в 0.1.7 (волна 2, без nextcloud-aio)

| Чарт marketplace | Образ / компонент | Примечание |
| --- | --- | --- |
| strimzi-operator | 1.3.0 | CR `kafka.strimzi.io/v1`; миграция с v1beta2 — отдельный runbook для кластеров |
| kafka | Kafka 4.2.2, operand `1.3.0-kafka-4.2.2` | metadata version 4.2-IV0 |
| minio-operator | v7.1.1 | Subchart `operator` 7.x; UI/console из operator chart убран |
| minio-tenant (console mirror) | v0.30.0 | Зеркало для tenant UI, не часть operator chart |
| proxmox-csi | plugin v0.16.0, chart dep 0.5.0 | Sidecars: attacher v4.10.0, provisioner v5.3.0, resizer v1.14.0, livenessprobe v2.16.0, snapshotter v8.3.0 |
| mariadb-operator | 26.10.1 (upstream без изменений) | Принятые CVE в `security/.trivyignore` (golang.org/x/crypto до нового релиза vendor) |

## Ожидаемое снижение блокеров

После **Mirror Images** и **Security Scan** должны снизиться CRITICAL с fix у: Strimzi/Kafka operands, MinIO Operator 7.x, proxmox plugin и CSI snapshotter.

Локально: `make verify-images`, `helm lint` / `helm template` (Kubernetes 1.32), `pytest tests/scan/` при наличии Trivy.

## Вне scope / отдельно

| Область | Статус |
| --- | --- |
| **nextcloud-aio** | Не обновлялся (`latest`); placeholder-чарт |
| **busybox** | 1.36; keycloak dbchecker |
| **MinIO Community server** | Архив upstream; CE без будущих патчей — см. baseline |
| **Proxmox CSI** | Chart 0.5.0 / plugin v0.16.0 — не v0.21; при появлении новых OCI-релизов — следующая волна |
| **MariaDB Operator** | Ждём upstream с обновлённым Go toolchain / x/crypto |

## CI

1. Push → **Mirror Images** (новые/обновлённые Dockerfile и теги в `images/images.yaml`).
2. **Security Scan** / [отчёт Pages](https://shturval-tech.github.io/community-marketplace/security/).
3. При необходимости **Nightly Rebuild** или ручной **Air-gap Bundle** после успешного scan-gate.
