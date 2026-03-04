unit tools_move_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPColor, FPDocument, FPSelection, FPSurface;

type
  TToolsMoveTests = class(TTestCase)
  published
    procedure MoveSelectionBy_ShiftsSelectionMask;
    procedure MoveSelectedPixelsBy_MovesPixelsAndSelection;
  end;

implementation

procedure TToolsMoveTests.MoveSelectionBy_ShiftsSelectionMask;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(4, 3);
  try
    // select a single pixel and move the selection
    Doc.SelectRectangle(1, 1, 1, 1, scReplace);
    AssertTrue('selection set at (1,1)', Doc.Selection[1, 1]);
    Doc.MoveSelectionBy(1, 0);
    AssertFalse('original cleared at (1,1)', Doc.Selection[1, 1]);
    AssertTrue('moved to (2,1)', Doc.Selection[2, 1]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsMoveTests.MoveSelectedPixelsBy_MovesPixelsAndSelection;
var
  Doc: TImageDocument;
  C: TRGBA32;
begin
  Doc := TImageDocument.Create(4, 2);
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    // paint one pixel, select it, move pixels by +1 x
    C := RGBA(255, 0, 0, 255);
    Doc.ActiveLayer.Surface[1, 0] := C;
    Doc.SelectRectangle(1, 0, 1, 0, scReplace);

    Doc.MoveSelectedPixelsBy(1, 0);

    // original location cleared
    AssertTrue('source cleared', RGBAEqual(Doc.ActiveLayer.Surface[1, 0], TransparentColor));
    // destination has the pixel
    AssertTrue('destination has moved pixel', RGBAEqual(Doc.ActiveLayer.Surface[2, 0], C));
    // selection moved as well
    AssertFalse('selection no longer at source', Doc.Selection[1, 0]);
    AssertTrue('selection moved to dest', Doc.Selection[2, 0]);
  finally
    Doc.Free;
  end;
end;

initialization
  RegisterTest(TToolsMoveTests);

end.
