# Product Requirements Document

## Product name
FlatPaint

## Product mission
Build a native macOS raster editor that is practical for daily image editing workflows, with stable multi-layer editing, predictable command surfaces, and fast iteration.

## Product positioning
FlatPaint is a lightweight desktop editor for screenshots, UI assets, annotation, quick retouching, and small composites.
It is not a Photoshop replacement, but it must feel complete and dependable for common editing tasks.

## Source-of-truth order
1. Implemented code behavior in this repository (`src/core`, `src/app`, `src/cli`).
2. Automated tests and current test run status (`src/tests`, `docs/TEST_LOG.md`).
3. Product docs (this PRD, feature matrix, audit docs).

If docs conflict with code, docs must be updated; code is authoritative for current capability.

## Reference standards
### UI and visual baseline (authoritative)
- `flatpaint_design/`
- `docs/UI_PARITY_AUDIT.md`

### Functional intent baseline
- Existing FlatPaint code behavior
- paint.net command semantics and naming as a secondary compatibility reference

### Backend and implementation reference
- GIMP/Krita may inform algorithm and IO decomposition only.

## Intentional UI deltas from Figma baseline
The current product intentionally keeps several behavior-first differences:
- A dedicated second row for tool options (not collapsed into a single top row).
- Four floating utility palettes (`Tools`, `Colors`, `History`, `Layers`) as first-class workspace elements.
- A persistent document tab strip for multi-document workflows.
- A dense status strip with operational readouts and zoom controls.

These are explicit product decisions and not treated as parity regressions.

## Target users
- Developers editing screenshots, icons, and release assets
- Designers needing quick edits without heavy suites
- Casual users performing practical layered edits and exports

## Product principles
- Native macOS desktop interaction first
- Code-backed command surfaces (no decorative placeholders)
- Deterministic, testable editing core
- Explicit fallback behavior for partial format compatibility
- Honest status tracking: build/test failures are never hidden by optimistic percentages

## In-scope feature surface
### Workspace and interaction
- Single-window editor with tabbed documents
- Floating child palettes: tools, colors, history, layers
- Top quick-action row + separate tool-options row
- Canvas viewport with rulers, grid toggle, and zoom controls
- Status strip with live context and render progress
- Menu bar routes and keyboard shortcuts for primary workflows

### Editing core
- Layered raster document model independent from UI state
- Deterministic undo/redo history for document mutations
- Layer operations: visibility, opacity, blend modes, reorder, duplicate, rename, merge down, flatten, lock
- Geometry and view operations: crop, resize, rotate, flip, pan/zoom

### Tools
- Selection tools: rectangle, ellipse, lasso, magic wand, move selection, move selected pixels
- Paint/utility tools: pan, crop, pencil, brush, eraser, fill, gradient, color picker, clone stamp, recolor
- Draw tools: text, line/curve (baseline), rectangle, rounded rectangle, ellipse, freeform shape

### Adjustments and effects
- Adjustments baseline: auto-level, brightness/contrast, curves (baseline), hue/saturation, levels, posterize, invert, grayscale, black and white, sepia
- Effects baseline: blur/noise/distort/photo/render/stylize families, repeat-last-effect

### File and compatibility workflows
- Native document open/save/save-as
- Export to common raster formats with explicit options
- Import/open routes for raster and compatibility formats with explicit fallback behavior
- Clipboard-based copy/paste workflows

## Explicit non-goals
- Third-party plugin execution
- Full PSD/PDN/XCF/KRA round-trip layered fidelity
- RAW pipeline
- Cloud collaboration
- Mobile builds

## Functional requirements
1. The app must launch into a usable editing workspace.
2. A user must be able to open/import, edit, and export a real image through the UI.
3. Document mutations must be undoable; view-only state (zoom/pan/grid/rulers) must not pollute document history.
4. Visible commands must map to real code paths.
5. Shortcut behavior must follow documented policy and remain test-covered.
6. Partial format support must be explicit and non-silent.
7. Feature status reporting must follow code-and-test reality.

## Non-functional requirements
- Buildability: repository scripts produce a runnable app bundle.
- Stability: regression suite should pass before release candidates.
- Performance: common interactions should feel immediate for typical document sizes.
- Maintainability: feature work should preserve separation between core image logic and UI routing.

## Current implementation snapshot (as of 2026-03-07)
- App build: passes via `bash ./scripts/build.sh`.
- Regression run: `279` tests executed, `0` failures (regression-clean).
- Product status: functionally broad and test-clean; architecture renovation now includes transactional move-pixels, coverage-aware selection pipeline, completed Phase-4.5 layer-offset metadata foundation (clone/history/native/XCF metadata routes), and completed Phase-5 history optimization with unified core region-transaction routing (stroke + move-pixels, including selection-aware undo/redo snapshots), plus guard-coupled mutation routes across menu/controller/interactive/high-frequency apply paths. Remaining UAT risk is concentrated in parity/polish depth and A4 offset-semantics migration.

## UAT gate
FlatPaint is UAT-ready only when all are true:
- App launches and is stable in smoke runs.
- End-to-end open/edit/export workflows pass in manual validation.
- Primary workflows are reachable from visible controls.
- Unit/integration/regression suites pass with zero failures.
- Feature matrix gaps are explicit and current.
- Docs and code are aligned with no stale baseline conflicts.
