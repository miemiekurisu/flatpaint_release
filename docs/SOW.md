# Statement of Work

## Objective
Deliver FlatPaint as a native macOS desktop application that reaches practical paint.net-style editing parity through staged milestones.

## Work packages
1. Product baseline and documentation
- Deliver PRD, implementation plan, feature matrix, SOW, rules, shortcut policy, progress log, test log, and event book
- Acceptance: documents exist and reference the same phased scope

2. Core architecture
- Deliver Swift package, app shell target, core library target, and test target
- Acceptance: package builds and tests execute locally

3. Editing foundation
- Deliver document model, layer commands, history stack, tool catalog
- Acceptance: unit tests cover core mutations

4. Rendering and tools
- Deliver viewport, raster buffer, selections, paint tools, transforms
- Acceptance: integration flows cover common edits, and active tool options materially change tool output

5. Effects and adjustments
- Deliver baseline adjustment/effect pipeline
- Acceptance: parity check against reference matrix shows no untracked gaps for targeted phase

6. File compatibility and export controls
- Deliver format-aware save/export options, compression controls, and flattened compatibility import paths for PSD and `.pdn`/`.xcf`/`.kra`
- Acceptance: save/open surfaces expose these controls explicitly, and compatibility import is covered by automated tests

7. Hardening
- Deliver regression suite, performance fixes, defect log closure, and menu/shortcut/config completeness review
- Acceptance: test logs and progress logs show stable passes, and the menu bar / toolbar / tool palette / utility icons / image-list surface / config surfaces align with `docs/SHORTCUT_POLICY.md` and `docs/COMMAND_SURFACE_BASELINE.md`

8. Workspace usability polish
- Deliver paint.net-style child-panel support for key workspace palettes and a coherent icon system for core controls
- Acceptance: the workspace no longer depends on text-only tool surfaces, and key palettes are draggable inside the main editor window with fixed default placement on launch
- Follow-up acceptance target: child-panel movement feedback (such as drag-time translucency) is explicitly tracked and implemented before UAT closure

10. Document shell parity
- Deliver a tabbed document strip and a new-document size prompt before creating a fresh document tab
- Acceptance: multiple open images can be switched from the main workspace, and new-tab creation does not bypass explicit size choice

11. Visible command-surface completion
- Deliver one-to-one implementation coverage for every visible menu item, toolbar icon, tool icon, utility icon, image-list control, and status-bar control tracked in `docs/COMMAND_SURFACE_BASELINE.md`
- Acceptance: no visible control remains as a placeholder, and every control has an explicit automated test obligation satisfied

9. Workspace visual parity audit and convergence
- Deliver a documented gap analysis against the official paint.net workspace and use it as the execution baseline for layout/placement changes
- Acceptance: `docs/UI_PARITY_AUDIT.md` exists, is referenced by the PRD/feature matrix, and the remaining visual gaps are explicitly tracked instead of implied

## Constraints
- Work happens inside this repository unless an explicit external dependency is required.
- Each change must keep docs, code, and progress logs aligned.
- Any repeated defect must be counted in the event book.
