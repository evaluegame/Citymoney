#!/usr/bin/env python3
"""Bake the shared scene into the Studio place, so the editor opens on the city."""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = json.loads((ROOT / "default.project.json").read_text())
scene = json.loads((ROOT / "build/board.json").read_text())


def rgb(hex_color):
    return [int(hex_color[index:index + 2], 16) / 255 for index in (0, 2, 4)]


def resolve_paths(node):
    if not isinstance(node, dict):
        return
    for key, value in node.items():
        if key == "$path":
            node[key] = str(ROOT / value)
        else:
            resolve_paths(value)


resolve_paths(project["tree"])
board = {"$className": "Folder"}
for index, entry in enumerate(scene):
    properties = {
        "Name": entry["name"], "Size": entry["size"], "CFrame": entry["position"] + entry.get("rotation", [1, 0, 0, 0, 1, 0, 0, 0, 1]),
        "Color": rgb(entry["color"]), "Anchored": True,
        "Material": entry.get("material", "SmoothPlastic"),
        "TopSurface": "Smooth", "BottomSurface": "Smooth",
        "Transparency": entry.get("transparency", 0),
        "Reflectance": entry.get("reflectance", 0), "CanCollide": entry.get("canCollide", True),
    }
    if "shape" in entry:
        properties["Shape"] = entry["shape"]
    if entry.get("className") == "SpawnLocation":
        properties.update(Neutral=True, Duration=0)
    node = {"$className": entry.get("className", "Part"), "$properties": properties}
    if entry.get("light"):
        node["Glow"] = {"$className": "PointLight", "$properties": {"Color": rgb(entry["color"]), "Brightness": 0.4, "Range": 10}}
    if "tileIndex" in entry:
        node["$attributes"] = {"TileIndex": entry["tileIndex"]}
    if "interaction" in entry:
        node.setdefault("$attributes", {})["Interaction"] = entry["interaction"]
    if "text" in entry:
        node["TileLabel"] = {
            "$className": "SurfaceGui",
            "$properties": {"Face": entry.get("textFace", "Top"), "SizingMode": "PixelsPerStud", "PixelsPerStud": 40, "LightInfluence": 0},
            "Caption": {"$className": "TextLabel", "$properties": {
                "Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundTransparency": 1,
                "Text": entry["text"], "TextColor3": rgb(entry["textColor"]),
                "TextSize": entry["textSize"], "Font": "GothamBold", "TextWrapped": True, "TextScaled": True,
            }, "Limit": {"$className": "UITextSizeConstraint", "$properties": {"MaxTextSize": entry["textSize"], "MinTextSize": 8}}},
        }
    board[entry["name"] if entry["name"].startswith("Tile") else f"{entry['name']}_{index:04}"] = node
project["tree"]["Workspace"]["CitymoneyBoard"] = board
# Camera basis uses right/up/back columns, matching Roblox CFrame.lookAt.
position = [58, 278, 178]
target = [0, 5, 0]
direction = [a-b for a,b in zip(position,target)]
length = math.sqrt(sum(value * value for value in direction))
back = [value / length for value in direction]
horizontal = math.hypot(back[0], back[2])
right = [back[2] / horizontal, 0, -back[0] / horizontal]
up = [back[1] * right[2] - back[2] * right[1], back[2] * right[0] - back[0] * right[2], back[0] * right[1] - back[1] * right[0]]
rotation = [component for row in zip(right, up, back) for component in row]
project["tree"]["Workspace"]["CityPreviewCamera"] = {"$className": "Camera", "$properties": {
    "CFrame": position + rotation, "FieldOfView": 38, "CameraType": "Scriptable",
}}
destination = ROOT / "build/Citymoney.project.json"
destination.write_text(json.dumps(project, indent=2))
print(f"Baked {len(scene)} scene parts for the Studio editor.")
