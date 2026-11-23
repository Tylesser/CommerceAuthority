# Changelog

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
