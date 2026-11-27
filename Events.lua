local addonName, ns = ...
local L = ns.L

local PREFIX

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Events registered after setup; pcall because not every client has every event.
local EVENTS = {
  "QUEST_COMPLETE", "QUEST_TURNED_IN", "CURRENCY_DISPLAY_UPDATE", "CHAT_MSG_COMBAT_FACTION_CHANGE",
  "BAG_UPDATE_DELAYED", "UPDATE_FACTION", "QUEST_LOG_UPDATE", "SKILL_LINES_CHANGED", "SPELLS_CHANGED",
  "TRAIT_CONFIG_UPDATED",
}

local function Setup()
  CommerceAuthorityDB = CommerceAuthorityDB or {}
  ns.ApplyDefaults(CommerceAuthorityDB, ns.defaults)
  PREFIX = ns.T.Prefix("Commerce Authority")
  ns.CreateOptions()
  ns.HookItemTooltips()
  ns.HookVendor()
  ns.T.AddCompartment({
    text = ns.TITLE,
    onClick = ns.ToggleWindow,
    tooltip = { L["Writs, crates, reputation and Merchant's Favor."], L["Click to open the window."] },
  })
  for _, event in ipairs(EVENTS) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
  end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    if ... == addonName then
      Setup()
      self:UnregisterEvent("ADDON_LOADED")
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- the currency can still read 0 right at login: take the starting balance a little later
    if C_Timer and C_Timer.After then
      C_Timer.After(5, ns.StartFavorTracking)
    end
  elseif event == "QUEST_COMPLETE" then
    ns.OnQuestComplete()
  elseif event == "QUEST_TURNED_IN" then
    ns.OnQuestTurnedIn((...))
  elseif event == "CURRENCY_DISPLAY_UPDATE" then
    local currencyID = ...
    if currencyID == nil or currencyID == ns.FAVOR_CURRENCY then
      ns.OnFavorChanged()
    end
  elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
    ns.OnRepMessage((...))
  else
    if event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
      ns.InvalidateCheapest()
    end
    ns.RequestRefresh()
  end
end)

local function Debug()
  local favor, favorName = ns.Favor()
  print(PREFIX .. "debug")
  print(("  Merchant's Favor: %s"):format(favor and (ns.Number(favor) .. " (" .. favorName .. ")") or "not found"))
  local faction = ns.Faction()
  if faction then
    print(("  Faction: %s (ID %s), %s, %s / %s"):format(faction.name, tostring(faction.id),
      ns.StandingName(faction.standingID), ns.Number((faction.value or 0) - (faction.min or 0)),
      ns.Number((faction.max or 0) - (faction.min or 0))))
  else
    print("  Faction: not in your reputation list yet")
  end
  local names = ns.PriceSourceNames()
  print("  Price addons: " .. (#names > 0 and table.concat(names, ", ") or "none"))
  local professions = {}
  for name, skill in pairs(ns.PlayerProfessions()) do
    professions[#professions + 1] = name .. " " .. skill
  end
  table.sort(professions)
  print("  Professions: " .. (#professions > 0 and table.concat(professions, ", ") or "none found"))
  print(("  Writ quests: %d"):format(#ns.ActiveWrits()))
  local builtIn, learned = 0, 0
  for writID = ns.FOREVER_WRIT_FIRST, ns.FOREVER_WRIT_LAST do
    local customer = ns.WritCustomer(writID)
    if customer and customer.learned then
      learned = learned + 1
    elseif customer then
      builtIn = builtIn + 1
    end
  end
  print(("  Writ customers known: %d built in, %d seen at your turn-ins"):format(builtIn, learned))
  local summary = ns.BagSummary()
  print(("  Bags: %d writs (%d rep), %d sealed writs, %d filled crates (%d Favor), %d crates to fill"):format(
    summary.writs, summary.writRep, summary.sealedWrits, summary.crates, summary.crateFavor, summary.toFill))
  local crates, writs = 0, 0
  for _ in pairs(CommerceAuthorityDB.learned.crates) do
    crates = crates + 1
  end
  for _ in pairs(CommerceAuthorityDB.learned.writs) do
    writs = writs + 1
  end
  print(("  Legacy talents: Performance Bonus %s, Diplomat %s"):format(
    ns.HasPerformanceBonus() and "yes" or "no", ns.HasDiplomat() and "yes" or "no"))
  print(("  Learned: %d crate kinds, %d writs, %d Performance Bonuses seen"):format(crates, writs,
    CommerceAuthorityDB.learned.bonuses or 0))
end

SLASH_COMMERCEAUTHORITY1 = "/aca"
SLASH_COMMERCEAUTHORITY2 = "/commerce"
SlashCmdList.COMMERCEAUTHORITY = function(msg)
  local command = (msg or ""):lower():match("^%s*(%S*)")
  if command == "" or command == "show" then
    ns.ToggleWindow()
  elseif command == "options" or command == "config" then
    ns.OpenOptions()
  elseif command == "buy" then
    ns.CreateBuyList()
  elseif command == "npcs" or command == "npc" then
    ns.ToggleNPCWindow()
  elseif command == "feedback" then
    ns.T.ShowFeedback()
  elseif command == "debug" then
    Debug()
  else
    print(PREFIX .. L["commands"])
    print("  /aca: " .. L["show or hide the window"])
    print("  /aca options: " .. L["open the options"])
    print("  /aca npcs: " .. L["every NPC who takes writs, with all its writs and which you have"])
    print("  /aca buy: " .. L["Auctionator shopping list of the cheapest writs to your next standing"])
    print("  /aca debug: " .. L["what the addon sees (faction, Favor, price addons, bags)"])
    print("  /aca feedback: " .. L["report a bug or suggest an idea"])
  end
end
