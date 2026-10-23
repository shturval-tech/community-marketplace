# Снимок после волн 0.1.6–0.1.9 и CI-fix

Сравнение с [baseline](security-update-baseline.md) (2026-10-22, commit `ce881b8`, **233** суммарных блокирующих CVE по образам до дедупликации).

## Источник

| Поле | Значение |
| --- | --- |
| Отчёт Pages | [security/](https://shturval-tech.github.io/community-marketplace/security/) |
| Обновление Pages | **2026-10-23 11:49 UTC** |
| Образы (mirror) | commit **`e81ed9c`** |
| **scan-gate** (Mirror Images #39941014310) | **success** |
| Air-gap Bundle (после mirror) | **success** |

## Плашка и полнота отчёта

- **badge.json:** «частично (1 без отч.)» — один образ без `report.bdu.json` в агрегате Pages.
- **Таблица «сканирование не удалось»:** `strimzi-kafka` (метаданные job; пересканировать через **Security Scan** или повторный **Mirror Images** при расхождении).
- **scan-gate** использует артефакты matrix-scan; при успешном gate блокирующие **CRITICAL+FixedVersion** (с учётом `.trivyignore`) в CI не остались.

## Что изменилось относительно baseline (кратко)

| Область | Baseline | После обновлений |
| --- | --- | --- |
| Alpine, authentik, keycloak, redis, CNPG postgres operand | patch/minor bumps | 0.1.6 / 0.1.7 |
| RabbitMQ server | 3.13.7 | **4.4.0-management** (major; см. [миграцию](migrations/rabbitmq-4.x.md)) |
| MinIO server | старый RELEASE | **RELEASE.2025-10-15**, Go **1.25** |
| MinIO Operator | quay 4.x | **7.1.1**, сборка из исходников |
| Strimzi / Kafka | 0.45 / 3.8 | **1.3.0**, Kafka **4.2.2**, CR **v1** |
| Proxmox CSI | plugin 0.10 | зеркала **v0.21**, chart **0.5.1**, sidecars **v4.13+ / v6.4+** |
| CSI snapshotter | — | зеркало **v8.7.0** |
| busybox (keycloak dbchecker) | 1.36 | **1.38.0** (волна 3) |
| nextcloud-aio | `latest` | pin **v14.4.1** (волна 3; чарт по-прежнему placeholder) |

## Принятые риски (`.trivyignore`)

См. [security-update-residual.md](security-update-residual.md) и [`security/.trivyignore`](../security/.trivyignore). Пересмотр — при новых релизах upstream или ежемесячно вместе с **Security Scan**.

## Следующий контроль

1. Убедиться, что **strimzi-kafka** появился в Pages (ручной **Security Scan**).
2. Сравнить число блокирующих в UI (фильтр CRITICAL + Fixed) с baseline 233 — ориентир «значимое снижение», не формальная сумма (ignore и BDU меняют картину).
3. **Nightly Rebuild** / **Security Scan** — мониторинг регрессий ([security-scanning.md](security-scanning.md#регулярное-обслуживание)).
