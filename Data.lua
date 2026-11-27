local _, ns = ...

-- Game data for the Azeroth Commerce Authority (Alliance) and Durotar Supply and Logistics (Horde),
-- the WoW Forever crafting factions. Numbers from the game where known, else from player guides
-- (Mobalytics "Merchant's Favor, Waylaid Crates & Craftsman's Writ Guide", wow.gg, Warcraft Wiki);
-- what the addon sees at turn-ins (Learn.lua) replaces the guesses.

ns.FAVOR_CURRENCY = 3402 -- Merchant's Favor
ns.FACTION_NAMES = { Alliance = "Azeroth Commerce Authority", Horde = "Durotar Supply and Logistics" }
-- By ID (Forever's Faction table on wago.tools), so other languages find them too (2026-11-27: the names above
-- are English and the game gives the client's own).
ns.FACTION_IDS = { Alliance = 2586, Horde = 2587 }
ns.HUBS = {
  Alliance = "Three Corners, Redridge Mountains (10, 72)",
  Horde = "west of the Crossroads, The Barrens (49, 29)",
}
-- The hubs by area ID (Forever's AreaTable: Three Corners 1002 in Redridge Mountains 44, The Crossroads 380 in The
-- Barrens 17), so the place names come from the game in the client's language (2026-11-27, translations).
ns.HUB_AREAS = {
  Alliance = { place = 1002, placeName = "Three Corners", zone = 44, zoneName = "Redridge Mountains", spot = "10, 72" },
  Horde = { place = 380, placeName = "the Crossroads", zone = 17, zoneName = "The Barrens", spot = "49, 29", west = true },
}

-- Legacy talents: Performance Bonus (15% chance of 100% more Favor from a crate) and Diplomat (+10% reputation).
ns.PERFORMANCE_BONUS_CHANCE = 0.15
ns.DIPLOMAT_BONUS = 0.10

-- Craftsman's Writs: [writ item ID] = { item ID to deliver (false: found by name in game), count, English name }
--
-- Classic (Argent Dawn, Light's Hope Chapel): item and count from each writ quest's
-- "Deliver 20 Major Healing Potions and the Craftsman's Writ" (classicdb, quests 9178-9206). No Commerce
-- Authority reputation; priced only.
-- WoW Forever ("Craftsman's Writ: <item>", items 264011-264160, quest = item - 169800): names from the
-- client's quest data; the one quest objective seen asks for 1 item, so the count is 1 unless the quest
-- log says otherwise (ns.WritCount).
ns.WRITS = {
  [22600] = { 12643, 120, "Dense Weightstone" },
  [22601] = { 12422, 3, "Imperial Plate Chest" },
  [22602] = { 12792, 3, "Volcanic Hammer" },
  [22603] = { 12775, 3, "Huge Thorium Battleaxe" },
  [22604] = { 12417, 3, "Radiant Circlet" },
  [22605] = { 15086, 10, "Wicked Leather Headband" },
  [22606] = { 15564, 25, "Rugged Armor Kit" },
  [22607] = { 15088, 9, "Wicked Leather Belt" },
  [22608] = { 15095, 4, "Runic Leather Pants" },
  [22609] = { 14104, 6, "Brightcloth Pants" },
  [22610] = { 13864, 8, "Runecloth Boots" },
  [22611] = { 14046, 8, "Runecloth Bag" },
  [22612] = { 13858, 8, "Runecloth Robe" },
  [22613] = { 10646, 20, "Goblin Sapper Charge" },
  [22614] = { 15993, 20, "Thorium Grenade" },
  [22615] = { 10725, 4, "Gnomish Battle Chicken" },
  [22616] = { 16000, 14, "Thorium Tube" },
  [22617] = { 13444, 10, "Major Mana Potion" },
  [22618] = { 13446, 20, "Major Healing Potion" },
  [22620] = { 13461, 15, "Greater Arcane Protection Potion" },
  [22621] = { 13506, 1, "Flask of Petrification" },
  [22622] = { 13422, 40, "Stonescale Eel" },
  [22623] = { 13890, 30, "Plated Armorfish" },
  [22624] = { 13757, 30, "Lightning Eel" },
  -- WoW Forever
  [264011] = { 3391, 1, "Elixir of Ogre's Strength" },
  [264012] = { 3383, 1, "Elixir of Wisdom" },
  [264013] = { 3385, 1, "Lesser Mana Potion" },
  [264014] = { 6048, 1, "Shadow Protection Potion" },
  [264015] = { 5634, 1, "Free Action Potion" },
  [264016] = { 3390, 1, "Elixir of Lesser Agility" },
  [264017] = { 3388, 1, "Lesser Troll's Blood Elixir" },
  [264018] = { 3389, 1, "Elixir of Defense" },
  [264019] = { 5996, 1, "Draught of Water Breathing" },
  [264020] = { 5540, 1, "Pearl-Handled Dagger" },
  [264021] = { 11128, 1, "Golden Rod" },
  [264022] = { 5541, 1, "Iridescent Hammer" },
  [264023] = { 15869, 1, "Silver Skeleton Key" },
  [264024] = { 3491, 1, "Heavy Bronze Mace" },
  [264025] = { 2865, 1, "Rough Bronze Leggings" },
  [264026] = { 3485, 1, "Green Iron Gauntlets" },
  [264027] = { 3848, 1, "Big Bronze Knife" },
  [264028] = { 3484, 1, "Green Iron Boots" },
  [264029] = { 5507, 1, "Ornate Spyglass" },
  [264030] = { 4384, 1, "Explosive Sheep" },
  [264031] = { 4383, 1, "Moonsight Rifle" },
  [264032] = { 4381, 1, "Minor Recombobulator" },
  [264033] = { 6712, 1, "Practice Lock" },
  [264034] = { 4373, 1, "Shadow Goggles" },
  [264035] = { 7506, 1, "Gnomish Universal Remote" },
  [264036] = { 4380, 1, "Big Bronze Bomb" },
  [264037] = { 8069, 1, "Crafted Solid Shot" },
  [264038] = { 18662, 1, "Heavy Leather Ball" },
  [264039] = { 5958, 1, "Fine Leather Pants" },
  [264040] = { 7349, 1, "Herbalist's Gloves" },
  [264041] = { 2317, 1, "Dark Leather Tunic" },
  [264042] = { 7358, 1, "Pilferer's Gloves" },
  [264043] = { 7371, 1, "Heavy Quiver" },
  [264044] = { 4252, 1, "Dark Leather Shoulders" },
  [264045] = { 4254, 1, "Barbaric Gloves" },
  [264046] = { 7284, 1, "Red Whelp Gloves" },
  [264047] = { 5766, 1, "Lesser Wizard's Robe" },
  [264048] = { 6263, 1, "Blue Overalls" },
  [264049] = { 7048, 1, "Azure Silk Hood" },
  [264050] = { 4245, 1, "Small Silk Pack" },
  [264051] = { 4317, 1, "Phoenix Pants" },
  [264052] = { 4313, 1, "Red Woolen Boots" },
  [264053] = { 10048, 1, "Colorful Kilt" },
  [264054] = { 6264, 1, "Greater Adept's Robe" },
  [264055] = { 4321, 1, "Spider Silk Slippers" },
  [264056] = { 6050, 1, "Frost Protection Potion" },
  [264057] = { 3823, 1, "Lesser Invisibility Potion" },
  [264058] = { 4623, 1, "Lesser Stoneshield Potion" },
  [264059] = { 6052, 1, "Nature Protection Potion" },
  [264060] = { 10592, 1, "Catseye Draught" },
  [264061] = { 5633, 1, "Great Rage Potion" },
  [264062] = { 3827, 1, "Mana Potion" },
  [264063] = { 6049, 1, "Fire Protection Potion" },
  [264064] = { 3824, 1, "Shadow Oil" },
  [264065] = { 9061, 1, "Goblin Rocket Fuel" },
  [264066] = { 8949, 1, "Elixir of Agility" },
  [264067] = { 9144, 1, "Wildvine Potion" },
  [264068] = { 7922, 1, "Steel Plate Helm" },
  [264069] = { 9060, 1, "Inlaid Mithril Cylinder" },
  [264070] = { 6041, 1, "Steel Weapon Chain" },
  [264071] = { 7928, 1, "Ornate Mithril Shoulders" },
  [264072] = { 7942, 1, "Blue Glittering Axe" },
  [264073] = { 3853, 1, "Moonsteel Broadsword" },
  [264074] = { 3837, 1, "Golden Scale Coif" },
  [264075] = { 7964, 1, "Solid Sharpening Stone" },
  [264076] = { 7943, 1, "Wicked Mithril Blade" },
  [264077] = { 11144, 1, "Truesilver Rod" },
  [264078] = { 9366, 1, "Golden Scale Gauntlets" },
  [264079] = { 7941, 1, "Heavy Mithril Axe" },
  [264080] = { 4396, 1, "Mechanical Dragonling" },
  [264081] = { 4392, 1, "Advanced Target Dummy" },
  [264082] = { 4393, 1, "Craftsman's Monocle" },
  [264083] = { 4395, 1, "Goblin Land Mine" },
  [264084] = { 10501, 1, "Catseye Ultra Goggles" },
  [264085] = { 10560, 1, "Unstable Trigger" },
  [264086] = { 4852, 1, "Flash Bomb" },
  [264087] = { 10500, 1, "Fire Goggles" },
  [264088] = { 10514, 1, "Mithril Frag Bomb" },
  [264089] = { 10498, 1, "Gyromatic Micro-Adjuster" }, -- the item is spelled "Micro-Adjustor"
  [264090] = { 11590, 1, "Mechanical Repair Kit" },
  [264091] = { 16005, 1, "Dark Iron Bomb" },
  [264092] = { 8174, 1, "Comfortable Leather Hat" },
  [264093] = { 5965, 1, "Guardian Cloak" },
  [264094] = { 7378, 1, "Dusky Bracers" },
  [264095] = { 8214, 1, "Wild Leather Helmet" },
  [264096] = { 8210, 1, "Wild Leather Shoulders" },
  [264097] = { 8217, 1, "Quickdraw Quiver" },
  [264098] = { 7391, 1, "Swift Boots" },
  [264099] = { 8192, 1, "Nightscape Shoulders" },
  [264100] = { 8201, 1, "Big Voodoo Mask" },
  [264101] = { 8200, 1, "Big Voodoo Robe" },
  [264102] = { 8189, 1, "Turtle Scale Breastplate" },
  [264103] = { 8218, 1, "Thick Leather Ammo Pouch" },
  [264104] = { 10050, 1, "Mageweave Bag" },
  [264105] = { 10023, 1, "Shadoweave Gloves" },
  [264106] = { 7063, 1, "Crimson Silk Robe" },
  [264107] = { 10004, 1, "Shadoweave Robe" },
  [264108] = { 22246, 1, "Enchanted Mageweave Pouch" },
  [264109] = { 4329, 1, "Star Belt" },
  [264110] = { 9998, 1, "Black Mageweave Vest" },
  [264111] = { 10009, 1, "Red Mageweave Pants" },
  [264112] = { 10052, 1, "Orange Martial Shirt" },
  [264113] = { 10008, 1, "White Bandit Mask" },
  [264114] = { 10042, 1, "Cindercloth Robe" },
  [264115] = { 7061, 1, "Earthen Silk Belt" },
  [264116] = { false, 1, "Potion of Demonslaying" },
  [264117] = { 12190, 1, "Dreamless Sleep Potion" },
  [264118] = { 13457, 1, "Greater Fire Protection Potion" },
  [264119] = { 9233, 1, "Draught of Detect Demon" },
  [264120] = { 9088, 1, "Gift of Arthas" },
  [264121] = { 13513, 1, "Flask of Chromatic Resistance" },
  [264122] = { 3387, 1, "Limited Invulnerability Potion" },
  [264123] = { 18253, 1, "Major Rejuvenation Potion" },
  [264124] = { 246948, 1, "Distilled Firewater" },
  [264125] = { 12417, 1, "Radiant Circlet" },
  [264126] = { 12416, 1, "Radiant Belt" },
  [264127] = { 7929, 1, "Orcish War Leggings" },
  [264128] = { 7969, 1, "Mithril Spurs" },
  [264129] = { 12422, 1, "Imperial Plate Chest" },
  [264130] = { 20549, 1, "Darkrune Gauntlets" },
  [264131] = { 12775, 1, "Huge Thorium Battleaxe" },
  [264132] = { 15872, 1, "Arcanite Skeleton Key" },
  [264133] = { 7947, 1, "Ebon Shiv" },
  [264134] = { 16023, 1, "Masterwork Target Dummy" },
  [264135] = { 10504, 1, "Green Lens" },
  [264136] = { 15996, 1, "Lifelike Mechanical Toad" },
  [264137] = { 18645, 1, "Gnomish Alarm-O-Bot" },
  [264138] = { 18587, 1, "Goblin Jumper Cables XL" },
  [264139] = { 18232, 1, "Field Repair Bot 74A" },
  [264140] = { 18631, 1, "Truesilver Transformer" },
  [264141] = { 10548, 1, "Sniper Scope" },
  [264142] = { 21277, 1, "Tranquil Mechanical Yeti" },
  [264143] = { 15087, 1, "Wicked Leather Pants" },
  [264144] = { 18258, 1, "Gordok Ogre Suit" },
  [264145] = { 15053, 1, "Volcanic Breastplate" },
  [264146] = { 15094, 1, "Runic Leather Headband" },
  [264147] = { 15084, 1, "Wicked Leather Bracers" },
  [264148] = { 15075, 1, "Chimeric Vest" },
  [264149] = { 15080, 1, "Heavy Scorpid Helm" },
  [264150] = { 15092, 1, "Runic Leather Bracers" },
  [264151] = { 15071, 1, "Frostsaber Boots" },
  [264152] = { 14130, 1, "Wizardweave Turban" },
  [264153] = { 14046, 1, "Runecloth Bag" },
  [264154] = { 13864, 1, "Runecloth Boots" },
  [264155] = { 10036, 1, "Tuxedo Jacket" },
  [264156] = { 14108, 1, "Felcloth Boots" },
  [264157] = { 22251, 1, "Cenarion Herb Bag" },
  [264158] = { 10025, 1, "Shadoweave Mask" },
  [264159] = { 14141, 1, "Ghostweave Vest" },
  [264160] = { 21340, 1, "Soul Pouch" },
}

ns.FOREVER_WRIT_FIRST, ns.FOREVER_WRIT_LAST = 264011, 264160
ns.FOREVER_QUEST_OFFSET = 169800
-- A writ's quest is its item ID - 169800, except these ([writ item ID] = quest ID).
ns.WRIT_QUEST_EXCEPTIONS = { [264011] = 94004 }
local writForQuest = {}
for writID, questID in pairs(ns.WRIT_QUEST_EXCEPTIONS) do
  writForQuest[questID] = writID
end

-- The quest a Forever writ starts, or nil for other items.
function ns.WritQuestID(writID)
  if not writID or writID < ns.FOREVER_WRIT_FIRST or writID > ns.FOREVER_WRIT_LAST then
    return nil
  end
  return ns.WRIT_QUEST_EXCEPTIONS[writID] or writID - ns.FOREVER_QUEST_OFFSET
end

-- The writ a quest belongs to, or nil.
function ns.WritForQuest(questID)
  if not questID then
    return nil
  end
  local writID = writForQuest[questID] or questID + ns.FOREVER_QUEST_OFFSET
  if ns.WRIT_QUEST_EXCEPTIONS[writID] and not writForQuest[questID] then
    return nil -- that ID's writ uses another quest
  end
  if writID >= ns.FOREVER_WRIT_FIRST and writID <= ns.FOREVER_WRIT_LAST then
    return writID
  end
end

-- Who takes each writ ("the customer"): [writ item ID] = { NPC name, uiMapID, x, y (0-100) }. Each writ goes to
-- its own NPC somewhere in the world, not to the trade hub; some NPCs take several writs (the writ quest's turn-in
-- NPC and that NPC's spot). 133 of the 150 writs; rows marked "(added by hand)" are kept when the table is rebuilt.
-- The other 17 (Artisan writs) are learned at the first turn-in (Learn.lua).
ns.WRIT_CUSTOMERS = {
  [264011] = { "Sos'mol", 1416, 38.4, 61.1 }, -- Elixir of Ogre's Strength: Alterac Mountains
  [264012] = { "Muggol Breezebeard", 1417, 48.7, 55.8 }, -- Elixir of Wisdom: Arathi Highlands
  [264013] = { "Ash'alari", 1440, 60.2, 72.7 }, -- Lesser Mana Potion: Ashenvale
  [264014] = { "Kzixx", 1431, 81.8, 19.8 }, -- Shadow Protection Potion: Duskwood
  [264015] = { "Webbed Mudsnout Gnoll", 1424, 62.4, 69.2 }, -- Free Action Potion: Hillsbrad Foothills
  [264016] = { "Ziz Fizziks", 1442, 59.0, 62.6 }, -- Elixir of Lesser Agility: Stonetalon Mountains
  [264017] = { "Short John Mithril", 1434, 29.6, 47.4 }, -- Lesser Troll's Blood Elixir: Stranglethorn Vale
  [264018] = { "Rizzle Brassbolts", 1441, 77.2, 77.4 }, -- Elixir of Defense: Thousand Needles
  [264019] = { "Kixxle", 1437, 50.2, 37.7 }, -- Draught of Water Breathing: Wetlands
  [264020] = { "Alan Sneeks", 1416, 30.6, 61.0 }, -- Pearl-Handled Dagger: Alterac Mountains
  [264021] = { "Muggol Breezebeard", 1417, 48.7, 55.8 }, -- Golden Rod: Arathi Highlands
  [264022] = { "Cowardly Peon", 1440, 78.5, 68.9 }, -- Iridescent Hammer: Ashenvale
  [264023] = { "Battered Trunk", 1431, 26.2, 36.2 }, -- Silver Skeleton Key: Duskwood (added by hand; an object, not an NPC)
  [264024] = { "Gorgrash", 1424, 80.0, 48.5 }, -- Heavy Bronze Mace: Hillsbrad Foothills
  [264025] = { "Ziz Fizziks", 1442, 59.0, 62.6 }, -- Rough Bronze Leggings: Stonetalon Mountains
  [264026] = { "\"Sea Wolf\" MacKinley", 1434, 27.8, 77.1 }, -- Green Iron Gauntlets: Stranglethorn Vale
  [264027] = { "\"Plucky\" Johnson", 1441, 79.6, 75.6 }, -- Big Bronze Knife: Thousand Needles
  [264028] = { "Kixxle", 1437, 50.2, 37.7 }, -- Green Iron Boots: Wetlands
  [264029] = { "Alan Sneeks", 1416, 30.6, 61.0 }, -- Ornate Spyglass: Alterac Mountains
  [264030] = { "Alyce", 1417, 34.0, 23.3 }, -- Explosive Sheep: Arathi Highlands
  [264031] = { "Grembly", 1440, 82.1, 51.0 }, -- Moonsight Rifle: Ashenvale
  [264032] = { "Kzixx", 1431, 81.8, 19.8 }, -- Minor Recombobulator: Duskwood
  [264033] = { "Gorgrash", 1424, 80.0, 48.5 }, -- Practice Lock: Hillsbrad Foothills
  [264034] = { "Ziz Fizziks", 1442, 59.0, 62.6 }, -- Shadow Goggles: Stonetalon Mountains
  [264035] = { "Scooty", 1434, 27.6, 77.5 }, -- Gnomish Universal Remote: Stranglethorn Vale
  [264036] = { "Razzeric", 1441, 80.3, 76.1 }, -- Big Bronze Bomb: Thousand Needles
  [264037] = { "Kixxle", 1437, 50.2, 37.7 }, -- Crafted Solid Shot: Wetlands
  [264038] = { "Sos'mol", 1416, 38.4, 61.1 }, -- Heavy Leather Ball: Alterac Mountains
  [264039] = { "Alyce", 1417, 34.0, 23.3 }, -- Fine Leather Pants: Arathi Highlands
  [264040] = { "Murache", 1440, 64.8, 80.2 }, -- Herbalist's Gloves: Ashenvale
  [264041] = { "Kzixx", 1431, 81.8, 19.8 }, -- Dark Leather Tunic: Duskwood
  [264042] = { "Kris Legace", 1424, 80.1, 38.9 }, -- Pilferer's Gloves: Hillsbrad Foothills
  [264043] = { "Ziz Fizziks", 1442, 59.0, 62.6 }, -- Heavy Quiver: Stonetalon Mountains
  [264044] = { "Narkk", 1434, 28.1, 74.4 }, -- Dark Leather Shoulders: Stranglethorn Vale
  [264045] = { "Goblin Pit Boss", 1441, 79.9, 76.7 }, -- Barbaric Gloves: Thousand Needles
  [264046] = { "Kixxle", 1437, 50.2, 37.7 }, -- Red Whelp Gloves: Wetlands
  [264047] = { "Alan Sneeks", 1416, 30.6, 61.0 }, -- Lesser Wizard's Robe: Alterac Mountains
  [264048] = { "Alyce", 1417, 34.0, 23.3 }, -- Blue Overalls: Arathi Highlands
  [264049] = { "Cowardly Peon", 1440, 78.5, 68.9 }, -- Azure Silk Hood: Ashenvale
  [264050] = { "Kzixx", 1431, 81.8, 19.8 }, -- Small Silk Pack: Duskwood
  [264051] = { "Bath'rah the Windwatcher", 1416, 80.5, 66.9 }, -- Phoenix Pants: Alterac Mountains
  [264052] = { "Ziz Fizziks", 1442, 59.0, 62.6 }, -- Red Woolen Boots: Stonetalon Mountains
  [264053] = { "Hekshi", 1434, 50.7, 19.3 }, -- Colorful Kilt: Stranglethorn Vale
  [264054] = { "Magus Tirth", 1441, 78.3, 75.7 }, -- Greater Adept's Robe: Thousand Needles
  [264055] = { "Kixxle", 1437, 50.2, 37.7 }, -- Spider Silk Slippers: Wetlands
  [264056] = { "Lotwil Veriatus", 1418, 25.9, 44.9 }, -- Frost Protection Potion: Badlands
  [264057] = { "Centaur Pariah", 1443, 50.4, 86.7 }, -- Lesser Invisibility Potion: Desolace
  [264058] = { "Mudcrush Durtfeet", 1445, 35.1, 38.3 }, -- Lesser Stoneshield Potion: Dustwallow Marsh
  [264059] = { "Greta Mosshoof", 1448, 51.2, 82.1 }, -- Nature Protection Potion: Felwood
  [264060] = { "Scout Raroul", 1444, 72.4, 52.5 }, -- Catseye Draught: Feralas
  [264061] = { "Dendrite Starblaze", 1450, 56.2, 30.6 }, -- Great Rage Potion: Moonglade
  [264062] = { "Spek", 2548, 76.9, 54.1 }, -- Mana Potion: Riverglades
  [264063] = { "Durganon", 1427, 41.1, 58.3 }, -- Fire Protection Potion: Searing Gorge
  [264064] = { "Mukomonji", 1435, 62.4, 52.9 }, -- Shadow Oil: Swamp of Sorrows
  [264065] = { "Alchemist Pestlezugg", 1446, 50.9, 27.0 }, -- Goblin Rocket Fuel: Tanaris
  [264066] = { "Juo", 1425, 80.1, 55.4 }, -- Elixir of Agility: The Hinterlands
  [264067] = { "Spark Nilminer", 1449, 43.5, 7.4 }, -- Wildvine Potion: Un'Goro Crater
  [264068] = { "Furious Shadowforge Digger", 1418, 44.3, 11.4 }, -- Steel Plate Helm: Badlands
  [264069] = { "Bibbly F'utzbuckle", 1443, 62.3, 39.0 }, -- Inlaid Mithril Cylinder: Desolace
  [264070] = { "Ugbert", 1445, 41.0, 27.9 }, -- Steel Weapon Chain: Dustwallow Marsh
  [264071] = { "Taronn Redfeather", 1448, 50.9, 81.6 }, -- Ornate Mithril Shoulders: Felwood
  [264072] = { "Scout Raroul", 1444, 72.4, 52.5 }, -- Blue Glittering Axe: Feralas
  [264073] = { "Meliri", 1450, 51.2, 42.3 }, -- Moonsteel Broadsword: Moonglade
  [264074] = { "Spek", 2548, 76.9, 54.1 }, -- Golden Scale Coif: Riverglades
  [264075] = { "Master Smith Burninate", 1427, 38.8, 28.5 }, -- Solid Sharpening Stone: Searing Gorge
  [264076] = { "Mukomonji", 1435, 62.4, 52.9 }, -- Wicked Mithril Blade: Swamp of Sorrows
  [264077] = { "Spigot Operator Luglunket", 1446, 52.5, 28.4 }, -- Truesilver Rod: Tanaris
  [264078] = { "Gilveradin Sunchaser", 1425, 26.7, 48.6 }, -- Golden Scale Gauntlets: The Hinterlands
  [264079] = { "Torwa Pathfinder", 1449, 71.6, 76.0 }, -- Heavy Mithril Axe: Un'Goro Crater
  [264080] = { "Garyanne Fleezlebop", 1418, 67.7, 51.7 }, -- Mechanical Dragonling: Badlands
  [264081] = { "Bibbly F'utzbuckle", 1443, 62.3, 39.0 }, -- Advanced Target Dummy: Desolace
  [264082] = { "The Ravenous", 1445, 54.0, 56.5 }, -- Craftsman's Monocle: Dustwallow Marsh
  [264083] = { "Jessir Moonbow", 1448, 51.4, 82.0 }, -- Goblin Land Mine: Felwood
  [264084] = { "Scout Raroul", 1444, 72.4, 52.5 }, -- Catseye Ultra Goggles: Feralas
  [264085] = { "Narianna", 1450, 53.3, 42.7 }, -- Unstable Trigger: Moonglade
  [264086] = { "Spek", 2548, 76.9, 54.1 }, -- Flash Bomb: Riverglades
  [264087] = { "Durganon", 1427, 41.1, 58.3 }, -- Fire Goggles: Searing Gorge
  [264088] = { "Bullets Bigblast", 1435, 70.0, 41.6 }, -- Mithril Frag Bomb: Swamp of Sorrows
  [264089] = { "Jhordy Lapforge", 1446, 52.3, 26.9 }, -- Gyromatic Micro-Adjuster: Tanaris
  [264090] = { "Rhapsody Shindigger", 1425, 26.9, 48.6 }, -- Mechanical Repair Kit: The Hinterlands
  [264091] = { "Gibbert", 1449, 44.1, 7.2 }, -- Dark Iron Bomb: Un'Goro Crater
  [264092] = { "Garek", 1418, 61.9, 54.3 }, -- Comfortable Leather Hat: Badlands
  [264093] = { "Azore Aldamort", 1443, 38.9, 27.2 }, -- Guardian Cloak: Desolace
  [264094] = { "The Ravenous", 1445, 54.0, 56.5 }, -- Dusky Bracers: Dustwallow Marsh
  [264095] = { "Ivy Leafrunner", 1448, 51.0, 81.6 }, -- Wild Leather Helmet: Felwood
  [264096] = { "Scout Raroul", 1444, 72.4, 52.5 }, -- Wild Leather Shoulders: Feralas
  [264097] = { "Narianna", 1450, 53.3, 42.7 }, -- Quickdraw Quiver: Moonglade
  [264098] = { "Spek", 2548, 76.9, 54.1 }, -- Swift Boots: Riverglades
  [264099] = { "Evonice Sootsmoker", 1427, 38.4, 27.7 }, -- Nightscape Shoulders: Searing Gorge
  [264100] = { "Mukomonji", 1435, 62.4, 52.9 }, -- Big Voodoo Mask: Swamp of Sorrows
  [264101] = { "Yeh'kinya", 1446, 67.0, 22.4 }, -- Big Voodoo Robe: Tanaris
  [264102] = { "Juo", 1425, 80.1, 55.4 }, -- Turtle Scale Breastplate: The Hinterlands
  [264103] = { "Nergal", 1449, 43.3, 7.7 }, -- Thick Leather Ammo Pouch: Un'Goro Crater
  [264104] = { "Rigglefuzz", 1418, 42.4, 52.9 }, -- Mageweave Bag: Badlands
  [264105] = { "Willow", 1443, 62.2, 39.6 }, -- Shadoweave Gloves: Desolace
  [264106] = { "Tabetha", 1445, 46.1, 57.1 }, -- Crimson Silk Robe: Dustwallow Marsh
  [264107] = { "Eridan Bluewind", 1448, 51.4, 81.5 }, -- Shadoweave Robe: Felwood
  [264108] = { "Impsy", 1448, 41.4, 45.0 }, -- Enchanted Mageweave Pouch: Felwood
  [264109] = { "Mylentha Riverbend", 1450, 51.8, 32.6 }, -- Star Belt: Moonglade
  [264110] = { "Spek", 2548, 76.9, 54.1 }, -- Black Mageweave Vest: Riverglades
  [264111] = { "Lookout Captain Lolo Longstriker", 1427, 37.7, 26.6 }, -- Red Mageweave Pants: Searing Gorge
  [264112] = { "Bullets Bigblast", 1435, 70.0, 41.6 }, -- Orange Martial Shirt: Swamp of Sorrows
  [264113] = { "Vizzklick", 1446, 51.0, 27.4 }, -- White Bandit Mask: Tanaris
  [264114] = { "Atal'ai Exile", 1425, 33.8, 75.2 }, -- Cindercloth Robe: The Hinterlands
  [264115] = { "Petra Grossen", 1449, 43.7, 7.2 }, -- Earthen Silk Belt: Un'Goro Crater
  [264116] = { "Archmage Xylem", 1447, 29.2, 40.2 }, -- Potion of Demonslaying: Azshara
  [264117] = { "Kum'isha the Collector", 1419, 52.0, 35.6 }, -- Dreamless Sleep Potion: Blasted Lands
  [264118] = { "Gorzeeki Wildeyes", 1428, 12.4, 31.6 }, -- Greater Fire Protection Potion: Burning Steppes
  [264119] = { "Hastings", 1430, 47.0, 75.3 }, -- Draught of Detect Demon: Deadwind Pass
  [264120] = { "Adon", 1423, 50.9, 11.5 }, -- Gift of Arthas: Eastern Plaguelands
  [264122] = { "Jarund Stoutstrider", 1451, 82.0, 18.1 }, -- Limited Invulnerability Potion: Silithus
  [264123] = { "Kirala Fairgrass", 1422, 59.6, 53.1 }, -- Major Rejuvenation Potion: Western Plaguelands
  [264124] = { "Bor'dorc", 1452, 64.8, 33.2 }, -- Distilled Firewater: Winterspring
  [264126] = { "Kum'isha the Collector", 1419, 52.0, 35.6 }, -- Radiant Belt: Blasted Lands
  [264127] = { "Ugkragg", 1428, 38.4, 35.4 }, -- Orcish War Leggings: Burning Steppes (added by hand; the spot from his other writ)
  [264128] = { "Calliard", 1430, 48.4, 68.7 }, -- Mithril Spurs: Deadwind Pass
  [264133] = { "Xizzer Fizzbolt", 1452, 60.8, 38.6 }, -- Ebon Shiv: Winterspring
  [264134] = { "Rayan Dawnrisen", 1447, 30.0, 40.2 }, -- Masterwork Target Dummy: Azshara
  [264135] = { "Kum'isha the Collector", 1419, 52.0, 35.6 }, -- Green Lens: Blasted Lands
  [264136] = { "Ugkragg", 1428, 38.4, 35.4 }, -- Lifelike Mechanical Toad: Burning Steppes
  [264137] = { "Hastings", 1430, 47.0, 75.3 }, -- Gnomish Alarm-O-Bot: Deadwind Pass
  [264140] = { "Khur Hornstriker", 1451, 48.7, 37.0 }, -- Truesilver Transformer: Silithus
  [264141] = { "Suspicious Adventurer", 1422, 65.7, 76.1 }, -- Sniper Scope: Western Plaguelands
  [264146] = { "Hastings", 1430, 47.0, 75.3 }, -- Runic Leather Headband: Deadwind Pass
  [264147] = { "Quartermaster Miranda Breechlock", 1423, 71.8, 50.2 }, -- Wicked Leather Bracers: Eastern Plaguelands
  [264148] = { "Earthcaller Franzahl", 1452, 54.0, 90.4 }, -- Chimeric Vest: Winterspring
  [264150] = { "Fallen Adventurer", 1422, 38.2, 72.4 }, -- Runic Leather Bracers: Western Plaguelands
  [264151] = { "Blixxrak", 1452, 61.7, 37.8 }, -- Frostsaber Boots: Winterspring
  [264153] = { "Kum'isha the Collector", 1419, 52.0, 35.6 }, -- Runecloth Bag: Blasted Lands
  [264154] = { "Gorzeeki Wildeyes", 1428, 12.4, 31.6 }, -- Runecloth Boots: Burning Steppes
  [264155] = { "Hastings", 1430, 47.0, 75.3 }, -- Tuxedo Jacket: Deadwind Pass
  [264158] = { "Hermit Ortell", 1451, 67.2, 69.8 }, -- Shadoweave Mask: Silithus
  [264160] = { "Zelizax", 1452, 57.6, 88.1 }, -- Soul Pouch: Winterspring
}

-- Writ levels and reputation. The Forever writ IDs come in three blocks (each block alchemy, blacksmithing,
-- engineering, leatherworking, tailoring), matching the guides' examples: Blue Overalls (Journeyman),
-- Enchanted Mageweave Pouch (Expert), Gift of Arthas (Artisan).
ns.WRIT_TIERS = {
  { name = "Journeyman", last = 264055, rep = 75 },
  { name = "Expert", last = 264115, rep = 125 },
  { name = "Artisan", last = 264160, rep = 200 },
}
-- Which profession makes what each writ asks for. In every level the writs run Alchemy, Blacksmithing,
-- Engineering, Leatherworking, Tailoring (from the items' recipes in NeedRoll's profession data).
ns.WRIT_PROFESSIONS = {
  { last = 264019, name = "Alchemy" }, { last = 264028, name = "Blacksmithing" },
  { last = 264037, name = "Engineering" }, { last = 264046, name = "Leatherworking" },
  { last = 264055, name = "Tailoring" },
  { last = 264067, name = "Alchemy" }, { last = 264079, name = "Blacksmithing" },
  { last = 264091, name = "Engineering" }, { last = 264103, name = "Leatherworking" },
  { last = 264115, name = "Tailoring" },
  { last = 264124, name = "Alchemy" }, { last = 264133, name = "Blacksmithing" },
  { last = 264142, name = "Engineering" }, { last = 264151, name = "Leatherworking" },
  { last = 264160, name = "Tailoring" },
}

function ns.WritProfession(writID)
  if not writID or writID < ns.FOREVER_WRIT_FIRST or writID > ns.FOREVER_WRIT_LAST then
    return nil
  end
  for _, block in ipairs(ns.WRIT_PROFESSIONS) do
    if writID <= block.last then
      return block.name
    end
  end
end

-- "Sealed Expert's Writ" and the like open into a random writ of that level.
ns.SEALED_WRITS = {
  ["Sealed Journeyman's Writ"] = 1,
  ["Sealed Expert's Writ"] = 2,
  ["Sealed Artisan's Writ"] = 3,
}

function ns.WritTier(writID)
  if not writID or writID < ns.FOREVER_WRIT_FIRST or writID > ns.FOREVER_WRIT_LAST then
    return nil
  end
  for _, tier in ipairs(ns.WRIT_TIERS) do
    if writID <= tier.last then
      return tier
    end
  end
end

-- Waylaid Crates ("Waylaid Crate: Journeyman Ore") are filled with one item from their list and turned in
-- at the hub for Merchant's Favor and silver (half a silver per Favor). Crates of raw goods pay the level's
-- base, crates of made goods (green) twice that. Apprentice, Journeyman and Expert are from the guides;
-- Artisan is a guess that follows the same steps.
ns.CRATE_LEVELS = {
  Apprentice = { favor = 5 },
  Journeyman = { favor = 10 },
  Expert = { favor = 15 },
  Artisan = { favor = 20, guess = true },
  Elite = { favor = 25, guess = true }, -- Sealed Elite Crates exist (no Waylaid Elite crate yet): a guess too
}
-- Made goods: these crates pay double. Used when the item's quality isn't known yet.
ns.CRATE_MADE_GOODS = { Cloth = true, Bars = true, Parts = true }

-- The crates by item ID (WoW Forever's item table), so they are known in every language and whatever their name
-- says ("Waylaid Crate: Earthly Artisan Herbs" puts its kind before the level). To fill: [itemID] = { level,
-- category }; sealed (filled) crates: [itemID] = level, in three qualities each (the quality says raw or made).
ns.CRATE_ITEMS = {
  [248682] = { "Apprentice", "Herbs" }, [248683] = { "Apprentice", "Ore" }, [248684] = { "Apprentice", "Textiles" },
  [248685] = { "Apprentice", "Oddities" }, [248686] = { "Journeyman", "Herbs" }, [248687] = { "Journeyman", "Ore" },
  [248688] = { "Journeyman", "Textiles" }, [248689] = { "Journeyman", "Oddities" }, [248690] = { "Expert", "Roots" },
  [248691] = { "Expert", "Flowers" }, [248692] = { "Expert", "Ore" }, [248693] = { "Expert", "Textiles" },
  [248694] = { "Expert", "Oddities" }, [248695] = { "Artisan", "Roots" }, [248696] = { "Artisan", "Flowers" },
  [248697] = { "Artisan", "Ore" }, [248698] = { "Artisan", "Textiles" }, [248699] = { "Artisan", "Oddities" },
  [248702] = { "Apprentice", "Cloth" }, [248703] = { "Apprentice", "Bars" }, [248704] = { "Apprentice", "Parts" },
  [248705] = { "Journeyman", "Cloth" }, [248706] = { "Journeyman", "Bars" }, [248707] = { "Journeyman", "Parts" },
  [248708] = { "Expert", "Cloth" }, [248709] = { "Expert", "Bars" }, [248710] = { "Expert", "Parts" },
  [248711] = { "Artisan", "Cloth" }, [248712] = { "Artisan", "Bars" }, [248713] = { "Artisan", "Parts" },
}
-- Crates that aren't one kind yet (2026-11-27): the plain Waylaid Crate (using it reads its label and turns it into
-- a crate of one kind: Forever's spell 1247168 "Read the label to identify the shipment") and Waylaid Herbs (a package
-- with a shipping bill: the bill's text lives on the game's servers, not in its files, so it is shown from players'
-- data, Tylesser - Data, once someone has read one).
ns.UNREAD_CRATES = { [248549] = "label", [275642] = "bill" }
ns.SEALED_CRATE_ITEMS = {
  [248765] = "Apprentice", [248766] = "Journeyman", [248767] = "Expert", [248768] = "Artisan", [248769] = "Elite",
  [248770] = "Apprentice", [248771] = "Journeyman", [248772] = "Expert", [248773] = "Artisan", [248774] = "Elite",
  [248775] = "Apprentice", [248776] = "Journeyman", [248777] = "Expert", [248778] = "Artisan", [248779] = "Elite",
}

-- What fills each crate: one stack of one of these, [category][level] = { { itemID, count, name }, ... }
-- (wow.gg "Merchant's Favor" guide). The guides name some categories differently (Curiosities and Oddities,
-- Fabrics and Cloth, Ingots and Bars), and Expert and Artisan herbs come as roots/stems and as flowers.
ns.CRATE_CONTENTS = {
  Herbs = {
    Apprentice = { { 2447, 20, "Peacebloom" }, { 765, 20, "Silverleaf" }, { 2449, 10, "Earthroot" }, { 785, 10, "Mageroyal" }, { 2450, 10, "Briarthorn" } },
    Journeyman = { { 3820, 10, "Stranglekelp" }, { 2453, 10, "Bruiseweed" }, { 3355, 10, "Wild Steelbloom" }, { 3369, 10, "Grave Moss" }, { 3356, 10, "Kingsblood" } },
  },
  Roots = {
    Expert = { { 3357, 20, "Liferoot" }, { 3818, 10, "Fadeleaf" }, { 3821, 10, "Goldthorn" }, { 3358, 10, "Khadgar's Whisker" } },
    Artisan = { { 13464, 10, "Golden Sansam" }, { 8838, 20, "Sungrass" }, { 8839, 10, "Blindweed" }, { 8845, 10, "Ghost Mushroom" }, { 8846, 10, "Gromsblood" } },
  },
  Flowers = {
    Expert = { { 3819, 10, "Wintersbite" }, { 4625, 10, "Firebloom" }, { 8831, 20, "Purple Lotus" }, { 8836, 10, "Arthas' Tears" } },
    Artisan = { { 13463, 20, "Dreamfoil" }, { 13465, 20, "Mountain Silversage" }, { 13466, 20, "Plaguebloom" }, { 13467, 20, "Icecap" } },
  },
  Ore = {
    Apprentice = { { 2770, 20, "Copper Ore" }, { 2771, 20, "Tin Ore" } },
    Journeyman = { { 2775, 10, "Silver Ore" }, { 2772, 20, "Iron Ore" } },
    Expert = { { 2776, 10, "Gold Ore" }, { 3858, 20, "Mithril Ore" } },
    Artisan = { { 7911, 10, "Truesilver Ore" }, { 10620, 20, "Thorium Ore" }, { 11370, 20, "Dark Iron Ore" } },
  },
  Textiles = {
    Apprentice = { { 2589, 40, "Linen Cloth" }, { 2318, 20, "Light Leather" } },
    Journeyman = { { 2592, 20, "Wool Cloth" }, { 4306, 40, "Silk Cloth" }, { 2319, 20, "Medium Leather" } },
    Expert = { { 4338, 40, "Mageweave Cloth" }, { 4234, 20, "Heavy Leather" } },
    Artisan = { { 14047, 40, "Runecloth" }, { 4304, 20, "Thick Leather" }, { 8170, 20, "Rugged Leather" } },
  },
  Oddities = {
    Apprentice = { { 10940, 20, "Strange Dust" }, { 10939, 4, "Greater Magic Essence" }, { 10978, 6, "Small Glimmering Shard" }, { 11084, 2, "Large Glimmering Shard" } },
    Journeyman = { { 11083, 20, "Soul Dust" }, { 11082, 4, "Greater Astral Essence" }, { 11138, 6, "Small Glowing Shard" }, { 11139, 2, "Large Glowing Shard" } },
    Expert = { { 11137, 20, "Vision Dust" }, { 11135, 4, "Greater Mystic Essence" }, { 11177, 6, "Small Radiant Shard" }, { 11178, 2, "Large Radiant Shard" } },
    Artisan = { { 11176, 20, "Dream Dust" }, { 11175, 4, "Greater Nether Essence" }, { 14343, 6, "Small Brilliant Shard" }, { 14344, 2, "Large Brilliant Shard" } },
  },
  Cloth = {
    Apprentice = { { 4231, 2, "Cured Light Hide" }, { 2996, 20, "Bolt of Linen Cloth" } },
    Journeyman = { { 2997, 6, "Bolt of Woolen Cloth" }, { 4305, 10, "Bolt of Silk Cloth" }, { 4233, 2, "Cured Medium Hide" } },
    Expert = { { 4339, 8, "Bolt of Mageweave" }, { 4236, 2, "Cured Heavy Hide" } },
    Artisan = { { 14048, 8, "Bolt of Runecloth" }, { 8172, 2, "Cured Thick Hide" } },
  },
  Bars = {
    Apprentice = { { 2840, 20, "Copper Bar" }, { 3576, 20, "Tin Bar" }, { 2841, 10, "Bronze Bar" } },
    Journeyman = { { 2842, 10, "Silver Bar" }, { 3575, 20, "Iron Bar" } },
    Expert = { { 3860, 20, "Mithril Bar" }, { 3859, 15, "Steel Bar" }, { 3577, 10, "Gold Bar" } },
    Artisan = { { 11371, 2, "Dark Iron Bar" }, { 6037, 10, "Truesilver Bar" }, { 12359, 20, "Thorium Bar" } },
  },
  Parts = {
    Apprentice = { { 4359, 16, "Handful of Copper Bolts" }, { 4361, 16, "Copper Tube" }, { 4363, 4, "Copper Modulator" } },
    Journeyman = { { 4371, 8, "Bronze Tube" }, { 4375, 7, "Whirring Bronze Gizmo" }, { 4382, 4, "Bronze Framework" }, { 10558, 45, "Gold Power Core" } },
    Expert = { { 4387, 8, "Iron Strut" }, { 10559, 5, "Mithril Tube" }, { 10560, 12, "Unstable Trigger" }, { 10561, 5, "Mithril Casing" } },
    Artisan = { { 15994, 5, "Thorium Widget" }, { 18631, 5, "Truesilver Transformer" }, { 16000, 2, "Thorium Tube" } },
  },
}
ns.CRATE_CATEGORY_ALIASES = { Curiosities = "Oddities", Fabrics = "Cloth", Ingots = "Bars", Stems = "Roots",
  Earthly = "Roots", Flowering = "Flowers", Blooms = "Flowers" }

-- The CRATE_CONTENTS category for a crate's name part ("Ore", "Fabrics", "Flowering Herbs"), or nil.
function ns.CrateCategory(text)
  if not text then
    return nil
  end
  for word in text:gmatch("[%a']+") do
    local key = ns.CRATE_CATEGORY_ALIASES[word] or word
    if key ~= "Herbs" and ns.CRATE_CONTENTS[key] then
      return key
    end
  end
  if text:find("Herb") then
    return "Herbs"
  end
end
ns.COPPER_PER_FAVOR = 50
