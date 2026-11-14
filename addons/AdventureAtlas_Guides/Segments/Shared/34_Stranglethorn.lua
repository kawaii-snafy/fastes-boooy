-- AdventureAtlas_Guides / Segments / Shared / 34_Stranglethorn.lua
--
-- Library segment "h-34-stranglethorn": Hammerfall -> Undercity -> zeppelin to Grom'gol -> on foot to Booty Bay
-- (quests, flight path) -> hearth Grom'gol -> Stranglethorn north (Nesingwary, Bloodscalp trolls, Lake Nazferiti)
-- -> Grom'gol -> Mosh'Ogg outpost / Shadowmaw cats -> Vile Reef -> Bloodscalp inner village -> Nesingwary ->
-- hearth Grom'gol -> fly Booty Bay, levels 34-37.
-- Class-neutral: no quest of the segment is limited to a race or class; no training here
-- (the paladin's level-34 training is the class insert after h-34-uc-arrive).
-- Coordinates: Forever uiMap 1458 (Undercity) / 1420 (Tirisfal Glades) / 1434 (Stranglethorn Vale), map percent,
-- from tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective mob
-- spawns of the chosen area for complete steps (h34 tools: research scratch cen.lua). Road points Grom'gol ->
-- Booty Bay are spawns of NPCs standing / patrolling on the road (Se'Jib 7871, Verifonix 14492) and the spirit
-- healer 6491 outside the Booty Bay tunnel; the Undercity lift exit is the one of h-13-silverpine (h13-uc-lift).
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
--
-- Plan: research plan60.md section 4.5 / plan60.json segments[5]. Hubs and quests:
--   UC     : 1164 (Genavie Callow; carried from Arathi), 513 (Faranell; carried from Tarren Mill). 515 (back
--            to Hillsbrad) is not taken.
--   GG 1   : 570, 568, 581, 596 + 629; flight path; hearth bound to Grom'gol.
--   BB 1   : on foot along the road: 575, 605, 189 + 213, 201; flight path; hearth back to Grom'gol.
--   north  : Nesingwary 5762, 583 > 194 / 185 / 190; camp: young tigers, young panthers, river crocolisks (575);
--            > 186 / 191; west: tigers + panthers, raptors + crystal spine basilisks (194, 605), Bloodscalp outer
--            village (581, 189, 596); > 195 / 187 / 192; Lake Nazferiti (213), lashtails
--            (568 + 195), elder tigers (187); > 195 / 187 > 188; Sin'Dall.
--   GG 2   : 568 > 569, 581 > 582; Mosh'Ogg outpost (569), Shadowmaw panthers / tigresses (192, 570); 569, 570.
--   west   : Vile Reef (629), Bloodscalp inner village (582, rest of 596; level gate); Nesingwary 188, 192;
--            hearth; GG 582, 596 + 629; fly Booty Bay: 201, 189 + 213, 605, 575.
-- Deviations from the plan:
--   * 577 Some Assembly Required / 628 Excelsior are not taken: 577 can only be accepted after 575 is turned in
--     (a third Booty Bay visit for 1400 XP) and 628's Elder Saltwater Crocolisk 2635 is a level-38 ELITE.
--   * h-37-bootybay-end is the last step of the segment (Booty Bay, the plan's segment end); plan60.json lists
--     it as the "last pass" id of the Grom'gol hub - the last Grom'gol step here is h36-gromgol-end.
--   * Booty Bay is visited first, on foot (all five of its quests have their objectives in the north); the
--     hearthstone is bound to Grom'gol. Booty Bay -> Grom'gol is a flight (h34-hearth-gromgol-1 keeps its id): the
--     stone was used at Hammerfall ~22-25 min earlier and is still on its 1-hour cooldown; it is used once, from
--     Nesingwary (h34-hearth-gromgol-2).
-- Skipped: 338-342 Green Hills pages (random drops), 196 / 572 / 584-586 / 193 / 209 / 600 (level 40+, h-44),
--   638 Trollbane (back to Arathi), 1109 / 1113 / 1160 / 1394 (dungeon / Test of Lore chain), Forever-new 97328 /
--   97329 / 97331 (Zul'Kunda, no turn-in NPC in the data), 97047 / 97048 (Kurzen, no giver), Drowned City
--   95748-95776 (no givers), 1180-1183 Goblin Sponsorship (starts in Ratchet).
-- Place names: "Grom'gol Base Camp" (AreaTable 117 = the bind location name) for the flight point, the hearth and
--   later flights; "Booty Bay" (area 35).
-- Automation notes: at each hub the transient steps (fp, sethearth, hearth, fly) follow its quest steps; the
--   background goal (581 / 189 / 596) is followed by its stateful steps with no transient step in between; the
--   hearth / fly steps come right after turn-ins that cannot be done before them. Kill objectives shared by two
--   quests (lashtails 568 / 195, Shadowmaw panthers 192 / 570) are completed in one combined step.
-- XP (validator, Classic quest XP + objective kills, ~46 k + ~51 k): the questing alone ends near 35.6. Every
--   quest of Stranglethorn that fits 34-37 and needs no elite is already taken (the rest are pages, elite, dungeon or
--   start/end far away), so the segment does not add quests; the densification is the grind: the optional gate
--   h34-level-35 (35 + 25%) is gone and h-34-stranglethorn-level-gate (inner village, 36-37 trolls that also drop
--   the 582 / 596 items) is lowered from 36 + 72% to 35 + 75% (~150 same-level kills instead of ~460), so the segment
--   ends at 36.06 (within 1 of the planned 37). The deficit moves to the Desolace gates, where it is ground at a
--   higher level (more XP per kill) and the Desolace quests are turned in at a lower one (less level penalty): the
--   gate retune of the range 34-46 saves ~30 kills (normal) / ~15 (worst case) for the same end level, 46.01.
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "h-34-stranglethorn",
    title = { ru = "34-37 Тернистая долина", en = "34-37 Stranglethorn Vale" },
    zone = "Stranglethorn Vale",
    levels = { 34, 37 },
    steps = {
        ------------------------------------------------------------------
        -- Hammerfall -> Undercity
        ------------------------------------------------------------------
        { id = "h34-fly-uc", fly = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Урда (Павший Молот): летите в Подгород (через Мельницу Таррен).",
                   en = "Urda (Hammerfall): fly to Undercity (via Tarren Mill)." } },
        { id = "h-34-uc-arrive", turnin = 1164, npc = 4486, at = { 1458, 63.83, 49.45 },
          note = { ru = "Генви Кэллоу рядом с Майклом Гарретом (полёты): «Ограбить воров».",
                   en = "Genavie Callow next to Michael Garrett (flights): To Steal From Thieves." } },
        { id = "h34-faranell", turnin = 513, npc = 2055, at = { 1458, 48.82, 69.28 },
          note = { ru = "Мастер аптекарь Фаранелл в зале аптекарей (юго-запад). Продолжение «Эликсир агонии» (515) "
                       .. "не берите: оно ведёт обратно в Хилсбрад.",
                   en = "Master Apothecary Faranell in the Apothecarium (south-west). Skip the next Elixir of Agony "
                       .. "(515): it leads back to Hillsbrad." } },
        { id = "h34-uc-exit", go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Наверх на лифте и из Руин Лордерона к башне дирижаблей.",
                   en = "Up the lift and out of the Ruins of Lordaeron to the zeppelin tower." } },
        { id = "h-34-tirisfal-zeppelin-to", go = true, radius = 15, npc = 3150, at = { 1420, 61.78, 59.18 },
          note = { ru = "Башня дирижаблей: Гин Денбург - дирижабль в Лагерь Гром'гол (Тернистая долина), а не в "
                       .. "Оргриммар.",
                   en = "Zeppelin tower: Hin Denburg - the zeppelin to Grom'gol Base Camp (Stranglethorn Vale), not "
                       .. "the one to Orgrimmar." } },
        { id = "h-34-gromgol-arrive", go = true, radius = 40, npc = 3149, at = { 1434, 31.43, 29.91 },
          note = { ru = "Прилёт в Лагерь Гром'гол.", en = "Arrival at Grom'gol Base Camp." } },

        ------------------------------------------------------------------
        -- Grom'gol Base Camp (34)
        ------------------------------------------------------------------
        { accept = 570, npc = 2465, at = { 1434, 32.12, 29.24 },
          note = { ru = "Провозвестник Мок'тардин. Когти и клык - позже, у тенебрюхих пантер к юго-востоку.",
                   en = "Far Seer Mok'thardin. The claws and the fang come later, from the Shadowmaw cats south-east." } },
        { accept = 568, npc = 2464, at = { 1434, 32.17, 28.90 },
          note = { ru = "Командир Агро'гош: 15 ящеров-кнутохвостов.", en = "Commander Aggro'gosh: 15 Lashtail Raptors." } },
        { accept = 581, npc = 2497, at = { 1434, 32.16, 27.72 },
          note = { ru = "Нимбойя.", en = "Nimboya." } },
        { accept = { 596, 629 }, npc = 2519, at = { 1434, 32.27, 27.71 },
          note = { ru = "Кин'вилай: ожерелья Кровавых костей падают со всех троллей Кровавого Скальпа.",
                   en = "Kin'weelay: the Bloody Bone Necklaces drop from every Bloodscalp troll." } },
        { id = "h34-fp-gromgol", fp = "Grom'gol Base Camp", npc = 1387, at = { 1434, 32.54, 29.35 },
          note = { ru = "Тиста: откройте карту полётов.", en = "Thysta: open the flight map." } },
        { id = "h34-sethearth-gromgol", sethearth = "Grom'gol Base Camp", npc = 5814, at = { 1434, 31.49, 29.75 },
          note = { ru = "Хозяин таверны Тулбек у башни: камень возвращения - в Гром'гол.",
                   en = "Innkeeper Thulbek by the tower: bind your hearthstone to Grom'gol." } },

        ------------------------------------------------------------------
        -- On foot to Booty Bay (its quests have their objectives in the north)
        ------------------------------------------------------------------
        { id = "h34-road-south", go = true, radius = 25, at = { 1434, 36.55, 34.09 },
          note = { ru = "Из лагеря на восток к большой дороге (огры Мош'Огг остаются слева) и по ней на юг, всего "
                       .. "5-6 минут. С дороги не сходите: вокруг мобы 37-43.",
                   en = "East out of the camp to the main road (the Mosh'Ogg ogres stay on your left), then south "
                       .. "along it, 5-6 minutes in all. Stay on the road: the mobs around are 37-43." } },
        { id = "h34-road-arena", go = true, radius = 25, at = { 1434, 35.91, 54.46 },
          note = { ru = "Дальше на юг мимо Арены Гурубаши (справа).", en = "On south past the Gurubashi Arena (on your right)." } },
        { id = "h34-bb-tunnel", go = true, radius = 25, at = { 1434, 30.36, 73.28 },
          note = { ru = "К туннелю в Пиратскую Бухту.", en = "To the tunnel into Booty Bay." } },
        { id = "h-34-booty-bay", accept = 575, npc = 2495, at = { 1434, 28.29, 77.59 },
          note = { ru = "Дриззлик на втором ярусе домов.", en = "Drizzlik on the second level of buildings." } },
        { accept = 605, npc = 2498, at = { 1434, 27.12, 77.21 },
          note = { ru = "Шиззи Пуззырикс на нижнем этаже таверны.", en = "Crank Fizzlebub on the inn's bottom floor." } },
        { accept = { 189, 213 }, npc = 737, at = { 1434, 27.00, 77.13 },
          note = { ru = "Кебок на верхнем этаже таверны.", en = "Kebok on the inn's top floor." } },
        { accept = 201, npc = 773, at = { 1434, 26.95, 77.21 },
          note = { ru = "Кразек рядом.", en = "Krazek next to him." } },
        { id = "h34-fp-bootybay", fp = "Booty Bay", npc = 2858, at = { 1434, 26.87, 77.10 },
          note = { ru = "Грингер рядом: откройте карту полётов.", en = "Gringer next to them: open the flight map." } },
        { id = "h34-hearth-gromgol-1", fly = "Grom'gol Base Camp", npc = 1387, at = { 1434, 32.54, 29.35 },
          note = { ru = "Грингер: летите в Гром'гол. Камень не тратьте - он ещё на откате после Павшего Молота (~25 мин "
                       .. "назад) и нужен позже, от Эрнестуэя.",
                   en = "Gringer: fly to Grom'gol. Do not use the hearthstone - it is still on cooldown from Hammerfall "
                       .. "(~25 min ago) and is needed later, from Nesingwary." } },

        ------------------------------------------------------------------
        -- North: Nesingwary's Expedition and its loops (34-35)
        ------------------------------------------------------------------
        { complete = { 581, 189, 596 }, bg = true, at = { 1434, 31.03, 18.41 },
          note = { ru = "Попутно бейте троллей Кровавого Скальпа (развалины к северу от Гром'гола, деревня на "
                       .. "северо-западе): клыки (581), уши (189), ожерелья (596).",
                   en = "Kill Bloodscalp trolls on the way (the ruins north of Grom'gol, the village in the "
                       .. "north-west): tusks (581), ears (189), necklaces (596)." } },
        { id = "h-34-nesingwary-s-expedition", accept = 583, complete = 201, npc = 716, at = { 1434, 35.66, 10.53 },
          note = { ru = "На север к лагерю Хеминга Эрнестуэя (Хемет Несингвари), 2 минуты. Лагерь найден - «Поиск "
                       .. "лагеря» выполнено. Барнил Каменный Кубок.",
                   en = "North to Hemet Nesingwary's camp, 2 minutes. The camp is found - Investigate the Camp is "
                       .. "done. Barnil Stonepot." } },
        { turnin = { 5762, 583 }, accept = 194, npc = 715, at = { 1434, 35.66, 10.81 },
          note = { ru = "Хеминг Эрнестуэй (Хемет Несингвари).", en = "Hemet Nesingwary." } },
        { accept = 185, npc = 717, at = { 1434, 35.62, 10.62 },
          note = { ru = "Ажек Руак.", en = "Ajeck Rouack." } },
        { accept = 190, npc = 718, at = { 1434, 35.55, 10.55 },
          note = { ru = "Сэр С. Дж. Эрлгедин.", en = "Sir S. J. Erlgadin." } },
        { id = "h-34-stranglethorn-vale-field", complete = { 185, 190, 575 }, at = { 1434, 38.50, 11.41 },
          note = { ru = "Вокруг лагеря: 10 молодых тигров (запад и юг), 10 молодых пантер (восток), 2 большие шкуры "
                       .. "речных кроколисков из реки у лагеря.",
                   en = "Around the camp: 10 young tigers (west and south), 10 young panthers (east), 2 large skins "
                       .. "from the river crocolisks in the river by the camp." } },
        { turnin = 185, accept = 186, npc = 717, at = { 1434, 35.62, 10.62 },
          note = { ru = "Ажек Руак.", en = "Ajeck Rouack." } },
        { turnin = 190, accept = 191, npc = 718, at = { 1434, 35.55, 10.55 },
          note = { ru = "Сэр С. Дж. Эрлгедин.", en = "Sir S. J. Erlgadin." } },
        { complete = { 186, 191 }, at = { 1434, 29.81, 12.05 },
          note = { ru = "На запад: 10 тигров и 10 пантер между лагерем и деревней троллей.",
                   en = "West: 10 tigers and 10 panthers between the camp and the troll village." } },
        { complete = { 194, 605 }, at = { 1434, 25.39, 16.72 },
          note = { ru = "Юго-западнее: 10 ящеров Тернистой долины и хрустальные василиски (10 осколков Поющего "
                       .. "кристалла).",
                   en = "South-west of them: 10 Stranglethorn Raptors and Crystal Spine Basilisks (10 Singing "
                       .. "Crystal Shards)." } },
        { complete = { 581, 189 }, at = { 1434, 25.03, 11.38 },
          note = { ru = "Внешняя часть деревни Кровавого Скальпа (разведчики, мистики, охотники 34-35): 9 клыков, "
                       .. "15 ушей; ожерелья (596) копите. Вглубь, к вождям, не ходите.",
                   en = "The outer Bloodscalp village (scouts, mystics, hunters 34-35): 9 tusks, 15 ears; keep the "
                       .. "necklaces (596). Do not go deep, to the chiefs." } },
        { turnin = 194, accept = 195, npc = 715, at = { 1434, 35.66, 10.81 },
          note = { ru = "Обратно в лагерь.", en = "Back to the camp." } },
        { turnin = 186, accept = 187, npc = 717, at = { 1434, 35.62, 10.62 },
          note = { ru = "Ажек Руак.", en = "Ajeck Rouack." } },
        { turnin = 191, accept = 192, npc = 718, at = { 1434, 35.55, 10.55 },
          note = { ru = "Сэр С. Дж. Эрлгедин.", en = "Sir S. J. Erlgadin." } },
        { complete = 213, at = { 1434, 44.51, 20.39 },
          note = { ru = "На юго-восток к озеру Назферити: геологи Торговой компании на восточном берегу - 8 упавших "
                       .. "кристаллов. Осторожно: штейгер Коззл (38) и крошшер.",
                   en = "South-east to Lake Nazferiti: Venture Co. Geologists on the east shore - 8 Tumbled "
                       .. "Crystals. Mind Foreman Cozzle (38) and the shredder." } },
        { complete = { 568, 195 }, at = { 1434, 38.44, 22.65 },
          note = { ru = "Ящеры-кнутохвосты к западу от озера: каждый засчитывается в оба задания (всего 15).",
                   en = "Lashtail Raptors west of the lake: every kill counts for both quests (15 in all)." } },
        { complete = 187, at = { 1434, 33.36, 18.50 },
          note = { ru = "Дальше на запад: 10 старых тигров Тернистой долины.",
                   en = "Further west: 10 Elder Stranglethorn Tigers." } },
        { turnin = 195, npc = 715, at = { 1434, 35.66, 10.81 },
          note = { ru = "Обратно в лагерь. Следующий ящер (196, 41) - позже.",
                   en = "Back to the camp. The next raptor quest (196, 41) is for later." } },
        { turnin = 187, accept = 188, npc = 717, at = { 1434, 35.62, 10.62 },
          note = { ru = "Ажек Руак.", en = "Ajeck Rouack." } },
        { complete = 188, at = { 1434, 31.84, 16.45 },
          note = { ru = "Син'Далл (37, в незаметности) бродит на холме к юго-западу от лагеря - лапа. Затем на юг в "
                       .. "Гром'гол через развалины троллей.",
                   en = "Sin'Dall (37, stealthed) roams the hill south-west of the camp - his paw. Then south to "
                       .. "Grom'gol through the troll ruins." } },

        ------------------------------------------------------------------
        -- Grom'gol, Mosh'Ogg outpost, Shadowmaw cats (35-36)
        ------------------------------------------------------------------
        { id = "h34-gromgol-568", turnin = 568, accept = 569, npc = 2464, at = { 1434, 32.17, 28.90 },
          note = { ru = "Командир Агро'гош.", en = "Commander Aggro'gosh." } },
        { id = "h34-gromgol-581", turnin = 581, accept = 582, npc = 2497, at = { 1434, 32.16, 27.72 },
          note = { ru = "Нимбойя.", en = "Nimboya." } },
        { complete = 569, at = { 1434, 37.10, 30.77 },
          note = { ru = "Восточнее лагеря, у заставы огров: 10 громил и 5 знахарей из клана Мош'Огг. Редкий Ролох "
                       .. "(38) тоже ходит здесь - обходите.",
                   en = "East of the camp, at the ogre outpost: 10 Mosh'Ogg Brutes and 5 Witch Doctors. The rare "
                       .. "Roloch (38) walks here too - avoid him." } },
        { complete = { 192, 570 }, at = { 1434, 38.90, 37.87 },
          note = { ru = "Южнее: 10 тенебрюхих пантер (в незаметности), 8 когтей с них и безупречный тигриный клык с "
                       .. "тигрицы Тернистой долины (появляются на тех же местах).",
                   en = "South: 10 Shadowmaw Panthers (stealthed), 8 claws from them and the Pristine Tigress Fang "
                       .. "from a Stranglethorn Tigress (they share the spots)." } },
        { id = "h34-gromgol-569", turnin = 569, npc = 2464, at = { 1434, 32.17, 28.90 },
          note = { ru = "Командир Агро'гош.", en = "Commander Aggro'gosh." } },
        { id = "h34-gromgol-570", turnin = 570, npc = 2465, at = { 1434, 32.12, 29.24 },
          note = { ru = "Следующие чары Мок'тардина (572, 41) - позже.",
                   en = "Mok'thardin's next enchantment (572, 41) is for later." } },

        ------------------------------------------------------------------
        -- Vile Reef, Bloodscalp inner village, Nesingwary (36-37)
        ------------------------------------------------------------------
        { complete = 629, object = 58, at = { 1434, 24.82, 23.03 },
          note = { ru = "Коварный риф к западу: обломок таблички с Гри'лека на дне. Мурлоки Соленой Чешуи - ЭЛИТА: "
                       .. "плывите над ними к табличке и сразу назад. Слишком опасно - бросьте 629, но тогда "
                       .. "Кин'вилай не даст «Ожерелье расколотых костей» (598, h-44): оно открывается только после "
                       .. "596 и 629.",
                   en = "The Vile Reef to the west: the Tablet Shard from Gri'lek on the sea floor. The Saltscale "
                       .. "murlocs are ELITE: swim over them to the tablet and straight back. Too risky: abandon 629, "
                       .. "but then Kin'weelay will not offer Split Bone Necklace (598, h-44): it needs both 596 and "
                       .. "629." } },
        { complete = { 582, 596 }, at = { 1434, 22.52, 10.62 },
          note = { ru = "На север во внутреннюю деревню Кровавого Скальпа: охотники за головами (20 сушеных голов), "
                       .. "берсерки и знахари 36-37; доберите 25 ожерелий. Вождей Ган'зулаха и Неззилока (40-41) не "
                       .. "трогайте.",
                   en = "North into the inner Bloodscalp village: headhunters (20 Shrunken Heads), berserkers and "
                       .. "witch doctors 36-37; finish the 25 necklaces. Leave chiefs Gan'zulah and Nezzliok (40-41) "
                       .. "alone." } },
        -- level-grind of the next step (acknowledged with `ok`): the minimum for Desolace (its first quests are 37-39 with mobs 34-40):
        -- 35 + 75% plus the remaining turn-ins = 36.06; the rest of the deficit is ground later, in Desolace.
        { id = "h-34-stranglethorn-level-gate", level = { 35, 0.75 }, at = { 1434, 22.52, 10.62 },
          ok = { ["level-grind"] = 160 }, -- 152 / 151 kills in the normal run (reason above)
          note = { ru = "Цель: 35 + 75% (с оставшимися сдачами будет 36 - хватит для первых заданий Пустошей). Не "
                       .. "хватает - бейте троллей здесь же: плотные лагеря 36-37, быстрый респаун, попутно падают "
                       .. "головы и ожерелья. Альтернатива - Монастырь Алого ордена (Кладбище) в группе.",
                   en = "Target: 35 + 75% (the remaining turn-ins then make 36, enough for the first Desolace "
                       .. "quests). Short: keep killing trolls right here - dense 36-37 camps, quick respawns, heads "
                       .. "and necklaces drop on the side. Alternative: Scarlet Monastery (Graveyard) in a group." } },
        { turnin = 188, npc = 717, at = { 1434, 35.62, 10.62 },
          note = { ru = "На восток в лагерь Эрнестуэя.", en = "East to Nesingwary's camp." } },
        { turnin = 192, npc = 718, at = { 1434, 35.55, 10.55 },
          note = { ru = "Последняя пантера (193, 40) - позже.", en = "The last panther quest (193, 40) is for later." } },
        { id = "h34-hearth-gromgol-2", hearth = "Grom'gol Base Camp", at = { 1434, 31.49, 29.75 },
          note = { ru = "Камень возвращения в Гром'гол. На откате - 2 минуты бегом на юг.",
                   en = "Hearth to Grom'gol. On cooldown: a 2-minute run south." } },

        ------------------------------------------------------------------
        -- Grom'gol turn-ins, fly to Booty Bay
        ------------------------------------------------------------------
        { id = "h35-gromgol-582", turnin = 582, npc = 2497, at = { 1434, 32.16, 27.72 },
          note = { ru = "Головы вождей (584, 41) - позже.", en = "The chiefs' heads (584, 41) are for later." } },
        { id = "h36-gromgol-end", turnin = { 596, 629 }, npc = 2519, at = { 1434, 32.27, 27.71 },
          note = { ru = "Кин'вилай.", en = "Kin'weelay." } },
        { id = "h34-fly-bootybay", fly = "Booty Bay", npc = 2858, at = { 1434, 26.87, 77.10 },
          note = { ru = "Тиста: летите в Пиратскую Бухту.", en = "Thysta: fly to Booty Bay." } },
        { id = "h35-bootybay-201", turnin = 201, npc = 773, at = { 1434, 26.95, 77.21 },
          note = { ru = "Кразек на верхнем этаже таверны.", en = "Krazek on the inn's top floor." } },
        { id = "h35-bootybay-189", turnin = { 189, 213 }, npc = 737, at = { 1434, 27.00, 77.13 },
          note = { ru = "Кебок. Следующее (209, 42) - позже.", en = "Kebok. The follow-up (209, 42) is for later." } },
        { id = "h35-bootybay-605", turnin = 605, npc = 2498, at = { 1434, 27.12, 77.21 },
          note = { ru = "Шиззи Пуззырикс внизу. Продолжение (600, 41) - позже.",
                   en = "Crank Fizzlebub downstairs. The follow-up (600, 41) is for later." } },
        { id = "h-37-bootybay-end", turnin = 575, npc = 2495, at = { 1434, 28.29, 77.59 },
          note = { ru = "Дриззлик. Продолжение (577) не берите: третий визит в Бухту не окупается.",
                   en = "Drizzlik. Skip the follow-up (577): a third Booty Bay visit does not pay off." } },
    },
})
