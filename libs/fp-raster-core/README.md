# fp-raster-core

Type: Library (pure FPC, no LCL dependency)
License: LGPL v2.1+ with Lazarus modified linking exception (`LICENSE`)

## Units
- `FPColor`: RGBA helpers, premultiplied-alpha math, blend operations
- `FPSelection`: byte-coverage selection mask + geometric selection transforms
- `FPSurface`: raster drawing/fill/effect primitives on `TRasterSurface`

## Dependency profile
- FPC RTL only
- no Lazarus/LCL unit dependency

## Use from FPC
Add this library source path to your compile command:
```bash
-Fu/path/to/fp-raster-core/src
```
Then import units directly in your program.

## Smoke build
```bash
bash ./build.sh
```
This compiles `examples/smoke_test.lpr` into `dist/`.

## Reliability status
- Standalone smoke build verified in this repository.
- Smoke test performs create/draw/read pixel path validation.
