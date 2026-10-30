#!/usr/bin/env python3
"""Exercise actual native dice coroutine ordering with a limited Roblox adapter."""
from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parents[1]
sources = list((root / "src/shared").glob("*.lua")) + [root / "src/server/DiceWorld.lua", root / "src/server/init.server.lua"]
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
