# Feature Matrix

## Governing rule
- This matrix is code-first: status is derived from implemented behavior in `src/` plus current automated test evidence.
- UI baseline follows `flatpaint_design` + `docs/UI_PARITY_AUDIT.md`.
- paint.net remains a functional intent reference, not the active visual authority.

## Evidence snapshot (2026-03-08)
- Build status: `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- Test status: `bash ./scripts/run_tests_ci.sh` => 363 tests, 0 failures.
- Consequence: P0 anti-aliasing module remains complete; premultiplied boundary correctness fixes, system-clipboard bridge behavior, ruler-aware palette bounds, recolor contiguous mode, About-content embedding (now build-time regenerated from `assets/about/*.txt`), and crop-offset rebasing regressions are all regression-backed.

## Status legend
- `Implemented`: code path exists and is used by visible UI route(s).
- `Partial`: usable baseline exists, but parity/polish or route-level test depth is incomplete.
- `Blocked`: currently regressed or contradicted by failing tests.

| Area | Baseline target | Current status | Confidence | Notes |
| --- | --- | --- | --- | --- |
| Workspace shell | Single-window editing workspace with top chrome, canvas, palettes, status bar | Partial | High | Implemented with floating palettes and status strip; visual convergence to Figma baseline still incomplete. |
| Document tabs | Multi-document tab strip with create/switch/close flow | Implemented | High | `AddDocumentTab` / `SwitchToTab` / `CloseDocumentTab` routes are live. |
| File surface | New/Open/Recent/Acquire/Save/Save As/Save All/Print/Exit | Implemented | High | Commands are present in menu and handlers are wired; `Save All Images` now iterates every dirty tab, prompts only where a path is missing, and returns focus to the original active tab. |
| Edit surface | Selection + clipboard + undo/redo command set | Implemented | High | Core commands are routed and test-covered; edit clipboard now bridges with macOS system clipboard while retaining app-local fallback metadata semantics. |
| View surface | Zoom/grid/rulers/units + tab navigation + pan behavior | Partial | High | Major routes are live and quick-size/status toggle semantics are deterministic + test-backed; ruler visibility now constrains floating palette bounds, and zoom interaction remains global-canvas zoom semantics aligned to Photoshop/GIMP baseline. Remaining gaps are parity polish depth, not baseline behavior absence. |
| Image geometry | Crop/resize/canvas size/rotate/flip/flatten | Implemented | High | Core operations are wired and broadly covered by tests. |
| Layers | Add/delete/duplicate/reorder/properties/merge/flatten/lock | Implemented | High | Blend modes, locking, drag reorder, thumbnail-backed list are present; layer offset metadata + runtime offset semantics are active across compositor and editing routes, with clone/history/native roundtrip/XCF coverage. |
| Selection tools | Rect/ellipse/lasso/wand/move-selection/move-pixels + combine modes | Implemented | High | Selection family is implemented in core + UI routes; `Move Pixels` uses transactional drag-preview/commit/cancel semantics, and selection coverage is now propagated through transform/apply/native round-trip paths with dedicated regression tests. SelectEllipse/SelectPolygon produce SDF fractional 0-255 coverage at edges. |
| Paint tools | Fill/gradient/pencil/brush/eraser/picker/clone/recolor/crop/pan | Implemented | High | Tool family is broad and functionally usable; bucket fill now applies selection-first overwrite semantics when an active selection exists (eliminates residual prior strokes inside selected area), and recolor includes R2 sampling/mode behavior (`Once`/`Continuous`/`SwatchCompat`, `Color/Hue/Saturation/Luminosity/ReplaceCompat`) plus contiguous-mode connectivity control with regression coverage. Shape drawing uses SDF edge AA for smooth 1px transitions. |
| Draw tools | Text/line/rect/rounded rect/ellipse/freeform shape | Implemented | High | Baseline draw workflows are complete; SDF AA applied to DrawEllipse, DrawRoundedRectangle, and FillPolygon. CG bridge available for stroked Bezier curves. Dashed line-style support in preview + committed pixels. |
| Colors panel | Primary/secondary + alpha-aware edits + fast controls | Partial | Medium | Functional and test-clean after compact-layout width realignment; color-wheel SV pane now uses dedicated rendered-hue cache logic to keep foreground/swatch sync immediate during hue scrubs. Remaining work is polish depth. |
| Adjustments | Core adjustments set with parameter dialogs | Implemented | High | Adjustment routes are live and integrated with progress/status flow. |
| Effects | Broad built-in effect families + repeat-last-effect | Implemented | High | Large effect set routed through menu and document operations. |
| Export/options | Format-specific export controls | Partial | Medium | Writer-backed export options now route through one unified dialog for `JPEG/PNG/BMP/TIFF/PCX/PNM/XPM` with live preview and encoded-size sample. Covered parameters include JPEG quality/progressive/grayscale, PNG compression/alpha/grayscale/indexed/16-bit/text-chunk compression, BMP true-color bit depth + resolution metadata, TIFF CMYK-save policy, PCX compression, PNM binary/depth/full-width(16-bit) mode, and XPM palette encoding controls. Remaining gap: backend-limited options (for example JPEG subsampling) are explicitly marked, and BMP paletted/RLE export is intentionally clamped to stable true-color output in the current RGBA pipeline. |
| Compatibility IO | PSD/PDN/XCF/KRA fallback-oriented support | Partial | Medium | Usable baseline with explicit fallbacks; XCF remains the deepest layered compatibility route, KRA/PDN remain flattened fallback-oriented imports. Licensing-risk posture is conservative: no private/proprietary-code integration, no GPL code reuse, no full-PDN round-trip commitment without stable public format documentation. |
| Menus/shortcuts | Command discoverability and shortcut policy adherence | Implemented | High | High-use shortcut audit is closed and test-backed, and long-tail route coverage was expanded again (including selection lifecycle routing beyond keyboard switching, with tool-classified keep/clear behavior); About text payload is now compile-time synced from `assets/about/*.txt` during build/test flows. Residual long-tail opportunities remain non-blocking polish. |
| Iconography | Cohesive icon surface across command/tool/utility controls | Implemented | High | Runtime icon pipeline now ships complete rendered icon assets in bundle (`1x` + `@2x`), loader prefers `@2x` with safe `1x` fallback, and previously fallback-only mapped tools (`Move Pixels`/`Mosaic`) now resolve asset-backed `pointer`/`grid-2x2` icons. Remaining work is visual polish, not missing asset-chain coverage. |
| Rendering quality | Premultiplied alpha, SDF edge AA, CG bridge, Retina DPI | Implemented | High | Premultiplied alpha pipeline (GIMP/Krita-aligned), SDF 1px smooth edge AA on ellipse/rounded rect/polygon shapes and selections, Core Graphics offscreen AA bridge for stroked curves, Retina-aware document sizing + CG high-quality interpolation. 16 dedicated tests. |
| Status bar | Tool/context/readout/progress/zoom controls | Partial | High | Progress and zoom controls are live; some parity behaviors are still under-implemented. |
| Regression health | Stable zero-failure CI-level suite | Implemented | High | Current CI-level run is green at 363 tests, 0 failures. |

## Current insufficient items (post-P0, still important before release)
1. Residual route-level coverage opportunities:
- most visible high-use and current P1-target routes are covered, but exhaustive one-to-one automation for every low-frequency control is still not complete
- utility-icon and status quick-action coverage depth can still be expanded incrementally

2. UI parity debt against active Figma baseline:
- top/toolbar/palette visual style still requires convergence and consistency polish

3. Compatibility depth debt (explicitly partial):
- layered fidelity for PDN/KRA and advanced XCF remains incomplete by design baseline

4. Architecture maintainability debt:
- `mainform` still carries high orchestration coupling in non-tool areas despite controller extraction
- further modularization and route-level coverage expansion remain desirable, but no longer block P0 architecture semantics

## Explicitly deferred
- Third-party plugin ecosystem compatibility
- Full foreign-format round-trip layered fidelity
- RAW workflow
- Cloud collaboration and mobile targets

## Completion policy
- A feature is not considered complete if tests for its visible route are failing.
- When docs and code disagree, docs must be corrected to code-first reality in the same change window.
