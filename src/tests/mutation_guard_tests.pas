unit mutation_guard_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPColor, FPDocument, FPSelection;

type
  TMutationGuardTests = class(TTestCase)
  published
    procedure LockedActiveLayerBlocksAdjustmentMutation;
    procedure LockedActiveLayerBlocksSelectionDrivenMutation;
    procedure LockedLayerBlocksDocumentWidePixelMutation;
    procedure UnlockedMutationsStillApply;
  end;

implementation

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
begin
  Doc := TImageDocument.Create(3, 1);
  try
    Doc.ActiveLayer.Surface[0, 0] := RGBA(10, 0, 0, 255);
    Doc.ActiveLayer.Surface[2, 0] := RGBA(20, 0, 0, 255);
    Doc.FlipHorizontal;

    AssertEquals('flip should move right value to left', 20, Doc.ActiveLayer.Surface[0, 0].R);
    AssertEquals('flip should move left value to right', 10, Doc.ActiveLayer.Surface[2, 0].R);

    Doc.SelectRectangle(1, 0, 1, 0, scReplace);
    Doc.FillSelection(RGBA(0, 255, 0, 255), 255);
    AssertEquals('unlocked fill should apply', 255, Doc.ActiveLayer.Surface[1, 0].G);
  finally
    Doc.Free;
  end;
end;

initialization
  RegisterTest(TMutationGuardTests);

end.
