# Citymoney

An original Roblox property-trading board game. Roll through a miniature city, buy districts, collect rent, and turn your deeds into a skyline. Play with **2–6 people**, or **start alone against City Bot**. All money is fictional match currency.

**[Download the game ZIP](https://github.com/evaluegame/Citymoney/raw/refs/heads/main/Citymoney-Studio.zip)** · **[Open the Studio file on GitHub](https://github.com/evaluegame/Citymoney/blob/main/Citymoney.rbxlx)**

The ready-to-open `Citymoney.rbxlx` and `Citymoney-Studio.zip` are included at the repository root. On a file's GitHub page, use **Download raw file** (the download-arrow button) to save it to your computer. For the entire project, use **Code → Download ZIP**.

## Play in Roblox Studio

Roblox Studio runs on a **Windows PC or Mac**. Install it from [Roblox Creator Hub](https://create.roblox.com/), then sign in to your Roblox account. The download includes a plain-text **START-HERE.txt** guide.

1. Download **`build/Citymoney.rbxlx`**. Alternatively, download and extract **`build/Citymoney-Studio.zip`**, which includes the place and all editable source.
2. In Roblox Studio, select **File → Open from File** (or **Ctrl+O / Cmd+O**). Choose **Citymoney.rbxlx** from your Downloads folder. In the ZIP it is inside **Citymoney/build/**.
3. The city is already visible in the editor. Press **Play (F5)** to start the game and display its interface.
4. Click **Got it — let's play**, then **Start the city** to play against the bot. Roll, buy or pass, then end your turn.
5. To test friends locally, use Studio's **Server & Clients** playtest with 2–6 clients. The first connected player is the host and starts the match. Later arrivals spectate until the next match.
6. To release your game, use **File → Publish to Roblox** in your own account. Set server capacity to **6** in the experience/place settings. This repository does not publish automatically.

The built place includes every script; no plugins, paid assets, API keys, or HTTP access are required to play. If your browser displays XML, save the file with the **.rbxlx** extension, or use the ZIP. The HUD runs during **Play**; an editing viewport only displays the city preview.

For development, rebuild the place using the commands below; generated files go into the ignored `build/` directory. The root-level downloads are release copies and are refreshed separately when publishing an update. If you prefer manual Studio setup, create a `Citymoney` Folder in ReplicatedStorage containing ModuleScripts named `Config`, `Engine`, and `Board`; paste in the matching shared files. Add a `CitymoneyServer` Script in ServerScriptService using `src/server/init.server.lua`, with a `World` ModuleScript as its child. Add a `CitymoneyClient` LocalScript in StarterPlayer → StarterPlayerScripts using `src/client/init.client.lua`. The server rebuilds the board and network remotes when Play starts, using the same scene definition as the baked editor preview.

## Improvements in this version

- A city preview with 273 scene parts, readable tile captions, and a saved editor camera.
- A fountain, roof gardens, street lamps, and taller buildings at maximum property level.
- A first-game guide, animated dice, turn prompts, cash-change notifications, and a countdown bar.
- Click/tap board tiles to highlight and inspect properties; the portfolio marks complete districts.
- Net worth and district totals, clear build requirements, and a confirmation before selling a deed.
- A final standings screen with confetti and a host replay button.

## Controls

- Click/tap the bottom action button to roll, buy, and end your turn. **R** rolls; **Space** performs the current main action.
- **Pass** declines the property you just landed on.
- Click/tap a **board tile** or one of **Your City** deeds to inspect it. During your turn, use **Build** or **Sell** on that deed. Selling asks for confirmation. You can sell deeds while deciding whether to buy another one.
- **Rotate view**, **+ / −**, and the mouse wheel control the board camera.
- **How to play** opens the rules. Button controls support touch; landscape gives the board more room.

## Rules

Start with **$1,500**. Roll two six-sided dice and move clockwise. Passing or landing on City Gate earns **$200**. Doubles do not grant an extra turn in Citymoney.

Buy an unowned property when you land on it. Landing on another resident's property automatically pays rent. Own both properties in one colored district to double their base rent and unlock building. Each deed can reach level 3; upgraded rent is 3×, 6×, then 10× its original base rent. Building is permitted anywhere in your portfolio during your turn, provided you still own its entire district.

City News draws a random cash or movement event. City Tax costs **$120**. Detention skips your next move; simply visiting detention is harmless. Central Park is a rest stop.

Sell deeds to the city for half their purchase and building costs. If a bill exceeds your cash, deeds automatically sell in board order until you can pay. If your assets cannot cover the bill, you pay your remaining cash and are eliminated. Deeds return to the city when their owner leaves. Selling a district partner removes the base-rent bonus and prevents further building; existing upgrades on the remaining deed keep their rent.

The last surviving resident wins. At **120 total turns**, the resident with the highest cash plus full property/building cost wins; equal scores go to the earlier seat. Each decision has **35 seconds** before the server acts automatically: roll, decline a purchase, or end the turn. The bot buys with a reserve and upgrades completed districts. The host can start a fresh match after the results.

## Development

The cloud bootstrap targets Linux x86_64 with Python 3 and Bash:

```bash
cd /workspace/Citymoney
python3 scripts/setup.py
bash scripts/test.sh
bash scripts/build.sh
```

`setup.py` downloads **Rojo 7.7.1** and **Luau 0.727** from their official GitHub releases, verifies the publisher's SHA-256 digests, and installs into ignored `.tools/`. No system package changes are needed. It can be rerun using its verified archive cache.

On Windows/macOS, install the same Rojo version from [Rojo's releases](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), then run:

```bash
rojo build default.project.json --output Citymoney.rbxlx
```

For live source editing on the same machine as Studio, run `rojo serve default.project.json --address 127.0.0.1 --port 34872` (or `.tools/rojo` in this Linux environment) and connect with the [official Rojo Studio plugin](https://rojo.space/docs/v7/getting-started/installation/). Cloud connectivity depends on your Studio/network configuration; the self-contained place file is the simplest way to play. Future cloud tasks should use the existing checkout; each task is already isolated and does not need a Git worktree.

### Structure and validation

| Path | Purpose |
| --- | --- |
| `src/shared/Config.lua` | Original board, prices, colors, events, and balance settings |
| `src/shared/Engine.lua` | Platform-independent turn and economy rules |
| `src/shared/Board.lua` | Shared geometry for the Studio preview and running city |
| `src/server/init.server.lua` | Server authority, lobby, bots, timeouts, and remotes |
| `src/server/World.lua` | Procedural 3D board, city, animated tokens, and buildings |
| `src/client/init.client.lua` | Responsive HUD, camera, keyboard, and touch controls |
| `tests/Engine.spec.luau` | Rules, invalid actions, economy invariants, and 200 full simulated matches |

`test.sh` runs 31 engine tests (including 200 simulated matches), validates the board's closed path and deterministic scene, analyzes the shared modules/tests, and compiles all game scripts with Luau. `build.sh` bakes the shared scene, frames the editor camera, and packages the source into a Studio place. It then runs `scripts/check_place.py` to validate the service/script hierarchy, all 24 labeled preview tiles, the camera reference, and embedded source against this checkout, before creating the ZIP.

Roblox Studio is not available in this Linux cloud environment. Automated checks validate rules and packaging; **actual rendering, input, replication, multiplayer play, and publication still need the Studio playtests above**. Money and progress reset with each match/server. Persistent profiles, trading, auctions, and cross-server matchmaking are outside this first version.
