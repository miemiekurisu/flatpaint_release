# fp-macos-lcl-bridge

Type: macOS bridge library for Lazarus/LCL (Cocoa widgetset)
License: LGPL v2.1+ with Lazarus modified linking exception (`LICENSE`)

## Pascal bridge units
- `FPAlphaBridge`
- `FPAppearanceBridge`
- `FPAppMenuBridge`
- `FPCGRenderBridge`
- `FPListBgBridge`
- `FPMagnifyBridge`
- `FPScrollViewBridge`

## Native modules
- `native/fp_alpha.m`
- `native/fp_appearance.m`
- `native/fp_cgrender.m`
- `native/fp_listbg.m`
- `native/fp_magnify.m`
- `native/fp_scrollview.m`

## Dependency profile
- macOS only
- Lazarus LCL Cocoa interface required
- clang required for Objective-C module compilation
- Build script auto-detects common Lazarus source locations
- You can override with `LAZARUS_DIR=/absolute/path/to/lazarus`

## Use from Lazarus/FPC
- Add `src/` to search path
- compile native `.m` modules to object files and ensure linker can find them
- this repo's `build.sh` demonstrates required flags and link setup

## Smoke build
```bash
bash ./build.sh
```
Compiles native bridge objects + `examples/smoke_test.lpr`.

## Reliability status
- Standalone macOS+Cocoa smoke build verified in this repository.
