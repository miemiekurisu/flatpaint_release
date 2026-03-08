unit tool_transaction_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, Controls, Types, fpcunit, testregistry, LCLType,
  FPColor, FPDocument, FPSelection, MainForm;

type
  TToolTransactionTests = class(TTestCase)
  private
    function CreateMovePixelsForm: TMainForm;
  published
    procedure MovePixelsDragDoesNotMutateLayerBeforeMouseUp;
    procedure MovePixelsClickWithoutDeltaDoesNotPushHistory;
    procedure MovePixelsEscapeCancelsPreviewAndRestoresSelection;
    procedure MovePixelsToolSwitchCancelsPreviewAndRestoresSelection;
  end;

implementation

function TToolTransactionTests.CreateMovePixelsForm: TMainForm;
begin
  Result := TMainForm.CreateForTesting;
  Result.CurrentToolForTest := tkMovePixels;
  Result.TestDocument.AddLayer('Paint');
  Result.TestDocument.ActiveLayerIndex := 1;
  Result.TestDocument.ActiveLayer.Surface[10, 10] := RGBA(255, 0, 0, 255);
  Result.TestDocument.SelectRectangle(10, 10, 10, 10, scReplace);
end;

procedure TToolTransactionTests.MovePixelsDragDoesNotMutateLayerBeforeMouseUp;
var
  F: TMainForm;
  MoveColor: TRGBA32;
  DepthBefore: Integer;
begin
  F := CreateMovePixelsForm;
  try
    MoveColor := RGBA(255, 0, 0, 255);
    DepthBefore := F.TestDocument.UndoDepth;

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 10);
    F.SimulateMouseMove([ssLeft], 12, 10);

    AssertTrue(
      'source pixel should stay intact before commit',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 10], MoveColor)
    );
    AssertTrue(
      'destination should remain unchanged before commit',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[12, 10], TransparentColor)
    );
    AssertFalse('selection should leave source during drag', F.TestDocument.Selection[10, 10]);
    AssertTrue('selection should preview at destination during drag', F.TestDocument.Selection[12, 10]);
    AssertEquals('drag preview should not push history', DepthBefore, F.TestDocument.UndoDepth);

    F.SimulateMouseUp(mbLeft, [], 12, 10);

    AssertTrue(
      'source should clear after commit',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 10], TransparentColor)
    );
    AssertTrue(
      'destination should receive moved pixel after commit',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[12, 10], MoveColor)
    );
    AssertFalse('selection should no longer include source after commit', F.TestDocument.Selection[10, 10]);
    AssertTrue('selection should remain at destination after commit', F.TestDocument.Selection[12, 10]);
    AssertEquals('commit should push exactly one history entry', DepthBefore + 1, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TToolTransactionTests.MovePixelsClickWithoutDeltaDoesNotPushHistory;
var
  F: TMainForm;
  MoveColor: TRGBA32;
  DepthBefore: Integer;
begin
  F := CreateMovePixelsForm;
  try
    MoveColor := RGBA(255, 0, 0, 255);
    DepthBefore := F.TestDocument.UndoDepth;

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 10);
    F.SimulateMouseUp(mbLeft, [], 10, 10);

    AssertTrue('click without drag should keep source pixel', RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 10], MoveColor));
    AssertTrue('click without drag should not touch destination', RGBAEqual(F.TestDocument.ActiveLayer.Surface[12, 10], TransparentColor));
    AssertTrue('selection should stay at source', F.TestDocument.Selection[10, 10]);
    AssertEquals('click without drag should not push history', DepthBefore, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TToolTransactionTests.MovePixelsEscapeCancelsPreviewAndRestoresSelection;
var
  F: TMainForm;
  MoveColor: TRGBA32;
  DepthBefore: Integer;
  Key: Word;
begin
  F := CreateMovePixelsForm;
  try
    MoveColor := RGBA(255, 0, 0, 255);
    DepthBefore := F.TestDocument.UndoDepth;

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 10);
    F.SimulateMouseMove([ssLeft], 12, 10);

    Key := VK_ESCAPE;
    F.SimulateKeyDown(Key, []);

    AssertTrue('escape cancel should keep source pixel intact', RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 10], MoveColor));
    AssertTrue('escape cancel should not leave moved pixels behind', RGBAEqual(F.TestDocument.ActiveLayer.Surface[12, 10], TransparentColor));
    AssertTrue('escape cancel should restore source selection', F.TestDocument.Selection[10, 10]);
    AssertFalse('escape cancel should clear moved selection preview', F.TestDocument.Selection[12, 10]);
    AssertEquals('escape cancel should not push history', DepthBefore, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

procedure TToolTransactionTests.MovePixelsToolSwitchCancelsPreviewAndRestoresSelection;
var
  F: TMainForm;
  MoveColor: TRGBA32;
  DepthBefore: Integer;
begin
  F := CreateMovePixelsForm;
  try
    MoveColor := RGBA(255, 0, 0, 255);
    DepthBefore := F.TestDocument.UndoDepth;

    F.SimulateMouseDown(mbLeft, [ssLeft], 10, 10);
    F.SimulateMouseMove([ssLeft], 12, 10);
    F.SimulateToolButtonSwitch(tkBrush);

    AssertTrue('tool switch should select destination tool', F.CurrentToolForTest = tkBrush);
    AssertTrue('tool switch should cancel move preview and keep source pixel',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[10, 10], MoveColor));
    AssertTrue('tool switch should not leave moved destination pixels behind',
      RGBAEqual(F.TestDocument.ActiveLayer.Surface[12, 10], TransparentColor));
    AssertTrue('selection should restore at source after cancel-by-tool-switch',
      F.TestDocument.Selection[10, 10]);
    AssertFalse('selection preview should not remain at dragged destination',
      F.TestDocument.Selection[12, 10]);
    AssertEquals('cancel-by-tool-switch should not push history',
      DepthBefore, F.TestDocument.UndoDepth);
  finally
    F.Destroy;
  end;
end;

initialization
  RegisterTest(TToolTransactionTests);

end.
