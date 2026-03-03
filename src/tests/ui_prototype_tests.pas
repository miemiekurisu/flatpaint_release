unit ui_prototype_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Process, LazUTF8, FPPaletteHelpers, FPUtilityHelpers;

type
  TUIPrototypeTests = class(TTestCase)
  published
    procedure Test_Osascript_Available;
    procedure Test_LightTheme_UsesReadableContrast;
    procedure Test_UtilityButtons_StayCompact;
  end;

implementation

function ColorBrightness(AColor: LongInt): Integer;
begin
  Result := (
    (AColor and $FF) +
    ((AColor shr 8) and $FF) +
    ((AColor shr 16) and $FF)
  ) div 3;
end;

procedure TUIPrototypeTests.Test_Osascript_Available;
var
  P: TProcess;
  Cmd: string;
begin
  Cmd := '/usr/bin/osascript';
  if not FileExists(Cmd) then
    Cmd := 'osascript';

  P := TProcess.Create(nil);
  try
    P.Executable := Cmd;
    P.Parameters.Add('-e');
    P.Parameters.Add('return true');
    P.Options := P.Options + [poWaitOnExit];
    P.Execute;
    AssertEquals('osascript should exit 0', 0, P.ExitStatus);
  finally
    P.Free;
  end;
end;

procedure TUIPrototypeTests.Test_LightTheme_UsesReadableContrast;
begin
  AssertTrue(
    'chrome text should stay darker than the toolbar background',
    ColorBrightness(ChromeTextColor) < ColorBrightness(ToolbarBackgroundColor)
  );
  AssertTrue(
    'muted text should stay darker than the toolbar background',
    ColorBrightness(ChromeMutedTextColor) < ColorBrightness(ToolbarBackgroundColor)
  );
  AssertTrue(
    'divider should stay darker than the toolbar background',
    ColorBrightness(ChromeDividerColor) < ColorBrightness(ToolbarBackgroundColor)
  );
  AssertTrue(
    'light theme still needs a visible drag tint',
    PaletteSurfaceColor(pkLayers, True) <> PaletteSurfaceColor(pkLayers, False)
  );
end;

procedure TUIPrototypeTests.Test_UtilityButtons_StayCompact;
var
  Index: Integer;
  Command: TUtilityCommandKind;
  Glyph: string;
begin
  for Index := 0 to UtilityCommandDisplayCount - 1 do
  begin
    Command := UtilityCommandAtDisplayIndex(Index);
    Glyph := UtilityCommandGlyph(Command);
    AssertTrue('utility glyph should be compact', UTF8Length(Glyph) <= 1);
    AssertTrue('utility hint should stay present', UtilityCommandHint(Command) <> '');
  end;
end;

initialization
  RegisterTest(TUIPrototypeTests);

end.
