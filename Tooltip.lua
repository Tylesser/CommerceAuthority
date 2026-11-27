local _, ns = ...
local L = ns.L

-- Tooltip lines for Craftsman's Writs, sealed writs and Waylaid Crates. Hooked with TooltipDataProcessor
-- where it exists (every item tooltip), otherwise OnTooltipSetItem on GameTooltip and ItemRefTooltip.

local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }
local GREY = { 0.6, 0.6, 0.6 }
local GREEN = { 0.25, 1, 0.25 }
local TITLE = "Commerce Authority: "

local function DB()
  return CommerceAuthorityDB or ns.defaults
end

-- "1g 20s" for one item, "1g 20s each, 24g for 20" for more.
local function Price(each, count)
  if count == 1 then
    return ns.Money(each)
  end
  return L["%s each, %s for %d"]:format(ns.Money(each), ns.Money(each * count), count)
end

-- "50s (Auctionator), 48s (TSM)"; only the first source unless all are wanted.
local function PriceList(prices, count)
  local parts = {}
  for index, entry in ipairs(prices) do
    if index > 1 and not DB().allSources then
      break
    end
    local text = Price(entry.price, count)
    if #prices > 1 or DB().allSources then
      text = text .. " (" .. entry.name .. ")"
    end
    parts[#parts + 1] = text
  end
  return table.concat(parts, ", ")
end

local function Lines()
  local lines = {}
  local function Add(text, color, wrap)
    lines[#lines + 1] = { text, color[1], color[2], color[3], wrap }
  end
  return lines, Add
end

local function RepText(rep, learned, tier)
  local level = ns.TierName(tier and tier.name)
  if learned then
    return L["%s writ, %s reputation"]:format(level, ns.Number(rep))
  end
  return L["%s writ, %s reputation (guide)"]:format(level, ns.Number(rep))
end

-- Lines for a Craftsman's Writ, or nil.
function ns.WritTooltipLines(writID)
  local writ = ns.Writ(writID)
  if not writ then
    return nil
  end
  local lines, Add = Lines()
  local rep, learned, tier = ns.WritReputation(writID)
  if rep then
    Add(TITLE .. RepText(rep, learned, tier), GOLD)
  else
    Add(TITLE .. "Craftsman's Writ", GOLD)
  end
  local itemID = ns.WantedItem(writ)
  local count = ns.WritCount(writID, writ)
  local name = (itemID and ns.ItemName(itemID)) or writ[3]
  local needs = L["Needs %d %s"]:format(count, name)
  local profession = ns.WritProfession(writID)
  if profession then
    local skill = ns.PlayerProfessions()[profession]
    needs = (skill and L["Needs %d %s (%s, yours)"] or L["Needs %d %s (%s)"]):format(count, name,
      ns.ProfessionName(profession))
  end
  Add("  " .. needs, WHITE)
  local prices = ns.Prices(itemID)
  if #prices > 0 then
    Add("  " .. L["AH: %s"]:format(PriceList(prices, count)), WHITE)
  else
    Add("  " .. L["No AH price yet: search for it at the auction house."], GREY)
  end
  local craft = itemID and ns.CraftCost(itemID)
  if craft then
    Add("  " .. L["Crafting: %s (Profit Sort)"]:format(Price(craft, count)), WHITE)
  end
  local total, per100 = ns.WritCost(writID)
  if total then
    local writPrice = ns.Price(writID)
    Add("  " .. L["With the writ (%s): %s, %s per 100 reputation"]:format(ns.Money(writPrice), ns.Money(total),
      ns.Money(per100)), GREEN)
  end
  ns.CustomerTooltipLines(writID, Add)
  return lines
end

-- Who takes the writ, and the other writs that NPC takes (so one trip delivers them all).
function ns.CustomerTooltipLines(writID, Add)
  if not ns.WritTier(writID) then
    return
  end
  local customer = ns.WritCustomer(writID)
  if not customer then
    Add("  " .. L["Deliver to: not known yet. Use the writ and the game marks the spot on your map."], GREY, true)
    return
  end
  Add("  " .. L["Deliver to %s"]:format(ns.CustomerText(customer)), WHITE)
  local others = {}
  local counts
  for _, otherID in ipairs(ns.CustomerWrits(customer)) do
    if otherID ~= writID then
      counts = counts or ns.BagCounts()
      local name = ns.Writ(otherID)[3]
      others[#others + 1] = (counts[otherID] or 0) > 0 and (name .. " |cff40ff40" .. L["(you have it)"] .. "|r") or name
    end
  end
  if #others > 0 then
    Add("  " .. L["%s also takes: %s"]:format(customer.name, table.concat(others, ", ")), GREY, true)
  end
end

-- Lines for "Sealed Expert's Writ" and the like, or nil.
function ns.SealedWritTooltipLines(name)
  local tierIndex = name and ns.SEALED_WRITS[name]
  if not tierIndex then
    return nil
  end
  local tier = ns.WRIT_TIERS[tierIndex]
  local rep = ns.TierRep(tier)
  local lines, Add = Lines()
  Add(TITLE .. L["opens into a %s writ, %s reputation"]:format(ns.TierName(tier.name), ns.Number(rep)), GOLD)
  return lines
end

-- Lines for a crate that doesn't say its kind yet (UNREAD_CRATES), or nil.
local function UnreadCrateLines(itemID)
  local kind = itemID and ns.UNREAD_CRATES[itemID]
  if not kind then
    return nil
  end
  local lines, Add = Lines()
  if kind == "label" then
    Add(TITLE .. L["use it to read the label."], GOLD)
    Add("  " .. L["It becomes a Waylaid Crate of one kind, which then shows its Favor and what fills it."], GREY, true)
    return lines
  end
  local data = ns.Collected and ns.Collected()
  local ok, text = false, nil
  if data and type(data.Text) == "function" then
    ok, text = pcall(data.Text, "item", itemID)
  end
  local page = ok and type(text) == "table" and type(text.pages) == "table" and text.pages[1]
  if type(page) == "string" and page ~= "" then
    page = page:gsub("%s+", " ")
    if #page > 160 then
      page = page:sub(1, 157) .. "..."
    end
    Add(TITLE .. L["its shipping bill (players' data):"], GOLD)
    Add("  " .. page, WHITE, true)
  else
    Add(TITLE .. L["use it to read its shipping bill."], GOLD)
    Add("  " .. L["What it asks for isn't known yet."], GREY)
  end
  return lines
end

-- Lines for a Waylaid Crate (to fill) or a sealed crate (filled), or nil.
function ns.CrateTooltipLines(itemID, name)
  local unread = UnreadCrateLines(itemID)
  if unread then
    return unread
  end
  local favor, learned, info = ns.CrateFavor(itemID, name)
  if not favor then
    return nil
  end
  local lines, Add = Lines()
  local text
  local amount, silver = ns.Number(favor), ns.Money(favor * ns.COPPER_PER_FAVOR)
  if learned then
    text = L["%s Merchant's Favor + %s"]:format(amount, silver)
  elseif info.guess then
    text = L["about %s Merchant's Favor + %s (a guess)"]:format(amount, silver)
  else
    text = L["about %s Merchant's Favor + %s (guide)"]:format(amount, silver)
  end
  Add(TITLE .. text, GOLD)
  if not info.filled and not (info.contents and #info.contents > 0) then
    Add("  " .. L["Fill it with one item from its list, then turn it in at the trade hub."], GREY)
  end
  if ns.HasPerformanceBonus() then
    Add("  " .. L["%s: %d%% chance of %s"]:format(ns.TalentName(ns.PERFORMANCE_BONUS_SPELL, "Performance Bonus"), ns.PERFORMANCE_BONUS_CHANCE * 100,
      ns.Number(favor * 2)), GREY)
  end
  if not info.filled then
    local crateCost = ns.Price(itemID)
    if crateCost then
      Add("  " .. L["Crate: %s"]:format(PriceList(ns.Prices(itemID), 1)), WHITE)
    end
    local counts = ns.BagCounts()
    local options = ns.CrateFillOptions(info, counts)
    local shown = 0
    for _, option in ipairs(options) do
      if option.owned >= option.count then
        Add("  " .. L["You have %d %s: enough to fill it"]:format(option.owned, option.name), GREEN)
        break
      end
    end
    for _, option in ipairs(options) do
      if shown >= 3 then
        break
      end
      shown = shown + 1
      local text = L["Fill: %d %s"]:format(option.count, option.name)
      if option.cost then
        text = L["Fill: %d %s, %s"]:format(option.count, option.name, ns.Money(option.cost))
      end
      Add("  " .. text, shown == 1 and WHITE or GREY)
    end
    local cheapest = options[1] and options[1].cost
    if cheapest and crateCost then
      Add("  " .. L["Crate + fill: %s, %s per Favor"]:format(ns.Money(crateCost + cheapest),
        ns.Money((crateCost + cheapest) / favor)), GREEN)
    end
  end
  return lines
end

-- All lines for an item, or nil.
function ns.TooltipLines(itemID)
  if not itemID then
    return nil
  end
  local db = DB()
  if db.writTooltips then
    local lines = ns.WritTooltipLines(itemID)
    if lines then
      return lines
    end
    lines = ns.SealedWritTooltipLines(ns.ItemName(itemID))
    if lines then
      return lines
    end
  end
  if db.crateTooltips then
    return ns.CrateTooltipLines(itemID)
  end
end

-- Hooks ------------------------------------------------------------------------------------------------

local added = {}   -- tooltip -> true while it shows the lines
local watched = {} -- tooltips whose OnTooltipCleared is hooked

local function IsShoppingTooltip(tooltip)
  if tooltip == ShoppingTooltip1 or tooltip == ShoppingTooltip2
    or tooltip == ItemRefShoppingTooltip1 or tooltip == ItemRefShoppingTooltip2 then
    return true
  end
  local ok, name = pcall(tooltip.GetName, tooltip)
  return ok and type(name) == "string" and name:find("ShoppingTooltip", 1, true) ~= nil
end

-- Hidden scanning tooltips (other addons') have no anchor points; real tooltips do.
local function IsOnScreen(tooltip)
  if tooltip == GameTooltip or tooltip == ItemRefTooltip then
    return true
  end
  if tooltip:IsVisible() then
    return true
  end
  return tooltip.GetNumPoints ~= nil and tooltip:GetNumPoints() > 0
end

local function Watch(tooltip)
  if watched[tooltip] then
    return
  end
  watched[tooltip] = true
  if tooltip.HookScript then
    tooltip:HookScript("OnTooltipCleared", function(self)
      added[self] = nil
    end)
  end
end

local function ItemOf(tooltip, data)
  if data and type(data.id) == "number" then
    return data.id
  end
  if tooltip.GetItem then
    local _, link = tooltip:GetItem()
    return ns.ItemIDFromLink(link)
  end
end

local function AddLines(tooltip, data)
  if added[tooltip] or IsShoppingTooltip(tooltip) or not IsOnScreen(tooltip) then
    return
  end
  Watch(tooltip)
  local lines = ns.TooltipLines(ItemOf(tooltip, data))
  if lines and #lines > 0 then
    added[tooltip] = true
    for _, line in ipairs(lines) do
      tooltip:AddLine(line[1], line[2], line[3], line[4], line[5])
    end
    tooltip:Show()
  end
end

function ns.OnItemTooltip(tooltip, data)
  pcall(AddLines, tooltip, data)
end

function ns.HookItemTooltips()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ns.OnItemTooltip)
    return
  end
  for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
    if tooltip and tooltip.HookScript then
      tooltip:HookScript("OnTooltipSetItem", ns.OnItemTooltip)
    end
  end
end
