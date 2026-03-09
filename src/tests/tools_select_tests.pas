unit tools_select_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, fpcunit, testregistry, FPDocument, FPSelection, FPColor;

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

initialization
  RegisterTest(TToolsSelectTests);

end.
