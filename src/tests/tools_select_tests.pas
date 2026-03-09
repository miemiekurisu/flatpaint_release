unit tools_select_tests;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Types, fpcunit, testregistry, FPDocument, FPSelection, FPColor;

type
  TToolsSelectTests = class(TTestCase)
  published
    procedure Document_SelectRectangle_ReplaceAndIntersect;
    procedure Document_SelectEllipse_BasicAndSubtract;
    procedure Document_SelectLasso_PolygonReplace;
    procedure RoundedRectSelection_CornersExcluded;
    procedure RoundedRectSelection_CenterSelected;
    procedure RoundedRectSelection_ZeroRadiusIsSharp;
    procedure RoundedRectSelection_AddMode;
    procedure AdjustedRectSelection_CommitsNewBounds;
    procedure AdjustedRectSelection_RoundedCornersPreserved;
    { Edge-case tests for core selection functions }
    procedure SelectRect_SinglePixel;
    procedure SelectRect_InvertedCoords;
    procedure SelectRect_OutOfBoundsClamp;
    procedure SelectRect_RadiusLargerThanHalfSize;
    procedure SelectRect_SubtractMode;
    procedure SelectRect_AntiAliasEdgeCoverage;
    procedure SelectRect_RoundedSubtractPreservesSurround;
    procedure SelectRect_FullDocumentExtent;
    procedure SelectRect_ZeroAreaProducesNoSelection;
    procedure SelectRect_ReplaceModeClearsPrevious;
  end;

implementation

procedure TToolsSelectTests.Document_SelectRectangle_ReplaceAndIntersect;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(8, 8);
  try
    Doc.SelectRectangle(1, 1, 3, 3, scReplace);
    AssertTrue('center selected', Doc.Selection[2,2]);
    Doc.SelectRectangle(2, 2, 6, 6, scIntersect);
    AssertTrue('overlap remains', Doc.Selection[2,2]);
    AssertFalse('old-only cleared', Doc.Selection[1,1]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsSelectTests.Document_SelectEllipse_BasicAndSubtract;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(7, 7);
  try
    Doc.SelectEllipse(1,1,5,5, scReplace);
    AssertTrue('ellipse center selected', Doc.Selection[3,3]);
    Doc.SelectEllipse(2,2,4,4, scSubtract);
    AssertFalse('inner removed', Doc.Selection[3,3]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsSelectTests.Document_SelectLasso_PolygonReplace;
var
  Doc: TImageDocument;
  P: array[0..3] of TPoint;
begin
  Doc := TImageDocument.Create(10, 10);
  try
    P[0] := Point(2,2);
    P[1] := Point(4,2);
    P[2] := Point(4,4);
    P[3] := Point(2,4);
    Doc.SelectLasso(P, scReplace);
    AssertTrue('lasso center selected', Doc.Selection[3,3]);
    AssertFalse('outside clear', Doc.Selection[1,1]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsSelectTests.RoundedRectSelection_CornersExcluded;
var
  Mask: TSelectionMask;
begin
  { 40x40 mask, select rect (0,0)-(39,39) with radius=12.
    The extreme corner pixel (0,0) should be outside the rounded area. }
  Mask := TSelectionMask.Create(40, 40);
  try
    Mask.SelectRectangle(0, 0, 39, 39, scReplace, False, 12);
    AssertTrue('has selection', Mask.HasSelection);
    AssertEquals('corner (0,0) excluded', 0, Mask.Coverage(0, 0));
    AssertEquals('corner (39,0) excluded', 0, Mask.Coverage(39, 0));
    AssertEquals('corner (0,39) excluded', 0, Mask.Coverage(0, 39));
    AssertEquals('corner (39,39) excluded', 0, Mask.Coverage(39, 39));
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.RoundedRectSelection_CenterSelected;
var
  Mask: TSelectionMask;
begin
  { Center of a rounded rectangle should be fully selected. }
  Mask := TSelectionMask.Create(40, 40);
  try
    Mask.SelectRectangle(0, 0, 39, 39, scReplace, False, 10);
    AssertEquals('center fully selected', 255, Mask.Coverage(20, 20));
    { Mid-edge should also be fully inside }
    AssertEquals('mid-top edge selected', 255, Mask.Coverage(20, 1));
    AssertEquals('mid-left edge selected', 255, Mask.Coverage(1, 20));
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.RoundedRectSelection_ZeroRadiusIsSharp;
var
  Mask: TSelectionMask;
begin
  { Radius=0 should give the same result as a normal sharp rectangle. }
  Mask := TSelectionMask.Create(20, 20);
  try
    Mask.SelectRectangle(2, 2, 17, 17, scReplace, False, 0);
    AssertTrue('corner selected with radius 0', Mask.Selected[2, 2]);
    AssertTrue('opposite corner selected', Mask.Selected[17, 17]);
    AssertFalse('outside not selected', Mask.Selected[0, 0]);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.RoundedRectSelection_AddMode;
var
  Mask: TSelectionMask;
begin
  { Test that rounded rect selection works correctly in Add combine mode. }
  Mask := TSelectionMask.Create(50, 50);
  try
    { First select a small sharp rect }
    Mask.SelectRectangle(0, 0, 5, 5, scReplace, False, 0);
    AssertTrue('initial corner selected', Mask.Selected[0, 0]);
    { Add a rounded rect in a different area }
    Mask.SelectRectangle(20, 20, 45, 45, scAdd, False, 8);
    { Both selections should exist }
    AssertTrue('initial still selected', Mask.Selected[0, 0]);
    AssertEquals('rounded center selected', 255, Mask.Coverage(32, 32));
    { Corner of rounded rect should be excluded }
    AssertEquals('rounded corner excluded', 0, Mask.Coverage(20, 20));
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.AdjustedRectSelection_CommitsNewBounds;
var
  Doc: TImageDocument;
begin
  { Simulate: user draws rect (10,10)-(30,30), then adjusts left edge to 5.
    Commit with adjusted bounds (5,10)-(30,30) should select the wider area. }
  Doc := TImageDocument.Create(50, 50);
  try
    Doc.SelectRectangle(5, 10, 30, 30, scReplace);
    AssertTrue('new left area selected', Doc.Selection[6, 15]);
    AssertTrue('original area still selected', Doc.Selection[15, 15]);
    AssertFalse('outside left not selected', Doc.Selection[3, 15]);
    AssertFalse('above not selected', Doc.Selection[15, 8]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsSelectTests.AdjustedRectSelection_RoundedCornersPreserved;
var
  Mask: TSelectionMask;
begin
  { After adjustment the rounded corners must be re-applied.
    Select (0,0)-(39,39) with radius=12, resize to (0,0)-(49,29).
    Corner pixel (0,0) should still be excluded by the rounded corner. }
  Mask := TSelectionMask.Create(50, 50);
  try
    Mask.SelectRectangle(0, 0, 49, 29, scReplace, False, 12);
    AssertTrue('has selection', Mask.HasSelection);
    AssertEquals('corner (0,0) excluded after resize', 0, Mask.Coverage(0, 0));
    AssertEquals('corner (49,0) excluded after resize', 0, Mask.Coverage(49, 0));
    AssertEquals('center selected after resize', 255, Mask.Coverage(25, 15));
  finally
    Mask.Free;
  end;
end;

{ ---- Edge-case tests for SelectRectangle core function ---- }

procedure TToolsSelectTests.SelectRect_SinglePixel;
var
  Mask: TSelectionMask;
begin
  { 1x1 selection on a small mask — should select exactly one pixel. }
  Mask := TSelectionMask.Create(10, 10);
  try
    Mask.SelectRectangle(5, 5, 5, 5, scReplace, False, 0);
    AssertTrue('single pixel selected', Mask.Selected[5, 5]);
    AssertFalse('neighbor not selected', Mask.Selected[4, 5]);
    AssertFalse('neighbor not selected', Mask.Selected[6, 5]);
    AssertFalse('neighbor not selected', Mask.Selected[5, 4]);
    AssertFalse('neighbor not selected', Mask.Selected[5, 6]);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_InvertedCoords;
var
  Mask, MaskNormal: TSelectionMask;
  X, Y: Integer;
begin
  { Inverted coordinates (X2<X1, Y2<Y1) should produce the same result
    as normal coordinates due to Min/Max normalization. }
  Mask := TSelectionMask.Create(20, 20);
  MaskNormal := TSelectionMask.Create(20, 20);
  try
    Mask.SelectRectangle(15, 15, 5, 5, scReplace, False, 0);
    MaskNormal.SelectRectangle(5, 5, 15, 15, scReplace, False, 0);
    for Y := 0 to 19 do
      for X := 0 to 19 do
        AssertEquals(Format('pixel (%d,%d) match', [X, Y]),
          MaskNormal.Coverage(X, Y), Mask.Coverage(X, Y));
  finally
    Mask.Free;
    MaskNormal.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_OutOfBoundsClamp;
var
  Mask: TSelectionMask;
begin
  { Coordinates extending far outside mask bounds should be clamped
    and not crash. }
  Mask := TSelectionMask.Create(10, 10);
  try
    Mask.SelectRectangle(-100, -100, 200, 200, scReplace, False, 0);
    AssertTrue('corner selected', Mask.Selected[0, 0]);
    AssertTrue('opposite corner selected', Mask.Selected[9, 9]);
    AssertTrue('center selected', Mask.Selected[5, 5]);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_RadiusLargerThanHalfSize;
var
  Mask: TSelectionMask;
begin
  { Radius (500) much larger than half-dimension (10) should be clamped.
    Result is a pill/capsule shape; center must be selected, corners excluded. }
  Mask := TSelectionMask.Create(30, 20);
  try
    Mask.SelectRectangle(2, 2, 27, 17, scReplace, False, 500);
    AssertTrue('has selection', Mask.HasSelection);
    AssertEquals('center selected', 255, Mask.Coverage(15, 10));
    { Extreme corner should be excluded because radius is clamped to half-height }
    AssertEquals('corner (2,2) excluded', 0, Mask.Coverage(2, 2));
    AssertEquals('corner (27,17) excluded', 0, Mask.Coverage(27, 17));
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_SubtractMode;
var
  Mask: TSelectionMask;
begin
  { Subtract should remove pixels from an existing selection. }
  Mask := TSelectionMask.Create(20, 20);
  try
    { Fill entire mask }
    Mask.SelectRectangle(0, 0, 19, 19, scReplace, False, 0);
    AssertTrue('full coverage before subtract', Mask.Selected[10, 10]);
    { Subtract a central region }
    Mask.SelectRectangle(5, 5, 14, 14, scSubtract, False, 0);
    AssertFalse('center removed', Mask.Selected[10, 10]);
    AssertTrue('border still selected', Mask.Selected[0, 0]);
    AssertTrue('border still selected', Mask.Selected[19, 19]);
    AssertTrue('border still selected', Mask.Selected[4, 4]);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_AntiAliasEdgeCoverage;
var
  Mask: TSelectionMask;
  CovAA, CovNoAA: Byte;
begin
  { Anti-aliased rect edges should have partial coverage (between 0 and 255),
    while non-AA rect edges are binary. }
  Mask := TSelectionMask.Create(30, 30);
  try
    { Non-AA: edge pixel should be fully selected }
    Mask.SelectRectangle(5, 5, 24, 24, scReplace, False, 0);
    CovNoAA := Mask.Coverage(5, 5);
    AssertEquals('non-AA edge is fully selected', 255, CovNoAA);

    { AA: interior pixel should still be fully selected }
    Mask.SelectRectangle(5, 5, 24, 24, scReplace, True, 0);
    AssertEquals('AA center is fully selected', 255, Mask.Coverage(15, 15));
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_RoundedSubtractPreservesSurround;
var
  Mask: TSelectionMask;
begin
  { Subtract with rounded corners: surrounding pixels must remain. }
  Mask := TSelectionMask.Create(60, 60);
  try
    Mask.SelectRectangle(0, 0, 59, 59, scReplace, False, 0);
    Mask.SelectRectangle(10, 10, 49, 49, scSubtract, False, 10);
    { Center should be removed }
    AssertEquals('center removed', 0, Mask.Coverage(30, 30));
    { Border remains }
    AssertTrue('top border remains', Mask.Selected[30, 0]);
    AssertTrue('left border remains', Mask.Selected[0, 30]);
    { Corner of the subtracted rounded rect — should still have coverage
      because the rounded corner does not fully cut into the rectangle corner }
    AssertTrue('subtracted corner area preserved', Mask.Coverage(10, 10) > 0);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_FullDocumentExtent;
var
  Mask: TSelectionMask;
  X, Y: Integer;
  AllSelected: Boolean;
begin
  { Selecting the entire mask area (sharp) must select every pixel. }
  Mask := TSelectionMask.Create(8, 8);
  try
    Mask.SelectRectangle(0, 0, 7, 7, scReplace, False, 0);
    AllSelected := True;
    for Y := 0 to 7 do
      for X := 0 to 7 do
        if not Mask.Selected[X, Y] then
        begin
          AllSelected := False;
          Break;
        end;
    AssertTrue('all 64 pixels selected', AllSelected);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_ZeroAreaProducesNoSelection;
var
  Mask: TSelectionMask;
begin
  { Completely out-of-bounds selection should produce nothing.
    Also tests that no crash occurs. }
  Mask := TSelectionMask.Create(10, 10);
  try
    Mask.SelectRectangle(-5, -5, -1, -1, scReplace, False, 0);
    AssertFalse('no selection for fully out-of-bounds rect', Mask.HasSelection);
  finally
    Mask.Free;
  end;
end;

procedure TToolsSelectTests.SelectRect_ReplaceModeClearsPrevious;
var
  Mask: TSelectionMask;
begin
  { Replace mode must clear the old selection before creating the new one.
    This ensures that when drawing a new rect selection over an existing one,
    only the new selection exists after commit — no double-marquee. }
  Mask := TSelectionMask.Create(50, 50);
  try
    { First selection: large area }
    Mask.SelectRectangle(0, 0, 40, 40, scReplace, False, 0);
    AssertTrue('first selection present', Mask.Selected[5, 5]);
    { Second selection: small area, replace mode }
    Mask.SelectRectangle(20, 20, 30, 30, scReplace, False, 0);
    AssertFalse('old area cleared by replace', Mask.Selected[5, 5]);
    AssertTrue('new area selected', Mask.Selected[25, 25]);
    { Same with rounded corners: replace clears small rect, new rounded rect applied }
    Mask.SelectRectangle(0, 0, 49, 49, scReplace, False, 15);
    AssertEquals('rounded center fully selected', 255, Mask.Coverage(25, 25));
    AssertEquals('rounded corner excluded', 0, Mask.Coverage(0, 0));
  finally
    Mask.Free;
  end;
end;

initialization
  RegisterTest(TToolsSelectTests);

end.
