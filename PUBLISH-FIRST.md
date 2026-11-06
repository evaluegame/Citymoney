# Citymoney 1.1 — publish the final build

The place is ready to open and upload in Roblox Studio. The free game works without a pass. Real Robux sales need a pass created under **your own published experience**; this bundle keeps `clubPassId = 0` until that ID is available.

1. Extract **Citymoney-Publish-Ready.zip**. In Studio, choose **File → Open from File** and open **Citymoney/build/Citymoney.rbxlx**.
2. Press **Play → PLAY NOW → PRACTICE WITH BOTS** to try the game. Stop Play, then choose **File → Publish** and save it to your Roblox account.
3. In [Creator Dashboard](https://create.roblox.com/dashboard/creations), select that experience → **Monetization → Passes → Create pass**. Upload `docs/Club-pass-icon.png`. Copy the pass name and description from [ROBLOX-LISTING.txt](docs/ROBLOX-LISTING.txt), enable sales, and set your Robux price.
4. Copy the pass's **Asset ID**. In Studio, open **ReplicatedStorage → Citymoney → Config**. Replace `clubPassId = 0` with that numeric ID. Publish to the **same experience** again.
5. In Creator Dashboard, set the audience/access for your intended players. Join a new server in the Roblox app and test **MENU → COSMETIC SHOP**, an owned pass, a cancelled prompt, and a 2-/4-player match before making the game public.

The shop reads the real Roblox price for each player and uses Roblox checkout. One permanent pass unlocks all three collections: house finishes, dice styles, player auras and walking trails. Premium styles do not change game cash, rent, cards or dice odds.

The pass icon, listing and checkout code are prepared. Creating the actual pass requires your signed-in Creator Dashboard; no pass or Roblox account was created by this cloud build.

Automated checks and build verification are recorded in [RELEASE-CHECKS.md](docs/RELEASE-CHECKS.md). Native Studio rendering, live teleports, purchases and persistence require the Roblox app/Studio checks described in the [full publishing guide](docs/PUBLISHING.md).
