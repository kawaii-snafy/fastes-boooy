-- FastesBoooy_Guides / Segments / Tirisfal / 01_Deathknell.lua
--
-- Segment ud-01-deathknell: character creation (Deathknell crypt) -> leaving Deathknell, levels 1-6.
-- Class-neutral: every Undead class walks these steps. What exists because of a class (the letter of the
-- class at level 1, class quests, training) is a shared insert of Classes/<Class>.lua on the anchors below.
-- Coordinates: Forever uiMap 1420 (Tirisfal Glades), map percent, from tools/data/forever_db.lua
-- (NPC/object spawns; centroids of the objective mob/object spawns for complete steps).
--
-- Hub plan (Forever DB): 363 > 364 > {3901, 376}; 376 unlocks 3902, 380, 6395 and 98389;
-- 380 > 381 > 382 > {383, 96656}.
-- Skipped: 590 (duel with Calvin Montague, little XP).
-- Carried into the next segment (turned in at Brill): 383, 96656, 8.
-- Hearthstone: not touched (starting bind).
--
-- Anchors for class files (docs/dev/PLAN.md C.2; level of the base profile before the step):
--   ud01-364       2.42  Sarvis hands out the letter of the class here (its quest needs 364); first training
--   ud01-church-4  3.74  the turn-ins of this step give level 4.0 (gate ud01-xp-4): training at 4
--   ud01-aramis    4.03  the optional accept of 98389 at Aramis: the last generic step in the church. A class
--                        whose trainer is Aramis (the paladin) puts its training after this step, not after
--                        ud01-church-4 (look-ahead rule); for the others both anchors work
--   ud01-381       5.33  last visit of the Deathknell trainers (start-camp trainers teach up to level 6)
--   ud01-382       5.51  the last turn-in in the village; ud01-end (Calvin Montague, on the road) follows
-- Trainers: priest, mage, warlock and paladin in the church (next to Sarvis); warrior and rogue in the house
-- across the road (next to the vendor Joshua Kien).
--
-- 98389 "A Light in the Darkness" starts and ends at Aramis Hammerhand, the paladin trainer, but has no class
-- limit in the DB: it is a generic quest here, and its three steps (ud01-aramis, ud01-cocoons, ud01-98389) are
-- `optional` (docs/dev/PLAN.md E.6). If he does not offer it to a class, the guide passes the three steps by
-- itself as soon as the next quest step is done (optional steps are forwarded, and a quest that was never taken
-- no longer holds its later steps), and no mandatory step shares an action with them. CONFIRM in game that he
-- offers it to the other classes; if he does not, the three steps move into Classes/Paladin.lua.
--
-- Automation note: a class file puts its training step AFTER its quest steps at the same trainer (turn-ins fire
-- as soon as the gossip opens). ud01-church-4 holds the generic quest actions at Sarvis and Elreth, ud01-aramis
-- the one at Aramis.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "ud-01-deathknell",
    title = { ru = "1-6 Мертвый Звон", en = "1-6 Deathknell" },
    zone = "Tirisfal Glades",
    levels = { 1, 6 },
    steps = {
        ------------------------------------------------------------------
        -- Crypt -> church (level 1)
        ------------------------------------------------------------------
        { id = "ud01-start", accept = 363, npc = 1568, at = { 1420, 30.22, 71.65 },
          note = { ru = "Выйдите из склепа: Гробовщик Мордо стоит прямо у выхода.",
                   en = "Leave the crypt: Undertaker Mordo stands right at the exit." } },
        { id = "ud01-363", turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.84, 66.2 },
          note = { ru = "Бегите по дороге на север к церкви: Жрец Тьмы Сарвис.",
                   en = "Run north along the path to the church: Shadow Priest Sarvis." } },
        -- level 2: 376 (accepted in the next step) requires it; the 10 zombies give it.
        { id = "ud01-zombies", complete = 364, level = 2, at = { 1420, 32.8, 63.3 },
          note = { ru = "Убейте 5 безмозглых и 5 жалких зомби сразу к северу и северо-востоку от церкви "
                       .. "(этого хватает на 2-й уровень).",
                   en = "Kill 5 Mindless and 5 Wretched Zombies just north and north-east of the church "
                       .. "(enough for level 2)." } },
        { id = "ud01-364", turnin = 364, accept = { 3901, 376 }, npc = { 1569, 1661 },
          at = { 1420, 30.85, 66.1 },
          note = { ru = "Сарвис: сдайте задание и возьмите следующее; Послушница Элрет рядом с ним — ещё одно. "
                       .. "Награда: плащ.",
                   en = "Sarvis: turn in and take his next quest; Novice Elreth next to him has another. "
                       .. "Reward: Battered Cloak." } },

        ------------------------------------------------------------------
        -- Loop 1 around the village (level 2-3)
        ------------------------------------------------------------------
        { id = "ud01-skeletons-bg", complete = 3901, bg = true, at = { 1420, 33.0, 61.7 },
          note = { ru = "Попутно бейте скелетов из Гремучей Клетки.",
                   en = "Kill Rattlecage Skeletons whenever you pass them." } },
        { id = "ud01-damned", complete = 376, at = { 1420, 30.5, 61.0 },
          note = { ru = "Молодые падальщики и сумеречные мыши к западу и северу от церкви: "
                       .. "6 лап падальщика и 6 крыльев сумеречной мыши.",
                   en = "Young Scavengers and Duskbats west and north of the church: "
                       .. "6 Scavenger Paws and 6 Duskbat Wings." } },
        { id = "ud01-skeletons", complete = 3901, at = { 1420, 33.0, 61.7 },
          note = { ru = "Добейте 8 скелетов на кладбище к северу от церкви.",
                   en = "Finish the 8 Rattlecage Skeletons in the graveyard north of the church." } },
        -- Trainer-hub gate (docs/dev/PLAN.md B.8): level 3 + 70%. The two turn-ins of ud01-church-4 are known
        -- XP (3901: 250, 376: 170 = 30% of level 3), so every class is level 4.0 at its trainer. Class quest
        -- XP is not counted on purpose.
        { id = "ud01-xp-4", level = { 3, 0.70 }, at = { 1420, 33.0, 61.7 },
          note = { ru = "Добейте скелетов и зомби до 3 ур. + 70% опыта: сдача двух заданий в церкви даст 4-й уровень, "
                       .. "а с ним новые умения у тренера вашего класса.",
                   en = "Grind skeletons and zombies to level 3 + 70% XP: the two turn-ins in the church then give "
                       .. "level 4, and with it new abilities at your class trainer." } },
        { id = "ud01-vendor", vendor = true, npc = 2115, at = { 1420, 32.29, 65.44 },
          note = { ru = "Продайте серый хлам Джошуа Киену (товары): обучение на 4-м уровне "
                       .. "стоит около 2 серебра.",
                   en = "Sell grey loot to Joshua Kien (General Supplies): level 4 training "
                       .. "costs about 2 silver." } },
        { id = "ud01-church-4", turnin = { 3901, 376 }, accept = 6395, npc = { 1569, 1661 },
          at = { 1420, 30.85, 66.1 },
          note = { ru = "В церкви: сдайте задания Сарвису и Элрет (у неё новое). Из наград берите доспехи, "
                       .. "которые носит ваш класс.",
                   en = "In the church: turn in to Sarvis and Elreth (she has a new quest). Rewards: pick the "
                       .. "armour your class can wear." } },
        -- CONFIRM: 98389 is offered by Aramis Hammerhand to every class (no class limit in the DB; he is the
        -- paladin trainer). Optional (docs/dev/PLAN.md E.6): a class that is not offered it loses nothing but
        -- the quest, see the header.
        { id = "ud01-aramis", accept = 98389, npc = 244808, optional = true, at = { 1420, 31.1, 66.41 },
          note = { ru = "Арамис в той же церкви: возьмите его задание (коконы в пещере пауков, по пути). Если "
                       .. "вашему классу он задание не предлагает, идите дальше: гайд сам пропустит его шаги.",
                   en = "Aramis Hammerhand in the same church: take his quest (the cocoons in the spider cave, "
                       .. "on the way). If he does not offer it to your class, move on: the guide skips its "
                       .. "steps by itself." } },
        { id = "ud01-arren-4", accept = { 3902, 380 }, npc = { 1740, 1570 }, at = { 1420, 31.9, 65.8 },
          note = { ru = "Стражник смерти Салтейн и Палач Аррен.",
                   en = "Deathguard Saltain and Executor Arren." } },

        ------------------------------------------------------------------
        -- Loop 2: boxes, Night Web's Hollow (level 4-5)
        ------------------------------------------------------------------
        { id = "ud01-boxes", complete = 3902, at = { 1420, 32.9, 63.9 },
          note = { ru = "Ящики со снаряжением среди зомби к северу и северо-востоку от церкви: "
                       .. "6 спасённых припасов.",
                   en = "Equipment Boxes among the zombies north and north-east of the church: "
                       .. "6 Scavenged Goods." } },
        { id = "ud01-spiders", complete = { [380] = { 1 } }, at = { 1420, 28.5, 57.6 },
          note = { ru = "Молодые пауки Ночной Паутины у входа в Логово Ночной Паутины (8).",
                   en = "Young Night Web Spiders around the entrance of Night Web's Hollow (8)." } },
        { id = "ud01-cave", complete = { [380] = { 2 } }, at = { 1420, 24.9, 59.6 },
          note = { ru = "В пещере: пауки Ночной Паутины (5). С заданием Арамиса заодно освобождайте Отрёкшихся "
                       .. "в коконах (атакуйте коконы). Если здоровья мало, быстрее всего умереть здесь "
                       .. "и воскреснуть у Целителя душ в деревне.",
                   en = "In the cave: Night Web Spiders (5). With the quest of Aramis, free the Webbed Forsaken "
                       .. "on the way (attack the cocoons). If you are low on health, dying here and taking "
                       .. "the Spirit Healer in the village is the fastest way back." } },
        { id = "ud01-cocoons", complete = 98389, optional = true, at = { 1420, 24.9, 59.6 },
          note = { ru = "Освободите 6 Отрёкшихся в коконах в той же пещере: атакуйте коконы (нет задания "
                       .. "Арамиса — идите дальше).",
                   en = "Free 6 Webbed Forsaken in the same cave: attack the cocoons (no quest of Aramis: "
                       .. "move on)." } },
        { id = "ud01-98389", turnin = 98389, npc = 244808, optional = true, at = { 1420, 31.1, 66.41 },
          note = { ru = "Арамис в церкви (нет его задания — идите дальше).",
                   en = "Aramis Hammerhand in the church (no quest of his: move on)." } },
        { id = "ud01-arren-5", turnin = { 3902, 380 }, accept = 381, npc = { 1740, 1570 }, at = { 1420, 31.9, 65.8 },
          note = { ru = "Салтейн и Аррен. Из наград берите доспехи, которые носит ваш класс.",
                   en = "Saltain and Arren. Rewards: pick the armour your class can wear." } },

        ------------------------------------------------------------------
        -- East: Scarlet camp, Samuel Fipps (level 5)
        ------------------------------------------------------------------
        { id = "ud01-scarlet-camp", complete = 381, at = { 1420, 37.5, 67.8 },
          note = { ru = "Лагерь Алого ордена к востоку от деревни: 12 алых нарукавных повязок. "
                       .. "Мевена Коргала пока не трогайте — он нужен для следующего задания. "
                       .. "Каннибализм на трупах людей восстанавливает здоровье без простоя.",
                   en = "Scarlet camp east of the village: 12 Scarlet Armbands. Leave Meven Korgal alone "
                       .. "for now - he is needed for the next quest. Cannibalize on humanoid corpses "
                       .. "restores your health without downtime." } },
        { id = "ud01-fipps", collect = { [16333] = 1 }, npc = 1919, at = { 1420, 36.68, 61.56 },
          note = { ru = "Убейте Сэмюэла Фиппса (5 ур.) к северу от лагеря и заберите его останки.",
                   en = "Kill Samuel Fipps (level 5) north of the camp and loot Samuel's Remains." } },
        { id = "ud01-marla-grave", complete = 6395, object = 178090, at = { 1420, 31.17, 65.08 },
          note = { ru = "Вернитесь в деревню и кликните Могилу Марлы у церкви.",
                   en = "Back in the village, click Marla's Grave by the church." } },
        { id = "ud01-6395", turnin = 6395, npc = 1661, at = { 1420, 30.86, 66.05 },
          note = { ru = "Послушница Элрет в церкви.", en = "Novice Elreth in the church." } },
        { id = "ud01-381", turnin = 381, accept = 382, npc = 1570, at = { 1420, 32.15, 66.01 },
          note = { ru = "Палач Аррен. Награда — оружие: берите то, которым владеет ваш класс (название не красное). "
                       .. "Тренеры Мертвого Звона учат до 6-го уровня: это последний визит к ним.",
                   en = "Executor Arren. The reward is a weapon: take the one your class can use (name not red). "
                       .. "The Deathknell trainers teach up to level 6: this is the last visit to them." } },
        { id = "ud01-korgal", complete = 382, npc = 1667, at = { 1420, 36.57, 68.54 },
          note = { ru = "Убейте Мевена Коргала (5 ур.) в центре лагеря Алого ордена и заберите документы.",
                   en = "Kill Meven Korgal (level 5) in the middle of the Scarlet camp and loot the documents." } },
        { id = "ud01-382", -- 383 and 96656 are carried: turned in at Brill (ud-02)
          turnin = 382, accept = { 383, 96656 }, npc = 1570, at = { 1420, 32.15, 66.01 },
          note = { ru = "Палач Аррен. 383 и 96656 сдаются в Брилле — держите их.",
                   en = "Executor Arren. 383 and 96656 are turned in at Brill: keep them." } },

        ------------------------------------------------------------------
        -- Leave Deathknell north-east (road to Brill)
        ------------------------------------------------------------------
        { id = "ud01-end", -- 8 is carried: turned in to Innkeeper Renee in Brill (ud-02)
          accept = 8, npc = 6784, at = { 1420, 38.23, 56.79 },
          note = { ru = "Кельвин Монтегю на дороге из Мертвого Звона на северо-восток: письмо сдаётся "
                       .. "в таверне Брилла. Его второе задание (дуэль) пропустите.",
                   en = "Calvin Montague on the road north-east out of Deathknell: the letter is turned in "
                       .. "at the Brill inn. Skip his follow-up (a duel)." } },
    },
})
