unit history_transaction_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Types, FPColor, FPDocument, FPSurface,
  FPHistoryTransaction;

type
  THistoryTransactionTests = class(TTestCase)
  published
    procedure RegionTransactionCommitRestoresViaUndo;
    procedure RegionTransactionUnionCapturePreservesEarlierOriginalPixels;
    procedure RegionTransactionSelectionSnapshotRestoresSelectionOnUndoRedo;
    procedure RegionTransactionClearDropsPendingWithoutHistoryNoise;
  end;

implementation

procedure THistoryTransactionTests.RegionTransactionCommitRestoresViaUndo;
var
  Doc: TImageDocument;
  Txn: TRegionHistoryTransaction;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(16, 16);
  Txn := TRegionHistoryTransaction.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[5, 5] := RGBA(220, 10, 20, 255);

    Txn.BeginSession(Doc, Doc.ActiveLayerIndex);
    Txn.CaptureBeforeRect(Doc, Rect(4, 4, 7, 7));
    Doc.ActiveLayer.Surface[5, 5] := RGBA(10, 20, 230, 255);

    AssertTrue('commit should push one region history entry',
      Txn.CommitToHistory(Doc, 'Stroke'));
    AssertEquals('history depth should be 1 after commit', 1, Doc.UndoDepth);

    Doc.Undo;
    Pixel := Doc.ActiveLayer.Surface[5, 5];
    AssertEquals('undo restores red channel', 220, Pixel.R);
    AssertEquals('undo restores green channel', 10, Pixel.G);
    AssertEquals('undo restores blue channel', 20, Pixel.B);
  finally
    Txn.Free;
    Doc.Free;
  end;
end;

procedure THistoryTransactionTests.RegionTransactionUnionCapturePreservesEarlierOriginalPixels;
var
  Doc: TImageDocument;
  Txn: TRegionHistoryTransaction;
  PixelA: TRGBA32;
  PixelB: TRGBA32;
begin
  Doc := TImageDocument.Create(24, 24);
  Txn := TRegionHistoryTransaction.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[5, 5] := RGBA(255, 0, 0, 255);
    Doc.ActiveLayer.Surface[15, 5] := RGBA(0, 255, 0, 255);

    Txn.BeginSession(Doc, Doc.ActiveLayerIndex);
    Txn.CaptureBeforeRect(Doc, Rect(4, 4, 7, 7));
    Doc.ActiveLayer.Surface[5, 5] := RGBA(0, 0, 255, 255);
    Txn.CaptureBeforeRect(Doc, Rect(14, 4, 17, 7));
    Doc.ActiveLayer.Surface[15, 5] := RGBA(255, 255, 0, 255);

    AssertTrue('commit should succeed for union-captured regions',
      Txn.CommitToHistory(Doc, 'Long Stroke'));
    Doc.Undo;

    PixelA := Doc.ActiveLayer.Surface[5, 5];
    PixelB := Doc.ActiveLayer.Surface[15, 5];
    AssertTrue('undo restores first segment original red pixel',
      RGBAEqual(PixelA, RGBA(255, 0, 0, 255)));
    AssertTrue('undo restores second segment original green pixel',
      RGBAEqual(PixelB, RGBA(0, 255, 0, 255)));
  finally
    Txn.Free;
    Doc.Free;
  end;
end;

procedure THistoryTransactionTests.RegionTransactionSelectionSnapshotRestoresSelectionOnUndoRedo;
var
  Doc: TImageDocument;
  Txn: TRegionHistoryTransaction;
  Floating: TRasterSurface;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(16, 16);
  Txn := TRegionHistoryTransaction.Create;
  Floating := nil;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[4, 4] := RGBA(210, 30, 40, 255);
    Doc.SelectRectangle(4, 4, 4, 4);

    Txn.BeginSession(Doc, Doc.ActiveLayerIndex, True);
    Txn.CaptureBeforeRect(Doc, Rect(3, 3, 7, 6));

    Floating := Doc.CopySelectionToSurface(False);
    Doc.EraseSelection(RGBA(255, 255, 255, 255));
    Doc.PasteSurfaceToActiveLayer(Floating, 2, 0);
    Doc.Selection.MoveBy(2, 0);

    AssertTrue('selection-aware transaction should commit successfully',
      Txn.CommitToHistory(Doc, 'Move Pixels Txn'));
    AssertEquals('history depth should be 1 after selection-aware commit', 1, Doc.UndoDepth);
    AssertTrue('selection should be moved before undo', Doc.Selection[6, 4]);
    AssertFalse('original selection location should be cleared before undo', Doc.Selection[4, 4]);

    Doc.Undo;
    Pixel := Doc.ActiveLayer.Surface[4, 4];
    AssertEquals('undo restores source pixel alpha', 255, Pixel.A);
    AssertTrue('undo restores original selection location', Doc.Selection[4, 4]);
    AssertFalse('undo clears moved selection location', Doc.Selection[6, 4]);

    Doc.Redo;
    Pixel := Doc.ActiveLayer.Surface[6, 4];
    AssertEquals('redo restores moved destination alpha', 255, Pixel.A);
    AssertTrue('redo restores moved selection location', Doc.Selection[6, 4]);
    AssertFalse('redo clears original selection location', Doc.Selection[4, 4]);
  finally
    Floating.Free;
    Txn.Free;
    Doc.Free;
  end;
end;

procedure THistoryTransactionTests.RegionTransactionClearDropsPendingWithoutHistoryNoise;
var
  Doc: TImageDocument;
  Txn: TRegionHistoryTransaction;
begin
  Doc := TImageDocument.Create(12, 12);
  Txn := TRegionHistoryTransaction.Create;
  try
    Doc.AddLayer('Paint');
    Doc.ActiveLayerIndex := 1;
    Txn.BeginSession(Doc, Doc.ActiveLayerIndex);
    Txn.CaptureBeforeRect(Doc, Rect(2, 2, 4, 4));
    Txn.Clear;

    AssertFalse('commit should fail when session was cleared',
      Txn.CommitToHistory(Doc, 'Cleared'));
    AssertEquals('no history entry expected after clear', 0, Doc.UndoDepth);
  finally
    Txn.Free;
    Doc.Free;
  end;
end;

initialization
  RegisterTest(THistoryTransactionTests);

end.
