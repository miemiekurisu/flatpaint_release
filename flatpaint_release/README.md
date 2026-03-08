# FlatPaint Public Libraries + Release Pack

This folder contains the partial-open export for GitHub publishing.

## License
All published libraries in `libs` use Lazarus-compatible modified LGPL:
- `licenses/COPYING.LGPL.txt`
- `licenses/COPYING.modifiedLGPL.txt`

## What is open-sourced
1. `fp-raster-core` (pure FPC raster core library)
2. `fp-viewport-kit` (pure FPC viewport/zoom/ruler helpers)
3. `fp-lcl-raster-bridge` (LCL bridge: `TRasterSurface <-> TBitmap`)
4. `fp-lcl-clipboard-meta` (LCL clipboard metadata helper)
5. `fp-macos-lcl-bridge` (macOS Cocoa bridge units for Lazarus LCL)

Every library folder includes:
- `README.md` (usage + scope)
- `LICENSE`
- `build.sh` (standalone smoke build)
- `examples/smoke_test.lpr`

## Release payload
- `release/FlatPaint.app` (macOS Apple Silicon app bundle)
- `release/APP_FEATURES.md` (feature summary)
- `release/packages/*.zip` (app + library source packages)
- `release/packages/SHA256SUMS.txt`

## Regenerate release payload
1. Build release app from project root:
   - `bash ./scripts/build-release.sh`
2. Build and package public payload:
   - `bash ./git/package_release.sh`
