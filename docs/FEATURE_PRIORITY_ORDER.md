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

### P0 closure status (completed on 2026-03-07)
1. Shortcut parity closure + route-level coverage expansion
- Closed by high-use command-surface audit and test-backed mappings (`Copy Selection`, `Paste into New Layer`, `Paste into New Image`, `Fill Selection`, `Crop To Selection`).

2. Recolor behavior completion (R1 -> R2)
- Closed by sampling-mode + blend-mode rollout and route-level recolor integration coverage (selection scope + undo/redo + sampling contracts).

3. A4 layer-offset semantics activation
- Closed by runtime offset-aware compositor/tool mapping with focused regression coverage.

### P1 closure status (completed on 2026-03-07)
1. Draw tools parity depth
- Closed by dashed line-style support across preview + commit paths (`line` + shape outlines), plus core and pipeline regression coverage.

2. View/status quick-size semantics closure
- Closed by deterministic quick-size toggle helper logic and dedicated zoom-helper regression coverage.

3. Command-surface long-tail coverage
- Closed at the current target by adding route-level tests for additional non-primary control paths (including tool-classified selection keep/clear behavior on toolbar/shortcut switching) and reducing remaining coverage debt to non-blocking parity follow-up.

### P2 (next active priority)
1. Export option depth
- Scope:
  - Format-option parity breadth and behavior depth beyond baseline controls.
- Exit criteria:
  - Major format routes expose stable option semantics with coverage.

2. Compatibility IO depth
- Scope:
  - Better layered fidelity where practical without violating explicit non-goals.
- Exit criteria:
  - Fallback behavior stays explicit, and fidelity limits are documented/tested.

## Not included in this ranking
- Purely visual/UI style convergence work (tracked separately in UI parity docs).
- Intentionally deferred non-goals (plugins, full foreign-format fidelity, RAW, cloud/mobile).
