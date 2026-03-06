unit mutation_guard_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPColor, FPSurface, FPDocument, FPSelection;

type
  TMutationGuardTests = class(TTestCase)
  published
    procedure MutableActiveLayerSurfaceRespectsLockState;
    procedure BeginActiveLayerMutationRespectsLockAndHistory;
    procedure BeginDocumentMutationRespectsLockAndHistory;
    procedure LockedActiveLayerBlocksAdjustmentMutation;
    procedure LockedActiveLayerBlocksSelectionDrivenMutation;
    procedure LockedActiveLayerBlocksSurfacePasteAndRotateRoutes;
    procedure LockedLayerBlocksDocumentWidePixelMutation;
    procedure UnlockedMutationsStillApply;
  end;

implementation

procedure TMutationGuardTests.MutableActiveLayerSurfaceRespectsLockState;
var
  Doc: TImageDocument;
  Surface: TRasterSurface;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    Surface := Doc.MutableActiveLayerSurface;
    AssertTrue('unlocked layer should expose mutable surface', Assigned(Surface));
    Surface[1, 1] := RGBA(12, 34, 56, 255);
    AssertEquals('write through mutable surface should apply when unlocked', 12, Doc.ActiveLayer.Surface[1, 1].R);

    Doc.ActiveLayer.Locked := True;
    Surface := Doc.MutableActiveLayerSurface;
    AssertFalse('locked layer should not expose mutable surface', Assigned(Surface));
    AssertEquals('locked state should preserve prior written red channel', 12, Doc.ActiveLayer.Surface[1, 1].R);
  finally
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.BeginActiveLayerMutationRespectsLockAndHistory;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    AssertTrue('unlocked active layer should allow begin-mutation',
      Doc.BeginActiveLayerMutation('Active Change'));
    AssertEquals('successful begin-mutation should push one history entry', 1, Doc.UndoDepth);

    Doc.ActiveLayer.Locked := True;
    AssertFalse('locked active layer should block begin-mutation',
      Doc.BeginActiveLayerMutation('Blocked Active Change'));
    AssertEquals('blocked begin-mutation must not add history noise', 1, Doc.UndoDepth);
  finally
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.BeginDocumentMutationRespectsLockAndHistory;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    Doc.AddLayer('Top');
    AssertTrue('unlocked document should allow begin-mutation',
      Doc.BeginDocumentMutation('Document Change'));
    AssertEquals('successful document begin-mutation should push one history entry', 1, Doc.UndoDepth);

    Doc.Layers[0].Locked := True;
    AssertFalse('any locked layer should block document begin-mutation',
      Doc.BeginDocumentMutation('Blocked Document Change'));
    AssertEquals('blocked document begin-mutation must not add history noise', 1, Doc.UndoDepth);

    Doc.Layers[0].Locked := False;
    AssertTrue('unlocking should restore document begin-mutation',
      Doc.BeginDocumentMutation('Document Change 2'));
    AssertEquals('second successful begin-mutation should push another entry', 2, Doc.UndoDepth);
  finally
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.LockedActiveLayerBlocksAdjustmentMutation;
var
  Doc: TImageDocument;
  BeforePixel: TRGBA32;
  AfterPixel: TRGBA32;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    Doc.ActiveLayer.Surface[1, 1] := RGBA(10, 20, 30, 255);
    BeforePixel := Doc.ActiveLayer.Surface[1, 1];
    Doc.ActiveLayer.Locked := True;

    Doc.InvertColors;

    AfterPixel := Doc.ActiveLayer.Surface[1, 1];
    AssertEquals('locked layer keeps red channel', BeforePixel.R, AfterPixel.R);
    AssertEquals('locked layer keeps green channel', BeforePixel.G, AfterPixel.G);
    AssertEquals('locked layer keeps blue channel', BeforePixel.B, AfterPixel.B);
    AssertEquals('locked layer keeps alpha', BeforePixel.A, AfterPixel.A);
  finally
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.LockedActiveLayerBlocksSelectionDrivenMutation;
var
  Doc: TImageDocument;
  Pixel: TRGBA32;
begin
  Doc := TImageDocument.Create(4, 4);
  try
    Doc.ActiveLayer.Surface[1, 1] := RGBA(200, 0, 0, 255);
    Doc.SelectRectangle(1, 1, 1, 1, scReplace);
    Doc.ActiveLayer.Locked := True;

    Doc.FillSelection(RGBA(0, 255, 0, 255), 255);
    Doc.EraseSelection;
    Doc.MoveSelectedPixelsBy(1, 0);

    Pixel := Doc.ActiveLayer.Surface[1, 1];
    AssertEquals('locked fill/erase/move keep source red', 200, Pixel.R);
    AssertEquals('locked fill/erase/move keep source green', 0, Pixel.G);
    AssertEquals('locked fill/erase/move keep source blue', 0, Pixel.B);
    AssertEquals('locked fill/erase/move keep source alpha', 255, Pixel.A);

    Pixel := Doc.ActiveLayer.Surface[2, 1];
    AssertEquals('target remains untouched red', 255, Pixel.R);
    AssertEquals('target remains untouched green', 255, Pixel.G);
    AssertEquals('target remains untouched blue', 255, Pixel.B);
    AssertEquals('target remains untouched alpha', 255, Pixel.A);

    AssertTrue('selection position should remain unchanged when move is blocked', Doc.Selection[1, 1]);
    AssertFalse('selection should not move while locked', Doc.Selection[2, 1]);
  finally
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.LockedActiveLayerBlocksSurfacePasteAndRotateRoutes;
var
  Doc: TImageDocument;
  Source: TRasterSurface;
  BeforeLeft: TRGBA32;
  BeforeRight: TRGBA32;
begin
  Doc := TImageDocument.Create(4, 2);
  Source := TRasterSurface.Create(1, 1);
  try
    Source[0, 0] := RGBA(0, 255, 0, 255);
    Doc.ActiveLayer.Surface[0, 0] := RGBA(10, 20, 30, 255);
    Doc.ActiveLayer.Surface[3, 0] := RGBA(200, 10, 10, 255);
    BeforeLeft := Doc.ActiveLayer.Surface[0, 0];
    BeforeRight := Doc.ActiveLayer.Surface[3, 0];
    Doc.ActiveLayer.Locked := True;

    Doc.PasteSurfaceToActiveLayer(Source, 1, 0);
    Doc.RotateActiveLayer90Clockwise;
    Doc.PixelateRect(0, 0, 3, 1, 2);

    AssertEquals('locked paste keeps original red channel', 255, Doc.ActiveLayer.Surface[1, 0].R);
    AssertEquals('locked paste keeps original green channel', 255, Doc.ActiveLayer.Surface[1, 0].G);
    AssertEquals('locked paste keeps original blue channel', 255, Doc.ActiveLayer.Surface[1, 0].B);
    AssertEquals('locked paste keeps original alpha', 255, Doc.ActiveLayer.Surface[1, 0].A);
    AssertEquals('locked rotate keeps left source red', BeforeLeft.R, Doc.ActiveLayer.Surface[0, 0].R);
    AssertEquals('locked rotate keeps right source red', BeforeRight.R, Doc.ActiveLayer.Surface[3, 0].R);
  finally
    Source.Free;
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.LockedLayerBlocksDocumentWidePixelMutation;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(3, 1);
  try
    Doc.Layers[0].Surface[0, 0] := RGBA(10, 0, 0, 255);
    Doc.Layers[0].Surface[2, 0] := RGBA(20, 0, 0, 255);
    Doc.AddLayer('Top');
    Doc.ActiveLayer.Locked := True;

    Doc.FlipHorizontal;

    AssertEquals('left pixel stays put when document-wide mutate is blocked', 10, Doc.Layers[0].Surface[0, 0].R);
    AssertEquals('right pixel stays put when document-wide mutate is blocked', 20, Doc.Layers[0].Surface[2, 0].R);
  finally
    Doc.Free;
  end;
end;

procedure TMutationGuardTests.UnlockedMutationsStillApply;
var
  Doc: TImageDocument;
  Source: TRasterSurface;
begin
  Doc := TImageDocument.Create(3, 1);
  Source := TRasterSurface.Create(1, 1);
  try
    Doc.ActiveLayer.Surface[0, 0] := RGBA(10, 0, 0, 255);
    Doc.ActiveLayer.Surface[2, 0] := RGBA(20, 0, 0, 255);
    Doc.FlipHorizontal;

    AssertEquals('flip should move right value to left', 20, Doc.ActiveLayer.Surface[0, 0].R);
    AssertEquals('flip should move left value to right', 10, Doc.ActiveLayer.Surface[2, 0].R);

    Doc.SelectRectangle(1, 0, 1, 0, scReplace);
    Doc.FillSelection(RGBA(0, 255, 0, 255), 255);
    AssertEquals('unlocked fill should apply', 255, Doc.ActiveLayer.Surface[1, 0].G);

    Source[0, 0] := RGBA(33, 44, 55, 255);
    Doc.PasteSurfaceToActiveLayer(Source, 0, 0);
    AssertEquals('unlocked paste route should apply red', 33, Doc.ActiveLayer.Surface[0, 0].R);
  finally
    Source.Free;
    Doc.Free;
  end;
end;

initialization
  RegisterTest(TMutationGuardTests);

end.
