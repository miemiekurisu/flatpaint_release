unit fpblurhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPBlurHelpers;

type
  TFPBlurHelpersTests = class(TTestCase)
  published
    procedure BlurClampStaysWithinDocumentedRange;
    procedure ParseBlurTextFallsBackAndClamps;
    procedure SliderMappingMatchesDocumentedRange;
  end;

implementation

procedure TFPBlurHelpersTests.BlurClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', 1, ClampBlurRadius(0));
  AssertEquals('midpoint', 4, ClampBlurRadius(4));
  AssertEquals('high clamp', 64, ClampBlurRadius(999));
end;

procedure TFPBlurHelpersTests.ParseBlurTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 8, ParseBlurText('8', 2));
  AssertEquals('invalid text fallback', 2, ParseBlurText('x', 2));
  AssertEquals('clamp after parse', 64, ParseBlurText('100', 2));
end;

procedure TFPBlurHelpersTests.SliderMappingMatchesDocumentedRange;
begin
  AssertEquals('radius to slider', 10, BlurRadiusToSliderPosition(10));
  AssertEquals('slider to radius', 12, SliderPositionToBlurRadius(12));
  AssertEquals('slider low clamp', 1, SliderPositionToBlurRadius(0));
  AssertEquals('slider high clamp', 64, SliderPositionToBlurRadius(100));
end;

initialization
  RegisterTest(TFPBlurHelpersTests);

end.
