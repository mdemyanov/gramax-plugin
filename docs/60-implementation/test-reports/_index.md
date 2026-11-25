---
title: Отчёты прогона
order: 1
---

# Отчёты прогона

Результаты прогона тестовых suite по фичам плагина.

Отчёты эпохи superpowers (2026-05…2026-08-10) удалены при инверсии раскладки
2026-11-17 (FR-129, ADR-0021); содержательное зерно — в требованиях 30-requirements.

- [QA Report — волна 4.2.0 (ADR-0012/0013/0015 + writer-consumer-rules)](2026-08-12-wave-4.2.0-qa-report.md)
- [QA Report — ретракция cross-каталожного `code:`-рецепта (hotfix 4.2.1)](2026-08-13-cross-catalog-retraction-qa-report.md)
- [QA Report — контракт формы ссылки на артефакт (`link-form-contract`, 4.3.0)](2026-08-13-link-form-contract-qa-report.md)
- [QA Report — линтер рендер-киллеров Gramax (`validate_render.py`, 4.4.0)](2026-08-13-render-killer-linter-qa-report.md)
- [QA Report — рекурсивное обнаружение `.doc-root.yaml` и типизация полей (FR-120…123, ADR-0020)](2026-08-13-doc-root-discovery-qa-report.md)
- [QA Report qa-057 — полный прогон после инверсии раскладки content/ → docs/](2026-11-18-qa-057-docs-layout-inversion-full-run.md)
- [QA Report — навык export (экспорт DOCX/PDF: шаблоны, placement, CI/CD, статический портал)](2026-11-18-export-skill-qa-report.md)
- [QA Report — навык plantuml (PlantUML/Salt/BPMN-авторство: file-based, без конвертационных пайплайнов)](2026-11-18-plantuml-bpmn-qa-report.md) — accept
- [QA Report — паритет офлайн-валидаторов с модулем «Проверка на ошибки» (W031→mermaid/plant-uml/bpmn, W035 `.icons/`, контракт-паритет W034)](2026-11-18-validators-parity-qa-report.md) — accept
- [QA Report — синхронизация writer 4.7.0 с движком 48592b36 (AC-073…AC-096: четыре override'а RES-008, диф контракта тегов NFR-072, миграция filterProperty)](2026-11-18-writer-sync-470-qa-report.md) — accept
- [QA Report — writer 4.8.0 хвосты волны 4.7.0 (AC-097…AC-103: служебная синтаксика, негативный перечень, HTML-компонент, frontmatter-поля)](2026-11-18-writer-tail-480-qa-report.md) — accept
- [Отчёт ночной сессии вычитки и ревью проекта (2026-11-19)](2026-11-19-night-review-report.md) — 2 фикса на месте, 5 классов предметов владельцу, гейты зелёные до/после
- [QA Report — прибор рендер-проб Playwright: первый --full после подключения сюиты render-quality (шаг 18); shellcheck SC2034×2 + SC2059×3, класс NEW, вердикт fix-first](2026-11-21-playwright-render-quality-qa-report.md)
- [QA Report qa-057 — волна-2 render-quality: полный гейт --full на f8af038; единственный красный — ac-128 нога (д), артефакт закрытия волны ещё не написан; вердикт — закрытие без возврата в Dev](2026-11-21-qa-057-render-quality-wave2-full-gate.md)
- [QA Report qa-057 — волна-3 (релиз 4.10.0): два полных прогона check.sh --full (красный на 7d8001c, зелёный на 07c05c0); оба отказа тестовые (ac-134, ac-105), класс test-adaptation; вердикт — pass](2026-11-23-wave3-qa-report.md)
- [QA-отчёт волны-4 (релиз 4.11.0): три полных прогона check.sh --full (красный на 09deb46 с изменениями трека — ac-003 test-adaptation, закрыт 2e9c86b; красный после фикса — только ac-191/192, красный по замыслу; зелёный релизный на 3a0166b — rc=0, ac-191/192 закрыт статусами FR-243); вердикт — pass](2026-11-24-wave4-qa-report.md)
