# Suite: plantuml-bpmn — авторство PlantUML/BPMN-диаграмм

Failing-stub suite (QA-author) по требованию
`docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md` (AC-051…AC-062,
FR-141…FR-148) и дизайну `docs/40-architecture/2026-11-18-plantuml-bpmn-design.md`
(раздел «Контракт с QA-author»), размещение — ADR-0023.

**Статус:** реализация существует с 4.7.0 (`plugins/gramax/skills/plantuml/`, волна
2026-11-18); suite зелёный, подключён к `--full` (шаг `plantuml-bpmn`). Детали — `at-design.md`.

## Запуск

```bash
bash tests/gramax/plantuml-bpmn/run.sh          # агрегатор (шаг --full `plantuml-bpmn`)
bash tests/gramax/plantuml-bpmn/ac-051-*.sh     # каждый stub — standalone из корня репо
```

Suite подключён к `--full` шагом `plantuml-bpmn` в `scripts/check-gramax.sh`.

## Проверки

| AC | Файл | Уровень (ADR-0011) | Красная причина на 9355b69 |
|----|------|--------------------|-----------------------------|
| AC-051 | `ac-051-puml-created-next-to-page.sh` | integration | навык отсутствует |
| AC-052 | `ac-052-puml-pure-plantuml-content.sh` | integration | навык отсутствует (механика литералы исполнена на фикстуре) |
| AC-053 | `ac-053-article-embeds-plant-uml-tag.sh` | integration | навык отсутствует |
| AC-054 | `ac-054-salt-mockup-same-puml-path.sh` | integration | навык отсутствует |
| AC-055 | `ac-055-bpmn-camunda-xml-authored.sh` | integration | навык отсутствует (механика литералы исполнена на синтетике) |
| AC-056 | `ac-056-article-embeds-bpmn-tag.sh` | integration | навык отсутствует |
| AC-057 | `ac-057-no-conversion-scripts-invariant.sh` | integration | секция «Стоп-правило» не написана; warden-половина (нулевая счётчик скриптов) зелёная по рождению |
| AC-058 | `ac-058-plantuml-bpmn-trigger-keys.sh` | integration | навык отсутствует |
| AC-059 | `ac-059-mermaid-boundary-preserved.sh` | integration | fallback-контракт mermaid не реализован (5 ассертов); warden-половина (запрет литералов) зелёная по рождению |
| AC-060 | `ac-060-overwrite-requires-consent.sh` | integration | навык отсутствует (поведенческий smoke — qa-runner) |
| AC-061 | `ac-061-inline-not-silently-migrated.sh` | integration | навык отсутствует (поведенческий smoke — qa-runner) |
| AC-062 | `ac-062-composite-gate-fast-green.sh` | e2e | guard: предмет suite отсутствует — композитный гейт не принимается |

## Фикстуры (`fixtures/doc-root/`)

Состав задан дизайном («Контракт с QA-author», список фикстур): scratch-каталог с
`.doc-root.yaml`; статья-`_index`-кейс (`process/_index.md`); статья с inline
` ```plant-uml `-блоком с опциями `{title, scale, float}` (`legacy-inline.md`);
существующий `.puml` для коллизии (`overview-component-diagram.puml`, он же образец
чистого PlantUML для механики AC-052). Модель чужого каталога потребителя — гейтами
репозитория не валидируется (прецедент `mermaid-adoption/fixtures`).

## Границы

- Поведенческие половины AC-051…AC-056/AC-060/AC-061 (артефакты живой сессии
  авторства) — шаг qa-runner при приёмке: исполняемой точки входа у навыка нет,
  скрипт-эмулятор запрещён BR-008.
- Runtime-probe `<bpmn>`/Salt в живом окружении — вне suite'а (релизный чек-лист PM,
  дизайн «Открытые вопросы»).
- Достижимость зелёного доказана rehearsal'ом (см. `at-design.md`):
  design-faithful симуляция навыка и правок mermaid/drawio во временном git-репо —
  11/11 статических stub'ов PASS.
