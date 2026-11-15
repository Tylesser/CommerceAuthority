local _, ns = ...

-- The Commerce Authority window (/aca): reputation and Merchant's Favor, what your bags are worth, the writ
-- quests you have (with waypoints), how far each standing is, the cheapest reputation on the auction house
-- (with a buy list for Auctionator) and this session's turn-ins.

local WIDTH = 400
local HEIGHT = 580
local PAD = 16
local INNER = WIDTH - PAD * 2
local CHEAP_ROWS = 8
local QUEST_ROWS = 4
local window

local function Text(parent, template, color)
  local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  text:SetJustifyH("LEFT")
  if color then
    text:SetTextColor(color[1], color[2], color[3])
  end
  return text
end

local function SavePosition(frame)
  local point, _, relativePoint, x, y = frame:GetPoint(1)
  CommerceAuthorityDB.position = { point, relativePoint, x, y }
end

local function RestorePosition(frame)
  frame:ClearAllPoints()
  local position = CommerceAuthorityDB and CommerceAuthorityDB.position
  if type(position) == "table" and position[1] then
    frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  end
end

local function HideTooltip()
  GameTooltip:Hide()
end

local function ItemTooltip(owner, itemID, hint)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  if GameTooltip.SetItemByID then
    GameTooltip:SetItemByID(itemID)
  else
    GameTooltip:SetHyperlink("item:" .. itemID)
  end
  if hint then
    GameTooltip:AddLine(hint, 0.6, 0.6, 0.6)
  end
  GameTooltip:Show()
end

local function Heading(y, text)
  local heading = ns.T.Heading(window, text, INNER)
  heading:SetPoint("TOPLEFT", PAD, y)
  return heading
end

-- Cheapest list rows ---------------------------------------------------------------------------------

local function CheapRow(index)
  local row = CreateFrame("Button", nil, window)
  row:SetSize(INNER, 16)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.T.GOLD[1], ns.T.GOLD[2], ns.T.GOLD[3], 0.12)
  row.name = Text(row)
  row.name:SetPoint("LEFT", 2, 0)
  row.name:SetPoint("RIGHT", -110, 0)
  row.name:SetWordWrap(false)
  row.cost = Text(row)
  row.cost:SetPoint("RIGHT", -2, 0)
  row.cost:SetJustifyH("RIGHT")
  row:SetScript("OnEnter", function(self)
    if self.writID then
      ItemTooltip(self, self.writID, "Shift-click to link it in chat.")
    end
  end)
  row:SetScript("OnLeave", HideTooltip)
  row:SetScript("OnClick", function(self)
    if self.writID and IsShiftKeyDown and IsShiftKeyDown() then
      local link = ns.ItemLink(self.writID)
      if link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
      end
    end
  end)
  row.index = index
  return row
end

-- Quest rows ------------------------------------------------------------------------------------------

local function QuestRow()
  local row = CreateFrame("Frame", nil, window)
  row:SetSize(INNER, 18)
  row.way = ns.T.Button(row, 44, 16, "Way")
  row.way:SetPoint("RIGHT", 0, 0)
  row.way:SetScript("OnClick", function()
    if row.questID then
      ns.SetWritWaypoint(row.questID, row.title)
    end
  end)
  row.way:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Waypoint")
    GameTooltip:AddLine("Puts a waypoint on where this writ is delivered (TomTom when installed).", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row.way:SetScript("OnLeave", HideTooltip)
  row.name = Text(row)
  row.name:SetPoint("LEFT", 2, 0)
  row.name:SetPoint("RIGHT", row.way, "LEFT", -6, 0)
  row.name:SetWordWrap(false)
  return row
end

local function Create()
  local T = ns.T
  window = CreateFrame("Frame", "CommerceAuthorityWindow", UIParent)
  window:SetSize(WIDTH, HEIGHT)
  window:SetFrameStrata("MEDIUM")
  window:SetClampedToScreen(true)
  window:SetMovable(true)
  window:EnableMouse(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", window.StartMoving)
  window:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition(self)
  end)
  window:SetScript("OnShow", function()
    ns.RefreshWindow()
  end)
  T.Stone(window)
  T.TitleBar(window, "Commerce Authority")
  local close = T.CloseButton(window)
  close:SetPoint("TOPRIGHT", -10, -9)
  close:SetScript("OnClick", function()
    window:Hide()
  end)
  -- Esc closes it, like other windows.
  if UISpecialFrames then
    table.insert(UISpecialFrames, "CommerceAuthorityWindow")
  end

  window.faction = Text(window, "GameFontNormal")
  window.faction:SetPoint("TOPLEFT", PAD, -44)
  window.faction:SetPoint("RIGHT", -PAD, 0)
  window.faction:SetWordWrap(false)

  local bar = CreateFrame("Frame", nil, window)
  bar:SetPoint("TOPLEFT", PAD, -64)
  bar:SetSize(INNER, 12)
  local barBack = bar:CreateTexture(nil, "BACKGROUND")
  barBack:SetAllPoints()
  barBack:SetColorTexture(0, 0, 0, 0.6)
  bar.fill = bar:CreateTexture(nil, "ARTWORK")
  bar.fill:SetPoint("TOPLEFT")
  bar.fill:SetPoint("BOTTOMLEFT")
  bar.fill:SetColorTexture(0.2, 0.7, 0.3, 1)
  bar.bags = bar:CreateTexture(nil, "ARTWORK", nil, -1)
  bar.bags:SetPoint("TOPLEFT", bar.fill, "TOPRIGHT")
  bar.bags:SetPoint("BOTTOMLEFT", bar.fill, "BOTTOMRIGHT")
  bar.bags:SetColorTexture(0.2, 0.7, 0.3, 0.35)
  T.Outline(bar, 0, T.BRONZE, 1)
  bar.text = Text(bar)
  bar.text:SetPoint("CENTER")
  window.bar = bar

  window.favor = Text(window)
  window.favor:SetPoint("TOPLEFT", PAD, -84)
  window.favor:SetPoint("RIGHT", -PAD, 0)
  window.favor:SetWordWrap(false)

  Heading(-106, "In your bags")
  window.bags = Text(window)
  window.bags:SetPoint("TOPLEFT", PAD, -126)
  window.bags:SetPoint("RIGHT", -PAD, 0)
  window.bags:SetSpacing(2)

  Heading(-192, "Writ quests")
  window.quests = {}
  for index = 1, QUEST_ROWS do
    local row = QuestRow()
    row:SetPoint("TOPLEFT", PAD, -210 - (index - 1) * 18)
    window.quests[index] = row
  end
  window.noQuests = Text(window, "GameFontDisableSmall")
  window.noQuests:SetPoint("TOPLEFT", PAD + 2, -212)
  window.noQuests:SetPoint("RIGHT", -PAD, 0)

  Heading(-290, "Next standings")
  window.goals = Text(window)
  window.goals:SetPoint("TOPLEFT", PAD, -310)
  window.goals:SetPoint("RIGHT", -PAD, 0)
  window.goals:SetSpacing(2)

  Heading(-364, "Cheapest reputation")
  local mine = T.Check(window, "Only my professions", "GameFontHighlightSmall")
  mine:SetPoint("TOPLEFT", PAD - 4, -380)
  mine:SetScript("OnShow", function(self)
    self:SetChecked(CommerceAuthorityDB.onlyMyProfessions)
  end)
  mine:SetScript("OnClick", function(self)
    CommerceAuthorityDB.onlyMyProfessions = self:GetChecked() and true or false
    ns.InvalidateCheapest()
    ns.RefreshWindow()
  end)
  mine:SetChecked(CommerceAuthorityDB.onlyMyProfessions)
  window.mine = mine
  local buy = T.Button(window, 96, 20, "Buy list")
  buy:SetPoint("TOPRIGHT", -PAD, -381)
  buy:SetScript("OnClick", function()
    ns.CreateBuyList()
  end)
  buy:SetScript("OnEnter", function(self)
    local plan = ns.PlanPurchases()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Buy list")
    GameTooltip:AddLine("Makes the Auctionator shopping list \"" .. ns.SHOPPING_LIST .. "\": the cheapest writs for "
      .. "the reputation you still need to your next standing, and the items they ask for.", 1, 1, 1, true)
    if #plan.picks > 0 then
      GameTooltip:AddLine(("%d writs, about %s reputation, about %s"):format(#plan.picks, ns.Number(plan.rep),
        ns.Money(plan.cost)), 0.25, 1, 0.25)
    end
    GameTooltip:Show()
  end)
  buy:SetScript("OnLeave", HideTooltip)
  window.buy = buy

  window.rows = {}
  for index = 1, CHEAP_ROWS do
    local row = CheapRow(index)
    row:SetPoint("TOPLEFT", PAD, -406 - (index - 1) * 16)
    window.rows[index] = row
  end
  window.empty = Text(window, "GameFontDisableSmall")
  window.empty:SetPoint("TOPLEFT", PAD + 2, -408)
  window.empty:SetPoint("RIGHT", -PAD, 0)

  window.session = Text(window, "GameFontDisableSmall")
  window.session:SetPoint("BOTTOMLEFT", PAD, 14)
  window.session:SetPoint("RIGHT", -PAD, 0)
  window.session:SetWordWrap(false)

  RestorePosition(window)
  window:Hide()
end

local function Bags(summary)
  local lines = {}
  if summary.writs > 0 then
    lines[#lines + 1] = ("%d writs: %s reputation"):format(summary.writs, ns.Number(summary.writRep))
  end
  if summary.sealedWrits > 0 then
    lines[#lines + 1] = ("%d sealed writs: %s reputation once done"):format(summary.sealedWrits,
      ns.Number(summary.sealedRep))
  end
  if summary.crates > 0 then
    lines[#lines + 1] = ("%d filled crates: about %s Favor + %s"):format(summary.crates,
      ns.Number(ns.ExpectedFavor(summary.crateFavor)), ns.Money(summary.crateFavor * ns.COPPER_PER_FAVOR))
  end
  if summary.toFill > 0 then
    lines[#lines + 1] = ("%d crates to fill: about %s Favor"):format(summary.toFill,
      ns.Number(ns.ExpectedFavor(summary.fillFavor)))
  end
  if #lines == 0 then
    return "No writs or crates in your bags."
  end
  return table.concat(lines, "\n")
end

local function Goals(faction, bagRep)
  local upcoming = ns.NextStandings(faction)
  if #upcoming == 0 then
    return faction and "Exalted. Nothing left to earn here but Merchant's Favor." or
      "Turn in your first crate at the trade hub to start."
  end
  local lines = {}
  local fewest = ns.TierRep(ns.WRIT_TIERS[3])
  local most = ns.TierRep(ns.WRIT_TIERS[1])
  for index = 1, math.min(#upcoming, 3) do
    local goal = upcoming[index]
    local needed = math.max(goal.needed - bagRep, 0)
    local text = ("%s: %s more"):format(ns.StandingName(goal.standingID), ns.Number(goal.needed))
    if bagRep > 0 then
      text = text .. (" (%s after your bags)"):format(ns.Number(needed))
    end
    if needed > 0 then
      text = text .. (", %d-%d writs"):format(math.ceil(needed / fewest), math.ceil(needed / most))
    end
    lines[#lines + 1] = text
  end
  return table.concat(lines, "\n")
end

local function Quests()
  local active = ns.ActiveWrits()
  for index, row in ipairs(window.quests) do
    local quest = active[index]
    if quest then
      local writ = ns.WRITS[quest.writID]
      local tier = ns.WritTier(quest.writID)
      row.questID, row.title = quest.questID, quest.title
      row.name:SetText(("%s |cff999999(%s)|r%s"):format(writ and writ[3] or quest.title or "?", tier.name,
        quest.complete and " |cff40ff40ready|r" or ""))
      row:Show()
    else
      row.questID = nil
      row:Hide()
    end
  end
  if #active == 0 then
    window.noQuests:SetText("No writ quests. Use a Craftsman's Writ from your bags to start one.")
  elseif #active > QUEST_ROWS then
    window.noQuests:SetText("")
    window.quests[QUEST_ROWS].name:SetText(window.quests[QUEST_ROWS].name:GetText() ..
      (" |cff999999+%d more|r"):format(#active - QUEST_ROWS))
  else
    window.noQuests:SetText("")
  end
end

local function Cheapest()
  local cheapest = ns.CheapestWrits(CHEAP_ROWS)
  for index, row in ipairs(window.rows) do
    local entry = cheapest[index]
    if entry then
      local writ = ns.WRITS[entry.writID]
      local tier = ns.WritTier(entry.writID)
      row.writID = entry.writID
      row.name:SetText(("%s |cff999999(%s, %d)|r"):format(writ[3], tier.name, entry.rep))
      row.cost:SetText(("%s |cff999999/ 100|r"):format(ns.Money(entry.per100)))
      row:Show()
    else
      row.writID = nil
      row:Hide()
    end
  end
  if #cheapest > 0 then
    window.empty:SetText("")
  elseif #ns.PriceSourceNames() == 0 then
    window.empty:SetText("Install Auctionator, TradeSkillMaster or Auctioneer to see auction prices.")
  elseif CommerceAuthorityDB.onlyMyProfessions and next(ns.PlayerProfessions()) == nil then
    window.empty:SetText("No crafting profession found on this character.")
  else
    window.empty:SetText("No priced writs yet. Scan the auction house, or search for \"Craftsman's Writ\".")
  end
end

function ns.RefreshWindow()
  if not (window and window:IsShown()) then
    return
  end
  local faction = ns.Faction()
  local summary = ns.BagSummary()
  local bagRep = summary.writRep
  local bar = window.bar
  if faction then
    window.faction:SetText(("%s: |cffffffff%s|r"):format(faction.name, ns.StandingName(faction.standingID)))
    local span = math.max((faction.max or 1) - (faction.min or 0), 1)
    local done = math.min(math.max((faction.value or 0) - (faction.min or 0), 0), span)
    local width = bar:GetWidth()
    bar.fill:SetWidth(math.max(done / span * width, 0.01))
    bar.bags:SetWidth(math.max(math.min(bagRep, span - done) / span * width, 0.01))
    bar.text:SetText(("%s / %s"):format(ns.Number(done), ns.Number(span)))
  else
    window.faction:SetText(ns.MyFactionName() .. ": |cff999999no reputation yet|r")
    bar.fill:SetWidth(0.01)
    bar.bags:SetWidth(0.01)
    bar.text:SetText("Trade hub: " .. (ns.HUBS[ns.Side()] or ns.HUBS.Alliance))
  end

  local favor = ns.Favor()
  if favor then
    local text = "Merchant's Favor: |cffffffff" .. ns.Number(favor) .. "|r"
    local coming = ns.ExpectedFavor(summary.crateFavor)
    if coming > 0 then
      text = text .. ("  (about %s after your crates)"):format(ns.Number(favor + coming))
    end
    window.favor:SetText(text)
  else
    window.favor:SetText("Merchant's Favor: not on this game version")
  end
  window.bags:SetText(Bags(summary))
  Quests()
  window.goals:SetText(Goals(faction, bagRep))
  Cheapest()

  local session = ns.session
  window.session:SetText(("This session: +%s Favor, +%s reputation, %d crates, %d writs%s"):format(
    ns.Number(session.favor), ns.Number(session.rep), session.crates, session.writs,
    session.bonuses > 0 and (", " .. session.bonuses .. " bonus") or ""))
end

-- Refreshes the window at most twice a second.
local refreshPending = false
function ns.RequestRefresh()
  if not (window and window:IsShown()) then
    return
  end
  if not (C_Timer and C_Timer.After) then
    ns.RefreshWindow()
    return
  end
  if refreshPending then
    return
  end
  refreshPending = true
  C_Timer.After(0.5, function()
    refreshPending = false
    ns.RefreshWindow()
  end)
end

function ns.ToggleWindow()
  if not window then
    Create()
  end
  window:SetShown(not window:IsShown())
end

function ns.Window()
  return window
end
