# Architecture Defect Assessment (Code-First, GIMP-Aligned Direction)

## Scope and method
- Date: 2026-03-06
- Scope: software architecture defects only (not CPU architecture), with focus on selection/move/compositing/history/layer model.
- Method: line-level review of current implementation in `src/core` and `src/app`; no code changes in this pass.
- Source-of-truth: implemented behavior in current codebase.

## Revalidation status
- Rechecked in multiple passes on 2026-03-06 after publication.
- All cited evidence locations were replayed and still matched their defect claims at the time of review.

## Executive summary
FlatPaint is functionally broad, but several deep architectural gaps remain in selection and edit-transaction design.
The largest defect is destructive `Move Selected Pixels` behavior without a floating transactional buffer layer, which can alter source pixels during drag rather than at commit.

Current architecture has reusable strengths (separate core units, region-history primitive), but release-grade editor reliability will require:
- transactional edit sessions for selection/pixel move
- true soft-selection coverage propagation
- model-layer invariants (lock/editability) enforced in core, not only in UI routes
- layer geometry metadata (offset/local bounds) kept as first-class state

## Critical defect list

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
  - UI mouse-down guard checks lock state: `src/app/mainform.pas:9413`
  - Core mutation methods generally call `ActiveLayer.Surface.*` directly with no lock guard: `src/core/fpdocument.pas:1086` through `src/core/fpdocument.pas:1238`
- Architectural problem:
  - Business invariants depend on entry route.
  - Menu/effect routes and future automation paths can bypass lock behavior unless each route re-checks manually.
- User-visible risk:
  - Inconsistent lock semantics across tools vs commands.

### A4. Layer geometry model lacks offset metadata; import offsets are flattened (P1)
- Evidence:
  - `TRasterLayer` has no offset fields: `src/core/fpdocument.pas:49`
  - XCF parser reads layer offsets: `src/core/fpxcfio.pas:263`, `src/core/fpxcfio.pas:264`
  - Import stamps offset pixels into full-canvas surface, losing structural offset state: `src/core/fpxcfio.pas:731`
- Architectural problem:
  - Layer position is not first-class state in document model.
  - Compatibility adapters cannot preserve higher-fidelity layer geometry semantics.
- User-visible risk:
  - Reduced interchange fidelity and constrained future transform workflow.

### A5. Undo architecture is hybrid but still full-layer-heavy at stroke start (P1)
- Evidence:
  - Full history snapshot clones full document: `src/core/fpdocument.pas:445`, `src/core/fpdocument.pas:447`
  - Stroke path clones full active layer first, crops later: `src/app/mainform.pas:9358`, `src/app/mainform.pas:9398`, `src/app/mainform.pas:9401`
- Architectural problem:
  - Region history exists, but capture strategy is still expensive at stroke begin.
- User-visible risk:
  - Memory and latency pressure on large documents/high-frequency brush workflows.

### A6. Main form is a high-coupling orchestration monolith (P2)
- Evidence:
  - `src/app/mainform.pas` is ~11.8k lines (current workspace audit).
  - Global callback coupling through `GMainForm`: `src/app/mainform.pas:682`, `src/app/mainform.pas:694`
- Architectural problem:
  - Tool state, rendering, IO, history routing, panel choreography, and command wiring are concentrated in one class.
- User-visible risk:
  - Regression probability increases with each feature; difficult to isolate behavioral contracts.

### A7. Selection store/paste flow appears underwired at app layer (P2)
- Evidence:
  - Stored-selection API exists in document core: `src/core/fpdocument.pas:1251`
  - App path checks and pastes stored selection: `src/app/mainform.pas:10689`
  - No app-layer call site found for `StoreSelectionForPaste` in current audit.
- Architectural problem:
  - Command surface can expose a route whose backing lifecycle is incomplete.
- User-visible risk:
  - "Paste Selection (Replace)" can behave as a dormant or confusing command depending on prior state.

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
