# Statement of Work

## Objective
Deliver FlatPaint as a native macOS desktop application (FPC + Lazarus) that reaches practical day-to-day editing completeness under the current product baseline.

## Governing baseline
- Functional behavior and shipped capability are judged by implemented code paths and automated tests in this repository.
- UI/visual baseline follows `flatpaint_design` and `docs/UI_PARITY_AUDIT.md`.
- Intentional UI deltas from the Figma baseline are allowed only when explicitly documented.

## Work packages
1. Product baseline and documentation
- Deliver PRD, implementation plan, feature matrix, SOW, rules, shortcut policy, progress log, test log, and event book.
- Acceptance: documents are internally consistent and match current code behavior.

2. Core architecture
- Deliver and maintain an FPC/Lazarus app shell target, shared core library units, CLI surface, and test target.
- Acceptance: `bash ./scripts/build.sh` builds the app bundle; test target compiles and executes locally.

3. Editing foundation
- Deliver document model, layer commands, history stack, and tool catalog.
- Acceptance: unit tests cover core mutations and regressions.

4. Rendering and tools
- Deliver viewport, raster buffer, selections, paint tools, and transforms.
- Acceptance: integration flows cover common edits, and active tool options materially change output.

5. Effects and adjustments
- Deliver baseline adjustment/effect pipeline.
- Acceptance: feature matrix status is backed by code paths and tests, with explicit gaps tracked.

6. File compatibility and export controls
- Deliver format-aware save/export options, compression controls, and compatibility import paths for PSD/PDN/XCF/KRA (with explicit fallback behavior where fidelity is partial).
- Acceptance: open/save surfaces expose these controls explicitly, and compatibility paths are covered by automated tests.

7. Hardening
- Deliver regression suite expansion, defect closure, performance stabilization, and command-surface completeness review.
- Acceptance: test and progress logs show current build/test status honestly (including failures), and command-surface gaps are explicitly tracked.

8. Workspace usability polish
- Deliver floating child-panel support for key workspace palettes, coherent iconography, and stable default placement on launch.
- Acceptance: workspace is not text-placeholder-driven; palettes are draggable within the main window and visually coherent with the active UI baseline.

9. Document shell parity
- Maintain a tabbed document strip and new-document size prompt in the main workspace.
- Acceptance: multiple open images are switchable from the tab strip; new-tab creation always goes through explicit size choice.

10. Visible command-surface completion
- Deliver one-to-one implementation coverage for visible menu/toolbar/tool/panel/status controls tracked in `docs/COMMAND_SURFACE_BASELINE.md`.
- Acceptance: each visible control has a real route and automated test obligation, with any remaining gap explicitly documented.

11. UI parity convergence
- Converge visual behavior toward the active Figma-derived baseline while preserving documented intentional deltas.
- Acceptance: `docs/UI_PARITY_AUDIT.md` stays current, and mismatches are explicit rather than implied.

## Constraints
- Work happens inside this repository unless an explicit external dependency is required.
- No feature should be marked complete based on planned behavior; completion must reference implemented code behavior.
- Test failures must be logged and treated as release blockers until resolved.
- Repeated defects must be recorded in `docs/EXPERIENCES.md`.
