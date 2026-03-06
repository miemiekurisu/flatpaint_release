unit history_transaction_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Types, FPColor, FPDocument,
  FPHistoryTransaction;

type
  THistoryTransactionTests = class(TTestCase)
  published
    procedure RegionTransactionCommitRestoresViaUndo;
    procedure RegionTransactionUnionCapturePreservesEarlierOriginalPixels;
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
