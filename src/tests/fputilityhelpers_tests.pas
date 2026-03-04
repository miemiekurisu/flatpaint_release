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
    procedure PaletteWindowsKeepCommandShortcuts;
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

procedure TFPUtilityHelpersTests.PaletteWindowsKeepCommandShortcuts;
begin
  AssertEquals('tools shortcut', 'Cmd+1', UtilityCommandShortcutLabel(ucTools));
  AssertEquals('colors shortcut', 'Cmd+2', UtilityCommandShortcutLabel(ucColors));
  AssertEquals('layers shortcut', 'Cmd+3', UtilityCommandShortcutLabel(ucLayers));
  AssertEquals('history shortcut', 'Cmd+4', UtilityCommandShortcutLabel(ucHistory));
  AssertEquals('settings should stay without shortcut', '', UtilityCommandShortcutLabel(ucSettings));
end;

initialization
  RegisterTest(TFPUtilityHelpersTests);

end.
