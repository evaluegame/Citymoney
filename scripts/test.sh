#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
.tools/luau tests/Engine.spec.luau
.tools/luau tests/Plans.spec.luau
.tools/luau tests/Board.spec.luau
.tools/luau tests/Homes.spec.luau
.tools/luau-analyze src/shared/Config.lua src/shared/Engine.lua src/shared/Board.lua src/shared/Architecture.lua src/shared/Layout.lua src/shared/PropertyPlans.lua tests/Engine.spec.luau tests/Plans.spec.luau tests/Board.spec.luau tests/Homes.spec.luau scripts/export_board.luau
while IFS= read -r -d '' source_file; do
  .tools/luau-compile "$source_file" > /dev/null
done < <(find src -name '*.lua' -print0)
printf 'All Roblox source files compiled successfully.\n'
