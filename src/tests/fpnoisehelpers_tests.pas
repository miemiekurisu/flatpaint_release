unit fpnoisehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPNoiseHelpers;

type
  TFPNoiseHelpersTests = class(TTestCase)
  published
    procedure NoiseClampStaysWithinDocumentedRange;
    procedure ParseNoiseTextFallsBackAndClamps;
    procedure SliderMappingMatchesDocumentedRange;
  end;

implementation

procedure TFPNoiseHelpersTests.NoiseClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', 0, ClampNoiseAmount(-1));
  AssertEquals('midpoint', 24, ClampNoiseAmount(24));
  AssertEquals('high clamp', 255, ClampNoiseAmount(999));
end;

procedure TFPNoiseHelpersTests.ParseNoiseTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 64, ParseNoiseText('64', 24));
  AssertEquals('invalid text fallback', 24, ParseNoiseText('x', 24));
  AssertEquals('clamp after parse', 255, ParseNoiseText('300', 24));
end;

procedure TFPNoiseHelpersTests.SliderMappingMatchesDocumentedRange;
begin
  AssertEquals('amount to slider', 48, NoiseAmountToSliderPosition(48));
  AssertEquals('slider to amount', 96, SliderPositionToNoiseAmount(96));
  AssertEquals('slider low clamp', 0, SliderPositionToNoiseAmount(-1));
  AssertEquals('slider high clamp', 255, SliderPositionToNoiseAmount(999));
end;

initialization
  RegisterTest(TFPNoiseHelpersTests);

end.
