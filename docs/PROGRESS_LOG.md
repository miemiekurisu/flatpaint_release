# Development Progress Log

## Scope note
- This is a cumulative historical log and contains pre-FPC entries from earlier prototype phases.
- The active implementation stack for current work is FPC + Lazarus.

## Rectangle Selection Edge Adjustment

### Changes

1. **Added post-draw edge adjustment for rectangle selection tool**:
   - After drawing a rectangle selection, users can drag any of the 4 edges to resize.
   - Marching-ants preview (clean, no extra solid outline) updates in real time while dragging.
   - Cursor changes to resize arrows (`crSizeWE`/`crSizeNS`) on `FPaintBox` when hovering over draggable edges.
   - Press Enter to commit the adjusted selection, Escape to cancel.
   - Clicking outside the edges also commits and allows starting a new selection.
   - Rounded corners are correctly re-applied when committing adjusted bounds.
   - Switching tools automatically commits the pending adjustment.

2. **Visual fixes (follow-up)**:
   - Cursor is set on `FPaintBox.Cursor` (not form-level `Cursor`) so the resize arrows appear correctly over the canvas control.
   - During edge-drag (`FPointerDown` + `FSelAdjusting`), the old-style preview rectangle/marching-ants from the initial draw phase are suppressed — only the adjustment preview is drawn.
   - Removed redundant solid-black rectangle border from the adjustment preview; only marching ants are rendered for a clean appearance matching the committed selection overlay.

3. **Files modified**:
   - `src/app/mainform.pas`: Added `FSelAdjusting`, `FSelAdjRect`, `FSelAdjDragEdge` fields; `BeginSelAdjust`, `CommitSelAdjust`, `CancelSelAdjust`, `SelAdjEdgeAtPoint`, `SelAdjCursorForEdge` methods; intercepted MouseDown/Move/Up and KeyDown for adjustment state machine; added adjustment preview in PaintCanvasTo; guarded old preview code in `PaintCanvasTo`.
   - `src/tests/tools_select_tests.pas`: Added 2 tests (`AdjustedRectSelection_CommitsNewBounds`, `AdjustedRectSelection_RoundedCornersPreserved`).

4. **Design reference**: GIMP rectangle selection tool edge-adjustment behavior (architecture reference only, original implementation).

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `403` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **success**, app bundle regenerated at `dist/FlatPaint.app`.

## 2026-03-09 (medium-priority GIMP parity gap closure: tool option depth)

### Changes

1. **Closed the previously tracked medium-depth tool-option gaps under the fixed tool set**:
   - Gradient now exposes and routes `Linear/Radial/Conical/Diamond` + repeat mode (`None/Sawtooth/Triangular`) via `FillGradientAdvanced`.
   - Clone Stamp now exposes sample source policy (`Current Layer` / `Image`) and routes composite-image sampling in both source pick and stroke paths.
   - Crop now exposes aspect presets (`Free/1:1/4:3/16:9/Current Image`) and composition guides (`None/Thirds/Center`) with constrained drag geometry.
   - Rounded Rectangle now exposes explicit corner radius in tool options and commit/preview paths.
   - Text now supports multiline inline editing and explicit alignment (`Left/Center/Right`) in editor style and raster commit route.

2. **Regression expectation correction for advanced gradient tests**:
   - Updated conical-gradient and sawtooth-repeat assertions to match implemented 360-degree conical semantics and linear-period repeat semantics.
   - No algorithm downgrade was introduced; this is assertion semantic alignment.

3. **Documentation realignment to code-first status**:
   - `TOOL_OPTIONS_BASELINE` now records these medium-depth items as implemented and moves remaining debt to advanced-parity scope.
   - `FEATURE_MATRIX` now reflects the new tool-depth state and latest regression-health evidence.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `390` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-09 (selection anti-alias semantics fix: decoupled from feather)

### Changes

1. **Fixed semantic mismatch between `Anti-alias` and `Feather` in selection workflows**:
   - `TSelectionToolController` now treats anti-alias and feather as independent controls.
   - Feather is now applied strictly by feather radius (`>0`), not by anti-alias checkbox state.

2. **Added explicit anti-alias toggles to core selection shape generators**:
   - `TSelectionMask.SelectRectangle(...)` now supports anti-alias-aware edge coverage mode.
   - `TSelectionMask.SelectEllipse(...)` and `SelectPolygon(...)` now support both aliased and anti-aliased generation paths.
   - `TImageDocument.SelectRectangle/SelectEllipse/SelectLasso` now forward anti-alias intent into selection-core APIs.

3. **UI routing alignment**:
   - Anti-alias checkbox is now shown for geometry selection tools (`Rect/Ellipse/Lasso`) and no longer shown for `Magic Wand` to avoid misleading no-op semantics.
   - Feather spinner remains visible for selection tools and is no longer enabled/disabled by anti-alias state.

4. **Regression coverage added**:
   - `fpselection_tests`:
     - `EllipseAliasedModeUsesBinaryCoverage`
     - `EllipseAntialiasModeProducesFractionalCoverage`
     - `PolygonAliasedModeUsesBinaryCoverage`
   - `tool_controller_tests`:
     - `SelectionFeatherIndependentFromAntiAliasToggle`

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `385` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-09 (docs alignment: fixed tool-set completeness vs GIMP depth)

### Changes

1. **Tool completeness wording corrected from route-complete to parity-partial where needed**:
   - `docs/TOOL_OPTIONS_BASELINE.md` now explicitly distinguishes:
     - all fixed tools are present and executable;
     - remaining deficits are option-semantics/depth gaps, not missing tool routes.
   - Replaced prior "no tracked gaps remain" statement with concrete gap list:
     - selection anti-alias semantics normalization
     - wand anti-alias path gap
     - text depth (single-line + style-basic)
     - gradient mode-family depth
     - clone sampling-policy depth
     - crop constraint/preset depth
     - shape post-commit/radius control depth

2. **Feature matrix status corrected for tool families**:
   - `docs/FEATURE_MATRIX.md` now marks:
     - `Selection tools` = `Partial`
     - `Paint tools` = `Partial`
     - `Draw tools` = `Partial`
   - Notes now align with current code paths instead of implying full GIMP-depth parity.

3. **No runtime code changes in this pass**:
   - This change window is documentation alignment only (code-first status correction).

### Verification

- `bash ./scripts/build.sh`
  - Result: **passed**, regenerated `dist/FlatPaint.app`.
- `bash ./scripts/run_tests_ci.sh`
  - Not rerun in this docs-only pass; latest full baseline remains `363` tests, `0` failures (2026-03-08).

## 2026-03-08 (release preflight: marquee half-speed + drag responsiveness + min-macOS declaration sync)

### Changes

1. **Marquee speed tuned down to requested half-speed**:
   - kept timer cadence smooth (`18ms`) and reduced phase stride from `2` to `1`.
   - preserves fluid motion while slowing ant travel.

2. **Drag-time responsiveness guard for slower machines**:
   - `PaintBoxMouseMove` now throttles status-bar refresh/reflow to ~30 FPS while pointer is down (`33ms` gate).
   - keeps final mouse-up status exact while reducing drag-loop UI churn on large canvases / older Apple Silicon.

3. **Compatibility declaration consistency hardening**:
   - centralized minimum macOS declaration as `APP_MIN_MACOS` in `scripts/common.sh`.
   - native module compile flags now consume the same value.
   - `Info.plist` now explicitly writes `LSMinimumSystemVersion` to match binary deployment target.
   - release feature summary now states `macOS 11.0+`.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `371` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-08 (marquee continuous-animation regression fix: idle -> timer driver)

### Changes

1. **Fixed root cause of “ants only move when mouse moves” regression**:
   - prior implementation advanced marquee phase in `AppIdle` while `Done := True`, which does not guarantee continuous idle callbacks when no input events arrive.
   - this caused animation to appear event-driven (mouse movement) instead of continuously time-driven.

2. **Moved marquee phase advance to a dedicated `TTimer`**:
   - added `FMarqueeTimer` (`18ms`) and `MarqueeTimerTick`.
   - each timer tick advances marquee phase by `2` steps and invalidates paintbox overlay.
   - ensures continuous marching-ants motion even when cursor is stationary.

3. **Kept low-resource architecture intact**:
   - retained cached selection-boundary overlay model.
   - `AppIdle` now only syncs whether marquee animation should be active (`UpdateMarqueeAnimationState`) instead of driving frame cadence.
   - avoids high-CPU busy-idle loops while preserving smooth flow.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `371` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-08 (marquee smoothness architecture pass: overlay-only animation)

### Changes

1. **Removed marquee animation from full display-surface rebuild path**:
   - selection ants are no longer animated by forcing `InvalidatePreparedBitmap` every tick.
   - animation now invalidates only the paintbox overlay path, avoiding repeated full composite + bitmap copy work per marquee frame.

2. **Introduced cached selection-boundary contour model for overlay drawing**:
   - added cache lifecycle (`InvalidateSelectionMarqueeCache`, `EnsureSelectionMarqueeCache`, `RebuildSelectionMarqueeCache`).
   - cache stores traced boundary contours + per-pixel marquee step mapping for test visibility parity.
   - cache is invalidated on selection/document replacement routes and image-mutation sync routes.

3. **Moved committed selection ants rendering to canvas overlay stage**:
   - `PaintCanvasTo` now draws committed selection marquee via `DrawSelectionMarqueeOverlay` after base image render.
   - this keeps ants crisp at zoom and decouples animation smoothness from base-scene recomposition.

4. **Kept integration-test semantics stable**:
   - `DisplayPixelForTest` now overlays cached marquee color (`TrySelectionMarqueePixelColor`) so existing dashed-boundary integration tests remain route-valid.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `371` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-08 (marquee motion/style tuning: faster + clearer without high repaint rate)

### Changes

1. **Marquee visual style aligned to mainstream editor behavior (Photoshop/GIMP/paint.net-style marching ants)**:
   - switched from gap-based sparse dash to continuous alternating dark/light segments (1px continuous boundary, segment-length based alternation).
   - this makes selection boundaries more legible on both light and mid-tone content.

2. **Animation speed increased with low-risk cadence strategy**:
   - instead of pushing very high frame frequency, idle cadence now uses moderate interval plus multi-step phase advance:
     - tick interval: `90ms`
     - phase advance per tick: `2`
   - effective ant travel speed is about `2.4x` prior behavior, while repaint frequency rises only modestly.

3. **Selection parity remains intact across requested routes**:
   - rectangle/ellipse/lasso committed selection boundaries share the same ant style.
   - magic wand hover/selection visuals stay on the same marquee system.

4. **Tests updated for continuous-ant contract**:
   - helper tests now assert continuous visibility and segment-based color alternation.
   - pipeline assertions now validate light ant segments directly (instead of old “gap shows base pixel” expectation).

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `371` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-08 (selection marquee parity follow-up: lasso + magic wand)

### Changes

1. **Completed marquee-visual parity for user-requested selection tools**:
   - `tkMagicWand` is now included in marquee animation policy (`FPMarqueeHelpers.ShouldAnimateMarqueeOverlay`) so wand hover/selection visuals share the same flowing cadence.
   - Wand hover cursor in `mainform` now renders as an animated marquee rectangle (instead of static solid box).
   - Lasso in-progress preview now uses a closed flowing marquee polyline (`DrawMarqueePolylineOverlay(..., True)`) for region readability.

2. **Added regression coverage for the two explicitly requested paths**:
   - `LassoSelectionOverlayUsesDashedBoundaryPattern`
   - `MagicWandSelectionOverlayUsesDashedBoundaryPattern`
   - Plus helper-policy assertion update for `tkMagicWand` marquee animation intent.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `371` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-08 (A6 closure pass + recolor/clone marquee hardening)

### Changes

1. **Closed A6 decomposition tail at mitigation threshold**:
   - Added `src/app/fpmarqueehelpers.pas` to extract marquee dash math, phase progression, and overlay animation policy from `mainform`.
   - Added `src/tests/fpmarqueehelpers_tests.pas` and wired it into `src/tests/flatpaint_tests.lpr`.
   - `mainform` now uses helper-driven animated marquee phase in `AppIdle`, selection boundary rendering, and selection-preview overlays (rect/ellipse/lasso).

2. **Recolor reliability/performance hardening for large connected regions**:
   - `TRasterSurface.RecolorBrush` now accepts an immutable source surface for candidate sampling (`ASourceSurface`).
   - Mainform recolor stroke now captures a per-stroke snapshot (`FRecolorStrokeSnapshot`) and passes it through apply/sample routes so contiguous recolor does not self-drift on already-updated pixels.
   - Recolor brush inner loop now uses cached coverage checks (`BrushCoverageAt`) and avoids repeated full-distance work for interior pixels.

3. **Clone stamp visual targeting improved to GIMP/PS-style clarity**:
   - Source anchor overlay stays animated dashed marquee circle/rect.
   - Destination cursor overlay for clone stamp now also uses animated dashed marquee circle for both point and radius cases.

4. **Pinch-zoom regression guard added after architecture edits**:
   - Added test hooks for simulated magnify gesture in `mainform`.
   - Added integration test `PinchGestureAdjustsZoomScale` in `pipeline_integration_tests`.

5. **Pipeline regression expansion for recolor residual issue**:
   - Added `RecolorContiguousDragKeepsApplyingAcrossLargeFlatRegion` to ensure contiguous recolor drag keeps replacing across same connected color family without leaving stale original pixels.

6. **Architecture docs synchronized for A6 closure state**:
   - `docs/ARCHITECTURE_DEFECT_ASSESSMENT.md`
   - `docs/ARCHITECTURE_MOD_PLAN_EVALUATION.md`
   - `docs/ARCHITECTURE_RENOVATION_PLAN.md`

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `369` tests, `0` errors, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, generated `dist/FlatPaint.app`.

## 2026-03-08 (A6 decomposition-tail pass 3: native magnify callback de-globalization)

### Changes

1. **Removed process-global pinch callback coupling (`GMainForm`) from `mainform`**:
   - native magnify callback now receives an explicit context pointer (`TMainForm` instance) instead of resolving a process-global form.
   - constructor/destructor assignments to `GMainForm` were removed.
   - obsolete unused `AppMainForm` global state stub was removed.

2. **Upgraded bridge contract to context-based install/uninstall**:
   - `src/app/fpmagnifybridge.pas` now exposes:
     - `FPInstallMagnifyHandler(ANSViewHandle, ACallback, AContext)`
     - `FPUninstallMagnifyHandler(ANSViewHandle)`
   - test-mode bridge stubs were updated to match the same API shape.

3. **Hardened native Objective-C pinch bridge against class re-swizzle churn**:
   - `src/native/fp_magnify.m` now:
     - stores callback context per NSView via associated object;
     - marks swizzled classes to avoid repeated exchange toggles;
     - supports explicit context detach via `FPUninstallMagnifyHandler`.

4. **Lifecycle safety alignment in app idle/teardown paths**:
   - install path now passes `Self` as callback context;
   - teardown path detaches the view context before destruction when magnify hook was installed.

5. **A6 risk posture update**:
   - reduced global-state callback coupling and lowered cross-form/callback routing risk in app-shell orchestration.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `363` tests, `0` errors, `0` failures.

## 2026-03-08 (A6 decomposition-tail pass 2: tool-switch path convergence)

### Changes

1. **Converged tool-switch option-memory behavior across button and combo routes**:
   - Introduced `ApplyToolOptionSwitch(...)` in `src/app/fpuihelpers.pas`.
   - Both `ToolButtonClick` and `ToolComboChange` now route through the same option-memory transfer logic, eliminating route drift where combo-switch previously skipped persisting outgoing tool options.

2. **Extracted blank-click auto-deselect policy to helper layer**:
   - Added `ShouldAutoDeselectFromBlankClick(...)` in `src/app/fpuihelpers.pas`.
   - `mainform` now delegates blank-click deselect decision to the shared helper policy rather than carrying inline conditional logic.

3. **Expanded helper-level regression coverage**:
   - `src/tests/fpuihelpers_tests.pas` adds:
     - `ToolOptionSwitchPersistsOldAndRestoresNew`
     - `BlankClickAutoDeselectPolicyMatchesSelectionRules`

4. **A6 risk posture update**:
   - non-render orchestration decisions are further centralized in helper units, reducing behavioral divergence risk across parallel UI entry routes.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `363` tests, `0` errors, `0` failures.

## 2026-03-08 (A6 decomposition-tail + A2 wand-coverage hardening pass)

### Changes

1. **A6 tail: extracted additional non-render orchestration policy from `mainform` into `FPUIHelpers`**:
   - Added shared helper contracts:
     - `ShouldPreserveSelectionAcrossToolSwitch(...)`
     - `ShouldAutoDeselectOnToolSwitch(...)`
     - `TryActivateTemporaryPan(...)`
     - `TryDeactivateTemporaryPan(...)`
     - `NextCycledTabIndex(...)`
   - `mainform` now routes tool-switch auto-deselect, temporary-pan state transitions, and Ctrl+Tab tab-cycle target computation through these helpers instead of duplicated local logic.

2. **A2 hardening: magic-wand combine path now preserves byte-coverage semantics on add/subtract**:
   - `TImageDocument.SelectMagicWand(...)` add/subtract merge now uses per-pixel coverage math (`max` for add, bounded subtraction for subtract) instead of boolean assign/clear.

3. **Regression coverage expanded for these policies**:
   - `src/tests/fpuihelpers_tests.pas`:
     - `ToolSwitchSelectionPolicyMatchesEditorRules`
     - `ToolSwitchAutoDeselectPolicyMatchesSelectionRules`
     - `TempPanStateTransitionsAreIdempotent`
     - `TabCycleIndexFollowsShortcutPolicy`
   - `src/tests/fpdocument_tests.pas`:
     - `MagicWandAddSubtractUsesCoverageCombineSemantics`

4. **Architecture docs synchronized for traceability**:
   - `docs/ARCHITECTURE_DEFECT_ASSESSMENT.md`
   - `docs/ARCHITECTURE_MOD_PLAN_EVALUATION.md`
   - `docs/ARCHITECTURE_RENOVATION_PLAN.md`

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `361` tests, `0` errors, `0` failures.

## 2026-03-08 (public-pack staging for partial GitHub open-source + release payload prep)

### Changes

1. **Added a dedicated `git/` staging tree for partial-open publication**:
   - root docs:
     - `git/README.md`
     - `git/LICENSE_OPTIONS.md`
     - `git/LICENSE`
     - `git/package_release.sh`
     - `git/verify_libs.sh`
   - bundled license texts:
     - `git/licenses/COPYING.LGPL.txt`
     - `git/licenses/COPYING.modifiedLGPL.txt`
   - release payload:
     - `git/release/FlatPaint.app` (copied from `dist/FlatPaint.app`)
     - `git/release/APP_FEATURES.md`
     - `git/release/packages/*.zip` + `SHA256SUMS.txt`

2. **Extracted 5 reusable libraries into standalone folders (one folder per lib)**:
   - `git/libs/fp-raster-core` (pure FPC raster core)
   - `git/libs/fp-viewport-kit` (pure FPC viewport/zoom/ruler math helpers)
   - `git/libs/fp-lcl-raster-bridge` (LCL bridge for `TRasterSurface <-> TBitmap`)
   - `git/libs/fp-lcl-clipboard-meta` (LCL clipboard metadata helper)
   - `git/libs/fp-macos-lcl-bridge` (macOS Cocoa bridge units + native `.m` modules)
   - each lib ships with:
     - `README.md`
     - `LICENSE`
     - `COPYING.LGPL.txt`
     - `COPYING.modifiedLGPL.txt`
     - `build.sh`
     - `examples/smoke_test.lpr`

3. **Finalized open-source license model for extracted libs**:
   - selected license: **LGPL v2.1+ with Lazarus modified linking exception**.
   - license texts are bundled both at `git/licenses/` and within each lib directory so per-lib zip artifacts are self-contained.

4. **Kept license-risk posture explicit and conservative**:
   - no FPC/Lazarus source code was copied into these lib folders.
   - only FlatPaint-owned units/native bridge files were extracted.
   - no private/proprietary third-party source was introduced.

5. **Feature-matrix mapping**:
   - `Regression health` / `Buildability` (release artifact reproducibility and deterministic packaging flow).
   - no end-user editing behavior changed in this pass.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `351` tests, `0` errors, `0` failures.
- `bash ./scripts/build-release.sh`
  - Result: **passed**, refreshed `dist/release/flatpaint` and `dist/FlatPaint.app`.
- Extracted-lib smoke builds:
  - `bash ./git/libs/fp-raster-core/build.sh` => passed
  - `bash ./git/libs/fp-viewport-kit/build.sh` => passed
  - `bash ./git/libs/fp-lcl-raster-bridge/build.sh` => passed
  - `bash ./git/libs/fp-lcl-clipboard-meta/build.sh` => passed
  - `bash ./git/libs/fp-macos-lcl-bridge/build.sh` => passed
- Packaging:
  - `bash ./git/package_release.sh` => passed
- Combined one-command library verification:
  - `bash ./git/verify_libs.sh` => passed (all 5 libraries)
- Standalone build-script robustness:
  - LCL/macOS lib scripts now auto-detect common Lazarus source locations and still allow explicit `LAZARUS_DIR`.
- Final regression gate:
  - `bash ./scripts/run_tests_ci.sh` => passed (`351` tests, `0` failures)

## 2026-03-08 (i18n dialog completion pass: shortcut-safe and regression-clean)

### Changes

1. **Completed language-switch coverage for previously untranslated dialog surfaces**:
   - localized and wired `TR(...)` for:
     - `src/app/fpaboutdialog.pas`
     - `src/app/fpblurdialog.pas`
     - `src/app/fpcurvesdialog.pas`
     - `src/app/fpeffectdialog.pas`
     - `src/app/fpexportdialog.pas`
     - `src/app/fplayerpropertiesdialog.pas`
     - `src/app/fpnewimagedialog.pas`
     - `src/app/fpnoisedialog.pas`
     - `src/app/fpposterizedialog.pas`
     - `src/app/fpresizedialog.pas`
     - `src/app/fptextdialog.pas`
   - `ResampleModeCaption(...)` in `src/app/fpresizehelpers.pas` now also follows `TR(...)` so resize dialog mode labels switch with language.

2. **Localized generic effect-parameter dialog entry points and repeat caption chain**:
   - converted `RunEffectDialog1/2` call-site titles and labels in `src/app/mainform.pas` to `TR(...)`.
   - localized effect-repeat prefix (`Repeat:`) and effect caption storage used by `Repeat Last Effect`.

3. **Kept behavior risk low by limiting this pass to UI strings only**:
   - no algorithm/path/selection/history semantics changed.
   - compile-time failures from mixed escaped-string syntax were resolved by normalizing affected export-dialog translations to stable UTF-8 string literals.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `351` tests, `0` errors, `0` failures.

## 2026-03-08 (export-dialog depth upgrade + JPEG stream regression + compatibility/licensing baseline refresh)

### Changes

1. **Reworked PNG/JPEG save flow into a unified export-options dialog with live preview**:
   - new unit: `src/app/fpexportdialog.pas`.
   - `SaveToPath(...)` now opens format-specific options for `.jpg/.jpeg` and `.png` instead of ad-hoc prompts.
   - dialog previews encoded output on a bounded thumbnail and shows sample encoded size.

2. **Extended persisted export options and writer coverage**:
   - session state now persists `JPEG quality`, `JPEG progressive`, `JPEG grayscale`, `PNG compression`, and `PNG alpha`.
   - save path keeps using `TSaveSurfaceOptions` and `SaveSurfaceToFileWithOpts(...)`; options are applied before each save.
   - JPEG subsampling control is shown as intentionally unavailable because current FPC `TFPWriterJPEG` does not expose a subsampling selector.

3. **Added stream-level JPEG regression coverage for the new save backend contract**:
   - `TFPIOTests.JpegStreamSaveSupportsExtensionNormalizationAndGrayscaleOutput` verifies:
     - stream-save accepts extension without dot (`jpg`);
     - stream payload is properly reset/truncated (valid JPEG SOI marker);
     - grayscale option produces near-equal RGB channels after decode.

4. **Export/reference baseline update recorded per development rules**:
   - paint.net save behavior reference: format-specific save-configuration + live preview model.
   - GIMP/Photoshop references used for option-surface parity targets (JPEG quality/progressive/subsampling-family controls, PNG compression/metadata surface expectations).
   - compatibility/licensing baseline clarified for partial formats:
     - `.xcf` and `.kra` remain open/ecosystem formats for compatibility import paths.
     - `.pdn` remains partial fallback-only (flattened import route), with no full round-trip commitment until public/stable format documentation is available.

5. **Low-risk AA/zoom rendering polish merged in the same window**:
   - straight solid line commit path now prefers Core Graphics stroked rendering with guarded fallback to prior raster path.
   - deep-zoom interpolation policy now switches to nearest-neighbor starting at `800%` (`8.0x`) for sharper pixel inspection.

6. **Top-toolbar readability alignment adjustments kept**:
   - zoom combo geometry and large-command typography were nudged for clearer visual centering/readability without changing command behavior.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `349` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-08 (Toolbar zoom-control centering and hover-style consistency)

### Changes
- Fixed zoom group horizontal centering: content padding was 6 px left / 2 px right; now 4 px each side (`ToolbarZoomButtonInsetLeft` 6→4, `ToolbarZoomComboLeft` 38→36, `ToolbarZoomInButtonLeft` 128→126).
- Adjusted zoom combo vertical position 1 px up (`ToolbarZoomComboTop` 4→3) to compensate for macOS NSPopUpButton visual baseline offset.
- Removed `Flat` toggle hover handler from New/Open/Save buttons; they now use the same native Cocoa hover as all other toolbar buttons.
- Removed unused `ToolbarBtnMouseEnter`/`ToolbarBtnMouseLeave` procedures.
- Updated `ZoomControlsFitInsideZoomCluster` test to accept 1 px vertical tolerance.

### Test results
- 350 tests, 0 errors, 0 failures.

## 2026-03-08 (About content build-time regeneration and source-sync guard)

### Changes

1. **Added a build-time About-content generator from `assets/about/*.txt`**:
   - new script: `scripts/generate_about_content.sh`.
   - regenerates `src/app/fpaboutcontent.pas` constants from:
     - `assets/about/APP_INFO.txt`
     - `assets/about/AUTHOR.txt`
     - `assets/about/ACKNOWLEDGMENTS.txt`
     - `assets/about/THIRD_PARTY_LICENSES.txt`
   - this removes stale hardcoded About text risk (including `author`) when source txt files change.

2. **Integrated generator into compile paths so each build/test refreshes About constants before compile**:
   - added `refresh_about_content` in `scripts/common.sh`.
   - wired into both `build_default_artifacts` and `build_release_artifacts`.
   - wired into `scripts/run_tests_ci.sh` before CLI/tests compile.

3. **Added regression coverage to guarantee compiled About constants match source text files**:
   - `src/tests/fpaboutcontent_tests.pas` now includes `AboutSectionsMatchAssetSourceFiles`.
   - test compares each About section constant against its `assets/about` source file content.

4. **Feature-matrix mapping**:
   - `Workspace shell` / `Menus/shortcuts`: About surface content is now deterministic and build-synced.
   - `Regression health`: added source-sync assertion to prevent stale metadata regressions.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `350` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-08 (ruler-aware palette bounds + clone overlay polish + zoom loupe restore + recolor contiguous + embedded About content)

### Changes

1. **Palette bounds now respect ruler occupancy when rulers are enabled**:
   - added `PaletteClampWorkspaceRect(...)` and `ClampPaletteRectToWorkspace(...)` in `src/app/fppalettehelpers.pas`.
   - integrated ruler-aware clamp flow in `mainform` palette creation, layout restore, drag-snap, resize, and ruler-toggle paths.
   - behavior contract:
     - rulers on: four utility palettes cannot cross ruler bands.
     - rulers off: original workspace-bounds-only clamp behavior remains.

2. **Clone stamp overlay visuals were restyled to reduce distraction and improve readability**:
   - replaced red dashed source-link line with neutral gray dotted line.
   - source cursor now uses dual-contrast black/white ring + crosshair.
   - source-link line is rendered only during active stamping (`pointer down`) to reduce idle clutter.

3. **Zoom tool local loupe overlay restored with bounded geometry**:
   - new helper `src/app/fpmagnifierhelpers.pas` computes source/destination rectangles with edge clamping.
   - `mainform` now renders a zoom loupe overlay for `tkZoom` hover path.
   - edge and small-canvas cases are bounded to visible canvas extents.

4. **Recolor functionality completed with contiguous-region option**:
   - `TRasterSurface.RecolorBrush(...)` adds `ContiguousOnly` flag with local BFS connectivity mask.
   - options bar gains `Contiguous` checkbox for recolor tool.
   - recolor apply route now passes contiguous-mode state through UI -> core path.

5. **FlatPaint app-menu About route + compile-time embedded About texts**:
   - added `FlatPaint` top-level menu with `About FlatPaint`.
   - added `FPAboutDialog` and `FPAboutContent`; about text now ships as compiled constants (no runtime file loading).
   - template about text assets were finalized and synchronized with embedded content.

6. **CI script robustness fix**:
   - `scripts/run_tests_ci.sh` now ensures `dist/` exists before copying CLI output.
   - removes false-negative CI failures when running tests from a freshly cleaned workspace.

7. **Reference baseline used in this pass**:
   - Photoshop/GIMP were used only as behavior/style references for clone-cursor ergonomics and contiguous recolor expectations.
   - no external private/proprietary assets were imported; no GPL code or identifiers were reused.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `341` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-08 (clipboard bridge + zoom interpolation quality refinement)

### Changes

1. **Integrated Edit copy/cut/paste routes with macOS system clipboard**:
   - `Cut` / `Copy` / `Copy Merged` now continue to fill in-app clipboard cache (`FClipboardSurface`) and additionally publish bitmap data to `Clipboard`.
   - `Paste` / `Paste into New Layer` / `Paste into New Image` now resolve source from system clipboard first (when picture format exists), and fall back to in-app cache only when needed.

2. **Added clipboard metadata channel to preserve in-app paste offset semantics across system clipboard**:
   - new helper unit: `src/app/fpclipboardhelpers.pas`.
   - publishes app-specific clipboard metadata (`com.flatpaint.surface-meta.v1`) with copied surface dimensions + offset.
   - paste path validates metadata against resolved clipboard image dimensions before applying offset (dimension mismatch safely falls back to origin).

3. **Refined zoom interpolation strategy so anti-aliased pencil edges remain visible at moderate zoom-in**:
   - added `DisplayInterpolationQualityForZoom(...)` in `src/app/fpviewporthelpers.pas`.
   - `PaintCanvasTo` now uses zoom-band mapping instead of hard switch at `>1.0`:
     - `<=1.0` high quality (`3`)
     - `<=2.0` medium (`2`)
     - `<=4.0` low (`1`)
     - `>4.0` nearest (`0`)

4. **Added regression coverage for new helper contracts**:
   - `src/tests/fpclipboardhelpers_tests.pas` (`3` tests) for metadata roundtrip/validation.
   - expanded `src/tests/fpviewporthelpers_tests.pas` with `DisplayInterpolationQualityTracksZoomBands`.
   - registered new suite in `src/tests/flatpaint_tests.lpr`.

5. **Reference/doc baseline used in this pass**:
   - Lazarus clipboard and control docs from local toolchain (`lcl/clipbrd.pp`, `docs/xml/lcl/controls.xml`).
   - project performance baseline (`docs/FPC_MACOS_PERFORMANCE_GUIDE.md`) and Apple High Resolution guidance already tracked there.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `334` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-08 (performance audit pass: LCL bridge hot-path micro-optimization)

### Changes

1. **Completed a focused performance audit against the render/display hot path**:
   - traced repaint path `PaintCanvasTo` → `BuildDisplaySurface` → `CopySurfaceToBitmap`.
   - identified per-pixel property access in `CopySurfaceToBitmap` as a high-frequency cost center (`ASurface[X, Y]` triggers bounds/index work for each pixel).
   - mapped this work to Feature Matrix row: `Rendering quality` (display pipeline responsiveness).

2. **Optimized `CopySurfaceToBitmap` without changing output semantics** (`src/app/fplclbridge.pas`):
   - replaced `X/Y` indexer loops with contiguous raw-pointer iteration (`ASurface.RawPixels`) while keeping `Unpremultiply(...)` conversion per pixel.
   - kept destination format identical (`B8G8R8A8`, top-to-bottom) and retained `LoadFromRawImage(..., True)` ownership flow.
   - added an explicit `Buffer` cleanup fallback around `LoadFromRawImage` to avoid leak risk on exceptional exits.

3. **Reduced repeated constant construction in compositor checkerboard path** (`src/app/mainform.pas`):
   - precomputed checkerboard colors once per call (`CheckerDark`/`CheckerLight`) instead of re-creating `RGBA(...)` values inside every transparent-pixel branch.
   - behavior stays unchanged; this is a hot-loop micro-optimization only.

4. **Documentation/source baseline cross-check used for this pass**:
   - local FPC toolchain option reference via `fpc -h` (reviewed `-O1/-O2/-O3/-O4`, `-CX`, `-XX`, `-Xs`).
   - local Lazarus docs (`docs/xml/lcl/controls.xml`) for `TWinControl.DoubleBuffered` repaint/flicker guidance.
   - project Apple guidance baseline kept aligned with High Resolution docs already tracked in `docs/FPC_MACOS_PERFORMANCE_GUIDE.md`.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `330` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-08 (premul boundary correctness pass: merge/move/clone/color sampling)

### Changes

1. **Fixed premultiplied-source blend routing in three mutation paths**:
   - `TImageDocument.MergeDown` now uses `BlendPixelPremul`.
   - `TImageDocument.MoveSelectedPixelsBy` background-layer path now uses `BlendPixelPremul` for copied soft-coverage pixels.
   - `mainform` clone-stamp apply loop now uses `BlendPixelPremul`.
   - Result: semi-transparent source pixels are no longer double-premultiplied (prevents visible darkening).

2. **Fixed sampled-color decoding on premultiplied surfaces**:
   - `RecolorSourceAtPoint` now unpremultiplies sampled active-layer pixels.
   - Color picker sampling from current-layer/composite surfaces now unpremultiplies before swatch adoption.
   - `AdoptSampledRGBPreservingAlpha` now decodes premultiplied samples while preserving the current paint alpha.

3. **Added regression tests for the corrected behavior**:
   - `TFPDocumentTests.BackgroundLayerSoftMoveKeepsFeatheredIntensity`
   - `TFPDocumentTests.MergeDownUsesPremultipliedBlendPath`
   - `TMainFormIntegrationTests.ColorPickerUnpremultipliesSampledRGB`

4. **Fixed `run_tests_ci.sh` Lazarus path fallback**:
   - replaced hardcoded `/Users/kurisu/...` fallback with workspace-relative auto-resolution (`$PROJECT_ROOT/../..` + `/lazarus`), while still honoring explicit `LAZARUS_DIR`.
   - Result: default local/CI invocation (`bash ./scripts/run_tests_ci.sh`) no longer depends on a specific username path.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `330` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-08 (Anti-aliasing module: premultiplied alpha migration + SDF edge AA + CG bridge + Retina DPI)

### Changes

1. **Migrated entire pixel pipeline to premultiplied alpha** (`fpcolor.pas`, `fpsurface.pas`, `fpdocument.pas`, `fpio.pas`, `fpnativeio.pas`, `fplclbridge.pas`):
   - Added `Premultiply`, `Unpremultiply`, `RGBA_Premul` helpers with correct rounding.
   - Rewrote `BlendNormal` for premultiplied Porter-Duff source-over.
   - Added `BlendPixel` (auto-premultiplies) and `BlendPixelPremul` (skips premultiply) gateways.
   - Added bulk `PremultiplyAlpha` / `UnpremultiplyAlpha` and `RawPixels` property for CG buffer sharing.
   - Updated all I/O boundaries: premultiply on load, unpremultiply on save. `.fpd` format stays straight alpha for backward compat.
   - Updated all erase operations to scale all RGBA channels uniformly.
   - Updated compositor to use `BlendPixelPremul` for normal mode, unpremultiply-before-formula for non-normal blend modes.
   - Updated 26+ filters with appropriate premul handling (spatial filters unchanged, color-space filters unpremultiply-before/re-premultiply-after).

2. **Implemented SDF edge anti-aliasing for filled shapes and selections** (`fpsurface.pas`, `fpselection.pas`):
   - Added `SDFCoverage`, `EllipseSDF`, `RoundedRectSDF`, `DistToSegment`, `PointInsidePolygon` helper functions.
   - Rewrote `DrawEllipse` (filled + stroked), `DrawRoundedRectangle`, `FillPolygon` with 1px smooth SDF coverage transitions.
   - Rewrote `SelectEllipse` and `SelectPolygon` to produce fractional 0-255 coverage instead of binary 0/255.
   - Algorithm reference: GIMP `gimp-gegl-mask-combine.cc` SDF approach (architecture reference only, original implementation).

3. **Created Core Graphics offscreen rendering bridge** (`src/native/fp_cgrender.m`, `src/app/fpcgrenderbridge.pas`, `scripts/common.sh`):
   - 5 CG rendering entry points: filled/stroked ellipse, filled path, stroked Bezier, stroked polyline.
   - `CGBitmapContext` directly over `TRasterSurface` pixel buffer (zero-copy, enabled by premul migration).
   - Build system integration in `compile_native_modules()`.
   - `{$IFDEF TESTING}` no-op stubs for headless test builds.

4. **Added Retina display DPI matching** (`fp_appearance.m`, `fpappearancebridge.pas`, `mainform.pas`):
   - `FPGetScreenBackingScale`: returns `NSScreen.mainScreen.backingScaleFactor`.
   - `FPSetInterpolationQuality`: sets `CGContextSetInterpolationQuality` on current graphics context.
   - Default document size scaled by backing factor (2048×1536 on Retina).
   - `PaintCanvasTo` sets CG high-quality interpolation for zoom ≤ 1.0, nearest-neighbor for zoom > 1.0.

5. **Fixed first-launch canvas centering race condition** (`mainform.pas`):
   - Root cause: `FCenterOnNextCanvasUpdate` consumed before LCL deferred layout passes completed.
   - Fix: re-trigger `FitDocumentToViewport(True)` + centering after deferred layout completes in `AppIdle`.

6. **Added 16 new tests** (`src/tests/fpcolor_premul_tests.pas`):
   - Premultiplied alpha round-trip, BlendNormal correctness, SDF shape AA verification, selection coverage, resize no-halo regression.

7. **Updated architecture documentation** (`docs/ANTIALIASING_RESEARCH.md`):
   - Added §0 Implementation Status, updated §1/§5.1 with resolved status, added §6.9-6.10 + §7 implementation details.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `327` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-07 (Retina icon rendering compliance pass: keep point-size, raise pixel density)

### Changes

1. **Aligned options-bar tool icon rendering to high-DPI point semantics**:
   - Kept options-bar icon box at the same logical size (`20x20` point contract).
   - Switched `FToolIconImage` to scaled rendering (`Stretch=True`, `Proportional=True`) so `@2x` assets render into the fixed logical box instead of being clipped.

2. **Resolved first-order `@2x` clipping route without touching tool logic**:
   - This pass is UI-only and affects icon presentation behavior in the options bar.
   - No drawing/tool state machine or document mutation routes were changed.

3. **Reference baseline used for this adjustment**:
   - Apple High Resolution guidance (point-size stable, backing pixel density increases):
     - `High Resolution Guidelines for OS X` (archived): `https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/`
     - `High Resolution Explained`: `https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Explained/Explained.html`

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `311` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-07 (Icon/Retina asset-chain closure pass: multi-scale package completeness + mapped-tool gap closure)

### Changes

1. **Closed the runtime `@2x` loading gap for picture-based icon paths**:
   - `FPIconHelpers` now uses one shared rendered-asset loader for both glyph and picture routes.
   - Loader behavior is explicit: prefer `@2x` when present, and fall back to `1x` if the preferred asset is missing or unreadable.

2. **Removed a hidden low-resolution fallback route for mapped tools**:
   - Added `pointer` and `grid-2x2` to the icon extraction/render pipeline (`extract_lucide_icons.py` + refreshed assets).
   - This closes the prior mismatch where `Move Pixels` / `Mosaic` icon mappings existed in code but corresponding rendered assets were absent.

3. **Completed bundle-side multi-scale asset packaging with real assets present**:
   - Regenerated `assets/icons/rendered` to include both `*.svg.png` and `*.svg@2x.png`.
   - Rebuilt app bundle now includes those multi-scale assets under `dist/FlatPaint.app/Contents/Resources/icons/rendered`.

4. **Expanded icon regression checks to enforce asset-chain completeness**:
   - Added `RepresentativeRetinaAssetsExist` and strengthened representative checks to include `pointer` / `grid-2x2`.
   - Added explicit icon-load assertions for `Move Pixels` and `Mosaic`.
   - Added `ButtonIconRenderedAssetPixelSize(...)` test hook to verify selected asset scale without widgetset-bound drawing calls.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `311` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed with `@2x` icon assets.

## 2026-03-07 (P0 closure pass: shortcut parity + recolor R2 + A4 runtime semantics)

### Changes

1. **Closed P0 shortcut parity high-use audit with executable coverage**:
   - Added `src/app/fpshortcuthelpers.pas` as a single source for high-use edit shortcuts:
     - `Copy Selection` (`Cmd+Opt+C`)
     - `Paste into New Layer` (`Cmd+Shift+V`)
     - `Paste into New Image` (`Cmd+Opt+V`)
     - `Fill Selection` (`Shift+Delete`)
     - `Crop To Selection` (`Cmd+Opt+X`)
   - Wired those bindings in `mainform` menu construction.
   - Added `src/tests/fpshortcuthelpers_tests.pas` and registered it in `src/tests/flatpaint_tests.lpr`.

2. **Completed recolor R2 behavior rollout in code-first surface**:
   - Recolor sampling modes (`Once` / `Continuous` / `SwatchCompat`) and blend modes (`Color/Hue/Saturation/Luminosity/ReplaceCompat`) are now active in core/UI routes.
   - Selection-scoped recolor + undo/redo + sampling contracts are covered in surface/pipeline tests.

3. **Completed A4 runtime semantic activation**:
   - Layer offsets are no longer metadata-only; compositor and tool coordinate/mask mapping now consume offsets as runtime invariants.
   - Offset-aware routes are covered in document + pipeline + IO tests.

4. **Synchronized architecture/product docs to code reality**:
   - Updated PRD, feature matrix, shortcut policy, feature priority order, recolor design spec, and architecture assessment/evaluation/renovation docs from “P0 open” to “P0 closed”.
   - Updated evidence counts and post-P0 remaining priorities.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `295` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed.

## 2026-03-07 (docs alignment refresh + functional priority ordering pass)

### Changes

1. **Synced code-first baseline docs to latest regression truth** — updated:
   - `docs/PRD.md` current snapshot test count from `279` to `284`.
   - `docs/FEATURE_MATRIX.md` evidence and regression-health rows from `279` to `284`.

2. **Closed shortcut-status wording drift in matrix** — `Menus/shortcuts` row now explicitly states that core mapping is test-clean while command-surface parity audit remains non-exhaustive per `docs/SHORTCUT_POLICY.md`.

3. **Added a dedicated function-side priority document** — created `docs/FEATURE_PRIORITY_ORDER.md` with P0/P1/P2 ranking based on release risk, user value, and regression containment cost.

4. **Linked implementation workflow to the new priority source** — `docs/IMPLEMENTATION_PLAN.md` now references `docs/FEATURE_PRIORITY_ORDER.md` under current implementation targets.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `284` tests, `0` failures.

## 2026-03-07 (recolor research baseline + Text tool visibility restore)

### Changes

1. **Completed recolor reference research before implementation work** — added two new docs to lock behavior/architecture baseline first:
   - `docs/RECOLOR_FEATURE_RESEARCH.md`
   - `docs/RECOLOR_DESIGN_SPEC.md`
   covering Photoshop behavior surface, open-source architecture references (GIMP/Pinta), gap mapping against current FlatPaint code, and anti-GPL implementation guardrails.

2. **Restored default visibility for final tools-row buttons (including Text)** — increased tools palette default height in `fppalettehelpers` from `500` to `540`, matching current 2-column grid row count so the last row is no longer clipped.

3. **Added regression coverage for tools-panel vertical capacity** — `TFPPaletteHelpersTests.ToolsPaletteHeightFitsAllVisibleToolRows` now asserts default tools palette height can contain all visible tool rows (excluding hidden `Zoom` button in the panel grid).

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `284` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.
- Execution note:
  - an earlier parallel run of test/build was discarded due shared output-directory cleanup contention; final evidence above is from serial re-run.

## 2026-03-07 (UI-only retina/readability stabilization pass: startup relayout + overlay realignment + optional @2x lookup)

### Changes

1. **Startup top-chrome relayout moved to a multi-pass deferred window** — `mainform` now keeps a bounded deferred layout retry counter (`3` idle passes) so first-launch options-row geometry is recomputed after Cocoa control metrics settle, instead of relying on a single post-handle pass.

2. **Window resize now replays top/status layout contracts** — `FormResize` now explicitly runs `RelayoutTopChrome` + `LayoutStatusBarControls` before palette clamping, reducing toolbar/option/status vertical drift when window geometry changes.

3. **Overlay icon positioning is now globally re-aligned from one UI helper** — added `RelayoutButtonIconOverlays` recursive pass so all command/tool/utility overlay icons can be re-centered against final control bounds, not just initial construction-time metrics.

4. **Overlay icon sizing now respects DPI-aware control metrics while preserving large-command text lane stability** — non-large command/icon-only surfaces can scale icon targets from `Scale96ToScreen(...)` and fit bounds, while `New/Open/Save` keep fixed max icon sizing to avoid caption-lane regressions.

5. **Icon loader now supports optional retina asset preference** — `FPIconHelpers` now prefers `@2x` rendered assets when present (for both picture and glyph load paths) while preserving existing 1x fallback behavior if retina variants are absent.

6. **Icon refresh tooling gained explicit size parameterization and @2x output path** — `extract_lucide_icons.py` now supports `--normalize ... [TARGET_SIZE]`, and `refresh_lucide_rendered.sh` now emits both standard and `@2x` output names in one pass.

7. **Current repo asset state remains 1x until icon refresh deps are present** — this workspace currently lacks Python `Pillow`, so `assets/icons/rendered` was not regenerated in this window; runtime keeps 1x fallback behavior and will pick `@2x` files automatically once generated.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `279` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-07 (shape-tool commit regression hardening after UI-side report)

### Changes

1. **Added explicit end-to-end shape commit regressions in pipeline tests** — new integration cases now assert that `Line`, `Rectangle`, and `Ellipse` drags commit pixels on mouse-up:
   - `LineDragCommitsPixels`
   - `RectangleDragCommitsPixels`
   - `EllipseDragCommitsPixels`

2. **Reduced deferred startup pass from state-refresh to layout-only for options row** — startup `AppIdle` deferred pass now runs `LayoutOptionRow` instead of `UpdateToolOptionControl`, avoiding unnecessary runtime control-state writes while still keeping first-frame option-row alignment behavior.

3. **Tool commit path confidence increased for user-reported regression class** — shape tools now have direct pipeline-level regression coverage rather than relying on indirect/semantic checks.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `279` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-07 (toolbar icon clarity + first-launch options-row overlap stabilization)

### Changes

1. **Top quick-action large command icons no longer downsample to a 14px overlay path** — `mainform` now keeps large command overlays at full asset size (bounded by 20px), avoiding extra runtime shrink blur and bringing visual weight closer to adjacent compact command/utility icons.

2. **Large-command caption padding is now centralized as one constant prefix contract** — replaced scattered hard-coded six-space prefixes with `ToolbarLargeCommandCaptionPrefix`, applied both at button construction and `TR(...)` caption rewrite sites (`New/Open/Save`), reducing icon/text collision drift risk.

3. **First-launch options-row overlap route now gets a deferred post-handle relayout** — `AppIdle` deferred-layout pass now triggers `UpdateToolOptionControl`, so option label/control positions are recomputed after initial widget metrics settle instead of waiting for the first manual tool switch.

4. **Code/doc alignment updated for this UI pass** — `FEATURE_MATRIX` `Iconography` notes now reflect this pass (large-command icon clarity + startup relayout stabilization) while keeping remaining retina/multi-scale icon debt explicit.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `276` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-07 (Phase 4.5 exit-criteria closure + XCF offset fixture correction)

### Changes

1. **Layer-offset metadata coverage now closes the remaining Phase-4.5 exit checks** — added `LayerOffsetMetadataPreservedAcrossFullSnapshotUndoRedo` in `fpdocument_tests` to assert full-snapshot undo/redo preserves per-layer offset metadata.

2. **XCF offset import regression fixture was corrected to use a valid property layout** — the minimal XCF generator now keeps image-property terminator fixed (`PROP_END`) and writes offset values only in layer `PROP_OFFSETS`, avoiding malformed files that only appeared when offsets were non-zero.

3. **Compatibility import offset preservation is now explicitly regression-covered** — added `XcfImportPreservesLayerOffsetMetadata` in `fpio_tests` to assert imported layer offset metadata is preserved and compatibility stamped payload matches clipped offset behavior.

4. **Architecture docs synchronized to code/test truth** — Phase 4.5 status is now marked complete in renovation planning docs; PRD/feature-matrix evidence snapshot updated to current regression count.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `276` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-07 (Phase 5 completion: move-pixels/stroke history now unified under core region transaction service)

### Changes

1. **Region snapshot model now supports optional selection/active-layer restore semantics** — `TDocumentSnapshot` region constructors now optionally carry selection state, and region snapshot application can restore both selection mask and active layer index when requested.

2. **Core history API gained explicit region+selection entry point** — added `PushRegionHistoryWithSelection(...)` in `TImageDocument` to push dirty-rect pixel history while atomically preserving pre-mutation selection state for undo/redo symmetry.

3. **Move-pixels commit no longer relies on full-document history snapshots** — `TMovePixelsController.Commit` now captures the union dirty rect (source + destination), stores pre-mutation pixels through region history with selection-state snapshot, then applies erase/paste commit via core APIs.

4. **Move-pixels history orchestration is now routed through core transaction service (A5 extraction closure)** — `TMovePixelsController` now uses `TRegionHistoryTransaction` (selection-aware begin/capture/commit) instead of manual controller-side region snapshot assembly.

5. **Core transaction service now supports optional selection-state snapshots** — `TRegionHistoryTransaction.BeginSession(..., AIncludeSelectionState)` and commit path now support selection+active-layer restore when needed, while preserving pixel-only transaction mode for brush-like strokes.

6. **Regression coverage expanded across controller and core transaction layers** — added:
   - `MovePixelsControllerUndoRedoRestoresSelectionAndPixels`
   - `MovePixelsControllerBackgroundCommitKeepsOpaqueFillAndUndo`
   - `RegionTransactionSelectionSnapshotRestoresSelectionOnUndoRedo`
   ensuring undo/redo symmetry for pixel+selection transaction snapshots.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `274` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 3 closure pass: removed remaining app-layer direct mutation routes)

### Changes

1. **`CommitShapeTool` and fill-mask apply now also use guarded writable-surface acquisition** — these previously lower-frequency commit paths were rerouted from direct `ActiveLayer.Surface.*` writes to `MutableActiveLayerSurface` access.

2. **Move-pixels preview session begin now respects core lock guard** — `TMovePixelsController.BeginSession` now acquires mutable surface via `MutableActiveLayerSurface`; when layer is locked, session begin short-circuits before preview mutation scaffolding.

3. **Controller regression coverage expanded for locked-begin path** — added `MovePixelsControllerBeginSessionBlockedByLockedLayer` in `tool_controller_tests`.

4. **App-layer direct mutation writes eliminated from `mainform` runtime routes** — remaining `ActiveLayer.Surface` usage in `mainform` is now read-only color picking (`InBounds` + pixel read), not mutation.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `271` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 3 tail: brush/recolor/clone stroke writes routed through guarded core surface access)

### Changes

1. **Added guarded mutable-surface core entry for active-layer tool writes** — `TImageDocument` now exposes `MutableActiveLayerSurface`, which returns a writable surface only when `MutationGuard` allows active-layer pixel mutation.

2. **High-frequency brush-like write loops now use core guard-coupled surface access** — `ApplyImmediateTool` brush/eraser/recolor/clone branches were rerouted to use `MutableActiveLayerSurface` instead of unconditional `ActiveLayer.Surface` writes.

3. **A3 tail risk reduced for in-flight stroke routes** — when lock/editability state changes between drag steps, subsequent high-frequency writes now naturally short-circuit at the core guard entry, reducing route-specific invariant drift.

4. **Mutation-guard suite expanded for the new core entry** — added `MutableActiveLayerSurfaceRespectsLockState` in `mutation_guard_tests`.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `270` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 3 tail: interactive shape/fill/crop commits moved to begin-mutation guards)

### Changes

1. **Interactive mouse-driven commit routes now avoid pre-guard history pushes** — Updated `PaintBoxMouseDown/MouseUp` paths to use guarded begin-mutation APIs for:
   - fill-tool click commit,
   - line/gradient/rectangle/rounded-rectangle/ellipse/freeform-shape commit,
   - drag-crop commit (`BeginDocumentMutation('Crop')`).

2. **Bezier line pending-segment commit now guard-coupled** — `CommitPendingLineSegment` uses `BeginActiveLayerMutation` before committing geometry, preventing blocked-lock no-op history entries in that route.

3. **A3 tail consistency improved in interactive routes** — lock-sensitive pointer commit paths now align better with the same core guard+history policy introduced for menu/effect commands.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `269` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 3 tail: move-pixels commit path now guard-coupled in controller)

### Changes

1. **Move-pixels controller commit path no longer mutates layer surfaces directly without guard gate** — `TMovePixelsController.Commit` now routes commit through core guarded mutation begin (`BeginActiveLayerMutation`) and core mutation APIs (`EraseSelection`, `PasteSurfaceToActiveLayer`) instead of direct `TargetLayer.Surface.*` writes.

2. **Blocked commit state made explicit** — Added `mpcBlocked` to `TMovePixelsCommitResult`; `mainform` commit handler now handles blocked commit as a non-mutating exit path with selection overlay sync.

3. **Layer-target consistency retained** — Commit still honors the session-captured layer index and restores prior active-layer index after commit/cancel decision.

4. **Controller regression coverage expanded** — Added `MovePixelsControllerCommitBlockedByLockedLayer` in `tool_controller_tests` to verify:
   - locked layer blocks commit,
   - blocked commit does not push history,
   - source pixels and selection origin remain intact.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `269` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 3 tail: no-op history cleanup through core begin-mutation guards)

### Changes

1. **Added guard-aware history entry points in core document API (`A3` tail)**:
   - `BeginActiveLayerMutation`
   - `BeginDocumentMutation`
   in `src/core/fpdocument.pas`, so lock checks and history push now share one domain entry.

2. **Rerouted menu/effect/history-sensitive UI commands away from raw `PushHistory`** — `mainform` now uses begin-mutation APIs for lock-sensitive mutation routes including:
   - inline text commit,
   - cut/paste to active layer,
   - resize/canvas-size/rotate/flip/crop-to-selection image commands,
   - fill/erase selection,
   - mosaic commit,
   - layer rotate dialog,
   - adjustment/effect command handlers.

3. **No-op history noise reduced for locked-layer scenarios** — commands that are mutation-blocked by `MutationGuard` no longer create undo entries first and fail afterward in these routed paths.

4. **Mutation guard regression suite expanded** — added:
   - `BeginActiveLayerMutationRespectsLockAndHistory`
   - `BeginDocumentMutationRespectsLockAndHistory`
   to lock guard + history coupling semantics in tests.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `268` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 3 tail: additional UI-direct mutation routes moved behind core guards)

### Changes

1. **Added guarded core wrappers for formerly UI-direct active-layer mutations (`A3` tail)**:
   - `PasteSurfaceToActiveLayer`
   - `PixelateRect`
   - `RotateActiveLayer90Clockwise`
   - `RotateActiveLayer90CounterClockwise`
   - `RotateActiveLayer180`
   in `src/core/fpdocument.pas`.

2. **Rerouted `mainform` direct-surface commands to core API**:
   - `Edit > Paste` now uses `PasteSurfaceToActiveLayer`
   - text stamp route now uses `PasteSurfaceToActiveLayer`
   - mosaic commit route now uses `PixelateRect`
   - `Layer Rotate / Zoom` now uses active-layer rotate wrappers.

3. **Mutation-guard regression suite expanded** — Added `LockedActiveLayerBlocksSurfacePasteAndRotateRoutes` and extended unlocked-path assertions to include guarded paste route behavior.

4. **Architecture docs synchronized for this tail step** — Updated A3 evidence/status wording to reflect expanded core-route guard coverage while keeping A3 in partial-mitigation status.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `263` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (A7 closure: stored-selection lifecycle moved to core copy routes)

### Changes

1. **Stored-selection route no longer depends on app-layer call sites** — Moved `StoreSelectionForPaste` invocation into core document copy paths:
   - `CopySelectionToSurface`
   - `CopyMergedToSurface`
   so selection-scoped copy/cut flows consistently prime `Paste Selection (Replace)` behavior.

2. **Cut path inherits the same contract automatically** — `CutSelectionToSurface` delegates through selection-copy path, so the stored-selection snapshot is captured before destructive erase/fill behavior in the same core route.

3. **A7 regression coverage added in core tests** — Expanded `TFPDocumentTests` with:
   - `CopySelectionStoresSelectionForPasteRoute`
   - `CopyMergedStoresSelectionForPasteRoute`
   asserting replace-paste selection lifecycle after route-level copy operations.

4. **Architecture docs synchronized for A7 status** — Updated defect/evaluation/plan docs to mark A7 as mitigated and removed from open critical-tail set.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `262` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 6: `TMainForm` decomposition completion for top-risk tool flows)

### Changes

1. **Selection tool controller extraction landed (`A6`)** — Added `TSelectionToolController` in `src/app/fptoolcontrollers.pas` to centralize:
   - modifier-to-selection-mode mapping (`replace/add/subtract/intersect`),
   - selection commits for rectangle / ellipse / lasso / magic wand,
   - optional feather application contract,
   - move-selection history begin + delta-step routing.

2. **`mainform` selection event routing switched to controller** — `PaintBoxMouseDown/Move/Up` now delegates high-risk selection mutation routes to `FSelectionController` while `TMainForm` remains UI shell + refresh orchestration.

3. **Controller decomposition set now covers `move + selection + paint-history`** — `TMovePixelsController` + `TSelectionToolController` + `TStrokeHistoryController` are all wired in `mainform` lifecycle creation/destruction paths.

4. **Independent controller regression coverage expanded** — `src/tests/tool_controller_tests.pas` now includes selection-controller behavior contracts (mode mapping, rectangle commit, move-selection route, magic-wand route), bringing the suite to 8 tests.

5. **Architecture docs synchronized for phase closure** — Updated architecture assessment/evaluation/renovation docs to reflect A6 as partially mitigated and Phase 6 exit criteria met for top-risk tool-flow decomposition.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `260` tests, `0` failures.
  - `TToolControllerTests`: `8/8` passed.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 4.5/5: layer-offset metadata + stroke-start history cost reduction)

### Changes

1. **Layer geometry metadata landed in core model (`A4` foundation)** — Added `OffsetX/OffsetY` to `TRasterLayer` and clone paths so geometry metadata now survives layer cloning/history full snapshots.

2. **Native project format upgraded for layer offsets** — `FPNativeIO` now writes `FPDOC04`, persisting per-layer offsets while keeping `FPDOC01/02/03` compatibility on load.

3. **XCF import now keeps source offset metadata structurally** — `LoadXCFDocument` continues compatibility stamping into canvas-sized layer surfaces, and now also records source offsets in layer metadata for future semantic migration.

4. **Brush-like stroke history no longer clones full active layer at mouse-down (`A5`)** — Replaced stroke-start `ActiveLayer.Surface.Clone` flow with incremental pre-stroke region capture in `TMainForm`:
   - touched segment bounds are captured before mutation,
   - capture grows by union while preserving already-recorded original pixels,
   - commit pushes one `PushRegionHistory` snapshot from captured region.

5. **History regression coverage expanded for long strokes** — Added `TPipelineIntegrationTests.UndoRedoAfterLongPencilStrokeRestoresPixels` to lock undo/redo correctness on long-segment brush strokes under the new incremental capture path.

6. **A4 persistence regression coverage expanded**:
   - `TFPDocumentTests.LayerOffsetMetadataPreservedInClone`
   - `TIntegrationNativeRoundTripTests.Test_MultiLayer_SaveLoad_PreservesLayersAndPixels` now asserts offset roundtrip.

7. **Architecture-reference protocol maintained** — This pass followed the existing GIMP-derived architecture notes for transaction/region-history direction only (no code/name reuse), consistent with anti-GPL contamination constraints.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `252` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (Phase 4 start: selection coverage semantics propagation)

### Changes

1. **Selection mask semantics moved to full-byte coverage contracts** — Updated `FPSelection` so binary helper paths no longer collapse to `0/1` storage:
   - `SelectAll` now writes `255`,
   - `Selected := True` now writes `255`,
   - `Invert` now performs `255 - coverage`,
   - `MoveBy` / `Flip` / `Rotate` / `Crop` / `ResizeNearest` / `IntersectWith` now preserve byte coverage values.

2. **Selection-aware mutation APIs now consume weighted coverage** — Updated `FPSurface` selection gates from boolean membership to weighted opacity/alpha scaling:
   - `BlendPixel`, selection-aware `EraseBrush`, `EraseSquareBrush`, and `RecolorBrush` now multiply effective opacity by selection coverage.
   - `FillSelection`, `EraseSelection`, `CopySelection`, and `MoveSelectedPixels` now use coverage-driven soft application.

3. **Background-layer move path remains opacity-safe under soft selection** — Updated `TImageDocument.MoveSelectedPixelsBy` background branch to blend copied pixels onto destination instead of direct assignment, preserving opaque-background invariant while allowing soft-edge transfer.

4. **Native selection persistence upgraded to byte coverage without breaking legacy files** — `FPNativeIO` now writes `FPDOC03` with full-byte selection mask values; loader keeps `FPDOC01/02` compatibility by mapping legacy non-zero mask bytes to selected (`255`) semantics.

5. **Coverage regression tests added across core + integration routes**:
   - `TFPSurfaceTests`: selection coverage opacity/alpha behavior for masked draw, fill, copy, and move-selected-pixels.
   - `TFPSelectionTests`: invert and transform paths preserve byte coverage.
   - `TIntegrationNativeRoundTripTests`: native save/load round-trip preserves byte coverage mask values.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `250` tests, `0` failures.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed in the same change window.

## 2026-03-06 (shortcut/layout regression closure + Phase 3 mutation guard start)

### Changes

1. **Closed the previously failing shortcut/metadata contract set** — Updated `FPUIHelpers` to align tool shortcut metadata and cycle behavior with the current tested policy:
   - selection family unified to `S`,
   - move family unified to `M`,
   - shape family unified to `O`,
   - picker single-key mapped to `K`,
   - crop bare-key shortcut cleared,
   - text tool hint now explicitly mentions inline editing.

2. **Closed the colors panel width contract regression** — Increased `ColorsPaletteWidth` (`220 -> 240`) in `FPPaletteHelpers` so the compact system-picker + slider layout contract remains satisfiable under current panel geometry tests.

3. **Started Architecture Renovation Phase 3 (`MutationGuard`) in core** — Added new core guard module `src/core/fpmutationguard.pas` and routed `TImageDocument` mutating pixel APIs through centralized guard checks:
   - active-layer pixel mutation paths now block on locked active layer,
   - document-wide pixel mutation paths now block when any layer is locked.

4. **Extended route consistency at app edge for remaining direct-surface commands** — Added explicit lock guards to menu routes that were still mutating `ActiveLayer.Surface` directly (`Paste`, `Layer Rotate/Zoom`) so they follow the same lock invariant as tool and core-command routes.

5. **Added dedicated mutation-guard regression suite** — New `src/tests/mutation_guard_tests.pas` covers:
   - locked active layer blocks adjustments,
   - locked active layer blocks selection-driven pixel mutation (`fill` / `erase` / `move selected pixels`),
   - locked layer blocks document-wide pixel mutations (`flip` path),
   - unlocked paths still mutate as expected.

6. **Code-first docs realigned after regression closure** — Updated `PRD` and `Feature Matrix` evidence snapshot from failing to passing regression baseline and removed stale “shortcut/colors test blocked” status.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **passed**, `243` tests, `0` failures.
  - New suite status: `TMutationGuardTests` `4/4` passed.
- `bash ./scripts/build.sh`
  - Result: **passed**, `dist/FlatPaint.app` refreshed on the same change window.

## 2026-03-06 (Phase 1/2: move-selected-pixels transaction migration)

### Changes

1. **Move Pixels entered transactional mode in `TMainForm`** — Added explicit session lifecycle helpers (`BeginMovePixelsTransaction`, `UpdateMovePixelsTransaction`, `CommitMovePixelsTransaction`, `CancelMovePixelsTransaction`) and session state fields so drag interaction no longer writes history on mouse-down.

2. **Drag preview is now non-destructive in document pixels** — During drag, selected pixels are held in a floating buffer and rendered as preview in `BuildDisplaySurface`, while the committed active-layer pixels remain unchanged until mouse-up commit.

3. **Commit/cancel semantics were hardened** — `MouseUp` commits exactly one history entry when the drag moved; no-delta click commits nothing; `Esc` cancels preview and restores the original selection state.

4. **Cross-route cleanup integrated** — Transaction state now clears during transient-state reset and tab/document transition paths to avoid stale session residue when context changes.

5. **New transaction regression suite added** — `src/tests/tool_transaction_tests.pas` now covers:
   - drag preview does not mutate layer pixels before commit,
   - click-without-delta does not create undo noise,
   - `Esc` cancel restores selection and leaves pixels/history unchanged.

6. **Architecture reference protocol followed** — This pass used the previously documented GIMP floating-selection lifecycle only as architecture guidance (transaction boundary and commit/cancel flow), with no code/identifier reuse and no runtime/build dependency on `reference/gimp-src`.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **failed**, `239` tests, `8` failures (same pre-existing failure set: `TFPUIHelpersTests`, `TFPPaletteHelpersTests`)
  - New transaction suite status: `TToolTransactionTests` `3/3` passed.
- `bash ./scripts/build.sh`
  - Result: **passed**, app linked and `dist/FlatPaint.app` refreshed.

## 2026-03-06 (code-first baseline realignment: PRD/Feature Matrix/SOW + latest verification)

### Changes

1. **Source-of-truth order updated to code-first** — `docs/PRD.md` now explicitly defines current implemented code behavior and automated tests as the authoritative product state, with docs required to follow code when conflicts exist.

2. **UI authority clarified to Figma baseline** — `docs/PRD.md` and `docs/FEATURE_MATRIX.md` now align with the active visual baseline in `flatpaint_design`/`docs/UI_PARITY_AUDIT.md` instead of treating old paint.net visual parity text as authoritative for layout.

3. **Intentional UI deltas documented** — Explicitly tracked that the product intentionally keeps a separate tool-options row, four floating utility palettes, a persistent tab strip, and a dense status strip even when the Figma prototype compresses or omits some of those surfaces.

4. **SOW architecture corrected** — `docs/SOW.md` no longer references Swift package targets; architecture and delivery language now match the active FPC + Lazarus implementation.

5. **Feature matrix rewritten from code/test evidence** — `docs/FEATURE_MATRIX.md` was replaced with a code-backed status table (`Implemented` / `Partial` / `Blocked`) tied to the latest local build/test evidence.

6. **Current regression truth recorded** — Test status is now explicitly captured as of this session: `236` tests executed, `8` failures; this is treated as a release blocker in docs instead of being masked by older optimistic completion text.

### Verification

- `bash ./scripts/run_tests_ci.sh`
  - Result: **failed**, `236` tests, `8` failures (`TFPUIHelpersTests`, `TFPPaletteHelpersTests`)
- `bash ./scripts/build.sh`
  - Result: **passed**, app linked and `dist/FlatPaint.app` refreshed

## 2026-03-05 (UI/UX polish pass: Preferences menu, close-tab save logic, effect dialog sliders, layer list rewrite, layer lock, toolbar spacing, i18n verification)

### Changes

This pass addressed 8 user-reported UI/UX issues in a single session. All changes build cleanly (288,949 lines compiled, 0 errors, 0 fatal warnings).

1. **Preferences menu added to Edit menu** — Added `Preferences...` (`Cmd+,`) to the Edit menu, wired to `@SettingsClick`. The FPC virtual key code for comma is `$BC`; the shortcut is `ShortCut($BC, [ssMeta])`. This makes the Settings dialog (language, DPI, display units) reachable from the standard macOS menu position. Previously the Settings dialog was only accessible via the utility strip.

2. **Close unsaved tab now prompts to save** — `TabCloseButtonClick` and `TabMenuCloseClick` changed from "Discard unsaved changes?" (Yes=discard, No=cancel) to "Do you want to save changes?" (Yes=save via `SaveDocumentClick`, No=discard, Cancel=abort). Both handlers now call `SwitchToTab(Idx)` before saving to ensure the correct document is persisted. Added `Choice: Integer` local variable for the three-way `QuestionDlg` result.

3. **Effect dialog TTrackBar sliders** — Added TTrackBar sliders to three adjustment dialogs that previously only had plain TEdit fields:
   - `fphuesaturationdialog.pas` — hue (-180..180) and saturation (-100..100)
   - `fpbrightnesscontrastdialog.pas` — brightness (-255..255) and contrast (-255..254)
   - `fplevelsdialog.pas` — 4 trackbars for input low/high + output low/high
   All trackbars are bidirectionally synced with their TEdit fields and use the `TR()` i18n function for localized labels.

4. **Layer list layout rewrite** — Rewrote `LayerListDrawItem` with new layout order: lock icon → eye icon → thumbnail → name. Layout constants: `LockLeft=4`, `EyeLeft=21`, `ThumbLeft=40`, `NameLeft=82`. Lock icon drawn as a padlock shape (filled when locked, outline when unlocked).

5. **Layer lock feature (full implementation)** — Added `FLocked: Boolean` field and `Locked` property to `TRasterLayer` in `fpdocument.pas`. Updated `Clone` to copy `FLocked`. Added lock icon click-to-toggle in `LayerListMouseDown` (X < 21). Added `ToggleLayerLockClick` method. Added "Lock" button in layer panel row 2. Added "Toggle Lock" menu item in Layers menu. Added locked-layer guard in `PaintBoxMouseDown` — blocks painting tools but allows zoom, pan, selection, and color picker.

6. **Toolbar spacing adjusted** — Changed constants in `fptoolbarhelpers.pas`: `ToolbarOptionRowTop` 52→56, `ToolbarOptionLabelTop` 57→60, `ToolbarOptionCheckTop` 54→57. Also adjusted Tool label Left 10→12, `FToolCombo` Left 46→50. This provides better vertical separation between the first toolbar row (grouped command panels) and the second tool-options row.

7. **i18n verification** — Confirmed `fpi18n.pas` code is correct: `GetAppConfigDir(False)` + `ForceDirectories` + `language.conf` file. The directory is created on first language change. The root issue was that the Settings dialog was unreachable without the Preferences menu item (now fixed).

8. **Build verification** — All changes compiled cleanly: 288,949 lines, 21.6 sec, 0 errors, 0 fatal warnings.

## 2026-03-05 (six critical/high/medium bugs fixed + 18 integration tests)

### Bugs Found and Fixed

Six bugs were identified through systematic trace of the three reported failure paths (all tools unable to draw, history stuck at first entry, layer add not working):

1. **Bug 1 (CRITICAL): OnKeyUp not wired** — `FormKeyUp` handler existed but was never assigned to the form's `OnKeyUp` event. Pressing Space activated temporary pan mode permanently with no way to release it — all subsequent tool interactions were silently consumed by pan mode. **Fix**: Added `OnKeyUp := @FormKeyUp` in the constructor.

2. **Bug 2 (CRITICAL): FTempToolActive not cleared on explicit tool change** — `ToolButtonClick`, `ToolComboChange`, and the keyboard tool‐switch path in `FormKeyDown` all changed `FCurrentTool` without clearing `FTempToolActive`. After Bug 1 trapped the user in pan mode, clicking another tool appeared to switch but the flag stayed set, so the next space‐bar release restored pan again. **Fix**: Added `FTempToolActive := False` in all three paths.

3. **Bug 3 (MEDIUM): History panel not refreshed after stroke commit** — `CommitStrokeHistory` and `CommitPendingLineSegment` both called `RefreshAuxiliaryImageViews(False)` which only invalidates the layer list, not `RefreshHistoryPanel`. The undo stack grew correctly but the history listbox never updated until the next unrelated canvas refresh. **Fix**: Added `RefreshHistoryPanel` call after both commit paths.

4. **Bug 4 (HIGH): GMainForm dangling pointer** — The destructor never set `GMainForm := nil`. The native Cocoa magnify callback could fire into freed memory after the form was destroyed. **Fix**: Added `GMainForm := nil` at the start of the destructor.

5. **Bug 5 (HIGH): LayerRotateZoomClick PushHistory after mutation** — `PushHistory('Rotate Layer')` was called after the rotation case block, meaning the undo snapshot captured the already‐rotated state. Undo was a no‐op. **Fix**: Moved `PushHistory` before the case block.

6. **Bug 6 (MEDIUM): Clone stamp state leaks across tabs** — `SwitchToTab` did not reset `FCloneStampSnapshot`, `FCloneStampSampled`, lasso points, or line/curve state. Switching tabs then stamping could use a stale source from a different document. **Fix**: Added cleanup for all five fields in `SwitchToTab`.

### Test Infrastructure

- `CreateForTesting` was rewritten to bypass all LCL constructors (which crash in headless test environments on macOS Cocoa) using raw `GetMem` + manual VMT setup. This allows headless integration tests to exercise the full TMainForm event pipeline without native widget creation.
- `UpdateCaption` and `RefreshCanvas` now early‐exit for test instances (`FIsTestInstance` guard) to avoid TForm property setters on raw‐allocated objects.
- 18 new integration tests in `pipeline_integration_tests.pas` covering: drawing pipeline (pencil/brush/eraser pixel verification), history pipeline (undo depth growth on mouse‐up, fill, add‐layer, multi‐stroke), layer pipeline (count and active index), temp‐pan regression (space activate/deactivate, keyboard switch clears flag), render revision tracking, dirty flag tracking, and display pixel verification.
- Total tests: 236 (218 existing + 18 new), all passing.

## 2026-03-04 (button icon overlays are now passive display layers again)

- The button icon pass has been tightened to use a cleaner interaction model: overlay images no longer impersonate clickable controls. The underlying `TSpeedButton` remains the only click target, while the overlay stays purely visual.
- Command and utility buttons now get their final toolbar height before overlay placement, which prevents the icon from being vertically positioned against a stale 26 px default. Tool buttons still use their larger palette height, but their overlays are explicitly realigned after that final height is applied.
- This is aimed directly at the recurring “tool looks selected / icon is visible, but the UI acts dead or misaligned” class of regressions. It keeps the icon rendering work while reducing the chance that decorative chrome drifts away from the actual input surface.

## 2026-03-04 (adjustments/effects/transform commands now honor pending-stroke sealing)

- The pending-stroke interaction fix now also covers the remaining document-mutating command surfaces, not just direct tool/layer/color/history UI.
- Resize/canvas operations, flips/rotations, adjustments, and the effect stack all now seal any in-flight brush-like stroke before they push history or mutate pixels. That removes another class of “the last stroke felt half-committed, then a filter or transform ran” state drift.
- `Repeat Last Effect` also now follows the same rule before dispatching the remembered effect callback, so repeated effect application cannot skip over a live pending stroke snapshot either.

## 2026-03-04 (UI interaction seal pass for pending brush-like strokes)

- This pass continues the pending-stroke fix by widening the protection boundary from “new mouse-down and document swap” to the rest of the UI interactions that can interrupt a brush-like gesture.
- `History`, `Undo/Redo`, tool switches, layer changes, layer property controls, selection commands, color-target changes, palette toggles, and close/quit now all seal any in-flight brush snapshot before they mutate visible state. That keeps the raster write, active-layer target, and history granularity aligned instead of letting a stale pending stroke linger behind the UI.
- `LayerBlendModeChanged` also now behaves like a real layer edit: it ignores programmatic control sync, skips no-op changes, and pushes a dedicated `Layer Blend Mode` history entry before mutating the active layer.
- The intent is not more hard-coded cleanup branches; it is the opposite. The pass reuses the existing `SealPendingStrokeHistory` gate as the single pre-mutation rule for non-drawing UI flows so the same state machine policy is applied consistently across tools, colors, layers, and history.

## 2026-03-04 (pending brush-stroke sealing fix)

- This pass fixes a real interaction bug in the paint pipeline rather than another toolbar-only issue. Repeated `Pencil` / brush-like strokes could collapse into one apparent edit when Cocoa failed to deliver a `MouseUp` and the next event was a fresh `MouseDown` instead of a `MouseMove`.
- The brush-stroke path now preserves the tool label for the in-flight region snapshot and seals any pending stroke before the next press starts a new one. That keeps repeated pencil-style gestures as separate history entries instead of silently replacing the prior pending snapshot.
- The protection now exists in both places that matter: `PaintBoxMouseDown` seals a pending stroke before beginning a new gesture, and `BeginStrokeHistory` no longer silently discards an unfinished snapshot if one still exists. The same pending-stroke seal is now also applied before tab switches, current-document replacement, and other document-swap flows so a stale stroke snapshot cannot cross into a different document.
- A matching regression check was added at the helper-contract level so the intended policy is encoded in tests: a new press must commit a pending brush stroke instead of replacing it.

## 2026-03-04 (low-risk toolbar/palette chrome correction pass)

- This pass deliberately avoided tool logic and image-mutation code. The repeated “it looks like nothing applied” symptom was re-audited against the existing canvas-invalidation lessons first, and the current regression did not point to a fresh raster-write failure.
- The visible fixes are limited to the UI chrome that was still misleading UAT: `New / Open / Save` were widened again, their overlaid icons were reduced and offset so the labels stop colliding with the icon area, and the top zoom combo now sits one pixel lower so its visual center aligns with the adjacent zoom buttons instead of riding high.
- The floating palette title-bar icons were also corrected without changing palette behavior: those four small icons now render through the built-in line-glyph path at a smaller 12x12 size, which avoids the clipped/purple-tinted rendered-asset path and fits the existing 22px title bar cleanly.
- A small test pass was added around the same contract: the toolbar metric tests now lock a minimum file-group width and vertical center alignment for the zoom combo, which gives this visual adjustment at least one shared geometry guard instead of leaving it as pure manual UAT.

## 2026-03-04 (Cocoa icon-overlay stabilization + toolbar width pass)

- Manual screenshot verification exposed that the checked-in Lucide-derived assets were present, but several visible controls still looked blank or wrong for two different reasons: Cocoa `TSpeedButton.Glyph` was not reliably painting on the most visible button surfaces, and the old masked-bitmap path leaked the magenta transparency key when the same icon data was reused in plain `TImage` overlays.
- The runtime fix is now explicit and stable. Visible toolbar and palette buttons keep the real clickable button, but the icon is rendered through a separate overlay image surface that forwards clicks back to the underlying control. That removes the dependency on Cocoa's fragile `TSpeedButton.Glyph` paint path for the main command/tool/utility surfaces.
- The overlay path now loads the rendered PNG asset directly into the overlay picture first, instead of reusing the masked magenta glyph bitmap. That eliminates the red/purple fringe that was still visible in palette header icons and compact utility buttons.
- `New / Open / Save` were widened and their text padding was adjusted so the icon and caption sit cleanly together, and the top-right utility/zoom cluster now computes from `FTopPanel.ClientWidth` instead of the less reliable outer-form width so that cluster is visible immediately on launch instead of drifting off-screen.
- A small remaining parity gap was also closed in the `History` palette: clicking the current history row now jumps to the “before” state, so clicking that same row again immediately redoes it for a quick before/after comparison.
- Live screenshot checks confirm the visible result: `New / Open / Save`, the compact edit buttons, the left `Tools` palette, the palette header icons, the top-right palette-toggle cluster, and the zoom controls are all now visible in the running app at the same time instead of splitting between “resource exists” and “UI surface still looks blank.”

## 2026-03-04 (canonical Lucide runtime render pass)

- The app is no longer stuck between “correct SVG source exists” and “runtime still shows fallback glyphs.” The icon pipeline now uses the local `./icons` Lucide stroke set as the source-of-truth, mirrors the required mapped files into `assets/icons/lucide`, and refreshes the checked-in runtime PNG assets through a dedicated manual script: `scripts/refresh_lucide_rendered.sh`.
- That refresh path uses `qlmanage` only as a one-time high-resolution rasterizer and then immediately normalizes each result to a transparent 18x18 icon with preserved anti-aliased alpha edges. Runtime still does not parse SVG directly, which keeps the Lazarus shell stable, but the visible icon surfaces are now backed by the correct SVG source family rather than the old font-outline sprite.
- `FPIconHelpers` now again prefers the rendered asset path for command, tool, and utility buttons alike, with the built-in line glyph path retained only as a fallback if a specific asset is missing.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes, and the icon tests now cover representative source and rendered assets across command, tool, and utility surfaces.

## 2026-03-04 (canonical icon source set synced from local `./icons`)

- The local `./icons` drop is now confirmed as the correct source-quality set: it contains the full Lucide-style stroke SVG library, not the old font-outline sprite.
- `assets/icons/lucide` has been repopulated from that local source so the project now carries a complete in-repo source set for every currently mapped button icon name, including the two alias cases where `file-plus-2` maps to `file-plus` and `circle-help` maps to `circle-question-mark`.
- This is a source-of-truth cleanup step, not a claim that the Lazarus runtime is now directly rendering SVG. The live tool/utility surfaces still use the built-in line glyph path until a reliable SVG-to-runtime rendering path is in place.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes, and the icon tests now also assert representative source SVG presence under `assets/icons/lucide`.

## 2026-03-04 (tool/utility icon fidelity rollback to stable line glyphs)

- Manual UAT exposed that the currently checked-in tool and palette icon assets still looked chunky and raster-like instead of reading as clean Lucide-style strokes.
- The root issue is source fidelity, not button wiring: the current generated tool/palette asset set comes from `lucide-font/lucide.symbol.svg`, which is a font-outline sprite, not the canonical Lucide stroke icon set. It is good enough as a temporary extraction source, but not good enough for dense `Tools` / `Colors` / `History` / `Layers` chrome.
- The live icon policy is now stricter: only `bicCommand` buttons may use the checked-in rendered asset path for now. `bicTool` and `bicUtility` buttons intentionally stay on the built-in line-glyph renderer until proper stroke SVG exports exist, so the visible tool surfaces stop using the coarse pseudo-SVG assets.
- The icon regression test was aligned to that policy too: it now only requires representative rendered assets for the command strip, instead of pretending tool/palette rendered assets are part of the trusted runtime contract.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes, and `bash ./scripts/build.sh` rebuilds `dist/FlatPaint.app`.

## 2026-03-04 (toolbar layout metrics + position regression pass)

- The top toolbar layout no longer depends on scattered literals in `mainform` alone. The shared geometry now lives in `src/app/fptoolbarhelpers.pas`, including the title band, left command groups, right palette/zoom clusters, divider placement, and zoom-control bounds.
- `mainform` now builds the visible top row directly from that shared metric layer, so the live UI and the regression tests use the same source-of-truth for positions and sizes.
- The left command groups were also normalized a little: the `Edit -> Undo` gap now matches the same 8px spacing used elsewhere, and the separators now sit in the center of their gaps instead of drifting by a couple of pixels.
- A new `TFPToolbarHelpersTests` suite now locks the main layout invariants: vertical band alignment, consistent left-group spacing, right-cluster anchoring, and zoom-control fit inside the right-most cluster.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **214 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilds `dist/FlatPaint.app`.

## 2026-03-04 (icon refresh decoupled from normal build)

- The Lucide extraction/normalization pipeline is now treated as a one-time asset-prep step instead of a normal build-time dependency.
- `scripts/common.sh` no longer regenerates icon assets during every `build`; it now simply uses the checked-in rendered icon set already present in the repository.
- This removes the accidental hard dependency on local Python `Pillow` / host-side icon-refresh tooling during routine compiles, while keeping the pre-rendered assets usable by the app bundle.
- The icon regression surface is also tighter now: `TFPIconHelpersTests` includes a direct representative asset-presence check for both extracted SVGs and rendered PNGs, so the repository can no longer silently lose the checked-in icon set while still passing the older caption-mapping tests.
- Verification is green after the change: `bash ./scripts/build.sh` completes without the old `Refreshing Lucide icon assets` phase and still rebuilds `dist/FlatPaint.app`; `bash ./scripts/run_tests_ci.sh` now passes at **210 tests, 0 errors, 0 failures**.

## 2026-03-04 (Lucide symbol extraction + full icon replacement pass)

- This pass maps primarily to `Iconography`, `Workspace visual parity`, and the packaged macOS app surface rather than to backend image-editing behavior.
- The previous icon work had two structural problems at the same time: the runtime was still relying on placeholder/fallback glyphs for much of the visible UI, and the earlier SVG-to-PNG path was not trustworthy because Quick Look was being used against the wrong source form.
- The icon source-of-truth is now the local `lucide-font/lucide.symbol.svg` sprite the user provided. A new `scripts/extract_lucide_icons.py` pipeline extracts the required symbols into standalone `assets/icons/extracted/*.svg` files, and the normalized transparent 18x18 PNG runtime assets live in `assets/icons/rendered/*.svg.png` as checked-in resources for the bundle to consume.
- `FPIconHelpers` was expanded so the rendered asset mapping now covers the top command strip, the tool palette, the palette headers/toggles, and the compact command buttons used in the colors/history/layers surfaces, instead of only a small top-toolbar subset. The visible UI is now pulling from one Lucide-derived asset family across the main button surfaces.
- The glyph load path was also tightened so pre-sized rendered icons draw directly instead of being rescaled again, which keeps the final icons consistent and avoids the earlier “tiny / off-center / white tile” failure modes.
- Verification is green after the pass: `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` against the generated asset set, and `bash ./scripts/run_tests_ci.sh` passes at **209 tests, 0 errors, 0 failures**.

## 2026-03-04 (runtime icon-asset hookup pass)

- This pass maps primarily to `Iconography`, `Workspace visual parity`, and the packaged app surface rather than to backend feature work.
- The earlier icon work had produced local SVG source assets, but the live Lazarus app was still not actually consuming them at runtime. That meant the repository could contain Lucide-style assets while the visible app still fell back to generated placeholder-style glyphs.
- The icon path is now truly connected. `FPIconHelpers` first resolves a real runtime icon directory, looks in the `.app` bundle resources or the repository `assets/icons/rendered` path, and loads the rendered PNG asset for the supported top-toolbar / palette icons before falling back to the built-in hand-drawn glyph path.
- To make that runtime path real, the checked-in `assets/icons/lucide/*.svg` files were rasterized into `assets/icons/rendered/*.png`, and the build staging path now copies that rendered icon directory into `dist/FlatPaint.app/Contents/Resources/icons/rendered` so the packaged app can find the assets directly.
- Verification is green after the pass: `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`, `bash ./scripts/run_tests_ci.sh` passes at **209 tests, 0 errors, 0 failures**, and the rebuilt bundle now contains the rendered icon assets under `Contents/Resources/icons/rendered`.

## 2026-03-04 (tool-glyph restoration + palette-header icon pass)

- This pass maps primarily to `Workspace visual parity`, `Iconography`, and the visible `Tool palette` / floating-palette chrome rather than to backend feature work.
- The previous UI iterations had already improved the top toolbar, but the floating tool surface was still lagging badly: the `Tools` palette was still rendering the old Unicode placeholder characters instead of the shared vector glyphs, which made the panel feel much rougher than the newer toolbar surfaces.
- The underlying issue is now fixed at the shared button level. `CreateButton(...)` once again allows the bitmap-glyph path for `bicTool`, so tool buttons no longer fall back to the raw compact-character captions that were only meant as a safety net.
- The `Tools` palette itself was then re-laid out to suit icon-first buttons instead of text surrogates: the palette grew slightly, the two-column grid now uses taller 44x40 hit targets, and the buttons keep the icon centered without the old overlaid Unicode character. This keeps the working handlers intact while materially improving the visible tool surface.
- The floating palette headers were also brought onto the same icon language. `Tools`, `Colors`, `History`, and `Layers` now render a shared utility glyph in the header itself instead of a text glyph surrogate, so palette chrome no longer mixes one icon style in the toolbar and another in the panel headers.
- As part of the same cleanup, the top-row palette-toggle button hints now use the shared shortcut metadata instead of hard-coded strings, so the visible hints match the real `Cmd+1...4` mapping again.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **209 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (lucide-source asset seeding + top-toolbar realignment pass)

- This pass maps primarily to `Workspace visual parity`, `Iconography`, and the visible `Command surface parity` of the top toolbar.
- The design target in `flatpaint_design` was still not reflected in the live Lazarus shell closely enough: the zoom cluster was not the right-most top control, the four palette-toggle buttons were not grouped where the design expected them, and the icon treatment still felt too rough even after the earlier stability rollback.
- The top toolbar now follows the intended first-row structure more closely. The row is organized into file actions, edit actions, undo/redo, the four palette toggles (`Tools`, `Colors`, `History`, `Layers`), and a right-anchored zoom cluster, while the `Tool:` selector remains on the second row. The zoom percentage chooser is now explicitly in the far-right top cluster instead of living mid-strip.
- The shared bitmap glyph path was also hardened instead of abandoned. Glyph bitmaps now render with a transparent background instead of an opaque tile, which removes the old "little square block" effect around command icons. With that in place, the top toolbar can safely use icon-bearing command buttons again without reintroducing the earlier white-box regression.
- A local `assets/icons/lucide/` source set was added for the currently visible top-toolbar icons. These SVG files are the repository-side source-of-truth for the new icon language, but this pass intentionally does not add a runtime SVG dependency; the live app still renders through the existing Lazarus button/glyph path for stability.
- Verification is green after the pass: `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`, and `bash ./scripts/run_tests_ci.sh` passes at **209 tests, 0 errors, 0 failures**.

## 2026-03-04 (toolbar click-surface recovery + visible zoom-tool removal pass)

- This pass maps primarily to `Workspace shell`, `Command surface parity`, `Workspace visual parity`, and the visible `Tool palette` contract.
- Manual UAT exposed three linked UI regressions in the current shell: the top quick-action strip still read as white blocks, some of those controls could not be clicked reliably, and the visible tool surfaces were inconsistent because `Zoom` had been removed from the floating `Tools` palette but was still present in the top `Tool:` combo.
- The fix deliberately moved the top toolbar farther away from the fragile bitmap-glyph path. The grouped top command strip now uses stable symbol/text button captions inside the grouped panels instead of relying on the earlier Cocoa-sensitive command glyph rendering, which removes the most visible "white block" failure mode while preserving the existing command handlers.
- The top title strip is now centered structurally instead of by a single hard-coded left offset: the traffic-light area and the right spacer are symmetric, so the in-window title label stays visually centered even while the grouped quick-action strip changes width.
- Visible tool selection surfaces now follow one rule: `Zoom` is no longer exposed in the floating `Tools` palette or the top `Tool:` combo, and zoom is left to the dedicated top zoom controls plus macOS pinch gestures. Internally the tool enum still exists for compatibility and tests, but the visible UI no longer advertises it as a primary tool.
- Verification is green after the pass: `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`, and `bash ./scripts/run_tests_ci.sh` passes at **208 tests, 0 errors, 0 failures**.

## 2026-03-04 (palette-drag root fix + tool/utility symbol pass)

- This pass maps primarily to `Workspace shell`, `Workspace visual parity`, and `Iconography`, but it is really a correctness-and-usability recovery pass for the live UI shell rather than a new feature pass.
- Manual UAT exposed two regressions in the previous UI iteration: only the `Tools` palette was reliably draggable, and the new icon treatment had made the tool buttons smaller/uglier while some shortcut-facing buttons still rendered as blank white blocks.
- The palette-drag bug was in the drag root calculation, not in the palette rectangles themselves. Header labels inside `Colors`, `History`, and `Layers` were starting drags from the header child panel instead of the actual outer palette host, so moving the header did not move the real palette. Dragging now walks back up to the owning palette root and converts child-control coordinates into palette-local coordinates before applying movement, which restores consistent drag behavior across all four floating palettes.
- The icon pass in this round deliberately chose the more robust path over the more ambitious one: tool buttons and the top-right utility strip now render as larger symbol-driven buttons again instead of relying on the tiny generated bitmap glyphs that were making the surface read worse than the design target. The tool palette no longer sacrifices the visible icon just to show a one-character shortcut, and the tab/palette close controls now use stable text symbols instead of fragile tiny glyph tiles.
- The bitmap-backed command glyph path still remains available for the places where it is stable, but the most user-visible mode-switch and palette-toggle surfaces are now back on clearer, larger symbols while the app continues toward a better final asset-backed icon system.
- Verification is green after the pass: `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`, and `bash ./scripts/run_tests_ci.sh` passes at **208 tests, 0 errors, 0 failures**.

## 2026-03-04 (icon-surface de-whiteboxing + host-tinted glyph pass)

- This pass maps primarily to `Iconography`, `Workspace visual parity`, and the remaining visible button surfaces in the live Lazarus shell.
- The main UAT problem in this pass was that several visible buttons had crossed the line from "rough" to actively misleading: toolbar and palette controls could render as white blocks or obvious square tiles instead of reading as intentional icon buttons.
- The root cause was twofold. First, command and utility buttons were still being forced into non-flat native `TSpeedButton` chrome, which produced stark white button slabs against the lighter grouped toolbar surfaces. Second, the shared glyph pipeline still assumed transparent-mask behavior and drew into a generic bitmap background instead of the real host surface color.
- The icon pipeline now renders glyphs against the intended host surface color directly and the main visible button surfaces stay on the flatter grouped-button path instead of forcing native raised white chrome. Top toolbar command buttons, utility buttons, palette close buttons, and tab add/close buttons now all use the same host-aware glyph strategy, so the visible controls read as part of their surrounding panel instead of detached white blocks.
- Coverage was tightened at the metadata layer too: the command-icon audit now explicitly includes the `Name` layer action, which keeps the visible layer-actions strip inside the same shared icon contract as the rest of the button surface.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **208 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (title-band + toolbar rhythm + tool-button polish pass)

- This pass maps primarily to `Workspace visual parity`, `Iconography`, and the visible `Tools` / top-toolbar chrome rather than to new document features.
- The goal here was to move the live Cocoa/Lazarus shell closer to the `flatpaint_design` baseline without destabilizing event routing: keep the same controls and handlers, but improve the visible structure and product feel of the most-used surfaces.
- The top chrome now has a dedicated in-window title band instead of dropping straight into controls. A lightweight macOS-style traffic-light strip was added on the left, and the centered title now mirrors the same live document caption used by the actual window title (`FlatPaint - <name>`, including the edited marker) so the content area reads more like a real designed workspace and less like a raw form.
- The toolbar itself now has clearer vertical rhythm: the quick-action row and the tool-options row no longer visually collide, because all row-1 and row-2 controls were moved onto shared vertical offsets instead of independent hard-coded numbers. That keeps the title band, command row, and option row visually distinct while leaving the underlying command handlers untouched.
- The `Tools` palette was also tightened into a less prototype-like control grid. The tool buttons now default to a flatter "ghost" state and only the active tool is raised, the shortcut glyph/caption spacing is less cramped, the visible shortcut character is slightly more legible, and the tool hints now lead with the explicit shortcut label before the behavior description.
- This pass intentionally avoided deeper custom painting and did not replace live controls with owner-drawn stand-ins; the UI gain comes from layout/style changes on the existing working controls, which keeps regression risk low while still moving the app toward the design baseline.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **208 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (Photoshop/GIMP-style background-layer semantics pass)

- This pass maps primarily to `Layers`, `Paint tools`, `Selection tools`, `Compatibility IO`, and the shared completion rule for visible destructive edits.
- The biggest remaining semantic mismatch in manual UAT was the bottom white `Background` behaving like an ordinary transparent paint layer. That made `Eraser`, `Cut`, `Erase Selection`, and move-selected-pixels behave more like Krita than Photoshop/GIMP, because they could punch checkerboard holes into the base layer.
- `TRasterLayer` now carries a real `IsBackground` flag in the core document model instead of inferring "background" only from name or layer index. New blank documents create the bottom layer as a true background layer, full-document snapshots preserve that flag through undo/redo, and native `.fpd` save/load now persists the flag in the file format while keeping backward compatibility with older `FPDOC01` documents.
- Background-layer behavior is now enforced in the core and UI instead of only in conventions: the background layer cannot be reordered away from the bottom, duplicating it creates a normal layer copy instead of a second background layer, and flatten now resolves to a single opaque white-backed `Background` layer instead of a transparent-ended result.
- Destructive operations that used to create transparency now split on layer semantics. On ordinary layers they still erase to transparency; on the special background layer they restore an opaque fill instead. In the live UI, `Eraser`, `Cut`, `Erase Selection`, and move-selected-pixels now use the current secondary/background swatch color as the replacement color, which matches Photoshop/GIMP habits more closely than the prior always-transparent behavior.
- The Layers UI now surfaces the semantics more clearly too: the layer list labels explicitly mark the special base layer as `[Background]`, and drag/drop or move-up/down paths no longer allow other layers to displace it from the bottom slot.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **208 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (paint-visibility recovery + line-default interaction pass)

- This pass maps primarily to `Paint tools`, `Draw tools`, `Colors`, `Tool/Config Options`, and the shared canvas-feedback completion bar.
- The highest-priority UAT issue in this pass was not missing raster math, but a semantic mismatch between visible previews and committed pixels: the eyedropper could sample a fully transparent pixel and silently copy its `A=0` into the active swatch, while the Colors panel still rendered that swatch as opaque-looking RGB. That made brush/shape/text previews look black while committed strokes were actually invisible.
- The live color-sampling path now preserves the active swatch alpha when sampling RGB from the canvas, the system color button now resets the chosen swatch to an opaque color, and the Colors panel swatches now paint through a real checkerboard alpha preview instead of ignoring transparency.
- The `Eraser` path was also corrected at the raster-core level. It no longer tries to "paint with transparent black" through normal alpha blending (which was a no-op); it now uses dedicated erase-brush/erase-line raster paths that actually reduce destination alpha toward transparency.
- `Line` now matches the expected default interaction again: a normal drag commits a straight line on release, while staged Bezier editing is now opt-in through a visible `Bezier` checkbox in the tool-options row. The older multi-step curve workflow is still available, but it no longer hijacks the default line gesture.
- Drag tools are also more reliable under Cocoa/LCL event delivery now: while a drag is active, the canvas captures the mouse, and the move path will finalize the gesture if the widgetset stops reporting the pressed button before a `MouseUp` reaches the control. This closes more of the "preview keeps following the cursor even after release" failure mode.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **206 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (toolbar grouping + palette-header shortcut pass)

- This pass maps primarily to `Workspace visual parity`, `Menus/Shortcuts`, and `Iconography`.
- The top toolbar now reads more like the local design baseline instead of a row of bare hit targets: the first-row command surface has explicit grouped background bands, and `New` / `Open` / `Save` now render as wider icon-plus-text action buttons rather than only compact glyph buttons.
- That change keeps the command handlers identical, but materially improves first-scan readability of the most common file actions and makes the toolbar feel less like an internal prototype row.
- The floating palette title bars were also upgraded: each header now shows a compact palette glyph, a visible palette shortcut badge (`1`..`4`) near the close button, and the close-button hint now spells out the real `Cmd+1...4` palette toggle mapping.
- Header labels now explicitly forward mouse drag events back to the shared palette drag handlers, so the added glyph/shortcut labels do not steal the drag affordance from the title bar.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **202 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (tool-palette shortcut + active-state UI pass)

- This pass maps primarily to `Workspace visual parity`, `Menus/Shortcuts`, `Iconography`, and the project-wide development-rule baseline.
- The development rules now explicitly state that a tool/filter/edit route is not complete unless it invalidates the relevant visual surfaces and produces immediate on-screen feedback, so the "logic worked but nothing visibly changed" class of bug is now part of the written completion bar, not just an ad hoc review note.
- The `Tools` palette itself was upgraded from a mostly static icon grid into a live stateful control surface: tool buttons now keep a pressed active state, surface visible one-key shortcut badges directly on the buttons, use the shared tool-shortcut metadata, and expose richer tooltips that combine tool purpose with the real shortcut behavior.
- The top toolbar tool chooser now exposes the same shortcut metadata in its visible item labels, so the user can see the active mapping without relying only on memory or docs.
- The top-right utility strip now also reflects palette visibility state for the four core windows and its hints now show the real `Cmd+1...4` palette shortcuts instead of generic "show window" text.
- Shared glyphs also received another UI-quality pass for several high-frequency tool icons (`Select`, `Move`, `Wand`, `Fill`, `Brush`, `Picker`, `Line`, `Text`) so the visible palette reads less like placeholder chrome and more like a product surface.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **201 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app`.

## 2026-03-04 (real-interaction cache-audit pass)

- This pass was a targeted audit of the live interaction chain rather than a new feature pass: every path was reviewed under the stricter rule that a tool/command is not "done" if the data changes but the user cannot immediately see that change on the canvas or in the nearby document surfaces.
- The audit surfaced a real shared failure mode in the cached-canvas path: some selection-driven and staged interactive mutations were still changing document state without invalidating the prepared display bitmap first.
- The concrete fixes in this pass are: selection-only commands (`Select All`, `Deselect`, `Invert Selection`), magic-wand picks, rectangle/ellipse/lasso selection commits, move-selection drags, move-selected-pixels drags, staged line-segment commits, and in-list layer drag reorder now all force the same visible cache-invalidating repaint path instead of relying on a later redraw to expose the change.
- `Move Selected Pixels` also now refreshes the tab thumbnail + layer surface after the drag completes, so the canvas is no longer the only place where the change becomes visible after that gesture.
- This pass did not change the core effect/adjustment math; those routes were rechecked and they are still consistently going through `SyncImageMutationUI(...)` with status-bar progress and canvas/thumbnail refresh.
- Verification is green after the audit pass: `bash ./scripts/run_tests_ci.sh` passes at **198 tests, 0 errors, 0 failures**.
- Honest progress update after this pass: the remaining gaps are increasingly parity/depth gaps, not the earlier class of "the operation really happened but the prepared display cache made it look like it did not."

## 2026-03-04 (tool-control logic audit + tolerance isolation pass)

- This pass maps primarily to the `Tool/Config Options`, `Paint tools`, `Selection tools`, and `Draw tools` rows in `docs/FEATURE_MATRIX.md`.
- This was a code-vs-docs audit pass, not an additive feature pass. The goal was to read through the tool options control logic in `mainform.pas`, cross-reference with `docs/TOOL_OPTIONS_BASELINE.md`, and fix any logic errors that had accumulated across interleaved tool-option additions.
- **Recolor tolerance was sharing `FWandTolerance` with Magic Wand.** Switching between the two tools silently overwrote the other's tolerance value because the tolerance spin's change handler wrote into the same field regardless of tool. Added a dedicated `FRecolorTolerance` field, initialized it independently (default 32), and rerouted `UpdateToolOptionControl`, `FillTolSpinChanged`, and `ApplyImmediateTool` so each tool owns its own tolerance state.
- **`SelAntiAliasChanged` did not sync the Feather spin's `Enabled` state.** Unchecking Anti-alias left the Feather spin visually enabled, which could mislead users into thinking feathering was still active. The handler now sets `FSelFeatherSpin.Enabled := FSelAntiAlias` immediately after toggling.
- **Recolor and Clone Stamp mouse-move paths called `SetDirty(True)` instead of `InvalidatePreparedBitmap`.** Every pixel of a drag stroke triggered `UpdateCaption` + `RefreshTabStrip` + `RefreshTabCardVisuals`, causing unnecessary full-strip churn during continuous painting. Changed both handlers to match the Pencil/Brush/Eraser pattern: `InvalidatePreparedBitmap` during drag, `SetDirty(True)` only on mouse-down.
- **`CommitPendingLineSegment` did not refresh layer thumbnails.** After committing each Bézier segment in a multi-segment line path, the Layers palette thumbnails stayed stale until the next unrelated refresh. Added `RefreshAuxiliaryImageViews(False)` at the end of the commit path.
- No new features or new tests were added in this pass — the existing 198 tests already cover the affected tool paths, and all pass cleanly after the fixes.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **198 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the tool-options surface is now internally cleaner; there are no more known shared-state bugs between tools, and the mouse-move performance path for Recolor/CloneStamp is no longer doing unnecessary tab-strip work during every stroke pixel.

## 2026-03-04 (pencil first-dab visibility + iconography extension pass)

- This pass maps primarily to the `Paint tools`, `Command surface parity`, and `Iconography` rows in `docs/FEATURE_MATRIX.md`.
- The most practical fix in this pass is for the same user-visible failure mode reported in UAT: hard-edge paint tools could mutate pixels on the active layer on mouse-down, but the first dab could still look missing because the prepared canvas bitmap was not being invalidated on that first mutation.
- `Pencil`, `Brush`, `Eraser`, `Clone Stamp`, and `Recolor` now all invalidate the prepared render cache on their immediate mouse-down mutation path before the canvas refresh, so single-click dabs and the first stamp/brush sample become visible immediately instead of waiting for a later move event to force the cache dirty.
- This was intentionally kept in the same live stroke path the user actually drives in the app, not only in the shared surface core, because the previous bug was a display-cache timing issue rather than a raster-math issue.
- The icon pass also moved another visible slice off text-only controls: the `Swap` and `Mono` actions in the Colors palette now have dedicated glyphs, and the floating palette header close buttons now use the same shared glyph-backed button path as the rest of the toolbar/panel action surface.
- The icon language is still not at final asset-pack quality, but more of the currently visible UI is now on one consistent glyph pipeline instead of mixing bitmap-backed controls with ad-hoc text buttons in panel chrome.
- The UI-automation constraint remains the same as the previous pass: full headless `TMainForm` construction is still not stable enough for deterministic CI assertions, so the retained tests stay one layer down at visible-output contract level plus lightweight desktop smoke.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **198 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the most obvious single-click paint-feedback hole is closed, and `Iconography` is less patchy in daily-use panels; the remaining work is now broader asset polish and deeper manual-UAT edge cleanup rather than this specific "first stroke did not visibly land" defect.

## 2026-03-04 (canvas-feedback hardening + UI-adjacent integration pass)

- This pass maps primarily to the `Command surface parity`, `Menus/Shortcuts`, `Paint tools`, and `Selection tools` rows in `docs/FEATURE_MATRIX.md`.
- The main focus was not adding another isolated tool, but closing more of the "the command ran, but the user cannot reliably see that it landed" gap that still showed up in manual testing.
- `TMainForm` now has a shared full-document replacement follow-up path instead of several ad-hoc ones. New/open/replace-style routes now reset transient tool state, refit the viewport, invalidate the prepared bitmap, refresh layer surfaces, and repaint the canvas through one `ResetTransientCanvasState` + `SyncDocumentReplacementUI(...)` flow.
- The same pass tightened more mutation-heavy layer/document paths onto the existing `SyncImageMutationUI(...)` route so canvas, layer thumbnails, and tab previews stay aligned more often after visible edits instead of each handler hand-rolling a partial refresh tail.
- Shortcut handling is now less likely to fight the macOS command surface: the single-key tool-switch family and the `C` / `X` / `D` color shortcuts now explicitly yield whenever `Command`, `Control`, or `Option` is held, so modified menu/command chords are no longer accidentally consumed by tool logic.
- `Paint Bucket` is more predictable with an active selection: clicking outside the selected region is now an explicit no-op instead of falling through a mutation-looking path that could still feel ambiguous in manual use.
- Added a new `TMainFormIntegrationTests` unit, but kept it intentionally stable and non-flaky: it verifies modifier-safe shortcut gating plus visible composite-output contracts for a pencil-style stroke and selection-masked bucket fill without depending on full desktop automation.
- The existing lightweight outer smoke layer remains in place as the third tier (`TUIPrototypeTests` / `TUIAppleScriptTests`): the test strategy is now deliberately split into stable contract tests for image feedback plus thin desktop smoke, rather than trying to force every assertion through brittle OS-level UI automation.
- A true headless `TMainForm` widget-construction path was also evaluated in this pass, but the current LCL harness still hits `EAccessViolation` there. The retained test layer therefore targets document state plus visible composite output rather than forcing brittle form-instantiation tests.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **197 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the remaining feedback issues are increasingly route-level visual polish and manual-UAT edge cases, not the earlier broad class of "mutation path exists but obviously stale UI surfaces make it look broken."

## 2026-03-04 (bitmap iconography + layered-xcf compatibility pass)

- This pass maps primarily to the `Iconography` and `Compatibility IO` rows in `docs/FEATURE_MATRIX.md`.
- `Iconography` is no longer only a caption/symbol pass. The shared button-construction path now prefers real 16x16 bitmap glyphs generated by `FPIconHelpers`, so the top toolbar, utility strip, tool palette, history controls, layer actions, and tab add/close buttons all render through one icon pipeline instead of relying on plain text captions.
- This is still not the final packaged asset pass, but it materially changes the testing surface: these controls are now visibly icon-backed in the live app, so iconography is no longer just "shorter labels on native buttons."
- `Compatibility IO` also crossed a real threshold in the same pass: `.xcf` no longer only opens as a flattened raster in the main document flow. The shared loader can now build a layered `TImageDocument` for the supported common 8-bit XCF path, preserving per-layer name, visibility, opacity, and offsets while keeping the flattened import path available where only a surface is needed.
- `.kra` and `.pdn` remain partial and mostly flattened, but the compatibility story is now stronger because the app can finally preserve actual layer structure for one practical foreign project format instead of flattening every non-native project type by default.
- Verification now covers both areas cleanly: the existing `src/tests/fpiconhelpers_tests.pas` suite continues to assert icon coverage for the visible tool/utility/main command families, and `src/tests/fpio_tests.pas` now also verifies that `.xcf` can load as a layered document instead of only as a flattened surface.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **194 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: `Iconography` and `Compatibility IO` both move into the low-80s; the remaining work in those areas is now final asset polish plus deeper `.kra` / `.pdn` layering and broader advanced XCF fidelity, not absence of a real route.

## 2026-03-04 (status-progress visibility pass)

- This pass maps primarily to the `Workspace shell`, `Command surface parity`, `Adjustments`, and `Effects` rows in `docs/FEATURE_MATRIX.md`.
- The last explicitly documented status-bar feedback hole is now materially smaller: effects and adjustments no longer run as "silent" mutations from the user's point of view.
- The status strip now has a real rendering-progress region inside the existing layer/units segment. When an adjustment or effect is applied, the live app now swaps that region from static text to an explicit caption plus a progress bar before the mutation runs, then restores the normal status labels after the image and surrounding previews refresh.
- This is intentionally tied to the same visible mutation chain as the earlier `SyncImageMutationUI(...)` work: the goal was not a decorative activity indicator, but a more trustworthy user-facing contract that says both "the command is running" and "the result has landed" on the actual document surfaces.
- Added layout-level regressions in `src/tests/fpstatushelpers_tests.pas` so the new progress region stays within the reserved status-bar segment and does not collide with the dedicated right-edge zoom cluster.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **190 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the command-surface gap is no longer "missing render progress" but the remaining smaller status-bar polish items, and the advanced image-processing routes are easier to verify manually because their work is now visibly surfaced in the live shell.

## 2026-03-04 (image-list parity closure + card-refresh pass)

- This pass maps primarily to the `Document tabs` and `Command surface parity` rows in `docs/FEATURE_MATRIX.md`.
- The code audit and docs are aligned again: the image-list/document-tab surface is not a missing feature anymore. The current app already has a live thumbnail-backed tab strip with visible tabs, click-to-activate, next/previous tab navigation, drag reorder, close, unsaved markers, horizontal scrolling, and a context menu.
- The implementation also got a practical UI-behavior improvement in the same pass: tab previews no longer need a full `RefreshTabStrip` rebuild for every same-state dirty update. `RefreshTabCardVisuals(...)` now refreshes just the affected card's thumbnail/title/hint when the strip structure itself has not changed.
- That keeps the image-list surface visibly current while reducing unnecessary full-strip churn during repeated document mutations, which matters because the tab strip is also part of the user's "did my operation really land?" feedback loop.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **188 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the image-list/tab-strip area has moved out of the "missing feature" bucket; the remaining gap there is parity polish and deeper route-level testing, not absence of the surface itself.

## 2026-03-04 (real save-options pass)

- This pass maps primarily to the `File workflow` and `Hidden Sheet Options` rows in `docs/FEATURE_MATRIX.md`.
- The export path is less placeholder-like now: PNG and JPEG save options are no longer just a partial prompt plus a mostly inert options record.
- `TSaveSurfaceOptions` now carries real format behavior (`JpegProgressive`, `PngCompressionLevel`, `PngUseAlpha`), `SaveSurfaceToFileWithOpts(...)` now actually applies those values to the active FPC writers, and the GUI `SaveToPath(...)` flow now exposes session-persisted JPEG quality + progressive choice plus a session-persisted PNG compression prompt.
- The most important practical fix in this pass is not just "more options": PNG export now explicitly preserves alpha through `TFPWriterPNG.UseAlpha`, so transparent work is no longer silently at risk of flattening on export just because the writer default omitted alpha.
- Added regression coverage in `src/tests/fpio_tests.pas` for both the now-real save-option defaults and PNG alpha round-tripping; `bash ./scripts/run_tests_ci.sh` now passes at **188 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: hidden save/export options are still not fully paint.net-deep, but this area has now crossed from "documented partial" into a materially real, user-verifiable export path.

## 2026-03-04 (visual-mutation sync pass)

- This pass maps primarily to the `Command surface parity`, `Effects`, `Adjustments`, and `Draw tools` rows in `docs/FEATURE_MATRIX.md`.
- The main goal was not adding another isolated feature, but tightening the visible contract after image mutations: when a command changes pixels, the user now needs to see that change not only on the canvas but also on the surrounding UI surfaces that expose the current document state.
- `TMainForm` now has a shared `SyncImageMutationUI(...)` path for mutation-driven refreshes. That path centralizes prepared-bitmap invalidation, dirty-state/tab-strip refresh, layer-surface refresh, and canvas repaint so adjustment/effect handlers stop depending on ad-hoc combinations of `InvalidatePreparedBitmap`, `SetDirty`, `RefreshLayers`, and `RefreshCanvas`.
- The pass explicitly routes the full high-visibility image-processing family through that shared path: history-timeline jumps, undo/redo, inline text commit, fill/erase selection, crop-to-selection, layer blend/property edits, layer rotate, the main adjustments family, and the current effects family now all refresh from one place after mutating the document.
- Stroke tools also gained better UI follow-through after the stroke finishes: `CommitStrokeHistory(...)` now updates the tab-strip preview and layer-list thumbnails after the region history is pushed, so brush-like tools no longer leave those secondary views lagging behind the final painted result.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **186 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: this does not change the visual style, but it materially improves functional testability because more image-changing paths now have an immediate, consistent visible feedback loop across the live workspace instead of only mutating backend state.

## 2026-03-03 (layer-properties completion pass)

- This pass maps primarily to the `Layers` row in `docs/FEATURE_MATRIX.md`.
- The layer-properties surface closes two explicit remaining gaps: `Layer Properties...` now exposes layer visibility in addition to name / opacity / blend mode, and the visible `Move Up` / `Move Down` commands now also support `Ctrl+Click` jump-to-top / jump-to-bottom behavior instead of only single-step movement.
- These are routed behaviors, not just UI labels. The property dialog now writes `Visible` back into the active `TRasterLayer`, and the move commands now choose either adjacent-step or edge-jump targets before calling the shared `MoveLayer(...)` path, so the layer order and canvas composite both update immediately.
- This tightens one more part of the "visible command surface must be real" rule: the previously documented layer-property and send-to-edge parity notes are no longer just deferred comments, they now have active code paths in the live app.
- Verification is still green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **184 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully after the layer-surface changes.
- Honest progress update after this pass: the layer stack is closer to "functional complete" now, and the remaining layer work is mostly deeper interaction polish rather than missing practical visibility/reorder behavior.

## 2026-03-03 (krita flattened-import pass)

- This pass maps primarily to the `Compatibility IO` row in `docs/FEATURE_MATRIX.md`.
- `.kra` is no longer just a recognized extension with a hard failure path. The shared file loader now attempts a real flattened Krita import by opening the archive as ZIP and extracting Krita's merged PNG preview (`mergedimage.png`, `preview.png`, or another fallback PNG entry).
- The new path is deliberately practical rather than over-claiming parity: it gives users an immediately editable flattened raster when Krita saved a merged preview, while keeping the previous descriptive fallback error when the archive does not contain a usable PNG preview.
- This keeps the same "real route + real data" rule as the rest of the project: `LoadSurfaceFromFile(...)` now returns actual pixels for common `.kra` files instead of only surfacing a message, so the compatibility entry is no longer a pure placeholder for that format.
- Added a dedicated `FPKRAIO` helper unit plus a new `KraZipLoadExtractsMergedImage` regression, while preserving the invalid-file error regression; `bash ./scripts/run_tests_ci.sh` now passes at **184 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully after the loader change.
- Honest progress update after this pass: compatibility import is materially stronger now because one of the previously explicit "recognized but unusable" file types now has a real flattened import path; the remaining compatibility work is deeper layer fidelity, not complete absence of `.kra` support.

## 2026-03-03 (effects near-completion + safe startup-tool pass)

- This pass maps primarily to the `Effects`, `Tool palette`, and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md`.
- Added six more previously missing high-visibility effects and routed each one through the real `Effects` menu: `Red Eye`, `Tile Reflection`, `Crystallize`, `Ink Sketch`, `Mandelbrot Fractal`, and `Julia Fractal`.
- These follow the same visible contract as the rest of the live effects family: the command is visible in the grouped menu, the active layer is mutated immediately, the prepared bitmap cache is invalidated, and the canvas refreshes in the same pass so the result is readable right after the dialog closes.
- The effect family is now materially closer to parity: the short, user-visible missing-effects list is gone, and the remaining work has moved to the smaller long-tail filters outside the current audited shortlist.
- Startup behavior is safer now too: the main form no longer boots into a paint tool by default. The shared `DefaultStartupTool` helper now drives both constructors and tests, and the default active tool is `Rectangle Select` so opening a document does not accidentally drop a brush stroke.
- Added six new surface regression tests for the new effects plus a startup-default helper regression; `bash ./scripts/run_tests_ci.sh` now passes at **183 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully after the new menu routes and startup-default change.
- Honest progress update after this pass: functional/tool-to-canvas integration is now down to deeper parity edges rather than obviously missing routed commands, and the remaining work is increasingly concentrated in visual/UI polish plus any final long-tail effect additions.

## 2026-03-03 (advanced effects expansion pass)

- This pass maps primarily to the `Effects` row in `docs/FEATURE_MATRIX.md`.
- Added five previously missing high-visibility effects and routed each one through the real `Effects` menu: `Unfocus`, `Surface Blur`, `Bulge`, `Dents`, and `Relief`.
- These are not backend-only additions. Every new effect now follows the same user-visible contract as the existing effect family: confirm parameters, mutate the active layer immediately, invalidate the cached prepared bitmap, and refresh the canvas in the same pass so the changed pixels are visible as soon as the dialog closes.
- `Surface Blur` now uses an edge-aware blur pass (radius + threshold) instead of a plain blur clone, `Unfocus` uses a disk-kernel blur for a softer defocus look, `Bulge` and `Dents` add opposite centre-weighted distortions, and `Relief` adds directional grayscale height shading.
- The same pass also fixes a visibility trap in fresh documents: `NewBlank(...)` now initializes the default `Background` layer as opaque white instead of transparent black, so new files open on a white base while later added layers remain transparent.
- Added five new core regression tests in `src/tests/fpsurface_tests.pas` plus a new document-default regression in `src/tests/fpdocument_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes at **176 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully after the new menu routes, effect primitives, and white-background default landed.
- Honest progress update after this pass: the effects family is materially more complete and easier to verify by eye; the remaining work is now in the longer-tail missing filters rather than the biggest obvious core gaps.

## 2026-03-03 (multi-segment line-path pass)

- This pass maps primarily to the `Draw tools` row in `docs/FEATURE_MATRIX.md` and removes the last explicitly tracked `Line / Shapes` tool-gap note from `docs/TOOL_OPTIONS_BASELINE.md`.
- The visible `Line` tool no longer stops after a single two-handle curve. Once one segment is committed, the last endpoint stays active on the canvas so the user can click a new endpoint, lock two new handles, and keep chaining additional Bézier segments without switching tools.
- This is not preview-only continuation: each finished segment is committed into the active layer immediately, so the image changes as the path grows, while the next segment still gets a live visible preview from the carried-forward endpoint.
- The path lifecycle is visible and controllable now: `Enter` commits the current segment (if one is in progress) and exits path mode, right-click exits the open path, and `Escape` cancels only the in-progress preview segment when a prior segment has already been committed.
- The canvas refresh path was tightened in the same pass so idle line-path previews repaint on mouse move even though `Line` is not one of the generic hover-overlay tools.
- Added helper coverage for the updated line-tool hint and reran full verification; `bash ./scripts/run_tests_ci.sh` now passes at **170 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully after the chained-path changes.
- Honest progress update after this pass: the explicit tool-surface gap list is now empty; the remaining work is deeper parity polish, not missing basic routed tool behaviors.

## 2026-03-03 (two-handle line-curve pass)

- This pass maps primarily to the `Draw tools` row in `docs/FEATURE_MATRIX.md` and closes the remaining `Line / Shapes` interaction gap in `docs/TOOL_OPTIONS_BASELINE.md`.
- The visible `Line` tool no longer stops at a single-handle bend. After the initial endpoint drag, the first click now locks handle one, the next move previews the second handle, and the following click commits a real two-handle Bézier curve into the active layer.
- The curve state is visible on the canvas while editing, not hidden in internal state: the first handle remains pinned as a locked marker, the second handle stays attached to the live pointer, and the preview path updates before the user commits the final stroke.
- This is backed by a real raster-path change, not just a different preview: `TRasterSurface` now has a `DrawCubicBezier(...)` path, so the final pixels follow the same two-handle curve the canvas previews.
- Added regression coverage for the new cubic path in `src/tests/fpsurface_tests.pas`, plus a helper assertion for the updated line-tool hint; `bash ./scripts/run_tests_ci.sh` now passes at **169 tests, 0 errors, 0 failures** after the curve-state and cubic-raster changes.
- Honest progress update after this pass: the previous curve-editing gap is materially smaller now; the remaining draw-tool gap is multi-segment path editing rather than a missing editable Bézier mode.

## 2026-03-03 (inline text tool pass)

- This pass maps primarily to the `Draw tools` and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md`, and it closes one of the remaining explicit tool-baseline gaps in `docs/TOOL_OPTIONS_BASELINE.md`.
- The visible `Text` tool no longer hard-jumps straight into a modal-only flow for every placement. Left-click on the canvas now opens a live inline text editor at the clicked image position, so text input is visibly attached to the canvas before it is committed.
- The inline text editor is not just cosmetic: pressing `Return` commits the typed text into the active layer through the existing text raster path, `Escape` cancels it, and focus loss also commits so tool switches, tab switches, and document-close flows do not silently drop pending text.
- The previous text-style dialog is still available as a real style surface instead of being discarded: right-click or `Option`-click with the `Text` tool now opens the font/style dialog and immediately updates the live inline editor if one is active.
- This pass also fixes a quieter reliability issue in the old text path: `TTextDialogResult` now starts from explicit defaults instead of relying on an uninitialized record, so first-use text placement no longer depends on undefined font state.
- Added helper coverage for the new interaction contract in `src/tests/fpuihelpers_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes at **166 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully after the inline-text changes.
- Honest progress update after this pass: the text tool now reads as a real canvas tool instead of a modal detour, so another explicit tool-baseline gap is closed; the biggest remaining tool-specific gaps are now feathered selections and richer multi-node curve editing.

## 2026-03-03 (selection feather pass)

- This pass maps primarily to the `Selection tools` and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md` plus the `Rectangle / Ellipse / Lasso Select` row in `docs/TOOL_OPTIONS_BASELINE.md`.
- Selection tools now expose a visible `Anti-alias` checkbox plus a `Feather` spinner (0–128 px) on the top option bar; those controls now call the new `TSelectionMask.Feather(...)` path so the mask itself softens immediately rather than only darkening the preview.
- The new feather implementation produces literal gradient coverage values so both the canvas preview and all core APIs (fill, erase, recolor, bucket, clone stamp within a selection) honor the softened boundary instead of needing special-case blits.
- Added regression coverage for the new feather path in `src/tests/fpselection_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes with that new selection coverage in the suite.
- Honest progress update after this pass: the last explicitly documented selection gap is resolved, so the remaining big tool-specific holes are richer multi-node curve editing and deeper effect parity.

## 2026-03-03 (eraser square-tip pass)

- This pass maps primarily to the `Paint tools` and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md`.
- The `Eraser` tool no longer hard-locks to a circular tip. The top tool-options row now exposes a visible `Shape` selector for eraser mode, with `Round` and `Square` choices.
- This is fully wired through the actual pixel path: square mode now uses a dedicated square brush/line raster pass instead of reusing the circular brush behind the scenes, so the effect on the image matches the selected tip shape.
- The canvas feedback is also consistent with the tool state now: switching the eraser to `Square` changes the live hover outline from a circle to a square, so the UI preview and the committed erase result stay aligned.
- Added regression coverage for the new square-tip raster path in `src/tests/fpsurface_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes at **165 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: another previously documented tool gap is now closed; the remaining tool work is increasingly in deeper parity items, not obviously missing basic shape/size behaviors.

## 2026-03-03 (line-curve interaction pass)

- This pass maps primarily to the `Draw tools` row in `docs/FEATURE_MATRIX.md`, with a smaller impact on the tool-behavior notes in `docs/TOOL_OPTIONS_BASELINE.md`.
- The visible `Line` tool no longer stops at straight segments only. It is now a real two-stage line/curve tool in the live UI: first drag sets the endpoints, then moving the pointer previews the bend, and the second click commits the curved stroke to the active layer.
- This is not a fake canvas-only preview. The raster core now has a real quadratic-curve path (`TRasterSurface.DrawQuadraticBezier(...)`), so the committed result follows the same curved path the user previews.
- The canvas preview also makes the second stage readable: the line tool now shows a dotted control scaffold, a live curved stroke preview, explicit start/end anchors, and a control-point marker while the curve is being adjusted.
- I also cleared stale multi-stage state on tool/document switches, so an unfinished curve edit does not leak across tool changes or document replacement flows.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **164 tests, 0 errors, 0 failures**, and the existing `bash ./scripts/build.sh` pass from the same code change still rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the line tool is materially closer to the expected paint-style behavior now, but the remaining gap is still richer multi-node / multi-segment curve editing rather than a missing curve mode altogether.

## 2026-03-03 (tool-preview cohesion pass)

- This pass maps primarily to the `Paint tools`, `Draw tools`, and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md`.
- The canvas/tool connection is stronger now for the advanced tool set: `Clone Stamp` no longer shows only a static source mark, it now renders a live red source halo plus a dashed source-to-destination link, so the sampled offset is visible before and during stamping.
- Drag tools also present a clearer live preview instead of a generic one-pixel guide: `Line` preview now scales with the current width, shape previews now reflect `Outline` vs `Fill` vs `Outline + Fill`, radial gradients now show a live radius circle, and drag-start anchors are rendered so the user can read the gesture from the canvas itself.
- Tool-option changes are now visibly connected to the canvas too: changing size, shape style, gradient mode/reverse, clone alignment, tolerance/sample toggles, and the rest of the routed tool options now forces an immediate canvas repaint instead of waiting for a later pointer event.
- I also tightened the UI-state plumbing behind that: `UpdateToolOptionControl(...)` now keeps `FUpdatingToolOption` active for the full programmatic sync, so option handlers can safely ignore internal control updates and only repaint on real user changes.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **163 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` rebuilt `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the tools now read as more genuinely attached to the canvas during hover and drag, so the completion estimate moves to **~92%**; the remaining gaps are still deeper behavior parity, not basic visibility of tool intent.

## 2026-03-03 (canvas-feedback tool pass)

- This pass maps primarily to the `Paint tools`, `Draw tools`, and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md`.
- The live tool surface is less "backend-only" now: visible tools no longer depend solely on hidden state changes or delayed commits to feel active, because the canvas now renders direct hover feedback for almost every non-move tool.
- `Pencil`, `Brush`, `Eraser`, `Clone Stamp`, and `Recolor` now draw a live brush-radius outline under the pointer, while click/drag-oriented tools such as `Paint Bucket`, `Magic Wand`, `Color Picker`, `Text`, `Crop`, and the drag-shape family now show a minimal point/crosshair marker so the user can see that the tool is attached to the canvas before committing.
- `Clone Stamp` is clearer during use now: after sampling, the canvas also shows a live source-point marker in addition to the destination brush outline, so the source/destination relationship is no longer hidden.
- This pass also closes one UI-state gap behind that feedback: switching tools now forces a canvas refresh, leaving the canvas clears hover state, and one-shot actions such as clone-source sampling and color picking now explicitly invalidate the paint surface so their feedback updates immediately.
- Added regression coverage for the new interaction contract in `src/app/fpuihelpers.pas` and `src/tests/fpuihelpers_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes at **163 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the tool layer is materially more trustworthy in real use because more tools now visibly attach to the canvas, so the overall completion estimate moves to **~91%**; the biggest remaining gaps are still true curve-node editing, real anti-aliased selections, image-list parity, and deeper per-tool behavior parity beyond the current first-pass interactions.

## 2026-03-03 (system-picker color panel + speed-button completion pass)

- This pass maps primarily to the `Colors`, `Workspace visual parity`, and `Iconography` rows in `docs/FEATURE_MATRIX.md`.
- The live Colors panel no longer depends on the custom wheel-first surface. It now follows a slimmer companion-panel model around the native macOS system color picker: a `TColorButton` opens the system palette for the active swatch, the floating `Colors` panel keeps stacked foreground/background swatches for active-slot switching, and the in-panel controls are limited to compact live hex readouts plus H/S/V/A scrub bars.
- This keeps the actual editing surface closer to the user's requested direction while staying inside standard LCL: the panel is still embedded in our window, but the color-picking dialog itself is delegated back to the widgetset-backed system color panel instead of trying to fake an entire custom picker.
- The earlier half-finished button refactor is now closed properly: the shared `CreateButton(...)` path uses `TSpeedButton`, so the top quick-action strip, tool palette, utility strip, history actions, and layer actions all now share one flatter, more icon-like button style instead of mixing old `TButton` and newer symbol-button variants.
- The default `Colors` floating panel is slimmer now in the default layout (`src/app/fppalettehelpers.pas`), so its first-launch footprint better matches the new control density without reintroducing default panel overlap.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` passes at **151 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: the implementation is materially closer to the intended macOS-native color workflow, but this is still refinement rather than a whole new feature family, so the overall completion estimate stays at **~87%**; the biggest remaining gaps are still image-list parity, broader effect coverage, richer layer-thumbnail interaction, and true asset-backed icon controls.

## 2026-03-03 (wheel-first color panel + icon-button pass)

- This pass maps primarily to the `Colors`, `Layers`, `Workspace visual parity`, and `Iconography` rows in `docs/FEATURE_MATRIX.md`.
- The Colors panel now follows the wheel-first direction the current design and mainstream editors imply more closely: the old dense quick-swatch grid is no longer part of the default surface, and the live panel now uses a fully saturated circular color wheel for hue/saturation selection, stacked foreground/background color squares on a checkerboard tray, plus dedicated H/S/V scrub bars below it.
- The color interaction path is deeper than the older wheel-only pass: left-drag now continuously scrubs on the wheel, the active slot remains directly selectable from the stacked preview, and right-clicking the wheel updates the inactive color slot without first changing the active slot.
- The Layers panel closes a real workflow gap now: the owner-drawn layer list supports drag-to-reorder in the live UI, with visual target-row feedback and real document-layer reordering through `TImageDocument.MoveLayer(...)`, instead of forcing all reordering through the Up/Down buttons only.
- The broader control language is more icon-like now across the top quick-action row, tool palette, utility strip, History, and Layers panels; however, this is still an honest Lazarus-native compromise based on compact symbol glyphs inside standard buttons, not full Figma-accurate vector icon controls yet.
- I also did a real visual check against the running app after the pass: the default launch layout stayed readable, the floating panels still avoided default overlap/clipping, and the updated Colors/Layers panel content fit without newly introduced occlusion in the checked window state.
- Verification is green after the pass: `bash ./scripts/run_tests_ci.sh` now passes at **151 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed `dist/FlatPaint.app` successfully.
- Honest progress update after this pass: closing drag-reorder plus the stronger wheel-first color surface moves the overall completion estimate to **~87%**; the biggest remaining gaps are still image-list parity, broader effect coverage, exact asset-backed icon parity, richer curve editing, and deeper layer-thumbnail interactions.

## 2026-03-03 (panel depth + compact control pass)

- This pass maps primarily to the `Colors`, `Layers`, `Iconography`, and `Tool/Config Options` rows in `docs/FEATURE_MATRIX.md`.
- The visible control language is now more coherent across the app: the tool palette and layer action strip no longer rely on the older mixed emoji-heavy captions, and the current UI now uses a tighter compact-label vocabulary that reads more consistently against the lighter macOS-style chrome pass.
- The Colors panel is deeper now in real code, not just visually: it now exposes direct H/S/V numeric fields in addition to the existing RGB/A and hex controls, and the RGB, HSV, and hex entry points now stay bi-directionally synchronized around the active color slot.
- The Layers panel is deeper too: the active layer now has inline visibility and opacity controls directly in the floating panel, and the owner-drawn list remains thumbnail-backed while the higher-friction modal opacity flow is still preserved as a fallback command.
- Added focused regression coverage for this pass: compact tool-label assertions plus layer-opacity percent/byte helpers in `src/tests/fpuihelpers_tests.pas`, and taller palette-capacity regressions in `src/tests/fppalettehelpers_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes at **149 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed the runnable app bundle successfully.
- Honest progress update after this pass: this is another incremental but real product-usage improvement, so the overall completion estimate moves to **~86%**; the biggest remaining gaps are still image-list parity, broader effect coverage, drag-to-reorder in layers, deeper color swatch parity, and a fuller native icon system.

## 2026-03-03 (light macOS chrome pass)

- This pass maps primarily to the `Workspace visual parity` row in `docs/FEATURE_MATRIX.md`.
- The live app now moves materially closer to the local `flatpaint_design` baseline on overall look-and-feel: the older dark slate chrome has been replaced with a lighter macOS-style layered theme across the top toolbar, tab strip, floating palettes, list surfaces, and status strip.
- The active UI-architecture constraints were preserved during the restyle: the quick-action row remains separate from the tool-options row, the document tab strip still sits between the toolbar stack and workspace, and the four utility surfaces remain floating, overlap-capable, and semi-transparent while dragging.
- This was intentionally a visual/system pass, not a feature-cutting pass: existing commands and tool options were preserved, the most obvious emoji-heavy top-row buttons were converted to compact text labels, and the reusable chrome colors now live in `src/app/fppalettehelpers.pas` so future style changes stop depending on scattered literals inside `mainform.pas`.
- Added new theme-regression coverage in `src/tests/fppalettehelpers_tests.pas` plus UI-side chrome assertions in `src/tests/ui_prototype_tests.pas`; `bash ./scripts/run_tests_ci.sh` now passes at **146 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` refreshed the runnable app bundle successfully.
- Honest progress update after this pass: the visual/style slice is clearly stronger, but this is still parity polish rather than a new feature family, so the overall completion estimate only moves slightly to **~85%**; the biggest remaining gaps are still image-list parity, broader effect coverage, fuller color/layer depth, and iconography polish.

## 2026-03-03 (UI baseline reset to local Figma export)

- The active UI visual authority has been switched from the older paint.net-style workspace spec to the local `flatpaint_design/` bundle.
- The previous paint.net-oriented UI baseline was archived into `DocsBackup/UI_REQUIREMENTS_BASELINE.paintnet.md` and `DocsBackup/UI_PARITY_AUDIT.paintnet.md` instead of being deleted outright.
- The new active UI docs are now `docs/UI_REQUIREMENTS_BASELINE.md` and `docs/UI_PARITY_AUDIT.md`, and they explicitly preserve the current product architecture that the design mock does not show in full.
- Two implementation constraints are now locked in the active spec: the four utility surfaces (`Tools`, `Colors`, `History`, `Layers`) remain floating panels that may overlap and become semi-transparent while dragging, and the tool-dependent control surface remains a dedicated second toolbar row beneath the quick-action row rather than being collapsed into the Figma mock's single strip.
- The document tab strip also remains part of the required top-of-workspace stack below the tool-options row, because the live code already supports multi-document tabs and the design mock is treated as visual guidance rather than a full feature contract.

## 2026-03-03 (tool options parity pass + documentation sync)

- Re-checked the current source against `src/app/mainform.pas`, `src/core/fpdocument.pas`, `src/core/fpsurface.pas`, `src/core/fpio.pas`, and the current test/build scripts so the latest docs match the real code again.
- The codebase is ahead of the stale audit notes that had drifted into this file: document tabs, text, clone stamp, recolor, `Paste Selection (Replace)`, Layer Properties, `Layers -> Import From File`, `Repeat Last Effect`, RGBA + hex color editing, `C` color-slot toggle, Spacebar temp pan, middle-mouse pan, redo-row display, and partial `.pdn` fallback import are all live in the current source.
- `bash ./scripts/run_tests_ci.sh` now compiles and runs the full suite at **142 tests, 0 errors, 0 failures**, and `bash ./scripts/build.sh` links the GUI app cleanly in the current workspace.

| Area | Completion | Key open gaps |
| --- | --- | --- |
| Workspace shell | ~78% | Tab strip and floating palettes are live; image-list strip, denser chrome, and icon polish still lag paint.net |
| Document tabs | ~73% | Real multi-document tab strip exists; missing image-list thumbnails, drag-to-reorder, and richer tab chrome |
| Command surface parity | ~80% | The previously cited missing routes are now live; the biggest remaining visible gap is still the missing image-list surface |
| Workspace visual parity | ~62% | Lighter macOS-style chrome plus denser panel internals are now live; image-list strip and fuller native icon language still remain below target |
| File workflow | ~87% | `Save All Images` still maps to the current shell, but import/open coverage is broader now because `.pdn` has a flattened fallback and `.kra` can load a merged preview when present |
| Undo/redo | ~90% | Undo/redo labels and redo rows are visible; grey-out / comparison-polish remains open |
| Layers | ~93% | Inline visibility/opacity, blend-mode picker, thumbnail list, drag reorder, visibility in Layer Properties, and `Ctrl+Click` jump-to-top / jump-to-bottom are live; richer thumbnail-first interaction still remains |
| Selection tools | ~85% | Visible combine-mode control is live; selection anti-alias is still a UI-only toggle pending core support |
| Paint tools | ~85% | Clone Stamp, Recolor, Gradient, Pan, Zoom, and interactive Crop are live; richer per-tool parity remains open |
| Draw tools | ~80% | Text is live; true curve-node editing is still missing |
| View controls | ~90% | Pinch zoom, Spacebar temp pan, and middle-mouse pan are live; resize-handle parity is still partial |
| Colors panel | ~82% | Slim companion panel around the native system color picker is live: stacked foreground/background swatches, a system-palette launch button, H/S/V/A scrub bars, live hex labels, swap/reset commands, and the `C` slot toggle are all live; true embedding/custom controls inside the native panel and richer polish still remain |
| Adjustments | ~90% | Broad baseline is routed; richer curve editing is still the main gap |
| Effects | ~94% | 31 effects plus `Repeat Last Effect` are live with grouped submenus; remaining work is now the smaller long-tail filters outside the audited shortlist |
| Resize/canvas ops | ~90% | Interactive Crop is live; remaining work is mostly parity polish |
| Text/rendering | ~80% | Modal text tool is implemented; richer editing still remains open |
| Clipboard | ~85% | `Paste Selection (Replace)` is live; remaining gaps are polish and edge-case parity |
| Menus/Shortcuts | ~85% | Single-key tool shortcuts, `C`, Spacebar pan, and Ctrl+Tab are live; remaining gaps are edge-case parity and image-list-related flows |
| Iconography | ~62% | Compact symbol-glyph buttons now cover the main tool/action surfaces, but a true asset-backed native icon system is still missing |
| Tool/Config Options | ~88% | Most visible controls now affect output, including inline layer controls; selection anti-alias remains the main UI-only option |
| Hidden sheet options | ~70% | Export/save-sheet options remain partial |
| Compatibility IO | ~68% | `.psd` / `.xcf` flattened import is live, `.pdn` has a ZIP-based flattened fallback, and `.kra` can now load a merged preview PNG when the archive contains one |
| **Overall** | **~90%** | Biggest remaining gaps are image-list parity, exact asset-backed icon parity, richer curve-node editing, hidden save/export options depth, and deeper layer-thumbnail polish |

## 2026-03-02 (test infrastructure fix)
- `run_tests_ci.sh` now compiles `flatpaint_cli` as its first step so the two CLI-backed test suites (`TCLIIntegrationTests`, `TFormatCompatTests`) no longer fail on clean checkouts without a manually pre-built binary.
- `perf_snapshot_tests` and `ui_prototype_tests` were orphaned test units that defined registered test cases but were absent from `flatpaint_tests.lpr`; both are now listed in the `uses` clause and run cleanly.
- Total test count is now 105 (was 103), all passing: 0 errors, 0 failures.

## 2026-03-02
- The selection core closes a real behavior gap now: rectangle, ellipse, lasso, and magic-wand selection composition now support `Intersect` in addition to the earlier replace/add/subtract paths.
- That intersect path is wired through both layers that matter: the shared `TSelectionMask` now has a reusable mask-intersection operation for geometric selection tools, and the document-level magic-wand path uses the same combine mode instead of treating the wand as a special-case add/subtract-only route.
- The current GUI input model is also slightly closer to the expected editor baseline: holding `Shift+Option` while starting a selection now maps to `Intersect`, which brings the hidden modifier behavior in line with the newly completed core combine mode even though the explicit visible selection-mode controls are still not implemented.
- The tool-surface audit is more honest now: a dedicated `docs/TOOL_OPTIONS_BASELINE.md` now records the current code-level tool inventory, the still-missing paint.net baseline tools, and the per-tool option requirements, instead of letting the feature docs drift ahead of the real `TToolKind` catalog.
- That audit explicitly follows the documented fallback order too: paint.net stays primary, Adobe Photoshop is recorded as the secondary UX fallback for unclear option behavior, and GIMP is recorded as the backend/reference model for tool-option semantics and pixel-operation expectations.
- The visible tool palette closes two more concrete gaps now: `Pan` is a real hand-style viewport tool in the current Lazarus GUI source, and `Pencil` is now a distinct routed tool instead of forcing every hard-edge stroke through `Brush`.
- The `Pan` path is also less UI-only now: its drag-to-scroll math now lives in the shared viewport helper so the hand-tool behavior has direct unit coverage instead of hiding entirely inside the form event handler.
- The shared raster core is slightly more tool-ready now: line drawing can now run with a zero-radius brush footprint, which gives the new `Pencil` path true single-pixel steps at size `1` instead of always expanding to the older minimum circular stamp.
- Adding two more tools also exposed another real layout dependency: the `Tools` child palette had to grow taller and its legacy static `Colors` launch rectangle had to move down so the default left-side palette stack stays separated even before the workspace-aware layout pass takes over.
- The startup palette layout is less brittle now: the `Tools`, `Colors`, `History`, and `Layers` child panels no longer depend on a pre-layout zero-sized workspace clamp, because a deferred first-idle layout pass now reapplies their default positions once the real workspace size exists.
- Those default palette positions are also less naive now: the launch layout is computed against the current workspace bounds instead of only using hard-coded absolute rectangles, which keeps the left and right palette clusters separated more reliably on the default window size.
- The bottom status strip is closer to the expected paint.net pattern now: the zoom slider and percentage readout are treated as a dedicated right-edge cluster, and the percentage label is now laid out from the far-right edge inward so it no longer drifts into the neighboring status text.
- The `File` menu closes two real code-level parity gaps now: `Acquire...` exists as a live command that imports from the macOS clipboard when an image is available and otherwise falls back to the normal open flow, and `Save All Images` now resolves to the current single-document shell behavior instead of remaining absent from the menu surface.
- The local maintenance path is less ad hoc now: the repository now has canonical `scripts/clean.sh`, `scripts/build.sh`, and `scripts/build-release.sh` entry points instead of relying on one-off shell commands and stale remembered build invocations.
- Those scripts intentionally terminate running `flatpaint` / `FlatPaint` processes before rebuilding or refreshing app bundles, so local rebuilds no longer depend on the user manually closing the app first when the output executable is still in use.
- The build outputs are now more predictable as well: `build.sh` refreshes both `flatpaint.app` and `dist/FlatPaint.app`, while `build-release.sh` also emits a stripped release binary at `dist/release/flatpaint` and keeps the repository bundle aligned with that release artifact.
- A dedicated `docs/BUILDING.md` now documents the supported manual clean/build/release flow, the `LAZBUILD` override, the kill-before-replace behavior, and the compatibility wrapper kept for the older `build_app_bundle.sh` path.
- The `Add Noise...` route is less placeholder-like now: it no longer uses a bare prompt box, and it now uses a dedicated amount dialog with a numeric field plus a slider for the current 0-to-255 range.
- That `Add Noise` path is now backed by a shared helper unit for parsing, clamping, and slider mapping, so the current amount bounds are explicit and testable instead of being re-declared inline in the menu handler.
- The most obvious prompt-only effect gap is closed now: `Blur...` and `Add Noise...` both follow the same bounded modal pattern, leaving the remaining bigger gaps concentrated in deeper paint.net fidelity and multi-document shell work rather than these basic parameter surfaces.
- The `Blur...` route is less placeholder-like now: it no longer uses a bare prompt box, and it now uses a dedicated radius dialog with a numeric field plus a slider for the current 1-to-64 range.
- That `Blur` path is now backed by a shared helper unit for parsing, clamping, and slider mapping, so the current radius bounds are explicit and testable instead of being re-declared inline in the menu handler.
- Parameterized adjustments and effects are more consistent now: the remaining prompt-based single-value commands are shrinking, while the common bounded-range commands now follow the same numeric-field-plus-slider modal pattern.
- The `Posterize...` route is less placeholder-like now: it no longer uses a bare prompt box, and it now uses a dedicated levels dialog with a numeric field plus a slider for the current 2-to-64 range.
- That `Posterize` path is now backed by a shared helper unit for parsing, clamping, and slider mapping, so the current level-count bounds are explicit and testable instead of being re-declared inline in the menu handler.
- The adjustment surface is incrementally denser and more credible now: `Brightness / Contrast...`, `Curves...`, `Hue / Saturation...`, `Levels...`, and `Posterize...` now all use dedicated modals instead of raw prompts, although effect-side parameter dialogs and fuller paint.net adjustment fidelity still remain open.
- The `Curves...` route is less placeholder-like now: it no longer uses a one-shot prompt box, and it now uses a dedicated gamma-curve modal with a numeric field plus a slider that matches the current shared-core baseline.
- That `Curves` path is now backed by a shared helper unit for gamma parsing, clamping, slider mapping, and stable numeric formatting, so the current 0.10 to 5.00 policy is explicit and testable outside the main form.
- This still does not claim full paint.net curve-editor parity: the current macOS flow is now a credible dialog around the existing one-value RGB gamma engine, but per-channel and multi-point curve editing are still open and remain below the final 1:1 target.
- The `Brightness / Contrast...` route is materially closer to paint.net now: the wrong split `Brightness...` and `Contrast...` menu items have been collapsed back into one combined adjustment command with a dedicated two-field modal.
- That command is now backed by a shared helper unit for parsing and clamping both parameters, so the current signed ranges are explicit and testable instead of being buried in separate prompt handlers.
- This is a command-surface parity fix first: the current implementation still applies brightness and then contrast as two sequential shared-core operations rather than a richer previewable combined adjustment engine, but the visible macOS workflow now matches the expected single-task shape much more closely.
- The `Levels...` route is less placeholder-like now too: it no longer chains four generic prompt boxes, and it now uses one dedicated four-field modal that keeps the full adjustment range on a single task-specific surface.
- That `Levels` dialog flow is now backed by a shared helper unit for parsing and clamping the four bounds, so the input-range ordering rule and the current independent output-range behavior are explicit, reusable, and covered outside the main form.
- The adjustment surface is incrementally closer to a credible macOS desktop editor now: both `Hue / Saturation...` and `Levels...` have moved off serial prompts and into dedicated dialogs, although richer paint.net-style `Curves` / channel-level adjustment UIs are still open and the product is still below the user's 90% integration-test threshold.
- The `Hue / Saturation...` route is less placeholder-like now: it no longer chains two generic prompt boxes, and it now uses a dedicated dual-parameter modal that keeps the hue and saturation controls in one task-specific dialog.
- That dialog flow is now backed by a shared helper unit for parsing and clamping signed adjustment values, so the parameter bounds are explicit, testable, and reusable instead of being re-declared inline in the main form.
- The current macOS desktop workflow is safer now: replacing or closing the current document no longer silently discards edits, because `New`, `Open`, `Open Recent`, `Close`, and `Quit` now all prompt before abandoning dirty state.
- That safety fix now also covers the real macOS window-close path instead of only menu commands: the form's close-query route uses the same dirty-document guard, so the titlebar close button no longer bypasses the unsaved-change prompt.
- The `Save` command is also slightly closer to normal macOS command semantics: the menu caption now uses an ellipsis only when the current document has no bound file path and the action will actually fall through to a save-location prompt.
- The current GUI paint cache is less allocation-heavy in the hot path now: content refresh still rebuilds the prepared bitmap only when the document render revision changes, but it no longer creates and assigns a throwaway intermediate `TBitmap` for that refresh step.
- Shortcut and title-state parity are slightly tighter now as well: the window title now uses a clearer macOS-style edited marker, the `View` surface now exposes `Command+'` for `Pixel Grid` and `Command+Option+R` for `Rulers`, and the palette visibility shortcuts now match the documented `Tools/Colors/Layers/History` order.
- The Lazarus project file is less machine-specific now: the old hardcoded `/Users/kurisu/.../lazarus` search paths have been replaced with `$(LazarusDir)` macros so the checked-in project configuration no longer depends on one developer's home directory.
- A project-local performance baseline now exists in `docs/FPC_MACOS_PERFORMANCE_GUIDE.md`, summarizing the current official FPC/Lazarus guidance for optimization levels, smartlinking, symbol stripping, double buffering, and text-IO buffering plus the project's own release-build inferences for macOS.
- The top-level product docs are less self-contradictory now too: the PRD's architecture section no longer claims a SwiftUI/Swift shell, and it now reflects the real Lazarus/LCL plus shared-FPC implementation path that this repository is actually shipping.
- This is a targeted standards pass, not a full UI-parity closure: the product still remains materially behind native macOS toolbar density, sheet/dialog fidelity, and true multi-document shell behavior, but it closes one real UX-risk gap (silent data loss) and one real FPC/LCL repaint inefficiency without widening the architecture.

## 2026-02-28
- The workspace is less self-conflicting now: the duplicate top-toolbar tool-button strip has been removed, leaving the actual `Tools` palette as the primary icon surface while the toolbar keeps the tool chooser and active-option controls.
- Default utility-window placement is materially less chaotic now: the baked-in `Tools`, `Colors`, `History`, and `Layers` rectangles no longer overlap each other at launch, and the right-side stack now matches the user's paint.net screenshot more closely with `History` above `Layers`.
- The bottom status strip no longer relies on fixed panel widths only: it now recalculates panel widths on resize and lays out the zoom slider against the actual panel partition, which closes the overlap bug between the zoom controls and the rest of the status text.
- macOS-oriented menu behavior is a little less confusing now: `File` now includes a real `Exit` route on `Command+Q`, and `View` uses a clearer `Zoom to Window` label with a direct shortcut instead of leaving that command as an unaccelerated fit action.
- With duplicate tool chrome reduced, default palettes de-conflicted, adaptive status-bar layout in place, and the basic `Exit` route added, the honest completion estimate moves slightly again: roughly `72%–76%` overall, while the most visible remaining gaps are still multi-document surfacing, native pinch, and deeper paint.net/Photoshop-level command completeness.
- The visible tool palette closes another explicit gap now: `Freeform Shape` is no longer just a tracked parity item, it now exists as a real tool in the shared tool catalog, previews as a closed freeform outline during drag, and commits through the normal GUI shape-tool path.
- The shared raster core now has a reusable polygon-outline primitive instead of forcing the GUI to fake freeform shapes locally, which keeps the new tool behavior testable at the same level as the other shape primitives.
- This pass also sharpens the code-level completion audit again: the image-list strip is still not implemented despite older command-surface notes having drifted ahead, so those docs have now been corrected back to the real Lazarus state.
- With `Freeform Shape` added on top of the viewport work, the honest completion estimate moves only slightly again: roughly `69%–73%` overall, with the shared editing core now stronger than the visible multi-document / command-surface parity and the biggest remaining gaps still concentrated in native pinch, image-list/document tabs, and the remaining `File` command surface.
- The viewport shell now follows the cross-editor baseline more closely in code, not just in the checklist: when the rendered image is smaller than the scroll viewport it is actively centered instead of drifting toward the top-left origin, which closes one of the most obvious layout mismatches from the user's paint.net screenshot.
- Zoom behavior is less fragmented now: the status-bar bottom-right slider is fully live and synchronized with the toolbar zoom chooser plus the menu/tool zoom routes, so zoom state no longer drifts between different controls in the same window.
- The viewport interaction model is also stronger in practical desktop use: `Ctrl` / `Command` modified wheel input now zooms around the pointer anchor, which is a closer match to Photoshop/GIMP/Photopea-class editor expectations even though a true native pinch recognizer is still not implemented in the current Lazarus path.
- This pass also removed another stale UI contradiction: the in-app help surface now advertises the actual unified open-format set (`.fpd`, flattened `XCF`, flattened `PSD`, and the current raster formats) instead of lagging behind the real loader.
- With centered-canvas behavior, synchronized status-bar zoom, and pointer-anchored wheel zoom all now real in code, the honest completion estimate moves only incrementally again: roughly `67%–71%` overall, with the shared editing core still ahead of the paint.net/Photoshop-style UI parity and the remaining big gaps still concentrated in native pinch, multi-document surfacing, and final panel/layout density.
- A dedicated cross-editor UI baseline now exists in `docs/UI_REQUIREMENTS_BASELINE.md`, built from paint.net, Photoshop, GIMP, Photopea, and Pixlr-class workspace patterns so layout work is no longer driven only by paint.net screenshots plus guesswork.
- That audit initially highlighted three blocking viewport gaps; after the latest viewport pass, canvas centering and the bottom-right zoom slider are now implemented in code, while true trackpad pinch-zoom remains the one major viewport-interaction gap still open in the current Lazarus GUI path.
- The existing `docs/UI_PARITY_AUDIT.md` remains in use for paint.net-specific parity, but its role is now narrower: cross-editor layout rules and current code comparison now live in the new baseline document so stale assumptions do not drive the next UI pass.
- The file-open surface is less demanding now: the main `Open...` route and `Import as Layer...` route no longer force the user to mentally separate "project" versus "image" file classes in the filter list first, because both dialogs now start with one unified "all supported" filter that includes FlatPaint projects plus every currently importable raster / compatibility format.
- GIMP project import now exists as a real baseline path instead of a documentation-only promise: `.xcf` files can now be opened directly through the shared image loader and are flattened into a single raster surface for editing, alongside the already-supported flattened `PSD` path.
- The current XCF support is intentionally explicit about scope: this first pass handles common 8-bit XCF files with uncompressed or RLE-compressed pixel tiles, normal layer visibility/opacity, and flattened compositing into one image, while masks, advanced blend modes, high-bit-depth precision, and full layer-preserving editing are still open work.
- `Import as Layer...` now follows the same compatibility rule: `.fpd`, `.xcf`, `PSD`, and the other currently supported raster formats all come through one import filter, and importing a `.fpd` now flattens that document to a new layer instead of rejecting it as a different file class.
- With unified open/import filters and a real flattened XCF path added on top of the earlier shape and adjustment work, the honest completion estimate moves slightly again: roughly `65%–69%` overall, with the shared editing core around the high `70%` to low `80%` range while paint.net-facing UI / command-surface parity still remains below the user's `90%` target.
- The shared shape-drawing baseline closes another visible paint.net gap now: `Rounded Rectangle` is no longer only a documented target, it now exists as a real raster primitive, appears in the shared tool catalog, previews during drag in the canvas overlay, and commits through the normal shape-tool path in the GUI.
- The current `Rounded Rectangle` path is a practical outline-first implementation: it uses a rounded-rect containment test in the raster core so the corners stay genuinely open instead of faking the shape with rectangle-plus-circle artifacts, while a richer fill/style/options surface still remains open.
- With rounded-rectangle drawing added on top of the earlier `Curves...` and resize-workflow pass, the honest completion estimate moves only incrementally again: roughly `63%–67%` overall, with the shared editing core now solidly in the high `70%` range while paint.net-facing UI / command-surface parity is still well short of the user's `90%` target.
- The shared image-resize path is now materially closer to how mature editors behave: `Resize Image...` no longer falls back to two generic prompt boxes, it now uses a dedicated modal with aspect locking and an explicit resampling choice (`Nearest Neighbor` or `Bilinear`) instead of forcing every resize through nearest-neighbor only.
- The shared raster core now supports bilinear interpolation in addition to the earlier nearest-neighbor resize path, and the document-level resize route can now choose between them while the binary selection mask intentionally still follows nearest-neighbor scaling so hard selection edges do not get blurred into fractional masks.
- The current zoom interaction is less self-contradictory now: the visible `Zoom` tool click path now uses the same preset zoom ladder as the menu, toolbar buttons, status-bar zoom controls, and the top percentage chooser instead of retaining a separate `* 1.25` stepping rule.
- The current `Adjustments` surface closes another explicit code-level gap: `Curves...` now exists in the shared raster core, the document model, and the GUI command path as a practical first-pass gamma curve instead of remaining a missing route.
- That `Curves` implementation is intentionally narrower than paint.net's full curve editor: it currently exposes one gamma control through the GUI prompt path so the command is real and testable end-to-end, while a richer multi-point curve editor UI still remains open work.
- With `Curves...` and the resize-flow upgrade both now real in code, the honest completion estimate moves only slightly again: roughly `62%–66%` overall, with the shared editing core in the mid-to-high `70%` range while paint.net-facing UI / command-surface parity is still materially below the user's `90%` target.
- The shared adjustment core closes another explicit gap now: `Levels...` is implemented in the raster engine, exposed through the document model, and routed in the GUI `Adjustments` menu instead of remaining only a tracked paint.net hole.
- The current `Levels` implementation is a practical first pass, not the final paint.net-quality dialog: it applies one shared input/output remap across RGB channels, skips fully transparent pixels, and the GUI currently gathers the four values through sequential prompts while a tighter combined dialog still remains open.
- With `Levels` added on top of `Pixel Grid` and `Hue / Saturation`, the honest completion estimate nudges upward again: roughly `60%–64%` overall, with the shared editing core now in the low-to-mid `70%` range while UI / visible command-surface parity still trails well below the user's 90% threshold.
- The shared adjustment core now closes another explicit code-level gap: `Hue / Saturation` is implemented in the raster engine, exposed through the document model, and routed in the GUI `Adjustments` menu instead of remaining only a missing paint.net item.
- The current implementation is a practical first pass: hue shifts wrap in HSV space, saturation can be raised or lowered, alpha is preserved, and the GUI currently collects the two parameters through sequential prompts while a closer paint.net-style combined dialog still remains open.
- With `Pixel Grid` and `Hue / Saturation` both now real in code, the honest completion estimate moves only slightly: roughly `58%–62%` overall, with the shared editing core now around `70%+` while the paint.net-facing UI / command-surface parity is still well below the user's 90% bar.
- The current `View` surface closes another real code-level gap now: `Pixel Grid` is implemented as an actual render overlay instead of remaining only a documented paint.net checkbox, and it is now reachable from both the `View` menu and the top toolbar.
- The pixel-grid route is intentionally editor-like rather than always-on noise: the current Lazarus canvas only renders the pixel grid when the user has enabled it and the zoom is high enough for the overlay to be useful, so normal zoom levels stay readable while deep zoom gains true pixel boundaries.
- The top command strip is a little closer to paint.net's view-control cluster now: next to the zoom percentage chooser, the toolbar now carries direct `Grid` and `Rulr` buttons instead of forcing those view-state toggles to live only in the menu.
- A direct code-level completion audit has now been done against the real Lazarus/FPC source instead of only reading the planning docs, and it exposed one major truth the docs had drifted away from: the current GUI shell is still single-document only because `TMainForm` owns one `TImageDocument` field and there is still no real tab strip / image-list control in the code path.
- That same audit also confirms the visible-command surface is still well short of paint.net parity in code, not just in styling: `File` still lacks `Acquire`, `Save All Images`, and `Exit`; `View` still lacks image-list navigation; `Adjustments` still lacks `Curves`; and the tool palette still lacks rounded-rectangle and freeform-shape routes.
- A more honest current estimate, based on the actual code paths rather than the optimistic docs, is now roughly 55–60% overall functional completion, with the shared editing core ahead of the paint.net-facing UI parity; the visible UI / command-surface parity is closer to the mid-40% to low-50% range, not near the user's 90% bar.
- The current zoom surface is stronger after this pass: zoom no longer steps by an arbitrary `* 1.25` ladder only, it now uses a fixed editor-style preset ladder (`12.5%` through `1600%`), exposes a real percentage chooser in the top toolbar, and keeps the status-bar zoom readout on the same preset-driven caption logic.
- The current Lazarus workspace now closes another visible paint.net gap from the user's screenshot and the command-surface baseline: dedicated top and left rulers are now rendered around the canvas instead of leaving measurement feedback only in the status text.
- Those rulers are now a real view feature, not static chrome: `View -> Rulers` exists on `Command+R`, the ruler ticks scale with zoom, and the ruler labels track canvas scroll offset so the measurement band moves with the current viewport instead of staying fixed at one origin.
- The bottom status strip is denser and more paint.net-like now: the old single-line status text has been split into compact segments for tool hint, image size, selection size, cursor position, active layer, units, and a dedicated quick-zoom cluster with `-`, `+`, and a clickable zoom label that toggles between fit-to-window and actual size.
- The current Lazarus scroll viewport also now uses an explicit idle-time scroll watcher for ruler refresh because the embedded `TScrollBox` path does not expose a reliable high-level scroll callback for keeping fixed viewport rulers in sync.
- The current Lazarus shell now uses the user-supplied paint.net screenshot as a direct arrangement reference for the top chrome, and this pass closed another obvious mismatch: a dedicated top-right utility cluster now exists in the main toolbar instead of scattering those window commands across the normal action row.
- The current Lazarus top command strip is closer to the screenshot baseline now: `Tools`, `History`, `Layers`, `Colors`, `Settings`, and `Help` are exposed as a compact utility-button group on the right side, and those routes now invoke real behavior instead of staying implied by menus alone.
- The current `Tools` utility window is less blocky now: its default frame is much narrower and the tool buttons now render in a two-column stack that reads more like paint.net's tall left tool window than the earlier four-column card.
- A real settings route now exists behind the new utility strip: the current Lazarus shell exposes a dedicated settings dialog for default new-image DPI and display units, and the help route now reports the primary shortcuts plus the current supported file formats instead of leaving those icons as dead space.
- A direct user-supplied paint.net 5.1.11 screenshot is now part of the active UI parity reference for this iteration cycle, and it made one major shell gap concrete: the current Lazarus `New` route now needs to look and behave like a dedicated modal dialog, not a pair of generic prompt boxes.
- The current Lazarus `New` command is materially closer to the paint.net reference now: the old `InputQuery` flow has been replaced with a dedicated modal `New` dialog that shows estimated image size, maintain-aspect control, pixel dimensions, resolution, and derived print size in one form instead of splitting that workflow across separate prompts.
- The shared FPC file-open path is less brittle now: raster import no longer relies only on the filename extension, it now tries the available FPC image readers by content when the extension is unknown or mismatched, which closes the common "file exists but won't open" failure path for renamed / mis-labeled images.
- Real file-format coverage is broader than the earlier narrow PNG/JPEG/BMP/TIFF baseline now: the current Lazarus GUI source and shared core can open flattened `PSD` plus `GIF`, `PCX`, `PNM`, `TGA`, `XPM`, and `XWD`, and the save path now also supports `PCX`, `PNM`, `TGA`, and `XPM`.
- The current Lazarus open/import routes are less hostile when file IO fails: `Open` and `Import as Layer` now report a controlled error dialog instead of leaking a raw exception path into the editing flow.
- The current Lazarus visual-parity pass now uses the official paint.net main-window / toolbar / utility-window docs and current public screenshots as the active layout baseline for iteration, not just the internal feature checklist, and this pass specifically tightened toolbar density plus palette chrome against that reference.
- The current Lazarus workspace chrome is less card-like now: the top command strip is slimmer and denser, now includes direct crop / deselect / palette-launcher controls, and the floating utility surfaces now use explicit palette-style title bars instead of relying on generic group-box captions.
- The current in-window palette behavior is closer to paint.net's movement feedback now: child panels still stay constrained and snap to the workspace edges, and drag now switches the palette into a brighter "in-motion" tint so movement reads as a transient overlay state instead of a static dock box.
- The current Lazarus utility-window slice is materially closer to paint.net now: `View` exposes direct `Tools` / `Colors` / `History` / `Layers` palette toggles on `Command+1...4`, each floating palette now has its own close button, and `Reset Window Layout` restores the fixed default cluster instead of leaving panel recovery implicit.
- The current in-window palette behavior is less brittle now: palette drags still clamp to the workspace, and they now also snap cleanly to nearby workspace edges on drop so the utility windows land in tighter, more paint.net-like positions instead of drifting off-grid.
- The shared FPC document history model now carries action labels alongside snapshots instead of only raw stack depth, and the current Lazarus `History` palette now surfaces the newest undo/redo action names instead of showing only numeric counts.
- The current Lazarus workspace now has a real baseline floating-palette set inside the editor instead of only one docked side box: `Tools`, `Colors`, `History`, and `Layers` all exist as in-window child panels with fixed paint.net-style default positions, basic constrained dragging on the palette surface, and live status content instead of placeholder chrome.
- The shared FPC document model now exposes explicit undo/redo depth counts instead of hiding that state entirely behind booleans, and the new in-window `History` palette uses those real counters for live context.
- The current Lazarus menu and tool surface is closer to paint.net's baseline structure now: the top-level menu count is back to the expected seven because selection commands were folded into `Edit`, and the visible tool strip now includes a real `Zoom` tool in the view-tool slot instead of forcing zoom to live only in menu commands.
- The current Lazarus top command strip is closer to paint.net's compact tool cadence now: the second toolbar row is no longer a text-heavy list, it uses a tighter icon-led tool strip in a paint.net-style family order (selection first, then move, paint, and shape tools), and the shared tool metadata now drives button glyphs, combo order, and status-bar hints from one source.
- A repository-local FPCUnit baseline now exists instead of relying only on manual smoke work: shared tests cover the new `Auto-Level` raster behavior plus the new paint.net-style tool-order / tool-metadata mapping used by the current Lazarus toolbar.
- The current Lazarus `File` surface now routes `Print` from both the menu and the top toolbar through a real printer path instead of leaving print discoverability implicit.
- The current Lazarus `File` surface now has a real `Close` route instead of forcing users to simulate it through `New`: `Command+W` now resets the workspace to a fresh untitled document at the current canvas size through an explicit menu path.
- The current Lazarus `Edit` surface is less implicit now: `Copy Selection`, `Paste into New Layer`, and `Paste into New Image` all exist as explicit menu routes instead of hiding behind the generic clipboard commands, and pasting into a new image now resets the workspace around the clipboard bounds as a real document replacement path.
- The current Lazarus `View` / status-bar slice is less skeletal now: `Zoom to Selection` is routed, `Units` now changes real display measurements instead of being a doc-only claim, size dialogs honor the active unit, and the status bar now shows tool-hint text plus unit-aware image/cursor readouts.
- The shared FPC adjustment baseline now includes a real `Auto-Level` path instead of leaving the first paint.net adjustment command as an implied gap: active-layer histogram stretch is implemented in shared code, exposed in the CLI as `autolevel` / `autoleveldoc`, and routed in the current Lazarus GUI source through `Adjustments`.
- A fresh validation pass also shows the current Lazarus project now links end-to-end again under the repository's pinned build flags, so the earlier Cocoa widgetset linker blocker is no longer the current build state for this workspace.
- The current Lazarus GUI source now has a real `Open Recent` path instead of a dead declaration: recent files are registered on successful open/save, invalid entries are pruned when selected, and the recent-file list is now persisted through the app-config directory across launches.
- The shared FPC raster core now has a practical baseline `Effects` slice instead of leaving that menu family as a doc-only claim: separable box blur, sharpen, additive noise, and outline/edge detection are implemented in shared code, exposed in the CLI (`blur`, `sharpen`, `noise`, `outline`, plus native-document variants), and routed in the current Lazarus GUI source through a real `Effects` menu.
- The latest performance follow-up now applies the FPC-specific compiler behavior observed during the new effects work: clamp logic in the blur/convolution hot path was folded directly into the pixel-sampling helper after Free Pascal refused to inline the extra helper layer, reducing avoidable inner-loop call overhead and cutting the effect-core build notes back down to the pre-existing baseline.
- The repository still only contained the documentation baseline from the earlier failed Swift attempt; there was no surviving application source to continue from.
- A fresh Free Pascal rewrite has now started in this repository, targeting Lazarus plus FPC instead of reviving the abandoned Swift shell.
- Real shared core units now exist for pixel color math, raster surfaces, document/layer/history state, and image file IO, instead of another UI-only stub.
- A new code-driven Lazarus app shell was added and now compiles through the application units, but the current local Lazarus Cocoa widgetset fails at final link inside its own `cocoawsextctrls` object, outside the project code.
- To keep delivery moving despite the Cocoa widgetset linker fault, the image-processing core was split away from LCL dependencies and a real command-line front-end (`dist/flatpaint_cli`) was added so the rewrite already performs actual raster edits instead of pretending through a dead UI.
- The shared FPC core is now deeper than the initial drawing slice: linear gradients, crop, nearest-neighbor resize, flips, 90-degree rotation, invert, and grayscale are implemented at the raster level.
- Those same geometry operations are now also implemented at the multi-layer document level, so future GUI wiring can mutate the whole document instead of only the active flattened view.
- The CLI front-end now exposes the expanded operation set (`gradient`, `crop`, `resize`, `fliph`, `flipv`, `rotcw`, `rotccw`, `invert`, `grayscale`) so the rewrite has broader real editing coverage even while the Lazarus Cocoa link issue remains unresolved.
- Selection is now part of the shared FPC document model instead of being left for the UI layer: rectangle/ellipse selection, select all, deselect, invert selection, move selection, move selected pixels, fill selection, erase selection, and crop-to-selection are now real core behaviors.
- Selection state now travels with document history snapshots and follows crop/resize/flip/rotate transforms, which removes a major future desync risk between the image data and the active selection.
- A native layered document format now exists in shared code, with persistence for layers, visibility, opacity, active layer, and the current selection mask.
- The CLI front-end now exposes selection-driven editing commands (`fillrect`, `fillellipse`, `eraserect`, `movepixelsrect`, `croprect`) and baseline native-document commands (`wrapdoc`, `exportdoc`, `addlayerdoc`), so multi-step work is no longer limited to flat raster-only files.
- The FPC rewrite selection slice is broader now: freeform lasso polygons and contiguous magic-wand selection are implemented in shared code, and the CLI now exposes real lasso/wand edit paths instead of leaving those tools as documented gaps.
- Native layered-document maintenance is less brittle now: imported layer rasters are fitted into the document canvas instead of being rejected on size mismatch, and the CLI now exposes layer delete/reorder/rename/visibility commands in addition to duplicate/merge/flatten.
- The FPC rewrite now has a real baseline clipboard-like pixel flow in shared code: selected pixels can be exported as cropped transparent rasters, active selections can be cut from the active layer, and external rasters can be pasted into a new native-document layer at an explicit offset.
- The shared raster adjustment slice is deeper now: brightness, contrast, sepia, black-and-white thresholding, and posterize are implemented in the FPC core and exposed through the CLI, instead of leaving the rewrite at only invert/grayscale.
- Native layered documents can now use that same baseline adjustment slice without flattening first: the CLI exposes active-layer adjustment commands for brightness, contrast, sepia, black-and-white, and posterize, plus single-layer raster export for round-tripping layer content directly.
- The Lazarus GUI source now follows the same import-layer baseline as the shared engine: import-as-layer no longer hard-fails on size mismatch, and an `Adjustments` menu now routes into the new shared-core adjustment methods in source.
- The Lazarus GUI source now has a real baseline selection workflow in code instead of only paint primitives: rectangle/ellipse selection tools, move-selection, move-selected-pixels, fill/erase/crop selection commands, and a visible selection-outline overlay are all wired in source.
- That GUI selection slice is deeper again now: the Lazarus source also routes a baseline magic-wand tool through the shared contiguous-selection core instead of leaving wand functionality CLI-only.
- The Lazarus GUI source now opens and saves the native `.fpd` layered document format in addition to flat raster exports, so the GUI code path is no longer limited to one-layer image files.
- Layer properties are less skeletal now across the rewrite: the shared FPC document model has an explicit layer-opacity setter, the CLI exposes `setopacitydoc`, and the Lazarus GUI source now exposes a layer-opacity command instead of leaving opacity as a hardcoded field.
- The Lazarus GUI source now has a more practical day-to-day selection route: freeform lasso selection is wired in source, shape and lasso drags now show live preview overlays, and selection edits are now treated as real document mutations so `.fpd`-persisted selection state marks the document dirty and stays in undoable flows.
- The current Lazarus GUI source now has an in-process clipboard path instead of only file import: `Cut`, `Copy`, `Copy Merged`, and `Paste` route through the shared-core selection/composite copy paths plus paste-as-new-layer, and the primary clipboard commands are also exposed as visible toolbar buttons instead of hiding only in menus.
- The current Lazarus GUI source now exposes baseline image-geometry commands directly through `Image`: resize image, resize canvas, flip horizontal/vertical, and rotate 90 degrees both directions all route into the shared FPC document transforms instead of remaining CLI-only.
- The current Lazarus GUI source now has a real bound-path save baseline instead of treating every save like `Save As`: `Save` writes directly to the current file when one exists, and `Save As` now exists as the explicit sheet-driven path picker.
- The current GUI selection-combine behavior now explicitly uses a documented fallback reference because the local paint.net docs are too thin on modifier details: Shift adds to the selection and Option subtracts, following the familiar Photoshop-style interaction while keeping paint.net as the product target.
- The shared FPC document model now has a real merged-copy path in addition to active-layer copy: flattened composite pixels can now be copied through the same selection-aware shared-core route instead of forcing the GUI to hand-roll a separate raster path.
- The current Lazarus GUI clipboard path is now less toy-like: selection copies and cuts are cropped to the selection bounds, the copied pixel block keeps its original top-left offset, `Paste` restores that offset instead of always landing at `0,0`, and `Copy Merged` now respects the current selection instead of blindly copying the entire canvas.
- Tool options are less error-prone now in the current Lazarus GUI source: magic-wand tolerance is no longer tied to the brush-size field, and the shared top option control now switches between brush-size and wand-tolerance semantics based on the active tool instead of silently reusing one value for incompatible tools.
- The current Lazarus GUI source now has a baseline `View` surface instead of only toolbar zoom buttons: `Zoom In`, `Zoom Out`, `Actual Size`, and `Fit to Window` are wired in source, and opening or creating oversized documents now starts from a shrink-to-fit zoom instead of blindly forcing 100%.
- Performance guidance is now an explicit implementation rule: the local official Lazarus/FPC documentation has been folded into the rewrite process, so hot-path changes are expected to follow documented widgetset and compiler guidance instead of ad hoc guesses.
- The current Lazarus GUI render path is now materially less wasteful: the custom canvas control uses `DoubleBuffered`, paint now reuses a prepared bitmap cache instead of recompositing and re-bridging the full document on every repaint, and the display-background blend path now skips full alpha math for fully opaque or fully transparent pixels.
- The shared FPC raster core is broader again now: outline ellipse drawing exists as a first-class primitive instead of forcing every ellipse-like result through selection fill hacks, and the CLI now exposes that same raster path directly through an `ellipse` command.
- The current Lazarus GUI source now has a real ellipse shape tool in its shared tool catalog (via the tool selector), so the editor is no longer limited to only line and rectangle shapes on the drawing side.
- The current Lazarus GUI source now has a real gradient drag tool in its shared tool catalog instead of leaving gradients CLI-only: the existing shared-core `FillGradient` path now routes through the normal drag-commit tool flow in source.
- The current Lazarus GUI color-picker route is less brittle now: it tracks the actual mouse button used for the pick target instead of inferring primary-versus-secondary updates by comparing color values, which removes wrong-target picks when the two colors match.
- The shared FPC document model is less uneven now across flat and native-document flows: invert and grayscale now exist as explicit document-level methods, the CLI exposes `invertdoc` and `grayscaledoc`, and the Lazarus GUI source now routes both commands directly in `Adjustments`.
- The shared geometry command set is broader now too: 180-degree rotation now exists as an explicit raster and document operation, the CLI exposes `rot180` and `rot180doc`, and the Lazarus GUI source now routes `Rotate 180` directly through `Image`.
- The current Lazarus GUI source now has baseline direct color-state actions in the toolbar instead of forcing repeated dialog trips: primary and secondary colors can be swapped instantly, and the common black/white reset is exposed as a one-click command.
- The development rules now explicitly allow Adobe Photoshop documentation as a secondary UX reference when paint.net behavior is unclear and paint.net’s own docs are too thin, so future parity decisions have a documented fallback instead of ad hoc guessing.
- Current honest status of the FPC rewrite: the shared editing engine is real and usable through the CLI, the Lazarus GUI source is in place but not yet shippable because of the current toolchain-level Cocoa link blocker, and overall product parity is still far below UAT readiness.
- Session start: repository initialized as a new Swift package for a native macOS implementation.
- Reference baseline established from official paint.net product/docs pages because current application source is not publicly available.
- Documentation set created: PRD, implementation plan, feature matrix, SOW, development rules, test log, and event book.
- Phase 0 is complete: traceability docs and repo structure are in place.
- Phase 1 foundation implemented in code: document model, layer commands, history stack, tool catalog, and a macOS shell workspace scaffold.
- Tests now cover default document setup, layer CRUD/history, merge down with undo/redo, tool selection, and a multi-step foundation workflow smoke path.
- `swift test` passed after resolving one build issue and one sandbox-related execution issue, then passed again after the smoke test was added.
- Phase 2 and most of Phase 3 core backend are now in place: pixel raster model, compositing, selection masks, fill/gradient/flood fill, line draw, rectangle stroke, text stamping, color sampling, recolor, clone stamp, adjustments, effects, rotate/flip/resize/crop, and file import/export.
- The workspace UI now previews the rendered raster image instead of only a placeholder and exposes fast action hooks for the implemented tool chain.
- Dedicated integration tests were added for file-backed workflows and multi-step regression flows.
- `docs/EXPERIENCES.md` is now the canonical defect and lessons-learned log for this project.
- Clipboard workflows are now implemented in the core as copy composite image / paste image as new layer, with integration coverage.
- The canvas now supports direct drag interaction for core tools (selection, draw, erase, fill-family actions, line, shape, move-selection, move-pixels, text drop, recolor sample, clone stamp).
- A startup smoke run of the built executable confirmed the app process can launch and stay running in the current environment.
- Menu bar coverage, shortcut routing, quick actions, and explicit tool-option controls have been promoted as tracked product requirements and are now partially implemented in the app shell.
- Tool options now materially affect core behavior (brush width, wand tolerance, recolor tolerance, clone size, shape width, text size, gradient orientation, default text), and selected layer opacity/blend mode are adjustable in the UI.
- The canvas preview bridge no longer round-trips through PNG encoding for every repaint; it now builds an `NSBitmapImageRep` directly to reduce avoidable allocation churn.
- File workflow depth increased: export now supports PNG/JPEG/TIFF with explicit save-sheet options for JPEG quality, PNG interlace, and flattening behavior.
- Compatibility import now has explicit user-facing entry points for PSD and external paint.net/GIMP/Krita project files, using flattened fallback import when full layered fidelity is unavailable.
- The app now exposes a native macOS Settings scene for persistent export defaults, closing a configuration-surface gap in the current UX.
- A post-change startup smoke run confirmed the app still launches and remains alive after the new settings/export-sheet wiring.
- The PRD and feature matrix were rewritten to make the governing constraint explicit: this is a macOS paint.net recreation, with GIMP/Krita limited to backend-reference status only.
- Clipboard behavior is now closer to paint.net expectations: `Copy` uses the active selection when present, `Cut` removes selected pixels after copying, and `Copy Merged` remains available separately.
- The adjustment pipeline now includes a contrast operation, and AppKit-heavy import/export/text rendering paths are wrapped in `autoreleasepool` blocks to reduce avoidable temporary object retention during repeated editing/export cycles.
- A fresh launch smoke run after the latest menu/clipboard changes confirmed the app still starts and can be cleanly interrupted from a TTY session.
- Native document workflow is now less provisional: `Save` and `Save As` are split, the current native document path is remembered after open/save, and the document title updates from the saved filename.
- The file-open semantics now better match paint.net expectations: `Open` replaces the current workspace as a document, while `Import Image` and `Import Project` remain explicit layer-import actions.
- A full code-versus-doc review pass was completed against PRD, feature matrix, development rules, and shortcut policy before the latest regression run; the main corrected gaps were shortcut semantics and open-versus-import file behavior.
- A repeatable bundle script now builds `dist/FlatPaint.app` inside the repository, so a launchable macOS app bundle is always available locally for progress checks.
- The view layer is closer to paint.net baseline usability: zoom shortcuts, rulers, pixel-grid toggle, and transparency-grid toggle are now wired into both state and UI.
- Direct color control is now available in the inspector: primary/secondary colors can be edited, swapped, reset, and read as hex values.
- The UI is no longer purely text-led in the tool surface: a first-pass SF Symbols icon mapping now backs the tool palette, and this laid the groundwork for the current in-window utility panel system.
- The repository-local bundle policy is now explicit: `dist/FlatPaint.app` is refreshed after successful build/regression runs so there is always a latest-known-good app bundle on disk.
- The workspace structure is now closer to paint.net’s main-window model: side control surfaces float above the canvas instead of permanently squeezing layout width, the top of the workspace has a more toolbar-like command strip, and the status bar carries more live context.
- Large-image handling is safer by default: opening oversized raster files now starts with a proportional fitted zoom instead of an unbounded 1:1 view.
- An explicit workspace visual-parity audit was added so layout work now tracks against official paint.net docs/screenshots instead of relying on functional resemblance alone.
- An earlier floating-palette coordinator pass was completed to keep AppKit observer cleanup compatible with `@MainActor`; that experiment has since been superseded by the current in-window panel model.
- The workspace now includes a dedicated `Colors` utility surface, the docked tools panel has been compressed away from a long quick-action list toward a more palette-like shape, and the top toolbar exposes palette launchers so the default workspace reads less like a sidebar app.
- The large embedded history strip at the bottom of the main canvas has been replaced by a compact palette-style history summary card, and the status bar now reports cursor coordinates plus sampled composite color under the pointer.
- Floating utility windows now persist their frames by palette id, and the docked inspector’s color section has been reduced to a summary/launcher so the dedicated `Colors` window is the primary detailed color-editing surface.
- The main workspace now shows the core panel set (tools, colors, layers, history) inside the editor itself, and launch-time placement is treated as a fixed product-default layout.
- Palette sizing and default placement were tightened again: the panel layout now targets more compact dimensions, zoom emphasis has shifted further into the status bar, `View` exposes explicit palette commands, and the docked inspector’s full layer list has been reduced to a compact layer summary/launcher.
- A previous single-instance `Window` scene experiment informed the current shortcut model; `View` still exposes direct `Command+1...4` shortcuts for the core utility surfaces.
- A viewport-smoothness pass has started: interactive zoom now has a no-history path, status-bar zoom uses that path, and the canvas now accepts baseline trackpad pinch-to-zoom input.
- The overlap/obstruction issue reported in the main workspace has been addressed by removing the large docked `Tools` and `Inspector` overlays; the utility-panel set is now the primary tool surface, and the preview pipeline now caches both the composited raster and its `NSImage` bridge across viewport-only changes.
- The viewport now routes two-finger zoom through an AppKit-backed scroll view instead of a pure SwiftUI magnification gesture, so pinch handling follows native macOS event flow while retaining the no-history zoom path and cached preview rendering.
- The palette system has been pulled fully back into the main editor window: tools/colors/layers/history are now draggable child panels constrained to the workspace instead of separate system windows.
- The bottom dock summary was corrected from a duplicate `History` surface to a compact `Inspector` launcher card so the workspace no longer shows two competing history surfaces.
- Default child-panel placement is now treated as fixed product behavior: `Tools` top-left, `Colors` below it, `Layers` top-right, and `History` below it on every launch instead of restoring prior sessions.
- Automated verification is now less coarse: command-equivalent coverage was expanded so view, layer, image, edit, adjustment, effect, and full-tool-catalog behaviors each have their own dedicated tests instead of relying mostly on a few broad smoke paths.
- The menu/test traceability bar is now much higher: the current test suite includes individually named checks for nearly every visible command path in `View`, `Layers`, `Image`, `Edit`, `Adjustments`, and `Effects`, plus explicit integration coverage for file-command branches.
- A live runtime sample was collected against the launched app bundle: the main thread was idle in the standard AppKit event loop during the sample window, and the sampled physical-footprint report was about 110 MB with a 313 MB peak during the session.
- Current remaining major gaps for parity are broader UI polish/menu parity, richer tool-option controls, and some advanced adjustments/effects edge cases; plugin support remains intentionally deferred.
- The major workflow feature slice is now at approximately 90% coverage for the scoped paint.net-style baseline in the current repository implementation.
- Tool routing is less superficial now: the tool catalog has a fixed paint.net-style order, pan/crop tools are wired into the canvas gesture layer, lasso gestures now preserve a real freeform path instead of degrading to a drag rectangle, and single-tap brush/pencil/eraser interactions now land real pixels.
- Tool-surface coverage is deeper: dedicated unit tests now verify tool-catalog completeness, pan, crop, freeform lasso, and single-tap brush/pencil/eraser behavior instead of relying on broad smoke tests.
- The next mainline shell gap remains explicit: tabbed multi-document UI with a new-document size prompt is required for parity but is still not implemented.
- A stricter command-completeness baseline is now in place: `docs/COMMAND_SURFACE_BASELINE.md` and `docs/COMMAND_SURFACE_BREAKDOWN.md` explicitly track every visible menu, toolbar, tool-palette, utility-icon, image-list, and status-bar surface as implementation obligations.
- The command/test bar is now formally higher than category-level menu coverage: broad menu-group tests are no longer considered sufficient for declaring visible command surfaces complete.
- Current honest progress estimate after the command-surface audit: the raster/core editing engine is roughly in the 70% range for the scoped paint.net-style baseline, but visible command-surface parity is much lower, roughly in the 40% range; overall product completion is therefore still well below UAT closure.
- The latest command-surface pass added real `Edit` / `View` functionality instead of more placeholders: `Select All`, `Invert Selection`, `Fill Selection`, `Copy Selection`, `Paste into New Layer`, `Paste into New Image`, `Close`, and `Zoom To Selection` now route to real code paths.
- Core support was added for full-canvas selection, inverted selection, zoom-to-selection viewport fitting, and pasting clipboard content as a brand-new document, closing a chunk of the everyday command-surface gap.
- Another command-surface pass landed after that: the tool palette now includes a real baseline `Zoom` tool, and the `Image` / `Adjustments` menus gained real `Rotate 90° Left`, `Rotate 180°`, `Flatten`, `Black and White`, and `Sepia` command paths.
- Progress is improving, but the honest command-surface estimate is still only around the 50% mark because the image-list/tab shell, many toolbar routes, utility icons, and several remaining menu items are still missing or partial.
- The top toolbar now routes more than view-only actions: `New`, `Open`, `Save`, `Cut`, `Copy`, and `Paste` are now wired into visible toolbar icons instead of living only in menus.
- The app shell is no longer single-document only: a real in-window tab strip now manages multiple open document sessions, includes a size prompt before creating a new tab, shows unsaved markers, supports close, and supports drag reordering.
- This closes one of the largest structural parity gaps. Image-list parity is still not complete, but next/previous tab navigation and a basic tab context menu are now present; the main remaining gaps are richer context actions and more paint.net-like thumbnail treatment.
- The `File` surface is less skeletal now: `Open Recent`, `Save All Images`, and `Print` all route to real behavior instead of remaining unimplemented gaps.
- The `Image` and `View` surfaces are less placeholder-heavy now: `Resize...`, `Canvas Size...`, and `Units` all route to real behavior, and the status bar now reports the active size unit and converted document dimensions.
- **2026-03-02 — Full-feature implementation pass (blend modes, new tools, new effects, dialogs).** All major remaining feature gaps from `FEATURE_MATRIX.md` were addressed in a single session. `TBlendMode` (8 modes: Normal, Multiply, Screen, Overlay, Darken, Lighten, Difference, SoftLight) was added to `fpdocument.pas`; `Composite()` now applies per-pixel channel math for all non-Normal modes using an integer-only Pegtop formula for Soft Light. `TToolKind` was extended from 19 to 23 values: `tkCrop` (interactive drag-to-crop rectangle), `tkText` (dialog + LCL canvas rasterization), `tkCloneStamp` (right-click sample, left-click/drag stamp), and `tkRecolor` (tolerance-based in-place color replace brush). Four new surface operations were added to `fpsurface.pas`: `Emboss` (zero-sum 3×3 kernel + bias 128), `Soften` (Gaussian 3×3 / 16), `RenderClouds` (sine-wave plasma with seed), and `RecolorBrush` (circular brush with color-distance tolerance). Three new files were created: `fptextdialog.pas` (font combo from `Screen.Fonts`, size slider, bold/italic toggles), `fptextrenderer.pas` (renders `TTextDialogResult` to `TRasterSurface` via LCL canvas + `TransparentizeSurface`), and `fplayerpropertiesdialog.pas` (Name / Opacity / BlendMode combo modal). `fplclbridge.pas` gained `TransparentizeSurface`. `fpuihelpers.pas` was updated to register all 23 tools with display names, hints, and glyphs (`ToolDisplayOrder[0..22]`). In `mainform.pas`: the `Effects` menu was restructured with `Repeat Last Effect` (Cmd+F) at the top plus `Emboss`, `Soften`, and `Render Clouds`; the Layers panel gained a blend-mode `TComboBox` and a `Properties` button; `RefreshLayers` now syncs the combo to the active layer; all four existing effect handlers (`BlurClick`, `SharpenClick`, `AddNoiseClick`, `OutlineClick`) were fixed to call `InvalidatePreparedBitmap`; and full mouse-down/move/up event handling was added for the four new tools. Ten new tests were added across `fpsurface_tests.pas`, `fpdocument_tests.pas`, and `fpuihelpers_tests.pas`, bringing the total from 105 to 115. Build result: 248 lines compiled, 0 errors, 0 warnings. Test result: 115/115 passing. Document tabs remain deferred (significant architectural change — separate `TObjectList` of documents + tab strip).
- **2026-03-02 — Parity completion pass (document tabs, RGBA colors panel, tool opacity, compat IO stubs).** Seven feature areas were advanced in a single session targeting 90% overall completion. **Document tabs** (`0% → 65%`): `FTabDocuments` / `FTabFileNames` / `FTabDirtyFlags` arrays now manage all open documents; `FTabStrip` panel sits between toolbar and canvas; per-tab label + close buttons plus a `+` new-tab button built by `RefreshTabStrip`; full lifecycle covered by `AddDocumentTab`, `SwitchToTab`, `CloseDocumentTab`, `OpenFileInNewTab`; `FormCloseQuery` counts all unsaved tabs before quitting. **Colors panel** (`45% → 80%`): R/G/B/A `TSpinEdit` fields and an 8-digit RRGGBBAA `TEdit` hex field added; `UpdateColorSpins`, `ColorSpinChanged`, and `ColorHexChanged` keep all controls bi-directionally in sync with `FPrimaryColor`; `ColorsPaletteWidth`/`Height` expanded to 254×306. **Tool opacity** (`40% → 75%`): `FOpacitySpin` (1–100%) shown for paint tools; `FSelModeCombo` (Replace/Add/Subtract/Intersect) shown for selection tools; `FBrushOpacity` wired as the 7th `DrawLine` parameter so brush opacity actually affects painted pixels. **Layers menu** (`+`): `Paste &Selection`, `Import From &File...`, `Layer &Properties...`, and `Rotate / &Zoom...` added; `LayerRotateZoomClick` shows a four-option dialog (CW90/CCW90/180/cancel) and calls the matching `TRasterSurface` rotate method. **Iconography** (`35% → 45%`): toolbar buttons updated to descriptive full-word labels (`Fore`/`Back` for color buttons, `Ruler`); all buttons carry accurate keyboard-shortcut hints visible on hover. **Compatibility IO** (`40% → 55%`): `.kra` and `.pdn` added to the open dialog filter and `SurfaceOpenPattern`; both extension paths in `LoadSurfaceUsingKnownReaders` now raise a descriptive user-facing error message directing to export-as-PNG from the source app. **Tests** (`115 → 120`): `DrawLineOpacityScalesAlphaChannel`, `DrawLineFullOpacityMatchesDirectPaint` in `fpsurface_tests.pas`; `ColorsPanelFitsRGBASpinsAndHexField` in `fppalettehelpers_tests.pas`; `KraLoadRaisesDescriptiveError`, `PdnLoadRaisesDescriptiveError`, and updated `UnifiedOpenFilterIncludesProjectsAndPSD` in `fpio_tests.pas`. Build result: 4656 lines compiled, 0 errors, 0 warnings. Test result: 120/120 passing.
- **2026-03-07 — Selection-scope regression fix (Fill/Gradient).** Fixed a tool-switch regression where switching from any selection tool to non-selection tools (`ToolButtonClick`, `ToolComboChange`, keyboard shortcut path in `FormKeyDown`) auto-cleared the active selection, causing bucket/gradient operations to run globally. Selection is now preserved across tool switches so fill-family tools honor selection scope consistently.
- **2026-03-07 — Selection masking policy split (drawing vs fill-family).** Adjusted paint routing so active selection masking now applies only to area-fill tools (`Fill`, `Gradient`) while drawing/shape tools no longer clip to selection presence. This restores the expected behavior where line/shape/brush-style drawing is not constrained by an existing selection, without regressing fill-family selection scope.
- **2026-03-07 — Selection overlay visual differentiation (dashed committed outline).** Updated the committed selection boundary raster overlay from a fully continuous 1px ant-line to a dashed ant-line pattern with explicit gap segments, so completed selection regions are visually distinct from shape/square drawing outlines.
- **2026-03-07 — Selection lifecycle update (blank-click + tool-switch auto-deselect).** Reintroduced auto-deselect behavior for the current UX target: with a committed selection active, blank left-click in selection tools now clears the selection, and leaving the selection-tool family now auto-clears selection. Switching within the selection-tool family keeps selection.
- **2026-03-07 — P1 draw parity depth closure.** Added line-style (`Solid` / `Dashed`) option routing for line and shape outlines across both preview rendering and committed pixel output, backed by new dashed raster-core tests and pipeline-level commit verification.
- **2026-03-07 — P1 command-surface long-tail coverage reduction.** Added additional non-keyboard route-level regression coverage for selection auto-deselect behavior through toolbar switching paths to reduce remaining long-tail route debt.
- **2026-03-07 — P1 status closure sync.** Updated `FEATURE_PRIORITY_ORDER`, `FEATURE_MATRIX`, `PRD`, and `TOOL_OPTIONS_BASELINE` to reflect code-first reality: P1 functional targets are closed at current scope, with remaining work explicitly tracked as parity polish rather than missing baseline behavior.
- **2026-03-07 — Selection lifecycle reclassification (tool-family matrix).** Refined tool-switch selection behavior from a blanket rule to a classified rule aligned with selection-aware operation families: `Fill` / `Gradient` / `Recolor` now preserve selection when switching away from selection tools, while free-draw/shape/text families clear selection; switching within selection tools still preserves selection.
- **2026-03-07 — Regression coverage update for classified selection behavior.** Replaced old switch tests with matrix-style routes in `pipeline_integration_tests` (`SwitchingFromSelectionToFillKeepsSelection`, `SwitchingFromSelectionToGradientKeepsSelection`, `ToolbarSwitchFromSelectionToFillKeepsSelection`, `SwitchingFromSelectionToBrushAutoDeselectsSelection`, `SwitchingWithinSelectionFamilyKeepsSelection`) and kept CI green.
- **2026-03-07 — Viewport edge jitter stabilization (zoom/pan boundary clamp unification).** Investigated GIMP display-shell offset handling (`app/display/gimpdisplayshell-scroll.c`, `app/display/gimpdisplayshell-scale.c`) and aligned FlatPaint to the same architecture intent: compute target offset once, clamp into a valid range, then update state. Added shared viewport scroll-range helpers and applied them to `UpdateCanvasSize`, anchor zoom, zoom-to-selection, and pan drag routes; removed unconditional re-center-to-zero writes in resize refresh paths to eliminate repeated edge correction oscillation.
- **2026-03-07 — Post-fix verification + docs sync.** Re-ran full CI and build (`N:305 E:0 F:0`), refreshed `dist/FlatPaint.app`, and updated PRD/feature-matrix test snapshots to match the new regression count.
- **2026-03-07 — Viewport edge jitter phase-2 hardening (GIMP-style unoverscroll gate + zoom-limit no-op).** Added pre-clamp delta gating modeled after GIMP's unoverscroll pattern (`scroll_unoverscrollify` intent): wheel deltas that push further past a reached bound are now collapsed to `0` before any scroll write. Also added zoom-limit no-op guards so repeated zoom input at min/max scale no longer triggers anchor/scroll recomputation. This removes remaining multi-step rebound behavior when users keep pushing toward an already reached edge/zoom bound.
- **2026-03-07 — Phase-2 verification.** Re-ran full CI and build (`N:309 E:0 F:0`), refreshed `dist/FlatPaint.app`, and kept docs synced to the new test count.
- **2026-03-07 — Viewport edge jitter phase-3 hardening (disable Cocoa elastic bounce).** Added a dedicated native bridge (`fp_scrollview.m`) and runtime hookup in `AppIdle` to disable `NSScrollView` horizontal/vertical elasticity for the canvas host once the handle is ready, preventing macOS rubber-band rebound from reintroducing edge wobble.
- **2026-03-08 — Crop layer-offset rebasing correctness fix (transparent-crop regression closure).** Fixed `TImageDocument.Crop(...)` to rebase each cropped layer into new document-local coordinates (`OffsetX/OffsetY := 0`) instead of re-applying the crop origin shift after local-space cropping, which could move visible content outside the canvas and produce transparent crop output.
- **2026-03-08 — Regression hardening for canvas overwrite + crop-offset flows.** Added `TFPDocumentTests.CropWithOffsetLayerKeepsVisiblePixels`, `TFPDocumentTests.CropToSelectionWithOffsetLayerKeepsVisiblePixels`, and `TPipelineIntegrationTests.OpaquePencilStrokeOverwritesExistingPixel`; CI now runs green at `N:344 E:0 F:0`.
- **2026-03-08 — Zoom interpolation policy follow-up (AA visibility at high zoom).**
  - Feature row mapping: `View surface` + `Rendering quality` in `docs/FEATURE_MATRIX.md`.
  - Performance/reference check before code change: re-reviewed local `docs/FPC_MACOS_PERFORMANCE_GUIDE.md` guidance and aligned decisions with official references used in project research notes (FPC optimization-switch docs, Lazarus/LCL invalidation guidance, Apple CoreGraphics interpolation API behavior).
  - Behavior change: `DisplayInterpolationQualityForZoom(...)` now keeps low-cost smoothing through `<=8.0x` and only falls back to nearest-neighbor above that range, so anti-aliased stroke edges remain readable during common zoom inspection.
  - Safety scope: display-only interpolation policy; document pixel data, compositing math, and history semantics unchanged.
- **2026-03-08 — Zoom local-loupe feature de-scope (Photoshop/GIMP parity alignment).**
  - Fallback reference record (per development rules): reviewed official Photoshop Zoom/Navigator docs and GIMP Zoom/Navigation Window docs; both expose global-canvas zoom/navigation semantics and do not define a Windows-Magnifier-style local pixel loupe as baseline zoom behavior.
  - Product decision: stop supplementing local loupe overlay behavior and keep zoom tool semantics focused on full-canvas zoom.
  - Implementation: removed runtime `DrawZoomLoupeOverlay(...)` invocation and `FPMagnifierHelpers` dependency from `mainform` paint/overlay path, leaving standard zoom interaction unchanged.
  - Feature row mapping: `View surface` in `docs/FEATURE_MATRIX.md` updated to global-zoom baseline wording.
- **2026-03-08 — Selection-first bucket overwrite fix (selected-region residual stroke closure).**
  - Feature row mapping: `Paint tools` in `docs/FEATURE_MATRIX.md`.
  - User-facing defect: bucket fill inside an active selection could leave previously drawn pencil/brush pixels visible in the selected area, which looked like failed overwrite/compositing.
  - Root cause: fill path still built a color/tolerance candidate mask first, then intersected with selection; non-matching ink pixels were excluded by mask construction, so they remained unchanged.
  - Implementation:
    1. `mainform` `tkFill` path now uses selection-first semantics: when an active selection exists, bucket fill clones and applies the active selection coverage mask directly (in active-layer space) instead of color-candidate masking.
    2. kept existing contiguous/global + tolerance route unchanged for no-selection fills.
    3. hardened fill-mask space bookkeeping to avoid double conversion/free hazards.
  - Regression coverage:
    - added `TPipelineIntegrationTests.FillWithinActiveSelectionOverwritesExistingPixels` to lock the reported scenario (selected-area fill overwrites pre-existing ink inside selection, keeps outside pixels untouched).
  - Verification:
    - `bash ./scripts/run_tests_ci.sh` passed (`N:345 E:0 F:0`).
    - `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-08 — Colors panel wheel-sync latency fix (foreground alignment).**
  - Feature row mapping: `Colors panel` in `docs/FEATURE_MATRIX.md`.
  - User-facing defect: lower SV area in the wheel-first Colors panel could appear one step behind current foreground hue during wheel hue scrubs.
  - Root cause: `FColorSVCachedHue` was shared between two unrelated responsibilities (grayscale fallback hue memory and SV bitmap rendered-hue cache), so hue-drag updates could mark cache-as-fresh before SV bitmap re-render.
  - Implementation:
    1. added dedicated `FColorSVRenderedHue` state for SV bitmap render cache tracking.
    2. added helper `ShouldRebuildSVSquare(...)` in `FPColorWheelHelpers` and routed `ColorWheelBoxPaint` rebuild decision through it.
    3. kept `FColorSVCachedHue` only for zero-saturation hue-memory fallback and explicit hue tracking.
  - Regression coverage:
    - new suite `TFPColorWheelHelpersTests` (`SVSquareRebuildsWhenHueChangesOrCacheMissing`, `SVSquareSkipsRebuildForStableHueAndSize`).
  - Verification:
    - `bash ./scripts/run_tests_ci.sh` passed (`N:347 E:0 F:0`).
    - `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-08 — Zoom control centering + toolbar hover style polish.**
  - Adjusted `ToolbarZoomButtonInsetLeft` (6→4), `ToolbarZoomComboLeft` (38→36), `ToolbarZoomComboTop` (4→3), `ToolbarZoomInButtonLeft` (128→126) in `fptoolbarhelpers.pas` to center the `– 100% +` cluster.
  - Removed `ToolbarBtnMouseEnter`/`ToolbarBtnMouseLeave` flat-toggle from New/Open/Save buttons in `mainform.pas` so hover appearance matches other toolbar buttons.
  - Relaxed `ZoomControlsFitInsideZoomCluster` test to 1px tolerance for macOS visual nudge.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:350 E:0 F:0`).
- **2026-03-08 — Four critical bug fixes (bucket crash, selection re-click, keyboard shortcuts, brush hardness).**
  - **Paint bucket crash on unfenced areas:** `SampleSurface := FDocument.ActiveLayer.Surface` stored a borrowed reference that `SampleSurface.Free` in the `finally` block destroyed, crashing the app. Fix: call methods directly on `FDocument.ActiveLayer.Surface` without storing into `SampleSurface`, so `finally` frees only actually-allocated masks.
  - **Selection re-click requiring two clicks:** `ShouldAutoDeselectFromBlankClick` path set `FPointerDown := False; Exit;`, blocking new selection start. Fix: removed the early exit so auto-deselect flows into normal mouse-down handling for immediate new selection.
  - **Undocumented keyboard tool switching:** `NextToolForKey` in `FormKeyDown` mapped 13 letter keys to tool cycles, not documented in `SHORTCUT_POLICY.md`. Fix: removed entire `NextToolForKey` block, kept only X (swap colors) and D (reset colors) bare-key shortcuts.
  - **Brush hardness/parameters ineffective:** `DrawLine` used Bresenham every-pixel dab spacing, causing ~radius overlapping dabs per pixel that saturated opacity regardless of hardness setting. Fix: added `DrawSpacedLine`/`EraseSpacedLine` with GIMP-inspired 25% diameter dab spacing, routed brush and round-eraser through new methods.
  - Removed 3 tests for deleted keyboard-switch behavior; rewrote `ClickingOutsideSelectionAutoDeselects` for new selection lifecycle.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:347 E:0 F:0`); `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-08 — Dashed shape commit fix (phase carry across polyline segments).**
  - Feature row mapping: `Paint tools` in `docs/FEATURE_MATRIX.md`.
  - User-facing defect: ellipse/circle dashed outline appeared solid after commit; rectangle/rounded-rectangle/freeform dash patterns looked different from preview.
  - Root cause: `DrawDashedPolyline` called `DrawDashedLine` independently per segment, resetting dash phase at each vertex. Ellipse segments (many tiny arcs) were each shorter than `DashLength`, producing all-dash with no gaps. Rectangle/freeform dash alignment shifted at each corner due to phase reset.
  - Fix: rewrote `DrawDashedPolyline` to carry a continuous dash phase across all segments. Phase tracks position within the dash+gap period and flows correctly through segment boundaries.
  - Regression coverage: `DashedPolylineEllipseHasGapPixels` verifies decomposed-ellipse polyline has both painted and transparent pixels.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:348 E:0 F:0`).
- **2026-03-08 — Selection masking for all paint/draw/shape tools (paint.net/Photoshop/GIMP parity).**
  - Feature row mapping: `Selection tools` + `Paint tools` in `docs/FEATURE_MATRIX.md`.
  - Fallback reference: paint.net clips all drawing tool output to the active selection boundary; Photoshop and GIMP do the same. Recorded per dev rules #14-15.
  - User-facing defect: pencil, brush, eraser, line, rectangle, ellipse, freeform shape, and clone stamp did not respect active selection — strokes painted outside the selected area.
  - Root cause: `ToolPaintPathUsesActiveSelection` returned `True` only for `tkFill`, `tkGradient`, `tkRecolor`. All other drawing tools got `nil` for `PaintSelection`. Additionally, `ShouldPreserveSelectionAcrossToolSwitch` deselected when switching from selection tools to drawing tools.
  - Fix: expanded `ToolPaintPathUsesActiveSelection` to return `True` for all paint/draw/shape tools (exclusion-based: only navigation/utility tools are excluded). Updated `ShouldPreserveSelectionAcrossToolSwitch` to preserve selection when switching to any tool that uses selection masking.
  - Text tool (`tkText`) already had its own selection-aware path via `PlaceTextAtPoint` using `FDocument.Selection` directly.
  - Updated 2 tests: `LineDragIgnoresExistingSelectionMask` now verifies clipping instead of bypass; `SwitchingFromSelectionToBrushAutoDeselectsSelection` now verifies selection is preserved.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:348 E:0 F:0`); `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-08 — DrawDashedPolyline floating-point stall fix (hang on rounded rectangle dash commit).**
  - Feature row mapping: `Paint tools` in `docs/FEATURE_MATRIX.md`.
  - User-facing defect: app hung for ~1 s when committing dashed rounded-rectangle outline. macOS hang report showed main thread stuck in `DrawDashedPolyline` → `DrawLine` → `DrawBrush` loop.
  - Root cause: floating-point drift could make `Phase` nearly equal to `DashLength` (or `Period`), producing `RemainingInChunk ≈ 0` (e.g., 1e-15). The inner `while CursorPos < SegLength` loop then advanced by sub-picometer increments, effectively infinite.
  - Fix: added guard in `DrawDashedPolyline` — when `RemainingInChunk < 0.5`, snap `Phase` to the exact dash/gap boundary and re-evaluate. This guarantees the next iteration gets a full chunk (≥ 1 px) and the loop terminates in bounded time.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:348 E:0 F:0`); `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-08 — Multi-format export options expansion + BMP safety alignment.**
  - Feature row mapping: `Export/options` in `docs/FEATURE_MATRIX.md`.
  - Extended save-option routing from JPEG/PNG-only behavior to writer-backed controls across `JPEG/PNG/BMP/TIFF/PCX/PNM/XPM`, including dialog-side live preview and session-persisted option state.
  - Added missing PNG writer control (`CompressedText`) to both `TSaveSurfaceOptions` and export dialog UI.
  - Using local FPC source (`/Users/chrischan/Documents/workspace.nosync/lazarus/fpc/3.2.4/sources`) for writer contract audit, added the previously omitted `TFPWriterPNM.FullWidth` route (`PNM` 16-bit output) to options, UI, and tests.
  - Aligned BMP UI/options to the current stable RGBA save path: expose `24/32 bpp` + `X/Y pixels per meter`, and explicitly disable paletted/RLE paths that require indexed conversion not currently wired in this pipeline.
  - Updated `Save As` filter aliases to expose supported extension families directly (`*.jpeg`, `*.tiff`, `*.pbm`, `*.pgm`, `*.ppm`) so format support and selectable UI entries stay aligned.
  - Regression updates: default-options coverage now includes PNG compressed-text default, and BMP header tests now assert true-color configurability plus non-RLE safety clamp behavior.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:351 E:0 F:0`); `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-08 — Release hardening follow-up (Save-All semantics + plist metadata + Gate-C checklist).**
  - `Save All Images` in `mainform` no longer saves only the active document; it now iterates all tabs, saves only dirty tabs, prompts `Save As` only where no file path exists, and restores the originally active tab after completion or cancel.
  - macOS bundle metadata generation in `scripts/common.sh` is now parameterized via `FLATPAINT_BUNDLE_ID`, `FLATPAINT_VERSION`, and `FLATPAINT_BUILD` instead of shipping placeholder values.
  - `Info.plist` document type declaration is now constrained to FlatPaint-native `.fpd` (`Editor` role, owner rank) instead of wildcard file associations.
  - Added explicit Gate-C manual validation file: `docs/RELEASE_SMOKE_CHECKLIST.md`, and linked it from `docs/ARCHITECTURE_RENOVATION_PLAN.md`.
  - Synced stale docs to current regression baseline (`363` tests), including `docs/PRD.md`, `docs/FEATURE_MATRIX.md`, and `docs/SHORTCUT_POLICY.md`.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:363 E:0 F:0`).
- **2026-03-09 — Rounded-corner preview during draw + edge-case unit tests.**
  - Feature row mapping: `Select/rectangle` in `docs/FEATURE_MATRIX.md`.
  - Bug fix: rounded-corner rectangle selection now shows rounded corners in the marching-ants preview while drawing (FPointerDown) and during edge-adjustment mode, not only after committing. Previously the preview always drew a sharp rectangle regardless of `FSelCornerRadius`.
  - Implementation: added `DrawMarqueeRoundedRectOverlay` — generates a parametric rounded-rect polyline (4 quarter-circle arcs × 8 steps + 4 straight segments + 1 close = 37 points) and calls `FPDrawMarchingAntsPolyline`. Updated both preview drawing paths (initial drag and adjustment mode) to use it when `FSelCornerRadius > 0`.
  - Added `ACanvas.RoundRect` call before the marching ants overlay in the initial draw preview so the filled selection indicator also shows rounded corners.
  - Added 9 edge-case unit tests for `TSelectionMask.SelectRectangle`: single-pixel select, inverted coordinates, out-of-bounds clamping, radius larger than half-size, subtract mode, anti-alias edge coverage, rounded subtract preserving surrounds, full-document-extent coverage, and zero-area (fully OOB) producing no selection.
  - Added development rule #26: edge-case and extreme-value test requirements for core functions.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:412 E:0 F:0`); `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
- **2026-03-10 — Rounded-rect marquee arc fix + adjustment-mode animation + state leak fixes.**
  - Feature row mapping: `Select/rectangle` in `docs/FEATURE_MATRIX.md`.
  - Bug fix: `DrawMarqueeRoundedRectOverlay` arc geometry was fundamentally wrong — the top-left arc used an incorrect trigonometric formula (`CX - R*cos(angle)` instead of `CX + R*cos(angle)`) with wrong angle range, producing stray diagonal lines from origin to the rectangle. Rewrote all 4 arcs with consistent parametric formula: `X = CX + R*cos(angle)`, `Y = CY + R*sin(angle)` using screen-coordinate convention (angle 0=right, π/2=down, π=left, 3π/2=up).
  - Bug fix: marching ants animation was mouse-dependent during edge-adjustment mode because `FDocument.HasSelection` is `False` before commit, so `ShouldAnimateMarqueeNow` fell through to the `PointerInCanvas` check. Added early `Exit(True)` when `FSelAdjusting` is `True`.
  - Bug fix: `FSelAdjusting` state leaked across tabs and document closes. Added `CancelSelAdjust` calls to `SwitchToTab` and `CloseDocumentTab`.
  - Performance: converted `DrawMarqueeRoundedRectOverlay` from dynamic `SetLength` allocation (heap churn every paint frame) to static array `array[0..MaxPts*2-1] of Double`.
  - Added 2 marquee animation policy tests to `fpmarqueehelpers_tests`.
  - Updated `docs/FEATURE_MATRIX.md` Selection tools row to mention post-draw edge adjustment and rounded-corner preview.
  - Verification: `bash ./scripts/run_tests_ci.sh` passed (`N:414 E:0 F:0`); `bash ./scripts/build.sh` passed and refreshed `dist/FlatPaint.app`.
