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
expected = []
for directory, parent, entry in (("shared", shared, None), ("server", server, "init.server.lua"), ("client", client, "init.client.lua")):
    for source in sorted((ROOT / "src" / directory).glob("*.lua")):
        item = parent if source.name == entry else child(parent, source.stem, "ModuleScript")
        expected.append((item, source.relative_to(ROOT).as_posix()))
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
    if entry.get("interaction"):
        attributes = item.find("Properties/BinaryString[@name='AttributesSerialize']")
        assert attributes is not None and attributes.text, f"Missing interactive attributes for {name}"
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
expected_camera = json.loads((ROOT / "build/board-camera.json").read_text())
camera_frame = camera.find("Properties/CoordinateFrame[@name='CFrame']")
rotation = [value for row in zip(expected_camera["right"], expected_camera["up"], expected_camera["back"]) for value in row]
for axis, value in zip(("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"), expected_camera["position"] + rotation):
    assert math.isclose(float(camera_frame.findtext(axis)), value, abs_tol=1e-4), ("Editor top view", axis)
print(f"Editor preview verified: {len(board.findall('Item'))} scene parts, including all 24 tiles.")
