# Functional Priority Order (Code-First)

## Scope
- Date: 2026-03-07
- This ranking is for functional delivery only, not pure visual polish.
- Source-of-truth order follows `docs/PRD.md`: implemented code, tests, then docs.

## Prioritization method
- Priority is weighted by:
1. Release risk reduction
2. User-visible workflow value
3. Regression containment cost

## Current priority ranking

### P0 (next, must-close for release confidence)
1. Shortcut parity closure + route-level coverage expansion
- Why now:
  - `docs/SHORTCUT_POLICY.md` still marks parity coverage as non-exhaustive.
  - Shortcut consistency is a high-frequency UX contract and regression hotspot.
- Exit criteria:
  - High-use command-surface shortcuts are fully audited against visible menu/tool routes.
  - Missing parity items are either implemented with tests or explicitly deferred in policy/matrix.

2. Recolor behavior completion (R1 -> R2 in design spec)
- Why now:
  - Recolor is user-reported as behavior-sensitive and currently baseline-only.
  - Existing design/test plan already exists in `docs/RECOLOR_DESIGN_SPEC.md`.
- Exit criteria:
  - Selection-scoped route-level recolor tests (undo/redo + sampling contract) are green.
  - Sampling mode and mode semantics progress from baseline toward documented R2 target.

3. A4 layer-offset semantics activation (architecture tail)
- Why now:
  - Metadata is landed, but runtime render/tool semantics are still compatibility-mode.
  - This is the main remaining architecture debt called out in defect assessment.
- Exit criteria:
  - Compositor/tool math consumes layer offsets as a runtime invariant.
  - Offset-aware behavior is covered by focused regression tests.

### P1 (high value, after P0 stabilizes)
1. Draw tools parity depth
- Scope:
  - Line/curve and shape workflows (dash styles, richer node-edit follow-up).
- Exit criteria:
  - Advanced draw interactions are functionally complete for the selected baseline.
  - Existing straight-line/shape commit routes remain regression-clean.

2. View/status quick-size semantics closure
- Scope:
  - View quick-size/status interactions currently listed as partial.
- Exit criteria:
  - Quick-size behavior is deterministic and route-tested across menu/toolbar/status.

3. Export option depth
- Scope:
  - Format-option parity breadth and behavior depth beyond baseline controls.
- Exit criteria:
  - Major format routes expose stable option semantics with coverage.

### P2 (important but can follow stabilization)
1. Compatibility IO depth
- Scope:
  - Better layered fidelity where practical without violating explicit non-goals.
- Exit criteria:
  - Fallback behavior stays explicit, and fidelity limits are documented/tested.

2. Command-surface long-tail coverage
- Scope:
  - Remaining one-to-one route tests for less frequently used visible controls.
- Exit criteria:
  - Coverage debt in `docs/FEATURE_MATRIX.md` is materially reduced.

## Not included in this ranking
- Purely visual/UI style convergence work (tracked separately in UI parity docs).
- Intentionally deferred non-goals (plugins, full foreign-format fidelity, RAW, cloud/mobile).
