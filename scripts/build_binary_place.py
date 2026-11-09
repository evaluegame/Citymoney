#!/usr/bin/env python3
"""Export the verified XML place as a directly downloadable Roblox binary place."""
from pathlib import Path
import json
import struct
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
source = root / "build/Citymoney.rbxlx"
tree = ET.parse(source)
xml = tree.getroot()
model = ET.Element("Item", {"class": "DataModel", "referent": "CitymoneyRoot"})
properties = ET.SubElement(model, "Properties")
ET.SubElement(properties, "string", {"name": "Name"}).text = "Citymoney"
for item in list(xml):
    if item.tag == "Item":
        xml.remove(item)
        model.append(item)
xml.append(model)
wrapped = root / "build/Citymoney-conversion.rbxmx"
tree.write(wrapped, encoding="utf-8", xml_declaration=True)
project = root / "build/Citymoney-conversion.project.json"
project.write_text(json.dumps({"name": "Citymoney", "tree": {"$path": str(wrapped)}}))
converted = root / "build/Citymoney-converted.rbxlx"
destination = root / "build/Citymoney.rbxl"
for output in (converted, destination):
    subprocess.run([str(root / ".tools/rojo"), "build", str(project), "--output", str(output)], check=True)


def contents(path):
    """Compare every instance/property, resolving renamed references by ancestry."""
    document = ET.parse(path).getroot()
    nodes, references = {}, {}

    def walk(item, ancestry):
        name = item.findtext("Properties/string[@name='Name']") or ""
        key = ancestry + ((item.attrib["class"], name),)
        assert key not in nodes, f"Ambiguous instance path: {key}"
        nodes[key] = item
        references[item.attrib["referent"]] = key
        for child in item.findall("Item"):
            walk(child, key)

    for item in document.findall("Item"):
        walk(item, ())

    def value(prop):
        if prop.tag == "Ref":
            return prop.tag, references.get(prop.text, prop.text)
        return prop.tag, prop.text or "", tuple((child.tag, value(child)) for child in prop)

    return {key: {prop.attrib["name"]: value(prop) for prop in item.findall("Properties/*")} for key, item in nodes.items()}


expected = contents(source)
assert expected == contents(converted), "Binary export input differs from the verified XML place"
body = destination.read_bytes()
assert body[:16] == b"<roblox!\x89\xff\r\n\x1a\n\x00\x00", "Invalid Roblox binary header"
classes, instances = struct.unpack_from("<II", body, 16)
assert instances == len(expected), (instances, len(expected))
assert classes == len({key[-1][0] for key in expected}), "Binary class count differs from XML"
offset, chunks = 32, []
while offset < len(body):
    kind, compressed, uncompressed, reserved = struct.unpack_from("<4sIII", body, offset)
    assert reserved == 0
    offset += 16 + (compressed or uncompressed)
    assert offset <= len(body), "Truncated Roblox binary chunk"
    chunks.append(kind)
assert offset == len(body) and chunks[-1] == b"END\x00"
assert {b"INST", b"PROP", b"PRNT"}.issubset(chunks)
destination.chmod(0o644)
print(f"Binary Studio place verified: {instances} instances, {classes} classes, {len(body)} bytes; XML properties and references preserved.")
