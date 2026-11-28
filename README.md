# Tylesser - Commerce Authority

A helper for the WoW Forever crafting factions, the **Azeroth Commerce Authority** (Alliance) and **Durotar Supply and Logistics** (Horde): Craftsman's Writs, Waylaid Crates, reputation and Merchant's Favor.

## Features

- **Writ tooltips**: hover a Craftsman's Writ, in your bags or in an auction house search, to see:
  - the reputation it gives (Journeyman 75, Expert 125, Artisan 200),
  - what it asks for and which profession makes it, like "Needs 1 Black Mageweave Vest (Tailoring, yours)",
  - that item's auction price from every price addon you have (Auctionator, TradeSkillMaster, Auctioneer),
  - your crafting cost, if Tylesser - Auctionator Profit Sort knows the recipe,
  - the total with the writ's own price, and what that comes to per 100 reputation,
  - **who takes it**: each writ goes to its own NPC somewhere in the world ("Deliver to Kzixx, Duskwood (81.8, 19.8)"), and the other writs that NPC takes, marked when you have them, so you can collect them all and deliver them in one trip.
- Sealed writs (Sealed Journeyman's, Expert's and Artisan's Writ) show the reputation of the writ they open into.
- **Crate tooltips**: Waylaid Crates show the Merchant's Favor and silver they give when filled and turned in, and **the cheapest way to fill them**: each crate takes one stack of one item from its list (like 20 Iron Ore or 10 Silver Ore), priced from your auction addon, and whether your bags already hold enough. With the crate's own price you see what each Favor costs.
- **The window** (`/aca`), in three tabs: **Writs**, **Crates** and **Characters**. The tab you used last opens next time.
- **Writs** tab:
  - your standing, with the reputation your bags would add shown on the bar,
  - the writs in your bags and the reputation they give,
  - **Deliveries**: the writs you hold (opened or not), grouped by the NPC who takes them, with how many are ready. Hover a row to see each writ and what else that NPC takes; **Way** puts a waypoint on the NPC (TomTom when installed, else the game's own map pin),
  - how much reputation each next standing needs, and how many writs that is,
  - the **cheapest reputation** on the auction house: writs sorted by cost per 100 reputation (writ + the item it asks for, or your crafting cost when that's cheaper). Tick **Only my professions** to see only writs you can craft for. The **By writ** button switches the ranking to **By NPC** (what buying all the priced writs an NPC takes costs per 100 reputation; writs you already hold aren't bought again) and **By zone** (the same for all the NPCs of a zone, so one trip around the zone delivers them all). Each row shows the total and the cost per 100 reputation. Hover a row for its NPCs, writs and prices; click it to put them all on the buy list; **Way** points you to the NPC, or to every NPC of the zone with TomTom (without TomTom: the first, the rest listed in chat),
  - **Buy list**: makes the Auctionator shopping list "Commerce Authority" with the cheapest writs for the reputation you still need to your next standing (**By NPC** or **By zone**: every priced writ of the top NPC or zone), and the items they ask for (or their materials, for items cheaper to craft).
- **Crates** tab:
  - your Merchant's Favor, and about how much your crates would add,
  - the crates in your bags, filled or still to fill,
  - **Crates to fill**: the Waylaid Crates in your bags, with the cheapest way to fill each. Click one at the auction house to search for everything that fills it (picking an item there opens its buy box with the amount your crates still need), or elsewhere to put the cheapest fill on the buy list,
  - **Cheapest Merchant's Favor**: every crate on the auction house by what turning it in costs: the crate's price plus the cheapest way to fill it (a Sealed crate's price alone), cheapest first, with the cost per Favor. Scroll it with the mouse wheel. Click a crate at the auction house to search for it and everything that fills it, elsewhere to put it and its cheapest fill on the buy list; **Buy list** does that for the cheapest one.
- **Characters** tab: every character's standing, Merchant's Favor and the writs and crates in its bags, with the totals for all of them and when you last played each (`/aca characters`). A character shows up once it has reputation, Favor, writs or crates. Shift-right-click one to forget it.
- Under every tab: this session's Favor, reputation and turn-ins.
- **Delivery route**: **Route** on the Writs tab (`/aca route`) puts waypoints on the NPCs who take your ready writs, nearest first from where you stand. With TomTom every stop gets one; otherwise the game's map pin goes on the first and chat names the rest. When no writ is ready yet, the route takes every NPC.
- **Writ NPCs on the map**: the world map shows the NPCs who take the writs you hold, on zone and continent maps: green when one is ready, gold while it still needs its item. Hover a pin for the writs, click it for a waypoint. Untick **Writ NPCs on the map** on the options page to hide them.
- **Crate price alert** (off until you switch it on): tick **Tell me when a crate is cheap** on the options page and type an amount (like 50s or 1g 20s). Every crate whose price plus its cheapest fill is at or under it gets a chat line, once per crate each session, after a scan or a search; with a sound if you like.
- **Writ NPCs** (`/aca npcs`, or **All NPCs** in the window): every NPC who takes writs, grouped by continent and zone, with all the writs it takes and which of them you have (ready, needs the item, not opened) or what each costs on the auction house. Zone and NPC lines show how many writs are yours and what buying the rest costs ("+" when some have no auction price yet). Zones and NPCs you hold writs for come first; **Way** puts a waypoint on an NPC or on every NPC of a zone, and the search box finds an NPC, zone or writ. Writs whose NPC isn't known yet are listed at the end. A ready writ you haven't opened (your bags hold what it asks for) gets a **Start** button there and in your Deliveries: it opens the writ's quest.
- **Search the auction house with a click**: while the auction house is open, click a writ, an NPC or a zone (in the cheapest list or in Writ NPCs) to search for those writs (the ones you don't have yet) and the items they ask for, or the items' materials when crafting them is cheaper (from Profit Sort). With Auctionator all of them at once in its Shopping tab; without it the game's search box takes the first.
- **Vendor marks**: at the Commerce Authority vendors, everything that costs Merchant's Favor shows "Can buy" or how much more you need, and its tooltip says how many crates that is.
- **Learns the real numbers**: the first values come from player guides. Each time you turn in a crate or a writ, the addon remembers what it actually gave and uses that from then on. Tooltips say "(guide)" or "(a guess)" until then. Who takes each writ is known for 133 of the 150 writs; for the rest (Artisan writs) the addon remembers the NPC the first time you turn one in.
- **Legacy talents**: when you have Performance Bonus (15% chance of double Favor from a crate) or Diplomat (+10% reputation), the estimates count them in. The addon sees which ones you have; the options page lists them.

## How the numbers are estimated

| | Reputation or Favor |
| --- | --- |
| Journeyman / Expert / Artisan writ | 75 / 125 / 200 reputation |
| Apprentice crate | 5 Favor (raw goods) or 10 (made goods: fabrics, ingots, parts) |
| Journeyman crate | 10 or 20 Favor |
| Expert crate | 15 or 30 Favor |
| Artisan crate | 20 or 40 Favor (a guess) |

Each crate also pays half a silver per Favor. All WoW Forever writs are counted as asking for 1 item; while you have a writ's quest, the count comes from your quest log.

## Requirements

None. For auction prices, install Auctionator, TradeSkillMaster or Auctioneer and scan the auction house.

Optional: [Tylesser - Data](https://tylesser.com/tylesserdata/) fills in what the addon doesn't know yet (who takes the last Artisan writs, the Favor of Artisan and Elite crates) from what players recorded with Tylesser - Collector.

## Usage

| Command | Action |
| --- | --- |
| `/aca` or `/commerce` | Show or hide the window |
| `/aca options` | Open the options page (also Esc > Options > AddOns > Tylesser) |
| `/aca npcs` | Show or hide the Writ NPCs window |
| `/aca route` | Waypoints to the NPCs who take your writs, nearest first |
| `/aca characters` | Open the window on the Characters tab |
| `/aca buy` | Make the Auctionator buy list |
| `/aca debug` | Show what the addon sees: faction, Favor, price addons, professions, bags |
| `/aca feedback` | Get the link to report a bug or suggest an idea |

The window can be dragged anywhere. Shift-click a writ in the cheapest list to link it in chat.

**Beside the auction house**: when the auction house opens, the window opens docked to its right edge and closes with it. When it's closed, the **Commerce Authority** button on the auction house's edge opens it. Drag it away to keep it where you put it. Untick **Open beside the auction house** on the options page to open it only from the button.

Languages: English, German, French, Spanish (Spain and Mexico), Russian and Brazilian Portuguese, following your game client.

## Feedback

Found a bug or have an idea? Click **Feedback** on the options page or type `/aca feedback` in game to get the link, or go straight to [tylesser.com/feedback](https://tylesser.com/feedback/#commerceauthority).

No GitHub account? Join the [Tylesser Discord](https://discord.gg/n2rEB6mRxF) and post in #bug-reports or #ideas with the addon's tag; each post is copied to GitHub and the bot answers with the link.

## Installation

Install from CurseForge, or download the latest zip from [Releases](https://github.com/Tylesser/CommerceAuthority/releases) and extract it to `Interface/AddOns`. The folder must be named `CommerceAuthority`.

## Releasing (maintainers)

Releases are built by [BigWigsMods/packager](https://github.com/BigWigsMods/packager). Push a version tag to publish to GitHub Releases and CurseForge:

```
git tag v1.0.0
git push origin v1.0.0
```

## License

[MIT](LICENSE)
