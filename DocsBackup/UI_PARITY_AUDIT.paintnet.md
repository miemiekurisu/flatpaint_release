# UI Parity Audit

## Purpose
This document captures the current visual and layout gap between FlatPaint and the official paint.net workspace.
It exists so UI work is driven by explicit parity targets instead of feature-count optimism.
The broader cross-editor layout and interaction rules now live in `docs/UI_REQUIREMENTS_BASELINE.md`; use that document first for normalized canvas/zoom/panel behavior, then use this audit for paint.net-specific parity details.

## Source set
- Official paint.net main-window documentation: `https://docs.getpaint.net/MainWindow.html`
- Official paint.net menu-bar documentation: `https://docs.getpaint.net/MenuBar.html`
- Official paint.net toolbar documentation: `https://docs.getpaint.net/Toolbar.html`
- Official paint.net status-bar documentation: `https://docs.getpaint.net/StatusBar.html`
- Official utility-window documentation: `https://docs.getpaint.net/ToolsWindow.html`, `https://docs.getpaint.net/HistoryWindow.html`, `https://docs.getpaint.net/LayersWindow.html`, `https://docs.getpaint.net/ColorsWindow.html`
- Official product screenshots and marketing imagery on `https://www.getpaint.net/` and `https://www.getpaint.net/features.html`
- Detailed visible-command checklist: `docs/COMMAND_SURFACE_BASELINE.md`

## paint.net visual baseline
1. Main window hierarchy
- A dense command surface sits at the top of the app.
- The image surface is the visual center.
- Utility windows read as small desktop palettes around the canvas, not as oversized sidebars.

2. Toolbar density
- The top toolbar is compact, icon-led, and spans many common actions without looking like a large card.
- It reads as a horizontal command strip, not as a secondary content panel.

3. Utility windows
- `Tools` is a compact tool palette, typically narrow and easy to scan.
- `Colors`, `History`, and `Layers` are child utility panels that can be repositioned inside the editor.
- These surfaces behave like in-window utilities around the image rather than separate app windows or permanent layout columns.

4. Status bar
- A dedicated status strip stays anchored at the bottom of the main window.
- It carries live editing context such as zoom, hints, and document/canvas state.
- It is visually light but information-dense.

5. Canvas-first composition
- The canvas remains dominant even when many controls are visible.
- Large images do not erase access to the rest of the UI because zoom and scrolling behavior protect workspace usability.

## Current FlatPaint differences
1. Top control strip
- The current top strip is functionally useful but still too sparse and too card-like compared with paint.net's denser toolbar.
- Control spacing is looser than the target, so the window reads more like a SwiftUI app shell than a paint.net-style editor.
- The overall toolbar proportion is improving, but it is still slightly oversized relative to paint.net's compact control density.

2. Default panel composition
- The old large left/right overlay surfaces have been removed, which fixed overlap, but the remaining bottom summary card and palette proportions still need tuning to feel like paint.net instead of a SwiftUI utility shell.
- The remaining docked surface is now a compact summary/launcher rather than a full editor, which is directionally correct but still needs tighter visual metrics.
- Default palette positions are now much closer, but the initial cluster still needs another pass to feel as balanced and intentional as paint.net.
- The large docked `Tools` and `Inspector` overlays have now been removed from the main workspace to avoid overlap and obstruction; compact child utility panels are now the primary detailed surfaces.

3. Utility-window fidelity
- Separate child panels now exist for `Tools`, `History`, `Layers`, and `Colors`, and they are now the primary detailed control model; the remaining gap is compactness, exact placement, and richer docking behavior, but the launch layout now at least waits for the real workspace size before placing those palettes so they do not all collapse into the same corner on startup.
- `Colors` now exists as a first-class utility panel, but its default placement still needs to feel more like a paint.net palette cluster and less like an inspector extension.
- Launch-time placement now resets to a non-overlapping product-default layout each run instead of restoring prior panel positions, but the exact pixel parity still needs more tuning.

4. Status-bar fidelity
- The status bar now includes more live editing context, including tool hint, image size, selection size, cursor position, active layer, units, and a bottom-right zoom slider.
- It is still missing some of the practical density paint.net users expect, especially richer sampled-color feedback and more nuanced context readouts.
- The overlap bug between the zoom cluster and neighboring status text is now addressed through adaptive panel partitioning, but the visual treatment is still closer to a modern translucent footer than to a tightly packed desktop editing strip.

5. Interaction smoothness
- A practical pointer-anchored fallback now exists: `Ctrl` / `Command` modified wheel input zooms through the current Lazarus viewport.
- True native trackpad pinch-to-zoom is still not implemented in the current Lazarus path.
- Continuous zoom smoothness is improved: interactive zoom no longer records history, and preview rendering is cached across viewport-only changes.
- Smoothness still needs work in scrolling feel and general UI polish during motion.

6. Visual language
- The current UI still looks more like a native SwiftUI utility app than a close paint.net recreation.
- `SF Symbols` solves the "no icons" problem, but it is still only a provisional icon system and does not yet match paint.net's visual cadence.

## Required parity targets
1. Default launch layout
- Default workspace should present the canvas centered with compact child utility panels around it inside the main editor window.
- The default mental model should feel like paint.net immediately, before the user opens extra windows.
- FlatPaint now presents the core panel set inside the main workspace by default, which moves the default experience closer to this target.

2. Utility-window set
- `Tools`, `Colors`, `History`, and `Layers` must all exist as first-class utility surfaces.
- They should support practical repositioning inside the main editor window and should visually read as persistent desktop palettes.
- The main window should only retain compact summaries/launchers for these areas once the child-panel versions are established as the primary detailed surfaces.

3. Compact chrome
- Top toolbar density must increase.
- Panel chrome must become lighter, tighter, and less card-like.
- The main workspace should avoid oversized rounded-container styling that makes controls feel detached from the editor.

4. Status-bar completeness
- Bottom status bar should include stronger live context:
- current tool
- zoom
- image size
- layer count
- selection metrics when applicable
- pointer-relative context when practical

5. Large-canvas safety
- Opening a large image must remain fit-first by default.
- Canvas scroll and zoom behavior must preserve access to commands and palettes.

## macOS-specific implementation difficulties
1. Menu-bar placement
- paint.net is a Windows app with an in-window menu bar.
- macOS uses a global system menu bar, so exact visual duplication is impossible.
- The practical requirement is command-surface parity, not literal menu embedding.

2. Dockable utility windows
- paint.net's utility windows behave like compact dockable child panels tied to the main editor.
- SwiftUI alone is not a strong fit for full palette docking behavior with persistence and nuanced movement feedback.
- Real parity will require tighter in-window panel coordination, constrained drag handling, and clearer docking behavior than a plain SwiftUI stack provides.

3. Window layering semantics
- "Always above the canvas" must be interpreted as a palette layer inside the editor, not as macOS-wide always-on-top windows.
- The implementation must avoid turning utility panels into separate app windows that compete with the main document window.

4. Density and metrics
- Matching paint.net's compact control density is harder on macOS because default AppKit/SwiftUI spacing, titlebar behavior, and font metrics differ.
- Reaching visual parity will require deliberate custom spacing and panel sizing rather than default control stacks.

5. Icon parity
- paint.net's icon language is product-specific.
- A close match will require a custom icon set or a carefully curated replacement; `SF Symbols` is only a temporary bridge.

## Implementation direction
1. Use `paint.net` as the visual/layout authority and treat this audit as the workspace-parity checklist.
2. Keep the current functional overlay layout only as an interim state.
3. Shift the default composition toward compact child panels and smaller, denser top-level controls.
4. Add a dedicated `Colors` palette and reduce reliance on the large integrated inspector.
5. Move child palettes toward fuller paint.net-style behavior:
- compact chrome
- movement translucency
- practical in-window drag constraints
- fixed paint.net-style default positions on launch
- clearer docking behavior
6. Continue using GIMP/Krita only for backend behavior, file compatibility, and algorithm decisions, not for visible workspace layout.

## UAT blocking UI gaps
- Default layout still does not visually read as paint.net strongly enough.
- Palette density and default placement are still off.
- The `Colors` utility window exists now, but its default role and placement still need stronger paint.net-style integration.
- The `Layers` utility window is now the intended primary detailed layer surface, but the remaining docked summaries still need another density pass.
- The bottom summary card now correctly acts as a compact `Inspector` launcher instead of a duplicate `History` surface.
- Toolbar density and icon fidelity still need another pass.
- Status-bar detail has improved, but still needs expansion beyond the current cursor and sampled-color readouts.
- Continuous scrolling and general motion smoothness still need another dedicated pass.

## Review rule
Before calling the product visually close to paint.net, compare the current app against this document, `docs/COMMAND_SURFACE_BASELINE.md`, and the official paint.net docs/screenshots, not just against the feature matrix.
