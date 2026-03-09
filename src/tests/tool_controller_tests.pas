unit tool_controller_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Types, FPColor, FPSelection, FPDocument, FPToolControllers;

type
  TToolControllerTests = class(TTestCase)
  published
    procedure StrokeControllerCommitRestoresViaUndo;
    procedure StrokeControllerUnionCapturePreservesEarlierOriginalPixels;
    procedure MovePixelsControllerCommitMovesPixelsAndSelection;
    procedure MovePixelsControllerUndoRedoRestoresSelectionAndPixels;
    procedure MovePixelsControllerBackgroundCommitKeepsOpaqueFillAndUndo;
    procedure MovePixelsControllerBeginSessionBlockedByLockedLayer;
    procedure MovePixelsControllerCommitBlockedByLockedLayer;
    procedure MovePixelsControllerCancelRestoresSelectionWithoutHistory;
    procedure SelectionModeMappingFollowsModifierContract;
    procedure SelectionRectangleCommitPushesHistoryAndSelection;
    procedure SelectionFeatherIndependentFromAntiAliasToggle;
    procedure SelectionMoveControllerPushesHistoryAndMovesMask;
    procedure SelectionMagicWandCommitPushesHistoryAndSelectsSample;
  end;

implementation

procedure TToolControllerTests.StrokeControllerCommitRestoresViaUndo;
var
  Doc: TImageDocument;
  Controller: TStrokeHistoryController;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(16, 16);
  Controller := TStrokeHistoryController.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[5, 5] := RGBA(220, 10, 20, 255);

    Controller.BeginSession(Doc, tkPencil, Doc.ActiveLayerIndex);
    Controller.CaptureBeforeRect(Doc, Rect(4, 4, 7, 7));
    Doc.ActiveLayer.Surface[5, 5] := RGBA(10, 20, 230, 255);

    AssertTrue('commit should push one region history entry',
      Controller.CommitToHistory(Doc, 'Stroke'));
    AssertEquals('history depth should be 1 after commit', 1, Doc.UndoDepth);

    Doc.Undo;
    Pixel := Doc.ActiveLayer.Surface[5, 5];
    AssertEquals('undo restores red channel', 220, Pixel.R);
    AssertEquals('undo restores green channel', 10, Pixel.G);
    AssertEquals('undo restores blue channel', 20, Pixel.B);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.StrokeControllerUnionCapturePreservesEarlierOriginalPixels;
var
  Doc: TImageDocument;
  Controller: TStrokeHistoryController;
  PixelA: TRGBA32;
  PixelB: TRGBA32;
begin
  Doc := TImageDocument.Create(24, 24);
  Controller := TStrokeHistoryController.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[5, 5] := RGBA(255, 0, 0, 255);
    Doc.ActiveLayer.Surface[15, 5] := RGBA(0, 255, 0, 255);

    Controller.BeginSession(Doc, tkBrush, Doc.ActiveLayerIndex);
    Controller.CaptureBeforeRect(Doc, Rect(4, 4, 7, 7));
    Doc.ActiveLayer.Surface[5, 5] := RGBA(0, 0, 255, 255);      { mutate first segment }
    Controller.CaptureBeforeRect(Doc, Rect(14, 4, 17, 7));      { expand capture after mutation }
    Doc.ActiveLayer.Surface[15, 5] := RGBA(255, 255, 0, 255);   { mutate second segment }

    AssertTrue('commit should succeed for union-captured regions',
      Controller.CommitToHistory(Doc, 'Long Stroke'));
    Doc.Undo;

    PixelA := Doc.ActiveLayer.Surface[5, 5];
    PixelB := Doc.ActiveLayer.Surface[15, 5];
    AssertTrue('undo restores first segment original red pixel',
      RGBAEqual(PixelA, RGBA(255, 0, 0, 255)));
    AssertTrue('undo restores second segment original green pixel',
      RGBAEqual(PixelB, RGBA(0, 255, 0, 255)));
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.MovePixelsControllerCommitMovesPixelsAndSelection;
var
  Doc: TImageDocument;
  Controller: TMovePixelsController;
  CommitResult: TMovePixelsCommitResult;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TMovePixelsController.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[3, 3] := RGBA(200, 40, 20, 255);
    Doc.SelectRectangle(3, 3, 3, 3);

    Controller.BeginSession(Doc, RGBA(255, 255, 255, 255));
    AssertTrue('session should activate when selection exists', Controller.Active);
    AssertTrue('delta update should be accepted', Controller.UpdateDelta(Doc, 2, 0));
    CommitResult := Controller.Commit(Doc, 'Move Pixels', RGBA(255, 255, 255, 255));
    AssertEquals('commit should report committed state', Ord(mpcCommitted), Ord(CommitResult));
    AssertEquals('history should record one move operation', 1, Doc.UndoDepth);

    Pixel := Doc.ActiveLayer.Surface[3, 3];
    AssertEquals('source pixel should be erased after commit', 0, Pixel.A);
    Pixel := Doc.ActiveLayer.Surface[5, 3];
    AssertEquals('destination pixel keeps moved red channel', 200, Pixel.R);
    AssertEquals('destination pixel keeps alpha', 255, Pixel.A);
    AssertTrue('selection moved with pixels', Doc.Selection[5, 3]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.MovePixelsControllerUndoRedoRestoresSelectionAndPixels;
var
  Doc: TImageDocument;
  Controller: TMovePixelsController;
  CommitResult: TMovePixelsCommitResult;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TMovePixelsController.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[3, 3] := RGBA(200, 40, 20, 255);
    Doc.SelectRectangle(3, 3, 3, 3);

    Controller.BeginSession(Doc, RGBA(255, 255, 255, 255));
    AssertTrue('session should activate when selection exists', Controller.Active);
    AssertTrue('delta update should be accepted', Controller.UpdateDelta(Doc, 2, 0));
    CommitResult := Controller.Commit(Doc, 'Move Pixels', RGBA(255, 255, 255, 255));
    AssertEquals('commit should report committed state', Ord(mpcCommitted), Ord(CommitResult));
    AssertEquals('history should record one move operation', 1, Doc.UndoDepth);

    Doc.Undo;
    Pixel := Doc.ActiveLayer.Surface[3, 3];
    AssertEquals('undo restores source pixel red channel', 200, Pixel.R);
    AssertEquals('undo restores source pixel alpha', 255, Pixel.A);
    Pixel := Doc.ActiveLayer.Surface[5, 3];
    AssertEquals('undo clears destination pixel alpha', 0, Pixel.A);
    AssertTrue('undo restores original selection location', Doc.Selection[3, 3]);
    AssertFalse('undo clears moved selection location', Doc.Selection[5, 3]);

    Doc.Redo;
    Pixel := Doc.ActiveLayer.Surface[3, 3];
    AssertEquals('redo clears source pixel alpha', 0, Pixel.A);
    Pixel := Doc.ActiveLayer.Surface[5, 3];
    AssertEquals('redo restores destination pixel red channel', 200, Pixel.R);
    AssertEquals('redo restores destination pixel alpha', 255, Pixel.A);
    AssertTrue('redo restores moved selection location', Doc.Selection[5, 3]);
    AssertFalse('redo clears original selection location', Doc.Selection[3, 3]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.MovePixelsControllerBackgroundCommitKeepsOpaqueFillAndUndo;
var
  Doc: TImageDocument;
  Controller: TMovePixelsController;
  CommitResult: TMovePixelsCommitResult;
  Pixel: TRGBA32;
  FillColor: TRGBA32;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TMovePixelsController.Create;
  try
    FillColor := RGBA(10, 20, 30, 255);
    Doc.ActiveLayer.Surface.Clear(RGBA(255, 255, 255, 255));
    Doc.ActiveLayer.Surface[3, 3] := RGBA(200, 40, 20, 255);
    Doc.SelectRectangle(3, 3, 3, 3);

    Controller.BeginSession(Doc, FillColor);
    AssertTrue('session should activate on background layer', Controller.Active);
    AssertTrue('delta update should be accepted', Controller.UpdateDelta(Doc, 2, 0));
    CommitResult := Controller.Commit(Doc, 'Move Pixels', FillColor);
    AssertEquals('commit should report committed state', Ord(mpcCommitted), Ord(CommitResult));

    Pixel := Doc.ActiveLayer.Surface[3, 3];
    AssertTrue('background source fill should remain opaque and match fill color', RGBAEqual(Pixel, FillColor));
    Pixel := Doc.ActiveLayer.Surface[5, 3];
    AssertTrue('destination keeps moved foreground pixel', RGBAEqual(Pixel, RGBA(200, 40, 20, 255)));

    Doc.Undo;
    Pixel := Doc.ActiveLayer.Surface[3, 3];
    AssertTrue('undo restores original source pixel', RGBAEqual(Pixel, RGBA(200, 40, 20, 255)));
    Pixel := Doc.ActiveLayer.Surface[5, 3];
    AssertTrue('undo restores original background at destination', RGBAEqual(Pixel, RGBA(255, 255, 255, 255)));
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.MovePixelsControllerBeginSessionBlockedByLockedLayer;
var
  Doc: TImageDocument;
  Controller: TMovePixelsController;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TMovePixelsController.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[3, 3] := RGBA(200, 40, 20, 255);
    Doc.SelectRectangle(3, 3, 3, 3);
    Doc.ActiveLayer.Locked := True;

    Controller.BeginSession(Doc, RGBA(255, 255, 255, 255));
    AssertFalse('locked layer should prevent move-pixels session begin', Controller.Active);
    AssertEquals('blocked begin must not create history', 0, Doc.UndoDepth);
    AssertTrue('selection remains on original pixel after blocked begin', Doc.Selection[3, 3]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.MovePixelsControllerCommitBlockedByLockedLayer;
var
  Doc: TImageDocument;
  Controller: TMovePixelsController;
  CommitResult: TMovePixelsCommitResult;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TMovePixelsController.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[3, 3] := RGBA(200, 40, 20, 255);
    Doc.SelectRectangle(3, 3, 3, 3);

    Controller.BeginSession(Doc, RGBA(255, 255, 255, 255));
    AssertTrue('session should activate when selection exists', Controller.Active);
    AssertTrue('delta update should be accepted', Controller.UpdateDelta(Doc, 2, 0));
    Doc.ActiveLayer.Locked := True;

    CommitResult := Controller.Commit(Doc, 'Move Pixels', RGBA(255, 255, 255, 255));
    AssertEquals('locked layer should block commit', Ord(mpcBlocked), Ord(CommitResult));
    AssertEquals('blocked commit should not push history', 0, Doc.UndoDepth);

    Pixel := Doc.ActiveLayer.Surface[3, 3];
    AssertEquals('source pixel should stay untouched when blocked', 200, Pixel.R);
    AssertTrue('selection should return to original location when blocked', Doc.Selection[3, 3]);
    AssertFalse('selection should not stay at moved location when blocked', Doc.Selection[5, 3]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.MovePixelsControllerCancelRestoresSelectionWithoutHistory;
var
  Doc: TImageDocument;
  Controller: TMovePixelsController;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TMovePixelsController.Create;
  try
    Doc.SelectRectangle(2, 2, 2, 2);
    Controller.BeginSession(Doc, RGBA(255, 255, 255, 255));
    Controller.UpdateDelta(Doc, 3, 0);
    AssertTrue('cancel should report active session', Controller.Cancel(Doc));
    AssertEquals('cancel should not push history', 0, Doc.UndoDepth);
    AssertTrue('selection should return to original location', Doc.Selection[2, 2]);
    AssertFalse('selection should not stay at moved location', Doc.Selection[5, 2]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.SelectionModeMappingFollowsModifierContract;
begin
  AssertEquals(
    'no modifiers should map to replace',
    Ord(scReplace),
    Ord(TSelectionToolController.ModeFromModifiers(False, False))
  );
  AssertEquals(
    'Shift should map to add',
    Ord(scAdd),
    Ord(TSelectionToolController.ModeFromModifiers(True, False))
  );
  AssertEquals(
    'Alt should map to subtract',
    Ord(scSubtract),
    Ord(TSelectionToolController.ModeFromModifiers(False, True))
  );
  AssertEquals(
    'Shift+Alt should map to intersect',
    Ord(scIntersect),
    Ord(TSelectionToolController.ModeFromModifiers(True, True))
  );
end;

procedure TToolControllerTests.SelectionRectangleCommitPushesHistoryAndSelection;
var
  Doc: TImageDocument;
  Controller: TSelectionToolController;
begin
  Doc := TImageDocument.Create(20, 20);
  Controller := TSelectionToolController.Create;
  try
    AssertTrue(
      'rectangle commit should report success',
      Controller.CommitRectangleSelection(
        Doc,
        Point(2, 2),
        Point(8, 8),
        scReplace,
        True,
        2,
        0,
        'Rect Select'
      )
    );
    AssertEquals('history should include rectangle selection commit', 1, Doc.UndoDepth);
    AssertTrue('center point should be selected', Doc.Selection[5, 5]);
    AssertTrue('selection mask should be non-empty', Doc.HasSelection);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.SelectionFeatherIndependentFromAntiAliasToggle;
var
  Doc: TImageDocument;
  Controller: TSelectionToolController;
begin
  Doc := TImageDocument.Create(24, 24);
  Controller := TSelectionToolController.Create;
  try
    AssertTrue(
      'rectangle commit with anti-alias disabled should still succeed',
      Controller.CommitRectangleSelection(
        Doc,
        Point(6, 6),
        Point(15, 15),
        scReplace,
        False,
        2,
        0,
        'Rect Select'
      )
    );
    AssertEquals('history should include selection commit', 1, Doc.UndoDepth);
    AssertEquals('center remains selected', 255, Doc.Selection.Coverage(10, 10));
    AssertTrue(
      'feather should still soften outside edge even with anti-alias disabled',
      Doc.Selection.Coverage(5, 10) > 0
    );
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.SelectionMoveControllerPushesHistoryAndMovesMask;
var
  Doc: TImageDocument;
  Controller: TSelectionToolController;
begin
  Doc := TImageDocument.Create(20, 20);
  Controller := TSelectionToolController.Create;
  try
    Doc.SelectRectangle(2, 2, 4, 4);
    AssertTrue(
      'begin move should succeed when selection exists',
      Controller.BeginMoveSelection(Doc, 'Move Selection')
    );
    AssertEquals('begin move should push one history entry', 1, Doc.UndoDepth);
    AssertTrue(
      'move step should report mutation',
      Controller.MoveSelectionStep(Doc, 3, -1)
    );
    AssertTrue('selection should move to translated location', Doc.Selection[6, 2]);
    AssertFalse('source location should be cleared after move', Doc.Selection[3, 3]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

procedure TToolControllerTests.SelectionMagicWandCommitPushesHistoryAndSelectsSample;
var
  Doc: TImageDocument;
  Controller: TSelectionToolController;
  X: Integer;
  Y: Integer;
begin
  Doc := TImageDocument.Create(12, 12);
  Controller := TSelectionToolController.Create;
  try
    for Y := 0 to Doc.Height - 1 do
      for X := 0 to Doc.Width - 1 do
        Doc.ActiveLayer.Surface[X, Y] := RGBA(0, 0, 0, 255);
    for Y := 3 to 7 do
      for X := 3 to 7 do
        Doc.ActiveLayer.Surface[X, Y] := RGBA(250, 0, 0, 255);

    AssertTrue(
      'magic wand commit should report success',
      Controller.CommitMagicWandSelection(
        Doc,
        Point(5, 5),
        0,
        scReplace,
        False,
        True,
        0,
        'Magic Wand'
      )
    );
    AssertEquals('history should include magic-wand selection commit', 1, Doc.UndoDepth);
    AssertTrue('sampled region should be selected', Doc.Selection[5, 5]);
    AssertFalse('different-color region should remain unselected', Doc.Selection[1, 1]);
  finally
    Controller.Free;
    Doc.Free;
  end;
end;

initialization
  RegisterTest(TToolControllerTests);

end.
