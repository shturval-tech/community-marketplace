# Сканирование уязвимостей (Trivy + БДУ ФСТЭК)

Для администраторов и разработчиков: как CI проверяет **зеркалируемые образы** в GHCR и где смотреть результат. В кластере Штурвала дополнительные компоненты для сканирования не ставятся.

См. также: [глоссарий](glossary.md), автоматизация — [ci.md](ci.md), закрытый контур — [airgap.md](airgap.md).

## Что сканируется

| Объект | Инструмент | Когда |
|--------|------------|--------|
| Образы `ghcr.io/shturval-tech/community-marketplace/*` | Trivy (`vuln`) + обогащение БДУ | После каждой сборки образа (workflow **Mirror Images**) |
| Те же образы `:latest` | Полный прогон | Ежедневно 03:00 UTC (06:00 МСК), свежая БДУ на расписании + вручную (**Security Scan**) |
| Каталог `charts/` | Trivy `config` | PR/main lint (информационно, job не падает) |

## Базы данных

- **Trivy DB:** `public.shturval.tech/trivy-db:2` — агрегированная база платформы Штурвал. Фолбэк: `ghcr.io/aquasecurity/trivy-db:2` ([`scripts/scan/verify-trivy-db.sh`](../scripts/scan/verify-trivy-db.sh)).
- **Java DB:** `public.shturval.tech/trivy-java-db:1`
- **БДУ ФСТЭК:** `vulxml.xml.gz` — зеркало [velvetway/bdu-fstec-mirror](https://github.com/velvetway/bdu-fstec-mirror). Переменная `BDU_SOURCE_URL`. В контуре: `BDU_LOCAL_FILE`.

Сопоставление CVE → BDU: [`scripts/scan/bdu-enrich.py`](../scripts/scan/bdu-enrich.py) (поле `BDU` в JSON).

## Где смотреть результаты

1. **[Отчёт на GitHub Pages](https://shturval-tech.github.io/community-marketplace/security/)** — сводка; плашка в README — [`security/badge.json`](https://shturval-tech.github.io/community-marketplace/security/badge.json).
2. **GitHub Actions → Summary** — таблица по образу (`report.bdu.md`).
3. **Security → Code scanning** — SARIF после Mirror Images (`trivy-<image>`).
4. **Артефакты** — `report.json`, `report.bdu.json`, `report.bdu.md`, `report.cyclonedx.json`.

Публикация на Pages: job `publish-pages` в **Security Scan** и **Mirror Images**. Повторная выгрузка вручную — workflow **Publish Security Pages** ([ci.md](ci.md)).

## Как читать отчёт

**Плашка в README**

| Сообщение | Смысл |
|-----------|--------|
| «нет данных» | Нет успешных отчётов (Pages ещё не обновлялись или все scan jobs упали). |
| «частично (N без отч.)» | Часть образов без `report.bdu.json`; есть данные по остальным. |
| «ошибки (N)» | Нет успешных отчётов, но N образов помечены как неудачное сканирование. |
| Зелёный / красный по CVE | Есть отчёты; красный — есть блокирующие по политике находки с известным fix. |

**Таблица «Сканирование не удалось»** на Pages — образы без отчёта со ссылкой на упавший job в Actions.

**Колонки в сводке:** Trivy (уровень сканера), ФСТЭК (уровень по БДУ), Fixed (версия исправления, если известна).

## Политика блокировки

- **Сборка и загрузка образа не блокируются** — job `scan` с `continue-on-error: true`.
- Отдельный job **`scan-gate`** проверяет агрегированный отчёт: уязвимость уровня **`SCAN_FAIL_SEVERITY`** (по умолчанию `CRITICAL`) **с непустым FixedVersion**. Учитывается более высокий уровень из Trivy и БДУ.
- Workflow **Mirror Images** может завершиться с ошибкой из‑за `scan-gate`; отчёт на Pages всё равно публикуется.
- При **Nightly Rebuild** этап `scan-gate` **пропускается** (пересборка не упирается в CVE).
- Исключения: [`security/.trivyignore`](../security/.trivyignore) (CVE или `BDU:YYYY-NNNNN`).
- Порог: variable репозитория `SCAN_FAIL_SEVERITY`.

## Локальный запуск

```bash
make bdu-fetch
make scan IMAGE=ghcr.io/shturval-tech/community-marketplace/redis:latest
make scan-all
make scan-test
```

Отчёты: `dist/scan/<image>/`.

## Закрытый контур

```bash
make bundle WITH_SCAN_DB=1   # dist/scan-db/
# распаковка бандла, затем:
./push-offline.sh
```

На хосте в контуре:

```bash
export TRIVY_DB_REPOSITORY=registry.internal/trivy-db:2
export BDU_LOCAL_FILE=/path/to/vulxml.xml
make scan-all
```

Подробнее: [airgap.md](airgap.md).

## Регулярное обслуживание

| Действие | Периодичность | Как |
| --- | --- | --- |
| **Security Scan** | Ежедневно 03:00 UTC | Workflow **Security Scan** (cron) |
| Пересмотр `.trivyignore` | Ежемесячно или после major bump upstream | [security-update-residual.md](security-update-residual.md) |
| Сверка с baseline | После волн обновлений | [security-post-update-snapshot.md](security-post-update-snapshot.md) |
| Pages «N без отч.» | По событию | **Actions → Security Scan → Run workflow**; проверить job scan для образа |
| **Nightly Rebuild** | По расписанию репозитория | Пересборка `:latest` без scan-gate |
| Air-gap bundle | После успешного Mirror Images | Workflow **Air-gap Bundle Release** (chain) или вручную |

Порог блокировки merge в main для образов: **scan-gate** в **Mirror Images** (не путать с nightly).

## Ограничения

- Зеркало БДУ отстаёт от `bdu.fstec.ru`; в отчёте — дата снимка.
- Уязвимости upstream устраняет поставщик образа; маркетплейс фиксирует и сигнализирует.
- SARIF в Security tab в основном с CVE; полные BDU — в `report.bdu.json` и Summary.
