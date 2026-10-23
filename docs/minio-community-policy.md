# Политика MinIO Community Edition в marketplace

## Статус upstream

- Репозиторий [minio/minio](https://github.com/minio/minio) **архивирован**; финальный security-тег CE — **RELEASE.2025-10-15T17-29-55Z**.
- Бинарники на GitHub Releases для поздних тегов **отсутствуют** — зеркало собирается через `go install` ([`images/minio/Dockerfile`](../images/minio/Dockerfile), toolchain **Go 1.25**).

## Риски

- Новые CVE в транзитивных Go-модулях **не получат патча от vendor** — часть учтена в [`security/.trivyignore`](../security/.trivyignore) с комментариями.
- **MinIO Console** (`quay.io/minio/console`, последний тег **v0.30.0**): устаревшая база (RHEL 8 / Go 1.20); публичных исходников для пересборки нет — зеркало только для tenant UI, не для operator 7.x.

## MinIO Operator 7.x

- Чарт marketplace: subchart `operator` **7.1.1**, образ — **сборка из GitHub** `minio/operator` v7.1.1, не quay.

## Рекомендации для эксплуатации

| Сценарий | Рекомендация |
| --- | --- |
| Greenfield, долгая поддержка | Рассмотреть **MinIO AIStor** или поддерживаемый дистрибутив с SLA |
| Остаёмся на CE | Зафиксировать тег operand в SSC, мониторить [security report](https://shturval-tech.github.io/community-marketplace/security/), air-gap bundle после каждого mirror |
| Console | Минимизировать exposure; ingress только при необходимости; ждать новый тег quay или замену UI |

## Связанные документы

- [Миграция operator 7.x](migrations/minio-operator-7.x.md)
- [Остаточные риски](security-update-residual.md)
