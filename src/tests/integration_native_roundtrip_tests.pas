unit integration_native_roundtrip_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPDocument, FPNativeIO, FPColor;

type
  TIntegrationNativeRoundTripTests = class(TTestCase)
  published
    procedure Test_MultiLayer_SaveLoad_PreservesLayersAndPixels;
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
    Doc.ActiveLayerIndex := 0;
    Doc.ActiveLayer.Surface.DrawBrush(2, 2, 1, RGBA(0, 0, 255, 255));

    // add layer 1: green dot at 7,7
    Doc.AddLayer('Layer 1');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
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

initialization
  RegisterTest(TIntegrationNativeRoundTripTests);

end.
