unit fpsurface_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, fpcunit, testregistry, FPColor, FPSurface;

type
  TFPSurfaceTests = class(TTestCase)
  published
    procedure ZeroRadiusLinePaintsSinglePixelSteps;
    procedure AutoLevelStretchesVisiblePixelsOnly;
    procedure HueSaturationShiftsHueAndPreservesAlpha;
    procedure GammaCurveDarkensMidtonesAndSkipsTransparentPixels;
    procedure LevelsMapsRangeAndSkipsTransparentPixels;
    procedure ResizeBilinearBlendsNeighborPixels;
    procedure RoundedRectangleLeavesHardCornersOpen;
    procedure PolygonOutlineClosesLastSegmentAndKeepsInteriorOpen;
    procedure EmbossShiftsPixelsRelativeToNeighbors;
    procedure SoftenBlursHighContrastEdge;
    procedure RecolorBrushReplacesMatchingPixels;
    procedure RenderCloudsWritesNonTransparentPixels;
  end;

implementation

procedure TFPSurfaceTests.ZeroRadiusLinePaintsSinglePixelSteps;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawLine(1, 1, 3, 3, 0, RGBA(255, 0, 0, 255));

    AssertEquals('start pixel painted', 255, Surface[1, 1].A);
    AssertEquals('middle pixel painted', 255, Surface[2, 2].A);
    AssertEquals('end pixel painted', 255, Surface[3, 3].A);
    AssertEquals('adjacent pixel stays clear', 0, Surface[2, 1].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.AutoLevelStretchesVisiblePixelsOnly;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(3, 1);
  try
    Surface[0, 0] := RGBA(10, 40, 90, 255);
    Surface[1, 0] := RGBA(110, 140, 190, 255);
    Surface[2, 0] := RGBA(250, 5, 5, 0);

    Surface.AutoLevel;

    AssertEquals('visible low red', 0, Surface[0, 0].R);
    AssertEquals('visible low green', 0, Surface[0, 0].G);
    AssertEquals('visible low blue', 0, Surface[0, 0].B);

    AssertEquals('visible high red', 255, Surface[1, 0].R);
    AssertEquals('visible high green', 255, Surface[1, 0].G);
    AssertEquals('visible high blue', 255, Surface[1, 0].B);

    AssertEquals('transparent red unchanged', 250, Surface[2, 0].R);
    AssertEquals('transparent alpha unchanged', 0, Surface[2, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.HueSaturationShiftsHueAndPreservesAlpha;
var
  HueSurface: TRasterSurface;
  SaturationSurface: TRasterSurface;
begin
  HueSurface := TRasterSurface.Create(1, 1);
  SaturationSurface := TRasterSurface.Create(1, 1);
  try
    HueSurface[0, 0] := RGBA(255, 0, 0, 255);
    SaturationSurface[0, 0] := RGBA(120, 40, 40, 128);

    HueSurface.AdjustHueSaturation(120, 0);
    SaturationSurface.AdjustHueSaturation(0, -100);

    AssertTrue('red should rotate away from red', HueSurface[0, 0].R < 20);
    AssertTrue('red should rotate toward green', HueSurface[0, 0].G > 240);
    AssertEquals('alpha should stay intact', 128, SaturationSurface[0, 0].A);
    AssertEquals('desaturated pixel should equalize red/green', SaturationSurface[0, 0].R, SaturationSurface[0, 0].G);
    AssertEquals('desaturated pixel should equalize green/blue', SaturationSurface[0, 0].G, SaturationSurface[0, 0].B);
  finally
    HueSurface.Free;
    SaturationSurface.Free;
  end;
end;

procedure TFPSurfaceTests.GammaCurveDarkensMidtonesAndSkipsTransparentPixels;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(2, 1);
  try
    Surface[0, 0] := RGBA(128, 128, 128, 255);
    Surface[1, 0] := RGBA(200, 10, 10, 0);

    Surface.AdjustGammaCurve(2.0);

    AssertTrue('gamma 2 should darken midpoint', Surface[0, 0].R < 128);
    AssertEquals('transparent pixel red should stay unchanged', 200, Surface[1, 0].R);
    AssertEquals('transparent alpha should stay unchanged', 0, Surface[1, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.LevelsMapsRangeAndSkipsTransparentPixels;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(3, 1);
  try
    Surface[0, 0] := RGBA(50, 100, 150, 255);
    Surface[1, 0] := RGBA(150, 150, 150, 255);
    Surface[2, 0] := RGBA(220, 10, 10, 0);

    Surface.AdjustLevels(50, 150, 10, 210);

    AssertEquals('input low should map to output low', 10, Surface[0, 0].R);
    AssertEquals('midpoint should map into output range', 210, Surface[1, 0].R);
    AssertEquals('transparent pixel red should stay unchanged', 220, Surface[2, 0].R);
    AssertEquals('transparent pixel alpha should stay unchanged', 0, Surface[2, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.ResizeBilinearBlendsNeighborPixels;
var
  Surface: TRasterSurface;
  Resized: TRasterSurface;
begin
  Surface := TRasterSurface.Create(2, 2);
  try
    Surface[0, 0] := RGBA(0, 0, 0, 255);
    Surface[1, 0] := RGBA(255, 0, 0, 255);
    Surface[0, 1] := RGBA(0, 255, 0, 255);
    Surface[1, 1] := RGBA(255, 255, 255, 255);

    Resized := Surface.ResizeBilinear(1, 1);
    try
      AssertEquals('red average', 128, Resized[0, 0].R);
      AssertEquals('green average', 128, Resized[0, 0].G);
      AssertEquals('blue average', 64, Resized[0, 0].B);
      AssertEquals('alpha average', 255, Resized[0, 0].A);
    finally
      Resized.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RoundedRectangleLeavesHardCornersOpen;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(9, 7);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawRoundedRectangle(0, 0, 8, 6, 1, RGBA(255, 0, 0, 255), False);

    AssertEquals('top-left corner stays open', 0, Surface[0, 0].A);
    AssertEquals('top edge is painted', 255, Surface[4, 0].A);
    AssertEquals('left edge is painted', 255, Surface[0, 3].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.PolygonOutlineClosesLastSegmentAndKeepsInteriorOpen;
var
  Surface: TRasterSurface;
  Points: array[0..2] of TPoint;
begin
  Surface := TRasterSurface.Create(15, 15);
  try
    Surface.Clear(TransparentColor);
    Points[0] := Point(2, 2);
    Points[1] := Point(2, 12);
    Points[2] := Point(12, 12);

    Surface.DrawPolygon(Points, 1, RGBA(255, 0, 0, 255), True);

    AssertEquals('left edge is painted', 255, Surface[2, 7].A);
    AssertEquals('bottom edge is painted', 255, Surface[7, 12].A);
    AssertEquals('closing diagonal is painted', 255, Surface[6, 6].A);
    AssertEquals('interior stays open', 0, Surface[6, 9].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.EmbossShiftsPixelsRelativeToNeighbors;
var
  Surface: TRasterSurface;
  CenterBefore, CenterAfter: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(128, 128, 128, 255));
    Surface[2, 2] := RGBA(255, 255, 255, 255);
    CenterBefore := Surface[2, 2];
    Surface.Emboss;
    CenterAfter := Surface[2, 2];
    AssertTrue('emboss changes center pixel', (CenterBefore.R <> CenterAfter.R) or
      (CenterBefore.G <> CenterAfter.G) or (CenterBefore.B <> CenterAfter.B));
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.SoftenBlursHighContrastEdge;
var
  Surface: TRasterSurface;
  I: Integer;
begin
  Surface := TRasterSurface.Create(6, 1);
  try
    for I := 0 to 2 do
      Surface[I, 0] := RGBA(0, 0, 0, 255);
    for I := 3 to 5 do
      Surface[I, 0] := RGBA(255, 255, 255, 255);
    Surface.Soften;
    { The boundary pixel should be blended, not pure black or white }
    AssertTrue('soften blends edge pixel R', Surface[2, 0].R < 255);
    AssertTrue('soften blends edge pixel R above 0', Surface[3, 0].R > 0);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushReplacesMatchingPixels;
var
  Surface: TRasterSurface;
  Source, Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(10, 10);
  try
    Surface.Clear(RGBA(200, 50, 50, 255));
    Source := RGBA(200, 50, 50, 255);
    Target := RGBA(50, 200, 50, 255);
    Surface.RecolorBrush(5, 5, 4, Source, Target, 10);
    AssertEquals('center pixel recolored R', 50, Surface[5, 5].R);
    AssertEquals('center pixel recolored G', 200, Surface[5, 5].G);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RenderCloudsWritesNonTransparentPixels;
var
  Surface: TRasterSurface;
  X, Y: Integer;
  AllOpaque: Boolean;
begin
  Surface := TRasterSurface.Create(16, 16);
  try
    Surface.Clear(TransparentColor);
    Surface.RenderClouds(42);
    AllOpaque := True;
    for Y := 0 to 15 do
      for X := 0 to 15 do
        if Surface[X, Y].A < 255 then
          AllOpaque := False;
    AssertTrue('all pixels written by RenderClouds', AllOpaque);
  finally
    Surface.Free;
  end;
end;

initialization
  RegisterTest(TFPSurfaceTests);

end.
