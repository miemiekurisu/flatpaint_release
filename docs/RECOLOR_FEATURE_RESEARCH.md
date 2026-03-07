# Recolor Feature Research (Photoshop/Open-source/FlatPaint)

## Scope and rule
- Goal: assess whether FlatPaint should keep and enhance `Recolor`, and define a concrete capability list before implementation.
- Rule: architecture reference only for GPL projects (no code/identifier copying).
- Research date: 2026-03-07.

## Primary references
- Adobe Photoshop user guide (Color Replacement Tool / Replace Color):
  - https://helpx.adobe.com/photoshop/using/matching-replacing-mixing-colors.html
- paint.net manual (Recolor tool):
  - https://www.getpaint.net/doc/latest/RecolorTool.html
- GIMP manual (Color Exchange):
  - https://docs.gimp.org/2.10/en/gimp-filter-color-exchange.html
- GIMP source architecture anchors (local reference only):
  - `reference/gimp-src/app/actions/filters-actions.c` (`gegl:color-exchange` route)
  - `reference/gimp-src/app/core/gimpdrawable-bucket-fill.c` (selection/sample-merged/fill-mask decomposition pattern)
- Pinta source architecture anchors (MIT):
  - `reference/pinta-src/Pinta.Tools/Tools/RecolorTool.cs`
  - `reference/pinta-src/Pinta.Core/Classes/Document.cs` (`CreateClippedContext` selection clipping contract)

## Photoshop recolor capability list
1. Brush-based Color Replacement Tool:
- Replaces sampled color while preserving shading/texture characteristics.
- Supports sampling modes: `Continuous`, `Once`, `Background Swatch`.
- Supports limits: `Contiguous`, `Discontiguous`, `Find Edges`.
- Supports tolerance and anti-alias.
- Supports replacement mode: `Hue`, `Saturation`, `Color`, `Luminosity`.

2. Dialog-based Replace Color command:
- Global/targeted recolor via eyedropper sample + fuzziness.
- Supports add/remove sampled colors.
- Supports `Localized Color Clusters` and range.
- Supports hue/saturation/lightness output shifts.

## Open-source implementation survey
1. GIMP (high completeness, filter-centric):
- Has `Color Exchange` with explicit `From`/`To` color and hue/sat/lightness thresholds.
- Routed as operation/filter (`gegl:color-exchange`) rather than a paint brush tool.
- Architecture emphasizes operation graph + selection/mask-aware core application.

2. Pinta (high relevance, tool-centric):
- Has dedicated `RecolorTool` with brush, tolerance slider, and left/right semantic swap.
- Uses temporary tool layer + stencil cache to avoid redundant pixel checks.
- Applies through clipped context, so active selection scope is enforced centrally.

## FlatPaint current state (code-first)
1. Implemented:
- `tkRecolor` tool exists and is wired in tool metadata:
  - `src/app/fpuihelpers.pas`
- Core recolor algorithm exists:
  - `src/core/fpsurface.pas` `RecolorBrush(...)`
- Selection coverage is honored in recolor path:
  - `ASelection.Coverage(...)` branch in `RecolorBrush(...)`
- Tolerance and preserve-value options exist in UI state:
  - `src/app/mainform.pas` (`FRecolorTolerance`, `FRecolorPreserveValue`)

2. Gaps versus Photoshop baseline:
- Missing sampling mode (`Continuous` / `Once` / `Background Swatch` equivalent).
- Missing limits mode (`Contiguous` / `Discontiguous` / `Find Edges`).
- Missing recolor mode matrix (`Hue` / `Saturation` / `Color` / `Luminosity`) as explicit option.
- Missing dialog-based global replace workflow (`Replace Color` equivalent).
- Current source-color semantics are swatch-derived, not click-sampled by default:
  - `src/app/mainform.pas:7330`

3. Known UX inconsistency:
- Recolor hint text describes “replace specific color with foreground color”, but runtime source selection is tied to color slot state and mouse button branch, not explicit sampled source workflow.

## Text tool visibility finding (requested side investigation)
- `tkText` is present in display order:
  - `src/app/fpuihelpers.pas:41-66`
- Tools panel builds 2-column grid with fixed row stride:
  - `src/app/mainform.pas:3299-3343`
- Panel default height is currently fixed:
  - `src/app/fppalettehelpers.pas:52`
- With current tool count, final row is clipped at startup/default palette geometry; this explains user-observed “Text tool seems missing”.

## Feasibility decision
- Keep `Recolor`; do not remove.
- Reason: both commercial baseline (Photoshop) and open-source comparables (GIMP/Pinta) provide mature reference behavior; FlatPaint already has usable core primitives and only lacks option/model layering and UX decomposition.

## Recommended implementation priority (safe, incremental)
1. P0 (must-have):
- Fix text-tool visibility clipping.
- Clarify recolor behavior contract in UI/docs and add route-level tests.

2. P1 (Photoshop-aligned core):
- Add recolor sampling mode (`Once` + `Continuous`; swatch mode as compatibility fallback).
- Add recolor mode (`Color` first; then `Hue`/`Saturation`/`Luminosity`).

3. P2 (parity depth):
- Add limits mode (`Contiguous`/`Discontiguous`/`FindEdges`).
- Add dialog-based targeted/global replace color route.

4. P3 (performance/polish):
- Optional stroke stencil cache and preview layer path for large brushes/documents.

## Anti-GPL contamination note
- GIMP references above are used only to extract architecture patterns (operation routing, selection/mask boundaries, preview/commit separation).
- No GPL code, comments, identifiers, or data tables should be copied into FlatPaint.
