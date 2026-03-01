# UI Requirements Baseline

## Purpose
This document normalizes the shared UI rules that are consistent across paint.net, Adobe Photoshop, GIMP, Photopea, and modern browser-based editors such as Pixlr.
It exists so FlatPaint UI work follows explicit layout and interaction requirements instead of ad hoc taste.

## Source set
- paint.net Main Window: `https://www.getpaint.net/doc/latest/MainWindow.html`
- paint.net Toolbar: `https://www.getpaint.net/doc/latest/Toolbar.html`
- paint.net Status Bar: `https://www.getpaint.net/doc/latest/StatusBar.html`
- Adobe Photoshop workspace basics: `https://helpx.adobe.com/photoshop/using/workspace-basics.html`
- GIMP dockable dialogs: `https://docs.gimp.org/2.10/en/gimp-concepts-docks.html`
- GIMP toolbox: `https://docs.gimp.org/2.10/en/gimp-toolbox.html`
- Photopea workspace docs: `https://www.photopea.com/learn/workspace`
- Pixlr product UI (current web app class reference): `https://pixlr.com/`

## Normalized cross-editor UI requirements
1. Canvas positioning
- The editable image must be the visual center of the workspace.
- When the rendered canvas is smaller than the viewport, it must be centered horizontally and vertically.
- When the rendered canvas is larger than the viewport, scroll origin may move, but zoom commands should preserve a clear focal point instead of snapping the image to a corner.
- `Open`, `New`, `Fit to Window`, `Actual Size`, and `Zoom to Selection` should all leave the canvas in an intentional position, not just update scale.

2. Zoom control model
- The primary quick-zoom control should live at the bottom-right of the status bar region.
- A compact horizontal zoom slider plus a percentage readout is the dominant pattern across paint.net-class editors.
- `Fit to Window` and `100%` should be one click away from that bottom-right cluster.
- A top-toolbar zoom chooser may exist, but it is secondary to the status-bar quick zoom.

3. Gesture behavior
- Trackpad pinch / magnify must zoom smoothly.
- Gesture zoom should be viewport-centric (or cursor-centric) and should not record undo history.
- Wheel / trackpad scrolling and zooming should feel continuous, not step-jumpy, whenever the toolkit allows it.

4. Workspace zoning
- Top: dense command surface (menu + main toolbar).
- Left: primary tool stack.
- Right: utility panels / docks (`Layers`, `History`, `Colors`, properties).
- Center: canvas viewport.
- Bottom: status strip with hints, metrics, and zoom.
- This zoning is consistent enough across the reference products that breaking it should be treated as a deliberate exception.

5. Utility panel behavior
- Panels should be compact, dockable or palette-like, and visually subordinate to the canvas.
- Panels should support closing, re-showing, and predictable reset to a default layout.
- Default layout matters: users should not need to manually arrange basic panels after launch.

6. Document surfacing
- Multiple documents are normally exposed as a visible tab strip, thumbnail strip, or document bar near the top of the workspace.
- Switching documents should be one-click.
- Unsaved state should be visible at the document surface, not only in the window title.

7. Toolbar density
- Toolbar controls should be compact, icon-first, and tightly grouped by function.
- Repeated controls should be avoided unless the duplicate surface has a clearly different role.
- Spacing and chrome should read like a desktop editor, not a generic form.

8. Canvas-first safety rules
- Large images should open fit-first.
- Small images should stay centered and not collapse to the top-left.
- Scrollbars, rulers, and overlays must support the canvas, not push it out of the primary visual focus.

## FlatPaint code comparison (current)
1. Canvas centering
- Implemented as a baseline invariant.
- `UpdateCanvasSize` now centers the canvas host child when the rendered image is smaller than the viewport and clears stale scroll offsets in those centered directions.
- The shared zoom route now preserves an explicit anchor point while still recentering the canvas correctly when the scaled image drops below the viewport size.
- Result: small documents now read as visually centered instead of collapsing toward the scroll origin.

2. Bottom-right zoom control
- Implemented as the primary quick-zoom path.
- The status bar now exposes a horizontal zoom slider plus the percentage readout, and the slider stays synchronized with the rest of the zoom commands instead of becoming a stale secondary control.
- The top-toolbar zoom chooser still exists, but it now reads as the secondary precision chooser rather than the only dense zoom surface.

3. Gesture zoom
- Partially implemented.
- The current Lazarus GUI source still has no dedicated magnification gesture recognizer, so true native pinch parity is still open.
- A practical cross-editor fallback now exists: `Ctrl` / `Command` modified wheel input zooms the viewport around the pointer anchor, which closes the old command-only gap while the native pinch path remains open.

4. Document surface
- Not implemented yet.
- The main form still owns one `TImageDocument`, and there is no real image-list / document-tab control in the current code path.

5. Workspace zoning
- Partially implemented.
- The current app does have a top command strip, left tools, right-side utility panels, and a bottom status strip.
- The basic zones now exist, but centering, density, and exact role separation are still weaker than the baseline.

6. Utility panels
- Partially implemented.
- `Tools`, `Colors`, `History`, and `Layers` exist and can be shown/hidden.
- The remaining gap is tighter docking behavior, denser layout, and more accurate default placement.

7. Toolbar density
- Partially implemented.
- Functionally stronger than before, but still too loose and too horizontally spread compared with paint.net / Photoshop / Photopea class editors.

## Immediate UI implementation rules
1. Keep canvas centering as a non-negotiable viewport invariant.
2. Keep the status-bar slider as the primary quick-zoom surface.
3. Keep the top zoom combo only as a secondary precision control.
4. Add smooth trackpad pinch zoom before claiming the viewport interaction is mature.
5. Do not claim image-list parity until a real multi-document surface exists in code.
6. Use this document together with `docs/UI_PARITY_AUDIT.md`:
- `UI_REQUIREMENTS_BASELINE.md` defines cross-editor rules.
- `UI_PARITY_AUDIT.md` remains paint.net-specific.

## Priority order
1. Trackpad pinch zoom
2. Real document tab / image-list surface
3. Palette docking and density refinement
4. Final iconography and spacing polish
