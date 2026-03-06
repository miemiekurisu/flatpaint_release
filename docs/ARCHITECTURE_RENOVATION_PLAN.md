# Architecture Renovation Plan (Lightweight + Stability First)

## 1. Goal and boundaries

### Goal
- Keep FlatPaint as a lightweight editor, while upgrading architecture to reduce tool regressions and stabilize rendering/editing behavior.
- Primary success metric: no blocking tool regressions in release gates.

### Non-goals
- No migration/port of GIMP code.
- No feature explosion during renovation.
- No full non-destructive node-graph redesign in this phase.

## 2. Hard constraints
- Code-first truth: behavior is judged by current implementation + tests.
- Render safety first: every architectural step must preserve visible output stability.
- Incremental change only: one high-risk subsystem change per step.
- No GPL contamination: use GIMP for architecture ideas only.

### GIMP reference anchors used for this plan
- Floating selection transaction lifecycle:
  - `reference/gimp-src/app/core/gimpselection.c`
  - `reference/gimp-src/app/core/gimplayer-floating-selection.c`
  - `reference/gimp-src/app/tools/gimpeditselectiontool.c`
- Selection mask as channel/coverage model:
  - `reference/gimp-src/app/core/gimpselection.c`
  - `reference/gimp-src/app/core/gimpchannel.c`
- Tool-controller and manager split:
  - `reference/gimp-src/app/tools/gimptool.h`
  - `reference/gimp-src/app/tools/tool_manager.h`
- Item geometry and lock state in core model:
  - `reference/gimp-src/app/core/gimpitem.c`
  - `reference/gimp-src/app/core/gimplayer.c`

## 3. Confirmed defect baseline (input to this plan)
This plan addresses defects validated in:
- `docs/ARCHITECTURE_DEFECT_ASSESSMENT.md`
- `docs/ARCHITECTURE_MOD_PLAN_EVALUATION.md`

Highest priority defects:
- A1: move-selected-pixels is destructive during drag (no transactional floating buffer).
- A2: soft-selection data exists but many edit paths reduce to boolean mask behavior.
- A3: lock/editability constraints are route-dependent (mainly UI-guarded).
- A5: stroke history capture still starts from full-layer clone cost. (baseline-at-plan-creation; now partially mitigated in current status)

## 4. Target architecture (lightweight-oriented)

### 4.1 Proposed modules
1. `EditSession` (new core service)
- Lifecycle: `BeginSession -> PreviewStep -> Commit/Cancel`.
- Scope: move-pixels, move-selection, future transform tools.
- Responsibility: isolate temporary mutable state from committed document pixels.

2. `SelectionEngine` (existing + upgraded)
- Keep 8-bit coverage semantics as first-class mask representation.
- Centralize mask combine/transform/coverage sampling.
- Provide one weighted-selection application API used by paint/fill/copy/move paths.

3. `MutationGuard` (new core gate)
- Central lock/background/editability checks for all mutating commands.
- UI routes call the same guarded mutation API; no per-route special casing.

4. `HistoryTransaction` (existing + upgraded)
- Command/session scoped undo grouping.
- Region-delta-first snapshots for brush-like tools.
- Explicit cancellation semantics for interactive tool sessions.

5. `ToolController` layer (new app-level split)
- Move tool state machines out of `TMainForm`.
- Keep `TMainForm` as shell, event dispatch, and view synchronization.

6. `LayerGeometry` model extension (started: metadata path)
- Add per-layer offset metadata in core model.
- Keep compatibility import path able to preserve offsets structurally.
- Keep rendering/edit semantics in compatibility mode until local-surface migration is explicitly planned.

### 4.2 Architecture shape
- UI Shell (`TMainForm`) -> ToolController -> Guarded Document API -> Core services (`EditSession`, `SelectionEngine`, `HistoryTransaction`) -> Surface/Compositor.

## 5. Change strategy (defensive, low-regression)

### Phase 0: Freeze + safety net (mandatory first)
- Freeze new features until Phase 2 completion.
- Establish baseline test pass target for touched suites.
- Add render guard tests before any behavior refactor.

Exit criteria:
- Existing critical tests run green except currently known unrelated failures.
- New render guard tests created and failing only on known defects.

### Phase 1: Infrastructure without behavior changes
- Introduce `EditSession`/`MutationGuard` scaffolding behind current APIs.
- No tool behavior switch yet; only internal plumbing.
- Add invariant checks and telemetry counters in tests.

Exit criteria:
- Zero user-visible behavior delta in regression tests.
- No render output drift in baseline pixel checks.

### Phase 2: Move Selected Pixels transaction migration (A1)
- Route `tkMovePixels` through `EditSession`.
- Drag updates preview buffer, not committed layer pixels.
- `MouseUp` commits; cancel path reverts with no destructive residue.

Exit criteria:
- New transaction tests pass.
- Existing move tests updated and pass with transactional semantics.
- Render and history integrity checks pass.

### Phase 3: Core lock/editability centralization (A3)
- All mutating document commands funnel through `MutationGuard`.
- Remove reliance on UI-only lock protection for correctness.

Exit criteria:
- Lock behavior consistent across tool, menu, and scripted/document API paths.
- New lock consistency test suite passes.

### Phase 4: Selection semantics unification (A2)
- Keep 8-bit mask path and propagate weighted coverage through apply APIs.
- Upgrade save/load behavior where feasible; if serialization unchanged, document explicit compatibility mode.

Exit criteria:
- Feathered selection affects paint/fill/copy/move as expected.
- Selection roundtrip tests define and validate persistence contract.

### Phase 4.5: Layer geometry metadata foundation (A4)
- Introduce per-layer offset metadata into the core layer model.
- Persist offset metadata in native project format and preserve XCF-imported offsets structurally.
- Keep compatibility rendering path unchanged (canvas-stamped payload) to avoid broad tool-regression risk in this phase.

Exit criteria:
- Layer offsets survive clone/history/full snapshot routes.
- Native save/load roundtrip preserves layer offset metadata.
- XCF import records source offsets in layer metadata without breaking current render behavior.

### Phase 5: History optimization (A5)
- Reduce full-layer clone usage at stroke start where safe.
- Prefer transaction/region delta snapshots with strict rollback behavior.

Exit criteria:
- Memory/perf tests show measurable reduction in large-canvas edit scenarios.
- Undo/redo deterministic tests remain green.

### Phase 6: `TMainForm` decomposition (A6, maintainability)
- Extract highest-risk tool flows first (`move`, `selection`, `paint`).
- Keep adapter layer to avoid broad one-shot rewrites.
- Land dedicated tool-session controllers in app layer and lock them with isolated unit tests.

Exit criteria:
- `mainform.pas` complexity reduced without route regression.
- Tool controllers independently unit-testable.

### Current implementation status (2026-03-06 latest)
- Phase 0: complete (baseline gates established).
- Phase 1: partial (infrastructure introduced, now extended with core `MutationGuard` module).
- Phase 2: complete (transactional move-pixels flow + `tool_transaction_tests` passing).
- Phase 3: in progress (core mutation routes expanded with guarded active-layer paste/pixelate-rect/rotate wrappers, and no-op-history cleanup landed for lock-sensitive menu/effect routes via `BeginActiveLayerMutation` / `BeginDocumentMutation`; residual debt remains in direct high-frequency tool-surface mutation paths).
- Phase 4: complete (selection byte-coverage semantics propagated through transform/apply/persistence paths with regression coverage).
- Phase 4.5: in progress (layer offset metadata model + native persistence + XCF metadata preservation landed in compatibility mode).
- Phase 5: in progress (stroke-start full-layer clone path replaced by incremental region capture with long-stroke undo/redo regression coverage).
- Phase 6: complete (top-risk tool flows split into `TMovePixelsController`, `TStrokeHistoryController`, and `TSelectionToolController`, with independent controller-suite coverage).
- A7 follow-up: complete (stored-selection lifecycle moved into core selection-copy routes with regression coverage, removing app-route underwiring).

## 6. Test renovation plan (to prevent repeat render breakage)

### 6.1 Existing suites to keep as hard gates
- `src/tests/fpsurface_tests.pas`
- `src/tests/mainform_integration_tests.pas`
- `src/tests/pipeline_integration_tests.pas`
- `src/tests/tools_move_tests.pas`
- `src/tests/fpdocument_tests.pas`
- `src/tests/fpselection_tests.pas`

### 6.2 New suites to add before risky refactors
1. `tool_transaction_tests.pas`
- Begin/drag/commit/cancel semantics for move-pixels and move-selection.
- Assert no source erasure before commit.

2. `render_regression_tests.pas`
- Deterministic fixture scenes and pixel assertions after tool operations.
- Include selection+move+undo+redo composite checks.

3. `mutation_guard_tests.pas`
- Lock/background invariants across menu-equivalent document commands.
- Guarded begin-mutation history coupling (blocked lock path must not create undo noise).

4. `selection_coverage_pipeline_tests.pas`
- Feather coverage propagation through fill/paint/copy/move.
- Current status: initial coverage checks are now landed in `fpsurface_tests`, `fpselection_tests`, and `integration_native_roundtrip_tests`; dedicated standalone suite file remains a follow-up.

5. `history_transaction_tests.pas`
- Grouped undo atomicity for interactive sessions.
- Cancel path should not leave undo noise or pixel residue.

6. `tool_controller_tests.pas`
- Independent behavioral checks for extracted app-layer tool controllers (`move`, `selection`, `paint` history capture routes).

### 6.3 Test execution gates
- Gate A (local commit): core unit + touched integration tests.
- Gate B (PR): full `scripts/run_tests_ci.sh`.
- Gate C (release candidate): full tests + render regression subset + manual smoke checklist.

## 7. Regression-risk controls
- Strangler approach: old and new path co-exist behind explicit switch during migration.
- Small PRs: one subsystem migration per PR.
- No cross-cutting refactor in same PR as behavioral change.
- Mandatory rollback switch for each migrated tool path until soak period passes.

## 8. Anti-GPL v3 contamination protocol (must-follow)
- Allowed: architecture patterns, workflow decomposition, module boundaries.
- Forbidden: copying code, comments, symbols, enum/function/type names, data tables.
- Process:
1. Read reference code.
2. Write neutral architecture notes in FlatPaint docs.
3. Close reference files.
4. Implement from notes only.
- Keep GIMP checkout under `reference/gimp-src/` and outside build/link paths.

## 9. Deliverables
1. Updated architecture docs:
- `docs/ARCHITECTURE_DEFECT_ASSESSMENT.md` (defect truth)
- `docs/ARCHITECTURE_MOD_PLAN_EVALUATION.md` (pattern fit evaluation)
- `docs/ARCHITECTURE_RENOVATION_PLAN.md` (this implementation plan)

2. Code deliverables by phase:
- new core services (`EditSession`, `MutationGuard`, transaction history adapters)
- tool-controller extraction for top-risk tools
- test suites listed in Section 6

3. Quality deliverables:
- documented migration checklist per PR
- updated test log entries for each phase

## 10. Definition of done
- No blocking tool regressions across release gates.
- Move-selected-pixels path is transactional and cancel-safe.
- Lock/editability invariants are core-enforced, not UI-route dependent.
- Selection behavior contract is explicit and test-enforced.
- Render regression suite remains stable throughout refactor series.
