# tests/gramax/comments/ — контур комментариев волны-3 (`validate_comments.py`, `parse_comments.py`, навыки comments-*)
Suite тест-дизайна волны-3 (QA-author, до реализации Dev — TDD-цепочка BR-025): AC-129…AC-130,
AC-139 и comments-нога FR-212/FR-216 требования
`docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`.
Дизайн: `docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md` (§6 — границы);
ADR: `docs/00-project/adr/0026-validator-contracts-engine-pin.md` (Решение 6 — UTF-8).

Стартовое состояние — red on 7553da1 (2026-11-23): каждый стаб падает на именованном
ассерте, причина красного — в шапке стаба и в at-design
`docs/60-implementation/acceptance/2026-11-23-wave3-plugin-at-design.md`.

| Тест | AC | Ассерт | Цвет при создании |
|---|---|---|---|
| ac-129-multiposition-id.sh | AC-129 (FR-210) | ID в двух позициях md — не ошибка, ID показан (info), `--strict` не эскалирует; негатив: невалидный формат ID остаётся ошибкой | 🔴 КРАСНЫЙ (validate_comments ставит «duplicate comment id») |
| ac-130-xml-block-form.sh | AC-130 (FR-211) | XML-блочная форма `<comment id="ID"/>` + текст + `</comment>`: parse_comments выводит якорь, validate_comments видит парность; скобочная legacy читается (контроль); навыки называют XML-форму каноном | 🔴 КРАСНЫЙ (регексы требуют «>» сразу после id; навыки знают только скобочную) |
| ac-132-comments-utf8-skip.sh | AC-133 (FR-212, комментарии) | битый UTF-8: validate_comments — E036 на битый .md и битый .comments.yaml (по одной), без traceback, обход полный; parse_comments — предупреждение на stderr, rc=0 | 🔴 КРАСНЫЙ (UnicodeDecodeError, обрыв обхода) |
| ac-139-reply-user-id.sh | AC-139 (FR-218) | ответ без user.id → warning, называющий user.id; обе формы пустых answers проходят (контроль); шаблон ответа comments-write несёт id=mail; дубликаты ответов ловятся (регресс) | 🔴 КРАСНЫЙ (тишина на missing user.id; шаблон без id) |
| ac-144-comments-illustrations-not-markup.sh | FR-216 → порог AC-144 (comments-нога; сам шаг гейта — ADR-0027, не здесь) | иллюстрации синтаксиса в inline-коде и fenced-блоке — не находки; тег, разорванный переносом строки, — находка «тег разорван», не ложный ID | 🔴 КРАСНЫЙ (DOTALL-мост через переносы, код не маскируется — beads gramax-4jf.13) |

Номер `ac-144` — привязка к гейт-порогу «0 ERROR validate_comments на docs/» (FR-220),
которому питает эта нога; шаг гейта — предмет ADR-0027, у стаба здесь не живёт.

## Запуск

    bash tests/gramax/comments/run.sh                          # весь suite (красный до цикла Dev — норма TDD)
    bash tests/gramax/comments/ac-130-xml-block-form.sh        # одиночный тест

Фикстуры — `fixtures/ac-*/` (page.md + page.comments.yaml парами; `ac-132-utf8` содержит
байты с оборванным 0xd0 — бинарная фикстура). Suite НЕ подключён к `scripts/check-gramax.sh` —
подключение делает шаг гейта волны (AC-144), не QA-author.
