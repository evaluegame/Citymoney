"""Offline review fonts with Thai shaping and Latin digits.

Roblox uses its own font fallback. The optional Linux renderer needs
fonts-noto-core and fonttools; merged fonts are kept in the ignored build folder.
"""
from pathlib import Path


def ensure_fonts():
    root = Path(__file__).resolve().parents[1]
    paths = []
    for weight in ("Regular", "Bold"):
        destination = root / "build" / f"CitymoneyThai-{weight}.ttf"
        if not destination.exists() or destination.stat().st_mtime < Path(__file__).stat().st_mtime:
            from fontTools.merge import Merger
            destination.parent.mkdir(exist_ok=True)
            font = Merger().merge([
                f"/usr/share/fonts/truetype/noto/NotoSansThai-{weight}.ttf",
                f"/usr/share/fonts/truetype/noto/NotoSans-{weight}.ttf",
                "/usr/share/fonts/truetype/noto/NotoSansSymbols2-Regular.ttf",
            ])
            font.save(destination)
        paths.append(str(destination))
    return paths
