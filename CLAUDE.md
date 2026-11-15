# CommerceAuthority ("Tylesser - Commerce Authority")

Shared conventions, release steps and the game client are in the workspace file `../../CLAUDE.md`. This file covers
this addon only. WoW Forever's crafting factions: Azeroth Commerce Authority (Alliance, Three Corners in Redridge) and
Durotar Supply and Logistics (Horde, west of the Crossroads), currency Merchant's Favor (3402). The user chose the name
"Tylesser - Commerce Authority" (2026-11-16) and wanted the writ pricing here instead of in ProfitSort.

## Files (load order from CommerceAuthority.toc)

- `Tylesser.lua`: the shared look (`ns.T`), identical in every Tylesser addon.
- `Data.lua`: `ns.WRITS[writItemID] = { itemID or false, count, englishName }`:
  - Classic Argent Dawn writs 22600-22624 (24): item and count from each quest's "Deliver N ..." text on classicdb
    (quests 9178-9206). Priced only, no Commerce Authority reputation.
  - WoW Forever writs 264011-264160 (150, "Craftsman's Writ: <item>", quest ID = item ID - 169800). Names from the
    SpokenQuestsAudio addon's generated item lookups; item IDs from NeedRoll's profession data and classicdb (vanilla
    IDs: the one cached quest objective, Orange Martial Shirt, asked for item 10052 x1). `false` = not found offline
    (Catseye Draught, Gyromatic Micro-Adjuster, Potion of Demonslaying, Draught of Detect Demon, Gnomish
    Alarm-O-Bot), resolved in game with `GetItemInfo(name)`. Items 264201-264231 are in Auctionator data too, names
    unknown.
  - `ns.WRIT_TIERS`: the Forever IDs come in three blocks (Journeyman to 264055: 75 rep, Expert to 264115: 125,
    Artisan to 264160: 200), confirmed by the Mobalytics guide's examples. Inside each block the professions run
    Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring (`ns.WRIT_PROFESSIONS`, from NeedRoll's recipe
    data). `ns.SEALED_WRITS` by name.
  - `ns.CRATE_CONTENTS[category][level]` = { { itemID, count, name } }: one stack of one of these fills a crate
    (wow.gg guide). Guides disagree on category names: `ns.CrateCategory` maps Curiosities/Oddities,
    Fabrics/Cloth, Ingots/Bars; Expert/Artisan herbs are Roots and Flowers (plain "Herbs" = both lists).
  - `ns.CRATE_LEVELS`: Favor per Waylaid Crate level (Apprentice 5, Journeyman 10, Expert 15 from the guide; Artisan
    20 is a guess), doubled for made goods (`ns.CRATE_MADE_GOODS` by category; filled "Sealed X Crate": green
    quality). Silver =
    50 copper per Favor. Legacy talents: Performance Bonus 15% chance of double Favor, Diplomat +10% reputation.
  - Sources: mobalytics.gg "Merchant's Favor, Waylaid Crates & Craftsman's Writ Guide" (read via Chrome; it blocks
    curl/WebFetch), wow.gg merchants-favor, warcraft.wiki.gg Merchant's_Favor, method.gg (NPCs). Wowhead is blocked in
    the user's region.
- `Prices.lua`: `ns.Prices(itemID)` from Auctionator (`Auctionator.API.v1`), TSM (`TSM_API.GetCustomPriceValue`
  DBMarket, then DBMinBuyout) and Auctioneer (`AucAdvanced.API.GetMarketValue`), each in pcall. Local function names
  must not shadow those globals (a `local function Auctionator` once hid the API). `ns.CraftCost` reads
  `ProfitSortCharDB.products` (Profit Sort's per-character cache) when present.
- `Core.lua`: defaults (`CommerceAuthorityDB`, account-wide), Merchant's Favor (`C_CurrencyInfo`; not on Retail,
  where 3402 may be another currency), the faction of the player's side (looked up by name in the reputation list
  first; the ID saved per side in `factionIDs` only for collapsed headers, because the ID APIs also answer for
  factions you aren't on), professions (`GetProfessions` or the skill list), writ reputation/cost, crate info and
  fill options, bag counts, `ns.CheapestWrits` (cached 10 s; `ns.InvalidateCheapest`). Learned amounts are read
  with `ns.UsualValue` (most common value seen).
- `Learn.lua`: learns real amounts; each turn-in is its own record with its own bag snapshot (QUEST_COMPLETE) and
  timer. Favor arriving while the dialog is open or up to 3 s after QUEST_TURNED_IN is that turn-in's; it is
  resolved 3 s later or when the next dialog opens (whose bags are its "after"), and only when exactly one crate
  kind left the bags. Learned per `level .. " raw"/" made"` (the key tooltips use). Double the usual amount counts
  as a Performance Bonus only with that option on. Writs: the faction chat message within 3 s of a writ quest's
  turn-in, either order (held as pending otherwise). The starting Favor is taken 5 s after PLAYER_ENTERING_WORLD
  (or by the first currency event), never counted as a gain. Stored in `CommerceAuthorityDB.learned`.
- `Tooltip.lua`: writ, sealed writ and crate lines; TooltipDataProcessor or OnTooltipSetItem; skips compare tooltips.
- `Quests.lua`: writ quests in the log (`C_QuestLog.GetInfo` or `GetQuestLogTitle`) and `ns.SetWritWaypoint`
  (`C_QuestLog.GetNextWaypoint`, else the quest's pin from `GetQuestsOnMap`; TomTom or `C_Map.SetUserWaypoint` +
  super-track; without a spot it tracks the quest and opens the map).
- `Vendor.lua`: marks on merchant rows for items costing Merchant's Favor (`GetMerchantItemCostItem`, currency link)
  and a tooltip line. The merchant index comes from `MerchantItemNItemButton:GetID()`, which Vendor Search also sets
  when it filters; updated again next frame after other addons lay the page out.
- `Shopping.lua`: `/aca buy`, the Auctionator shopping list "Commerce Authority" (`ConvertToSearchString` with
  `isExact` and `quantity`, `CreateShoppingList`): cheapest writs up to the next standing (max 20) and the items to
  buy for them.
- `Window.lua`: the `/aca` window (`CommerceAuthorityWindow`, in UISpecialFrames so Esc closes it); refreshes go
  through `ns.RequestRefresh` (at most twice a second, only while shown).
- `Options.lua`: options page. `Events.lua`: events and `/aca` `/commerce` (`options`, `debug`, `feedback`).

Tests: `tools/harness/ca_test.lua` (`node run.js ca_test.lua E:/Games/Wow/Addons/CommerceAuthority`).

## Unverified in game (ask the user)

- Crate item names ("Waylaid Crate: Journeyman Ore" to fill, "Sealed Journeyman Crate" filled) and whether the turn-in
  quest is "A Sealed Crate" (quests 91899-91906, giver Marcy Baker / Dokimi).
- Whether the bag count has dropped 3 s after QUEST_TURNED_IN, and the CURRENCY_DISPLAY_UPDATE arguments.
- Whether `C_QuestLog.GetNextWaypoint` or `GetQuestsOnMap` know the writ delivery spots on Forever.
- Where the vendor mark sits on the merchant row, next to Vendor Search's own marks.
- The faction chat message format on Forever, and whether writs ask for more than 1 item.
