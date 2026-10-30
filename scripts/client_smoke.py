#!/usr/bin/env python3
"""Load real client modules in a limited headless API adapter; export HUD layouts.

This catches UI integration errors but does not emulate Roblox rendering/services.
"""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def literal(text):
    equals = "="
    while "]" + equals + "]" in text:
        equals += "="
    return "[" + equals + "[" + text + "]" + equals + "]"


sources = []
for folder in ("shared", "client"):
    for file in sorted((ROOT / "src" / folder).glob("*.lua")):
        sources.append("[" + json.dumps(file.relative_to(ROOT).as_posix()) + "]=" + literal(file.read_text()))
encoder = (ROOT / "scripts/export_board.luau").read_text()
encoder = encoder[encoder.index("local encode"):encoder.index("local mode = ...")]
base = "local mock=require('../tests/roblox_ui_mock')\nlocal sources={" + ",\n".join(sources) + "}\n" + encoder
(ROOT / "build").mkdir(exist_ok=True)
for name, width, height in (("desktop", 1440, 900), ("studio", 1192, 642), ("short", 800, 560), ("mobile", 390, 760)):
    runner = ROOT / "build/client-smoke.luau"
    runner.write_text(base + f"\nprint(encode(mock(sources,{width},{height})))\n")
    result = subprocess.run([str(ROOT / ".tools/luau"), str(runner)], cwd=ROOT, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr + result.stdout)
    data = json.loads(result.stdout.splitlines()[-1])
    for view, snapshot in data.pop("views").items():
        (ROOT / "build" / f"{view}-{name}-scene.json").write_text(json.dumps(snapshot.pop("scene")))
        if view!="main":
            (ROOT / "build" / f"{view}-{name}.json").write_text(json.dumps({"width":width,"height":height,**snapshot}, indent=2))
    (ROOT / "build" / f"hud-{name}.json").write_text(json.dumps(data, indent=2))
    print(f"PASS client UI adapter: {name} {width}×{height}; 24 non-overlapping map labels, view toggle/reset, goals/rewards, arrival timing, opportunities, event targets, upgrades, buy/skip, lobby/practice and HUD bounds.")
