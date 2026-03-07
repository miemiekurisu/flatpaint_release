# Implementation Plan

## Mandatory workflow
1. Read `docs/PRD.md`, `docs/FEATURE_MATRIX.md`, `docs/COMMAND_SURFACE_BASELINE.md`, `docs/COMMAND_SURFACE_BREAKDOWN.md`, `docs/PROGRESS_LOG.md`, `docs/DEVELOPMENT_RULES.md`, and `docs/SHORTCUT_POLICY.md` before any code change.
2. Implement only work that maps to an explicit feature row and progress item.
3. After each code change, update progress, test log, and event book if anything failed.
4. Write unit tests for the changed core behavior.
5. Run unit tests, fix failures, and log the result.
6. Re-check feature coverage against the reference baseline.
7. Run integration and regression checks once a vertical slice exists.

## Delivery phases
### Phase 0: Baseline and guardrails
- Lock the reference baseline
- Create docs and traceability artifacts
- Create project skeleton and test target

### Phase 1: Editing core foundation
- Document model
- Layer stack state and commands
- History model and undo/redo base
- Tool catalog and feature gating
- Shell UI for workspace navigation
- Initial command routing for menu bar and shortcut parity

### Phase 2: Raster engine
- Backing pixel buffer abstraction
- Canvas viewport
- Selection mask model
- Brush/fill/transform paths
- Direct canvas interaction for mouse-driven editing
- Tool option state that actively affects tool behavior

### Phase 3: Adjustments and effects
- Adjustment pipeline
- Previewable effects
- Shared parameter schemas
- Tool and command option surfaces hardened in the UI

### Phase 4: File and integration
- Native document format
- PNG/JPEG/TIFF import/export
- Save/open sheet options for format-specific controls and compatibility entry points
- Flattened compatibility adapters for PSD and external project import (.pdn/.xcf/.kra)
- Clipboard and drag/drop
- Integration and regression suite
- Menu/shortcut parity sweep and command discoverability pass
- Windows-to-macOS shortcut translation audit against `docs/SHORTCUT_POLICY.md`

## Current implementation target
- Harden the current launchable app toward UAT usability
- Prioritize functional closure using `docs/FEATURE_PRIORITY_ORDER.md`
- Drive command completion from `docs/COMMAND_SURFACE_BASELINE.md` instead of from rough menu-category coverage
- Complete the missing menu/shortcut/config parity items that are easy to miss
- Expose hidden file-dialog workflow capabilities instead of leaving them implicit
- Close major desktop-UI blind spots such as detachable palettes, usable iconography, and scannable panel controls
- Drive workspace-layout changes from `docs/UI_PARITY_AUDIT.md`, not from ad hoc visual approximations
- Reduce the current sidebar-like feel by moving toward compact paint.net-style utility palette placement and denser top-level control surfaces
- Track and later implement movement-time translucency for floating palettes so panel dragging does not heavily obscure the canvas
- Close the current mainline gaps in tool behavior and shell flow, especially tabbed documents, pan/crop tool routing, and freeform lasso behavior
- Expand tests from category-level coverage to one visible command-surface item at a time
- Keep tightening runtime safety and memory discipline while interactive editing expands

## Traceability rules
- Every implemented feature needs a matching row in `docs/FEATURE_MATRIX.md`
- Every visible command surface needs a matching checklist item in `docs/COMMAND_SURFACE_BASELINE.md`
- Every work session needs an entry in `docs/PROGRESS_LOG.md`
- Every test run needs an entry in `docs/TEST_LOG.md`
- Every defect or fix needs an entry in `docs/EXPERIENCES.md`
