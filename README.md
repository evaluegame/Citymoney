# Citymoney · The Waterfront Club

A Roblox property board game with a clear tabletop view, interactive 3D dice, automatic turn handoffs, furnished homes, and an interactive city plaza. Play through **2- or 4-player online queues**, invite friends, choose your property's rent, and decide which rival house to demolish.

Now includes an optional **Waterfront Club cosmetic game pass** with three luxury collections, a 3D showroom, styled dice, player auras, walking trails, saved preferences, and reduced motion. **[Publishing and pass setup guide](docs/PUBLISHING.md)**.

**[Download the Studio game ZIP](https://github.com/evaluegame/Citymoney/raw/refs/heads/main/Citymoney-Waterfront.zip)** · **[Studio place file](https://github.com/evaluegame/Citymoney/blob/main/Citymoney-Waterfront.rbxlx)**

The download files are at the repository root. On a GitHub file page, use **Download raw file** (the download-arrow button). The ZIP includes a ready-to-open place, source, and instructions.

![The full tabletop board with an open event plaza and dice tray](docs/Neighborhood-preview.png)

*A geometry render showing example purchases. The live table view also adds upright, clickable labels with prices/rent. This is a model preview, not a Roblox Studio screenshot.*

## Table view, dice, and automatic turns

**Table view** is now the default: a flatter, square board with the entire route and tall homes fitted into the area left by the HUD. The camera recalibrates when you resize the window, rotate the board, or open a property card. It accounts for Roblox's top bar and device safe areas. Every space has an upright label; purchased deeds display rent and their owner's color. **City view** offers an angled 3D view. **Fit** restores the full board. Purchases and upgrades no longer zoom the camera away automatically; **Close-up** still lets you inspect a chosen home.

During your roll phase, click/tap **either HUD die**, the **3D dice**, or their central **tray**, or press **R**. Everyone sees the same server-selected values. The dice tumble, bounce, and settle with the exact rolled faces on top before the avatar moves. Reduced motion settles the dice immediately. Dice skins remain cosmetic.

After a resolved landing, purchase, or pass, the turn hands off **automatically after four seconds**. The next resident gets a fresh roll phase. **Finish now / Space** can hand off sooner. An unresolved purchase keeps its full **55-second decision clock**; a completed turn does not wait for that clock to expire. Use cards, the city plaza, and property management before rolling so you have time to make choices. Browsing menus or changing cosmetics does not postpone handoff.

## The interactive city plaza

The center's decorative houses and trees have been replaced with four low, clickable destinations. Press **P**, click a station, or use **Explore city plaza** while another resident takes a turn:

| Destination | What it does |
| --- | --- |
| City Market | Buy the tactical card you choose using game cash: demolition $180, rent demand $140, rent boost $100, shield $100, renovation $160. Hand caps still apply. |
| City Festival | Choose one of your homes for the current rotating offer: Lantern Festival gives a two-payment rent boost for $80; Design Fair adds one building level for $110; Neighborhood Watch adds a demolition shield for $60. |
| Challenge Hall | Open your challenge progress, claim completed goals, or choose a new goal. |
| City News | See the active festival and recent city bulletin. |

Festivals rotate every **eight total turns**. The festival pavilion displays the current offer and turns remaining. Make **one plaza purchase per turn, before rolling**; a market purchase and a festival offer share that allowance. Playing a tactical card remains a separate allowance. Existing shields/boosts and fully upgraded homes cannot be purchased again wastefully. Failed, stale, unaffordable, or invalid requests spend nothing. Bots use eligible festivals and still improve their homes. All plaza prices use **game cash**, never Robux.

## Open in Roblox Studio

1. Install [Roblox Studio](https://create.roblox.com/) on Windows or macOS and sign in.
2. Download and extract **Citymoney-Waterfront.zip**.
3. Choose **File → Open from File** (Ctrl+O / Cmd+O) and open **Citymoney/build/Citymoney.rbxlx**.
4. Press **Play (F5)**. Open **Match / invite**, choose **2 players** or **4 players**, keep practice bots on, and click **Practice**.

The neighborhood is visible in the editor; menus appear during Play. The place contains its models and scripts. No paid assets, API keys, plugins, or HTTP access are needed to play it.

## Play online and invite friends

1. Open the updated place and use **File → Publish** (called **Publish to Roblox** in some Studio versions) in your account.
2. In Creator Dashboard, make the experience available to your intended players. A **12-player server capacity** allows several parties to wait in the public lobby. Each reserved match admits exactly **2 or 4 matched humans**.
3. Join the published experience using the Roblox app. Open **Match / invite**, choose a size and color, then click **Join 2-player queue** or **Join 4-player queue**.
4. To play together, click **Invite friends before joining the queue**. A friend accepting that invitation is brought to your public server and joins your party. Guests click **I'm ready to play**. The party leader queues everyone together.
5. Parties contain up to four people and are never split: two pairs can fill a four-player match, or three friends can wait for one solo player. Online queues never fill seats with bots.

Every match assigns distinct player colors. If separate parties chose the same color, matching gives the later resident an unused color. Roofs, lot borders, flags, mailboxes, avatar rings, and HUD labels use those match colors; house signs also show the owner's name.

Use **Cancel queue** while searching or **Leave party** to form a new solo party. Once a match is connecting, wait for the teleport. In an online match, **Return to lobby / Leave match** returns you to a public server; leaving an ongoing match forfeits your deeds. Invite your friends again from the lobby for another party.

Matching uses Roblox **MemoryStoreService** and **TeleportService** to create a reserved server in the same place. Access codes stay on the server. The destination validates the ticket and roster, then waits for the matched players. Failed teleports retry; an incomplete arrival times out after 60 seconds and returns arrivals to a public lobby.

**Live queueing, invitations, and teleports require a published experience and a Roblox app playtest.** Studio uses a local queue without live teleports. In **Server & Clients**, launch 2 or 4 clients, choose the same queue size on each, and join the queue on each client. The table starts automatically when enough players are available. Practice is a separate button and can fill empty seats with bots.

## Houses, upgrades, and rent options

![A cottage with a player-colored roof, border and flag](docs/House-preview.png)

*A geometry preview of a purchased cottage.*

Land on an unowned property and choose **Cottage (L0), Townhouse (L1), Garden villa (L2), or Grand villa (L3)**. The selector shows a 3D preview, total price, rent, affordability, and remaining cash. Buying immediately builds that furnished home with a porch, mailbox, garden, owner sign, and your color.

Purchase price is `land price + selected level × build cost`. Later, select your home during your turn and open **Upgrade options**. Choose any higher level and pay `(target level − current level) × build cost`. You do not need a district pair to upgrade. Houses gain floors, stairs, bedrooms, balconies, or rooftop gardens as their level rises.

Select your property → **Rent options** to buy a permanent multiplier for its future rent payments:

| Rent tier | Multiplier | Fee from the original 1× tier |
| --- | --- | --- |
| Standard | 1× | Included |
| Improved | 1.5× | 2 × build cost |
| Premium | 2× | 4 × build cost |
| Maximum | 3× | 6 × build cost |

Moving between paid tiers charges only the added tier steps: `steps added × 2 × build cost`. The menu shows the fee, resulting rent, and balance before confirmation. The house keeps its building level. Lower/current tiers cannot be purchased again. A physical sign displays the new rate, which continues until the property is sold or destroyed. All payments use in-game cash, never Robux.

For example, Copper Lane costs $90 for land and $60 per building level. A Townhouse costs $150 and earns $36 base rent. Raising its rent from 1× to 1.5× costs $120 and makes future rent $54. Upgrading that Townhouse to Grand villa later costs $120 for two added levels; its paid rent multiplier remains in place.

## Cards, events, and challenges

Open **Cards & goals** to select a card, its property, and an opponent where needed. You start with one of each type and can hold up to **three of each type**. Hands are private. Play **one tactical card per turn**, alongside normal rolls, purchases, upgrades, and rent improvements.

| Card | Chosen target and effect |
| --- | --- |
| Demolition permit | Choose an opponent's house. Destroy the entire home and return its lot to the city, clearing building levels, paid rent tiers, shield, and boosts. The former owner receives no refund. |
| Property shield | Choose your home. Block its next demolition attempt; both the attacking permit and shield are consumed. |
| Renovation grant | Choose your home. Add one building level free, up to L3. |
| Rent boost | Choose your property. Add 50% to its rent for the next two paid collections. |
| Rent demand | Choose your property and a living opponent. Collect twice its current rent immediately, capped at $350. This also counts as a collection for a temporary boost. |

Online games always use full-house demolition. Practice offers an optional one-level attack rule; under that rule, attacking an L0 cottage still returns the lot to the city. Signs mark protected homes and rental effects. Destroying a visited home returns its owner to the board.

There are **20 City News events**: cash gains/losses, card grants, extra draws, maintenance based on homes or levels, home dividends, a community street fair, and movement events. Passing City Gate and resting in Central Park also award cards, subject to the hand cap.

Seven rotating challenges reward collecting homes, adding building levels, earning rent, passing City Gate, drawing City News, playing cards, and completing districts. Watch progress in **Cards & goals**, then **claim** the cash reward and a random card during your turn. Claim one goal per turn; pay **$50** to change your goal once per turn. Rewards range from $120 to $180. Losing property can invalidate an unclaimed ownership goal. Bots also play cards and claim goals.

## Controls

| Action | Control |
| --- | --- |
| Matchmaking, party, color, practice | **Match / invite** |
| Cards, targets, challenges | **Cards & goals** |
| Roll | Click/tap a HUD die, 3D die, or dice tray; bottom action button or **R** also works |
| Buy / finish early | Bottom action button; **Space** performs the current action. Resolved turns advance automatically |
| City plaza | Click a station, press **P**, or use **Explore city plaza** while waiting |
| Inspect a property | Click/tap its plot or house, or open **Your homes** |
| Upgrade / set rent | Select your home during your turn → **Upgrade options / Rent options** |
| Repaint / sell | Property card during your turn; repainting is free, sales ask for confirmation |
| Visit your home | Property card → **Walk through your home**, including during another player's turn |
| Walk / door / return | Roblox walking controls; **E** operates your door; **B** or **Back to board** returns |
| Camera | **Table view / City view / Fit**, rotate buttons, + / −, mouse wheel; **Close-up** on a property card |
| Lighting | **Golden hour / Night stroll** in the desktop header |

Visits do not change your game position, cash, or turn. The match continues while you explore. Rolling/ending your turn returns you to the board. Selling or losing a visited home returns you; upgrades/repainting move you safely onto its front path.

## Waterfront Club cosmetics

![Golden Estate villa with marble steps, lanterns and garden ornaments](docs/Club-home-preview.png)

*A render of the actual Golden Estate geometry. The showroom previews every collection before purchase.*

Open **Club collection** under the player list. Preview **Golden Estate**, **Aurora Residence**, and **Rose Conservatory**, then equip a collection you own. Each adds coordinated metal trim, marble foundations, garden lanterns, planters, ornaments, a Club plaque, dice colors, and a player aura with a walking trail. Your player-colored roof, borders, flag, and owner sign stay visible. Changing styles also updates existing houses and their 3D property previews.

One **permanent cosmetic game pass** unlocks all three collections. Waterfront Classic is free. The pass adds appearance only: no extra game cash, cards, rent, turn time, or dice advantages. It is separate from a Roblox Premium subscription. Roblox handles payment and supplies the price; the server verifies pass ownership on join and after purchases. **Check ownership** retries verification, including passes bought outside the game. Only the active collection and effects preference are saved in DataStore; ownership always comes from Roblox. Selections are carried through matchmaking teleports and validated again at the destination.

**Creator setup is required to sell the pass:** create it under this game's **Monetization → Passes**, put it on sale, and replace `clubPassId = 0` in **ReplicatedStorage → Citymoney → Config** with its numeric asset ID. Republish the place. Until then, the live showroom allows previews and shows **Club pass coming soon**; it cannot charge Robux. See the [full guide](docs/PUBLISHING.md). A ready-to-upload **512×512 PNG** icon is included at `docs/Club-pass-icon.png`.

In Studio, all collections can be equipped for a clearly labeled **test-session preview**; it makes no purchases or permanent unlocks and needs no DataStore/API-access setting. In a published game, only verified pass owners can equip paid collections. **Reduced motion** stops the rotating showroom, dice animation, victory confetti, and your walking trail. Cosmetic menus do not pause the turn timer.

## Core rules

Start with **$1,500**, roll two six-sided dice, and collect **$200** for passing or landing on City Gate. Doubles do not grant another turn. Own both deeds in a district to double their **L0 base rent**. L1/L2/L3 earn **3× / 6× / 10×** base rent before paid tiers and boosts. City Tax costs $120. Detention skips your next move; merely visiting is harmless.

Rolls and unresolved purchases allow **55 seconds**, then the server rolls or declines the property automatically. Resolved turns hand off after **four seconds**. Opening menus, visiting, playing cards, claiming goals, and improving properties do not extend the current deadline. Server checks enforce ownership, targets, funds, inventory, and turn/phase restrictions. Stale and repeated purchases cannot double-charge.

Selling returns half the land, building, and paid rental investment. Cash shortfalls automatically sell deeds in board order; insolvency eliminates a resident. Sold, demolished, abandoned, and repossessed homes disappear physically. A departing resident's deeds return to the city. Temporary boosts and shields add no resale value.

The last resident standing wins. At **120 total turns**, the surviving resident with the highest cash plus full property/building/rental investment wins; ties go to the earlier seat. Progress belongs to the current match. Persistent profiles, trading, and auctions are not included.

## Development and verification

Use the existing checkout; cloud tasks do not require a Git worktree.

```bash
cd /workspace/Citymoney
python3 scripts/setup.py
bash scripts/test.sh
bash scripts/build.sh
```

The Linux x86_64 bootstrap installs **Rojo 7.7.1** and **Luau 0.727** into ignored `.tools/` from official releases with verified publisher SHA-256 digests. `build.sh` creates **build/Citymoney.rbxlx** and **build/Citymoney-Studio.zip**. Root download files are release copies refreshed separately; ordinary builds leave them alone.

For source editing alongside Studio, use `rojo serve default.project.json --address 127.0.0.1 --port 34872` and the [official Rojo Studio plugin](https://rojo.space/docs/v7/getting-started/installation/). A source-only build creates the scene at runtime. The packaged place also includes an editor preview.

| Source | Purpose |
| --- | --- |
| `Architecture`, `Board`, `Scene`, `Layout` | Homes, neighborhood, Roblox geometry adapter, responsive HUD |
| `Engine`, `PropertyPlans`, `Config` | Authoritative economy, turns, home/rental quotes, settings |
| `Tactics` | Cards, targets, challenges, bots' tactical choices |
| `BoardCamera`, `client/BoardView`, `client/TileLabels` | Screen-safe table/city camera fitting and upright interactive deed labels |
| `Dice`, `server/DiceWorld`, `TurnFlow` | Exact-result 3D dice animation, turn clocks and automatic handoff |
| `Plaza`, `client/CityPlaza` | Game-cash card market, rotating festivals and interactive plaza menus |
| `Cosmetics`, `CosmeticProfiles`, `server/ClubService`, `client/Boutique` | Cosmetic catalogue, verified ownership, saved appearance, Roblox checkout, 3D showroom |
| `Lobby`, `Parties`, `QueuePlanner`, `MatchProtocol` | Parties, exact-size packing, colors, atomic reservations and recovery |
| `server/Matchmaker` | MemoryStore, reserved teleports, invitations, Studio queue adapter |
| `server/World`, `server/init.server` | Physical lifecycle, avatar visits, doors, validated remotes, timers |
| `client/Menus`, `client/init.client` | Match/card/goal menus, rent selector, HUD, cameras, input |

Checks include **155 numbered cases and 600 complete simulated matches**: 35 core engine cases (200 matches), 18 purchase/upgrade cases, 23 strategy/rent cases (200 tactical matches), 25 party/matchmaking cases, 23 cosmetic/ownership/profile cases, and 31 tabletop cases (200 automatic matches). New cases cover camera projections across desktop/portrait/inset/rotation combinations, tall homes and closeups, exact dice faces, automatic handoff and stale clocks, market prices/caps, festival rotation/targets, and bots. Cosmetic cases cover verification/storage failures, concurrent saves, reconnects, and all **256 plot/style/level combinations**. Additional scene, home and layout checks run; pure modules are analyzed, all Roblox source compiles, and built-place scripts, interactive attributes and geometry are checked against source.

Reservation and cosmetic service tests use in-memory adapters. **Cloud checks do not run Roblox Studio or live Roblox services.** Rendering, movement, input, doors, replication, native invites, cross-server joins, actual game-pass checkout, and DataStore persistence still require Studio and published-game playtests.

`scripts/render_preview.py` optionally renders exported geometry with Blender. These are model previews, not Studio screenshots; Blender is not needed to play or build.
