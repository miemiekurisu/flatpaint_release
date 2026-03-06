# Architecture Modification Plan Evaluation (Lightweight Target)

## Scope
- Date: 2026-03-06
- Goal: evaluate the existing lightweight-architecture improvement plan against current FlatPaint code and GIMP architecture references.
- Constraint: architecture reference only; no GPL code/name/comment reuse.

## Defect revalidation result (multi-pass)

`docs/ARCHITECTURE_DEFECT_ASSESSMENT.md` was revalidated in three passes:
1. Extracted all cited evidence locations and replayed code lines.
2. Confirmed each cited line still matches described behavior.
3. Ran assertion checks for ambiguous claims.

Conclusion: defects A1/A2/A3/A7 moved to mitigated or materially mitigated status, A4/A5 remain partial-mitigation architecture tails, and A6 is partial-mitigation.

## Implementation delta (2026-03-06 latest)
- This evaluation section above is preserved as the pre-renovation baseline verdict.
- Current code status after latest implementation pass:
  - **A1**: mitigated by transactional move-pixels workflow (`tool_transaction_tests` green).
  - **A2**: materially mitigated by byte-coverage propagation through selection transforms, weighted selection-aware apply paths, and native mask persistence (`FPDOC04`, legacy-compatible load) with regression tests.
  - **A3**: materially mitigated by core `FPMutationGuard`, additional guarded core APIs for formerly UI-direct mutations (active-layer paste/pixelate-rect/rotate routes), guard-coupled history begin APIs (`BeginActiveLayerMutation` / `BeginDocumentMutation`) now used by lock-sensitive menu/effect and interactive fill/shape/crop routes to prevent no-op history entries, move-pixels controller commit/begin-session migration to guarded core mutation APIs, and guard-coupled writable-surface acquisition (`MutableActiveLayerSurface`) now used by high-frequency brush/recolor/clone/eraser apply loops.
  - **A4**: partially mitigated by layer offset metadata in core model, native persistence, and XCF metadata capture (compatibility render mode retained).
  - **A5**: partially mitigated by replacing brush-like stroke-start full-layer clone with incremental region capture plus long-stroke undo/redo regression coverage.
  - **A6**: partially mitigated by extracting high-risk tool routes into `TMovePixelsController`, `TStrokeHistoryController`, and `TSelectionToolController`, with dedicated `tool_controller_tests`.
  - **A7**: materially mitigated by centralizing selection-store lifecycle in core copy routes (`CopySelectionToSurface` / `CopyMergedToSurface`) with route-level regression tests.
- Remaining priority architecture work still aligns with the plan sequence:
  - **A4 semantic migration tail** (offset-aware compositor/tool math),
  - **A5 transaction-service extraction tail** (reduce app-layer history orchestration).

### Additional assertion checks
- `StoreSelectionForPaste()` usage:
  - Found only declaration/implementation in core.
  - No app-layer call site found in current `src/app` routes.
- Core lock guards:
  - Current `TImageDocument` mutation methods are now guard-gated through centralized mutation checks.
  - Guard-aware begin-mutation APIs now couple lock checks and history push, eliminating routed no-op-history noise.
  - High-frequency and commit-time tool writes now use guard-coupled mutable-surface acquisition in core; current app runtime routes no longer perform direct pixel mutation writes in `mainform`.

## GIMP architecture reference findings (pattern-level only)

### 1) Selection move/edit is transactional, not per-mouse-move destructive
- Floating selection creation is wrapped in undo grouping and explicit attach flow:
  - `reference/gimp-src/app/core/gimpselection.c:902-936`
- Floating selection anchor/commit has explicit grouped operation:
  - `reference/gimp-src/app/core/gimplayer-floating-selection.c:126-157`
- Edit-selection tool starts undo group at start, ends at release, and can cancel by undoing the group:
  - `reference/gimp-src/app/tools/gimpeditselectiontool.c:249`
  - `reference/gimp-src/app/tools/gimpeditselectiontool.c:439`
  - `reference/gimp-src/app/tools/gimpeditselectiontool.c:441-445`

Implication for FlatPaint:
- Your plan item `Tool Transaction layer` is correct and should be first implementation priority.

### 2) Selection is modeled as mask/channel coverage, then applied through buffer operations
- Selection mask is a dedicated mask/channel object:
  - `reference/gimp-src/app/core/gimpselection.c:162`
  - `reference/gimp-src/app/core/gimpselection.c:180-190`
- Extraction path applies selection mask as opacity operation (not bool gate):
  - `reference/gimp-src/app/core/gimpselection.c:804-813`

Implication for FlatPaint:
- Your plan item `Selection semantics unify` is mandatory.
- Recommend keeping 8-bit coverage and propagating it, since current FlatPaint already has feather groundwork.

### 3) Tool logic is split from UI shell via tool classes + manager
- Tool callback contract is class-based:
  - `reference/gimp-src/app/tools/gimptool.h:121-167`
- Tool routing/undo hooks handled through manager APIs:
  - `reference/gimp-src/app/tools/tool_manager.h:81-88`

Implication for FlatPaint:
- Your plan item `Tool state machine isolation` is high-value and aligned with proven architecture patterns.

### 4) Layer geometry offsets are first-class model state
- Item model stores offsets and lock flags:
  - `reference/gimp-src/app/core/gimpitem.c:98-105`
- Offset set/get is centralized and updates dependent graph nodes:
  - `reference/gimp-src/app/core/gimpitem.c:1203-1237`

Implication for FlatPaint:
- Your plan item `Layer geometry metadata` should be implemented in core model (not importer-only stamping).

### 5) Lock semantics are model-level state with undo integration
- Lock fields and setters are in core item model:
  - `reference/gimp-src/app/core/gimpitem.c:2479-2555`
- Some transform behavior checks lock state in core path:
  - `reference/gimp-src/app/core/gimpitem.c:731-734`

Implication for FlatPaint:
- Your plan item `Core invariants sink` is correct: lock/content-position rules should be centrally enforced.

## Evaluation of your current 6-point plan

1. Feature freeze: **Correct**
- Necessary to stabilize tool reliability and prevent moving targets.

2. Tool transaction layer: **Critical / P0**
- Directly addresses current highest-risk architecture defect (A1).

3. Tool controller split from `MainForm`: **Strongly recommended / P1**
- Reduces coupling and regression blast radius (A6).

4. Core invariants in document/domain layer: **Critical / P0**
- Required for consistent lock behavior across all mutation routes (A3).

5. Selection semantics unification: **Critical / P0**
- Current mixed model causes behavioral inconsistency (A2).

6. Tool quality gate with automated regression: **Mandatory / P0**
- Required to keep lightweight scope while eliminating blocking tool defects.

## Lightweight-friendly modification sequence

### Phase 1 (stability first, minimal surface expansion)
- Implement transaction session for `Move Selected Pixels` and related select-move routes.
- Add centralized mutation guard for lock/background constraints.
- Add regression tests for move/cancel/undo semantics.

### Phase 2 (semantic consistency)
- Propagate selection coverage semantics through fill/paint/copy/move and native persistence.
- If full propagation is deferred, explicitly downgrade to binary selection everywhere and remove soft-selection claims.

### Phase 3 (maintainability)
- Split tool event/state code into tool controllers.
- Keep `MainForm` as shell/composition layer only.

### Phase 4 (fidelity and future-proofing)
- Introduce layer offset metadata in core model and compositor.
- Update compatibility import to preserve offsets structurally.

## Current go/no-go conclusion
- For your stated goal ("lightweight editor + stable tools"), the plan is correct.
- Minimum go-live architecture work should include: Phase 1 + Phase 2.
- Without those, tool-level bug recurrence risk remains high even if no new features are added.
