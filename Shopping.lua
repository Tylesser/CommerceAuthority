local addonName, ns = ...
local L = ns.L

-- The buy list: an Auctionator shopping list "Commerce Authority" with the cheapest writs for the
-- reputation you still need to the next standing, or every writ one NPC takes, and the items they ask for
-- (the ones cheaper to buy than to craft). At most MAX_WRITS writs per list to the next standing.

ns.SHOPPING_LIST = "Commerce Authority"
local MAX_WRITS = 20
local DEFAULT_GOAL = 3000 -- no reputation yet: enough for Friendly

local function Say(text)
  print("|cfff0c24eCommerce Authority:|r " .. text)
end

-- The writs to buy: { picks = { entry... }, rep, cost, goal }.
function ns.PlanPurchases()
  local faction = ns.Faction()
  local goal = DEFAULT_GOAL
  local standings = ns.NextStandings(faction)
  if faction then
    goal = standings[1] and standings[1].needed or 0
  end
  goal = math.max(goal - ns.BagSummary().writRep, 0)
  local plan = { picks = {}, rep = 0, cost = 0, goal = goal }
  for _, entry in ipairs(ns.CheapestWrits()) do
    if plan.rep >= goal or #plan.picks >= MAX_WRITS then
      break
    end
    plan.picks[#plan.picks + 1] = entry
    plan.rep = plan.rep + entry.rep
    plan.cost = plan.cost + entry.total
  end
  return plan
end

-- What to buy for a writ's items (2026-11-22, the user's request: search the materials of what you craft): the item
-- itself when buying is cheaper, its materials when crafting is (Profit Sort's record), else nothing. Calls
-- add(name, quantity) for each; `count` = how many of the item the writs ask for.
local function ItemsFor(writID, writ, count, add)
  local _, how = ns.WantedItemCost(writID)
  local itemID = ns.WantedItem(writ)
  if how == "craft" and itemID then
    local reagents, made = ns.CraftReagents(itemID)
    if reagents then
      local crafts = math.ceil(count / math.max(made or 1, 1))
      for _, reagent in ipairs(reagents) do
        add(ns.ItemName(reagent.itemID), reagent.count * crafts)
      end
      return
    end
  end
  if itemID or writ[3] then
    add((itemID and ns.ItemName(itemID)) or writ[3], count)
  end
end
ns.ItemsFor = ItemsFor

-- Puts writs (cheapest-list entries) and the items they ask for (or, for the items cheaper to craft, their
-- materials) into the Auctionator list. Returns true when the list was made.
local function MakeList(api, picks)
  local searches, items, order = {}, {}, {}
  for _, entry in ipairs(picks) do
    local writ = ns.WRITS[entry.writID]
    local writName = ns.ItemName(entry.writID) or ("Craftsman's Writ: " .. writ[3])
    searches[#searches + 1] = api.ConvertToSearchString(addonName, { searchString = writName, isExact = true,
      quantity = 1 })
    ItemsFor(entry.writID, writ, ns.WritCount(entry.writID, writ), function(name, quantity)
      if name then
        if not items[name] then
          order[#order + 1] = name
          items[name] = 0
        end
        items[name] = items[name] + quantity
      end
    end)
  end
  for _, name in ipairs(order) do
    searches[#searches + 1] = api.ConvertToSearchString(addonName, { searchString = name, isExact = true,
      quantity = items[name] })
  end
  local ok, err = pcall(api.CreateShoppingList, addonName, ns.SHOPPING_LIST, searches)
  if not ok then
    Say(L["Auctionator couldn't make the list: %s"]:format(tostring(err)))
    return false
  end
  return true
end

local function API()
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not (api and api.CreateShoppingList and api.ConvertToSearchString) then
    Say(L["the buy list needs Auctionator."])
    return nil
  end
  return api
end

-- The cheapest writs to your next standing.
function ns.CreateBuyList()
  local api = API()
  if not api then
    return false
  end
  local plan = ns.PlanPurchases()
  if plan.goal <= 0 then
    Say(L["the writs in your bags already reach your next standing."])
    return false
  end
  if #plan.picks == 0 then
    Say(L["no priced writs yet. Scan the auction house, or search for \"%s\"."]:format("Craftsman's Writ"))
    return false
  end
  if not MakeList(api, plan.picks) then
    return false
  end
  Say(L["shopping list \"%s\": %d writs for about %s reputation (%s needed), about %s in all."]:format(
    ns.SHOPPING_LIST, #plan.picks, ns.Number(plan.rep), ns.Number(plan.goal), ns.Money(plan.cost)))
  return true
end

-- Every priced writ one NPC takes (a group from ns.CheapestCustomers), to deliver in one trip.
function ns.CreateCustomerBuyList(group)
  local api = API()
  if not (api and group and #group.writs > 0) then
    return false
  end
  if not MakeList(api, group.writs) then
    return false
  end
  Say(L["shopping list \"%s\": %d writs for %s, about %s reputation, about %s in all."]:format(
    ns.SHOPPING_LIST, #group.writs, ns.CustomerText(group.customer), ns.Number(group.rep), ns.Money(group.total)))
  return true
end

-- Every priced writ taken in one zone (a zone from ns.CheapestZones): one list, one trip around the zone.
function ns.CreateZoneBuyList(zone)
  local api = API()
  if not (api and zone and #zone.writs > 0) then
    return false
  end
  if not MakeList(api, zone.writs) then
    return false
  end
  Say(L["shopping list \"%s\": %d writs for %d NPCs in %s, about %s reputation, about %s in all."]:format(
    ns.SHOPPING_LIST, #zone.writs, #zone.npcs, zone.name, ns.Number(zone.rep), ns.Money(zone.total)))
  return true
end

-- The buy list for one kind of crate (an entry of ns.CratesToFill): the cheapest priced fill item, enough for all
-- of them, less what your bags hold.
function ns.CreateCrateBuyList(crate)
  local api = API()
  local option = crate and crate.options[1]
  if not (api and option) then
    if api then
      Say(L["no known fill for %s."]:format(crate and crate.info.name or L["that crate"]))
    end
    return false
  end
  local need = ns.CrateNeed(crate, option) or 0
  if need == 0 then
    Say(L["your bags already hold enough %s to fill %s."]:format(option.name, crate.info.name))
    return false
  end
  local search = api.ConvertToSearchString(addonName, { searchString = option.name, isExact = true, quantity = need })
  local ok, err = pcall(api.CreateShoppingList, addonName, ns.SHOPPING_LIST, { search })
  if not ok then
    Say(L["Auctionator couldn't make the list: %s"]:format(tostring(err)))
    return false
  end
  Say(L["shopping list \"%s\": %d %s to fill %d %s."]:format(ns.SHOPPING_LIST, need, option.name, crate.count,
    crate.info.name))
  return true
end

-- Auction house search ----------------------------------------------------------------------------------

function ns.AuctionHouseOpen()
  return (AuctionHouseFrame and AuctionHouseFrame:IsShown()) or (AuctionFrame and AuctionFrame:IsShown()) or false
end

-- The game's own search box takes one name.
local function BlizzardSearch(term)
  local bar = AuctionHouseFrame and AuctionHouseFrame:IsShown() and AuctionHouseFrame.SearchBar
  if bar and bar.SearchBox and bar.StartSearch then
    bar.SearchBox:SetText(term)
    bar:StartSearch()
    return true
  end
  if BrowseName and AuctionFrameBrowse_Search then
    BrowseName:SetText(term)
    AuctionFrameBrowse_Search()
    return true
  end
  return false
end

-- How many of one fill item (an entry of crate.options) all the crates of that kind still need, less what your
-- bags hold; nil when the bags hold enough.
function ns.CrateNeed(crate, option)
  local need = (option.count or 0) * (crate.count or 1) - (option.owned or 0)
  return need > 0 and need or nil
end

-- The amount to buy in the game's own commodity buy view (2026-11-27, the user's request: a crate's fill item opens
-- with the amount the crates need). `wanted[itemID]` = amount, kept for a few minutes after a crate search. Done the
-- way typing in its box does it (forever Blizzard_AuctionHouseCommoditiesBuyFrame.lua: the QuantityInput's changed
-- callback triggers CommoditiesQuantitySelectionChanged, which BuyDisplay and the list listen to); again a frame
-- after the item's results come (before them the game can't total the price or cap the amount at what is on sale).
-- Nothing is bought: the player still presses Buy. (Auctionator's own buy view takes the amount from the search.)
local wanted, wantedUntil, pending = {}, 0, nil
local WANT_SECONDS = 300

local function SetBuyQuantity()
  local frame = AuctionHouseFrame
  local display = frame and frame.CommoditiesBuyFrame and frame.CommoditiesBuyFrame.BuyDisplay
  if not (display and display.QuantityInput and display.GetItemID and display:IsShown()) or GetTime() > wantedUntil then
    return false
  end
  local ok, itemID = pcall(display.GetItemID, display)
  local quantity = ok and itemID and wanted[itemID]
  if not quantity then
    return false
  end
  pcall(display.QuantityInput.SetQuantity, display.QuantityInput, quantity)
  local event = AuctionHouseFrameMixin and AuctionHouseFrameMixin.Event
    and AuctionHouseFrameMixin.Event.CommoditiesQuantitySelectionChanged
  if event and frame.TriggerEvent then
    pcall(frame.TriggerEvent, frame, event, quantity)
  elseif display.SetQuantitySelected then
    pcall(display.SetQuantitySelected, display, quantity)
  end
  return true
end

local watcher
local function WatchBuyView()
  local buy = AuctionHouseFrame and AuctionHouseFrame.CommoditiesBuyFrame
  if watcher or not (buy and buy.SetItemIDAndPrice and hooksecurefunc and CreateFrame) then
    return
  end
  watcher = CreateFrame("Frame")
  hooksecurefunc(buy, "SetItemIDAndPrice", function(_, itemID)
    pending = itemID and wanted[itemID] and GetTime() <= wantedUntil and itemID or nil
    if pending then
      SetBuyQuantity()
    end
  end)
  watcher:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
  watcher:SetScript("OnEvent", function(_, _, itemID)
    if pending and itemID == pending then
      pending = nil -- once: after a purchase the game's own reset to 1 stays
      C_Timer.After(0, SetBuyQuantity)
    end
  end)
end

-- Searches the open auction house for `searches` ({ searchString, quantity, itemID }) and keeps their amounts for the
-- buy view. With Auctionator every item at once ("auctionator"), else the game's search box with the first
-- ("blizzard"). Returns how, or nil.
local function SearchItems(searches)
  local terms, advanced = {}, {}
  wanted, wantedUntil = {}, GetTime() + WANT_SECONDS
  for _, search in ipairs(searches) do
    terms[#terms + 1] = search.searchString
    advanced[#advanced + 1] = { searchString = search.searchString, isExact = true, quantity = search.quantity }
    if search.quantity and search.itemID then
      wanted[search.itemID] = search.quantity
    end
  end
  pcall(WatchBuyView)
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if api and (api.MultiSearchAdvanced or api.MultiSearchExact) then
    local ok, err
    if api.MultiSearchAdvanced then
      ok, err = pcall(api.MultiSearchAdvanced, addonName, advanced)
    else
      ok, err = pcall(api.MultiSearchExact, addonName, terms)
    end
    if ok then
      return "auctionator"
    end
    Say(L["Auctionator couldn't search: %s"]:format(tostring(err)))
  end
  local ok, started = pcall(BlizzardSearch, terms[1])
  if ok and started then
    return "blizzard"
  end
  return nil
end

-- Searches the open auction house for everything that fills a crate (an entry of ns.CratesToFill), cheapest first.
-- With Auctionator every item at once, else the game's search box with the cheapest. Returns true when started.
-- Picking a result opens the buy view with the amount the crates still need (Auctionator's or the game's).
function ns.SearchCrate(crate)
  if not (crate and ns.AuctionHouseOpen()) then
    return false
  end
  local searches = {}
  for _, option in ipairs(crate.options) do
    searches[#searches + 1] = { searchString = option.name, quantity = ns.CrateNeed(crate, option),
      itemID = option.itemID }
  end
  if #searches == 0 then
    Say(L["no known fill for %s."]:format(crate.info.name))
    return false
  end
  local how = SearchItems(searches)
  if how == "auctionator" then
    if #searches == 1 then
      Say(L["searching the auction house: what fills %s (1 item)."]:format(crate.info.name))
    else
      Say(L["searching the auction house: what fills %s (%d items)."]:format(crate.info.name, #searches))
    end
  elseif how == "blizzard" and #searches > 1 then
    Say(L["searching for %s; install Auctionator to search all %d fills at once."]:format(searches[1].searchString,
      #searches))
  end
  return how ~= nil
end

-- A crate from the By crate ranking (an entry of ns.CheapestCrates): searches the open auction house for the crate
-- and every item that fills it (one crate's worth each, the cheapest first). Returns true when a search started.
function ns.SearchRankedCrate(entry)
  if not (entry and ns.AuctionHouseOpen()) then
    return false
  end
  local searches = { { searchString = entry.name, quantity = 1, itemID = entry.itemID } }
  if not entry.info.filled then
    for _, option in ipairs(ns.CrateFillOptions(entry.info)) do
      searches[#searches + 1] = { searchString = option.name, quantity = option.count, itemID = option.itemID }
    end
  end
  local how = SearchItems(searches)
  if how == "auctionator" then
    Say(L["searching the auction house: %s and what fills it."]:format(entry.name))
  elseif how == "blizzard" and #searches > 1 then
    Say(L["searching for %s; install Auctionator to search for what fills it at the same time."]:format(entry.name))
  end
  return how ~= nil
end

-- The buy list for a crate from the By crate ranking: the crate and its cheapest fill.
function ns.CreateRankedCrateBuyList(entry)
  local api = API()
  if not (api and entry) then
    return false
  end
  local searches = { api.ConvertToSearchString(addonName, { searchString = entry.name, isExact = true, quantity = 1 }) }
  if entry.fill then
    searches[2] = api.ConvertToSearchString(addonName, { searchString = entry.fill.name, isExact = true,
      quantity = entry.fill.count })
  end
  local ok, err = pcall(api.CreateShoppingList, addonName, ns.SHOPPING_LIST, searches)
  if not ok then
    Say(L["Auctionator couldn't make the list: %s"]:format(tostring(err)))
    return false
  end
  if entry.fill then
    Say(L["shopping list \"%s\": %s and %d %s to fill it, about %s."]:format(ns.SHOPPING_LIST, entry.name,
      entry.fill.count, entry.fill.name, ns.Money(entry.total)))
  else
    Say(L["shopping list \"%s\": %s, about %s."]:format(ns.SHOPPING_LIST, entry.name, ns.Money(entry.total)))
  end
  return true
end

-- Searches the open auction house for writs you don't hold yet, and the items asked for by those and by your
-- writs that aren't ready (for an item cheaper to craft: its materials). `held` from ns.HeldWrits. With Auctionator every name at once (its Shopping tab),
-- else the game's search box with the first. Returns true when a search started.
function ns.SearchWrits(writIDs, held)
  if not ns.AuctionHouseOpen() then
    return false
  end
  held = held or {}
  local terms, seen = {}, {}
  local function Add(name)
    if name and not seen[name] then
      seen[name] = true
      terms[#terms + 1] = name
    end
  end
  local writCount = 0
  for _, writID in ipairs(writIDs) do
    local writ = ns.WRITS[writID]
    local mine = held[writID]
    if writ and not mine then
      Add(ns.ItemName(writID) or ("Craftsman's Writ: " .. writ[3]))
      writCount = writCount + 1
    end
    if writ and not (mine and mine.ready) then
      ItemsFor(writID, writ, ns.WritCount(writID, writ), Add)
    end
  end
  if #terms == 0 then
    Say(L["you already hold all of these writs, and they're ready."])
    return false
  end
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if api and api.MultiSearchExact then
    local ok, err = pcall(api.MultiSearchExact, addonName, terms)
    if ok then
      if writCount == 1 then
        Say(L["searching the auction house: 1 writ and the items they ask for (the materials for those you craft)."])
      else
        Say(L["searching the auction house: %d writs and the items they ask for (the materials for those you craft)."]
          :format(writCount))
      end
      return true
    end
    Say(L["Auctionator couldn't search: %s"]:format(tostring(err)))
  end
  local ok, started = pcall(BlizzardSearch, terms[1])
  if ok and started then
    if #terms > 1 then
      Say(L["searching for %s; install Auctionator to search all %d names at once."]:format(terms[1], #terms))
    end
    return true
  end
  return false
end
