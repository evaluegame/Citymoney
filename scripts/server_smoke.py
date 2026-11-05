#!/usr/bin/env python3
"""Exercise actual native dice ordering and avatar placement with limited Roblox adapters."""
from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parents[1]
sources = list((root / "src/shared").glob("*.lua")) + [root / "src/server/DiceWorld.lua", root / "src/server/World.lua", root / "src/server/ClubService.lua", root / "src/server/Matchmaker.lua", root / "src/server/init.server.lua"]
def literal(value):
    equals = "="
    while "]" + equals + "]" in value:
        equals += "="
    return "[" + equals + "[" + value + "]" + equals + "]"
table = ",\n".join("[" + json.dumps(path.relative_to(root).as_posix()) + "]=" + literal(path.read_text()) for path in sources)
runner = root / "build/dice-server-smoke.luau"
runner.parent.mkdir(exist_ok=True)
runner.write_text("local run=require('../tests/dice_world_mock')\nlocal sources={" + table + "}\nprint(run(sources)..' native dice/router cases passed.')\n")
subprocess.run([str(root / ".tools/luau"), str(runner)], cwd=root, check=True)
avatar_runner = root / "build/avatar-server-smoke.luau"
avatar_runner.write_text("local run=require('../tests/avatar_world_mock')\nlocal sources={" + table + "}\nprint(run(sources)..' native avatar cases passed.')\n")
subprocess.run([str(root / ".tools/luau"), str(avatar_runner)], cwd=root, check=True)
club_runner = root / "build/club-server-smoke.luau"
club_runner.write_text("local run=require('../tests/club_service_mock')\nlocal sources={" + table + "}\nprint(run(sources)..' native Club purchase cases passed.')\n")
subprocess.run([str(root / ".tools/luau"), str(club_runner)], cwd=root, check=True)
match_runner = root / "build/match-server-smoke.luau"
match_runner.write_text("local run=require('../tests/matchmaker_mock')\nlocal sources={" + table + "}\nprint(run(sources)..' native matchmaking cases passed.')\n")
subprocess.run([str(root / ".tools/luau"), str(match_runner)], cwd=root, check=True)
