#!/usr/bin/env python3
"""Connect the baked preview camera to Workspace in the serialized place."""
from pathlib import Path
import xml.etree.ElementTree as ET

path = Path(__file__).resolve().parents[1] / "build/Citymoney.rbxlx"
tree = ET.parse(path)
workspace = next(item for item in tree.getroot().findall("Item") if item.attrib["class"] == "Workspace")
camera = next(item for item in workspace.findall("Item") if item.attrib["class"] == "Camera")
properties = workspace.find("Properties")
reference = properties.find("Ref[@name='CurrentCamera']")
if reference is None:
    reference = ET.SubElement(properties, "Ref", name="CurrentCamera")
reference.text = camera.attrib["referent"]
tree.write(path, encoding="utf-8", xml_declaration=True)
print("Studio editor camera framed on the city.")
