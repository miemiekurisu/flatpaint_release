# Product Requirements Document

## Product name
FlatPaint

## Product mission
Build a native macOS desktop recreation of paint.net: preserve the practical workflow, command discoverability, interface expectations, and day-to-day editing power of paint.net, while re-implementing the stack in a maintainable macOS-native form.

## Product positioning
FlatPaint sits between preview-style tools and heavyweight professional suites.
It must be fast enough for screenshots, UI assets, casual photo correction, memes, small composites, and annotation work.
It is not trying to compete with Photoshop on depth, but it must feel complete and dependable for common editing tasks.

## Reference hierarchy
1. UX and product reference: paint.net
- Primary and authoritative reference for mental model, command naming, workspace layout, menu grouping, tool expectations, and editing flow.
- If a GIMP/Krita pattern conflicts with paint.net user expectations, paint.net wins.
- The detailed workspace-layout parity checklist is maintained in `docs/UI_PARITY_AUDIT.md` and is part of the product baseline.
- The detailed visible-command checklist is maintained in `docs/COMMAND_SURFACE_BASELINE.md` and is part of the product baseline.

2. Backend implementation reference: GIMP and Krita
- Secondary reference for engine decomposition, raster-operation boundaries, effect/adjustment organization, file compatibility fallbacks, and defensive memory/runtime behavior.
- Backend borrowing must not make the user-facing behavior drift away from paint.net.

3. Local implementation rule
- When paint.net behavior is clear, follow paint.net.
- When paint.net source is unavailable or behavior is ambiguous, use the simplest GIMP/Krita-style backend pattern that still preserves paint.net-style user expectations.

## Problem statement
macOS lacks a lightweight layer-based image editor with paint.net-level practicality.
Existing tools are often either too simple for real retouching/compositing or too heavy for fast everyday work.
The gap is specifically in a responsive, familiar, low-friction editor that still has layers, selections, adjustments, effects, and real export/import workflows.

## Target users
- Developers editing screenshots, icons, UI assets, and release imagery
- Designers who need quick edits without opening a heavy suite
- Casual users doing fast retouching, annotation, composition, and export work
- Users migrating from paint.net who want similar behavior on macOS

## Product principles
- Native macOS desktop behavior first
- paint.net recreation fidelity first on UX-facing decisions
- Simple, deterministic, testable editing core
- Fast common actions, low friction, low ceremony
- Complete command surfaces: menus, shortcuts, quick actions, sheet options, and tool options are all first-class
- Visible controls are requirements, not decoration
- Explicit compatibility behavior is better than silent failure
- Memory discipline matters: avoid avoidable raster duplication and UI-side re-encoding churn

## In-scope feature surface
### Workspace and interaction
- Single-window workspace
- Tabbed document strip for multiple open images, with a new-document size prompt before creating a fresh tab
- Tool palette
- Dedicated colors palette
- Top toolbar for common actions and view toggles in the main workspace
- Canvas viewport with checkerboard transparency
- Trackpad-friendly viewport interaction, including pinch-to-zoom driven through a macOS-native AppKit viewport path rather than a SwiftUI-only gesture path
- Layers panel
- History panel
- Color controls
- Tool options / command-adjacent option surfaces
- Main-window child utility panels for tools, layers, history, colors, and similar workspace controls, with fixed paint.net-style default placement on launch
- Cohesive tool and panel iconography instead of text-only control surfaces
- Palette movement behavior should avoid heavy canvas obstruction; semi-transparent drag-state behavior is part of the target desktop feel, but launch-time positions should reset to the product-default layout instead of restoring prior sessions
- Native menu bar commands
- Keyboard shortcuts for primary workflows
- Every visible menu item, toolbar icon, tool icon, utility icon, and status-bar control tracked in `docs/COMMAND_SURFACE_BASELINE.md`
- Quick action surfaces for discoverability
- Native macOS settings/preferences entry for persistent defaults
- Status bar with practical live document/context information

### Editing core
- Raster document model independent of UI state
- Deterministic undo/redo history for all mutations
- Multi-layer editing
- Visibility, opacity, blend modes, reorder, duplicate, rename, merge down, flatten
- Zoom and pan
- Large-image open behavior should default to a fitted proportional zoom instead of forcing a 1:1 view that destabilizes the workspace
- Canvas resize, crop, rotate, flip

### Selection tools
- Rectangle select
- Ellipse select
- Lasso select
- Magic wand
- Move selection
- Move selected pixels
- Additive and subtractive selection composition

### Paint and utility tools
- Pan canvas tool
- Crop tool
- Pencil
- Paintbrush
- Eraser
- Paint bucket
- Gradient
- Color picker
- Recolor
- Clone stamp
- Text
- Line / curve baseline
- Basic shapes baseline

### Adjustments and effects
- Auto-level
- Brightness / contrast baseline
- Hue / saturation
- Posterize
- Grayscale
- Black and white
- Sepia
- Invert
- Core blur
- Sharpen
- Noise
- Outline / edge-style baseline
- Additional effect families may be added incrementally if they map clearly to the matrix

### File and compatibility workflows
- New / open / save native document
- Save As native document
- Export PNG / JPEG / TIFF
- Format-specific export options in save sheets
- JPEG compression quality control
- PNG interlace control where supported
- Flattening behavior control for single-layer export formats
- Clipboard copy/paste image workflows
- Raster image import for common image formats
- PSD import as flattened raster if layered fidelity is not yet implemented
- paint.net `.pdn`, GIMP `.xcf`, and Krita `.kra` import as compatibility paths, at least as flattened layers when full fidelity is unavailable
- Unified open flow that routes native docs, raster images, and compatibility opens predictably: `Open` replaces the current workspace, while `Import` adds a layer

## Paint.NET Reference Analysis (from official documentation)

Based on thorough analysis of https://www.getpaint.net/doc/latest/, the following details the reference UI architecture and identifies remaining gaps in FlatPaint.

### Paint.NET Main Window Layout (11 areas)
1. Title Bar — filename (asterisk if unsaved) + version
2. Menu Bar — 7 menus (File, Edit, View, Image, Layers, Adjustments, Effects) + 6 utility icons
3. Tool Bar — 2 rows: common actions + tool-specific options
4. Image List — tabbed thumbnails, reorderable via drag-and-drop
5. Canvas — center editing area
6. Tools Window — floating/dockable
7. History Window — floating/dockable
8. Layers Window — floating/dockable
9. Colors Window — floating/dockable
10. Status Bar — bottom of window
11. Utility Window toggle icons — in menu bar area

### Paint.NET Status Bar (left to right)
- Help Tips / Tool Status text
- Progress bar (during effects/adjustments rendering)
- Image size (W × H in current units)
- Cursor location (X, Y)
- Units selector dropdown
- Editable zoom text box
- Quick size toggle icon (100% ↔ fit-to-window)
- Zoom slider

### Paint.NET Colors Window
- Primary/Secondary overlapping squares with notch indicator for active slot
- Swap icon (shortcut X) + Default icon (reset to B/W)
- Switch active slot shortcut: C
- Color wheel with modifier support: Ctrl=hue only, Alt=saturation only, Shift=snap to spokes, Ctrl+Shift=15° snap
- RGB + HSV + Opacity sliders (not just wheel)
- Hex text box
- Palette grid: 32 colors minimized, 96 expanded, left-click=active, right-click=inactive
- "More »/Less" toggle

### Paint.NET History Window
- Every session action listed chronologically
- Click any entry to rewind to that state
- Toggle trick: click same entry to toggle before/after comparison
- Undone actions shown with grey background
- New action while reviewing history permanently erases future history
- Closing image or Paint.NET clears history entirely

### Paint.NET Layers Window
- Layer thumbnails with active highlight
- Click to activate, drag-to-reorder
- Icons: New, Delete, Duplicate, Merge Down, Move Up, Move Down, Properties
- Ctrl+Click Move Up/Down = send to top/bottom
- Layer Properties: name, visibility, blend mode, opacity

### Identified Gaps vs Paint.NET Reference

#### Implementation Completion Summary
| Area | Completion | Notes |
|------|-----------|-------|
| Tools | ~100% | 21/21 Paint.NET tools present + 2 extras; Line/Curve partial (no curve node editing) |
| Toolbar Row 1 | ~100% | 13/13 command buttons present + extras |
| Toolbar Row 2 | ~82% | 14/17 tool option categories; missing Finish button, per-tool blend mode, recolor tolerance |
| File Menu | 100% | 10/10 items |
| Edit Menu | 100% | 16/16 items |
| Image Menu | 100% | 9/9 items |
| Layers Menu | 100% | 11/11 items + extras |
| View Menu | 100% | 8/8 items + extras |
| Adjustments | 100% | 9/9 core adjustments + extra Grayscale |
| Effects | ~52% | 17/33+ effects; missing ~16 effects; no sub-menu categorization |
| Tool Shortcuts | ~11% | 2/18; only X (swap) and D (reset); all 14 single-key tool-switch keys missing; no Spacebar pan |
| Menu Shortcuts | 100% | 33/33 modifier shortcuts present |
| Viewport | ~71% | 5/7 techniques; missing Spacebar+drag pan, middle-mouse pan |
| Status Bar | ~75% | 6/8 cells; missing progress bar, inline units selector; zoom label not editable |
| Colors Panel | ~50% | Wheel + value bar + hex + RGBA spins; missing HSV sliders, palette grid, overlapping squares with notch, C shortcut, wheel modifiers, right-click |
| History Panel | ~70% | Click-to-rewind works; missing redo-entry display, grey-out styling, toggle trick |
| Layers Panel | ~80% | All buttons present; missing thumbnails, drag-to-reorder, Ctrl+Click top/bottom |
| Iconography | ~45% | Text-heavy buttons, limited icon usage |

#### Detailed Gap Inventory
| Area | Gap | Priority |
|------|-----|----------|
| **Colors** | Missing overlapping squares with active-slot notch (currently side-by-side) | Medium |
| **Colors** | Missing C shortcut to switch active color slot | High |
| **Colors** | Missing HSV sliders / numeric fields (only wheel + value bar) | Medium |
| **Colors** | Missing palette grid (32 minimized / 96 expanded swatches) | Medium |
| **Colors** | Missing "More »/Less" toggle for palette expansion | Medium |
| **Colors** | Missing right-click on wheel/palette = set inactive slot | Low |
| **Colors** | Missing Ctrl/Alt/Shift wheel modifiers (hue-lock, saturation-lock, snap) | Low |
| **Colors** | RGB controls are spin edits, not gradient sliders (functional but visually different) | Low |
| **History** | Redo entries not displayed in list (only undo stack visible) | Medium |
| **History** | No grey-out styling for undone/redo-able entries | Low |
| **History** | No toggle trick (click same entry for before/after comparison) | Low |
| **Status Bar** | Missing progress bar for effects/adjustments rendering | Medium |
| **Status Bar** | Units label is read-only, not a clickable dropdown selector | Low |
| **Status Bar** | Zoom label is not editable (click-to-type percentage) | Low |
| **Status Bar** | Quick-size toggle overloaded on zoom label instead of separate icon | Low |
| **Status Bar** | FStatusLabels[6] unused (empty) | Low |
| **Layers** | Missing layer thumbnails (text-only list) | Medium |
| **Layers** | Missing drag-to-reorder | Medium |
| **Layers** | Missing Ctrl+Click on Move Up/Down = send to top/bottom | Low |
| **Layers** | Visibility not in Properties dialog (only as separate toggle button) | Low |
| **Tools** | Line/Curve tool has no interactive curve/Bézier node editing | Medium |
| **Tool Shortcuts** | All 14 single-key tool-switch keys missing (S,M,Z,H,F,G,B,E,P,K,L,R,T,O) | High |
| **Tool Shortcuts** | Missing Spacebar temporary pan mode | High |
| **Viewport** | Missing Spacebar+drag pan | High |
| **Viewport** | Missing middle-mouse-button drag pan | Medium |
| **Toolbar** | Missing Finish/Commit button for multi-step tools | Low |
| **Toolbar** | Missing per-tool blend mode selector | Low |
| **Effects** | ~16 effects missing (Gaussian, Surface/Radial Blur, Fragment, Unfocus, Red Eye, Relief, Tile Reflection, Twist, Bulge, Dents, Crystallize, Ink Sketch, Julia/Mandelbrot Fractal, etc.) | Medium |
| **Effects** | No sub-menu categorization (Blurs, Distort, Noise, Photo, Render, Stylize) | Low |
| **Image List** | Missing drag-to-reorder tabs | Low |
| **Iconography** | Text-heavy buttons vs icon-based controls throughout | Medium |

## Explicitly out of scope for current baseline
- Third-party plugin execution
- Full PSD round-trip fidelity
- Full `.pdn`, `.xcf`, `.kra` layered fidelity
- RAW pipeline
- Cloud collaboration
- Mobile builds

## Functional requirements
1. The app must launch into a usable editing workspace, not a placeholder shell.
2. The app must be operable for real image edits through the current UI, not only through tests.
3. Every mutating document action must create an undoable history entry, while non-destructive view-state changes (such as zoom/pan/grid toggles) must stay out of document history.
4. Core editing behavior must remain testable without UI involvement.
5. The menu bar, shortcut layer, quick actions, and tool-option surfaces must expose the primary workflows.
6. Shortcut behavior must preserve paint.net command intent while translating modifier usage to native macOS conventions.
7. Save and export sheets must expose output-affecting options instead of hiding them behind hardcoded defaults.
8. If a format is only partially supported, the app must use an explicit fallback path and keep the result usable.
9. File open behavior must be deterministic across native documents, raster imports, and compatibility imports.
10. Opening a very large image must fit the initial viewport proportionally so the workspace remains usable and does not collapse around the canvas.
11. Layer, selection, transform, adjustment, and effect actions must operate on real pixel data.
12. The user experience must remain recognizably aligned with paint.net in command grouping, interface expectations, and expected flow.
13. Backend implementation decisions may borrow from GIMP/Krita patterns, but user-facing command semantics must remain paint.net-aligned.
14. Major workspace panels must behave as main-window child surfaces with paint.net-style default placement, constrained movement, and practical dock-like behavior.
15. Core workspace controls should use a coherent icon system so tools and panel actions are visually scannable.
16. Floating utility palettes should reduce visual obstruction while being repositioned, including a drag-time translucency behavior target.
17. The workspace must expose both a top toolbar-like control strip and a meaningful status bar, in line with paint.net’s main-window information layout.
18. No visible menu item, toolbar icon, tool icon, utility icon, image-list control, or status-bar control may remain as a non-functional placeholder.
19. A visible command surface is only complete when both its backend behavior and its visible route are implemented and tested.

## Non-functional requirements
- Cold launch target: under 2 seconds on an Apple Silicon development machine after stabilization work
- Common non-render-heavy actions should feel immediate (<100 ms perceived delay)
- Crash-free target: 99%+ in internal sessions before wider release
- Memory discipline: avoid duplicate full-frame buffers unless required by undo/history or a deliberate render stage
- UI rendering should avoid unnecessary format round-trips during preview generation
- Viewport interaction should avoid obvious stutter from history churn or other avoidable UI-side work during continuous input
- Safety: track regressions, warnings, and runtime hazards (including likely leak-prone patterns) in the engineering experience log

## UX requirements
- The default workspace must remain single-window and practical.
- Tool placement, layer flow, menu naming, and command grouping should feel familiar to paint.net users.
- Keyboard shortcuts should feel like macOS-native translations of paint.net, not arbitrary remaps.
- Floating utility palettes should feel like natural extensions of the docked workspace, not disconnected secondary UIs.
- Floating utility palettes should communicate movement with lightweight translucency or similar anti-obstruction feedback while being repositioned.
- The canvas must remain the visual center, while major control strips and palettes read as overlays or utility surfaces above it rather than competing layouts that squeeze it.
- The default visible arrangement of controls must resemble paint.net's compact palette-and-canvas composition, not a generic sidebar-based SwiftUI utility layout.
- Native macOS adaptation is allowed where platform conventions materially improve usability.
- Hidden workflow surfaces inside modal sheets must be treated as part of the UX, not optional polish.
- The app should be usable with both mouse and trackpad.
- Trackpad interaction should feel native, including AppKit-backed pinch zoom support, non-sticky continuous zoom, and reasonably smooth scrolling behavior.
- The visual/layout parity audit in `docs/UI_PARITY_AUDIT.md` must be reviewed before claiming UI readiness.

## Architecture direction
- App shell: Lazarus/LCL on the Cocoa widgetset, with macOS-specific behavior handled through LCL-compatible patterns first
- Editing core: Free Pascal units for document state, raster operations, selections, and file-format routing, kept independent from GUI-only state where practical
- Rendering path: CPU raster first, with prepared-bitmap reuse in the GUI paint path and a clean seam for future acceleration if the current FPC/LCL baseline becomes a bottleneck
- Compatibility adapters: isolated file-format import/export helpers in shared FPC units, separate from GUI routing and document mutation orchestration
- Reference architecture influence:
  - paint.net defines the UX target
  - Krita-style separation informs image core vs plugin/format boundaries
  - GIMP-style separation informs image core vs file/processing pipeline boundaries

## Release phases
1. Foundation
- Workspace shell, document model, layer stack, history, tests, traceability docs

2. Core editing
- Selections, drawing, fill, transform, viewport interaction, core tool options

3. Adjustments and effects
- Practical baseline adjustments/effects with testable raster behavior

4. File and compatibility hardening
- Native document flow, export options, clipboard, compatibility import, menu/shortcut coverage, integration and regression testing

5. UAT readiness
- Launchable, usable desktop app with stable end-to-end editing flow, exhaustive visible-command coverage, and documented remaining gaps

## UAT gate
FlatPaint reaches UAT readiness only when all of the following are true:
- The app launches and remains stable in a manual smoke run.
- A user can open/import, edit, and export a real image through the UI.
- Primary workflows are accessible from menus and/or visible controls.
- Unit, integration, and regression suites pass.
- The feature matrix explicitly marks any remaining gaps.
- The docs, code, and logs agree on the current product state.
