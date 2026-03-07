unit fpzoomhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPZoomHelpers;

type
  TFPZoomHelpersTests = class(TTestCase)
  published
    procedure ZoomPresetsStayOrdered;
    procedure ZoomStepFunctionsUsePresetLadder;
    procedure ZoomCaptionsStayHumanReadable;
    procedure QuickSizeToggleUsesDeterministicThreshold;
  end;

implementation

procedure TFPZoomHelpersTests.ZoomPresetsStayOrdered;
var
  Index: Integer;
begin
  AssertTrue('need multiple presets', ZoomPresetCount > 3);
  for Index := 1 to ZoomPresetCount - 1 do
    AssertTrue(
      'presets must increase',
      ZoomPresetScale(Index) > ZoomPresetScale(Index - 1)
    );
end;

procedure TFPZoomHelpersTests.ZoomStepFunctionsUsePresetLadder;
begin
  AssertEquals('zoom in from 100%', 1.5, NextZoomInScale(1.0));
  AssertEquals('zoom out from 100%', 0.667, NextZoomOutScale(1.0));
  AssertEquals('nearest preset for 90%', 4, NearestZoomPresetIndex(0.9));
end;

procedure TFPZoomHelpersTests.ZoomCaptionsStayHumanReadable;
begin
  AssertEquals('100% caption', '100%', ZoomCaptionForScale(1.0));
  AssertEquals('66.7% preset caption', '66.7%', ZoomPresetCaption(3));
  AssertEquals('1600% caption', '1600%', ZoomCaptionForScale(16.0));
end;

procedure TFPZoomHelpersTests.QuickSizeToggleUsesDeterministicThreshold;
begin
  AssertTrue('exact actual size should toggle to fit', QuickSizeToggleTargetsFit(1.0));
  AssertTrue('near-actual value inside epsilon should toggle to fit', QuickSizeToggleTargetsFit(1.009));
  AssertFalse('zoomed-in state should toggle to actual size', QuickSizeToggleTargetsFit(1.05));
  AssertFalse('zoomed-out state should toggle to actual size', QuickSizeToggleTargetsFit(0.9));
end;

initialization
  RegisterTest(TFPZoomHelpersTests);

end.
