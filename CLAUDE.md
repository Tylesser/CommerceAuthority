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
  - Writ quest = item ID - 169800, except `ns.WRIT_QUEST_EXCEPTIONS` (Elixir of Ogre's Strength 264011 -> quest
    94004; there is no quest 94211). Always go through `ns.WritQuestID` / `ns.WritForQuest`.
  - `ns.WRIT_CUSTOMERS[writItemID] = { npcName, uiMapID, x, y }`: who takes each writ. Every writ has its own
    "customer" NPC somewhere in the world (not the trade hub; the hub's profession NPCs are vendors). 133 of 150
    known (2026-11-24, QuestieDB 1.1.5 + two by hand); the other 17 (Artisan) are learned at the first turn-in. Rows marked "(added by hand)" must be
    kept when a rebuilt table is pasted. How the table is built and where the data comes from:
    `E:/Games/Wow/tools/data/README.md` (workspace, not in this repo: the repo keeps only addon data and names no
    data source, the user's choice 2026-11-20).
  - `ns.WRIT_TIERS`: the Forever IDs come in three blocks (Journeyman to 264055: 75 rep, Expert to 264115: 125,
    Artisan to 264160: 200), confirmed by the Mobalytics guide's examples. Inside each block the professions run
    Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring (`ns.WRIT_PROFESSIONS`, from NeedRoll's recipe
    data). `ns.SEALED_WRITS` by name.
  - `ns.CRATE_CONTENTS[category][level]` = { { itemID, count, name } }: one stack of one of these fills a crate
    (wow.gg guide). Guides disagree on category names: `ns.CrateCategory` maps Curiosities/Oddities,
    Fabrics/Cloth, Ingots/Bars; Expert/Artisan herbs are Roots and Flowers (plain "Herbs" = both lists).
  - `ns.CRATE_ITEMS` / `ns.SEALED_CRATE_ITEMS` (2026-11-27): the 30 Waylaid Crates (248682-248713) and 15 Sealed
    crates (248765-248779, Apprentice to Elite in three qualities) by item ID from Forever's item table; `ns.CrateInfo`
    tries the ID first, then the name. Expert/Artisan herb crates are named "Waylaid Crate: Earthly Artisan Herbs"
    (kind before the level: the old `^Waylaid Crate: (%a+)` match took "Earthly" as the level). Their contents and
    counts were checked against each crate's use spell (all matched).
  - Tylesser - Data (2026-11-27): `ns.Collected()` (Core.lua) loads it on demand (never in a fight; also picks it up
    when loaded later). `ns.WritCustomer`: learned > WRIT_CUSTOMERS > players' data (`collected = true`, shown as
    "(players' data)"). `ns.CrateFavor`: learned > players' data (quests requiring a Sealed crate, currency 3402) >
    guide. `ns.UNREAD_CRATES`: the plain Waylaid Crate (read its label) and Waylaid Herbs (its bill from `Text`).
  - `ns.CRATE_LEVELS`: Favor per Waylaid Crate level (Apprentice 5, Journeyman 10, Expert 15 from the guide; Artisan
    20 is a guess), doubled for made goods (`ns.CRATE_MADE_GOODS` by category; filled "Sealed X Crate": green
    quality). Silver =
    50 copper per Favor. Legacy talents: Performance Bonus 15% chance of double Favor, Diplomat +10% reputation.
- `Prices.lua`: `ns.Prices(itemID)` from Auctionator (`Auctionator.API.v1`), TSM (`TSM_API.GetCustomPriceValue`
  DBMarket, then DBMinBuyout) and Auctioneer (`AucAdvanced.API.GetMarketValue`), each in pcall. Local function names
  must not shadow those globals (a `local function Auctionator` once hid the API). `ns.CraftCost` reads
  `ProfitSortCharDB.products` (Profit Sort's per-character cache) when present.
- `Core.lua`: defaults (`CommerceAuthorityDB`, account-wide), Merchant's Favor (`C_CurrencyInfo`; not on Retail,
  where 3402 may be another currency), the faction of the player's side (looked up by name in the reputation list
  first; the ID saved per side in `factionIDs` only for collapsed headers, because the ID APIs also answer for
  factions you aren't on), professions (`GetProfessions` or the skill list), writ reputation/cost, crate info and
  fill options, bag counts, `ns.CheapestWrits` (cached 10 s; `ns.InvalidateCheapest`), `ns.CheapestCustomers`
  (the cheapest list grouped by customer, minus writs in your bags: all priced writs averaged, which the user
  wants kept), `ns.CheapestZones` (those NPCs grouped by map); the window's ranking button `ns.CheapestMode()`
  (`cheapestBy` writ/npc/zone; the old `cheapestByNPC` is still read). Learned amounts are read with `ns.UsualValue` (most
  common value seen).
- `Learn.lua`: learns real amounts; each turn-in is its own record with its own bag snapshot (QUEST_COMPLETE) and
  timer. Favor arriving while the dialog is open or up to 3 s after QUEST_TURNED_IN is that turn-in's; it is
  resolved 3 s later or when the next dialog opens (whose bags are its "after"), and only when exactly one crate
  kind left the bags. Learned per `level .. " raw"/" made"` (the key tooltips use). Double the usual amount counts
  as a Performance Bonus only when you have that talent (`ns.HasPerformanceBonus`; Core.lua `ns.HasLegacyTalent`: the
  talents are WoW Forever trait talents, spells 1225456 / 1225485, found with IsPlayerSpell / IsSpellKnown /
  C_SpellBook.IsSpellKnown or their passive aura; no options since 2026-11-19). Writs: the faction chat message within 3 s of a writ quest's
  turn-in, either order (held as pending otherwise). The starting Favor is taken 5 s after PLAYER_ENTERING_WORLD
  (or by the first currency event), never counted as a gain. At a writ's turn-in it also stores the dialog's NPC
  and your map position as that writ's customer (`learned.customers`, kept by "Forget what was learned").
  Stored in `CommerceAuthorityDB.learned`.
- `Tooltip.lua`: writ, sealed writ and crate lines; TooltipDataProcessor or OnTooltipSetItem; skips compare tooltips.
- `Quests.lua`: customers (`ns.WritCustomer`: learned first, then the built-in list; `ns.CustomerWrits`;
  `ns.HeldWrits` (writs in your bags and quest log); `ns.Deliveries` groups them by customer for the window;
  `ns.CustomerDirectory` lists every customer with all its writs for NPCs.lua), writ quests in the log
  (`C_QuestLog.GetInfo` or `GetQuestLogTitle`) and `ns.SetWritWaypoint`
  (`C_QuestLog.GetNextWaypoint`, else the quest's pin from `GetQuestsOnMap`; TomTom or `C_Map.SetUserWaypoint` +
  super-track; without a spot it tracks the quest and opens the map).
- `Vendor.lua`: marks on merchant rows for items costing Merchant's Favor (`GetMerchantItemCostItem`, currency link)
  and a tooltip line. The merchant index comes from `MerchantItemNItemButton:GetID()`, which Vendor Search also sets
  when it filters; updated again next frame after other addons lay the page out.
- `Shopping.lua`: `/aca buy`, the Auctionator shopping list "Commerce Authority" (`ConvertToSearchString` with
  `isExact` and `quantity`, `CreateShoppingList`): cheapest writs up to the next standing (max 20) and the items to
  buy for them; `ns.CreateCustomerBuyList(group)` / `ns.CreateZoneBuyList(zone)` put one NPC's or zone's writs on
  it instead (By NPC / By zone rows). `ns.SetZoneWaypoints` (Quests.lua): TomTom pins every NPC of a zone, the
  game's single pin only the first. `ns.SearchWrits(writIDs, held)`: clicks while the AH is open
  (`ns.AuctionHouseOpen`) search the writs you don't hold and the items not-ready ones need, with Auctionator's
  `MultiSearchExact` (its Shopping tab), else the game's search box (`AuctionHouseFrame.SearchBar`, or the legacy
  `BrowseName`) with the first name.
- `Window.lua`: the `/aca` window (`CommerceAuthorityWindow`, in UISpecialFrames so Esc closes it); refreshes go
  through `ns.RequestRefresh` (at most twice a second, only while shown).
- `NPCs.lua`: the Writ NPCs window (`/aca npcs`, "All NPCs" button; `CommerceAuthorityNPCWindow`, position in
  `npcPosition`): flat lines (zone header, NPC header, its writs, then "NPC not known yet" and those writs) shown in fixed rows
  scrolled with the mouse wheel; search box (`InputBoxTemplate` + `T.EditBox`). Refreshed by `ns.RequestRefresh`.
  Filter row (2026-11-19, the user's request): level button (`npcTier`: nil / Journeyman / Expert / Artisan), "My
  professions" (`npcMine`), "Not done today" (`npcNotDone`; writs are daily quests: `ns.WritDoneToday` =
  `C_QuestLog.IsQuestFlaggedCompleted(ns.WritQuestID(writID))`, also "done today" on the writ line), "Fold all" /
  "Unfold all"; zones grouped under continents (2026-11-24, the user's request: `ns.ContinentOf(mapID)` in Quests.lua walks
  C_Map.GetMapInfo's parents to the continent, else `ns.ZONE_CONTINENT` / the classic map ID ranges; a "continent"
  line with fold key "c<id>", a click on it always folds); folded zones in `npcFolded` ([uiMapID] = true, unknown =
  true, "c<continent>" = true; plus/minus button on the zone line, or a click on the line while the AH is closed). The filters go to
  `ns.CustomerDirectory(counts, search, { tier, mine, notDone })`.
- Start (2026-11-24, the user's request): `ns.StartWrit(writID)` (Core.lua) uses the writ from the bags
  (`C_Container.UseContainerItem`, as a right-click), refused in combat and while MerchantFrame / BankFrame /
  MailFrame / TradeFrame / GuildBankFrame / AuctionHouseFrame shows (UseContainerItem would sell or move it);
  `ns.StartableWrit(group)` = the first ready writ without a quest. Buttons: `row.start` on Deliveries rows
  (Window.lua) and on writ lines of the Writ NPCs window, shown out of combat only.
- `Options.lua`: options page. `Events.lua`: events and `/aca` `/commerce` (`options`, `debug`, `feedback`).

**Twin in Codex:** `Addons/Codex/Modules/Commerce` is this addon ported into Codex (2026-11-19): the same Data,
Core, Learn, Quests, Tooltip and Vendor code on `ns.commerce`, with Codex's prices, shopping lists and widgets. A fix
here goes there too (and back); see Codex's CLAUDE.md.

Tests: `tools/harness/ca_test.lua` (`node run.js ca_test.lua E:/Games/Wow/Addons/CommerceAuthority`).

## Unverified in game (ask the user)

- Crate item names ("Waylaid Crate: Journeyman Ore" to fill, "Sealed Journeyman Crate" filled) and whether the turn-in
  quest is "A Sealed Crate" (quests 91899-91906, giver Marcy Baker / Dokimi).
- Whether the bag count has dropped 3 s after QUEST_TURNED_IN, and the CURRENCY_DISPLAY_UPDATE arguments.
- Whether `C_QuestLog.GetNextWaypoint` or `GetQuestsOnMap` know the writ delivery spots on Forever.
- Where the vendor mark sits on the merchant row, next to Vendor Search's own marks.
- The faction chat message format on Forever, and whether writs ask for more than 1 item.
- Customers: whether the table's NPCs and spots are right, and whether `UnitName("npc")` and the player's map
  position at QUEST_COMPLETE give the customer (learned per writ in `learned.customers`).
