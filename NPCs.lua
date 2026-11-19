local _, ns = ...

-- The Writ NPCs window (/aca npcs, or "All NPCs" in the main window): every NPC who takes Craftsman's Writs,
-- grouped by zone, with all the writs it takes and which of them you hold, so you can collect the writs of a
-- zone's NPCs and deliver them in one trip. Then the writs whose NPC isn't known yet. A search box filters by
-- NPC, zone or writ; a row under it filters by writ level and your professions. Zones (and the "not known yet"
-- group) fold with the button on their line, or a click on it away from the auction house.

local WIDTH = 440
local HEIGHT = 540
local PAD = 16
local INNER = WIDTH - PAD * 2
local ROW_HEIGHT = 16
local TOP = 124 -- where the list starts, below the search box, the filter row and the summary
local LEVELS = { false, "Journeyman", "Expert", "Artisan" } -- the level button's steps (false: every level)
local ROWS = math.floor((HEIGHT - TOP - 32) / ROW_HEIGHT)
local frame
local lines = {}
local held = {} -- the writs you hold (ns.HeldWrits), as of the last rebuild
local offset = 0

local function DB()
  return CommerceAuthorityDB or ns.defaults
end

-- Folded zones (by map ID, and "unknown" for the writs with no known NPC), kept between sessions.
local function Folded(key)
  return DB().npcFolded ~= nil and DB().npcFolded[key] == true
end

local function ToggleFold(key)
  local db = CommerceAuthorityDB
  if not db then
    return
  end
  db.npcFolded = db.npcFolded or {}
  db.npcFolded[key] = not Folded(key) or nil
  ns.RefreshNPCWindow()
end

local function FoldKey(line)
  if line.kind == "zone" then
    return line.zone.mapID
  elseif line.kind == "unknown" then
    return "unknown"
  end
end

local function Text(parent, template)
  local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  text:SetJustifyH("LEFT")
  return text
end

local function HideTooltip()
  GameTooltip:Hide()
end

local function WritLabel(writID)
  local writ = ns.WRITS[writID]
  local tier = ns.WritTier(writID)
  local rep = ns.WritReputation(writID)
  return ("%s |cff999999(%s, %s)|r"):format(writ and writ[3] or ("item " .. writID), tier and tier.name or "?",
    rep and ns.Number(rep) or "?")
end

-- What the right side of a writ line says: your writ's state, else its auction cost (writ + item).
-- "1 of 5 yours · 6g 20s" or "5 writs · 6g 20s": how many are yours, and what buying the rest costs ("+" when
-- some of them have no auction price yet).
local function CountAndCost(held, count, cost, unpriced)
  local text = held > 0 and ("|cff40ff40%d of %d yours|r"):format(held, count)
    or ("%d writ%s"):format(count, count == 1 and "" or "s")
  if cost > 0 then
    text = text .. (" |cff999999· %s%s|r"):format(ns.ShortMoney(cost), unpriced > 0 and "+" or "")
  end
  return text
end

local function WritState(writID, held)
  local mine = held[writID]
  if mine then
    if mine.ready then
      return "|cff40ff40yours, ready|r"
    end
    return mine.questID and "|cffffd100yours, needs the item|r" or "|cffffffffyours, not opened|r"
  end
  if ns.WritDoneToday(writID) then
    return "|cff999999done today|r"
  end
  local total = ns.WritCost(writID)
  return total and ("|cff999999%s|r"):format(ns.Money(total)) or "|cff666666no AH price|r"
end

-- Rows ----------------------------------------------------------------------------------------------------

local function OnEnter(row)
  local line = row.line
  if not line then
    return
  end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if line.kind == "writ" then
    if GameTooltip.SetItemByID then
      GameTooltip:SetItemByID(line.writID)
    else
      GameTooltip:SetHyperlink("item:" .. line.writID)
    end
    GameTooltip:AddLine("Click at the auction house to search for it. Shift-click to link it.", 0.6, 0.6, 0.6)
  elseif line.kind == "zone" then
    local zone = line.zone
    GameTooltip:AddLine(zone.name)
    GameTooltip:AddLine(("%d NPCs take %d writs here; you hold %d."):format(#zone.npcs, zone.writs, zone.held),
      1, 1, 1)
    if zone.cost > 0 then
      GameTooltip:AddLine(("Buying the others: %s on the auction house%s."):format(ns.Money(zone.cost),
        zone.unpriced > 0 and (", plus %d with no price yet"):format(zone.unpriced) or ""), 0.25, 1, 0.25, true)
    end
    GameTooltip:AddLine("Click at the auction house: search for the writs here you don't have, and their items. "
      .. "Way: waypoints to the NPCs here (all of them with TomTom, else the first).", 0.6, 0.6, 0.6, true)
  elseif line.kind == "npc" then
    local customer = line.group.customer
    GameTooltip:AddLine(customer.name)
    GameTooltip:AddLine(("%s %.1f, %.1f%s"):format(line.group.zone, customer.x, customer.y,
      customer.learned and " (seen at your turn-in)" or ""), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(("Takes %d writs; you hold %d."):format(#line.group.writs, line.group.held), 1, 1, 1)
    if line.group.cost > 0 then
      GameTooltip:AddLine(("Buying the others: %s on the auction house%s."):format(ns.Money(line.group.cost),
        line.group.unpriced > 0 and (", plus %d with no price yet"):format(line.group.unpriced) or ""), 0.25, 1,
        0.25, true)
    end
    GameTooltip:AddLine("Click at the auction house: search for its writs you don't have, and their items. Way: "
      .. "waypoint to " .. customer.name .. ".", 0.6, 0.6, 0.6, true)
  else
    GameTooltip:AddLine("Who takes these isn't known yet")
    GameTooltip:AddLine("Use the writ and the game marks the spot on your map. The addon remembers the NPC once "
      .. "you turn one in.", 1, 1, 1, true)
  end
  GameTooltip:Show()
end

local function Row()
  local row = CreateFrame("Button", nil, frame)
  row:SetSize(INNER, ROW_HEIGHT)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.T.GOLD[1], ns.T.GOLD[2], ns.T.GOLD[3], 0.12)
  row.way = ns.T.Button(row, 40, 15, "Way")
  row.way:SetPoint("RIGHT", 0, 0)
  row.way:SetScript("OnClick", function()
    local line = row.line
    if line and line.kind == "zone" then
      ns.SetZoneWaypoints(line.zone)
    elseif line and line.group then
      ns.SetCustomerWaypoint(line.group.customer)
    end
  end)
  row.fold = CreateFrame("Button", nil, row)
  row.fold:SetSize(14, 14)
  row.fold:SetPoint("LEFT", 0, 0)
  row.fold:SetScript("OnClick", function()
    local key = row.line and FoldKey(row.line)
    if key then
      ToggleFold(key)
    end
  end)
  row.name = Text(row)
  row.name:SetWordWrap(false)
  row.state = Text(row)
  row.state:SetJustifyH("RIGHT")
  row:SetScript("OnEnter", OnEnter)
  row:SetScript("OnLeave", HideTooltip)
  row:SetScript("OnClick", function(self)
    local line = self.line
    if not line then
      return
    end
    if line.kind == "writ" and IsShiftKeyDown and IsShiftKeyDown() then
      local link = ns.ItemLink(line.writID)
      if link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
      end
      return
    end
    if not ns.AuctionHouseOpen() then
      local key = FoldKey(line)
      if key then
        ToggleFold(key) -- away from the auction house a zone line folds
      end
      return
    end
    local writIDs = {}
    if line.kind == "writ" then
      writIDs[1] = line.writID
    elseif line.kind == "npc" then
      writIDs = line.group.writs
    elseif line.kind == "zone" then
      for _, group in ipairs(line.zone.npcs) do
        for _, writID in ipairs(group.writs) do
          writIDs[#writIDs + 1] = writID
        end
      end
    end
    ns.SearchWrits(writIDs, held)
  end)
  return row
end

local function ShowFold(row, key)
  if not key then
    row.fold:Hide()
    return
  end
  local folded = Folded(key)
  row.fold:SetNormalTexture(folded and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
  row.fold:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  row.fold.folded = folded
  row.fold:Show()
end

local function ShowLine(row, line, held)
  row.line = line
  row.name:ClearAllPoints()
  row.state:ClearAllPoints()
  ShowFold(row, FoldKey(line))
  if line.kind == "zone" then
    local zone = line.zone
    row.way:Show()
    row.name:SetPoint("LEFT", 18, 0)
    row.name:SetPoint("RIGHT", -206, 0)
    row.name:SetText(("|cffff9933%s|r |cff999999%d NPC%s|r"):format(zone.name, #zone.npcs,
      #zone.npcs == 1 and "" or "s"))
    row.state:SetPoint("RIGHT", -46, 0)
    row.state:SetText(CountAndCost(zone.held, zone.writs, zone.cost, zone.unpriced))
  elseif line.kind == "npc" then
    local group = line.group
    row.way:Show()
    row.name:SetPoint("LEFT", 12, 0)
    row.name:SetPoint("RIGHT", -206, 0)
    row.name:SetText(("|cffffd100%s|r |cff999999%.1f, %.1f|r"):format(group.customer.name, group.customer.x,
      group.customer.y))
    row.state:SetPoint("RIGHT", -46, 0)
    row.state:SetText(CountAndCost(group.held, #group.writs, group.cost, group.unpriced))
  elseif line.kind == "writ" then
    row.way:Hide()
    row.name:SetPoint("LEFT", line.group and 24 or 12, 0)
    row.name:SetPoint("RIGHT", -150, 0)
    row.name:SetText(WritLabel(line.writID))
    row.state:SetPoint("RIGHT", -2, 0)
    row.state:SetText(WritState(line.writID, held))
  else
    row.way:Hide()
    row.name:SetPoint("LEFT", 18, 0)
    row.name:SetPoint("RIGHT", -2, 0)
    row.name:SetText(("|cffffd100NPC not known yet|r |cff999999(%d writs)|r"):format(line.count))
    row.state:SetPoint("RIGHT", -2, 0)
    row.state:SetText("")
  end
  row:Show()
end

-- Window --------------------------------------------------------------------------------------------------

local function Scroll(delta)
  local maxOffset = math.max(#lines - ROWS, 0)
  offset = math.min(math.max(offset - delta * 3, 0), maxOffset)
  ns.RefreshNPCWindow(true)
end

local function Create()
  local T = ns.T
  frame = CreateFrame("Frame", "CommerceAuthorityNPCWindow", UIParent)
  frame:SetSize(WIDTH, HEIGHT)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    CommerceAuthorityDB.npcPosition = { point, relativePoint, x, y }
  end)
  frame:SetScript("OnShow", function()
    ns.RefreshNPCWindow()
  end)
  if frame.EnableMouseWheel then
    frame:EnableMouseWheel(true)
  end
  frame:SetScript("OnMouseWheel", function(_, delta)
    Scroll(delta)
  end)
  T.Stone(frame)
  T.TitleBar(frame, "Writ NPCs")
  local close = T.CloseButton(frame)
  close:SetPoint("TOPRIGHT", -10, -9)
  close:SetScript("OnClick", function()
    frame:Hide()
  end)
  if UISpecialFrames then
    table.insert(UISpecialFrames, "CommerceAuthorityNPCWindow")
  end

  local search = CreateFrame("EditBox", "CommerceAuthorityNPCSearch", frame, "InputBoxTemplate")
  search:SetSize(INNER - 8, 20)
  search:SetPoint("TOPLEFT", PAD + 6, -44)
  search:SetAutoFocus(false)
  T.EditBox(search)
  search.hint = Text(search, "GameFontDisableSmall")
  search.hint:SetPoint("LEFT", 2, 0)
  search.hint:SetText("Search an NPC, zone or writ")
  search:SetScript("OnTextChanged", function(self)
    self.hint:SetShown(self:GetText() == "")
    offset = 0
    ns.RefreshNPCWindow()
  end)
  search:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  search:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)
  frame.search = search

  local level = T.Button(frame, 96, 20, "All levels")
  level:SetPoint("TOPLEFT", PAD, -72)
  level:SetScript("OnClick", function()
    local db = CommerceAuthorityDB
    local current = 1
    for index, name in ipairs(LEVELS) do
      if (name or nil) == db.npcTier then
        current = index
      end
    end
    db.npcTier = LEVELS[current % #LEVELS + 1] or nil
    offset = 0
    ns.RefreshNPCWindow()
  end)
  level:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Writ level")
    GameTooltip:AddLine("Click to show every level, or only Journeyman, Expert or Artisan writs.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  level:SetScript("OnLeave", HideTooltip)
  frame.level = level
  local mine = T.Check(frame, "My professions", "GameFontHighlightSmall")
  mine:SetPoint("LEFT", level, "RIGHT", 10, 0)
  mine:SetScript("OnClick", function(self)
    CommerceAuthorityDB.npcMine = self:GetChecked() and true or false
    offset = 0
    ns.RefreshNPCWindow()
  end)
  ns.FitCheck(mine)
  frame.mine = mine
  local notDone = T.Check(frame, "Not done today", "GameFontHighlightSmall")
  notDone:SetPoint("LEFT", mine.label or mine.Text or mine, "RIGHT", 8, 0)
  notDone:SetScript("OnClick", function(self)
    CommerceAuthorityDB.npcNotDone = self:GetChecked() and true or false
    offset = 0
    ns.RefreshNPCWindow()
  end)
  notDone:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Not done today")
    GameTooltip:AddLine("Every writ can be turned in once a day: show only the ones you haven't turned in since the "
      .. "daily reset.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  notDone:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  ns.FitCheck(notDone)
  frame.notDone = notDone
  local foldAll = T.Button(frame, 80, 20, "Fold all")
  foldAll:SetPoint("TOPRIGHT", -PAD, -72)
  foldAll:SetScript("OnClick", function()
    local db = CommerceAuthorityDB
    local anyOpen = false
    for _, line in ipairs(lines) do
      local key = FoldKey(line)
      if key and not Folded(key) then
        anyOpen = true
      end
    end
    db.npcFolded = {}
    if anyOpen then
      for _, line in ipairs(lines) do
        local key = FoldKey(line)
        if key then
          db.npcFolded[key] = true
        end
      end
    end
    offset = 0
    ns.RefreshNPCWindow()
  end)
  frame.foldAll = foldAll

  frame.summary = Text(frame)
  frame.summary:SetPoint("TOPLEFT", PAD, -100)
  frame.summary:SetPoint("RIGHT", -PAD, 0)
  frame.summary:SetWordWrap(false)

  frame.rows = {}
  for index = 1, ROWS do
    local row = Row()
    row:SetPoint("TOPLEFT", PAD, -TOP - (index - 1) * ROW_HEIGHT)
    frame.rows[index] = row
  end

  frame.footer = Text(frame, "GameFontDisableSmall")
  frame.footer:SetPoint("BOTTOMLEFT", PAD, 14)
  frame.footer:SetPoint("RIGHT", -PAD, 0)
  frame.footer:SetWordWrap(false)

  frame:ClearAllPoints()
  local position = CommerceAuthorityDB and CommerceAuthorityDB.npcPosition
  if type(position) == "table" and position[1] then
    frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 420, 40)
  end
  frame:Hide()
end

-- Rebuilds the list (unless `keep`, when only scrolling) and shows the rows from the scroll offset.
function ns.RefreshNPCWindow(keep)
  if not (frame and frame:IsShown()) then
    return
  end
  if not keep then
    local db = DB()
    local text = frame.search:GetText() or ""
    local directory = ns.CustomerDirectory(nil, text:lower():match("^%s*(.-)%s*$"),
      { tier = db.npcTier, mine = db.npcMine, notDone = db.npcNotDone })
    frame.level:SetText(db.npcTier or "All levels")
    frame.mine:SetChecked(db.npcMine and true or false)
    frame.notDone:SetChecked(db.npcNotDone and true or false)
    held = directory.held
    lines = {}
    local writs, mine = 0, 0
    local anyOpen = false
    for _, zone in ipairs(directory.zones) do
      lines[#lines + 1] = { kind = "zone", zone = zone }
      local folded = Folded(zone.mapID)
      anyOpen = anyOpen or not folded
      for _, group in ipairs(zone.npcs) do
        if not folded then
          lines[#lines + 1] = { kind = "npc", group = group }
          for _, writID in ipairs(group.writs) do
            lines[#lines + 1] = { kind = "writ", writID = writID, group = group }
          end
        end
        writs = writs + #group.writs
        mine = mine + group.held
      end
    end
    if #directory.unknown > 0 then
      lines[#lines + 1] = { kind = "unknown", count = #directory.unknown }
      local folded = Folded("unknown")
      anyOpen = anyOpen or not folded
      for _, writID in ipairs(directory.unknown) do
        if not folded then
          lines[#lines + 1] = { kind = "writ", writID = writID }
        end
        if held[writID] then
          mine = mine + 1
        end
      end
    end
    frame.foldAll:SetText(anyOpen and "Fold all" or "Unfold all")
    frame.summary:SetText(("%d NPCs in %d zones take %d writs; %d with no known NPC. You hold %d."):format(
      #directory.npcs, #directory.zones, writs, #directory.unknown, mine))
    offset = math.min(offset, math.max(#lines - ROWS, 0))
  end
  for index, row in ipairs(frame.rows) do
    local line = lines[offset + index]
    if line then
      ShowLine(row, line, held)
    else
      row.line = nil
      row:Hide()
    end
  end
  if #lines == 0 then
    frame.footer:SetText("Nothing matches.")
  elseif #lines > ROWS then
    frame.footer:SetText(("Lines %d-%d of %d. Scroll with the mouse wheel."):format(offset + 1,
      math.min(offset + ROWS, #lines), #lines))
  else
    frame.footer:SetText("")
  end
end

function ns.ToggleNPCWindow()
  if not frame then
    Create()
  end
  frame:SetShown(not frame:IsShown())
end

function ns.NPCWindowShown()
  return frame ~= nil and frame:IsShown()
end

function ns.NPCWindow()
  return frame
end

function ns.ScrollNPCWindow(delta)
  Scroll(delta)
end
