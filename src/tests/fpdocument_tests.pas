unit fpdocument_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPColor, FPSurface, FPDocument, FPSelection;

type
  TFPDocumentTests = class(TTestCase)
  published
    procedure HistoryDepthTracksUndoAndRedo;
    procedure HistoryLabelsTrackUndoAndRedo;
    procedure HistoryTimelineRowCountMatchesDepths;
    procedure HistoryTimeline_CurrentIndexIsUndoDepth;
    procedure HistoryTimeline_UndoRestoresPixelState;
    procedure HistoryTimeline_NavigateViaRowClickSimulation;
    procedure HistoryTimeline_ClickInitialStateUndoesAll;
    procedure MagicWandIntersectKeepsOnlySharedRegion;
    procedure LayerBlendModeDefaultsToNormal;
    procedure LayerBlendModePreservedInClone;
    procedure LayerOffsetMetadataPreservedInClone;
    procedure MoveLayerReordersAndTracksActiveLayer;
    procedure BackgroundLayerStaysLockedAtBottom;
    procedure BackgroundLayerEraseAndMovePreserveOpacity;
    procedure StoredSelectionRoundtrips;
    procedure CopySelectionStoresSelectionForPasteRoute;
    procedure CopyMergedStoresSelectionForPasteRoute;
    procedure NewBlankStartsWithWhiteBackground;
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

{ Helper: simulate the mainform HistoryListClick navigation on a document.
  ClickedRow = row index in the history list (0=initial, 1..N=past, N=current, N+1..=redo).
  CurrentRow is always UndoDepth. }
procedure NavigateHistoryTo(Doc: TImageDocument; ClickedRow: Integer);
var
  CurrentRow: Integer;
  Delta: Integer;
  I: Integer;
begin
  CurrentRow := Doc.UndoDepth;
  if ClickedRow = CurrentRow then Exit;
  Delta := ClickedRow - CurrentRow;
  if Delta < 0 then
    for I := 1 to Abs(Delta) do
    begin
      if Doc.UndoDepth = 0 then Break;
      Doc.Undo;
    end
  else
    for I := 1 to Delta do
    begin
      if Doc.RedoDepth = 0 then Break;
      Doc.Redo;
    end;
end;

procedure TFPDocumentTests.HistoryTimelineRowCountMatchesDepths;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    { No operations: 0+1+0 = 1 row (just initial) }
    AssertEquals('rows before any op', 1, Doc.UndoDepth + 1 + Doc.RedoDepth);
    { Push 3 ops }
    Doc.PushHistory('A');
    Doc.PushHistory('B');
    Doc.PushHistory('C');
    AssertEquals('rows after 3 ops', 4, Doc.UndoDepth + 1 + Doc.RedoDepth);
    { Undo once: row count stays 4 (1 undo moves to redo) }
    Doc.Undo;
    AssertEquals('rows after 1 undo', 4, Doc.UndoDepth + 1 + Doc.RedoDepth);
    { Undo twice more: still 4 }
    Doc.Undo;
    Doc.Undo;
    AssertEquals('rows after 3 undos', 4, Doc.UndoDepth + 1 + Doc.RedoDepth);
  finally
    Doc.Free;
  end;
end;

procedure TFPDocumentTests.HistoryTimeline_CurrentIndexIsUndoDepth;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    AssertEquals('current index before any op', 0, Doc.UndoDepth);
    Doc.PushHistory('A');
    AssertEquals('current index = 1 after op A', 1, Doc.UndoDepth);
    Doc.PushHistory('B');
    Doc.PushHistory('C');
    AssertEquals('current index = 3 after ops A,B,C', 3, Doc.UndoDepth);
    Doc.Undo;
    AssertEquals('current index = 2 after 1 undo', 2, Doc.UndoDepth);
    Doc.Undo;
    Doc.Undo;
    AssertEquals('current index = 0 after 3 undos (at initial)', 0, Doc.UndoDepth);
    Doc.Redo;
    AssertEquals('current index = 1 after 1 redo', 1, Doc.UndoDepth);
  finally
    Doc.Free;
  end;
end;

procedure TFPDocumentTests.HistoryTimeline_UndoRestoresPixelState;
var
  Doc: TImageDocument;
  RedPixel, BluePixel, RestoredPixel: TRGBA32;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    { Paint pixel red, push history (snapshot before painting blue) }
    Doc.ActiveLayer.Surface[1, 1] := RGBA(255, 0, 0, 255);
    Doc.PushHistory('Paint Blue');
    Doc.ActiveLayer.Surface[1, 1] := RGBA(0, 0, 255, 255);

    BluePixel := Doc.ActiveLayer.Surface[1, 1];
    AssertEquals('pixel is blue before undo', 255, BluePixel.B);
    AssertEquals('pixel is not red before undo', 0, BluePixel.R);

    Doc.Undo;
    RedPixel := Doc.ActiveLayer.Surface[1, 1];
    AssertEquals('pixel restored to red after undo', 255, RedPixel.R);
    AssertEquals('pixel is not blue after undo', 0, RedPixel.B);

    Doc.Redo;
    RestoredPixel := Doc.ActiveLayer.Surface[1, 1];
    AssertEquals('pixel is blue again after redo', 255, RestoredPixel.B);
    AssertEquals('pixel is not red after redo', 0, RestoredPixel.R);
  finally
    Doc.Free;
  end;
end;

procedure TFPDocumentTests.HistoryTimeline_NavigateViaRowClickSimulation;
var
  Doc: TImageDocument;
begin
  { Build a 3-op timeline: ops A, B, C.
    List rows: 0=(initial), 1=A, 2=B, 3=C(current).
    Click row 1 (after op A) → should undo 2 times → UndoDepth becomes 1. }
  Doc := TImageDocument.Create(4, 4);
  try
    Doc.PushHistory('A');
    Doc.PushHistory('B');
    Doc.PushHistory('C');
    AssertEquals('start: UndoDepth=3', 3, Doc.UndoDepth);

    NavigateHistoryTo(Doc, 1);  { click row 1 = state after A }
    AssertEquals('after click row 1: UndoDepth=1', 1, Doc.UndoDepth);
    AssertEquals('after click row 1: RedoDepth=2', 2, Doc.RedoDepth);
    AssertEquals('current row = 1', 1, Doc.UndoDepth);

    NavigateHistoryTo(Doc, 3);  { click row 3 = state after C }
    AssertEquals('after click row 3: UndoDepth=3', 3, Doc.UndoDepth);
    AssertEquals('after click row 3: RedoDepth=0', 0, Doc.RedoDepth);

    NavigateHistoryTo(Doc, 2);  { click row 2 = state after B }
    AssertEquals('after click row 2: UndoDepth=2', 2, Doc.UndoDepth);
    AssertEquals('UndoActionLabel is B', 'B', Doc.UndoActionLabel);
  finally
    Doc.Free;
  end;
end;

procedure TFPDocumentTests.HistoryTimeline_ClickInitialStateUndoesAll;
var
  Doc: TImageDocument;
begin
  { Clicking row 0 (initial) should undo everything. }
  Doc := TImageDocument.Create(4, 4);
  try
    Doc.ActiveLayer.Surface[0, 0] := RGBA(10, 20, 30, 255);
    { initial pixel color is now set; push 3 ops }
    Doc.PushHistory('Op1');
    Doc.ActiveLayer.Surface[0, 0] := RGBA(100, 0, 0, 255);
    Doc.PushHistory('Op2');
    Doc.ActiveLayer.Surface[0, 0] := RGBA(200, 0, 0, 255);
    Doc.PushHistory('Op3');
    Doc.ActiveLayer.Surface[0, 0] := RGBA(255, 0, 0, 255);

    AssertEquals('UndoDepth=3 before navigate', 3, Doc.UndoDepth);

    NavigateHistoryTo(Doc, 0);  { click row 0 = initial state }
    AssertEquals('UndoDepth=0 at initial state', 0, Doc.UndoDepth);
    AssertEquals('RedoDepth=3 at initial state', 3, Doc.RedoDepth);
    { Canvas should show the snapshot that was taken at first PushHistory, i.e. RGBA(10,20,30,255) }
    AssertEquals('pixel R at initial', 10, Doc.ActiveLayer.Surface[0, 0].R);
    AssertEquals('pixel G at initial', 20, Doc.ActiveLayer.Surface[0, 0].G);
    AssertEquals('pixel B at initial', 30, Doc.ActiveLayer.Surface[0, 0].B);
  finally
    Doc.Free;
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

procedure TFPDocumentTests.LayerOffsetMetadataPreservedInClone;
var
  Document: TImageDocument;
  Layer2: TRasterLayer;
begin
  Document := TImageDocument.Create(4, 4);
  try
    Document.ActiveLayer.OffsetX := 12;
    Document.ActiveLayer.OffsetY := -7;
    Layer2 := Document.ActiveLayer.Clone;
    try
      AssertEquals('clone preserves layer offset x', 12, Layer2.OffsetX);
      AssertEquals('clone preserves layer offset y', -7, Layer2.OffsetY);
    finally
      Layer2.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.MoveLayerReordersAndTracksActiveLayer;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(4, 4);
  try
    Document.ActiveLayer.Name := 'Base';
    Document.AddLayer('Mid');
    Document.AddLayer('Top');
    AssertEquals('top starts active', 2, Document.ActiveLayerIndex);

    Document.MoveLayer(2, 0);
    AssertEquals('background stays pinned to bottom', 'Base', Document.Layers[0].Name);
    AssertEquals('dragged layer becomes first movable layer', 'Top', Document.Layers[1].Name);
    AssertEquals('middle layer shifts above moved layer', 'Mid', Document.Layers[2].Name);
    AssertEquals('active index follows moved layer', 1, Document.ActiveLayerIndex);

    Document.ActiveLayerIndex := 2;
    Document.MoveLayer(1, 2);
    AssertEquals('base stays pinned after second reorder', 'Base', Document.Layers[0].Name);
    AssertEquals('mid stays in the first movable slot', 'Mid', Document.Layers[1].Name);
    AssertEquals('top moves back to the end', 'Top', Document.Layers[2].Name);
    AssertEquals('active index shifts when a lower layer crosses it', 1, Document.ActiveLayerIndex);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.BackgroundLayerStaysLockedAtBottom;
var
  Document: TImageDocument;
begin
  Document := TImageDocument.Create(4, 4);
  try
    AssertTrue('new blank starts with a background layer', Document.Layers[0].IsBackground);
    Document.AddLayer('Top');
    Document.MoveLayer(0, 1);
    AssertTrue('background refuses upward move', Document.Layers[0].IsBackground);
    AssertEquals('top layer stays above background', 'Top', Document.Layers[1].Name);

    Document.ActiveLayerIndex := 1;
    Document.MoveLayer(1, 0);
    AssertTrue('background still occupies bottom slot', Document.Layers[0].IsBackground);
    AssertEquals('ordinary layer cannot displace background', 'Top', Document.Layers[1].Name);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.BackgroundLayerEraseAndMovePreserveOpacity;
var
  Document: TImageDocument;
  Pixel: TRGBA32;
begin
  Document := TImageDocument.Create(6, 6);
  try
    Document.ActiveLayer.Surface[1, 1] := RGBA(10, 20, 30, 255);
    Document.SelectRectangle(1, 1, 1, 1);
    Document.EraseSelection;
    Pixel := Document.ActiveLayer.Surface[1, 1];
    AssertEquals('erase restores opaque white red', 255, Pixel.R);
    AssertEquals('erase restores opaque white green', 255, Pixel.G);
    AssertEquals('erase restores opaque white blue', 255, Pixel.B);
    AssertEquals('erase keeps background opaque', 255, Pixel.A);

    Document.ActiveLayer.Surface[2, 2] := RGBA(200, 0, 0, 255);
    Document.SelectRectangle(2, 2, 2, 2);
    Document.MoveSelectedPixelsBy(1, 0);

    Pixel := Document.ActiveLayer.Surface[2, 2];
    AssertEquals('move leaves source filled white red', 255, Pixel.R);
    AssertEquals('move leaves source filled white green', 255, Pixel.G);
    AssertEquals('move leaves source filled white blue', 255, Pixel.B);
    AssertEquals('move leaves source opaque', 255, Pixel.A);

    Pixel := Document.ActiveLayer.Surface[3, 2];
    AssertEquals('moved pixel arrives at new location', 200, Pixel.R);
    AssertEquals('moved pixel keeps alpha', 255, Pixel.A);
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

procedure TFPDocumentTests.CopySelectionStoresSelectionForPasteRoute;
var
  Document: TImageDocument;
  Copied: TRasterSurface;
begin
  Document := TImageDocument.Create(10, 10);
  try
    Document.SelectRectangle(2, 2, 6, 6);
    AssertFalse('no stored selection before copy route', Document.HasStoredSelection);
    Copied := Document.CopySelectionToSurface(True);
    Copied.Free;
    AssertTrue('copy route stores selection for paste', Document.HasStoredSelection);
    Document.Deselect;
    Document.PasteStoredSelection;
    AssertTrue('stored selection restores after paste route', Document.Selection[4, 4]);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.CopyMergedStoresSelectionForPasteRoute;
var
  Document: TImageDocument;
  Copied: TRasterSurface;
begin
  Document := TImageDocument.Create(10, 10);
  try
    Document.SelectRectangle(1, 1, 3, 3);
    AssertFalse('no stored selection before merged copy route', Document.HasStoredSelection);
    Copied := Document.CopyMergedToSurface(True);
    Copied.Free;
    AssertTrue('merged copy route stores selection for paste', Document.HasStoredSelection);
    Document.Deselect;
    Document.PasteStoredSelection;
    AssertTrue('stored selection restores after merged copy paste route', Document.Selection[2, 2]);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.NewBlankStartsWithWhiteBackground;
var
  Document: TImageDocument;
  Pixel: TRGBA32;
begin
  Document := TImageDocument.Create(8, 8);
  try
    AssertTrue('first layer is marked as background', Document.ActiveLayer.IsBackground);
    Pixel := Document.ActiveLayer.Surface[0, 0];
    AssertEquals('background starts white red', 255, Pixel.R);
    AssertEquals('background starts white green', 255, Pixel.G);
    AssertEquals('background starts white blue', 255, Pixel.B);
    AssertEquals('background starts opaque', 255, Pixel.A);
  finally
    Document.Free;
  end;
end;

procedure TFPDocumentTests.NewToolKindCountIsCorrect;
begin
  { TToolKind should now have 24 values: 0..23 }
  AssertEquals('tkRecolor ordinal', 22, Ord(tkRecolor));
  AssertEquals('tkMosaic ordinal', 23, Ord(tkMosaic));
  AssertEquals('tkCrop ordinal', 19, Ord(tkCrop));
  AssertEquals('tkText ordinal', 20, Ord(tkText));
  AssertEquals('tkCloneStamp ordinal', 21, Ord(tkCloneStamp));
end;

initialization
  RegisterTest(TFPDocumentTests);

end.
