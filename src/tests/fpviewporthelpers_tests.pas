unit fpviewporthelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpcunit, testregistry, FPViewportHelpers;

type
  TFPViewportHelpersTests = class(TTestCase)
  published
    procedure CenteredContentOffsetCentersSmallerCanvas;
    procedure CenteredContentOffsetClampsLargeCanvasToOrigin;
    procedure ZoomSliderMappingUsesZoomPresets;
    procedure ClampZoomScaleAppliesSupportedBounds;
    procedure ZoomScaleEffectivelyEqualUsesClampAndEpsilon;
    procedure DisplayInterpolationQualityTracksZoomBands;
    procedure ViewportImageCoordinateRespectsCanvasOffset;
    procedure ScrollPositionForAnchorKeepsAnchorStable;
    procedure MaxViewportScrollPositionUsesCanvasGeometry;
    procedure ClampViewportScrollPositionRespectsComputedRange;
    procedure ClampViewportScrollDeltaBlocksOverscrollDirections;
    procedure PannedScrollPositionMovesOppositeToDrag;
    procedure ZoomWheelUsesCrossEditorModifierRule;
    procedure WheelScrollPixelsMapsDeltaToStableStep;
  end;

implementation

procedure TFPViewportHelpersTests.CenteredContentOffsetCentersSmallerCanvas;
begin
  AssertEquals('center horizontally', 100, CenteredContentOffset(400, 200));
  AssertEquals('center with odd remainder', 49, CenteredContentOffset(101, 3));
end;

procedure TFPViewportHelpersTests.CenteredContentOffsetClampsLargeCanvasToOrigin;
begin
  AssertEquals('large content stays at origin', 0, CenteredContentOffset(200, 400));
  AssertEquals('negative inputs clamp', 0, CenteredContentOffset(-1, 10));
end;

procedure TFPViewportHelpersTests.ZoomSliderMappingUsesZoomPresets;
begin
  AssertEquals('slider min', 0, ZoomSliderMin);
  AssertTrue('slider max positive', ZoomSliderMax > ZoomSliderMin);
  AssertEquals('100% maps to slider position', 4, ZoomSliderPositionForScale(1.0));
  AssertEquals('slider roundtrip', 1.0, ZoomScaleForSliderPosition(ZoomSliderPositionForScale(1.0)));
end;

procedure TFPViewportHelpersTests.ClampZoomScaleAppliesSupportedBounds;
begin
  AssertEquals('lower bound clamp', 0.1, ClampZoomScale(0.01));
  AssertEquals('in-range scale unchanged', 1.5, ClampZoomScale(1.5));
  AssertEquals('upper bound clamp', 16.0, ClampZoomScale(32.0));
end;

procedure TFPViewportHelpersTests.ZoomScaleEffectivelyEqualUsesClampAndEpsilon;
begin
  AssertTrue('tiny delta should be treated as equal',
    ZoomScaleEffectivelyEqual(1.0, 1.0000005));
  AssertTrue('clamped lower-bound values should be equal',
    ZoomScaleEffectivelyEqual(0.02, 0.1));
  AssertFalse('materially different zoom values should not match',
    ZoomScaleEffectivelyEqual(1.0, 1.01));
end;

procedure TFPViewportHelpersTests.DisplayInterpolationQualityTracksZoomBands;
begin
  AssertEquals('downscale keeps high quality', 3, DisplayInterpolationQualityForZoom(0.5));
  AssertEquals('1x keeps high quality', 3, DisplayInterpolationQualityForZoom(1.0));
  AssertEquals('modest zoom uses medium quality', 2, DisplayInterpolationQualityForZoom(1.5));
  AssertEquals('larger zoom uses low quality', 1, DisplayInterpolationQualityForZoom(3.0));
  AssertEquals('8x still keeps low smoothing for AA visibility', 1, DisplayInterpolationQualityForZoom(8.0));
  AssertEquals('very deep zoom falls back to nearest', 0, DisplayInterpolationQualityForZoom(12.0));
end;

procedure TFPViewportHelpersTests.ViewportImageCoordinateRespectsCanvasOffset;
begin
  AssertEquals(
    'viewport coordinate subtracts centered canvas offset',
    50,
    ViewportImageCoordinate(0, 150, 100, 1.0, 200)
  );
  AssertEquals(
    'negative viewport side clamps to image origin',
    0,
    ViewportImageCoordinate(0, 40, 100, 1.0, 200)
  );
  AssertEquals(
    'overscroll clamps to image end',
    199,
    ViewportImageCoordinate(400, 350, 0, 1.0, 200)
  );
end;

procedure TFPViewportHelpersTests.ScrollPositionForAnchorKeepsAnchorStable;
begin
  AssertEquals(
    'centered 100% anchor stays at zero scroll',
    0,
    ScrollPositionForAnchor(49.0, 1.0, 50, 100)
  );
  AssertEquals(
    'zoomed anchor maps to positive scroll position',
    101,
    ScrollPositionForAnchor(100.0, 2.0, 0, 100)
  );
end;

procedure TFPViewportHelpersTests.MaxViewportScrollPositionUsesCanvasGeometry;
begin
  AssertEquals(
    'larger content computes positive range',
    300,
    MaxViewportScrollPosition(0, 800, 500)
  );
  AssertEquals(
    'centered smaller content has no scroll range',
    0,
    MaxViewportScrollPosition(100, 200, 400)
  );
  AssertEquals(
    'content offset contributes to computed max',
    220,
    MaxViewportScrollPosition(20, 500, 300)
  );
end;

procedure TFPViewportHelpersTests.ClampViewportScrollPositionRespectsComputedRange;
begin
  AssertEquals(
    'target below origin clamps at zero',
    0,
    ClampViewportScrollPosition(-10, 0, 800, 500)
  );
  AssertEquals(
    'in-range value stays unchanged',
    120,
    ClampViewportScrollPosition(120, 0, 800, 500)
  );
  AssertEquals(
    'value past max clamps to max',
    300,
    ClampViewportScrollPosition(500, 0, 800, 500)
  );
  AssertEquals(
    'small content always clamps to zero',
    0,
    ClampViewportScrollPosition(12, 120, 200, 500)
  );
end;

procedure TFPViewportHelpersTests.ClampViewportScrollDeltaBlocksOverscrollDirections;
begin
  AssertEquals(
    'negative scroll at origin is blocked',
    0,
    ClampViewportScrollDelta(0, -48, 0, 800, 500)
  );
  AssertEquals(
    'positive delta near max clamps to remaining room',
    40,
    ClampViewportScrollDelta(260, 60, 0, 800, 500)
  );
  AssertEquals(
    'positive scroll at max is blocked',
    0,
    ClampViewportScrollDelta(300, 48, 0, 800, 500)
  );
  AssertEquals(
    'in-range negative delta stays unchanged',
    -48,
    ClampViewportScrollDelta(120, -48, 0, 800, 500)
  );
end;

procedure TFPViewportHelpersTests.PannedScrollPositionMovesOppositeToDrag;
begin
  AssertEquals(
    'dragging right reduces horizontal scroll',
    84,
    PannedScrollPosition(96, 22, 10)
  );
  AssertEquals(
    'dragging left increases horizontal scroll',
    108,
    PannedScrollPosition(96, 4, 16)
  );
  AssertEquals(
    'scroll clamps at origin',
    0,
    PannedScrollPosition(6, 30, 10)
  );
end;

procedure TFPViewportHelpersTests.ZoomWheelUsesCrossEditorModifierRule;
begin
  AssertTrue('control key zooms viewport', ZoomWheelUsesViewportZoom([ssCtrl]));
  AssertTrue('meta key zooms viewport', ZoomWheelUsesViewportZoom([ssMeta]));
  AssertFalse('plain wheel keeps scrolling', ZoomWheelUsesViewportZoom([]));
  AssertFalse('shift alone does not become zoom', ZoomWheelUsesViewportZoom([ssShift]));
end;

procedure TFPViewportHelpersTests.WheelScrollPixelsMapsDeltaToStableStep;
begin
  AssertEquals('zero delta stays idle', 0, WheelScrollPixels(0, 48));
  AssertEquals('wheel up maps to negative scroll delta', -48, WheelScrollPixels(120, 48));
  AssertEquals('wheel down maps to positive scroll delta', 48, WheelScrollPixels(-120, 48));
  AssertEquals('larger wheel deltas scale by notches', 96, WheelScrollPixels(-240, 48));
end;

initialization
  RegisterTest(TFPViewportHelpersTests);
end.
