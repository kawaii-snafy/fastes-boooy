# Что подтверждается только в игре (`-- CONFIRM`)

Сгенерировано из комментариев `-- CONFIRM` модуля `addons/FastesBoooy_Guides` (фаза R, 77 пунктов). Текст пунктов —
комментарии кода как есть (английский). Подтвердили пункт в игре — уберите `CONFIRM` из комментария (и, если пункт
держится на поправке БД, поставьте ей `verified = true` в `tools/overrides/*.lua`); не подтвердился — исправьте шаг.
Пересобрать список: `python3 -I tools/gen_confirm_list.py > docs/routes/confirm-in-game.md`.

Общие вопросы плана (E.1-E.22: полёт таурена и скайборна в Оргриммар, тренеры паладина, таймер 812, опыт новых
квестов Forever, цена верховой езды) — `docs/dev/PLAN.md`, раздел E; что проверяется только в игре в самом аддоне —
конец [docs/VALIDATION.md](../VALIDATION.md).

## `Segments/Durotar/02_Durotar.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 37 | заголовок файла | The segment therefore takes 812, walks in to Kor'ghan for 813, kills the scorpids between the gate and Rhinag, and the city loop of h-12 hands both in. CONFIRM: the timer of 812 (45 minutes in Classic) and whether the sacs drop without 813 (then the Kor'ghan trip could be dropped). |
| 315 | `dur02-rhinag-accept` | (docs/dev/PLAN.md E.20): the timer of 812 (45 minutes in Classic) against the city loop of h-12. |
| 362 | `dur02-rhinag` | (docs/dev/PLAN.md E.20): the 812 timer. |

## `Segments/Mulgore/02_Mulgore.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 65 | `mul02-campfire` | The campfire objective of 96605 works as in Tirisfal (sit at the camp's fire). |
| 180 | `mul02-kyle` | Tender Strider Meat (item of 99411) drops from Adult Plainstriders (DB), Kyle at 46.3, 62.3. |
| 420 | `mul02-arrachea` | Arra'chea's DB spawn (51.2, 24.8) and that 776 is offered right after 775 in Forever. |

## `Segments/Mulgore/03_BarrensCrossing.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 127 | `mul03-org-gate` | The way from the Southfury bridge north along the river past Thunder Ridge (terrain). |

## `Segments/Tirisfal/01_Deathknell.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 30 | заголовок файла | If he does not offer it to a class, the guide passes the three steps by itself as soon as the next quest step is done (optional steps are forwarded, and a quest that was never taken no longer holds its later steps), and no mandatory step shares an action with them. CONFIRM in game that he offers it to the other classes; if he does not, the three steps move into Classes/Paladin.lua. |
| 98 | `ud01-aramis` | 98389 is offered by Aramis Hammerhand to every class (no class limit in the DB; he is the paladin trainer). |

## `Segments/Zephras/02_Zephras_9_13.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 268 | `sd02-wounded` | How a class without a healing spell completes "Injured Druids healed" (an interact objective in the DB; the reference guide is a druid's and heals them). |

## `Segments/Zephras/03_ThunderBluff.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 47 | `sd03-fly-org` | (docs/dev/PLAN.md E.2): the RestedXP Skyborne guide flies Thunder Bluff -> Orgrimmar right here (Skyborne start flight points are not in the DB). |

## `Segments/Shared/15_Barrens.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 110 | `h15-xr-arrive` | (docs/dev/PLAN.md E.21): the DB lists 844 as exclusive with the Tauren breadcrumbs 861 and 854; tools/overrides/shared.lua removes that (unverified). |

## `Races/Orc.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 59 | `orc-40-riding` | The price of riding and whether the wolf comes with the skill (docs/dev/PLAN.md E.9). |

## `Races/Tauren.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 40 | `tau-40d-riding` | The price of riding and whether the kodo comes with the skill (docs/dev/PLAN.md E.9). |
| 76 | `tau-40-riding` | The price of riding and whether the kodo comes with the skill (docs/dev/PLAN.md E.9). |

## `Races/Troll.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 68 | `tro-40-riding` | The price of riding and whether the raptor comes with the skill (docs/dev/PLAN.md E.9). |

## `Classes/Druid.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 449 | `dru-mul-train-10` | Gennia teaches Teleport: Moonglade at 10 (classic: any druid trainer; dru-mul-tb-train is the fallback) |
| 495 | `dru-mul-fly-tb` | Bunthen Plainswind's druid flight lands at Tal in Thunder Bluff (classic) |
| 516 | заголовок файла | Lunaclaw appears when the Cenarion Lunardust (item 15710) is used at the Moonkin Stone (classic quest; the snapshot has Lunaclaw and his spirit on the same spot, 41.96, 60.79). |

## `Classes/Hunter.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 10 | заголовок файла | Spell levels: classes.md 5.2 (the web list for Forever) for the key ones; the others are the trainer lists of the original game and only shown as text (the core never reads `spells`). CONFIRM in game. |
| 209 | `hun-dur-scorpid` | The beast tamed with the Taming Rod stays as the hunter's pet (as in the original game) |
| 372 | `hun-zep-crawler` | The three Zephras beasts have spawns right at Quel'ana in Valanaar (DB; fallback: south-west of the isle) |
| 545 | `hun-train-40` | Mail armour and Aspect of the Pack / Volley at 40 (spell levels of the original game) |
| 619 | `hun-8153-coursers` | Drop rate of the Perfect Courser Antler (not in the DB) |

## `Classes/Mage.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 11 | заголовок файла | Spell levels: classes.md 5.6 (the web list for Forever) for the key ones (4 Frostbolt, 6 Fire Blast, 8 Arcane Missiles, 10 Frost Nova / Polymorph, 14 Arcane Explosion, 20 Blizzard + Blink, 30 Ice Armor, 34 Mage Armor); the other ranks are the trainer lists of the original game and only shown as text (the core never reads `spells`). CONFIRM in game. |
| 494 | `mag-research` | 97286 has no objective (accept and turn in at once) and what it gives a mage |

## `Classes/Paladin.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 48 | заголовок файла | No class reward table (FastesBoooy.AddLibraryData({ rewards = { PALADIN = ... } })): the DB snapshot has no reward lists and the old route named the items without their index in the reward window; a wrong index would make the automation take the wrong item, no index only shows a hint. CONFIRM: the reward indexes of 3901, 376, 3902, 380, 381, 382, 426, 398, 358, 97558, 374 in game, then add the table. |
| 50 | заголовок файла | Training on 12-60 (CONFIRM, docs/dev/PLAN.md E.3: the paladin trainers Garen Largo 260093 in the Undercity and Alodan the Hopeful 246344 in Thunder Bluff are in the DB but not on the web; every step at them carries a CONFIRM comment and its note names Shari Stilwell in Brill as the fallback: the zeppelins of 22.0, 31.1 and 41.0 land ~200 yd south of her, the Undercity entrance is ~400 yd south): 14        Garen Largo (Undercity, War Quarter), after h13-uc-end (the gate h13-lvl-14 guarantees the level) 18        Alodan the Hopeful (Thunder Bluff, Pools of Vision: Zamah's cave), after h18-tb-zamah (gate h18-lvl-18) 20        Alodan, after h18-tb-2 (from Elder Rise over the central mesa to Spirit Rise; gate h18-lvl-20) 22        Alodan, after h-22-tb-start (Zamah hands out 1065 right after the turn-in of 1064: a training step between the two would be fast-forwarded by the automation) |
| 417 | `pal-train-14` | The paladin trainer Garen Largo in the Undercity (in the DB, not on the web) |
| 434 | `pal-train-18` | The paladin trainer Alodan the Hopeful in Thunder Bluff (in the DB, not on the web) |
| 456 | `pal-train-20` | Alodan the Hopeful (see pal-train-18) |
| 478 | `pal-train-22` | Alodan the Hopeful (see pal-train-18) |
| 569 | `pal-train-26` | Alodan the Hopeful (see pal-train-18) |
| 590 | `pal-train-30` | Alodan the Hopeful (see pal-train-18) |
| 616 | `pal-train-34` | Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill |
| 704 | `pal-train-40-garen` | Garen Largo (see pal-train-14) |
| 725 | `pal-train-44` | Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill |
| 757 | `pal-train-52` | Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill |
| 793 | `pal-train-58` | Garen Largo (see pal-train-14) |
| 822 | `pal-train-60` | Garen Largo (see pal-train-14); fallback Shari Stilwell in Brill |

## `Classes/Priest.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 10 | заголовок файла | Spell levels: classes.md 5.7 (the web list for Forever) for the key ones (4 Shadow Word: Pain, 10 Mind Blast, 20 Devouring Plague from the trainer, 32 Shadow Word: Death); the other ranks are the trainer lists of the original game and only shown as text (the core never reads `spells`). CONFIRM in game. |
| 318 | `pri-tir-train-12` | What 5658 teaches in Forever (classes.md 7: the Undead racial pair is Touch of Weakness + Dark Sacrifice) |
| 387 | `pri-staves` | Whether a Forever priest already knows Staves (classes.md 6.1: maces, daggers, staves can be learned) |
| 443 | `pri-5642` | What 5642 teaches in Forever (classes.md 7: the Troll racial pair is Hex of Weakness + Shadowguard) |
| 457 | `pri-5644` | What 5644 teaches in Forever (classes.md 7: Devouring Plague is a trainer spell there) |
| 610 | `pri-8255-coursers` | Drop rate of the Healthy Courser Gland (not in the DB) |

## `Classes/Rogue.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 11 | заголовок файла | Spell levels: classes.md 5.3 (the web list for Forever) for the key ones; the ranks of Sinister Strike, Backstab and Eviscerate and the other spells are the trainer lists of the original game and only shown as text (the core never reads `spells`). CONFIRM in game. |
| 202 | `rog-dur-train-10` | Dual Wield is a trainer spell at 10 (as in the original game) |
| 269 | `rog-tir-train-10` | Dual Wield is a trainer spell at 10 (as in the original game) |
| 393 | `rog-zep-train-10` | Dual Wield is a trainer spell at 10 (as in the original game) |
| 502 | `rog-22-fizzule` | The Flare Gun summons Fizzule and /salute makes him talk (as in the original game) |
| 508 | `rog-22-tower` | Gallywix's Lockbox needs Pick Lock (about 80 skill, classes.md section 7) |
| 559 | `rog-train-24` | Shank (Forever-new) is trained at 24 |
| 616 | `rog-train-44` | Shank rank 2 at 44 |

## `Classes/Shaman.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 12 | заголовок файла | Spell levels: classes.md 5.4 (the web list for Forever) for the key ones (Flametongue 10, Ghost Wolf 20, Totemic Recall / Call of the Elements 20, Totemic Projection 22, Windfury Weapon 30, Call of the Ancestors 30, Windfury Totem 32, mail 40); the others are the trainer lists of the original game and only shown as text (the core never reads `spells`). CONFIRM in game. |
| 205 | `sha-dur-1516` | 1516 has no prerequisite (snapshot: itself; tools/overrides/shaman.lua) |
| 307 | `sha-mul-1519` | 1519 has no prerequisite (snapshot: itself; tools/overrides/shaman.lua) |
| 399 | `…-telf` | Where the trail up to Telf Joolam starts (the snapshot has only his position) |
| 474 | `sha-zep-signet` | The Converts drop the Signet of Akir (the snapshot lists them among eight drop sources, no rate) |
| 635 | `sha-2h-maces` | Shamans learn two-handed maces / axes from weapon masters in Forever (a talent in the original game) |
| 648 | `sha-train-20` | Ghost Wolf at 20 and the Forever-new Totemic Recall / Call of the Elements at 20 (classes.md 5.4) |

## `Classes/Warlock.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 9 | заголовок файла | Spell levels: classes.md 5.5 (the web list for Forever) for the key ones; the other ranks are the trainer lists of the original game and only shown as text (the core never reads `spells`). CONFIRM in game. |
| 246 | `wlk-ganrul` | The Troll can take 1501 (web, classes.md section 7; the DB mask says Orc only) |
| 272 | `wlk-tablet` | The Troll can do 1501 / 1504 (see wlk-ganrul) |
| 504 | `wlk-avelina` | Avelina Lilly (L22, no faction in the DB) can be attacked and drops the heart; |
| 514 | `wlk-isaac` | Isaac Pearson (faction A in the DB) can be attacked inside Ratchet without the goblin guards joining |
| 612 | `wlk-38-spirit` | The Felhas Ruby is used on a slain Mana Eater (original game) |
| 625 | `wlk-train-40` | Incinerate (Forever-new) at 40 (classes.md 5.5); 4490 needs no item (none in the DB) |
| 658 | `wlk-41-demon` | Tabetha summons the Demon of the Orb when 4961 is accepted (original game) |
| 686 | `wlk-46-menara` | Noh'Orahil follows the felhound spirit (tools/overrides/warlock.lua) |

## `Classes/Warrior.lua`

| Строка | Шаг | Что проверить |
|---|---|---|
| 98 | заголовок файла | Class reward table: none. The DB has no reward lists, so the index of a warrior's choice is unknown; the notes of the class steps name the items instead (CONFIRM the indexes in game, then FastesBoooy.AddLibraryData). |
| 209 | `war-dur-uzzek` | The river crossing from the crocolisks to Far Watch Post (swim or bridge) and ~3 min there and back |
| 400 | `war-tir-ulag` | Ulag appears when the mausoleum trigger (object index 706178, outside the snapshot) is used |
| 542 | `war-zep-94003-turnin` | 94003 teaches Defensive Stance (Warcraft Tavern; the DB has no rewards), classes.md 8.4 item 6 |
| 607 | `war-1503` | The reward list of 1503 (and of 1822): then the class reward table can name the indexes |
| 757 | `war-30-affray` | The event (two waves, then Big Will) and the Intercept reward of 1719 in Forever |
| 865 | `war-8423` | The Fallen Hero offers 8423 without the breadcrumb 8417 (DB: 8417 is only its breadcrumb) |

