unit fpresizehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPResizeHelpers, FPSurface;

type
  TFPResizeHelpersTests = class(TTestCase)
  published
    procedure AspectLinkScalesPairedDimension;
    procedure AspectLinkClampsToAtLeastOnePixel;
    procedure ResampleModeCaptionsStayStable;
  end;

implementation

procedure TFPResizeHelpersTests.AspectLinkScalesPairedDimension;
begin
  AssertEquals('scale up height', 600, LinkedResizeValue(1600, 800, 300));
  AssertEquals('scale down width', 400, LinkedResizeValue(300, 600, 800));
end;

procedure TFPResizeHelpersTests.AspectLinkClampsToAtLeastOnePixel;
begin
  AssertEquals('minimum pixel', 1, LinkedResizeValue(0, 800, 600));
end;

procedure TFPResizeHelpersTests.ResampleModeCaptionsStayStable;
begin
  AssertEquals('nearest caption', 'Nearest Neighbor', ResampleModeCaption(rmNearestNeighbor));
  AssertEquals('bilinear caption', 'Bilinear', ResampleModeCaption(rmBilinear));
end;

initialization
  RegisterTest(TFPResizeHelpersTests);
end.
