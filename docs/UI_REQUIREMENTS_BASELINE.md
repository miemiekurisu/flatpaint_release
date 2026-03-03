# UI Requirements Baseline

## Purpose
This document defines the active FlatPaint UI baseline.
The visual reference now comes from the local Figma export in `flatpaint_design/`, not from the earlier paint.net-style UI baseline.

The archived paint.net-focused UI docs have been preserved at:
- `DocsBackup/UI_REQUIREMENTS_BASELINE.paintnet.md`
- `DocsBackup/UI_PARITY_AUDIT.paintnet.md`

This baseline changes the workspace presentation and layout rules only.
It does not reduce the existing feature surface.

## Source set
- `flatpaint_design/src/app/App.tsx`
- `flatpaint_design/src/app/components/TopMenuBar.tsx`
- `flatpaint_design/src/app/components/FloatingToolbar.tsx`
- `flatpaint_design/src/app/components/FloatingColorPanel.tsx`
- `flatpaint_design/src/app/components/FloatingHistoryPanel.tsx`
- `flatpaint_design/src/app/components/FloatingLayersPanel.tsx`
- `flatpaint_design/src/app/components/CanvasArea.tsx`
- `flatpaint_design/src/styles/theme.css`

## Core layout model
1. Workspace hierarchy
- Native macOS menu bar remains the complete command surface.
- Inside the app window, the visual structure is:
- top quick-action bar
- top tool-options bar
- document tab strip
- central canvas workspace
- bottom status strip

2. Top quick-action bar
- This row carries high-frequency commands only.
- It should surface the compact shortcut layer: New, Open, Save, Cut, Copy, Paste, Undo, Redo, palette toggles, and zoom controls.
- It should read as a light macOS-style strip, not a dark banner.

3. Top tool-options bar
- Tool-dependent controls stay on a dedicated second row below the quick-action bar.
- This is an intentional divergence from the Figma mock's inline placement because the real product has many more adjustable controls.
- The second row should continue to host dynamic controls such as:
- active tool
- size
- opacity
- hardness
- selection mode
- fill / wand / gradient / picker / shape options
- Any tool option that materially affects output must remain reachable here.

4. Document tab strip
- The existing multi-document tab strip remains directly below the tool-options row.
- The Figma mock does not show it, but the real product must keep it visible because multi-document support already exists in code.

5. Canvas region
- The canvas remains the visual center.
- The workspace background should be a light neutral gray consistent with the updated Figma shell.
- Rulers remain visible when enabled and stay integrated with the canvas area.
- The status strip remains anchored at the bottom.

## Floating panel model
1. Panels
- The primary utility surfaces remain:
- `Tools`
- `Colors`
- `History`
- `Layers`

2. Floating behavior
- These four surfaces remain floating panels inside the editor workspace.
- They are not treated as fixed dock columns.
- Overlap between panels is acceptable and matches the new design bundle as well as the current code model.

3. Movement behavior
- Panels must remain draggable by their header region.
- While dragging, panels should become semi-transparent.
- When the drag ends, they return to full opacity.
- Practical in-window clamping is still preferred so panels do not disappear outside the workspace.

4. Default placement
- Default positions should roughly follow the current code layout:
- tools upper-left
- colors lower-left
- history upper-right
- layers lower-right
- Exact overlap-free placement is desirable, but mild overlap is not a design violation by itself.

## Visual language
1. Surface style
- Prefer light neutral surfaces with subtle borders.
- Floating panels may use translucent or frosted styling, but they should remain legible over the canvas.
- Avoid the previous dark slate palette chrome as the primary visual identity.

2. Control style
- Favor compact icon or short-label controls.
- Emoji-like toolbar captions are no longer acceptable as the primary UI style.
- Header bars should be light, compact, and visibly draggable.

3. Canvas framing
- The canvas surround should be quiet and low-contrast.
- Transparency checkerboard, rulers, and selection overlays must remain clearly readable over the lighter shell.

## Functional preservation rules
1. Design is not the full spec
- The Figma export is a visual reference only.
- Missing controls in the mockup must not be treated as removed features.

2. Preserve advanced functionality
- Existing commands, dialogs, and tool options must remain available even if the design only shows a simplified subset.
- If a feature is not visible in the quick-action row or panel mock, keep it in:
- the menu bar
- the tool-options row
- the relevant dialog
- the relevant floating panel

3. Panel simplification must not remove actions
- `History` still needs undo/redo plus the timeline list.
- `Layers` still needs add/delete/duplicate/merge/visibility/properties/blend mode/list behavior.
- `Colors` still needs practical color editing, not just the visible mock controls.
- `Tools` still needs the full tool set available in code, not just the subset shown in the design file.

## Immediate implementation rules
1. Re-skin the workspace to match `flatpaint_design`, but keep the current floating-panel architecture.
2. Keep the dedicated second tool-options row under the quick-action row.
3. Keep the document tab strip below the tool-options row.
4. Preserve the status strip and ruler behavior.
5. Keep drag translucency on floating panels as a required behavior, not optional polish.

## Review rule
Before calling a UI pass complete, confirm both:
1. The window reads like the updated `flatpaint_design` composition at first glance.
2. No existing workflow became unreachable while matching the new style.
