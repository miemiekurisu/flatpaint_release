unit integration_document_flow_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPDocument, FPSurface, FPNativeIO, FPColor;

type
  TIntegrationDocumentFlowTests = class(TTestCase)
  published
    procedure Test_SaveLoadDocument_PreservesPixels;
  end;

implementation

procedure TIntegrationDocumentFlowTests.Test_SaveLoadDocument_PreservesPixels;
var
  Doc, Loaded: TImageDocument;
  TempPath: string;
  Pixel: TRGBA32;
begin
  TempPath := 'dist/tmp_integration.fpd';
  if DirectoryExists('dist') = False then
    ForceDirectories('dist');

  Doc := TImageDocument.Create(5, 5);
  try
    // draw a red dot at center
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface.DrawBrush(2, 2, 1, RGBA(255, 0, 0, 255));

    SaveNativeDocumentToFile(TempPath, Doc);
  finally
    Doc.Free;
  end;

  Loaded := LoadNativeDocumentFromFile(TempPath);
  try
    Pixel := Loaded.Layers[0].Surface[2, 2];
    AssertEquals('Loaded pixel R', 255, Pixel.R);
    AssertEquals('Loaded pixel G', 0, Pixel.G);
    AssertEquals('Loaded pixel B', 0, Pixel.B);
    AssertEquals('Loaded pixel A', 255, Pixel.A);
  finally
    Loaded.Free;
  end;

  // cleanup
  if FileExists(TempPath) then
    DeleteFile(TempPath);
end;

initialization
  RegisterTest(TIntegrationDocumentFlowTests);

end.
