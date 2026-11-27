local _, ns = ...
local L = ns.L

-- The Commerce Authority window (/aca), in two tabs (2026-11-28, the user's request: writs and crates are not the
-- same thing, give crates their own section). Writs: reputation, the writs in your bags, the ones you hold grouped
-- by who takes them (with waypoints), how far each standing is and the cheapest reputation on the auction house
-- (with a buy list for Auctionator). Crates: Merchant's Favor, the crates in your bags, the ones you have to fill
-- and every crate on the auction house by crate price + cheapest fill. Under both: this session's turn-ins.

local WIDTH = 400
local HEIGHT = 580
local PAD = 16
local INNER = WIDTH - PAD * 2
local CHEAP_ROWS = 8
local DELIVERY_ROWS = 4
local FILL_ROWS = 5 -- the Crates tab: crates to fill
local RANK_ROWS = 13 -- the Crates tab: the crate ranking (scrolls)
-- the cheapest list's rankings, switched by one button
local MODE_LABELS = { writ = L["By writ"], npc = L["By NPC"], zone = L["By zone"] }
local NEXT_MODE = { writ = "npc", npc = "zone", zone = "writ" }
local MODE_HELP = {
  writ = L["Writs sorted by what each costs per 100 reputation (the writ and the item it asks for)."],
  npc = L["The NPCs who take writs, by what buying all their priced writs costs per 100 reputation: one shopping list, one trip."],
  zone = L["Zones, by what buying all the priced writs their NPCs take costs per 100 reputation: one shopping list, one trip around the zone."],
}
local crateOffset = 0 -- the crate ranking scrolls (with the mouse wheel)
local window

-- "1 writ" / "5 writs" and the like.
local function Writs(count)
  return count == 1 and L["1 writ"] or L["%d writs"]:format(count)
end

local function Text(parent, template, color)
  local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  text:SetJustifyH("LEFT")
  if color then
    text:SetTextColor(color[1], color[2], color[3])
  end
  return text
end

-- A check box clickable over its own label only: the shared check boxes reach 200+ px to the right, and in a row
-- of controls they covered the next one (hovering "Not done today" lit "My professions", 2026-11-19).
function ns.FitCheck(check)
  local label = check.label or check.Text
  local width = label and label.GetStringWidth and label:GetStringWidth()
  if type(width) ~= "number" or width <= 0 then
    -- not measured yet (before the first show): about 6 px a letter at these sizes
    local text = label and label.GetText and label:GetText()
    width = type(text) == "string" and #text * 6 or 90
  end
  check:SetHitRectInsets(0, -(math.ceil(width) + 6), 0, 0)
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

local function CustomerTooltip(row)
  local group = row.group
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  local customer = group.customer
  GameTooltip:AddLine(customer.name)
  GameTooltip:AddLine(("%s %.1f, %.1f"):format(ns.MapName(customer.mapID), customer.x, customer.y), 0.6, 0.6, 0.6)
  for _, entry in ipairs(group.writs) do
    local writ = ns.WRITS[entry.writID]
    local tier = ns.WritTier(entry.writID)
    GameTooltip:AddDoubleLine(("%s |cff999999(%s, %d)|r"):format(writ[3], ns.TierName(tier.name), entry.rep),
      ns.Money(entry.total), 1, 1, 1, 1, 1, 1)
  end
  GameTooltip:AddLine(L["All %d: %s for %s reputation, %s per 100"]:format(#group.writs, ns.Money(group.total),
    ns.Number(group.rep), ns.Money(group.per100)), 0.25, 1, 0.25)
  if group.have > 0 then
    local text = group.have == 1 and L["You also hold 1 writ for %s: deliver it on the same trip."]:format(customer.name)
      or L["You also hold %d writs for %s: deliver them on the same trip."]:format(group.have, customer.name)
    GameTooltip:AddLine(text, 1, 0.82, 0, true)
  end
  local missing = #ns.CustomerWrits(customer) - #group.writs - group.have
  if missing > 0 then
    local text = missing == 1 and L["1 more writ for %s with no auction price yet."]:format(customer.name)
      or L["%d more writs for %s with no auction price yet."]:format(missing, customer.name)
    GameTooltip:AddLine(text, 0.6, 0.6, 0.6, true)
  end
  GameTooltip:AddLine(L["Click: search the auction house for these writs and their items (the materials, for items cheaper to craft) when it's open, else make the Auctionator buy list. Way: waypoint to %s."]:format(customer.name), 0.6, 0.6, 0.6, true)
  GameTooltip:Show()
end

local function ZoneTooltip(row)
  local zone = row.zone
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine(zone.name)
  for _, group in ipairs(zone.npcs) do
    local customer = group.customer
    GameTooltip:AddLine(("%s |cff999999%.1f, %.1f|r"):format(customer.name, customer.x, customer.y), 1, 0.82, 0)
    for _, entry in ipairs(group.writs) do
      local writ = ns.WRITS[entry.writID]
      local tier = ns.WritTier(entry.writID)
      GameTooltip:AddDoubleLine(("  %s |cff999999(%s, %d)|r"):format(writ[3], ns.TierName(tier.name), entry.rep),
        ns.Money(entry.total), 1, 1, 1, 1, 1, 1)
    end
  end
  GameTooltip:AddLine(L["All %d writs: %s for %s reputation, %s per 100"]:format(#zone.writs, ns.Money(zone.total),
    ns.Number(zone.rep), ns.Money(zone.per100)), 0.25, 1, 0.25)
  if zone.have > 0 then
    local text = zone.have == 1 and L["You also hold 1 writ for NPCs here: deliver it on the same trip."]
      or L["You also hold %d writs for NPCs here: deliver them on the same trip."]:format(zone.have)
    GameTooltip:AddLine(text, 1, 0.82, 0, true)
  end
  GameTooltip:AddLine(L["Click: search the auction house for these writs and their items (the materials, for items cheaper to craft) when it's open, else make the Auctionator buy list. Way: waypoints to the NPCs (all of them with TomTom, else the first)."], 0.6, 0.6, 0.6, true)
  GameTooltip:Show()
end

-- A crate of the By crate ranking (row.ranked, from ns.CheapestCrates): what it costs and what it gives.
local function RankedCrateTooltip(row)
  local entry = row.ranked
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine(entry.name)
  GameTooltip:AddLine(L["About %s Merchant's Favor"]:format(ns.Number(entry.favor)), 1, 1, 1)
  GameTooltip:AddDoubleLine(L["The crate"], ns.Money(entry.price), 1, 1, 1, 1, 1, 1)
  if entry.fill then
    GameTooltip:AddDoubleLine(L["Fill: %d %s"]:format(entry.fill.count, entry.fill.name), ns.Money(entry.fillCost),
      1, 1, 1, 1, 1, 1)
  else
    GameTooltip:AddLine(L["Already filled: turn it in as it is."], 0.6, 0.6, 0.6, true)
  end
  GameTooltip:AddDoubleLine(L["Total"], ns.Money(entry.total), 1, 0.82, 0, 1, 0.82, 0)
  GameTooltip:AddDoubleLine(L["Per Merchant's Favor"], ns.Money(entry.perFavor), 0.25, 1, 0.25, 0.25, 1, 0.25)
  GameTooltip:AddLine(L["Click at the auction house to search for the crate and what fills it, else put both on the buy list. Shift-click to link it."], 0.6, 0.6, 0.6, true)
  GameTooltip:Show()
end

local function CheapRow(index, parent)
  local row = CreateFrame("Button", nil, parent or window)
  row:SetSize(INNER, 16)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.T.GOLD[1], ns.T.GOLD[2], ns.T.GOLD[3], 0.12)
  row.way = ns.T.Button(row, 40, 15, L["Way"])
  row.way:SetPoint("RIGHT", 0, 0)
  row.way:SetScript("OnClick", function()
    if row.zone then
      ns.SetZoneWaypoints(row.zone)
    elseif row.group then
      ns.SetCustomerWaypoint(row.group.customer)
    end
  end)
  row.way:Hide()
  row.name = Text(row)
  row.name:SetPoint("LEFT", 2, 0)
  row.name:SetPoint("RIGHT", -110, 0)
  row.name:SetWordWrap(false)
  row.cost = Text(row)
  row.cost:SetPoint("RIGHT", -2, 0)
  row.cost:SetJustifyH("RIGHT")
  row:SetScript("OnEnter", function(self)
    if self.ranked then
      RankedCrateTooltip(self)
    elseif self.zone then
      ZoneTooltip(self)
    elseif self.group then
      CustomerTooltip(self)
    elseif self.writID then
      ItemTooltip(self, self.writID, L["Click at the auction house to search for it and its item (or the item's materials, when crafting it is cheaper). Shift-click to link it."])
    end
  end)
  row:SetScript("OnLeave", HideTooltip)
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel", function(self, delta)
    if self.rankList then -- (the crate ranking scrolls; the writ lists show their top rows)
      crateOffset = math.max(crateOffset - delta, 0)
      ns.RefreshWindow()
    end
  end)
  row:SetScript("OnClick", function(self)
    local linkID = self.writID or (self.ranked and self.ranked.itemID)
    if linkID and IsShiftKeyDown and IsShiftKeyDown() then
      local link = ns.ItemLink(linkID)
      if link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
      end
      return
    end
    if self.ranked then
      if ns.AuctionHouseOpen() then
        ns.SearchRankedCrate(self.ranked)
      else
        ns.CreateRankedCrateBuyList(self.ranked)
      end
      return
    end
    local entries = (self.zone and self.zone.writs) or (self.group and self.group.writs)
    if ns.AuctionHouseOpen() then
      local writIDs = {}
      for _, entry in ipairs(entries or {}) do
        writIDs[#writIDs + 1] = entry.writID
      end
      if self.writID then
        writIDs[1] = self.writID
      end
      ns.SearchWrits(writIDs, ns.HeldWrits())
    elseif self.zone then
      ns.CreateZoneBuyList(self.zone)
    elseif self.group then
      ns.CreateCustomerBuyList(self.group)
    end
  end)
  row.index = index
  return row
end

-- Lays a cheapest row out for a writ (cost at the right edge) or an NPC (cost left of the Way button).
local function CheapLayout(row, byNPC)
  row.way:SetShown(byNPC)
  row.cost:ClearAllPoints()
  row.cost:SetPoint("RIGHT", byNPC and -46 or -2, 0)
  row.name:SetPoint("RIGHT", byNPC and -200 or -110, 0)
end

-- Delivery rows: one per customer, with the writs you hold for them ------------------------------------

local function WritName(writID)
  local writ = ns.Writ(writID)
  return writ and writ[3] or L["item %d"]:format(writID)
end

local function Way(row)
  local group = row.group
  if not group then
    return
  end
  if group.customer then
    ns.SetCustomerWaypoint(group.customer)
  elseif group.writs[1].questID then
    ns.SetWritWaypoint(group.writs[1].questID, WritName(group.writs[1].writID))
  end
end

-- A crate to fill (row.crate, from ns.CratesToFill): its Favor and every way to fill it, cheapest first.
local function CrateTooltip(row)
  local crate = row.crate
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine(crate.info.name)
  GameTooltip:AddLine(L["%d in your bags: about %s Merchant's Favor each"]:format(crate.count,
    ns.Number(crate.favor)), 1, 1, 1, true)
  for _, option in ipairs(crate.options) do
    local have = option.owned > 0 and (" |cff999999" .. L["(you have %d)"]:format(option.owned) .. "|r") or ""
    GameTooltip:AddDoubleLine(L["Fill: %d %s"]:format(option.count, option.name) .. have,
      option.cost and ns.Money(option.cost) or ("|cff999999" .. L["no price"] .. "|r"), 1, 1, 1, 1, 1, 1)
  end
  if #crate.options == 0 then
    GameTooltip:AddLine(L["What fills it isn't known."], 0.6, 0.6, 0.6, true)
  end
  GameTooltip:AddLine(L["Click: search the auction house for what fills it when it's open, else make the Auctionator buy list with the cheapest fill for all of them."], 0.6, 0.6, 0.6, true)
  GameTooltip:Show()
end

local function DeliveryTooltip(row)
  if row.crate then
    CrateTooltip(row)
    return
  end
  local group = row.group
  if not group then
    return
  end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  local customer = group.customer
  if customer then
    GameTooltip:AddLine(customer.name)
    GameTooltip:AddLine(("%s %.1f, %.1f%s"):format(ns.MapName(customer.mapID), customer.x, customer.y,
      customer.learned and (" " .. L["(seen at your turn-in)"]) or customer.collected and (" " .. L["(players' data)"])
      or ""), 0.6, 0.6, 0.6)
  else
    GameTooltip:AddLine(WritName(group.writs[1].writID))
    GameTooltip:AddLine(L["Who takes this writ isn't known yet. Use it, and the game marks the spot on your map; the addon remembers the NPC once you turn it in."], 1, 1, 1, true)
  end
  local mine = {}
  for _, entry in ipairs(group.writs) do
    mine[entry.writID] = true
    local state
    if entry.ready then
      state = "|cff40ff40" .. L["ready"] .. "|r"
    elseif entry.questID then
      state = "|cffffd100" .. L["needs the item"] .. "|r"
    else
      state = "|cff999999" .. L["not opened, needs the item"] .. "|r"
    end
    GameTooltip:AddDoubleLine(WritName(entry.writID), state, 1, 1, 1, 1, 1, 1)
  end
  if customer then
    local others = {}
    for _, writID in ipairs(ns.CustomerWrits(customer)) do
      if not mine[writID] then
        others[#others + 1] = WritName(writID)
      end
    end
    if #others > 0 then
      GameTooltip:AddLine(L["Also takes: %s"]:format(table.concat(others, ", ")), 0.6, 0.6, 0.6, true)
    end
  end
  GameTooltip:Show()
end

local function DeliveryRow(parent)
  local row = CreateFrame("Button", nil, parent or window)
  row:SetSize(INNER, 18)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.T.GOLD[1], ns.T.GOLD[2], ns.T.GOLD[3], 0.12)
  row:SetScript("OnEnter", DeliveryTooltip)
  row:SetScript("OnLeave", HideTooltip)
  row.way = ns.T.Button(row, 44, 16, L["Way"])
  row.way:SetPoint("RIGHT", 0, 0)
  row.way:SetScript("OnClick", function()
    Way(row)
  end)
  row.way:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Waypoint"])
    GameTooltip:AddLine(L["Puts a waypoint on who takes these writs (TomTom when installed)."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row.way:SetScript("OnLeave", HideTooltip)
  row.start = ns.T.Button(row, 48, 16, L["Start"])
  row.start:SetPoint("RIGHT", row.way, "LEFT", -4, 0)
  row.start:SetScript("OnClick", function()
    local writID = row.group and ns.StartableWrit(row.group)
    if writID then
      local ok, why = ns.StartWrit(writID)
      if not ok and why then
        print(ns.T.Prefix("Commerce Authority") .. why)
      end
    end
  end)
  row.start:SetScript("OnEnter", function(self)
    local writID = row.group and ns.StartableWrit(row.group)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Start"])
    GameTooltip:AddLine(L["Opens the quest of %s: your bags hold what it asks for. Each click starts one writ."]:format(
      writID and WritName(writID) or L["the writ"]), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row.start:SetScript("OnLeave", HideTooltip)
  row.start:Hide()
  row.name = Text(row)
  row.name:SetPoint("LEFT", 2, 0)
  row.name:SetPoint("RIGHT", row.way, "LEFT", -6, 0)
  row.name:SetWordWrap(false)
  -- a crate to fill: search for what fills it (or the buy list away from the auction house)
  row:SetScript("OnClick", function(self)
    if not self.crate then
      return
    end
    if IsShiftKeyDown and IsShiftKeyDown() then
      local link = ns.ItemLink and ns.ItemLink(self.crate.itemID)
      if link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
      end
    elseif ns.AuctionHouseOpen() then
      ns.SearchCrate(self.crate)
    else
      ns.CreateCrateBuyList(self.crate)
    end
  end)
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

  -- the two tabs and their panes (each pane covers the window; its parts keep window coordinates)
  window.panes, window.tabs = {}, {}
  for index, key in ipairs({ "writs", "crates" }) do
    local pane = CreateFrame("Frame", nil, window)
    pane:SetAllPoints(window)
    pane:Hide()
    window.panes[key] = pane
    local tab = T.Button(window, 96, 22, key == "writs" and L["Writs"] or L["Crates"])
    tab:SetPoint("TOPLEFT", PAD + (index - 1) * 100, -38)
    tab.mark = tab:CreateTexture(nil, "OVERLAY")
    tab.mark:SetPoint("BOTTOMLEFT", 3, 2)
    tab.mark:SetPoint("BOTTOMRIGHT", -3, 2)
    tab.mark:SetHeight(2)
    tab.mark:SetColorTexture(T.GOLD[1], T.GOLD[2], T.GOLD[3], 1)
    tab.key = key
    tab:SetScript("OnClick", function()
      ns.SelectWindowTab(key)
    end)
    window.tabs[key] = tab
  end
  local writs, crates = window.panes.writs, window.panes.crates
  local function PaneHeading(pane, y, text)
    local heading = T.Heading(pane, text, INNER)
    heading:SetPoint("TOPLEFT", PAD, y)
    return heading
  end

  -- Writs ------------------------------------------------------------------------------------------------
  window.faction = Text(writs, "GameFontNormal")
  window.faction:SetPoint("TOPLEFT", PAD, -70)
  window.faction:SetPoint("RIGHT", -PAD, 0)
  window.faction:SetWordWrap(false)

  local bar = CreateFrame("Frame", nil, writs)
  bar:SetPoint("TOPLEFT", PAD, -90)
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

  PaneHeading(writs, -112, L["In your bags"])
  window.bags = Text(writs)
  window.bags:SetPoint("TOPLEFT", PAD, -132)
  window.bags:SetPoint("RIGHT", -PAD, 0)
  window.bags:SetSpacing(2)

  -- shorter on both sides (title still centred like the others), leaving room for the button at the right
  local deliveries = T.Heading(writs, L["Deliveries"], INNER - 2 * 84)
  deliveries:SetPoint("TOP", window, "TOP", 0, -176)
  local allNPCs = T.Button(writs, 76, 18, L["All NPCs"])
  allNPCs:SetPoint("RIGHT", window, "TOPRIGHT", -PAD, -184) -- vertically on the heading's middle
  allNPCs:SetScript("OnClick", function()
    ns.ToggleNPCWindow()
  end)
  allNPCs:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Writ NPCs"])
    GameTooltip:AddLine(L["Every NPC who takes writs, with all its writs and which of them you have (%s)."]:format(
      "/aca npcs"), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  allNPCs:SetScript("OnLeave", HideTooltip)
  window.deliveries = {}
  for index = 1, DELIVERY_ROWS do
    local row = DeliveryRow(writs)
    row:SetPoint("TOPLEFT", PAD, -194 - (index - 1) * 18)
    window.deliveries[index] = row
  end
  window.noDeliveries = Text(writs, "GameFontDisableSmall")
  window.noDeliveries:SetPoint("TOPLEFT", PAD + 2, -196)
  window.noDeliveries:SetPoint("RIGHT", -PAD, 0)

  PaneHeading(writs, -276, L["Next standings"])
  window.goals = Text(writs)
  window.goals:SetPoint("TOPLEFT", PAD, -296)
  window.goals:SetPoint("RIGHT", -PAD, 0)
  window.goals:SetSpacing(2)

  window.cheapHeading = PaneHeading(writs, -356, L["Cheapest reputation"])
  local mine = T.Check(writs, L["Only my professions"], "GameFontHighlightSmall")
  mine:SetPoint("TOPLEFT", PAD - 4, -372)
  mine:SetScript("OnShow", function(self)
    self:SetChecked(CommerceAuthorityDB.onlyMyProfessions)
  end)
  mine:SetScript("OnClick", function(self)
    CommerceAuthorityDB.onlyMyProfessions = self:GetChecked() and true or false
    ns.InvalidateCheapest()
    ns.RefreshWindow()
  end)
  mine:SetChecked(CommerceAuthorityDB.onlyMyProfessions)
  ns.FitCheck(mine)
  window.mine = mine
  local mode = T.Button(writs, 84, 20, MODE_LABELS[ns.CheapestMode()])
  mode:SetPoint("TOPLEFT", PAD + 160, -373)
  mode:SetScript("OnClick", function(self)
    ns.SetCheapestMode(NEXT_MODE[ns.CheapestMode()])
    self:SetText(MODE_LABELS[ns.CheapestMode()])
    ns.RefreshWindow()
    if GameTooltip.IsOwned and GameTooltip:IsOwned(self) then
      self:GetScript("OnEnter")(self) -- the tooltip follows the new ranking
    end
  end)
  mode:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(MODE_LABELS[ns.CheapestMode()])
    GameTooltip:AddLine(MODE_HELP[ns.CheapestMode()], 1, 1, 1, true)
    GameTooltip:AddLine(L["Click to switch: by writ, by NPC, by zone."], 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  mode:SetScript("OnLeave", HideTooltip)
  window.mode = mode
  local buy = T.Button(writs, 96, 20, L["Buy list"])
  buy:SetPoint("TOPRIGHT", -PAD, -373)
  buy:SetScript("OnClick", function()
    if ns.CheapestMode() == "zone" then
      ns.CreateZoneBuyList(ns.CheapestZones(1)[1])
    elseif ns.CheapestMode() == "npc" then
      ns.CreateCustomerBuyList(ns.CheapestCustomers(1)[1])
    else
      ns.CreateBuyList()
    end
  end)
  buy:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Buy list"])
    if ns.CheapestMode() == "zone" then
      local zone = ns.CheapestZones(1)[1]
      GameTooltip:AddLine(L["Makes the Auctionator shopping list \"%s\" with every priced writ taken in the cheapest zone, and the items they ask for. Click a zone's row for that zone's."]:format(ns.SHOPPING_LIST), 1, 1, 1, true)
      if zone then
        GameTooltip:AddLine(L["%s: %d writs for %d NPCs, %s reputation, about %s"]:format(zone.name, #zone.writs,
          #zone.npcs, ns.Number(zone.rep), ns.Money(zone.total)), 0.25, 1, 0.25)
      end
      GameTooltip:Show()
      return
    end
    if ns.CheapestMode() == "npc" then
      local group = ns.CheapestCustomers(1)[1]
      GameTooltip:AddLine(L["Makes the Auctionator shopping list \"%s\" with every priced writ the cheapest NPC takes, and the items they ask for. Click an NPC's row for that NPC's."]:format(ns.SHOPPING_LIST), 1, 1, 1, true)
      if group then
        GameTooltip:AddLine(L["%s: %d writs, %s reputation, about %s"]:format(group.customer.name, #group.writs,
          ns.Number(group.rep), ns.Money(group.total)), 0.25, 1, 0.25)
      end
      GameTooltip:Show()
      return
    end
    local plan = ns.PlanPurchases()
    GameTooltip:AddLine(L["Makes the Auctionator shopping list \"%s\": the cheapest writs for the reputation you still need to your next standing, and the items they ask for."]:format(ns.SHOPPING_LIST), 1, 1, 1, true)
    if #plan.picks > 0 then
      GameTooltip:AddLine(L["%d writs, about %s reputation, about %s"]:format(#plan.picks, ns.Number(plan.rep),
        ns.Money(plan.cost)), 0.25, 1, 0.25)
    end
    GameTooltip:Show()
  end)
  buy:SetScript("OnLeave", HideTooltip)
  window.buy = buy

  window.rows = {}
  for index = 1, CHEAP_ROWS do
    local row = CheapRow(index, writs)
    row:SetPoint("TOPLEFT", PAD, -398 - (index - 1) * 16)
    window.rows[index] = row
  end
  window.empty = Text(writs, "GameFontDisableSmall")
  window.empty:SetPoint("TOPLEFT", PAD + 2, -400)
  window.empty:SetPoint("RIGHT", -PAD, 0)

  -- Crates -----------------------------------------------------------------------------------------------
  window.favor = Text(crates, "GameFontNormal")
  window.favor:SetPoint("TOPLEFT", PAD, -70)
  window.favor:SetPoint("RIGHT", -PAD, 0)
  window.favor:SetWordWrap(false)

  PaneHeading(crates, -92, L["In your bags"])
  window.crateBags = Text(crates)
  window.crateBags:SetPoint("TOPLEFT", PAD, -112)
  window.crateBags:SetPoint("RIGHT", -PAD, 0)
  window.crateBags:SetSpacing(2)

  PaneHeading(crates, -150, L["Crates to fill"])
  window.fills = {}
  for index = 1, FILL_ROWS do
    local row = DeliveryRow(crates)
    row:SetPoint("TOPLEFT", PAD, -168 - (index - 1) * 18)
    window.fills[index] = row
  end
  window.noFills = Text(crates, "GameFontDisableSmall")
  window.noFills:SetPoint("TOPLEFT", PAD + 2, -170)
  window.noFills:SetPoint("RIGHT", -PAD, 0)

  PaneHeading(crates, -266, L["Cheapest Merchant's Favor"])
  window.rankHint = Text(crates, "GameFontDisableSmall")
  window.rankHint:SetPoint("TOPLEFT", PAD + 2, -288)
  window.rankHint:SetPoint("RIGHT", -PAD - 104, 0)
  window.rankHint:SetWordWrap(false)
  window.rankHint:SetText(L["Crate price + its cheapest fill, cheapest first"])
  local rankBuy = T.Button(crates, 96, 20, L["Buy list"])
  rankBuy:SetPoint("TOPRIGHT", -PAD, -283)
  rankBuy:SetScript("OnClick", function()
    ns.CreateRankedCrateBuyList(ns.CheapestCrates(1)[1])
  end)
  rankBuy:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Buy list"])
    local entry = ns.CheapestCrates(1)[1]
    GameTooltip:AddLine(L["Makes the Auctionator shopping list \"%s\" with the cheapest crate and what fills it. Click a crate's row for that crate."]:format(ns.SHOPPING_LIST), 1, 1, 1, true)
    if entry then
      GameTooltip:AddLine(L["%s: about %s for %s Favor"]:format(entry.name, ns.Money(entry.total),
        ns.Number(entry.favor)), 0.25, 1, 0.25)
    end
    GameTooltip:Show()
  end)
  rankBuy:SetScript("OnLeave", HideTooltip)
  window.rankBuy = rankBuy
  window.rankRows = {}
  for index = 1, RANK_ROWS do
    local row = CheapRow(index, crates)
    row.rankList = true
    row:SetPoint("TOPLEFT", PAD, -310 - (index - 1) * 16)
    window.rankRows[index] = row
  end
  window.rankEmpty = Text(crates, "GameFontDisableSmall")
  window.rankEmpty:SetPoint("TOPLEFT", PAD + 2, -312)
  window.rankEmpty:SetPoint("RIGHT", -PAD, 0)

  window.session = Text(window, "GameFontDisableSmall")
  window.session:SetPoint("BOTTOMLEFT", PAD, 14)
  window.session:SetPoint("RIGHT", -PAD, 0)
  window.session:SetWordWrap(false)

  RestorePosition(window)
  ns.SelectWindowTab(CommerceAuthorityDB.windowTab, true)
  window:Hide()
end

-- Shows a tab of the window ("writs" or "crates"; anything else = writs), saved for next time.
function ns.SelectWindowTab(key, quiet)
  key = key == "crates" and "crates" or "writs"
  if CommerceAuthorityDB then
    CommerceAuthorityDB.windowTab = key
  end
  if not window then
    return
  end
  for name, pane in pairs(window.panes) do
    pane:SetShown(name == key)
    local tab = window.tabs[name]
    tab.mark:SetShown(name == key)
    if tab.label and tab.label.SetTextColor then
      local color = name == key and ns.T.GOLD or { 0.75, 0.75, 0.75 }
      tab.label:SetTextColor(color[1], color[2], color[3])
    end
  end
  window.tab = key
  if not quiet then
    ns.RefreshWindow()
  end
end

-- The Writs tab's "In your bags": writs and sealed writs.
local function Bags(summary)
  local lines = {}
  if summary.writs > 0 then
    lines[#lines + 1] = L["%d writs: %s reputation"]:format(summary.writs, ns.Number(summary.writRep))
  end
  if summary.sealedWrits > 0 then
    lines[#lines + 1] = L["%d sealed writs: %s reputation once done"]:format(summary.sealedWrits,
      ns.Number(summary.sealedRep))
  end
  if #lines == 0 then
    return L["No writs in your bags."]
  end
  return table.concat(lines, "\n")
end

-- The Crates tab's "In your bags": filled crates and crates to fill.
local function CrateBags(summary)
  local lines = {}
  if summary.crates > 0 then
    lines[#lines + 1] = L["%d filled crates: about %s Favor + %s"]:format(summary.crates,
      ns.Number(ns.ExpectedFavor(summary.crateFavor)), ns.Money(summary.crateFavor * ns.COPPER_PER_FAVOR))
  end
  if summary.toFill > 0 then
    lines[#lines + 1] = L["%d crates to fill: about %s Favor"]:format(summary.toFill,
      ns.Number(ns.ExpectedFavor(summary.fillFavor)))
  end
  if #lines == 0 then
    return L["No crates in your bags."]
  end
  return table.concat(lines, "\n")
end

local function Goals(faction, bagRep)
  local upcoming = ns.NextStandings(faction)
  if #upcoming == 0 then
    return faction and L["Exalted. Nothing left to earn here but Merchant's Favor."] or
      L["Turn in your first crate at the trade hub to start."]
  end
  local lines = {}
  local fewest = ns.TierRep(ns.WRIT_TIERS[3])
  local most = ns.TierRep(ns.WRIT_TIERS[1])
  for index = 1, math.min(#upcoming, 3) do
    local goal = upcoming[index]
    local needed = math.max(goal.needed - bagRep, 0)
    local text = L["%s: %s more"]:format(ns.StandingName(goal.standingID), ns.Number(goal.needed))
    if bagRep > 0 then
      text = text .. " " .. L["(%s after your bags)"]:format(ns.Number(needed))
    end
    if needed > 0 then
      text = text .. ", " .. L["%d-%d writs"]:format(math.ceil(needed / fewest), math.ceil(needed / most))
    end
    lines[#lines + 1] = text
  end
  return table.concat(lines, "\n")
end

-- "Kzixx, Duskwood: 2 writs, 1 ready" or "Radiant Circlet (Artisan): who takes it isn't known yet"
local function DeliveryText(group)
  local ready = group.ready > 0 and (" |cff40ff40" .. L["%d ready"]:format(group.ready) .. "|r") or ""
  if group.customer then
    local what = #group.writs == 1 and WritName(group.writs[1].writID) or Writs(#group.writs)
    return ("%s |cff999999%s|r: %s%s"):format(group.customer.name, ns.MapName(group.customer.mapID), what,
      ready ~= "" and "," .. ready or "")
  end
  return ("%s |cff999999%s|r%s"):format(WritName(group.writs[1].writID), L["(not known who takes it)"], ready)
end

-- "Waylaid Crate: Journeyman Ore x2: fill 20 Iron Ore, 1g 20s" (or "ready to fill" when your bags hold enough)
local function CrateText(crate)
  local short = crate.info.name:match("^Waylaid Crate: (.+)$")
  local name = short and L["Crate: %s"]:format(short) or crate.info.name
  local times = crate.count > 1 and (" x%d"):format(crate.count) or ""
  if crate.ready then
    return ("%s%s |cff40ff40%s|r"):format(name, times, L["ready to fill"])
  end
  local option = crate.options[1]
  if not option then
    return ("%s%s |cff999999%s|r"):format(name, times, L["(fill not known)"])
  end
  return ("%s%s|cff999999: %s%s|r"):format(name, times, L["fill %d %s"]:format(option.count, option.name),
    option.cost and (", " .. ns.ShortMoney(option.cost)) or "")
end

local function Deliveries(counts)
  local groups = ns.Deliveries(counts)
  for index, row in ipairs(window.deliveries) do
    local group = groups[index]
    row.group, row.crate = group, nil
    if group then
      row.name:SetText(DeliveryText(group))
      row.way:SetShown(group.customer ~= nil or group.writs[1].questID ~= nil)
      local startable = ns.StartableWrit(group) ~= nil and not (InCombatLockdown and InCombatLockdown())
      row.start:SetShown(startable)
      row.name:SetPoint("RIGHT", startable and row.start or row.way, "LEFT", -6, 0)
      row:Show()
    else
      row:Hide()
    end
  end
  if #groups == 0 then
    window.noDeliveries:SetText(L["No writs. The writs you hold show here, grouped by who takes them."])
  elseif #groups > DELIVERY_ROWS then
    window.noDeliveries:SetText("")
    local last = window.deliveries[DELIVERY_ROWS]
    last.name:SetText(last.name:GetText() .. " |cff999999" .. L["+%d more"]:format(#groups - DELIVERY_ROWS) .. "|r")
  else
    window.noDeliveries:SetText("")
  end
end

-- The Crates tab: the Waylaid Crates in your bags that still need filling, the cheapest fill on each row.
local function Fills(counts)
  local crates = ns.CratesToFill(counts)
  for index, row in ipairs(window.fills) do
    local crate = crates[index]
    row.group, row.crate = nil, crate
    row.way:Hide()
    row.start:Hide()
    if crate then
      row.name:SetText(CrateText(crate))
      row.name:SetPoint("RIGHT", row, "RIGHT", -2, 0)
      row:Show()
    else
      row:Hide()
    end
  end
  if #crates == 0 then
    window.noFills:SetText(L["No crates to fill. The Waylaid Crates in your bags show here, with the cheapest way to fill each."])
  elseif #crates > FILL_ROWS then
    window.noFills:SetText("")
    local last = window.fills[FILL_ROWS]
    last.name:SetText(last.name:GetText() .. " |cff999999" .. L["+%d more"]:format(#crates - FILL_ROWS) .. "|r")
  else
    window.noFills:SetText("")
  end
end

-- "Spek Riverglades: 4 writs" with "1g 90s / 100", for the By NPC ranking. Returns how many are shown.
local function CheapestByNPC(counts)
  local groups = ns.CheapestCustomers(CHEAP_ROWS, counts)
  for index, row in ipairs(window.rows) do
    local group = groups[index]
    row.writID, row.zone = nil, nil
    CheapLayout(row, true)
    if group then
      row.group = group
      local what = #group.writs == 1 and ns.WRITS[group.writs[1].writID][3] or Writs(#group.writs)
      row.name:SetText(("%s |cff999999%s|r: %s"):format(group.customer.name, ns.MapName(group.customer.mapID),
        what))
      row.cost:SetText(("%s |cff999999· %s / 100|r"):format(ns.ShortMoney(group.total), ns.ShortMoney(group.per100)))
      row:Show()
    else
      row.group = nil
      row:Hide()
    end
  end
  return #groups
end

-- "Tanaris: 3 NPCs, 5 writs" with "1g 20s / 100", for the By zone ranking. Returns how many are shown.
local function CheapestByZone(counts)
  local zones = ns.CheapestZones(CHEAP_ROWS, counts)
  for index, row in ipairs(window.rows) do
    local zone = zones[index]
    row.writID, row.group = nil, nil
    CheapLayout(row, true)
    if zone then
      row.zone = zone
      local npcs = #zone.npcs == 1 and L["1 NPC"] or L["%d NPCs"]:format(#zone.npcs)
      row.name:SetText(("%s|cff999999:|r %s, %s"):format(zone.name, npcs, Writs(#zone.writs)))
      row.cost:SetText(("%s |cff999999· %s / 100|r"):format(ns.ShortMoney(zone.total), ns.ShortMoney(zone.per100)))
      row:Show()
    else
      row.zone = nil
      row:Hide()
    end
  end
  return #zones
end

-- "Waylaid Crate: Journeyman Ore (10)" with "45s · 4s 50c / Favor", the Crates tab's ranking: crate price plus the
-- cheapest fill, scrolled by crateOffset (mouse wheel).
local function CrateRanking()
  local crates = ns.CheapestCrates()
  crateOffset = math.min(crateOffset, math.max(#crates - RANK_ROWS, 0))
  for index, row in ipairs(window.rankRows) do
    local entry = crates[crateOffset + index]
    CheapLayout(row, false)
    row.name:SetPoint("RIGHT", -150, 0)
    row.ranked = entry
    if entry then
      row.name:SetText(("%s |cff999999(%s)|r"):format(entry.name, ns.Number(entry.favor)))
      row.cost:SetText(("%s |cff999999· %s|r"):format(ns.ShortMoney(entry.total),
        L["%s / Favor"]:format(ns.ShortMoney(entry.perFavor))))
      row:Show()
    else
      row:Hide()
    end
  end
  if #crates > 0 then
    window.rankEmpty:SetText("")
    window.rankHint:SetText(#crates > RANK_ROWS
      and L["Crate price + its cheapest fill, cheapest first (%d-%d of %d, scroll for more)"]:format(crateOffset + 1,
        math.min(crateOffset + RANK_ROWS, #crates), #crates)
      or L["Crate price + its cheapest fill, cheapest first"])
  elseif #ns.PriceSourceNames() == 0 then
    window.rankEmpty:SetText(L["Install Auctionator, TradeSkillMaster or Auctioneer to see auction prices."])
  else
    window.rankEmpty:SetText(L["No priced crates yet. Scan the auction house, or search for \"%s\"."]:format("Waylaid Crate"))
  end
end

local function Cheapest(counts)
  local shown
  local mode = ns.CheapestMode()
  if mode == "zone" then
    shown = CheapestByZone(counts)
  elseif mode == "npc" then
    shown = CheapestByNPC(counts)
  end
  local cheapest = shown and {} or ns.CheapestWrits(CHEAP_ROWS)
  for index, row in ipairs(window.rows) do
    local entry = cheapest[index]
    if shown then
      -- laid out by CheapestByNPC
    elseif entry then
      local writ = ns.WRITS[entry.writID]
      local tier = ns.WritTier(entry.writID)
      CheapLayout(row, false)
      row.group, row.zone = nil, nil
      row.writID = entry.writID
      row.name:SetText(("%s |cff999999(%s, %d)|r"):format(writ[3], ns.TierName(tier.name), entry.rep))
      row.cost:SetText(("%s |cff999999/ 100|r"):format(ns.Money(entry.per100)))
      row:Show()
    else
      row.writID, row.group, row.zone = nil, nil, nil
      row:Hide()
    end
  end
  if (shown or #cheapest) > 0 then
    window.empty:SetText("")
  elseif #ns.PriceSourceNames() == 0 then
    window.empty:SetText(L["Install Auctionator, TradeSkillMaster or Auctioneer to see auction prices."])
  elseif CommerceAuthorityDB.onlyMyProfessions and next(ns.PlayerProfessions()) == nil then
    window.empty:SetText(L["No crafting profession found on this character."])
  else
    window.empty:SetText(L["No priced writs yet. Scan the auction house, or search for \"%s\"."]:format(
      "Craftsman's Writ"))
  end
end

function ns.RefreshWindow()
  if not (window and window:IsShown()) then
    return
  end
  local faction = ns.Faction()
  local counts = ns.BagCounts()
  local summary = ns.BagSummary(counts)
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
    window.faction:SetText(ns.MyFactionName() .. ": |cff999999" .. L["no reputation yet"] .. "|r")
    bar.fill:SetWidth(0.01)
    bar.bags:SetWidth(0.01)
    bar.text:SetText(L["Trade hub: %s"]:format(ns.HubText()))
  end

  local favor = ns.Favor()
  if favor then
    local text = L["Merchant's Favor: %s"]:format("|cffffffff" .. ns.Number(favor) .. "|r")
    local coming = ns.ExpectedFavor(summary.crateFavor)
    if coming > 0 then
      text = text .. "  " .. L["(about %s after your crates)"]:format(ns.Number(favor + coming))
    end
    window.favor:SetText(text)
  else
    window.favor:SetText(L["Merchant's Favor: not on this game version"])
  end
  window.bags:SetText(Bags(summary))
  Deliveries(counts)
  window.goals:SetText(Goals(faction, bagRep))
  Cheapest(counts)
  window.crateBags:SetText(CrateBags(summary))
  Fills(counts)
  CrateRanking()

  local session = ns.session
  window.session:SetText(L["This session: +%s Favor, +%s reputation, %d crates, %d writs"]:format(
    ns.Number(session.favor), ns.Number(session.rep), session.crates, session.writs)
    .. (session.bonuses > 0 and (", " .. L["%d bonus"]:format(session.bonuses)) or ""))
end

local function RefreshAll()
  ns.RefreshWindow()
  if ns.RefreshNPCWindow then
    ns.RefreshNPCWindow()
  end
end

-- Refreshes the windows (this one and Writ NPCs) at most twice a second, while one is shown.
local refreshPending = false
function ns.RequestRefresh()
  if not ((window and window:IsShown()) or (ns.NPCWindowShown and ns.NPCWindowShown())) then
    return
  end
  if not (C_Timer and C_Timer.After) then
    RefreshAll()
    return
  end
  if refreshPending then
    return
  end
  refreshPending = true
  C_Timer.After(0.5, function()
    refreshPending = false
    RefreshAll()
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

-- The window, made the first time it is needed (Dock.lua opens it beside the auction house).
function ns.EnsureWindow()
  if not window then
    Create()
  end
  return window
end

-- Back to the player's own place (after it was docked beside the auction house).
function ns.RestoreWindowPosition()
  if window then
    RestorePosition(window)
  end
end
