local _, ns = ...

ns.defaults = {
  writTooltips = true,      -- writ tooltips: what it needs, prices, reputation
  crateTooltips = true,     -- crate tooltips: Merchant's Favor, silver, what fills it
  vendorMarks = true,       -- at the Commerce Authority vendors: what you can afford
  allSources = true,        -- every installed price addon in tooltips, not only the first
  onlyMyProfessions = false, -- the window's cheapest list: only writs your professions make
  cheapestBy = nil,         -- the window's cheapest list: "writ", "npc" or "zone" (nil: writ; ns.CheapestMode)
  position = nil,           -- the window's position
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
  return false
end
ns.IsCommerceFaction = IsCommerceFaction

local function Side()
  return UnitFactionGroup and UnitFactionGroup("player") or "Alliance"
end
ns.Side = Side

-- Your side's faction name: Azeroth Commerce Authority or Durotar Supply and Logistics.
function ns.MyFactionName()
  return ns.FACTION_NAMES[Side()] or ns.FACTION_NAMES.Alliance
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
  for index = 1, NumFactions() do
    local ok, faction = pcall(FactionByIndex, index)
    if ok and faction and faction.name == wanted then
      if faction.id and CommerceAuthorityDB then
        CommerceAuthorityDB.factionIDs[Side()] = faction.id
      end
      return faction
    end
  end
  local savedID = DB().factionIDs and DB().factionIDs[Side()]
  if savedID then
    local ok, faction = pcall(FactionByID, savedID)
    if ok and faction and faction.name == wanted then
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

-- Professions ---------------------------------------------------------------------------------------

local PROFESSIONS = { Alchemy = true, Blacksmithing = true, Engineering = true, Leatherworking = true,
  Tailoring = true }

-- { [profession name] = skill } for the crafting professions you have.
function ns.PlayerProfessions()
  local found = {}
  if GetProfessions and GetProfessionInfo then
    for _, index in ipairs({ GetProfessions() }) do
      if index then
        local ok, name, _, skill = pcall(GetProfessionInfo, index)
        if ok and name and PROFESSIONS[name] then
          found[name] = skill or 0
        end
      end
    end
  end
  if next(found) == nil and GetNumSkillLines and GetSkillLineInfo then
    for index = 1, GetNumSkillLines() do
      local name, isHeader, _, skill = GetSkillLineInfo(index)
      if name and not isHeader and PROFESSIONS[name] then
        found[name] = skill or 0
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
-- From names like "Waylaid Crate: Journeyman Ore" (to fill) and "Sealed Journeyman Crate" (filled).
-- nil for other items.
function ns.CrateInfo(itemID, name)
  name = name or ns.ItemName(itemID)
  if not name then
    return nil
  end
  local level, rest = name:match("^Waylaid Crate: (%a+) (.+)$")
  local filled = false
  if not level then
    level = name:match("^Sealed (%a+) Crate$")
    filled = level ~= nil
  end
  local info = level and ns.CRATE_LEVELS[level]
  if not info then
    return nil
  end
  local category = rest and ns.CrateCategory(rest)
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

-- Merchant's Favor for a crate: what crates of its level and kind gave you before, else the guide's amount.
-- Returns favor, learned (true when seen), info.
function ns.CrateFavor(itemID, name)
  local info = ns.CrateInfo(itemID, name)
  if not info then
    return nil
  end
  local usual = ns.UsualValue(DB().learned.crates[info.key])
  if usual then
    return usual, true, info
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

-- Which ranking the window's cheapest list shows: "writ", "npc" or "zone". (Before zones it was the
-- cheapestByNPC check box.)
function ns.CheapestMode()
  local db = DB()
  return db.cheapestBy or (db.cheapestByNPC and "npc") or "writ"
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
