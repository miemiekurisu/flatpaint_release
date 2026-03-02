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
    procedure PanAndPencilAppearInExpectedBands;
    procedure FreeformShapeAppearsAfterBasicShapes;
    procedure ToolMetadataIsCompleteForDisplayOrder;
    procedure CropTextCloneRecolorAppearInDisplayOrder;
    procedure TotalDisplayCountIsCorrect;
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

procedure TFPUIHelpersTests.PanAndPencilAppearInExpectedBands;
begin
  AssertTrue(
    'pan should sit after zoom',
    PaintToolDisplayIndex(tkPan) > PaintToolDisplayIndex(tkZoom)
  );
  AssertTrue(
    'pan should stay before fill',
    PaintToolDisplayIndex(tkPan) < PaintToolDisplayIndex(tkFill)
  );
  AssertTrue(
    'pencil should appear before brush',
    PaintToolDisplayIndex(tkPencil) < PaintToolDisplayIndex(tkBrush)
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

procedure TFPUIHelpersTests.CropTextCloneRecolorAppearInDisplayOrder;
begin
  AssertTrue('crop has display index', PaintToolDisplayIndex(tkCrop) >= 0);
  AssertTrue('text has display index', PaintToolDisplayIndex(tkText) >= 0);
  AssertTrue('clone stamp has display index', PaintToolDisplayIndex(tkCloneStamp) >= 0);
  AssertTrue('recolor has display index', PaintToolDisplayIndex(tkRecolor) >= 0);
  AssertTrue('text metadata complete', PaintToolName(tkText) <> '');
  AssertTrue('clone glyph present', PaintToolGlyph(tkCloneStamp) <> '');
  AssertTrue('recolor hint present', PaintToolHint(tkRecolor) <> '');
end;

procedure TFPUIHelpersTests.TotalDisplayCountIsCorrect;
begin
  AssertEquals('total tool display count', 23, PaintToolDisplayCount);
end;

initialization
  RegisterTest(TFPUIHelpersTests);

end.
