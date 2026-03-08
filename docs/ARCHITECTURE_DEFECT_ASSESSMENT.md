# Architecture Defect Assessment (Code-First, GIMP-Aligned Direction)

## Scope and method
- Date: 2026-03-06
- Scope: software architecture defects only (not CPU architecture), with focus on selection/move/compositing/history/layer model.
- Method: line-level review of current implementation in `src/core` and `src/app`; no code changes in this pass.
- Source-of-truth: implemented behavior in current codebase.

## Revalidation status
- Rechecked in multiple passes on 2026-03-06 after publication.
- All cited evidence locations were replayed and still matched their defect claims at the time of review.

## Implementation delta (2026-03-08 latest)
- This document keeps the pre-renovation defect baseline as historical input.
- Since that baseline review, seven items have moved:
  - **A1 (move-pixels transaction model):** materially mitigated by the transactional move-pixels session now covered by `tool_transaction_tests` (including drag-preview no-mutation, escape-cancel restore, and tool-switch cancel restore guards).
  - **A2 (selection coverage pipeline):** materially mitigated by byte-coverage propagation across selection transform paths, weighted selection-aware surface apply paths (including gradient and radial-gradient masked blend routes), native byte-mask persistence (`FPDOC04` legacy-compatible load path), and coverage-preserving magic-wand add/subtract merge semantics plus regression tests.
  - **A3 (lock/editability invariants):** materially mitigated by core `FPMutationGuard` adoption, expansion of guarded core mutation APIs for previously UI-direct routes (`PasteSurfaceToActiveLayer`, `PixelateRect`, active-layer rotate wrappers), guard-aware history entry APIs (`BeginActiveLayerMutation` / `BeginDocumentMutation`) now used by lock-sensitive menu/effect and interactive shape/fill/crop commit routes to prevent no-op undo noise, guard-coupled move-pixels controller commit/begin-session flow, and guard-coupled writable-surface acquisition (`MutableActiveLayerSurface`) now used by high-frequency brush/recolor/clone/eraser apply loops; route-level UI-edge locked-layer blocking regression checks are additionally covered in `pipeline_integration_tests`.
  - **A4 (layer geometry semantics):** materially mitigated; metadata foundation plus runtime semantic activation are complete (offset-aware compositor + tool/local-selection mapping + offset-preserving XCF/native routes) with regression coverage.
  - **A5 (history capture cost):** materially mitigated by replacing stroke-start full-layer clone with incremental pre-stroke region capture, switching move-pixels commit to dirty-rect + selection-aware region snapshots, and converging stroke/move transaction routes on core `TRegionHistoryTransaction`.
  - **A6 (mainform decomposition):** partially mitigated by extracting high-risk tool routes (`move`, `selection`, `paint history`) into dedicated app-layer controllers with independent regression tests, plus ongoing extraction of shared non-render UI policy logic into helper units (`tool-switch deselect policy`, `tool-option switch memory policy`, `blank-click auto-deselect policy`, `temporary-pan state transitions`, `tab-cycle index policy`) with focused helper tests; native magnify callback routing has also moved from process-global `GMainForm` coupling to per-view context installation/uninstallation, reducing global callback/state coupling in the app shell.
  - **A7 (stored-selection route closure):** materially mitigated by moving `StoreSelectionForPaste` into core selection-copy routes (`CopySelectionToSurface`/`CopyMergedToSurface`), eliminating app-route dependency.
- Defects still treated as open architecture work in the active plan: **A6 (mainform orchestration coupling)**.

## Executive summary
FlatPaint is functionally broad, and previously critical selection/edit-transaction architecture defects are materially mitigated.
The historically largest defect (`Move Selected Pixels` destructive drag behavior) has been mitigated by transactional edit-session behavior; current highest-risk open architecture gap is residual high-coupling UI orchestration risk (A6), not unresolved P0 semantic correctness.

Current architecture has reusable strengths (separate core units, region-history transaction service, mutation-guarded routes, active offset-aware layer semantics).
The remaining release-grade architecture priority is maintainability decomposition and long-tail route hardening.

## Critical defect list
The sections below preserve the originally validated defect evidence snapshot for traceability.
Current status for each item is defined by the **Implementation delta** section above.

### A1. No floating selection transaction layer for move-pixels operations (P0)
- Evidence:
  - `tkMovePixels` pushes history once, then mutates per mouse move: `src/app/mainform.pas:9653`, `src/app/mainform.pas:9723`
  - Core move path copies then erases then writes directly to active layer: `src/core/fpsurface.pas:3168`, `src/core/fpsurface.pas:3170`, `src/core/fpsurface.pas:3181`
  - Background-layer path also clears source region immediately: `src/core/fpdocument.pas:1002`
- Architectural problem:
  - No explicit "edit transaction surface" (floating selected pixels) with commit/cancel anchor.
  - In-drag operations are destructive to document state rather than staged.
- User-visible risk:
  - Data loss patterns during interrupted drags or multi-step edits.
  - Harder to add non-destructive transform handles later.

### A2. Soft selection mask exists in data model but collapses to boolean in edit pipeline (P0)
- Evidence:
  - Selection stores byte coverage and feather writes 0..255: `src/core/fpselection.pas:194`, `src/core/fpselection.pas:271`
  - Primary accessors degrade to boolean semantics: `src/core/fpselection.pas:167`, `src/core/fpselection.pas:174`
  - Paint/fill/erase paths gate on boolean selection membership: `src/core/fpsurface.pas:406`, `src/core/fpsurface.pas:3052`
  - Native format persistence also stores only 0/1 selection: `src/core/fpnativeio.pas:86`, `src/core/fpnativeio.pas:158`
- Architectural problem:
  - Selection subsystem advertises soft coverage but most mutation routes consume only binary inclusion.
- User-visible risk:
  - Feathered selection behavior cannot be consistently preserved through editing and save/load cycles.

### A3. Editability/lock invariants are enforced at UI edge instead of core domain layer (P1)
- Evidence:
  - UI mouse-down guard still exists: `src/app/mainform.pas` pointer-down editability gate.
  - Core now contains guard-wrapped mutation routes for formerly UI-direct operations:
    - `PasteSurfaceToActiveLayer`
    - `PixelateRect`
    - `RotateActiveLayer90Clockwise / RotateActiveLayer90CounterClockwise / RotateActiveLayer180`
  - Core now provides guard-coupled history begin APIs:
    - `BeginActiveLayerMutation`
    - `BeginDocumentMutation`
    and `mainform` lock-sensitive menu/effect routes are routed through them.
  - `TMovePixelsController.Commit` now uses guard-aware begin-mutation + core mutation APIs instead of direct layer-surface commit writes.
  - Pointer commit routes for fill/shape/crop and pending line segment now start via begin-mutation guards instead of unconditional `PushHistory`.
  - High-frequency brush/recolor/clone/eraser apply loops now acquire writable surface through core `MutableActiveLayerSurface` entry before writing.
  - Regression coverage expanded in `src/tests/mutation_guard_tests.pas` (`LockedActiveLayerBlocksSurfacePasteAndRotateRoutes`, `MutableActiveLayerSurfaceRespectsLockState`).
- Architectural problem:
  - Route consistency is materially improved for current code paths, with mutation authorization now centralized at core entry points used by runtime tool/menu/controller routes.
- User-visible risk:
  - Reduced versus baseline; current residual risk is mostly future-regression risk if new mutation routes bypass established guard-coupled core entry points.

### A4. Layer geometry semantics were compatibility-only at baseline (historical snapshot; now mitigated) (P1)
- Evidence:
  - `TRasterLayer` now carries `OffsetX/OffsetY` metadata in core model.
  - XCF parser reads layer offsets and importer now stores them in layer metadata.
  - Compatibility import path still stamps payload into full-canvas surfaces; compositor and paint routes are not yet driven by offset metadata.
- Architectural problem:
  - Geometry metadata exists, but runtime edit/composite semantics still assume canvas-aligned layer surfaces.
  - Offset metadata is not yet a fully active model invariant across rendering and tool math.
- User-visible risk:
  - Interchange fidelity improves structurally, but future local-surface/offset workflows remain constrained until semantic migration is completed.

### A5. Undo architecture hybrid baseline (now materially mitigated) (P1 historical)
- Evidence:
  - Full history snapshot clones full document: `src/core/fpdocument.pas:445`, `src/core/fpdocument.pas:447`
  - Brush-like stroke capture now incrementally snapshots touched region before mutation instead of cloning full active layer at stroke begin.
  - Undo grouping/capture policy for interactive tools is still orchestrated directly in `TMainForm`.
- Architectural problem:
  - Baseline concern was hybrid transaction orchestration across route families; current status is materially mitigated by converging brush-like stroke and move-pixels undo capture on core region transaction services, including selection-aware snapshot mode where required.
- User-visible risk:
  - Substantially reduced versus baseline; remaining risk is mainly future-route governance (new interactive tools should reuse the same transaction service rather than reintroduce ad-hoc history paths).

### A6. Main form is a high-coupling orchestration monolith (partially mitigated, P2)
- Evidence:
  - `src/app/mainform.pas` remains a very large shell (~12k lines in current workspace audit).
  - Former global native magnify callback coupling through `GMainForm` has been removed; callback dispatch now uses per-view context passed through `FPMagnifyBridge` install/uninstall APIs.
  - High-risk tool session logic is now split into dedicated controllers:
    - `src/app/fptoolcontrollers.pas` (`TMovePixelsController`, `TStrokeHistoryController`, `TSelectionToolController`)
    - `src/tests/tool_controller_tests.pas` (independent controller regression coverage)
  - Additional non-render policy extraction now lives in `src/app/fpuihelpers.pas` and is covered in `src/tests/fpuihelpers_tests.pas` (tool-switch selection retention/deselect, tool-option switch memory persistence, blank-click auto-deselect policy, temporary pan state transitions, and tab-cycle index policy).
- Architectural problem:
  - Tool-state coupling was reduced for top-risk flows, but rendering/IO/panel choreography and many command routes still live in one form class.
- User-visible risk:
  - Regression risk is lower in extracted tool flows, but non-tool orchestration changes can still have broad blast radius.

### A7. Selection store/paste flow was underwired at app layer (mitigated, P2)
- Evidence:
  - Stored-selection API exists in core and is now called from core copy routes:
    - `StoreSelectionForPaste`, `CopySelectionToSurface`, `CopyMergedToSurface` in `src/core/fpdocument.pas`
  - App path still performs selection paste command dispatch:
    - `src/app/mainform.pas:10887` (`PasteSelectionClick`)
  - Regression coverage now validates copy routes store selection for replace-paste:
    - `src/tests/fpdocument_tests.pas` (`CopySelectionStoresSelectionForPasteRoute`, `CopyMergedStoresSelectionForPasteRoute`)
- Architectural problem:
  - Original issue was lifecycle ownership at app layer; core now owns selection-store contract for selection-copy routes.
- User-visible risk:
  - Reduced for copy/cut/copy-merged workflows; future new copy-like routes must still use the same core APIs to preserve this guarantee.

## Positive architecture assets to keep
- Core/unit split (`FPDocument`, `FPSurface`, `FPSelection`, format IO units) is a useful base for refactoring rather than rewrite.
- Region-history primitive already exists (`PushRegionHistory`) and can be evolved into transactional undo blocks.
- Tool catalog and command routing are broad enough to validate architecture improvements with real workflows.

## GIMP-aligned target architecture (concept-only, no code borrowing)

### Target principles
- Transactional edits: stage mutable operations in a temporary edit context and commit atomically.
- Selection as coverage field: keep 0..255 mask semantics through paint/composite/history/serialization.
- Separation of concerns: document model, projection/compositor, and UI interaction loops should be independently testable.
- Geometry-first layers: layer position/extent must be explicit metadata, not implied by stamped pixels.

### Recommended module split
1. `edit_session` domain service:
- owns transient buffers for move/transform/selection edits
- provides `begin -> preview -> commit/cancel` lifecycle

2. `selection_pipeline` service:
- central coverage math and mask transforms
- exposes weighted-mask compositing helpers

3. `document_command_guard` layer:
- enforces lock/editability/background invariants for every mutating command

4. `layer_geometry` model extension:
- per-layer offset/local bounds maintained in core model
- compositor reads geometry; importers map source offsets into metadata, not destructive stamp-only conversion

5. `history_transaction` service:
- records command-scoped delta blocks, not route-scoped ad hoc snapshots

6. `ui_tool_controller` split from form:
- keep `TMainForm` as shell/view binding only
- move tool finite-state machines into dedicated controllers

## GPL contamination control policy (must follow)
- Use GIMP source only as architecture reference material; do not copy code or comments.
- Do not reuse GIMP/Krita identifier names for types/functions/variables.
- Produce neutral design notes first, then implement independently from those notes.
- Keep any third-party source checkout under `reference/` and outside build/link paths.
- Never include GPL source fragments in project docs, tests, or code comments.

## Optional local reference checkout workflow
If deeper architecture study is needed, place a local GIMP source checkout in:
- `reference/gimp-src/`

Recommended practice:
- keep it read-only for this project
- do architecture note extraction into FlatPaint-owned docs
- avoid direct side-by-side code translation work

## Exit criteria for closing the critical architecture gap set
- `Move Selected Pixels` uses a transactional floating buffer workflow with explicit commit/cancel semantics.
- Selection coverage is preserved as weighted mask through paint/edit/save/load paths.
- Lock/editability checks are enforced centrally in core mutation services.
- Layer offset metadata is first-class in document model and preserved by compatibility import paths.
- Undo memory profile improves from full-layer-start snapshots to bounded transaction deltas for brush-like edits.
