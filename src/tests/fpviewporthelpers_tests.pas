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
    procedure ViewportImageCoordinateRespectsCanvasOffset;
    procedure ScrollPositionForAnchorKeepsAnchorStable;
    procedure PannedScrollPositionMovesOppositeToDrag;
    procedure ZoomWheelUsesCrossEditorModifierRule;
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

initialization
  RegisterTest(TFPViewportHelpersTests);
end.
