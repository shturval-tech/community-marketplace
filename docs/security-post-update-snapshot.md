# Снимок после волны security-fix (Strimzi / MariaDB / CSI / MinIO)

Baseline для сравнения: Pages **2026-10-28**, commit `f696a37`, **gate_failures: 2** (`CVE-2026-114406` на Strimzi operator/kafka). См. также [baseline](security-update-baseline.md).

## Что сделано в репозитории (ожидается после Mirror Images)

| Область | Изменение |
| --- | --- |
| **strimzi-operator**, **strimzi-kafka** | UBI9 `microdnf upgrade` (`ca-certificates`, pcre2, python3, expat, curl); `USER 1001` |
| **mariadb-operator** | upstream **26.10.2**, чарт marketplace **0.1.8** |
| **csi-resizer** | сборка из **v1.14.0** + Go **1.25.7**, `grpc@v1.79.3` (тег sidecar **v1.14.0**) |
| **minio**, **minio-operator** | Go **1.26.9**, `go get` crypto/grpc/amqp091-go |
| **rabbitmq-server** | `apt` upgrade **gpgv** (BDU CRITICAL **CVE-2025-68973**) |
| **postgres** | без bump: **16.16** в CNPG catalog нет, operand **16.15** |
| **`.trivyignore`** | сняты amqp091-go (пересборка minio) и устаревшие proxmox/openssl CVE; crypto/grpc/stdlib — пока для console/minio |

## Целевой результат scan-gate

- **gate_failures: 0** (плашка «нет критич. с fix»).
- Блокирующие **CVE-2026-114406** должны исчезнуть на Strimzi после overlay.

## Контроль после merge

1. **Mirror Images** → **scan-gate** success.
2. **Security Scan** workflow_dispatch — сверка [Pages](https://shturval-tech.github.io/community-marketplace/security/) и `status.json`.
3. Убедиться, что **nextcloud-aio** присутствует в агрегате (на `f696a37` секции не было в опубликованном отчёте).
4. `make lint` для **mariadb-operator** **0.1.8**.

## Остаётся в `.trivyignore`

См. [security-update-residual.md](security-update-residual.md): minio-console, Strimzi Java netty/lz4, CNPG PyJWT/certifi, глобальные crypto/grpc пока console в каталоге.
