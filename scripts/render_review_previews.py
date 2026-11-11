#!/usr/bin/env python3
"""Refresh the offline GUI/scene previews. Requires Blender and client exports.

These renders use real source geometry and exported GUI positions. They are not
Roblox Studio screenshots or substitutes for native graphics playtests.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import subprocess
from preview_fonts import ensure_fonts

root = Path(__file__).resolve().parents[1]
jobs = [
    ("main-desktop", "hud-desktop", "Play-screen-preview"),
    ("main-mobile", "hud-mobile", "Phone-screen-preview"),
    ("en-main-desktop", "en-hud-desktop", "English-play-preview"),
    ("en-main-mobile", "en-hud-mobile", "English-phone-preview"),
    ("card-space-desktop", "card-space-desktop", "Card-space-preview"),
    ("card-space-mobile", "card-space-mobile", "Card-space-phone-preview"),
    ("rent-card-space-desktop", "rent-card-space-desktop", "Rent-card-space-preview"),
    ("card-guide-desktop", "card-guide-desktop", "Card-space-guide-preview"),
    ("walking-desktop", "walking-desktop", "Walking-screen-preview"),
    ("walking-mobile", "walking-mobile", "Walking-phone-preview"),
    ("result-desktop", "result-desktop", "Dice-result-preview"),
    ("reward-desktop", "reward-desktop", "Goal-reward-preview"),
    ("opportunity-desktop", "opportunity-desktop", "Opportunity-screen-preview"),
    ("events-desktop", "events-desktop", "Events-screen-preview"),
    ("lobby-desktop", "lobby-desktop", "Start-menu-preview"),
    ("recap-desktop", "recap-desktop", "Match-recap-preview"),
    ("recap-mobile", "recap-mobile", "Match-recap-phone-preview"),
]


def render(scene, camera, output):
    with (root / "build" / f"{Path(output).stem}.log").open("w") as log:
        subprocess.run(["blender", "-b", "-t", "2", "--python", "scripts/render_preview.py", "--", scene, output, camera, "16"], cwd=root, stdout=log, stderr=subprocess.STDOUT, check=True)


def run(job):
    scene, layout, name = job
    background = f"build/Review-{scene}.png"
    render(f"build/{scene}-scene.json", f"build/{layout}.json", background)
    subprocess.run(["python3", "scripts/render_hud_preview.py", f"build/{layout}.json", background, f"docs/{name}.png"], cwd=root, check=True)
    return name


if __name__ == "__main__":
    ensure_fonts()
    with ThreadPoolExecutor(max_workers=2) as pool:
        for name in pool.map(run, jobs):
            print("READY", name, flush=True)
    for mode, name in [("showcase", "review-city-scene"), ("citycamera", "review-city-camera")]:
        result = subprocess.run([str(root / ".tools/luau"), "scripts/export_board.luau", "-a", mode, "th-th"], cwd=root, text=True, capture_output=True, check=True)
        data = json.loads(result.stdout)
        if mode == "citycamera":
            data = {"width": 1440, "height": 1050, "camera": data}
        (root / "build" / f"{name}.json").write_text(json.dumps(data))
    render("build/review-city-scene.json", "build/review-city-camera.json", "build/Review-city.png")
    from PIL import Image, ImageDraw, ImageFont
    image = Image.open(root / "build/Review-city.png").convert("RGB")
    ImageDraw.Draw(image).text((16, image.height - 24), "MODEL PREVIEW · Shared game geometry · Not a Studio screenshot", font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12), fill=(35, 65, 100))
    image.save(root / "docs/Neighborhood-preview.png")
    for view, output in [("shop-robux-desktop", "docs/Robux-shop-preview.png"), ("shop-robux-mobile", "docs/Robux-shop-phone-preview.png")]:
        subprocess.run(["python3", "scripts/render_shop_preview.py", view, output], cwd=root, check=True)
    for mode, name in [("home", "House-preview"), ("clubhome", "Club-home-preview")]:
        result = subprocess.run([str(root / ".tools/luau"), "scripts/export_board.luau", "-a", mode, "en-us"], cwd=root, text=True, capture_output=True, check=True)
        source = root / "build" / f"review-{mode}.json"
        source.write_text(result.stdout)
        background = f"build/Review-{mode}.png"
        render(str(source), "", background)
        model = Image.open(root / background).convert("RGB")
        ImageDraw.Draw(model).text((16, model.height - 24), "MODEL PREVIEW · Shared game geometry · Not a Studio screenshot", font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12), fill=(35, 65, 100))
        model.save(root / "docs" / f"{name}.png")
        print("READY", name, flush=True)
