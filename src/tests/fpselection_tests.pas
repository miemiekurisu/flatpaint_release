unit fpselection_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, fpcunit, testregistry, FPSelection;

type
  TFPSelectionTests = class(TTestCase)
  published
    procedure RectangleIntersectKeepsOnlyOverlap;
    procedure PolygonIntersectCanClearToEmpty;
    procedure FeatherSoftensEdges;
  end;

implementation

procedure TFPSelectionTests.RectangleIntersectKeepsOnlyOverlap;
var
  Selection: TSelectionMask;
begin
  Selection := TSelectionMask.Create(8, 8);
  try
    Selection.SelectRectangle(0, 0, 4, 4, scReplace);
    Selection.SelectRectangle(2, 2, 6, 6, scIntersect);

    AssertTrue('center overlap remains selected', Selection[3, 3]);
    AssertFalse('old-only area clears', Selection[1, 1]);
    AssertFalse('new-only area stays clear', Selection[5, 5]);
  finally
    Selection.Free;
  end;
end;

procedure TFPSelectionTests.PolygonIntersectCanClearToEmpty;
var
  Selection: TSelectionMask;
  Points: array[0..2] of TPoint;
begin
  Selection := TSelectionMask.Create(8, 8);
  try
    Selection.SelectRectangle(0, 0, 1, 1, scReplace);
    Points[0] := Point(6, 6);
    Points[1] := Point(7, 6);
    Points[2] := Point(6, 7);

    Selection.SelectPolygon(Points, scIntersect);

    AssertFalse('non-overlapping intersect clears selection', Selection.HasSelection);
  finally
    Selection.Free;
  end;
end;

procedure TFPSelectionTests.FeatherSoftensEdges;
var
  Selection: TSelectionMask;
begin
  Selection := TSelectionMask.Create(16, 16);
  try
    Selection.SelectRectangle(4, 4, 11, 11, scReplace);
    Selection.Feather(3);
    AssertEquals('center stays fully selected', 255, Selection.Coverage(7, 7));
    AssertTrue('interior at boundary softens', Selection.Coverage(4, 4) < 255);
    AssertTrue('outside near selection gets partial coverage', Selection.Coverage(3, 7) > 0);
    AssertEquals('far outside stays unselected', 0, Selection.Coverage(0, 0));
  finally
    Selection.Free;
  end;
end;

initialization
  RegisterTest(TFPSelectionTests);

end.
