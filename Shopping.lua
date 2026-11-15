local addonName, ns = ...

-- The buy list: an Auctionator shopping list "Commerce Authority" with the cheapest writs for the
-- reputation you still need to the next standing, and the items they ask for (the ones cheaper to buy than
-- to craft). At most MAX_WRITS writs per list.

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

function ns.CreateBuyList()
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not (api and api.CreateShoppingList and api.ConvertToSearchString) then
    Say("the buy list needs Auctionator.")
    return false
  end
  local plan = ns.PlanPurchases()
  if plan.goal <= 0 then
    Say("the writs in your bags already reach your next standing.")
    return false
  end
  if #plan.picks == 0 then
    Say("no priced writs yet. Scan the auction house, or search for \"Craftsman's Writ\".")
    return false
  end
  local searches, items, order = {}, {}, {}
  for _, entry in ipairs(plan.picks) do
    local writ = ns.WRITS[entry.writID]
    local writName = ns.ItemName(entry.writID) or ("Craftsman's Writ: " .. writ[3])
    searches[#searches + 1] = api.ConvertToSearchString(addonName, { searchString = writName, isExact = true,
      quantity = 1 })
    local _, how = ns.WantedItemCost(entry.writID)
    local itemID = ns.WantedItem(writ)
    if how == "buy" and itemID then
      local name = ns.ItemName(itemID) or writ[3]
      if not items[name] then
        order[#order + 1] = name
        items[name] = 0
      end
      items[name] = items[name] + ns.WritCount(entry.writID, writ)
    end
  end
  for _, name in ipairs(order) do
    searches[#searches + 1] = api.ConvertToSearchString(addonName, { searchString = name, isExact = true,
      quantity = items[name] })
  end
  local ok, err = pcall(api.CreateShoppingList, addonName, ns.SHOPPING_LIST, searches)
  if not ok then
    Say("Auctionator couldn't make the list: " .. tostring(err))
    return false
  end
  Say(("shopping list \"%s\": %d writs for about %s reputation (%s needed), about %s in all."):format(
    ns.SHOPPING_LIST, #plan.picks, ns.Number(plan.rep), ns.Number(plan.goal), ns.Money(plan.cost)))
  return true
end
