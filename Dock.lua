local addonName, ns = ...
local L = ns.L

-- Beside the auction house (2026-11-28, the user's request: Commerce Authority as a side panel of the auction
-- house). The window itself is the panel: when the auction house opens it opens docked to the auction house's
-- right edge (option `auctionDock`) and closes with it; a "Commerce Authority" button on that edge opens it when
-- it is closed. Dragging it, or closing it, gives it back its own place. No tab: tabs on Blizzard's auction house
-- frame are its own (PanelTemplates) and Auctionator adds its own there.
--
-- Everything is parented to UIParent and only anchored to the auction house, so nothing of ours becomes a child
-- of Blizzard's frame. When Codex's auction panel sits on that edge (CodexAuctionPanel), we dock to its right.

local dock = { docked = false, byAH = false }
local button

local function Host()
  if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
    return AuctionHouseFrame
  end
  if AuctionFrame and AuctionFrame:IsShown() then
    return AuctionFrame
  end
  return nil
end

-- What sits on the auction house's right edge: Codex's auction panel when it is shown there, else the AH itself.
local function Edge(host)
  local codex = CodexAuctionPanel
  if codex and codex:IsShown() and codex:GetParent() == host then
    return codex
  end
  return host
end

local function UpdateButton()
  if not button then
    return
  end
  local window = ns.Window()
  local host = Host()
  if host and not (window and window:IsShown()) then
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", Edge(host), "TOPRIGHT", 4, -6)
    button:Show()
  else
    button:Hide()
  end
end

local function WatchWindow(window)
  if window.dockWatched then
    return
  end
  window.dockWatched = true
  window:HookScript("OnShow", UpdateButton)
  window:HookScript("OnHide", function()
    if dock.docked then
      dock.docked, dock.byAH = false, false
      ns.RestoreWindowPosition()
    end
    UpdateButton()
  end)
  -- moved by the player: their place now, and it stays open when the auction house closes
  window:HookScript("OnDragStop", function()
    dock.docked, dock.byAH = false, false
  end)
end

-- Opens the window docked beside the open auction house. Returns true when it did.
function ns.DockWindow()
  local host = Host()
  if not host then
    return false
  end
  local window = ns.EnsureWindow()
  WatchWindow(window)
  window:ClearAllPoints()
  window:SetPoint("TOPLEFT", Edge(host), "TOPRIGHT", 4, 0)
  dock.docked, dock.byAH = true, true
  window:Show()
  UpdateButton()
  return true
end

function ns.WindowDocked()
  return dock.docked
end

local function CreateButton()
  if button or not ns.T then
    return
  end
  button = ns.T.Button(UIParent, 176, 24, "Commerce Authority", true)
  button:SetFrameStrata("HIGH")
  button:Hide()
  local emblem = button:CreateTexture(nil, "ARTWORK")
  emblem:SetTexture(ns.T.EMBLEM)
  emblem:SetSize(14, 14)
  emblem:SetPoint("LEFT", 5, 0)
  button.label:SetPoint("LEFT", emblem, "RIGHT", 2, 0)
  button:SetScript("OnClick", function()
    ns.DockWindow()
  end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Commerce Authority")
    GameTooltip:AddLine(L["Opens the window beside the auction house: the crates you have to fill, your writs and the cheapest writs. Click one to search for it here."],
      0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", GameTooltip_Hide)
end

-- The auction house's frame can appear a moment after the event (its addon loads on demand): one frame later.
local function Show()
  if not Host() then
    return
  end
  CreateButton()
  local window = ns.Window()
  if CommerceAuthorityDB and CommerceAuthorityDB.auctionDock and not (window and window:IsShown()) then
    ns.DockWindow()
  end
  UpdateButton()
end

function ns.OnAuctionHouseShow()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, Show)
  else
    Show()
  end
end

function ns.OnAuctionHouseClosed()
  local window = ns.Window()
  if window and dock.docked and dock.byAH then
    window:Hide() -- (OnHide gives it back its own place)
  end
  if button then
    button:Hide()
  end
end
