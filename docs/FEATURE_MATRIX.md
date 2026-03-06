# Feature Matrix

## Governing rule
- This matrix is code-first: status is derived from implemented behavior in `src/` plus current automated test evidence.
- UI baseline follows `flatpaint_design` + `docs/UI_PARITY_AUDIT.md`.
- paint.net remains a functional intent reference, not the active visual authority.

## Evidence snapshot (2026-03-06)
- Build status: `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- Test status: `bash ./scripts/run_tests_ci.sh` => 270 tests, 0 failures.
- Consequence: regression gate is clean; remaining risk is parity depth and architecture follow-up phases, not immediate failing-suite blockers.

## Status legend
- `Implemented`: code path exists and is used by visible UI route(s).
- `Partial`: usable baseline exists, but parity/polish or route-level test depth is incomplete.
- `Blocked`: currently regressed or contradicted by failing tests.

| Area | Baseline target | Current status | Confidence | Notes |
| --- | --- | --- | --- | --- |
| Workspace shell | Single-window editing workspace with top chrome, canvas, palettes, status bar | Partial | High | Implemented with floating palettes and status strip; visual convergence to Figma baseline still incomplete. |
| Document tabs | Multi-document tab strip with create/switch/close flow | Implemented | High | `AddDocumentTab` / `SwitchToTab` / `CloseDocumentTab` routes are live. |
| File surface | New/Open/Recent/Acquire/Save/Save As/Save All/Print/Exit | Implemented | High | Commands are present in menu and handlers are wired; Save All currently maps to active-shell behavior. |
| Edit surface | Selection + clipboard + undo/redo command set | Implemented | High | Core commands are routed and test-covered in baseline. |
| View surface | Zoom/grid/rulers/units + tab navigation + pan behavior | Partial | High | Major routes are live; remaining parity is around deeper quick-size/status semantics. |
| Image geometry | Crop/resize/canvas size/rotate/flip/flatten | Implemented | High | Core operations are wired and broadly covered by tests. |
| Layers | Add/delete/duplicate/reorder/properties/merge/flatten/lock | Implemented | High | Blend modes, locking, drag reorder, thumbnail-backed list are present; layer offset metadata now exists in core/native persistence and is captured on XCF import in compatibility mode. |
| Selection tools | Rect/ellipse/lasso/wand/move-selection/move-pixels + combine modes | Implemented | High | Selection family is implemented in core + UI routes; `Move Pixels` uses transactional drag-preview/commit/cancel semantics, and selection coverage is now propagated through transform/apply/native round-trip paths with dedicated regression tests. |
| Paint tools | Fill/gradient/pencil/brush/eraser/picker/clone/recolor/crop/pan | Implemented | High | Tool family is broad and functionally usable. |
| Draw tools | Text/line/rect/rounded rect/ellipse/freeform shape | Partial | Medium | Baseline present; advanced node-edit parity for line/curve/object workflows is incomplete. |
| Colors panel | Primary/secondary + alpha-aware edits + fast controls | Partial | Medium | Functional and test-clean after compact-layout width realignment; polish depth remains. |
| Adjustments | Core adjustments set with parameter dialogs | Implemented | High | Adjustment routes are live and integrated with progress/status flow. |
| Effects | Broad built-in effect families + repeat-last-effect | Implemented | High | Large effect set routed through menu and document operations. |
| Export/options | Format-specific export controls | Partial | Medium | Practical controls exist; deeper parity for all format-specific workflows remains open. |
| Compatibility IO | PSD/PDN/XCF/KRA fallback-oriented support | Partial | Medium | Usable baseline with explicit fallbacks; full layered fidelity intentionally out of scope. |
| Menus/shortcuts | Command discoverability and shortcut policy adherence | Implemented | High | Shortcut mapping/hint/cycle regressions in `TFPUIHelpersTests` are closed; suite is green. |
| Iconography | Cohesive icon surface across command/tool/utility controls | Partial | Medium | Runtime icon pipeline exists; final spacing/density and polish remain open. |
| Status bar | Tool/context/readout/progress/zoom controls | Partial | High | Progress and zoom controls are live; some parity behaviors are still under-implemented. |
| Regression health | Stable zero-failure CI-level suite | Implemented | High | Current CI-level run is green at 270 tests, 0 failures. |

## Current insufficient items (must close for release confidence)
1. Route-level parity debt (documented, not fully closed):
- not every visible toolbar/tool route has one-to-one route-level automated coverage
- utility-icon and status quick-action parity still behind documented target

2. UI parity debt against active Figma baseline:
- top/toolbar/palette visual style still requires convergence and consistency polish

3. Compatibility depth debt (explicitly partial):
- layered fidelity for PDN/KRA and advanced XCF remains incomplete by design baseline

4. Architecture tail debt (active pre-A6 work):
- layer offset metadata is persisted, but compositor/tool math is still compatibility-mode (not fully offset-driven)
- stroke history capture cost improved, and lock/history coupling now covers menu/effect + move-pixels + interactive shape/fill/crop commit routes + high-frequency brush/recolor/clone/eraser loops through guarded mutable-surface access; residual A3 debt is now limited to lower-frequency legacy direct-surface commit helpers

## Explicitly deferred
- Third-party plugin ecosystem compatibility
- Full foreign-format round-trip layered fidelity
- RAW workflow
- Cloud collaboration and mobile targets

## Completion policy
- A feature is not considered complete if tests for its visible route are failing.
- When docs and code disagree, docs must be corrected to code-first reality in the same change window.
