# AGENTS.md — gramax-marketplace

Матрица ролей, контракт вызова субагентов и поток работы для AI-команды проекта.

## Каталог ролей

| Имя | Описание | Где исполняется | Модель | Промпт-файл | Slash-команда |
|-----|----------|-----------------|--------|-------------|---------------|
| pm | Координатор/orchestrator | main | Opus | (main, не subagent) | `/nauta:pm` |
| researcher | Контекст-сборщик | subagent | Sonnet | `nauta:researcher-agent` | `/nauta:research` |
| ba | Бизнес-аналитик | subagent | Sonnet | `nauta:ba-agent` | `/nauta:ba` |
| sa | Архитектор плагина | subagent | Sonnet | `nauta:sa-agent` | `/nauta:sa` |
| dev | TDD-разработчик | subagent | Sonnet | `nauta:dev-agent` | `/nauta:dev` |
| qa | QA author + runner | subagent | Sonnet | `nauta:qa-author-agent`, `nauta:qa-runner-agent` | `/nauta:qa` |
| tech-writer | README, CHANGELOG, descriptions | subagent | Sonnet | `nauta:tech-writer-agent` | `/nauta:tech-writer` |
| devsecops | Secrets/SAST/supply-chain (opt-in) | subagent | Sonnet | `nauta:devsecops-agent` | `/nauta:devsecops` |

**Выключены:** `devops` — плагин не деплоится; `compliance` — compliance-скоупа у публичного
marketplace нет. Включаются явным запросом, если появится основание.

**Почему nauta, а не свои промпты:** локальный плагин `project` дублировал те же роли в более
старых редакциях и при этом не загружался. Источник ролей теперь один.

## Контракт вызова субагента

При запуске любой роли (через `/<command>` или Task tool) передавай:

1. **Цель** одной фразой.
2. **Входные файлы** — пути к контексту (spec, ADR, код плагина, плагин-документация). Субагент сам прочитает.
3. **Ожидаемый артефакт** — какой файл должен появиться/измениться.
4. **Критерии приёмки** — как проверить, что задача выполнена.

**Конвенции передавай в промпте, а не надейся, что агент их прочитает.** Из десяти агентов
nauta только три вообще упоминают `CLAUDE.md`, и то точечно (секции «Стек», «Команды сборки»);
`AGENTS.md` не читает ни один. Целевой путь артефакта, таксономию `content/` и красные линии
включай в текст задачи явно.

Пример корректного prompt'а для `/nauta:dev`:

```
Цель: добавить skill `gramax:diagrams-export` в плагин gramax.
Входы: content/30-requirements/2026-05-09-diagrams-export-design.md,
       plugins/gramax/skills/mermaid/SKILL.md (для стиля),
       tests/gramax/diagrams-export/ac-001-skill-exists.sh (failing stub от qa-author)
Артефакт: plugins/gramax/skills/diagrams-export/SKILL.md
Критерии: suite из tests/gramax/diagrams-export/ зелёный, обновлён plugins/gramax/CHANGELOG.md,
          AC из требования покрыты, bash scripts/check.sh --fast зелёный.
```

Субагент **не ищет контекст «вокруг»** — работает по явно переданному скопу.

Новый подраздел `content/` обязан нести `_index.md` и ссылку на него из родительского
`_index.md` — иначе `check.sh --fast` красный (C1: отсутствие `_index.md` — error;
C10: статья-сирота без входящих ссылок — warning).

(Полные prompt'ы — агенты плагина `nauta`, см. столбец «Промпт-файл» в каталоге ролей выше.)

## Поток работы (канонический порядок)

Researcher (опц.) → BA → SA (для нетривиальных фич) → QA-author (failing stubs) → Dev (TDD) → QA-runner → BA-acceptance gate → Tech-writer (docs).

PM координирует на каждом этапе: приоритизирует, разрешает блокеры, запускает `/nauta:pm-review` перед merge.

## Branch strategy

`main` — единственная trunk-ветка. Feature-ветки опциональны (через worktree из `superpowers:using-git-worktrees`); merge через PR с прошедшим `/nauta:pm-review`.

## Self-improvement

- `content/lessons-learned.md` — append-only журнал.
- Субагенты сохраняют находки в auto-memory (типы: `reference`, `project`, `feedback`).
- `/nauta:pm-review` читает lessons + memory и предлагает обновления `CLAUDE.md` / промтов агентов.

## Красные линии (универсальные)

- НЕ публиковать секреты (`.env`, токены, API-ключи, credentials).
- НЕ включать PII (реальные имена, контакты, персональные данные).
- НЕ менять корневой `.claude-plugin/marketplace.json` (публичный) без ADR.
- НЕ добавлять vendored submodule без ADR (vendored-плагины удаляются через ADR, см. content/00-project/adr/).
- НЕ принимать задачи `/nauta:dev` без артефакта SA для нетривиальных фич.
- НЕ передавать тесты из Dev в qa-runner до прохождения qa-author stub'ов (TDD-цепочка).
- Tests/линтеры (если есть) — зелёные перед commit.

<!-- nauta:managed:begin protocol=1 — блок до строки nauta:managed:end целиком перезаписывается командой /nauta:init: правка внутри него не переживает следующий прогон, свой текст держите снаружи блока. -->

## Каталог ролей

A role prompt is a universal contract **in the plugin** `nauta` that reads the local context
at runtime. The paths of the "Prompt" column live inside the plugin, not in the project
tree; per-project copies of prompts do not exist.

| Role | Command | Prompt (in the plugin) | Zone |
|---|---|---|---|
| researcher | `/nauta:research` | `agents/researcher-agent.md` | Context building: domain, competitors, foreign code. Writes no requirements and no ADRs |
| ba | `/nauta:ba` | `agents/ba-agent.md` | JTBD, FR/NFR, business rules, acceptance criteria |
| sa | `/nauta:sa` | `agents/sa-agent.md` | Components, ADRs, data models, API contracts |
| qa | `/nauta:qa --mode=author`, `--mode=runner` | `agents/qa-author-agent.md`, `agents/qa-runner-agent.md` | Test design before Dev; suite runs and failure classification |
| dev | `/nauta:dev` | `agents/dev-agent.md` | Implementation from the SA architecture via TDD |
| devops | `/nauta:devops` | `agents/devops-agent.md` | Runbook, deploy, monitoring, rollback. Optional |
| tech-writer | `/nauta:tech-writer` | `agents/tech-writer-agent.md` | Presentation for the audience. Does not change the substance |
| devsecops | `/nauta:devsecops` | `agents/devsecops-agent.md` | Secrets, SAST, supply chain. **Opt-in** |
| compliance | `/nauta:compliance` | `agents/compliance-agent.md` | Gap analysis against the **passed** standard. **Opt-in** |

Coordination is held by the main context via `/nauta:pm`; there is no `pm` subagent file —
the human gate is held only by the interactive session. Two roles are enabled by an explicit
decision, not by a guess from the topic: devsecops — in the Dev phase, on secrets, SAST and
supply-chain triggers; compliance — only when a concrete standard is named, it has no
built-in regulations of its own.

## Subagent call contract

Subagent prompts are English and every role thinks in English (Think in English); replies to
the user and `content/` files stay Russian.

Four points are mandatory in every brief:

1. **Goal** in one phrase.
2. **Input files** — paths to the context; the subagent reads them itself and does not search
   "around". One file — one executor for the time of parallel work: the intersection is
   resolved **at task issue** by an interface contract at the boundary, not by
   `git commit --only` discipline after the fact. The precedent is the lesson-journal entry
   of 2026-05-07 (W4c-A) in `nauta`, not a hypothesis.
3. **Expected artefact** — which file must appear or change.
4. **Acceptance criteria** — how to check that the task is done.

The four delegation brief rules live in one home:
`.claude/skills/subagent-delegation-brief/SKILL.md` — keep the pointer, not a copy: the skill
is loaded when a subagent brief is written, and it also carries the model and effort table by
role and the isolation rule echoed below.

**Isolation.** Parallel writing subagents in one tree produce a race: either disjoint file
lists declared in the brief, or a separate worktree for the writer. Reviewers read and work
in parallel with anyone.

## Pipeline catalogue

| Pipeline | Purpose | Command |
|---|---|---|
| project-planning | Epic orchestrator: Researcher → BA → SA → QA-author → Dev → QA-runner → acceptance | `/nauta:pipelines:project-planning <epic>` |
| ba-acceptance | Gate: checks acceptance criteria against the implementation, verdict | `/nauta:pipelines:ba-acceptance <requirement>` |
| critical-path | Epic task dependencies: the critical path | `/nauta:pipelines:critical-path <epic>` |

## Where a role writes

The three-homes rule lives in `CLAUDE.md`. Never written to `content/`: test-report,
acceptance log, round counter, stage status, epic plan, open questions, backlog items.

## Self-improvement

The lesson journal is append-only; artefacts of this class are compacted periodically; the
working sample of the procedure is the header of that very journal.

## Content layout map

<!-- nauta:layout-map:begin -->
The declared documentation layout (`content/`) adapted to this tree by
`/nauta:init` (ADR-128): a pair `content/<home>/ → <address>` maps a declared
home of the scaffold to its actual address in this tree. `content/` paths in
shipped prompts name declared homes and resolve through this map. A home
resolved ambiguously or not found is NOT mapped — `/nauta:init` names it in
its report as unadapted, and a role that needs it stops the step and names the
divergence (no silent assumption). The map is regenerated in full on every
run — re-run `/nauta:init` after moving or renaming homes.

- content/00-project/ → content/00-project
- content/10-domain/ → content/10-domain
- content/30-requirements/ → content/30-requirements
- content/40-architecture/ → content/40-architecture
- content/60-implementation/ → content/60-implementation
- content/70-operations/ → content/70-operations
<!-- nauta:layout-map:end -->

<!-- nauta:managed:end -->
