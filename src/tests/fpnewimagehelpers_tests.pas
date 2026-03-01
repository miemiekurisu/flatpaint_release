unit fpnewimagehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPNewImageHelpers;

type
  TFPNewImageHelpersTests = class(TTestCase)
  published
    procedure EstimatedSizeMatchesRGBAFootprint;
    procedure PixelsConvertToPrintInches;
    procedure CentimeterPrintSizeConvertsBackToPixels;
  end;

implementation

procedure TFPNewImageHelpersTests.EstimatedSizeMatchesRGBAFootprint;
begin
  AssertEquals('rgba byte estimate', 1920000, EstimateNewImageBytes(800, 600));
end;

procedure TFPNewImageHelpersTests.PixelsConvertToPrintInches;
begin
  AssertEquals(
    '800 px at 96 dpi should be 8.33 inches',
    8.333333,
    PixelsToPrintValue(800, 96.0, pmInches),
    0.001
  );
end;

procedure TFPNewImageHelpersTests.CentimeterPrintSizeConvertsBackToPixels;
begin
  AssertEquals(
    '21.17 cm at 96 dpi should map near 800 px',
    800,
    PrintValueToPixels(21.166667, 96.0, pmCentimeters)
  );
end;

initialization
  RegisterTest(TFPNewImageHelpersTests);

end.
