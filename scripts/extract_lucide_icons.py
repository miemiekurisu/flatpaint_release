#!/usr/bin/env python3

from __future__ import annotations

import shutil
import sys
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent.parent
SOURCE_ICON_DIR = ROOT_DIR / "icons"
LUCIDE_DIR = ROOT_DIR / "assets" / "icons" / "lucide"
RENDERED_DIR = ROOT_DIR / "assets" / "icons" / "rendered"

TARGET_ICON_SIZE = 20
TARGET_INSET = 1
ICON_COLOR = (50, 50, 50, 255)
MIN_ALPHA = 6

ICON_NAMES = (
    "file-plus-2",
    "folder-open",
    "save",
    "scissors",
    "copy",
    "clipboard-paste",
    "undo",
    "redo",
    "zoom-in",
    "zoom-out",
    "plus",
    "copy-plus",
    "trash-2",
    "combine",
    "eye",
    "arrow-up",
    "arrow-down",
    "blend",
    "layers-2",
    "pen",
    "sliders-horizontal",
    "arrow-left-right",
    "contrast",
    "wrench",
    "history",
    "layers",
    "palette",
    "settings",
    "circle-help",
    "square-dashed",
    "circle-dashed",
    "lasso",
    "wand",
    "move",
    "hand",
    "search",
    "paint-bucket",
    "pencil",
    "paintbrush",
    "eraser",
    "pipette",
    "stamp",
    "droplets",
    "slash",
    "square",
    "square-round-corner",
    "circle",
    "spline",
    "crop",
    "type",
)

SOURCE_ALIASES = {
    "file-plus-2": "file-plus",
    "circle-help": "circle-question-mark",
}


def require_pillow():
    try:
        from PIL import Image
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "Pillow is required for icon rasterization; install python3 module 'PIL'"
        ) from exc
    return Image


def resolve_source_svg(name: str) -> Path:
    source_name = SOURCE_ALIASES.get(name, name)
    path = SOURCE_ICON_DIR / f"{source_name}.svg"
    if not path.exists():
        raise RuntimeError(f"missing source SVG for {name}: {path}")
    return path


def sync_source_svgs() -> None:
    LUCIDE_DIR.mkdir(parents=True, exist_ok=True)
    for path in LUCIDE_DIR.glob("*.svg"):
        path.unlink()

    for name in ICON_NAMES:
        source_path = resolve_source_svg(name)
        dest_path = LUCIDE_DIR / f"{name}.svg"
        shutil.copyfile(source_path, dest_path)


def normalize_png(raw_png: Path, dest_png: Path) -> None:
    Image = require_pillow()

    source = Image.open(raw_png).convert("RGBA")
    gray = source.convert("L")
    inverted = gray.point(lambda value: 255 - value)
    alpha = inverted.point(lambda value: 0 if value < MIN_ALPHA else value)
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"rendered icon contains no visible pixels: {raw_png}")

    cropped_alpha = alpha.crop(bbox)
    inner_size = TARGET_ICON_SIZE - (TARGET_INSET * 2)
    width, height = cropped_alpha.size
    scale = min(inner_size / width, inner_size / height)
    scaled_width = max(1, round(width * scale))
    scaled_height = max(1, round(height * scale))
    resampling = getattr(Image, "Resampling", Image).LANCZOS
    scaled_alpha = cropped_alpha.resize((scaled_width, scaled_height), resampling)

    glyph = Image.new("RGBA", (TARGET_ICON_SIZE, TARGET_ICON_SIZE), (0, 0, 0, 0))
    ink = Image.new("RGBA", (scaled_width, scaled_height), ICON_COLOR)
    offset_x = (TARGET_ICON_SIZE - scaled_width) // 2
    offset_y = (TARGET_ICON_SIZE - scaled_height) // 2
    glyph.paste(ink, (offset_x, offset_y), scaled_alpha)
    glyph.save(dest_png)

def sync_only() -> int:
    if not SOURCE_ICON_DIR.exists():
        print(f"missing source icon directory: {SOURCE_ICON_DIR}", file=sys.stderr)
        return 1
    try:
        sync_source_svgs()
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


def main() -> int:
    if len(sys.argv) == 1:
        return sync_only()
    if len(sys.argv) == 2 and sys.argv[1] == "--sync-only":
        return sync_only()
    if len(sys.argv) == 4 and sys.argv[1] == "--normalize":
        try:
            normalize_png(Path(sys.argv[2]), Path(sys.argv[3]))
        except RuntimeError as exc:
            print(str(exc), file=sys.stderr)
            return 1
        return 0
    print(
        "usage: extract_lucide_icons.py [--sync-only | --normalize SOURCE_PNG DEST_PNG]",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
