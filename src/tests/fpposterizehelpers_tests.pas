unit fpposterizehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPPosterizeHelpers;

type
  TFPPosterizeHelpersTests = class(TTestCase)
  published
    procedure PosterizeClampStaysWithinDocumentedRange;
    procedure ParsePosterizeTextFallsBackAndClamps;
    procedure SliderMappingMatchesDocumentedRange;
  end;

implementation

procedure TFPPosterizeHelpersTests.PosterizeClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', 2, ClampPosterizeLevels(-1));
  AssertEquals('midpoint', 6, ClampPosterizeLevels(6));
  AssertEquals('high clamp', 64, ClampPosterizeLevels(999));
end;

procedure TFPPosterizeHelpersTests.ParsePosterizeTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 12, ParsePosterizeText('12', 6));
  AssertEquals('invalid text fallback', 6, ParsePosterizeText('x', 6));
  AssertEquals('clamp after parse', 64, ParsePosterizeText('99', 6));
end;

procedure TFPPosterizeHelpersTests.SliderMappingMatchesDocumentedRange;
begin
  AssertEquals('levels to slider', 14, PosterizeLevelsToSliderPosition(14));
  AssertEquals('slider to levels', 20, SliderPositionToPosterizeLevels(20));
  AssertEquals('slider low clamp', 2, SliderPositionToPosterizeLevels(0));
  AssertEquals('slider high clamp', 64, SliderPositionToPosterizeLevels(100));
end;

initialization
  RegisterTest(TFPPosterizeHelpersTests);

end.
