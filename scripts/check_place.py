#!/usr/bin/env python3
"""Check that the built Studio place contains the current server/client modules."""
from pathlib import Path
import json
import math
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
place = ET.parse(ROOT / "build/Citymoney.rbxlx").getroot()


def child(parent, name, class_name):
    for item in parent.findall("Item"):
        properties = item.find("Properties")
        if properties is not None and properties.findtext("string[@name='Name']") == name:
            assert item.attrib["class"] == class_name, (name, item.attrib)
            return item
    raise AssertionError(f"Missing {class_name}: {name}")


replicated = child(place, "ReplicatedStorage", "ReplicatedStorage")
shared = child(replicated, "Citymoney", "Folder")
server = child(child(place, "ServerScriptService", "ServerScriptService"), "CitymoneyServer", "Script")
client = child(child(child(place, "StarterPlayer", "StarterPlayer"), "StarterPlayerScripts", "StarterPlayerScripts"), "CitymoneyClient", "LocalScript")
expected = [
    (child(shared, "Config", "ModuleScript"), "src/shared/Config.lua"),
    (child(shared, "Engine", "ModuleScript"), "src/shared/Engine.lua"),
    (child(shared, "Board", "ModuleScript"), "src/shared/Board.lua"),
    (child(shared, "Architecture", "ModuleScript"), "src/shared/Architecture.lua"),
    (child(shared, "Scene", "ModuleScript"), "src/shared/Scene.lua"),
    (child(shared, "Layout", "ModuleScript"), "src/shared/Layout.lua"),
    (child(shared, "PropertyPlans", "ModuleScript"), "src/shared/PropertyPlans.lua"),
    (server, "src/server/init.server.lua"),
    (child(server, "World", "ModuleScript"), "src/server/World.lua"),
    (client, "src/client/init.client.lua"),
]
for item, source in expected:
    embedded = item.find("Properties/*[@name='Source']")
    assert embedded is not None and embedded.text == (ROOT / source).read_text(), source
print(f"Studio place verified: {len(expected)} scripts match their source and expected services.")
board = child(child(place, "Workspace", "Workspace"), "CitymoneyBoard", "Folder")
tiles = [item for item in board.findall("Item") if (item.findtext("Properties/string[@name='Name']") or "").startswith("Tile")]
assert len(tiles) == 24, "The editor preview must include all 24 board tiles"
assert len(board.findall("Item")) >= 100, "Missing city geometry"
scene = json.loads((ROOT / "build/board.json").read_text())
for index, entry in enumerate(scene):
    name = entry["name"] if entry["name"].startswith("Tile") else f"{entry['name']}_{index:04}"
    item = child(board, name, entry.get("className", "Part"))
    frame = item.find("Properties/CoordinateFrame[@name='CFrame']")
    assert frame is not None, f"Missing serialized CFrame for {name}"
    for axis, expected_coordinate in zip(("X", "Y", "Z"), entry["position"]):
        assert math.isclose(float(frame.findtext(axis)), expected_coordinate, abs_tol=1e-4), name
    for axis, expected_component in zip(("R00","R01","R02","R10","R11","R12","R20","R21","R22"), entry.get("rotation", [1,0,0,0,1,0,0,0,1])):
        assert math.isclose(float(frame.findtext(axis)), expected_component, abs_tol=1e-4), (name, axis)
for index in range(1, 25):
    tile = child(board, f"Tile{index}", "Part")
    assert tile.find("Item[@class='SurfaceGui']") is not None, "Missing editor tile caption"
camera = child(child(place, "Workspace", "Workspace"), "CityPreviewCamera", "Camera")
assert child(place, "Workspace", "Workspace").findtext("Properties/Ref[@name='CurrentCamera']") == camera.attrib["referent"]
print(f"Editor preview verified: {len(board.findall('Item'))} scene parts, including all 24 tiles.")
