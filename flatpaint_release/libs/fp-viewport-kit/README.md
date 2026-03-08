# fp-viewport-kit

Type: Library (pure FPC, no LCL dependency)
License: LGPL v2.1+ with Lazarus modified linking exception (`LICENSE`)

## Units
- `FPZoomHelpers`: zoom presets, step ladder, caption formatting
- `FPViewportHelpers`: viewport coordinate/scroll/zoom math
- `FPMagnifierHelpers`: local-loupe geometry computation
- `FPRulerHelpers`: ruler metrics and major/minor step helpers

## Dependency profile
- FPC RTL only
- no Lazarus/LCL unit dependency

## Use from FPC
```bash
-Fu/path/to/fp-viewport-kit/src
```
Then import needed units.

## Smoke build
```bash
bash ./build.sh
```
Compiles `examples/smoke_test.lpr` into `dist/`.

## Reliability status
- Standalone smoke build verified in this repository.
- Smoke test validates zoom stepping + loupe rect + ruler-step invariants.
