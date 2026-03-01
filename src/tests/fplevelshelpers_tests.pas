unit fplevelshelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPLevelsHelpers;

type
  TFPLevelsHelpersTests = class(TTestCase)
  published
    procedure DefaultSettingsMatchIdentityLevels;
    procedure InputBoundsStayOrderedDuringNormalization;
    procedure OutputBoundsKeepIndependentClampRules;
    procedure ParseLevelTextFallsBackAndClamps;
  end;

implementation

procedure TFPLevelsHelpersTests.DefaultSettingsMatchIdentityLevels;
var
  Settings: TLevelsSettings;
begin
  Settings := DefaultLevelsSettings;
  AssertEquals('input low', 0, Settings.InputLow);
  AssertEquals('input high', 255, Settings.InputHigh);
  AssertEquals('output low', 0, Settings.OutputLow);
  AssertEquals('output high', 255, Settings.OutputHigh);
end;

procedure TFPLevelsHelpersTests.InputBoundsStayOrderedDuringNormalization;
var
  Settings: TLevelsSettings;
begin
  Settings.InputLow := 254;
  Settings.InputHigh := 10;
  Settings.OutputLow := 0;
  Settings.OutputHigh := 255;

  NormalizeLevels(Settings);

  AssertEquals('input low rebased to stay below high', 9, Settings.InputLow);
  AssertEquals('input high remains valid', 10, Settings.InputHigh);
end;

procedure TFPLevelsHelpersTests.OutputBoundsKeepIndependentClampRules;
var
  Settings: TLevelsSettings;
begin
  Settings.InputLow := 0;
  Settings.InputHigh := 255;
  Settings.OutputLow := 220;
  Settings.OutputHigh := 40;

  NormalizeLevels(Settings);

  AssertEquals('output low stays independent', 220, Settings.OutputLow);
  AssertEquals('output high stays independent', 40, Settings.OutputHigh);
  AssertEquals('output low clamps at low edge', 0, ClampOutputLow(-1));
  AssertEquals('output high clamps at high edge', 255, ClampOutputHigh(999));
end;

procedure TFPLevelsHelpersTests.ParseLevelTextFallsBackAndClamps;
begin
  AssertEquals('valid text', 24, ParseLevelText('24', 0, 0, 255));
  AssertEquals('invalid text fallback', 7, ParseLevelText('x', 7, 0, 255));
  AssertEquals('clamp after parse', 254, ParseLevelText('300', 0, 0, 254));
end;

initialization
  RegisterTest(TFPLevelsHelpersTests);

end.
