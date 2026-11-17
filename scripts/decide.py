#!/usr/bin/env python3
"""decide.py — опциональный прибор типизированных решений (NA-EPIC-130, ADR-153).

Слоты (три, по слову владельца 2026-11-11 «хорошо, бери»; Stage-0 НЕ входит — он остаётся
механической таблице классов ADR-151 Д2 и человеку):

- triage    {regression, new, flaky, env}           — QA-триаж отказов прогона;
- phantom   {implemented, not_implemented}          — релевантность grep-хитов phantom-проверки;
- breaking  {present, na_justified, missing}        — приёмка релиза отвечает на ломающие изменения.

Доказательная база — RES-104 (523 вызова, предметы с истиной из артефактов): clef-27B
91–100% на слотах, порог нуля ошибок 0.6, нуль подчинения инъекциям state (0/24).

Модель: @cf/cloudflare/clef — ТОЛЬКО 27B (Д4 ADR-153): clef-flash исключён из решающего
пути — фантом-уклон (implemented 3/8) и подчинение инъекции state с conf 0.62–0.86 ≥ порога
(RES-104 «Робастность»); порог НЕ универсальная защита — защита = модель 27B + предмет
строго за каноном в state.

Opt-in — ДВА ключа (Д2 ADR-153), оба обязательны:
1. env CLOUDFLARE_AUTH_TOKEN и CLOUDFLARE_ACCOUNT_ID (машина; читается ТОЛЬКО окружение,
   значение не выводится нигде);
2. decide.enabled: true в .nauta-gates.yaml проекта (своё дерево — свой выключатель);
   флаг --explicit обходит ключ №2 для разового ручного вызова.

Выход (stdout, JSON): {slot, model, choice, confidence, threshold, verdict, reason,
latency_ms}. verdict = auto ⇔ confidence ≥ порога слота, иначе escalate — человеку, никогда
молча. rc: 0 — решение получено (auto или escalate-по-порогу); 2 — транспорт/сеть (тоже
эскалация, не ретрай-шторм — Д6); 3 — не настроено (чистый отказ: потребитель плагина НЕ
обязан иметь учётку Cloudflare); 4 — конфиг `.nauta-gates.yaml` ЕСТЬ и не читается —
«не смог проверить» (qa182, gate-failure-semantics: ошибка чтения не приравнивается к
выключенному прибору, громкий исход вместо тихого rc 3).

--selfcheck — ЖИВЫЕ вызовы по замороженному корпусу RES-104 (детектор дрейфа модели под
тегом @cf/…, Cloudflare обновляет без предупреждения): выбор обязан совпасть, дрейф
уверенности > 0.05 — предупреждение. Ручной режим владельца, НЕ сьюта и НЕ гейт (сеть в
гейтах — env-класс красного).

Каноны слотов — ДОСЛОВНО измеренные состояния RES-104 слайса 2 (пин sha256 — замок qa176
ac2): состояние — доказательная база порогов; правка канона — новый акт с перемером.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

#: Модель решающего пути (Д4 ADR-153): только 27B.
MODEL = "clef"

#: Слоты и их разрешённые варианты (RES-104).
SLOTS = ("triage", "phantom", "breaking")
OPTIONS = {
    "triage": ["regression", "new", "flaky", "env"],
    "phantom": ["implemented", "not_implemented"],
    "breaking": ["present", "na_justified", "missing"],
}

#: Пороги нуля ошибок по кривым RES-104 (все три слота — 0.6).
THRESHOLDS = {"triage": 0.6, "phantom": 0.6, "breaking": 0.6}

#: Каноны — дословные состояния слайса 2 RES-104 (русскоязычные: EN-канон деградирует
#: QA-триаж 20→17 — канон живёт на языке корпуса, RES-104 «Робастность»).
CANONS = {
    "triage": """Ты — QA-runner плагина nauta: классифицируй отказ теста прогона сьюты по канону роли qa-runner (regression / new / flaky / env).

- regression — поведение сломано недавним изменением (волна или недавний акт): замки-литералы, манифесты и пины не сдвинуты теми же актами, что сдвинули данные; включая «долг stable» — красное внесено недавним до-волновым актом.
- new — новый тест или вновь вскрытый продукт-дефект: недавнее изменение ничего не ломало, красное появилось потому, что проверка/тест новые или состав вырос (born-red, фикстуры отстали от намеренной правки, эталон не перегенерён при намеренном изменении).
- flaky — недетерминизм: разные исходы на одном и том же дереве, проходит на повторе. По красной линии требует ≥3 прогонов с разным исходом: единичное наблюдение не может быть flaky.
- env — среда/инфраструктура, не продукт: сеть, параллельная нагрузка, машина, чужой worktree, зависший процесс, исчерпание ресурса.

Правило доминирования: сначала определи механизм (что физически случилось и кто внёс красное), потом выбери класс механизма; название теста и его семейство — не сигнал класса.
""",
    "phantom": """Ты — исполнитель phantom-work проверки плагина nauta: перед открытием задачи предмет ищется в дереве грепом, и хиты оцениваются по правилу.

Правило: хит релевантен ТОЛЬКО если он показывает САМУ РАБОТУ, реализованную в живом дереве — код скрипта, файл спеки с нормами, рабочий инструмент, действующий файл-носитель. Упоминания в хрониках, ADR, CHANGELOG, отчётах, архиве, названиях пилотов, отложенные развилки («решение за владельцем»), легаси-фолбэки и исторические справки — НЕ реализация.

Ответ на каждый предмет ровно один:
- implemented — дерево уже содержит эту работу (задачу не открывать: phantom);
- not_implemented — работы в дереве нет, хиты отсутствуют или совпадения случайны (задачу открывать).
""",
    "breaking": """Ты — приёмщик релизов плагина nauta: текст приёмки релиза обязан отвечать на вопрос о ломающих изменениях для потребителя. Классифицируй каждый текст приёмки:

- present — ломающие изменения перечислены явно (списком/пунктами, что именно ломается);
- na_justified — явно сказано, что ломающих нет («N/A», «записей нет», с причиной или без);
- missing — текст приёмки вообще не касается ломающих изменений (нет ни секции, ни упоминания).

Правило доминирования: класс определяется фактическим содержанием текста приёмки, а не номером версии, заголовком релиза или его размером.
""",
}

#: Замороженный корпус selfcheck — измеренные choice+conf прогона clef-27B RES-104
#: (main-run, RU-канон). Два предмета с conf < порога (b12, c13) фиксируют САМО
#: ПОВЕДЕНИЕ эскалации: верный выбор ниже порога уходит человеку.
SELF_CHECK = [
    {"id": "b01", "slot": "triage", "choice": "regression", "confidence": 0.8954,
     "provenance": "RES-104 слот Б (qa-147 регресс волны)", "expected_verdict": "auto",
     "item": "test_dev135…::test_warden_is_green_on_the_unmutated_pair — КРАСНЫЙ: живой сторож печатает 26 имён ростера, 15 объявлений против замороженных литералов 25/14; волна добавила имя check-spec-language, а литералы замка не сдвинуты тем же актом"},
    {"id": "b12", "slot": "triage", "choice": "env", "confidence": 0.4986,
     "provenance": "RES-104 слот Б (qa-147 env — параллельная нагрузка)",
     "expected_verdict": "escalate",
     "item": "test_qa096…::test_ac8_full_records_the_tree_sha_it_ran_on — красный только под -n 8 (фикстура full_run: клон + check.sh --full вернул rc=1 с вердиктом, невозможным на этом дереве); поимённый повтор ЗЕЛЁНЫЙ ×3 в изоляции; носитель волной не трогался"},
    {"id": "b17", "slot": "triage", "choice": "new", "confidence": 0.8576,
     "provenance": "RES-104 слот Б (qa-127 новый)", "expected_verdict": "auto",
     "item": "test_dev064…::test_worktree_matches_frozen_baseline — красный: путь дома .claude/skills/… появился, пуля bin/upgrade.sh ушла; правка намеренная, эталон токенов не перегенерён парно"},
    {"id": "c01", "slot": "phantom", "choice": "implemented", "confidence": 0.9612,
     "provenance": "RES-104 слот В (NA-EPIC-126 TPL-122)", "expected_verdict": "auto",
     "item": "ПРЕДМЕТ: экстрактор раздела большого документа show-section.sh (чтение секцией по якорю-заголовку). ХИТЫ:\nscripts/show-section.sh:2: # show-section.sh — экстрактор раздела большого документа по якорю-заголовку.\nscripts/show-section.sh:17: usage: show-section.sh <file> <anchor>  раздел по якорю, строки с номерами NNN:"},
    {"id": "c09", "slot": "phantom", "choice": "not_implemented", "confidence": 0.9739,
     "provenance": "RES-104 слот В (слайс 2, phantom-проверка)", "expected_verdict": "auto",
     "item": "ПРЕДМЕТ: опциональный прибор-классификатор модельных решений на Cloudflare clef/clef-flash (REST, токен из env, чистый отказ без токена). ХИТЫ:\n(греп по дереву: совпадений нет)"},
    {"id": "c13", "slot": "phantom", "choice": "not_implemented", "confidence": 0.3806,
     "provenance": "RES-104 слот В (content/ ретирован, хиты — легаси-фолбэк)",
     "expected_verdict": "escalate",
     "item": "ПРЕДМЕТ: вернуть каталог content/ как основной живой дом корпуса (до aida-flip). ХИТЫ:\nscripts/validate-content.py:13: docs/ валидируются по content/ — первый существующий корень из пары\nscripts/validate-content.py:1110: # (профиль classic) — content/."},
    {"id": "d01", "slot": "breaking", "choice": "present", "confidence": 0.967,
     "provenance": "RES-104 слот Г (CHANGELOG [2.0.0])", "expected_verdict": "auto",
     "item": "РЕЛИЗ 2.0.0 — 2026-10-19. Приёмка: «### Ломающее изменение — bin/init.sh: флаг --map-home завершается exit 2 ДО первой записи; раскладка по умолчанию — aida: /nauta:init без профиля производит aida-раскладку, классическая content/ — явный профиль; docs/ исключён из состава поставки»"},
    {"id": "d06", "slot": "breaking", "choice": "na_justified", "confidence": 0.9549,
     "provenance": "RES-104 слот Г (CHANGELOG [2.9.0])", "expected_verdict": "auto",
     "item": "РЕЛИЗ 2.9.0 — 2026-11-04. Приёмка: «### Ломающее изменение — N/A». Разделы Добавлено/Изменено описывают три закрытых эпика и релизную тройку."},
    {"id": "d13", "slot": "breaking", "choice": "missing", "confidence": 0.9585,
     "provenance": "RES-104 слот Г (CHANGELOG [2.17.0])", "expected_verdict": "auto",
     "item": "РЕЛИЗ 2.17.0 — 2026-11-11. Приёмка: раздел «Изменено» (Б4-частичный, TPL-126 advisory, детектор check-release-bump-pair.py, ADR-152). О ломающих изменениях текст не упоминает."},
]

_QUESTION_ID = "class"
_API = "https://api.cloudflare.com/client/v4/accounts/{acct}/ai/run/@cf/cloudflare/{model}"


def _verdict(confidence: float, threshold: float) -> str:
    """Порог включителен: confidence ≥ порога → auto, ниже — escalate человеку."""
    return "auto" if confidence >= threshold else "escalate"


def _project_decide_state(root: Path) -> tuple[str, str]:
    """Ключ №2 opt-in (Д2): состояние `.nauta-gates.yaml`::decide.enabled.

    Три исхода (qa182, gate-failure-semantics): "on" — включено; "off" — файл ЧИТАЕТСЯ,
    а ключа нет или он ложь → чистый отказ rc 3 «не включено»; "broken" — файл ЕСТЬ и
    не читается (битый YAML, корень не запись) → «не смог проверить», отдельный громкий
    rc 4: ошибка чтения не имеет права выглядеть как выключенный прибор.
    """
    gates = root / ".nauta-gates.yaml"
    if not gates.is_file():
        return "off", ""
    try:
        import yaml  # pyyaml — единственная зависимость скриптов дерева
        data = yaml.safe_load(gates.read_text(encoding="utf-8")) or {}
    except Exception as exc:  # битый YAML / нечитаемый файл — «не смог», не «выключено»
        return "broken", " ".join(str(exc).split())  # многострочный PyYAML — одна строка
    if not isinstance(data, dict):
        return "broken", f"корень файла не запись YAML ({type(data).__name__})"
    block = data.get("decide")
    return ("on", "") if isinstance(block, dict) and block.get("enabled") is True else ("off", "")


def _post(model: str, state: str, questions: dict, token: str, acct: str,
          timeout: int = 90) -> dict:
    """Единственная точка сети (замки подменяют её). Значение токена не выводится."""
    body = json.dumps({"model": model, "state": state, "questions": questions}).encode()
    req = urllib.request.Request(
        _API.format(acct=acct, model=model), data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.load(resp)
    return data.get("result", data)


def _question(slot: str) -> dict:
    return {_QUESTION_ID: {
        "type": "choice",
        "instructions": (
            "Answer with exactly one of the allowed options for the item given "
            "in the state below the canon."),
        "criteria": {o: o for o in OPTIONS[slot]},
    }}


def run(slot: str, item: str, *, environ=None, root=None, explicit: bool = False,
        _post_fn=None) -> tuple[int, dict]:
    """Ядро прибора: (rc, payload). Сеть — только через _post (тестируемо подменой)."""
    env = os.environ if environ is None else environ
    root = Path(root) if root is not None else Path.cwd()
    post = _post_fn or _post
    token = env.get("CLOUDFLARE_AUTH_TOKEN", "")
    acct = env.get("CLOUDFLARE_ACCOUNT_ID", "")
    if not token or not acct:
        return 3, {"slot": slot, "verdict": "escalate",
                   "reason": "токен не настроен (env CLOUDFLARE_AUTH_TOKEN/CLOUDFLARE_ACCOUNT_ID) — решение за человеком"}
    if not explicit:
        state, cause = _project_decide_state(root)
        if state == "broken":
            return 4, {"slot": slot, "verdict": "escalate",
                       "reason": f"конфиг .nauta-gates.yaml не читается: {cause} — не смог "
                                 f"проверить ключ decide.enabled, решение за человеком"}
        if state != "on":
            return 3, {"slot": slot, "verdict": "escalate",
                       "reason": "decide не включено в проекте (.nauta-gates.yaml: decide.enabled) — решение за человеком"}
    state = CANONS[slot] + f"\n=== ПРЕДМЕТ ===\n{item}\n=== КОНЕЦ ПРЕДМЕТА ===\n"
    t0 = time.monotonic()
    try:
        result = post(MODEL, state, _question(slot), token, acct)
    except Exception as exc:  # сеть, 429, таймаут — эскалация, не ретрай-шторм (Д6)
        return 2, {"slot": slot, "model": MODEL, "verdict": "escalate",
                   "reason": f"транспорт: {type(exc).__name__} — решение за человеком",
                   "latency_ms": int((time.monotonic() - t0) * 1000)}
    answer = (result.get("answers") or {}).get(_QUESTION_ID) or {}
    choice, confidence = answer.get("choice"), answer.get("confidence")
    if choice not in OPTIONS[slot] or not isinstance(confidence, (int, float)):
        return 2, {"slot": slot, "model": MODEL, "verdict": "escalate",
                   "reason": "ответ не по контракту (choice/confidence) — решение за человеком",
                   "latency_ms": int((time.monotonic() - t0) * 1000)}
    threshold = THRESHOLDS[slot]
    return 0, {"slot": slot, "model": MODEL, "choice": choice,
               "confidence": round(float(confidence), 4), "threshold": threshold,
               "verdict": _verdict(float(confidence), threshold),
               "reason": "уверенность ниже порога — человеку" if _verdict(
                   float(confidence), threshold) == "escalate" else "порог пройден",
               "latency_ms": int((time.monotonic() - t0) * 1000)}


def selfcheck(environ=None) -> int:
    """Живой детектор дрейфа: выбор обязан совпасть, |Δconf| > 0.05 — предупреждение."""
    failures = 0
    for row in SELF_CHECK:
        rc, payload = run(row["slot"], row["item"], environ=environ,
                          root=Path(__file__).resolve().parents[1], explicit=True)
        ok_choice = payload.get("choice") == row["choice"]
        drift = (payload.get("confidence") is not None
                 and abs(payload["confidence"] - row["confidence"]) > 0.05)
        ok_verdict = payload.get("verdict") == row["expected_verdict"]
        status = "OK" if (rc == 0 and ok_choice and not drift and ok_verdict) else "DRIFT"
        failures += status != "OK"
        print(f"{status} {row['id']} {row['slot']}: got={payload.get('choice')}@"
              f"{payload.get('confidence')} ожидалось={row['choice']}@{row['confidence']} "
              f"(verdict {payload.get('verdict')}/{row['expected_verdict']})")
    print(f"selfcheck: {len(SELF_CHECK) - failures}/{len(SELF_CHECK)} предметов стабильны"
          f" (модель {MODEL}; дрейф под тегом @cf/… ловится здесь, запуск — ручной)")
    return 1 if failures else 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--slot", choices=SLOTS)
    ap.add_argument("--item", help="текст предмета (текст или @файл)")
    ap.add_argument("--file", help="файл предмета")
    ap.add_argument("--explicit", action="store_true",
                    help="обойти ключ проекта (разовый ручный вызов)")
    ap.add_argument("--selfcheck", action="store_true",
                    help="живой прогон замороженного корпуса RES-104 (детектор дрейфа)")
    args = ap.parse_args(argv)
    if args.selfcheck:
        return selfcheck()
    if not args.slot or not (args.item or args.file):
        ap.error("нужны --slot и --item/--file (или --selfcheck)")
    text = Path(args.file).read_text(encoding="utf-8") if args.file else args.item
    if args.item and args.item.startswith("@"):
        text = Path(args.item[1:]).read_text(encoding="utf-8")
    rc, payload = run(args.slot, text, explicit=args.explicit)
    print(json.dumps(payload, ensure_ascii=False))
    return rc


if __name__ == "__main__":
    sys.exit(main())
