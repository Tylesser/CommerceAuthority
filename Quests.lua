local _, ns = ...

-- Writ quests in your quest log, and a waypoint to where each one is delivered. The game marks the spot on
-- the world map; this puts a waypoint on it (TomTom when installed, else the game's own map pin).

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
    local writID = questID and questID + ns.FOREVER_QUEST_OFFSET
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

local function MapName(mapID)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
  return info and info.name or "?"
end

-- Puts a waypoint on a writ's delivery spot. Without a known spot, tracks the quest and opens the map.
function ns.SetWritWaypoint(questID, title)
  local mapID, x, y = ns.QuestLocation(questID)
  if mapID then
    local where = ("%s %.1f, %.1f"):format(MapName(mapID), x * 100, y * 100)
    if TomTom and TomTom.AddWaypoint then
      TomTom:AddWaypoint(mapID, x, y, { title = title, from = "Commerce Authority" })
    elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
      C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
      if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
      end
    end
    print(PREFIX .. ("waypoint for %s: %s"):format(title or "the writ", where))
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
