#!/usr/bin/env python3
"""Render the real exported shop GUI, viewport model, and matching board.

The shop fixture uses an example price. These are offline review images, not
native Roblox screenshots or proof of a configured sale.
"""
from pathlib import Path
import json
import subprocess
import sys
from preview_fonts import ensure_fonts

ensure_fonts()

root = Path(__file__).resolve().parents[1]
view = sys.argv[1] if len(sys.argv) > 1 else "shop-robux-desktop"
output = sys.argv[2] if len(sys.argv) > 2 else "docs/Robux-shop-preview.png"
layout_path = root / "build" / f"{view}.json"
layout = json.loads(layout_path.read_text())
viewport = next(item["viewport"] for item in layout["elements"] if item.get("viewport"))
scene_path = root / "build" / f"{view}-viewport-scene.json"
camera_path = root / "build" / f"{view}-viewport-camera.json"
preview_path = root / "build" / f"{view}-viewport.png"
scene_path.write_text(json.dumps(viewport["scene"]))
camera_path.write_text(json.dumps({key: value for key, value in viewport.items() if key != "scene"}))
background = root / "build" / f"{view}-background.png"
for scene, camera, destination in [
    (root / "build" / f"{view}-scene.json", layout_path, background),
    (scene_path, camera_path, preview_path),
]:
    with (root / "build" / f"{destination.stem}.log").open("w") as log:
        subprocess.run(["blender", "-b", "-t", "2", "--python", "scripts/render_preview.py", "--", str(scene), str(destination), str(camera), "32"], cwd=root, stdout=log, stderr=subprocess.STDOUT, check=True)
caption = "LAYOUT PREVIEW · Example price · Not a Studio screenshot"
if "studio" in view:
    caption = "LAYOUT PREVIEW · Studio preview mode · Not a Studio screenshot"
subprocess.run([sys.executable, "scripts/render_hud_preview.py", str(layout_path), str(background), output, str(preview_path), caption], cwd=root, check=True)
