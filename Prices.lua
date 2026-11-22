local addonName, ns = ...

-- Auction prices from whichever price addons are installed, in this order: Auctionator, TradeSkillMaster,
-- Auctioneer. Only their public APIs are used. Every call is protected, so a changed or broken API
-- just means no price from that addon.

local function ItemLink(itemID)
  local getInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
  if getInfo then
    return (select(2, getInfo(itemID)))
  end
end
ns.ItemLink = ItemLink

-- By link first: on the modern auction house Auctionator keys gear by item level, so armour and weapons
-- (what most writs ask for) may only have a price under their link. Then by item ID.
local function FromAuctionator(itemID)
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not api then
    return nil
  end
  local link = api.GetAuctionPriceByItemLink and ItemLink(itemID)
  local price = link and api.GetAuctionPriceByItemLink(addonName, link)
  if not price and api.GetAuctionPriceByItemID then
    price = api.GetAuctionPriceByItemID(addonName, itemID)
  end
  return price
end

local function FromTSM(itemID)
  if TSM_API and TSM_API.GetCustomPriceValue then
    local itemString = "i:" .. itemID
    return TSM_API.GetCustomPriceValue("DBMarket", itemString)
      or TSM_API.GetCustomPriceValue("DBMinBuyout", itemString)
  end
end

local function FromAuctioneer(itemID)
  local api = AucAdvanced and AucAdvanced.API
  if api and api.GetMarketValue then
    local link = ItemLink(itemID)
    if link then
      return (api.GetMarketValue(link))
    end
  end
end

ns.PRICE_SOURCES = {
  { name = "Auctionator", get = FromAuctionator },
  { name = "TSM", get = FromTSM },
  { name = "Auctioneer", get = FromAuctioneer },
}

-- All prices for an item: { { name, price }, ... } in source order. Empty when no addon has one.
function ns.Prices(itemID)
  local found = {}
  if not itemID then
    return found
  end
  for _, source in ipairs(ns.PRICE_SOURCES) do
    local ok, price = pcall(source.get, itemID)
    if ok and type(price) == "number" and price > 0 then
      found[#found + 1] = { name = source.name, price = price }
    end
  end
  return found
end

-- The price to calculate with: the first installed source that has one.
function ns.Price(itemID)
  local first = ns.Prices(itemID)[1]
  return first and first.price, first and first.name
end

-- Names of the installed price addons, for the options page and /aca debug.
function ns.PriceSourceNames()
  local names = {}
  if Auctionator and Auctionator.API and Auctionator.API.v1 then
    names[#names + 1] = "Auctionator"
  end
  if TSM_API then
    names[#names + 1] = "TSM"
  end
  if AucAdvanced and AucAdvanced.API then
    names[#names + 1] = "Auctioneer"
  end
  return names
end

-- Your crafting cost of one item, when Tylesser - Auctionator Profit Sort has scanned a recipe that makes it.
function ns.CraftCost(itemID)
  local products = ProfitSortCharDB and ProfitSortCharDB.products
  local record = itemID and type(products) == "table" and products[itemID]
  if type(record) == "table" and record.cost then
    return record.cost / (record.numMade or 1)
  end
end

-- The materials of one craft of an item (from Profit Sort's record: { itemID, count } each) and how many one craft
-- makes, or nil (no record, or a Profit Sort from before it kept materials).
function ns.CraftReagents(itemID)
  local products = ProfitSortCharDB and ProfitSortCharDB.products
  local record = itemID and type(products) == "table" and products[itemID]
  if type(record) == "table" and type(record.reagents) == "table" and #record.reagents > 0 then
    return record.reagents, record.numMade or 1
  end
end

-- "12g 34s 56c", or "--" for nil.
function ns.Money(amount)
  if not amount then
    return "--"
  end
  amount = math.floor(amount + 0.5)
  local gold = math.floor(amount / 10000)
  local silver = math.floor(amount / 100) % 100
  local copper = amount % 100
  local parts = {}
  if gold > 0 then
    parts[#parts + 1] = gold .. "g"
  end
  if silver > 0 then
    parts[#parts + 1] = silver .. "s"
  end
  if copper > 0 or #parts == 0 then
    parts[#parts + 1] = copper .. "c"
  end
  return table.concat(parts, " ")
end

-- Like ns.Money, without copper from 1 gold up (for short columns): "4g 10s".
function ns.ShortMoney(amount)
  if amount and amount >= 10000 then
    return ns.Money(math.floor(amount / 100 + 0.5) * 100)
  end
  return ns.Money(amount)
end

-- "1,234"
function ns.Number(value)
  local text = tostring(math.floor((value or 0) + 0.5))
  local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (formatted:gsub("^,", ""))
end
