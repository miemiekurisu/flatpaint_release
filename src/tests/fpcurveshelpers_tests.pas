unit fpcurveshelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPCurvesHelpers;

type
  TFPCurvesHelpersTests = class(TTestCase)
  published
    procedure GammaClampStaysWithinDocumentedRange;
    procedure ParseGammaTextFallsBackAndClamps;
    procedure SliderMappingRoundTripsToTwoDecimalPrecision;
    procedure GammaFormattingStaysStable;
  end;

implementation

procedure TFPCurvesHelpersTests.GammaClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', 0.1, ClampGammaValue(-1.0));
  AssertEquals('midpoint', 1.25, ClampGammaValue(1.25));
  AssertEquals('high clamp', 5.0, ClampGammaValue(9.0));
end;

procedure TFPCurvesHelpersTests.ParseGammaTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 1.75, ParseGammaText('1.75', 1.0));
  AssertEquals('invalid text fallback', 1.0, ParseGammaText('x', 1.0));
  AssertEquals('clamp after parse', 5.0, ParseGammaText('8.50', 1.0));
end;

procedure TFPCurvesHelpersTests.SliderMappingRoundTripsToTwoDecimalPrecision;
var
  Gamma: Double;
begin
  Gamma := SliderPositionToGamma(GammaToSliderPosition(2.34));
  AssertEquals('round trip', 2.34, Gamma);
  AssertEquals('slider low clamp', 10, GammaToSliderPosition(0.01));
  AssertEquals('slider high clamp', 500, GammaToSliderPosition(9.99));
end;

procedure TFPCurvesHelpersTests.GammaFormattingStaysStable;
begin
  AssertEquals('neutral', '1.00', FormatGammaText(1.0));
  AssertEquals('rounded', '2.35', FormatGammaText(2.345));
end;

initialization
  RegisterTest(TFPCurvesHelpersTests);

end.
