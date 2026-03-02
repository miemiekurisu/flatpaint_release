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
- Line
- Rectangle
- Rounded Rectangle
- Ellipse
- Freeform Shape

### Still missing from the target baseline
- Crop tool (menu crop exists, but not a dedicated interactive tool)
- Clone Stamp
- Recolor
- Text
- True line/curve dual-mode tool
- Direct shape fill toggle / line-style controls
- Explicit visible selection-mode UI (`Replace / Add / Subtract / Intersect`)
- Explicit sample-source controls (`Current Layer` vs `Composite Image`) for wand/fill/picker

## Required per-tool option baseline

| Tool family | Current code | Required visible options for parity | Notes |
| --- | --- | --- | --- |
| Rectangle / Ellipse / Lasso Select | Drag selection plus modifier-based replace/add/subtract/intersect | Selection mode (`Replace`, `Add`, `Subtract`, `Intersect`), edge quality (`Aliased` vs `Anti-aliased`), feather deferred | Current code now exposes intersect through `Shift+Option`, but the full explicit visible mode control is still missing |
| Magic Wand | Contiguous region select with tolerance plus replace/add/subtract/intersect combine | Selection mode, tolerance, contiguous toggle, sample source (`Layer` / `Image`), edge quality | Current code now supports the combine family in core, but still only exposes tolerance as a visible option |
| Move Selection / Move Selected Pixels | Real mask / pixel movement | Move mode stays tool-defined; no extra options required beyond future nudge settings | Already backed by real shared-core movement paths |
| Zoom | Preset zoom ladder, toolbar chooser, status slider | Zoom mode (`In` / `Out`), optional scrub zoom deferred | Current code supports left-click in / right-click out plus menu and slider parity |
| Pan | New hand-style viewport drag | No heavy options required; future "spacebar temporary hand" is optional | User-facing expectation follows Photoshop/GIMP hand tool behavior |
| Paint Bucket | Flood fill on active layer | Fill mode (`Contiguous` / `Global`), tolerance, sample source (`Layer` / `Image`) | Current code currently uses one fixed contiguous flood-fill path with hardcoded tolerance |
| Gradient | Linear two-point gradient | Gradient type (start with `Linear`), reverse, alpha mode deferred | Current code is a fixed linear primary→secondary gradient |
| Pencil | Hard-edged stroke | Size, hard-edge behavior, future square/round shape choice | Current code now uses zero-radius-capable line drawing for true single-pixel steps at size `1` |
| Brush | Soft round stroke baseline | Size, opacity, shape, hardness | Current code only exposes size |
| Eraser | Transparency paint | Size, shape (`Round` / `Square`), hardness deferred | Current code only exposes size and uses transparent brush semantics |
| Color Picker | Composite sample to primary/secondary | Target (`Primary` / `Secondary`), sample source (`Layer` / `Image`) | Current code supports primary via left-click and secondary via right-click |
| Line / Shapes | Outline draw only | Width, line style, fill (`Outline` / `Fill` / `Fill+Outline`), shape-kind chooser | Current code exposes width only and outlines only |
| Clone Stamp | Missing | Brush size, aligned toggle, sample-on-Option-click | Implement against GIMP-style source sampling, but keep Photoshop-style option naming if paint.net is unclear |
| Recolor | Missing | Tolerance, source hue preservation toggle | Implement as a constrained local-color replace, not a full adjustment dialog |
| Text | Missing | Font family, size, weight/style, anti-alias, alignment | Requires a dedicated text entry flow; current code has no routed text tool |

## Acceptance rules
- If a tool appears in the visible `Tools` palette, its main action must work on real pixels or viewport state and must be testable.
- If a tool has a visible option control, that option must have helper-level or core-level unit coverage.
- Do not claim the tool-options surface complete while modifier-only hidden behavior is standing in for a required visible paint.net-style control.
