# Changelog

## 1.7.0

- **Delivery route**: **Route** on the Writs tab (or `/aca route`) puts waypoints on the NPCs who take your ready writs, nearest first from where you stand. With TomTom every stop gets one; otherwise the game's map pin goes on the first and chat names the rest. When no writ is ready yet, the route takes every NPC.
- **Writ NPCs on the map**: the world map shows the NPCs who take the writs you hold, green when one is ready, gold while it still needs its item. Hover a pin for the writs, click it for a waypoint. Option **Writ NPCs on the map** (on by default).
- **Characters tab**: every character's standing, Merchant's Favor and the writs and crates in its bags, with the totals for all of them and when you last played each. Shift-right-click one to forget it. Also `/aca characters`.
- **Crate price alert** (off until you switch it on): **Tell me when a crate is cheap** names every crate whose price plus its cheapest fill is at or under the amount you type (like 50s or 1g 20s), once per crate each session, after a scan or a search. With a sound if you like.

## 1.6.0

- **Beside the auction house**: the window opens docked to the auction house's right edge when you open it, and closes with it. When it's closed, a Commerce Authority button on the auction house's edge opens it. Drag it away to keep it open where you put it. Option **Open beside the auction house** (on by default).
- **Writs and crates in their own tabs**: the window has a **Writs** tab (standing, your writs, deliveries, next standings, the cheapest reputation) and a **Crates** tab (Merchant's Favor, your crates, the crates you have to fill and the cheapest Merchant's Favor). The tab you used last opens next time.
- **Cheapest Merchant's Favor** on the Crates tab: every crate on the auction house by what turning it in costs: the crate's price plus the cheapest way to fill it (a Sealed crate's price alone), cheapest first, with the cost per Favor. Scroll it with the mouse wheel. Click a crate at the auction house to search for it and everything that fills it, elsewhere to put it and its cheapest fill on the buy list.
- **Crate fills come with their amount**: when you click a crate at the auction house and pick one of the items that fill it, the buy box already holds how many your crates still need (less what your bags hold), in Auctionator's buy view and in the game's own. You still press Buy yourself.
- **Clearer options page**: a thin line now separates each option from the next.
- **Tylesser settings window**: the options now open in a window of their own with room for everything, every Tylesser addon you have listed on its left. Options > AddOns has one **Tylesser** entry that opens it.

## 1.5.0

- **In your language**: German, French, Spanish, Russian and Brazilian Portuguese game clients now show the addon in their language (other clients stay in English). Russian clients get the game's own font for headings, since the addon's fonts have no Cyrillic letters.
- **Fills its gaps from players' data**: with Tylesser - Data installed, writs whose NPC isn't known yet show who takes them and where, and crates show the Merchant's Favor players' recorded turn-ins gave, once someone has collected them with Tylesser - Collector. Your own turn-ins still come first.
- **The plain Waylaid Crate** says to read its label (using it turns it into a crate of one kind), and **Waylaid Herbs** says to read its shipping bill, or shows the bill from players' data.
- **Other game languages**: your faction is found by its ID, so the window's standing and the reputation per writ work on every client; "Only my professions" finds your professions in any language; the NPC who takes a writ no longer shows twice when you turned one in on another client.
- Four writs that only knew their item by name now know its ID (Catseye Draught, Gyromatic Micro-Adjuster, Draught of Detect Demon, Gnomish Alarm-O-Bot), so they get prices and a buy list on every client.

## 1.4.1

- **Herb crates from Expert on now show their lines**: "Waylaid Crate: Earthly Artisan Herbs" and the other Earthly and Flowering crates showed no Favor, price or fill list in their tooltip. Crates are now known by their item, so this also works in every game language.
- **Sealed Elite Crates** are known too (their Favor is a guess until you turn one in).

## 1.4.0

- **Start**: a writ that is ready but not opened yet (your bags hold what it asks for) gets a Start button: in the window's Deliveries (one writ per click) and on its line in the Writ NPCs window. It opens the writ's quest as a right-click on it does; not in a fight, and not while a vendor, bank, mail, trade or auction house window is open (the writ would go there).
- **More writ NPCs**: 133 of the 150 writs now know who takes them (20 more Artisan writs: Blasted Lands, Deadwind Pass, Winterspring, Silithus and more). The other 17 are still learned at your first turn-in.
- **Writ NPCs window**: zones are grouped under their continents (Eastern Kingdoms, Kalimdor), each folding like a zone; Fold all folds the continents.

## 1.3.0

- **Waylaid Crates in the window**: the crates you still have to fill show under Deliveries, after your writs, with how many you hold and the cheapest way to fill them (or "ready to fill" when your bags hold enough). Hover one for every fill and its price. At the auction house a click searches for everything that fills it (with Auctionator all at once); elsewhere it puts the cheapest fill on the Auctionator buy list, enough for all your crates of that kind.
- **Materials for what you craft**: when a writ's item is cheaper to craft than to buy, a click at the auction house searches for the item's materials instead of the item, and the buy list holds the materials (enough for the writs' count). The materials come from Profit Sort (1.6.0 or later, after you open the profession once); without them it searches the item as before.

## 1.2.1

- Fixed: a Lua error at some writ hand-ins ("attempt to compare local 'name'"): when the game keeps the NPC's name hidden, that hand-in simply isn't used to learn where the customer stands.

## 1.2.0

- Writ NPCs window: a writ level button (all, Journeyman, Expert, Artisan), a "My professions" filter and a "Not done today" filter (every writ can be turned in once a day; writs you turned in today say "done today"); zones fold with the button on their line (or a click on the zone away from the auction house), and "Fold all" folds or unfolds every zone. Your filters and folded zones are kept.
- 8 more writs name who takes them: Silver Skeleton Key, Ornate Mithril Shoulders, Potion of Demonslaying, Dreamless Sleep Potion, Greater Fire Protection Potion, Gift of Arthas, Limited Invulnerability Potion and Major Rejuvenation Potion.
- The Performance Bonus and Diplomat legacy talents are detected: the two check boxes are gone, and the options page shows which of them you have.
- Check boxes react only over their own label: hovering "Not done today" no longer lit "My professions".

## 1.1.0

- **Who takes each writ**: writ tooltips name the NPC the writ is delivered to, where it stands, and the other writs that NPC takes (marked when you have them), so you can collect them and deliver them all in one trip. Known for 105 of the 150 writs; the rest are learned at your first turn-in.
- The window's **Deliveries** section groups the writs you hold by that NPC, shows how many are ready, and puts a waypoint on the NPC.
- **Writ NPCs** window (`/aca npcs`, or **All NPCs** in the window): every NPC, grouped by zone, with all the writs it takes and which of them you have, what buying the rest costs, with a search box and waypoints.
- At the auction house, click a writ, an NPC or a zone to search for those writs and the items they ask for (all at once with Auctionator).
- **By NPC** and **By zone** in the cheapest list: ranks the NPCs, or the zones, by what buying all their writs costs per 100 reputation, with the total. Click a row to put its writs on the Auctionator buy list; **Way** points you to the NPC, or to every NPC of the zone (with TomTom).
- Fixed: the Elixir of Ogre's Strength writ's quest wasn't recognised.

## 1.0.0

- First version: writ and crate tooltips with auction prices from Auctionator, TradeSkillMaster or Auctioneer, reputation and Merchant's Favor estimates that learn from your turn-ins, and the `/aca` window with your standing, your bags, the next standings and the cheapest reputation on the auction house.
- Crate tooltips show the cheapest way to fill each crate, and whether your bags already hold enough.
- Writ quests in the window, with a waypoint to where each is delivered (TomTom or the game's map pin).
- **Buy list**: an Auctionator shopping list of the cheapest writs to your next standing.
- Marks at the Commerce Authority vendors: "Can buy" or how much more Merchant's Favor you need.
- **Only my professions**: writ tooltips name the profession that makes the item, and the cheapest list can show only writs you can craft for.
