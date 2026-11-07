#!/usr/bin/env python3
"""Generate tools/data/forever_api.lua -- the list of API functions, events,
FrameXML globals, templates, mixins, widget methods and enums that exist in the
World of Warcraft: Forever client ("camelot" game type, ## Interface: 16001).

Input: Ketho/BlizzardInterfaceResources, branch "forever" (a KethoDoc in-game dump).
Its Resources/*.lua files are parsed strictly AS TEXT with regular expressions;
they are never executed, loaded or imported.

Optional input (--wowui): the Blizzard FrameXML source tree of the Forever client
(Interface/AddOns). It is also read only as text: the TOC files are resolved for the
"camelot" game type and column-0 global assignments (``NAME = ...`` or
``_G.NAME = ...``) of the files that load in Forever are collected as
``frameXMLExtraGlobals`` (global tables/constants such as Settings, SlashCmdList,
RAID_CLASS_COLORS, DEFAULT_CHAT_FRAME that the BIR function lists do not contain).
Function-library tables among them (initialized at column 0 with a table constructor,
given at least one ``function Name.Field(`` and never extended through ``Mixin``),
such as Settings or UiMapPoint, also get their member list as
``frameXMLExtraTables`` (constructor keys + column-0 ``Name.Field =`` /
``function Name.Field(`` / ``function Name:Field(``), so .luacheckrc can close them.

WidgetAPI quirk: the dump lists ``Region`` as inheriting itself; the client's Region
derives from ScriptRegion, so that self-reference is written as "ScriptRegion" and the
inheritance graph is checked to be acyclic.

The output is deterministic: every list is sorted, maps are written in sorted key
order, and no timestamp other than the dump's own build date is written.

usage:
    python3 -I tools/gen_forever_api.py --bir DIR --wowui DIR|none [--out FILE]
"""
import argparse
import os
import re
import sys
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.join(HERE, "data", "forever_api.lua")

QSTR = re.compile(r'^\t"([^"]+)",\s*$')
IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
    "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}


class ParseError(Exception):
    pass


# ---------------------------------------------------------------------------
# BIR parsing (text only)
# ---------------------------------------------------------------------------

def read_lines(bir, name):
    with open(os.path.join(bir, name), "r", encoding="utf-8") as fh:
        return fh.read().split("\n")


def split_sections(lines):
    """{sectionName: [lines]} for top-level 'local X = {' ... '}' blocks."""
    sections = OrderedDict()
    cur = None
    for ln in lines:
        m = re.match(r'^local (\w+) = \{\s*$', ln)
        if m:
            cur = m.group(1)
            sections[cur] = []
            continue
        if ln.startswith("}"):
            cur = None
            continue
        if cur is not None:
            sections[cur].append(ln)
    return sections


def flat_strings(lines):
    out = []
    for ln in lines:
        m = QSTR.match(ln)
        if m:
            out.append(m.group(1))
    return out


def count_quoted(lines):
    return sum(1 for ln in lines if QSTR.match(ln))


def check(cond, msg):
    if not cond:
        raise ParseError(msg)


def split_dotted(names):
    """Split a list of names into (plain names, {table: [fields]})."""
    plain, tables = set(), {}
    for n in names:
        if "." in n:
            t, f = n.split(".", 1)
            tables.setdefault(t, set()).add(f)
        elif ":" in n:
            continue
        else:
            plain.add(n)
    return sorted(plain), OrderedDict((k, sorted(v)) for k, v in sorted(tables.items()))


def read_build(bir):
    readme_path = os.path.join(os.path.dirname(bir.rstrip("/")), "README.md")
    with open(readme_path, "r", encoding="utf-8") as fh:
        readme = fh.read()
    m = re.search(r'GetBuildInfo\(\) => "([^"]+)", "([^"]+)", "([^"]+)", (\d+)', readme)
    check(m is not None, "GetBuildInfo line not found in BIR README.md")
    build = [m.group(1), m.group(2), m.group(3), int(m.group(4))]
    meta = OrderedDict()
    for key in ("WOW_PROJECT_ID", "LE_EXPANSION_LEVEL_CURRENT", r"TOC \[Family\]", r"TOC \[Game\]"):
        mm = re.search(key + r" => (.+)", readme)
        if mm:
            meta[key.replace("\\", "")] = mm.group(1).strip()
    return build, meta


def read_git_commit(bir):
    """Read the checked-out commit of the BIR clone from .git as plain text (no git exec)."""
    gitdir = os.path.join(os.path.dirname(bir.rstrip("/")), ".git")
    try:
        with open(os.path.join(gitdir, "HEAD"), "r", encoding="utf-8") as fh:
            head = fh.read().strip()
    except OSError:
        return None, None
    if not head.startswith("ref: "):
        return None, head if re.match(r'^[0-9a-f]{40}$', head) else None
    ref = head[5:]
    branch = ref.rsplit("/", 1)[-1]
    try:
        with open(os.path.join(gitdir, ref), "r", encoding="utf-8") as fh:
            sha = fh.read().strip()
            return branch, sha if re.match(r'^[0-9a-f]{40}$', sha) else None
    except OSError:
        pass
    try:
        with open(os.path.join(gitdir, "packed-refs"), "r", encoding="utf-8") as fh:
            for ln in fh:
                parts = ln.strip().split(" ")
                if len(parts) == 2 and parts[1] == ref and re.match(r'^[0-9a-f]{40}$', parts[0]):
                    return branch, parts[0]
    except OSError:
        pass
    return branch, None


def parse_bir(bir):
    res = OrderedDict()
    checks = OrderedDict()

    # GlobalAPI.lua: GlobalAPI (C functions incl. C_ namespaces) + LuaAPI
    ga = split_sections(read_lines(bir, "GlobalAPI.lua"))
    gapi = flat_strings(ga["GlobalAPI"])
    lapi = flat_strings(ga["LuaAPI"])
    check(count_quoted(ga["GlobalAPI"]) == len(gapi), "GlobalAPI parse mismatch")
    check(count_quoted(ga["LuaAPI"]) == len(lapi), "LuaAPI parse mismatch")
    res["globals"], res["namespaces"] = split_dotted(gapi)
    res["luaGlobals"], res["luaNamespaces"] = split_dotted(lapi)
    checks["GlobalAPI"] = len(gapi)
    checks["LuaAPI"] = len(lapi)

    # Events.lua: { System = { "EVENT", ... }, ... }
    ev_lines = read_lines(bir, "Events.lua")
    events = []
    cur = None
    for ln in ev_lines:
        m = re.match(r'^\t(\w+) = \{\s*$', ln)
        if m:
            cur = m.group(1)
            continue
        if re.match(r'^\t\},?\s*$', ln):
            cur = None
            continue
        m = re.match(r'^\t\t"([A-Z0-9_]+)",\s*$', ln)
        if m and cur:
            events.append(m.group(1))
    check(sum(1 for ln in ev_lines if re.match(r'^\t\t"[A-Z0-9_]+",\s*$', ln)) == len(events),
          "Events parse mismatch")
    res["events"] = sorted(set(events))
    checks["Events"] = len(events)

    # FrameXML.lua: FrameXML + LoadOnDemand (functions and *Util.* fields)
    fx = split_sections(read_lines(bir, "FrameXML.lua"))
    fx_main = flat_strings(fx["FrameXML"])
    fx_lod = flat_strings(fx["LoadOnDemand"])
    check(count_quoted(fx["FrameXML"]) == len(fx_main), "FrameXML parse mismatch")
    res["frameXMLGlobals"], res["frameXMLTables"] = split_dotted(fx_main)
    res["frameXMLLoadOnDemandGlobals"], res["frameXMLLoadOnDemandTables"] = split_dotted(fx_lod)
    checks["FrameXML"] = len(fx_main)
    checks["FrameXML.LoadOnDemand"] = len(fx_lod)

    # Frames.lua: named frames
    fr = split_sections(read_lines(bir, "Frames.lua"))
    res["frames"] = sorted(set(flat_strings(fr["Frames"])))
    res["framesLoadOnDemand"] = sorted(set(flat_strings(fr["LoadOnDemand"])))

    # Templates.lua: ["Name"] = {type = "Frame", mixin = "...", inherits = "...", intrinsic = true}
    tpl_lines = read_lines(bir, "Templates.lua")
    tre = re.compile(r'^\t\["([^"]+)"\] = \{(.*)\},\s*$')
    template_types = {}
    for ln in tpl_lines:
        m = tre.match(ln)
        if not m:
            continue
        name, body = m.group(1), m.group(2)
        tm = re.search(r'type = "([^"]*)"', body)
        template_types[name] = tm.group(1) if tm else ""
    check(sum(1 for ln in tpl_lines if ln.startswith('\t["')) == len(template_types), "Templates parse mismatch")
    res["templates"] = sorted(template_types)
    res["templateTypes"] = OrderedDict(sorted(template_types.items()))
    # Font objects declared in XML are real global objects (GameFontNormal, ...).
    res["fonts"] = sorted(n for n, t in template_types.items() if t in ("Font", "FontFamily") and IDENT.match(n))
    checks["Templates"] = len(template_types)

    # Mixins.lua
    mx = split_sections(read_lines(bir, "Mixins.lua"))
    mixins = flat_strings(mx["Mixins"])
    check(count_quoted(mx["Mixins"]) == len(mixins), "Mixins parse mismatch")
    res["mixins"] = sorted(set(mixins))
    checks["Mixins"] = len(mixins)

    # WidgetAPI.lua: Type = { inherits = {...}, handlers = {...}, methods = {...} }
    w_lines = read_lines(bir, "WidgetAPI.lua")
    widgets = OrderedDict()
    cur = sub = None
    for ln in w_lines:
        m = re.match(r'^\t(\w+) = \{\s*$', ln)
        if m:
            cur = m.group(1)
            widgets[cur] = {"inherits": [], "handlers": [], "methods": []}
            sub = None
            continue
        if cur is None:
            continue
        m = re.match(r'^\t\tinherits = \{(.*)\},\s*$', ln)
        if m:
            widgets[cur]["inherits"] = re.findall(r'"([^"]+)"', m.group(1))
            continue
        m = re.match(r'^\t\t(handlers|methods) = \{\s*$', ln)
        if m:
            sub = m.group(1)
            continue
        if re.match(r'^\t\t(handlers|methods) = \{\},?\s*$', ln) or re.match(r'^\t\t\},?\s*$', ln):
            sub = None
            continue
        if re.match(r'^\t\},?\s*$', ln):
            cur = sub = None
            continue
        m = re.match(r'^\t\t\t"([^"]+)",\s*$', ln)
        if m and sub:
            widgets[cur][sub].append(m.group(1))
    n_lines = sum(1 for ln in w_lines if re.match(r'^\t\t\t"[^"]+",\s*$', ln))
    check(n_lines == sum(len(w["methods"]) + len(w["handlers"]) for w in widgets.values()), "WidgetAPI parse mismatch")
    # Dump quirk: Region = { inherits = {"Region"} }; in the client Region derives from ScriptRegion.
    for n, w in widgets.items():
        if n in w["inherits"]:
            check(n == "Region" and "ScriptRegion" in widgets, "unexpected widget self-inheritance: " + n)
            w["inherits"] = ["ScriptRegion" if p == n else p for p in w["inherits"]]
            checks["WidgetAPI.selfInheritanceFixed"] = n
    for w in widgets.values():
        for parent in w["inherits"]:
            check(parent in widgets, "unknown widget parent " + parent)
    state = {}

    def visit(n, path):
        if state.get(n) == "done":
            return
        check(state.get(n) != "open", "widget inheritance cycle: " + " -> ".join(path + [n]))
        state[n] = "open"
        for parent in widgets[n]["inherits"]:
            visit(parent, path + [n])
        state[n] = "done"
    for n in widgets:
        visit(n, [])
    res["widgetMethods"] = OrderedDict((n, sorted(set(w["methods"]))) for n, w in sorted(widgets.items()))
    res["widgetHandlers"] = OrderedDict((n, sorted(set(w["handlers"]))) for n, w in sorted(widgets.items()))
    res["widgetInherits"] = OrderedDict((n, list(w["inherits"])) for n, w in sorted(widgets.items()))
    checks["WidgetAPI.types"] = len(widgets)

    # ScriptObjectAPI.lua: methods of script objects returned by APIs
    so_lines = read_lines(bir, "ScriptObjectAPI.lua")
    so = {}
    cur = None
    for ln in so_lines:
        m = re.match(r'^\t(\w+) = \{\s*$', ln)
        if m:
            cur = m.group(1)
            so[cur] = []
            continue
        if re.match(r'^\t\},?\s*$', ln):
            cur = None
            continue
        m = re.match(r'^\t\t"([^"]+)",\s*$', ln)
        if m and cur:
            so[cur].append(m.group(1))
    res["scriptObjectMethods"] = OrderedDict((k, sorted(set(v))) for k, v in sorted(so.items()))

    # LuaEnum.lua: Enum = {...}, Constants = {...}, LE_* globals
    le_lines = read_lines(bir, "LuaEnum.lua")
    enums, consts = {}, {}
    block = curname = None
    for ln in le_lines:
        if ln.startswith("Enum = {"):
            block = enums
            continue
        if ln.startswith("Constants = {"):
            block = consts
            continue
        if ln.startswith("}"):
            block = None
            continue
        if block is None:
            continue
        m = re.match(r'^\t(\w+) = \{\s*$', ln)
        if m:
            curname = m.group(1)
            block[curname] = {}
            continue
        m = re.match(r'^\t\t(\w+) = (.+?),\s*$', ln)
        if m and curname:
            block[curname][m.group(1)] = parse_enum_value(m.group(2))
    le = {}
    for ln in le_lines:
        m = re.match(r'^([A-Z][A-Z0-9_]+) = (-?\w+)\s*$', ln)
        if m:
            le[m.group(1)] = parse_enum_value(m.group(2))
    res["enumNames"] = sorted(enums)
    res["enums"] = OrderedDict((k, OrderedDict(sorted(v.items()))) for k, v in sorted(enums.items()))
    res["constantNames"] = sorted(consts)
    res["constants"] = OrderedDict((k, OrderedDict(sorted(v.items()))) for k, v in sorted(consts.items()))
    res["leGlobals"] = sorted(le)
    res["leValues"] = OrderedDict(sorted(le.items()))
    checks["Enum"] = len(enums)
    checks["Constants"] = len(consts)
    checks["LE_globals"] = len(le)
    return res, checks


def parse_enum_value(val):
    val = val.strip()
    if val in ("true", "false"):
        return val == "true"
    if val.startswith('"') and val.endswith('"'):
        inner = val[1:-1]
        if re.match(r'^0x[0-9A-Fa-f]+$', inner):
            return int(inner, 16)
        return inner
    try:
        return int(val, 0)
    except ValueError:
        pass
    try:
        return float(val)
    except ValueError:
        return val


# ---------------------------------------------------------------------------
# optional: Blizzard FrameXML tree (text only) -> global tables/constants
# ---------------------------------------------------------------------------

# Forever = game type "camelot", family "Mainline". From the TOCs of build 70862:
# "[AllowLoadGameType mainline] [ExcludeLoadGameType camelot]" proves camelot is a
# sub-type of mainline; "standard, camelot", "classic, camelot", "vanilla, camelot"
# prove those groups do not include camelot.
CAMELOT_TOKENS = {"camelot", "mainline"}
SUBST = {"[Family]": "Mainline", "[Game]": "Camelot"}


def gametype_allows(directive_text):
    """Evaluate [AllowLoadGameType a, b] / [ExcludeLoadGameType a b] annotations."""
    ok = True
    for kind, body in re.findall(r'\[(AllowLoadGameType|ExcludeLoadGameType)\s+([^\]]*)\]', directive_text):
        toks = {t for t in re.split(r'[\s,]+', body.strip().lower()) if t}
        if kind == "AllowLoadGameType" and not (toks & CAMELOT_TOKENS):
            ok = False
        if kind == "ExcludeLoadGameType" and (toks & CAMELOT_TOKENS):
            ok = False
    return ok


def resolve_path(base_dir, rel):
    rel = rel.strip().replace("\\", "/")
    for k, v in SUBST.items():
        rel = rel.replace(k, v)
    p = os.path.normpath(os.path.join(base_dir, rel))
    if os.path.exists(p):
        return p
    # case-insensitive fallback (TOCs were written for Windows)
    cur = base_dir
    for part in rel.split("/"):
        if part in ("", "."):
            continue
        if part == "..":
            cur = os.path.dirname(cur)
            continue
        try:
            entries = os.listdir(cur)
        except OSError:
            return None
        hit = [e for e in entries if e.lower() == part.lower()]
        if not hit:
            return None
        cur = os.path.join(cur, hit[0])
    return cur if os.path.exists(cur) else None


def xml_includes(path, seen, out_lua):
    if path in seen:
        return
    seen.add(path)
    XML_FILES.append(path)
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError:
        return
    text = re.sub(r'<!--.*?-->', "", text, flags=re.S)
    for tag, attrs in re.findall(r'<(Script|Include)\b([^>]*)>', text):
        m = re.search(r'file\s*=\s*"([^"]+)"', attrs)
        if not m:
            continue
        p = resolve_path(os.path.dirname(path), m.group(1))
        if not p:
            continue
        if p.lower().endswith(".lua"):
            out_lua.append(p)
        elif p.lower().endswith(".xml"):
            xml_includes(p, seen, out_lua)


XML_FILES = []


def camelot_lua_files(addons_dir):
    files = []
    seen_xml = set()
    for addon in sorted(os.listdir(addons_dir)):
        adir = os.path.join(addons_dir, addon)
        if not os.path.isdir(adir):
            continue
        tocs = sorted(f for f in os.listdir(adir) if f.lower().endswith(".toc"))
        if not tocs:
            continue
        # Prefer a game-specific TOC (Name_Camelot.toc / Name_Mainline.toc) when present.
        chosen = None
        for suffix in ("_camelot.toc", "_mainline.toc", ".toc"):
            for t in tocs:
                if t.lower() == (addon + suffix).lower():
                    chosen = t
                    break
            if chosen:
                break
        if not chosen:
            continue
        with open(os.path.join(adir, chosen), "r", encoding="utf-8", errors="replace") as fh:
            lines = fh.read().split("\n")
        addon_ok = True
        for ln in lines:
            m = re.match(r'^##\s*AllowLoadGameType\s*:\s*(.*)$', ln.strip())
            if m:
                toks = {t for t in re.split(r'[\s,]+', m.group(1).strip().lower()) if t}
                if not (toks & CAMELOT_TOKENS):
                    addon_ok = False
            m = re.match(r'^##\s*AllowLoad\s*:\s*(\S+)', ln.strip())
            if m and m.group(1).lower() == "glue":
                addon_ok = False
            m = re.match(r'^##\s*OnlyBetaAndPTR\s*:\s*1', ln.strip())
            if m:
                addon_ok = False
        if not addon_ok:
            continue
        for ln in lines:
            s = ln.strip()
            if not s or s.startswith("#"):
                continue
            if not gametype_allows(s):
                continue
            rel = re.sub(r'\[(AllowLoadGameType|ExcludeLoadGameType)[^\]]*\]', "", s)
            rel = rel.replace("[Bootstrap]", "").strip()
            p = resolve_path(adir, rel)
            if not p:
                continue
            if p.lower().endswith(".lua"):
                files.append(p)
            elif p.lower().endswith(".xml"):
                xml_includes(p, seen_xml, files)
    out, seen = [], set()
    for f in files:
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


TABLE_FUNC = re.compile(r'^function\s+([A-Za-z_][A-Za-z0-9_]*)[.:]([A-Za-z_][A-Za-z0-9_]*)\s*\(')
TABLE_FIELD = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)')
TABLE_INIT = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*(.*?)\s*$')
CTOR_KEY = re.compile(r'^\s+([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)')


def scan_tables(lines, tables):
    """Collect member names of column-0 global tables into `tables`:
    tables[name] = {"fields": set, "funcs": int, "ctor": bool (every column-0 init is a table
    constructor), "inits": int}."""
    i = 0
    n = len(lines)
    while i < n:
        ln = lines[i]
        m = TABLE_FUNC.match(ln)
        if m:
            t = tables.setdefault(m.group(1), {"fields": set(), "funcs": 0, "ctor": True, "inits": 0})
            t["fields"].add(m.group(2))
            t["funcs"] += 1
            i += 1
            continue
        m = TABLE_FIELD.match(ln)
        if m:
            t = tables.setdefault(m.group(1), {"fields": set(), "funcs": 0, "ctor": True, "inits": 0})
            t["fields"].add(m.group(2))
            i += 1
            continue
        m = TABLE_INIT.match(ln)
        if m and m.group(1) not in LUA_KEYWORDS:
            name, rhs = m.group(1), m.group(2)
            t = tables.setdefault(name, {"fields": set(), "funcs": 0, "ctor": True, "inits": 0})
            t["inits"] += 1
            j = i
            if rhs == "" and i + 1 < n and lines[i + 1].strip().startswith("{"):
                j, rhs = i + 1, lines[i + 1].strip()
            if not rhs.startswith("{"):
                t["ctor"] = False
            elif not re.match(r'^\{\s*\}\s*;?\s*(--.*)?$', rhs):
                # multi-line constructor: top-level keys up to the closing brace at column 0
                if re.match(r'^\{\s*(--.*)?$', rhs):
                    k = j + 1
                    while k < n and not re.match(r'^\}', lines[k]):
                        cm = CTOR_KEY.match(lines[k])
                        if cm and lines[k].startswith("\t") and not lines[k].startswith("\t\t"):
                            t["fields"].add(cm.group(1))
                        k += 1
                    i = k
                else:
                    t["ctor"] = False  # one-line constructor with content: keys not parsed
        i += 1


def scan_globals(addons_dir, tables=None):
    """Return (column-0 global names, DB-driven *_COLOR names, number of files).
    With `tables` (dict), also collect member names of column-0 tables (see scan_tables)."""
    names = set()
    colors = set()
    mixed = set()
    mixin_ref = re.compile(r'\bMixin\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,')
    color_ref = re.compile(r'\b([A-Z][A-Z0-9_]*_COLOR)(_CODE)?\b')
    files = camelot_lua_files(addons_dir)
    assign = re.compile(r'^(?:_G\.)?([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)')
    assign_g = re.compile(r'^_G\["([A-Za-z_][A-Za-z0-9_]*)"\]\s*=(?!=)')
    func = re.compile(r'^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(')
    for path in files:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        text = re.sub(r'--\[(=*)\[.*?\]\1\]', "", text, flags=re.S)
        if tables is not None:
            scan_tables(text.split("\n"), tables)
            mixed.update(mixin_ref.findall(text))
        for ln in text.split("\n"):
            m = assign.match(ln) or assign_g.match(ln) or func.match(ln)
            if m and m.group(1) not in LUA_KEYWORDS:
                names.add(m.group(1))
            if "--" in ln:
                ln = ln.split("--", 1)[0]
            for cm in color_ref.finditer(ln):
                colors.add(cm.group(1))
                colors.add(cm.group(1) + "_CODE")
    # Named, non-virtual widgets declared in the loaded XML files are globals too (Minimap, ...).
    tag = re.compile(r'<([A-Za-z]+)\b([^>]*)>')
    for path in XML_FILES:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = re.sub(r'<!--.*?-->', "", fh.read(), flags=re.S)
        for _tagname, attrs in tag.findall(text):
            m = re.search(r'\bname\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"', attrs)
            if not m or re.search(r'\bvirtual\s*=\s*"true"', attrs):
                continue
            names.add(m.group(1))
    if tables is not None:
        for name in mixed:
            if name in tables:
                tables[name]["ctor"] = False  # members also come from mixins: not enumerable
    return sorted(names), sorted(colors), len(files)


def read_wowui_version(addons_dir):
    p = os.path.join(os.path.dirname(os.path.dirname(addons_dir.rstrip("/"))), "version.txt")
    try:
        with open(p, "r", encoding="utf-8") as fh:
            v = fh.read().strip()
            return v if re.match(r'^[0-9.]+$', v) else None
    except OSError:
        return None


# ---------------------------------------------------------------------------
# Lua serialization
# ---------------------------------------------------------------------------

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
        elif o < 32 or o == 127:
            out.append("\\%d" % o)
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def lua_key(k):
    if isinstance(k, str) and IDENT.match(k) and k not in LUA_KEYWORDS:
        return k
    if isinstance(k, int):
        return "[%d]" % k
    return "[" + lua_str(k) + "]"


def lua_scalar(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        r = repr(v)
        return r
    if v is None:
        return "nil"
    return lua_str(v)


def lua_list(items, indent, per_line=4):
    if not items:
        return "{}"
    pad = "    " * (indent + 1)
    parts = [lua_scalar(i) for i in items]
    lines = []
    for i in range(0, len(parts), per_line):
        lines.append(pad + ", ".join(parts[i:i + per_line]) + ",")
    return "{\n" + "\n".join(lines) + "\n" + "    " * indent + "}"


def lua_value(v, indent):
    pad = "    " * (indent + 1)
    if isinstance(v, dict):
        if not v:
            return "{}"
        lines = []
        for k in v:  # already ordered
            lines.append(pad + lua_key(k) + " = " + lua_value(v[k], indent + 1) + ",")
        return "{\n" + "\n".join(lines) + "\n" + "    " * indent + "}"
    if isinstance(v, (list, tuple)):
        return lua_list(list(v), indent)
    return lua_scalar(v)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bir", required=True, help="BlizzardInterfaceResources/Resources dir (branch forever)")
    ap.add_argument("--wowui", required=True,
                    help="Blizzard FrameXML Interface/AddOns dir of the Forever client, or 'none' to skip "
                         "frameXMLExtraGlobals/frameXMLExtraTables/uiColorGlobals")
    ap.add_argument("--out", default=DEFAULT_OUT)
    args = ap.parse_args()

    if not os.path.isdir(args.bir):
        sys.exit("BIR Resources dir not found: %s (pass --bir)" % args.bir)
    if args.wowui != "none" and not os.path.isdir(args.wowui):
        # Without the FrameXML tree frameXMLExtraGlobals/uiColorGlobals would silently become
        # empty and luacheck would then reject Settings, SlashCmdList, RAID_CLASS_COLORS, ...
        sys.exit("FrameXML dir not found: %s (pass --wowui <Interface/AddOns>, or --wowui none to "
                 "skip frameXMLExtraGlobals/uiColorGlobals on purpose)" % args.wowui)
    build, build_meta = read_build(args.bir)
    branch, commit = read_git_commit(args.bir)
    res, checks = parse_bir(args.bir)

    extra, colors, n_files, wowui_version = [], [], 0, None
    extra_tables = OrderedDict()
    if args.wowui != "none" and os.path.isdir(args.wowui):
        known = set(res["globals"]) | set(res["frameXMLGlobals"]) | set(res["luaGlobals"]) | set(res["leGlobals"])
        known |= set(res["namespaces"]) | set(res["frameXMLTables"]) | set(res["frames"]) | set(res["mixins"])
        tables = {}
        scanned, color_refs, n_files = scan_globals(args.wowui, tables)
        extra = [n for n in scanned if n not in known]
        for n in extra:
            t = tables.get(n)
            if t and t["ctor"] and t["inits"] >= 1 and t["funcs"] >= 1:
                extra_tables[n] = sorted(t["fields"])
        # Colors are created at load time from C_UIColor.GetColors() (Blizzard_SharedXMLBase/Color.lua:
        # envTbl[dbColor.baseTag] = color; envTbl[baseTag.."_CODE"] = hex). We keep those referenced by
        # camelot FrameXML that are not assigned statically anywhere.
        colors = [n for n in color_refs if n not in known and n not in set(extra)]
        wowui_version = read_wowui_version(args.wowui)
    res["frameXMLExtraGlobals"] = extra
    res["frameXMLExtraTables"] = extra_tables
    res["uiColorGlobals"] = colors
    checks["wowui.camelotLuaFiles"] = n_files
    checks["frameXMLExtraGlobals"] = len(extra)
    checks["frameXMLExtraTables"] = len(extra_tables)
    checks["uiColorGlobals"] = len(colors)

    out = OrderedDict()
    out["build"] = build
    meta = OrderedDict()
    meta["source"] = "Ketho/BlizzardInterfaceResources"
    meta["branch"] = branch or "forever"
    if commit:
        meta["commit"] = commit
    for k, v in build_meta.items():
        meta[k] = v
    if wowui_version:
        meta["frameXMLVersion"] = wowui_version
    meta["generator"] = "tools/gen_forever_api.py"
    out["meta"] = meta
    order = [
        "globals", "namespaces", "luaGlobals", "luaNamespaces", "events",
        "frameXMLGlobals", "frameXMLTables", "frameXMLExtraGlobals", "frameXMLExtraTables", "uiColorGlobals",
        "frameXMLLoadOnDemandGlobals", "frameXMLLoadOnDemandTables",
        "frames", "framesLoadOnDemand", "templates", "templateTypes", "fonts", "mixins",
        "widgetMethods", "widgetHandlers", "widgetInherits", "scriptObjectMethods",
        "leGlobals", "leValues", "enumNames", "enums", "constantNames", "constants",
    ]
    for k in order:
        out[k] = res[k]
    counts = OrderedDict()
    for k in order:
        v = res[k]
        counts[k] = len(v)
    out["counts"] = counts

    header = [
        "-- tools/data/forever_api.lua -- GENERATED by tools/gen_forever_api.py. DO NOT EDIT BY HAND.",
        "--",
        "-- API surface of the World of Warcraft: Forever client (game type \"camelot\").",
        "-- GetBuildInfo() => %s" % ", ".join(lua_scalar(b) for b in build),
        "-- Source: Ketho/BlizzardInterfaceResources, branch %s%s (KethoDoc in-game dump)," % (
            branch or "forever", (" @ " + commit) if commit else ""),
        "--         Resources/*.lua parsed as text (never executed).",
    ]
    if wowui_version:
        header.append("-- frameXMLExtraGlobals: column-0 global assignments in Blizzard FrameXML %s files" % wowui_version)
        header.append("--         that load for game type camelot (%d files, TOC directives resolved)." % n_files)
        header.append("-- frameXMLExtraTables: member names of the function-library tables among them (Settings,")
        header.append("--         UiMapPoint, ...): constructor keys + column-0 Name.Field = / function Name.Field(.")
        header.append("-- uiColorGlobals: *_COLOR / *_COLOR_CODE globals created from C_UIColor.GetColors() at load")
        header.append("--         time (Blizzard_SharedXMLBase/Color.lua), as referenced by camelot FrameXML code.")
    header += [
        "--",
        "-- Layout:",
        "--   globals / luaGlobals        plain global function names (C API / Lua+WoW Lua helpers)",
        "--   namespaces                  { C_QuestLog = {\"GetInfo\", ...}, ... }  (from dotted GlobalAPI names)",
        "--   luaNamespaces               { string = {...}, table = {...}, math = {...}, bit = {...}, ... }",
        "--   frameXMLGlobals/Tables      FrameXML functions / { SomeUtil = {fields} }",
        "--   widgetMethods/Handlers      OWN methods/script handlers per widget type;",
        "--   widgetInherits              parents per widget type (resolve recursively for the full set;",
        "--                               the dump's Region -> Region self-loop is written as ScriptRegion)",
        "--   leGlobals / leValues        LE_* and NUM_LE_* constants (names / values)",
        "--   enums / constants           Enum.X.Y and Constants.X.Y values",
        "",
        "return " + lua_value(out, 0),
        "",
    ]
    text = "\n".join(header)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("wrote %s (%d bytes)" % (args.out, len(text.encode("utf-8"))))
    for k, v in counts.items():
        print("  %-28s %d" % (k, v))
    for k, v in checks.items():
        print("  check %-22s %s" % (k, v))


if __name__ == "__main__":
    try:
        main()
    except ParseError as e:
        sys.exit("parse error: %s" % e)
