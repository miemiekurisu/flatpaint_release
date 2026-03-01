unit fpbrightnesscontrasthelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPBrightnessContrastHelpers;

type
  TFPBrightnessContrastHelpersTests = class(TTestCase)
  published
    procedure DefaultSettingsStartNeutral;
    procedure BrightnessClampStaysWithinDocumentedRange;
    procedure ContrastClampStaysWithinDocumentedRange;
    procedure ParseAdjustmentTextFallsBackAndClamps;
  end;

implementation

procedure TFPBrightnessContrastHelpersTests.DefaultSettingsStartNeutral;
var
  Settings: TBrightnessContrastSettings;
begin
  Settings := DefaultBrightnessContrastSettings;
  AssertEquals('brightness', 0, Settings.Brightness);
  AssertEquals('contrast', 0, Settings.Contrast);
end;

procedure TFPBrightnessContrastHelpersTests.BrightnessClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', -255, ClampBrightnessDelta(-999));
  AssertEquals('midpoint', 12, ClampBrightnessDelta(12));
  AssertEquals('high clamp', 255, ClampBrightnessDelta(999));
end;

procedure TFPBrightnessContrastHelpersTests.ContrastClampStaysWithinDocumentedRange;
begin
  AssertEquals('low clamp', -255, ClampContrastAmount(-999));
  AssertEquals('midpoint', 24, ClampContrastAmount(24));
  AssertEquals('high clamp', 254, ClampContrastAmount(999));
end;

procedure TFPBrightnessContrastHelpersTests.ParseAdjustmentTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 18, ParseAdjustmentText('18', 0, -255, 255));
  AssertEquals('invalid text fallback', 7, ParseAdjustmentText('x', 7, -255, 255));
  AssertEquals('clamp after parse', -255, ParseAdjustmentText('-999', 0, -255, 255));
end;

initialization
  RegisterTest(TFPBrightnessContrastHelpersTests);

end.
