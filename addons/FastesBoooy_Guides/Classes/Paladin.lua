-- FastesBoooy_Guides / Classes / Paladin.lua
--
-- Every step that exists because of the class, as shared inserts with class scope (step ids "pal-..."; below
-- level 12 one group per start zone, "pal-tir-..." for Tirisfal: the Undead are the only paladins of the
-- module). Every insert is anchored to a step with an explicit id of a start-zone or shared segment; the
-- inserted steps belong to the anchor's segment. Plan: research paladin60.md / plan60.json
-- classInserts.PALADIN, moved to the levels the validator reaches.
--
-- Tirisfal 1-12 (Segments/Tirisfal; level before the first step of the insert, validator normal run):
--   Deathknell, Aramis Hammerhand in the church (he teaches up to level 6)
--     after ud01-364        2.6   the letter 98601 (Sarvis) > 90902 (Aramis), training at 1 (the Mindless Ones
--                                 reward pays it), 90902 runs along the first loop
--     after ud01-aramis     4.0   90902 turned in, 91208 + 91209 (both need level 4: the gate ud01-xp-4 gives it
--                                 with the two generic turn-ins of ud01-church-4), training at 4. The anchor is
--                                 the generic accept of 98389 at Aramis himself, not ud01-church-4: a training
--                                 step in front of an accept at the same NPC is fast-forwarded (look-ahead rule)
--     after ud01-boxes            91208 (Frightened Paladin, west of the church)
--     after ud01-98389            91208 turned in (Aramis; the generic 98389 is turned in to him right before)
--   Brill, Shari Stilwell by the stables (outside the inn, between the entrance and the inn)
--     after ud02-dillinger-report  6.5   91209 turned in, training at 6, Wooden Mallet (optional): Shari stands on
--                                 the way from Dillinger to the inn, so the visit comes before ud02-sethearth
--     after ud02-shari-99144  8.3  training at 8 (99144, a quest of every class, is turned in to her first)
--     after ud02-level-10    10.2  91282 "A Second Home", training at 10
--     after ud02-carolai-2   12.6  training at 12 (Carolai stands 35 yd from Shari)
--   Bandarion Keep and Shadowvale: the chain 91282 > 91285 > 91294 > 91316 / 91317 > 95803 runs next to the
--     generic keep quests (96899 > 96896 > 98545, 99152, 99153, 95314), same order as before the split:
--     before ud02-keep (Breton), after ud02-leonid-letter (murlocs, Driftwood Smasher, Hilda), after ud02-hilda
--     (the tour, Danitha, Jorin), after ud02-ephram (the two along-the-way goals), after ud02-elixir-bg (Rudolph
--     Gelhardt's head: behind the generic along-the-way goals, so all four are listed while he is hunted), after
--     ud02-shadowvale (Shadowvale), after ud02-hilda-2 (turn-ins), after ud02-lvl-12 (94427, optional).
--   Undercity, after ud02-fp-uc: Tanis Alderwood 94427 > 94434 (optional: 10 Linen Cloth), Lady Sylvanas 95803
--     (the Royal Quarter walk exists only for it: 460 XP estimated, and the chain ends there).
--   Skipped: the rest of the Lesson in Divinity chain 94435+ (Redemption). It runs Undercity > Bandarion Keep (west
--   edge) > Deathguard Falgan (Tirisfal 86.7, 47.7, east edge) > a Scarlet drop > the keep again: about 2 x 2,900 yd
--   on foot at level 12, ~25 min, for 5 quests of estimated XP and a resurrection spell that does nothing for solo
--   leveling speed. PLAN.md C.4 lists Redemption as a key ability; skipped on the user's rule "only the class quests
--   worth it for leveling speed" (deviation, docs/dev/handover/c-paladin.md). Hilda the Breaker (246389, Paladin
--   Trainer in the DB) stands at the keep: the route talks to her for 91294 at 12.1 but trains in Brill (12.6).
--   XP of the group (all estimated, Forever-new quests): 98601 40, 90902 170, 91208 355, 91209 355, 91282 /
--   91285 / 91294 / 91316 660 each, 91317 / 95803 / 94427 / 94434 460 each, plus the kills of 91285 and 91317:
--   the paladin leaves Tirisfal 0.7 level above the other classes (12.79 against 12.10).
--   Quest rewards of the generic Tirisfal quests: the segments only say "pick the armour your class can wear"; what
--   a paladin takes (mail, the two-hander) is named in the note of the pal-tir step that stands in front of the
--   turn-ins: pal-tir-train-1 (3901 / 376), pal-tir-91208 (3902 / 380, 381, 382), pal-tir-train-8 (426, 398, 358),
--   pal-tir-train-10 (97558, 374). No class reward table (FastesBoooy.AddLibraryData({ rewards = { PALADIN = ... }
--   })): the DB snapshot has no reward lists and the old route named the items without their index in the reward
--   window; a wrong index would make the automation take the wrong item, no index only shows a hint.
--   CONFIRM: the reward indexes of 3901, 376, 3902, 380, 381, 382, 426, 398, 358, 97558, 374 in game, then add the table.
--
-- Training on 12-60 (CONFIRM, docs/dev/PLAN.md E.3: the paladin trainers Garen Largo 260093 in the Undercity and
-- Alodan the Hopeful 246344 in Thunder Bluff are in the DB but not on the web; every step at them carries a CONFIRM
-- comment and its note names Shari Stilwell in Brill as the fallback: the zeppelins of 22.0, 31.1 and 41.0 land
-- ~200 yd south of her, the Undercity entrance is ~400 yd south):
--   14        Garen Largo (Undercity, War Quarter), after h13-uc-end (the gate h13-lvl-14 guarantees the level)
--   18        Alodan the Hopeful (Thunder Bluff, Pools of Vision: Zamah's cave), after h18-tb-zamah (gate
--             h18-lvl-18)
--   20        Alodan, after h18-tb-2 (from Elder Rise over the central mesa to Spirit Rise; gate h18-lvl-20)
--   22        Alodan, after h-22-tb-start (Zamah hands out 1065 right after the turn-in of 1064: a training step
--             between the two would be fast-forwarded by the automation)
--
-- Training (no paladin trainer in Orgrimmar or any questing hub 22-60; Garen Largo in the Undercity War Quarter,
-- Alodan the Hopeful in the Thunder Bluff Pools of Vision, Shari Stilwell in Brill). Visits at the impactful levels
-- only, each at a stop the path makes anyway (level at the stop: validator normal / worst case):
--   26        Alodan, after h-27-tb-arrive (27.58 / 27.12; 27.39 without the optional class chain; Zamah stands in
--             the same cave)
--   28 + 30   Alodan, after h-31-tb-hearth (30.91 / 30.91; 28 alone is not worth the h-28 detour)
--   32 + 34   Garen Largo, after h-34-uc-arrive (34.10 / 34.10)
--   36-40     Shari Stilwell in Brill + riding (Velma Warnam) + horse (Zachariah Post), after h-41-uc-arrive
--             (40.88 / 40.75; Brill is 2 minutes from the zeppelin tower; Orgrimmar at 40.04 has no trainer); then
--             optional Garen Largo in Undercity for the level-40 ranks, only if Shari's list lacks them (whether she
--             sells ranks of 40+ is unproven: research paladin60.md section 1 and open question 2)
--   42 + 44   Garen Largo, after h-44-uc-arrive (44.02 / 44.00)
--   46-52     Garen Largo, after h53-fly-uc (52.57 / 52.54; the Undercity stop at h-50-uc-arrive is at 49.54, short
--             of 50, so the 50 ranks wait for 52)
--   54 + 58   optional, Garen Largo, after h59-hearth-uc (57.95-57.99: 58 only if kills on the way pushed it over)
--   58 + 60   Garen Largo, after h-60-end (hearth to Undercity, bound at h-58-uc-arrive)
-- Skipped: 24 (Hammer of Justice R2 only), 28 at h-28-tb-arrive (Holy Strike R4: merged into 30), the Undercity
--   stops at 31.17 / 49.54 and Thunder Bluff at 24.89 / 28.42 (nothing new or one rank short).
-- Weapons (Wowhead Forever stats; levels: validator normal case): Demolition Hammer (893, 2H mace 17.61 dps +9 Str,
--   25.90) is the weapon until 1427 (44.43). The Servomechanic Sledgehammer of 666 (41.35, 30.23 dps) requires
--   Engineering (100) and the other choice is a wand, so most paladins get nothing there; the Orcish War Sword of 1153
--   (31.05, 2H sword 18.23 dps, no stats) is no upgrade over the Hammer and needs 2H Swords. 1427 offers Tok'kar's
--   Murloc Chopper (2H axe 32.50 dps, speed 3.2, +15 Str +6 Sta), Basher (2H mace 32.32 dps, speed 2.8, +18 Sta) and a
--   dagger; Beastslayer (4301 The Mighty U'cha, 53.87) is a 2H axe (42.58 dps, +36 AP), so is Limb Cleaver (optional
--   Blackrock Depths quest 4134, 51.32, 42.71 dps +21 Str).
-- Weapon skill: Two-Handed Axes at Hanashi (Orgrimmar, Valley of Honor) after h41-hearth-org (40.88 / 40.75; the
--   only Orgrimmar stop between 40 and 1427 that walks through the city anyway, ~3 min on foot), optional but
--   recommended: the Chopper at 44 (better than the Basher with Seal of Command: slower, Strength) and the axe skill has
--   grown by Beastslayer. Trained at 53 instead, the skill would start at 1 with Beastslayer against level-54 mobs.
--   Skipped at 40: take the Basher; the pal-train-52 note points to Hanashi next to Belgrom (h54-hearth-org).
-- Class quests: the Forever-new chain 91858 > 91859 > 91860 > 91861 > 91862 > 96204 > 95034 (part 1, Bandarion Keep,
--   the Sepulcher and Fenris Isle) is optional: XP unknown, ~25 minutes of detours, no reward of its own. It only
--   unlocks part 2 (95036 > 95111 > 95125 > 95126 > 95140, Wolfsbane), which needs the Deadmines (Whitestone Oak
--   Lumber, 1.6% drop), an Enchanted Silver Ingot (reportedly Shadowfang Keep), the Kor Gem from the naga at the
--   Blackfathom Deeps entrance (95042) and the elite Old Fire-Eye: not routed (route doc section 5).
--
-- Automation notes: the trainers, Velma, Zachariah and Hanashi give no route quests, so no training / vendor step
-- here sits before an accept at the same NPC (the automation could otherwise take the quest early and the engine
-- would fast-forward the transient step). Every insert follows a step the player has just done (arrival, hearth or a
-- turn-in) and is followed by quest steps that cannot be done before it.

if not FastesBoooy.AddLibraryInsert then return end
local insert = FastesBoooy.AddLibraryInsert

------------------------------------------------------------------------------------------------------------------
-- Tirisfal (Undead) ---------------------------------------------------------------------------------------------
-- Deathknell: the letter, Aramis Hammerhand, training at 1
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-364",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-letter", accept = 98601, npc = { 1569, 1661 }, at = { 1420, 30.85, 66.1 },
          note = { ru = "Сарвис (или Элрет рядом) даёт и письмо паладина: «Трудный путь».",
                   en = "Sarvis (or Elreth next to him) also has the paladin's letter: A Difficult Path." } },
        { id = "pal-tir-aramis", turnin = 98601, accept = 90902, npc = 244808, at = { 1420, 31.1, 66.41 },
          use = 282423,
          note = { ru = "Прочитайте свиток (кнопка предмета) и поговорите с Арамисом — тренером паладинов "
                       .. "в церкви.",
                   en = "Read the Consecrated Scroll (item button), then talk to Aramis Hammerhand, "
                       .. "the paladin trainer in the church." } },
        { id = "pal-tir-train-1", train = true, npc = 244808, at = { 1420, 31.1, 66.41 },
          spells = { { ru = "Аура благочестия", en = "Devotion Aura" } },
          note = { ru = "Выучите Ауру благочестия (10 меди — хватает денег за зомби). Награды при следующей сдаче "
                       .. "в церкви (скелеты, лапы и крылья): кольчужные поножи и кожаный пояс.",
                   en = "Train Devotion Aura (10 copper, paid by The Mindless Ones reward). Rewards at the next "
                       .. "turn-ins in the church (skeletons, paws and wings): Roamer's Leggings (mail) and Old "
                       .. "Leather Belt." } },
        { id = "pal-tir-heal-bg", complete = 90902, bg = true, at = { 1420, 31.6, 63.7 },
          note = { ru = "Свет небес на раненых стражников смерти, лежащих по всей деревне (5). "
                       .. "Лечите, когда мана полная.",
                   en = "Cast Holy Light on the Injured Deathguards lying around the village (5), "
                       .. "whenever your mana is full." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Deathknell: level 4 (the generic gate ud01-xp-4 and the turn-ins of ud01-church-4 give it). Anchored on the
-- generic accept at Aramis (ud01-aramis), so the training follows every quest action at him.
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-aramis",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-90902", turnin = 90902, npc = 244808, at = { 1420, 31.1, 66.41 },
          note = { ru = "Арамис: сдайте лечение стражников.",
                   en = "Aramis Hammerhand: turn in the healing of the Deathguards." } },
        { id = "pal-tir-91209", -- 91209 is carried: turned in to Shari Stilwell in Brill (pal-tir-shari)
          accept = { 91208, 91209 }, npc = 244808, at = { 1420, 31.1, 66.41 },
          note = { ru = "Возьмите оба задания (нужен 4-й уровень). 91209 ведёт к тренеру паладинов в Брилле — "
                       .. "держите его.",
                   en = "Take both quests (they need level 4). 91209 leads to the paladin trainer in Brill: keep it." } },
        { id = "pal-tir-train-4", train = true, npc = 244808, at = { 1420, 31.1, 66.41 },
          spells = { { ru = "Правосудие", en = "Judgement" },
                     { ru = "Благословение могущества", en = "Blessing of Might" } },
          note = { ru = "В Forever Правосудие не снимает печать: жмите его по откату. "
                       .. "Не хватает денег — сначала Правосудие.",
                   en = "In Forever Judgement does not consume the Seal: use it on cooldown. "
                       .. "Short on money: Judgement first." } },
    },
})

insert({
    after = "ud01-boxes",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-frightened", complete = 91208, npc = 246143, at = { 1420, 27.69, 63.82 },
          note = { ru = "Испуганный паладин к западу от церкви: заговорите с ней, она нападёт — убейте её.",
                   en = "Frightened Paladin west of the church: talk to her, she turns hostile, kill her." } },
    },
})

insert({
    after = "ud01-98389",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-91208", turnin = 91208, npc = 244808, at = { 1420, 31.1, 66.41 },
          note = { ru = "Арамис: сдайте и «Примирение». Он учит до 6-го уровня; дальше — Шари Стилвелл в Брилле. "
                       .. "Награды дальше в Мертвом Звоне: у Салтейна и Аррена — кольчужные наручи и кольчужный "
                       .. "жилет; за повязки Алого ордена — Полуторный меч Отрекшихся (двуручный), если его "
                       .. "название не красное, иначе Кувалда Отрекшихся; за документы Коргала — щит.",
                   en = "Aramis Hammerhand: turn in Coming to Terms as well. He teaches up to level 6; then it is "
                       .. "Shari Stilwell in Brill. Rewards ahead in Deathknell: Rustmetal Bracers and Rugged Mail "
                       .. "Vest (mail) at Saltain and Arren; Forsaken Bastard Sword (two-hander) for the Scarlet "
                       .. "Armbands if its name is not red, otherwise Forsaken Maul; Deathguard Buckler for "
                       .. "Korgal's documents." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Brill, level 6: Shari Stilwell stands between Dillinger (the entrance) and the inn
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud02-dillinger-report",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-shari", complete = 91209, turnin = 91209, npc = 246152, at = { 1420, 60.22, 52.66 },
          note = { ru = "Шари Стилвелл — тренер паладинов у конюшни. Поговорите с ней и сдайте задание.",
                   en = "Shari Stilwell, the paladin trainer by the stables: talk to her and turn in." } },
        { id = "pal-tir-train-6", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Священный удар", en = "Holy Strike" },
                     { ru = "Свет небес (ранг 2)", en = "Holy Light (Rank 2)" } },
          note = { ru = "Нужен 6-й уровень. Священный удар — главная кнопка: жмите по откату вместе "
                       .. "с Правосудием. Не продавайте льняную ткань — 10 штук понадобятся паладину в Подгороде.",
                   en = "Needs level 6. Holy Strike is your key button: use it on cooldown together "
                       .. "with Judgement. Keep Linen Cloth: a paladin quest in the Undercity takes 10." } },
        { id = "pal-tir-mallet", vendor = true, npc = 2136, optional = true, at = { 1420, 60.12, 53.39 },
          note = { ru = "Деревянная киянка у Оливера Двора (двуручная булава, 5 ед. урона в секунду, 6 с 66 м): "
                       .. "купите, если она лучше вашего оружия и хватает денег. Продайте серый хлам.",
                   en = "Wooden Mallet from Oliver Dwor (two-handed mace, 5 DPS, 6s 66c): buy it if it beats "
                       .. "your weapon and you can afford it. Sell grey loot." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Brill, level 8: after the turn-in of 99144 at Shari
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud02-shari-99144",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-train-8", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Молот правосудия", en = "Hammer of Justice" } },
          note = { ru = "Шари Стилвелл: нужен 8-й уровень (если нет — выучите на 10-м вместе с остальным). Молот "
                       .. "правосудия держите на случай беды, например для Глаза Личинки. Награды при следующем "
                       .. "возвращении в Брилл — кольчуга: Сапоги склепохода (Диллинджер), Латунные чешуйчатые "
                       .. "штаны (Зиганд, за Глаз Личинки), Перчатки из холодной стали (Севрен, за гноллов).",
                   en = "Shari Stilwell: needs level 8 (if not yet, train it at level 10 with the rest). Keep "
                       .. "Hammer of Justice for emergencies, Maggot Eye for example. Rewards when you are back in "
                       .. "Brill, all mail: Cryptwalker Boots (Dillinger), Brass Scale Pants (Zygand, for Maggot "
                       .. "Eye), Cold Steel Gauntlets (Sevren, for the gnolls)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Brill, level 10 (the generic gate ud02-level-10): the quest to Bandarion Keep, training
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud02-level-10",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-91282", accept = 91282, npc = 246152, at = { 1420, 60.22, 52.66 },
          note = { ru = "Шари Стилвелл: задание паладина в крепость Бандарион.",
                   en = "Shari Stilwell: the paladin quest to Bandarion Keep." } },
        { id = "pal-tir-train-10", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Печать праведности (ранг 2)", en = "Seal of Righteousness (Rank 2)" },
                     { ru = "Аура благочестия (ранг 2)", en = "Devotion Aura (Rank 2)" },
                     { ru = "Возложение рук", en = "Lay on Hands" } },
          note = { ru = "Обучение 10-го уровня. Выучите и Молот правосудия, если пропустили. Таланты: первое "
                       .. "очко — в Воздаяние. Награды на восточном круге: за шкуры мурлоков (Шелена Робарт) — "
                       .. "Подошвы из плавников (+1 к силе); за кольца (Берджесс) — Пояс с застёжками (кольчуга).",
                   en = "Level-10 training. Also train Hammer of Justice if you missed it. Talents: first point "
                       .. "in Retribution. Rewards on the east loop: Finscale Soles (+1 Str) for the murloc skins "
                       .. "(Shelene Rhobart); Clasped Belt (mail) for the rings (Burgess)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Bandarion Keep: 91282 > 91285 > 91294 > 91316 / 91317 > 95803, next to the generic keep quests
------------------------------------------------------------------------------------------------------------------
insert({
    before = "ud02-keep",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-breton", turnin = 91282, accept = 91285, npc = 246349, at = { 1420, 21.85, 45.23 },
          note = { ru = "Бретон Сэмюэлс у крепости Бандарион.", en = "Breton Samuels at Bandarion Keep." } },
    },
})

insert({
    after = "ud02-leonid-letter",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-murlocs", complete = 91285, at = { 1420, 26.8, 45.0 },
          note = { ru = "Лагерь мурлоков на берегу озера сразу к востоку от крепости: 8 налётчиков и 8 провидцев.",
                   en = "Murloc camp on the lake shore just east of the keep: 8 Vile Fin Attackers and 8 Seers." } },
        { id = "pal-tir-smasher", turnin = 91285, accept = 91294, npc = 246349, at = { 1420, 21.85, 45.23 },
          note = { ru = "Бретон Сэмюэлс. Награда: Плавниковый крушитель (двуручная булава; не Головолом) — главное "
                       .. "оружие до Молота Каменного леса (855, ~19 ур.).",
                   en = "Breton Samuels. Reward: Driftwood Smasher (two-handed mace; not Skullthumper) - your main "
                       .. "weapon until the Stonewood Hammer from 855 (~level 19)." } },
        { id = "pal-tir-hilda", complete = { [91294] = { 1 } }, npc = 246389, at = { 1420, 21.96, 47.25 },
          note = { ru = "Хильда Сокрушительница у южной стены крепости: поговорите с ней (обход крепости).",
                   en = "Hilda the Breaker by the south wall of the keep: talk to her (the tour of the grounds)." } },
    },
})

insert({
    after = "ud02-hilda",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-ander", complete = { [91294] = { 3 } }, npc = 246394, at = { 1420, 25.41, 50.41 },
          note = { ru = "Андер Соллиден патрулирует дорогу к юго-востоку от крепости.",
                   en = "Ander Solliden patrols the road south-east of the keep." } },
        { id = "pal-tir-jorin", complete = { [91294] = { 2 } }, npc = 246393, at = { 1420, 22.69, 44.70 },
          note = { ru = "Джорин Кроге внутри крепости.", en = "Jorin Croge inside the keep." } },
        { id = "pal-tir-danitha", complete = { [91294] = { 4 } }, turnin = 91294, accept = 91317, npc = 246378,
          at = { 1420, 22.09, 44.66 },
          note = { ru = "Данита Морр наверху.", en = "Danitha Morr upstairs." } },
        { id = "pal-tir-91316", accept = 91316, npc = 246393, at = { 1420, 22.69, 44.70 },
          note = { ru = "Джорин Кроге: доски для ремонта крепости.", en = "Jorin Croge: lumber for the repairs." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shadowvale: the Tarnished, the lumber, Rudolph Gelhardt's head
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud02-ephram",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-tarnished-bg", complete = 91317, bg = true, at = { 1420, 14.8, 63.1 },
          note = { ru = "Потускневшие работяги (8) и фанатики (6) по всей Тенистой долине.",
                   en = "Tarnished Drudges (8) and Zealots (6) all over Shadowvale." } },
        { id = "pal-tir-lumber-bg", complete = 91316, bg = true, at = { 1420, 10.2, 65.5 },
          note = { ru = "Кучи досок (12 досок) на земле в Тенистой долине.",
                   en = "Lumber Piles (12 Sturdy Lumber) on the ground in Shadowvale." } },
    },
})

-- The head is a blocking step: it stands behind the generic along-the-way goals (bones, elixir bottles), so all
-- four goals of Shadowvale are listed while the paladin hunts Rudolph (the engine lists only the bg steps in
-- front of the cursor).
insert({
    after = "ud02-elixir-bg",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-head", collect = { [270435] = 1 }, npc = 259431, at = { 1420, 11.51, 64.18 },
          note = { ru = "Рудольф Гельхардт (12) наверху: заберите его голову.",
                   en = "Rudolph Gelhardt (12) upstairs: loot his head." } },
    },
})

insert({
    after = "ud02-shadowvale",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-shadowvale", complete = { 91317, 91316 }, at = { 1420, 11.5, 65.5 },
          note = { ru = "Добейте Потускневших и доски, прежде чем возвращаться в крепость.",
                   en = "Finish the Tarnished and the lumber before you head back to the keep." } },
    },
})

insert({
    after = "ud02-hilda-2",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-91316-turnin", turnin = 91316, npc = 246393, at = { 1420, 22.69, 44.70 },
          note = { ru = "Джорин Кроге. Награда: башенный щит — пригодится только для игры со щитом.",
                   en = "Jorin Croge. Reward: Salvaged Wooden Tower Shield - only useful for shield play." } },
        { id = "pal-tir-95803", turnin = 91317, accept = 95803, npc = 246378, at = { 1420, 22.09, 44.66 },
          note = { ru = "Данита: голову Рудольфа нужно отнести леди Сильване в Подгород.",
                   en = "Danitha: Rudolph's head goes to Lady Sylvanas in the Undercity." } },
    },
})

-- 94427 needs level 12: the generic gate ud02-lvl-12 guarantees it. The chain is optional (its second quest
-- takes 10 Linen Cloth), so nothing mandatory depends on it.
insert({
    after = "ud02-lvl-12",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-94427", accept = 94427, npc = 246378, optional = true, at = { 1420, 22.09, 44.66 },
          note = { ru = "По желанию, если есть 10 льняной ткани: Данита Морр — «Урок божественности» (сдаётся в "
                       .. "Подгороде). Нет ткани — пропустите этот шаг и два шага у Танис в Подгороде.",
                   en = "Optional, if you carry 10 Linen Cloth: Danitha Morr - A Lesson in Divinity (turned in at "
                       .. "the Undercity). No cloth: skip this step and the two steps at Tanis in the Undercity." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Brill, level 12: Shari Stilwell, 35 yd from Carolai
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud02-carolai-2",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-train-12", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Священный удар (ранг 2)", en = "Holy Strike (Rank 2)" },
                     { ru = "Благословение могущества (ранг 2)", en = "Blessing of Might (Rank 2)" } },
          note = { ru = "Шари Стилвелл: обучение 12-го уровня. Следующий тренер — Гарен Ларго в Подгороде на 14-м "
                       .. "(конец Серебряного бора).",
                   en = "Shari Stilwell: level-12 training. The next trainer is Garen Largo in the Undercity at 14 "
                       .. "(end of Silverpine)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Undercity: A Lesson in Divinity (optional), Lady Sylvanas
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud02-fp-uc",
    class = "PALADIN",
    steps = {
        { id = "pal-tir-tanis", turnin = 94427, accept = 94434, npc = 257648, optional = true,
          at = { 1458, 65.48, 37.49 },
          note = { ru = "Танис Алдервуд в Торговом квартале (если брали «Урок божественности»).",
                   en = "Tanis Alderwood in the Trade Quarter (if you took A Lesson in Divinity)." } },
        { id = "pal-tir-tanis-2", complete = 94434, turnin = 94434, npc = 257648, optional = true,
          at = { 1458, 65.48, 37.49 },
          note = { ru = "Отдайте 10 льняной ткани. Следующее задание (обратно в крепость) не берите.",
                   en = "Hand in 10 Linen Cloth. Do not take the next one (back to the keep)." } },
        { id = "pal-tir-sylvanas", turnin = 95803, npc = 10181, at = { 1458, 58.05, 91.79 },
          note = { ru = "Леди Сильвана в Королевском квартале: отдайте голову Рудольфа.",
                   en = "Lady Sylvanas in the Royal Quarter: hand over Rudolph's head." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path --------------------------------------------------------------------------------------------------
-- 14: Undercity (Garen Largo)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h13-uc-end",
    class = "PALADIN",
    steps = {
        -- CONFIRM: the paladin trainer Garen Largo in the Undercity (in the DB, not on the web)
        { id = "pal-train-14", train = true, npc = 260093, at = { 1458, 47.5, 15.0 },
          spells = { { ru = "Свет небес (ранг 3)", en = "Holy Light (Rank 3)" } },
          note = { ru = "Гарен Ларго в Квартале Воинов (следующий тренер - только в Громовом Утёсе на 18-м). Не выучили ранги 12-го в "
                       .. "Брилле - возьмите их здесь же. Нет его на месте - Шари Стилвелл в Брилле, по пути к башне дирижаблей.",
                   en = "Garen Largo in the War Quarter (the next trainer is Thunder Bluff at 18). Missed the level-12 ranks in "
                       .. "Brill: train them here too. Not there: Shari Stilwell in Brill, on the way to the zeppelin tower." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 18: Thunder Bluff (Alodan, in Zamah's cave)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h18-tb-zamah",
    class = "PALADIN",
    steps = {
        -- CONFIRM: the paladin trainer Alodan the Hopeful in Thunder Bluff (in the DB, not on the web)
        { id = "pal-train-18", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Печать праведности (ранг 3)", en = "Seal of Righteousness (Rank 3)" } },
          note = { ru = "Тренер паладинов Алодан Жизнерадостный бродит по этой же пещере: Печать праведности 3 - главный ранг урона. "
                       .. "Пропустили Свет небес 3 на 14-м - возьмите здесь. Освящение и Благословение королей будут на 20-м. Нет его "
                       .. "на месте - ранги подождут Брилла (Шари Стилвелл) на 22-м.",
                   en = "Alodan the Hopeful wanders in the same cave: Seal of Righteousness R3, the main damage rank. Missed Holy "
                       .. "Light R3 at 14: train it here. Consecration and Blessing of Kings come at 20. Not there: the ranks wait "
                       .. "for Brill (Shari Stilwell) at 22." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 20: Thunder Bluff (Alodan), from Elder Rise
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h18-tb-2",
    class = "PALADIN",
    steps = {
        { id = "pal-20-pools", go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "С Вершины Старейшин через центральную вершину на Вершину Духов: Пруды Видений под ней.",
                   en = "From Elder Rise across the central mesa to Spirit Rise: the Pools of Vision below it." } },
        -- CONFIRM: Alodan the Hopeful (see pal-train-18)
        { id = "pal-train-20", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Освящение", en = "Consecration" },
                     { ru = "Священный удар (ранг 3)", en = "Holy Strike (Rank 3)" },
                     { ru = "Благословение королей", en = "Blessing of Kings" },
                     { ru = "Аура благочестия (ранг 3)", en = "Devotion Aura (Rank 3)" },
                     { ru = "Печать праведности (ранг 3)", en = "Seal of Righteousness (Rank 3)" } },
          note = { ru = "Тренер паладинов Алодан Жизнерадостный: обучение 20-го уровня (и Печать праведности 3, если не выучили на "
                       .. "18-м). Талант - Стремление к справедливости. Нет его на месте - ранги подождут Брилла (Шари Стилвелл) на "
                       .. "22-м.",
                   en = "Alodan the Hopeful: level-20 training (plus Seal of Righteousness R3 if you missed it at 18). Talent: "
                       .. "Pursuit of Justice. Not there: the ranks wait for Brill (Shari Stilwell) at 22." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 22: Thunder Bluff (Alodan), after Zamah's two quest steps
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-22-tb-start",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Alodan the Hopeful (see pal-train-18)
        { id = "pal-train-22", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Благословение могущества (ранг 3)", en = "Blessing of Might (Rank 3)" },
                     { ru = "Свет небес (ранг 4)", en = "Holy Light (Rank 4)" } },
          note = { ru = "Тренер паладинов Алодан Жизнерадостный в этой же пещере: обучение 22-го уровня. Талант 22 - Печать "
                       .. "повиновения. Нет его на месте - Шари Стилвелл в Брилле: маршрут проходит башню дирижаблей Тирисфаля чуть "
                       .. "позже.",
                   en = "Alodan the Hopeful in the same cave: level-22 training. Talent at 22: Seal of Command. Not there: Shari "
                       .. "Stilwell in Brill - the route passes the Tirisfal zeppelin tower a little later." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 22-24: optional class chain, part 1 (Bandarion Keep -> the Sepulcher -> Fenris Isle -> the Sepulcher)
------------------------------------------------------------------------------------------------------------------
insert({
    before = "h-22-uc-fly",
    class = "PALADIN",
    steps = {
        -- This optional chain (estimated XP) is why h-22-hillsbrad ends at ~25.1 on the paladin route: the
        -- segment-level warning is acknowledged on the segment (Segments/Shared/22_Hillsbrad.lua).
        { id = "pal-22-danitha", accept = 91858, npc = 246378, optional = true, at = { 1420, 22.09, 44.66 },
          note = { ru = "По желанию, классовая цепочка к «Акониту» (двуручный меч 25.6 DPS): только если потом пойдёте в "
                       .. "Мертвые копи, Крепость Темного Клыка и к Непроглядной Пучине (вторая часть в гайде не "
                       .. "ведётся), ~25 мин, опыт неизвестен. Из Подгорода на запад к крепости Бандарион: Данита Морр "
                       .. "— «Дипломатический скандал». Потом летите из Подгорода в Гробницу (или бегом на юг). Не "
                       .. "делаете — «Вперёд» на этом шаге и на девяти шагах цепочки в Гробнице. Сам «Аконит» — "
                       .. "двуручный меч: навык у Арчибальда в Подгороде.",
                   en = "Optional class chain towards Wolfsbane (2H sword, 25.6 dps): only if you will also run the "
                       .. "Deadmines, Shadowfang Keep and the Blackfathom Deeps entrance later (part 2 is not routed), "
                       .. "~25 min, XP unknown. Out of Undercity west to Bandarion Keep: Danitha Morr - Diplomatic "
                       .. "Incident. Then fly from Undercity to the Sepulcher (or run south). Not doing it: press Forward on this "
                       .. "step and the nine chain steps at the Sepulcher. Wolfsbane itself is a 2H sword: the skill is "
                       .. "taught by Archibald in Undercity." } },
    },
})

insert({
    after = "h-22-the-sepulcher-apothecary",
    class = "PALADIN",
    steps = {
        { id = "pal-22-trevan", turnin = 91858, accept = 91859, npc = 248840, optional = true,
          at = { 1421, 43.40, 41.10 },
          note = { ru = "Классовая цепочка (по желанию): Треван Рол в Гробнице — «Любопытная парочка».",
                   en = "Class chain (optional): Trevan Rol at the Sepulcher - A Curious Pair." } },
        { id = "pal-22-baldren", turnin = 91859, accept = 91860, npc = 259611, optional = true,
          at = { 1421, 45.81, 41.88 },
          note = { ru = "Страж смерти Балдрен рядом — «Незавидная участь» (остров Фенрис).",
                   en = "Deathguard Baldren nearby - A Grim Fate (Fenris Isle)." } },
        { id = "pal-22-remains", turnin = 91860, accept = 91861, object = 566037, optional = true,
          at = { 1421, 65.02, 34.10 },
          note = { ru = "На восток к озеру и вплавь на остров Фенрис: обугленные останки на юге острова — «В крепость "
                       .. "Фенриса».",
                   en = "East to the lake and swim over to Fenris Isle: the Charred Remains in the south of the isle - "
                       .. "Into Fenris Keep." } },
        { id = "pal-22-lumina-keep", turnin = 91861, accept = 91862, npc = 248755, optional = true,
          at = { 1421, 65.55, 23.27 },
          note = { ru = "Север острова, крепость Фенриса: Люмина Песнь Ветра в плену — «Люмина Песнь Ветра».",
                   en = "North of the isle, Fenris Keep: Lumina Windsinger is held captive - Lumina Windsinger." } },
        { id = "pal-22-key", complete = 91862, optional = true, at = { 1421, 66.20, 24.20 },
          note = { ru = "Гноллы Гнилошкуры в крепости: ключ от острова Фенрис.",
                   en = "The Rot Hide gnolls in the keep: the Fenris Isle Key." } },
        { id = "pal-22-escort-start", turnin = 91862, accept = 96204, npc = 248755, optional = true,
          at = { 1421, 65.55, 23.27 },
          note = { ru = "Освободите Люмину ключом — «Гнев Ваятелей Ветра» (сопровождение).",
                   en = "Free Lumina with the key - The Windshaper's Wrath (escort)." } },
        { id = "pal-22-escort", complete = 96204, optional = true, at = { 1421, 65.00, 30.00 },
          note = { ru = "Выведите Люмину из крепости Фенриса.", en = "Escort Lumina out of Fenris Keep." } },
        { id = "pal-22-lumina", turnin = 96204, accept = 95034, npc = 259620, optional = true,
          at = { 1421, 43.40, 40.99 },
          note = { ru = "Обратно в Гробницу: Люмина — «Долг».", en = "Back to the Sepulcher: Lumina - The Debt." } },
        { id = "pal-22-debt", turnin = 95034, npc = 259620, optional = true,
          at = { 1421, 43.40, 40.99 },
          note = { ru = "Поговорите с ней ещё раз. Дальше «Клинок лунного поцелуя» (95036): древесина белокаменного дуба "
                       .. "(Мертвые копи, 1.6%), зачарованный серебряный слиток (Крепость Темного Клыка) и камень Кор "
                       .. "(95042, наги у входа в Непроглядную Пучину) — только если идёте в эти подземелья; гайд его не "
                       .. "ведёт.",
                   en = "Talk to her once more. Next is A Moon-Kissed Blade (95036): Whitestone Oak Lumber (the "
                       .. "Deadmines, 1.6%), an Enchanted Silver Ingot (Shadowfang Keep) and the Kor Gem (95042, the "
                       .. "naga at the Blackfathom Deeps entrance) - only if you run those dungeons; the guide does not "
                       .. "route it." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 26: Thunder Bluff (Alodan)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-27-tb-arrive",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Alodan the Hopeful (see pal-train-18)
        { id = "pal-train-26", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Печать праведности (ранг 4)", en = "Seal of Righteousness (Rank 4)" },
                     { ru = "Вспышка Света (ранг 2)", en = "Flash of Light (Rank 2)" },
                     { ru = "Молот правосудия (ранг 2)", en = "Hammer of Justice (Rank 2)" } },
          note = { ru = "Алодан Жизнерадостный бродит в этой же пещере: обучение 26-го (Печать праведности 4 — главный "
                       .. "ранг урона). Нет его на месте — ранги подождут Брилла (Шари Стилвелл, 2 мин от башни дирижаблей на 31-м). "
                       .. "Таланты: 23-25 — Приговор 3/3, 26-28 — Специализация на двуручном оружии.",
                   en = "Alodan the Hopeful wanders in the same cave: level-26 training (Seal of Righteousness R4, the "
                       .. "main damage rank). Not there: the ranks wait for Brill (Shari Stilwell, 2 min from the zeppelin tower at "
                       .. "31). Talents: 23-25 Conviction 3/3, 26-28 Two-Handed Weapon Specialization." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 28 + 30: Thunder Bluff (Alodan), last Thunder Bluff visit of the route
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-31-tb-hearth",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Alodan the Hopeful (see pal-train-18)
        { id = "pal-train-30", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Священный удар (ранг 4)", en = "Holy Strike (Rank 4)" },
                     { ru = "Освящение (ранг 2)", en = "Consecration (Rank 2)" },
                     { ru = "Печать повиновения (ранг 2)", en = "Seal of Command (Rank 2)" },
                     { ru = "Свет небес (ранг 5)", en = "Holy Light (Rank 5)" },
                     { ru = "Возложение рук (ранг 2)", en = "Lay on Hands (Rank 2)" },
                     { ru = "Экзорцизм (ранг 2)", en = "Exorcism (Rank 2)" } },
          note = { ru = "От таверны по мосту на Вершину Духов, вниз в Пруды Видений: Алодан, обучение 28 + 30. Это "
                       .. "последний визит в Громовой Утёс — дальше тренер Гарен Ларго в Подгороде. Нет Алодана — на 31-м маршрут "
                       .. "прилетает дирижаблем к башне Тирисфаля: оттуда 2 мин на север к Шари Стилвелл в Брилле. "
                       .. "Таланты: 29 — Sacred Arbiter, 30-32 — Отмщение 3/3.",
                   en = "From the inn over the bridge to Spirit Rise and down into the Pools of Vision: Alodan, "
                       .. "training 28 + 30. Last Thunder Bluff visit of the route; from now on the trainer is Garen "
                       .. "Largo in Undercity. No Alodan: at 31 the zeppelin lands at the Tirisfal tower, 2 min south "
                       .. "of Shari Stilwell in Brill. Talents: 29 Sacred Arbiter, 30-32 Vengeance 3/3." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 32 + 34: Undercity (Garen Largo)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-34-uc-arrive",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill
        { id = "pal-train-34", train = true, npc = 260093, at = { 1458, 47.53, 15.04 },
          spells = { { ru = "Печать праведности (ранг 5)", en = "Seal of Righteousness (Rank 5)" },
                     { ru = "Благословение могущества (ранг 4)", en = "Blessing of Might (Rank 4)" },
                     { ru = "Божественный щит", en = "Divine Shield" },
                     { ru = "Вспышка Света (ранг 3)", en = "Flash of Light (Rank 3)" },
                     { ru = "Печать воина Света (ранг 4)", en = "Seal of the Crusader (Rank 4)" } },
          note = { ru = "Квартал Воинов (северо-запад): тренер паладинов Гарен Ларго, обучение 32 + 34 (нет его — Шари Стилвелл "
                       .. "в Брилле, 2 мин на север от входа в Подгород). Потом к "
                       .. "Фаранеллу в зал аптекарей. Таланты: 33 — Покаяние, 34 — Благодарение 1/5. Оружие: квестовых "
                       .. "двуручников до 44-го больше нет (Молот Уничтожения, 17.6 DPS) — есть золото, загляните на "
                       .. "аукцион Подгорода (двуручная булава 25+ DPS).",
                   en = "The War Quarter (north-west): paladin trainer Garen Largo, training 32 + 34 (not there: Shari "
                       .. "Stilwell in Brill, 2 min north of the Undercity entrance). Then to Faranell "
                       .. "in the Apothecarium. Talents: 33 Repentance, 34 Benediction 1/5. Weapon: no quest two-hander "
                       .. "until 44 (Demolition Hammer, 17.6 dps) - with gold to spare, check the Undercity auction house "
                       .. "(a 2H mace of 25+ dps)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 40: Two-Handed Axes (Hanashi, Orgrimmar) before the 1427 reward (Tok'kar's Murloc Chopper) and Beastslayer
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h41-hearth-org",
    class = "PALADIN",
    steps = {
        { id = "pal-axes", manual = true, npc = 2704, optional = true, at = { 1454, 81.53, 19.63 },
          spells = { { ru = "Двуручные топоры", en = "Two-Handed Axes" } },
          note = { ru = "Рекомендуется: от таверны на северо-восток в Аллею Чести, мастер оружия Ханаши — Двуручные "
                       .. "топоры (~3 мин крюка пешком), потом через главные ворота к дирижаблям. Тогда за 1427 на 44-м "
                       .. "берите Колун мурлоков Ток'Кара (двуручный топор, 32.5 DPS, +15 к силе, скорость 3.2 — с "
                       .. "Печатью повиновения лучше Сокрушителя), а к Зверобою (4301, 54-й) навык топоров уже вырастет. "
                       .. "Навык начинается с 1: первые бои с Колуном — с промахами, пока он не догонит уровень (окно "
                       .. "персонажа, «Навыки»). До 44-го остаётся Молот Уничтожения: молот из 666 требует Инженерное "
                       .. "дело (100). Пропустили — на 44-м берите Сокрушитель (булава). Готово — «Вперёд».",
                   en = "Recommended: from the inn north-east to the Valley of Honor, weapon master Hanashi - Two-Handed "
                       .. "Axes (~3 min detour on foot), then out the main gate to the zeppelins. Then take Tok'kar's "
                       .. "Murloc Chopper for 1427 at 44 (2H axe, 32.5 dps, +15 Str, speed 3.2 - better than the Basher "
                       .. "with Seal of Command), and the axe skill has grown by Beastslayer (4301, at 54). The skill "
                       .. "starts at 1: the first fights with the Chopper miss a lot until it catches up with your level "
                       .. "(character pane, Skills). Until 44 the Demolition Hammer stays: the hammer of 666 requires "
                       .. "Engineering (100). Skipped: take the Basher (mace) at 44. Done: press Forward." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 36-40 + riding: Brill (Shari Stilwell, Velma Warnam, Zachariah Post), 2 minutes from the zeppelin tower;
-- optional Garen Largo (Undercity) for the level-40 ranks if Shari's list lacks them
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-41-uc-arrive",
    class = "PALADIN",
    steps = {
        { id = "pal-train-40", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Молот праведника", en = "Hammer of the Righteous" },
                     { ru = "Освящение (ранг 3)", en = "Consecration (Rank 3)" },
                     { ru = "Печать повиновения (ранг 3)", en = "Seal of Command (Rank 3)" },
                     { ru = "Священный удар (ранг 5)", en = "Holy Strike (Rank 5)" },
                     { ru = "Молот правосудия (ранг 3)", en = "Hammer of Justice (Rank 3)" },
                     { ru = "Свет небес (ранг 6)", en = "Holy Light (Rank 6)" },
                     { ru = "Экзорцизм (ранг 3)", en = "Exorcism (Rank 3)" },
                     { ru = "Латы", en = "Plate Mail" },
                     { ru = "Призыв боевого коня (если есть в списке)", en = "Summon Warhorse (if listed)" } },
          note = { ru = "От башни дирижаблей на север в Брилл (2 мин): Шари Стилвелл у конюшни, обучение 36-40 (Молот "
                       .. "праведника — удар по цели и трём соседним, 6 с). Если в её списке нет рангов 40-го (Молот "
                       .. "праведника, Освящение 3, Печать повиновения 3, Молот правосудия 3) — они у Гарена Ларго в "
                       .. "Подгороде (необязательный шаг после коня). Таланты: 35-39 — Champion of the Light 5/5, 40 — "
                       .. "Unsealed Wrath (вершина Воздаяния).",
                   en = "North from the zeppelin tower to Brill (2 min): Shari Stilwell by the stables, training 36-40 "
                       .. "(Hammer of the Righteous hits the target and 3 more, 6 s). If her list lacks the level-40 "
                       .. "ranks (Hammer of the Righteous, Consecration 3, Seal of Command 3, Hammer of Justice 3): Garen "
                       .. "Largo in Undercity has them (optional step after the horse). Talents: 35-39 Champion of the "
                       .. "Light 5/5, 40 Unsealed Wrath (the Retribution capstone)." } },
        { id = "pal-40-riding", manual = true, npc = 4773, optional = true, at = { 1420, 60.08, 52.57 },
          note = { ru = "Вельма Варнам рядом: Верховая езда (ученик), ~100 з. — по анонсу Forever скакун выдаётся "
                       .. "вместе с навыком. Если у тренера паладинов был «Призыв боевого коня» — выучили его, езда не нужна. "
                       .. "Не хватает золота — «Вперёд», вернётесь на 44-м (Брилл в 2 мин от башни дирижаблей). "
                       .. "Готово — «Вперёд».",
                   en = "Velma Warnam next to her: Apprentice Riding, ~100 g - Forever announced a mount with the skill. "
                       .. "If the paladin trainer offered Summon Warhorse, you learned that and need no riding. Not "
                       .. "enough gold: press Forward and come back at 44 (Brill is 2 min from the zeppelin tower). Done: "
                       .. "press Forward." } },
        { id = "pal-40-horse", vendor = true, npc = 4731, optional = true, at = { 1420, 59.87, 52.68 },
          note = { ru = "Только если с ездой не дали скакуна: Захария Пост — скелет-конь (любой). Потом обратно в "
                       .. "Подгород.",
                   en = "Only if the riding skill came without a mount: Zachariah Post - a skeletal horse (any). Then "
                       .. "back to Undercity." } },
        -- CONFIRM: Garen Largo (see pal-train-14)
        { id = "pal-train-40-garen", train = true, npc = 260093, optional = true, at = { 1458, 47.53, 15.04 },
          spells = { { ru = "Молот праведника", en = "Hammer of the Righteous" },
                     { ru = "Освящение (ранг 3)", en = "Consecration (Rank 3)" },
                     { ru = "Печать повиновения (ранг 3)", en = "Seal of Command (Rank 3)" },
                     { ru = "Молот правосудия (ранг 3)", en = "Hammer of Justice (Rank 3)" },
                     { ru = "Латы", en = "Plate Mail" } },
          note = { ru = "Только если у Шари не было рангов 40-го: в Подгороде на северо-запад в Квартал Воинов, Гарен "
                       .. "Ларго (верхом ~1 мин крюка). Всё выучили в Брилле — «Вперёд».",
                   en = "Only if Shari lacked the level-40 ranks: in Undercity north-west to the War Quarter, Garen "
                       .. "Largo (~1 min detour mounted). Learned everything in Brill: press Forward." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 42 + 44: Undercity (Garen Largo)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-44-uc-arrive",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill
        { id = "pal-train-44", train = true, npc = 260093, at = { 1458, 47.53, 15.04 },
          spells = { { ru = "Молот гнева", en = "Hammer of Wrath" },
                     { ru = "Священный удар (ранг 6)", en = "Holy Strike (Rank 6)" },
                     { ru = "Печать праведности (ранг 6)", en = "Seal of Righteousness (Rank 6)" },
                     { ru = "Благословение могущества (ранг 5)", en = "Blessing of Might (Rank 5)" },
                     { ru = "Вспышка Света (ранг 4)", en = "Flash of Light (Rank 4)" },
                     { ru = "Очищение", en = "Cleanse" },
                     { ru = "Экзорцизм (ранг 4)", en = "Exorcism (Rank 4)" },
                     { ru = "Печать воина Света (ранг 5)", en = "Seal of the Crusader (Rank 5)" } },
          note = { ru = "Квартал Воинов: Гарен Ларго, обучение 42 + 44 (Молот гнева — добивание ниже 20% здоровья; нет его — "
                       .. "Шари Стилвелл в Брилле, 1 мин верхом от входа в Подгород). "
                       .. "Без езды с 40-го? Вельма Варнам в Брилле, 2 мин от башни дирижаблей. Таланты: 41-45 — "
                       .. "Божественная сила 5/5 (Свет). Награда Ток'Кара за 1427 в Болоте Печали: Колун мурлоков Ток'Кара "
                       .. "(двуручный топор, +15 к силе), если на 40-м выучили топоры; иначе Сокрушитель мурлоков "
                       .. "Ток'Кара (двуручная булава, +18 к выносливости).",
                   en = "The War Quarter: Garen Largo, training 42 + 44 (Hammer of Wrath finishes targets below 20% "
                       .. "health; not there: Shari Stilwell in Brill, 1 min mounted from the Undercity entrance). No riding "
                       .. "since 40? Velma Warnam in Brill, 2 min from the zeppelin tower. Talents: "
                       .. "41-45 Divine Strength 5/5 (Holy). Tok'Kar's reward for 1427 in the Swamp of Sorrows: Tok'kar's "
                       .. "Murloc Chopper (2H axe, +15 Str) if you learned Two-Handed Axes at 40, otherwise Tok'kar's "
                       .. "Murloc Basher (2H mace, +18 Sta)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 46-52: Undercity (Garen Largo); the Undercity stop at 49.5 (h-50-uc-arrive) is short of 50
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h53-fly-uc",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill
        { id = "pal-train-52", train = true, npc = 260093, at = { 1458, 47.53, 15.04 },
          spells = { { ru = "Печать праведности (ранг 7)", en = "Seal of Righteousness (Rank 7)" },
                     { ru = "Печать повиновения (ранг 4)", en = "Seal of Command (Rank 4)" },
                     { ru = "Освящение (ранг 4)", en = "Consecration (Rank 4)" },
                     { ru = "Священный удар (ранг 7)", en = "Holy Strike (Rank 7)" },
                     { ru = "Молот гнева (ранг 2)", en = "Hammer of Wrath (Rank 2)" },
                     { ru = "Благословение могущества (ранг 6)", en = "Blessing of Might (Rank 6)" },
                     { ru = "Свет небес (ранг 7)", en = "Holy Light (Rank 7)" },
                     { ru = "Вспышка Света (ранг 5)", en = "Flash of Light (Rank 5)" },
                     { ru = "Возложение рук (ранг 3)", en = "Lay on Hands (Rank 3)" },
                     { ru = "Божественный щит (ранг 2)", en = "Divine Shield (Rank 2)" },
                     { ru = "Гнев небес", en = "Holy Wrath" },
                     { ru = "Экзорцизм (ранг 5)", en = "Exorcism (Rank 5)" } },
          note = { ru = "Квартал Воинов: Гарен Ларго, обучение 46-52 (ранги 50-го ждали с прошлого визита на 49.5; нет его — "
                       .. "Шари Стилвелл в Брилле, 1 мин верхом от входа в Подгород). "
                       .. "Потом в Квартал Магов к Орану. Гнев небес и Экзорцизм — для Чумных земель (нежить). Таланты: "
                       .. "46-50 — Improved Seals 5/5 (Свет), 51-54 — Благодарение до 5/5. Не учили двуручные топоры на "
                       .. "40-м? Ханаши стоит рядом с Белгромом в Аллее Чести Оргриммара (маршрут будет там на 53-м) — без "
                       .. "них Зверобой (4301) бесполезен.",
                   en = "The War Quarter: Garen Largo, training 46-52 (the 50 ranks waited since the 49.5 visit; not there: "
                       .. "Shari Stilwell in Brill, 1 min mounted from the Undercity entrance). Then "
                       .. "to Oran in the Magic Quarter. Holy Wrath and Exorcism are for the Plaguelands (undead). "
                       .. "Talents: 46-50 Improved Seals 5/5 (Holy), 51-54 Benediction up to 5/5. No Two-Handed Axes "
                       .. "from 40? Hanashi stands next to Belgrom in Orgrimmar's Valley of Honor (the route takes you "
                       .. "there at 53) - Beastslayer (4301) needs them." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 54 + 58 (optional): Undercity, last stop before the Plaguelands (57.95-57.99)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h59-hearth-uc",
    class = "PALADIN",
    steps = {
        -- CONFIRM: Garen Largo (see pal-train-14)
        { id = "pal-train-58", train = true, npc = 260093, optional = true, at = { 1458, 47.53, 15.04 },
          spells = { { ru = "Печать праведности (ранг 8)", en = "Seal of Righteousness (Rank 8)" },
                     { ru = "Вспышка Света (ранг 6)", en = "Flash of Light (Rank 6)" },
                     { ru = "Свет небес (ранг 8)", en = "Holy Light (Rank 8)" },
                     { ru = "Молот правосудия (ранг 4)", en = "Hammer of Justice (Rank 4)" } },
          note = { ru = "По желанию: Квартал Воинов, Гарен Ларго — ранги 54 и, если уже 58-й (обычно да с попутными "
                       .. "убийствами; по квестам здесь 57.95-57.99), Печать праведности 8. Нет 58-го — «Вперёд», всё "
                       .. "выучите на 60-м (нет Гарена — тоже на 60-м, в Брилле). Таланты: 55-59 — Божественный интеллект 5/5 "
                       .. "(Защита).",
                   en = "Optional: War Quarter, Garen Largo - the 54 ranks and, if you are 58 already (usually yes with "
                       .. "kills on the way; the quests alone give 57.95-57.99 here), Seal of Righteousness R8. Not 58: "
                       .. "press Forward, you train everything at 60 (no Garen: also at 60, in Brill). Talents: 55-59 Divine "
                       .. "Intellect 5/5 (Protection)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 60: hearth to Undercity (bound at h-58-uc-arrive), level-60 training
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-60-end",
    class = "PALADIN",
    steps = {
        { id = "pal-60-hearth", hearth = "Undercity", at = { 1458, 67.74, 37.89 },
          note = { ru = "Камень возвращения в Подгород (привязан в Подгороде перед Чумными землями). На откате — полёт "
                       .. "из Часовни Последней Надежды.",
                   en = "Hearth to Undercity (bound there before the Plaguelands). On cooldown: fly from Light's Hope "
                       .. "Chapel." } },
        -- CONFIRM: Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill
        { id = "pal-train-60", train = true, npc = 260093, at = { 1458, 47.53, 15.04 },
          spells = { { ru = "Священный удар (ранг 8)", en = "Holy Strike (Rank 8)" },
                     { ru = "Печать повиновения (ранг 5)", en = "Seal of Command (Rank 5)" },
                     { ru = "Освящение (ранг 5)", en = "Consecration (Rank 5)" },
                     { ru = "Молот гнева (ранг 3)", en = "Hammer of Wrath (Rank 3)" },
                     { ru = "Благословение могущества (ранг 7)", en = "Blessing of Might (Rank 7)" },
                     { ru = "Свет небес (ранг 9)", en = "Holy Light (Rank 9)" },
                     { ru = "Экзорцизм (ранг 6)", en = "Exorcism (Rank 6)" },
                     { ru = "Печать праведности (ранг 8)", en = "Seal of Righteousness (Rank 8)" } },
          note = { ru = "Квартал Воинов: Гарен Ларго — обучение 60 (и 58, если пропустили; нет его — Шари Стилвелл в Брилле, "
                       .. "1 мин верхом от входа в Подгород). Талант 60 — Точность 1/3 "
                       .. "(Защита). «Призыв скакуна Отрекшихся» (60) — источник пока неизвестен (по анонсу "
                       .. "Blizzard — задание у крепости Бандарион). Маршрут 1-60 пройден!",
                   en = "The War Quarter: Garen Largo - level-60 training (and 58 if you skipped it; not there: Shari "
                       .. "Stilwell in Brill, 1 min mounted from the Undercity entrance). Talent at 60: "
                       .. "Precision 1/3 (Protection). Summon Forsaken Charger (60): source unknown so far (Blizzard "
                       .. "announced a quest at Bandarion Keep). The 1-60 route is done!" } },
    },
})
