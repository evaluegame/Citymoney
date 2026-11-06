# Citymoney 1.1 — release verification

This report distinguishes the automated checks from Roblox account tests.

| Area | Automated result |
| --- | --- |
| Rules and full matches | 600 complete simulated matches; purchases, chosen starting levels, upgrades, rent tiers, insolvency, victory, events and tactical cards pass. |
| Named cases | 275 cases across the engine, plans, strategy, parties, matchmaking, cosmetics, dice timelines, layout, city geometry, avatars and Robux checkout. |
| Desktop and phone UI | The actual client modules pass four headless layouts: 1440×900, 1192×642, 800×560 and 390×760. Shop controls, prices, cancellation, server confirmation, restoration, automatic equipping and lookup/prompt outages are included. |
| Physical card spaces | Two marked card plots, all five card types, no purchases/home bonuses, full hands, bots, skips, AFK recovery, duplicate/stale requests and post-arrival collection pass. |
| Dice and automatic turns | Both dice settle before the 0.4-second result hold and step-by-step movement. Late completion shifts movement and decision deadlines together. Automatic handoffs and stale requests pass. |
| Homes and city | All 16 purchasable parcels, four home levels, 256 plot/style/level combinations, doors, furniture, ownership markers, empty plots and contained deed labels pass. |
| Avatar lifecycle | Actual World methods pass R6/R15 placement, board/home scaling, loading/replacement, spectator cleanup and removed bot tests through controlled native-service adapters. |
| Online matchmaking | Actual Matchmaker methods start the real Engine with 2 or 4 humans; readiness, unique colors, admission tickets, outsiders, departures and incomplete-arrival retries pass. Pure cross-server claim/reservation cases also pass. |
| Robux cosmetics | Server-owned pass verification and checkout outcomes, delayed ownership, failures, cancellation, duplicate events, stale responses and departure/rejoin behavior pass. Premium access cannot be granted by a local completion event. |
| Source and Studio file | Luau analysis and compilation pass. The serialized place is checked against every current script and scene part. The final ZIP is checked byte-for-byte against the place, source, guides and previews. |

## Roblox account checks still required

This workspace cannot run Roblox Studio or log into your Creator Dashboard. No live Robux purchase, native rendering playtest, cross-server teleport or published DataStore test was performed here. The automated service adapters do not replace those tests.

The package ships with **`clubPassId = 0`**, because the creator has not created the pass yet. Free play is available; live cosmetic purchases remain disabled until you create the pass under your published experience, set its ID and republish. The R$149 shop preview is an example test fixture, not an active sale.

Use [PUBLISH-FIRST.md](../PUBLISH-FIRST.md) for the short setup and [PUBLISHING.md](PUBLISHING.md) for Studio/app checks. No Robux payment or account access is required to run the automated tests.

## Reproduce the automated checks

```bash
python3 scripts/setup.py
bash scripts/test.sh
bash scripts/build.sh
```

The setup script installs pinned, checksum-verified Luau and Rojo tools on Linux x86_64. The ready-to-open place requires no Rojo/plugin installation for Roblox Studio users.
