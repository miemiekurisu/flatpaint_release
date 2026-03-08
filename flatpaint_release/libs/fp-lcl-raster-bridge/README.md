# fp-lcl-raster-bridge

Type: LCL bridge library
License: LGPL v2.1+ with Lazarus modified linking exception (`LICENSE`)

## Units
- `FPLCLBridge`: `TRasterSurface <-> TBitmap` conversion and transparentization
- bundled core units for standalone build:
  - `FPColor`
  - `FPSelection`
  - `FPSurface`

## Dependency profile
- Requires Lazarus LCL + LazUtils units
- Build script auto-detects common Lazarus source locations
- You can override path with `LAZARUS_DIR=/absolute/path/to/lazarus`

## Use from Lazarus/FPC
- Add `src/` to unit search path (`-Fu` or Lazarus package/project paths)
- Import `FPLCLBridge` and core units as needed

## Smoke build
```bash
bash ./build.sh
```
Compiles `examples/smoke_test.lpr` against local LCL and validates bitmap conversion path.

## Reliability status
- Standalone LCL smoke build verified in this repository.
