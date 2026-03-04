unit fpiconhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, FPIconHelpers, FPUIHelpers, FPUtilityHelpers;

type
  TFPIconHelpersTests = class(TTestCase)
  published
    procedure ToolIconsCoverEveryDisplayedTool;
    procedure UtilityIconsCoverEveryUtilityButton;
    procedure CommandIconsCoverMainToolbarAndLayerActions;
  end;

implementation

procedure TFPIconHelpersTests.ToolIconsCoverEveryDisplayedTool;
var
  ToolIndex: Integer;
begin
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
    AssertTrue(
      'tool icon should exist for display index ' + IntToStr(ToolIndex),
      ButtonIconSupported(
        PaintToolGlyph(PaintToolAtDisplayIndex(ToolIndex)),
        bicTool
      )
    );
end;

procedure TFPIconHelpersTests.UtilityIconsCoverEveryUtilityButton;
var
  CommandIndex: Integer;
begin
  for CommandIndex := 0 to UtilityCommandDisplayCount - 1 do
    AssertTrue(
      'utility icon should exist for display index ' + IntToStr(CommandIndex),
      ButtonIconSupported(
        UtilityCommandGlyph(UtilityCommandAtDisplayIndex(CommandIndex)),
        bicUtility
      )
    );
end;

procedure TFPIconHelpersTests.CommandIconsCoverMainToolbarAndLayerActions;
const
  CommandCaptions: array[0..18] of string = (
    'New', 'Open', 'Save', 'Cut', 'Copy', 'Paste', 'Undo', 'Redo', '+', '-',
    'Dup', 'Del', 'Mrg', 'Vis', 'Up', 'Dn', 'Fade', 'Flat', 'Props'
  );
var
  Index: Integer;
begin
  for Index := Low(CommandCaptions) to High(CommandCaptions) do
    AssertTrue(
      'command icon should exist for "' + CommandCaptions[Index] + '"',
      ButtonIconSupported(CommandCaptions[Index], bicCommand)
    );
end;

initialization
  RegisterTest(TFPIconHelpersTests);
end.
