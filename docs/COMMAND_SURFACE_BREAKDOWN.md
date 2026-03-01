# Command Surface Breakdown

## Purpose
This document decomposes the visible paint.net-style command surface into implementation packages.
It exists so work is driven by command completeness, not by isolated backend functions.

## Package 1: Document shell and navigation
### Scope
- Title state
- Image list / tab strip
- New-image size dialog
- Document switching
- Document close from the tab strip
- Unsaved markers

### Acceptance
- More than one image can be open at once
- The user can switch images from visible thumbnails
- New document creation always presents a size choice
- Unsaved state is visible in both title and image-list surface

### Required tests
- Core document-session tests
- Image-list command tests
- Image-list reorder tests
- New-document dialog flow tests

## Package 2: File surface
### Scope
- Every `File` menu command
- Matching toolbar routes for New / Open / Save / Print
- Save-sheet and export-sheet options

### Acceptance
- Every visible file command performs the matching action
- Commands with dialogs expose the expected options
- Open and Import remain semantically distinct

### Required tests
- One test per visible `File` command
- Route-equivalence tests for matching toolbar icons
- Integration tests for file-backed workflows

## Package 3: Edit surface
### Scope
- Every `Edit` menu command
- Matching toolbar routes for Cut / Copy / Paste / Crop / Deselect / Undo / Redo
- Selection-dependent command behavior

### Acceptance
- Clipboard, selection, and history actions behave correctly with and without an active selection
- Toolbar routes invoke the same command path as menu routes

### Required tests
- One test per visible `Edit` command
- Route-equivalence tests for every matching toolbar icon
- Serialized integration coverage for global pasteboard paths

## Package 4: View surface
### Scope
- Every `View` menu command
- Toolbar view controls
- Zoom tool
- Pan tool
- Status-bar zoom controls
- Quick-size behavior

### Acceptance
- Non-destructive view actions never pollute document history
- Zoom behavior is smooth, reversible, and reachable from all visible routes
- Units, rulers, and grid settings stay in sync across toolbar and status bar

### Required tests
- One test per visible `View` command
- Route-equivalence tests for toolbar and status-bar view controls
- Interaction tests for pinch zoom, pan drag, and quick-size toggle semantics

## Package 5: Image and layer geometry
### Scope
- Every `Image` menu command
- Every `Layers` menu command
- Crop commands
- Resize/canvas-size dialogs
- Layer import, properties, and transform flows

### Acceptance
- Whole-image and per-layer geometry commands affect the correct target
- Layer-only commands do not silently fall back to whole-document behavior

### Required tests
- One test per visible `Image` command
- One test per visible `Layers` command
- Dialog-path tests for size/property commands

## Package 6: Tool palette completeness
### Scope
- Every visible tool icon
- Tool-specific parameter surfaces
- Tool keyboard shortcuts

### Acceptance
- Every visible tool performs real editing or real view behavior
- Tool parameters materially affect output
- Selection tools, paint tools, and shape tools all match the expected interaction model

### Required tests
- One dedicated behavior test per tool
- One route-equivalence test per visible tool icon
- Interaction tests for drag-path tools

## Package 7: Utility icons and utility windows
### Scope
- Menu-bar utility icons
- Tools / History / Layers / Colors windows
- Window reset and visibility toggles
- Constrained in-window dragging

### Acceptance
- Every utility icon toggles or resets the matching utility window
- Utility windows stay within the main workspace model
- Movement feedback remains usable and non-obstructive

### Required tests
- One test per utility icon
- Window visibility tests
- Movement-constraint tests

## Package 8: Status bar
### Scope
- Tool help
- Render progress
- Image size
- Pointer position
- Units
- Zoom controls

### Acceptance
- Status bar reflects current document and tool state in real time
- Zoom and unit controls are not read-only decorations

### Required tests
- State-propagation tests
- Route-equivalence tests for any clickable status-bar controls

## Test contract
1. No menu item may be marked complete without at least one command-level automated test.
2. No toolbar icon may be marked complete without at least one route-level automated test.
3. No tool icon may be marked complete without at least one dedicated tool-behavior test.
4. If one visible control routes to another command, that equivalence must still be tested explicitly.
5. Broad smoke tests are allowed, but they do not replace per-surface tests.
