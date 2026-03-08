# Engineering Event Book

Use one short block per issue.

## Template
- Problem: what failed from the user or developer perspective
- Core error: the main error text or direct symptom
- Investigation: how the issue was located
- Fix: what changed to resolve it
- Repeat count: `This issue has occurred N time(s)`

## Scope note
- This file tracks the active FPC/Lazarus implementation era.
- Pre-FPC/Swift-era historical entries are archived in `docs/archive/ENGINEERING_EVENT_BOOK_PRE_FPC.md`.

## 2026-03-05
- Problem: Drawing tools (pencil, rectangle, etc.) appeared to work (visual feedback during drag) but strokes never "landed" on canvas. Undo history only showed 0 and 1 entries, never growing to 2, 3, 4.
- Core error: `FHistory.Count` reset to 0 between every `PushHistory` call despite no explicit `ClearHistory` invocation.
- Investigation: Created `TDebugObjectList` subclass overriding `Notify` to log all ADDED/EXTRACTED/DELETED events with stack traces. Caught an EXTRACTED notification immediately after ADDED — proving `Undo` was called right after `PushHistory`. Stack trace led to `RefreshHistoryPanel` → `FHistoryList.ItemIndex := UndoCount` → macOS Cocoa fires `OnClick` → `HistoryListClick` → `FDocument.Undo`. The Cocoa widgetset fires `TListBox.OnClick` when `ItemIndex` is set programmatically (unlike Win32/GTK). Tests never caught this because `CreateForTesting` sets `FHistoryList := nil`, so `RefreshHistoryPanel` exits early.
- Fix: In `RefreshHistoryPanel`, disconnect `FHistoryList.OnClick` (set to nil) before programmatic `ItemIndex` update, reconnect in `finally` block. One-line root cause, ~5-line fix.
- Repeat count: This issue has occurred 1 time(s)

## Note
- `docs/EXPERIENCES.md` is now the primary cumulative issue log. This file remains only as the earlier session-local record.

## 2026-03-08 (anti-aliasing module: premultiplied alpha + SDF AA + CG bridge + Retina DPI)
- Problem: shape edges (ellipse, rounded rect, polygon) were aliased with hard staircase edges; selection masks were binary 0/255; pixel pipeline used straight alpha incompatible with CG/vImage; Retina displays showed poor rendering quality due to 1:1 document-to-pixel resolution and uncontrolled upscale interpolation.
- Core error: binary inside/outside tests produced no sub-pixel coverage; straight alpha format blocked zero-copy CG buffer sharing; display pipeline nearest-neighbor upscale on Retina destroyed document-level AA fringe.
- Investigation: (1) researched GIMP source code for SDF AA approach (`gimp-gegl-mask-combine.cc`), (2) evaluated FPC/Lazarus graphics libraries (BGRABitmap, AggPas, Cairo — all rejected), (3) audited Apple framework FPC bindings (CG fully available, vImage needs bridge, Metal needs bridge), (4) diagnosed display pipeline as critical path for visible quality on Retina.
- Fix: (1) migrated entire pipeline to premultiplied alpha (`Premultiply`/`Unpremultiply` helpers, `BlendNormal` rewrite, all I/O boundaries, all erase ops, compositor, 26+ filters), (2) implemented SDF edge AA (`SDFCoverage`, `EllipseSDF`, `RoundedRectSDF`, `DistToSegment`) for DrawEllipse, DrawRoundedRectangle, FillPolygon, SelectEllipse, SelectPolygon, (3) created CG offscreen rendering bridge (`fp_cgrender.m` + `fpcgrenderbridge.pas`), (4) added Retina DPI detection (`FPGetScreenBackingScale`) and CG interpolation quality control (`FPSetInterpolationQuality`), (5) fixed first-launch centering race condition. 327 tests, 0 failures.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-05 (UI/UX polish pass)
- Problem: 8 user-reported UI/UX issues including missing Preferences menu, wrong close-unsaved-tab logic, effect dialogs lacking sliders, layer list layout ordering, no layer lock feature, toolbar spacing too tight, and unreachable i18n settings
- Core error: the Settings dialog existed but was unreachable from the menu bar; close-tab used discard-first logic; effect parameter dialogs had no TTrackBar sliders; layer list lacked lock icon column; `TRasterLayer` had no lock property; toolbar option row overlapped with first row
- Investigation: systematic sub-agent investigation of all 8 reported issues, then sequential implementation of each fix
- Fix: (1) Added Preferences... to Edit menu with Cmd+, shortcut ($BC + ssMeta); (2) Changed close-tab to Yes=save, No=discard, Cancel=abort pattern; (3) Added TTrackBar sliders to 3 effect dialogs (hue/sat, brightness/contrast, levels); (4) Rewrote layer list layout as lock→eye→thumbnail→name with explicit position constants; (5) Full layer lock: FLocked property in TRasterLayer, lock icon, click-to-toggle, menu item, panel button, paint guard; (6) Adjusted toolbar spacing constants (+4px); (7) Verified i18n code was correct — root cause was missing Preferences menu
- Repeat count: This issue has occurred 1 time(s)
