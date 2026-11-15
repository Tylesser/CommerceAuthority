local _, ns = ...

-- Options page: Esc > Options > AddOns > Tylesser - Commerce Authority
ns.TITLE = "Tylesser - Commerce Authority"

local function CreateCheck(parent, anchor, label, description, key, onChange)
  local check = ns.T.Check(parent, label)
  if anchor then
    check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -26, -12)
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
    "Craftsman's Writs, Waylaid Crates, reputation and Merchant's Favor for the Azeroth Commerce Authority "
      .. "and Durotar Supply and Logistics. Type /aca for the window.")

  local _, help = CreateCheck(panel, nil, "Writ tooltips",
    "Craftsman's Writs show the reputation they give, what they ask for, its auction price and the cost per "
      .. "100 reputation.", "writTooltips")
  _, help = CreateCheck(panel, help, "Crate tooltips",
    "Waylaid Crates show the Merchant's Favor and silver they give, and the cheapest way to fill them.",
    "crateTooltips")
  _, help = CreateCheck(panel, help, "Marks at the Commerce Authority vendors",
    "Items that cost Merchant's Favor show \"Can buy\" or how much more you need, and their tooltip how many "
      .. "crates that is.", "vendorMarks", function()
      if ns.UpdateVendorMarks then
        ns.UpdateVendorMarks()
      end
    end)
  _, help = CreateCheck(panel, help, "Prices from every auction addon",
    "When more than one price addon is installed (Auctionator, TradeSkillMaster, Auctioneer), show all their "
      .. "prices instead of only the first.", "allSources")
  _, help = CreateCheck(panel, help, "I have the Performance Bonus legacy talent",
    "15% chance of double Merchant's Favor from a crate: estimates count it in.", "performanceBonus")
  _, help = CreateCheck(panel, help, "I have the Diplomat legacy talent",
    "10% more reputation: writ estimates count it in until a turn-in shows the real amount.", "diplomat",
    ns.InvalidateCheapest)

  local sources = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sources:SetPoint("TOPLEFT", help, "BOTTOMLEFT", -26, -18)
  sources:SetWidth(540)
  sources:SetJustifyH("LEFT")
  panel:HookScript("OnShow", function()
    local names = ns.PriceSourceNames()
    sources:SetText("Price addons found: " .. (#names > 0 and table.concat(names, ", ")
      or "none. Install Auctionator, TradeSkillMaster or Auctioneer for auction prices."))
  end)

  local open = ns.T.Button(panel, 140, 24, "Open the window", true)
  open:SetPoint("TOPLEFT", sources, "BOTTOMLEFT", 0, -16)
  open:SetScript("OnClick", ns.ToggleWindow)

  local forget = ns.T.Button(panel, 160, 24, "Forget what was learned")
  forget:SetPoint("LEFT", open, "RIGHT", 12, 0)
  forget:SetScript("OnClick", function()
    CommerceAuthorityDB.learned = { crates = {}, writs = {} }
    ns.InvalidateCheapest()
    print(ns.T.Prefix("Commerce Authority") .. "learned turn-in amounts cleared; the guides' numbers are used again.")
    ns.RefreshWindow()
  end)
  forget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Forget what was learned")
    GameTooltip:AddLine("The addon remembers the Merchant's Favor and reputation each crate and writ gave you. "
      .. "Clear them to go back to the guides' numbers.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  forget:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, ns.TITLE)
    Settings.RegisterAddOnCategory(category)
    ns.optionsCategory = category
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
  ns.optionsPanel = panel
end

function ns.OpenOptions()
  if ns.optionsCategory and Settings and Settings.OpenToCategory then
    local id = ns.optionsCategory.GetID and ns.optionsCategory:GetID() or ns.optionsCategory.ID
    Settings.OpenToCategory(id)
  elseif ns.optionsPanel and InterfaceOptionsFrame_OpenToCategory then
    -- called twice: the first call only opens the frame on some clients
    InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
  end
end
