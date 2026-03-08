# Test Log

## Scope note
- This is a cumulative historical log and includes legacy test records from earlier prototype phases.
- The active test/build toolchain for current work is FPC + Lazarus.

## 2026-03-08 (public-pack staging verification: release + extracted library smoke builds)
- Release build verification before packaging: `bash ./scripts/build-release.sh`
- Result: passed; refreshed `dist/release/flatpaint` and `dist/FlatPaint.app`.
- Full regression verification after packaging scripts and standalone lib build-script adjustments: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `351` tests, `0` errors, `0` failures.
- Final standalone-library verification after license + README completion:
  - `bash ./git/verify_libs.sh`
  - Result: passed; all 5 extracted libraries compiled via standalone scripts.
- Follow-up verification after auto-detection fix for Lazarus source path depth:
  - `bash ./git/verify_libs.sh`
  - Result: passed; all 5 extracted libraries compiled successfully.
- Final repository regression gate after public-pack/license updates:
  - `bash ./scripts/run_tests_ci.sh`
  - Result: passed; `351` tests, `0` errors, `0` failures.
- Extracted-library smoke builds:
  - `bash ./git/libs/fp-raster-core/build.sh` => passed
  - `bash ./git/libs/fp-viewport-kit/build.sh` => passed
  - `bash ./git/libs/fp-lcl-raster-bridge/build.sh` => passed
  - `bash ./git/libs/fp-lcl-clipboard-meta/build.sh` => passed
  - `bash ./git/libs/fp-macos-lcl-bridge/build.sh` => passed
- Packaging verification:
  - `bash ./git/package_release.sh`
  - Result: passed; refreshed `git/release/FlatPaint.app` and `git/release/packages/*.zip`.

## 2026-03-08 (dialog i18n completion + effect-dialog caption localization)
- Full CI verification after localizing untranslated dialog surfaces (`about/blur/curves/effect/export/layer-properties/new-image/noise/posterize/resize/text`), localizing resize resample captions, and wiring `mainform` effect-dialog title/label + repeat-caption strings to `TR(...)`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `351` tests, `0` errors, `0` failures.

## 2026-03-08 (export options dialog + JPEG stream-save regression coverage)
- Full CI verification after introducing `fpexportdialog`-based PNG/JPEG save options + preview flow, wiring new persisted JPEG/PNG option fields into `mainform`, and adding `TFPIOTests.JpegStreamSaveSupportsExtensionNormalizationAndGrayscaleOutput`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `349` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-08 (About content build-time regeneration + source-sync regression coverage)
- Full CI verification after adding `scripts/generate_about_content.sh`, wiring it into build/test scripts, regenerating `FPAboutContent`, and adding `TFPAboutContentTests.AboutSectionsMatchAssetSourceFiles`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `350` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-08 (ruler-aware palette clamp + clone overlay polish + zoom loupe + recolor contiguous + About embed + CI script fix)
- Full CI verification after landing ruler-aware palette clamp helpers/routes, clone-stamp overlay style adjustment, zoom-tool loupe overlay helper integration, recolor contiguous-mode end-to-end path, app-menu About dialog with embedded content, and `run_tests_ci.sh` `dist/` bootstrap guard: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `341` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-08 (system clipboard edit bridge + zoom interpolation policy verification)
- Full CI verification after wiring Edit copy/cut/paste to system clipboard (with app metadata guard for paste offsets), adding `fpclipboardhelpers` helper tests, and refining zoom-band interpolation policy via `DisplayInterpolationQualityForZoom`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `334` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-08 (performance audit + display bridge hot-loop optimization verification)
- Full CI verification after optimizing `CopySurfaceToBitmap` to raw-pointer traversal (removing per-pixel indexed property access overhead while preserving unpremultiply semantics), adding safe raw-image buffer cleanup, and precomputing checkerboard colors in `BuildDisplaySurface`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `330` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-08 (premultiplied boundary correctness fix verification)
- Full CI verification after fixing premultiplied-source blend routing (`MergeDown`, background `MoveSelectedPixelsBy`, clone-stamp apply), correcting sampled-color unpremultiply paths (color picker + recolor source), adding dedicated regressions, and repairing `run_tests_ci.sh` default Lazarus path fallback: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `330` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-07 (Retina point-size compliance fix for options-bar icon path)
- Full CI verification after changing options-bar tool-icon `TImage` to fixed logical size with scaled rendering (`Stretch=True`, `Proportional=True`) so `@2x` icon assets are not clipped inside a 20pt box: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `311` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-07 (Icon/Retina multi-scale asset-chain closure verification)
- Full CI verification after unifying rendered-icon `@2x` fallback-safe loading, adding mapped-tool assets (`pointer`/`grid-2x2`) to the extraction/render pipeline, and expanding icon regression checks: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `311` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed and bundle now contains `1x` + `@2x` rendered icon assets.

## 2026-03-07 (P0 closure verification pass)
- Full CI verification after completing the three P0 tracks (shortcut parity high-use audit closure, recolor R2 rollout, A4 offset runtime semantic activation), adding `fpshortcuthelpers_tests`, and wiring the new test unit into `flatpaint_tests.lpr`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `295` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-07 (doc-alignment and prioritization verification pass)
- Full CI verification during doc-sync updates (`PRD`, `FEATURE_MATRIX`, `IMPLEMENTATION_PLAN`) and new `FEATURE_PRIORITY_ORDER` baseline creation: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `284` tests, `0` errors, `0` failures.

## 2026-03-07 (recolor research docs + tools palette height regression fix)
- Full CI verification after adding recolor research/design docs, increasing tools palette default height to prevent last-row clipping, and adding `ToolsPaletteHeightFitsAllVisibleToolRows` regression coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `284` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.
- Execution note:
  - an earlier parallel test/build attempt was discarded because both scripts clean shared build outputs; final evidence above is from serial execution.

## 2026-03-07 (UI-only retina/readability stabilization pass)
- Full CI verification after startup multi-pass relayout (`FDeferredLayoutPassesRemaining`), resize-time top/status relayout hookup, global overlay realignment helper, DPI-aware overlay sizing, and optional `@2x` icon lookup support: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `279` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-07 (shape commit regression suite expansion + deferred-layout safety adjustment)
- Full CI verification after adding shape commit pipeline regressions (`LineDragCommitsPixels`, `RectangleDragCommitsPixels`, `EllipseDragCommitsPixels`) and switching deferred startup options-row pass to layout-only (`LayoutOptionRow`): `bash ./scripts/run_tests_ci.sh`
- Result: passed; `279` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-07 (toolbar icon overlay sizing + startup options-row relayout pass)
- Full CI verification after `mainform` toolbar icon overlay sizing/padding adjustments and deferred options-row relayout hook: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `276` tests, `0` errors, `0` failures.
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.
- Execution note:
  - a parallel test/build attempt was discarded because both scripts run clean/compile steps and can race on `lib/aarch64-darwin`; final evidence above is from serial re-run.

## 2026-03-07 (Phase 4.5 closure verification + XCF offset fixture correction)
- Full CI verification after adding full-snapshot layer-offset regression, correcting minimal-XCF offset fixture layout, and adding XCF offset-import metadata coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `276` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TFPDocumentTests`:
    - `LayerOffsetMetadataPreservedAcrossFullSnapshotUndoRedo`
  - `TFPIOTests`:
    - `XcfImportPreservesLayerOffsetMetadata`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-07 (Phase 5 completion: region transaction service now covers stroke + move-pixels history paths)
- Full CI verification after extending `TRegionHistoryTransaction` with optional selection-state snapshots, routing `TMovePixelsController` history through the core transaction service, and expanding controller/core transaction regressions: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `274` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `THistoryTransactionTests`:
    - `RegionTransactionSelectionSnapshotRestoresSelectionOnUndoRedo`
  - `TToolControllerTests`:
    - `MovePixelsControllerUndoRedoRestoresSelectionAndPixels`
    - `MovePixelsControllerBackgroundCommitKeepsOpaqueFillAndUndo`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 3 closure: fill/shape + move-session-begin guard coupling)
- Full CI verification after routing fill/shape commit writes through `MutableActiveLayerSurface`, guard-coupling `TMovePixelsController.BeginSession`, and adding controller locked-begin regression coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `271` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TToolControllerTests`:
    - `MovePixelsControllerBeginSessionBlockedByLockedLayer`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 3 tail: guarded mutable-surface routing for brush/recolor/clone writes)
- Full CI verification after adding `MutableActiveLayerSurface`, rerouting high-frequency brush-like mutation loops in `ApplyImmediateTool`, and expanding mutation-guard coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `270` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TMutationGuardTests`:
    - `MutableActiveLayerSurfaceRespectsLockState`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 3 tail: interactive shape/fill/crop begin-mutation routing)
- Full CI verification after moving pointer-driven fill/shape/crop commit paths and pending-bezier segment commit to guard-aware begin-mutation entry points: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `269` tests, `0` errors, `0` failures.
- Regression note:
  - no suite regressions after converting these interactive routes from direct `PushHistory` preambles to begin-mutation guarded starts.
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 3 tail: move-pixels controller commit guard coupling)
- Full CI verification after routing `TMovePixelsController.Commit` through guard-aware core begin-mutation + core mutation APIs and adding blocked-commit controller regression: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `269` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TToolControllerTests`:
    - `MovePixelsControllerCommitBlockedByLockedLayer`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 3 tail: begin-mutation guard routes + no-op history cleanup)
- Full CI verification after adding `BeginActiveLayerMutation` / `BeginDocumentMutation`, rerouting lock-sensitive menu/effect handlers to guard-aware history entry points, and expanding mutation-guard tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `268` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TMutationGuardTests`:
    - `BeginActiveLayerMutationRespectsLockAndHistory`
    - `BeginDocumentMutationRespectsLockAndHistory`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 3 tail: guarded core routes for paste/pixelate/rotate)
- Full CI verification after introducing guarded core mutation wrappers (`PasteSurfaceToActiveLayer`, `PixelateRect`, active-layer rotate wrappers), rerouting `mainform` call sites, and expanding mutation-guard regression coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `263` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TMutationGuardTests`:
    - `LockedActiveLayerBlocksSurfacePasteAndRotateRoutes`
    - extended unlocked-route coverage for guarded paste path
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (A7 closure: stored-selection core-route contract)
- Full CI verification after moving stored-selection capture into core selection-copy routes (`CopySelectionToSurface` / `CopyMergedToSurface`) and adding route regression tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `262` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TFPDocumentTests`:
    - `CopySelectionStoresSelectionForPasteRoute`
    - `CopyMergedStoresSelectionForPasteRoute`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 6: tool-controller decomposition for selection routes)
- Full CI verification after adding `TSelectionToolController`, wiring `mainform` selection routes through app-layer controllers, and expanding controller-level regression tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `260` tests, `0` errors, `0` failures.
- Controller suite highlights (`TToolControllerTests`, `8/8` passed):
  - `SelectionModeMappingFollowsModifierContract`
  - `SelectionRectangleCommitPushesHistoryAndSelection`
  - `SelectionMoveControllerPushesHistoryAndMovesMask`
  - `SelectionMagicWandCommitPushesHistoryAndSelectsSample`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 4.5/5: layer-offset metadata + incremental stroke history capture)
- Full CI verification after landing layer-offset metadata in core/native/XCF compatibility routes and replacing stroke-start full-layer clone with incremental region capture: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `252` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TFPDocumentTests`:
    - `LayerOffsetMetadataPreservedInClone`
  - `TIntegrationNativeRoundTripTests`:
    - `Test_MultiLayer_SaveLoad_PreservesLayersAndPixels` now validates per-layer offset roundtrip
  - `TPipelineIntegrationTests`:
    - `UndoRedoAfterLongPencilStrokeRestoresPixels`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 4 selection coverage propagation + native mask v3)
- Full CI verification after propagating selection coverage semantics through selection transforms, selection-aware surface mutation paths, background move blend path, and native `.fpd` selection persistence upgrade to `FPDOC03`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `250` tests, `0` errors, `0` failures.
- New/expanded suite highlights:
  - `TFPSurfaceTests` added coverage-aware selection application assertions:
    - `MaskedLineCoverageScalesAlpha`
    - `FillSelectionCoverageScalesOpacity`
    - `CopySelectionCoverageScalesAlpha`
    - `MoveSelectedPixelsCoverageUsesSoftCopyAndSoftErase`
  - `TFPSelectionTests` added byte-coverage invariants:
    - `InvertPreservesByteCoverage`
    - `TransformPathsPreserveCoverageValues`
  - `TIntegrationNativeRoundTripTests` added native mask persistence check:
    - `Test_SelectionCoverage_SaveLoad_PreservesByteMask`
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (shortcut/colors regression closure + mutation guard suite)
- Full CI verification after fixing `TFPUIHelpersTests` shortcut/hint/cycle regressions, fixing colors panel width contract, introducing core `MutationGuard`, and adding dedicated guard tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; `243` tests, `0` errors, `0` failures.
- New suite result:
  - `TMutationGuardTests` passed (`4/4`)
  - Cases:
    - `LockedActiveLayerBlocksAdjustmentMutation`
    - `LockedActiveLayerBlocksSelectionDrivenMutation`
    - `LockedLayerBlocksDocumentWidePixelMutation`
    - `UnlockedMutationsStillApply`
- Follow-up status:
  - previously failing `TFPUIHelpersTests` set is now green
  - previously failing `TFPPaletteHelpersTests.ColorsPanelFitsSystemPickerAndSliderRows` is now green
- GUI build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (Phase 1/2 move-pixels transaction migration)
- Full regression run after transactional `Move Pixels` migration and new transaction tests: `bash ./scripts/run_tests_ci.sh`
- Result: failed; `239` tests, `0` errors, `8` failures.
- Failure set unchanged from previous baseline:
  - `TFPUIHelpersTests` (shortcut/hint/cycle mapping contracts)
  - `TFPPaletteHelpersTests` (colors panel width contract)
- New suite result:
  - `TToolTransactionTests` passed (`3/3`)
  - Cases:
    - `MovePixelsDragDoesNotMutateLayerBeforeMouseUp`
    - `MovePixelsClickWithoutDeltaDoesNotPushHistory`
    - `MovePixelsEscapeCancelsPreviewAndRestoresSelection`
- Build verification in the same change window: `bash ./scripts/build.sh`
- Result: passed; `dist/FlatPaint.app` refreshed.

## 2026-03-06 (docs/code baseline alignment audit)
- Full regression run after code-vs-doc alignment audit: `bash ./scripts/run_tests_ci.sh`
- Result: failed; 236 tests, 0 errors, 8 failures.
- Failing suites:
  - `TFPUIHelpersTests` (shortcut/hint/cycle mapping contracts)
  - `TFPPaletteHelpersTests` (colors panel width contract)
- GUI build verification in the same session: `bash ./scripts/build.sh`
- Result: passed; app linked and `dist/FlatPaint.app` refreshed.
- Follow-up rule: current feature completion and release readiness must be assessed against this failing test state until regressions are closed.

## 2026-03-05 (six bug fixes + 18 pipeline integration tests)
- Full CI verification after fixing 6 bugs (OnKeyUp not wired, FTempToolActive not cleared, history panel not refreshed, GMainForm dangling pointer, PushHistory ordering in LayerRotateZoomClick, clone stamp state leak on tab switch) and adding 18 new pipeline integration tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; 236 tests, 0 errors, 0 failures (218 existing + 18 new in `TPipelineIntegrationTests`)
- New tests cover: drawing pipeline (pencil/brush/eraser pixel verification), history pipeline (undo depth growth), layer pipeline (count and active index), temp-pan regression (space activate/deactivate, keyboard tool switch clears flag), render revision, dirty flag, and display pixel verification
- `CreateForTesting` rewritten to use raw `GetMem` + manual VMT setup to bypass LCL widget creation that crashes in headless Cocoa test environments
- GUI build verification: `bash ./scripts/build.sh` — passed, no FPC warnings

## 2026-03-04 (passive button-overlay interaction fix)
- Full CI verification after returning button icon overlays to a display-only role, sizing command/utility buttons to their final height before overlay placement, and explicitly realigning tool-button overlays after their final palette height is applied: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 218 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint` and refreshed `dist/FlatPaint.app`

## 2026-03-04 (document-mutating command seal pass)
- Full CI verification after extending pending-stroke sealing to resize/canvas operations, rotations/flips, adjustment commands, effect commands, and `Repeat Last Effect`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 218 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint` and refreshed `dist/FlatPaint.app`

## 2026-03-04 (pending-stroke UI interaction seal pass)
- Full CI verification after sealing pending brush-like strokes before history jumps, undo/redo, tool switches, layer/color UI mutations, palette toggles, and close/quit flows, plus adding tracked history behavior for layer blend-mode changes: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 218 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint` and refreshed `dist/FlatPaint.app`

## 2026-03-04 (pending brush-stroke sealing fix)
- Full CI verification after sealing pending brush-like strokes on a fresh mouse-down, preserving the in-flight stroke tool label, and adding the new helper-level regression check: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 218 tests, 0 errors, 0 failures, including the new `TMainFormIntegrationTests.NewMouseDownCommitsPendingBrushStroke`
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint` and refreshed `dist/FlatPaint.app`

## 2026-03-04 (low-risk toolbar/palette chrome correction pass)
- Full CI verification after widening `New / Open / Save`, tightening the overlay-icon placement on wide command buttons, vertically re-centering the zoom combo, switching palette-header icons to the built-in line-glyph path, and adding the new toolbar/icon regression assertions: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite with the added `TFPToolbarHelpersTests.FileGroupStaysWideEnoughForIconLabels` coverage and the tightened zoom-center alignment assertion
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint` and refreshed `dist/FlatPaint.app`

## 2026-03-04 (Cocoa icon-overlay stabilization + right-cluster visibility pass)
- Full CI verification after moving the visible button-icon path to overlay images, switching palette-header icons to direct picture loading, widening `New / Open / Save`, and anchoring the top-right utility/zoom cluster to `FTopPanel.ClientWidth`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 216 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and the live screenshot check confirmed the top-right utility cluster and zoom controls were visible again
- Manual interaction verification after the same pass: screenshot-based UAT plus live click-through confirmed `New / Open / Save`, the top-right utility cluster, palette header icons, and the history-row before/after toggle behavior all stayed visible and interactive together

## 2026-03-04 (canonical Lucide runtime render pass)
- Full CI verification after restoring asset-backed rendering for command/tool/utility buttons, widening representative rendered-asset coverage across those surfaces, and locking the canonical SVG source set to the local `./icons` Lucide drop: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 215 tests, 0 errors, 0 failures

## 2026-03-04 (canonical icon source set synced from local `./icons`)
- Full CI verification after mirroring the local `./icons` Lucide stroke SVG set into `assets/icons/lucide` and adding direct source-asset coverage in `TFPIconHelpersTests`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite with the added `RepresentativeLucideSourceAssetsExist` coverage

## 2026-03-04 (tool/utility icon fidelity rollback to stable line glyphs)
- Full CI verification after restricting rendered icon assets to command-button surfaces and moving tool/utility buttons back to the built-in line glyph path: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite with the updated `TFPIconHelpersTests.RepresentativeRenderedCommandAssetsExist` coverage
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (toolbar layout metrics + position regression pass)
- Full CI verification after extracting top-toolbar geometry into `FPToolbarHelpers`, wiring `mainform` to the shared metric layer, normalizing the left command-group spacing, and adding direct toolbar-position tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 214 tests, 0 errors, 0 failures, including the new `TFPToolbarHelpersTests` coverage for top-row geometry
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, rebuilt `flatpaint`, and refreshed `dist/FlatPaint.app`

## 2026-03-04 (icon refresh decoupled from normal build)
- GUI build verification after removing automatic Lucide icon regeneration from the normal build path and switching the build back to the checked-in rendered icon assets: `bash ./scripts/build.sh`
- Result: passed; the build completed without the old `Refreshing Lucide icon assets` phase and still rebuilt `dist/FlatPaint.app`
- Full CI verification after adding a direct asset-presence regression for representative extracted/rendered Lucide files so the checked-in icon set is explicitly covered by tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 210 tests, 0 errors, 0 failures

## 2026-03-04 (Lucide symbol extraction + full icon replacement pass)
- GUI build verification after extracting the required Lucide symbols from `lucide.symbol.svg`, regenerating normalized transparent rendered icon assets, expanding the runtime icon map across the visible button surfaces, and rebundling the app: `bash ./scripts/build.sh`
- Result: passed; the build regenerated `assets/icons/extracted/*.svg`, regenerated `assets/icons/rendered/*.svg.png`, linked `flatpaint`, and refreshed `dist/FlatPaint.app`
- Full CI verification after the same pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 209 tests, 0 errors, 0 failures

## 2026-03-04 (runtime icon-asset hookup pass)
- GUI build verification after wiring `FPIconHelpers` to load rendered PNG assets first, rasterizing the local Lucide SVG set into checked-in PNGs, and copying those rendered icons into the app bundle resources: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and the rebuilt bundle now contains `Contents/Resources/icons/rendered/*.png`
- Full CI verification after the same pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 209 tests, 0 errors, 0 failures

## 2026-03-04 (tool-glyph restoration + palette-header icon pass)
- Full CI verification after re-enabling shared glyph rendering for tool buttons, resizing the two-column tools palette around icon-first buttons, switching palette headers to shared utility glyphs, and correcting palette-toggle shortcut hints: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 209 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (lucide-source asset seeding + top-toolbar realignment pass)
- GUI build verification after right-aligning the top zoom cluster, regrouping the four palette-toggle buttons into the top row, switching shared glyphs to transparent-backed bitmaps, and adding the new top-toolbar icon-source assets: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace
- Full CI verification after the same pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 209 tests, 0 errors, 0 failures, including the new `TFPIconHelpersTests.TopToolbarCaptionAliasesStayMapped` coverage for the top-toolbar icon alias paths

## 2026-03-04 (toolbar click-surface recovery + visible zoom-tool removal pass)
- GUI build verification after moving the top quick-action strip to stable symbol/text command buttons, keeping the title centered via symmetric title-band rails, and removing `Zoom` from the visible tool selectors: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace
- Full CI verification after the same pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 208 tests, 0 errors, 0 failures

## 2026-03-04 (palette-drag root fix + tool/utility symbol pass)
- GUI build verification after fixing palette drag-root resolution, restoring larger symbol-based tool/utility buttons, and switching tab/palette close affordances back to stable text symbols: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace
- Full CI verification after the same pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 208 tests, 0 errors, 0 failures

## 2026-03-04 (icon-surface de-whiteboxing + host-tinted glyph pass)
- Full CI verification after switching shared glyph generation to host-surface-aware backgrounds, removing forced raised `TSpeedButton` chrome from the visible toolbar/utility controls, and routing tab add/close glyphs through the same host-aware path: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 208 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (title-band + toolbar rhythm + tool-button polish pass)
- Full CI verification after adding the in-window title band, re-spacing the top toolbar into shared title/command/option rows, and switching the tool buttons to ghost-vs-active styling without changing their handlers: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 208 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (Photoshop/GIMP-style background-layer semantics pass)
- Full CI verification after introducing a real `IsBackground` document flag, persisting it through native save/load, locking the background layer to the bottom slot, and routing destructive background-layer edits through opaque replacement color semantics: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 208 tests, 0 errors, 0 failures, including the new `TFPDocumentTests` coverage for background-layer lock behavior and opacity-preserving erase/move semantics plus the native round-trip regression for the saved background flag
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (paint-visibility recovery + line-default interaction pass)
- Full CI verification after fixing sampled-alpha visibility traps, adding dedicated erase-line/erase-brush raster paths, restoring straight-line-by-default behavior with opt-in Bezier staging, and hardening drag finalization against missing `MouseUp` delivery: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 206 tests, 0 errors, 0 failures, including the new eraser-alpha regression and the new helper-level interaction-contract coverage for sampled-color alpha preservation, line-release staging, and drag-button-state tracking
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (toolbar grouping + palette-header shortcut pass)
- Full CI verification after adding palette shortcut-label helpers, toolbar grouping visuals, wider icon-plus-text file-action buttons, and palette-header shortcut badges: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 202 tests, 0 errors, 0 failures, including the new `TFPPaletteHelpersTests.PaletteShortcutLabelsStayReadable` coverage
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (tool-palette shortcut + active-state UI pass)
- Full CI verification after adding shared tool-shortcut metadata, visible tool-button shortcut badges, tool-button pressed-state sync, utility-button palette-toggle state, and the corresponding helper tests: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 201 tests, 0 errors, 0 failures, including the expanded `TFPUIHelpersTests` and `TFPUtilityHelpersTests` coverage for visible shortcut metadata
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (real-interaction cache-audit pass)
- Full CI verification after routing selection-only mutations, move-selection/move-pixels drags, staged line commits, and layer drag reorder through cache-invalidating visible refresh paths: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 198 tests, 0 errors, 0 failures after the interactive cache-audit fixes

## 2026-03-04 (tool-control logic audit + tolerance isolation pass)
- Full CI verification after separating Recolor tolerance from Magic Wand tolerance, syncing Feather spin enabled state on Anti-alias toggle, aligning Recolor/CloneStamp mouse-move to lightweight cache-invalidation instead of full SetDirty, and adding layer thumbnail refresh after line segment commit: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 198 tests, 0 errors, 0 failures
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (pencil first-dab visibility + iconography extension pass)
- Full CI verification after invalidating the prepared display bitmap on the initial mouse-down mutation path for the live paint tools and extending shared glyph coverage to Colors actions plus palette close buttons: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 198 tests, 0 errors, 0 failures, including the expanded `TFPIconHelpersTests` coverage for `Swap`, `Mono`, and shared close-button glyph support
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (canvas-feedback hardening + UI-adjacent integration pass)
- Full CI verification after unifying more document-replacement/mutation refresh paths, tightening bucket-with-selection behavior, making single-key tool shortcuts yield to modified command chords, and adding stable UI-adjacent integration coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 197 tests, 0 errors, 0 failures, including the new `TMainFormIntegrationTests` coverage for modifier-safe shortcut gating plus visible composite-output checks for pencil-style strokes and selection-masked bucket fills
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (bitmap iconography + layered-xcf compatibility pass)
- Full CI verification after moving the main visible button surfaces onto a shared bitmap-glyph path and adding layered `.xcf` document loading: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 194 tests, 0 errors, 0 failures, including the existing `TFPIconHelpersTests` coverage plus the new `XcfCanLoadLayeredDocument` regression
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (status-progress visibility pass)
- Full CI verification after adding a real status-bar progress region for adjustments/effects and extending the status-layout tests for the new progress slot: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 190 tests, 0 errors, 0 failures after the new status-progress helpers and layout assertions
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (image-list parity closure + card-refresh pass)
- Full CI verification after replacing repeated full tab-strip rebuilds with lighter in-place tab-card preview refresh for same-structure updates and updating the image-list parity audit: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 188 tests, 0 errors, 0 failures after the tab-strip refresh refinement
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (real save-options pass)
- Full CI verification after wiring PNG alpha/compression and JPEG progressive settings through the real writer path and adding save-option regressions: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 188 tests, 0 errors, 0 failures after the export-path update
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-04 (visual-mutation sync pass)
- Full CI verification after centralizing mutation-driven UI refresh through `SyncImageMutationUI(...)` and routing the high-visibility adjustments/effects/history paths through it: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 186 tests, 0 errors, 0 failures after the shared post-mutation UI sync pass
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (layer-properties completion pass)
- Full CI verification after adding visibility to `Layer Properties...` and `Ctrl+Click` jump-to-top / jump-to-bottom layer movement: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 184 tests, 0 errors, 0 failures after the layer-surface updates
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace after switching the modifier check to the public `GetKeyShiftState` helper

## 2026-03-03 (krita flattened-import pass)
- Full CI verification after adding ZIP-based `.kra` flattened import through Krita's merged preview PNG path: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 184 tests, 0 errors, 0 failures, including the new `KraZipLoadExtractsMergedImage` regression while preserving the invalid `.kra` fallback-error coverage
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (effects near-completion + safe startup-tool pass)
- Full CI verification after adding `Red Eye`, `Tile Reflection`, `Crystallize`, `Ink Sketch`, `Mandelbrot Fractal`, `Julia Fractal`, and switching the startup default tool to `Rectangle Select`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 183 tests, 0 errors, 0 failures, including six new effect-specific surface tests plus the new startup-default helper regression
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (advanced effects expansion pass)
- Full CI verification after adding `Unfocus`, `Surface Blur`, `Bulge`, `Dents`, and `Relief`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 176 tests, 0 errors, 0 failures, including five new effect-specific surface tests plus the new white-background document-default regression
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (multi-segment line-path pass)
- Full CI verification after extending the `Line` tool from a single staged Bézier segment into a chained multi-segment path flow: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 170 tests, 0 errors, 0 failures, including the new line-hint chaining helper coverage
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (two-handle line-curve pass)
- Full CI verification after promoting the `Line` tool from a single-handle bend to a staged two-handle Bézier flow: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 169 tests, 0 errors, 0 failures, including the new `CubicBezierUsesBothControlHandles` coverage and the line-hint helper assertion
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (selection feather pass)
- Full CI verification after wiring `Anti-alias` + `Feather` through `TSelectionMask.Feather(...)`: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 167 tests, 0 errors, 0 failures, including the new `FeatherSoftensEdges` coverage

## 2026-03-03 (inline text tool pass)
- Full CI verification after moving the `Text` tool from modal-only placement to live inline canvas editing: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 166 tests, 0 errors, 0 failures, including the new `TextToolHintMentionsInlineEditing` helper coverage
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (eraser square-tip pass)
- Full CI verification after adding the eraser `Round` / `Square` tip path and square hover feedback: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 165 tests, 0 errors, 0 failures, including the new `SquareLineBrushCoversCornerPixels` coverage
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (line-curve interaction pass)
- Full CI verification after adding quadratic-curve raster support and the two-stage `Line` tool interaction: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 164 tests, 0 errors, 0 failures, including the new `QuadraticBezierBendsTowardControlPoint` coverage

## 2026-03-03 (tool-preview cohesion pass)
- Full CI verification after strengthening clone/drag previews and routing immediate canvas repaints from tool-option changes: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 163 tests, 0 errors, 0 failures after the canvas-preview and option-refresh changes
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (canvas-feedback tool pass)
- Full CI verification after adding shared canvas hover feedback, clone-source markers, and tool-hover metadata coverage: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 163 tests, 0 errors, 0 failures, including the new hover-feedback and brush-overlay helper assertions
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace
- GUI smoke verification after the same pass: launched `./flatpaint`, left it running briefly, then confirmed the process stayed alive until manually terminated
- Result: no startup crash or immediate event-loop failure was observed after wiring the new paint-box hover/leave handlers and canvas overlay draw path

## 2026-03-03 (system-picker color panel + speed-button completion pass)
- Full CI verification after replacing the custom wheel-first Colors surface with the slimmer system-picker companion panel and completing the shared speed-button path: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 151 tests, 0 errors, 0 failures after the color-panel refactor, palette-height reduction, and button-type unification
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (wheel-first color panel + icon-button pass)
- Full CI verification after the wheel-first Colors panel and layer-reorder/icon-button pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 151 tests, 0 errors, 0 failures after the color-wheel interaction change, the layer drag-reorder path, the glyph-button updates, and the later foreground/background preview visibility tweak
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace
- Live visual verification after the same pass: launched `dist/FlatPaint.app` and captured the running window via the local screenshot helper
- Result: the checked default window state showed no new clipping or default panel overlap, and the updated Colors/Layers panel content fit in the visible layout

## 2026-03-03 (panel depth + compact control pass)
- Full CI verification after the color/layer panel density pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 149 tests, 0 errors, 0 failures, including the new compact-glyph assertions, layer-opacity mapping coverage, and deeper palette-size regressions
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03 (light theme refresh)
- Full CI verification after the global chrome/theme pass: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 146 tests, 0 errors, 0 failures, including the new palette-theme helper coverage and UI chrome-contract assertions
- GUI build verification after the same pass: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-03
- Full CI verification after the documentation-sync audit: `bash ./scripts/run_tests_ci.sh`
- Result: passed; the script rebuilt `flatpaint_cli`, rebuilt `dist/flatpaint_tests`, and ran the full suite at 142 tests, 0 errors, 0 failures
- GUI build verification after the same audit: `bash ./scripts/build.sh`
- Result: passed; the current Lazarus/Cocoa build linked `flatpaint`, refreshed `dist/FlatPaint.app`, and completed cleanly in the workspace

## 2026-03-02
- FPCUnit rebuild after the selection-intersect follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 92 tests, adding direct `TSelectionMask` intersect coverage plus a document-level magic-wand intersect regression
- Lazarus project compile pass after the same follow-up: `./scripts/build.sh`
- Result: passed end-to-end and refreshed `flatpaint`, `flatpaint.app`, and `dist/FlatPaint.app`; the new selection-combine mode and `Shift+Option` routing compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log still only showed the same macOS-side `LaunchServices` / connection-invalid warnings, not a FlatPaint crash in the new selection path
- FPCUnit rebuild after the tool-surface audit plus `Pan` / `Pencil` follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 89 tests, adding zero-radius pencil-stroke coverage, a shared `Pan` scroll helper regression, and updated tool-order coverage while keeping the palette-layout regressions green after the taller `Tools` window baseline
- Lazarus project compile pass after the same tool follow-up: `./scripts/build.sh`
- Result: passed end-to-end and refreshed `flatpaint`, `flatpaint.app`, and `dist/FlatPaint.app`; the new `Pan` / `Pencil` tool routes plus the updated palette metrics compile cleanly under the current Cocoa target
- GUI smoke path after the same tool follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log still only showed the same macOS-side `LaunchServices` / connection-invalid warnings, not a FlatPaint crash in the new tool path
- FPCUnit rebuild after the menu/layout follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 86 tests, adding file-menu helper coverage plus the new workspace-aware palette and status-bar layout regressions
- Lazarus project compile pass after the same menu/layout follow-up: `./scripts/build.sh`
- Result: passed end-to-end and refreshed `flatpaint`, `flatpaint.app`, and `dist/FlatPaint.app`; the new `Acquire` route, `Save All Images` route, deferred palette layout pass, and right-edge zoom-cluster layout compile cleanly under the current Cocoa target
- GUI smoke path after the same menu/layout follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log still only showed the same macOS-side `LaunchServices` / connection-invalid warnings, not a FlatPaint crash in the new menu/layout path
- Build-script syntax check after the local-maintenance follow-up: `bash -n ./scripts/common.sh ./scripts/clean.sh ./scripts/build.sh ./scripts/build-release.sh ./scripts/build_app_bundle.sh`
- Result: passed; the new clean/build/release entry points are syntactically valid shell scripts
- Manual clean/build path check after the same follow-up: `./scripts/clean.sh && ./scripts/build.sh`
- Result: passed; the scripts removed generated outputs, rebuilt `flatpaint`, and refreshed both `flatpaint.app` and `dist/FlatPaint.app`
- Manual release path check after the same follow-up: `./scripts/build-release.sh`
- Result: passed; the scripts performed a clean rebuild, refreshed `dist/FlatPaint.app`, and emitted the stripped release binary at `dist/release/flatpaint`
- FPCUnit rebuild after the `Add Noise...` dialog follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 79 tests, adding noise helper coverage on top of the earlier blur, posterize, curves, brightness/contrast, levels, hue/saturation, save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Add Noise` dialog, helper unit, and updated main-form command path compile cleanly in the current Cocoa GUI target
- FPCUnit rebuild after the `Blur...` dialog follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 76 tests, adding blur helper coverage on top of the earlier posterize, curves, brightness/contrast, levels, hue/saturation, save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Blur` dialog, helper unit, and updated main-form command path compile cleanly in the current Cocoa GUI target
- FPCUnit rebuild after the `Posterize...` dialog follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 73 tests, adding posterize helper coverage on top of the earlier curves, brightness/contrast, levels, hue/saturation, save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Posterize` dialog, helper unit, and updated main-form command path compile cleanly in the current Cocoa GUI target
- FPCUnit rebuild after the `Curves...` dialog follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 70 tests, adding gamma-curve helper coverage on top of the earlier brightness/contrast, levels, hue/saturation, save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Curves` dialog, gamma helper unit, and updated main-form command path compile cleanly in the current Cocoa GUI target
- Linked `dist/FlatPaint.app` refresh attempt after the same follow-up: `/opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -o./dist/FlatPaint.app/Contents/MacOS/FlatPaint ./flatpaint.lpr`
- Result: failed at link time in the current local Cocoa toolchain path; direct GUI linking hit unresolved `UserNotifications` symbols first, then a `cocoawsextctrls.o` malformed-method-list linker failure after adding the framework, so compile-only Cocoa checks remain the stable gate for now
- FPCUnit rebuild after the `Brightness / Contrast...` command-surface follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 66 tests, adding brightness/contrast parameter-helper coverage on top of the earlier levels, hue/saturation, save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Brightness / Contrast` dialog, helper unit, and combined `Adjustments` menu route compile cleanly in the current Cocoa GUI target
- FPCUnit rebuild after the `Levels...` dialog follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 62 tests, adding `Levels` parameter-helper coverage on top of the earlier hue/saturation, save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Levels` dialog, its helper unit, and the updated main-form command path compile cleanly in the current Cocoa GUI target
- FPCUnit rebuild after the `Hue / Saturation...` dialog follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 58 tests, adding hue/saturation parameter-helper coverage on top of the earlier save-state, palette, viewport, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed; the new dedicated `Hue / Saturation` dialog and the updated main-form command path compile cleanly in the current Cocoa GUI target
- FPCUnit rebuild after the macOS-safety / paint-cache follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 54 tests, adding save-caption and dirty-document confirmation policy coverage on top of the earlier palette, viewport, zoom, resize, file-IO, and raster regressions
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed through the current Cocoa source build with the user-supplied Lazarus tree; the new dirty-document confirmation flow, save-caption policy, and direct prepared-bitmap copy path compile cleanly in the real GUI target
- FPCUnit rebuild after the close-query / shortcut-policy / project-config follow-up: `mkdir -p lib/tests dist/tests && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 55 tests, adding the edited-title-caption regression and the updated palette-shortcut policy coverage on top of the earlier save-caption, dirty-document confirmation, and command-surface checks
- GUI compile check after the same follow-up: `mkdir -p ./lib/gui-check ./dist/gui-check && /opt/homebrew/bin/fpc -Fu./src/core -Fu./src/app -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/widgetset -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/nonwin32 -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -Fu/Users/chrischan/Documents/workspace.nosync/lazarus/components/lazutils -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/include -Fi/Users/chrischan/Documents/workspace.nosync/lazarus/lcl/interfaces/cocoa -dCOCOA -FU./lib/gui-check -FE./dist/gui-check -Cn ./flatpaint.lpr`
- Result: passed again; the real Cocoa source path now compiles cleanly with the new form-close query hook, updated shortcut declarations, and the project-file macro path cleanup

## 2026-02-28
- FPCUnit rebuild after the toolbar / palette / status-bar layout follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 52 tests, adding palette non-overlap coverage plus adaptive status-bar partition coverage on top of the earlier freeform-shape, viewport-anchor, unified-open-filter, XCF, rounded-rectangle, gamma-curve, resize, levels, hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same UI-layout follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new status-layout helper, toolbar de-duplication, menu updates, and non-overlapping palette defaults compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log still only showed the same macOS-side `LaunchServices` / connection-invalid warnings, not a FlatPaint crash in the new UI-layout path
- FPCUnit rebuild after the `Freeform Shape` follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 48 tests, adding polygon-outline raster coverage plus freeform-shape tool-order coverage on top of the earlier viewport-anchor, unified-open-filter, XCF, rounded-rectangle, gamma-curve, resize, levels, hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same `Freeform Shape` follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new polygon primitive, tool metadata expansion, and GUI freeform-shape interaction path compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log still only showed the same macOS-side `LaunchServices` / connection-invalid warnings, not a FlatPaint crash in the new freeform-shape path
- FPCUnit rebuild after the viewport-anchor / wheel-zoom follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 46 tests, adding viewport-anchor math plus modifier-wheel zoom policy coverage on top of the earlier unified-open-filter, XCF, rounded-rectangle, gamma-curve, resize, levels, hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same viewport follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new viewport helper functions, status-bar zoom synchronization, mouse-wheel zoom handler, and cursor-anchored zoom-tool path compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log still only showed the same macOS-side `LaunchServices` / connection-invalid warnings, not a FlatPaint crash in the new viewport interaction path
- FPCUnit rebuild after the unified open-filter / XCF-import follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 40 tests, adding a minimal XCF project-load regression plus unified open-filter coverage on top of the earlier rounded-rectangle, gamma-curve, bilinear resize, resize-dialog helper, levels, hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same unified open-filter / XCF-import follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new XCF loader, unified dialog filters, and `.fpd`-as-layer flatten import path compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new compatibility-IO path
- FPCUnit rebuild after the rounded-rectangle tool follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 38 tests, adding a rounded-rectangle raster regression on top of the earlier gamma-curve, bilinear resize, resize-dialog helper, levels, hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same rounded-rectangle tool follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new rounded-rectangle raster primitive, tool metadata, preview overlay path, and GUI shape commit route compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new rounded-rectangle path
- FPCUnit rebuild after the `Curves...` and resize-flow follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 37 tests, adding shared-core gamma-curve coverage, bilinear resize blending coverage, and resize-dialog helper coverage on top of the earlier levels, hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and raster checks
- Lazarus project compile pass after the same `Curves...` and resize-flow follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new shared gamma-curve path, bilinear resize path, dedicated `Resize Image...` modal, and zoom-tool ladder unification compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new curves / resize path
- FPCUnit rebuild after the `Levels...` follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 32 tests, adding shared-core levels-remap coverage on top of the earlier hue/saturation, pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and raster checks
- Lazarus project compile pass after the same `Levels...` follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new shared levels method plus the GUI `Adjustments -> Levels...` route compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new levels path
- FPCUnit rebuild after the `Hue / Saturation` follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 31 tests, adding shared-core hue-shift / desaturation coverage on top of the earlier pixel-grid, zoom, ruler, utility-strip, new-image, file-IO, palette, history, and raster checks
- Lazarus project compile pass after the same `Hue / Saturation` follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new shared adjustment method plus the GUI `Adjustments -> Hue / Saturation...` route compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new adjustment path
- FPCUnit rebuild after the pixel-grid / toolbar view-toggle follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 30 tests, adding pixel-grid visibility-threshold coverage on top of the earlier zoom, ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same pixel-grid / toolbar view-toggle follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new view helper unit plus the menu/toolbar pixel-grid routes compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new pixel-grid path
- FPCUnit rebuild after the zoom-preset / toolbar zoom-chooser follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 27 tests, adding zoom-preset ladder / caption coverage on top of the earlier ruler, utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same zoom-preset / toolbar zoom-chooser follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new zoom helper unit plus the top-toolbar percentage chooser compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed the same macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new zoom-control path
- FPCUnit rebuild after the rulers / segmented-status-strip follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 24 tests, adding scale-step coverage for the new ruler helper unit on top of the earlier utility-strip, new-image, file-IO, palette, history, and core raster checks
- Lazarus project compile pass after the same rulers / segmented-status-strip follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new ruler helper unit, fixed ruler controls, `View -> Rulers` route, and segmented status-strip controls compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint >/tmp/flatpaint-smoke.log 2>&1 & pid=$!; sleep 2; kill $pid; wait $pid || true`
- Result: process launched and stayed up long enough for a timed smoke run; the captured log only showed macOS-side LaunchServices notification warnings, not a FlatPaint crash in the new ruler / status-strip path
- FPCUnit rebuild after the utility-strip / settings follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 21 tests, adding utility-strip metadata coverage plus a narrower tools-palette layout check on top of the earlier new-image, file-IO, palette, and history checks
- Lazarus project compile pass after the same utility-strip / settings follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new utility helper unit, settings dialog, top-right utility strip, and narrower tools palette compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- FPCUnit rebuild after the paint.net `New`-dialog follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local suite now runs 17 tests, adding `New`-dialog size-estimate and print-size conversion coverage on top of the earlier file-IO, palette, and history checks
- Lazarus project compile pass after the same `New`-dialog follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new modal `New` dialog unit and its main-form integration compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- FPCUnit rebuild after the file-IO coverage follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr`
- Result: passed and refreshed `dist/tests/flatpaint_tests`; the local suite now runs 14 tests, adding file-format sniffing coverage and a `TGA` round-trip regression on top of the earlier palette, toolbar, and adjustment checks
- Automated unit result after the same file-IO follow-up: `./dist/tests/flatpaint_tests --all`
- Result: passed with 14 tests; the new checks are `LoaderCanSniffPngWithUnknownExtension` and `TargaRoundTripPreservesPixels`
- Lazarus project compile pass after the same file-IO follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the expanded loader units, broader open/import filters, and UI-side IO error dialogs compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- FPCUnit rebuild after the visual-parity chrome follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr`
- Result: passed and refreshed `dist/tests/flatpaint_tests`; the local suite now runs 12 tests, adding compact palette-chrome metrics and drag-tint coverage on top of the earlier history-label and palette-layout checks
- Automated unit result after the same follow-up: `./dist/tests/flatpaint_tests --all`
- Result: passed with 12 tests; the new checks are `PaletteChromeMetricsStayCompact` and `PaletteDragTintDiffersFromRestTint`
- Lazarus project compile pass after the same visual-parity chrome follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the slimmer toolbar, palette title bars, darker chrome palette, and drag-state tint feedback compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- FPCUnit rebuild after the palette-visibility / labeled-history follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr`
- Result: passed and refreshed `dist/tests/flatpaint_tests`; the local suite now runs 10 tests, adding coverage for history labels plus palette shortcut and edge-snap metadata on top of the earlier toolbar, auto-level, and floating-palette checks
- Automated unit result after the same follow-up: `./dist/tests/flatpaint_tests --all`
- Result: passed with 10 tests; the new checks are `HistoryLabelsTrackUndoAndRedo`, `PaletteShortcutsFollowUtilityOrder`, and `SnapPaletteRectAlignsToNearbyWorkspaceEdges`
- Lazarus project compile pass after the same palette-visibility / labeled-history follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new `View` palette toggles, per-palette close buttons, reset-layout route, snap-on-drop behavior, and labeled history panel compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- FPCUnit rebuild after the floating-palette follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr && ./dist/tests/flatpaint_tests --all`
- Result: passed; the local FPCUnit suite now runs 7 tests, adding coverage for document history depth and default floating-palette layout metadata on top of the existing `Auto-Level` and tool-surface checks
- Lazarus project compile pass after the same floating-palette follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- First result: failed because the first palette-layout helper used a local variable named `BoundsRect`, which collides in this LCL context
- Fix applied: renamed the local variable to `PaletteRect` in `mainform.pas`
- Final result: passed end-to-end and relinked `flatpaint`; the new workspace panel, floating palettes, drag handlers, and history/count surfaces compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- FPCUnit rebuild after the `Zoom`-tool and menu-structure follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr`
- Result: passed and refreshed `dist/tests/flatpaint_tests` after adding explicit zoom-tool ordering coverage
- Automated unit result after the same follow-up: `./dist/tests/flatpaint_tests --all`
- Result: passed with 4 tests, adding `ZoomToolAppearsBeforePaintTools` on top of the earlier `Auto-Level` and tool-metadata checks
- Lazarus project compile pass after the same `Zoom`-tool and menu-structure follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new `Zoom` tool enum path, compact tool strip, and `Edit`-menu restructuring compile cleanly under the current Cocoa target
- FPCUnit harness bootstrap after the tool-strip and `Auto-Level` follow-up: `mkdir -p lib/tests dist/tests && /usr/local/bin/fpc -Fu./src/core -Fu./src/app -Fu./src/tests -Fu/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/fcl-fpcunit -FE./dist/tests -FU./lib/tests ./src/tests/flatpaint_tests.lpr`
- First result: failed because the initial test units used Pascal unit names that did not match their filenames, so the runner could not resolve `FPSurfaceTests`
- Fix applied: renamed the unit declarations to match `fpsurface_tests.pas` and `fpuihelpers_tests.pas`, and corrected the runner setup to use the global `DefaultFormat` / `DefaultRunAllTests` settings exposed by `consoletestrunner`
- Final result: passed and produced `dist/tests/flatpaint_tests`
- Automated unit result: `./dist/tests/flatpaint_tests --all`
- Result: passed with 3 tests (`AutoLevelStretchesVisiblePixelsOnly`, `ToolDisplayOrderStartsWithSelectionTools`, and `ToolMetadataIsCompleteForDisplayOrder`)
- Lazarus project compile pass after the compact tool-strip / print-route follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- First result: failed when the first print-dialog attempt assumed `TPrintDialog` was available from the currently imported LCL units
- Fix applied: kept the visible `Print` routes but switched the handler to a direct default-printer render path plus explicit error reporting instead of depending on the missing dialog type
- Final result: passed end-to-end and relinked `flatpaint`; the new tool metadata unit, compact tool strip, status-bar additions, tests, and print route all compile cleanly under the current Cocoa target
- GUI smoke path after the same follow-up: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- CLI rebuild after the `File -> Close` route follow-up: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`; this file-menu UI pass kept the shared build green without touching CLI behavior
- Lazarus project compile pass after the same `File -> Close` route follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the added `Close` handler and `Command+W` menu route in `mainform.pas` compile cleanly under the current Cocoa target
- CLI rebuild after the explicit clipboard-route follow-up: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`; this GUI-route pass kept the shared build green without changing CLI behavior
- Lazarus project compile pass after the same explicit clipboard-route follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the added `Edit` handlers in `mainform.pas` compile cleanly under the current Cocoa target
- CLI rebuild after the `View` / status-bar UI follow-up: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`; this UI-only pass kept the CLI build green without adding new core notes
- Lazarus project compile pass after the same `View` / status-bar UI follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the new `View` handlers and unit-aware status-bar path in `mainform.pas` compile cleanly under the current Cocoa target
- GUI smoke path: `./flatpaint` launched successfully from the workspace, the process stayed alive long enough to confirm startup via `ps`, and it was then terminated cleanly
- CLI rebuild after the `Auto-Level` adjustment expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`; the new `autolevel` and `autoleveldoc` command routes compile cleanly, and the build-note baseline remains at the existing `IndexOf` / `Move` notes
- Lazarus project compile pass after the same `Auto-Level` expansion: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: passed end-to-end and relinked `flatpaint`; the current project now completes the Cocoa build path under the repository's pinned flags, with the pre-existing hint/note set still present
- Manual CLI smoke path: `new`, `brush`, `autolevel`, `wrapdoc`, and `autoleveldoc` all completed and produced output files during the current adjustment follow-up pass
- CLI rebuild after the recent-file and effects expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FU./lib/cli ./src/cli/flatpaint_cli.lpr`
- First result: passed, but the initial effects pass showed repeated non-inlined helper-call notes in the new blur/convolution hot path
- Fix applied: folded the clamp helper into `PixelAtClamped` in `fpsurface.pas`
- Final result: passed again; the new CLI commands (`blur`, `sharpen`, `noise`, `outline`, plus native-document variants) compiled cleanly, and the effects-core build notes dropped back to the pre-existing `IndexOf` / `Move` baseline
- Lazarus project compile pass after the same recent-file, effects, and hot-path follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the new `Open Recent` persistence flow and `Effects` menu routes in `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after the `rot180` and `rot180doc` expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FU./lib/cli ./src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed the CLI after adding the 180-degree rotation commands
- Lazarus project compile pass after the same image/toolbar follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the new `Rotate 180` and color-toolbar actions in `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after the `MagicRead` cleanup check: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FU./lib/cli ./src/cli/flatpaint_cli.lpr`
- Result: passed, and the previous `MagicRead` initialization hint is gone from the CLI build path
- Lazarus project compile pass after the same `MagicRead` cleanup check: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: the application still compiles through project units, but Lazarus/FPC continues to emit the same `MagicRead` hint in this build path before stopping at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after the document-level invert/grayscale expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FU./lib/cli ./src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed the CLI after adding `invertdoc` and `grayscaledoc`
- Lazarus project compile pass after the same adjustments/tooling expansion: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the new gradient-tool and `Adjustments` routes in `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after the ellipse-shape core expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FU./lib/cli ./src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed the CLI after adding the shared `DrawEllipse` path and `ellipse` command
- Lazarus project compile pass after the same ellipse/tool-catalog expansion: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the expanded shape-tool path in `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- Lazarus project compile pass after the color-picker target fix: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units compiled again after the color-picker routing fix; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- Lazarus project compile pass after the canvas prepared-bitmap performance pass: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the updated cached paint path in `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- Lazarus project compile pass after the selection-aware clipboard / tool-option / `View` pass: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- First result: failed because `VK_EQUAL` and `VK_MINUS` are not defined in the current Lazarus/LCL target
- Fix applied: changed the zoom shortcuts to `Ord('=')` and `Ord('-')`
- Final result: application units, including the new shared-core merged-copy path and the latest `mainform.pas` updates, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- Lazarus project compile pass after the bound-path save follow-up: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the latest `Save` / `Save As` updates in `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after the GUI lasso/clipboard/transform pass: setup `mkdir -p lib/cli`, then `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FU./lib/cli ./src/cli/flatpaint_cli.lpr`
- First result: failed until the `-FU` output directory existed
- Final result: passed after creating `lib/cli`
- Lazarus project compile pass after the same GUI source expansion: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units, including the updated `mainform.pas`, compiled again; the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after clipboard/adjustment expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- First result: failed because a grouped default-parameter declaration in `fpdocument.pas` used an FPC-incompatible default-value form
- Fix applied: split the defaulted parameters into separate declarations
- Final result: passed and refreshed `dist/flatpaint_cli`
- Lazarus project compile pass after the GUI import/adjustment-source changes: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: project units, including the updated `mainform.pas`, compiled; the build still stops at the existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- Manual CLI smoke path: `brightness`, `extractrect`, `extractwand`, `posterize`, `wrapdoc`, and `pastedoc` all completed and produced output files during the current FPC rewrite pass
- Manual CLI smoke path: `brightnessdoc` and `exportlayerdoc` also completed and produced native-document and raster outputs during the same pass
- CLI rebuild after GUI-selection and native-project-flow source expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`
- Lazarus project compile pass after adding GUI selection tools and native `.fpd` open/save source: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units compiled again, and the build still stops only at the pre-existing Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after GUI magic-wand and layer-opacity-source expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`
- Lazarus project compile pass after the same source expansion: `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild flatpaint.lpi`
- Result: application units compiled again, and the build still stops only at the same Cocoa widgetset linker fault in `cocoawsextctrls.o`
- CLI rebuild after lasso/wand and native-layer-management expansion: `/usr/local/bin/fpc -Fu./src/core -Fu./src/cli -FE./dist -FU./dist src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`
- Manual CLI smoke path: `new`, `filllasso`, `fillwand`, `wrapdoc`, `addlayerdoc`, `movelayerdoc`, `renamelayerdoc`, `setvisibledoc`, and `deletelayerdoc` all completed and produced output files during the current FPC rewrite pass
- Core compile check after adding selection and native-document support: `fpc -Fu./src/core -FU./lib/corecheck -Cn ./src/core/fpdocument.pas`
- Result: completed after the selection/native-document changes
- CLI rebuild after adding selection and native-document commands: `fpc -Fu./src/core -FE./dist -o./dist/flatpaint_cli ./src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`
- Manual CLI smoke path: `wrapdoc` converted a raster file into a native `.fpd` document, and `exportdoc` converted that native document back to a raster export
- Core compile check for the expanded document transforms: `fpc -Fu./src/core -FU./lib/corecheck -Cn ./src/core/fpdocument.pas`
- First result: failed because `-FU` output directory did not exist
- Fix applied: created `lib/corecheck`
- Second result: failed because `Exchange` was not available in `fpdocument.pas`
- Fix applied: replaced the swap with an explicit temporary variable
- Final result: the direct `fpdocument.pas` compile completed
- CLI rebuild after the transform/adjustment expansion: `fpc -Fu./src/core -FE./dist -o./dist/flatpaint_cli ./src/cli/flatpaint_cli.lpr`
- Result: passed and refreshed `dist/flatpaint_cli`
- Free Pascal rewrite baseline: `fpc -Fu./src/core -FE./dist -o./dist/flatpaint_cli ./src/cli/flatpaint_cli.lpr`
- Result: passed and produced `dist/flatpaint_cli`
- Lazarus GUI build status: application units compile, but the final Cocoa app link currently fails inside `cocoawsextctrls.o` with a widgetset-level linker error (`malformed method list atom`)
- First attempt: `swift test` failed inside the workspace sandbox because SwiftPM sandbox/caches could not initialize correctly.
- Second attempt: `swift test` rerun outside the workspace sandbox after approval.
- Result: passed.
- Command: `swift test`
- Coverage in the second successful run: 4 `Testing` tests passed for the core document/layer/history/tool logic.
- Follow-up: added one foundation workflow smoke test that chains new document, layer edit, tool selection, merge, undo, and redo.
- Regression rerun: `swift test` passed again.
- Final coverage in this session: 5 `Testing` tests passed, including the current slice's foundation integration smoke path.
- Expanded regression suite: added core pixel workflow coverage for selection masks, move selection, move selected pixels, flood fill, gradient, color sampling, adjustments, effects, resize/crop/rotate, file round-trip, text stamping, recolor, and clone stamp.
- Added dedicated integration tests for disk-backed save/load/import/export and broader end-to-end regression workflows.
- Added clipboard integration coverage for copy/paste image workflows.
- Latest result: `swift test` passed with 17 tests across core and integration targets.
- Added interactive canvas support for direct drag-based editing with the selected tool; latest regression remains green.
- Startup smoke check: launched `./.build/debug/FlatPaintApp`, confirmed the process stayed alive until manually interrupted.
- Current latest automated result: `swift test` passed with 18 tests across core and integration targets.
- Added tool-option behavior coverage and layer property coverage.
- Latest automated result: `swift test` passed with 19 tests across core and integration targets.
- Added export-option coverage (PNG interlace, JPEG quality path, TIFF export, flatten-required guard) and compatibility import coverage for Krita package fallback import.
- Latest automated result: `swift test` passed with 21 tests across core and integration targets.
- Launch smoke re-run after file-dialog and settings changes: `./.build/debug/FlatPaintApp` stayed alive until explicitly terminated.
- Added coverage for contrast adjustment and selection-aware clipboard workflows (`Copy`/`Cut` bounded to the active selection).
- Latest automated result: `swift test` passed with 21 tests across core and integration targets after the clipboard and contrast changes.
- Launch smoke re-run after the latest menu/clipboard changes: `./.build/debug/FlatPaintApp` stayed alive and was interrupted cleanly from a TTY session.
- Added a shortcut-policy pass and corrected `Save` / `Save As` semantics and `Deselect` shortcut semantics in the app menu layer.
- Added unit coverage for document-title updates so the new native Save/Save As flow remains traceable in core behavior.
- Added integration coverage that `Open` on a raster file replaces the current workspace as a new document instead of silently importing as a layer.
- Latest automated result: `swift test` passed with 23 tests across core and integration targets after the shortcut/save/open-flow audit fixes.
- Added viewport-state coverage for rulers/pixel-grid/transparency toggles and core color-state coverage for swap/reset.
- Latest automated result: `swift test` passed with 24 tests across core and integration targets after the view-layer and color-panel work.
- UI-shell follow-up: added floating companion windows for tools/layers/history and replaced the text-only tool palette with icon-backed controls; latest automated regression remained green.
- Latest maintenance rerun: `swift test` passed with 24 tests, and `dist/FlatPaint.app` was refreshed as the current last-known-good bundle.
- Added viewport-fit coverage for large canvases and large-image open behavior; latest automated result is `swift test` passed with 26 tests.
- Post-audit regression rerun: `swift test` passed again with 26 tests after adding the UI parity audit docs and fixing an `@MainActor` cleanup compile error in the floating-palette coordinator.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` as the current last-known-good bundle after the successful regression pass.
- UI-parity follow-up rerun: `swift test` passed again with 26 tests after adding the dedicated floating `Colors` window and tightening the default workspace panel and toolbar composition.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the UI-parity follow-up changes.
- UI-parity refinement rerun: `swift test` passed again with 26 tests after replacing the embedded history block with a compact history dock card and adding cursor/sampled-color status-bar feedback.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the workspace refinement pass.
- Floating-palette persistence rerun: `swift test` passed again with 26 tests after adding per-palette frame autosave and reducing the docked color section to a summary/launcher.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the floating-palette persistence pass.
- Default-palette-launch rerun: `swift test` passed again with 26 tests after auto-opening the core palette set on first workspace appearance.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the default-palette-launch pass.
- Palette-proportion refinement rerun: `swift test` passed again with 26 tests after tightening floating palette sizes/default placement, moving zoom emphasis toward the status bar, adding `View` palette commands, and shrinking the docked layer surface to a summary/launcher.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the palette-proportion refinement pass.
- Single-instance-palette rerun: `swift test` passed again with 26 tests after converting the four utility palettes to single-instance `Window` scenes and adding `Command+1...4` shortcuts for them.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the single-instance-palette pass.
- Viewport-smoothness rerun: `swift test` passed with 27 tests after adding interactive no-history zoom, pinch-to-zoom wiring, and unit coverage that interactive zoom does not pollute history.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the viewport-smoothness pass.
- Workspace-overlap and render-cache rerun: `swift test` passed again with 27 tests after removing the docked tools/inspector overlays and caching both the composited raster and `NSImage` bridge for viewport-only changes.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the overlap and render-cache pass.
- Native-viewport rerun: `swift test` passed again with 27 tests after replacing the SwiftUI magnification path with an AppKit-backed trackpad viewport and tightening floating palette window ordering.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the native-viewport pass.
- Runtime smoke and diagnostics: launched `./.build/debug/FlatPaintApp`, confirmed the process stayed alive, captured a one-shot `sample` stack report, and queried system logs for the last minute; the stack sample showed the main thread idle in AppKit's event loop and the log query showed no app-specific crash/error lines in that window.
- Final verification rerun: `swift test` passed again with 27 tests after the viewport initialization follow-up.
- Final bundle refresh: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again as the latest known-good bundle.
- Final bundle smoke and sample: `open dist/FlatPaint.app` launched the packaged app, `sample` captured a live stack from the bundle process, and the main thread again sampled idle inside the normal AppKit event loop.
- UI-baseline-and-coverage rerun: `swift test` passed again with 34 tests after moving utility surfaces back into the main window, fixing launch-time default panel placement, and adding granular menu/tool-equivalent coverage.
- Current breakdown: 28 unit tests in `FlatPaintCoreTests` and 6 integration tests in `FlatPaintIntegrationTests`.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the default-layout and coverage pass.
- Menu-completeness rerun: `swift test` passed again with 75 tests after adding per-menu-item command coverage and explicit file-command integration coverage.
- Current breakdown: 66 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Coverage note: `View`, `Layers`, `Image`, `Edit`, `Adjustments`, and `Effects` commands now have individually named tests, while clipboard commands remain covered in a consolidated integration path to avoid global pasteboard concurrency hazards.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the menu-completeness pass.
- Tool-coverage rerun: `swift test` passed again with 83 tests after adding dedicated tool-equivalent tests for tool-catalog completeness, pan, crop, freeform lasso selection, and single-tap brush/pencil/eraser behavior.
- Current breakdown: 74 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Bundle refresh rerun: `./scripts/build_app_bundle.sh` rebuilt `dist/FlatPaint.app` again after the tool-coverage pass.
- Bundle smoke rerun: `open dist/FlatPaint.app` launched the packaged app successfully, the process was confirmed live via `ps`, and then it was terminated cleanly.
- Documentation baseline tightened: category-level command tests are now explicitly insufficient for UAT; remaining work must expand toward one visible command-surface item at a time as defined in `docs/COMMAND_SURFACE_BASELINE.md`.
- Command-surface follow-up rerun: `swift test` passed again with 87 tests after adding command-level coverage for `Select All`, `Invert Selection`, `Fill Selection`, `Zoom To Selection`, and extending the serialized clipboard integration path to cover `Paste into New Image`.
- Current breakdown: 78 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Command-surface follow-up rerun: `swift test` passed again with 93 tests after adding baseline zoom-tool coverage plus command-level coverage for `Rotate 90° Left`, `Rotate 180°`, `Flatten` (Image), `Black and White`, and `Sepia`.
- Current breakdown: 84 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Toolbar-route follow-up rerun: `swift test` passed again with 93 tests after wiring `New`, `Open`, `Save`, `Cut`, `Copy`, and `Paste` into the top toolbar; this pass did not add new tests, but it kept the shell changes inside the current regression envelope.
- Tabbed-shell rerun: `swift test` passed again with 98 tests after adding a multi-document workspace controller, tab-management coverage, and save-baseline tracking tests.
- Current breakdown: 89 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Bundle smoke rerun: `open dist/FlatPaint.app` launched the packaged app after the tabbed-shell pass; a delayed `ps` check confirmed the process was live, and it was then terminated cleanly.
- Tab-navigation rerun: `swift test` passed again with 99 tests after adding next/previous image-session navigation coverage in the workspace controller.
- Current breakdown: 90 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Shell follow-up rerun: `swift test` passed again with 99 tests after wiring `Open Recent`, `Save All Images`, `Print`, and a baseline tab context menu; this pass kept the UI-shell changes inside the current regression envelope without adding new tests.
- Bundle smoke rerun: `open dist/FlatPaint.app` launched the packaged app after the latest shell pass; a delayed `ps` check confirmed the process was live, and it was then terminated cleanly.
- Geometry-and-units rerun: `swift test` passed again with 101 tests after adding command-level coverage for image resampling and unit conversion behavior.
- Current breakdown: 92 unit tests in `FlatPaintCoreTests` and 9 integration tests in `FlatPaintIntegrationTests`.
- Selection-scope regression rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:281 E:0 F:0`, including new pipeline regressions `SwitchingFromSelectionToFillKeepsSelectionAndConstrainsScope` and `SwitchingFromSelectionToGradientKeepsSelectionAndConstrainsScope`.
- Build verification (2026-03-07): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Selection-vs-drawing policy rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:282 E:0 F:0` after adding `LineDragIgnoresExistingSelectionMask`, while existing fill/gradient selection-scope regressions remained green.
- Build verification (2026-03-07, post-policy split): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Selection-overlay dashed-border rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:283 E:0 F:0` after adding `SelectionOverlayUsesDashedBoundaryPattern`.
- Build verification (2026-03-07, dashed-border pass): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Selection lifecycle + P1-closure rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:302 E:0 F:0` after adding toolbar-route selection auto-deselect regressions and selection-family retention coverage.
- Build verification (2026-03-07, post-P1 closure sync): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Selection lifecycle classification rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:303 E:0 F:0` after switching to tool-family keep/clear behavior tests (`Fill/Gradient keep`, `Brush clears`, selection-family switch keeps).
- Build verification (2026-03-07, classified-selection pass): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Viewport edge-jitter clamp rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:305 E:0 F:0` after adding viewport scroll-range clamp helpers and routing them through zoom/pan/zoom-to-selection/update-canvas paths.
- Build verification (2026-03-07, edge-jitter fix): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Viewport edge-jitter phase-2 rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:309 E:0 F:0` after adding GIMP-style overscroll-delta gating (`ClampViewportScrollDelta` route) and zoom-limit no-op guards.
- Build verification (2026-03-07, edge-jitter phase-2): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.
- Viewport edge-jitter phase-3 rerun (2026-03-07): `bash ./scripts/run_tests_ci.sh` passed with `N:309 E:0 F:0` after adding native `NSScrollView` elasticity-disable bridge wiring for the canvas host.
- Build verification (2026-03-07, edge-jitter phase-3): `bash ./scripts/build.sh` completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (crop offset rebasing + overwrite regression hardening)
- Full CI verification after crop-offset rebasing fix and new regression tests (`CropWithOffsetLayerKeepsVisiblePixels`, `CropToSelectionWithOffsetLayerKeepsVisiblePixels`, `OpaquePencilStrokeOverwritesExistingPixel`): `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:344 E:0 F:0`, including all newly added document/pipeline regressions.
- Build verification after the same change window: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (zoom interpolation threshold follow-up)
- Full CI verification after extending display interpolation smoothing band (`DisplayInterpolationQualityForZoom` now keeps smoothing through `<=8x` and falls back to nearest above that): `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:344 E:0 F:0`.
- Build verification after the same change window: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (zoom local-loupe de-scope parity update)
- Full CI verification after removing runtime zoom local-loupe overlay invocation and restoring strict global-zoom semantics in `mainform`: `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:344 E:0 F:0`.
- Build verification after the same change window: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (selection-first bucket overwrite fix)
- Full CI verification after changing bucket behavior to use active-selection coverage directly when selection exists, and adding `FillWithinActiveSelectionOverwritesExistingPixels`: `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:345 E:0 F:0`.
- Build verification after the same change window: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (color wheel SV pane sync-latency fix)
- Full CI verification after splitting SV rendered-hue cache from hue-memory fallback and adding `fpcolorwheelhelpers_tests` (`2` tests): `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:347 E:0 F:0`.
- Build verification after the same change window: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (multi-format export options expansion + BMP behavior alignment)
- Initial CI run after broad export-option refactor: `bash ./scripts/run_tests_ci.sh`
- Result: failed with `N:351 E:0 F:1` (`TFPIOTests.BmpSaveHonorsBitsPerPixelAndRLEOptions` expected paletted/RLE BMP output that is intentionally clamped in the current true-color RGBA path).
- Follow-up CI run after test + UI alignment (`BMP` true-color-only assertions, PNG compressed-text option coverage): `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:351 E:0 F:0`.
- Build verification after the same change window: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.
- Final CI rerun after extending `Save As` extension aliases (`*.jpeg/*.tiff/*.pbm/*.pgm/*.ppm`) to match supported writer routes: `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:351 E:0 F:0`.
- Final build rerun after the same dialog-filter update: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.
- CI rerun after adding `PNM FullWidth` (16-bit P5/P6) option routing + regression assertion (`65535` max header): `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:351 E:0 F:0`.
- Build rerun after the same PNM option update: `bash ./scripts/build.sh`
- Result: completed successfully and refreshed `dist/FlatPaint.app`.

## 2026-03-08 (save-all multi-tab semantics + bundle metadata cleanup)
- Full CI verification after rewiring `Save All Images` to iterate dirty tabs and after parameterizing `Info.plist` metadata generation: `bash ./scripts/run_tests_ci.sh`
- Result: passed with `N:363 E:0 F:0`.
- Additional verification notes:
- `SaveAllDocumentsClick` now restores original active-tab focus after processing save attempts.
- Gate-C manual validation checklist is now codified in `docs/RELEASE_SMOKE_CHECKLIST.md`.
