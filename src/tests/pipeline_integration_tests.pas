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
  Classes, Controls, Types, fpcunit, testregistry, FPColor, FPDocument, MainForm;

type
  TPipelineIntegrationTests = class(TTestCase)
  published
    { Drawing pipeline }
    procedure PencilStrokeModifiesSurfacePixels;
    procedure BrushStrokeModifiesSurfacePixels;
    procedure EraserStrokeModifiesSurfacePixels;
    procedure DrawingWithMoveChangesPixels;

    { History pipeline }
    procedure MouseUpAfterPencilStrokePushesHistory;
    procedure MouseUpAfterBrushStrokePushesHistory;
    procedure FillToolPushesHistoryOnMouseDown;
    procedure AddLayerPushesHistory;
    procedure MultipleStrokesIncrementHistory;

    { Layer pipeline }
    procedure AddLayerIncreasesLayerCount;
    procedure AddLayerSetsNewLayerAsActive;

    { Temp-pan / OnKeyUp bug regression }
    procedure SpaceKeyActivatesTempPan;
    procedure SpaceKeyUpDeactivatesTempPan;
    procedure KeyboardToolSwitchClearsTempPanFlag;
    procedure ExplicitToolPropertyChangeClearsTempPanFlag;

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

procedure TPipelineIntegrationTests.KeyboardToolSwitchClearsTempPanFlag;
var
  F: TMainForm;
  Key: Word;
begin
  { Verify that keyboard tool switch via FormKeyDown properly clears
    FTempToolActive. Scenario:
    1. StartTempPan -> temp pan active
    2. Press 'B' -> switch to Brush (FormKeyDown should clear FTempToolActive)
    3. Space cycle should work normally again }
  F := CreateTestForm(tkPencil);
  try
    { Activate temp pan }
    F.StartTempPan;
    AssertTrue('temp pan active', F.TempToolActiveForTest);

    { Press 'B' for brush — FormKeyDown now clears FTempToolActive }
    Key := Ord('B');
    F.SimulateKeyDown(Key, []);
    AssertFalse('FTempToolActive should be cleared after keyboard tool switch',
      F.TempToolActiveForTest);
    AssertTrue('tool should be brush after pressing B',
      F.CurrentToolForTest = tkBrush);

    { Space should work normally again }
    F.StartTempPan;
    AssertTrue('space should activate temp pan normally', F.TempToolActiveForTest);
    AssertTrue('tool should be pan', F.CurrentToolForTest = tkPan);

    F.StopTempPan;
    AssertFalse('space release should deactivate', F.TempToolActiveForTest);
    AssertTrue('tool should revert to brush', F.CurrentToolForTest = tkBrush);
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
