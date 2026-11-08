#!/usr/bin/env python3
"""Build tools/data/forever_db.lua -- the compact World of Warcraft: Forever database
snapshot used by the offline route validator (tools/validate_routes.lua) and the
route-data generator (tools/gen_route_data.lua).

Inputs (JSON produced by our research step, see <research>/db/README.md):
    <research>/db/quests.json npcs.json objects.json items.json zones.json enums.json
    <research>/db/wclbox_quests.json      (WCLBox/Wowhead Forever: objective counts, status, XP)
    <research>/xp_table.json              (XP per level, quest XP rule, mob XP rule,
                                           Forever dungeon quest XP)
    tools/data/wowhead_requirements.json  (--requirements: Wowhead Forever tooltip "Requirements:"
                                           lists = Forever objective counts, written by
                                           tools/fetch_wowhead_requirements.py)

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

Scope (Horde leveling 1-60): every quest available to the Horde that touches a core (1-22) area
(CORE_AREAS, any level / class), plus every Horde quest with questLevel <= MAX_QUEST_LEVEL in any
open-world zone of Eastern Kingdoms / Kalimdor (capitals and Forever-new zones included), 5-man
dungeon quests up to MAX_DUNGEON_QUEST_LEVEL, uncategorized / profession / invasion quests whose
giver or ender spawns in the world, all PALADIN / DRUID class quests, and REF_DEPTH levels of
prerequisite / next / breadcrumb / exclusive links. Raids, battlegrounds, holidays and other
classes stay in the brief questIndex. Service NPCs: Horde / neutral / unknown-faction ones in
every zone and dungeon, Alliance ones only in the core areas.

Map sizes: zones[uiMapID].size = {width, height} in yards, from the Forever map bounds
(`geometry.transforms[].target_bounds` of QuestieDB data/Forever/conversion.json: width =
|left - right|, height = |top - bottom|), so the validator can measure distances in yards.
The Forever-new maps (Riverglades, Mount Hyjal, Darkspear Islands, Shen'dralas) have no bounds
there; their size comes from the WCLBox map mirror (WCLBOX_MAP_PIXELS, records carry
`sizeSrc = "wclbox-map"`). Zephras Isle (2521) stays without a size for now (see WCLBOX_MAP_PIXELS).

Objective counts: the Wowhead Forever tooltip "Requirements:" list (--requirements, matched by
objective name) wins; then WCLBox `goals` / `need`, then the number in front of the objective's name
in the QuestieDB objective text. The research counts are Classic-era (e.g. 545 Dalaran Patrols 12
Elemental Slaves, Forever 8) and Forever-new quests often have none (meta.counts.objectiveCounts.*).

Area triggers: a quest completed by an area trigger (exploration, "leap from the planks") keeps
`objectives.event = true` plus `objectives.trigger = {[uiMapID] = {{x, y}, ...}}` (QuestieDB
triggerEnd spawns), so the validator can check that the route's `complete` step goes there; an escort
(trigger text "Escort ...") also has `objectives.escort = true` (the trigger is where it ends).

Objective icons: creature / killCredit objectives keep QuestieDB's objective icon when it is
not the default (`icon = N`, enums.iconTypes: 3 EVENT, 5 TALK, 17 INTERACT; 0/1 = slay), so the
validator can tell "kill 8" from "speak with" / "heal" / "free" objectives (no kill XP).

Transport NPCs: zeppelin / boat / skycutter NPCs (TRANSPORT_SUBNAMES, TRANSPORT_IDS) with a known
spawn on any map, and the friendly NPCs at transport landings without a dock NPC
(TRANSPORT_LANDINGS, e.g. Skywatcher Plateau where the Valanaar skycutter lands), are full NPC
records with `transport = "zeppelin|boat|skycutter|landing"`, so routes can anchor travel steps
on them (research/mechanics.md "Zeppelins", "Skyborne leaving Zephras Isle").

Spawn thinning: objective mobs / drop sources with many spawns keep ONE spawn per
SPAWN_GRID x SPAWN_GRID map-unit cell (the one nearest the cell centre), so every cluster
keeps a representative; such records carry `spawnsGrid = SPAWN_GRID` (every real spawn is
within SPAWN_GRID * sqrt(2) map units of a kept one).

Supplements: gaps of the research inputs found while writing routes (a missing quest ender, a wrong
npcFlags bit, a missing spawn or object) are filled from the SUPPLEMENT_* tables before anything
else, only where the input lacks the data; each entry names its source (meta.counts.supplements.*).

The output is deterministic (sorted keys, no wall-clock timestamp; the snapshot date is
the fixed --date value). Run:

    python3 -I tools/build_db_snapshot.py --research DIR --conversion FILE|none [--out FILE]
                                          [--date YYYY-MM-DD] [--requirements FILE|none]
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
DEFAULT_REQUIREMENTS = os.path.join(HERE, "data", "wowhead_requirements.json")
DEFAULT_DATE = "2026-11-07"

BUILD = ["1.60.1", "70862"]
INTERFACE = 16001

# Core (1-22) areas: EVERY quest available to the Horde that touches them (zone or start/finish
# spawn) is in the snapshot, whatever its level or class (sub-areas are resolved through the
# parent chain of research zones.json). Kept from the 1-22 snapshot so it stays a superset.
CORE_AREAS = OrderedDict([
    (85, "Tirisfal Glades"), (1497, "Undercity"), (130, "Silverpine Forest"), (14, "Durotar"),
    (1637, "Orgrimmar"), (17, "The Barrens"), (406, "Stonetalon Mountains"), (331, "Ashenvale"),
    (215, "Mulgore"), (1638, "Thunder Bluff"), (267, "Hillsbrad Foothills"),
    (16593, "Zephras Isle"), (493, "Moonglade"), (16591, "Riverglades"),
    (2437, "Ragefire Chasm"), (718, "Wailing Caverns"), (16611, "Ruins of Lordaeron"),
    (16919, "The Hall of Thanes"),
])
# World scope (Horde leveling 1-60): every open-world zone of Eastern Kingdoms and Kalimdor,
# capitals and Forever-new zones included = every native (non-override) uiMap of research
# zones.json except the world / continent maps and the battleground maps.
NON_ZONE_UIMAPS = OrderedDict([
    (947, "Azeroth"), (1414, "Kalimdor"), (1415, "Eastern Kingdoms"),
    (1459, "Alterac Valley"), (1460, "Warsong Gulch"), (1461, "Arathi Basin"),
])
# AreaIDs used by quests but absent from research zones.json: Blackrock Mountain (25) is the
# open-world hub between Searing Gorge and Burning Steppes (WCLBox renwu/index.json lists it as an
# Eastern Kingdoms zone, slug blackrock-mountain).
EXTRA_WORLD_AREAS = OrderedDict([(25, "Blackrock Mountain")])
# Raid and battleground AreaIDs (WCLBox renwu/index.json groups "raid" / "battleground"): their
# quests are not leveling content and stay in questIndex. Every other dungeon of zones.json
# (`dungeon` set, or listed as one of its alternativeAreaIds) is a 5-man dungeon.
RAID_AREAS = OrderedDict([
    (2717, "Molten Core"), (2159, "Onyxia's Lair"), (2677, "Blackwing Lair"), (1977, "Zul'Gurub"),
    (3429, "Ruins of Ahn'Qiraj"), (3428, "Temple of Ahn'Qiraj"), (3456, "Naxxramas"),
])
BATTLEGROUND_AREAS = OrderedDict([(2597, "Alterac Valley"), (3277, "Warsong Gulch"), (3358, "Arathi Basin")])
MAX_QUEST_LEVEL = 62          # world quests up to this questLevel (Horde, any race incl. Skyborne)
MAX_DUNGEON_QUEST_LEVEL = 60  # dungeon quests (zoneOrSort = a 5-man dungeon) up to this questLevel
# QuestSort keys (negative zoneOrSort) of class quests in scope.
CLASS_SORTS = {-141: "PALADIN", -263: "DRUID"}
SCOPE_CLASSES = ("PALADIN", "DRUID")
# QuestSort keys never selected by the world rule (holidays / world events / legendary and epic
# chains / other classes / battlegrounds); they stay in questIndex (enums.json sortKeys).
EXCLUDED_SORTS = OrderedDict([
    (-1, "EPIC"), (-21, "HALLOWS_END"), (-22, "SEASONAL"), (-25, "BATTLEGROUNDS"),
    (-41, "DAY_OF_THE_DEAD"), (-344, "LEGENDARY"), (-364, "DARKMOON_FAIRE"), (-365, "AHN_QIRAJ_WAR"),
    (-366, "LUNAR_FESTIVAL"), (-369, "MIDSUMMER"), (-370, "BREWFEST"), (-374, "NOBLEGARDEN"),
    (-375, "PILGRIMS_BOUNTY"), (-376, "LOVE_IS_IN_THE_AIR"), (-378, "CHILDRENS_WEEK"),
    (-402, "HARVEST_FESTIVAL"), (-404, "WINTER_VEIL"),
    (-81, "WARRIOR"), (-82, "SHAMAN"), (-61, "WARLOCK"), (-161, "MAGE"), (-162, "ROGUE"),
    (-261, "HUNTER"), (-262, "PRIEST"), (-372, "DEATHKNIGHT"), (-395, "MONK"),
])
# Uncategorized quests (no zone sort) and profession / reputation / invasion quests are selected
# when a start or finish NPC/object spawns in a world zone.
# Extra uiMaps that exist in the Forever client but have no AreaID assignment in the
# reviewed DBC export (QuestieDB docs/forever-data.md "Outstanding export gaps").
EXTRA_UIMAPS = {
    2665: {"name": "Zephras Isle (secondary map)", "areaId": 16593,
           "note": "unresolved in QuestieDB export; no spawns are keyed to it"},
}
# World size of the Forever-new maps, which conversion.json lists in geometry.added_maps WITHOUT
# bounds: WCLBox map mirror (https://wowforever.wclbox.com/shuju/en/maps.json, `paint[].bounds` of
# <uiMap>.webp, client build 1.60.1.70178) in map pixels at 512 px per ADT tile of 533 1/3 yards.
# Check: pixel size * 533.333/512 reproduces conversion.json target_bounds to 0.1 yard on all 49
# maps that have both (confidence: likely). {uiMapID: (widthPx, heightPx, source map slug)}.
# Zephras Isle 2521 (5340 x 3560 px on map "zephras-isle" = 5562.5 x 3708.3 yd) is deliberately NOT
# sized yet: the validator fixtures (tests/spec/validator_fixtures_spec.lua, FastesBoooy_FxNpcFar) use
# it as the map-percent fallback example; add it here once they use another map without a size.
WCLBOX_MAP_PIXELS = OrderedDict([
    (2482, (3334.0, 2222.0, "kalimdor")),           # Mount Hyjal
    (2524, (1848.0, 1232.0, "darkspear-islands")),  # Darkspear Islands
    (2548, (4656.0, 3104.0, "eastern-kingdoms")),   # Riverglades
    (2652, (1968.0, 1312.0, "kalimdor")),           # Shen'dralas
])
YARDS_PER_MAP_PIXEL = 1600.0 / 3.0 / 512.0  # 533 1/3 yards per 512-pixel tile
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
# Transport NPCs (zeppelins, boats, skycutters): matched on the lower-case subName (substring) or
# by id, included as full records (with `transport = kind`) wherever they spawn.
TRANSPORT_SUBNAMES = OrderedDict([
    ("zeppelin master", "zeppelin"), ("zeppelin operator", "zeppelin"),
    ("shipmaster", "boat"), ("boat operator", "boat"), ("dockmaster", "boat"),
    ("captain of the skycutter", "skycutter"),
])
TRANSPORT_IDS = OrderedDict([
    (275270, "skycutter"),  # Windshapers Dockmaster, Valanaar Skydocks (Horde skycutter to Mulgore)
    (275269, "skycutter"),  # High Order Dockmaster, Zephras Isle (Alliance side)
])
# Transport landings without a dock NPC: every friendly (friendlyToFaction set) NPC spawning in
# the box (AreaID, x1, y1, x2, y2 in that AreaID's map percent) is included as transport="landing".
TRANSPORT_LANDINGS = [
    # Skywatcher Plateau (AreaID 17045, spawns keyed to Mulgore 215): the Valanaar skycutter lands here
    (215, 31.0, 19.5, 35.5, 25.5, "Skywatcher Plateau"),
]
# Forever-new NPCs often come without npcFlags (QuestieDB generated rows: npcFlags 0), e.g. 255993
# Grakna <Wind Rider Master>, the Riverglades flight master. For such NPCs the service flags are
# inferred from the subName (records get `flagsSrc = "subName"`); placeholder / unfinished NPCs are
# skipped. Regexes on the lower-case subName -> npcFlags bits (ALL_FLAGS).
SUBNAME_FLAGS = [
    (re.compile(r"(wind rider|gryphon|hippogryph|bat) (master|handler)|flight master"), ("flightmaster",)),
    (re.compile(r"innkeeper"), ("innkeeper",)),
    (re.compile(r"stable master"), ("stablemaster",)),
    (re.compile(r"\btrainers?\b"), ("trainer",)),
    (re.compile(r"armorer|weaponsmith|armorcrafter"), ("vendor", "repair")),
    (re.compile(r"vendor|merchant|quartermaster|supplies|goods|butcher|baker|food|drink|reagents"), ("vendor",)),
]
SUBNAME_SKIP = re.compile(r"\bnyi\b|<ph>|\[ph\]|\bdebug\b|\bptr\b|placeholder|reuse me|unused")
# UnitRace() raceFile -> QuestieDB/Forever race bit. Skyborne shares one raceFile for both
# factions (raceID 95 = Alliance, 96 = Horde): resolved by faction.
RACEFILE_TO_KEY = OrderedDict([
    ("Human", "HUMAN"), ("Orc", "ORC"), ("Dwarf", "DWARF"), ("NightElf", "NIGHT_ELF"),
    ("Scourge", "UNDEAD"), ("Tauren", "TAUREN"), ("Gnome", "GNOME"), ("Troll", "TROLL"),
    ("Goblin", "GOBLIN"),
])
# Gaps of the research inputs found while writing routes, filled from other sources (explicit, minimal,
# deterministic: applied to the raw QuestieDB records before anything else, counted in
# meta.counts.supplements.*). Every entry names its source.
#   * quest enders missing in QuestieDB (Forever-new quests whose trace has a starter only) where the
#     objective text names the starter as the recipient (QuestieDB foreverQuestTraces objectivesText,
#     identical in the Wowhead Forever tooltip https://nether.wowhead.com/forever/tooltip/quest/<id>):
SUPPLEMENT_QUEST_ENDERS = OrderedDict([
    (96222, [253066]),  # Khan Hratha: "Bring the Maraudine Key Fragment to Umarak in the Desolace."
    (97265, [268705]),  # Hate the Hatefury: "... and then return to Aka'rai in S..."
    (97539, [12920]),   # Silky Sutures: "Return 12 Surgical Spidersilk to Doctor Gregory Victor in Hammerfall"
])
#   * npcFlags bits wrongly set: 11741 Dredge Crusher carries QUEST_GIVER (2) but is a hostile beast
#     (factionID 14, Wowhead Forever tooltip "Level 57 - 58 Beast (Normal)") that starts / ends no quest
#     -- the flag made the validator treat the 20 kills of 8281 Stepping Up Security as a service NPC:
SUPPLEMENT_NPC_FLAGS_CLEAR = OrderedDict([(11741, 2)])
#   * spawns missing in QuestieDB: {npcId: (AreaID, [[x, y], ...], source)}
SUPPLEMENT_NPC_SPAWNS = OrderedDict([
    # Sulhasa, Forever-new giver / ender of 98093 Field to Clear (QuestieDB authored row without spawns)
    (14242, (17, [[47.9, 77.6]], "Wowhead Forever tooltip npc/14242: map zone 17 (The Barrens) 47.9,77.6")),
])
#   * objects missing in QuestieDB but referenced by an item (objectDrops): {objectId: (name, AreaID, points, source)}
SUPPLEMENT_OBJECTS = OrderedDict([
    # Stolen Freewind Supplies (container), drop source of item 279383 for 98069 Stolen Freewind Supplies
    (670338, ("Stolen Freewind Supplies", 400, [
        [25.9, 52.5], [26.1, 54.9], [26.1, 56], [26.4, 52.2], [26.5, 53.2], [26.6, 51.9], [26.7, 56.2], [26.8, 53.5],
        [27, 47.2], [27, 55.3], [27.1, 48.7], [27.3, 51], [27.6, 48.4], [27.6, 49.4], [27.9, 50.4], [28, 50.5]],
        "Wowhead Forever tooltip object/670338: map zone 400 (Thousand Needles), 16 spawns")),
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


class LuaList(list):
    """A list with named fields: written as one Lua constructor `{a, b, k = v}` (array part
    first, then the fields in insertion order), e.g. an objective `{251902, icon = 5}`."""

    def __init__(self, items, fields=None):
        super().__init__(items)
        self.fields = OrderedDict(fields or ())

    def __eq__(self, other):
        if not isinstance(other, list):
            return NotImplemented
        return list(self) == list(other) and self.fields == getattr(other, "fields", OrderedDict())

    def __ne__(self, other):
        r = self.__eq__(other)
        return r if r is NotImplemented else not r

    __hash__ = None


def lua_inline(v):
    """Single-line Lua constructor."""
    if v is None:
        return "nil"
    if isinstance(v, (bool, int, float)):
        return lua_num(v)
    if isinstance(v, str):
        return lua_str(v)
    if isinstance(v, LuaList):
        parts = [lua_inline(x) for x in v]
        parts += [lua_key(k) + "=" + lua_inline(x) for k, x in v.fields.items() if x is not None]
        return "{" + ",".join(parts) + "}"
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
        self._cat = {}
        # native zone maps of Eastern Kingdoms / Kalimdor (capitals and Forever-new zones included)
        self.world_uimaps = set(um for um, u in self.uimaps.items()
                                if not u.get("override") and um not in NON_ZONE_UIMAPS)
        # dungeon alternativeAreaIds without a parent / map of their own (e.g. 1417 Sunken Temple ->
        # 1477 The Temple of Atal'Hakkar); outdoor alternatives such as 1717 Razorfen Kraul (The
        # Barrens) keep their world zone
        self.alt_dungeon = {}
        for area, a in sorted(self.areas.items()):
            for alt in ((a.get("dungeon") or {}).get("alternativeAreaIds") or []):
                r = self.areas.get(alt) if isinstance(alt, int) else None
                if r is not None and not r.get("parentAreaId") and not r.get("uiMapId") and not r.get("dungeon"):
                    self.alt_dungeon.setdefault(alt, area)

    def category(self, area):
        """'world' | 'dungeon' | 'raid' | 'battleground' | None (unknown / other) for an AreaID,
        through its parent chain."""
        if not isinstance(area, int) or area <= 0:
            return None
        if area in self._cat:
            return self._cat[area]
        chain = self.chain(area)
        cat = None
        for a in chain:
            a = self.alt_dungeon.get(a, a)
            if a in RAID_AREAS:
                cat = "raid"
            elif a in BATTLEGROUND_AREAS:
                cat = "battleground"
            elif (self.areas.get(a) or {}).get("dungeon"):
                cat = "dungeon"
            if cat:
                break
        if cat is None:
            for a in chain:
                if a in EXTRA_WORLD_AREAS or self.ui_map(a) in self.world_uimaps:
                    cat = "world"
                    break
        self._cat[area] = cat
        return cat

    def in_world(self, area):
        return self.category(area) == "world"

    def top(self, area):
        """Top-level area of the parent chain (dungeon alternative ids resolved)."""
        chain = self.chain(area) if isinstance(area, int) and area > 0 else []
        if not chain:
            return None
        t = chain[-1]
        return self.alt_dungeon.get(t, t)

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

    def in_core(self, area):
        """In one of the core (1-22) areas."""
        if not isinstance(area, int) or area <= 0:
            return False
        return any(a in CORE_AREAS for a in self.chain(area))

    def in_scope(self, area):
        """Open world or a 5-man dungeon (where quests / service NPCs are collected)."""
        return self.in_core(area) or self.category(area) in ("world", "dungeon")

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
    def __init__(self, research, requirements=None):
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
        # optional: WCLBox quests of the 20-60 zone lists (same format); fills quests missing from
        # wclbox_quests.json (objective counts, status, XP)
        p60 = os.path.join(dbdir, "wclbox_quests_60.json")
        if os.path.isfile(p60):
            self.paths["wclbox60"] = p60
        self.qraw = {int(k): v for k, v in load_json(self.paths["quests"])["data"].items()}
        self.nraw = {int(k): v for k, v in load_json(self.paths["npcs"])["data"].items()}
        self.oraw = {int(k): v for k, v in load_json(self.paths["objects"])["data"].items()}
        self.iraw = {int(k): v for k, v in load_json(self.paths["items"])["data"].items()}
        self.zjson = load_json(self.paths["zones"])
        self.zones = Zones(self.zjson)
        self.enums = load_json(self.paths["enums"])
        self.wcl = {int(k): v for k, v in load_json(self.paths["wclbox"])["data"].items()}
        if "wclbox60" in self.paths:
            for k, v in load_json(self.paths["wclbox60"])["data"].items():
                self.wcl.setdefault(int(k), v)
        self.xpt = load_json(self.paths["xp_table"])
        # Wowhead Forever "Requirements:" lists: {questID: [[name, count|None], ...]}
        self.req = {}
        if requirements:
            self.paths["requirements"] = requirements
            for k, v in load_json(requirements)["data"].items():
                self.req[int(k)] = v
        self.count_stats = OrderedDict([("wowhead", 0), ("wowheadChanged", 0), ("research", 0)])
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
        self.transport = OrderedDict()
        self.sizes = {}  # {uiMapID: [widthYards, heightYards]} (set by main before build_entities)
        self.thin_worst = {"maps": 0, "units": 0.0, "yards": 0.0, "yardsMap": None}
        self.apply_supplements()

    def apply_supplements(self):
        """Fill the research-input gaps of the SUPPLEMENT_* tables (only where the input lacks the data)."""
        n = OrderedDict([("questEnders", 0), ("npcFlagsCleared", 0), ("npcSpawns", 0), ("objects", 0)])
        for qid, npcs in SUPPLEMENT_QUEST_ENDERS.items():
            q = self.qraw.get(qid)
            fb = (q or {}).get("finishedBy") or {}
            if q is not None and not fb.get("npcs") and not fb.get("objects"):
                q = dict(q)
                q["finishedBy"] = {"npcs": [{"id": i} for i in npcs], "objects": []}
                self.qraw[qid] = q
                n["questEnders"] += 1
        for nid, bit in SUPPLEMENT_NPC_FLAGS_CLEAR.items():
            r = self.nraw.get(nid)
            if r is not None and has_bit(r.get("npcFlags") or 0, bit):
                r = dict(r)
                r["npcFlags"] = (r.get("npcFlags") or 0) - bit
                self.nraw[nid] = r
                n["npcFlagsCleared"] += 1
        for nid, (area, pts, _src) in SUPPLEMENT_NPC_SPAWNS.items():
            r = self.nraw.get(nid)
            if r is not None and not r.get("spawns"):
                r = dict(r)
                r["spawns"] = {str(area): [list(p) for p in pts]}
                if not r.get("zoneID"):
                    r["zoneID"] = area
                self.nraw[nid] = r
                n["npcSpawns"] += 1
        for oid, (name, area, pts, _src) in SUPPLEMENT_OBJECTS.items():
            if oid not in self.oraw:
                self.oraw[oid] = {"id": oid, "name": name, "zoneID": area,
                                  "spawns": {str(area): [list(p) for p in pts]}}
                n["objects"] += 1
        for k, v in n.items():
            self.stats["supplements." + k] = v

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

    def giver_areas(self, q):
        """AreaIDs of the start/finish NPC/object spawns only."""
        out = set()
        sb, fb = q.get("startedBy") or {}, q.get("finishedBy") or {}
        for nid in ids_of(sb.get("npcs")) + ids_of(fb.get("npcs")):
            out.update(int(a) for a in (self.nraw.get(nid, {}).get("spawns") or {}))
        for oid in ids_of(sb.get("objects")) + ids_of(fb.get("objects")):
            out.update(int(a) for a in (self.oraw.get(oid, {}).get("spawns") or {}))
        return out

    def world_reason(self, q, per):
        """Why a Horde-available quest outside the core areas is selected ("world", "dungeon",
        "giver"), or None: questLevel <= MAX_QUEST_LEVEL, not restricted to other classes, not an
        excluded QuestSort; zone = an open-world zone, or a 5-man dungeon with questLevel <=
        MAX_DUNGEON_QUEST_LEVEL; no zone / sort / unknown area: a start or finish spawn in the world."""
        ql = q.get("questLevel") or 0
        if ql > MAX_QUEST_LEVEL:
            return None
        rc = q.get("requiredClasses") or 0
        if rc:
            ck = self.enums["classKeys"]
            if not any(has_bit(rc, ck[c]) for c in SCOPE_CLASSES):
                return None
        zs = q.get("zoneOrSort") or 0
        if zs in EXCLUDED_SORTS:
            return None
        if zs > 0:
            cat = self.zones.category(zs)
            if cat == "world":
                return "world"
            if cat == "dungeon":
                return "dungeon" if ql <= MAX_DUNGEON_QUEST_LEVEL else None
            if cat in ("raid", "battleground"):
                return None
        areas = self.giver_areas(q)
        for p in per.values():
            areas |= self.giver_areas(p)
        if any(self.zones.in_world(a) for a in areas):
            return "giver"
        return None

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
            if any(self.zones.in_core(a) for a in areas):
                core.add(qid)
                reason[qid] = "zone"
                continue
            r = self.world_reason(q, per)
            if r:
                core.add(qid)
                reason[qid] = r
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
        self.stats["questsByCoreArea"] = sum(1 for q in core if reason.get(q) == "zone")
        self.stats["questsByWorldZone"] = sum(1 for q in core if reason.get(q) == "world")
        self.stats["questsByDungeon"] = sum(1 for q in core if reason.get(q) == "dungeon")
        self.stats["questsByGiverSpawn"] = sum(1 for q in core if reason.get(q) == "giver")
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

    def objective_counts(self, qid, q, stats=False):
        """{('creature'|'killCredit'|'item'|'object', id): count}: Wowhead Forever "Requirements:" (by
        objective name), else WCLBox, else the objective text. stats: count the sources (main record)."""
        counts = self.research_counts(qid, q)
        req = self.req.get(qid) or []
        if not req:
            if stats:
                self.count_stats["research"] += len(counts)
            return counts
        free = list(range(len(req)))

        def take(name):
            if not name:
                return None
            for i in free:
                if req[i][0].lower() == name.lower():
                    free.remove(i)
                    return req[i][1] or 1
            return None
        obj = q.get("objectives") or {}
        keyed = [("creature", c["id"], c.get("name")) for c in obj.get("creature") or []]
        keyed += [("killCredit", k.get("baseId"), k.get("baseName")) for k in obj.get("killCredit") or []]
        keyed += [("item", i["id"], i.get("name")) for i in obj.get("item") or []]
        keyed += [("object", o["id"], o.get("name")) for o in obj.get("object") or []]
        out = OrderedDict()
        for kind, oid, name in keyed:
            key = (kind, oid)
            n = take(name)
            if n is not None:
                if stats:
                    self.count_stats["wowhead"] += 1
                    if counts.get(key) != n:
                        self.count_stats["wowheadChanged"] += 1
                out[key] = n
            elif counts.get(key):
                if stats:
                    self.count_stats["research"] += 1
                out[key] = counts[key]
        return out

    def research_counts(self, qid, q):
        """{('creature'|'item'|'object', id): count} from WCLBox then the text."""
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

    @staticmethod
    def objective_icon(o):
        """[("icon", N)] for a non-default objective icon (0 = unset, 1 = slay), else []."""
        icon = o.get("icon")
        if isinstance(icon, int) and icon not in (0, 1):
            return [("icon", icon)]
        return []

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
            cr.append(LuaList([c["id"], n] if n else [c["id"]], self.objective_icon(c)))
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
            e.update(self.objective_icon(k))
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
            te = q["triggerEnd"] or {}
            trig, _inst, _raw, _thinned = self.convert_spawns(te.get("spawns"), None)
            if trig:
                objectives["trigger"] = trig
                if re.search(r"escort", te.get("text") or "", flags=re.I):
                    objectives["escort"] = True  # the trigger is where the escort ENDS (it starts at the giver)
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
            counts = self.objective_counts(qid, q, stats=True)
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
        self.stats.update(("objectiveCounts." + k, v) for k, v in self.count_stats.items())
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
                kept = thin_spatial(pts, SPAWN_GRID)
                self._thin_check(um, pts, kept)
                pts = kept
                thinned = True
            out[um] = [[x, y] for x, y in pts]
        raw = OrderedDict()
        for area in sorted(raw_areas):
            raw[area] = [[x, y] for x, y in sorted(set(raw_areas[area]))]
        return out, sorted(instance), raw, thinned

    def _thin_check(self, um, pts, kept):
        """Worst distance from a dropped spawn to the nearest kept one (map units and, when the map
        size is known, yards), accumulated in self.thin_worst for the snapshot counts."""
        size = self.sizes.get(um)
        worst_u, worst_y = 0.0, 0.0
        for x, y in pts:
            bu, by = None, None
            for kx, ky in kept:
                du = ((x - kx) ** 2 + (y - ky) ** 2) ** 0.5
                if bu is None or du < bu:
                    bu = du
                if size:
                    dy = (((x - kx) * size[0] / 100.0) ** 2 + ((y - ky) * size[1] / 100.0) ** 2) ** 0.5
                    if by is None or dy < by:
                        by = dy
            worst_u = max(worst_u, bu or 0.0)
            worst_y = max(worst_y, by or 0.0)
        t = self.thin_worst
        t["maps"] += 1
        t["units"] = max(t["units"], worst_u)
        if worst_y > t["yards"]:
            t["yards"], t["yardsMap"] = worst_y, um

    def npc_flags(self, flags):
        out = OrderedDict()
        for name, bit in ALL_FLAGS.items():
            if has_bit(flags or 0, bit):
                out[name] = True
        return out

    def subname_flags(self, n):
        """npcFlags inferred from the subName of a flagless NPC with an open-world spawn
        (SUBNAME_FLAGS), or 0."""
        if n.get("npcFlags"):
            return 0
        if not any(self.zones.in_world(int(a)) and any(isinstance(p, list) and len(p) >= 2 and p[0] != -1
                                                       for p in pts or [])
                   for a, pts in (n.get("spawns") or {}).items()):
            return 0
        sub = (n.get("subName") or "").lower()
        if not sub or SUBNAME_SKIP.search(sub) or SUBNAME_SKIP.search((n.get("name") or "").lower()):
            return 0
        bits = set()
        for rx, names in SUBNAME_FLAGS:
            if rx.search(sub):
                bits.update(ALL_FLAGS[nm] for nm in names)
        return sum(sorted(bits))

    def effective_npc(self, n):
        hd = n.get("hordeDynamic")
        if not hd:
            return self._with_inferred_flags(n)
        return self._with_inferred_flags(self._dynamic_npc(n, hd))

    def _with_inferred_flags(self, n):
        inferred = self.subname_flags(n)
        if not inferred:
            return n
        r = dict(n)
        r["npcFlags"] = inferred
        r["_flagsSrc"] = "subName"
        return r

    def _dynamic_npc(self, n, hd):
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
            if n.get("_flagsSrc"):
                rec["flagsSrc"] = n["_flagsSrc"]
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
        kind = self.transport.get(nid)
        if kind:
            rec["transport"] = kind
        return rec

    def transport_kind(self, nid, n):
        """Transport role of an NPC ("zeppelin" / "boat" / "skycutter" / "landing") or None."""
        if nid in TRANSPORT_IDS:
            return TRANSPORT_IDS[nid]
        sub = (n.get("subName") or "").lower()
        for pat, kind in TRANSPORT_SUBNAMES.items():
            if pat in sub:
                return kind
        if n.get("friendlyToFaction"):
            for area, x1, y1, x2, y2, _label in TRANSPORT_LANDINGS:
                for p in (n.get("spawns") or {}).get(str(area)) or []:
                    if isinstance(p, list) and len(p) >= 2 and x1 <= p[0] <= x2 and y1 <= p[1] <= y2:
                        return "landing"
        return None

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

    def service_in_scope(self, n):
        """Service NPC wanted in the snapshot: any faction in the core areas; elsewhere in the world
        or a dungeon only when not Alliance-only (friendlyToFaction H / AH / unknown)."""
        areas = [int(a) for a in (n.get("spawns") or {})]
        if any(self.zones.in_core(a) for a in areas):
            return True
        if (n.get("friendlyToFaction") or "") == "A":
            return False
        return any(self.zones.in_scope(a) for a in areas)

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
        for nid, n0 in self.nraw.items():
            n = self.effective_npc(n0)
            fl = n.get("npcFlags") or 0
            if any(has_bit(fl, b) for b in SERVICE_FLAGS.values()) and self.service_in_scope(n):
                service.add(nid)
        # class trainers of the scope classes anywhere (e.g. Moonglade, capitals)
        for nid, n in self.nraw.items():
            sub = (n.get("subName") or "").lower()
            if any((c.lower() + " trainer") in sub for c in SCOPE_CLASSES):
                service.add(nid)
        # zeppelin / boat / skycutter NPCs with a known spawn (any map: the Grom'gol and Booty Bay
        # ends of Horde transports too) and the NPCs at transport landings
        self.transport = OrderedDict()
        for nid in sorted(self.nraw):
            n = self.effective_npc(self.nraw[nid])
            kind = self.transport_kind(nid, n)
            if kind and n.get("spawns"):
                self.transport[nid] = kind

        full_npcs = (refs["npcs"] | service | set(self.transport))
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
        for fac in ("H", "AH", "A", ""):
            self.stats["npcs.service." + (fac or "unknown")] = len(
                [n for n in service if (self.effective_npc(self.nraw[n]).get("friendlyToFaction") or "") == fac])
        self.stats["npcs.transport"] = len(self.transport)
        self.stats["npcs.mobsAndDropSources"] = len(mob_npcs)
        self.stats["npcs.missingFromDB"] = len([n for n in full_npcs | mob_npcs if n not in self.nraw])
        self.stats["objects.missingFromDB"] = len([o for o in full_objs | refs["mobObjects"] | drop_objs
                                                   if o not in self.oraw])
        self.stats["items.missingFromDB"] = len([i for i in refs["items"] if i not in self.iraw])
        t = self.thin_worst
        self.stats["spawnsThinned.maps"] = t["maps"]
        self.stats["spawnsThinned.worstMapUnits"] = round(t["units"], 2)
        self.stats["spawnsThinned.worstYards"] = round(t["yards"], 1)
        if t["yardsMap"]:
            self.stats["spawnsThinned.worstYardsMap"] = t["yardsMap"]
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
            if self.zones.in_scope(u.get("areaId")):
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
        for area, name in EXTRA_WORLD_AREAS.items():
            area_names.setdefault(area, name)
        area_names = OrderedDict(sorted(area_names.items()))
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
        # top-level areas whose quests / service NPCs are collected: the core areas, every open-world
        # zone and every 5-man dungeon
        scope = OrderedDict()
        for area in sorted(self.zones.areas):
            a = self.zones.areas[area]
            if a.get("name") and not a.get("parentAreaId") and area not in self.zones.alt_dungeon \
                    and self.zones.in_scope(area):
                scope[area] = a["name"]
        for area, name in EXTRA_WORLD_AREAS.items():
            scope.setdefault(area, name)
        scope = OrderedDict(sorted(scope.items()))
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
        it = self.enums.get("iconTypes") or {}
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
            ("iconTypes", OrderedDict((k, it[k]) for k in sorted(it))),
            # quests[id].reqSkill = {skillLineID, value}: the profession names (validator: quest-profession)
            ("professions", OrderedDict((k, v) for k, v in sorted((self.enums.get("professionKeys") or {}).items()))),
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


def add_wclbox_map_sizes(sizes):
    """Sizes of the Forever-new maps (WCLBOX_MAP_PIXELS) where conversion.json has none."""
    added = []
    for um, (wpx, hpx, _slug) in WCLBOX_MAP_PIXELS.items():
        if um not in sizes:
            sizes[um] = [round(wpx * YARDS_PER_MAP_PIXEL, 1), round(hpx * YARDS_PER_MAP_PIXEL, 1)]
            added.append(um)
    return added


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--research", required=True, help="research directory (contains db/ and xp_table.json)")
    ap.add_argument("--conversion", required=True,
                    help="QuestieDB data/Forever/conversion.json (map bounds -> zone sizes in yards), "
                         "or 'none' (no sizes: the validator then measures distances in map percent)")
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--date", default=DEFAULT_DATE, help="snapshot date written into meta (fixed for determinism)")
    ap.add_argument("--requirements", default=DEFAULT_REQUIREMENTS,
                    help="Wowhead Forever quest requirements JSON (tools/fetch_wowhead_requirements.py; default "
                         "tools/data/wowhead_requirements.json), or 'none' (research counts only)")
    args = ap.parse_args()
    if not os.path.isdir(args.research):
        ap.error("research directory not found: %s" % args.research)
    if args.conversion != "none" and not os.path.isfile(args.conversion):
        ap.error("conversion.json not found: %s (pass --conversion none to skip zone sizes)" % args.conversion)

    if args.requirements != "none" and not os.path.isfile(args.requirements):
        ap.error("requirements file not found: %s (pass --requirements none to use the research counts only)"
                 % args.requirements)
    b = Builder(args.research, None if args.requirements == "none" else args.requirements)
    sizes = load_map_sizes(args.conversion)
    wcl_sized = add_wclbox_map_sizes(sizes) if args.conversion != "none" else []
    b.sizes = sizes
    qids, _reason = b.select_quests()
    quests, refs = b.build_quests(qids)
    npcs, objects, items = b.build_entities(refs)
    zones, area_to_ui, area_names, dungeons, scope = b.build_zones(sizes)
    for um in wcl_sized:
        if um in zones:
            zones[um]["sizeSrc"] = "wclbox-map"
    enums = b.build_enums()
    xp = b.build_xp()
    quest_brief = b.brief_quests(qids)
    npc_brief = b.brief_npcs(set(npcs))
    object_brief = b.brief_objects(set(objects))

    sources = OrderedDict()
    for k, p in b.paths.items():
        rel = "tools/data/" + os.path.basename(p) if k == "requirements" else os.path.relpath(p, args.research)
        sources[k] = OrderedDict([("file", rel), ("sha256", sha256_short(p))])
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
        ("coreAreas", OrderedDict(CORE_AREAS)),
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
        "--       WCLBox mirror of Wowhead Forever data (quest status, XP), Wowhead Forever tooltips (objective",
        "--       counts: tools/data/wowhead_requirements.json), see research/db/README.md and",
        "--       research/db/crosscheck.md. Our repository is GPL-3.0 as well.",
        "-- Coordinates: uiMapID + map percent (0-100), Forever frame (QuestieDB Forever data is already",
        "--       converted from Era; only AreaID -> uiMapID was resolved here).",
        "--",
        "-- Layout (see tools/README.md):",
        "--   quests[id]   = {name, level, reqLevel, races, classes, side=\"H|A|AH\", start={npcs,objects,items},",
        "--                   finish={npcs,objects}, preGroup, preSingle, exclusive, next, breadcrumbFor, breadcrumbs,",
        "--                   parent, children, objectives={creatures={{id,count?,icon=?}},",
        "--                   killCredit={{ids,base,count,icon}},",
        "--                   objects={{id,count?}}, items={{id,count?}}, event=true,",
        "--                   trigger={[uiMapID]={{x,y},...}}, escort=true}, sourceItem, zone, uiMap, flags,",
        "--                   reqSkill={skillLine,value},",
        "--                   special, xp, xpSrc, status=\"same|new|changed\", byClass={CLASS={overridden fields}}}",
        "--                   (objective icon only when not slay: enums.iconTypes 3 EVENT, 5 TALK, 17 INTERACT;",
        "--                   event = completes on an area trigger / scripted event: exploration, escort;",
        "--                   trigger = where the area trigger is, when known; escort = the trigger ends an escort)",
        "--   npcs[id]     = {name, sub, minLevel, maxLevel, rank, faction=\"A|H|AH|\", flags={trainer=true,...},",
        "--                   flagsSrc=\"subName\" (flags inferred for a flagless Forever NPC),",
        "--                   spawns={[uiMapID]={{x,y},...}}, spawnsGrid (thinned: one spawn per grid cell),",
        "--                   instance={AreaID,...}, zone, transport=\"zeppelin|boat|skycutter|landing\"}",
        "--   zones[uiMapID] = {name, areaId, dungeon, scope, size={widthYards, heightYards}, sizeSrc=\"wclbox-map\"}",
        "--   coreAreas / scopeAreas = {[AreaID] = name}: 1-22 core areas / every zone and 5-man dungeon in scope",
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
