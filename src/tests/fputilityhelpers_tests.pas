unit fputilityhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPUtilityHelpers;

type
  TFPUtilityHelpersTests = class(TTestCase)
  published
    procedure UtilityStripKeepsSixCommands;
    procedure UtilityStripStartsWithPaletteWindows;
    procedure UtilityHintsAreNonEmpty;
  end;

implementation

procedure TFPUtilityHelpersTests.UtilityStripKeepsSixCommands;
begin
  AssertEquals('utility command count', 6, UtilityCommandDisplayCount);
end;

procedure TFPUtilityHelpersTests.UtilityStripStartsWithPaletteWindows;
begin
  AssertEquals('tools first', Ord(ucTools), Ord(UtilityCommandAtDisplayIndex(0)));
  AssertEquals('history second', Ord(ucHistory), Ord(UtilityCommandAtDisplayIndex(1)));
  AssertEquals('layers third', Ord(ucLayers), Ord(UtilityCommandAtDisplayIndex(2)));
  AssertEquals('colors fourth', Ord(ucColors), Ord(UtilityCommandAtDisplayIndex(3)));
end;

procedure TFPUtilityHelpersTests.UtilityHintsAreNonEmpty;
var
  CommandKind: TUtilityCommandKind;
begin
  for CommandKind := Low(TUtilityCommandKind) to High(TUtilityCommandKind) do
    AssertTrue('utility hint missing', UtilityCommandHint(CommandKind) <> '');
end;

initialization
  RegisterTest(TFPUtilityHelpersTests);

end.
