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

initialization
  RegisterTest(TFPSelectionTests);

end.
