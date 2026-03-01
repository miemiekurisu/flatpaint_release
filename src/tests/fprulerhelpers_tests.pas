unit fprulerhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPRulerHelpers;

type
  TFPRulerHelpersTests = class(TTestCase)
  published
    procedure RulerMetricsStayCompact;
    procedure LowerZoomUsesLargerMajorSteps;
    procedure MinorStepTracksMajorStep;
  end;

implementation

procedure TFPRulerHelpersTests.RulerMetricsStayCompact;
begin
  AssertEquals('ruler thickness', 18, RulerThickness);
  AssertTrue('background should differ from border', RulerBackgroundColor <> RulerBorderColor);
  AssertTrue('ticks should differ from text', RulerTickColor <> RulerTextColor);
end;

procedure TFPRulerHelpersTests.LowerZoomUsesLargerMajorSteps;
begin
  AssertTrue('low zoom should widen major step', RulerMajorStep(0.25) > RulerMajorStep(1.0));
  AssertTrue('high zoom should tighten major step', RulerMajorStep(3.0) < RulerMajorStep(1.0));
end;

procedure TFPRulerHelpersTests.MinorStepTracksMajorStep;
var
  MajorStep: Integer;
  MinorStep: Integer;
begin
  MajorStep := RulerMajorStep(1.0);
  MinorStep := RulerMinorStep(1.0);
  AssertTrue('minor step should stay positive', MinorStep >= 1);
  AssertTrue('major step should be divisible by minor step', (MajorStep mod MinorStep) = 0);
  AssertTrue('minor step should be smaller than major step', MinorStep < MajorStep);
end;

initialization
  RegisterTest(TFPRulerHelpersTests);

end.
