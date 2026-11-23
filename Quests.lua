local _, ns = ...

-- Writ quests in your quest log, who takes each writ (its "customer", an NPC somewhere in the world), the
-- writs you hold grouped by customer so one trip delivers them all, and waypoints (TomTom when installed,
-- else the game's own map pin).

local PREFIX = "|cfff0c24eCommerce Authority:|r "

local function IsComplete(questID, fallback)
  if C_QuestLog and C_QuestLog.IsComplete then
    local ok, complete = pcall(C_QuestLog.IsComplete, questID)
    if ok then
      return complete and true or false
    end
  end
  return fallback and true or false
end

-- { { questID, writID, title, complete }, ... } for the WoW Forever writ quests you have.
function ns.ActiveWrits()
  local list = {}
  local function Add(questID, title, complete)
    local writID = ns.WritForQuest(questID)
    if writID and ns.WritTier(writID) then
      list[#list + 1] = { questID = questID, writID = writID, title = title, complete = IsComplete(questID, complete) }
    end
  end
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for index = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
      local info = C_QuestLog.GetInfo(index)
      if info and not info.isHeader and info.questID then
        Add(info.questID, info.title)
      end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for index = 1, GetNumQuestLogEntries() or 0 do
      local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index)
      if not isHeader and questID then
        Add(questID, title, isComplete == 1 or isComplete == true)
      end
    end
  end
  return list
end

-- Where a quest's delivery spot is: mapID, x, y (0-1), or nil.
function ns.QuestLocation(questID)
  if C_QuestLog and C_QuestLog.GetNextWaypoint then
    local ok, mapID, x, y = pcall(C_QuestLog.GetNextWaypoint, questID)
    if ok and mapID and x and y then
      return mapID, x, y
    end
  end
  -- The quest's pin on your map, or on the maps above it (zone, continent).
  if C_Map and C_Map.GetBestMapForUnit and C_QuestLog and C_QuestLog.GetQuestsOnMap then
    local mapID = C_Map.GetBestMapForUnit("player")
    local guard = 0
    while mapID and mapID > 0 and guard < 6 do
      guard = guard + 1
      local ok, quests = pcall(C_QuestLog.GetQuestsOnMap, mapID)
      for _, quest in ipairs(ok and quests or {}) do
        if quest.questID == questID and quest.x and quest.y then
          return mapID, quest.x, quest.y
        end
      end
      local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
      mapID = info and info.parentMapID
    end
  end
end

function ns.MapName(mapID)
  local info = mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
  return info and info.name or "?"
end

-- Puts a waypoint on mapID at x, y (0-1). Returns true when one was set.
local function Waypoint(mapID, x, y, title)
  local where = ("%s %.1f, %.1f"):format(ns.MapName(mapID), x * 100, y * 100)
  if TomTom and TomTom.AddWaypoint then
    TomTom:AddWaypoint(mapID, x, y, { title = title, from = "Commerce Authority" })
  elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
  else
    print(PREFIX .. ("%s: %s"):format(title or "the writ", where))
    return false
  end
  print(PREFIX .. ("waypoint for %s: %s"):format(title or "the writ", where))
  return true
end

-- Puts a waypoint on a writ's delivery spot. Without a known spot, tracks the quest and opens the map.
function ns.SetWritWaypoint(questID, title)
  local mapID, x, y = ns.QuestLocation(questID)
  if mapID then
    Waypoint(mapID, x, y, title)
    return true
  end
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
    pcall(C_SuperTrack.SetSuperTrackedQuestID, questID)
  end
  if QuestMapFrame_OpenToQuestDetails then
    pcall(QuestMapFrame_OpenToQuestDetails, questID)
  elseif ToggleWorldMap then
    ToggleWorldMap()
  end
  print(PREFIX .. "the delivery spot for " .. (title or "this writ") .. " is marked on your world map.")
  return false
end

-- Customers -----------------------------------------------------------------------------------------

local function LearnedCustomers()
  local db = CommerceAuthorityDB
  return db and db.learned and db.learned.customers or {}
end

-- Who takes a writ: { name, mapID, x, y (0-100), learned }, or nil while not known. What you saw at a turn-in
-- wins over the built-in list.
function ns.WritCustomer(writID)
  local seen = writID and LearnedCustomers()[writID]
  if type(seen) == "table" and seen[1] and seen[2] then
    return { name = seen[1], mapID = seen[2], x = seen[3] or 0, y = seen[4] or 0, learned = true }
  end
  local known = writID and ns.WRIT_CUSTOMERS[writID]
  if known then
    return { name = known[1], mapID = known[2], x = known[3], y = known[4] }
  end
end

-- The same NPC on the same map is one customer, whichever writ it was found through.
function ns.CustomerKey(customer)
  return customer.name .. "@" .. tostring(customer.mapID)
end

-- "Kzixx, Duskwood (81.8, 19.8)"
function ns.CustomerText(customer)
  return ("%s, %s (%.1f, %.1f)"):format(customer.name, ns.MapName(customer.mapID), customer.x, customer.y)
end

-- Every writ a customer takes, Journeyman first.
function ns.CustomerWrits(customer)
  local key = ns.CustomerKey(customer)
  local list = {}
  for writID = ns.FOREVER_WRIT_FIRST, ns.FOREVER_WRIT_LAST do
    local other = ns.WritCustomer(writID)
    if other and ns.CustomerKey(other) == key then
      list[#list + 1] = writID
    end
  end
  return list
end

function ns.SetCustomerWaypoint(customer)
  return Waypoint(customer.mapID, customer.x / 100, customer.y / 100, customer.name)
end

-- The NPC whose quest dialog is open and where you stand: { name, mapID, x, y (0-100) }, or nil (no NPC, or
-- no map position, as in instances).
local function Secret(value)
  return value ~= nil and issecretvalue ~= nil and issecretvalue(value) == true
end

function ns.CurrentCustomer()
  local name = UnitName and UnitName("npc")
  -- the NPC's name can be secret (the user's error at a writ hand-in, 2026-11-21): test before any comparison
  if name == nil or Secret(name) or name == "" then
    return nil
  end
  local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local position = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
  local x, y
  if position then
    if position.GetXY then
      x, y = position:GetXY()
    else
      x, y = position.x, position.y
    end
  end
  if not (x and y) or Secret(x) or Secret(y) or (x == 0 and y == 0) then
    return nil
  end
  return { name, mapID, math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10 }
end

-- Remembers who took a writ (called at its turn-in).
function ns.LearnCustomer(writID, seen)
  local db = CommerceAuthorityDB
  if writID and seen and db and db.learned then
    db.learned.customers = db.learned.customers or {}
    db.learned.customers[writID] = seen
  end
end

-- The writs you hold, in your bags or as quests, grouped by who takes them:
-- { { customer (nil while not known), ready = n, writs = { { writID, questID, ready }, ... } }, ... }.
-- A writ is ready when its quest is complete or, not opened yet, your bags hold what it asks for. Writs with
-- an unknown customer each get their own group. Customers with the most writs come first.
-- The Forever writs you hold: [writID] = { writID, questID (when started), title, ready }. Ready = its quest
-- is complete or, not opened yet, your bags hold what it asks for.
function ns.HeldWrits(counts)
  counts = counts or ns.BagCounts()
  local held = {}
  for _, quest in ipairs(ns.ActiveWrits()) do
    held[quest.writID] = { writID = quest.writID, questID = quest.questID, title = quest.title,
      ready = quest.complete }
  end
  for itemID in pairs(counts) do
    if not held[itemID] and ns.WritTier(itemID) then
      local writ = ns.Writ(itemID)
      local wanted = writ and ns.WantedItem(writ)
      local need = writ and ns.WritCount(itemID, writ) or 1
      held[itemID] = { writID = itemID, ready = wanted and (counts[wanted] or 0) >= need or false }
    end
  end
  return held
end

function ns.Deliveries(counts)
  local held = ns.HeldWrits(counts)
  local groups, byKey = {}, {}
  for writID, entry in pairs(held) do
    local customer = ns.WritCustomer(writID)
    local group = customer and byKey[ns.CustomerKey(customer)]
    if not group then
      group = { customer = customer, writs = {}, ready = 0 }
      groups[#groups + 1] = group
      if customer then
        byKey[ns.CustomerKey(customer)] = group
      end
    end
    group.writs[#group.writs + 1] = entry
    if entry.ready then
      group.ready = group.ready + 1
    end
  end
  for _, group in ipairs(groups) do
    table.sort(group.writs, function(a, b)
      return a.writID < b.writID
    end)
  end
  table.sort(groups, function(a, b)
    if (a.customer ~= nil) ~= (b.customer ~= nil) then
      return a.customer ~= nil
    end
    if #a.writs ~= #b.writs then
      return #a.writs > #b.writs
    end
    if a.ready ~= b.ready then
      return a.ready > b.ready
    end
    return a.writs[1].writID < b.writs[1].writID
  end)
  return groups
end

-- Every NPC who takes writs, with all its writs, grouped by zone, and the writs whose NPC isn't known yet:
-- { zones = { { mapID, name, npcs = { NPC groups }, held, writs, cost, unpriced }, ... }, npcs = { { customer,
-- writs = { writID, ... }, held = n, zone, cost, unpriced }, ... }, unknown = { writID, ... }, held }. cost =
-- what buying the writs you don't hold costs on the auction house (writ + item; `unpriced` have no price yet). Zones (and NPCs in them) where you hold
-- writs come first, then by name.
-- `search` (lower case) keeps NPCs whose name or zone matches, or their matching writs. NPCs you hold writs
-- for come first (most first), then by zone and name.
-- Whether you turned the writ in today: every writ is a daily quest, flagged completed until the daily reset.
function ns.WritDoneToday(writID)
  local questID = ns.WritQuestID(writID)
  local flagged = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
  if not (questID and flagged) then
    return false
  end
  local ok, done = pcall(flagged, questID)
  return ok and done == true
end

-- `options` (the Writ NPCs window's filters): { tier = "Journeyman" / "Expert" / "Artisan" (nil: every level),
-- mine = true (only writs your crafting professions make), notDone = true (only writs not turned in today) }.
-- The continent a zone lies on: its map ID and name (the Writ NPCs window groups its zones under them, the user's
-- request 2026-11-24). Walks C_Map.GetMapInfo's parents up to the continent (Enum.UIMapType.Continent); the
-- classic zones' continents are known too while the map data isn't there.
ns.CONTINENTS = { [1414] = "Kalimdor", [1415] = "Eastern Kingdoms" }
ns.ZONE_CONTINENT = { [2548] = 1415 } -- Forever's own zones (the game's UiMap table): Riverglades
function ns.ContinentOf(mapID)
  local id, steps = mapID, 0
  local continent = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
  while id and steps < 8 and C_Map and C_Map.GetMapInfo do
    local ok, info = pcall(C_Map.GetMapInfo, id)
    if not ok or type(info) ~= "table" then
      break
    end
    if info.mapType == continent then
      return id, info.name or ns.CONTINENTS[id] or "?"
    end
    id, steps = info.parentMapID, steps + 1
  end
  if ns.ZONE_CONTINENT[mapID] then
    local id = ns.ZONE_CONTINENT[mapID]
    return id, ns.CONTINENTS[id]
  elseif type(mapID) == "number" and mapID >= 1416 and mapID <= 1437 then
    return 1415, ns.CONTINENTS[1415]
  elseif type(mapID) == "number" and mapID >= 1438 and mapID <= 1452 then
    return 1414, ns.CONTINENTS[1414]
  end
  return 0, "Other zones"
end

function ns.CustomerDirectory(counts, search, options)
  local held = ns.HeldWrits(counts)
  local mine = options and options.mine and ns.PlayerProfessions() or nil
  local function Wanted(writID)
    local tier = ns.WritTier(writID)
    if options and options.tier and not (tier and tier.name == options.tier) then
      return false
    end
    if options and options.notDone and ns.WritDoneToday(writID) then
      return false
    end
    return not mine or mine[ns.WritProfession(writID) or ""] ~= nil
  end
  if search == "" then
    search = nil
  end
  local function Matches(text)
    return text and text:lower():find(search, 1, true) ~= nil
  end
  local npcs, byKey, unknown = {}, {}, {}
  for writID = ns.FOREVER_WRIT_FIRST, ns.FOREVER_WRIT_LAST do
    local customer = ns.WritCustomer(writID)
    local writName = ns.WRITS[writID] and ns.WRITS[writID][3]
    if not Wanted(writID) then
      -- filtered out (level or profession)
    elseif customer then
      local key = ns.CustomerKey(customer)
      local group = byKey[key]
      if not group then
        group = { customer = customer, writs = {}, held = 0, zone = ns.MapName(customer.mapID),
          matched = not search or Matches(customer.name) or Matches(ns.MapName(customer.mapID)) }
        byKey[key] = group
        npcs[#npcs + 1] = group
      end
      group.writs[#group.writs + 1] = writID
      group.writMatched = group.writMatched or (search and Matches(writName))
      if held[writID] then
        group.held = group.held + 1
      end
    elseif not search or Matches(writName) then
      unknown[#unknown + 1] = writID
    end
  end
  local result = {}
  -- what buying the listed writs you don't hold costs (cost: the priced ones; unpriced: how many have no price)
  local function Cost(group)
    group.cost, group.unpriced = 0, 0
    for _, writID in ipairs(group.writs) do
      if not held[writID] then
        local total = ns.WritCost(writID)
        if total then
          group.cost = group.cost + total
        else
          group.unpriced = group.unpriced + 1
        end
      end
    end
  end
  for _, group in ipairs(npcs) do
    if group.matched then
      result[#result + 1] = group
    elseif group.writMatched then
      local only = {}
      for _, writID in ipairs(group.writs) do
        if Matches(ns.WRITS[writID][3]) then
          only[#only + 1] = writID
        end
      end
      group.writs = only
      result[#result + 1] = group
    end
  end
  table.sort(result, function(a, b)
    if a.held ~= b.held then
      return a.held > b.held
    end
    if a.zone ~= b.zone then
      return a.zone < b.zone
    end
    return a.customer.name < b.customer.name
  end)
  local zones, byMap = {}, {}
  for _, group in ipairs(result) do
    Cost(group)
    local mapID = group.customer.mapID
    local zone = byMap[mapID]
    if not zone then
      zone = { mapID = mapID, name = group.zone, npcs = {}, held = 0, writs = 0, cost = 0, unpriced = 0 }
      byMap[mapID] = zone
      zones[#zones + 1] = zone
    end
    zone.npcs[#zone.npcs + 1] = group
    zone.held = zone.held + group.held
    zone.writs = zone.writs + #group.writs
    zone.cost = zone.cost + group.cost
    zone.unpriced = zone.unpriced + group.unpriced
  end
  table.sort(zones, function(a, b)
    if a.held ~= b.held then
      return a.held > b.held
    end
    return a.name < b.name
  end)
  return { zones = zones, npcs = result, unknown = unknown, held = held }
end

-- Waypoints on every NPC of a zone (a zone from ns.CheapestZones) with TomTom; the game's own map pin holds only
-- one, so without TomTom the first (cheapest) NPC gets it and the others are listed in chat.
function ns.SetZoneWaypoints(zone)
  if not (zone and zone.npcs[1]) then
    return false
  end
  if TomTom and TomTom.AddWaypoint then
    for _, group in ipairs(zone.npcs) do
      ns.SetCustomerWaypoint(group.customer)
    end
    return true
  end
  ns.SetCustomerWaypoint(zone.npcs[1].customer)
  if #zone.npcs > 1 then
    local others = {}
    for index = 2, #zone.npcs do
      local customer = zone.npcs[index].customer
      others[#others + 1] = ("%s %.1f, %.1f"):format(customer.name, customer.x, customer.y)
    end
    print(PREFIX .. ("also in %s: %s"):format(zone.name, table.concat(others, "; ")))
  end
  return true
end
