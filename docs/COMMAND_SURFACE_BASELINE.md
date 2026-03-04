# Command Surface Baseline

## Purpose
This document is the authoritative checklist for visible command surfaces in FlatPaint.
Nothing visible in the menu bar, toolbar, utility icons, tool palette, image list, or status bar may be treated as decorative.
If a control is visible, it must either:
- invoke a real working feature, or
- be explicitly marked `Deferred` in this document and in `docs/FEATURE_MATRIX.md`

## Reference sources
- Main Window: `https://www.getpaint.net/doc/latest/MainWindow.html`
- Menu Bar: `https://www.getpaint.net/doc/latest/MenuBar.html`
- File Menu: `https://www.getpaint.net/doc/latest/FileMenu.html`
- Tool Bar: `https://www.getpaint.net/doc/latest/Toolbar.html`
- Keyboard & Mouse Commands: `https://www.getpaint.net/doc/latest/KeyboardMouseCommands.html`
- Image List: `https://www.getpaint.net/doc/latest/ImageList.html`
- Tool Window: `https://www.getpaint.net/doc/latest/ToolsWindow.html`
- Status Bar: `https://www.getpaint.net/doc/latest/StatusBar.html`

## paint.net command-surface baseline
### Main window structure
- Title bar
- Menu bar with seven top-level menus
- Six utility icons on the right side of the menu bar
- Toolbar
- Image list (thumbnail tab strip)
- Editing window / canvas
- Status bar
- Utility windows: Tools, History, Layers, Colors

### Menu bar
#### File
- New
- Open
- Open Recent
- Acquire
- Close
- Save
- Save As
- Save All Images
- Print
- Exit

#### Edit
- Undo
- Redo
- Cut
- Copy
- Copy Merged
- Paste
- Paste into New Layer
- Paste into New Image
- Copy Selection
- Paste Selection (Replace)
- Erase Selection
- Fill Selection
- Invert Selection
- Select All
- Deselect

#### View
- Zoom In
- Zoom Out
- Zoom to Window
- Zoom to Selection
- Actual Size
- Pixel Grid toggle
- Rulers toggle
- Units selection
- Image-list navigation affordances

#### Image
- Crop to Selection
- Resize
- Canvas Size
- Rotate 90 clockwise
- Rotate 90 counter-clockwise
- Rotate 180
- Flatten

#### Layers
- Add New Layer
- Delete Layer
- Duplicate Layer
- Merge Layer Down
- Import From File
- Layer Properties
- Rotate / Zoom
- Visibility toggle path
- Layer transform commands

#### Adjustments
- Auto-Level
- Brightness / Contrast
- Curves
- Black and White
- Hue / Saturation
- Invert Colors
- Levels
- Sepia
- Posterize
- Any additional built-in adjustment shown in the target release must be tracked before completion is claimed

#### Effects
- Built-in effect families must be represented as real commands, not placeholders
- Blur family
- Noise family
- Stylize / outline-style baseline
- Repeat-last-effect command path
- Any additional built-in effect shown in the target release must be tracked before completion is claimed

### Menu-bar utility icons
- Reset / show Tools window
- Reset / show History window
- Reset / show Layers window
- Reset / show Colors window
- Settings
- Help

### Toolbar
#### Common-action icons
- New
- Open
- Save
- Print
- Cut
- Copy
- Paste
- Crop
- Deselect
- Undo
- Redo

#### View controls
- Zoom In
- Zoom Out
- Zoom level chooser / quick size control
- Pixel Grid toggle
- Rulers toggle
- Units chooser

#### Tool controls
- Tool chooser drop-down
- Tool parameter row for the active tool

### Image list
- One visible tab per open document
- Click to activate
- Next / previous document navigation
- Horizontal scrolling when many images are open
- Reordering by drag and drop
- Close from the image list
- Unsaved-change indicator
- Context menu for the active image

### Tool palette
#### Selection tools
- Rectangle Select
- Lasso Select
- Ellipse Select
- Magic Wand

#### Move tools
- Move Selected Pixels
- Move Selection

#### View tools
- Zoom
- Pan

#### Paint tools
- Paint Bucket
- Gradient
- Paintbrush
- Eraser
- Pencil
- Color Picker
- Clone Stamp
- Recolor
- Text

#### Shape / object tools
- Line / Curve
- Rectangle
- Rounded Rectangle
- Ellipse
- Freeform Shape

### Status bar
- Quick help / tool hint region
- Rendering progress region
- Image size readout
- Cursor location readout
- Units readout
- View-size / zoom controls
- Quick-size toggle behavior

## Completion rules
1. A command surface item is not complete if only the icon/text exists.
2. Every item above must map to a named feature in `docs/FEATURE_MATRIX.md`.
3. Every item above must map to an implementation task in `docs/COMMAND_SURFACE_BREAKDOWN.md`.
4. Every item above must have:
- a core functional path
- a route-level invocation path from the visible UI surface
- an automated test obligation
5. Continuous interactions (zoom, pan, drag tools, image-list drag reorder) also need behavior-specific interaction tests, not just static command tests.

## Current known mainline gaps
- The image list / document-tab strip is now live in the current Lazarus GUI source: visible thumbnail-backed tabs, next/previous navigation, drag reordering, close buttons, horizontal scrolling, and a context menu are all present; the remaining gap here is richer paint.net-style image-list polish rather than absence of the surface.
- `Resize...`, `Canvas Size...`, and `Units` now exist in baseline form, but they still need deeper paint.net-style polish and fuller route-level coverage.
- Not every toolbar command currently has a guaranteed one-to-one route-level test.
- Not every tool-palette icon is backed by full paint.net-equivalent behavior yet.
- The current visible tool set now has baseline zoom-tool behavior, but fuller zoom-tool parity (such as richer mode semantics) and full shape-object parity are still open.
- Utility icons on the menu bar are not yet a complete paint.net-equivalent command surface.
- Status-bar quick-help and quick-size behavior are still under-implemented relative to paint.net.
