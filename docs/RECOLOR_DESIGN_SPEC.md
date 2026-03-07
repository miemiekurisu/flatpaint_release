# Recolor Design Spec (FlatPaint)

## Status
- Implemented through Phase R2 on 2026-03-07.
- This document is code-first aligned; sections below distinguish landed behavior vs deferred R3 depth.

## Product objective
- Make `Recolor` predictable, selection-safe, and close to Photoshop mental model while keeping FlatPaint lightweight.

## Non-goals
- Full Photoshop parity in one pass.
- New heavyweight non-destructive stack in this phase.
- Any GPL code reuse.

## Current implementation baseline
- Entry route: `tkRecolor` in `TMainForm.ApplyImmediateTool`.
- Core primitive: `TRasterSurface.RecolorBrush(...)`.
- Current options: brush size/opacity, tolerance, preserve value, sampling mode (`Once`/`Continuous`/`SwatchCompat`), and recolor mode (`Color`/`Hue`/`Saturation`/`Luminosity`/`ReplaceCompat`).

## Architecture constraints
1. Keep core mutation through `MutableActiveLayerSurface` guard-coupled routes.
2. Keep selection scoping enforced in core apply calls (`ASelection` mask path).
3. Avoid UI-only state branching for pixel mutation correctness.

## Target behavior model
1. Recolor inputs:
- `source color` (match color)
- `target color` (replacement output intent)
- `tolerance`
- `mode` (`Color` first, then `Hue` / `Saturation` / `Luminosity`)
- `sampling mode` (`Once` / `Continuous`, optional compatibility `Swatch`)
- `selection mask` (always enforced when present)

2. Stroke semantics:
- `Once`: sample source at stroke start and keep stable until mouse-up.
- `Continuous`: re-sample source around cursor during drag.
- Right-click keeps reverse target semantics only when explicitly enabled; default should prioritize clarity.

3. Scope contract:
- Paint attributes tools (line/shape/brush/recolor/etc.) are not clipped by selection boundary geometry preview logic.
- Pixel mutation from recolor is clipped only by active selection coverage mask if selection exists.

## Phase plan
### Phase R1 (safe baseline)
1. Completed: tool visibility regression fixed (`Text` no longer clipped by default tools-panel height).
2. Completed: route-level recolor pipeline tests added:
- selection-scoped recolor modifies inside but not outside
- recolor undo/redo symmetry
- source sampling contract test (once-mode)
3. Completed: UI options and runtime semantics aligned.

### Phase R2 (Photoshop-aligned options)
1. Completed: recolor sampling mode state + UI control.
2. Completed: recolor mode enum and core mapping path (`Color/Hue/Saturation/Luminosity/ReplaceCompat`).
3. Completed: preserve-value bridge retained for compatibility behavior.

### Phase R3 (parity depth and performance)
1. Add limits mode behavior.
2. Optional cached/stencil-assisted per-stroke traversal for large documents.
3. Optional replace-color dialog route for targeted/global recolor.

## Data model additions (implemented)
- `TRecolorSamplingMode = (rsmOnce, rsmContinuous, rsmSwatchCompat)`
- `TRecolorBlendMode = (rbmReplaceRGBCompat, rbmColor, rbmHue, rbmSaturation, rbmLuminosity)`
- Runtime stroke state:
  - `FRecolorStrokeSourceColor`
  - `FRecolorStrokeSourceValid`

## Test strategy
1. Core tests (`fpsurface_tests`):
- mode-specific output expectations (`Color/Hue/Saturation/Luminosity`)
- tolerance edge behavior
- preserve alpha and selection coverage

2. Pipeline tests (`pipeline_integration_tests`):
- mouse-down/move/up recolor route correctness
- selection scoping and undo depth
- no regression to non-recolor tools

3. UI contract tests:
- tool palette can display final-row tools including `tkText`

## Risk and mitigation
1. Risk: recolor semantics change can break existing user habit.
- Mitigation: keep optional compatibility swatch mode.

2. Risk: tool options bar crowding.
- Mitigation: stage controls; keep advanced controls collapsed until R3.

3. Risk: hidden regressions in high-frequency paint loop.
- Mitigation: add explicit pipeline tests and run full CI + build in same window.

## Documentation sync requirements
- `docs/FEATURE_MATRIX.md`: `Paint tools` row updated for R2 behavior.
- `docs/PROGRESS_LOG.md`: add route/test evidence for each phase.
- `docs/TEST_LOG.md`: record suite command and pass/fail counts.
- `docs/EXPERIENCES.md`: record root cause for each recolor regression found.
