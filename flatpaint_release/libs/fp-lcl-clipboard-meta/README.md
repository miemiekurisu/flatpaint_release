# fp-lcl-clipboard-meta

Type: LCL utility library
License: LGPL v2.1+ with Lazarus modified linking exception (`LICENSE`)

## Units
- `FPClipboardHelpers`
  - clipboard metadata write/read helpers
  - clipboard publish helper with metadata stream

## Dependency profile
- Requires Lazarus LCL (`Clipbrd`, `Graphics`, `LCLType`)
- Build script auto-detects common Lazarus source locations
- Override with `LAZARUS_DIR=/absolute/path/to/lazarus`

## Use from Lazarus/FPC
- Add `src/` to search path
- import `FPClipboardHelpers`

## Smoke build
```bash
bash ./build.sh
```
Compiles `examples/smoke_test.lpr` and validates metadata roundtrip.

## Reliability status
- Standalone LCL smoke build verified in this repository.
