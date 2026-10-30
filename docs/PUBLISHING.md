# Publish Citymoney and enable the Club pass

The ZIP contains a ready-to-open place and its source. Publishing it and creating a pass require your Roblox account in Studio/Creator Dashboard. No Roblox account credentials are included or needed by the cloud build.

## 1. Open and try the place

1. Install [Roblox Studio](https://create.roblox.com/) on Windows or macOS and sign in.
2. Extract **Citymoney-Waterfront.zip**.
3. In Studio, choose **File → Open from File**. Open **Citymoney/build/Citymoney.rbxlx** from the extracted folder.
4. Press **Play (F5)**. Open **MENU → Play Together**, select 2 or 4 players, click **PRACTICE WITH BOTS**. Optional practice rules are under **SETTINGS**.
5. Open **MENU → Style Studio** to preview/equip all three paid collections in Studio. Studio labels this as a preview and never opens a payment prompt or grants a real pass.
6. Click **Stop** before editing scripts or publishing, so you edit the saved place rather than a temporary Play session.

For local multiplayer, use **Server & Clients** with 2 or 4 clients. On each client, select the same match size and join its queue. Matching starts a local table once enough clients are queued.

## 2. Publish to your account

1. Choose **File → Publish**. Some Studio versions label this **Publish to Roblox**. For an existing experience, select the intended start place when using **Publish As / Publish to Roblox As**.
2. Give the game a name such as **Citymoney — Build Your City**, add a description, choose supported devices, and save/publish. This uploads the place to Roblox; it does not necessarily make it public yet.
3. Open [Creator Dashboard → Creations](https://create.roblox.com/dashboard/creations) and select that game.
4. In its start-place settings, a **Maximum Player Count of 12** is recommended for the public lobby. Each reserved Citymoney match still admits exactly 2 or 4 matched people.
5. Open **Publish settings → Manage Audience → Manage access**. Choose the appropriate audience, and enable **Public** access when ready. Disable the **Friends** restriction if you want everyone eligible to join. Dashboard labels can change; use the game's audience/access settings shown in your account.
6. Complete the age/account checks and **Maturity & Compliance** questions Roblox requires for your chosen audience. Eligibility can differ for friends, older players, and all-ages releases; follow the requirements Roblox displays rather than assuming the initial upload is already public.

Current official instructions: [Create and publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

## 3. Create the optional Robux cosmetic pass

1. In Creator Dashboard, select **this same Citymoney game**. Open **Monetization → Passes → Create pass**.
2. Upload **Citymoney/docs/Club-pass-icon.png** from the ZIP. It is a 512×512 PNG designed with room for circular cropping.
3. Suggested name: **Waterfront Club — Signature Collection**.
4. Suggested description: **Unlock Golden Estate, Aurora Residence and Rose Conservatory house decorations, Club dice, a player aura and walking trail. Permanent cosmetic collections; no gameplay bonuses.**
5. Create the pass, then open its sales/pricing settings, enable sales, set your desired **Robux price**, and save. This is a one-time pass, not a subscription or a consumable developer product.
6. From the pass's **⋯** menu, choose **Copy Asset ID**. Use the pass asset ID, not the place ID, universe ID, or developer-product ID.

The pass must belong to the same game: Roblox no longer supports cross-game pass sales. The game reads the actual price from Roblox on the client; regional/personalized pricing is not hard-coded.

## 4. Connect the pass to the place

1. In Studio, **stop Play**. Open **Explorer** if hidden.
2. Expand **ReplicatedStorage → Citymoney → Config** and open the Config ModuleScript.
3. Find this setting near the top:

   ```lua
   clubPassId = 0,
   ```

4. Replace `0` with your copied numeric pass asset ID. For example, if your real pass ID were `123456789`, the setting would be `clubPassId = 123456789,`. Keep it as a number, without quotes. The example is not a real configured pass.
5. Publish this updated place to **the same Citymoney experience** again. Join a new server so it runs the new scripts/configuration. Existing running servers can continue using the previous version until restarted.

If editing repository source instead, change `src/shared/Config.lua`, rebuild the place, open the rebuilt place, then publish it. Editing the source in this ZIP does not automatically change an already open or published Studio place.

Leaving the ID at `0` safely disables live purchases. The showroom still previews every collection and says **Club pass coming soon**. The free game and online queues work independently of pass setup.

Official reference: [Passes](https://create.roblox.com/docs/production/monetization/passes).

## 5. Test the published version

Use the **Roblox app**, not just Studio, for live-service checks:

- **Queues:** join with two accounts; choose a 2-player queue and confirm both reach the same reserved match. Repeat with four people. Invite a friend before queueing, mark ready on each party member, and verify the party stays together.
- **Free account:** open MENU → Style Studio. Preview paid styles and confirm they cannot be equipped without ownership. The checkout button should show Roblox's current price. Open the native prompt and cancel to verify that cancellation leaves access locked.
- **Owner account:** use an account that owns the pass, equip each collection, and buy a home. Check the decorations, owner color, dice colors, aura, and walking trail. Try reduced motion and visiting a home.
- **Saved appearance:** wait for **Style saved for your next visit**, leave, and rejoin. Verify the selected collection/effects return and remain selected when traveling from lobby to match. Use **Check ownership** if a purchase made outside the game is not reflected yet.
- **Real purchase:** when you choose to test an actual sale, Roblox checkout charges real Robux. After a successful purchase, the collection should unlock; choose a style and press Equip. The server verifies ownership. Studio previews do not simulate a real transaction.
- **Gameplay:** check buying at different starting levels, later upgrades, rental tiers, targeted demolition/shields, rent demands, challenge claims, doors, and the end-of-match screen. Unowned properties must stay empty; buying should construct a home with owner colors, name and chosen level. Skip an offer, then sell or demolish an owned home and verify those lots are empty again. Verify purchase/upgrade reveals, cash feedback and reduced motion. Confirm real players load their avatar portraits and still show a colored initial if loading fails.
- **Top view:** confirm the game opens on an aligned overhead board and all edges/tall homes fit. Open a property card and check that the camera position stays unchanged. Check all 24 upright badges, owner-colored borders, prices and RENT labels, corner spacing and phone layout. Tapping a badge must open the full property or News panel. Check 3D view / Top view switching, hover cards, and Fit restoring Top view. Check the smaller title/map text and confirm zoom buttons and Close-up are absent; the mouse wheel must keep the board camera unchanged. Check the larger HUD dice and their total, and confirm the bigger 3D dice tumble without clipping through the felt. Click both HUD dice and the 3D tray; every client should see the same final values before the avatar moves.
- **Dice before movement / fixed camera:** confirm both physical dice reach their final faces, the HUD dice stop changing, and the result remains visible for 0.4 seconds before the first step. Test short/twelve-space rolls, corners, another player's turn, reduced motion and a lagging server/client. The board camera must remain unchanged during rolling, movement, arrival, purchases, upgrades and inspection. Confirm late completion preserves the full buying/reward clock. Try R6/R15 avatars, fallback replacement, respawning, colored rings, active outlines and names. After a first-person home visit, return to the board and confirm the body remains visible. Native rendering, replication and camera checks require Studio/app playtests.
- **Waterfront:** inspect downtown storefronts, lamps, benches, fountains and the ferry. Check that public scenery leaves the playable route and event stations clear, and that all unowned parcels remain empty. The overview fits the board; the surrounding scenery can extend behind the HUD.
- **Goals and opportunities:** progress the main-screen goal card, tap a ready goal to claim its reward, and inspect the celebration/new goal. On the second City News visit, choose cash or a card. Check full card types, closing/reopening the prompt, duplicate clicks, other-player visibility and the 55-second automatic cash choice.
- **Automatic turns and plaza:** confirm the token advances in separate 0.38-second steps with a 0.13-second stationary pause at every space, including corners and passing City Gate. Test both a short and twelve-space roll, News teleports and detention. Finish the movement before showing the result and starting the four-second handoff. Pending purchases/opportunities must get 55 seconds after arrival; early finish/buy/reward attempts should be disabled while moving. Use the direct EVENTS shortcut or touch a station to open the four large event cards. Before rolling, try City Market or the current festival; inspect the shared one-purchase allowance, confirmation price, cash deduction, effect on the chosen home, return to board after purchase, and festival change after eight turns.

Citymoney uses Roblox's own MemoryStore, TeleportService, DataStore, and MarketplaceService. Live play needs no HTTP flag or external API keys. Studio preview uses session-only cosmetic preferences and does not require enabling **Studio Access to API Services**.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Download opens XML | Use the ZIP, extract it, then open the `.rbxlx` in Studio. Do not import it as a model/image. |
| Friends cannot join | Confirm audience/access, playtest permissions, and Roblox's account/age requirements for every tester. |
| Queue waits | Match size must agree. Every party member must be ready; online queues wait for exactly 2 or 4 humans. Use Practice for bots. |
| Teleports fail in Studio | Expected: Studio uses the local queue. Test live reserved teleports in the Roblox app. |
| Club pass coming soon | Set the pass ID in Config and republish. |
| Pass currently unavailable | Check the ID, that the pass belongs to this game, and that it is on sale. Use Check ownership to retry product/ownership lookups. |
| Own the pass but still locked | Wait for loading, use Check ownership, then rejoin a new server if Roblox services are delayed. |
| Style equipped but saving delayed | The game keeps your style for this session and retries saving. Roblox DataStore can be temporarily unavailable. |
| Studio appearance resets | Expected: Studio cosmetics are explicitly session-only previews. Verify persistence in the published app. |

The cloud build runs logic tests, source analysis, compilation, and place/bundle verification. It cannot run Studio, charge a test purchase, or verify live service behavior in your Roblox account.
