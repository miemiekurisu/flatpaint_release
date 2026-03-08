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
    procedure HasSelectionAndBoundsRectTrackCoverageChanges;
    procedure BoundsRectCacheInvalidatesAcrossTransformMutations;
    procedure TranslateToClipsAndOffsetsCoverage;
    procedure FeatherSoftensEdges;
    procedure InvertPreservesByteCoverage;
    procedure TransformPathsPreserveCoverageValues;
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

procedure TFPSelectionTests.HasSelectionAndBoundsRectTrackCoverageChanges;
var
  Selection: TSelectionMask;
  Bounds: TRect;
begin
  Selection := TSelectionMask.Create(6, 6);
  try
    AssertFalse('new selection starts empty', Selection.HasSelection);
    AssertEquals('empty bounds left', 0, Selection.BoundsRect.Left);
    AssertEquals('empty bounds right', 0, Selection.BoundsRect.Right);

    Selection.SetCoverage(1, 1, 255);
    Selection.SetCoverage(4, 3, 128);
    AssertTrue('non-zero coverage toggles has-selection', Selection.HasSelection);
    Bounds := Selection.BoundsRect;
    AssertEquals('bounds include minimum x', 1, Bounds.Left);
    AssertEquals('bounds include minimum y', 1, Bounds.Top);
    AssertEquals('bounds include maximum x + 1', 5, Bounds.Right);
    AssertEquals('bounds include maximum y + 1', 4, Bounds.Bottom);

    Selection.SetCoverage(1, 1, 0);
    Bounds := Selection.BoundsRect;
    AssertEquals('removing edge pixel shrinks bounds left', 4, Bounds.Left);
    AssertEquals('removing edge pixel shrinks bounds top', 3, Bounds.Top);
    AssertEquals('single remaining pixel keeps right edge', 5, Bounds.Right);
    AssertEquals('single remaining pixel keeps bottom edge', 4, Bounds.Bottom);

    Selection.SetCoverage(4, 3, 0);
    AssertFalse('clearing last selected pixel resets has-selection', Selection.HasSelection);
    Bounds := Selection.BoundsRect;
    AssertEquals('empty bounds left after clear', 0, Bounds.Left);
    AssertEquals('empty bounds top after clear', 0, Bounds.Top);
    AssertEquals('empty bounds right after clear', 0, Bounds.Right);
    AssertEquals('empty bounds bottom after clear', 0, Bounds.Bottom);
  finally
    Selection.Free;
  end;
end;

procedure TFPSelectionTests.BoundsRectCacheInvalidatesAcrossTransformMutations;
var
  Selection: TSelectionMask;
  Bounds: TRect;
begin
  Selection := TSelectionMask.Create(6, 4);
  try
    Selection.SelectRectangle(1, 1, 2, 2, scReplace);
    Bounds := Selection.BoundsRect;
    AssertEquals('initial bounds left', 1, Bounds.Left);
    AssertEquals('initial bounds right', 3, Bounds.Right);

    Selection.MoveBy(2, 0);
    Bounds := Selection.BoundsRect;
    AssertEquals('move updates bounds left', 3, Bounds.Left);
    AssertEquals('move updates bounds right', 5, Bounds.Right);

    Selection.FlipHorizontal;
    Bounds := Selection.BoundsRect;
    AssertEquals('flip updates bounds left', 1, Bounds.Left);
    AssertEquals('flip updates bounds right', 3, Bounds.Right);
  finally
    Selection.Free;
  end;
end;

procedure TFPSelectionTests.TranslateToClipsAndOffsetsCoverage;
var
  Source: TSelectionMask;
  Dest: TSelectionMask;
begin
  Source := TSelectionMask.Create(4, 3);
  Dest := TSelectionMask.Create(3, 2);
  try
    Source.SetCoverage(0, 0, 200);
    Source.SetCoverage(1, 1, 255);
    Source.TranslateTo(Dest, 1, 0);

    AssertEquals('translated destination x=1 keeps source x=0 coverage', 200, Dest.Coverage(1, 0));
    AssertEquals('translated destination x=2 keeps source x=1 coverage', 0, Dest.Coverage(2, 0));
    AssertEquals('translated destination clips out-of-range samples', 0, Dest.Coverage(0, 0));
    AssertEquals('translated destination maps shifted pixel', 255, Dest.Coverage(2, 1));
  finally
    Dest.Free;
    Source.Free;
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

procedure TFPSelectionTests.InvertPreservesByteCoverage;
var
  Selection: TSelectionMask;
begin
  Selection := TSelectionMask.Create(2, 1);
  try
    Selection.SetCoverage(0, 0, 64);
    Selection[1, 0] := True;

    Selection.Invert;

    AssertEquals('partial coverage inverts to 255-coverage', 191, Selection.Coverage(0, 0));
    AssertEquals('full coverage inverts to zero', 0, Selection.Coverage(1, 0));
  finally
    Selection.Free;
  end;
end;

procedure TFPSelectionTests.TransformPathsPreserveCoverageValues;
var
  Selection: TSelectionMask;
begin
  Selection := TSelectionMask.Create(3, 2);
  try
    Selection.SetCoverage(0, 0, 64);
    Selection.SetCoverage(2, 1, 200);

    Selection.FlipHorizontal;
    AssertEquals('flip keeps first sample coverage', 64, Selection.Coverage(2, 0));
    AssertEquals('flip keeps second sample coverage', 200, Selection.Coverage(0, 1));

    Selection.Rotate90Clockwise;
    AssertEquals('rotate keeps first sample coverage', 64, Selection.Coverage(1, 2));
    AssertEquals('rotate keeps second sample coverage', 200, Selection.Coverage(0, 0));
  finally
    Selection.Free;
  end;
end;

initialization
  RegisterTest(TFPSelectionTests);

end.
