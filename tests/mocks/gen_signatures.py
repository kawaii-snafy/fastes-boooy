#!/usr/bin/env python3
"""Generate tests/mocks/wow/signatures.lua -- argument / payload specs used by the
strict WoW: Forever mock (tests/mocks/wow.lua) to check how the addon calls the
client API and how specs fire events.

Input: the Blizzard_APIDocumentationGenerated dump of the Forever client
(1.60.1.70862) as JSON (research/apidocs.json, produced by a sandboxed loader that
never executes Blizzard code outside setfenv). The JSON is read as data only.

Output (deterministic, sorted):
    return {
        functions = { ["C_QuestLog.GetInfo"] = { "questLogIndex:n" }, ... },
        events    = { QUEST_TURNED_IN = { "questID:n", "xpReward:n", "moneyReward:n" }, ... },
    }
Each argument is "name:C" or "name:C?" (? = nilable or has a default) where C is:
    n number   s string (numbers are coerced, like the client)   u unit token (string)
    g GUID (string)   b boolean (any value accepted)   t table   f function
    x number or string (ItemInfo / SpellIdentifier / uiAddon)   a anything

usage: python3 -I tests/mocks/gen_signatures.py --apidocs FILE [--out FILE]
"""
import argparse
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.join(HERE, "wow", "signatures.lua")

# Namespaces whose functions the mock implements (or may implement); global
# (namespace-less) documented functions are always included.
NAMESPACES = {
    "C_AddOns", "C_ClassColor", "C_Container", "C_CreatureInfo", "C_CVar", "C_DateAndTime",
    "C_GameRules", "C_GossipInfo", "C_Item", "C_Map", "C_Minimap", "C_Navigation",
    "C_PlayerInfo", "C_PlayerInteractionManager", "C_QuestLog", "C_QuestOffer",
    "C_RestrictedActions", "C_Secrets", "C_SkillInfo", "C_Spell", "C_SpellBook",
    "C_SuperTrack", "C_TaxiMap", "C_Timer", "C_UnitAuras",
}
# Event payloads are emitted for NAMESPACES, global systems and these systems
# (events of other systems are still known to the mock -- existence comes from
# tools/data/forever_api.lua -- but their payloads are not type-checked).
EVENT_NAMESPACES = NAMESPACES | {
    "C_System", "C_DeathInfo", "C_LossOfControl", "C_MerchantFrame", "C_Trainer", "C_Loot",
    "C_CurrencyInfo", "C_KeyBindings", "C_LoadingScreen",
}

NUMBER = {"number", "luaIndex", "fileID", "Seconds", "BigUInteger", "BigInteger", "WOWMONEY",
          "normalizedValue", "SingleColorValue", "uiFontHeight", "time_t", "FrameTime",
          "CalendarEventID", "ClubId", "ClubStreamId"}
STRING = {"cstring", "string", "stringView", "textureKit", "textureAtlas", "FramePoint",
          "DrawLayer", "mouseButton", "FileAsset", "TextureAsset", "kstringClubMessage",
          "ClubMemberOpaqueId"}
UNIT = {"UnitToken", "UnitTokenVariant", "UnitTokenPvPRestrictedForAddOns",
        "UnitTokenRestrictedForAddOns", "uiUnit"}
TABLE = {"table", "vector2", "vector3", "UiMapPoint", "ItemLocation", "PlayerLocation",
         "colorRGB", "colorRGBA", "AzeriteEmpoweredItemLocation", "ItemKey"}
FUNC = {"function", "LuaFunctionReference"}
EITHER = {"ItemInfo", "SpellIdentifier", "uiAddon"}
ANY = {"LuaValueReference", "LuaValueVariant"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apidocs", required=True,
                    help="Blizzard_APIDocumentationGenerated dump as JSON (research/apidocs.json)")
    ap.add_argument("--out", default=DEFAULT_OUT)
    args = ap.parse_args()
    with open(args.apidocs, encoding="utf-8") as fh:
        docs = json.load(fh)

    kinds = {}
    for system in docs:
        for t in system.get("Tables") or []:
            kinds[t["Name"]] = t.get("Type")

    def cat(tp):
        if tp in NUMBER or kinds.get(tp) == "Enumeration":
            return "n"
        if tp in STRING:
            return "s"
        if tp in UNIT:
            return "u"
        if tp == "WOWGUID":
            return "g"
        if tp == "bool":
            return "b"
        if tp in TABLE or kinds.get(tp) == "Structure":
            return "t"
        if tp in FUNC or kinds.get(tp) == "CallbackType":
            return "f"
        if tp in EITHER:
            return "x"
        return "a"

    def spec(a):
        # nil is a valid Lua value for LuaValueReference (Blizzard code calls
        # issecretvalue(x) with possibly-nil x), so those arguments are optional
        opt = a.get("Nilable") or ("Default" in a) or a["Type"] in ANY
        return "%s:%s%s" % (a["Name"], cat(a["Type"]), "?" if opt else "")

    functions, events = {}, {}
    for system in docs:
        if system.get("Type") != "System" or system.get("Environment") not in (None, "All"):
            continue
        ns = system.get("Namespace")
        if ns is None or ns in NAMESPACES:
            for f in system.get("Functions") or []:
                name = "%s.%s" % (ns, f["Name"]) if ns else f["Name"]
                functions[name] = [spec(a) for a in f.get("Arguments") or []]
        if ns is None or ns in EVENT_NAMESPACES:
            for e in system.get("Events") or []:
                events[e["LiteralName"]] = [spec(p) for p in e.get("Payload") or []]

    def lua_list(items):
        return "{" + ", ".join('"%s"' % i for i in items) + "}"

    out = [
        "-- tests/mocks/wow/signatures.lua -- GENERATED by tests/mocks/gen_signatures.py. DO NOT EDIT.",
        "-- Source: Blizzard_APIDocumentationGenerated of WoW: Forever 1.60.1.70862 (JSON dump, data only).",
        "-- Argument codes: n number, s string, u unit token, g GUID, b boolean, t table, f function,",
        "-- x number|string, a any; a trailing ? means nilable / has a default.",
        "return {",
        "    functions = {",
    ]
    for name in sorted(functions):
        out.append('        ["%s"] = %s,' % (name, lua_list(functions[name])))
    out.append("    },")
    out.append("    events = {")
    for name in sorted(events):
        out.append("        %s = %s," % (name, lua_list(events[name])))
    out.append("    },")
    out.append("}")
    with open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(out) + "\n")
    print("wrote %s: %d functions, %d events" % (args.out, len(functions), len(events)))


if __name__ == "__main__":
    main()
