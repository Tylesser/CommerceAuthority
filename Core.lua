local _, ns = ...
local L = ns.L

ns.defaults = {
  writTooltips = true,      -- writ tooltips: what it needs, prices, reputation
  crateTooltips = true,     -- crate tooltips: Merchant's Favor, silver, what fills it
  vendorMarks = true,       -- at the Commerce Authority vendors: what you can afford
  allSources = true,        -- every installed price addon in tooltips, not only the first
  onlyMyProfessions = false, -- the window's cheapest list: only writs your professions make
  cheapestBy = nil,         -- the window's cheapest list: "writ", "npc" or "zone" (nil: writ; ns.CheapestMode)
  windowTab = nil,          -- the window's tab: "writs" (nil) or "crates" (ns.SelectWindowTab)
  position = nil,           -- the window's position
  auctionDock = true,       -- the window opens beside the auction house and closes with it (Dock.lua)
  mapPins = true,           -- the NPCs who take your writs on the world map (Route.lua)
  crateAlert = false,       -- tell me when a crate + its cheapest fill costs less than crateAlertBelow
  crateAlertBelow = 10000,  -- copper (1g)
  crateAlertSound = true,   -- ... with a sound
  characters = {},          -- ["Realm-Name"] = what each character has (Characters.lua)
  npcTier = nil,            -- the Writ NPCs window: only this writ level ("Journeyman", "Expert", "Artisan")
  npcMine = false,          -- the Writ NPCs window: only writs your professions make
  npcNotDone = false,       -- the Writ NPCs window: only writs not turned in today
  npcFolded = {},           -- the Writ NPCs window: folded zones ([uiMapID] = true, unknown = true)
  learned = {
    crates = {},            -- [level .. " raw"/" made"] = { n, total, min, max, last, values }: Favor per turn-in
    writs = {},             -- [writ quest ID] = { n, total, min, max, last, values }: reputation per turn-in
    customers = {},         -- [writ item ID] = { NPC name, uiMapID, x, y }: who took the writ, where
  },
  factionIDs = {},          -- [Alliance/Horde] = the faction's ID, once found in the reputation list
}

-- Copies missing defaults into a saved table (also inside nested tables).
function ns.ApplyDefaults(saved, defaults)
  for key, value in pairs(defaults) do
    if saved[key] == nil then
      if type(value) == "table" then
        saved[key] = {}
        ns.ApplyDefaults(saved[key], value)
      else
        saved[key] = value
      end
    elseif type(value) == "table" and type(saved[key]) == "table" then
      ns.ApplyDefaults(saved[key], value)
    end
  end
end

local function DB()
  return CommerceAuthorityDB or ns.defaults
end

-- Items --------------------------------------------------------------------------------------------

function ns.ItemName(itemID)
  if not itemID then
    return nil
  end
  local name
  if C_Item and C_Item.GetItemNameByID then
    name = C_Item.GetItemNameByID(itemID)
  end
  if not name and GetItemInfo then
    name = GetItemInfo(itemID)
  end
  return name
end

local function ItemQuality(itemID)
  if C_Item and C_Item.GetItemQualityByID then
    local quality = C_Item.GetItemQualityByID(itemID)
    if quality then
      return quality
    end
  end
  if GetItemInfo then
    return (select(3, GetItemInfo(itemID)))
  end
end

function ns.ItemIDFromLink(link)
  return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

-- The most common value seen (ties: the smaller), so one odd turn-in doesn't move the estimate.
function ns.UsualValue(seen)
  if not seen then
    return nil
  end
  local best, bestCount
  for value, count in pairs(seen.values or {}) do
    if not bestCount or count > bestCount or (count == bestCount and value < best) then
      best, bestCount = value, count
    end
  end
  return best or seen.last or seen.min
end

-- Legacy talents ------------------------------------------------------------------------------------
-- WoW Forever's legacy talents are talent tree talents: Performance Bonus (spell 1225456, 15% chance of double
-- Merchant's Favor from a crate) and Diplomat (1225485, +10% reputation). Detected like any spell you know (or by
-- their passive aura) instead of asking (the user's request, 2026-11-19).

ns.PERFORMANCE_BONUS_SPELL = 1225456
ns.DIPLOMAT_SPELL = 1225485

-- A talent's name as the game writes it in the client's language (2026-11-27, translations), else `english`.
function ns.TalentName(spellID, english)
  if C_Spell and C_Spell.GetSpellName then
    local ok, name = pcall(C_Spell.GetSpellName, spellID)
    if ok and type(name) == "string" and name ~= "" and (not canaccessvalue or canaccessvalue(name)) then
      return name
    end
  end
  return english
end

local function Yes(fn, ...)
  if type(fn) ~= "function" then
    return false
  end
  local ok, result = pcall(fn, ...)
  return ok and result == true
end

function ns.HasLegacyTalent(spellID)
  if Yes(IsPlayerSpell, spellID) or Yes(IsSpellKnown, spellID) then
    return true
  end
  if C_SpellBook and Yes(C_SpellBook.IsSpellKnown, spellID) then
    return true
  end
  local auras = C_UnitAuras
  if auras and type(auras.GetPlayerAuraBySpellID) == "function" then
    local ok, aura = pcall(auras.GetPlayerAuraBySpellID, spellID)
    if ok and type(aura) == "table" then
      return true
    end
  end
  return false
end

function ns.HasPerformanceBonus()
  return ns.HasLegacyTalent(ns.PERFORMANCE_BONUS_SPELL)
end

function ns.HasDiplomat()
  return ns.HasLegacyTalent(ns.DIPLOMAT_SPELL)
end

-- Merchant's Favor and the faction -----------------------------------------------------------------

-- quantity, name, icon of Merchant's Favor, or nil on clients without it. Not on Retail, where the
-- same currency ID may be something else.
function ns.Favor()
  if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    return nil
  end
  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, ns.FAVOR_CURRENCY)
    if ok and type(info) == "table" and info.name and info.name ~= "" then
      return info.quantity or 0, info.name, info.iconFileID
    end
  end
end

local function IsCommerceFaction(name)
  for _, factionName in pairs(ns.FACTION_NAMES) do
    if name == factionName then
      return true
    end
  end
  for side in pairs(ns.FACTION_IDS) do
    if name == ns.FactionNameOf(side) then -- the client's own name
      return true
    end
  end
  return false
end
ns.IsCommerceFaction = IsCommerceFaction

local function Side()
  return UnitFactionGroup and UnitFactionGroup("player") or "Alliance"
end
ns.Side = Side

-- Your side's faction name: Azeroth Commerce Authority or Durotar Supply and Logistics, in the client's language
-- (ns.FactionNameOf).
function ns.MyFactionName()
  return ns.FactionNameOf(Side())
end

local function FromModern(data)
  if type(data) == "table" and data.name then
    return {
      id = data.factionID, name = data.name, standingID = data.reaction,
      min = data.currentReactionThreshold, max = data.nextReactionThreshold, value = data.currentStanding,
    }
  end
end

local function FromClassic(name, _, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _, factionID)
  if name then
    return { id = factionID, name = name, standingID = standingID, min = barMin, max = barMax, value = barValue }
  end
end

local function FactionByID(factionID)
  if C_Reputation and C_Reputation.GetFactionDataByID then
    return FromModern(C_Reputation.GetFactionDataByID(factionID))
  end
  if GetFactionInfoByID then
    return FromClassic(GetFactionInfoByID(factionID))
  end
end

-- A side's faction name as the game gives it (the client's language; by ID), else the English one.
function ns.FactionNameOf(side)
  side = ns.FACTION_IDS[side] and side or "Alliance"
  local ok, faction = pcall(FactionByID, ns.FACTION_IDS[side])
  local name = ok and type(faction) == "table" and faction.name
  if type(name) == "string" and name ~= "" and (not canaccessvalue or canaccessvalue(name)) then
    return name
  end
  return ns.FACTION_NAMES[side]
end

-- Where your side's trade hub is: "Three Corners, Redridge Mountains (10, 72)", the names from the game.
function ns.HubText()
  local hub = ns.HUB_AREAS[ns.Side()] or ns.HUB_AREAS.Alliance
  local function Area(id, english)
    local ok, name = false, nil
    if C_Map and C_Map.GetAreaInfo then
      ok, name = pcall(C_Map.GetAreaInfo, id)
    end
    return ok and type(name) == "string" and name ~= "" and name or english
  end
  local place, zone = Area(hub.place, hub.placeName), Area(hub.zone, hub.zoneName)
  local where = hub.west and L["west of %s, %s"]:format(place, zone) or ("%s, %s"):format(place, zone)
  return ("%s (%s)"):format(where, hub.spot)
end

local function FactionByIndex(index)
  if C_Reputation and C_Reputation.GetFactionDataByIndex then
    return FromModern(C_Reputation.GetFactionDataByIndex(index))
  end
  if GetFactionInfo then
    return FromClassic(GetFactionInfo(index))
  end
end

local function NumFactions()
  if C_Reputation and C_Reputation.GetNumFactions then
    return C_Reputation.GetNumFactions() or 0
  end
  return GetNumFactions and GetNumFactions() or 0
end

-- Your side's Commerce Authority faction: { id, name, standingID, min, max, value } (value counts from
-- Hated), or nil while you have no reputation with it. Looked up by name in your reputation list; the ID
-- found there (saved per side) is only used when the list hides it under a collapsed header.
function ns.Faction()
  local wanted = ns.MyFactionName()
  local wantedID = ns.FACTION_IDS[Side()]
  for index = 1, NumFactions() do
    local ok, faction = pcall(FactionByIndex, index)
    if ok and faction and ((wantedID and faction.id == wantedID) or faction.name == wanted) then
      if faction.id and CommerceAuthorityDB then
        CommerceAuthorityDB.factionIDs[Side()] = faction.id
      end
      return faction
    end
  end
  local savedID = DB().factionIDs and DB().factionIDs[Side()]
  if savedID then
    local ok, faction = pcall(FactionByID, savedID)
    if ok and faction and (faction.id == savedID or faction.name == wanted) then
      return faction
    end
  end
end

local STANDINGS = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }
function ns.StandingName(standingID)
  return _G["FACTION_STANDING_LABEL" .. tostring(standingID)] or STANDINGS[standingID] or "?"
end

-- Reputation needed from here to the start of each higher standing: { { standingID, needed }, ... }.
-- Standard steps; Exalted is 42,000 from Neutral.
local STEP = { [1] = 36000, [2] = 3000, [3] = 3000, [4] = 3000, [5] = 6000, [6] = 12000, [7] = 21000 }
function ns.NextStandings(faction)
  local list = {}
  if not faction or not faction.standingID or faction.standingID >= 8 then
    return list
  end
  local needed = (faction.max or 0) - (faction.value or 0)
  list[1] = { standingID = faction.standingID + 1, needed = needed }
  for standingID = faction.standingID + 1, 7 do
    needed = needed + (STEP[standingID] or 0)
    list[#list + 1] = { standingID = standingID + 1, needed = needed }
  end
  return list
end

-- Writ levels and professions as the player reads them (the English names stay the keys everywhere else).
local TIER_TEXT = { Journeyman = L["Journeyman"], Expert = L["Expert"], Artisan = L["Artisan"] }
function ns.TierName(name)
  return TIER_TEXT[name] or name or "?"
end

local PROFESSION_TEXT = { Alchemy = L["Alchemy"], Blacksmithing = L["Blacksmithing"], Engineering = L["Engineering"],
  Leatherworking = L["Leatherworking"], Tailoring = L["Tailoring"] }
function ns.ProfessionName(name)
  return PROFESSION_TEXT[name] or name
end

-- Professions ---------------------------------------------------------------------------------------

local PROFESSIONS = { Alchemy = true, Blacksmithing = true, Engineering = true, Leatherworking = true,
  Tailoring = true }
-- By skill line (GetProfessionInfo's 7th value), so other languages match too (2026-11-27); the skill list fallback
-- has names only: the profession's own spell gives the client's name for it.
local SKILL_LINES = { [171] = "Alchemy", [164] = "Blacksmithing", [202] = "Engineering", [165] = "Leatherworking",
  [197] = "Tailoring" }
local PROFESSION_SPELLS = { Alchemy = 2259, Blacksmithing = 2018, Engineering = 4036, Leatherworking = 2108,
  Tailoring = 3908 }
local localProfessions
local function EnglishProfession(name)
  if PROFESSIONS[name] then
    return name
  end
  if not localProfessions or next(localProfessions) == nil then
    localProfessions = {}
    for english, spellID in pairs(PROFESSION_SPELLS) do
      local ok, own = false, nil
      if C_Spell and C_Spell.GetSpellName then
        ok, own = pcall(C_Spell.GetSpellName, spellID)
      end
      if ok and type(own) == "string" and own ~= "" then
        localProfessions[own] = english
      end
    end
  end
  return localProfessions[name]
end

-- { [profession name] = skill } for the crafting professions you have.
function ns.PlayerProfessions()
  local found = {}
  if GetProfessions and GetProfessionInfo then
    for _, index in ipairs({ GetProfessions() }) do
      if index then
        local ok, name, _, skill, _, _, _, skillLine = pcall(GetProfessionInfo, index)
        local english = ok and (SKILL_LINES[skillLine] or EnglishProfession(name))
        if english then
          found[english] = skill or 0
        end
      end
    end
  end
  if next(found) == nil and GetNumSkillLines and GetSkillLineInfo then
    for index = 1, GetNumSkillLines() do
      local name, isHeader, _, skill = GetSkillLineInfo(index)
      local english = name and not isHeader and EnglishProfession(name)
      if english then
        found[english] = skill or 0
      end
    end
  end
  return found
end

-- Writs ---------------------------------------------------------------------------------------------

-- A writ missing from ns.WRITS is still found by its name ("Craftsman's Writ: <item>" on WoW Forever,
-- "Craftsman's Writ - <item>" on Classic); the count is then taken as 1.
local function WritByName(writID)
  local name = ns.ItemName(writID)
  local wanted = name and (name:match("^Craftsman's Writ: (.+)$") or name:match("^Craftsman's Writ %- (.+)$"))
  if wanted then
    return { false, 1, wanted }
  end
end

function ns.Writ(writID)
  if not writID then
    return nil
  end
  return ns.WRITS[writID] or WritByName(writID)
end

-- The item a writ asks for: its ID, else (until the client knows it) found by name.
function ns.WantedItem(writ)
  if writ[1] then
    return writ[1]
  end
  if GetItemInfo then
    local _, link = GetItemInfo(writ[3])
    return ns.ItemIDFromLink(link)
  end
end

-- How many the writ asks for: from the quest log while you have the writ's quest, else the table's count.
function ns.WritCount(writID, writ)
  local getObjectives = C_QuestLog and C_QuestLog.GetQuestObjectives
  if getObjectives and writID >= ns.FOREVER_WRIT_FIRST then
    local ok, objectives = pcall(getObjectives, ns.WritQuestID(writID))
    if ok and type(objectives) == "table" then
      for _, objective in ipairs(objectives) do
        if objective.type == "item" and (objective.numRequired or 0) > 0 then
          return objective.numRequired
        end
      end
    end
  end
  return writ[2]
end

-- A writ level's reputation, +10% with Diplomat.
function ns.TierRep(tier)
  if ns.HasDiplomat() then
    return math.floor(tier.rep * (1 + ns.DIPLOMAT_BONUS) + 0.5)
  end
  return tier.rep
end

-- Reputation a writ gives: what you were given for it before, else its level's amount.
-- Returns reputation, learned (true when seen at a turn-in), tier.
function ns.WritReputation(writID)
  local tier = ns.WritTier(writID)
  if not tier then
    return nil, false, nil
  end
  local seen = DB().learned.writs[ns.WritQuestID(writID) or 0]
  local usual = ns.UsualValue(seen)
  if usual then
    return usual, true, tier
  end
  return ns.TierRep(tier), false, tier
end

-- What getting a writ's items costs: the cheaper of buying and crafting, per item. Returns each, how.
function ns.WantedItemCost(writID)
  local writ = ns.Writ(writID)
  local itemID = writ and ns.WantedItem(writ)
  if not itemID then
    return nil
  end
  local each = ns.Price(itemID)
  local craft = ns.CraftCost(itemID)
  if craft and (not each or craft < each) then
    return craft, "craft"
  end
  return each, each and "buy" or nil
end

-- Cost of one writ's reputation: writ price + the items it asks for (the cheaper of buying and crafting).
-- Returns total cost, per 100 reputation, or nil when a price is missing.
function ns.WritCost(writID)
  local writ = ns.Writ(writID)
  if not writ then
    return nil
  end
  local each = ns.WantedItemCost(writID)
  local writPrice = ns.Price(writID)
  local rep = ns.WritReputation(writID)
  if not (each and writPrice and rep and rep > 0) then
    return nil
  end
  local total = writPrice + each * ns.WritCount(writID, writ)
  return total, total / rep * 100
end

-- Crates --------------------------------------------------------------------------------------------

-- What a crate is: { name, level, category, made (double Favor), filled, guess, favor, key, contents }.
-- By item ID (CRATE_ITEMS, SEALED_CRATE_ITEMS), else from names like "Waylaid Crate: Journeyman Ore",
-- "Waylaid Crate: Earthly Artisan Herbs" (to fill) and "Sealed Journeyman Crate" (filled). nil for other items.
function ns.CrateInfo(itemID, name)
  name = name or ns.ItemName(itemID)
  if not name then
    return nil
  end
  local known = itemID and ns.CRATE_ITEMS[itemID]
  local sealed = itemID and ns.SEALED_CRATE_ITEMS[itemID]
  local level, category, filled
  if known then
    level, category, filled = known[1], known[2], false
  elseif sealed then
    level, filled = sealed, true
  else
    local rest = name:match("^Waylaid Crate: (.+)$")
    if rest then
      for word in rest:gmatch("%a+") do
        if ns.CRATE_LEVELS[word] then
          level = word
          break
        end
      end
      category = level and ns.CrateCategory(rest)
      filled = false
    else
      level = name:match("^Sealed (%a+) Crate$")
      filled = level ~= nil
    end
  end
  local info = level and ns.CRATE_LEVELS[level]
  if not info then
    return nil
  end
  local made
  if category then
    made = ns.CRATE_MADE_GOODS[category] or false
  else
    local quality = itemID and ItemQuality(itemID)
    made = quality ~= nil and quality >= 2
  end
  local contents = category and ns.CRATE_CONTENTS[category] and ns.CRATE_CONTENTS[category][level]
  if category == "Herbs" and not contents then
    -- Expert and Artisan herbs come as roots/stems and flowers: without the kind, either list may apply
    contents = {}
    for _, kind in ipairs({ "Roots", "Flowers" }) do
      for _, option in ipairs(ns.CRATE_CONTENTS[kind][level] or {}) do
        contents[#contents + 1] = option
      end
    end
  end
  return { name = name, level = level, category = category, made = made, filled = filled, guess = info.guess,
    favor = info.favor * (made and 2 or 1), key = level .. (made and " made" or " raw"), contents = contents }
end

-- Tylesser - Data (load on demand, if installed): what players' Tylesser - Collector files saw, for what this
-- addon doesn't know by itself: who takes the Artisan writs missing from WRIT_CUSTOMERS and the Favor a crate gives
-- (2026-11-27). Loaded the first time it's needed, never in a fight (asked again later then). nil without it.
local collected -- nil: not tried yet, false: not installed, else the TylesserData API
function ns.Collected()
  if collected == nil then
    if InCombatLockdown and InCombatLockdown() then
      return nil
    end
    collected = false
    local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    if load then
      pcall(load, "TylesserData")
    end
  end
  -- loaded since (by another addon, or the first try was too early): a cheap check, no second LoadAddOn
  if not collected and type(TylesserData) == "table" and type(TylesserData.Quest) == "function" then
    collected = TylesserData
  end
  return collected or nil
end

-- What each crate level and kind ("Expert made") gave at turn-ins players recorded: the quest that takes a Sealed
-- crate (its required items) and the Merchant's Favor it rewards (base amount, before talents). Built once.
local collectedFavor
local function CollectedFavor(key)
  if not collectedFavor then
    local data = ns.Collected()
    if not data then
      return nil
    end
    collectedFavor = {}
    if type(data.QuestsRequiring) == "function" then
      for itemID, level in pairs(ns.SEALED_CRATE_ITEMS) do
        -- the IDs come in blocks of five per quality (raw 248765-248769, made 248770-248774, blue after)
        local quality = ItemQuality(itemID) or (math.floor((itemID - 248765) / 5) + 1)
        local made = quality >= 2 and " made" or " raw"
        local ok, quests = pcall(data.QuestsRequiring, itemID)
        for _, quest in ipairs(ok and type(quests) == "table" and quests or {}) do
          local favor = type(quest.currencies) == "table" and tonumber(quest.currencies[ns.FAVOR_CURRENCY])
          if favor and favor > 0 then
            collectedFavor[level .. made] = favor
          end
        end
      end
    end
  end
  return collectedFavor[key]
end

-- Merchant's Favor for a crate: what crates of its level and kind gave you before, else what players' recorded
-- turn-ins gave (Tylesser - Data), else the guide's amount. Returns favor, learned (true when seen by you or by
-- players' data), info.
function ns.CrateFavor(itemID, name)
  local info = ns.CrateInfo(itemID, name)
  if not info then
    return nil
  end
  local usual = ns.UsualValue(DB().learned.crates[info.key])
  if usual then
    return usual, true, info
  end
  local seen = CollectedFavor(info.key)
  if seen then
    return seen, true, info
  end
  return info.favor, false, info
end

-- Expected Favor including the Performance Bonus when you have it.
function ns.ExpectedFavor(favor)
  if ns.HasPerformanceBonus() then
    return favor * (1 + ns.PERFORMANCE_BONUS_CHANCE)
  end
  return favor
end

-- Ways to fill a crate, cheapest first: { { itemID, count, name, cost (nil: no price), owned }, ... }.
function ns.CrateFillOptions(info, counts)
  local options = {}
  for _, option in ipairs(info and info.contents or {}) do
    local each = ns.Price(option[1])
    options[#options + 1] = { itemID = option[1], count = option[2], name = ns.ItemName(option[1]) or option[3],
      cost = each and each * option[2], owned = counts and counts[option[1]] or 0 }
  end
  table.sort(options, function(a, b)
    if (a.cost ~= nil) ~= (b.cost ~= nil) then
      return a.cost ~= nil
    end
    if a.cost and a.cost ~= b.cost then
      return a.cost < b.cost
    end
    return a.name < b.name
  end)
  return options
end

-- Bags -----------------------------------------------------------------------------------------------

local function BagSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    return C_Container.GetContainerNumSlots(bag) or 0
  end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function BagItem(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info then
      return info.itemID, info.stackCount or 1
    end
    return nil
  end
  if GetContainerItemInfo then
    local _, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bag, slot)
    return itemID or ns.ItemIDFromLink(link), count or 1
  end
end

-- Starts a writ's quest: uses the writ in your bags, as a right-click on it does (2026-11-24, the user's "a button
-- next to the ready writs to start their quest"). Out of combat only, and never while a vendor, the bank, mail, trade,
-- the guild bank or the auction house is open (UseContainerItem would sell or move the writ there). Returns true, or
-- false and why.
local START_BLOCKERS = { "MerchantFrame", "BankFrame", "MailFrame", "TradeFrame", "GuildBankFrame", "AuctionHouseFrame" }
function ns.StartWrit(writID)
  if InCombatLockdown and InCombatLockdown() then
    return false, L["Writs can't be started in a fight."]
  end
  for _, name in ipairs(START_BLOCKERS) do
    local frame = _G[name]
    if type(frame) == "table" and frame.IsShown and frame:IsShown() then
      return false, L["Close the vendor, bank, mail, trade or auction house window first: it would take the writ."]
    end
  end
  local use = (C_Container and C_Container.UseContainerItem) or UseContainerItem
  if type(use) ~= "function" then
    return false, L["This game version can't use bag items from an addon."]
  end
  local lastBag = (NUM_BAG_SLOTS or 4) + ((NUM_REAGENTBAG_SLOTS or 0) > 0 and NUM_REAGENTBAG_SLOTS or 0)
  for bag = 0, lastBag do
    for slot = 1, BagSlots(bag) do
      if BagItem(bag, slot) == writID then
        local ok = pcall(use, bag, slot)
        if ok then
          return true
        end
        return false, L["The game didn't let the writ be used."]
      end
    end
  end
  return false, L["The writ isn't in your bags."]
end

-- The first writ of a delivery group that can be started: ready (your bags hold what it asks for) and not opened.
function ns.StartableWrit(group)
  for _, entry in ipairs(group and group.writs or {}) do
    if entry.ready and not entry.questID then
      return entry.writID
    end
  end
  return nil
end

-- { [itemID] = count } for everything in your bags.
function ns.BagCounts()
  local counts = {}
  local lastBag = (NUM_BAG_SLOTS or 4) + ((NUM_REAGENTBAG_SLOTS or 0) > 0 and NUM_REAGENTBAG_SLOTS or 0)
  for bag = 0, lastBag do
    for slot = 1, BagSlots(bag) do
      local itemID, count = BagItem(bag, slot)
      if itemID then
        counts[itemID] = (counts[itemID] or 0) + count
      end
    end
  end
  return counts
end

-- The Waylaid Crates in your bags that still need filling, one entry per kind (2026-11-22, the user's request: click
-- a crate to search the auction house for what fills it): { itemID, count, info, favor, options (CrateFillOptions,
-- cheapest first), ready (your bags hold enough of one option for all of them) }, sorted by name.
function ns.CratesToFill(counts)
  counts = counts or ns.BagCounts()
  local list = {}
  for itemID, count in pairs(counts) do
    local name = ns.ItemName(itemID)
    local favor, _, info = ns.CrateFavor(itemID, name)
    if favor and info and not info.filled then
      local options = ns.CrateFillOptions(info, counts)
      local ready = false
      for _, option in ipairs(options) do
        if option.owned >= option.count * count then
          ready = true
        end
      end
      list[#list + 1] = { itemID = itemID, count = count, info = info, favor = favor, options = options,
        ready = ready }
    end
  end
  table.sort(list, function(a, b)
    return a.info.name < b.info.name
  end)
  return list
end

-- What your bags hold for the Commerce Authority:
-- { writs, writRep, sealedWrits, sealedRep, crates (filled), crateFavor, toFill (empty crates), fillFavor }.
function ns.BagSummary(counts)
  local summary = { writs = 0, writRep = 0, sealedWrits = 0, sealedRep = 0, crates = 0, crateFavor = 0,
    toFill = 0, fillFavor = 0 }
  for itemID, count in pairs(counts or ns.BagCounts()) do
    local rep = ns.WritTier(itemID) and ns.WritReputation(itemID)
    if rep then
      summary.writs = summary.writs + count
      summary.writRep = summary.writRep + rep * count
    else
      local name = ns.ItemName(itemID)
      if name and ns.SEALED_WRITS[name] then
        summary.sealedWrits = summary.sealedWrits + count
        summary.sealedRep = summary.sealedRep + ns.TierRep(ns.WRIT_TIERS[ns.SEALED_WRITS[name]]) * count
      else
        local favor, _, info = ns.CrateFavor(itemID, name)
        if favor then
          if info.filled then
            summary.crates = summary.crates + count
            summary.crateFavor = summary.crateFavor + favor * count
          else
            summary.toFill = summary.toFill + count
            summary.fillFavor = summary.fillFavor + favor * count
          end
        end
      end
    end
  end
  return summary
end

-- The cheapest reputation on the auction house: priced Forever writs sorted by cost per 100 reputation.
-- { { writID, total, per100, rep, profession }, ... }, at most `max`. With onlyMyProfessions, only writs
-- whose item your professions make. Kept for 10 seconds: it looks up every writ's prices.
local CACHE_SECONDS = 10
local cache
function ns.InvalidateCheapest()
  cache = nil
end

function ns.CheapestWrits(max)
  local now = GetTime and GetTime() or 0
  local mine = DB().onlyMyProfessions and ns.PlayerProfessions() or nil
  local key = mine and "mine" or "all"
  if not (cache and cache.key == key and now - cache.time < CACHE_SECONDS) then
    local list = {}
    for writID = ns.FOREVER_WRIT_FIRST, ns.FOREVER_WRIT_LAST do
      local profession = ns.WritProfession(writID)
      if ns.WRITS[writID] and (not mine or mine[profession]) then
        local total, per100 = ns.WritCost(writID)
        if total then
          list[#list + 1] = { writID = writID, total = total, per100 = per100, rep = (ns.WritReputation(writID)),
            profession = profession }
        end
      end
    end
    table.sort(list, function(a, b)
      if a.per100 ~= b.per100 then
        return a.per100 < b.per100
      end
      return a.writID < b.writID
    end)
    cache = { key = key, time = now, list = list }
  end
  local result = {}
  for index = 1, math.min(max or #cache.list, #cache.list) do
    result[index] = cache.list[index]
  end
  return result
end

-- The cheapest NPCs to deliver to: for each customer, the priced writs it takes that you don't hold yet, and
-- what buying them all costs per 100 reputation (one shopping list, one trip).
-- { { customer, writs = { cheapest-list entries }, total, rep, per100, have (writs of theirs you hold) }, ... },
-- cheapest first, at most `max`. Follows onlyMyProfessions like ns.CheapestWrits.
function ns.CheapestCustomers(max, counts)
  counts = counts or ns.BagCounts()
  local groups, byKey = {}, {}
  for _, entry in ipairs(ns.CheapestWrits()) do
    local customer = ns.WritCustomer(entry.writID)
    if customer and (counts[entry.writID] or 0) == 0 then
      local key = ns.CustomerKey(customer)
      local group = byKey[key]
      if not group then
        group = { customer = customer, writs = {}, total = 0, rep = 0, have = 0 }
        byKey[key] = group
        groups[#groups + 1] = group
      end
      group.writs[#group.writs + 1] = entry
      group.total = group.total + entry.total
      group.rep = group.rep + entry.rep
    end
  end
  for _, group in ipairs(groups) do
    group.per100 = group.total / group.rep * 100
    for _, writID in ipairs(ns.CustomerWrits(group.customer)) do
      if (counts[writID] or 0) > 0 then
        group.have = group.have + 1
      end
    end
  end
  table.sort(groups, function(a, b)
    if a.per100 ~= b.per100 then
      return a.per100 < b.per100
    end
    return #a.writs > #b.writs
  end)
  local result = {}
  for index = 1, math.min(max or #groups, #groups) do
    result[index] = groups[index]
  end
  return result
end

-- Every crate on the auction house by what it costs to turn in (2026-11-28, the user's request: the crate's price
-- and what filling it costs, sorted by both together): a Waylaid Crate's price plus its cheapest priced fill, a
-- Sealed crate's price alone (already filled). Only crates with an auction price, and Waylaid Crates with a priced
-- fill. { { itemID, name, info, favor, price, fill (CrateFillOptions entry or nil), fillCost, total, perFavor } },
-- cheapest total first, at most `max`.
function ns.CheapestCrates(max)
  local list = {}
  local function Add(itemID, fallback)
    local price = ns.Price(itemID)
    if not price then
      return
    end
    local name = ns.ItemName(itemID) or fallback -- (English until the game has the item's name)
    local favor, _, info = ns.CrateFavor(itemID, name)
    if not (favor and favor > 0 and info) then
      return
    end
    local fill, fillCost = nil, 0
    if not info.filled then
      fill = ns.CrateFillOptions(info)[1]
      if not (fill and fill.cost) then
        return
      end
      fillCost = fill.cost
    end
    local total = price + fillCost
    list[#list + 1] = { itemID = itemID, name = name, info = info, favor = favor, price = price, fill = fill,
      fillCost = fillCost, total = total, perFavor = total / favor }
  end
  for itemID, crate in pairs(ns.CRATE_ITEMS) do
    Add(itemID, ("Waylaid Crate: %s %s"):format(crate[1], crate[2]))
  end
  for itemID, level in pairs(ns.SEALED_CRATE_ITEMS) do
    Add(itemID, ("Sealed %s Crate"):format(level))
  end
  table.sort(list, function(a, b)
    if a.total ~= b.total then
      return a.total < b.total
    end
    if a.perFavor ~= b.perFavor then
      return a.perFavor < b.perFavor
    end
    return a.itemID < b.itemID
  end)
  for index = #list, (max or #list) + 1, -1 do
    list[index] = nil
  end
  return list
end

-- Which ranking the window's cheapest list shows: "writ", "npc" or "zone". (Before zones it was the
-- cheapestByNPC check box.)
function ns.CheapestMode()
  local db = DB()
  local mode = db.cheapestBy or (db.cheapestByNPC and "npc") or "writ"
  return (mode == "npc" or mode == "zone") and mode or "writ" -- (crates have their own tab since 2026-11-28)
end

function ns.SetCheapestMode(mode)
  if CommerceAuthorityDB then
    CommerceAuthorityDB.cheapestBy = mode
    CommerceAuthorityDB.cheapestByNPC = nil
  end
end

-- The cheapest zones to go to: every NPC of ns.CheapestCustomers grouped by zone, with all their priced writs.
-- { { mapID, name, npcs = { NPC groups, cheapest first }, writs = { cheapest-list entries }, total, rep, per100,
-- have }, ... }, cheapest per 100 reputation first, at most `max`.
function ns.CheapestZones(max, counts)
  local zones, byMap = {}, {}
  for _, group in ipairs(ns.CheapestCustomers(nil, counts)) do
    local mapID = group.customer.mapID
    local zone = byMap[mapID]
    if not zone then
      zone = { mapID = mapID, name = ns.MapName(mapID), npcs = {}, writs = {}, total = 0, rep = 0, have = 0 }
      byMap[mapID] = zone
      zones[#zones + 1] = zone
    end
    zone.npcs[#zone.npcs + 1] = group
    for _, entry in ipairs(group.writs) do
      zone.writs[#zone.writs + 1] = entry
    end
    zone.total = zone.total + group.total
    zone.rep = zone.rep + group.rep
    zone.have = zone.have + group.have
  end
  for _, zone in ipairs(zones) do
    zone.per100 = zone.total / zone.rep * 100
  end
  table.sort(zones, function(a, b)
    if a.per100 ~= b.per100 then
      return a.per100 < b.per100
    end
    return #a.writs > #b.writs
  end)
  for index = (max or #zones) + 1, #zones do
    zones[index] = nil
  end
  return zones
end

-- "1g 50s", "75s", "2.5g", "30c" -> copper. A number without g, s or c is silver. nil when the text isn't money
-- (Tylesser - Auctionator Profit Sort's ParseMoney).
function ns.ParseMoney(text)
  text = tostring(text or ""):lower():gsub(",", ".")
  if not text:find("%d") then
    return text:match("^%s*$") and 0 or nil
  end
  local total, bare = 0, 0
  local rest = text:gsub("(%d*%.?%d+)%s*([gsc]?)", function(number, unit)
    local factor = unit == "g" and 10000 or unit == "c" and 1 or 100
    if unit == "" then
      bare = bare + 1
    end
    total = total + tonumber(number) * factor
    return ""
  end)
  if bare > 1 or rest:find("%S") then
    return nil
  end
  return math.floor(total + 0.5)
end

-- Crate price alert (2026-11-28, the user's request): when crateAlert is on, every crate of ns.CheapestCrates whose
-- total (crate + cheapest fill) is at or under crateAlertBelow gets one chat line per session (and a sound, with
-- crateAlertSound). Checked after price updates (Auctionator's database, the auction house closing) and when the
-- window shows the ranking. Returns the crates it told about.
local alerted = {}
function ns.ResetCrateAlerts()
  alerted = {}
end

function ns.CheckCrateAlert()
  local db = DB()
  local below = tonumber(db.crateAlertBelow)
  if not (db.crateAlert and below and below > 0) then
    return {}
  end
  local found = {}
  for _, entry in ipairs(ns.CheapestCrates()) do
    if entry.total > below then
      break -- cheapest first
    end
    if not alerted[entry.itemID] then
      alerted[entry.itemID] = true
      found[#found + 1] = entry
    end
  end
  if #found == 0 then
    return found
  end
  local prefix = ns.T and ns.T.Prefix and ns.T.Prefix("Commerce Authority") or "Commerce Authority: "
  for index, entry in ipairs(found) do
    if index > 3 then
      print(prefix .. L["%d more crates under %s."]:format(#found - 3, ns.Money(below)))
      break
    end
    local what = entry.fill and L["%s with its fill"]:format(ns.Money(entry.total)) or ns.Money(entry.total)
    print(prefix .. L["%s costs %s on the auction house (%s Favor, %s per Favor): under your %s."]:format(entry.name,
      what, ns.Number(entry.favor), ns.Money(entry.perFavor), ns.Money(below)))
  end
  if db.crateAlertSound and PlaySound then
    pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959)
  end
  return found
end

-- After a price update: checked once things have settled (a scan updates many prices at once).
local alertPending = false
function ns.RequestCrateAlert()
  if not DB().crateAlert then
    return
  end
  if not (C_Timer and C_Timer.After) then
    ns.CheckCrateAlert()
    return
  end
  if alertPending then
    return
  end
  alertPending = true
  C_Timer.After(3, function()
    alertPending = false
    ns.InvalidateCheapest()
    ns.CheckCrateAlert()
  end)
end
