# Tylesser - Commerce Authority

A helper for the WoW Forever crafting factions, the **Azeroth Commerce Authority** (Alliance) and **Durotar Supply and Logistics** (Horde): Craftsman's Writs, Waylaid Crates, reputation and Merchant's Favor.

## Features

- **Writ tooltips**: hover a Craftsman's Writ, in your bags or in an auction house search, to see:
  - the reputation it gives (Journeyman 75, Expert 125, Artisan 200),
  - what it asks for and which profession makes it, like "Needs 1 Black Mageweave Vest (Tailoring, yours)",
  - that item's auction price from every price addon you have (Auctionator, TradeSkillMaster, Auctioneer),
  - your crafting cost, if Tylesser - Auctionator Profit Sort knows the recipe,
  - the total with the writ's own price, and what that comes to per 100 reputation.
- Sealed writs (Sealed Journeyman's, Expert's and Artisan's Writ) show the reputation of the writ they open into.
- **Crate tooltips**: Waylaid Crates show the Merchant's Favor and silver they give when filled and turned in, and **the cheapest way to fill them**: each crate takes one stack of one item from its list (like 20 Iron Ore or 10 Silver Ore), priced from your auction addon, and whether your bags already hold enough. With the crate's own price you see what each Favor costs.
- **The window** (`/aca`):
  - your standing, with the reputation your bags would add shown on the bar,
  - Merchant's Favor, and about how much your crates would add,
  - the writs and crates in your bags and what they're worth,
  - your **writ quests**, with a **Way** button that puts a waypoint on where each one is delivered (TomTom when installed, else the game's own map pin),
  - how much reputation each next standing needs, and how many writs that is,
  - the **cheapest reputation** on the auction house: writs sorted by cost per 100 reputation (writ + the item it asks for, or your crafting cost when that's cheaper). Tick **Only my professions** to see only writs you can craft for,
  - **Buy list**: makes the Auctionator shopping list "Commerce Authority" with the cheapest writs for the reputation you still need to your next standing, and the items they ask for,
  - this session's Favor, reputation and turn-ins.
- **Vendor marks**: at the Commerce Authority vendors, everything that costs Merchant's Favor shows "Can buy" or how much more you need, and its tooltip says how many crates that is.
- **Learns the real numbers**: the first values come from player guides. Each time you turn in a crate or a writ, the addon remembers what it actually gave and uses that from then on. Tooltips say "(guide)" or "(a guess)" until then.
- **Legacy talents**: tick Performance Bonus (15% chance of double Favor from a crate) or Diplomat (+10% reputation) on the options page and the estimates count them in.

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

## Usage

| Command | Action |
| --- | --- |
| `/aca` or `/commerce` | Show or hide the window |
| `/aca options` | Open the options page (also in Esc > Options > AddOns) |
| `/aca buy` | Make the Auctionator buy list |
| `/aca debug` | Show what the addon sees: faction, Favor, price addons, professions, bags |
| `/aca feedback` | Get the link to report a bug or suggest an idea |

The window can be dragged anywhere. Shift-click a writ in the cheapest list to link it in chat.

## Feedback

Found a bug or have an idea? Click **Feedback** on the options page or type `/aca feedback` in game to get the link, or go straight to [tylesser.com/feedback](https://tylesser.com/feedback/#commerceauthority).

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
