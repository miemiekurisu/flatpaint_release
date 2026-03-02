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
    procedure LayerBlendModeDefaultsToNormal;
    procedure LayerBlendModePreservedInClone;
    procedure StoredSelectionRoundtrips;
    procedure NewToolKindCountIsCorrect;
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

procedure TFPDocumentTests.LayerBlendModeDefaultsToNormal;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(4, 4);
  try
    AssertEquals('default blend mode', Ord(bmNormal), Ord(Document.ActiveLayer.BlendMode));
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.LayerBlendModePreservedInClone;
var
  Document: TImageDocument;
  Layer2: TRasterLayer;
begin
  Document := TImageDocument.Create(4, 4);
  try
    Document.ActiveLayer.BlendMode := bmMultiply;
    Layer2 := Document.ActiveLayer.Clone;
    try
      AssertEquals('clone preserves blend mode', Ord(bmMultiply), Ord(Layer2.BlendMode));
    finally
      Layer2.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.StoredSelectionRoundtrips;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(8, 8);
  try
    Document.SelectRectangle(1, 1, 5, 5);
    AssertFalse('no stored selection initially', Document.HasStoredSelection);
    Document.StoreSelectionForPaste;
    AssertTrue('has stored selection after store', Document.HasStoredSelection);
    Document.Deselect;
    AssertFalse('selection cleared', Document.HasSelection);
    Document.PasteStoredSelection;
    AssertTrue('selection restored after paste', Document.Selection[2, 2]);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.NewToolKindCountIsCorrect;
begin
  { TToolKind should now have 23 values: 0..22 }
  AssertEquals('tkRecolor ordinal', 22, Ord(tkRecolor));
  AssertEquals('tkCrop ordinal', 19, Ord(tkCrop));
  AssertEquals('tkText ordinal', 20, Ord(tkText));
  AssertEquals('tkCloneStamp ordinal', 21, Ord(tkCloneStamp));
end;

initialization
  RegisterTest(TFPDocumentTests);

end.
