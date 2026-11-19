local _, ns = ...

-- The Commerce Authority window (/aca): reputation and Merchant's Favor, what your bags are worth, the writs
-- you hold grouped by who takes them (with waypoints), how far each standing is, the cheapest reputation on the auction house
-- (with a buy list for Auctionator) and this session's turn-ins.

local WIDTH = 400
local HEIGHT = 580
local PAD = 16
local INNER = WIDTH - PAD * 2
local CHEAP_ROWS = 8
local DELIVERY_ROWS = 4
-- the cheapest list's rankings, switched by one button
local MODE_LABELS = { writ = "By writ", npc = "By NPC", zone = "By zone" }
local NEXT_MODE = { writ = "npc", npc = "zone", zone = "writ" }
local MODE_HELP = {
  writ = "Writs sorted by what each costs per 100 reputation (the writ and the item it asks for).",
  npc = "The NPCs who take writs, by what buying all their priced writs costs per 100 reputation: one shopping "
    .. "list, one trip.",
  zone = "Zones, by what buying all the priced writs their NPCs take costs per 100 reputation: one shopping list, "
    .. "one trip around the zone.",
}
local window

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
    GameTooltip:AddDoubleLine(("%s |cff999999(%s, %d)|r"):format(writ[3], tier.name, entry.rep),
      ns.Money(entry.total), 1, 1, 1, 1, 1, 1)
  end
  GameTooltip:AddLine(("All %d: %s for %s reputation, %s per 100"):format(#group.writs, ns.Money(group.total),
    ns.Number(group.rep), ns.Money(group.per100)), 0.25, 1, 0.25)
  if group.have > 0 then
    GameTooltip:AddLine(("You also hold %d writ%s for %s: deliver %s on the same trip."):format(group.have,
      group.have == 1 and "" or "s", customer.name, group.have == 1 and "it" or "them"), 1, 0.82, 0, true)
  end
  local missing = #ns.CustomerWrits(customer) - #group.writs - group.have
  if missing > 0 then
    GameTooltip:AddLine(("%d more writ%s for %s with no auction price yet."):format(missing,
      missing == 1 and "" or "s", customer.name), 0.6, 0.6, 0.6, true)
  end
  GameTooltip:AddLine("Click: search the auction house for these writs when it's open, else make the Auctionator "
    .. "buy list. Way: waypoint to " .. customer.name .. ".", 0.6, 0.6, 0.6, true)
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
      GameTooltip:AddDoubleLine(("  %s |cff999999(%s, %d)|r"):format(writ[3], tier.name, entry.rep),
        ns.Money(entry.total), 1, 1, 1, 1, 1, 1)
    end
  end
  GameTooltip:AddLine(("All %d writs: %s for %s reputation, %s per 100"):format(#zone.writs, ns.Money(zone.total),
    ns.Number(zone.rep), ns.Money(zone.per100)), 0.25, 1, 0.25)
  if zone.have > 0 then
    GameTooltip:AddLine(("You also hold %d writ%s for NPCs here: deliver %s on the same trip."):format(zone.have,
      zone.have == 1 and "" or "s", zone.have == 1 and "it" or "them"), 1, 0.82, 0, true)
  end
  GameTooltip:AddLine("Click: search the auction house for these writs when it's open, else make the Auctionator "
    .. "buy list. Way: waypoints to the NPCs (all of them with TomTom, else the first).", 0.6, 0.6, 0.6, true)
  GameTooltip:Show()
end

local function CheapRow(index)
  local row = CreateFrame("Button", nil, window)
  row:SetSize(INNER, 16)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.T.GOLD[1], ns.T.GOLD[2], ns.T.GOLD[3], 0.12)
  row.way = ns.T.Button(row, 40, 15, "Way")
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
    if self.zone then
      ZoneTooltip(self)
    elseif self.group then
      CustomerTooltip(self)
    elseif self.writID then
      ItemTooltip(self, self.writID, "Click at the auction house to search for it. Shift-click to link it.")
    end
  end)
  row:SetScript("OnLeave", HideTooltip)
  row:SetScript("OnClick", function(self)
    if self.writID and IsShiftKeyDown and IsShiftKeyDown() then
      local link = ns.ItemLink(self.writID)
      if link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
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
  return writ and writ[3] or ("item " .. writID)
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

local function DeliveryTooltip(row)
  local group = row.group
  if not group then
    return
  end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  local customer = group.customer
  if customer then
    GameTooltip:AddLine(customer.name)
    GameTooltip:AddLine(("%s %.1f, %.1f%s"):format(ns.MapName(customer.mapID), customer.x, customer.y,
      customer.learned and " (seen at your turn-in)" or ""), 0.6, 0.6, 0.6)
  else
    GameTooltip:AddLine(WritName(group.writs[1].writID))
    GameTooltip:AddLine("Who takes this writ isn't known yet. Use it, and the game marks the spot on your map; "
      .. "the addon remembers the NPC once you turn it in.", 1, 1, 1, true)
  end
  local mine = {}
  for _, entry in ipairs(group.writs) do
    mine[entry.writID] = true
    local state
    if entry.ready then
      state = "|cff40ff40ready|r"
    elseif entry.questID then
      state = "|cffffd100needs the item|r"
    else
      state = "|cff999999not opened, needs the item|r"
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
      GameTooltip:AddLine("Also takes: " .. table.concat(others, ", "), 0.6, 0.6, 0.6, true)
    end
  end
  GameTooltip:Show()
end

local function DeliveryRow()
  local row = CreateFrame("Button", nil, window)
  row:SetSize(INNER, 18)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.T.GOLD[1], ns.T.GOLD[2], ns.T.GOLD[3], 0.12)
  row:SetScript("OnEnter", DeliveryTooltip)
  row:SetScript("OnLeave", HideTooltip)
  row.way = ns.T.Button(row, 44, 16, "Way")
  row.way:SetPoint("RIGHT", 0, 0)
  row.way:SetScript("OnClick", function()
    Way(row)
  end)
  row.way:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Waypoint")
    GameTooltip:AddLine("Puts a waypoint on who takes these writs (TomTom when installed).", 1, 1, 1, true)
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

  -- shorter on both sides (title still centred like the others), leaving room for the button at the right
  local deliveries = T.Heading(window, "Deliveries", INNER - 2 * 84)
  deliveries:SetPoint("TOP", window, "TOP", 0, -192)
  local allNPCs = T.Button(window, 76, 18, "All NPCs")
  allNPCs:SetPoint("RIGHT", window, "TOPRIGHT", -PAD, -200) -- vertically on the heading's middle
  allNPCs:SetScript("OnClick", function()
    ns.ToggleNPCWindow()
  end)
  allNPCs:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Writ NPCs")
    GameTooltip:AddLine("Every NPC who takes writs, with all its writs and which of them you have (/aca npcs).",
      1, 1, 1, true)
    GameTooltip:Show()
  end)
  allNPCs:SetScript("OnLeave", HideTooltip)
  window.deliveries = {}
  for index = 1, DELIVERY_ROWS do
    local row = DeliveryRow()
    row:SetPoint("TOPLEFT", PAD, -210 - (index - 1) * 18)
    window.deliveries[index] = row
  end
  window.noDeliveries = Text(window, "GameFontDisableSmall")
  window.noDeliveries:SetPoint("TOPLEFT", PAD + 2, -212)
  window.noDeliveries:SetPoint("RIGHT", -PAD, 0)

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
  ns.FitCheck(mine)
  window.mine = mine
  local mode = T.Button(window, 84, 20, MODE_LABELS[ns.CheapestMode()])
  mode:SetPoint("TOPLEFT", PAD + 160, -381)
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
    GameTooltip:AddLine("Click to switch: by writ, by NPC, by zone.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  mode:SetScript("OnLeave", HideTooltip)
  window.mode = mode
  local buy = T.Button(window, 96, 20, "Buy list")
  buy:SetPoint("TOPRIGHT", -PAD, -381)
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
    GameTooltip:AddLine("Buy list")
    if ns.CheapestMode() == "zone" then
      local zone = ns.CheapestZones(1)[1]
      GameTooltip:AddLine("Makes the Auctionator shopping list \"" .. ns.SHOPPING_LIST .. "\" with every priced "
        .. "writ taken in the cheapest zone, and the items they ask for. Click a zone's row for that zone's.", 1, 1,
        1, true)
      if zone then
        GameTooltip:AddLine(("%s: %d writs for %d NPCs, %s reputation, about %s"):format(zone.name, #zone.writs,
          #zone.npcs, ns.Number(zone.rep), ns.Money(zone.total)), 0.25, 1, 0.25)
      end
      GameTooltip:Show()
      return
    end
    if ns.CheapestMode() == "npc" then
      local group = ns.CheapestCustomers(1)[1]
      GameTooltip:AddLine("Makes the Auctionator shopping list \"" .. ns.SHOPPING_LIST .. "\" with every priced "
        .. "writ the cheapest NPC takes, and the items they ask for. Click an NPC's row for that NPC's.", 1, 1, 1,
        true)
      if group then
        GameTooltip:AddLine(("%s: %d writs, %s reputation, about %s"):format(group.customer.name, #group.writs,
          ns.Number(group.rep), ns.Money(group.total)), 0.25, 1, 0.25)
      end
      GameTooltip:Show()
      return
    end
    local plan = ns.PlanPurchases()
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

-- "Kzixx, Duskwood: 2 writs, 1 ready" or "Radiant Circlet (Artisan): who takes it isn't known yet"
local function DeliveryText(group)
  local ready = group.ready > 0 and (" |cff40ff40%d ready|r"):format(group.ready) or ""
  if group.customer then
    local what = #group.writs == 1 and WritName(group.writs[1].writID) or (#group.writs .. " writs")
    return ("%s |cff999999%s|r: %s%s"):format(group.customer.name, ns.MapName(group.customer.mapID), what,
      ready ~= "" and "," .. ready or "")
  end
  return ("%s |cff999999(not known who takes it)|r%s"):format(WritName(group.writs[1].writID), ready)
end

local function Deliveries(counts)
  local groups = ns.Deliveries(counts)
  for index, row in ipairs(window.deliveries) do
    local group = groups[index]
    if group then
      row.group = group
      row.name:SetText(DeliveryText(group))
      row.way:SetShown(group.customer ~= nil or group.writs[1].questID ~= nil)
      row:Show()
    else
      row.group = nil
      row:Hide()
    end
  end
  if #groups == 0 then
    window.noDeliveries:SetText("No writs. The writs you hold show here, grouped by who takes them.")
  elseif #groups > DELIVERY_ROWS then
    window.noDeliveries:SetText("")
    local last = window.deliveries[DELIVERY_ROWS]
    last.name:SetText(last.name:GetText() .. (" |cff999999+%d more|r"):format(#groups - DELIVERY_ROWS))
  else
    window.noDeliveries:SetText("")
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
      local what = #group.writs == 1 and ns.WRITS[group.writs[1].writID][3] or (#group.writs .. " writs")
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
      row.name:SetText(("%s|cff999999:|r %d NPC%s, %d writ%s"):format(zone.name, #zone.npcs,
        #zone.npcs == 1 and "" or "s", #zone.writs, #zone.writs == 1 and "" or "s"))
      row.cost:SetText(("%s |cff999999· %s / 100|r"):format(ns.ShortMoney(zone.total), ns.ShortMoney(zone.per100)))
      row:Show()
    else
      row.zone = nil
      row:Hide()
    end
  end
  return #zones
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
      row.name:SetText(("%s |cff999999(%s, %d)|r"):format(writ[3], tier.name, entry.rep))
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
  Deliveries(counts)
  window.goals:SetText(Goals(faction, bagRep))
  Cheapest(counts)

  local session = ns.session
  window.session:SetText(("This session: +%s Favor, +%s reputation, %d crates, %d writs%s"):format(
    ns.Number(session.favor), ns.Number(session.rep), session.crates, session.writs,
    session.bonuses > 0 and (", " .. session.bonuses .. " bonus") or ""))
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
