#!/usr/bin/env python3
"""Make a portable Studio place + source bundle, without caches or credentials."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parents[1]
destination = root / "build/Citymoney-Studio.zip"
with ZipFile(destination, "w", compression=ZIP_DEFLATED) as bundle:
    bundle.write(root / "build/Citymoney.rbxlx", "Citymoney/build/Citymoney.rbxlx")
    for name in ("START-HERE.txt", "README.md", ".gitignore", "default.project.json"):
        bundle.write(root / name, "Citymoney/" + name)
    for directory in ("src", "scripts", "tests"):
        for source in sorted((root / directory).rglob("*")):
            if source.is_file() and "__pycache__" not in source.parts:
                bundle.write(source, "Citymoney/" + source.relative_to(root).as_posix())
with ZipFile(destination) as bundle:
    assert bundle.testzip() is None
print(f"Studio and source bundle created: {destination.name}")
