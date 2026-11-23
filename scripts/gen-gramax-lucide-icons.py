#!/usr/bin/env python3
"""gen-gramax-lucide-icons.py — сборка реестра кодов иконок `gramax-lucide-icons.json`.

Инструмент сопровождения репозитория (в payload плагина не входит, дизайн волны-3 §3):
пересобирает `plugins/gramax/gramax-lucide-icons.json` — реестр встроенных кодов иконок
для W035 (ADR-0026 Решение 3, FR-215). Два входа, оба ЗАКРЕПЛЕНЫ за пином движка:

  1. tarball `lucide-react` версии движка — из bun.lock движка; контроль целостности —
     base64(SHA-512) архива, сверяется с константой ШАГА 1 ниже;
  2. файл движка `core/components/Atoms/Icon/customIcons.tsx` на пине (blob фиксируется
     ADR-0026; на 48592b36 — `5f40c5ab2a904d52b1da30d764f23fcee9cdeb58`).

Использование:
    python3 scripts/gen-gramax-lucide-icons.py <lucide-react-VER.tgz> <customIcons.tsx> [out.json]

out.json по умолчанию — `plugins/gramax/gramax-lucide-icons.json` рядом с payload плагина.
Ключи собираются ТЕКСТОВО (регэкспы R1–R3 дословно — дизайн §3), без import/exec чужого кода.
Скрипт печатает две контрольные строки вида `lucide <N> <sha256>` / `engineCustom <N> <sha256>`
(дайджест — SHA-256 от UTF-8-текста «имена через LF плюс завершающий LF»); значения для
пина 48592b36 зафиксированы в ADR-0026 «Целевые значения контрактов» и в дизайне §3
«Контрольные значения».

Пересборка при смене пина движка (дизайн §3 «Пересборка»): обновите три константы ниже
(версия пакета, контрольная сумма из bun.lock, короткий хэш пина), прогоните скрипт,
свежие дайджесты зафиксируйте в ADR (целевые значения) тем же коммитом, что и JSON,
а смену состава реестра объявите строкой `Contract:` в `plugins/gramax/CHANGELOG.md`.
Stdlib only — сетевых вызовов нет, tarball читается потоково без распаковки на диск.
"""

import base64
import hashlib
import json
import re
import sys
import tarfile
from pathlib import Path

# ===== Закреплённые источники (пин движка 48592b36) ==================================

LUCIDE_REACT_VERSION = "0.525.0"
ENGINE_PIN = "48592b36"
# bun.lock движка:3155 — base64 от SHA-512 архива lucide-react-0.525.0.tgz
SHA512_B64 = (
    "Tm1txJ2OkymCGkvwoHt33Y2JpN5xucVq1slHcgE6Lk0WjDfjgKWor5CdVER8U6DvcfMwh4M8XxmpTiyzfmfDYQ=="
)
DTS_MEMBER = "package/dynamicIconImports.d.ts"

# Регулярные выражения дословно (дизайн волны-3 §3)
LUCIDE_KEY_RE = re.compile(
    r"^\s+(?:'([a-z0-9]+(?:-[a-z0-9]+)*)'|([a-z][a-z0-9]*)):\s*\(\) => Promise<typeof __icons_[a-z0-9_]+>;\s*$"
)
CUSTOM_KEY_RE = re.compile(r'^\t(?:"([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)"|([A-Za-z][A-Za-z0-9]*)):\s*\(')
KEY_SHAPE_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

DEFAULT_OUT = Path(__file__).resolve().parent.parent / "plugins" / "gramax" / "gramax-lucide-icons.json"


def die(msg: str) -> None:
    print(f"gen-gramax-lucide-icons: {msg}", file=sys.stderr)
    sys.exit(2)


def extract_dts(tgz_path: Path) -> str:
    """Достаёт `package/dynamicIconImports.d.ts` из tarball потоково (без распаковки)."""
    with tarfile.open(tgz_path, "r:gz") as tar:
        member = None
        for candidate in tar.getmembers():
            if candidate.name == DTS_MEMBER:
                member = candidate
                break
        if member is None or not member.isfile():
            die(f"в tarball нет файла {DTS_MEMBER}")
        fh = tar.extractfile(member)
        if fh is None:
            die(f"файл {DTS_MEMBER} нечитаем")
        return fh.read().decode("utf-8")


def collect_keys(text: str, start_marker: str, end_marker: str, pattern: re.Pattern) -> list[str]:
    """Строки блока от start_marker до первой строки end_marker, подошедшие под pattern."""
    keys: list[str] = []
    started = False
    for line in text.splitlines():
        if not started:
            started = line.startswith(start_marker)
            continue
        if line.startswith(end_marker):
            break
        m = pattern.match(line)
        if m:
            keys.append(m.group(1) or m.group(2))
    return keys


def digest_list(names: list[str]) -> str:
    """SHA-256 от UTF-8-текста «имена через LF плюс завершающий LF» (дизайн §3)."""
    return hashlib.sha256(("\n".join(names) + "\n").encode("utf-8")).hexdigest()


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print("usage: gen-gramax-lucide-icons.py <lucide-react-VER.tgz> <customIcons.tsx> [out.json]",
              file=sys.stderr)
        return 2
    tgz_path = Path(sys.argv[1])
    custom_path = Path(sys.argv[2])
    out_path = Path(sys.argv[3]) if len(sys.argv) == 4 else DEFAULT_OUT
    if not tgz_path.is_file():
        die(f"tarball не найден: {tgz_path}")
    if not custom_path.is_file():
        die(f"исходник движка не найден: {custom_path}")

    # Шаг 1: контроль целостности tarball по bun.lock движка
    sha512_b64 = hashlib.sha512(tgz_path.read_bytes()).digest()
    actual = base64.b64encode(sha512_b64).decode("ascii")
    if actual != SHA512_B64:
        die(f"SHA-512 tarball не совпал с контрольной суммой bun.lock (пин {ENGINE_PIN}): {actual}")

    # Шаги 2–4: ключи dynamicIconImports и customIcons текстово, дедупликация, сортировка
    lucide = sorted(set(collect_keys(extract_dts(tgz_path), "declare const dynamicIconImports", "};", LUCIDE_KEY_RE)))
    custom = sorted(set(collect_keys(custom_path.read_text(encoding="utf-8"), "const customIcons = {", "};", CUSTOM_KEY_RE)))
    for name in lucide + custom:
        if not KEY_SHAPE_RE.match(name):
            die(f"имя кода вне формы R3 (голый kebab-case): {name!r}")

    # Шаг 5: JSON с порядком ключей схемы, отступ 2, без ASCII-эскейпов, LF в конце
    registry = {
        "schemaVersion": 1,
        "source": {"lucideReact": LUCIDE_REACT_VERSION, "enginePin": ENGINE_PIN},
        "lucide": lucide,
        "engineCustom": custom,
    }
    out_path.write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"written {out_path}")
    print(f"lucide {len(lucide)} {digest_list(lucide)}")
    print(f"engineCustom {len(custom)} {digest_list(custom)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
