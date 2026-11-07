-- FastesBoooy_UndeadPaladin / Segments / 01_Deathknell.lua
--
-- Segment ud-01-deathknell: character creation (Deathknell crypt) -> leaving Deathknell, levels 1-6.
-- Coordinates: Forever uiMap 1420 (Tirisfal Glades), map percent, from tools/data/forever_db.lua
-- (NPC/object spawns; centroids of the objective mob/object spawns for complete steps).
--
-- Hub plan (Forever DB): 363 > 364 > {98601, 3901, 376}; 98601 > 90902 > 91208;
-- 376 unlocks 3902, 380, 6395 and 98389; 91208/91209 need level 4; 380 > 381 > 382 > {383, 96656}.
-- Skipped: 590 (duel with Calvin Montague, little XP), other classes' scroll quests.
-- Carried into the next segment (turned in at Brill): 91209, 383, 96656, 8.
-- Hearthstone: not touched (starting bind).
--
-- Automation note: each train step comes right AFTER the quest steps at Aramis Hammerhand, and no
-- later step accepts anything from him. His turn-ins are automated as soon as his gossip opens, so a
-- train step placed before them would be fast-forwarded by the turn-in.
FastesBoooy.AddSegment("horde-undead-paladin", {
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
        { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.84, 66.2 },
          note = { ru = "Бегите по дороге на север к церкви: Жрец Тьмы Сарвис.",
                   en = "Run north along the path to the church: Shadow Priest Sarvis." } },
        -- level 2: 376 and 90902 (accepted in the next two steps) require level 2; the 10 zombies give it.
        { complete = 364, level = 2, at = { 1420, 32.8, 63.3 },
          note = { ru = "Убейте 5 безмозглых и 5 жалких зомби сразу к северу и северо-востоку от церкви "
                       .. "(этого хватает на 2-й уровень).",
                   en = "Kill 5 Mindless and 5 Wretched Zombies just north and north-east of the church "
                       .. "(enough for level 2)." } },
        { id = "ud01-364", turnin = 364, accept = { 98601, 3901, 376 }, npc = { 1569, 1661 },
          at = { 1420, 30.85, 66.1 },
          note = { ru = "Сарвис: сдайте и возьмите оба новых задания; Послушница Элрет рядом с ним — третье. "
                       .. "Награда: плащ.",
                   en = "Sarvis: turn in and take both new quests; Novice Elreth next to him has the third. "
                       .. "Reward: Battered Cloak." } },
        { id = "ud01-98601", -- WARN-OK: xp-unknown, Forever-new class quest (XP estimated offline)
          turnin = 98601, accept = 90902, npc = 244808, at = { 1420, 31.1, 66.41 }, use = 282423,
          note = { ru = "Прочитайте свиток (кнопка предмета) и поговорите с Арамисом — тренером паладинов "
                       .. "в церкви.",
                   en = "Read the Consecrated Scroll (item button), then talk to Aramis Hammerhand, "
                       .. "the paladin trainer in the church." } },
        { id = "ud01-train-1", train = true, npc = 244808, at = { 1420, 31.1, 66.41 },
          spells = { { ru = "Аура благочестия", en = "Devotion Aura" } },
          note = { ru = "Выучите Ауру благочестия (10 меди — хватает денег за зомби).",
                   en = "Train Devotion Aura (10 copper, paid by The Mindless Ones reward)." } },

        ------------------------------------------------------------------
        -- Loop 1 around the village (level 2-3)
        ------------------------------------------------------------------
        { complete = 90902, bg = true, at = { 1420, 31.6, 63.7 },
          note = { ru = "Свет небес на раненых стражников смерти, лежащих по всей деревне (5). "
                       .. "Лечите, когда мана полная.",
                   en = "Cast Holy Light on the Injured Deathguards lying around the village (5), "
                       .. "whenever your mana is full." } },
        { complete = 3901, bg = true, at = { 1420, 33.0, 61.7 },
          note = { ru = "Попутно бейте скелетов из Гремучей Клетки.",
                   en = "Kill Rattlecage Skeletons whenever you pass them." } },
        { complete = 376, at = { 1420, 30.5, 61.0 },
          note = { ru = "Молодые падальщики и сумеречные мыши к западу и северу от церкви: "
                       .. "6 лап падальщика и 6 крыльев сумеречной мыши.",
                   en = "Young Scavengers and Duskbats west and north of the church: "
                       .. "6 Scavenger Paws and 6 Duskbat Wings." } },
        { complete = 3901, at = { 1420, 33.0, 61.7 },
          note = { ru = "Добейте 8 скелетов на кладбище к северу от церкви.",
                   en = "Finish the 8 Rattlecage Skeletons in the graveyard north of the church." } },
        -- level 3 + 64%: 3901 (250) + 376 (170) + 90902 (~85 per reference) then reach level 4, which
        -- 91208/91209 and the Judgement training require (all at the same visit to the village).
        { id = "ud01-xp-4", level = { 3, 0.64 }, at = { 1420, 33.0, 61.7 },
          note = { ru = "Добейте скелетов и зомби до 3 ур. + 64% опыта: следующие сдачи дадут 4-й уровень "
                       .. "(он нужен для Правосудия и заданий паладина).",
                   en = "Grind skeletons and zombies to level 3 + 64% XP: the next turn-ins then give "
                       .. "level 4 (needed for Judgement and the next paladin quests)." } },
        { id = "ud01-vendor", vendor = true, npc = 2115, at = { 1420, 32.29, 65.44 },
          note = { ru = "Продайте серый хлам Джошуа Киену (товары): обучение на 4-м уровне "
                       .. "стоит около 2 серебра.",
                   en = "Sell grey loot to Joshua Kien (General Supplies): level 4 training "
                       .. "costs about 2 silver." } },
        { turnin = { 3901, 376 }, accept = 6395, npc = { 1569, 1661 }, at = { 1420, 30.85, 66.1 },
          note = { ru = "Награды: кольчужные поножи и кожаный пояс.",
                   en = "Rewards: Roamer's Leggings (mail) and Old Leather Belt." } },
        { id = "ud01-90902", -- WARN-OK: xp-unknown, Forever-new class quest (XP estimated offline)
          turnin = 90902, npc = 244808, at = { 1420, 31.1, 66.41 },
          note = { ru = "Арамис: сдайте задание — это 4-й уровень.",
                   en = "Aramis Hammerhand: turn in - this gives level 4." } },
        { id = "ud01-91209", -- 91209 is carried: turned in to Shari Stilwell in Brill (ud-02)
          accept = { 91208, 91209, 98389 }, npc = 244808, at = { 1420, 31.1, 66.41 },
          note = { ru = "Возьмите все три задания. 91209 ведёт к тренеру паладинов в Брилле — держите его.",
                   en = "Take all three quests. 91209 leads to the paladin trainer in Brill: keep it." } },
        { id = "ud01-train-4", train = true, npc = 244808, at = { 1420, 31.1, 66.41 },
          spells = { { ru = "Правосудие", en = "Judgement" },
                     { ru = "Благословение могущества", en = "Blessing of Might" } },
          note = { ru = "В Forever Правосудие не снимает печать: жмите его по откату. "
                       .. "Не хватает денег — сначала Правосудие.",
                   en = "In Forever Judgement does not consume the Seal: use it on cooldown. "
                       .. "Short on money: Judgement first." } },
        { accept = { 3902, 380 }, npc = { 1740, 1570 }, at = { 1420, 31.9, 65.8 },
          note = { ru = "Стражник смерти Салтейн и Палач Аррен.",
                   en = "Deathguard Saltain and Executor Arren." } },

        ------------------------------------------------------------------
        -- Loop 2: boxes, Frightened Paladin, Night Web's Hollow (level 4-5)
        ------------------------------------------------------------------
        { complete = 3902, at = { 1420, 32.9, 63.9 },
          note = { ru = "Ящики со снаряжением среди зомби к северу и северо-востоку от церкви: "
                       .. "6 спасённых припасов.",
                   en = "Equipment Boxes among the zombies north and north-east of the church: "
                       .. "6 Scavenged Goods." } },
        { id = "ud01-91208", complete = 91208, npc = 246143, at = { 1420, 27.69, 63.82 },
          note = { ru = "Испуганный паладин к западу от церкви: заговорите с ней, она нападёт — убейте её.",
                   en = "Frightened Paladin west of the church: talk to her, she turns hostile, kill her." } },
        { complete = { [380] = { 1 } }, at = { 1420, 28.5, 57.6 },
          note = { ru = "Молодые пауки Ночной Паутины у входа в Логово Ночной Паутины (8).",
                   en = "Young Night Web Spiders around the entrance of Night Web's Hollow (8)." } },
        { complete = { 98389, [380] = { 2 } }, at = { 1420, 24.9, 59.6 },
          note = { ru = "В пещере: пауки Ночной Паутины (5) и 6 Отрёкшихся в коконах — атакуйте коконы, "
                       .. "чтобы освободить их. Если здоровья мало, быстрее всего умереть здесь "
                       .. "и воскреснуть у Целителя душ в деревне.",
                   en = "In the cave: Night Web Spiders (5) and 6 Webbed Forsaken - attack the cocoons "
                       .. "to free them. If you are low on health, dying here and taking the Spirit "
                       .. "Healer in the village is the fastest way back." } },
        { turnin = { 91208, 98389 }, npc = 244808, at = { 1420, 31.1, 66.41 }, -- WARN-OK: xp-unknown, Forever-new
          note = { ru = "Арамис в церкви.", en = "Aramis Hammerhand in the church." } },
        { turnin = { 3902, 380 }, accept = 381, npc = { 1740, 1570 }, at = { 1420, 31.9, 65.8 },
          note = { ru = "Награды: кольчужные наручи и кольчужный жилет.",
                   en = "Rewards: Rustmetal Bracers and Rugged Mail Vest (mail)." } },

        ------------------------------------------------------------------
        -- East: Scarlet camp, Samuel Fipps (level 5)
        ------------------------------------------------------------------
        { complete = 381, at = { 1420, 37.5, 67.8 },
          note = { ru = "Лагерь Алого ордена к востоку от деревни: 12 алых нарукавных повязок. "
                       .. "Мевена Коргала пока не трогайте — он нужен для следующего задания. "
                       .. "Каннибализм на трупах людей восстанавливает здоровье и ману.",
                   en = "Scarlet camp east of the village: 12 Scarlet Armbands. Leave Meven Korgal alone "
                       .. "for now - he is needed for the next quest. Cannibalize on humanoid corpses "
                       .. "restores health and mana." } },
        { collect = { [16333] = 1 }, npc = 1919, at = { 1420, 36.68, 61.56 },
          note = { ru = "Убейте Сэмюэла Фиппса (5 ур.) к северу от лагеря и заберите его останки.",
                   en = "Kill Samuel Fipps (level 5) north of the camp and loot Samuel's Remains." } },
        { complete = 6395, object = 178090, at = { 1420, 31.17, 65.08 },
          note = { ru = "Вернитесь в деревню и кликните Могилу Марлы у церкви.",
                   en = "Back in the village, click Marla's Grave by the church." } },
        { turnin = 6395, npc = 1661, at = { 1420, 30.86, 66.05 } },
        { id = "ud01-381", turnin = 381, accept = 382, npc = 1570, at = { 1420, 32.15, 66.01 },
          note = { ru = "Награда: двуручный меч, если навык позволяет (название не красное), "
                       .. "иначе одноручная булава.",
                   en = "Reward: Forsaken Bastard Sword (two-hander) if your skills allow it (name not red), "
                       .. "otherwise Forsaken Maul." } },
        { complete = 382, npc = 1667, at = { 1420, 36.57, 68.54 },
          note = { ru = "Убейте Мевена Коргала (5 ур.) в центре лагеря Алого ордена и заберите документы.",
                   en = "Kill Meven Korgal (level 5) in the middle of the Scarlet camp and loot the documents." } },
        { id = "ud01-382", -- 383 and 96656 are carried: turned in at Brill (ud-02)
          turnin = 382, accept = { 383, 96656 }, npc = 1570, at = { 1420, 32.15, 66.01 },
          note = { ru = "Награда: щит. 383 и 96656 сдаются в Брилле — держите их.",
                   en = "Reward: Deathguard Buckler. 383 and 96656 are turned in at Brill: keep them." } },

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
