# Сканирование уязвимостей (Trivy + БДУ ФСТЭК)

CI маркетплейса проверяет **зеркалируемые образы** в ghcr.io и (информационно) Helm-манифесты чартов. В кластере Штурвала ничего дополнительно не ставится.

## Что сканируется

| Объект | Инструмент | Когда |
|--------|------------|--------|
| Образы `ghcr.io/shturval-tech/community-marketplace/*` | Trivy (`vuln`) + обогащение БДУ | После каждой сборки образа ([`.github/workflows/images.yaml`](../.github/workflows/images.yaml)) |
| Те же образы `:latest` | Полный прогон | Еженедельно + вручную ([`.github/workflows/security-scan.yaml`](../.github/workflows/security-scan.yaml)) |
| Каталог `charts/` | Trivy `config` | PR/main lint (без падения job) |

## Базы данных

- **Trivy DB:** `public.shturval.tech/trivy-db:2` — агрегированная база платформы Штурвал (CVE, errata ОС и др.). При недоступности используется фолбэк `ghcr.io/aquasecurity/trivy-db:2` ([`scripts/scan/verify-trivy-db.sh`](../scripts/scan/verify-trivy-db.sh)).
- **Java DB:** `public.shturval.tech/trivy-java-db:1`
- **БДУ ФСТЭК:** выгрузка `vulxml.xml.gz` — по умолчанию зеркало [velvetway/bdu-fstec-mirror](https://github.com/velvetway/bdu-fstec-mirror) (доступно из GitHub Actions). Свой URL: переменная `BDU_SOURCE_URL`. В air-gap: `BDU_LOCAL_FILE=/path/to/vulxml.xml`.

Сопоставление **CVE → BDU** выполняется скриптом [`scripts/scan/bdu-enrich.py`](../scripts/scan/bdu-enrich.py) и добавляет в JSON поле `BDU` (идентификаторы, уровень по формулировке ФСТЭК, CVSS).

## Где смотреть результаты

1. **[Отчёт на GitHub Pages](https://shturval-tech.github.io/community-marketplace/security/)** — сводка последнего сканирования; плашка в README берёт статус из [`security/badge.json`](https://shturval-tech.github.io/community-marketplace/security/badge.json) (shields.io endpoint).
2. **GitHub Actions → Step Summary** — таблица по каждому образу (`report.bdu.md`).
3. **Security → Code scanning alerts** — SARIF после сборки образов (категория `trivy-<image>`).
4. **Артефакты workflow** — `report.json`, `report.bdu.json`, `report.bdu.md`, `report.cyclonedx.json` (SBOM).

Публикация на Pages: job **`publish-pages`** в workflow **Security Scan** и **Mirror Images** (после job `scan`). Workflow **Publish Security Pages** — только ручной перезапуск по `workflow_run_id` Security Scan.

## Политика блокировки

- Сборка и push образа **не блокируются**.
- Job `scan` падает, если найдена уязвимость уровня **`SCAN_FAIL_SEVERITY`** (по умолчанию `CRITICAL`) **с известной версией исправления** (`FixedVersion` не пустой). Уровень учитывает и Trivy, и БДУ (берётся более высокий).
- Исключения — файл [`security/.trivyignore`](../security/.trivyignore) (CVE или `BDU:YYYY-NNNNN`).

Порог можно изменить в настройках репозитория: variable `SCAN_FAIL_SEVERITY`.

## Локальный запуск

```bash
make bdu-fetch
# нужны: trivy, docker/login к ghcr при приватных образах
make scan IMAGE=ghcr.io/shturval-tech/community-marketplace/redis:latest
make scan-all
make scan-test   # unit-тесты обогащения БДУ
```

Отчёты: `dist/scan/<image>/`.

## Закрытый контур

```bash
make bundle WITH_SCAN_DB=1   # dist/scan-db/: trivy-db, trivy-java-db, vulxml.xml.gz
make push REGISTRY=... HELM_REPO_URL=...
```

На build-хосте в контуре:

```bash
export TRIVY_DB_REPOSITORY=registry.internal/trivy-db:2
export BDU_LOCAL_FILE=/path/to/vulxml.xml
make scan-all
```

Подробнее: [airgap.md](airgap.md).

## Ограничения

- Зеркало БДУ обновляется с лагом относительно `bdu.fstec.ru`; в отчёте указывается дата снимка.
- Образы upstream — уязвимости устраняет поставщик; маркетплейс только фиксирует и сигнализирует.
- SARIF в Security tab содержит в основном идентификаторы CVE; полные BDU — в `report.bdu.json` / Step Summary.
