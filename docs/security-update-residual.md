# Остаточные риски после безопасной волны 0.1.6

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
| proxmox-csi | CSI sidecars v4.8.1 / v5.2.0 / v1.13.2 / v2.15.0 / v2.13.0 |
| зеркало alpine | 3.21 |

## Ожидаемое снижение блокеров

После пересборки зеркал в GHCR и ночного **Security Scan** должны уменьшиться находки с известным fix у: alpine, authentik, keycloak, postgres, redis, rabbitmq-*, minio (server), CSI sidecars и proxmox-csi (через sidecars).

Локально без Trivy полный `make scan-all` не выполнялся; проверки: `helm lint` + `helm template` (Kubernetes 1.32), `make verify-images`, `pytest tests/scan/`.

## Вне scope (отдельные миграции)

| Область | Текущее | Почему отдельно |
| --- | --- | --- |
| **Strimzi / Kafka** | 0.45.0, Kafka 3.8.0 | Переход на Strimzi 1.x: CRD API `v1`, Kafka 4.x, Kubernetes ≥ 1.32, смена vendored chart |
| **MinIO Operator / Console** | v4.3.7 / v0.12.3 | Десятки CRITICAL с fix на RHEL8 base; нужен переход на operator 7.x и отказ от operator UI/console chart |
| **Proxmox CSI plugin** | v0.10.0, chart 0.3.3 | Upstream v0.21+; согласование sidecars уже обновлено, plugin — breaking upgrade |
| **MariaDB Operator** | 26.10.1 | Уже последний релиз upstream; блокеры в Go-зависимостях ждут нового образа vendor |
| **nextcloud-aio** | `latest` | Нет pin версии; placeholder-чарт |
| **busybox** | 1.36 | Используется в keycloak dbchecker; отдельный pin patch |

## MinIO Community

Upstream [minio/minio](https://github.com/minio/minio) архивирован; финальный security-тег **RELEASE.2025-10-15T17-29-55Z** закрывает известные CVE на момент релиза, но **дальнейших патчей CE не будет**. Для долгосрочной поддержки рассмотреть AIStor или поддерживаемый fork (см. обсуждения community).

## Следующие шаги для полного эффекта в CI

1. Merge и workflow **Mirror Images** — пересборка затронутых Dockerfile.
2. Дождаться **Security Scan** / проверить [Pages](https://shturval-tech.github.io/community-marketplace/security/).
3. При необходимости — **Nightly Rebuild** (fingerprint upstream digest изменится).
