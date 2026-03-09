# Tool Options Baseline

## Governing rule
- `paint.net` remains the primary source for tool names, default ordering, and visible control surfaces.
- If paint.net's public docs are too thin for option details, use Adobe Photoshop as the secondary UX acceptance reference.
- Use GIMP as the primary backend/reference model for option semantics, raster behavior, and how tool options map to pixel operations.
- This file is code-audited against the current `TToolKind` catalog in `src/core/fpdocument.pas` and the routed GUI behavior in `src/app/mainform.pas`; do not mark a tool complete until both the visible route and the behavior exist.

## Fallback references used for this pass
- Adobe Photoshop quick-selection baseline: `https://helpx.adobe.com/photoshop/using/making-quick-selections.html`
- Adobe Photoshop selecting/deselecting baseline: `https://helpx.adobe.com/photoshop/using/selecting-deselecting-areas.html`
- GIMP Fuzzy Select: `https://docs.gimp.org/2.10/en/gimp-tool-fuzzy-select.html`
- GIMP selection tool baseline: `https://docs.gimp.org/2.10/en/gimp-tools-selection.html`
- GIMP rectangle selection interaction baseline: `https://docs.gimp.org/2.10/en/gimp-tool-rect-select.html`
- GIMP Bucket Fill: `https://docs.gimp.org/2.10/en/gimp-tool-bucket-fill.html`
- GIMP Paintbrush: `https://docs.gimp.org/2.10/en/gimp-tool-paintbrush.html`
- GIMP Pencil: `https://docs.gimp.org/2.10/en/gimp-tool-pencil.html`
- GIMP Eraser: `https://docs.gimp.org/2.10/en/gimp-tool-eraser.html`
- GIMP Clone: `https://docs.gimp.org/2.10/en/gimp-tool-clone.html`
- GIMP Text: `https://docs.gimp.org/2.10/en/gimp-tool-text.html`

## Current code-audited tool coverage

### Live now
- Startup default active tool: Rectangle Select
- Rectangle Select
- Ellipse Select
- Lasso Select
- Magic Wand
- Move Selection
- Move Selected Pixels
- Zoom
- Pan
- Paint Bucket
- Gradient
- Pencil
- Brush
- Eraser
- Color Picker
- Clone Stamp
- Recolor
- Crop
- Text
- Line
- Rectangle
- Rounded Rectangle
- Ellipse
- Freeform Shape

### 2026-03-09 completeness snapshot (fixed tool set, GIMP parity lens)
- Overall tool routing completeness: `24/24` tools have visible UI route + executable path.
- Overall parity depth against GIMP same-tool expectations: `Partial` (roughly medium maturity).
- Main deficit category is no longer "missing tool entries"; it is "option semantics and depth not yet equivalent".

### Still missing from the target baseline
- Magic Wand edge/refinement depth is still narrower than GIMP-class workflows (for example richer edge policy and post-select refinement routes).
- Text tool now supports multiline + left/center/right alignment, but still lacks deeper paragraph typography controls (for example line spacing and text-box wrapping policy).
- Shape family still lacks deeper post-commit node editing.

## Required per-tool option baseline

| Tool family | Current code | Required visible options for parity | Notes |
| --- | --- | --- | --- |
| Rectangle / Ellipse / Lasso Select | Drag selection + replace/add/subtract/intersect + anti-alias + feather controls | Selection mode (`Replace`, `Add`, `Subtract`, `Intersect`), edge quality (`Aliased` vs `Anti-aliased`), feather radius spinner (0–128) | Anti-alias and feather are now semantically decoupled: anti-alias controls edge coverage generation, feather applies independently by radius. Ellipse/Lasso support explicit aliased vs anti-aliased mask generation; rectangle route also follows the anti-alias control path. |
| Magic Wand | Tolerance + replace/add/subtract/intersect + **Contiguous TCheckBox live** + **Sample Source TComboBox live** | Selection mode, tolerance, contiguous toggle, sample source (`Layer` / `Image`) | Core behavior is usable and test-backed. To avoid misleading semantics, anti-alias is not shown for wand in the current UI path. |
| Move Selection / Move Selected Pixels | Real mask / pixel movement | Move mode stays tool-defined; no extra options required beyond future nudge settings | Already backed by real shared-core movement paths |
| Zoom | Preset zoom ladder, toolbar chooser, status slider | Zoom mode (`In` / `Out`), optional scrub zoom deferred | Current code supports left-click in / right-click out plus menu and slider parity |
| Pan | Hand-style viewport drag | No heavy options required; future "spacebar temporary hand" is optional | User-facing expectation follows Photoshop/GIMP hand tool behavior |
| Paint Bucket | Flood fill on active layer + **Fill mode TComboBox live** + **Tolerance TSpinEdit live** + **Sample Source TComboBox live** | Fill mode (`Contiguous` / `Global`), tolerance, sample source (`Layer` / `Image`) | Contiguous/global + tolerance + sample source now visible; global mode now replaces every matching color instead of clearing the layer |
| Gradient | **Type TComboBox (Linear/Radial/Conical/Diamond) live** + **Repeat TComboBox (None/Sawtooth/Triangular) live** + **Reverse TCheckBox live** + `FillGradientAdvanced` wired | Gradient type, repeat, reverse, alpha mode | Shape and repeat families are now visible and routed. Remaining depth debt is advanced controls such as alpha-function editing and midpoint/offset tuning. |
| Pencil | Size, hard-edge | Size, hard-edge behavior, future square/round shape choice | Zero-radius line drawing for true single-pixel steps at size `1` |
| Brush | Size, opacity (**live**), hardness (**live**) | Size, opacity, shape, hardness | All three primary options now visible |
| Eraser | Size, opacity (**live**), hardness (**live**), **Shape ComboBox live** | Size, shape (`Round` / `Square`), hardness | Opacity, hardness, and round/square tip shape are now visible and routed; square mode uses a real square raster path plus matching hover preview |
| Color Picker | Primary/secondary via mouse button + **Sample Source TComboBox (Current Layer / All Layers) live** | Target (`Primary` / `Secondary`), sample source (`Layer` / `Image`) | Sample source now wired; left=primary/right=secondary remains |
| Line / Shapes | Width + **Shape style TComboBox (Outline / Fill / Outline+Fill) live** + **Line style TComboBox (Solid / Dashed) live** + **Rounded radius spin (px) live** | Width, line style, fill (`Outline` / `Fill` / `Fill+Outline`), shape-kind chooser | Shape style, line-style, and rounded-corner radius controls are live. Remaining parity depth is richer post-commit node editing. |
| Clone Stamp | Brush size + opacity + right-click / Option-click sample + **Aligned TCheckBox live** + **Sample Source (`Current Layer` / `Image`) live** | Aligned toggle, sample-on-Option-click, sample-source policy | Core sampling respects brush radius/opacity; aligned sampling is stable across strokes; current-layer vs composite-image sampling is now routed. Remaining depth debt is advanced source transform/perspective workflows. |
| Recolor | Brush size + opacity + **dedicated tolerance (separate from wand)** live + **Preserve Value TCheckBox live** | Tolerance, source hue preservation toggle | Visible tolerance is routed through the shared tolerance spin while `Recolor` is active, backed by a dedicated `FRecolorTolerance` field that does not share state with Magic Wand; `Preserve Value` now keeps original brightness while shifting hue/saturation |
| Text | Inline canvas text entry on left-click + font family/size/bold/italic style dialog on right-click / `Option`-click + **alignment combo (`Left/Center/Right`) live** + multiline inline editor | Full inline text entry with alignment/paragraph controls | Inline entry is stable and now supports multiline + left/center/right alignment in both editor and raster commit path. Remaining parity depth is richer paragraph/box layout control. |

## Acceptance rules
- If a tool appears in the visible `Tools` palette, its main action must work on real pixels or viewport state and must be testable.
- If a tool is expected to act on the canvas directly, it must also provide at least minimal visible hover, click, or drag feedback on the canvas instead of feeling inert until after a hidden state change.
- If a visible tool option changes anything the canvas can preview, that option change must trigger an immediate repaint of the canvas preview instead of waiting for the next pointer event.
- Programmatic control-sync paths must be guarded separately from user-edit paths before adding repaint side effects, or the UI will drift into noisy re-entrant updates.
- If a tool has a visible option control, that option must have helper-level or core-level unit coverage.
- Do not claim the tool-options surface complete while modifier-only hidden behavior is standing in for a required visible paint.net-style control.
