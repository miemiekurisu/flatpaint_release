# Recolor Design Spec (FlatPaint)

## Status
- Drafted after cross-reference against Photoshop docs + GIMP/Pinta architecture.
- This document is implementation-oriented and code-first aligned.

## Product objective
- Make `Recolor` predictable, selection-safe, and close to Photoshop mental model while keeping FlatPaint lightweight.

## Non-goals
- Full Photoshop parity in one pass.
- New heavyweight non-destructive stack in this phase.
- Any GPL code reuse.

## Current implementation baseline
- Entry route: `tkRecolor` in `TMainForm.ApplyImmediateTool`.
- Core primitive: `TRasterSurface.RecolorBrush(...)`.
- Current options: brush size/opacity, tolerance, preserve value.

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
1. Fix tool visibility regression (`Text` button clipping).
2. Add recolor route-level pipeline tests:
- selection-scoped recolor modifies inside but not outside
- recolor undo/redo symmetry
- source sampling contract test (once-mode)
3. Align UI hints to real semantics.

### Phase R2 (Photoshop-aligned options)
1. Add recolor sampling mode state and UI control.
2. Add recolor mode enum and core mapping path (`Color` first).
3. Keep existing preserve-value as backward-compatible mode bridge until full mode matrix lands.

### Phase R3 (parity depth and performance)
1. Add limits mode behavior.
2. Optional cached/stencil-assisted per-stroke traversal for large documents.
3. Optional replace-color dialog route for targeted/global recolor.

## Data model additions (planned)
- `TRecolorSamplingMode = (rsmOnce, rsmContinuous, rsmSwatchCompat)`
- `TRecolorBlendMode = (rbmColor, rbmHue, rbmSaturation, rbmLuminosity)`
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
- `docs/FEATURE_MATRIX.md`: update `Paint tools` notes when R2 lands.
- `docs/PROGRESS_LOG.md`: add route/test evidence for each phase.
- `docs/TEST_LOG.md`: record suite command and pass/fail counts.
- `docs/EXPERIENCES.md`: record root cause for each recolor regression found.
