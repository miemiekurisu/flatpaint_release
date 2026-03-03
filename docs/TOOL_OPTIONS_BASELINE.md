# Tool Options Baseline

## Governing rule
- `paint.net` remains the primary source for tool names, default ordering, and visible control surfaces.
- If paint.net's public docs are too thin for option details, use Adobe Photoshop as the secondary UX acceptance reference.
- Use GIMP as the primary backend/reference model for option semantics, raster behavior, and how tool options map to pixel operations.
- This file is code-audited against the current `TToolKind` catalog in `src/core/fpdocument.pas` and the routed GUI behavior in `src/app/mainform.pas`; do not mark a tool complete until both the visible route and the behavior exist.

## Fallback references used for this pass
- Adobe Photoshop quick-selection baseline: `https://helpx.adobe.com/photoshop/using/making-quick-selections.html`
- GIMP Fuzzy Select: `https://docs.gimp.org/2.10/en/gimp-tool-fuzzy-select.html`
- GIMP Bucket Fill: `https://docs.gimp.org/2.10/en/gimp-tool-bucket-fill.html`
- GIMP Paintbrush: `https://docs.gimp.org/2.10/en/gimp-tool-paintbrush.html`
- GIMP Pencil: `https://docs.gimp.org/2.10/en/gimp-tool-pencil.html`
- GIMP Eraser: `https://docs.gimp.org/2.10/en/gimp-tool-eraser.html`
- GIMP Clone: `https://docs.gimp.org/2.10/en/gimp-tool-clone.html`
- GIMP Text: `https://docs.gimp.org/2.10/en/gimp-tool-text.html`

## Current code-audited tool coverage

### Live now
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

### Still missing from the target baseline
- True inline text editing (modal dialog exists; inline canvas text entry deferred)
- True line/curve dual-mode tool (line tool exists; curve editing deferred)
- Square brush mode for eraser
- Sample-source controls for paint bucket (layer vs composite still deferred for Fill)
- Aligned-clone toggle for Clone Stamp
- Hue preservation toggle for Recolor
- Feather option for selection tools

## Required per-tool option baseline

| Tool family | Current code | Required visible options for parity | Notes |
| --- | --- | --- | --- |
| Rectangle / Ellipse / Lasso Select | Drag selection + replace/add/subtract/intersect | Selection mode (`Replace`, `Add`, `Subtract`, `Intersect`), edge quality (`Aliased` vs `Anti-aliased`), feather deferred | Selection mode combo is functional (keyboard modifiers override only when held; combo value used otherwise); the anti-alias checkbox is now hidden until the core selection APIs can consume it |
| Magic Wand | Tolerance + replace/add/subtract/intersect + **Contiguous TCheckBox live** + **Sample Source TComboBox live** | Selection mode, tolerance, contiguous toggle, sample source (`Layer` / `Image`), edge quality | All primary visible options now present; anti-alias on wand still deferred |
| Move Selection / Move Selected Pixels | Real mask / pixel movement | Move mode stays tool-defined; no extra options required beyond future nudge settings | Already backed by real shared-core movement paths |
| Zoom | Preset zoom ladder, toolbar chooser, status slider | Zoom mode (`In` / `Out`), optional scrub zoom deferred | Current code supports left-click in / right-click out plus menu and slider parity |
| Pan | Hand-style viewport drag | No heavy options required; future "spacebar temporary hand" is optional | User-facing expectation follows Photoshop/GIMP hand tool behavior |
| Paint Bucket | Flood fill on active layer + **Fill mode TComboBox live** + **Tolerance TSpinEdit live** | Fill mode (`Contiguous` / `Global`), tolerance, sample source (`Layer` / `Image`) | Contiguous/global + tolerance now visible; sample source still deferred |
| Gradient | **Type TComboBox (Linear/Radial) live** + **Reverse TCheckBox live** + `FillRadialGradient` wired | Gradient type, reverse, alpha mode deferred | Linear and radial gradient types now selectable with reverse; alpha mode deferred |
| Pencil | Size, hard-edge | Size, hard-edge behavior, future square/round shape choice | Zero-radius line drawing for true single-pixel steps at size `1` |
| Brush | Size, opacity (**live**), hardness (**live**) | Size, opacity, shape, hardness | All three primary options now visible |
| Eraser | Size, opacity (**live**), hardness (**live**) | Size, shape (`Round` / `Square`), hardness deferred | Opacity and hardness now visible; square mode deferred |
| Color Picker | Primary/secondary via mouse button + **Sample Source TComboBox (Current Layer / All Layers) live** | Target (`Primary` / `Secondary`), sample source (`Layer` / `Image`) | Sample source now wired; left=primary/right=secondary remains |
| Line / Shapes | Width + **Shape style TComboBox (Outline / Fill / Outline+Fill) live** | Width, line style, fill (`Outline` / `Fill` / `Fill+Outline`), shape-kind chooser | Shape style combo live; line-style/dash and shape-kind chooser still deferred |
| Clone Stamp | Brush size + opacity + right-click sample live | Aligned toggle, sample-on-Option-click | Core sampling now respects brush radius and opacity; aligned toggle still deferred |
| Recolor | Brush size + opacity + tolerance live | Tolerance, source hue preservation toggle | Visible tolerance is now routed through the shared tolerance spin while `Recolor` is active; hue preservation remains deferred |
| Text | Font family, size, bold/italic (modal dialog) | Full inline text entry with alignment | Modal text flow live; inline text editing deferred |

## Acceptance rules
- If a tool appears in the visible `Tools` palette, its main action must work on real pixels or viewport state and must be testable.
- If a tool has a visible option control, that option must have helper-level or core-level unit coverage.
- Do not claim the tool-options surface complete while modifier-only hidden behavior is standing in for a required visible paint.net-style control.
