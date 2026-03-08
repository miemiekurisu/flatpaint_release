unit fpmagnifierhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, Types, FPMagnifierHelpers;

type
  TFPMagnifierHelpersTests = class(TTestCase)
  published
    procedure ComputeLoupeRectsRejectsInvalidInputs;
    procedure ComputeLoupeRectsClampInsideVisibleCanvas;
  end;

implementation

procedure TFPMagnifierHelpersTests.ComputeLoupeRectsRejectsInvalidInputs;
var
  SourceRect: TRect;
  DestRect: TRect;
begin
  AssertFalse(
    'negative image point should be rejected',
    ComputeZoomLoupeRects(Point(-1, 10), 1.0, 100, 80, 9, 120, 16, SourceRect, DestRect)
  );
  AssertFalse(
    'zero zoom scale should be rejected',
    ComputeZoomLoupeRects(Point(10, 10), 0.0, 100, 80, 9, 120, 16, SourceRect, DestRect)
  );
end;

procedure TFPMagnifierHelpersTests.ComputeLoupeRectsClampInsideVisibleCanvas;
var
  SourceRect: TRect;
  DestRect: TRect;
begin
  AssertTrue(
    'valid input should produce source and destination rectangles',
    ComputeZoomLoupeRects(Point(98, 78), 1.0, 100, 80, 9, 120, 16, SourceRect, DestRect)
  );
  AssertTrue('source rect should stay within document', SourceRect.Right <= 100);
  AssertTrue('source rect should stay within document', SourceRect.Bottom <= 80);
  AssertTrue('destination rect should stay inside visible canvas width', DestRect.Right <= 100);
  AssertTrue('destination rect should stay inside visible canvas height', DestRect.Bottom <= 80);
end;

initialization
  RegisterTest(TFPMagnifierHelpersTests);

end.
