# Changelog

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
