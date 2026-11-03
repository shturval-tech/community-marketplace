# Остаточные риски и дорожная карта

- [Baseline до обновлений](security-update-baseline.md)
- [Снимок после волн](security-post-update-snapshot.md)
- [Сканирование](security-scanning.md)
- [MinIO CE — политика](minio-community-policy.md)
- [Миграции в кластере](migrations/)

## Версии marketplace (актуально)

| Волна | Чарты / образы |
| --- | --- |
| **0.1.6** | authentik, keycloak (до 0.1.7 busybox), cnpg-cluster, redis, rabbitmq-operator, minio-tenant, первая волна CSI |
| **0.1.7** | strimzi-operator, kafka, minio-operator, mariadb-operator; rabbitmq **4.4** |
| **0.1.8** | mariadb-operator (**26.10.2**) |
| **0.1.8–0.1.9** | proxmox-csi (образы **v0.21**, sidecars новее upstream chart); chart dep **0.5.1** |
| **0.1.6 nextcloud** | pin **v14.4.1** (placeholder-чарт) |
| **security wave (образы)** | Strimzi UBI9 overlay; csi-resizer rebuild **v1.14.0**; MinIO CE/operator Go **1.26.9** + `go get` транзитивов |

## Принятые риски (`.trivyignore`)

| Группа | Причина | Когда снять |
| --- | --- | --- |
| golang.org/x/crypto (серия CVE-2026-3983*) | **minio-console** quay **v0.30.0**; operator **26.10.2** закрывает только mariadb-operator | новый тег console или отказ от зеркала; minio/minio-operator после пересборки — перескан |
| CVE-2026-33186, CVE-2025-68121 (global) | **minio-console**, **mariadb** (stdlib); csi-resizer/minio пересобраны локально | исчезновение CVE из всех образов каталога |
| minio-console (legacy Go) | quay **v0.30.0**, нет исходников | новый тег или отказ от зеркала |
| strimzi-kafka netty/lz4 | operand **1.3.0-kafka-4.2.2** | patch Strimzi/Kafka image |
| postgres PyJWT/certifi | CNPG **16.15** (нет **16.16** в каталоге CNPG) | bump operand, когда upstream выпустит патч-сборку |
| minio/minio in-tree CVE без fix | **CVE-2026-33322**, **CVE-2026-33419** | вне ignore; архив minio/minio, FixedVersion пустой |

Пересмотр списка: **ежемесячно** или при каждом **Security Scan** (см. ниже).

## Вне scope / backlog

| Компонент | Статус |
| --- | --- |
| **nextcloud-aio** | Pin **v14.4.1**; полноценный чарт — после `sync-upstream.sh` |
| **rabbitmq-operator 2.23.x** | на Docker Hub **нет**; остаётся **2.19.2** |
| **Proxmox Helm appVersion** | OCI chart **0.5.1** всё ещё **v0.16.0**; зеркала **v0.21** — override в values |
| **busybox** | **1.38.0** для keycloak dbchecker |

## Миграции (только runbook, не автоматика)

- [Strimzi 1.3 / Kafka 4.2](migrations/strimzi-1.3-kafka-4.md)
- [MinIO Operator 7.x](migrations/minio-operator-7.x.md)
- [RabbitMQ 4.4](migrations/rabbitmq-4.x.md)

## CI / мониторинг

1. **Mirror Images** после изменений `images/**` / `security/.trivyignore`.
2. **Security Scan** ( nightly 03:00 UTC ) — полный прогон `:latest`.
3. Pages: [отчёт](https://shturval-tech.github.io/community-marketplace/security/); при «без отчёта» — перескан (**Security Scan** workflow_dispatch).
4. **Air-gap Bundle** — после успешного mirror (или вручную).
