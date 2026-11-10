-- FastesBoooy_Guides / Segments / Shared / 50_Hinterlands_Searing_Steppes.lua
--
-- Library segment "h-50-hinterlands-searing-steppes": levels 50-53, class-neutral (Undead Paladin and Skyborne
-- Druid, Horde). Camp Mojache -> fly Orgrimmar (turn-ins) -> zeppelin -> Undercity -> fly Tarren Mill -> ride into
-- the Hinterlands (Quel'Danil Lodge, Skulk Rock) -> Revantusk Village (two loops: north coast + wilds + west, then
-- Jintha'Alor) -> fly Kargath -> Searing Gorge (Thorium Point, Kalaran Windblade, the Cauldron) -> Blackrock Mountain
-- -> Burning Steppes (Flame Crest, Dreadmaul Rock) -> hearth Kargath -> fly Stonard (Fallen Hero chain) -> Blasted
-- Lands (Bloodmages, Kum'isha, level gate) -> hearth Kargath (optional Sunken Temple turn-in: Stonard instead).
-- Plan: research plan60.md section 4.10 / plan60.json segments[10] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1454 (Orgrimmar) / 1411 (Durotar) / 1420 (Tirisfal) / 1458 (Undercity) / 1424
-- (Hillsbrad) / 1425 (The Hinterlands) / 1418 (Badlands) / 1427 (Searing Gorge) / 1428 (Burning Steppes) / 1435
-- (Swamp of Sorrows) / 1419 (Blasted Lands), map percent, from tools/data/forever_db.lua: NPC / object spawns for
-- npc / object steps, centroids of the objective mob / object spawns of the area used for complete steps (h50
-- tools: research scratch h50/cen.lua, near.lua). ruRU names: Wowhead Forever ruRU tooltips.
-- Objective counts: the Revantusk quest texts still say 15 / 20 / 30 kills; the DB (WCLBox goals) has lower counts,
-- which are the ones given in the notes. The Wowhead Forever tooltips (objective data) give the full text counts, so
-- the sources conflict: every note names both and tells the player to trust the quest log counter (the steps finish
-- from the game state anyway); for the elite 7861 / 7862 (~100 elite kills at the text counts) the note says to
-- abandon them if the counter shows 20 (the engine skips their steps; the mixed turn-in step waits for the rest).
--
-- Hub plan (Forever DB; every quest is open to Scourge and Skyborne Horde characters of any class):
--   ORG : 3002 (Uthel'nay); 3121 (Neeru); 32 + 7732 (Zilzibin); 4300 (Jes'rimon); 649 > 650 (Droffers); 2976 > 3504.
--   UC  : 2995 (Oran), 81949 (Owen Thadd), 864 (Zinge), 3568 (Cuely). Fly Tarren Mill, ride into the Hinterlands.
--   HW  : Gilveradin 650 > 77; Highvale papers (2995); Rin'ji 2742 (escort out of the lodge); Skulk Rock crates (77).
--   RV1 : fp, hearth; 7840, 7845 + 7850, 7815 + 7816, 7828 + 7829 + 7830 + 7849, 7861 + 7862, 7841, 7844, 7839.
--   L1  : coast snapjaws (7815), Gammerita (7816), Rin'ji's Secret 2742 > 2782, Lard's lunch (7840), Vilebranch camp
--         (7844, 7839), wilds (7829, 7830, 7828), Violet Tragan (2641), book 81954, Atal'ai Exile 1429 > 1444, Quel'Danil elves
--         (7841), Gilveradin 77 > 81; hearth.
--   RV2 : turn-ins; 7841 > 7842.
--   L2  : skylords (7842 feathers), Jintha'Alor: skull pile, vessels, bones, elite trolls (7862), Hexx + guards
--         (7861), Elder Torntusk 7845 > 7846, Hitah'ya (key), 7846 > 7847.   RV3: turn-ins, fly Kargath.
--   KG  : hearth Kargath, 3821, (optional BRD: 4134, 3906, 4081).  SG: Thorium Point (fp, 7701 / 7728 / 7729 board, 7722,
--         7723 / 7724 / 7727),
--         Kalaran 3441 > 3442, Slag Pit (incendosaurs 7727, 7701, 7722), Cauldron (7723, 3442, 7729 bg, 7728),
--         lava spiders (7724), 3442 > 3443 (daggers), 3443 > 3452 (Twilight cultists), Thorium Point turn-ins,
--         3452 > 3453 > 3454 > 3462 > 3463 (braziers), 3481 hoard, book 81955 (Cauldron). South through Blackrock
--         Mountain: book 81953 (Franclorn), optional Blackrock Depths block (3906 Pyron, 4081, 4134).
--   BS  : Flame Crest fp, 4296, 4726; tablet; Dreadmaul Rock 3821 > 3822 (Krom'Grul); broodlings (4726);
--         4726 > 4808, 4296; hearth Kargath 3822, (optional 4134, 3906, 4081); fly Stonard.
--   SW  : Fallen Hero 2784 > 2621; Stonard 2621 > 2622, 1444 (+ optional 1445), 2622 > 2623; book 81947 (Pool of Tears),
--         optional Sunken Temple (1445); Swamp Talkers; Fallen Hero 2623.
--   BL  : Bloodmages 2581 / 2583 / 2585 / 2601 / 2603 (shared parts: collect totals), Kum'isha 2521 / 3501 (random
--         drops), book 81956, field loop, level gate at the helboars, turn-ins; hearth Kargath (the stone is off its
--         cooldown since the Flame Crest hearth; Kargath -> Undercity skips the ride back to Stonard and the
--         Stonard -> Kargath flight leg; only after the optional 1445 does the player go to Stonard and fly from there).
-- Deviations from the plan (documented in the handoff):
--   * 2995 Lines of Communication cannot be turned in on the same Undercity visit (its papers are in the
--     Hinterlands): it is carried COMPLETE, with 2782 Rin'ji's Secret, to Oran Snakewrithe (Undercity) - the plan's
--     next segment travels Kargath (hearth) -> Undercity -> Orgrimmar (+ 8273 Oran's Gratitude there).
--   * Added on the path: 7841 > 7842 (Otho Moji'ko; Quel'Danil elves + gryphon feathers), 3481 Trinkets... (hoard next
--     to Kalaran, 470 XP). 3379 / 3385 / 3402 (Nilith Lokrav) are not in the Forever quest lists (WCLBox) -> not used;
--     Nilith Lokrav and the Wooden Outhouse stay travel points (Searing Gorge exit / entrance), as in the plan.
--   * No second Kargath visit on foot: the hearthstone is bound in Kargath on the way in and used from Flame Crest
--     to turn in 3822 (the plan's "Revantusk, then Kargath"), and once more from the Blasted Lands at the end
--     (h-51-stonard-2 keeps its plan id: Kargath -> Undercity instead of the ride to Stonard + Stonard -> Undercity).
--   * The end gate sits before the last turn-ins (level 52 + 30%: Kum'isha + Bloodmage turn-ins make ~52.6).
--   * Densify pass (r3): the segment starts at ~49.4 (h-46 end gate lowered), so the two reqLevel 50 quests of the old
--     start moved: 4494 March of the Silithid -> the Orgrimmar visit of h-53 (Zilzibin), 5094 A Call to Arms: The
--     Plaguelands! -> the Undercity visit of h-56 (Balthazad). Added: 3121 turn-in (Neeru, from Feralas), the
--     Forever-new library books 81954 / 81955 / 81953 / 81947 / 81956 (objects on the path, XP unknown, turned in to
--     Owen Thadd in the Undercity of h-53) and 81949 turn-in (from Tanaris); optional group blocks for Blackrock Depths
--     (4134, 3906, 4081 at Kargath) and the Sunken Temple (1445, Fel'Zerul). 4133 Vivian Lagrave (reqLevel 50 at Zinge)
--     dropped. End gate 52 + 77% -> 52 + 30% (Azshara / Un'Goro are fine from 52).
-- Skipped: 485 / 836 OOX-09/HL (random drop + escort), 2933-2938 (Tarren Mill / Sen'jin chain), 7843 (Aerie Peak),
--   4449 Caught! (done in h-41, next to Kargath), 4450 / 4451 (Ledger from Tanaris: one item is in Dustwallow, which
--   the route does not revisit), 7704 (removed), 4082 / 3907 / 3981 (follow-ups of the BRD block,
--   offered only after its turn-ins) and 4061 (reqLevel 52 at Kargath), 2801 > 2681 (18 demons of level 53-57), 1446
--   (Jammal'an, turned in at the Atal'ai Exile before the temple), 4133 (reqLevel 50).
-- Carried out: 81 (Orgrimmar), 2641 (complete, Gadgetzan), 2782 + 2995 (complete, Undercity), the book items for 81953
--   / 81954 / 81955 / 81947 / 81956 (looted from the book containers; Owen Thadd offers and takes the quests in the
--   Undercity of h-53 - see the h-46 header), 3504 + 3568 (Azshara), 4300 (Un'Goro), 4808 (Everlook); 3520
--   untouched.
-- Automation notes: transient steps (fp, sethearth, hearth, go) come before the quest steps of their hub; accepts at
--   one NPC are merged into one step - a sethearth at an innkeeper who also gives a quest shares the step with that
--   accept (h50-revantusk-hearth: Lard binds and gives 7840; a separate accept right after it would fast-forward the
--   bind when the gossip auto-accept takes 7840 first); the paladin's training insert after h-50-uc-arrive (Oran) is followed by a
--   step at another NPC (the level there is ~49.5 since the 46-60 densify pass: docs/routes/horde-22-60.md section 10
--   suggests merging pal-train-50 into the 52 set). Shared-item quests (Bloodmages) finish with collect totals; bg
--   goals get a later non-bg finishing step.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-50-hinterlands-searing-steppes",
    title = { ru = "50-53 Внутренние земли, Тлеющее ущелье, Пылающие степи, Выжженные земли",
              en = "50-53 Hinterlands, Searing Gorge, Burning Steppes, Blasted Lands" },
    zone = "The Hinterlands",
    levels = { 50, 53 },
    steps = {
        ------------------------------------------------------------------
        -- Orgrimmar (level 50)
        ------------------------------------------------------------------
        { id = "h50-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Летите из Лагеря Мохаче в Оргриммар.", en = "Fly from Camp Mojache to Orgrimmar." } },
        { id = "h-50-org-arrive", turnin = 3002, npc = 7311, at = { 1454, 39.16, 86.27 },
          note = { ru = "Аллея Духов, Утель'най: «Сфера Гордунни».",
                   en = "Valley of Spirits, Uthel'nay: The Gordunni Orb." } },
        { turnin = 3121, npc = 3216, at = { 1454, 49.47, 50.59 },
          note = { ru = "Расселина Теней, Нииру Огненный Клинок: голова от Узер'и. «Возвращение к знахарю Узер'и» не "
                       .. "берите.",
                   en = "Cleft of Shadow, Neeru Fireblade: the head from Uzer'i. Skip Return to Witch Doctor Uzer'i." } },
        { turnin = { 32, 7732 }, npc = 7010, at = { 1454, 56.26, 46.68 },
          note = { ru = "Зилзибин Барабанный Бой: сдайте «Восхождение силитидов» и «Донесение об улье Цуккаш». "
                       .. "«Нашествие силитидов» (50+) он даст при следующем визите в Оргриммар.",
                   en = "Zilzibin Drumlore: turn in Rise of the Silithid and Zukk'ash Report. March of the Silithid "
                       .. "(50+) is taken on the next Orgrimmar visit." } },
        { accept = 4300, npc = 8659, at = { 1454, 55.52, 34.08 },
          note = { ru = "Джес'римон: «Костяные клинки» (когти равазавров в Ун'Горо, следующий сегмент).",
                   en = "Jes'rimon: Bone-Bladed Weapons (ravasaur claws in Un'Goro, next segment)." } },
        { accept = 649, npc = 6986, at = { 1454, 59.49, 36.57 },
          note = { ru = "Дран Дрофферс: «За медовухой».", en = "Dran Droffers: Ripple Recovery." } },
        { turnin = 649, accept = 650, npc = 6987, at = { 1454, 59.65, 36.94 },
          note = { ru = "Мальтон Дрофферс рядом: вторая часть — к Гилверадину во Внутренние земли.",
                   en = "Malton Droffers next to him: part 2 goes to Gilveradin in the Hinterlands." } },
        { turnin = 2976, accept = 3504, npc = 4485, at = { 1454, 75.23, 34.24 },
          note = { ru = "Аллея Чести, Белгром Каменная Булава: «Зловещее открытие», возьмите «Предательница» "
                       .. "(Азшара, следующий сегмент).",
                   en = "Valley of Honor, Belgrom Rockmaul: A Grim Discovery; take Betrayed (Azshara, next "
                       .. "segment)." } },
        { id = "h50-zeppelin-uc", go = true, radius = 15, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Через главные ворота к башне дирижаблей (Фрезза): дирижабль в Тирисфальские леса.",
                   en = "Out through the main gate to the zeppelin tower (Frezza): zeppelin to Tirisfal Glades." } },

        ------------------------------------------------------------------
        -- Undercity -> Tarren Mill (level 50)
        ------------------------------------------------------------------
        { go = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Прибытие к башне в Тирисфальских лесах (Запота), дальше в Подгород.",
                   en = "Arrival at the Tirisfal Glades tower (Zapetta), then into Undercity." } },
        { id = "h-50-uc-arrive", accept = 2995, npc = 7825, at = { 1458, 73.06, 32.85 },
          note = { ru = "Квартал Магов, Оран Змеиные Кольца: «Линии связи» (бумаги Высокодолья во Внутренних землях).",
                   en = "Magic Quarter, Oran Snakewrithe: Lines of Communication (Highvale papers in the "
                       .. "Hinterlands)." } },
        { accept = 81949, complete = 81949, turnin = 81949, npc = 211022, at = { 1458, 73.40, 33.00 },
          note = { ru = "Рядом, Оуэн Тэдд: книга «Легенды о волнопевах» из Танариса - возьмите задание (книга в сумках) "
                       .. "и сразу сдайте.",
                   en = "Next to him, Owen Thadd: the book Legends of the Tidesages from Tanaris - take the quest (the "
                       .. "book is in your bags) and turn it in at once." } },
        { turnin = 864, npc = 5204, at = { 1458, 50.14, 67.97 },
          note = { ru = "Чумной квартал, аптекарь Зинг: «Возвращение к аптекарю Зинг».",
                   en = "Apothecarium, Apothecary Zinge: Return to Apothecary Zinge." } },
        { accept = 3568, npc = 8390, at = { 1458, 48.71, 71.39 },
          note = { ru = "Химик Карабос: «Разносчик порчи» (приливные пруды Азшары, следующий сегмент).",
                   en = "Chemist Cuely: Seeping Corruption (Azshara tide pools, next segment)." } },
        { id = "h50-fly-tarrenmill", fly = "Tarren Mill", npc = 2389, at = { 1424, 60.14, 18.62 },
          note = { ru = "Летите на Мельницу Таррен (Майкл Гарретт в центре города).",
                   en = "Fly to Tarren Mill (Michael Garrett in the city centre)." } },

        ------------------------------------------------------------------
        -- Into the Hinterlands: Quel'Danil Lodge, Skulk Rock (level 50)
        ------------------------------------------------------------------
        { id = "h50-hinterlands-pass", go = true, radius = 60, at = { 1424, 86.00, 32.00 },
          note = { ru = "На восток и северо-восток по дороге к перевалу во Внутренние земли.",
                   en = "East and north-east along the road to the pass into the Hinterlands." } },
        { id = "h-50-gilveradin-sunchaser", turnin = 650, accept = 77, npc = 7801, at = { 1425, 26.71, 48.59 },
          note = { ru = "Мимо Заоблачного пика (Альянс, держитесь южнее) к Гилверадину Ловчему Солнца у Сторожки "
                       .. "Кель'Данил: «За медовухой», возьмите «Грязное дело».",
                   en = "Past Aerie Peak (Alliance, keep south of it) to Gilveradin Sunchaser by Quel'Danil Lodge: "
                       .. "Ripple Recovery; take A Sticky Situation." } },
        { complete = 2995, at = { 1425, 30.06, 47.18 },
          note = { ru = "Сторожка Кель'Данил: сожгите записи (32.0,46.8), заметки (29.6,48.7) и отчёт (28.6,46.1). "
                       .. "Эльфы Высокодолья 43-47.",
                   en = "Quel'Danil Lodge: burn the Records (32.0,46.8), Notes (29.6,48.7) and Report (28.6,46.1). "
                       .. "Highvale elves 43-47." } },
        { id = "h-50-rin-ji", accept = 2742, npc = 7780, at = { 1425, 30.73, 46.90 },
          note = { ru = "Рин'джи в клетке в сторожке: «Рин'джи в ловушке».",
                   en = "Rin'ji in the cage inside the lodge: Rin'ji is Trapped!" } },
        { complete = 2742, at = { 1425, 34.00, 48.50 },
          note = { ru = "Проводите его из сторожки (эльфы нападают по пути). Тайник — на Отвесных скалах на востоке.",
                   en = "Escort him out of the lodge (elves attack on the way). His secret is on the Overlook Cliffs "
                       .. "to the east." } },
        { complete = 77, at = { 1425, 53.51, 40.85 },
          note = { ru = "На восток по дороге к Осклизлой скале: 10 бутылок медовой зыби из ящиков Орды (46.5,39.4 и "
                       .. "58.2,41.8).",
                   en = "East along the road to Skulk Rock: 10 Hinterlands Honey Ripples from the Horde Supply Crates "
                       .. "(46.5,39.4 and 58.2,41.8)." } },

        ------------------------------------------------------------------
        -- Revantusk Village, first visit (level 50)
        ------------------------------------------------------------------
        { id = "h-50-revantusk-arrive", fp = "Revantusk Village", npc = 4314, at = { 1425, 81.70, 81.76 },
          note = { ru = "Дальше на юго-восток к деревне Сломанного Клыка: Горкас — откройте точку полёта.",
                   en = "On south-east to Revantusk Village: Gorkas - learn the flight point." } },
        { id = "h50-revantusk-hearth", sethearth = "Revantusk Village", accept = 7840, npc = 14731,
          at = { 1425, 78.14, 81.38 },
          note = { ru = "Лярд: привяжите камень (вернётесь им с запада зоны) и возьмите «Лярд потерял свой обед».",
                   en = "Lard: bind the hearthstone (you hearth back from the west of the zone) and take Lard Lost His "
                       .. "Lunch." } },
        { accept = { 7845, 7850 }, npc = 14736, at = { 1425, 78.20, 81.18 },
          note = { ru = "Старейшина племени Сломанного Клыка: «Похищен старейшина Сломанный Клык!» и «Темные сосуды».",
                   en = "Primal Torntusk: Kidnapped Elder Torntusk! and Dark Vessels." } },
        { accept = { 7815, 7816 }, npc = 14740, at = { 1425, 80.33, 81.54 },
          note = { ru = "Катум Удильщик на причале: «Хрустогрызы, чувак!» и «Гаммерита!».",
                   en = "Katoom the Angler on the pier: Snapjaws, Mon! and Gammerita, Mon!" } },
        { accept = { 7828, 7829, 7830, 7849 }, npc = 14741, at = { 1425, 79.16, 79.53 },
          note = { ru = "Охотник Мархор: «Охота на бродяг», «Охота на дикарей», «Отмщение за погибших», "
                       .. "«Воссоединение останков».",
                   en = "Huntsman Markhor: Stalking the Stalkers, Hunt the Savages, Avenging the Fallen, Separation "
                       .. "Anxiety." } },
        { accept = { 7861, 7862 }, object = 179913, at = { 1425, 79.08, 78.99 },
          note = { ru = "Объявление «К оружию!»: жрица Ведьмиса и капитан стражи (Джинта'Алор, элитные тролли). "
                       .. "Проверьте счётчики в журнале: показывает 20 каждого (как текст задания и Wowhead) - это ~100 "
                       .. "элит; тогда бросьте 7861/7862, гайд пропустит их шаги.",
                   en = "Call to Arms! board: Vile Priestess Hexx and Guard Captain (Jintha'Alor, elite trolls). Check "
                       .. "the quest log counters: if they show 20 of each (as the quest text and Wowhead), that is "
                       .. "~100 elites - abandon 7861/7862, the guide skips their steps." } },
        { accept = 7841, npc = 14738, at = { 1425, 79.38, 79.08 },
          note = { ru = "Отхо Можи'ко: «Письмо для Громового Молота» (эльфы у Сторожки Кель'Данил).",
                   en = "Otho Moji'ko: Message to the Wildhammer (the elves at Quel'Danil Lodge)." } },
        { accept = 7844, npc = 14739, at = { 1425, 78.80, 78.25 },
          note = { ru = "Мистик Яо'джин: «Собратья-каннибалы».", en = "Mystic Yayo'jin: Cannibalistic Cousins." } },
        { accept = 7839, npc = 14737, at = { 1425, 77.23, 80.13 },
          note = { ru = "Кузнец Углежог: «Хулиганы Порочной Ветви».", en = "Smith Slagtree: Vilebranch Hooligans." } },

        ------------------------------------------------------------------
        -- Loop 1: north coast, Vilebranch camp, the wilds, west (level 50-51)
        ------------------------------------------------------------------
        { complete = 7815, bg = true, at = { 1425, 78.43, 67.15 },
          note = { ru = "Попутно: 10 морских хрустогрызов вдоль всего берега (в тексте задания и на Wowhead — 15; "
                       .. "верен счётчик в журнале).",
                   en = "On the way: 10 Saltwater Snapjaws all along the coast (the quest text and Wowhead say 15; "
                       .. "trust the quest log counter)." } },
        { complete = 7828, bg = true, at = { 1425, 65.64, 52.90 },
          note = { ru = "Попутно: 5 среброгривых бродяг (восток и центр) и 5 ревунов (запад) - в тексте и на Wowhead "
                       .. "по 15, верен счётчик в журнале.",
                   en = "On the way: 5 Silvermane Stalkers (east and centre) and 5 Howlers (west) - the quest text and "
                       .. "Wowhead say 15 each, trust the quest log counter." } },
        { complete = 7816, at = { 1425, 80.40, 58.23 },
          note = { ru = "На север по берегу: черепаха Гаммерита (элита 48) — лучшая наживка Катума.",
                   en = "North along the coast: the turtle Gammerita (elite 48) - Katoom's Best Lure." } },
        { id = "h-50-rin-ji-s", turnin = 2742, accept = 2782, object = 142127, at = { 1425, 86.30, 59.01 },
          note = { ru = "Отвесные скалы: тайник Рин'джи — «Секрет Рин'джи» (табличку несите Оран в Подгород).",
                   en = "Overlook Cliffs: Rin'ji's Secret - take Rin'ji's Secret (the tablet goes to Oran in "
                       .. "Undercity)." } },
        { complete = 7815, at = { 1425, 83.00, 49.80 },
          note = { ru = "Хрустогрызов меньше 10? Их много на северном берегу.",
                   en = "Fewer than 10 snapjaws? Plenty on the northern shore." } },
        { complete = 7840, at = { 1425, 84.47, 41.22 },
          note = { ru = "Островок на севере: корзина Лярда у похитителя из племени Порочной Ветви (49).",
                   en = "The islet to the north: Lard's basket by the Vilebranch Kidnapper (49)." } },
        { complete = { 7839, 7844 }, at = { 1425, 69.26, 46.74 },
          note = { ru = "На запад к лагерям Порочной Ветви у дороги (70,48 и 66,44): 6 охотников за скальпами и 2 "
                       .. "ворожея (в тексте и на Wowhead 30 и 15 - верен счётчик в журнале); инструменты Углежога "
                       .. "лежат там же.",
                   en = "West to the Vilebranch camps by the road (70,48 and 66,44): 6 Scalpers and 2 Soothsayers (the "
                       .. "quest text and Wowhead say 30 and 15 - trust the quest log counter); Slagtree's Lost Tools "
                       .. "lie there too." } },
        { id = "h-50-the-hinterlands-field", complete = { 7829, 7830 }, at = { 1425, 59.15, 49.93 },
          note = { ru = "Центр зоны: 10 диких совухов (в тексте и на Wowhead 20 - верен счётчик в журнале); перо из "
                       .. "остроклювов-повелителей небес (46-48).",
                   en = "Centre of the zone: 10 Savage Owlbeasts (the quest text and Wowhead say 20 - trust the quest "
                       .. "log counter); the Skylord Plume from the Razorbeak Skylords (46-48)." } },
        { complete = 7828, at = { 1425, 44.32, 56.98 },
          note = { ru = "На юго-запад: среброгривые ревуны (45-46).",
                   en = "South-west: Silvermane Howlers (45-46)." } },
        { complete = 2641, at = { 1425, 40.63, 59.66 },
          note = { ru = "Рядом: сорвите фиалковый траган для «Маленького секрета Поливалки» (Танарис).",
                   en = "Nearby: pick a Violet Tragan for Sprinkle's Secret Ingredient (Tanaris)." } },
        { collect = { [220350] = 1 }, object = 441252, at = { 1425, 36.00, 72.80 },
          note = { ru = "На юго-запад, у троллей Сохнущей Коры (36.0,72.8): книга «Ядовитые странствия» — заберите её "
                       .. "(контейнер; задание даст Оуэн Тэдд в Подгороде, когда книга в сумках, следующий сегмент; "
                       .. "новое задание Forever).",
                   en = "South-west, by the Witherbark trolls (36.0,72.8): the book Venomous Journeys - loot it (a "
                       .. "container; Owen Thadd in Undercity offers the quest when the book is in your bags, next "
                       .. "segment; a Forever-new quest)." } },
        { id = "h-50-atal-ai-exile", turnin = 1429, accept = 1444, npc = 5598, at = { 1425, 33.75, 75.21 },
          note = { ru = "На юго-запад, изгнанник племени Атал'ай: возьмите «Возвращение к Фел'зерулу» (Каменор).",
                   en = "South-west, the Atal'ai Exile: take Return to Fel'Zerul (Stonard)." } },
        { complete = 7841, at = { 1425, 31.41, 47.55 },
          note = { ru = "На север к Сторожке Кель'Данил: 8 разведчиков, 5 гонцов, 5 следопытов, 2 стрелка "
                       .. "Высокодолья (в тексте и на Wowhead по 15 - верен счётчик в журнале).",
                   en = "North to Quel'Danil Lodge: 8 Highvale Scouts, 5 Outrunners, 5 Rangers, 2 Marksmen (the quest "
                       .. "text and Wowhead say 15 each - trust the quest log counter)." } },
        { turnin = 77, accept = 81, npc = 7801, at = { 1425, 26.71, 48.59 },
          note = { ru = "Гилверадин: «Грязное дело», возьмите «Груз медовухи» (Оргриммар, следующий сегмент).",
                   en = "Gilveradin: A Sticky Situation; take Ripple Delivery (Orgrimmar, next segment)." } },
        { id = "h50-hearth-revantusk", hearth = "Revantusk Village", at = { 1425, 78.14, 81.38 },
          note = { ru = "Камень возвращения в деревню Сломанного Клыка.", en = "Hearth to Revantusk Village." } },

        ------------------------------------------------------------------
        -- Revantusk Village, second visit (level 51)
        ------------------------------------------------------------------
        { turnin = 7840, npc = 14731, at = { 1425, 78.14, 81.38 },
          note = { ru = "Лярд.", en = "Lard." } },
        { turnin = { 7815, 7816 }, npc = 14740, at = { 1425, 80.33, 81.54 },
          note = { ru = "Катум.", en = "Katoom." } },
        { turnin = { 7828, 7829, 7830 }, npc = 14741, at = { 1425, 79.16, 79.53 },
          note = { ru = "Мархор.", en = "Markhor." } },
        { turnin = 7841, accept = 7842, npc = 14738, at = { 1425, 79.38, 79.08 },
          note = { ru = "Отхо: «Еще одно письмо для Громового Молота» (10 длинных перьев грифонов).",
                   en = "Otho: Another Message to the Wildhammer (10 Long Elegant Feathers)." } },
        { turnin = 7844, npc = 14739, at = { 1425, 78.80, 78.25 },
          note = { ru = "Яо'джин.", en = "Yayo'jin." } },
        { turnin = 7839, npc = 14737, at = { 1425, 77.23, 80.13 },
          note = { ru = "Углежог.", en = "Slagtree." } },

        ------------------------------------------------------------------
        -- Loop 2: gryphons, Jintha'Alor (level 51)
        ------------------------------------------------------------------
        { complete = 7842, at = { 1425, 61.68, 49.36 },
          note = { ru = "На северо-запад к остроклювам-повелителям небес (46-48): 10 длинных перьев.",
                   en = "North-west to the Razorbeak Skylords (46-48): 10 Long Elegant Feathers." } },
        { complete = { [7849] = { 1 } }, at = { 1425, 58.56, 64.76 },
          note = { ru = "На юг к Джинта'Алору: груда черепов (58.6,64.8) — череп Малькора.",
                   en = "South to Jintha'Alor: the Pile of Skulls (58.6,64.8) - Malkhor's skull." } },
        { complete = 7850, bg = true, at = { 1425, 63.53, 71.70 },
          note = { ru = "Попутно: 5 сосудов с порченой кровью на ярусах Джинта'Алора (в тексте и на Wowhead 10 - "
                       .. "верен счётчик в журнале).",
                   en = "On the way: 5 Vessels of Tainted Blood on the tiers of Jintha'Alor (the quest text and Wowhead "
                       .. "say 10 - trust the quest log counter)." } },
        { complete = 7862, bg = true, at = { 1425, 63.48, 72.34 },
          note = { ru = "Попутно (элита 47-50, по одному): 5 берсерков, 3 тёмных охотника, 3 кровопийцы, 2 пожирателя "
                       .. "душ (в тексте и на Wowhead по 20 - верен счётчик в журнале; 20 - бросьте 7862).",
                   en = "On the way (elites 47-50, one at a time): 5 Berserkers, 3 Shadow Hunters, 3 Blood Drinkers, "
                       .. "2 Soul Eaters (the quest text and Wowhead say 20 each - trust the quest log counter; 20: "
                       .. "abandon 7862)." } },
        { complete = { [7849] = { 2 } }, at = { 1425, 62.11, 75.35 },
          note = { ru = "Груда костей в волчьем логове (62.1,75.4) — кости Малькора.",
                   en = "The Pile of Bones in the wolf den (62.1,75.4) - Malkhor's bones." } },
        { complete = 7861, at = { 1425, 58.50, 80.50 },
          note = { ru = "Вершина: 5 стражей Аман'заси (элита 50-51; в тексте и на Wowhead 20 - верен счётчик в журнале, "
                       .. "20 - бросьте 7861) и жрица Ведьмиса (элита 51, 59.5,78.3).",
                   en = "The top: 5 Aman'zasi Guards (elite 50-51; the quest text and Wowhead say 20 - trust the quest "
                       .. "log counter, 20: abandon 7861) and Vile Priestess Hexx (elite 51, 59.5,78.3)." } },
        { id = "h-50-elder-torntusk", turnin = 7845, accept = 7846, npc = 14757, at = { 1425, 59.69, 77.84 },
          note = { ru = "Старейшина Сломанный Клык в клетке: «Отыщите ключ!».",
                   en = "Elder Torntusk in the cage: Recover the Key!" } },
        { complete = 7846, at = { 1425, 57.32, 86.64 },
          note = { ru = "Хита'йа Хранительница (элита 51) на юге города — ключ от оков.",
                   en = "Hitah'ya the Keeper (elite 51) in the south of the city - the Shackle Key." } },
        { turnin = 7846, accept = 7847, npc = 14757, at = { 1425, 59.69, 77.84 },
          note = { ru = "Обратно к старейшине.", en = "Back to the Elder." } },
        { complete = { 7850, 7862 }, at = { 1425, 63.50, 72.00 },
          note = { ru = "Не хватает сосудов или элитных троллей? Нижние ярусы на востоке города.",
                   en = "Vessels or elite trolls missing? The lower tiers on the east side of the city." } },

        ------------------------------------------------------------------
        -- Revantusk Village, last visit -> Kargath (level 51)
        ------------------------------------------------------------------
        { turnin = 7842, npc = 14738, at = { 1425, 79.38, 79.08 },
          note = { ru = "Отхо.", en = "Otho." } },
        { turnin = 7849, npc = 14741, at = { 1425, 79.16, 79.53 },
          note = { ru = "Мархор.", en = "Markhor." } },
        { id = "h-51-revantusk-end", turnin = { 7847, 7850, 7861, 7862 }, npc = 14736, at = { 1425, 78.20, 81.18 },
          note = { ru = "Старейшина племени Сломанного Клыка: четыре задания.",
                   en = "Primal Torntusk: four quests." } },
        { id = "h51-fly-kargath", fly = "Kargath", npc = 2861, at = { 1418, 3.99, 44.78 },
          note = { ru = "Горкас: летите в Каргат (Бесплодные земли).",
                   en = "Gorkas: fly to Kargath (Badlands)." } },
        { id = "h51-kargath-hearth", sethearth = "Kargath", npc = 9356, at = { 1418, 2.82, 45.86 },
          note = { ru = "Хозяин таверны Шул'кар: привяжите камень (вернётесь им из Пылающих степей).",
                   en = "Innkeeper Shul'kar: bind the hearthstone (you hearth back from the Burning Steppes)." } },
        { id = "h-51-kargath", accept = 3821, npc = 9082, at = { 1418, 3.36, 48.06 },
          note = { ru = "Тал'трак Гордый Клык: «Скала Молота Ужаса».", en = "Thal'trak Proudtusk: Dreadmaul Rock." } },
        -- Optional group content: Blackrock Depths (52-60), on the way through Blackrock Mountain; turned in after the
        -- hearth back to Kargath.
        { accept = 4134, npc = 9078, optional = true, at = { 1418, 2.90, 47.76 },
          note = { ru = "По желанию, если собрали группу в Глубины Черной горы: Вивиан — «Утерянный рецепт Громоваров».",
                   en = "Optional, if you have a group for Blackrock Depths: Vivian - Lost Thunderbrew Recipe." } },
        { accept = 3906, npc = 9084, optional = true, at = { 1418, 3.33, 48.26 },
          note = { ru = "По желанию (с группой): Громосерд — «Разлад пламени» (Повелитель Пирон у входа в Глубины).",
                   en = "Optional (with a group): Thunderheart - Disharmony of Flame (Overmaster Pyron by the Depths "
                       .. "entrance)." } },
        { accept = 4081, object = 164867, optional = true, at = { 1418, 3.74, 47.43 },
          note = { ru = "По желанию (с группой): плакат «Разыскивается» — «Убивать на месте: дворфы Черного Железа».",
                   en = "Optional (with a group): the WANTED poster - KILL ON SIGHT: Dark Iron Dwarves." } },

        ------------------------------------------------------------------
        -- Searing Gorge (level 51)
        ------------------------------------------------------------------
        { id = "h-50-wooden-outhouse", go = true, radius = 40, at = { 1427, 65.59, 62.17 },
          note = { ru = "На запад по каньону в Тлеющее ущелье: выход у деревянного нужника.",
                   en = "West through the canyon into the Searing Gorge: it comes out by the Wooden Outhouse "
                       .. "(Grimesilt Dig Site)." } },
        { id = "h-51-thoriumpoint-arrive", fp = "Thorium Point", npc = 3305, at = { 1427, 34.84, 30.87 },
          note = { ru = "На северо-запад вдоль края Котла к лагерю Братства Тория: Гриха — откройте точку полёта.",
                   en = "North-west along the rim of the Cauldron to Thorium Point: Grisha - learn the flight "
                       .. "point." } },
        { accept = { 7701, 7728, 7729 }, object = 179827, at = { 1427, 37.65, 26.47 },
          note = { ru = "Доска «Розыск/Пропал без вести/Найден»: Мальториус, украденные фурма и труба, устранитель "
                       .. "конкурентов.",
                   en = "Wanted/Missing/Lost & Found board: Overseer Maltorius, the stolen Tuyere and Spyglass, "
                       .. "Culling the Competition." } },
        { accept = 7722, npc = 14624, at = { 1427, 38.80, 28.51 },
          note = { ru = "Мастер-кузнец Гориврат: «Какой еще плавень?».", en = "Master Smith Burninate: What the Flux?" } },
        { accept = { 7723, 7724, 7727 }, npc = 14627, at = { 1427, 38.58, 27.81 },
          note = { ru = "Хансел Большерук: големы, лавовые пауки, пламезавры (по 20).",
                   en = "Hansel Heavyhands: golems, lava spiders, incendosaurs (20 each)." } },
        { id = "h-50-kalaran-windblade", accept = 3441, complete = 3441, turnin = 3441, npc = 8479,
          at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан Ветрорез на северном краю Котла: «Божественное воздаяние» — выслушайте его рассказ.",
                   en = "Kalaran Windblade on the north rim of the Cauldron: Divine Retribution - listen to his "
                       .. "story." } },
        { accept = 3442, npc = 8479, at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан: «Неугасимое пламя» (4 сердца пламени, 4 масла големов).",
                   en = "Kalaran: The Flawless Flame (4 Hearts of Flame, 4 Golem Oils)." } },
        { complete = 7729, bg = true, at = { 1427, 43.10, 32.67 },
          note = { ru = "Попутно по всему Котлу: 15 надсмотрщиков и 15 поработителей Черного Железа.",
                   en = "On the way, all over the Cauldron: 15 Dark Iron Taskmasters and 15 Slavers." } },
        { complete = { 7723, 3442 }, bg = true, at = { 1427, 41.70, 48.31 },
          note = { ru = "Попутно: 20 тяжелых боевых големов (масло), элементали магмы (сердца и масло).",
                   en = "On the way: 20 Heavy War Golems (oil), Magma Elementals (hearts and oil)." } },
        { complete = 7727, at = { 1427, 48.43, 28.01 },
          note = { ru = "Шлаковая Яма (вход у Каларана): 20 пламезавров (47-49) в лавовых озёрах на востоке ямы.",
                   en = "The Slag Pit (entrance by Kalaran): 20 Incendosaurs (47-49) in the lava pools of its east "
                       .. "part." } },
        { complete = { 7701, 7722 }, at = { 1427, 40.60, 35.80 },
          note = { ru = "Глубже в Шлаковой Яме: надзиратель Мальториус (элита 50) — голова; секретные планы лежат "
                       .. "рядом.",
                   en = "Deeper in the Slag Pit: Overseer Maltorius (elite 50) - his head; the Secret Plans lie next "
                       .. "to him." } },
        { complete = 7728, at = { 1427, 41.66, 55.82 },
          note = { ru = "Дно Котла: фурма с кузнецов Черного Железа (40,50), труба с наблюдателей (34,55 и 52,58).",
                   en = "Floor of the Cauldron: the Tuyere from the Dark Iron Steamsmiths (40,50), the Spyglass from "
                       .. "the Lookouts (34,55 and 52,58)." } },
        { complete = 7724, at = { 1427, 28.06, 59.49 },
          note = { ru = "На запад: 20 опаляющих лавовых пауков (47-49).",
                   en = "West: 20 Greater Lava Spiders (47-49)." } },
        { collect = { [220352] = 1 }, object = 441253, at = { 1427, 37.80, 49.30 },
          note = { ru = "Дно Котла (37.8,49.3): книга «Разум из металла» — заберите её (контейнер; задание - у Оуэна "
                       .. "Тэдда в Подгороде).",
                   en = "Floor of the Cauldron (37.8,49.3): the book A Mind of Metal - loot it (a container; the quest is "
                       .. "Owen Thadd's, Undercity)." } },
        { id = "h-50-searing-gorge-field", complete = { 7723, 3442 }, at = { 1427, 40.83, 49.21 },
          note = { ru = "Не хватает големов, сердец или масла? Центр Котла.",
                   en = "Golems, hearts or oil missing? The centre of the Cauldron." } },
        { turnin = 3442, accept = 3443, npc = 8479, at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан: «Древко факела» (8 кинжалов с ториевой обкладкой с дворфов).",
                   en = "Kalaran: Forging the Shaft (8 Thorium Plated Daggers from the dwarves)." } },
        { complete = { 3443, 7729 }, at = { 1427, 43.10, 32.67 },
          note = { ru = "Северная часть Котла: дворфы Черного Железа — кинжалы и остаток надсмотрщиков/поработителей.",
                   en = "North part of the Cauldron: Dark Iron dwarves - the daggers and the rest of the "
                       .. "Taskmasters / Slavers." } },
        { turnin = 3443, accept = 3452, npc = 8479, at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан: «Защита пламени» (символ Рагнароса).",
                   en = "Kalaran: The Flame's Casing (Symbol of Ragnaros)." } },
        { complete = 3452, at = { 1427, 27.42, 25.90 },
          note = { ru = "Культисты Сумеречного Молота к западу от лагеря Братства Тория (элита 48-51, по одному): символ "
                       .. "Рагнароса.",
                   en = "Twilight's Hammer cultists west of Thorium Point (elites 48-51, one at a time): the Symbol "
                       .. "of Ragnaros." } },
        { turnin = 7701, npc = 14634, at = { 1427, 37.74, 26.56 },
          note = { ru = "Лагерь Братства Тория: капитан дозорных Лоло Долгобой.",
                   en = "Thorium Point: Lookout Captain Lolo Longstriker." } },
        { turnin = { 7728, 7729 }, npc = 14626, at = { 1427, 38.97, 27.51 },
          note = { ru = "Надсмотрщик Скрендж.", en = "Taskmaster Scrange." } },
        { turnin = 7722, npc = 14624, at = { 1427, 38.80, 28.51 },
          note = { ru = "Гориврат.", en = "Burninate." } },
        { id = "h-52-thoriumpoint-end", turnin = { 7723, 7724, 7727 }, npc = 14627, at = { 1427, 38.58, 27.81 },
          note = { ru = "Хансел.", en = "Hansel." } },
        { turnin = { 3452, 3453 }, accept = 3453, complete = 3453, npc = 8479, at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан: сдайте символ и дождитесь, пока он закончит факел («Факел воздаяния»).",
                   en = "Kalaran: hand over the Symbol and wait while he finishes the torch (The Torch of "
                       .. "Retribution)." } },
        { accept = 3454, npc = 8479, at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан: второй «Факел воздаяния».", en = "Kalaran: The Torch of Retribution, part 2." } },
        { turnin = 3454, object = 149047, at = { 1427, 39.06, 39.07 },
          note = { ru = "Возьмите факел воздаяния рядом с ним.", en = "Take the Torch of Retribution next to him." } },
        { accept = 3462, npc = 8479, at = { 1427, 39.06, 38.99 },
          note = { ru = "Каларан: «Оруженосец Малтрейк».", en = "Kalaran: Squire Maltrake." } },
        { turnin = 3462, accept = 3463, npc = 8509, at = { 1427, 39.17, 39.00 },
          note = { ru = "Оруженосец Малтрейк рядом: «Задай им жару!».",
                   en = "Squire Maltrake next to him: Set Them Ablaze!" } },
        { complete = 3463, use = 10515, at = { 1427, 40.77, 57.70 },
          note = { ru = "Факелом подожгите 4 сторожевые башни вокруг Котла: 33.3,54.5; 35.7,60.7; 44.0,60.9; "
                       .. "50.1,54.7.",
                   en = "Use the torch on the 4 sentry towers around the Cauldron: 33.3,54.5; 35.7,60.7; 44.0,60.9; "
                       .. "50.1,54.7." } },
        { turnin = 3463, npc = 8509, at = { 1427, 39.17, 39.00 },
          note = { ru = "Малтрейк.", en = "Maltrake." } },
        { accept = 3481, turnin = 3481, object = 149502, at = { 1427, 38.85, 38.99 },
          note = { ru = "Сокровищница черных драконов рядом: «Безделушки...» (откройте сундук).",
                   en = "The Hoard of the Black Dragonflight next to them: Trinkets... (open the chest)." } },

        ------------------------------------------------------------------
        -- Blackrock Mountain -> Burning Steppes (level 52)
        ------------------------------------------------------------------
        { id = "h-50-nilith-lokrav", go = true, radius = 40, at = { 1427, 40.99, 74.95 },
          note = { ru = "На юг к Черной горе (мимо гоблина Нилиты Локрав).",
                   en = "South towards Blackrock Mountain (past the goblin Nilith Lokrav)." } },
        { collect = { [220349] = 1 }, object = 441251, at = { 1428, 28.96, 28.93 },
          note = { ru = "В Черной горе, у призрака Франклорна Кузнечного Горна: книга «Каменное зодчество» — заберите её "
                       .. "(контейнер; задание - у Оуэна Тэдда в Подгороде).",
                   en = "Inside Blackrock Mountain, by Franclorn Forgewright's ghost: the book Stonewrought Design - loot "
                       .. "it (a container; the quest is Owen Thadd's, Undercity)." } },
        { complete = { 3906, 4081, 4134 }, optional = true, at = { 1427, 34.80, 85.30 },
          note = { ru = "По желанию, если собрали группу: Глубины Черной горы — Повелитель Пирон (элита 52) в карьере у "
                       .. "входа; внутри 15 стражников, 10 надзирателей и 5 пехотинцев Ярости Наковальни; рецепт — с Херли "
                       .. "Черного Дыхания (Мрачный Трактир).",
                   en = "Optional, if you have a group: Blackrock Depths - Overmaster Pyron (elite 52) in the quarry by "
                       .. "the entrance; inside 15 Anvilrage Guardsmen, 10 Wardens and 5 Footmen; the recipe drops from "
                       .. "Hurley Blackbreath (Grim Guzzler)." } },
        { id = "h52-burning-steppes-road", go = true, radius = 60, at = { 1428, 47.00, 24.00 },
          note = { ru = "Через Черную гору (по цепям) в Пылающие степи; на восток вдоль северного края — южнее "
                       .. "крепость Черной горы (орки 55-58).",
                   en = "Through Blackrock Mountain (over the chains) into the Burning Steppes; east along the "
                       .. "northern edge - Blackrock Stronghold (orcs 55-58) is to the south." } },
        { id = "h-52-flamecrest-arrive", fp = "Flame Crest", npc = 13177, at = { 1428, 65.69, 24.22 },
          note = { ru = "Пламенеющий Стяг: Вагрук — откройте точку полёта.",
                   en = "Flame Crest: Vahgruk - learn the flight point." } },
        { accept = 4296, npc = 9536, at = { 1428, 65.15, 23.91 },
          note = { ru = "Максворт Суперблеск: «Табличка Семерых».", en = "Maxwort Uberglint: Tablet of the Seven." } },
        { accept = 4726, npc = 10267, at = { 1428, 65.24, 24.00 },
          note = { ru = "Тинки Кипеллер: «Сущность детеныша дракона» (Драко-инкарцинатор 900).",
                   en = "Tinkee Steamboil: Broodling Essence (Draco-Incarcinatrix 900)." } },
        { complete = 4296, at = { 1428, 54.12, 40.76 },
          note = { ru = "На юго-запад: перепишите табличку Семерых (54.1,40.8). Вокруг разорители и агенты 53-55.",
                   en = "South-west: copy the Tablet of the Seven (54.1,40.8). War Reavers and agents 53-55 around." } },
        { id = "h-51-sha-ni-proudtusk", turnin = 3821, accept = 3822, npc = 9136, at = { 1428, 79.95, 45.40 },
          note = { ru = "На восток к скале Молота Ужаса: Ша'ни Гордый Клык в клетке наверху — «Кром'Грул». Огры "
                       .. "Огненного Чрева 50-53.",
                   en = "East to Dreadmaul Rock: Sha'ni Proudtusk in the cage at the top - Krom'Grul. Firegut ogres "
                       .. "50-53." } },
        { complete = 3822, at = { 1428, 79.66, 47.43 },
          note = { ru = "Кром'Грул (54) бродит по пещерам скалы — кольцо Ша'ни.",
                   en = "Krom'Grul (54) walks through the caves of the rock - Sha'ni's Nose-Ring." } },
        { id = "h-51-burning-steppes-field", complete = 4726, use = 12284, at = { 1428, 88.19, 36.55 },
          note = { ru = "На восток к детёнышам черного дракона (51-52): выстрелите в детёныша из Драко-инкарцинатора "
                       .. "900 и поднимите сущность — 8 раз.",
                   en = "East to the Black Broodlings (51-52): fire the Draco-Incarcinatrix 900 at a broodling and "
                       .. "loot the essence - 8 times." } },
        { turnin = 4296, npc = 9536, at = { 1428, 65.15, 23.91 },
          note = { ru = "Обратно в Пламенеющий Стяг, Максворт.", en = "Back to Flame Crest, Maxwort." } },
        { turnin = 4726, accept = 4808, npc = 10267, at = { 1428, 65.24, 24.00 },
          note = { ru = "Тинки: «Фелнок Сталлист» (Круговзор, Зимние Ключи — позже).",
                   en = "Tinkee: Felnok Steelspring (Everlook, Winterspring - later)." } },
        { id = "h52-hearth-kargath", hearth = "Kargath", at = { 1418, 2.82, 45.86 },
          note = { ru = "Камень возвращения в Каргат.", en = "Hearth to Kargath." } },
        { id = "h-51-kargath-2", turnin = 3822, npc = 9082, at = { 1418, 3.36, 48.06 },
          note = { ru = "Тал'трак.", en = "Thal'trak." } },
        { turnin = 4134, npc = 9078, optional = true, at = { 1418, 2.90, 47.76 },
          note = { ru = "По желанию (после Глубин): Вивиан — рецепт.", en = "Optional (after the Depths): Vivian - the recipe." } },
        { turnin = 3906, npc = 9084, optional = true, at = { 1418, 3.33, 48.26 },
          note = { ru = "По желанию: Громосерд — Пирон.", en = "Optional: Thunderheart - Pyron." } },
        { turnin = 4081, npc = 9077, optional = true, at = { 1418, 5.81, 47.52 },
          note = { ru = "По желанию: военачальник Гнилозуб — дворфы Черного Железа.",
                   en = "Optional: Warlord Goretooth - the Dark Iron dwarves." } },
        { id = "h52-fly-stonard", fly = "Stonard", npc = 6026, at = { 1435, 46.07, 54.83 },
          note = { ru = "Горрик: летите в Каменор (Болото Печали).", en = "Gorrik: fly to Stonard (Swamp of Sorrows)." } },

        ------------------------------------------------------------------
        -- Swamp of Sorrows: the Fallen Hero (level 52)
        ------------------------------------------------------------------
        { id = "h-51-swamp-of-sorrows", accept = 2784, complete = 2784, turnin = 2784, npc = 7572,
          at = { 1435, 34.29, 66.14 },
          note = { ru = "На запад к развилке на Выжженные земли: павший герой Орды — «Попавший в немилость», "
                       .. "выслушайте его историю.",
                   en = "West to the fork towards the Blasted Lands: the Fallen Hero of the Horde - Fall From Grace, "
                       .. "listen to his story." } },
        { accept = 2621, npc = 7572, at = { 1435, 34.29, 66.14 },
          note = { ru = "Павший герой: «Опозоренный» (в Каменор).", en = "Fallen Hero: The Disgraced One (to Stonard)." } },
        { id = "h-51-stonard", turnin = 2621, accept = 2622, npc = 7623, at = { 1435, 47.79, 54.94 },
          note = { ru = "Каменор, командир разведотряда Руаг: «Пропавшие приказы».",
                   en = "Stonard, Dispatch Commander Ruag: The Missing Orders." } },
        { turnin = 1444, npc = 1443, at = { 1435, 47.93, 54.78 },
          note = { ru = "Фел'зерул рядом: «Возвращение к Фел'зерулу».",
                   en = "Fel'Zerul next to him: Return to Fel'Zerul." } },
        { accept = 1445, npc = 1443, optional = true, at = { 1435, 47.93, 54.78 },
          note = { ru = "По желанию, если собрали группу в Затонувший храм: Фел'зерул — «Храм Атал'Хаккара».",
                   en = "Optional, if you have a group for the Sunken Temple: Fel'Zerul - The Temple of Atal'Hakkar." } },
        { turnin = 2622, accept = 2623, npc = 7643, at = { 1435, 44.97, 57.37 },
          note = { ru = "Бенгор: «Болотный говорун».", en = "Bengor: The Swamp Talker." } },
        { collect = { [220345] = 1 }, object = 441247, at = { 1435, 70.00, 51.00 },
          note = { ru = "На восток к Озеру Слез (70.0,51.0): книга «Кровавое чародейство» — заберите её (контейнер; "
                       .. "задание - у Оуэна Тэдда в Подгороде).",
                   en = "East to the Pool of Tears (70.0,51.0): the book Sanguine Sorcery - loot it (a container; the "
                       .. "quest is Owen Thadd's, Undercity)." } },
        { complete = 1445, optional = true, at = { 1435, 69.90, 53.50 },
          note = { ru = "По желанию (с группой): Затонувший храм (вход в озере рядом) — 20 фетишей Хаккара с троллей.",
                   en = "Optional (with a group): the Sunken Temple (entrance in the pool next to it) - 20 Fetishes of "
                       .. "Hakkar from the trolls." } },
        { id = "h-51-swamp-of-sorrows-2", complete = 2623, at = { 1435, 63.97, 83.66 },
          note = { ru = "На юго-восток: болотные говоруны (50) — приказы военного вождя.",
                   en = "South-east: Swamp Talkers (50) - the Warchief's Orders." } },
        { id = "h-51-swamp-of-sorrows-3", turnin = 2623, npc = 7572, at = { 1435, 34.29, 66.14 },
          note = { ru = "Обратно к павшему герою. Дальнейшую цепочку («Горестная повесть») не берите: 18 демонов 53-57.",
                   en = "Back to the Fallen Hero. Skip the rest of his chain (A Tale of Sorrow): 18 demons of level "
                       .. "53-57." } },

        ------------------------------------------------------------------
        -- Blasted Lands (level 52-53)
        ------------------------------------------------------------------
        { id = "h-52-blastedlands-arrive", accept = { 2581, 2583, 2585 }, npc = 7505, at = { 1419, 50.55, 14.20 },
          note = { ru = "На юг по дороге в Выжженные земли: маг крови Дразиал — три задания.",
                   en = "South along the road into the Blasted Lands: Bloodmage Drazial - three quests." } },
        { accept = { 2601, 2603 }, npc = 7506, at = { 1419, 50.64, 14.30 },
          note = { ru = "Волшебница крови Линора: «Укус василиска» и «Стойкость стервятника».",
                   en = "Bloodmage Lynnore: The Basilisk's Bite and Vulture's Vigor." } },
        { complete = { 2581, 2583, 2585, 2601, 2603 }, bg = true,
          collect = { [8391] = 5, [8392] = 6, [8393] = 6, [8394] = 11, [8396] = 14 }, at = { 1419, 52.00, 33.00 },
          note = { ru = "Попутно (задания делят добычу, нужно всего): 5 челюстей гиен, 6 легких вепря, 6 клешней "
                       .. "скорпоков, 11 мозгов василисков, 14 желудков стервятников.",
                   en = "On the way (the quests share the parts, totals needed): 5 Snickerfang Jowls, 6 Blasted Boar "
                       .. "Lungs, 6 Scorpok Pincers, 11 Basilisk Brains, 14 Vulture Gizzards." } },
        { id = "h-51-kum-isha-the", accept = { 2521, 3501 }, npc = 7363, at = { 1419, 51.98, 35.65 },
          note = { ru = "На юг к Кум'ише Коллекционеру: «Служба для Кум'иша» и «Счет идет на большие числа».",
                   en = "South to Kum'isha the Collector: To Serve Kum'isha and Everything Counts In Large "
                       .. "Amounts." } },
        { collect = { [220353] = 1 }, object = 441254, at = { 1419, 55.40, 32.20 },
          note = { ru = "Чуть северо-восточнее (55.4,32.2): книга «Кодекс заклинателя» — заберите её (контейнер; задание "
                       .. "- у Оуэна Тэдда в Подгороде).",
                   en = "Just north-east (55.4,32.2): the book Conjurer's Codex - loot it (a container; the quest is "
                       .. "Owen Thadd's, Undercity)." } },
        { complete = { 2521, 3501 }, bg = true, at = { 1419, 52.00, 41.47 },
          note = { ru = "Попутно: безупречная сфера дренетиста и несовершенный осколок падают с любых местных "
                       .. "существ.",
                   en = "On the way: the Flawless Draenethyst Sphere and the Imperfect Draenethyst Fragment drop "
                       .. "from any creature here." } },
        { id = "h-51-blasted-lands-field", collect = { [8391] = 5, [8393] = 6 }, at = { 1419, 48.20, 22.00 },
          note = { ru = "Север: голодные хохотуны (челюсти) и скорпоки-острожалы (клешни); стервятники здесь же.",
                   en = "North: Starving Snickerfangs (jowls) and Scorpok Stingers (pincers); vultures here too." } },
        { collect = { [8394] = 11 }, at = { 1419, 59.80, 37.50 },
          note = { ru = "Восток: краснокаменные василиски и хрусталиски — 11 мозгов; пеплогривые вепри и стервятники там же.",
                   en = "East: Redstone Basilisks and Crystalhides - 11 brains; Ashmane Boars and vultures there too." } },
        { id = "h-50-hinterlands-searing-steppes-level-gate", complete = { 2581, 2583, 2585, 2601, 2603 },
          ok = { ["level-grind"] = 160 }, -- end-of-segment gate: 154 kills in the normal run
          collect = { [8391] = 5, [8392] = 6, [8393] = 6, [8394] = 11, [8396] = 14 }, level = { 52, 0.30 },
          at = { 1419, 49.76, 42.23 },
          note = { ru = "Центр: зловепри (52-53, плотно — лучший опыт рядом), стервятники-костегрызы, гиены. "
                       .. "Добейте части и бейте зловепрей до 52-го + 30%: сдачи дадут ~52.6 — Азшара (волхв Римтори 55) "
                       .. "и Ун'Горо идут с 52-го. Нет сферы или осколка Кум'иши — до 52 + 40%.",
                   en = "Centre: Helboars (52-53, dense: the best XP nearby), Bonepickers, hyenas. Finish the parts "
                       .. "and keep killing Helboars up to 52 + 30%: the turn-ins make ~52.6 - Azshara (Magus Rimtori 55) "
                       .. "and Un'Goro are fine from 52. No sphere or fragment for Kum'isha - up to 52 + 40%." } },
        { turnin = { 2521, 3501 }, npc = 7363, at = { 1419, 51.98, 35.65 },
          note = { ru = "Кум'иша. Сферы нет — бросьте 2521 (гайд пропустит шаг).",
                   en = "Kum'isha. No sphere - abandon 2521 (the guide skips the step)." } },
        { turnin = { 2581, 2583, 2585 }, npc = 7505, at = { 1419, 50.55, 14.20 },
          note = { ru = "На север к магам крови: Дразиал.", en = "North to the Bloodmages: Drazial." } },
        { id = "h-53-blastedlands-end", turnin = { 2601, 2603 }, npc = 7506, at = { 1419, 50.64, 14.30 },
          note = { ru = "Линора.", en = "Lynnore." } },
        { turnin = 1445, npc = 1443, optional = true, at = { 1435, 47.93, 54.78 },
          note = { ru = "По желанию (были в Затонувшем храме, 1445 в журнале): на север в Каменор, Фел'зерул — фетиши "
                       .. "Хаккара; затем летите от Брейка в Подгород, камень ниже не нужен. Нет 1445 - «Вперёд».",
                   en = "Optional (you ran the Sunken Temple, 1445 is in the log): north to Stonard, Fel'Zerul - the "
                       .. "Fetishes of Hakkar; then fly from Breyk to Undercity, no hearth below. No 1445: press Forward." } },
        { id = "h-51-stonard-2", hearth = "Kargath", at = { 1418, 2.82, 45.86 },
          note = { ru = "Камень возвращения в Каргат (привязан там же, последний раз использован в Пылающих степях больше "
                       .. "часа назад): оттуда полёт в Подгород короче, чем от Каменора (дальше — следующий сегмент). "
                       .. "Сдавали 1445 в Каменоре - пропустите шаг и летите от Брейка.",
                   en = "Hearth to Kargath (bound there, last used in the Burning Steppes over an hour ago): the flight to "
                       .. "Undercity is shorter from there than from Stonard (next segment from here). Turned in 1445 in "
                       .. "Stonard: skip this step and fly from Breyk." } },
    },
})
