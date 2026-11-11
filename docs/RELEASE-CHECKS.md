# Citymoney 1.5 — release verification

This report distinguishes the automated checks from Roblox account tests.

The complete automated suite was rerun for this publishing package on **2026-11-11**: all 334 named cases, 600 simulated matches and eight bilingual client runs passed. The package includes an English/Thai publishing guide, native binary place, editable XML place, source, pass icon and listing text. It is ready to upload for a private playtest; live account checks below remain required before public launch.

| Area | Automated result |
| --- | --- |
| Rules and full matches | 600 complete simulated matches; purchases, chosen starting levels, upgrades, rent tiers, insolvency, victory, events and tactical cards pass. |
| Named cases | 334 cases across the engine, plans, strategy, parties, matchmaking, cosmetics, dice timelines, layout, city geometry, avatars, translation, Robux checkout and recovery. |
| Showcase and guidance | Four event courtyards, enamel/brass board layers, detailed roofs/porch lighting and a clearer party lobby. Eight guided-turn cases cover roll/result/movement/choice/handoff ordering, stale journeys and contextual advice. |
| Match recap | Eight cases cover declared winner priority, ties, true investment values, sold/demolished homes, elimination, recorded awards, empty matches and state privacy. Actual client layouts exercise four and six residents. |
| Optional sound | Actual client sound adapter tests cover four bounded voices, rapid input, muting active/queued notes and an unavailable sound API. Native audibility and mix still require a Roblox app playtest. |
| Dark theme | Dark navy panels, light text, readable gold actions and stronger city colors. Actual visible UI text retains at least 4.5:1 contrast during the eight integration runs; player initials, premium logos, ready goals, disabled options and card icons are included. |
| Recovery | Eight publication cases and seven actual World/clock adapter cases cover render failure, preserved houses, staged-model cleanup, retry backoff, latest-state recovery, recipient failure, missing models, effect retries, isolated property failure and a continuing automatic clock. |
| Per-player language | Roblox English/Thai selection, English fallback, account language taking precedence over device language, independent client contexts, canonical shared English, language changes and fresh/updated world signs pass. Player names, text input, currency and game state are preserved. |
| Readable view | All 24 slots fit the aligned 64-degree view with a 28-degree field of view; zoom/follow remain disabled. Thai marks and UTF-8 initials remain supported. |
| Desktop and phone UI | Eight client runs: both English and Thai at 1440×900, 1192×642, 800×560 and 390×760. Contrast, repeated bootstrap/stale snapshot requests, staged-model cleanup/localization, shop controls, confirmation, restoration and lookup/prompt outages are included. |
| Physical card spaces | Two marked card plots, all five card types, no purchases/home bonuses, full hands, bots, skips, AFK recovery, duplicate/stale requests and post-arrival collection pass. |
| Dice and automatic turns | Both dice settle before the 0.4-second result hold and step-by-step movement. Late completion shifts movement and decision deadlines together. Automatic handoffs and stale requests pass. |
| Homes and city | All 16 purchasable parcels, four home levels, 256 plot/style/level combinations, doors, furniture, ownership markers, empty plots and contained deed labels pass. |
| Avatar lifecycle | Actual World methods pass R6/R15 placement, board/home scaling, loading/replacement, spectator cleanup and removed bot tests through controlled native-service adapters. |
| Online matchmaking | Ten actual Matchmaker cases cover 2-/4-player games, readiness, tickets, outsiders, departures, incomplete arrivals, cancellation-write failure, a claim racing with cancellation, and retried departure cleanup. Pure cross-server claim/reservation cases also pass. |
| Robux cosmetics | Server-owned pass verification and checkout outcomes, delayed ownership, failures, cancellation, duplicate events, stale responses and departure/rejoin behavior pass. Premium access cannot be granted by a local completion event. |
| Source and Studio file | Luau analysis and compilation pass. The serialized place is checked against every current script and scene part. The binary `.rbxl` export preserves the complete XML property/reference graph, with verified native header, instance/class counts and chunk boundaries. The final ZIP is checked byte-for-byte against both places, source, guides and previews. |

## Roblox account checks still required

This workspace cannot run Roblox Studio or log into your Creator Dashboard. No live Robux purchase, native audio/rendering playtest, cross-server teleport or published DataStore test was performed here. The automated service adapters do not replace those tests.

The package ships with **`clubPassId = 0`**, because the creator has not created the pass yet. Free play is available; live cosmetic purchases remain disabled until you create the pass under your published experience, set its ID and republish. The R$149 shop preview is an example test fixture, not an active sale.

Use [PUBLISH-FIRST.md](../PUBLISH-FIRST.md) for the short setup and [PUBLISHING.md](PUBLISHING.md) for Studio/app checks. No Robux payment or account access is required to run the automated tests.

## Reproduce the automated checks

```bash
python3 scripts/setup.py
bash scripts/test.sh
bash scripts/build.sh
```

The setup script installs pinned, checksum-verified Luau and Rojo tools on Linux x86_64. The ready-to-open place requires no Rojo/plugin installation for Roblox Studio users.
