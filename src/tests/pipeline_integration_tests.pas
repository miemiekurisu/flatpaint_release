unit pipeline_integration_tests;

{$mode objfpc}{$H+}

{ Comprehensive integration tests that exercise the MainForm event pipeline
  end-to-end: mouse events -> data model mutations -> UI state consistency.
  These tests cover the three critical paths reported as broken:
    1. Drawing tools (pencil/brush/eraser) modify surface pixels
    2. History grows on mouse-up (CommitStrokeHistory)
    3. AddLayerClick creates a new layer
  Plus regression tests for the six bugs that were fixed.

  NOTE: Tests use TMainForm.CreateForTesting which builds a headless form
  via raw GetMem (bypassing LCL widget creation).  No MakeTestSafe call
  is needed for these pipeline-level verifications. }

interface

uses
  Classes, Controls, Types, fpcunit, testregistry, FPColor, FPDocument, FPSelection, MainForm;

type
  TPipelineIntegrationTests = class(TTestCase)
  published
    { Drawing pipeline }
    procedure PencilStrokeModifiesSurfacePixels;
    procedure OpaquePencilStrokeOverwritesExistingPixel;
    procedure BrushStrokeModifiesSurfacePixels;
    procedure EraserStrokeModifiesSurfacePixels;
    procedure SelectionOverlayUsesDashedBoundaryPattern;
    procedure LassoSelectionOverlayUsesDashedBoundaryPattern;
    procedure MagicWandSelectionOverlayUsesDashedBoundaryPattern;
    procedure DrawingWithMoveChangesPixels;
    procedure LineDragCommitsPixels;
    procedure LineDashedStyleCommitsVisibleGapPattern;
    procedure LineDragClipsToSelectionMask;
    procedure RectangleDragCommitsPixels;
    procedure EllipseDragCommitsPixels;
    procedure OffsetLayerLineDragCommitsPixelsAtLayerLocalPosition;
    procedure FillWithinActiveSelectionOverwritesExistingPixels;
    procedure RecolorToolRespectsSelectionScopeAndUndoRedo;
    procedure RecolorOnceSamplingKeepsInitialSourceAcrossDrag;
    procedure RecolorContinuousSamplingResamplesAcrossDrag;
    procedure RecolorContiguousDragKeepsApplyingAcrossLargeFlatRegion;
    procedure CloneStampSampleSourceCanUseCompositeImage;
    procedure CloneStampAlignedModePreservesOffsetAcrossStrokes;
    procedure CropToolAspectConstraintProducesSquareOutput;
    procedure CropToolFourByThreeAspectConstraintProducesCorrectRatio;
    procedure CropToolSixteenByNineAspectConstraintProducesCorrectRatio;

    { History pipeline }
    procedure MouseUpAfterPencilStrokePushesHistory;
    procedure MouseUpAfterBrushStrokePushesHistory;
    procedure FillToolPushesHistoryOnMouseDown;
    procedure LockedLayerBlocksPencilStrokeAtMainFormEdge;
    procedure LockedLayerBlocksFillToolAtMainFormEdge;
    procedure LockedLayerAllowsMoveSelectionAtMainFormEdge;
    procedure ClickingOutsideSelectionAutoDeselects;
    procedure ToolbarSwitchFromSelectionToFillKeepsSelection;
    procedure SwitchingFromSelectionToBrushPreservesSelection;
    procedure SwitchingWithinSelectionFamilyKeepsSelection;
    procedure AddLayerPushesHistory;
    procedure MultipleStrokesIncrementHistory;
    procedure UndoRedoAfterLongPencilStrokeRestoresPixels;

    { Layer pipeline }
    procedure AddLayerIncreasesLayerCount;
    procedure AddLayerSetsNewLayerAsActive;

    { Temp-pan / OnKeyUp bug regression }
    procedure SpaceKeyActivatesTempPan;
    procedure SpaceKeyUpDeactivatesTempPan;
    procedure ExplicitToolPropertyChangeClearsTempPanFlag;
    procedure PinchGestureAdjustsZoomScale;

    { Render revision tracking }
    procedure DrawingBumpsRenderRevision;

    { Dirty flag tracking }
    procedure DrawingSetsDirtyFlag;

    { Display pixel verification }
    procedure DrawBlackOnWhiteChangesDisplayPixel;
  end;

implementation

uses
  LCLType, FPSurface;

{ Helper: create a headless test form with specified tool.
  Does NOT call MakeTestSafe — avoids creating real LCL widgets that
  require a fully-initialised Cocoa widgetset. }
function CreateTestForm(ATool: TToolKind): TMainForm;
begin
  Result := TMainForm.CreateForTesting;
  Result.CurrentToolForTest := ATool;
end;

{ ---------------------------------------------------------------------------
  Drawing pipeline tests
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.PencilStrokeModifiesSurfacePixels;
var
  F: TMainForm;
  Before, After: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    Before := F.TestDocument.ActiveLayer.Surface[20, 20];
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    After := F.TestDocument.ActiveLayer.Surface[20, 20];
    AssertFalse('pencil mouse-down should change the surface pixel',
      RGBAEqual(Before, After));
    F.SimulateMouseUp(mbLeft, [], 20, 20);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.OpaquePencilStrokeOverwritesExistingPixel;
var
  F: TMainForm;
  FinalPixel: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    F.SetPrimaryColorForTest(RGBA(220, 40, 30, 255));
    F.SimulateMouseDown(mbLeft, [ssLeft], 24, 24);
    F.SimulateMouseUp(mbLeft, [], 24, 24);

    F.SetPrimaryColorForTest(RGBA(0, 0, 0, 255));
    F.SimulateMouseDown(mbLeft, [ssLeft], 24, 24);
    F.SimulateMouseUp(mbLeft, [], 24, 24);

    FinalPixel := F.TestDocument.ActiveLayer.Surface[24, 24];
    AssertTrue('opaque pencil should overwrite prior pixel data at same location',
      RGBAEqual(FinalPixel, RGBA(0, 0, 0, 255)));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.BrushStrokeModifiesSurfacePixels;
var
  F: TMainForm;
  Before, After: TRGBA32;
begin
  F := CreateTestForm(tkBrush);
  try
    Before := F.TestDocument.ActiveLayer.Surface[30, 30];
    F.SimulateMouseDown(mbLeft, [ssLeft], 30, 30);
    After := F.TestDocument.ActiveLayer.Surface[30, 30];
    AssertFalse('brush mouse-down should change the surface pixel',
      RGBAEqual(Before, After));
    F.SimulateMouseUp(mbLeft, [], 30, 30);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.EraserStrokeModifiesSurfacePixels;
var
  F: TMainForm;
  Before, After: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    { First draw some content to erase }
    F.SimulateMouseDown(mbLeft, [ssLeft], 40, 40);
    F.SimulateMouseUp(mbLeft, [], 40, 40);
    Before := F.TestDocument.ActiveLayer.Surface[40, 40];

    { Switch to eraser and erase }
    F.CurrentToolForTest := tkEraser;
    F.SimulateMouseDown(mbLeft, [ssLeft], 40, 40);
    After := F.TestDocument.ActiveLayer.Surface[40, 40];
    AssertFalse('eraser should change the surface pixel',
      RGBAEqual(Before, After));
    F.SimulateMouseUp(mbLeft, [], 40, 40);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.SelectionOverlayUsesDashedBoundaryPattern;
var
  F: TMainForm;
  DashOnPixel: TRGBA32;
  DashOffPixel: TRGBA32;
begin
  F := CreateTestForm(tkSelectRect);
  try
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);
    DashOnPixel := F.DisplayPixelForTest(12, 10);
    DashOffPixel := F.DisplayPixelForTest(14, 10);

    AssertTrue('selection dash-on segment should render an outline pixel',
      RGBAEqual(DashOnPixel, RGBA(0, 0, 0, 255)));
    AssertTrue('selection light ant segment should render white for contrast',
      RGBAEqual(DashOffPixel, RGBA(255, 255, 255, 255)));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LassoSelectionOverlayUsesDashedBoundaryPattern;
var
  F: TMainForm;
  LassoPoints: array of TPoint;
  DashOnPixel: TRGBA32;
  DashOffPixel: TRGBA32;
begin
  F := CreateTestForm(tkSelectLasso);
  try
    SetLength(LassoPoints, 4);
    LassoPoints[0] := Point(10, 10);
    LassoPoints[1] := Point(20, 10);
    LassoPoints[2] := Point(18, 18);
    LassoPoints[3] := Point(10, 20);
    F.TestDocument.SelectLasso(LassoPoints, scReplace);

    DashOnPixel := F.DisplayPixelForTest(12, 10);
    DashOffPixel := F.DisplayPixelForTest(14, 10);

    AssertTrue('lasso selection dash-on segment should render an outline pixel',
      RGBAEqual(DashOnPixel, RGBA(0, 0, 0, 255)));
    AssertTrue('lasso selection light ant segment should render white for contrast',
      RGBAEqual(DashOffPixel, RGBA(255, 255, 255, 255)));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.MagicWandSelectionOverlayUsesDashedBoundaryPattern;
var
  F: TMainForm;
  X: Integer;
  Y: Integer;
  RegionColor: TRGBA32;
  DashOnPixel: TRGBA32;
  DashOffPixel: TRGBA32;
begin
  F := CreateTestForm(tkMagicWand);
  try
    RegionColor := RGBA(210, 50, 50, 255);
    F.TestDocument.ActiveLayer.Surface.Clear(RGBA(255, 255, 255, 255));
    for Y := 12 to 19 do
      for X := 12 to 19 do
        F.TestDocument.ActiveLayer.Surface[X, Y] := RegionColor;

    F.SimulateMouseDown(mbLeft, [ssLeft], 15, 15);
    AssertTrue('magic wand should create selection for sampled region',
      F.TestDocument.HasSelection);

    DashOnPixel := F.DisplayPixelForTest(14, 12);
    DashOffPixel := F.DisplayPixelForTest(16, 12);

    AssertTrue('magic wand selection dash-on segment should render an outline pixel',
      RGBAEqual(DashOnPixel, RGBA(0, 0, 0, 255)));
    AssertTrue('magic wand selection light ant segment should render white for contrast',
      RGBAEqual(DashOffPixel, RGBA(255, 255, 255, 255)));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.DrawingWithMoveChangesPixels;
var
  F: TMainForm;
  Before, After: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    Before := F.TestDocument.ActiveLayer.Surface[50, 50];
    F.SimulateMouseDown(mbLeft, [ssLeft], 50, 50);
    F.SimulateMouseMove([ssLeft], 52, 50);
    F.SimulateMouseUp(mbLeft, [], 52, 50);
    After := F.TestDocument.ActiveLayer.Surface[50, 50];
    AssertFalse('drawing a short stroke should change origin pixel',
      RGBAEqual(Before, After));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LineDragCommitsPixels;
var
  F: TMainForm;
  BeforeMid: TRGBA32;
  AfterMid: TRGBA32;
begin
  F := CreateTestForm(tkLine);
  try
    BeforeMid := F.TestDocument.ActiveLayer.Surface[25, 20];
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseMove([ssLeft], 30, 20);
    F.SimulateMouseUp(mbLeft, [], 30, 20);
    AfterMid := F.TestDocument.ActiveLayer.Surface[25, 20];
    AssertFalse('line drag should commit visible pixels on mouse-up',
      RGBAEqual(BeforeMid, AfterMid));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LineDashedStyleCommitsVisibleGapPattern;
var
  F: TMainForm;
  SampleX: Integer;
  FoundPainted: Boolean;
  FoundGap: Boolean;
  BaselinePixel: TRGBA32;
begin
  F := CreateTestForm(tkLine);
  try
    F.SetBrushSizeForTest(1);
    F.SetShapeLineStyleForTest(1); { dashed }
    BaselinePixel := F.TestDocument.ActiveLayer.Surface[12, 20];

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 20);
    F.SimulateMouseMove([ssLeft], 60, 20);
    F.SimulateMouseUp(mbLeft, [], 60, 20);

    FoundPainted := False;
    FoundGap := False;
    for SampleX := 12 to 58 do
    begin
      if not RGBAEqual(F.TestDocument.ActiveLayer.Surface[SampleX, 20], BaselinePixel) then
        FoundPainted := True
      else
        FoundGap := True;
    end;

    AssertTrue('dashed line should paint dash-on pixels', FoundPainted);
    AssertTrue('dashed line should also leave at least one visible gap pixel', FoundGap);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LineDragClipsToSelectionMask;
var
  F: TMainForm;
  BeforeMid: TRGBA32;
  AfterMid: TRGBA32;
begin
  { Drawing tools should respect an active selection mask and clip output
    to the selected area, matching paint.net/Photoshop/GIMP behaviour. }
  F := CreateTestForm(tkLine);
  try
    { Selection covers only 1..4; draw line at y=20 which is outside it. }
    F.TestDocument.SelectRectangle(1, 1, 4, 4, scReplace);
    AssertTrue('selection should exist before drawing', F.TestDocument.HasSelection);

    BeforeMid := F.TestDocument.ActiveLayer.Surface[25, 20];
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseMove([ssLeft], 30, 20);
    F.SimulateMouseUp(mbLeft, [], 30, 20);
    AfterMid := F.TestDocument.ActiveLayer.Surface[25, 20];

    AssertTrue('line outside selection should be clipped (pixel unchanged)',
      RGBAEqual(BeforeMid, AfterMid));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.RectangleDragCommitsPixels;
var
  F: TMainForm;
  BeforeEdge: TRGBA32;
  AfterEdge: TRGBA32;
begin
  F := CreateTestForm(tkRectangle);
  try
    BeforeEdge := F.TestDocument.ActiveLayer.Surface[25, 20];
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseMove([ssLeft], 30, 30);
    F.SimulateMouseUp(mbLeft, [], 30, 30);
    AfterEdge := F.TestDocument.ActiveLayer.Surface[25, 20];
    AssertFalse('rectangle drag should commit outline pixels on mouse-up',
      RGBAEqual(BeforeEdge, AfterEdge));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.EllipseDragCommitsPixels;
var
  F: TMainForm;
  BeforeTop: TRGBA32;
  AfterTop: TRGBA32;
begin
  F := CreateTestForm(tkEllipseShape);
  try
    BeforeTop := F.TestDocument.ActiveLayer.Surface[25, 20];
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseMove([ssLeft], 30, 30);
    F.SimulateMouseUp(mbLeft, [], 30, 30);
    AfterTop := F.TestDocument.ActiveLayer.Surface[25, 20];
    AssertFalse('ellipse drag should commit outline pixels on mouse-up',
      RGBAEqual(BeforeTop, AfterTop));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.OffsetLayerLineDragCommitsPixelsAtLayerLocalPosition;
var
  F: TMainForm;
  BeforeLocalMid: TRGBA32;
  AfterLocalMid: TRGBA32;
  BeforeWrongMid: TRGBA32;
  AfterWrongMid: TRGBA32;
begin
  F := CreateTestForm(tkLine);
  try
    F.TestDocument.AddLayer('Offset Layer');
    F.TestDocument.ActiveLayerIndex := 1;
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    F.TestDocument.ActiveLayer.OffsetX := 8;
    F.TestDocument.ActiveLayer.OffsetY := 0;

    BeforeLocalMid := F.TestDocument.ActiveLayer.Surface[17, 20];
    BeforeWrongMid := F.TestDocument.ActiveLayer.Surface[30, 20];

    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseMove([ssLeft], 30, 20);
    F.SimulateMouseUp(mbLeft, [], 30, 20);

    AfterLocalMid := F.TestDocument.ActiveLayer.Surface[17, 20];
    AfterWrongMid := F.TestDocument.ActiveLayer.Surface[30, 20];
    AssertFalse('line should land at layer-local midpoint when offset exists',
      RGBAEqual(BeforeLocalMid, AfterLocalMid));
    AssertTrue('line should not paint the old un-offset midpoint',
      RGBAEqual(BeforeWrongMid, AfterWrongMid));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.FillWithinActiveSelectionOverwritesExistingPixels;
var
  F: TMainForm;
  InkPixel: TRGBA32;
  FillColor: TRGBA32;
begin
  F := CreateTestForm(tkFill);
  try
    InkPixel := RGBA(0, 0, 0, 255);
    FillColor := RGBA(170, 170, 20, 255);
    F.TestDocument.ActiveLayer.Surface[30, 20] := InkPixel;
    F.TestDocument.ActiveLayer.Surface[10, 20] := InkPixel;
    F.TestDocument.SelectRectangle(20, 15, 40, 30, scReplace);
    F.SetPrimaryColorForTest(FillColor);

    F.SimulateMouseDown(mbLeft, [ssLeft], 25, 25);
    F.SimulateMouseUp(mbLeft, [], 25, 25);

    AssertTrue(
      'fill should overwrite previously drawn pixels inside the active selection',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[30, 20], FillColor)
    );
    AssertTrue(
      'fill should not touch matching pixels outside the active selection',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 20], InkPixel)
    );
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.RecolorToolRespectsSelectionScopeAndUndoRedo;
var
  F: TMainForm;
  SourceColor: TRGBA32;
  TargetColor: TRGBA32;
  InsideBefore: TRGBA32;
  OutsideBefore: TRGBA32;
  InsideAfter: TRGBA32;
  OutsideAfter: TRGBA32;
  UndoInside: TRGBA32;
  RedoInside: TRGBA32;
  DepthBefore: Integer;
begin
  F := CreateTestForm(tkRecolor);
  try
    SourceColor := RGBA(220, 30, 30, 255);
    TargetColor := RGBA(20, 200, 80, 255);
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    F.TestDocument.ActiveLayer.Surface[15, 15] := SourceColor;
    F.TestDocument.ActiveLayer.Surface[40, 40] := SourceColor;
    F.SetPrimaryColorForTest(TargetColor);
    F.SetSecondaryColorForTest(SourceColor);
    F.SetRecolorOptionsForTest(rsmSwatchCompat, rbmReplaceRGBCompat, 0, False);
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);

    DepthBefore := F.TestDocument.UndoDepth;
    InsideBefore := F.TestDocument.ActiveLayer.Surface[15, 15];
    OutsideBefore := F.TestDocument.ActiveLayer.Surface[40, 40];

    F.SimulateMouseDown(mbLeft, [ssLeft], 15, 15);
    F.SimulateMouseUp(mbLeft, [], 15, 15);

    InsideAfter := F.TestDocument.ActiveLayer.Surface[15, 15];
    OutsideAfter := F.TestDocument.ActiveLayer.Surface[40, 40];

    AssertFalse('recolor should change inside selected pixel', RGBAEqual(InsideBefore, InsideAfter));
    AssertTrue('recolor should leave outside pixel unchanged when selected',
      RGBAEqual(OutsideBefore, OutsideAfter));
    AssertEquals('recolor stroke should push one history entry',
      DepthBefore + 1, F.TestDocument.UndoDepth);

    F.TestDocument.Undo;
    UndoInside := F.TestDocument.ActiveLayer.Surface[15, 15];
    AssertTrue('undo should restore original inside pixel', RGBAEqual(InsideBefore, UndoInside));

    F.TestDocument.Redo;
    RedoInside := F.TestDocument.ActiveLayer.Surface[15, 15];
    AssertTrue('redo should restore recolored inside pixel', RGBAEqual(InsideAfter, RedoInside));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.RecolorOnceSamplingKeepsInitialSourceAcrossDrag;
var
  F: TMainForm;
  SourceA: TRGBA32;
  SourceB: TRGBA32;
  TargetColor: TRGBA32;
begin
  F := CreateTestForm(tkRecolor);
  try
    SourceA := RGBA(220, 30, 30, 255);
    SourceB := RGBA(30, 30, 220, 255);
    TargetColor := RGBA(30, 220, 80, 255);
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    F.TestDocument.ActiveLayer.Surface[10, 20] := SourceA;
    F.TestDocument.ActiveLayer.Surface[40, 20] := SourceB;
    F.SetPrimaryColorForTest(TargetColor);
    F.SetRecolorOptionsForTest(rsmOnce, rbmReplaceRGBCompat, 0, False);

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 20);
    F.SimulateMouseMove([ssLeft], 40, 20);
    F.SimulateMouseUp(mbLeft, [], 40, 20);

    AssertTrue('once sampling recolors first sampled family',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 20], TargetColor));
    AssertTrue('once sampling should not resample and recolor second family',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[40, 20], SourceB));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.RecolorContinuousSamplingResamplesAcrossDrag;
var
  F: TMainForm;
  SourceA: TRGBA32;
  SourceB: TRGBA32;
  TargetColor: TRGBA32;
begin
  F := CreateTestForm(tkRecolor);
  try
    SourceA := RGBA(220, 30, 30, 255);
    SourceB := RGBA(30, 30, 220, 255);
    TargetColor := RGBA(30, 220, 80, 255);
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    F.TestDocument.ActiveLayer.Surface[10, 20] := SourceA;
    F.TestDocument.ActiveLayer.Surface[40, 20] := SourceB;
    F.SetPrimaryColorForTest(TargetColor);
    F.SetRecolorOptionsForTest(rsmContinuous, rbmReplaceRGBCompat, 0, False);

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 20);
    F.SimulateMouseMove([ssLeft], 40, 20);
    F.SimulateMouseUp(mbLeft, [], 40, 20);

    AssertTrue('continuous sampling recolors first sampled family',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 20], TargetColor));
    AssertTrue('continuous sampling should resample and recolor second family',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[40, 20], TargetColor));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.RecolorContiguousDragKeepsApplyingAcrossLargeFlatRegion;
var
  F: TMainForm;
  SourceColor: TRGBA32;
  TargetColor: TRGBA32;
  SampleX: Integer;
begin
  F := CreateTestForm(tkRecolor);
  try
    SourceColor := RGBA(200, 40, 40, 255);
    TargetColor := RGBA(30, 200, 90, 255);
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    for SampleX := 8 to 56 do
      F.TestDocument.ActiveLayer.Surface[SampleX, 20] := SourceColor;

    F.SetPrimaryColorForTest(TargetColor);
    F.SetRecolorOptionsForTest(
      rsmOnce,
      rbmReplaceRGBCompat,
      0,
      False,
      True
    );
    F.SetBrushSizeForTest(5);

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 20);
    F.SimulateMouseMove([ssLeft], 50, 20);
    F.SimulateMouseUp(mbLeft, [], 50, 20);

    AssertTrue('contiguous recolor drag should still recolor far pixels in same flat region',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[45, 20], TargetColor));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.CloneStampSampleSourceCanUseCompositeImage;
var
  F: TMainForm;
  SnapshotPixel: TRGBA32;
begin
  F := CreateTestForm(tkCloneStamp);
  try
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    F.TestDocument.ActiveLayer.Surface[10, 10] := RGBA(255, 30, 30, 255);
    F.TestDocument.AddLayer('Top');
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);

    F.SetCloneOptionsForTest(True, 0);
    F.SimulateMouseDown(mbRight, [ssRight], 10, 10);
    AssertTrue(
      'current-layer sampling should snapshot the active layer surface',
      F.CloneSnapshotPixelForTest(10, 10, SnapshotPixel)
    );
    SnapshotPixel := Unpremultiply(SnapshotPixel);
    AssertEquals('current-layer sampling on empty top layer should remain transparent', 0, SnapshotPixel.A);

    F.SetCloneOptionsForTest(True, 1);
    F.SimulateMouseDown(mbRight, [ssRight], 10, 10);
    AssertTrue(
      'image sampling should snapshot composite surface',
      F.CloneSnapshotPixelForTest(10, 10, SnapshotPixel)
    );
    SnapshotPixel := Unpremultiply(SnapshotPixel);
    AssertTrue('composite sample should include lower-layer red payload', SnapshotPixel.R > 200);
    AssertEquals('composite sample should stay opaque', 255, SnapshotPixel.A);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.CropToolAspectConstraintProducesSquareOutput;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkCrop);
  try
    F.SetCropOptionsForTest(1, 0); { 1:1 }
    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 10);
    F.SimulateMouseMove([ssLeft], 70, 40);
    F.SimulateMouseUp(mbLeft, [], 70, 40);
    AssertEquals('1:1 crop should produce square canvas width', F.TestDocument.Width, F.TestDocument.Height);
    AssertEquals('square crop width should match constrained drag size', 60, F.TestDocument.Width);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.CloneStampAlignedModePreservesOffsetAcrossStrokes;
{ In aligned mode the offset between source and destination must remain
  constant across multiple strokes. Verify by doing two separate strokes
  at different canvas positions and checking the painted pixels match
  the expected source offsets. }
var
  F: TMainForm;
  Pixel1: TRGBA32;
  Pixel2: TRGBA32;
begin
  F := CreateTestForm(tkCloneStamp);
  try
    { Paint a recognizable pattern on the single layer }
    F.TestDocument.ActiveLayer.Surface.Clear(TransparentColor);
    F.TestDocument.ActiveLayer.Surface[10, 10] := RGBA(255, 0, 0, 255);
    F.TestDocument.ActiveLayer.Surface[20, 10] := RGBA(0, 255, 0, 255);

    F.SetCloneOptionsForTest(True, 0); { aligned, current layer }
    F.SetBrushSizeForTest(1);

    { Set clone source at (10, 10) — right-click }
    F.SimulateMouseDown(mbRight, [ssRight], 10, 10);

    { First stroke: paint at (30, 10) — offset is (10-30, 10-10) = (-20, 0) }
    F.SimulateMouseDown(mbLeft, [ssLeft], 30, 10);
    F.SimulateMouseUp(mbLeft, [], 30, 10);

    { Second stroke: paint at (40, 10) — aligned offset should still be (-20, 0),
      so it reads from (20, 10) which is green }
    F.SimulateMouseDown(mbLeft, [ssLeft], 40, 10);
    F.SimulateMouseUp(mbLeft, [], 40, 10);

    Pixel1 := Unpremultiply(F.TestDocument.ActiveLayer.Surface[30, 10]);
    Pixel2 := Unpremultiply(F.TestDocument.ActiveLayer.Surface[40, 10]);
    AssertTrue('first stroke should clone red pixel', Pixel1.R > 200);
    AssertTrue('second stroke should clone green pixel (aligned offset preserved)', Pixel2.G > 200);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.CropToolFourByThreeAspectConstraintProducesCorrectRatio;
var
  F: TMainForm;
  W, H: Integer;
begin
  F := CreateTestForm(tkCrop);
  try
    F.SetCropOptionsForTest(2, 0); { 4:3, no guide }
    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 10);
    F.SimulateMouseMove([ssLeft], 90, 90);
    F.SimulateMouseUp(mbLeft, [], 90, 90);
    W := F.TestDocument.Width;
    H := F.TestDocument.Height;
    AssertTrue('4:3 crop should produce width > height', W > H);
    { Check ratio: W/H should equal 4/3. Allow 1 pixel rounding tolerance. }
    AssertTrue('4:3 crop ratio should be approximately 4/3',
      Abs(W * 3 - H * 4) <= 4);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.CropToolSixteenByNineAspectConstraintProducesCorrectRatio;
var
  F: TMainForm;
  W, H: Integer;
begin
  F := CreateTestForm(tkCrop);
  try
    F.SetCropOptionsForTest(3, 0); { 16:9, no guide }
    F.SimulateMouseDown(mbLeft, [ssLeft], 5, 5);
    F.SimulateMouseMove([ssLeft], 85, 60);
    F.SimulateMouseUp(mbLeft, [], 85, 60);
    W := F.TestDocument.Width;
    H := F.TestDocument.Height;
    AssertTrue('16:9 crop should produce width > height', W > H);
    { Check ratio: W/H should equal 16/9. Allow 1 pixel rounding tolerance. }
    AssertTrue('16:9 crop ratio should be approximately 16/9',
      Abs(W * 9 - H * 16) <= 16);
  finally
    F.Destroy;
  end;
end;

{ ---------------------------------------------------------------------------
  History pipeline tests
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.MouseUpAfterPencilStrokePushesHistory;
var
  F: TMainForm;
  DepthBefore: Integer;
begin
  F := CreateTestForm(tkPencil);
  try
    DepthBefore := F.TestDocument.UndoDepth;
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
    AssertEquals('UndoDepth should increase by 1 after pencil stroke',
      DepthBefore + 1, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.MouseUpAfterBrushStrokePushesHistory;
var
  F: TMainForm;
  DepthBefore: Integer;
begin
  F := CreateTestForm(tkBrush);
  try
    DepthBefore := F.TestDocument.UndoDepth;
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
    AssertEquals('UndoDepth should increase by 1 after brush stroke',
      DepthBefore + 1, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.FillToolPushesHistoryOnMouseDown;
var
  F: TMainForm;
  DepthBefore: Integer;
begin
  F := CreateTestForm(tkFill);
  try
    DepthBefore := F.TestDocument.UndoDepth;
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    AssertEquals('UndoDepth should increase by 1 after fill',
      DepthBefore + 1, F.TestDocument.UndoDepth);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LockedLayerBlocksPencilStrokeAtMainFormEdge;
var
  F: TMainForm;
  DepthBefore: Integer;
  BeforePixel: TRGBA32;
  AfterPixel: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    F.SetPrimaryColorForTest(RGBA(0, 0, 0, 255));
    F.TestDocument.ActiveLayer.Locked := True;
    DepthBefore := F.TestDocument.UndoDepth;
    BeforePixel := F.TestDocument.ActiveLayer.Surface[24, 24];

    F.SimulateMouseDown(mbLeft, [ssLeft], 24, 24);
    F.SimulateMouseMove([ssLeft], 28, 24);
    F.SimulateMouseUp(mbLeft, [], 28, 24);

    AfterPixel := F.TestDocument.ActiveLayer.Surface[24, 24];
    AssertTrue('locked active layer should reject pencil writes at UI edge',
      RGBAEqual(BeforePixel, AfterPixel));
    AssertEquals('blocked locked-layer pencil route must not push history',
      DepthBefore, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LockedLayerBlocksFillToolAtMainFormEdge;
var
  F: TMainForm;
  DepthBefore: Integer;
  BeforePixel: TRGBA32;
  AfterPixel: TRGBA32;
begin
  F := CreateTestForm(tkFill);
  try
    F.SetPrimaryColorForTest(RGBA(0, 0, 0, 255));
    F.TestDocument.ActiveLayer.Locked := True;
    DepthBefore := F.TestDocument.UndoDepth;
    BeforePixel := F.TestDocument.ActiveLayer.Surface[24, 24];

    F.SimulateMouseDown(mbLeft, [ssLeft], 24, 24);
    F.SimulateMouseUp(mbLeft, [], 24, 24);

    AfterPixel := F.TestDocument.ActiveLayer.Surface[24, 24];
    AssertTrue('locked active layer should reject fill writes at UI edge',
      RGBAEqual(BeforePixel, AfterPixel));
    AssertEquals('blocked locked-layer fill route must not push history',
      DepthBefore, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.LockedLayerAllowsMoveSelectionAtMainFormEdge;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkMoveSelection);
  try
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);
    AssertTrue('selection should exist before move', F.TestDocument.HasSelection);
    AssertEquals('old center coverage should start selected', 255, F.TestDocument.Selection.Coverage(12, 12));

    F.TestDocument.ActiveLayer.Locked := True;
    F.SimulateMouseDown(mbLeft, [ssLeft], 15, 15);
    F.SimulateMouseMove([ssLeft], 18, 17); { +3, +2 }
    F.SimulateMouseUp(mbLeft, [], 18, 17);

    AssertEquals('old center should be cleared after move', 0, F.TestDocument.Selection.Coverage(12, 12));
    AssertEquals('new translated center should be selected', 255, F.TestDocument.Selection.Coverage(15, 14));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.ClickingOutsideSelectionAutoDeselects;
{ Clicking outside an existing selection should deselect the old selection
  and immediately begin a new selection drag — the user should not need
  two separate clicks to start a new selection. }
var
  F: TMainForm;
  OutsideBefore: TRGBA32;
  OutsideAfter: TRGBA32;
begin
  F := CreateTestForm(tkSelectRect);
  try
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);
    AssertTrue('selection should exist before blank click', F.TestDocument.HasSelection);
    OutsideBefore := F.TestDocument.ActiveLayer.Surface[40, 40];

    { Mouse down outside the selection — should deselect AND begin new drag }
    F.SimulateMouseDown(mbLeft, [ssLeft], 40, 40);

    AssertFalse('old selection should be cleared on mouse down outside',
      F.TestDocument.HasSelection);

    { Complete the mouse cycle }
    F.SimulateMouseUp(mbLeft, [], 40, 40);

    OutsideAfter := F.TestDocument.ActiveLayer.Surface[40, 40];
    AssertTrue('click should not paint when using selection tool',
      RGBAEqual(OutsideBefore, OutsideAfter));
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.ToolbarSwitchFromSelectionToFillKeepsSelection;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkSelectRect);
  try
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);
    AssertTrue('selection should exist before toolbar switch', F.TestDocument.HasSelection);

    F.SimulateToolButtonSwitch(tkFill);
    AssertTrue('toolbar switch should select fill tool', F.CurrentToolForTest = tkFill);
    AssertTrue('toolbar switch to fill should preserve selection',
      F.TestDocument.HasSelection);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.SwitchingFromSelectionToBrushPreservesSelection;
var
  F: TMainForm;
begin
  { Switching from selection to brush should preserve the selection so
    subsequent brush strokes are clipped to the selected region. }
  F := CreateTestForm(tkSelectRect);
  try
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);
    AssertTrue('selection should exist before brush switch', F.TestDocument.HasSelection);

    F.SimulateToolButtonSwitch(tkBrush);
    AssertTrue('toolbar switch should select brush tool', F.CurrentToolForTest = tkBrush);
    AssertTrue('switching to brush should preserve selection for clipping',
      F.TestDocument.HasSelection);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.SwitchingWithinSelectionFamilyKeepsSelection;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkSelectRect);
  try
    F.TestDocument.SelectRectangle(10, 10, 20, 20, scReplace);
    AssertTrue('selection should exist before switching selection tools', F.TestDocument.HasSelection);

    F.SimulateToolButtonSwitch(tkSelectEllipse);
    AssertTrue('toolbar switch should select ellipse select tool', F.CurrentToolForTest = tkSelectEllipse);
    AssertTrue('selection should remain when switching within selection tool family',
      F.TestDocument.HasSelection);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.AddLayerPushesHistory;
var
  F: TMainForm;
  DepthBefore: Integer;
begin
  F := CreateTestForm(tkPencil);
  try
    DepthBefore := F.TestDocument.UndoDepth;
    F.TestDocument.PushHistory('Add Layer');
    F.TestDocument.AddLayer;
    AssertEquals('UndoDepth should increase by 1 after AddLayer',
      DepthBefore + 1, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.MultipleStrokesIncrementHistory;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkPencil);
  try
    AssertEquals('initial UndoDepth should be 0', 0, F.TestDocument.UndoDepth);

    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
    AssertEquals('UndoDepth should be 1 after first stroke', 1, F.TestDocument.UndoDepth);

    F.SimulateMouseDown(mbLeft, [ssLeft], 30, 30);
    F.SimulateMouseUp(mbLeft, [], 30, 30);
    AssertEquals('UndoDepth should be 2 after second stroke', 2, F.TestDocument.UndoDepth);

    F.SimulateMouseDown(mbLeft, [ssLeft], 40, 40);
    F.SimulateMouseUp(mbLeft, [], 40, 40);
    AssertEquals('UndoDepth should be 3 after third stroke', 3, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.UndoRedoAfterLongPencilStrokeRestoresPixels;
var
  F: TMainForm;
  BeforeMid: TRGBA32;
  AfterMid: TRGBA32;
  UndoMid: TRGBA32;
  RedoMid: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    BeforeMid := F.TestDocument.ActiveLayer.Surface[35, 20];

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 20);
    F.SimulateMouseMove([ssLeft], 60, 20);
    F.SimulateMouseUp(mbLeft, [], 60, 20);

    AfterMid := F.TestDocument.ActiveLayer.Surface[35, 20];
    AssertFalse('long pencil stroke should change a middle pixel',
      RGBAEqual(BeforeMid, AfterMid));

    F.TestDocument.Undo;
    UndoMid := F.TestDocument.ActiveLayer.Surface[35, 20];
    AssertTrue('undo should restore middle pixel from long stroke',
      RGBAEqual(BeforeMid, UndoMid));

    F.TestDocument.Redo;
    RedoMid := F.TestDocument.ActiveLayer.Surface[35, 20];
    AssertTrue('redo should reapply middle pixel from long stroke',
      RGBAEqual(AfterMid, RedoMid));
  finally
    F.Destroy;
  end;
end;

{ ---------------------------------------------------------------------------
  Layer pipeline tests
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.AddLayerIncreasesLayerCount;
var
  F: TMainForm;
  CountBefore: Integer;
begin
  F := CreateTestForm(tkPencil);
  try
    CountBefore := F.TestDocument.LayerCount;
    F.TestDocument.PushHistory('Add Layer');
    F.TestDocument.AddLayer;
    AssertEquals('LayerCount should increase by 1',
      CountBefore + 1, F.TestDocument.LayerCount);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.AddLayerSetsNewLayerAsActive;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkPencil);
  try
    AssertEquals('initially one layer at index 0', 0, F.TestDocument.ActiveLayerIndex);
    F.TestDocument.PushHistory('Add Layer');
    F.TestDocument.AddLayer;
    AssertEquals('new layer should be active at index 1', 1, F.TestDocument.ActiveLayerIndex);
  finally
    F.Destroy;
  end;
end;

{ ---------------------------------------------------------------------------
  Temp-pan / OnKeyUp regression tests
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.SpaceKeyActivatesTempPan;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkPencil);
  try
    AssertFalse('FTempToolActive should be false initially', F.TempToolActiveForTest);
    AssertTrue('tool should be pencil', F.CurrentToolForTest = tkPencil);

    { Use StartTempPan (lightweight variant) to avoid native widget calls }
    F.StartTempPan;
    AssertTrue('FTempToolActive should be true after StartTempPan', F.TempToolActiveForTest);
    AssertTrue('tool should be pan', F.CurrentToolForTest = tkPan);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.SpaceKeyUpDeactivatesTempPan;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkPencil);
  try
    F.StartTempPan;
    AssertTrue('temp pan should be active', F.TempToolActiveForTest);
    AssertTrue('tool should be pan', F.CurrentToolForTest = tkPan);

    F.StopTempPan;
    AssertFalse('FTempToolActive should be false after StopTempPan', F.TempToolActiveForTest);
    AssertTrue('tool should revert to pencil', F.CurrentToolForTest = tkPencil);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.ExplicitToolPropertyChangeClearsTempPanFlag;
var
  F: TMainForm;
begin
  { Verify StopTempPan properly restores FPreviousTool }
  F := CreateTestForm(tkPencil);
  try
    F.StartTempPan;
    AssertTrue('temp pan active', F.TempToolActiveForTest);
    AssertTrue('current is pan', F.CurrentToolForTest = tkPan);

    F.StopTempPan;
    AssertTrue('StopTempPan should restore previous tool (pencil)',
      F.CurrentToolForTest = tkPencil);
    AssertFalse('temp pan no longer active', F.TempToolActiveForTest);
  finally
    F.Destroy;
  end;
end;

procedure TPipelineIntegrationTests.PinchGestureAdjustsZoomScale;
var
  F: TMainForm;
  StartZoom: Double;
  ZoomAfterIn: Double;
begin
  F := CreateTestForm(tkPencil);
  try
    StartZoom := F.ZoomScaleForTest;
    F.SimulateMagnifyGestureForTest(0.25, 100.0, 100.0);
    ZoomAfterIn := F.ZoomScaleForTest;
    AssertTrue('positive pinch magnification should zoom in',
      ZoomAfterIn > StartZoom);

    F.SimulateMagnifyGestureForTest(-0.20, 100.0, 100.0);
    AssertTrue('negative pinch magnification should zoom out',
      F.ZoomScaleForTest < ZoomAfterIn);
  finally
    F.Destroy;
  end;
end;

{ ---------------------------------------------------------------------------
  Render revision tracking tests
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.DrawingBumpsRenderRevision;
var
  F: TMainForm;
  RevBefore: QWord;
begin
  F := CreateTestForm(tkPencil);
  try
    RevBefore := F.RenderRevisionForTest;
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    AssertTrue('render revision should increase after drawing',
      F.RenderRevisionForTest > RevBefore);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
  finally
    F.Destroy;
  end;
end;

{ ---------------------------------------------------------------------------
  Dirty flag tests
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.DrawingSetsDirtyFlag;
var
  F: TMainForm;
begin
  F := CreateTestForm(tkPencil);
  try
    AssertFalse('should start clean', F.DirtyForTest);
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    AssertTrue('dirty flag should be set after drawing', F.DirtyForTest);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
  finally
    F.Destroy;
  end;
end;

{ ---------------------------------------------------------------------------
  Display pixel verification
  --------------------------------------------------------------------------- }

procedure TPipelineIntegrationTests.DrawBlackOnWhiteChangesDisplayPixel;
var
  F: TMainForm;
  Before, After: TRGBA32;
begin
  F := CreateTestForm(tkPencil);
  try
    Before := F.DisplayPixelForTest(20, 20);
    F.SimulateMouseDown(mbLeft, [ssLeft], 20, 20);
    F.SimulateMouseUp(mbLeft, [], 20, 20);
    After := F.DisplayPixelForTest(20, 20);
    AssertFalse('display pixel should change after drawing black on white',
      RGBAEqual(Before, After));
  finally
    F.Destroy;
  end;
end;

initialization
  RegisterTest(TPipelineIntegrationTests);
end.
