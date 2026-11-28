local _, ns = ...
local L = ns.L

-- The delivery route and the map pins (2026-11-28, the user's request).
-- Route: the NPCs who take the writs you hold, nearest first from where you stand, then each next one nearest to
-- the last (on the same continent; other continents after). Only the NPCs with a ready writ while you have one,
-- else all of them. With TomTom every stop gets a waypoint; the game's own map pin holds one, so it marks the
-- first and chat names the rest. Distances come from C_Map.GetWorldPosFromMapPos (yards, per continent).
-- Pins: a small icon on the world map at each of those NPCs (zone maps, and the continent and world maps through
-- C_Map.GetMapRectOnMap), green when a writ for it is ready, gold otherwise. Hover for the NPC and its writs,
-- click for a waypoint. Our own data provider on WorldMapFrame (MapCanvas AddDataProvider), frames of ours on
-- the map canvas: a holder at the spot and the pin on it, scaled against the canvas zoom so it keeps its size.
-- Option mapPins (on by default).

local PREFIX = "|cfff0c24eCommerce Authority:|r "
local PIN_SIZE = 18

local function DB()
  return CommerceAuthorityDB or ns.defaults
end

local function Secret(value)
  return value ~= nil and issecretvalue ~= nil and issecretvalue(value) == true
end

local function Num(value)
  return type(value) == "number" and not Secret(value) and value or nil
end

-- Route ------------------------------------------------------------------------------------------------------------

-- A spot as the game's world coordinates: continentID, x, y (yards), or nil.
function ns.WorldPosition(mapID, x, y)
  if not (mapID and x and y and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
    return nil
  end
  local ok, continent, position = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
  if not (ok and Num(continent) and type(position) == "table") then
    return nil
  end
  local wx, wy
  if position.GetXY then
    wx, wy = position:GetXY()
  else
    wx, wy = position.x, position.y
  end
  wx, wy = Num(wx), Num(wy)
  if not (wx and wy) then
    return nil
  end
  return continent, wx, wy
end

-- Where you stand, in world coordinates (nil in instances and wherever the game gives no map position).
function ns.PlayerWorldPosition()
  local mapID = C_Map and C_Map.GetBestMapForUnit and Num(C_Map.GetBestMapForUnit("player"))
  local position = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
  if type(position) ~= "table" then
    return nil
  end
  local x, y
  if position.GetXY then
    x, y = position:GetXY()
  else
    x, y = position.x, position.y
  end
  x, y = Num(x), Num(y)
  if not (x and y) or (x == 0 and y == 0) then
    return nil
  end
  return ns.WorldPosition(mapID, x, y)
end

-- The stops of the delivery route: { { group (ns.Deliveries), yards (from the stop before; nil when not known) },
-- ... } and whether it holds only the NPCs with a ready writ.
function ns.DeliveryRoute(counts)
  local known, ready = {}, {}
  for _, group in ipairs(ns.Deliveries(counts)) do
    if group.customer then
      known[#known + 1] = group
      if group.ready > 0 then
        ready[#ready + 1] = group
      end
    end
  end
  local readyOnly = #ready > 0
  local left = {}
  for _, group in ipairs(readyOnly and ready or known) do
    local customer = group.customer
    local continent, x, y = ns.WorldPosition(customer.mapID, customer.x / 100, customer.y / 100)
    left[#left + 1] = { group = group, continent = continent, x = x, y = y }
  end
  local route = {}
  local hereContinent, hereX, hereY = ns.PlayerWorldPosition()
  while #left > 0 do
    local best, bestDistance
    for index, stop in ipairs(left) do
      if hereContinent and stop.continent == hereContinent then
        local distance = math.sqrt((stop.x - hereX) ^ 2 + (stop.y - hereY) ^ 2)
        if not bestDistance or distance < bestDistance then
          best, bestDistance = index, distance
        end
      end
    end
    if not best then
      -- nothing left on this continent (or no position): the next one that has a spot, else the list's order
      for index, stop in ipairs(left) do
        if stop.continent then
          best = index
          break
        end
      end
      best = best or 1
    end
    local stop = table.remove(left, best)
    route[#route + 1] = { group = stop.group, yards = bestDistance }
    if stop.continent then
      hereContinent, hereX, hereY = stop.continent, stop.x, stop.y
    end
  end
  return route, readyOnly
end

-- "Spek (Alterac Mountains, 2 writs, 1 ready)"
local function StopText(group)
  local writs = #group.writs == 1 and L["1 writ"] or L["%d writs"]:format(#group.writs)
  local ready = group.ready > 0 and (", " .. L["%d ready"]:format(group.ready)) or ""
  return ("%s (%s, %s%s)"):format(group.customer.name, ns.MapName(group.customer.mapID), writs, ready)
end

-- Waypoints along the route (TomTom: every stop; the game's pin: the first) and one chat line. Returns the route.
function ns.SetDeliveryRoute(counts)
  local route, readyOnly = ns.DeliveryRoute(counts)
  if #route == 0 then
    print(PREFIX .. L["no deliveries: none of the writs you hold has a known NPC."])
    return route
  end
  local all = TomTom and TomTom.AddWaypoint
  for index, stop in ipairs(route) do
    if index == 1 or all then
      ns.SetCustomerWaypoint(stop.group.customer, true)
    end
  end
  local first = route[1]
  local text = L["next delivery: %s"]:format(StopText(first.group))
  if first.yards then
    text = text .. ", " .. L["%s yards"]:format(ns.Number(math.floor(first.yards + 0.5)))
  end
  if #route > 1 then
    local rest = {}
    for index = 2, #route do
      rest[#rest + 1] = route[index].group.customer.name
    end
    text = text .. ". " .. L["Then: %s."]:format(table.concat(rest, ", "))
  end
  if not readyOnly then
    text = text .. " " .. L["(No writ is ready yet: the route takes every NPC.)"]
  end
  print(PREFIX .. text)
  return route
end

-- Map pins ---------------------------------------------------------------------------------------------------------

local pins = { list = {}, used = 0, points = {} }
ns.mapPins = pins

-- The pins for a map: { { group, u, v (0-1 on that map) }, ... }.
function ns.MapPinPoints(mapID)
  local points = {}
  if not mapID then
    return points
  end
  for _, group in ipairs(ns.Deliveries()) do
    local customer = group.customer
    if customer then
      local u, v
      if customer.mapID == mapID then
        u, v = customer.x / 100, customer.y / 100
      elseif C_Map and C_Map.GetMapRectOnMap then
        local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, customer.mapID, mapID)
        minX, maxX, minY, maxY = Num(minX), Num(maxX), Num(minY), Num(maxY)
        if ok and minX and maxX and minY and maxY and maxX > minX and maxY > minY then
          u = minX + customer.x / 100 * (maxX - minX)
          v = minY + customer.y / 100 * (maxY - minY)
        end
      end
      if u and v and u >= 0 and u <= 1 and v >= 0 and v <= 1 then
        points[#points + 1] = { group = group, u = u, v = v }
      end
    end
  end
  return points
end

-- The tooltip lines of a pin: { text, r, g, b }.
function ns.MapPinLines(group)
  local customer = group.customer
  local lines = { { customer.name, 1, 0.82, 0 },
    { ("%s %.1f, %.1f"):format(ns.MapName(customer.mapID), customer.x, customer.y), 0.6, 0.6, 0.6 } }
  for _, entry in ipairs(group.writs) do
    local writ = ns.WRITS[entry.writID]
    local name = writ and writ[3] or L["item %d"]:format(entry.writID)
    local state
    if entry.ready then
      state = "|cff40ff40" .. L["ready"] .. "|r"
    elseif entry.questID then
      state = "|cffffd100" .. L["needs the item"] .. "|r"
    else
      state = "|cff999999" .. L["not opened, needs the item"] .. "|r"
    end
    lines[#lines + 1] = { ("%s: %s"):format(name, state), 1, 1, 1 }
  end
  lines[#lines + 1] = { L["Click for a waypoint."], 0.6, 0.6, 0.6 }
  return lines
end

local function Map()
  local map = _G.WorldMapFrame
  return type(map) == "table" and map or nil
end

local function Canvas(map)
  local ok, canvas = pcall(map.GetCanvas, map)
  return ok and type(canvas) == "table" and canvas or nil
end

local function CanvasScale(map)
  local ok, scale = pcall(map.GetCanvasScale, map)
  scale = ok and Num(scale)
  return scale and scale > 0 and scale or 1
end

local function PinEnter(pin)
  local group = pin.group
  if not group then
    return
  end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  for index, line in ipairs(ns.MapPinLines(group)) do
    if index == 1 then
      GameTooltip:SetText(line[1], line[2], line[3], line[4])
    else
      GameTooltip:AddLine(line[1], line[2], line[3], line[4], true)
    end
  end
  GameTooltip:Show()
end

local function NewPin(overlay)
  local holder = CreateFrame("Frame", nil, overlay)
  holder:SetSize(1, 1)
  local pin = CreateFrame("Button", nil, holder)
  pin:SetSize(PIN_SIZE, PIN_SIZE)
  pin:SetPoint("CENTER", holder, "CENTER")
  local back = pin:CreateTexture(nil, "BACKGROUND")
  back:SetAllPoints()
  back:SetColorTexture(0, 0, 0, 0.85)
  pin.icon = pin:CreateTexture(nil, "ARTWORK")
  pin.icon:SetPoint("TOPLEFT", 2, -2)
  pin.icon:SetPoint("BOTTOMRIGHT", -2, 2)
  pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  pin.ring = {}
  for index = 1, 4 do
    pin.ring[index] = pin:CreateTexture(nil, "OVERLAY")
  end
  local top, bottom, left, right = pin.ring[1], pin.ring[2], pin.ring[3], pin.ring[4]
  top:SetPoint("TOPLEFT")
  top:SetPoint("TOPRIGHT")
  top:SetHeight(2)
  bottom:SetPoint("BOTTOMLEFT")
  bottom:SetPoint("BOTTOMRIGHT")
  bottom:SetHeight(2)
  left:SetPoint("TOPLEFT")
  left:SetPoint("BOTTOMLEFT")
  left:SetWidth(2)
  right:SetPoint("TOPRIGHT")
  right:SetPoint("BOTTOMRIGHT")
  right:SetWidth(2)
  local hover = pin:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  hover:SetColorTexture(1, 1, 1, 0.2)
  pin:SetScript("OnEnter", PinEnter)
  pin:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  pin:SetScript("OnClick", function(self)
    if self.group and self.group.customer then
      ns.SetCustomerWaypoint(self.group.customer)
    end
  end)
  local entry = { holder = holder, pin = pin }
  pins.list[#pins.list + 1] = entry
  return entry
end

local function ItemIcon(itemID)
  if C_Item and C_Item.GetItemIconByID then
    local icon = C_Item.GetItemIconByID(itemID)
    if icon then
      return icon
    end
  end
  return GetItemIcon and GetItemIcon(itemID) or 134939 -- (a scroll)
end

local function Paint(entry, group)
  local pin = entry.pin
  pin.group = group
  pin.icon:SetTexture(ItemIcon(group.writs[1].writID))
  local color = group.ready > 0 and { 0.25, 1, 0.25 } or ns.T.GOLD
  for _, line in ipairs(pin.ring) do
    line:SetColorTexture(color[1], color[2], color[3], 1)
  end
end

function ns.HideMapPins()
  for _, entry in ipairs(pins.list) do
    entry.holder:Hide()
    entry.pin.group = nil
  end
  pins.used = 0
  pins.points = {}
end

function ns.PlaceMapPins()
  local map = Map()
  local canvas = map and Canvas(map)
  if not (canvas and pins.overlay) then
    return
  end
  local scale = CanvasScale(map)
  local width, height = Num(canvas:GetWidth()) or 0, Num(canvas:GetHeight()) or 0
  for index = 1, pins.used do
    local entry, point = pins.list[index], pins.points[index]
    entry.pin:SetScale(1 / scale)
    entry.holder:ClearAllPoints()
    entry.holder:SetPoint("CENTER", pins.overlay, "TOPLEFT", point.u * width, -point.v * height)
  end
end

local function PinLevel(map, canvas)
  local ok, manager = pcall(map.GetPinFrameLevelsManager, map)
  if ok and type(manager) == "table" and manager.GetValidFrameLevel then
    local okLevel, level = pcall(manager.GetValidFrameLevel, manager, "PIN_FRAME_LEVEL_AREA_POI")
    if okLevel and Num(level) then
      return level
    end
  end
  return (Num(canvas:GetFrameLevel()) or 0) + 2100
end

-- Draws the pins for the map shown (none while the option is off or the map is hidden).
function ns.DrawMapPins()
  ns.HideMapPins()
  local map = Map()
  if not (map and pins.provider and DB().mapPins and map:IsShown()) then
    return
  end
  local ok, mapID = pcall(map.GetMapID, map)
  local points = ns.MapPinPoints(ok and Num(mapID) or nil)
  if #points == 0 then
    return
  end
  local canvas = Canvas(map)
  if not canvas then
    return
  end
  if not pins.overlay then
    pins.overlay = CreateFrame("Frame", nil, canvas)
    pins.overlay:SetAllPoints(canvas)
  end
  pins.overlay:SetFrameLevel(PinLevel(map, canvas))
  local level = pins.overlay:GetFrameLevel()
  for index, point in ipairs(points) do
    local entry = pins.list[index] or NewPin(pins.overlay)
    Paint(entry, point.group)
    entry.holder:SetFrameLevel(level + 1)
    entry.pin:SetFrameLevel(level + 1)
    entry.holder:Show()
    pins.used = index
  end
  pins.points = points
  ns.PlaceMapPins()
end

local function Safe(fn)
  return function()
    local ok, err = pcall(fn)
    if not ok and not pins.failed then
      pins.failed = true -- one report, not one per refresh
      geterrorhandler()(err)
    end
  end
end

-- Redraws the pins while the world map is open (after bag and quest changes).
function ns.RefreshMapPins()
  local map = Map()
  if pins.provider and map and map:IsShown() then
    Safe(ns.DrawMapPins)()
  end
end

local function NewProvider()
  local provider
  if type(CreateFromMixins) == "function" and type(MapCanvasDataProviderMixin) == "table" then
    provider = CreateFromMixins(MapCanvasDataProviderMixin)
  else
    provider = {}
    function provider:OnAdded(map) self.owningMap = map end
    function provider:OnRemoved() self.owningMap = nil end
    function provider:GetMap() return self.owningMap end
  end
  provider.RefreshAllData = Safe(ns.DrawMapPins)
  provider.OnMapChanged = Safe(ns.DrawMapPins)
  provider.RemoveAllData = Safe(ns.HideMapPins)
  provider.OnCanvasScaleChanged = Safe(ns.PlaceMapPins)
  provider.OnCanvasSizeChanged = Safe(ns.PlaceMapPins)
  provider.OnHide = Safe(ns.HideMapPins)
  return provider
end

-- Puts the provider on the world map (now, or when Blizzard_WorldMap loads).
function ns.HookMapPins()
  if pins.provider then
    return true
  end
  local map = Map()
  if not (map and type(map.AddDataProvider) == "function") then
    if not pins.waiter and CreateFrame then
      pins.waiter = CreateFrame("Frame")
      pins.waiter:RegisterEvent("ADDON_LOADED")
      pins.waiter:SetScript("OnEvent", function(self, _, name)
        if name == "Blizzard_WorldMap" and ns.HookMapPins() then
          self:UnregisterEvent("ADDON_LOADED")
        end
      end)
    end
    return false
  end
  local provider = NewProvider()
  if not pcall(map.AddDataProvider, map, provider) then
    return false
  end
  pins.provider = provider
  if map:IsShown() then
    Safe(ns.DrawMapPins)()
  end
  return true
end
