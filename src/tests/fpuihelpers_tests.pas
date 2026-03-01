unit fpuihelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPDocument, FPUIHelpers;

type
  TFPUIHelpersTests = class(TTestCase)
  published
    procedure ToolDisplayOrderStartsWithSelectionTools;
    procedure ZoomToolAppearsBeforePaintTools;
    procedure FreeformShapeAppearsAfterBasicShapes;
    procedure ToolMetadataIsCompleteForDisplayOrder;
  end;

implementation

procedure TFPUIHelpersTests.ToolDisplayOrderStartsWithSelectionTools;
begin
  AssertEquals('first tool', Ord(tkSelectRect), Ord(PaintToolAtDisplayIndex(0)));
  AssertEquals('second tool', Ord(tkSelectEllipse), Ord(PaintToolAtDisplayIndex(1)));
  AssertEquals('third tool', Ord(tkSelectLasso), Ord(PaintToolAtDisplayIndex(2)));
  AssertEquals('fourth tool', Ord(tkMagicWand), Ord(PaintToolAtDisplayIndex(3)));
end;

procedure TFPUIHelpersTests.ZoomToolAppearsBeforePaintTools;
begin
  AssertTrue(
    'zoom should appear before fill in the display order',
    PaintToolDisplayIndex(tkZoom) < PaintToolDisplayIndex(tkFill)
  );
end;

procedure TFPUIHelpersTests.FreeformShapeAppearsAfterBasicShapes;
begin
  AssertTrue(
    'freeform shape should appear after ellipse shape',
    PaintToolDisplayIndex(tkFreeformShape) > PaintToolDisplayIndex(tkEllipseShape)
  );
end;

procedure TFPUIHelpersTests.ToolMetadataIsCompleteForDisplayOrder;
var
  ToolIndex: Integer;
  ToolKind: TToolKind;
begin
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
  begin
    ToolKind := PaintToolAtDisplayIndex(ToolIndex);
    AssertTrue('tool name missing', PaintToolName(ToolKind) <> '');
    AssertTrue('tool hint missing', PaintToolHint(ToolKind) <> '');
    AssertTrue('tool glyph missing', PaintToolGlyph(ToolKind) <> '');
    AssertEquals(
      'display index roundtrip',
      ToolIndex,
      PaintToolDisplayIndex(ToolKind)
    );
  end;
end;

initialization
  RegisterTest(TFPUIHelpersTests);

end.
