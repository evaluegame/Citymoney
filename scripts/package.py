#!/usr/bin/env python3
"""Make a portable Studio place + source bundle, without caches or credentials."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import hashlib
import shutil

root = Path(__file__).resolve().parents[1]
destination = root / "build/Citymoney-Studio.zip"
with ZipFile(destination, "w", compression=ZIP_DEFLATED) as bundle:
    bundle.write(root / "build/Citymoney.rbxlx", "Citymoney/build/Citymoney.rbxlx")
    bundle.write(root / "build/Citymoney.rbxl", "Citymoney/build/Citymoney.rbxl")
    for name in ("PUBLISH-FIRST.md", "START-HERE.txt", "START-HERE-TH.txt", "README.md", ".gitignore", "default.project.json"):
        bundle.write(root / name, "Citymoney/" + name)
    for directory in ("src", "scripts", "tests", "docs"):
        for source in sorted((root / directory).rglob("*")):
            if source.is_file() and "__pycache__" not in source.parts:
                bundle.write(source, "Citymoney/" + source.relative_to(root).as_posix())
with ZipFile(destination) as bundle:
    assert bundle.testzip() is None
    for entry in bundle.infolist():
        path = Path(entry.filename)
        assert path.parts[0] == "Citymoney" and ".." not in path.parts
        assert bundle.read(entry) == root.joinpath(*path.parts[1:]).read_bytes(), entry.filename
    count = len(bundle.infolist())
for name in ("Citymoney.rbxlx", "Citymoney-Waterfront.rbxlx"):
    shutil.copyfile(root / "build/Citymoney.rbxlx", root / name)
shutil.copyfile(root / "build/Citymoney.rbxl", root / "Citymoney.rbxl")
for name in ("Citymoney-Publish-Ready.zip", "Citymoney-Studio.zip", "Citymoney-Waterfront.zip"):
    shutil.copyfile(destination, root / name)
print(f"Studio bundle verified: {count} current files; all root downloads refreshed.")
print(f"ZIP SHA256: {hashlib.sha256(destination.read_bytes()).hexdigest()}")
