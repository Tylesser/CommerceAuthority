local _, ns = ...
local L = ns.L

-- Options page: Esc > Options > AddOns > Tylesser - Commerce Authority
ns.TITLE = "Tylesser - Commerce Authority"

local function CreateCheck(parent, anchor, label, description, key, onChange)
  local check = ns.T.Check(parent, label)
  if anchor then
    -- a line between two options (the user's request, 2026-11-28: the page's sections ran together)
    local divider = ns.T.Divider(parent, 540, 13)
    divider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -26, -6)
    check:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -6)
  else
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, ns.T.OPTIONS_TOP)
  end
  local help = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  help:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 26, 0)
  help:SetWidth(520)
  help:SetJustifyH("LEFT")
  help:SetText(description)
  check:SetScript("OnShow", function(self)
    self:SetChecked(CommerceAuthorityDB[key])
  end)
  check:SetScript("OnClick", function(self)
    CommerceAuthorityDB[key] = self:GetChecked() and true or false
    if onChange then
      onChange()
    end
    ns.RefreshWindow()
  end)
  return check, help
end

function ns.CreateOptions()
  local panel = CreateFrame("Frame")
  panel.name = ns.TITLE
  ns.T.OptionsPage(panel, "Commerce Authority",
    L["Craftsman's Writs, Waylaid Crates, reputation and Merchant's Favor for the %s and %s. Type %s for the window."]:format(
      ns.FactionNameOf("Alliance"), ns.FactionNameOf("Horde"), "/aca"))

  local _, help = CreateCheck(panel, nil, L["Writ tooltips"],
    L["Craftsman's Writs show the reputation they give, what they ask for, its auction price and the cost per 100 reputation."],
    "writTooltips")
  _, help = CreateCheck(panel, help, L["Crate tooltips"],
    L["Waylaid Crates show the Merchant's Favor and silver they give, and the cheapest way to fill them."],
    "crateTooltips")
  _, help = CreateCheck(panel, help, L["Marks at the Commerce Authority vendors"],
    L["Items that cost Merchant's Favor show \"%s\" or how much more you need, and their tooltip how many crates that is."]
      :format(L["Can buy"]), "vendorMarks", function()
      if ns.UpdateVendorMarks then
        ns.UpdateVendorMarks()
      end
    end)
  _, help = CreateCheck(panel, help, L["Prices from every auction addon"],
    L["When more than one price addon is installed (Auctionator, TradeSkillMaster, Auctioneer), show all their prices instead of only the first."],
    "allSources")
  _, help = CreateCheck(panel, help, L["Open beside the auction house"],
    L["When the auction house opens, the window opens beside it and closes with it. The Commerce Authority button on the auction house's edge opens it too."],
    "auctionDock")

  local sources = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  local sourcesLine = ns.T.Divider(panel, 540, 13)
  sourcesLine:SetPoint("TOPLEFT", help, "BOTTOMLEFT", -26, -8)
  sources:SetPoint("TOPLEFT", sourcesLine, "BOTTOMLEFT", 0, -8)
  sources:SetWidth(540)
  sources:SetJustifyH("LEFT")
  panel:HookScript("OnShow", function()
    local names = ns.PriceSourceNames()
    local talents = {}
    for _, talent in ipairs({ { ns.TalentName(ns.PERFORMANCE_BONUS_SPELL, "Performance Bonus"), ns.HasPerformanceBonus() },
      { ns.TalentName(ns.DIPLOMAT_SPELL, "Diplomat"), ns.HasDiplomat() } }) do
      talents[#talents + 1] = talent[1] .. " " .. (talent[2] and L["(yours: counted in)"] or L["(not taken)"])
    end
    sources:SetText(L["Price addons found: %s"]:format(#names > 0 and table.concat(names, ", ")
      or L["none. Install Auctionator, TradeSkillMaster or Auctioneer for auction prices."])
      .. "\n" .. L["Legacy talents: %s."]:format(table.concat(talents, ", ")))
  end)

  local open = ns.T.Button(panel, 140, 24, L["Open the window"], true)
  open:SetPoint("TOPLEFT", sources, "BOTTOMLEFT", 0, -16)
  open:SetScript("OnClick", ns.ToggleWindow)

  local forget = ns.T.Button(panel, 160, 24, L["Forget what was learned"])
  forget:SetPoint("LEFT", open, "RIGHT", 12, 0)
  forget:SetScript("OnClick", function()
    -- who takes each writ is a fact seen in the game, not an estimate: kept
    local customers = CommerceAuthorityDB.learned.customers or {}
    CommerceAuthorityDB.learned = { crates = {}, writs = {}, customers = customers }
    ns.InvalidateCheapest()
    print(ns.T.Prefix("Commerce Authority") .. L["learned turn-in amounts cleared; the guides' numbers are used again."])
    ns.RefreshWindow()
  end)
  forget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Forget what was learned"])
    GameTooltip:AddLine(L["The addon remembers the Merchant's Favor and reputation each crate and writ gave you. Clear them to go back to the guides' numbers. Who takes each writ is kept."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  forget:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- shown in Tylesser's own settings window (Tylesser.lua T.RegisterOptions, 2026-11-28)
  ns.optionsCategory = ns.T.RegisterOptions(panel, ns.TITLE)
  ns.optionsPanel = panel
end

function ns.OpenOptions()
  ns.T.OpenOptions(ns.optionsCategory)
end
