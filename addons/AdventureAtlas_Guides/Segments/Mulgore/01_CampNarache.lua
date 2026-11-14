-- AdventureAtlas_Guides / Segments / Mulgore / 01_CampNarache.lua
-- Segment "mul-01-camp-narache": Camp Narache and Red Cloud Mesa (Mulgore, uiMap 1412), levels 1-6, the start
-- zone of the Tauren. Class-neutral: every Tauren class walks it; what exists because of a class (the level-1
-- letter, the training visits, class quests, reward choices) is in Classes/<Class>.lua as shared inserts on the
-- anchors below.
-- Camp (747 + 752) -> Greatmother Hawkwind's well (753) -> camp -> mountain cougars on the way south -> Seer
-- Graytongue (757, 95805) -> Antur Fallow (1656) -> camp (750 > 780, 3376) -> Brambleblade Ravine (780, 757, 3376,
-- the map of 781) -> Ritual Fire (95805) -> camp (757, 780, 3376, 781 in; 763 and 96659 out, both lead to
-- Bloodhoof Village).
--
-- Anchors for the class files (docs/dev/PLAN.md C.2; level = validator level of the base profile before the step,
-- read with --levels; the hand-over docs/dev/handover/p1-mulgore.md has the measured list):
--   mul01-hunt    turn in 747 at Grull Hawkwind, the last step of the first camp visit: class letter, first
--                 training (the start-camp trainers stand around Chief Hawkwind; they teach to level 6 only).
--   mul01-ravine  the last step of the second camp visit (750 in, 780 + 3376 out), right before the ravine:
--                 training at 4, shaman 1519 (Meela Dawnstrider).
--   mul01-leave   the last step of the segment (757 / 781 in, 763 + 96659 out at Chief Hawkwind): training at 6,
--                 the last visit of the start-camp trainers.
-- Every step has an explicit id (prefix "mul01-"). No `reward` here: reward choices differ per class and live in
-- the class reward table of the class files.
--
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of the
-- objective mob spawns near the path. Mulgore's map changed in Forever: Classic guide coordinates do not apply.
-- Skipped: 5844 Welcome! (needs a gift voucher that a new character does not carry).
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "mul-01-camp-narache",
    title = {
        ru = "1-6 Лагерь Нараче, Плато Красных Облаков",
        en = "1-6 Camp Narache, Red Cloud Mesa",
    },
    zone = "Mulgore",
    levels = { 1, 6 },
    steps = {
        ------------------------------------------------------------------
        -- Camp Narache (level 1-3)
        ------------------------------------------------------------------
        { id = "mul01-start", accept = { 747, 752 }, npc = { 2980, 2981 }, at = { 1412, 44.20, 77.10 },
          note = {
              ru = "Старт. Grull Hawkwind и Chief Hawkwind в центре лагеря: возьмите оба задания.",
              en = "Start. Grull Hawkwind and Chief Hawkwind in the middle of the camp: take both quests.",
          } },
        { id = "mul01-striders-bg", complete = 747, bg = true, at = { 1412, 48.0, 79.5 },
          note = {
              ru = "По пути бейте равнинных долгоногов: 7 мяса и 7 перьев.",
              en = "Kill Plainstriders on the way: 7 meat and 7 feathers.",
          } },
        { id = "mul01-greatmother", turnin = 752, accept = 753, npc = 2991, at = { 1412, 48.82, 80.90 },
          note = {
              ru = "Greatmother Hawkwind у колодца к юго-востоку от лагеря.",
              en = "Greatmother Hawkwind at the well south-east of the camp.",
          } },
        { id = "mul01-pitcher", complete = 753, object = 2907, at = { 1412, 49.00, 81.20 },
          note = {
              ru = "Кувшин с водой стоит прямо у колодца.",
              en = "The Water Pitcher stands right at the well.",
          } },
        { id = "mul01-striders", complete = 747, at = { 1412, 48.0, 79.5 },
          note = {
              ru = "Добейте долгоногов вокруг колодца и по дороге в лагерь.",
              en = "Finish the Plainstriders around the well and on the way back to the camp.",
          } },
        { id = "mul01-chief-1", turnin = 753, accept = 755, npc = 2981, at = { 1412, 43.91, 76.70 },
          note = {
              ru = "Chief Hawkwind: сдайте кувшин.",
              en = "Chief Hawkwind: hand in the pitcher.",
          } },
        -- Anchor: the class letter and the first training (the start-camp trainers stand around the chief).
        { id = "mul01-hunt", turnin = 747, accept = 750, npc = 2980, at = { 1412, 44.50, 77.50 },
          note = {
              ru = "Grull Hawkwind: сдайте мясо и перья. Тренеры классов стоят вокруг вождя.",
              en = "Grull Hawkwind: hand in the meat and feathers. The class trainers stand around the chief.",
          } },

        ------------------------------------------------------------------
        -- South: mountain cougars, Seer Graytongue (level 3-4)
        ------------------------------------------------------------------
        { id = "mul01-cougars", complete = 750, at = { 1412, 44.5, 87.5 },
          note = {
              ru = "На юг к Seer Graytongue: по дороге 10 шкур горных пум.",
              en = "South towards Seer Graytongue: 10 Mountain Cougar Pelts on the way.",
          } },
        { id = "mul01-graytongue", turnin = 755, accept = { 757, 95805 }, npc = 2982, at = { 1412, 42.50, 90.10 },
          note = {
              ru = "Seer Graytongue на южном краю плато.",
              en = "Seer Graytongue at the south edge of the mesa.",
          } },
        { id = "mul01-antur", accept = 1656, npc = 6775, at = { 1412, 39.20, 81.20 },
          note = {
              ru = "Обратно на север мимо Antur Fallow (запад от лагеря): письмо сдаётся в деревне Кровавого Копыта.",
              en = "Back north past Antur Fallow (west of the camp): the letter is turned in at Bloodhoof Village.",
          } },
        -- Trainer-hub gate (docs/dev/PLAN.md B.8): every class trains at 4 on this camp visit, and the base profile
        -- arrives at 3.96 (about 1 kill). `at`: the Mountain Cougars (3) between Antur Fallow and the camp.
        { id = "mul01-lvl-4", level = 4, at = { 1412, 41.7, 83.1 },
          note = {
              ru = "4-й уровень перед лагерем: у тренеров новые умения. Не хватает - горные пумы по пути.",
              en = "Level 4 before the camp: the trainers have new ranks. Short: the Mountain Cougars on the way.",
          } },
        -- Anchor: training at 4; shaman 1519 (Meela Dawnstrider) before the ravine.
        { id = "mul01-ravine", turnin = 750, accept = { 780, 3376 }, npc = { 2980, 3209 }, at = { 1412, 44.30, 77.30 },
          note = {
              ru = "В лагере: Grull Hawkwind (кабаны) и Brave Windfeather (вождь Sharptusk). Дальше на восток, "
                  .. "в ущелье Колючего Клинка.",
              en = "In the camp: Grull Hawkwind (battleboars) and Brave Windfeather (Chief Sharptusk). Then east "
                  .. "into Brambleblade Ravine.",
          } },

        ------------------------------------------------------------------
        -- Brambleblade Ravine and the Ritual Fire (level 4-6)
        ------------------------------------------------------------------
        { id = "mul01-boars-bg", complete = 780, bg = true, at = { 1412, 52.5, 79.5 },
          note = {
              ru = "Кабаны по пути и в ущелье: 8 рыл и 8 окороков.",
              en = "Battleboars on the way and in the ravine: 8 snouts and 8 flanks.",
          } },
        { id = "mul01-belts", complete = 757, at = { 1412, 57.4, 78.0 },
          note = {
              ru = "Ущелье: 12 поясов с кабанов-людей Колючей Шкуры (воины и шаманы).",
              en = "The ravine: 12 Bristleback Belts from the Bristleback Quilboar and Shamans.",
          } },
        { id = "mul01-sharptusk", complete = 3376, at = { 1412, 61.00, 78.00 },
          note = {
              ru = "Chief Sharptusk Thornmantle в восточном конце ущелья.",
              en = "Chief Sharptusk Thornmantle at the east end of the ravine.",
          } },
        { id = "mul01-map", accept = 781, use = 4851, object = 3076, at = { 1412, 59.80, 82.20 },
          note = {
              ru = "Испачканная карта на земле в южной части ущелья: подберите и начните задание.",
              en = "The Dirt-stained Map on the ground in the south of the ravine: loot it and start the quest.",
          } },
        { id = "mul01-boars", complete = 780, at = { 1412, 55.5, 86.5 },
          note = {
              ru = "Добейте кабанов на выходе из ущелья, к югу.",
              en = "Finish the battleboars south of the ravine exit.",
          } },
        { id = "mul01-fire", turnin = 95805, object = 660739, at = { 1412, 56.60, 88.70 },
          note = {
              ru = "Ритуальный костёр к югу от ущелья.",
              en = "The Ritual Fire south of the ravine.",
          } },

        ------------------------------------------------------------------
        -- Camp Narache: last visit (level 6)
        ------------------------------------------------------------------
        { id = "mul01-grull-3", turnin = 780, npc = 2980, at = { 1412, 44.50, 77.50 },
          note = {
              ru = "Обратно в лагерь: Grull Hawkwind.",
              en = "Back to the camp: Grull Hawkwind.",
          } },
        { id = "mul01-windfeather", turnin = 3376, npc = 3209, at = { 1412, 44.20, 77.00 } },
        -- Anchor: training at 6 (the last start-camp trainer visit).
        { id = "mul01-leave", turnin = { 757, 781 }, accept = { 763, 96659 }, npc = 2981, at = { 1412, 43.91, 76.70 },
          note = {
              ru = "Chief Hawkwind: оба задания ведут в деревню Кровавого Копыта, на север по дороге.",
              en = "Chief Hawkwind: both quests lead to Bloodhoof Village, north along the road.",
          } },
    },
})
