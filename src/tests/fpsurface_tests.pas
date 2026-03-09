unit fpsurface_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, Math, fpcunit, testregistry, FPColor, FPSelection, FPSurface;

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
    procedure FilledPolygonPaintsInterior;
    procedure MaskedLineOnlyPaintsInsideSelection;
    procedure MaskedLineCoverageScalesAlpha;
    procedure MaskedGradientLeavesUnselectedPixelsUntouched;
    procedure MaskedGradientCoverageBlendsPartiallySelectedPixels;
    procedure MaskedRadialGradientCoverageBlendsPartiallySelectedPixels;
    procedure ConicalGradientVariesByAngle;
    procedure LinearGradientSawtoothRepeatWrapsRamp;
    procedure DiamondGradientUsesL1Distance;
    procedure LinearGradientTriangularRepeatMirrors;
    procedure FillSelectionCoverageScalesOpacity;
    procedure CopySelectionCoverageScalesAlpha;
    procedure MoveSelectedPixelsCoverageUsesSoftCopyAndSoftErase;
    procedure EmbossShiftsPixelsRelativeToNeighbors;
    procedure SoftenBlursHighContrastEdge;
    procedure RecolorBrushReplacesMatchingPixels;
    procedure RecolorBrushContiguousLimitsConnectedRegion;
    procedure RecolorBrushOpacityBlendsTowardTarget;
    procedure RecolorBrushPreserveValueKeepsShading;
    procedure RecolorBrushColorModePreservesValue;
    procedure RecolorBrushHueModeShiftsHueOnly;
    procedure RecolorBrushSaturationModeShiftsSaturationOnly;
    procedure RecolorBrushLuminosityModeShiftsValueOnly;
    procedure RenderCloudsWritesNonTransparentPixels;
    procedure PixelateBlursPixelsIntoBlocks;
    procedure VignetteDarkensEdges;
    procedure DrawLineOpacityScalesAlphaChannel;
    procedure DashedLineLeavesExpectedGapPixels;
    procedure DashedPolylineClosesOutlineWithVisibleGaps;
    procedure DashedPolylineEllipseHasGapPixels;
    procedure DrawLineFullOpacityMatchesDirectPaint;
    procedure EraserLineReducesAlphaChannel;
    procedure DrawLineSoftHardnessProducesGradientEdge;
    procedure SquareLineBrushCoversCornerPixels;
    procedure RoundedRectangleHonorsExplicitCornerRadius;
    procedure QuadraticBezierBendsTowardControlPoint;
    procedure CubicBezierUsesBothControlHandles;
    procedure MotionBlurChangesPixels;
    procedure MedianFilterReducesNoise;
    procedure MedianFilterUpdatesAlphaAndKeepsPremulInvariant;
    procedure OilPaintChangesPixels;
    procedure FrostedGlassDisplacesPixels;
    procedure ZoomBlurSmearsCentreBrightness;
    procedure CopyRegionToClipsPartiallyOutOfBoundsSource;
    procedure OverwriteRegionClipsPartiallyOutOfBoundsDestination;
    procedure PixelateRectSelectionAveragesOnlySelectedPixels;
    procedure RadialGradientFadesFromCenter;
    procedure UnfocusSoftensSingleBrightPixel;
    procedure SurfaceBlurKeepsHardEdgeFromBleeding;
    procedure BulgePullsGradientTowardCenter;
    procedure DentsPushesGradientAwayFromCenter;
    procedure ReliefProducesDirectionalShading;
    procedure RedEyeReducesRedDominance;
    procedure TileReflectionMirrorsWithinTiles;
    procedure CrystallizeCollapsesSingleCellToOneColor;
    procedure InkSketchChangesHighContrastPixels;
    procedure MandelbrotRenderWritesVisibleFractal;
    procedure JuliaRenderWritesVisibleFractal;
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

    { With SDF AA, corner pixels get partial coverage from the anti-aliased fringe }
    AssertTrue('top-left corner has partial or no coverage', Surface[0, 0].A < 255);
    AssertTrue('top edge is painted', Surface[4, 0].A > 0);
    AssertTrue('left edge is painted', Surface[0, 3].A > 0);
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

procedure TFPSurfaceTests.FilledPolygonPaintsInterior;
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

    Surface.FillPolygon(Points, RGBA(255, 0, 0, 255));

    AssertEquals('interior is filled', 255, Surface[6, 9].A);
    AssertEquals('outside stays clear', 0, Surface[11, 4].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MaskedLineOnlyPaintsInsideSelection;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(5, 1);
  Selection := TSelectionMask.Create(5, 1);
  try
    Surface.Clear(TransparentColor);
    Selection[2, 0] := True;

    Surface.DrawLine(0, 0, 4, 0, 0, RGBA(255, 0, 0, 255), 255, 255, Selection);

    AssertEquals('left pixel stays clear', 0, Surface[0, 0].A);
    AssertEquals('middle selected pixel is painted', 255, Surface[2, 0].A);
    AssertEquals('right pixel stays clear', 0, Surface[4, 0].A);
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MaskedLineCoverageScalesAlpha;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(5, 1);
  Selection := TSelectionMask.Create(5, 1);
  try
    Surface.Clear(TransparentColor);
    Selection.SetCoverage(2, 0, 128);

    Surface.DrawLine(0, 0, 4, 0, 0, RGBA(255, 0, 0, 255), 255, 255, Selection);

    AssertEquals('unselected pixel stays clear', 0, Surface[1, 0].A);
    AssertEquals('selected pixel alpha scales by coverage', 128, Surface[2, 0].A);
    AssertEquals('selected pixel color follows blended alpha', 128, Surface[2, 0].R);
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MaskedGradientLeavesUnselectedPixelsUntouched;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(4, 1);
  Selection := TSelectionMask.Create(4, 1);
  try
    Surface.Clear(TransparentColor);
    Selection[1, 0] := True;
    Selection[2, 0] := True;

    Surface.FillGradient(0, 0, 3, 0, RGBA(255, 0, 0, 255), RGBA(0, 0, 255, 255), Selection);

    AssertEquals('unselected left pixel stays clear', 0, Surface[0, 0].A);
    AssertEquals('selected left-middle pixel is written', 255, Surface[1, 0].A);
    AssertEquals('selected right-middle pixel is written', 255, Surface[2, 0].A);
    AssertEquals('unselected right pixel stays clear', 0, Surface[3, 0].A);
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MaskedGradientCoverageBlendsPartiallySelectedPixels;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(3, 1);
  Selection := TSelectionMask.Create(3, 1);
  try
    Surface.Clear(TransparentColor);
    Selection.SetCoverage(1, 0, 128);

    Surface.FillGradient(
      0,
      0,
      2,
      0,
      RGBA(200, 40, 20, 255),
      RGBA(200, 40, 20, 255),
      Selection
    );

    AssertEquals('unselected left pixel stays clear', 0, Surface[0, 0].A);
    AssertEquals('partially selected pixel alpha is coverage-weighted', 128, Surface[1, 0].A);
    AssertEquals('partially selected pixel red is coverage-weighted', 100, Surface[1, 0].R);
    AssertEquals('partially selected pixel green is coverage-weighted', 20, Surface[1, 0].G);
    AssertEquals('partially selected pixel blue is coverage-weighted', 10, Surface[1, 0].B);
    AssertEquals('unselected right pixel stays clear', 0, Surface[2, 0].A);
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MaskedRadialGradientCoverageBlendsPartiallySelectedPixels;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(3, 3);
  Selection := TSelectionMask.Create(3, 3);
  try
    Surface.Clear(TransparentColor);
    Selection.SetCoverage(1, 1, 64);

    Surface.FillRadialGradient(
      1,
      1,
      2,
      RGBA(240, 120, 60, 255),
      RGBA(240, 120, 60, 255),
      Selection
    );

    AssertEquals('outside radial selection stays clear', 0, Surface[0, 0].A);
    AssertEquals('center pixel alpha is coverage-weighted', 64, Surface[1, 1].A);
    AssertEquals('center red is coverage-weighted', 60, Surface[1, 1].R);
    AssertEquals('center green is coverage-weighted', 30, Surface[1, 1].G);
    AssertEquals('center blue is coverage-weighted', 15, Surface[1, 1].B);
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.ConicalGradientVariesByAngle;
var
  Surface: TRasterSurface;
  EastPixel: TRGBA32;
  WestPixel: TRGBA32;
  NorthPixel: TRGBA32;
  SouthPixel: TRGBA32;
begin
  Surface := TRasterSurface.Create(9, 9);
  try
    Surface.Clear(TransparentColor);
    Surface.FillGradientAdvanced(
      4, 4, 8, 4,
      RGBA(255, 0, 0, 255),
      RGBA(0, 0, 255, 255),
      gkConical,
      grmNone
    );
    EastPixel := Surface[8, 4];
    WestPixel := Surface[0, 4];
    NorthPixel := Surface[4, 0];
    SouthPixel := Surface[4, 8];
    AssertTrue('east pixel should stay closer to start color', EastPixel.R > EastPixel.B);
    AssertTrue('west pixel should be near midpoint blend', Abs(WestPixel.R - WestPixel.B) <= 8);
    AssertTrue('north pixel should move toward end color', NorthPixel.B > NorthPixel.R);
    AssertTrue('south pixel should stay closer to start color', SouthPixel.R > SouthPixel.B);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.LinearGradientSawtoothRepeatWrapsRamp;
var
  Surface: TRasterSurface;
  SampleA: TRGBA32;
  SampleB: TRGBA32;
begin
  Surface := TRasterSurface.Create(8, 1);
  try
    Surface.Clear(TransparentColor);
    Surface.FillGradientAdvanced(
      0, 0, 3, 0,
      RGBA(255, 0, 0, 255),
      RGBA(0, 0, 255, 255),
      gkLinear,
      grmSawtooth
    );
    SampleA := Surface[1, 0];
    SampleB := Surface[4, 0];
    AssertTrue('wrapped sawtooth repeat should produce similar repeated samples',
      Abs(SampleA.R - SampleB.R) <= 8);
    AssertTrue('wrapped sawtooth repeat should produce similar repeated samples (blue)',
      Abs(SampleA.B - SampleB.B) <= 8);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DiamondGradientUsesL1Distance;
{ Diamond gradient should use Manhattan (L1) distance from center.
  Pixels at the same Manhattan distance should get the same T value. }
var
  Surface: TRasterSurface;
  CornerPixel: TRGBA32;
  EdgeMidPixel: TRGBA32;
  CenterPixel: TRGBA32;
begin
  Surface := TRasterSurface.Create(11, 11);
  try
    Surface.Clear(TransparentColor);
    Surface.FillGradientAdvanced(
      5, 5, 10, 5,
      RGBA(255, 0, 0, 255),
      RGBA(0, 0, 255, 255),
      gkDiamond,
      grmNone
    );
    CenterPixel := Surface[5, 5];
    EdgeMidPixel := Surface[10, 5];
    CornerPixel := Surface[8, 8];
    AssertTrue('center should be start color (red)', CenterPixel.R > 200);
    AssertTrue('east edge mid should be near end color', EdgeMidPixel.B > EdgeMidPixel.R);
    { (8,8) has Manhattan dist 6 from (5,5), same as (10,1). Both should be > 1.0 → clamped to end. }
    AssertTrue('diagonal pixel beyond L1 radius should be end color', CornerPixel.B > CornerPixel.R);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.LinearGradientTriangularRepeatMirrors;
{ Triangular repeat should mirror the ramp: T=0→1→0 over two gradient lengths.
  With gradient length=4, at pixel 2 T=0.5→mapped to 1.0 (end), at pixel 4
  T=1.0→mapped to 0.0 (back to start), at pixel 6 T=1.5→mapped to 1.0 (end). }
var
  Surface: TRasterSurface;
  SampleAtHalf: TRGBA32;
  SampleAtOne: TRGBA32;
  SampleAtOneAndHalf: TRGBA32;
begin
  Surface := TRasterSurface.Create(16, 1);
  try
    Surface.Clear(TransparentColor);
    Surface.FillGradientAdvanced(
      0, 0, 4, 0,
      RGBA(255, 0, 0, 255),
      RGBA(0, 0, 255, 255),
      gkLinear,
      grmTriangular
    );
    SampleAtHalf := Surface[2, 0];
    SampleAtOne := Surface[4, 0];
    SampleAtOneAndHalf := Surface[6, 0];
    { At T=0.5 (pixel 2): triangular maps to 1.0 → end color (blue) }
    AssertTrue('T=0.5 should reach end color via triangular peak',
      SampleAtHalf.B > SampleAtHalf.R);
    { At T=1.0 (pixel 4): triangular maps to 0.0 → start color (red) }
    AssertTrue('T=1.0 should mirror back to start color', SampleAtOne.R > SampleAtOne.B);
    { At T=1.5 (pixel 6): triangular maps to 1.0 → end color (blue) }
    AssertTrue('T=1.5 should reach end color again', SampleAtOneAndHalf.B > SampleAtOneAndHalf.R);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.FillSelectionCoverageScalesOpacity;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(1, 1);
  Selection := TSelectionMask.Create(1, 1);
  try
    Surface.Clear(TransparentColor);
    Selection.SetCoverage(0, 0, 64);

    Surface.FillSelection(Selection, RGBA(200, 10, 20, 255), 255);

    AssertEquals('fill alpha scales with coverage', 64, Surface[0, 0].A);
    AssertEquals('fill red scales with coverage on transparent dst', 50, Surface[0, 0].R);
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.CopySelectionCoverageScalesAlpha;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
  Copied: TRasterSurface;
begin
  Surface := TRasterSurface.Create(1, 1);
  Selection := TSelectionMask.Create(1, 1);
  try
    Surface[0, 0] := RGBA(40, 80, 120, 200);
    Selection.SetCoverage(0, 0, 128);

    Copied := Surface.CopySelection(Selection);
    try
      AssertEquals('copied alpha scales with coverage', 100, Copied[0, 0].A);
      { Premultiplied: all channels scale proportionally with coverage }
      AssertEquals('copied red channel scales with coverage', 20, Copied[0, 0].R);
    finally
      Copied.Free;
    end;
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MoveSelectedPixelsCoverageUsesSoftCopyAndSoftErase;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
begin
  Surface := TRasterSurface.Create(3, 1);
  Selection := TSelectionMask.Create(3, 1);
  try
    Surface.Clear(TransparentColor);
    Surface[1, 0] := RGBA(220, 100, 10, 200);
    Selection.SetCoverage(1, 0, 128);

    Surface.MoveSelectedPixels(Selection, 1, 0);

    AssertEquals('source alpha reduced by soft erase', 100, Surface[1, 0].A);
    AssertEquals('destination alpha uses soft copy', 100, Surface[2, 0].A);
  finally
    Selection.Free;
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

procedure TFPSurfaceTests.RecolorBrushContiguousLimitsConnectedRegion;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(12, 3);
  try
    Source := RGBA(200, 50, 50, 255);
    Target := RGBA(40, 180, 60, 255);

    Surface.Clear(RGBA(240, 240, 240, 255));
    Surface[2, 1] := Source;
    Surface[3, 1] := Source;
    Surface[8, 1] := Source;
    Surface[9, 1] := Source;

    Surface.RecolorBrush(3, 1, 7, Source, Target, 0, 255, False, nil, rbmReplaceRGBCompat, True);

    AssertEquals('connected source family recolored (left cluster)', Target.G, Surface[2, 1].G);
    AssertEquals('connected source family recolored (center cluster)', Target.G, Surface[3, 1].G);
    AssertEquals('disconnected matching family should stay unchanged', Source.R, Surface[8, 1].R);
    AssertEquals('disconnected matching family should stay unchanged', Source.G, Surface[9, 1].G);

    Surface.Clear(RGBA(240, 240, 240, 255));
    Surface[2, 1] := Source;
    Surface[3, 1] := Source;
    Surface[8, 1] := Source;
    Surface[9, 1] := Source;

    Surface.RecolorBrush(3, 1, 7, Source, Target, 0, 255, False, nil, rbmReplaceRGBCompat, False);

    AssertEquals('discontiguous mode should recolor remote match 1', Target.G, Surface[8, 1].G);
    AssertEquals('discontiguous mode should recolor remote match 2', Target.G, Surface[9, 1].G);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushOpacityBlendsTowardTarget;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(200, 50, 50, 255));
    Source := RGBA(200, 50, 50, 255);
    Target := RGBA(50, 200, 50, 255);

    Surface.RecolorBrush(2, 2, 2, Source, Target, 10, 128);

    AssertTrue('red channel moves toward target', Surface[2, 2].R < 200);
    AssertTrue('red channel does not jump fully to target', Surface[2, 2].R > 50);
    AssertTrue('green channel moves toward target', Surface[2, 2].G > 50);
    AssertTrue('green channel does not jump fully to target', Surface[2, 2].G < 200);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushPreserveValueKeepsShading;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(120, 30, 30, 255));
    Source := RGBA(120, 30, 30, 255);
    Target := RGBA(50, 200, 50, 255);

    Surface.RecolorBrush(2, 2, 2, Source, Target, 10, 255, True);

    AssertTrue('green channel shifts toward target hue', Surface[2, 2].G > Surface[2, 2].R);
    AssertTrue('preserved value stays darker than raw target', Surface[2, 2].G < 200);
    AssertTrue('preserved value stays above original red floor', Surface[2, 2].G > 30);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushColorModePreservesValue;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(120, 30, 30, 255));
    Source := RGBA(120, 30, 30, 255);
    Target := RGBA(50, 200, 50, 255);

    Surface.RecolorBrush(2, 2, 2, Source, Target, 10, 255, False, nil, rbmColor);

    AssertTrue('color mode should keep hue closer to target', Surface[2, 2].G > Surface[2, 2].R);
    AssertTrue('color mode should keep original brightness envelope', Surface[2, 2].G < 200);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushHueModeShiftsHueOnly;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(200, 50, 50, 255));
    Source := RGBA(200, 50, 50, 255);
    Target := RGBA(50, 50, 200, 255);

    Surface.RecolorBrush(2, 2, 2, Source, Target, 10, 255, False, nil, rbmHue);

    AssertTrue('hue mode should move output toward blue hue', Surface[2, 2].B > Surface[2, 2].R);
    AssertTrue('hue mode should keep strong saturation/value envelope', Surface[2, 2].B >= 180);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushSaturationModeShiftsSaturationOnly;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(120, 90, 90, 255));
    Source := RGBA(120, 90, 90, 255);
    Target := RGBA(30, 220, 30, 255);

    Surface.RecolorBrush(2, 2, 2, Source, Target, 10, 255, False, nil, rbmSaturation);

    AssertTrue('saturation mode should keep source hue dominance', Surface[2, 2].R > Surface[2, 2].G);
    AssertTrue('saturation mode should increase channel separation', Surface[2, 2].R - Surface[2, 2].G >= 20);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RecolorBrushLuminosityModeShiftsValueOnly;
var
  Surface: TRasterSurface;
  Source: TRGBA32;
  Target: TRGBA32;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(RGBA(200, 50, 50, 255));
    Source := RGBA(200, 50, 50, 255);
    Target := RGBA(20, 20, 60, 255);

    Surface.RecolorBrush(2, 2, 2, Source, Target, 10, 255, False, nil, rbmLuminosity);

    AssertTrue('luminosity mode should darken the source color', Surface[2, 2].R < 120);
    AssertTrue('luminosity mode should keep source hue family', Surface[2, 2].R > Surface[2, 2].G);
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

procedure TFPSurfaceTests.PixelateBlursPixelsIntoBlocks;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(4, 4);
  try
    Surface.Clear(RGBA(0, 0, 0, 255));
    Surface[0, 0] := RGBA(100, 100, 100, 255);
    Surface[1, 0] := RGBA(100, 100, 100, 255);
    Surface.Pixelate(2);
    AssertEquals('TL block is averaged', 50, Surface[0, 0].R);
    AssertEquals('TR block stays original (0 avg)', 0, Surface[2, 0].R);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.VignetteDarkensEdges;
var
  Surface: TRasterSurface;
  CenterR, EdgeR: Integer;
begin
  Surface := TRasterSurface.Create(10, 10);
  try
    Surface.Clear(RGBA(255, 255, 255, 255));
    Surface.Vignette(1.0);
    CenterR := Surface[5, 5].R;
    EdgeR := Surface[0, 0].R;
    AssertTrue('center is lighter than edge', CenterR > EdgeR);
    AssertEquals('edge is dimmed', 0, EdgeR);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DrawLineOpacityScalesAlphaChannel;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(10, 1);
  try
    Surface.Clear(TransparentColor);
    { Half opacity (128): DrawLine over transparent background }
    Surface.DrawLine(0, 0, 9, 0, 0, RGBA(255, 0, 0, 255), 128);
    AssertTrue('half opacity alpha above zero', Surface[5, 0].A > 0);
    AssertTrue('half opacity alpha less than full', Surface[5, 0].A < 255);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DashedLineLeavesExpectedGapPixels;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(64, 16);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawDashedLine(5, 8, 45, 8, 0, RGBA(255, 0, 0, 255), 6, 4);

    AssertEquals('dash-on pixel should be painted', 255, Surface[6, 8].A);
    AssertEquals('first dash gap should stay transparent', 0, Surface[13, 8].A);
    AssertEquals('second dash should resume painting', 255, Surface[18, 8].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DashedPolylineClosesOutlineWithVisibleGaps;
var
  Surface: TRasterSurface;
  Points: array[0..3] of TPoint;
begin
  Surface := TRasterSurface.Create(48, 32);
  try
    Surface.Clear(TransparentColor);
    Points[0] := Point(10, 10);
    Points[1] := Point(30, 10);
    Points[2] := Point(30, 20);
    Points[3] := Point(10, 20);
    Surface.DrawDashedPolyline(Points, 1, RGBA(255, 0, 0, 255), True, 6, 4);

    AssertEquals('top edge should have painted dash segments', 255, Surface[11, 10].A);
    AssertEquals('top edge should retain dash gaps', 0, Surface[18, 10].A);
    AssertEquals('closing edge should be painted', 255, Surface[10, 15].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DashedPolylineEllipseHasGapPixels;
var
  Surface: TRasterSurface;
  Points: array of TPoint;
  SegCount, I: Integer;
  CX, CY, RX, RY: Double;
  PaintedCount, TransparentCount: Integer;
  X: Integer;
begin
  { An ellipse decomposed into many short segments must still show gaps
    when rendered with DrawDashedPolyline (phase must carry across segments). }
  Surface := TRasterSurface.Create(120, 80);
  try
    Surface.Clear(TransparentColor);
    CX := 60.0;
    CY := 40.0;
    RX := 40.0;
    RY := 25.0;
    SegCount := Max(24, Round(2.0 * Pi * Max(RX, RY)));
    SetLength(Points, SegCount);
    for I := 0 to SegCount - 1 do
      Points[I] := Point(
        Round(CX + Cos(2.0 * Pi * I / SegCount) * RX),
        Round(CY + Sin(2.0 * Pi * I / SegCount) * RY)
      );
    Surface.DrawDashedPolyline(Points, 1, RGBA(255, 0, 0, 255), True, 8, 6);
    { Scan the top row of the ellipse (y = CY - RY = 15) for alternating painted/gap pixels }
    PaintedCount := 0;
    TransparentCount := 0;
    for X := Round(CX - RX) to Round(CX + RX) do
    begin
      if Surface[X, Round(CY - RY)].A > 0 then
        Inc(PaintedCount)
      else
        Inc(TransparentCount);
    end;
    AssertTrue('ellipse top should have some painted pixels', PaintedCount > 0);
    AssertTrue('ellipse top should have some gap (transparent) pixels', TransparentCount > 0);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DrawLineFullOpacityMatchesDirectPaint;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(5, 1);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawLine(0, 0, 4, 0, 0, RGBA(200, 100, 50, 255), 255);
    AssertEquals('full opacity red', 200, Surface[2, 0].R);
    AssertEquals('full opacity alpha', 255, Surface[2, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.EraserLineReducesAlphaChannel;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(5, 1);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawLine(0, 0, 4, 0, 0, RGBA(20, 30, 40, 255), 255);
    Surface.EraseLine(0, 0, 4, 0, 0, 255);

    AssertEquals('eraser should clear alpha to zero at the touched pixel', 0, Surface[2, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DrawLineSoftHardnessProducesGradientEdge;
{ A brush stroke with Hardness < 255 should produce a gradient falloff:
  the centre pixel of the brush area gets full opacity while a pixel near the
  edge of the radius gets partial opacity. }
var
  Surface: TRasterSurface;
  CentreAlpha, EdgeAlpha: Byte;
begin
  { 20-pixel-wide surface, draw a thick line (radius 5) at half-height }
  Surface := TRasterSurface.Create(20, 11);
  try
    Surface.Clear(TransparentColor);
    { Hardness 50 means ~half the radius is the hard core }
    Surface.DrawLine(10, 5, 10, 5, 5, RGBA(255, 0, 0, 255), 255, 128);
    CentreAlpha := Surface[10, 5].A;   { centre of stroke }
    EdgeAlpha   := Surface[10, 9].A;   { near outer edge (4 pixels from centre) }
    AssertTrue('centre should be opaque', CentreAlpha = 255);
    AssertTrue('edge should be semi-transparent', EdgeAlpha < 255);
    AssertTrue('edge should not be fully transparent', EdgeAlpha > 0);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.SquareLineBrushCoversCornerPixels;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(5, 5);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawSquareLine(2, 2, 2, 2, 1, RGBA(255, 0, 0, 255), 255, 255);

    AssertEquals('top-left corner is painted', 255, Surface[1, 1].A);
    AssertEquals('top-right corner is painted', 255, Surface[3, 1].A);
    AssertEquals('bottom-left corner is painted', 255, Surface[1, 3].A);
    AssertEquals('bottom-right corner is painted', 255, Surface[3, 3].A);
    AssertEquals('outside stays clear', 0, Surface[0, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RoundedRectangleHonorsExplicitCornerRadius;
var
  SmallRadiusSurface: TRasterSurface;
  LargeRadiusSurface: TRasterSurface;
begin
  SmallRadiusSurface := TRasterSurface.Create(24, 24);
  LargeRadiusSurface := TRasterSurface.Create(24, 24);
  try
    SmallRadiusSurface.Clear(TransparentColor);
    LargeRadiusSurface.Clear(TransparentColor);
    SmallRadiusSurface.DrawRoundedRectangle(
      2, 2, 21, 21, 1,
      RGBA(255, 0, 0, 255),
      True,
      255,
      nil,
      2
    );
    LargeRadiusSurface.DrawRoundedRectangle(
      2, 2, 21, 21, 1,
      RGBA(255, 0, 0, 255),
      True,
      255,
      nil,
      8
    );

    AssertTrue(
      'smaller corner radius should preserve more corner coverage',
      SmallRadiusSurface[3, 3].A > LargeRadiusSurface[3, 3].A
    );
  finally
    SmallRadiusSurface.Free;
    LargeRadiusSurface.Free;
  end;
end;

procedure TFPSurfaceTests.QuadraticBezierBendsTowardControlPoint;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(9, 9);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawQuadraticBezier(1, 7, 4, 1, 7, 7, 0, RGBA(255, 0, 0, 255));

    AssertEquals('curve midpoint is painted above the baseline', 255, Surface[4, 4].A);
    AssertEquals('start point is painted', 255, Surface[1, 7].A);
    AssertEquals('end point is painted', 255, Surface[7, 7].A);
    AssertEquals('baseline midpoint stays clear when the curve bends upward', 0, Surface[4, 7].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.CubicBezierUsesBothControlHandles;
var
  Surface: TRasterSurface;
  X: Integer;
  Y: Integer;
  HasUpperArc: Boolean;
  HasLowerArc: Boolean;
begin
  Surface := TRasterSurface.Create(13, 16);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawCubicBezier(1, 8, 3, 1, 9, 14, 11, 8, 0, RGBA(255, 0, 0, 255));

    HasUpperArc := False;
    for Y := 1 to 6 do
      for X := 2 to 5 do
        if Surface[X, Y].A > 0 then
          HasUpperArc := True;
    HasLowerArc := False;
    for Y := 10 to 14 do
      for X := 7 to 10 do
        if Surface[X, Y].A > 0 then
          HasLowerArc := True;

    AssertTrue('upper arc should paint above the baseline', HasUpperArc);
    AssertTrue('lower arc should paint below the baseline', HasLowerArc);
    AssertEquals('start point is painted', 255, Surface[1, 8].A);
    AssertEquals('end point is painted', 255, Surface[11, 8].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MotionBlurChangesPixels;
{ Motion blur on a surface that has a single bright pixel in an otherwise dark
  field should spread that brightness along the blur direction. }
var
  Surface: TRasterSurface;
  BeforeR, AfterR: Byte;
begin
  Surface := TRasterSurface.Create(40, 10);
  try
    Surface.Clear(RGBA(10, 10, 10, 255));
    Surface[20, 5] := RGBA(255, 255, 255, 255);
    BeforeR := Surface[25, 5].R;   { pixel to the right – initially dark }
    Surface.MotionBlur(0, 8);      { horizontal blur, distance 8 }
    AfterR := Surface[25, 5].R;
    AssertTrue('motion blur should brighten neighbour', AfterR > BeforeR);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MedianFilterReducesNoise;
{ A single noise pixel surrounded by uniform colour should be pushed toward
  the median of its neighbourhood – i.e. its value should decrease. }
var
  Surface: TRasterSurface;
  Before, After: Byte;
begin
  Surface := TRasterSurface.Create(7, 7);
  try
    Surface.Clear(RGBA(50, 50, 50, 255));
    { Salt-pepper noise pixel at centre }
    Surface[3, 3] := RGBA(255, 255, 255, 255);
    Before := Surface[3, 3].R;
    Surface.MedianFilter(1);
    After := Surface[3, 3].R;
    AssertTrue('median filter should reduce noise spike', After < Before);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MedianFilterUpdatesAlphaAndKeepsPremulInvariant;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(3, 3);
  try
    Surface.Clear(RGBA(0, 0, 0, 0));
    Surface[1, 1] := RGBA(255, 255, 255, 255);

    Surface.MedianFilter(1);

    AssertEquals('median alpha should follow neighborhood median', 0, Surface[1, 1].A);
    AssertTrue('premultiplied invariant requires red <= alpha', Surface[1, 1].R <= Surface[1, 1].A);
    AssertTrue('premultiplied invariant requires green <= alpha', Surface[1, 1].G <= Surface[1, 1].A);
    AssertTrue('premultiplied invariant requires blue <= alpha', Surface[1, 1].B <= Surface[1, 1].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.OilPaintChangesPixels;
var
  Surface: TRasterSurface;
  Before: TRasterSurface;
  X: Integer;
  Y: Integer;
  Changed: Boolean;
begin
  Surface := TRasterSurface.Create(20, 20);
  Before := nil;
  try
    for Y := 0 to 19 do
      for X := 0 to 19 do
        Surface[X, Y] := RGBA(Byte((X * 13 + Y * 7) and $FF), Byte((X * 3 + Y * 11) and $FF), Byte((X * 17 + Y * 5) and $FF), 255);
    Before := Surface.Clone;
    Surface.OilPaint(2);
    Changed := False;
    for Y := 0 to 19 do
      for X := 0 to 19 do
        if not RGBAEqual(Surface[X, Y], Before[X, Y]) then
        begin
          Changed := True;
          Break;
        end;
    AssertTrue('oil paint should change at least one pixel on textured input', Changed);
    AssertEquals('OilPaint keeps the centre pixel opaque', 255, Surface[10, 10].A);
  finally
    Before.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.FrostedGlassDisplacesPixels;
{ FrostedGlass samples displaced neighbours, so a clean stripe pattern should
  produce a result that differs from the original at some pixel. }
var
  Surface: TRasterSurface;
  X, Y: Integer;
  OrigR, AfterR: Byte;
  Changed: Boolean;
begin
  Surface := TRasterSurface.Create(30, 30);
  try
    { Fill with vertical gradient so displacement is detectable }
    for Y := 0 to 29 do
      for X := 0 to 29 do
        Surface[X, Y] := RGBA(Byte(X * 8), 128, 0, 255);
    OrigR := Surface[15, 15].R;
    Surface.FrostedGlass(3);
    AfterR := Surface[15, 15].R;
    { At least one edge pixel must have been displaced }
    Changed := False;
    for Y := 0 to 29 do
      for X := 0 to 29 do
        if Surface[X, Y].R <> Byte(X * 8) then
          Changed := True;
    AssertTrue('frosted glass displaces at least one pixel', Changed);
    if OrigR = AfterR then ; { suppress unused hint }
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.ZoomBlurSmearsCentreBrightness;
var
  Surface: TRasterSurface;
  X, Y: Integer;
  BeforeSample, AfterSample: TRGBA32;
begin
  Surface := TRasterSurface.Create(30, 30);
  try
    for Y := 0 to 29 do
      for X := 0 to 29 do
        Surface[X, Y] := RGBA(Byte((X * 8) and $FF), 120, 0, 255);
    BeforeSample := Surface[20, 15];
    Surface.ZoomBlur(15, 15, 6);
    AfterSample := Surface[20, 15];
    AssertFalse('zoom blur should alter off-center gradient sample',
      RGBAEqual(AfterSample, BeforeSample));
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.CopyRegionToClipsPartiallyOutOfBoundsSource;
var
  Source: TRasterSurface;
  Dest: TRasterSurface;
begin
  Source := TRasterSurface.Create(4, 2);
  Dest := TRasterSurface.Create(3, 2);
  try
    Source.Clear(TransparentColor);
    Dest.Clear(TransparentColor);
    Source[0, 0] := RGBA(10, 0, 0, 255);
    Source[1, 0] := RGBA(20, 0, 0, 255);

    Source.CopyRegionTo(Dest, -1, 0);

    AssertEquals('out-of-bounds sample keeps destination transparent', 0, Dest[0, 0].A);
    AssertTrue('dest x=1 should copy source x=0',
      RGBAEqual(Dest[1, 0], Source[0, 0]));
    AssertTrue('dest x=2 should copy source x=1',
      RGBAEqual(Dest[2, 0], Source[1, 0]));
  finally
    Dest.Free;
    Source.Free;
  end;
end;

procedure TFPSurfaceTests.OverwriteRegionClipsPartiallyOutOfBoundsDestination;
var
  Source: TRasterSurface;
  Dest: TRasterSurface;
begin
  Source := TRasterSurface.Create(3, 1);
  Dest := TRasterSurface.Create(4, 1);
  try
    Source[0, 0] := RGBA(11, 0, 0, 255);
    Source[1, 0] := RGBA(22, 0, 0, 255);
    Source[2, 0] := RGBA(33, 0, 0, 255);
    Dest.Clear(TransparentColor);

    Dest.OverwriteRegion(Source, -1, 0);

    AssertTrue('dest x=0 should receive source x=1',
      RGBAEqual(Dest[0, 0], Source[1, 0]));
    AssertTrue('dest x=1 should receive source x=2',
      RGBAEqual(Dest[1, 0], Source[2, 0]));
    AssertEquals('dest x=2 should remain unchanged', 0, Dest[2, 0].A);
  finally
    Dest.Free;
    Source.Free;
  end;
end;

procedure TFPSurfaceTests.PixelateRectSelectionAveragesOnlySelectedPixels;
var
  Surface: TRasterSurface;
  Selection: TSelectionMask;
  SelectedColor: TRGBA32;
  UnselectedColor: TRGBA32;
begin
  Surface := TRasterSurface.Create(2, 2);
  Selection := TSelectionMask.Create(2, 2);
  try
    SelectedColor := RGBA(255, 0, 0, 255);
    UnselectedColor := RGBA(0, 0, 255, 255);
    Surface[0, 0] := SelectedColor;
    Surface[1, 0] := UnselectedColor;
    Surface[0, 1] := UnselectedColor;
    Surface[1, 1] := UnselectedColor;

    Selection.Clear;
    Selection.SetCoverage(0, 0, 255);
    Surface.PixelateRect(0, 0, 1, 1, 2, Selection);

    AssertTrue('selected pixel should average from selected samples only',
      RGBAEqual(Surface[0, 0], SelectedColor));
    AssertTrue('unselected pixel should remain unchanged',
      RGBAEqual(Surface[1, 0], UnselectedColor));
  finally
    Selection.Free;
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RadialGradientFadesFromCenter;
{ FillRadialGradient should place the start colour at the centre and fade
  toward the end colour as distance from centre grows. }
var
  Surface: TRasterSurface;
  CentreR, EdgeR: Byte;
begin
  Surface := TRasterSurface.Create(40, 40);
  try
    Surface.Clear(RGBA(0, 0, 0, 255));
    { White at centre → Black at radius=18 }
    Surface.FillRadialGradient(20, 20, 18, RGBA(255, 255, 255, 255), RGBA(0, 0, 0, 255));
    CentreR := Surface[20, 20].R;
    EdgeR   := Surface[20, 38].R;   { near the rim }
    AssertTrue('centre should be brighter than near-edge', CentreR > EdgeR);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.UnfocusSoftensSingleBrightPixel;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(11, 11);
  try
    Surface.Clear(RGBA(0, 0, 0, 255));
    Surface[5, 5] := RGBA(255, 255, 255, 255);
    Surface.Unfocus(2);

    AssertTrue('unfocus should dim the original hotspot', Surface[5, 5].R < 255);
    AssertTrue('unfocus should spread brightness to a neighbour', Surface[6, 5].R > 0);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.SurfaceBlurKeepsHardEdgeFromBleeding;
var
  Surface: TRasterSurface;
  X: Integer;
begin
  Surface := TRasterSurface.Create(12, 3);
  try
    for X := 0 to 5 do
    begin
      Surface[X, 1] := RGBA(0, 0, 0, 255);
      Surface[X, 0] := RGBA(0, 0, 0, 255);
      Surface[X, 2] := RGBA(0, 0, 0, 255);
    end;
    for X := 6 to 11 do
    begin
      Surface[X, 1] := RGBA(255, 255, 255, 255);
      Surface[X, 0] := RGBA(255, 255, 255, 255);
      Surface[X, 2] := RGBA(255, 255, 255, 255);
    end;

    Surface.SurfaceBlur(2, 10);

    AssertTrue('dark side should stay dark near the edge', Surface[5, 1].R < 40);
    AssertTrue('light side should stay light near the edge', Surface[6, 1].R > 215);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.BulgePullsGradientTowardCenter;
var
  Surface: TRasterSurface;
  X, Y: Integer;
  BeforeValue, AfterValue: Byte;
begin
  Surface := TRasterSurface.Create(21, 21);
  try
    for Y := 0 to 20 do
      for X := 0 to 20 do
        Surface[X, Y] := RGBA(Byte(X * 12), 0, 0, 255);

    BeforeValue := Surface[15, 10].R;
    Surface.Bulge(60);
    AfterValue := Surface[15, 10].R;

    AssertTrue('bulge should sample from closer to center on the right side', AfterValue < BeforeValue);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.DentsPushesGradientAwayFromCenter;
var
  Surface: TRasterSurface;
  X, Y: Integer;
  BeforeValue, AfterValue: Byte;
begin
  Surface := TRasterSurface.Create(21, 21);
  try
    for Y := 0 to 20 do
      for X := 0 to 20 do
        Surface[X, Y] := RGBA(Byte(X * 12), 0, 0, 255);

    BeforeValue := Surface[15, 10].R;
    Surface.Dents(60);
    AfterValue := Surface[15, 10].R;

    AssertTrue('dents should sample from farther out on the right side', AfterValue > BeforeValue);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.ReliefProducesDirectionalShading;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(7, 5);
  try
    Surface.Clear(RGBA(0, 0, 0, 255));
    Surface[4, 2] := RGBA(255, 255, 255, 255);
    Surface[5, 2] := RGBA(255, 255, 255, 255);
    Surface[6, 2] := RGBA(255, 255, 255, 255);

    Surface.Relief(0);

    AssertEquals('relief should produce grayscale output', Surface[4, 2].R, Surface[4, 2].G);
    AssertEquals('relief should keep grayscale output in blue too', Surface[4, 2].G, Surface[4, 2].B);
    AssertEquals('relief should preserve alpha', 255, Surface[4, 2].A);
    AssertTrue('relief should create visible shading on the edge', Surface[4, 2].R <> 0);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.RedEyeReducesRedDominance;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(2, 1);
  try
    Surface[0, 0] := RGBA(250, 24, 24, 255);
    Surface[1, 0] := RGBA(80, 72, 70, 255);

    Surface.RedEye(40, 100);

    AssertTrue('red-eye pass should reduce strong red channel', Surface[0, 0].R < 250);
    AssertEquals('red-eye pass should preserve alpha', 255, Surface[0, 0].A);
    AssertEquals('neutral pixel red should stay the same', 80, Surface[1, 0].R);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.TileReflectionMirrorsWithinTiles;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(4, 1);
  try
    Surface[0, 0] := RGBA(10, 0, 0, 255);
    Surface[1, 0] := RGBA(40, 0, 0, 255);
    Surface[2, 0] := RGBA(200, 0, 0, 255);
    Surface[3, 0] := RGBA(250, 0, 0, 255);

    Surface.TileReflection(4);

    AssertEquals('third pixel should mirror the second', 40, Surface[2, 0].R);
    AssertEquals('fourth pixel should mirror the first', 10, Surface[3, 0].R);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.CrystallizeCollapsesSingleCellToOneColor;
var
  Surface: TRasterSurface;
  X, Y: Integer;
  FirstPixel: TRGBA32;
begin
  Surface := TRasterSurface.Create(8, 8);
  try
    for Y := 0 to 7 do
      for X := 0 to 7 do
        Surface[X, Y] := RGBA(Byte(X * 20), Byte(Y * 20), 0, 255);

    Surface.Crystallize(8, 1);
    FirstPixel := Surface[0, 0];

    AssertEquals('single crystallize cell keeps one flat color (r)', FirstPixel.R, Surface[7, 7].R);
    AssertEquals('single crystallize cell keeps one flat color (g)', FirstPixel.G, Surface[4, 3].G);
    AssertEquals('single crystallize cell keeps one flat color (a)', FirstPixel.A, Surface[2, 6].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.InkSketchChangesHighContrastPixels;
var
  Surface: TRasterSurface;
  Original: array[0..4] of TRGBA32;
  X: Integer;
  Changed: Boolean;
begin
  Surface := TRasterSurface.Create(5, 1);
  try
    Surface[0, 0] := RGBA(255, 255, 255, 255);
    Surface[1, 0] := RGBA(255, 255, 255, 255);
    Surface[2, 0] := RGBA(0, 0, 0, 255);
    Surface[3, 0] := RGBA(0, 0, 0, 255);
    Surface[4, 0] := RGBA(255, 255, 255, 255);
    for X := 0 to 4 do
      Original[X] := Surface[X, 0];

    Surface.InkSketch(100, 50);

    Changed := False;
    for X := 0 to 4 do
      if (Surface[X, 0].R <> Original[X].R) or
         (Surface[X, 0].G <> Original[X].G) or
         (Surface[X, 0].B <> Original[X].B) then
      begin
        Changed := True;
        Break;
      end;
    AssertTrue('ink sketch should visibly alter at least one contrasted pixel', Changed);
    AssertEquals('ink sketch should preserve alpha', 255, Surface[2, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.MandelbrotRenderWritesVisibleFractal;
var
  Surface: TRasterSurface;
  CornerPixel: TRGBA32;
  CenterPixel: TRGBA32;
begin
  Surface := TRasterSurface.Create(48, 32);
  try
    Surface.Clear(TransparentColor);
    Surface.RenderMandelbrot(48, 1.0);
    CornerPixel := Surface[0, 0];
    CenterPixel := Surface[24, 16];

    AssertEquals('mandelbrot render should paint opaque output', 255, CornerPixel.A);
    AssertTrue(
      'mandelbrot render should produce visible variation',
      (CornerPixel.R <> CenterPixel.R) or
      (CornerPixel.G <> CenterPixel.G) or
      (CornerPixel.B <> CenterPixel.B)
    );
  finally
    Surface.Free;
  end;
end;

procedure TFPSurfaceTests.JuliaRenderWritesVisibleFractal;
var
  Surface: TRasterSurface;
  LeftPixel: TRGBA32;
  RightPixel: TRGBA32;
begin
  Surface := TRasterSurface.Create(48, 32);
  try
    Surface.Clear(TransparentColor);
    Surface.RenderJulia(48, 1.0);
    LeftPixel := Surface[8, 16];
    RightPixel := Surface[40, 16];

    AssertEquals('julia render should paint opaque output', 255, LeftPixel.A);
    AssertTrue(
      'julia render should produce visible variation',
      (LeftPixel.R <> RightPixel.R) or
      (LeftPixel.G <> RightPixel.G) or
      (LeftPixel.B <> RightPixel.B)
    );
  finally
    Surface.Free;
  end;
end;

initialization
  RegisterTest(TFPSurfaceTests);

end.
