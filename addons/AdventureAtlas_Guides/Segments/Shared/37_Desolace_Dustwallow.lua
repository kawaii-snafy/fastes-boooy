-- AdventureAtlas_Guides / Segments / Shared / 37_Desolace_Dustwallow.lua
--
-- Segment "h-37-desolace-dustwallow": levels 37-41, all races and classes.
-- Booty Bay -> fly Grom'gol -> zeppelin to Orgrimmar (1431 / 1432) -> fly Sun Rock Retreat -> on foot through the
-- Charred Vale into Desolace -> Ghost Walker Post and its loops (Kodo Graveyard, Thunder Axe Fortress, Kolkar,
-- Sargeron, Valley of Spears, Shadowprey Village, Sar'theris Strand / Ethel Rethor / Ranzajar Isle, Mannoroc Coven,
-- Valley of Bones) -> fly Orgrimmar (level 40 stop) -> fly Camp Taurajo -> east into Dustwallow Marsh (Shady Rest,
-- Brackenwall Village, Swamplight Manor, Darkmist spiders, Wyrmbog twice) -> Brackenwall Village.
-- Plan: research plan60.md section 4.6 / plan60.json segments[6] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1434 (Stranglethorn Vale) / 1411 (Durotar) / 1454 (Orgrimmar) / 1442 (Stonetalon
-- Mountains) / 1443 (Desolace) / 1413 (The Barrens) / 1445 (Dustwallow Marsh), map percent, from
-- tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective mob / object
-- spawns of the area used for complete steps (h37 tools: research scratch h37/cen.lua). Travel points: Sun Rock west
-- exit (h-24 route), Stonetalon spirit healer 6491 (Charred Vale south), Rexxar 10182 on the Desolace road (54, 2),
-- the Valley of Spears coast 25,46 (west of the Maraudon canyon and its elite Shadowshards), Rigger Gizelton 11626
-- on the southern road.
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
-- Objective counts in the notes are the Forever ones (Wowhead Forever tooltips); the DB snapshot still has the
-- smaller TBC counts for 1168 / 1169 / 1177 / 1206 / 1322, so the validator underestimates their kill XP.
--
-- Hub plan (Forever DB; no quest of the segment is limited to a race or class):
--   Org 1 : 1431 (Craven Drok) > 1432 (Keldran); fly Sun Rock Retreat.
--   GWP 1 : Kormek's Hut 5501 on the way in (optional caravan escort 5821 if the caravan stands there); 1432 > 1433 +
--           1434 (Takata), 1433 > 1435 (Maurin), 5386 (Nataka),
--           1365 (Felgur), optional Forever-new 93225 (Gurda); Smeed 5561 (optional 5821 turn-in).
--   K     : Kodo Graveyard: bones (5501), tamed kodos to Smeed (5561); Kormek's 5501.
--   TA 1  : Thunder Axe Fortress: 15 Infused Burning Gems (1435), Flayed Demon Skin > 1480.
--   GWP 2 : 1435 + 1480 > 1481 (Maurin).  E: Khan Dez'hepah (1365), Sargeron satyrs (1434, 1481 scalp).
--   GWP 3 : 1434 > 1436 (Takata), 1481 > 1482 (Maurin), 1365 > 1366 (Felgur); Hornizz 6134.
--   W     : Valley of Spears (Maraudine 36-40): ears (1366), totems (93225), level gate 1 (37 + 50%), Melizza's
--           escort out of the Maraudine camp (6132).
--   SV 1  : sethearth; 5381 (Taiga), 6142 (Mai'Lahii), 6143 (Drulzegar), talk to Jinar'Zillen (5386); flight point.
--   NW    : Rackmore's Log 6161, clams (6142) + Drysnap silver key, Azore 5741; Thunder Axe 2 (5741 sceptre, 5381
--           Demon Box); Azore 5741 > 6027; Slitherblade naga (6143, golden key, 1482 Oracle Crystal), Ranzajar Isle
--           (Lord Kragaru 6027, Rackmore's Chest 6161); Azore 6027; hearth.
--   SV 2  : 5381 > 5581, 6142, 6143.
--   S     : optional caravan escort 5943 at Rigger Gizelton; Mannoroc Coven (5581 portals, level gate 2 = 40 at the
--           Orgrimmar stop), Valley of Bones (6134); optional Smeed 5943; Hornizz 6134 + 6132.
--   GWP 4 : spices for Dustwallow (Kireena); 1482 > 1484 > Takata; 5386; 1366; 93225.  SV 3: hearth, 5581; fly
--           Orgrimmar.
--   Org 2 : hearth bound in Orgrimmar (the next segment can hearth out of Brackenwall), 1436 (Keldran); fly Camp
--           Taurajo; optional Razorfen Downs block (6626 at the entrance, south Barrens), run east into Dustwallow.
--   DW    : Shady Rest 1251 / 1268 / 1269; Mudcrush 1177; Brackenwall: fp, 1251 + 1268 + 1269 > 1321 (Krog),
--           1321 > 1322 (Do'gol), 1201, 1166, 1168, 1169.  East: Theramore Infiltrators (1201), Ogron 1273 + Reethe,
--           Darkfang spiders (1322), Jarl 1218 > 1206, Loose Dirt 1238, Mirefin murlocs (1177).  Brackenwall:
--           1201 + 1238 > 1202, 1322 > 1323, 1323 + 1273.  Darkmist spiders (1206), Jarl 1206, Loose Dirt 1239;
--           Theramore docks (1202 footlocker).  Wyrmbog 1: 1166 (snuff, grog, strongbox), 1168, 1169.  Mudcrush 1177;
--           Brackenwall 1239 + 1202, 1168, 1169 > 1170 > 1171 > 1172.  Wyrmbog 2: eggs (1172), checkpoint; Brackenwall
--           1172.
-- Deviations from the plan (documented in the handoff):
--   * 1367 Magram Alliance is skipped: it needs Friendly with the Magram (~150 Gelkis kills) and a trip to Warug in
--     the far south-east for 650 XP. The anchor id h-37-warug sits on the Valley of Bones step (south of Magram
--     Village); Warug himself is not visited.
--   * 5821 / 5943 Gizelton caravan escorts are optional (slow kodo caravan, unknown start time: taken only when the
--     caravan stands at its stop); h-37-rigger-gizelton is the road point where Rigger's caravan stands. 1488 (Lord
--     Azrethoc is a level 40 ELITE) is not taken.
--   * Added: 6143 Other Fish to Fry (Shadowprey; the same naga as 6161 / 1482) and the optional Forever-new 93225
--     Carved Centaur Totems (Maraudine centaurs, where the route grinds anyway). Densification pass (34-46): 6132 Get
--     Me Out of Here! (Melizza's escort out of the Maraudine camp the route grinds in; turned in at Hornizz with
--     6134), 1202 The Theramore Docks (footlocker under the Theramore pier, +1 200 yards between Jarl and the Wyrmbog),
--     the optional caravan escorts above and an optional Razorfen Downs block (6626 A Host of Evil: the elites 33-34
--     at the entrance, 1 100 yards from Shady Rest; Belnistrasz's quests inside are only named in the note: no outdoor
--     position for the waypoint).
--   * Not taken: 1203 Jarl Needs a Blade (needs a crafted Moonsteel Broadsword), 1240 / 1276 (Stranglethorn, Thunder
--     Bluff), 1270 Stinky's Escape (turned in in Ratchet: next range), 1173 (fight the elite Mok'Morokk), 97265 Hate
--     the Hatefury (Forever-new, Shadowprey giver, Sargeron objectives: the route reaches Shadowprey only after
--     Sargeron), 96222 Khan Hratha (Forever-new, elite Khan 42), the Magram / Gelkis reputation chains (1367-1381,
--     Forever's "Buying Friendship" 94872 / 94873 need Neutral standing first).
--   * Brackenwall Village has no innkeeper (no innkeeper on uiMap 1445 in the DB): the hearthstone is bound in
--     Shadowprey Village (Desolace) and then in Orgrimmar (h-40 stop), not in Brackenwall.
--   * Anchor placement by name where the plan's hub mapping does not fit the route: h-37-orgrimmar = the Orgrimmar
--     gate (before Craven Drok), h-40-shadowprey-end = the last Desolace quest step (5581 at Taiga in Shadowprey),
--     h-41-brackenwall-end = the last step (1172 at Draz'Zilb in Brackenwall); h-40-brackenwall-arrive = Shady Rest,
--     as in the plan.
-- XP (validator, Classic quest XP + objective kills with the DB counts; a route that enters at 36.06): required quests
--   ~102 k (+ ~9 k optional), objective kills ~44 k. The segment now starts at 36.06 (h-34 grinds less), so the two
--   Desolace gates take that deficit too, at a higher level: h38-level-maraudine (now required, 37 + 50%, Valley of
--   Spears centaurs 36-40, ~340 same-level kills) and h39-level-mannoroc (39 + 78%, Mannoroc Coven demons 37-40,
--   ~680 kills; set so the required turn-ins make 40.0 at the Orgrimmar stop even with every optional step skipped).
--   h-37-desolace-dustwallow-level-gate is a checkpoint (40 + 25%) the Dustwallow quests reach alone; the segment
--   ends at ~40.85 (within 1 of 41) and the h-41 gate grinds the rest at 42-43. ~1 010 kills in all (normal) / ~1 030
--   (worst case), was ~835 from 37.02 (+~460 h-34 kills moved here, minus the new quests). Group alternative:
--   Razorfen Downs (optional block at Camp Taurajo).
-- Automation notes: accepts at one NPC sit in one step (except 1218 > 1206, which needs the turn-in in between);
--   transient steps (fp, sethearth, vendor) come before the quest steps of the same place; the optional 93225
--   complete step is bg, its optional accept / turn-in are passed by the next quest step.
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "h-37-desolace-dustwallow",
    title = { ru = "37-41 Пустоши и Пылевые топи", en = "37-41 Desolace and Dustwallow Marsh" },
    zone = "Desolace",
    levels = { 37, 41 },
    steps = {
        ------------------------------------------------------------------
        -- Booty Bay -> Grom'gol -> zeppelin -> Orgrimmar (37)
        ------------------------------------------------------------------
        { id = "h37-fly-gromgol", fly = "Grom'gol Base Camp", npc = 1387, at = { 1434, 32.54, 29.35 },
          note = { ru = "Грингер: летите в Гром'гол (камень возвращения ещё на откате).",
                   en = "Gringer: fly to Grom'gol (the hearthstone is still on cooldown)." } },
        { id = "h-37-grom-gol-zeppelin", go = true, radius = 15, npc = 3149, at = { 1434, 31.43, 29.91 },
          note = { ru = "Башня дирижаблей: Нез'раз - дирижабль в Оргриммар (не в Подгород).",
                   en = "Zeppelin tower: Nez'raz - the zeppelin to Orgrimmar (not the one to Undercity)." } },
        { id = "h37-durotar-arrive", go = true, radius = 40, npc = 12136, at = { 1411, 50.69, 12.89 },
          note = { ru = "Прилёт к башне в Дуротаре.", en = "Arrival at the Durotar tower." } },
        { id = "h-37-orgrimmar", go = true, radius = 25, at = { 1454, 48.97, 92.84 },
          note = { ru = "На запад к главным воротам Оргриммара.", en = "West to the main gate of Orgrimmar." } },
        { id = "h-37-org-arrive", accept = 1431, npc = 5639, at = { 1454, 51.30, 45.90 },
          note = { ru = "Кравен Дрок в центре города: «Отношения с Альянсом».",
                   en = "Craven Drok in the middle of the city: Alliance Relations." } },
        { id = "h-37-orgrimmar-keldran", turnin = 1431, accept = 1432, npc = 5640, at = { 1454, 22.56, 52.63 },
          note = { ru = "Кельдран в западной части города.", en = "Keldran in the west of the city." } },
        { id = "h-37-orgrimmar-flight-master", fly = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = { ru = "Дорас на башне ветрокрылов: летите в Приют Солнечного Камня.",
                   en = "Doras on the wind rider tower: fly to Sun Rock Retreat." } },

        ------------------------------------------------------------------
        -- Stonetalon -> Desolace, Kormek's Hut, Ghost Walker Post (37)
        ------------------------------------------------------------------
        { id = "h37-sunrock-west", go = true, radius = 30, at = { 1442, 38.70, 68.60 },
          note = { ru = "Из Приюта через западный выход вниз в Обугленную долину.",
                   en = "Out of Sun Rock through the west exit, down into the Charred Vale." } },
        { id = "h37-charred-vale", go = true, radius = 40, at = { 1442, 36.44, 75.24 },
          note = { ru = "На юг по долине (гарпии серые) к перевалу в Пустоши.",
                   en = "South through the vale (the harpies are grey) to the pass into Desolace." } },
        { id = "h37-desolace-north", go = true, radius = 40, at = { 1443, 54.00, 4.00 },
          note = { ru = "Пустоши. Дальше по дороге на юг мимо Крепости Громового Топора (Пылающий Клинок): если с "
                       .. "них выпадет рваная демонская кожа - сохраните, она начинает «Осквернителя душ».",
                   en = "Desolace. South along the road past Thunder Axe Fortress (Burning Blade): if a Flayed Demon "
                       .. "Skin drops from them, keep it - it starts The Corrupter." } },
        { id = "h-37-cork-gizelton-bibbly", accept = 5501, npc = 11438, at = { 1443, 62.33, 38.99 },
          note = { ru = "Хижина Кормека у дороги: Биббли Скобкофуз - «Собиратель костей».",
                   en = "Kormek's Hut by the road: Bibbly F'utzbuckle - Bone Collector." } },
        -- Optional: the Gizelton caravan escorts (only when the caravan happens to stand at its stop; do not wait).
        { accept = 5821, npc = 11625, optional = true, at = { 1443, 66.54, 37.51 },
          note = { ru = "По желанию, если караван Гизлтонов стоит у хижины (не ждите его): Корк Гизлтон - «Наемный "
                       .. "телохранитель».",
                   en = "Optional, if the Gizelton caravan stands by the hut (do not wait for it): Cork Gizelton - "
                       .. "Bodyguard for Hire." } },
        { complete = 5821, optional = true, at = { 1443, 67.20, 56.60 },
          note = { ru = "Проводите караван на юг по дороге (кентавры нападают дважды). Сдача - у Смида.",
                   en = "Escort the caravan south along the road (centaurs attack twice). Turned in at Smeed." } },
        { id = "h-37-ghostwalker-arrive", turnin = 1432, accept = { 1433, 1434 }, npc = 5641,
          at = { 1443, 52.57, 54.39 },
          note = { ru = "На юг к заставе в центре Пустошей: Таката Стальной Клинок.",
                   en = "South to Ghost Walker Post in the middle of Desolace: Takata Steelblade." } },
        { turnin = 1433, accept = 1435, npc = 4498, at = { 1443, 52.25, 53.44 },
          note = { ru = "Маурин Костолом рядом: «Сжигание душ» (пылающий самоцвет).",
                   en = "Maurin Bonesplitter next to him: The Burning of Spirits (Burning Gem)." } },
        { accept = 5386, npc = 11259, at = { 1443, 55.41, 55.81 },
          note = { ru = "Натака Длинный Рог: рыба - позже, в Деревне Ночных Охотников.",
                   en = "Nataka Longhorn: the fish comes later, from Shadowprey Village." } },
        { id = "h-37-kolkar-guests", accept = 1365, npc = 5395, at = { 1443, 56.19, 59.57 },
          note = { ru = "Фелгур Бью-Двоих на южном краю заставы: «Вождь Дез'хеп».",
                   en = "Felgur Twocuts at the south edge of the post: Khan Dez'hepah." } },
        { accept = 93225, npc = 5412, at = { 1443, 56.29, 59.68 }, optional = true,
          note = { ru = "По желанию (новое в Forever, опыт неизвестен): Гурда Буйногривая - 5 резных тотемов "
                       .. "кентавров (падают с кентавров племени Мародин, где маршрут всё равно бьёт мобов). «Союз с "
                       .. "племенем Маграм» не берите: нужно «Дружелюбие» с Маграм (~150 убийств Гелкис).",
                   en = "Optional (new in Forever, XP unknown): Gurda Wildmane - 5 Carved Centaur Totems (they drop "
                       .. "from the Maraudine centaurs, where the route grinds anyway). Skip Magram Alliance: it needs "
                       .. "Friendly with the Magram (~150 Gelkis kills)." } },
        { id = "h-37-smeed-scrabble", accept = 5561, npc = 11596, at = { 1443, 60.86, 61.86 },
          note = { ru = "На восток к Лагерю Заржавня: Смид Заржавень - «Отлов кодо». Караван Гизлтонов не ждите.",
                   en = "East to Scrabblescrew's Camp: Smeed Scrabblescrew - Kodo Roundup. Do not wait for the "
                       .. "Gizelton caravan." } },
        { turnin = 5821, npc = 11596, optional = true, at = { 1443, 60.86, 61.86 },
          note = { ru = "Если провели караван: Смид.", en = "If you escorted the caravan: Smeed." } },

        ------------------------------------------------------------------
        -- Kodo Graveyard, Kormek's Hut, Thunder Axe Fortress (37)
        ------------------------------------------------------------------
        { complete = 5501, object = { 176751, 176752 }, at = { 1443, 51.70, 59.20 },
          note = { ru = "Кладбище кодо к западу: 10 костей кодо на земле. Мерзкие падальщики (35-37) агрессивны.",
                   en = "The Kodo Graveyard to the west: 10 Kodo Bones on the ground. The Carrion Horrors (35-37) "
                       .. "are aggressive." } },
        { complete = 5561, use = 13892, at = { 1443, 52.03, 55.88 },
          note = { ru = "Энергетический инкапсулятор кодо - на старых, умирающих и древних кодо (не бейте их): "
                       .. "приручённый идёт за вами - приведите 5 к Смиду (если за вами идут несколько, ведите сразу "
                       .. "всех).",
                   en = "Use the Kodo Kombobulator on Aged, Dying and Ancient Kodos (do not kill them): a tamed one "
                       .. "follows you - lead 5 to Smeed (if several follow you, bring them together)." } },
        { turnin = 5561, npc = 11596, at = { 1443, 60.86, 61.86 },
          note = { ru = "Смид.", en = "Smeed." } },
        { turnin = 5501, npc = 11438, at = { 1443, 62.33, 38.99 },
          note = { ru = "На север по дороге к хижине Кормека: Биббли.", en = "North along the road to Kormek's Hut: Bibbly." } },
        { id = "h37-thunder-axe", complete = 1435, use = 6436, at = { 1443, 54.98, 27.70 },
          note = { ru = "Крепость Громового Топора: используйте пылающий самоцвет на почти убитых бойцах Пылающего "
                       .. "Клинка - 15 одушевлённых самоцветов. Попутно падает рваная демонская кожа.",
                   en = "Thunder Axe Fortress: use the Burning Gem on Burning Blade members that are about to die - "
                       .. "15 Infused Burning Gems. The Flayed Demon Skin drops here too." } },
        { accept = 1480, use = 20310, at = { 1443, 54.98, 27.70 },
          note = { ru = "Рваная демонская кожа (с любого Пылающего Клинка): используйте - «Осквернитель душ».",
                   en = "Flayed Demon Skin (from any Burning Blade): use it - The Corrupter." } },
        { turnin = { 1435, 1480 }, accept = 1481, npc = 4498, at = { 1443, 52.25, 53.44 },
          note = { ru = "Обратно на юг к Маурину.", en = "Back south to Maurin." } },

        ------------------------------------------------------------------
        -- East: Khan Dez'hepah, Sargeron (37-38)
        ------------------------------------------------------------------
        { complete = 1365, at = { 1443, 73.70, 45.20 },
          note = { ru = "На восток в деревню Колкар: вождь Дез'хеп (35) ходит по деревне с охраной - голова.",
                   en = "East to the Kolkar village: Khan Dez'hepah (35) walks the village with guards - his head." } },
        { id = "h-37-desolace-field-loop", complete = { 1434, 1481 }, at = { 1443, 75.50, 19.20 },
          note = { ru = "На север в Саргерон: по 7 разбойников, скверноподданных, предателей и адских сатиров Ярой "
                       .. "Ненависти; скальп тенелова - с тенеловов (в незаметности).",
                   en = "North to Sargeron: 7 each of Hatefury Rogues, Felsworn, Betrayers and Hellcallers; the "
                       .. "Shadowstalker Scalp from the Hatefury Shadowstalkers (stealthed)." } },
        { turnin = 1365, accept = 1366, npc = 5395, at = { 1443, 56.19, 59.57 },
          note = { ru = "Обратно на заставу, Фелгур: 15 ушей - с любых кентавров (маршрут берёт их у племени Мародин).",
                   en = "Back to Ghost Walker Post, Felgur: the 15 ears drop from any centaur (the route takes them "
                       .. "from the Maraudine)." } },
        { turnin = 1434, accept = 1436, npc = 5641, at = { 1443, 52.57, 54.39 },
          note = { ru = "Таката: «Отношения с Альянсом» (сдать в Оргриммаре).",
                   en = "Takata: Alliance Relations (turned in in Orgrimmar)." } },
        { turnin = 1481, accept = 1482, npc = 4498, at = { 1443, 52.25, 53.44 },
          note = { ru = "Маурин: кристалл оракула - позже, у наг на северо-западе.",
                   en = "Maurin: the Oracle Crystal comes later, from the naga in the north-west." } },
        { id = "h-37-hornizz-brimbuzzle", accept = 6134, npc = 6019, at = { 1443, 47.83, 61.83 },
          note = { ru = "Хормиц Жужжалит на западном краю Кладбища кодо: «Сбор эктоплазмы» (позже, на юго-востоке).",
                   en = "Hornizz Brimbuzzle on the west edge of the Kodo Graveyard: Ghost-o-plasm Round Up (later, "
                       .. "in the south-east)." } },

        ------------------------------------------------------------------
        -- West: Valley of Spears (Maraudine centaurs), Shadowprey Village (38)
        ------------------------------------------------------------------
        { complete = 1366, at = { 1443, 32.20, 58.20 },
          note = { ru = "На запад в Долину Копий: кентавры племени Мародин (36-40) - 15 ушей. В каньон Мародона "
                       .. "не спускайтесь: там элитные осколочники (40-42).",
                   en = "West to the Valley of Spears: Maraudine centaurs (36-40) - 15 ears. Stay out of the Maraudon "
                       .. "canyon: elite Shadowshards (40-42)." } },
        { complete = 93225, bg = true, optional = true, at = { 1443, 32.20, 58.20 },
          note = { ru = "По желанию: 5 резных тотемов кентавров с тех же кентавров.",
                   en = "Optional: 5 Carved Centaur Totems from the same centaurs." } },
        -- level-grind of the next step (acknowledged with `ok`): about a third of the Desolace deficit, in the densest 36-40 camp of the
        -- zone, where the ears (1366) and totems (93225) drop anyway; the quests ahead are 38-40 (Slitherblade naga,
        -- Lord Kragaru 38, the Burning Blade Seer). The rest waits for the Mannoroc gate (higher level, fewer kills).
        { id = "h38-level-maraudine", level = { 37, 0.50 }, at = { 1443, 32.20, 58.20 },
          ok = { ["level-grind"] = 330 }, -- 325 kills in the normal run (reason above)
          note = { ru = "Цель: 37 + 50%. Не хватает - кентавры племени Мародин (36-40) здесь же: плотные лагеря, уши "
                       .. "(1366) и тотемы (93225) падают попутно. Дальше задания 38-40 (наги, лорд Крагару, "
                       .. "ясновидец). Отложите 15 отрезов шелка (не продавайте) для «Попался!» (Тлеющее ущелье, 43).",
                   en = "Target: 37 + 50%. Short: the Maraudine centaurs (36-40) right here - dense camps, the ears "
                       .. "(1366) and totems (93225) drop on the side. The quests ahead are 38-40 (naga, Lord Kragaru, "
                       .. "the Seer). Keep 15 Silk Cloth (do not sell it) for Caught! (Searing Gorge, 43)." } },
        { id = "h38-melizza", accept = 6132, complete = 6132, npc = 12277, at = { 1443, 33.95, 53.50 },
          note = { ru = "Мелицца Жужжалит в лагере кентавров Мародин (северная часть долины): «Вытащи меня отсюда!» - "
                       .. "проводите её на восток к Кладбищу кодо (по пути нападут кентавры). Сдача - позже, у "
                       .. "Хормица.",
                   en = "Melizza Brimbuzzle in the Maraudine camp (north part of the valley): Get Me Out of Here! - "
                       .. "escort her east towards the Kodo Graveyard (centaurs attack on the way). Turned in later, at "
                       .. "Hornizz." } },
        { id = "h38-sethearth-shadowprey", sethearth = "Shadowprey Village", npc = 11106, at = { 1443, 24.09, 68.21 },
          note = { ru = "На юго-запад в Деревню Ночных Охотников: хозяйка таверны Сикоя - камень возвращения сюда.",
                   en = "South-west to Shadowprey Village: Innkeeper Sikewa - bind your hearthstone here." } },
        { id = "h-37-shadowprey-village", accept = 5381, npc = 11624, at = { 1443, 25.82, 68.21 },
          note = { ru = "Тайга Мудрая Грива: «Рука Ируксоса» (кирка демона).",
                   en = "Taiga Wisemane: Hand of Iruxos (Demon Pick)." } },
        { accept = 6142, npc = 12031, at = { 1443, 22.64, 71.97 },
          note = { ru = "Май'Лахия у причала.", en = "Mai'Lahii by the pier." } },
        { accept = 6143, npc = 12340, at = { 1443, 23.32, 72.87 },
          note = { ru = "Друльзегар Скрюг-скрак: «Смерть земноводным!».", en = "Drulzegar Skraghook: Other Fish to Fry." } },
        { complete = 5386, npc = 11317, at = { 1443, 22.45, 73.12 },
          note = { ru = "Джинар'Зиллен на причале: поговорите - он даст 2 рыбы-кровобрюха.",
                   en = "Jinar'Zillen on the pier: talk to him - he hands over 2 Bloodbelly Fish." } },
        { id = "h38-fp-shadowprey", fp = "Shadowprey Village", npc = 6726, at = { 1443, 21.60, 74.13 },
          note = { ru = "Фалон: откройте карту полётов.", en = "Thalon: open the flight map." } },

        ------------------------------------------------------------------
        -- North-west: Sar'theris Strand, Ethel Rethor, Thunder Axe, Ranzajar Isle (38)
        ------------------------------------------------------------------
        { id = "h38-coast-north", go = true, radius = 40, at = { 1443, 25.00, 46.00 },
          note = { ru = "На север вдоль побережья (мимо каньона Мародона с элитными осколочниками).",
                   en = "North along the coast (past the Maraudon canyon and its elite Shadowshards)." } },
        { id = "h-37-rackmore-s-log", accept = 6161, object = 177787, at = { 1443, 36.07, 30.41 },
          note = { ru = "Корабельный журнал Ракмора у разбитого корабля: «Сокровища Ракмора».",
                   en = "Rackmore's Log by the wrecked ship: Claim Rackmore's Treasure!" } },
        { complete = { [6142] = { 1 }, [6161] = { 1 } }, object = 177784, at = { 1443, 32.80, 30.80 },
          note = { ru = "Берег у корабля: 10 кусочков мяса моллюска (раковины на земле, рифовые крабы); "
                       .. "серебряный ключ - с крабов с мертвой хваткой.",
                   en = "The shore by the ship: 10 Soft-shelled Clams (clams on the ground, Reef Crawlers); the Silver "
                       .. "Key from the Drysnap crabs." } },
        { id = "h-37-azore-aldamort", accept = 5741, npc = 11863, at = { 1443, 38.88, 27.16 },
          note = { ru = "Азор Альдаморт в башне Этель-Ретор: «Скипетр Света».",
                   en = "Azore Aldamort in the Ethel Rethor tower: Sceptre of Light." } },
        { complete = 5741, at = { 1443, 55.17, 30.15 },
          note = { ru = "На восток в Крепость Громового Топора: ясновидец Пылающего Клинка на вершине башни - скипетр.",
                   en = "East to Thunder Axe Fortress: the Burning Blade Seer on top of the tower - the sceptre." } },
        { complete = 5381, use = 14523, at = { 1443, 55.00, 26.60 },
          note = { ru = "Северная часть крепости: киркой демона по красному кристаллу - дух демона, с него "
                       .. "демоническая шкатулка.",
                   en = "The north part of the fortress: use the Demon Pick on the red crystal - a Demon Spirit, "
                       .. "the Demon Box drops from it." } },
        { turnin = 5741, accept = 6027, npc = 11863, at = { 1443, 38.88, 27.16 },
          note = { ru = "Обратно к Азору: «Книга Древних» (самоцвет Змеи).",
                   en = "Back to Azore: Book of the Ancients (Gem of the Serpent)." } },
        { complete = { 6143, [6161] = { 2 }, 1482 }, at = { 1443, 32.40, 17.60 },
          note = { ru = "Берег Сар'терис: наги Скользящего Плавника - 7 мирмидонов, 7 наг, 5 колдуний; золотой "
                       .. "ключ и кристалл оракула (с оракулов, их всего 5).",
                   en = "Sar'theris Strand: Slitherblade naga - 7 Myrmidons, 7 Naga, 5 Sorceresses; the Golden Key and "
                       .. "the Oracle Crystal (from the Oracles, only 5 of them)." } },
        { complete = 6027, use = 15766, at = { 1443, 28.24, 6.67 },
          note = { ru = "Остров Ранзаджар (вплавь): самоцвет Змеи в руки статуи змея - лорд Крагару (38), книга.",
                   en = "Ranzajar Isle (swim): the Gem of the Serpent into the serpent statue's hands - Lord Kragaru "
                       .. "(38), the book." } },
        { id = "h-37-rackmore-s-chest", turnin = 6161, object = 177786, at = { 1443, 30.00, 8.71 },
          note = { ru = "Там же: сундук Ракмора - откройте двумя ключами.",
                   en = "On the same isle: Rackmore's Chest - open it with both keys." } },
        { turnin = 6027, npc = 11863, at = { 1443, 38.88, 27.16 },
          note = { ru = "Обратно к Азору.", en = "Back to Azore." } },
        { id = "h38-hearth-shadowprey", hearth = "Shadowprey Village", at = { 1443, 24.09, 68.21 },
          note = { ru = "Камень возвращения в Деревню Ночных Охотников.", en = "Hearth to Shadowprey Village." } },
        { turnin = 5381, accept = 5581, npc = 11624, at = { 1443, 25.82, 68.21 },
          note = { ru = "Тайга: «Порталы Легиона» (рука Ируксоса).", en = "Taiga: Portals of the Legion (Hand of Iruxos)." } },
        { turnin = 6142, npc = 12031, at = { 1443, 22.64, 71.97 },
          note = { ru = "Май'Лахия.", en = "Mai'Lahii." } },
        { turnin = 6143, npc = 12340, at = { 1443, 23.32, 72.87 },
          note = { ru = "Друльзегар Скрюг-скрак.", en = "Drulzegar Skraghook." } },

        ------------------------------------------------------------------
        -- South: Mannoroc Coven, Valley of Bones (39)
        ------------------------------------------------------------------
        { id = "h-37-rigger-gizelton", go = true, radius = 30, npc = 11626, at = { 1443, 45.40, 75.29 },
          note = { ru = "На восток по южной дороге. Караван Гизлтонов (сопровождение) не ждите.",
                   en = "East along the southern road. Do not wait for the Gizelton caravan (escort)." } },
        { accept = 5943, npc = 11626, optional = true, at = { 1443, 45.40, 75.29 },
          note = { ru = "По желанию, если караван здесь: Риггер Гизлтон - «Караван Гизлтона».",
                   en = "Optional, if the caravan is here: Rigger Gizelton - Gizelton Caravan." } },
        { complete = 5943, optional = true, at = { 1443, 55.70, 67.80 },
          note = { ru = "Проводите караван на восток по дороге (нападут кентавры и демоны). Сдача - у Смида.",
                   en = "Escort the caravan east along the road (centaurs and demons attack). Turned in at Smeed." } },
        { complete = 5581, use = 14547, at = { 1443, 51.99, 76.98 },
          note = { ru = "Поле Маннорок: рукой Ируксоса закройте 6 порталов, стражи порталов (38-39) нападают. "
                       .. "Лорд Азреток - элита, обходите.",
                   en = "Mannoroc Coven: banish 6 portals with the Hand of Iruxos, the Demon Portal Guardians (38-39) "
                       .. "attack. Lord Azrethoc is elite - avoid him." } },
        -- level-grind of the next step (acknowledged with `ok`): the rest of the Desolace deficit, as late as possible before the pinned
        -- level: with the required turn-ins that follow (the optional ones not counted) this makes 40.0 at the
        -- Orgrimmar stop h-40-org-arrive (druid insert: Dire Bear Form and riding at 40; Dustwallow needs 38).
        { id = "h39-level-mannoroc", level = { 39, 0.78 }, at = { 1443, 52.50, 77.00 },
          ok = { ["level-grind"] = 690 }, -- 683 / 684 kills in the normal run (reason above)
          note = { ru = "Цель: 39 + 78% (оставшиеся сдачи дадут 40 к Оргриммару: обучение и верховая езда на 40, "
                       .. "задания Пылевых топей). Не хватает - демоны Поля Маннорок (37-40) здесь же, плотные и быстро "
                       .. "появляются снова.",
                   en = "Target: 39 + 78% (the remaining turn-ins make 40 for Orgrimmar: training and riding at 40, the "
                       .. "Dustwallow quests). Short: the Mannoroc Coven demons (37-40) right here, dense with quick "
                       .. "respawns." } },
        { id = "h-37-warug", complete = 6134, use = 15848, at = { 1443, 64.18, 91.63 },
          note = { ru = "На юго-восток в Долину Костей (к югу от деревни Маграм): ящик с призрачным магнитом "
                       .. "между двумя скелетами - призраки Маграм (38-39), 8 эктоплазм.",
                   en = "South-east to the Valley of Bones (south of Magram Village): the Crate of Ghost Magnets "
                       .. "between two skeletons - Magrami Spectres (38-39), 8 Ghost-o-plasms." } },
        { turnin = 5943, npc = 11596, optional = true, at = { 1443, 60.86, 61.86 },
          note = { ru = "Если провели караван: на север к Смиду (по пути к Хормицу).",
                   en = "If you escorted the caravan: north to Smeed (on the way to Hornizz)." } },
        { turnin = { 6134, 6132 }, npc = 6019, at = { 1443, 47.83, 61.83 },
          note = { ru = "На северо-запад к Хормицу: эктоплазма и спасённая Мелицца.",
                   en = "North-west to Hornizz: the ghost-o-plasm and the rescued Melizza." } },

        ------------------------------------------------------------------
        -- Ghost Walker Post, Shadowprey Village, fly out (40)
        ------------------------------------------------------------------
        { id = "h40-spices", vendor = true, npc = 9636, at = { 1443, 50.98, 53.55 },
          note = { ru = "Киреена на заставе: купите 3 ароматные специи (для Ярла в Пылевых топях).",
                   en = "Kireena at Ghost Walker Post: buy 3 Soothing Spices (for Jarl in Dustwallow Marsh)." } },
        { turnin = 1482, accept = 1484, npc = 4498, at = { 1443, 52.25, 53.44 },
          note = { ru = "Маурин Костолом.", en = "Maurin Bonesplitter." } },
        { turnin = 1484, npc = 5641, at = { 1443, 52.57, 54.39 },
          note = { ru = "Таката. Следующий «Осквернитель душ» (лорд Азреток - элита 40) не берите.",
                   en = "Takata. Skip the next The Corrupter (Lord Azrethoc is a level 40 elite)." } },
        { turnin = 5386, npc = 11259, at = { 1443, 55.41, 55.81 },
          note = { ru = "Натака Длинный Рог.", en = "Nataka Longhorn." } },
        { turnin = 1366, npc = 5395, at = { 1443, 56.19, 59.57 },
          note = { ru = "Фелгур Бью-Двоих.", en = "Felgur Twocuts." } },
        { turnin = 93225, npc = 5412, at = { 1443, 56.29, 59.68 }, optional = true,
          note = { ru = "Гурда Буйногривая: тотемы кентавров.", en = "Gurda Wildmane: the centaur totems." } },
        { id = "h40-hearth-shadowprey", hearth = "Shadowprey Village", at = { 1443, 24.09, 68.21 },
          note = { ru = "Камень в Деревню Ночных Охотников. На откате - 4 минуты на запад по дороге.",
                   en = "Hearth to Shadowprey Village. On cooldown: 4 minutes west along the road." } },
        { id = "h-40-shadowprey-end", turnin = 5581, npc = 11624, at = { 1443, 25.82, 68.21 },
          note = { ru = "Тайга.", en = "Taiga." } },
        { id = "h40-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Фалон: летите в Оргриммар.", en = "Thalon: fly to Orgrimmar." } },

        ------------------------------------------------------------------
        -- Orgrimmar (40) -> Camp Taurajo -> Dustwallow Marsh
        ------------------------------------------------------------------
        { id = "h40-sethearth-org", sethearth = "Orgrimmar", npc = 6929, at = { 1454, 54.10, 68.41 },
          note = { ru = "Хозяйка таверны Гришка: камень возвращения - в Оргриммар (в Гиблотопи таверны нет; "
                       .. "следующий сегмент вернётся сюда камнем).",
                   en = "Innkeeper Gryshka: bind your hearthstone to Orgrimmar (Brackenwall has no inn; the next "
                       .. "segment hearths back here)." } },
        { id = "h-40-org-arrive", turnin = 1436, npc = 5640, at = { 1454, 22.56, 52.63 },
          note = { ru = "Кельдран в западной части города.", en = "Keldran in the west of the city." } },
        { id = "h-38-orgrimmar-flight-master", fly = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = { ru = "Дорас: летите в Лагерь Таурахо.", en = "Doras: fly to Camp Taurajo." } },
        -- Optional group content: Razorfen Downs (37-46). The entrance is 1 100 yards from Shady Rest, so the block
        -- costs ~2 000 yards of extra road; without a group the next step (Shady Rest) passes it.
        { id = "h40-rfd-host", accept = 6626, npc = 12866, optional = true, at = { 1413, 49.01, 94.94 },
          note = { ru = "По желанию, если собрали группу в Курганы Иглошкурых: на юг к входу (49, 94) - Мириам Лунная "
                       .. "Певица, «Воинство зла». Без группы - сразу на восток в Пылевые топи (шаги пропустятся сами).",
                   en = "Optional, if you have a group for Razorfen Downs: south to the entrance (49, 94) - Myriam "
                       .. "Moonsinger, A Host of Evil. No group: go straight east into Dustwallow Marsh (these steps "
                       .. "skip themselves)." } },
        { complete = 6626, optional = true, at = { 1413, 46.30, 89.60 },
          note = { ru = "Вокруг входа: по 8 боевых стражей, терноплетов (Иглошкурые) и сектанток Мертвой Головы - "
                       .. "элита 33-34, на 40 по силам и в одиночку. В подземелье: Белнистраз - «Плеть в холмах» и "
                       .. "«Уничтожить идола» (гайд их не ведёт).",
                   en = "Around the entrance: 8 each of Razorfen Battleguards, Thornweavers and Death's Head Cultists - "
                       .. "elites 33-34, fine solo at 40. Inside: Belnistrasz - Scourge of the Downs and Extinguishing "
                       .. "the Idol (not tracked by the guide)." } },
        { turnin = 6626, npc = 12866, optional = true, at = { 1413, 49.01, 94.94 },
          note = { ru = "Мириам. Дальше на северо-восток в Пылевые топи, к Тенистому Приюту (1 100 ярдов).",
                   en = "Myriam. Then north-east into Dustwallow Marsh, to Shady Rest (1 100 yards)." } },
        { id = "h-40-brackenwall-arrive", accept = { 1251, 1268, 1269 }, object = { 20992, 21015, 21042 },
          at = { 1445, 29.72, 48.17 },
          note = { ru = "На восток по дороге в Пылевые топи (2-3 минуты) к сгоревшей таверне: черный щит, следы "
                       .. "копыт и жетон тераморского стражника.",
                   en = "East along the road into Dustwallow Marsh (2-3 minutes) to the burned inn: the Black "
                       .. "Shield, the Hoofprints and the Theramore Guard Badge." } },
        { id = "h-38-mudcrush-durtfeet", accept = 1177, npc = 4503, at = { 1445, 35.15, 38.26 },
          note = { ru = "На северо-восток: дробильщик Грязноног - «Моя голодный!».",
                   en = "North-east: Mudcrush Durtfeet - Hungry!" } },

        ------------------------------------------------------------------
        -- Brackenwall Village 1 (40)
        ------------------------------------------------------------------
        { id = "h-38-brackenwall-village", fp = "Brackenwall Village", npc = 11899, at = { 1445, 35.56, 31.88 },
          note = { ru = "Деревня Гиблотопь: Щербушка - откройте карту полётов.",
                   en = "Brackenwall Village: Shardi - open the flight map." } },
        { turnin = { 1251, 1268, 1269 }, accept = 1321, npc = 4926, at = { 1445, 36.42, 31.88 },
          note = { ru = "Крог.", en = "Krog." } },
        { turnin = 1321, accept = 1322, npc = 5087, at = { 1445, 36.53, 30.79 },
          note = { ru = "До'гол.", en = "Do'gol." } },
        { accept = 1201, npc = 4791, at = { 1445, 35.21, 30.66 },
          note = { ru = "Назир Кровавое Копье: шпионы - по дороге на восток.", en = "Nazeer Bloodpike: the spies are on the way east." } },
        { accept = 1166, npc = 4500, at = { 1445, 36.29, 31.41 },
          note = { ru = "Властитель Мок'Морокк.", en = "Overlord Mok'Morokk." } },
        { accept = 1168, npc = 4502, at = { 1445, 37.37, 31.39 },
          note = { ru = "Тхарг.", en = "Tharg." } },
        { accept = 1169, npc = 4501, at = { 1445, 37.15, 33.09 },
          note = { ru = "Драз'Зилб.", en = "Draz'Zilb." } },

        ------------------------------------------------------------------
        -- East: spies, Reethe, Darkfang spiders, Swamplight Manor, murlocs (40)
        ------------------------------------------------------------------
        { complete = 1201, bg = true, at = { 1445, 39.87, 27.58 },
          note = { ru = "Попутно: 9 тераморских шпионов (в незаметности) к востоку от деревни и у Огрона.",
                   en = "On the way: 9 Theramore Infiltrators (stealthed) east of the village and around Ogron." } },
        { id = "h-38-ogron", accept = 1273, npc = 4983, at = { 1445, 40.96, 36.69 },
          note = { ru = "Огрон к юго-востоку от деревни: «Допрос Рита».",
                   en = "Ogron south-east of the village: Questioning Reethe." } },
        { complete = 1273, at = { 1445, 42.65, 38.07 },
          note = { ru = "Идите с Огроном к Павалу Риту и защищайте Огрона, когда нападут люди Рита.",
                   en = "Go with Ogron to Paval Reethe and protect Ogron when Reethe's men attack." } },
        { complete = 1322, at = { 1445, 43.30, 39.50 },
          note = { ru = "Вокруг: пауки-темножвалы (38-39) - 6 желез с едким ядом.",
                   en = "Around: Darkfang Creepers (38-39) - 6 Acidic Venom Sacs." } },
        { id = "h-38-swamp-eye-jarl", accept = 1218, complete = 1218, turnin = 1218, npc = 4792,
          at = { 1445, 55.44, 26.27 },
          note = { ru = "На северо-восток к сторожке «Болотный Огонек»: Ярл «Болотный Глаз» - отдайте 3 специи. "
                       .. "Специй нет - бросьте 1218 (и «Ярлу нужны глаза» тоже пропадёт).",
                   en = "North-east to Swamplight Manor: \"Swamp Eye\" Jarl - hand over the 3 spices. No spices: "
                       .. "abandon 1218 (Jarl Needs Eyes is lost with it)." } },
        { accept = 1206, npc = 4792, at = { 1445, 55.44, 26.27 },
          note = { ru = "Ярл: «Ярлу нужны глаза». «Ярлу нужен клинок» не берите (нужен кованый меч).",
                   en = "Jarl: Jarl Needs Eyes. Skip Jarl Needs a Blade (it needs a crafted sword)." } },
        { accept = 1238, object = 20985, at = { 1445, 55.44, 25.92 },
          note = { ru = "Рыхлая земля у сторожки: «Потерянный рапорт».", en = "Loose Dirt by the manor: The Lost Report." } },
        { complete = 1177, at = { 1445, 57.20, 21.30 },
          note = { ru = "К северу у воды: мурлоки Болотного Плавника - 12 голов.",
                   en = "North by the water: Mirefin murlocs - 12 Mirefin Heads." } },

        ------------------------------------------------------------------
        -- Brackenwall 2, Darkmist spiders, Jarl 2 (40)
        ------------------------------------------------------------------
        { turnin = { 1201, 1238 }, accept = 1202, npc = 4791, at = { 1445, 35.21, 30.66 },
          note = { ru = "Обратно на запад в деревню: Назир. Возьмите «Доки Терамора» (сундучок капитана - по пути "
                       .. "от Ярла в Драконью топь).",
                   en = "Back west to the village: Nazeer. Take The Theramore Docks (the Captain's Footlocker is on the "
                       .. "way from Jarl to the Wyrmbog)." } },
        { turnin = 1322, accept = 1323, npc = 5087, at = { 1445, 36.53, 30.79 },
          note = { ru = "До'гол.", en = "Do'gol." } },
        { turnin = { 1323, 1273 }, npc = 4926, at = { 1445, 36.42, 31.88 },
          note = { ru = "Крог. Следующий «Черный щит» (в Громовой Утес) не берите.",
                   en = "Krog. Skip the next The Black Shield (to Thunder Bluff)." } },
        { complete = 1206, at = { 1445, 32.40, 22.10 },
          note = { ru = "К северу у Мглистой пещеры: пауки (35-39) - 40 целых глаз.",
                   en = "North at Darkmist Cavern: the spiders (35-39) - 40 Unpopped Darkmist Eyes." } },
        { turnin = 1206, npc = 4792, at = { 1445, 55.44, 26.27 },
          note = { ru = "На восток к Ярлу.", en = "East to Jarl." } },
        { accept = 1239, object = 20985, at = { 1445, 55.44, 25.92 },
          note = { ru = "Рыхлая земля: «Отрубленная голова».", en = "Loose Dirt: The Severed Head." } },
        { id = "h40-theramore-docks", complete = 1202, object = 20925, at = { 1445, 71.53, 51.19 },
          note = { ru = "На юго-восток к Терамору: сундучок капитана лежит под водой у причалов - подплывайте со "
                       .. "стороны моря, к стражникам на причале (53-57) не приближайтесь.",
                   en = "South-east to Theramore: the Captain's Footlocker lies underwater by the docks - swim in from "
                       .. "the sea side and keep away from the guards on the pier (53-57)." } },

        ------------------------------------------------------------------
        -- Wyrmbog 1 (40)
        ------------------------------------------------------------------
        { complete = { [1166] = { 1 } }, object = 19904, at = { 1445, 44.53, 66.04 },
          note = { ru = "На запад к Драконьей топи: понюшка Мок'Морокка в разрушенной хижине огров.",
                   en = "West to the Wyrmbog: Mok'Morokk's Snuff in a ruined ogre hut." } },
        { id = "h-38-dustwallow-marsh-field", complete = { 1168, 1169 }, at = { 1445, 45.00, 71.50 },
          note = { ru = "Драконья топь: Огнегривые - 15 разведчиков, 10 пеплохвостов, 5 чешуйчатых губителей (41-44); "
                       .. "с опаляющих дракончиков и малышей - 15 огненных языков и 15 пылающих сердец.",
                   en = "The Wyrmbog: Firemane - 15 Scouts, 10 Ash Tails, 5 Scalebanes (41-44); Searing Whelps and "
                       .. "Hatchlings - 15 Searing Tongues and 15 Searing Hearts." } },
        { complete = { [1166] = { 2 } }, object = 19905, at = { 1445, 38.66, 65.57 },
          note = { ru = "На запад: грог Мок'Морокка.", en = "West: Mok'Morokk's Grog." } },
        { complete = { [1166] = { 3 } }, object = 19906, at = { 1445, 36.64, 69.57 },
          note = { ru = "Рядом: сейф Мок'Морокка.", en = "Nearby: Mok'Morokk's Strongbox." } },
        { turnin = 1177, npc = 4503, at = { 1445, 35.15, 38.26 },
          note = { ru = "На север к дробильщику Грязноногу.", en = "North to Mudcrush Durtfeet." } },

        ------------------------------------------------------------------
        -- Brackenwall 3, Wyrmbog 2, Brackenwall end (40-41)
        ------------------------------------------------------------------
        { turnin = { 1239, 1202 }, npc = 4791, at = { 1445, 35.21, 30.66 },
          note = { ru = "Назир: голова и бумаги капитана. «Тролль-знахарь» (в Тернистую долину) не берите.",
                   en = "Nazeer: the head and the captain's papers. Skip The Troll Witchdoctor (Stranglethorn)." } },
        { turnin = 1168, npc = 4502, at = { 1445, 37.37, 31.39 },
          note = { ru = "Тхарг.", en = "Tharg." } },
        { turnin = 1169, accept = 1170, npc = 4501, at = { 1445, 37.15, 33.09 },
          note = { ru = "Драз'Зилб.", en = "Draz'Zilb." } },
        { turnin = { 1166, 1170 }, accept = 1171, npc = 4500, at = { 1445, 36.29, 31.41 },
          note = { ru = "Властитель Мок'Морокк.", en = "Overlord Mok'Morokk." } },
        { turnin = 1171, accept = 1172, npc = 4501, at = { 1445, 37.15, 33.09 },
          note = { ru = "Драз'Зилб.", en = "Draz'Zilb." } },
        { complete = 1172, object = 20359, at = { 1445, 48.48, 74.00 },
          note = { ru = "Снова в Драконью топь: 5 яиц Ониксии в гнездах среди дракончиков.",
                   en = "Back to the Wyrmbog: 5 Eggs of Onyxia in the nests among the whelps." } },
        -- End-of-segment checkpoint of the plan: the Dustwallow quests alone reach it (no grind in the validator's
        -- model); Arathi and the Badlands need 40 (782 at Kargath), the rest of the deficit waits for the h-41 gate,
        -- where it is ground at 42-43 (more XP per kill).
        { id = "h-37-desolace-dustwallow-level-gate", level = { 40, 0.25 }, at = { 1445, 45.00, 71.50 },
          note = { ru = "Контроль: 40 + 25% (задания Пылевых топей дают это сами; дальше Арати и Бесплодные земли). Не "
                       .. "хватает (пропустили задания) - Огнегривые и дракончики Драконьей топи (41-44) здесь же.",
                   en = "Checkpoint: 40 + 25% (the Dustwallow quests get you there; Arathi and the Badlands are next). "
                       .. "Short (skipped quests): the Wyrmbog Firemane and whelps (41-44) right here." } },
        { id = "h-41-brackenwall-end", turnin = 1172, npc = 4501, at = { 1445, 37.15, 33.09 },
          note = { ru = "Обратно в Гиблотопь: Драз'Зилб. «Вызов властителю Мок'Морокку» (он элита) не берите.",
                   en = "Back to Brackenwall: Draz'Zilb. Skip Challenge Overlord Mok'Morokk (elite)." } },
    },
})
