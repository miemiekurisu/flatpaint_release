# Release Smoke Checklist

## Goal
- Provide the Gate-C manual verification list referenced by `docs/ARCHITECTURE_RENOVATION_PLAN.md`.
- Keep this checklist focused on user-visible routes that historically regressed in FlatPaint.

## Preconditions
1. Run `bash ./scripts/run_tests_ci.sh` and confirm zero failures.
2. Run `bash ./scripts/build-release.sh` to refresh `dist/FlatPaint.app`.
3. Launch `dist/FlatPaint.app` on macOS and start from a clean session.

## Manual checks
1. App menu sanity
- Verify only one `FlatPaint` application menu is shown.
- Verify `About FlatPaint` appears in the system app menu and opens normally.

2. Multi-document save flow
- Open or create at least two tabs, make both dirty.
- Trigger `Save All Images` (`Command+Option+S`).
- Confirm each dirty tab is saved; untitled tabs prompt for `Save As`.
- Confirm active-tab focus returns to the tab that was active before `Save All`.

3. Clipboard system bridge
- Copy pixels from FlatPaint, then paste into another macOS app (for example Preview/Notes) and confirm image data is available.
- Copy image data from another app and paste into FlatPaint; confirm a new layer appears.

4. Selection overwrite semantics
- Draw a visible stroke, create a selection intersecting the stroke, then bucket-fill inside selection.
- Confirm fill result overwrites selected-region pixels and does not leave stale pre-fill stroke fragments.

5. Crop semantics
- Draw content, crop to an area that contains visible pixels.
- Confirm cropped result preserves visible content inside crop bounds and does not collapse to transparent-only output.

6. Export options surface
- Open `Save As` for each writer-backed format shown in the dialog (`JPEG/PNG/BMP/TIFF/PCX/PNM/XPM`).
- Confirm format-specific options appear and preview updates without crashes.
- Save at least one `PNG` and one `JPEG`, then reopen both files successfully.

7. Palette/layout bounds
- Enable rulers and drag each floating panel (`Tools`, `Colors`, `History`, `Layers`) near top edges.
- Confirm panels do not overlap ruler bands when rulers are visible, and do not leave workspace bounds when rulers are hidden.

## Exit criteria
1. All manual checks above pass.
2. Any failure is logged in `docs/PROGRESS_LOG.md` and fixed before release tagging.
