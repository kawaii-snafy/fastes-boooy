#!/usr/bin/env python3
"""Build tools/data/forever_db.lua -- the compact World of Warcraft: Forever database
snapshot used by the offline route validator (tools/validate_routes.lua) and the
route-data generator (tools/gen_route_data.lua).

Inputs (JSON produced by our research step, see <research>/db/README.md):
    <research>/db/quests.json npcs.json objects.json items.json zones.json enums.json
    <research>/db/wclbox_quests.json      (WCLBox/Wowhead Forever: objective counts, status, XP)
    <research>/xp_table.json              (XP per level, quest XP rule, mob XP rule,
                                           Forever dungeon quest XP)

Data provenance: QuestieDB Forever data (GPLv3; data/Forever + src/corrections/Forever,
static correction layers reproduced by the research step) + WCLBox Forever mirror of
Wowhead Forever data. Client build 1.60.1.70862 (## Interface: 16001).

Coordinate space
----------------
QuestieDB keys spawns by AreaID; x/y are percentages (0-100) of the zone map drawn for that
AreaID. The Forever QuestieDB data is ALREADY in the Forever frame: the raw Forever files
were produced by `QuestieDB convert-forever` (Era DBC map bounds 1.15.9 -> Forever
1.60.1.69893); only Mulgore 215, Eastern Plaguelands 139, Redridge 44 and Stormwind 1519
changed geometry and they are converted already; trace/generated layers are native Forever
coordinates (research/db/crosscheck.md: median distance 0.04 map units vs WCLBox over 1,628
points, Mulgore included). Therefore the only conversion done here is
AreaID -> uiMapID (research zones.json `areas[AreaID].uiMapId`, which also resolves
sub-areas such as 154 Deathknell -> 1420 Tirisfal Glades or 16622 Thendal Grove -> 2521
Zephras Isle). The result is exactly the route format's `at = {uiMapID, x, y}` space.
Spawns marked [-1, -1] ("inside the instance") are not coordinates and are listed in
`instance = {AreaID, ...}` instead.

Map sizes: zones[uiMapID].size = {width, height} in yards, from the Forever map bounds
(`geometry.transforms[].target_bounds` of QuestieDB data/Forever/conversion.json: width =
|left - right|, height = |top - bottom|), so the validator can measure distances in yards.
Maps without known bounds (e.g. Zephras Isle 2521) get no size.

Spawn thinning: objective mobs / drop sources with many spawns keep ONE spawn per
SPAWN_GRID x SPAWN_GRID map-unit cell (the one nearest the cell centre), so every cluster
keeps a representative; such records carry `spawnsGrid = SPAWN_GRID` (every real spawn is
within SPAWN_GRID * sqrt(2) map units of a kept one).

The output is deterministic (sorted keys, no wall-clock timestamp; the snapshot date is
the fixed --date value). Run:

    python3 -I tools/build_db_snapshot.py --research DIR --conversion FILE|none [--out FILE]
                                          [--date YYYY-MM-DD]
"""
import argparse
import hashlib
import json
import os
import re
import sys
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.join(HERE, "data", "forever_db.lua")
DEFAULT_DATE = "2026-11-07"

BUILD = ["1.60.1", "70862"]
INTERFACE = 16001

# Top-level AreaIDs whose quests / service NPCs are in scope (sub-areas are resolved through
# the parent chain of research zones.json).
SCOPE_AREAS = OrderedDict([
    (85, "Tirisfal Glades"), (1497, "Undercity"), (130, "Silverpine Forest"), (14, "Durotar"),
    (1637, "Orgrimmar"), (17, "The Barrens"), (406, "Stonetalon Mountains"), (331, "Ashenvale"),
    (215, "Mulgore"), (1638, "Thunder Bluff"), (267, "Hillsbrad Foothills"),
    (16593, "Zephras Isle"), (493, "Moonglade"), (16591, "Riverglades"),
    (2437, "Ragefire Chasm"), (718, "Wailing Caverns"), (16611, "Ruins of Lordaeron"),
    (16919, "The Hall of Thanes"),
])
# QuestSort keys (negative zoneOrSort) of class quests in scope.
CLASS_SORTS = {-141: "PALADIN", -263: "DRUID"}
SCOPE_CLASSES = ("PALADIN", "DRUID")
# Extra uiMaps that exist in the Forever client but have no AreaID assignment in the
# reviewed DBC export (QuestieDB docs/forever-data.md "Outstanding export gaps").
EXTRA_UIMAPS = {
    2665: {"name": "Zephras Isle (secondary map)", "areaId": 16593,
           "note": "unresolved in QuestieDB export; no spawns are keyed to it"},
}
REF_DEPTH = 3                 # transitive prerequisite / next / exclusive closure depth
MAX_MOB_SPAWNS_PER_MAP = 40   # objective mobs / drop sources with more spawns per map are thinned...
SPAWN_GRID = 2.0              # ...to one spawn per SPAWN_GRID x SPAWN_GRID map-unit cell
SERVICE_FLAGS = OrderedDict([
    ("trainer", 16), ("flightmaster", 8), ("innkeeper", 128), ("vendor", 4), ("repair", 16384),
    ("banker", 256), ("stablemaster", 8192), ("spirithealer", 32),
])
ALL_FLAGS = OrderedDict([
    ("gossip", 1), ("questgiver", 2), ("vendor", 4), ("flightmaster", 8), ("trainer", 16),
    ("spirithealer", 32), ("spiritguide", 64), ("innkeeper", 128), ("banker", 256),
    ("petitioner", 512), ("tabard", 1024), ("battlemaster", 2048), ("auctioneer", 4096),
    ("stablemaster", 8192), ("repair", 16384),
])
# UnitRace() raceFile -> QuestieDB/Forever race bit. Skyborne shares one raceFile for both
# factions (raceID 95 = Alliance, 96 = Horde): resolved by faction.
RACEFILE_TO_KEY = OrderedDict([
    ("Human", "HUMAN"), ("Orc", "ORC"), ("Dwarf", "DWARF"), ("NightElf", "NIGHT_ELF"),
    ("Scourge", "UNDEAD"), ("Tauren", "TAUREN"), ("Gnome", "GNOME"), ("Troll", "TROLL"),
    ("Goblin", "GOBLIN"),
])
HORDE_RACE_KEYS = ("ORC", "UNDEAD", "TAUREN", "TROLL", "SKYBORNE_HORDE")
ALLIANCE_RACE_KEYS = ("HUMAN", "DWARF", "NIGHT_ELF", "GNOME", "SKYBORNE_ALLIANCE")


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def load_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def sha256_short(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def has_bit(mask, bit):
    """64-bit-safe bit test on a non-negative integer mask (masks exceed 32 bits)."""
    if not mask or not bit:
        return False
    return (int(mask) // int(bit)) % 2 == 1


def ilist(v):
    if not v:
        return []
    if isinstance(v, (list, tuple)):
        return [x for x in v if isinstance(x, int) and x > 0]
    if isinstance(v, int) and v > 0:
        return [v]
    return []


def thin_spatial(pts, grid):
    """One point per grid x grid cell (the one nearest the cell centre; ties by
    coordinates), sorted -- deterministic and keeps a representative of every cluster."""
    cells = OrderedDict()
    for x, y in pts:
        cells.setdefault((int(x // grid), int(y // grid)), []).append((x, y))
    out = []
    for key in sorted(cells):
        cx, cy = (key[0] + 0.5) * grid, (key[1] + 0.5) * grid
        out.append(min(cells[key], key=lambda p: ((p[0] - cx) ** 2 + (p[1] - cy) ** 2, p)))
    return sorted(out)


def ids_of(entries):
    out = []
    for e in entries or []:
        if isinstance(e, dict) and isinstance(e.get("id"), int):
            out.append(e["id"])
        elif isinstance(e, int):
            out.append(e)
    return out


# ---------------------------------------------------------------------------
# Lua serialization (deterministic, compact)
# ---------------------------------------------------------------------------

IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
    "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}


def lua_str(s):
    out = ['"']
    for ch in s:
        o = ord(ch)
        if ch == '"':
            out.append('\\"')
        elif ch == "\\":
            out.append("\\\\")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif o < 32 or o == 127:
            out.append("\\%d" % o)
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def lua_num(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if v == int(v) and abs(v) < 2 ** 53:
            return str(int(v))
        r = repr(round(v, 4))
        return r
    raise TypeError(v)


def lua_key(k):
    if isinstance(k, bool):
        raise TypeError("bool key")
    if isinstance(k, int):
        return "[%d]" % k
    if IDENT.match(k) and k not in LUA_KEYWORDS:
        return k
    return "[" + lua_str(k) + "]"


def is_array(v):
    return isinstance(v, (list, tuple))


def sort_keys(d):
    keys = list(d.keys())
    if all(isinstance(k, int) for k in keys):
        return sorted(keys)
    if isinstance(d, OrderedDict):
        return keys
    return sorted(keys, key=lambda k: (0, k) if isinstance(k, int) else (1, str(k)))


def lua_inline(v):
    """Single-line Lua constructor."""
    if v is None:
        return "nil"
    if isinstance(v, (bool, int, float)):
        return lua_num(v)
    if isinstance(v, str):
        return lua_str(v)
    if is_array(v):
        return "{" + ",".join(lua_inline(x) for x in v) + "}"
    if isinstance(v, dict):
        parts = []
        for k in sort_keys(v):
            if v[k] is None:
                continue
            parts.append(lua_key(k) + "=" + lua_inline(v[k]))
        return "{" + ",".join(parts) + "}"
    raise TypeError(type(v))


def lua_block(v, indent, inline_depth):
    """Multi-line for the top `inline_depth` levels, inline below."""
    if inline_depth <= 0 or not isinstance(v, dict) or not v:
        return lua_inline(v)
    pad = "    " * (indent + 1)
    lines = []
    for k in sort_keys(v):
        if v[k] is None:
            continue
        lines.append(pad + lua_key(k) + " = " + lua_block(v[k], indent + 1, inline_depth - 1) + ",")
    return "{\n" + "\n".join(lines) + "\n" + "    " * indent + "}"


# ---------------------------------------------------------------------------
# zones
# ---------------------------------------------------------------------------

class Zones:
    def __init__(self, zjson):
        self.areas = {int(k): v for k, v in zjson["areas"].items()}
        self.uimaps = {int(k): v for k, v in zjson["uiMaps"].items()}
        self._top = {}

    def parent(self, area):
        a = self.areas.get(area)
        return a and a.get("parentAreaId")

    def chain(self, area):
        out, cur, n = [], area, 0
        while cur and n < 12:
            out.append(cur)
            cur = self.parent(cur)
            n += 1
        return out

    def in_scope(self, area):
        if not isinstance(area, int) or area <= 0:
            return False
        return any(a in SCOPE_AREAS for a in self.chain(area))

    def scope_root(self, area):
        for a in self.chain(area) if isinstance(area, int) and area > 0 else []:
            if a in SCOPE_AREAS:
                return a
        return None

    def ui_map(self, area):
        a = self.areas.get(area)
        if not a:
            return None
        u = a.get("uiMapId")
        return u if isinstance(u, int) and u > 0 else None

    def name(self, area):
        a = self.areas.get(area)
        return a and a.get("name")


# ---------------------------------------------------------------------------
# snapshot builder
# ---------------------------------------------------------------------------

class Builder:
    def __init__(self, research):
        dbdir = os.path.join(research, "db")
        self.paths = OrderedDict([
            ("quests", os.path.join(dbdir, "quests.json")),
            ("npcs", os.path.join(dbdir, "npcs.json")),
            ("objects", os.path.join(dbdir, "objects.json")),
            ("items", os.path.join(dbdir, "items.json")),
            ("zones", os.path.join(dbdir, "zones.json")),
            ("enums", os.path.join(dbdir, "enums.json")),
            ("wclbox", os.path.join(dbdir, "wclbox_quests.json")),
            ("xp_table", os.path.join(research, "xp_table.json")),
        ])
        for k, p in self.paths.items():
            if not os.path.isfile(p):
                sys.exit("missing input %s: %s (pass --research)" % (k, p))
        self.qraw = {int(k): v for k, v in load_json(self.paths["quests"])["data"].items()}
        self.nraw = {int(k): v for k, v in load_json(self.paths["npcs"])["data"].items()}
        self.oraw = {int(k): v for k, v in load_json(self.paths["objects"])["data"].items()}
        self.iraw = {int(k): v for k, v in load_json(self.paths["items"])["data"].items()}
        self.zjson = load_json(self.paths["zones"])
        self.zones = Zones(self.zjson)
        self.enums = load_json(self.paths["enums"])
        self.wcl = {int(k): v for k, v in load_json(self.paths["wclbox"])["data"].items()}
        self.xpt = load_json(self.paths["xp_table"])
        rk = self.enums["raceKeys"]
        self.horde_mask = sum(rk[k] for k in HORDE_RACE_KEYS)
        self.alliance_mask = sum(rk[k] for k in ALLIANCE_RACE_KEYS)
        assert self.horde_mask == rk["ALL_HORDE"], "ALL_HORDE mismatch"
        assert self.alliance_mask == rk["ALL_ALLIANCE"], "ALL_ALLIANCE mismatch"
        self.dungeon_xp = {}
        for dkey, d in (self.xpt.get("dungeonQuestXp") or {}).items():
            for q in d.get("hordeQuests") or []:
                if isinstance(q.get("xpForever"), int) and q["xpForever"] > 0:
                    self.dungeon_xp[q["id"]] = (q["xpForever"], dkey)
        self.stats = OrderedDict()

    # -- quest helpers -----------------------------------------------------

    def effective_quest(self, q):
        """Apply the Horde Dynamic overlay (faction-level); returns (record, {class: record})."""
        hd = q.get("hordeDynamic")
        if not hd:
            return q, {}
        if "fields" in hd or "deleted" in hd:
            return self._overlay(q, hd), {}
        per = {}
        for cls in SCOPE_CLASSES:
            if cls in hd:
                per[cls] = self._overlay(q, hd[cls])
        return q, per

    @staticmethod
    def _overlay(q, ov):
        r = dict(q)
        for k, v in (ov.get("fields") or {}).items():
            r[k] = v
        for k in ov.get("deleted") or []:
            r.pop(k, None)
        return r

    def side_of(self, races):
        if not races:
            return "AH"
        h = (int(races) & self.horde_mask) != 0
        a = (int(races) & self.alliance_mask) != 0
        return ("A" if a else "") + ("H" if h else "") or "-"

    def horde_available(self, q):
        return "H" in self.side_of(q.get("requiredRaces") or 0)

    def quest_areas(self, q):
        """AreaIDs touched by the quest's zone and its start/finish NPC/object spawns."""
        out = set()
        z = q.get("zoneOrSort") or 0
        if z > 0:
            out.add(z)
        sb, fb = q.get("startedBy") or {}, q.get("finishedBy") or {}
        for nid in ids_of(sb.get("npcs")) + ids_of(fb.get("npcs")):
            out.update(int(a) for a in (self.nraw.get(nid, {}).get("spawns") or {}))
        for oid in ids_of(sb.get("objects")) + ids_of(fb.get("objects")):
            out.update(int(a) for a in (self.oraw.get(oid, {}).get("spawns") or {}))
        return out

    def is_class_quest(self, q):
        if (q.get("zoneOrSort") or 0) in CLASS_SORTS:
            return True
        rc = q.get("requiredClasses") or 0
        if rc:
            ck = self.enums["classKeys"]
            return any(has_bit(rc, ck[c]) for c in SCOPE_CLASSES)
        return False

    @staticmethod
    def quest_refs(q):
        refs = []
        for k in ("preQuestGroup", "preQuestSingle", "breadcrumbs", "exclusiveTo", "childQuests", "inGroupWith"):
            refs += ilist(q.get(k))
        for k in ("nextQuestInChain", "breadcrumbForQuestId", "parentQuest"):
            refs += ilist(q.get(k))
        return refs

    def select_quests(self):
        core = set()
        reason = {}
        for qid, q0 in self.qraw.items():
            q, per = self.effective_quest(q0)
            if self.is_class_quest(q):
                core.add(qid)
                reason[qid] = "class"
                continue
            if not self.horde_available(q):
                continue
            areas = self.quest_areas(q)
            for p in per.values():
                areas |= self.quest_areas(p)
            if any(self.zones.in_scope(a) for a in areas):
                core.add(qid)
                reason[qid] = "zone"
        selected = set(core)
        frontier = set(core)
        for _depth in range(REF_DEPTH):
            nxt = set()
            for qid in frontier:
                q0 = self.qraw[qid]
                recs = [q0] + [self._overlay(q0, v) for v in self._dyn_variants(q0)]
                for r in recs:
                    for ref in self.quest_refs(r):
                        if ref in self.qraw and ref not in selected:
                            nxt.add(ref)
                            reason[ref] = "ref"
            selected |= nxt
            frontier = nxt
        missing_refs = set()
        for qid in selected:
            for ref in self.quest_refs(self.qraw[qid]):
                if ref not in self.qraw:
                    missing_refs.add(ref)
        self.stats["questsCore"] = len(core)
        self.stats["questsByClassSort"] = sum(1 for q in core if reason.get(q) == "class")
        self.stats["questsByReference"] = len(selected) - len(core)
        self.stats["questRefsMissingFromDB"] = len(missing_refs)
        return sorted(selected), reason

    @staticmethod
    def _dyn_variants(q):
        hd = q.get("hordeDynamic")
        if not hd:
            return []
        if "fields" in hd or "deleted" in hd:
            return [hd]
        return [hd[c] for c in SCOPE_CLASSES if c in hd]

    # -- objective counts --------------------------------------------------

    @staticmethod
    def _count_from_text(texts, name):
        if not name:
            return None
        for t in texts or []:
            if not t:
                continue
            m = re.search(r'(\d+)\s+' + re.escape(name), t, flags=re.I)
            if m:
                n = int(m.group(1))
                if 0 < n < 1000:
                    return n
        return None

    def objective_counts(self, qid, q):
        """{('creature'|'item'|'object', id): count} from WCLBox (Forever) then the text."""
        w = self.wcl.get(qid) or {}
        counts = {}
        goals = [g for g in (w.get("goals") or []) if g.get("k") == "kill"]
        obj = q.get("objectives") or {}
        creatures = obj.get("creature") or []
        for i, c in enumerate(creatures):
            n = None
            for g in goals:
                if g.get("c") and g.get("n") and c.get("name") and g["n"].lower() == c["name"].lower():
                    n = g["c"]
                    break
            if n is None and len(goals) == len(creatures) and goals[i].get("c"):
                n = goals[i]["c"]
            if n is None:
                n = self._count_from_text(q.get("objectivesText"), c.get("name"))
            if n:
                counts[("creature", c["id"])] = n
        for kc in obj.get("killCredit") or []:
            n = None
            for g in goals:
                if g.get("c") and g.get("n") and kc.get("baseName") and g["n"].lower() == kc["baseName"].lower():
                    n = g["c"]
            if n is None:
                n = self._count_from_text(q.get("objectivesText"), kc.get("baseName"))
            if n:
                counts[("killCredit", kc.get("baseId"))] = n
        # WCLBox `need` = required items: `c` is the required count (absent for single items);
        # `q` is the item quality, not a quantity.
        need = {}
        for nd in w.get("need") or []:
            if isinstance(nd.get("i"), int):
                need[nd["i"]] = nd.get("c") if isinstance(nd.get("c"), int) and nd["c"] > 0 else None
        for it in obj.get("item") or []:
            n = need.get(it["id"]) or self._count_from_text(q.get("objectivesText"), it.get("name"))
            if n is None and it["id"] in need:
                n = 1
            if n:
                counts[("item", it["id"])] = n
        for ob in obj.get("object") or []:
            n = self._count_from_text(q.get("objectivesText"), ob.get("name"))
            if n:
                counts[("object", ob["id"])] = n
        return counts

    # -- conversion --------------------------------------------------------

    def quest_xp(self, qid, q):
        if qid in self.dungeon_xp:
            return self.dungeon_xp[qid][0], "forever-dungeon"
        w = self.wcl.get(qid)
        if w and isinstance(w.get("xp"), int) and w["xp"] > 0 and w.get("status") != "new":
            return w["xp"], "wclbox-classic"
        xq = q.get("xpQuestieDB") or {}
        if isinstance(xq.get("xp"), int) and xq["xp"] > 0:
            return xq["xp"], "questie-classic"
        return None, None

    def quest_status(self, qid, q):
        w = self.wcl.get(qid)
        if w and w.get("status") in ("same", "new", "changed"):
            return w["status"]
        created = q.get("_created") or ""
        if created.startswith(("generated:", "traces:", "authored:")):
            return "new"
        return "same"

    def convert_quest(self, qid, q, counts):
        rec = OrderedDict()
        rec["name"] = q.get("name") or ("quest %d" % qid)
        ql = q.get("questLevel") or 0
        rl = q.get("requiredLevel") or 0
        rec["level"] = ql
        rec["reqLevel"] = rl
        races = q.get("requiredRaces") or 0
        rec["races"] = races
        rec["classes"] = q.get("requiredClasses") or 0
        rec["side"] = self.side_of(races)
        sb, fb = q.get("startedBy") or {}, q.get("finishedBy") or {}
        start = OrderedDict()
        for k in ("npcs", "objects", "items"):
            ids = sorted(set(ids_of(sb.get(k))))
            if ids:
                start[k] = ids
        if start:
            rec["start"] = start
        finish = OrderedDict()
        for k in ("npcs", "objects"):
            ids = sorted(set(ids_of(fb.get(k))))
            if ids:
                finish[k] = ids
        if finish:
            rec["finish"] = finish
        for src, dst in (("preQuestGroup", "preGroup"), ("preQuestSingle", "preSingle"),
                         ("exclusiveTo", "exclusive"), ("breadcrumbs", "breadcrumbs"),
                         ("childQuests", "children"), ("inGroupWith", "inGroupWith")):
            v = ilist(q.get(src))
            if v:
                rec[dst] = v
        for src, dst in (("nextQuestInChain", "next"), ("breadcrumbForQuestId", "breadcrumbFor"),
                         ("parentQuest", "parent"), ("requiredMaxLevel", "maxLevel"),
                         ("requiredSpell", "reqSpell"), ("availableUntilCompleted", "untilCompleted"),
                         ("disabledByQuest", "disabledBy")):
            v = q.get(src)
            if isinstance(v, int) and v != 0:
                rec[dst] = v
        obj = q.get("objectives") or {}
        objectives = OrderedDict()
        cr = []
        for c in obj.get("creature") or []:
            n = counts.get(("creature", c["id"]))
            cr.append([c["id"], n] if n else [c["id"]])
        if cr:
            objectives["creatures"] = cr
        kc = []
        for k in obj.get("killCredit") or []:
            e = OrderedDict([("ids", sorted(set(ilist(k.get("ids")))))])
            if k.get("baseId"):
                e["base"] = k["baseId"]
            n = counts.get(("killCredit", k.get("baseId")))
            if n:
                e["count"] = n
            if e["ids"]:
                kc.append(e)
        if kc:
            objectives["killCredit"] = kc
        ob = []
        for o in obj.get("object") or []:
            n = counts.get(("object", o["id"]))
            ob.append([o["id"], n] if n else [o["id"]])
        if ob:
            objectives["objects"] = ob
        it = []
        for i in obj.get("item") or []:
            n = counts.get(("item", i["id"]))
            it.append([i["id"], n] if n else [i["id"]])
        if it:
            objectives["items"] = it
        sp = [s.get("spellId") for s in (obj.get("spell") or []) if s.get("spellId")]
        if sp:
            objectives["spells"] = sp
        if obj.get("reputation"):
            objectives["reputation"] = [obj["reputation"].get("factionId"), obj["reputation"].get("value")]
        if q.get("triggerEnd"):
            objectives["event"] = True
        if objectives:
            rec["objectives"] = objectives
        if q.get("sourceItemId"):
            rec["sourceItem"] = q["sourceItemId"]
        rsi = ids_of(q.get("requiredSourceItems"))
        if rsi:
            rec["reqItems"] = rsi
        z = q.get("zoneOrSort") or 0
        if z:
            rec["zone"] = z
            if z > 0:
                um = self.zones.ui_map(z)
                if um:
                    rec["uiMap"] = um
        if q.get("questFlags"):
            rec["flags"] = q["questFlags"]
        if q.get("specialFlags"):
            rec["special"] = q["specialFlags"]
        if q.get("requiredSkill"):
            rec["reqSkill"] = [q["requiredSkill"].get("skillId"), q["requiredSkill"].get("value")]
        xp, xsrc = self.quest_xp(qid, q)
        if xp:
            rec["xp"] = xp
            rec["xpSrc"] = xsrc
        rec["status"] = self.quest_status(qid, q)
        return rec

    def build_quests(self, qids):
        quests = OrderedDict()
        refs = {"npcs": set(), "objects": set(), "items": set(), "mobs": set(), "mobObjects": set()}
        stats = {"xpKnown": 0, "xpUnknown": 0, "dynamicApplied": 0, "byClass": 0}
        for qid in qids:
            q0 = self.qraw[qid]
            q, per = self.effective_quest(q0)
            if q is not q0:
                stats["dynamicApplied"] += 1
            counts = self.objective_counts(qid, q)
            rec = self.convert_quest(qid, q, counts)
            if per:
                byc = OrderedDict()
                for cls, pq in sorted(per.items()):
                    prec = self.convert_quest(qid, pq, self.objective_counts(qid, pq))
                    diff = OrderedDict((k, v) for k, v in prec.items() if rec.get(k) != v)
                    gone = [k for k in rec if k not in prec]
                    if gone:
                        diff["_deleted"] = sorted(gone)
                    if diff:
                        byc[cls] = diff
                    self._collect_refs(prec, refs)
                if byc:
                    rec["byClass"] = byc
                    stats["byClass"] += 1
            if rec.get("xp"):
                stats["xpKnown"] += 1
            else:
                stats["xpUnknown"] += 1
            self._collect_refs(rec, refs)
            quests[qid] = rec
        self.stats.update(("quests." + k, v) for k, v in stats.items())
        return quests, refs

    @staticmethod
    def _collect_refs(rec, refs):
        st, fi = rec.get("start") or {}, rec.get("finish") or {}
        refs["npcs"].update(st.get("npcs") or [])
        refs["npcs"].update(fi.get("npcs") or [])
        refs["objects"].update(st.get("objects") or [])
        refs["objects"].update(fi.get("objects") or [])
        refs["items"].update(st.get("items") or [])
        ob = rec.get("objectives") or {}
        for e in ob.get("creatures") or []:
            refs["mobs"].add(e[0])
        for e in ob.get("killCredit") or []:
            refs["mobs"].update(e["ids"])
            if e.get("base"):
                refs["mobs"].add(e["base"])
        for e in ob.get("objects") or []:
            refs["mobObjects"].add(e[0])
        for e in ob.get("items") or []:
            refs["items"].add(e[0])
        if rec.get("sourceItem"):
            refs["items"].add(rec["sourceItem"])
        refs["items"].update(rec.get("reqItems") or [])

    # -- npcs / objects ----------------------------------------------------

    def convert_spawns(self, spawns, cap):
        out = OrderedDict()
        instance = set()
        raw_areas = OrderedDict()
        per_map = {}
        for area_s, pts in sorted((spawns or {}).items(), key=lambda kv: int(kv[0])):
            area = int(area_s)
            um = self.zones.ui_map(area)
            for p in pts or []:
                if not isinstance(p, list) or len(p) < 2:
                    continue
                x, y = p[0], p[1]
                if x == -1 and y == -1:
                    instance.add(area)
                    continue
                if not um:
                    raw_areas.setdefault(area, []).append((x, y))
                    continue
                per_map.setdefault(um, []).append((x, y))
        thinned = False
        for um in sorted(per_map):
            pts = sorted(set(per_map[um]))
            if cap and len(pts) > cap:
                pts = thin_spatial(pts, SPAWN_GRID)
                thinned = True
            out[um] = [[x, y] for x, y in pts]
        raw = OrderedDict()
        for area in sorted(raw_areas):
            raw[area] = [[x, y] for x, y in sorted(set(raw_areas[area]))]
        return out, sorted(instance), raw, thinned

    def npc_flags(self, flags):
        out = OrderedDict()
        for name, bit in ALL_FLAGS.items():
            if has_bit(flags or 0, bit):
                out[name] = True
        return out

    def effective_npc(self, n):
        hd = n.get("hordeDynamic")
        if not hd:
            return n
        if "fields" in hd or "deleted" in hd:
            return self._overlay(n, hd)
        # class-dependent NPC overlays do not exist in the inputs; take PALADIN's if any
        for cls in SCOPE_CLASSES:
            if cls in hd:
                return self._overlay(n, hd[cls])
        return n

    def convert_npc(self, nid, cap):
        n = self.effective_npc(self.nraw[nid])
        rec = OrderedDict()
        rec["name"] = n.get("name") or ("npc %d" % nid)
        if n.get("subName"):
            rec["sub"] = n["subName"]
        rec["minLevel"] = n.get("minLevel") or 0
        rec["maxLevel"] = n.get("maxLevel") or rec["minLevel"]
        if n.get("rank"):
            rec["rank"] = n["rank"]
        rec["faction"] = n.get("friendlyToFaction") or ""
        fl = self.npc_flags(n.get("npcFlags") or 0)
        if fl:
            rec["flags"] = fl
        spawns, instance, raw, thinned = self.convert_spawns(n.get("spawns"), cap)
        if spawns:
            rec["spawns"] = spawns
            if thinned:
                rec["spawnsGrid"] = SPAWN_GRID
        if instance:
            rec["instance"] = instance
        if raw:
            rec["areaSpawns"] = raw
        if n.get("zoneID"):
            rec["zone"] = n["zoneID"]
        return rec

    def convert_object(self, oid, cap):
        o = self.oraw[oid]
        hd = o.get("hordeDynamic")
        if hd and ("fields" in hd or "deleted" in hd):
            o = self._overlay(o, hd)
        rec = OrderedDict()
        rec["name"] = o.get("name") or ("object %d" % oid)
        spawns, instance, raw, thinned = self.convert_spawns(o.get("spawns"), cap)
        if spawns:
            rec["spawns"] = spawns
            if thinned:
                rec["spawnsGrid"] = SPAWN_GRID
        if instance:
            rec["instance"] = instance
        if raw:
            rec["areaSpawns"] = raw
        if o.get("zoneID"):
            rec["zone"] = o["zoneID"]
        return rec

    def npc_in_scope_areas(self, n):
        return any(self.zones.in_scope(int(a)) for a in (n.get("spawns") or {}))

    def build_entities(self, refs):
        # items first: their drop sources join the mob set
        items = OrderedDict()
        drop_npcs, drop_objs = set(), set()
        for iid in sorted(refs["items"]):
            it = self.iraw.get(iid)
            if not it:
                continue
            rec = OrderedDict()
            rec["name"] = it.get("name") or ("item %d" % iid)
            nd = sorted(set(ilist(it.get("npcDrops"))))
            od = sorted(set(ilist(it.get("objectDrops"))))
            idr = sorted(set(ilist(it.get("itemDrops"))))
            vd = sorted(set(ilist(it.get("vendors"))))
            if nd:
                rec["npcDrops"] = nd
                drop_npcs.update(nd)
            if od:
                rec["objectDrops"] = od
                drop_objs.update(od)
            if idr:
                rec["itemDrops"] = idr
            if vd:
                rec["vendors"] = vd
            if it.get("startQuest"):
                rec["startQuest"] = it["startQuest"]
            if it.get("class") is not None:
                rec["class"] = it.get("class")
            items[iid] = rec

        service = set()
        for nid, n in self.nraw.items():
            fl = self.effective_npc(n).get("npcFlags") or 0
            if any(has_bit(fl, b) for b in SERVICE_FLAGS.values()) and self.npc_in_scope_areas(n):
                service.add(nid)
        # class trainers of the scope classes anywhere (e.g. Moonglade, capitals)
        for nid, n in self.nraw.items():
            sub = (n.get("subName") or "").lower()
            if any((c.lower() + " trainer") in sub for c in SCOPE_CLASSES):
                service.add(nid)

        full_npcs = (refs["npcs"] | service)
        mob_npcs = (refs["mobs"] | drop_npcs) - full_npcs
        npcs = OrderedDict()
        for nid in sorted(full_npcs | mob_npcs):
            if nid not in self.nraw:
                continue
            npcs[nid] = self.convert_npc(nid, None if nid in full_npcs else MAX_MOB_SPAWNS_PER_MAP)
        objects = OrderedDict()
        full_objs = refs["objects"]
        for oid in sorted(full_objs | refs["mobObjects"] | drop_objs):
            if oid not in self.oraw:
                continue
            objects[oid] = self.convert_object(oid, None if oid in full_objs else MAX_MOB_SPAWNS_PER_MAP)
        self.stats["npcs.questGivers"] = len(refs["npcs"])
        self.stats["npcs.service"] = len(service)
        self.stats["npcs.mobsAndDropSources"] = len(mob_npcs)
        self.stats["npcs.missingFromDB"] = len([n for n in full_npcs | mob_npcs if n not in self.nraw])
        self.stats["objects.missingFromDB"] = len([o for o in full_objs | refs["mobObjects"] | drop_objs
                                                   if o not in self.oraw])
        self.stats["items.missingFromDB"] = len([i for i in refs["items"] if i not in self.iraw])
        return npcs, objects, items

    # -- brief indexes (existence checks for ids outside the scope) -------

    def brief_quests(self, selected):
        sel = set(selected)
        out = OrderedDict()
        for qid in sorted(self.qraw):
            if qid in sel:
                continue
            q = self.qraw[qid]
            out[qid] = [q.get("name") or "", q.get("questLevel") or 0, q.get("requiredLevel") or 0,
                        q.get("requiredRaces") or 0, q.get("requiredClasses") or 0, q.get("zoneOrSort") or 0]
        return out

    def brief_npcs(self, included):
        out = OrderedDict()
        for nid in sorted(self.nraw):
            if nid in included:
                continue
            n = self.nraw[nid]
            out[nid] = [n.get("name") or "", n.get("zoneID") or 0]
        return out

    def brief_objects(self, included):
        out = OrderedDict()
        for oid in sorted(self.oraw):
            if oid in included:
                continue
            out[oid] = self.oraw[oid].get("name") or ""
        return out

    # -- zones / enums / xp --------------------------------------------------

    def build_zones(self, sizes):
        zones = OrderedDict()
        for um in sorted(self.zones.uimaps):
            u = self.zones.uimaps[um]
            name = u.get("name")
            area = self.zones.areas.get(u.get("areaId")) or {}
            alias = name == "Referenced dungeon area"
            if alias and area.get("name"):
                name = area["name"]
            rec = OrderedDict([("name", name), ("areaId", u.get("areaId"))])
            if alias or area.get("dungeon"):
                rec["dungeon"] = True
            if alias:
                rec["note"] = "QuestieDB legacy dungeon alias map (not a native Forever floor map)"
            if u.get("areaId") in SCOPE_AREAS:
                rec["scope"] = True
            if um in sizes:
                rec["size"] = sizes[um]
            zones[um] = rec
        for um, extra in sorted(EXTRA_UIMAPS.items()):
            zones.setdefault(um, OrderedDict(sorted(extra.items())))
        # dungeon alias maps used as uiMap overrides by QuestieDB (not native floor maps)
        for area, a in sorted(self.zones.areas.items()):
            um = a.get("uiMapId")
            if isinstance(um, int) and um > 0 and um not in zones and a.get("dungeon"):
                zones[um] = OrderedDict([("name", a.get("name")), ("areaId", area), ("dungeon", True),
                                         ("note", "QuestieDB legacy dungeon alias map")])
        area_to_ui = OrderedDict()
        area_names = OrderedDict()
        for area in sorted(self.zones.areas):
            a = self.zones.areas[area]
            um = a.get("uiMapId")
            if isinstance(um, int) and um > 0:
                area_to_ui[area] = um
            if self.zones.in_scope(area) and a.get("name"):
                area_names[area] = a["name"]
        dungeons = OrderedDict()
        for area in sorted(self.zones.areas):
            a = self.zones.areas[area]
            d = a.get("dungeon")
            if not d:
                continue
            ents = []
            for e in d.get("entrances") or []:
                um = self.zones.ui_map(e[0])
                if um:
                    ents.append([um, e[1], e[2]])
            rec = OrderedDict([("name", d.get("name") or a.get("name"))])
            if ents:
                rec["entrances"] = ents
            if d.get("parentZone"):
                rec["parentArea"] = d["parentZone"]
            dungeons[area] = rec
        scope = OrderedDict((a, n) for a, n in SCOPE_AREAS.items())
        return zones, area_to_ui, area_names, dungeons, scope

    def build_enums(self):
        rk = self.enums["raceKeys"]
        races = OrderedDict((k, rk[k]) for k in sorted(rk) if k not in ("NONE", "ALL_HORDE", "ALL_ALLIANCE"))
        ck = self.enums["classKeys"]
        classes = OrderedDict((k, ck[k]) for k in sorted(ck) if k not in ("NONE", "ALL_CLASSES"))
        rf = OrderedDict()
        for raceFile, key in RACEFILE_TO_KEY.items():
            rf[raceFile] = rk[key]
        rf["Skyborne"] = OrderedDict([("Alliance", rk["SKYBORNE_ALLIANCE"]), ("Horde", rk["SKYBORNE_HORDE"])])
        nf = self.enums["npcFlags"]
        npc_flags = OrderedDict((k, nf[k]) for k in sorted(nf) if k != "NONE")
        qf = self.enums["questFlags"]
        quest_flags = OrderedDict((k, qf[k]) for k in sorted(qf) if k != "NONE")
        sk = self.enums.get("sortKeys") or {}
        class_sorts = OrderedDict((name, sk[name]) for name in sorted(sk)
                                  if name in ("WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN",
                                              "MAGE", "WARLOCK", "DRUID"))
        return OrderedDict([
            ("races", races),
            ("classes", classes),
            ("raceFileToBit", rf),
            ("factionMasks", OrderedDict([("Alliance", self.alliance_mask), ("Horde", self.horde_mask)])),
            ("npcFlags", npc_flags),
            ("questFlags", quest_flags),
            ("classSorts", class_sorts),
            ("specialFlags", OrderedDict([("REPEATABLE", 1)])),
        ])

    def build_xp(self):
        x = self.xpt
        levels = OrderedDict((int(k), v) for k, v in sorted(x["levels"].items(), key=lambda kv: int(kv[0])))
        rule = OrderedDict([
            ("formula", "mult = clamp(2*(questLevel-playerLevel)+20, 1, 10)/10; round: <=100 -> 5*floor((x+2)/5); "
                        "<=500 -> 10*floor((x+5)/10); <=1000 -> 25*floor((x+12)/25); else 50*floor((x+25)/50)"),
            ("fullUpTo", 5),
            ("multipliers", OrderedDict([(6, 0.8), (7, 0.6), (8, 0.4), (9, 0.2), (10, 0.1)])),
            ("maxLevelXp", 0),
            ("confidence", "likely (Classic rule; no Forever change found)"),
        ])
        md = x.get("mobXpDetail") or {}
        zd = OrderedDict()
        for rng, v in (md.get("ZD_zeroDifference") or {}).items():
            if "-" in rng:
                a, b = rng.split("-")
            else:
                a = b = rng
            for lv in range(int(a), int(b) + 1):
                zd[lv] = v
        mob = OrderedDict([
            ("formula", "same/higher: (5*pL+45)*(1+0.05*min(mL-pL,4)); lower non-grey: (5*pL+45)*(1-(pL-mL)/ZD); "
                        "grey: 0; elite x2"),
            ("zeroDifference", OrderedDict(sorted(zd.items()))),
            ("greyLevel", "pL<=5: none; 6-39: pL-floor(pL/10)-5; 40-59: pL-floor(pL/5)-1"),
            ("eliteMult", 2),
            ("foreverGreenPenalty", "open-world mobs below the player's level give 4-20% less XP than Classic "
                                    "(community-measured; exact formula unpublished)"),
            ("foreverGreenPenaltyMax", 0.20),
        ])
        dq = OrderedDict()
        for dkey, d in sorted((x.get("dungeonQuestXp") or {}).items()):
            mult = (d.get("questXpMultVsClassic") or {}).get("now")
            dq[dkey] = OrderedDict([("levels", d.get("levels")), ("questXpMult", mult)])
        tiers = OrderedDict()
        for lv, vals in sorted(((x.get("questXpRule") or {}).get("typicalClassicQuestXpTiersByQuestLevel") or {}).items(),
                               key=lambda kv: int(kv[0])):
            tiers[int(lv)] = vals
        return OrderedDict([
            ("levels", levels),
            ("levelCap", 60),
            ("questRule", rule),
            ("mobRule", mob),
            ("dungeons", dq),
            ("typicalQuestXpByLevel", tiers),
        ])


def load_map_sizes(path):
    """{uiMapID: [width, height]} in yards from QuestieDB conversion.json target_bounds."""
    sizes = OrderedDict()
    if not path or path == "none":
        return sizes
    conv = load_json(path)
    for t in (conv.get("geometry") or {}).get("transforms") or []:
        um, b = t.get("ui_map_id"), t.get("target_bounds")
        if not isinstance(um, int) or not isinstance(b, dict):
            continue
        try:
            w = abs(float(b["left"]) - float(b["right"]))
            h = abs(float(b["top"]) - float(b["bottom"]))
        except (KeyError, TypeError, ValueError):
            continue
        if w > 0 and h > 0:
            sizes[um] = [round(w, 1), round(h, 1)]
    return sizes


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--research", required=True, help="research directory (contains db/ and xp_table.json)")
    ap.add_argument("--conversion", required=True,
                    help="QuestieDB data/Forever/conversion.json (map bounds -> zone sizes in yards), "
                         "or 'none' (no sizes: the validator then measures distances in map percent)")
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--date", default=DEFAULT_DATE, help="snapshot date written into meta (fixed for determinism)")
    args = ap.parse_args()
    if not os.path.isdir(args.research):
        ap.error("research directory not found: %s" % args.research)
    if args.conversion != "none" and not os.path.isfile(args.conversion):
        ap.error("conversion.json not found: %s (pass --conversion none to skip zone sizes)" % args.conversion)

    b = Builder(args.research)
    qids, _reason = b.select_quests()
    quests, refs = b.build_quests(qids)
    npcs, objects, items = b.build_entities(refs)
    sizes = load_map_sizes(args.conversion)
    zones, area_to_ui, area_names, dungeons, scope = b.build_zones(sizes)
    enums = b.build_enums()
    xp = b.build_xp()
    quest_brief = b.brief_quests(qids)
    npc_brief = b.brief_npcs(set(npcs))
    object_brief = b.brief_objects(set(objects))

    sources = OrderedDict()
    for k, p in b.paths.items():
        sources[k] = OrderedDict([("file", os.path.relpath(p, args.research)), ("sha256", sha256_short(p))])
    if args.conversion != "none":
        sources["conversion"] = OrderedDict([("file", "QuestieDB data/Forever/conversion.json"),
                                             ("sha256", sha256_short(args.conversion))])
    counts = OrderedDict([
        ("quests", len(quests)), ("questIndex", len(quest_brief)), ("npcs", len(npcs)),
        ("npcIndex", len(npc_brief)), ("objects", len(objects)), ("objectIndex", len(object_brief)),
        ("items", len(items)), ("zones", len(zones)), ("zonesWithSize", len([z for z in zones.values() if "size" in z])),
        ("dungeons", len(dungeons)),
    ])
    for k, v in b.stats.items():
        counts[k] = v
    meta = OrderedDict([
        ("build", BUILD),
        ("interface", INTERFACE),
        ("generated", args.date),
        ("generator", "tools/build_db_snapshot.py"),
        ("license", "data derived from QuestieDB (GPL-3.0) Forever data and WCLBox/Wowhead Forever data"),
        ("coordinates", "spawns[uiMapID] = {{x, y}, ...} in uiMap percent 0-100 (Forever frame); "
                        "QuestieDB AreaID keys resolved to uiMapID; no geometric transform needed"),
        ("raceMasks", "races/classes are bit masks; race masks exceed 32 bits (Skyborne 2^32/2^33): "
                      "test with floor(mask / bit) % 2, never bit.band"),
        ("questLogSizeSource", "Constants.QuestLogConsts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT = 40 "
                               "(runtime: C_QuestLog.GetMaxNumQuestsCanAccept())"),
        ("sources", sources),
        ("counts", counts),
    ])
    out = OrderedDict([
        ("meta", meta),
        ("questLogSize", 40),
        ("levelCap", 60),
        ("enums", enums),
        ("scopeAreas", scope),
        ("zones", zones),
        ("areaToUiMap", area_to_ui),
        ("areaNames", area_names),
        ("dungeons", dungeons),
        ("xp", xp),
        ("quests", quests),
        ("npcs", npcs),
        ("objects", objects),
        ("items", items),
        ("questIndex", quest_brief),
        ("npcIndex", npc_brief),
        ("objectIndex", object_brief),
    ])

    header = [
        "-- tools/data/forever_db.lua -- GENERATED by tools/build_db_snapshot.py. DO NOT EDIT BY HAND.",
        "--",
        "-- World of Warcraft: Forever database snapshot for offline route validation.",
        "-- Client %s.%s (## Interface: %d). Snapshot date %s." % (BUILD[0], BUILD[1], INTERFACE, args.date),
        "-- Data: QuestieDB Forever data (GPL-3.0; data/Forever + src/corrections/Forever static layers) and",
        "--       WCLBox mirror of Wowhead Forever data (objective counts, quest status, XP), see",
        "--       research/db/README.md and research/db/crosscheck.md. Our repository is GPL-3.0 as well.",
        "-- Coordinates: uiMapID + map percent (0-100), Forever frame (QuestieDB Forever data is already",
        "--       converted from Era; only AreaID -> uiMapID was resolved here).",
        "--",
        "-- Layout (see tools/README.md):",
        "--   quests[id]   = {name, level, reqLevel, races, classes, side=\"H|A|AH\", start={npcs,objects,items},",
        "--                   finish={npcs,objects}, preGroup, preSingle, exclusive, next, breadcrumbFor, breadcrumbs,",
        "--                   parent, children, objectives={creatures={{id,count?}}, killCredit={{ids,base,count}},",
        "--                   objects={{id,count?}}, items={{id,count?}}}, sourceItem, zone, uiMap, flags, special,",
        "--                   xp, xpSrc, status=\"same|new|changed\", byClass={CLASS={overridden fields}}}",
        "--   npcs[id]     = {name, sub, minLevel, maxLevel, rank, faction=\"A|H|AH|\", flags={trainer=true,...},",
        "--                   spawns={[uiMapID]={{x,y},...}}, spawnsGrid (thinned: one spawn per grid cell),",
        "--                   instance={AreaID,...}, zone}",
        "--   zones[uiMapID] = {name, areaId, dungeon, scope, size={widthYards, heightYards}}",
        "--   objects[id]  = {name, spawns, instance, zone};  items[id] = {name, npcDrops, objectDrops, vendors, ...}",
        "--   questIndex[id] = {name, level, reqLevel, races, classes, zoneOrSort}  (quests outside the scope)",
        "--   npcIndex[id] = {name, zoneAreaID};  objectIndex[id] = name  (entities outside the scope)",
        "",
    ]
    body = "return " + lua_block(out, 0, 2) + "\n"
    text = "\n".join(header) + body
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    size = len(text.encode("utf-8"))
    print("wrote %s (%d bytes, %.2f MB)" % (args.out, size, size / 1048576.0))
    for k, v in counts.items():
        print("  %-28s %s" % (k, v))


if __name__ == "__main__":
    main()
