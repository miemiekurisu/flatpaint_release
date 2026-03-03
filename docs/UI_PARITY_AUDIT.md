# UI Parity Audit

## Purpose
This document tracks FlatPaint's UI alignment against the active local Figma baseline in `flatpaint_design/`.
It is no longer a paint.net-specific visual audit.

The old paint.net visual audit has been archived to:
- `DocsBackup/UI_PARITY_AUDIT.paintnet.md`

## Active visual authority
- `flatpaint_design/src/app/App.tsx`
- `flatpaint_design/src/app/components/TopMenuBar.tsx`
- `flatpaint_design/src/app/components/FloatingToolbar.tsx`
- `flatpaint_design/src/app/components/FloatingColorPanel.tsx`
- `flatpaint_design/src/app/components/FloatingHistoryPanel.tsx`
- `flatpaint_design/src/app/components/FloatingLayersPanel.tsx`
- `flatpaint_design/src/app/components/CanvasArea.tsx`

## Baseline target
1. Top region
- A light quick-action bar at the top
- A separate second tool-options bar underneath it
- The document tab strip still present below those two rows

2. Workspace body
- Full canvas area in the center
- Light neutral workspace surround
- Rulers integrated into the canvas zone

3. Floating panels
- Four floating panels remain visible as the primary utility model:
- `Tools`
- `Colors`
- `History`
- `Layers`
- These panels may overlap.
- They are draggable and become semi-transparent during movement.

4. Bottom region
- A compact light status strip remains visible and information-dense.

## Current code alignment
1. Already aligned in behavior
- The current code already uses four floating workspace panels.
- Dragging already applies translucency through Cocoa view alpha.
- The current code already keeps a dedicated second tool-options row.
- The current code already keeps the document tab strip separate from the toolbar.

2. Still visually misaligned
- The current toolbar is still too dark and too text-heavy.
- Emoji-like captions and older dark-surface chrome do not match the new design direction.
- Floating panel surfaces still read more like dark utility palettes than light translucent cards.
- The status strip is still functionally strong, but visually closer to the older dark-shell aesthetic than the new light Figma reference.

## Required parity targets
1. Toolbar restyling
- Convert the top shell from the old dark command strip toward the new light quick-action presentation.
- Keep grouped actions and right-side zoom controls.

2. Tool-options row retention
- Keep the second row.
- Restyle it to visually belong to the new top shell while preserving the broader option set that the mock does not show.

3. Floating-panel restyling
- Keep the panels floating.
- Keep overlap allowed.
- Keep drag translucency.
- Restyle headers, borders, and surfaces to match the lighter translucent Figma direction.

4. Canvas region restyling
- Shift the workspace surround, ruler chrome, and status strip toward the lighter design palette.
- Preserve canvas-first readability.

## Non-goals
- Do not remove the second tool-options row just because the Figma mock compresses controls into one row.
- Do not replace floating panels with fixed sidebars.
- Do not remove document tabs because the mock omits them.
- Do not remove advanced feature routes that are not shown in the visual prototype.

## UAT blockers for this visual target
- The top area must clearly read as two coordinated rows, not one overloaded strip.
- The floating panels must look like the new design while keeping their current behavior.
- The old dark paint.net-style shell chrome must no longer dominate the interface.
- Existing tool-option density must still fit comfortably on the second row.

## Review rule
Before approving a UI pass:
1. Compare against the local `flatpaint_design` layout first.
2. Confirm that floating panels, drag translucency, the second tool-options row, and document tabs are all still present and functional.
