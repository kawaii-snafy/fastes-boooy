#!/usr/bin/env python3
"""tools/gen_confirm_list.py -- the "confirm in game" list of the guides module (docs/dev/PLAN.md D.6 step 5).

Collects every `-- CONFIRM` comment of addons/FastesBoooy_Guides (segments, race files, class files) with the
step id it belongs to (the step on the comment line, or the first step after a comment block) and prints
docs/routes/confirm-in-game.md (Russian frame, the comment text as written):

    python3 -I tools/gen_confirm_list.py > docs/routes/confirm-in-game.md
"""
import os, re, sys
root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
G = os.path.join(root, "addons/FastesBoooy_Guides")
order = []
for sub in ("Segments/Durotar", "Segments/Mulgore", "Segments/Tirisfal", "Segments/Zephras", "Segments/Shared", "Races", "Classes"):
    d = os.path.join(G, sub)
    for f in sorted(os.listdir(d)):
        if f.endswith(".lua"):
            order.append(os.path.join(sub, f))
idre = re.compile(r'\bid = "([^"]+)"')
COMMENT = re.compile(r"^\s*--\s?(.*)$")


def paragraph(lines, i):
    """The comment paragraph around line i (own-line comments, no ruler, no empty comment line)."""
    def text(k):
        m = COMMENT.match(lines[k])
        if not m or re.match(r"^-{5,}", m.group(1).strip()) or not m.group(1).strip():
            return None
        return m.group(1).strip()
    a = i
    while a > 0 and text(a - 1) is not None:
        a -= 1
    b = i + 1
    while b < len(lines) and text(b) is not None:
        b += 1
    return a, b, " ".join(text(k) for k in range(a, b))


def item_text(par, header):
    """The sentences with CONFIRM; for a file header also the sentence before the first (its subject)."""
    sentences = re.split(r"(?<=[.;])\s+(?=[A-Z(`])", par)
    hits = [k for k, t in enumerate(sentences) if "CONFIRM" in t]
    first = max(0, hits[0] - 1) if header else hits[0]
    t = " ".join(sentences[first:hits[-1] + 1]).strip()
    if t.startswith("CONFIRM"):
        t = re.sub(r"^CONFIRM\s*:?\s*", "", t)
        t = t[:1].upper() + t[1:]
    return t


out = []
for rel in order:
    lines = open(os.path.join(G, rel), encoding="utf-8").read().split("\n")
    items = []
    i = 0
    while i < len(lines):
        ln = lines[i]
        if "CONFIRM" not in ln or "--" not in ln:
            i += 1
            continue
        code = ln[:ln.index("--")]
        step = None
        if code.strip():  # trailing comment on a step line
            m2, k = idre.search(code), i
            while not m2 and k > 0 and k > i - 4:
                k -= 1
                m2 = idre.search(lines[k])
            step = m2.group(1) if m2 else None
            text = re.sub(r"^\s*CONFIRM\s*:?\s*", "", ln[ln.index("--") + 2:])
            j = i + 1
        else:
            a, j, par = paragraph(lines, i)
            inside = ln.startswith("    ")  # inside an insert / segment: the comment is about the next step
            text = item_text(par, not inside)
            if inside:
                for k in range(j, min(j + 12, len(lines))):
                    m2 = idre.search(lines[k])
                    if m2:
                        step = m2.group(1)
                        break
                    m3 = re.search(r'\bid = \w+ \.\. "([^"]+)"', lines[k])
                    if m3:
                        step = "…" + m3.group(1)
                        break
        if "CONFIRM above" not in text:
            items.append((i + 1, step, text.strip()))
        i = j
    if items:
        out.append((rel, items))
n = sum(len(x[1]) for x in out)
print("# Что подтверждается только в игре (`-- CONFIRM`)\n")
print("Сгенерировано из комментариев `-- CONFIRM` модуля `addons/FastesBoooy_Guides` (фаза R, %d пунктов). Текст пунктов —" % n)
print("комментарии кода как есть (английский). Подтвердили пункт в игре — уберите `CONFIRM` из комментария (и, если пункт")
print("держится на поправке БД, поставьте ей `verified = true` в `tools/overrides/*.lua`); не подтвердился — исправьте шаг.")
print("Пересобрать список: `python3 -I tools/gen_confirm_list.py > docs/routes/confirm-in-game.md`.\n")
print("Общие вопросы плана (E.1-E.22: полёт таурена и скайборна в Оргриммар, тренеры паладина, таймер 812, опыт новых")
print("квестов Forever, цена верховой езды) — `docs/dev/PLAN.md`, раздел E; что проверяется только в игре в самом аддоне —")
print("конец [docs/VALIDATION.md](../VALIDATION.md).\n")
for rel, items in out:
    print("## `%s`\n" % rel)
    print("| Строка | Шаг | Что проверить |")
    print("|---|---|---|")
    for line, step, text in items:
        print("| %d | %s | %s |" % (line, ("`%s`" % step) if step else "заголовок файла", text.replace("|", "\\|")))
    print()
