local _, ns = ...

-- Game data for the Azeroth Commerce Authority (Alliance) and Durotar Supply and Logistics (Horde),
-- the WoW Forever crafting factions. Numbers from the game where known, else from player guides
-- (Mobalytics "Merchant's Favor, Waylaid Crates & Craftsman's Writ Guide", wow.gg, Warcraft Wiki);
-- what the addon sees at turn-ins (Learn.lua) replaces the guesses.

ns.FAVOR_CURRENCY = 3402 -- Merchant's Favor
ns.FACTION_NAMES = { Alliance = "Azeroth Commerce Authority", Horde = "Durotar Supply and Logistics" }
ns.HUBS = {
  Alliance = "Three Corners, Redridge Mountains (10, 72)",
  Horde = "west of the Crossroads, The Barrens (49, 29)",
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
  [264060] = { false, 1, "Catseye Draught" },
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
  [264089] = { false, 1, "Gyromatic Micro-Adjuster" },
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
  [264119] = { false, 1, "Draught of Detect Demon" },
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
  [264137] = { false, 1, "Gnomish Alarm-O-Bot" },
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
}
-- Made goods: these crates pay double. Used when the item's quality isn't known yet.
ns.CRATE_MADE_GOODS = { Cloth = true, Bars = true, Parts = true }

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
  Flowering = "Flowers", Blooms = "Flowers" }

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
