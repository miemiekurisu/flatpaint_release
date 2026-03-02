unit fpdocument_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPColor, FPDocument, FPSelection;

type
  TFPDocumentTests = class(TTestCase)
  published
    procedure HistoryDepthTracksUndoAndRedo;
    procedure HistoryLabelsTrackUndoAndRedo;
    procedure MagicWandIntersectKeepsOnlySharedRegion;
  end;

implementation

procedure TFPDocumentTests.HistoryDepthTracksUndoAndRedo;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(8, 8);
  try
    AssertEquals('initial undo depth', 0, Document.UndoDepth);
    AssertEquals('initial redo depth', 0, Document.RedoDepth);

    Document.PushHistory;
    Document.AddLayer;
    AssertEquals('after push history', 1, Document.UndoDepth);
    AssertEquals('redo still empty', 0, Document.RedoDepth);

    Document.Undo;
    AssertEquals('undo stack after undo', 0, Document.UndoDepth);
    AssertEquals('redo stack after undo', 1, Document.RedoDepth);

    Document.Redo;
    AssertEquals('undo restored after redo', 1, Document.UndoDepth);
    AssertEquals('redo cleared after redo', 0, Document.RedoDepth);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.HistoryLabelsTrackUndoAndRedo;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(8, 8);
  try
    Document.PushHistory('Add Layer');
    Document.AddLayer;
    AssertEquals('latest undo label', 'Add Layer', Document.UndoActionLabel);
    AssertEquals('redo label starts empty', '', Document.RedoActionLabel);

    Document.Undo;
    AssertEquals('undo label clears after undo', '', Document.UndoActionLabel);
    AssertEquals('redo label matches undone action', 'Add Layer', Document.RedoActionLabel);

    Document.Redo;
    AssertEquals('undo label restored after redo', 'Add Layer', Document.UndoActionLabel);
    AssertEquals('redo label clears after redo', '', Document.RedoActionLabel);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.MagicWandIntersectKeepsOnlySharedRegion;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(4, 2);
  try
    Document.ActiveLayer.Surface.Clear(RGBA(0, 0, 0, 255));
    Document.ActiveLayer.Surface[2, 0] := RGBA(255, 0, 0, 255);
    Document.ActiveLayer.Surface[2, 1] := RGBA(255, 0, 0, 255);

    Document.SelectRectangle(1, 0, 3, 0, scReplace);
    Document.SelectMagicWand(0, 0, 0, scIntersect);

    AssertFalse('non-overlap clears right edge', Document.Selection[3, 0]);
    AssertFalse('different color clears', Document.Selection[2, 0]);
    AssertTrue('shared black region remains', Document.Selection[1, 0]);
    AssertFalse('row outside original selection stays clear', Document.Selection[1, 1]);
  finally
    Document.Free;
  end;
end;

initialization
  RegisterTest(TFPDocumentTests);

end.
