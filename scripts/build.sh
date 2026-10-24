#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
mkdir -p build
.tools/luau scripts/export_board.luau > build/board.json
python3 scripts/make_place_project.py
.tools/rojo build build/Citymoney.project.json --output build/Citymoney.rbxlx
python3 scripts/set_editor_camera.py
python3 scripts/check_place.py
python3 scripts/package.py
