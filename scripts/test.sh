#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
.tools/luau tests/Engine.spec.luau
.tools/luau tests/Plans.spec.luau
.tools/luau tests/Tactics.spec.luau
.tools/luau tests/Matchmaking.spec.luau
.tools/luau tests/Cosmetics.spec.luau
.tools/luau tests/Tabletop.spec.luau
.tools/luau tests/Presentation.spec.luau
.tools/luau tests/Experience.spec.luau
.tools/luau tests/CityView.spec.luau
.tools/luau tests/Board.spec.luau
.tools/luau tests/Homes.spec.luau
pure_sources=()
for source_file in src/shared/*.lua; do
  # Scene is a Roblox adapter. The standalone analyzer has no Roblox API types.
  if [[ "$source_file" != src/shared/Scene.lua ]]; then pure_sources+=("$source_file"); fi
done
.tools/luau-analyze "${pure_sources[@]}" tests/*.luau scripts/export_board.luau
while IFS= read -r -d '' source_file; do
  .tools/luau-compile "$source_file" > /dev/null
done < <(find src -name '*.lua' -print0)
printf 'All Roblox source files compiled successfully.\n'
python3 scripts/client_smoke.py
