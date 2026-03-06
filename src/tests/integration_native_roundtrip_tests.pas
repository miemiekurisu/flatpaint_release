unit integration_native_roundtrip_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPDocument, FPNativeIO, FPColor;

type
  TIntegrationNativeRoundTripTests = class(TTestCase)
  published
    procedure Test_MultiLayer_SaveLoad_PreservesLayersAndPixels;
    procedure Test_SelectionCoverage_SaveLoad_PreservesByteMask;
  end;

implementation

procedure TIntegrationNativeRoundTripTests.Test_MultiLayer_SaveLoad_PreservesLayersAndPixels;
var
  Doc, Loaded: TImageDocument;
  TempPath: string;
  PixelTop, PixelBottom: TRGBA32;
begin
  TempPath := 'dist/tmp_multi_layer.fpd';
  if DirectoryExists('dist') = False then
    ForceDirectories('dist');

  Doc := TImageDocument.Create(10, 10);
  try
    // layer 0: blue dot at 2,2
    Doc.Layers[0].Surface.Clear(TransparentColor);
    Doc.Layers[0].OffsetX := -3;
    Doc.Layers[0].OffsetY := 4;
    Doc.ActiveLayerIndex := 0;
    Doc.ActiveLayer.Surface.DrawBrush(2, 2, 1, RGBA(0, 0, 255, 255));

    // add layer 1: green dot at 7,7
    Doc.AddLayer('Layer 1');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.OffsetX := 6;
    Doc.ActiveLayer.OffsetY := -2;
    Doc.ActiveLayer.Surface.DrawBrush(7, 7, 1, RGBA(0, 255, 0, 255));

    SaveNativeDocumentToFile(TempPath, Doc);
  finally
    Doc.Free;
  end;

  Loaded := LoadNativeDocumentFromFile(TempPath);
  try
    AssertEquals('Layer count preserved', 2, Loaded.LayerCount);
    AssertTrue('bottom layer keeps background flag', Loaded.Layers[0].IsBackground);
    AssertFalse('upper layer stays a normal layer', Loaded.Layers[1].IsBackground);
    AssertEquals('bottom layer offset x preserved', -3, Loaded.Layers[0].OffsetX);
    AssertEquals('bottom layer offset y preserved', 4, Loaded.Layers[0].OffsetY);
    AssertEquals('upper layer offset x preserved', 6, Loaded.Layers[1].OffsetX);
    AssertEquals('upper layer offset y preserved', -2, Loaded.Layers[1].OffsetY);
    PixelBottom := Loaded.Layers[0].Surface[2,2];
    PixelTop := Loaded.Layers[1].Surface[7,7];
    AssertEquals('Bottom layer blue R', 0, PixelBottom.R);
    AssertEquals('Bottom layer blue B', 255, PixelBottom.B);
    AssertEquals('Top layer green G', 255, PixelTop.G);
  finally
    Loaded.Free;
  end;

  if FileExists(TempPath) then
    DeleteFile(TempPath);
end;

procedure TIntegrationNativeRoundTripTests.Test_SelectionCoverage_SaveLoad_PreservesByteMask;
var
  Doc: TImageDocument;
  Loaded: TImageDocument;
  TempPath: string;
begin
  TempPath := 'dist/tmp_selection_coverage.fpd';
  if DirectoryExists('dist') = False then
    ForceDirectories('dist');

  Doc := TImageDocument.Create(4, 1);
  try
    Doc.Deselect;
    Doc.Selection.SetCoverage(1, 0, 64);
    Doc.Selection.SetCoverage(2, 0, 200);
    SaveNativeDocumentToFile(TempPath, Doc);
  finally
    Doc.Free;
  end;

  Loaded := LoadNativeDocumentFromFile(TempPath);
  try
    AssertEquals('coverage at first point preserved', 64, Loaded.Selection.Coverage(1, 0));
    AssertEquals('coverage at second point preserved', 200, Loaded.Selection.Coverage(2, 0));
    AssertEquals('outside remains unselected', 0, Loaded.Selection.Coverage(0, 0));
  finally
    Loaded.Free;
  end;

  if FileExists(TempPath) then
    DeleteFile(TempPath);
end;

initialization
  RegisterTest(TIntegrationNativeRoundTripTests);

end.
