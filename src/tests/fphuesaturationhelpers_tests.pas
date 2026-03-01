unit fphuesaturationhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPHueSaturationHelpers;

type
  TFPHueSaturationHelpersTests = class(TTestCase)
  published
    procedure HueClampStaysWithinDocumentedRange;
    procedure SaturationClampStaysWithinDocumentedRange;
    procedure ParseDeltaTextFallsBackAndClamps;
  end;

implementation

procedure TFPHueSaturationHelpersTests.HueClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', -180, ClampHueDelta(-999));
  AssertEquals('midpoint', 24, ClampHueDelta(24));
  AssertEquals('high clamp', 180, ClampHueDelta(999));
end;

procedure TFPHueSaturationHelpersTests.SaturationClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', -100, ClampSaturationDelta(-999));
  AssertEquals('midpoint', 12, ClampSaturationDelta(12));
  AssertEquals('high clamp', 100, ClampSaturationDelta(999));
end;

procedure TFPHueSaturationHelpersTests.ParseDeltaTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 18, ParseDeltaText('18', 0, -100, 100));
  AssertEquals('invalid text fallback', 7, ParseDeltaText('x', 7, -100, 100));
  AssertEquals('clamp after parse', 100, ParseDeltaText('240', 0, -100, 100));
end;

initialization
  RegisterTest(TFPHueSaturationHelpersTests);

end.
