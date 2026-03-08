# FlatPaint macOS (Apple Silicon) Feature Summary

## Build target
- macOS Apple Silicon (`arm64` / `aarch64`)
- Minimum supported macOS: `11.0` (Big Sur) and later
- Artifact: `FlatPaint.app`

## Core capabilities
- Multi-layer raster editing with undo/redo and blend modes
- Selection tools (rect/ellipse/lasso/wand/move-selection/move-pixels)
- Paint tools (pencil/brush/eraser/fill/gradient/clone/recolor)
- Draw tools (text/line/rectangle/rounded-rectangle/ellipse/freeform)
- Crop/resize/rotate/flip and layer operations
- Export options dialog with format-specific controls and preview
- Compatibility import baseline for XCF/KRA/PDN (partial by design)
- System clipboard integration and macOS-native menu/appearance bridges

## Quality baseline
- CI regression suite: 351 tests passing at packaging time
- About metadata is build-time embedded from `assets/about/*.txt`
