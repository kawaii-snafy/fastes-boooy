#!/usr/bin/env python3
"""Fetch the objective requirements of World of Warcraft: Forever quests from the Wowhead Forever
tooltip API and write tools/data/wowhead_requirements.json -- the objective-count input of
tools/build_db_snapshot.py (`--requirements`).

Why: the counts of the research inputs are not Forever's. WCLBox `goals` carry Classic-era (and
sometimes inconsistent) counts, QuestieDB's objective text is the Classic text, and Forever-new
quests often have no count at all. The tooltip's "Requirements:" list is what the Forever client
shows (e.g. 545 Dalaran Patrols: "Elemental Slave x 8", Classic 12; 96260 Stronger than Steel:
"Crystalline Silk x 3").

    https://nether.wowhead.com/forever/tooltip/quest/<id>
    -> {"name": ..., "tooltip": "... <span class=\"q\">Requirements:</span><br /> - Elemental Slave x 8<br /> ..."}

Output (deterministic: sorted ids, no timestamps besides the fixed --date):

    {"_meta": {"source": ..., "date": "YYYY-MM-DD", "quests": N, "withRequirements": M},
     "data": {"545": [["Dalaran Summoner", 6], ["Elemental Slave", 8]], "532": [["Magistrate Burnside", null], ...]}}

Each entry is one "Requirements:" line: [name, count] ("Name x N"), count null for a line without
"x N" (one creature / item, or a text objective such as "Hillsbrad Proclamation destroyed").
build_db_snapshot.py matches the names against the quest's creature / killCredit / item objectives
(case-insensitive) and ignores the other lines. Quests whose tooltip has no "Requirements:" list
are stored with an empty list (the research counts stay).

Quest ids: every quest of the current snapshot (--db, default tools/data/forever_db.lua) that has a
creature / killCredit / object / item objective, or the ids of --ids FILE (one per line).
--cache DIR keeps / reuses the raw tooltip JSON (q<id>.json). The tooltip text is data, never code.

    python3 -I tools/fetch_wowhead_requirements.py [--db FILE | --ids FILE] [--cache DIR]
                                                   [--out FILE] [--date YYYY-MM-DD] [--jobs N]
"""
import argparse
import html
import json
import os
import re
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.join(HERE, "data", "forever_db.lua")
DEFAULT_OUT = os.path.join(HERE, "data", "wowhead_requirements.json")
DEFAULT_DATE = "2026-11-08"
URL = "https://nether.wowhead.com/forever/tooltip/quest/%d"


def snapshot_quest_ids(path):
    """Ids of the snapshot's quests[] with a creature / killCredit / object / item objective
    (the generated file has one quest per line inside `quests = {`)."""
    ids = []
    inside = False
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            if not inside:
                if line.startswith("    quests = {"):
                    inside = True
                continue
            if line.startswith("    }"):
                break
            m = re.match(r"\s*\[(\d+)\] = \{name=", line)
            if m and re.search(r"objectives=\{[^}]*\b(creatures|killCredit|objects|items)=", line):
                ids.append(int(m.group(1)))
    return sorted(set(ids))


def parse_requirements(tooltip):
    """[[name, count|None], ...] of the tooltip's "Requirements:" list ([] when it has none)."""
    m = re.search(r"Requirements:</span>(.*?)</td>", tooltip or "", re.S)
    if not m:
        return []
    out = []
    for line in re.split(r"<br\s*/?>", m.group(1)):
        line = html.unescape(re.sub(r"<[^>]+>", "", line)).replace("\xa0", " ").strip()
        if not line.startswith("-"):
            continue
        line = line[1:].strip()
        if not line:
            continue
        mm = re.match(r"^(.*?)\s+x\s+(\d+)$", line)
        if mm:
            out.append([mm.group(1).strip(), int(mm.group(2))])
        else:
            out.append([line, None])
    return out


def fetch(qid, cache):
    path = os.path.join(cache, "q%d.json" % qid) if cache else None
    if path and os.path.isfile(path) and os.path.getsize(path) > 2:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    err = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(URL % qid, timeout=30) as r:
                raw = r.read()
            d = json.loads(raw.decode("utf-8"))
            if path:
                with open(path, "wb") as fh:
                    fh.write(raw)
            return d
        except Exception as e:  # network / JSON error: retry with back-off
            err = e
            time.sleep(1 + 2 * attempt)
    raise RuntimeError("quest %d: %s" % (qid, err))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--db", default=DEFAULT_DB, help="snapshot whose quest ids to fetch")
    ap.add_argument("--ids", help="file with one quest id per line (instead of --db)")
    ap.add_argument("--cache", help="directory for the raw tooltip JSON (reused when present)")
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--date", default=DEFAULT_DATE, help="fetch date written into _meta (fixed for determinism)")
    ap.add_argument("--jobs", type=int, default=4, help="parallel requests (default 4)")
    args = ap.parse_args()
    if args.ids:
        with open(args.ids, "r", encoding="utf-8") as fh:
            ids = sorted({int(l) for l in fh if l.strip()})
    else:
        ids = snapshot_quest_ids(args.db)
    if not ids:
        sys.exit("no quest ids")
    if args.cache:
        os.makedirs(args.cache, exist_ok=True)
    data = {}
    with ThreadPoolExecutor(max(1, args.jobs)) as ex:
        for qid, d in zip(ids, ex.map(lambda q: fetch(q, args.cache), ids)):
            data[str(qid)] = parse_requirements(d.get("tooltip") if isinstance(d, dict) else None)
    with_req = sum(1 for v in data.values() if v)
    out = {
        "_meta": {
            "source": "Wowhead Forever tooltip API " + URL.replace("%d", "<id>") + ", \"Requirements:\" list",
            "generator": "tools/fetch_wowhead_requirements.py",
            "date": args.date,
            "quests": len(data),
            "withRequirements": with_req,
        },
        "data": {k: data[k] for k in sorted(data, key=int)},
    }
    text = json.dumps(out, ensure_ascii=False, indent=None, separators=(",", ":"), sort_keys=False)
    # one quest per line: readable diffs
    text = text.replace(',"data":{', ',\n"data":{\n').replace('],"', '],\n"')
    with open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text + "\n")
    print("wrote %s: %d quests, %d with a Requirements list" % (args.out, len(data), with_req))


if __name__ == "__main__":
    main()
