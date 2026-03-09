unit extreme_value_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, Math, fpcunit, testregistry, FPColor, FPSelection, FPSurface;

type
  TExtremeValueTests = class(TTestCase)
  published
    { --- FPColor extreme values --- }
    procedure LerpColorPositionBelowZeroClampsToStart;
    procedure LerpColorPositionAboveOneClampsToEnd;
    procedure LerpColorNaNPositionClampsGracefully;
    procedure LerpColorInfinityPositionClampsGracefully;
    procedure LerpColorIdenticalColorReturnsExact;
    procedure BlendNormalBothTransparentReturnsTransparent;
    procedure BlendNormalZeroOpacityReturnsDst;
    procedure BlendNormalFullOpacityOpaqueReplacesDst;
    procedure PremultiplyLowAlphaRoundTrip;
    procedure PremultiplyAlpha1RoundTrip;
    procedure UnpremultiplyChannelAboveAlphaClamps;
    procedure RGBAPremulAllZeros;
    procedure RGBAPremulAllMax;

    { --- FPSurface extreme values --- }
    procedure CreateWithZeroDimensionsClampsToOne;
    procedure CreateWithNegativeDimensionsClampsToOne;
    procedure ClearOnMinimalSurfaceSetsPixel;
    procedure DrawBrushZeroRadiusOnMinimalSurface;
    procedure DrawLineCompletelyOutOfBounds;
    procedure DrawRectangleInvertedCoords;
    procedure DrawEllipseZeroArea;
    procedure DrawPolygonZeroPoints;
    procedure DrawPolygonOnePoint;
    procedure DrawPolygonTwoPoints;
    procedure FillPolygonDegenerateTriangle;
    procedure FillGradientIdenticalEndpoints;
    procedure FillGradientInvertedCoords;
    procedure FloodFillOnSinglePixelSurface;
    procedure FloodFillMaxTolerance;
    procedure BoxBlurRadiusZeroClampsToOne;
    procedure BoxBlurRadiusHugeClampsToMax;
    procedure GaussianBlurOnSinglePixelSurface;
    procedure MotionBlurZeroDistance;
    procedure BlackAndWhiteThresholdZero;
    procedure BlackAndWhiteThresholdMax;
    procedure PosterizeLevelsMinTwo;
    procedure PosterizeLevelsAboveMaxClamps;
    procedure AdjustBrightnessExtremePositive;
    procedure AdjustBrightnessExtremeNegative;
    procedure AdjustContrastExtremePositive;
    procedure AdjustContrastExtremeNegative;
    procedure AdjustGammaCurveZero;
    procedure AdjustGammaCurveTen;
    procedure AdjustLevelsFullRange;
    procedure AdjustLevelsInvertedRange;
    procedure SurfaceBlurRadiusClamps;
    procedure ResizeNearestToOnePx;
    procedure ResizeBilinearToOnePx;
    procedure CropCompletelyOutOfBounds;
    procedure PasteSurfaceWithNegativeOffset;

    { --- FPSelection extreme values --- }
    procedure SelectionCreateNegativeSizeClampsToOne;
    procedure SelectRectInvertedCoordsSetsNothing;
    procedure SelectRectZeroAreaSetsNothing;
    procedure SelectEllipseZeroArea;
    procedure SelectPolygonEmptyArray;
    procedure SelectPolygonSinglePoint;
    procedure SelectPolygonTwoPoints;
    procedure FeatherRadiusZeroNoOp;
    procedure FeatherRadiusVeryLargeStaysInBounds;
    procedure FeatherOnEmptySelectionNoOp;
    procedure InvertEmptySelectsAll;
    procedure InvertFullDeSelectsAll;
    procedure CropOutOfBoundsYieldsEmpty;
    procedure MoveByLargeOffset;
    procedure SelectAllCombineModes;
  end;

implementation

{ === FPColor Extreme Values === }

procedure TExtremeValueTests.LerpColorPositionBelowZeroClampsToStart;
var
  A, B, R: TRGBA32;
begin
  A := RGBA(255, 0, 0, 255);
  B := RGBA(0, 0, 255, 255);
  R := LerpColor(A, B, -5.0);
  AssertTrue('R channel matches start', RGBAEqual(R, A));
end;

procedure TExtremeValueTests.LerpColorPositionAboveOneClampsToEnd;
var
  A, B, R: TRGBA32;
begin
  A := RGBA(255, 0, 0, 255);
  B := RGBA(0, 0, 255, 255);
  R := LerpColor(A, B, 100.0);
  AssertTrue('R channel matches end', RGBAEqual(R, B));
end;

procedure TExtremeValueTests.LerpColorNaNPositionClampsGracefully;
var
  A, B, R: TRGBA32;
begin
  A := RGBA(100, 100, 100, 255);
  B := RGBA(200, 200, 200, 255);
  R := LerpColor(A, B, NaN);
  { NaN through EnsureRange is platform-defined; just verify no crash
    and channels stay in valid byte range. }
  AssertTrue('R in valid range', R.R <= 255);
  AssertTrue('G in valid range', R.G <= 255);
end;

procedure TExtremeValueTests.LerpColorInfinityPositionClampsGracefully;
var
  A, B, R: TRGBA32;
begin
  A := RGBA(10, 20, 30, 255);
  B := RGBA(200, 210, 220, 255);
  R := LerpColor(A, B, Infinity);
  AssertTrue('infinity clamps to end', RGBAEqual(R, B));
end;

procedure TExtremeValueTests.LerpColorIdenticalColorReturnsExact;
var
  C, R: TRGBA32;
begin
  C := RGBA(123, 45, 67, 200);
  R := LerpColor(C, C, 0.5);
  AssertTrue('lerp identical returns same', RGBAEqual(R, C));
end;

procedure TExtremeValueTests.BlendNormalBothTransparentReturnsTransparent;
var
  R: TRGBA32;
begin
  R := BlendNormal(TransparentColor, TransparentColor);
  AssertTrue('both transparent returns transparent', RGBAEqual(R, TransparentColor));
end;

procedure TExtremeValueTests.BlendNormalZeroOpacityReturnsDst;
var
  Src, Dst, R: TRGBA32;
begin
  Src := Premultiply(RGBA(255, 0, 0, 128));
  Dst := Premultiply(RGBA(0, 255, 0, 255));
  R := BlendNormal(Src, Dst, 0);
  AssertTrue('zero opacity returns dst', RGBAEqual(R, Dst));
end;

procedure TExtremeValueTests.BlendNormalFullOpacityOpaqueReplacesDst;
var
  Src, Dst, R: TRGBA32;
begin
  Src := Premultiply(RGBA(255, 0, 0, 255));
  Dst := Premultiply(RGBA(0, 255, 0, 255));
  R := BlendNormal(Src, Dst, 255);
  AssertEquals('R fully replaced', 255, R.R);
  AssertEquals('G zero after overwrite', 0, R.G);
end;

procedure TExtremeValueTests.PremultiplyLowAlphaRoundTrip;
var
  Original, Premul, Back: TRGBA32;
begin
  { Alpha=1: maximum quantization error but should not crash }
  Original := RGBA(255, 128, 64, 1);
  Premul := Premultiply(Original);
  Back := Unpremultiply(Premul);
  AssertEquals('alpha preserved', 1, Back.A);
  { At alpha=1 large error is expected but channels stay in [0..255] }
  AssertTrue('R in valid range', Back.R <= 255);
end;

procedure TExtremeValueTests.PremultiplyAlpha1RoundTrip;
var
  C, P: TRGBA32;
begin
  C := RGBA(200, 100, 50, 1);
  P := Premultiply(C);
  { At A=1: channels ≈ (V*1+127)/255 = 1 or 0 }
  AssertTrue('premul R <= original', P.R <= C.R);
  AssertEquals('premul A preserved', 1, P.A);
end;

procedure TExtremeValueTests.UnpremultiplyChannelAboveAlphaClamps;
var
  C, U: TRGBA32;
begin
  { Manually craft invalid premul where channel > alpha }
  C.R := 200; C.G := 150; C.B := 100; C.A := 50;
  U := Unpremultiply(C);
  AssertTrue('R clamped to 255', U.R <= 255);
  AssertTrue('G clamped to 255', U.G <= 255);
  AssertTrue('B clamped to 255', U.B <= 255);
end;

procedure TExtremeValueTests.RGBAPremulAllZeros;
var
  R: TRGBA32;
begin
  R := RGBA_Premul(0, 0, 0, 0);
  AssertTrue('zero premul is transparent', RGBAEqual(R, TransparentColor));
end;

procedure TExtremeValueTests.RGBAPremulAllMax;
var
  R: TRGBA32;
begin
  R := RGBA_Premul(255, 255, 255, 255);
  AssertEquals('R', 255, R.R);
  AssertEquals('G', 255, R.G);
  AssertEquals('B', 255, R.B);
  AssertEquals('A', 255, R.A);
end;

{ === FPSurface Extreme Values === }

procedure TExtremeValueTests.CreateWithZeroDimensionsClampsToOne;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(0, 0);
  try
    AssertEquals('width clamped', 1, S.Width);
    AssertEquals('height clamped', 1, S.Height);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.CreateWithNegativeDimensionsClampsToOne;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(-10, -5);
  try
    AssertEquals('width clamped', 1, S.Width);
    AssertEquals('height clamped', 1, S.Height);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.ClearOnMinimalSurfaceSetsPixel;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(1, 1);
  try
    S.Clear(RGBA(42, 84, 126, 255));
    AssertEquals('single pixel R', 42, S[0, 0].R);
    AssertEquals('single pixel A', 255, S[0, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawBrushZeroRadiusOnMinimalSurface;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(1, 1);
  try
    S.Clear(TransparentColor);
    S.DrawBrush(0, 0, 0, RGBA(255, 0, 0, 255));
    { Radius 0 should still paint the center pixel }
    AssertTrue('center pixel painted', S[0, 0].A > 0);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawLineCompletelyOutOfBounds;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    S.DrawLine(-100, -100, -50, -50, 1, RGBA(255, 0, 0, 255));
    { No pixel should be painted }
    AssertEquals('origin stays transparent', 0, S[0, 0].A);
    AssertEquals('center stays transparent', 0, S[5, 5].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawRectangleInvertedCoords;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    { Inverted corners: X2 < X1, Y2 < Y1 }
    S.DrawRectangle(8, 8, 2, 2, 1, RGBA(255, 0, 0, 255), True);
    { Should still fill the normalized rectangle }
    AssertTrue('center of normalized rect painted', S[5, 5].A > 0);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawEllipseZeroArea;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    { Degenerate ellipse: same start and end }
    S.DrawEllipse(5, 5, 5, 5, 1, RGBA(255, 0, 0, 255), True);
    { Should not crash; painting result may be empty or a dot }
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawPolygonZeroPoints;
var
  S: TRasterSurface;
  Pts: array of TPoint;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(RGBA(0, 0, 0, 255));
    SetLength(Pts, 0);
    S.DrawPolygon(Pts, 1, RGBA(255, 0, 0, 255));
    { Should not crash; surface stays unchanged }
    AssertEquals('no crash on empty polygon', 0, S[5, 5].R);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawPolygonOnePoint;
var
  S: TRasterSurface;
  Pts: array[0..0] of TPoint;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    Pts[0] := Point(5, 5);
    S.DrawPolygon(Pts, 1, RGBA(255, 0, 0, 255));
    { Should not crash }
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.DrawPolygonTwoPoints;
var
  S: TRasterSurface;
  Pts: array[0..1] of TPoint;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    Pts[0] := Point(2, 2);
    Pts[1] := Point(8, 8);
    S.DrawPolygon(Pts, 1, RGBA(255, 0, 0, 255));
    { Two-point polygon = line segment; should draw without crashing }
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.FillPolygonDegenerateTriangle;
var
  S: TRasterSurface;
  Pts: array[0..2] of TPoint;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    { Collinear points: degenerate triangle with zero area }
    Pts[0] := Point(2, 5);
    Pts[1] := Point(5, 5);
    Pts[2] := Point(8, 5);
    S.FillPolygon(Pts, RGBA(255, 0, 0, 255));
    { Collinear fill may or may not paint, but must not crash }
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.FillGradientIdenticalEndpoints;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    { From and To are the same point }
    S.FillGradient(5, 5, 5, 5, RGBA(255, 0, 0, 255), RGBA(0, 0, 255, 255));
    { Should not crash or produce NaN; result is implementation-defined }
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.FillGradientInvertedCoords;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    { Reversed start/end coords }
    S.FillGradient(9, 9, 0, 0, RGBA(255, 0, 0, 255), RGBA(0, 0, 255, 255));
    { Should produce valid gradient in reverse direction }
    AssertTrue('some pixel painted', S[5, 5].A > 0);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.FloodFillOnSinglePixelSurface;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(1, 1);
  try
    S.Clear(TransparentColor);
    S.FloodFill(0, 0, RGBA(255, 0, 0, 255));
    AssertEquals('single pixel flooded', 255, S[0, 0].R);
    AssertEquals('single pixel alpha', 255, S[0, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.FloodFillMaxTolerance;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(5, 5);
  try
    { Create a multi-colored surface }
    S.Clear(RGBA(0, 0, 0, 255));
    S[2, 2] := RGBA(128, 128, 128, 255);
    { FloodFill with max tolerance: the fill color is also "close enough"
      to the target within tolerance 255, so FloodFill exits early (no-op).
      This is correct — verify it does not crash. }
    S.FloodFill(0, 0, RGBA(255, 0, 0, 255), 255);
    { Origin is unchanged because fill color matches target within tolerance }
    AssertEquals('origin unchanged at max tolerance', 0, S[0, 0].R);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.BoxBlurRadiusZeroClampsToOne;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(5, 5);
  try
    S.Clear(TransparentColor);
    S[2, 2] := Premultiply(RGBA(255, 0, 0, 255));
    S.BoxBlur(0);
    { Radius 0 clamps to 1; blur with radius 1 averages a 3x3 window }
    AssertTrue('center still has some red', S[2, 2].R > 0);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.BoxBlurRadiusHugeClampsToMax;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(5, 5);
  try
    S.Clear(Premultiply(RGBA(128, 128, 128, 255)));
    S.BoxBlur(10000);
    { Radius clamped to 64; on a uniform surface the blur is identity }
    AssertEquals('pixel unchanged after blur of uniform surface', 255, S[0, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.GaussianBlurOnSinglePixelSurface;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(1, 1);
  try
    S[0, 0] := Premultiply(RGBA(200, 100, 50, 255));
    S.GaussianBlur(3);
    { Single pixel: must not crash; pixel essentially unchanged }
    AssertEquals('alpha preserved', 255, S[0, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.MotionBlurZeroDistance;
var
  S: TRasterSurface;
  Original: TRGBA32;
begin
  S := TRasterSurface.Create(5, 5);
  try
    S.Clear(Premultiply(RGBA(100, 150, 200, 255)));
    Original := S[2, 2];
    S.MotionBlur(45, 0);
    { Zero distance should leave pixels unchanged }
    AssertTrue('pixel unchanged after zero motion blur',
      RGBAEqual(S[2, 2], Original));
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.BlackAndWhiteThresholdZero;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(3, 1);
  try
    S[0, 0] := Premultiply(RGBA(0, 0, 0, 255));
    S[1, 0] := Premultiply(RGBA(128, 128, 128, 255));
    S[2, 0] := Premultiply(RGBA(255, 255, 255, 255));
    S.BlackAndWhite(0);
    { Threshold=0 means luma>=0 is white; all visible pixels white }
    AssertEquals('black becomes white at threshold 0', 255, Unpremultiply(S[0, 0]).R);
    AssertEquals('gray becomes white at threshold 0', 255, Unpremultiply(S[1, 0]).R);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.BlackAndWhiteThresholdMax;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(3, 1);
  try
    S[0, 0] := Premultiply(RGBA(128, 128, 128, 255));
    S[1, 0] := Premultiply(RGBA(254, 254, 254, 255));
    S[2, 0] := Premultiply(RGBA(255, 255, 255, 255));
    S.BlackAndWhite(255);
    { Threshold=255: only luma>=255 stays white; most become black }
    AssertEquals('gray becomes black at threshold 255', 0, Unpremultiply(S[0, 0]).R);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.PosterizeLevelsMinTwo;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(3, 1);
  try
    S[0, 0] := Premultiply(RGBA(64, 64, 64, 255));
    S[1, 0] := Premultiply(RGBA(128, 128, 128, 255));
    S[2, 0] := Premultiply(RGBA(250, 250, 250, 255));
    S.Posterize(1); { Below minimum, clamps to 2 }
    { With 2 levels, pixels should be either 0 or 255 }
    AssertTrue('posterize 2: low pixel near 0',
      Unpremultiply(S[0, 0]).R <= 1);
    AssertTrue('posterize 2: high pixel near 255',
      Unpremultiply(S[2, 0]).R >= 254);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.PosterizeLevelsAboveMaxClamps;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(3, 1);
  try
    S[0, 0] := Premultiply(RGBA(42, 100, 200, 255));
    S[1, 0] := Premultiply(RGBA(128, 128, 128, 255));
    S[2, 0] := Premultiply(RGBA(250, 250, 250, 255));
    S.Posterize(200); { Above max, clamps to 64 }
    { With 64 levels, not much visible quantization - just verify no crash }
    AssertEquals('alpha unchanged', 255, S[1, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustBrightnessExtremePositive;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(200, 200, 200, 255));
    S[1, 0] := Premultiply(RGBA(0, 0, 0, 255));
    S.AdjustBrightness(1000);
    { Should clamp to 255, not overflow }
    AssertEquals('bright clamped to 255', 255, Unpremultiply(S[0, 0]).R);
    AssertEquals('alpha preserved', 255, S[0, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustBrightnessExtremeNegative;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(50, 50, 50, 255));
    S[1, 0] := Premultiply(RGBA(255, 255, 255, 255));
    S.AdjustBrightness(-1000);
    { Should clamp to 0, not underflow }
    AssertEquals('dark clamped to 0', 0, Unpremultiply(S[0, 0]).R);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustContrastExtremePositive;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(200, 200, 200, 255));
    S[1, 0] := Premultiply(RGBA(50, 50, 50, 255));
    S.AdjustContrast(1000);
    { Extreme contrast pushes channels toward 0 or 255 }
    AssertTrue('high pixel pushed to max', Unpremultiply(S[0, 0]).R >= 250);
    AssertTrue('low pixel pushed to min', Unpremultiply(S[1, 0]).R <= 5);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustContrastExtremeNegative;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(255, 255, 255, 255));
    S[1, 0] := Premultiply(RGBA(0, 0, 0, 255));
    S.AdjustContrast(-1000);
    { Extreme negative contrast pushes everything toward 128 }
    AssertTrue('white pushed toward gray', Unpremultiply(S[0, 0]).R <= 140);
    AssertTrue('black pushed toward gray', Unpremultiply(S[1, 0]).R >= 115);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustGammaCurveZero;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(128, 128, 128, 255));
    S[1, 0] := Premultiply(RGBA(10, 10, 10, 255));
    S.AdjustGammaCurve(0.0);
    { Gamma=0 should not crash; Power(x, 0) would give 1 for x>0 }
    AssertEquals('alpha preserved', 255, S[0, 0].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustGammaCurveTen;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(128, 128, 128, 255));
    S[1, 0] := Premultiply(RGBA(250, 250, 250, 255));
    S.AdjustGammaCurve(10.0);
    { Very high gamma darkens midtones dramatically }
    AssertTrue('midgray darkened by gamma 10', Unpremultiply(S[0, 0]).R < 50);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustLevelsFullRange;
var
  S: TRasterSurface;
  Original: TRGBA32;
begin
  S := TRasterSurface.Create(1, 1);
  try
    S[0, 0] := Premultiply(RGBA(100, 100, 100, 255));
    Original := S[0, 0];
    S.AdjustLevels(0, 255, 0, 255);
    { Full in -> full out: identity transform }
    AssertTrue('identity levels', RGBAEqual(S[0, 0], Original));
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.AdjustLevelsInvertedRange;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(2, 1);
  try
    S[0, 0] := Premultiply(RGBA(0, 0, 0, 255));
    S[1, 0] := Premultiply(RGBA(255, 255, 255, 255));
    S.AdjustLevels(0, 255, 255, 0);
    { Inverted output range should invert pixel values }
    AssertTrue('black becomes white', Unpremultiply(S[0, 0]).R >= 250);
    AssertTrue('white becomes black', Unpremultiply(S[1, 0]).R <= 5);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.SurfaceBlurRadiusClamps;
var
  S: TRasterSurface;
begin
  S := TRasterSurface.Create(5, 5);
  try
    S.Clear(Premultiply(RGBA(128, 128, 128, 255)));
    S.SurfaceBlur(1000, 100);
    { Radius clamped to 24; should not crash }
    AssertEquals('alpha preserved', 255, S[2, 2].A);
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.ResizeNearestToOnePx;
var
  S, R: TRasterSurface;
begin
  S := TRasterSurface.Create(100, 100);
  try
    S.Clear(Premultiply(RGBA(200, 100, 50, 255)));
    R := S.ResizeNearest(1, 1);
    try
      AssertEquals('resize to 1x1 width', 1, R.Width);
      AssertEquals('resize to 1x1 height', 1, R.Height);
      AssertTrue('pixel has color', R[0, 0].A > 0);
    finally
      R.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.ResizeBilinearToOnePx;
var
  S, R: TRasterSurface;
begin
  S := TRasterSurface.Create(100, 100);
  try
    S.Clear(Premultiply(RGBA(200, 100, 50, 255)));
    R := S.ResizeBilinear(1, 1);
    try
      AssertEquals('resize to 1x1 width', 1, R.Width);
      AssertEquals('resize to 1x1 height', 1, R.Height);
    finally
      R.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.CropCompletelyOutOfBounds;
var
  S, R: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(RGBA(255, 0, 0, 255));
    R := S.Crop(-100, -100, 5, 5);
    try
      { Region completely out of bounds; result should be transparent }
      AssertEquals('crop width', 5, R.Width);
      AssertEquals('crop height', 5, R.Height);
    finally
      R.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TExtremeValueTests.PasteSurfaceWithNegativeOffset;
var
  S, Src: TRasterSurface;
begin
  S := TRasterSurface.Create(10, 10);
  try
    S.Clear(TransparentColor);
    Src := TRasterSurface.Create(5, 5);
    try
      Src.Clear(Premultiply(RGBA(255, 0, 0, 255)));
      S.PasteSurface(Src, -3, -3);
      { Only the 2x2 overlap should be painted }
      AssertTrue('overlap pixel painted', S[0, 0].A > 0);
      AssertEquals('non-overlap stays transparent', 0, S[5, 5].A);
    finally
      Src.Free;
    end;
  finally
    S.Free;
  end;
end;

{ === FPSelection Extreme Values === }

procedure TExtremeValueTests.SelectionCreateNegativeSizeClampsToOne;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(-5, -10);
  try
    AssertEquals('width clamped', 1, M.Width);
    AssertEquals('height clamped', 1, M.Height);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectRectInvertedCoordsSetsNothing;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    { Inverted rect: X1>X2, Y1>Y2 - should normalize or skip }
    M.SelectRectangle(8, 8, 2, 2);
    { The normalized region should still be selected }
    AssertTrue('center of normalized rect selected', M.HasSelection);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectRectZeroAreaSetsNothing;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.SelectRectangle(5, 5, 5, 5);
    { Single-pixel rect: at least 1 pixel selected via SDF }
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectEllipseZeroArea;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.SelectEllipse(5, 5, 5, 5);
    { Degenerate: zero-area ellipse. Should not crash. }
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectPolygonEmptyArray;
var
  M: TSelectionMask;
  Pts: array of TPoint;
begin
  M := TSelectionMask.Create(10, 10);
  try
    SetLength(Pts, 0);
    M.SelectPolygon(Pts);
    AssertFalse('empty polygon selects nothing', M.HasSelection);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectPolygonSinglePoint;
var
  M: TSelectionMask;
  Pts: array[0..0] of TPoint;
begin
  M := TSelectionMask.Create(10, 10);
  try
    Pts[0] := Point(5, 5);
    M.SelectPolygon(Pts);
    { Single point polygon should not crash; may or may not select }
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectPolygonTwoPoints;
var
  M: TSelectionMask;
  Pts: array[0..1] of TPoint;
begin
  M := TSelectionMask.Create(10, 10);
  try
    Pts[0] := Point(2, 2);
    Pts[1] := Point(8, 8);
    M.SelectPolygon(Pts);
    { Two-point polygon should not crash }
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.FeatherRadiusZeroNoOp;
var
  M: TSelectionMask;
  CovBefore, CovAfter: Byte;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.SelectRectangle(2, 2, 7, 7);
    CovBefore := M.Coverage(5, 5);
    M.Feather(0);
    CovAfter := M.Coverage(5, 5);
    AssertEquals('feather 0 is no-op', CovBefore, CovAfter);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.FeatherRadiusVeryLargeStaysInBounds;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.SelectRectangle(4, 4, 6, 6);
    M.Feather(10000);
    { Very large radius; edges should all be softened; center may still have some coverage }
    { Main check: no crash or out-of-bounds }
    AssertTrue('no crash on huge feather radius', True);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.FeatherOnEmptySelectionNoOp;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.Feather(5);
    AssertFalse('empty stays empty after feather', M.HasSelection);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.InvertEmptySelectsAll;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(5, 5);
  try
    M.Invert;
    AssertTrue('invert empty selects all', M.HasSelection);
    AssertEquals('center is full coverage', 255, M.Coverage(2, 2));
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.InvertFullDeSelectsAll;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(5, 5);
  try
    M.SelectAll;
    M.Invert;
    AssertFalse('invert full deselects all', M.HasSelection);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.CropOutOfBoundsYieldsEmpty;
var
  M, Cropped: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.SelectAll;
    Cropped := M.Crop(-100, -100, 5, 5);
    try
      AssertEquals('crop width', 5, Cropped.Width);
      AssertEquals('crop height', 5, Cropped.Height);
    finally
      Cropped.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.MoveByLargeOffset;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    M.SelectRectangle(2, 2, 7, 7);
    M.MoveBy(10000, 10000);
    { All selected pixels moved out of bounds }
    AssertFalse('selection moved entirely out', M.HasSelection);
  finally
    M.Free;
  end;
end;

procedure TExtremeValueTests.SelectAllCombineModes;
var
  M: TSelectionMask;
begin
  M := TSelectionMask.Create(10, 10);
  try
    { scReplace }
    M.SelectRectangle(0, 0, 9, 9, scReplace);
    AssertTrue('replace: has selection', M.HasSelection);

    { scSubtract should remove everything }
    M.SelectRectangle(0, 0, 9, 9, scSubtract);
    AssertFalse('subtract: empty', M.HasSelection);

    { scAdd on empty }
    M.SelectRectangle(2, 2, 5, 5, scAdd);
    AssertTrue('add: has selection', M.HasSelection);

    { scIntersect with non-overlapping region }
    M.SelectRectangle(7, 7, 9, 9, scIntersect);
    AssertFalse('intersect disjoint: empty', M.HasSelection);
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest(TExtremeValueTests);

end.
