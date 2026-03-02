unit format_compat_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPColor, FPSurface, FPDocument, FPIO, FPNativeIO, Process;

type
  TFormatCompatTests = class(TTestCase)
  published
    procedure Test_PNG_RoundTrip_PreservesPixels;
    procedure Test_ExportDoc_UsingCLI_ProducesComposite;
  end;

implementation

procedure TFormatCompatTests.Test_PNG_RoundTrip_PreservesPixels;
var
  S1, S2: TRasterSurface;
  PngPath: string;
begin
  S1 := TRasterSurface.Create(3,3);
  try
    S1.Clear(TransparentColor);
    S1[1,1] := RGBA(123,45,67,255);
    PngPath := GetTempDir(False) + 'flatpaint_png_rt.png';
    if FileExists(PngPath) then DeleteFile(PngPath);
    SaveSurfaceToFile(PngPath, S1);
    S2 := LoadSurfaceFromFile(PngPath);
    try
      AssertTrue('png rt pixel', RGBAEqual(S1[1,1], S2[1,1]));
    finally
      S2.Free;
    end;
  finally
    S1.Free;
    if FileExists(PngPath) then DeleteFile(PngPath);
  end;
end;

procedure TFormatCompatTests.Test_ExportDoc_UsingCLI_ProducesComposite;
var
  Doc: TImageDocument;
  FpdPath, OutPath: string;
  Proc: TProcess;
begin
  FpdPath := GetTempDir(False) + 'flatpaint_export_doc.fpd';
  OutPath := GetTempDir(False) + 'flatpaint_export_doc.png';
  if FileExists(FpdPath) then DeleteFile(FpdPath);
  if FileExists(OutPath) then DeleteFile(OutPath);

  Doc := TImageDocument.Create(6,6);
  try
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[2,2] := RGBA(200,100,50,255);
    Doc.AddLayer('Top');
    Doc.ActiveLayerIndex := 1;
    Doc.ActiveLayer.Surface.Clear(TransparentColor);
    Doc.ActiveLayer.Surface[3,3] := RGBA(10,20,30,255);
    SaveNativeDocumentToFile(FpdPath, Doc);
  finally
    Doc.Free;
  end;

  Proc := TProcess.Create(nil);
  try
    Proc.Executable := GetCurrentDir + PathDelim + 'dist' + PathDelim + 'flatpaint_cli';
    Proc.Parameters.Add('exportdoc');
    Proc.Parameters.Add(FpdPath);
    Proc.Parameters.Add(OutPath);
    Proc.Options := [poWaitOnExit];
    Proc.Execute;
    AssertEquals('cli export exit', 0, Proc.ExitStatus);
  finally
    Proc.Free;
  end;

  AssertTrue('exported file exists', FileExists(OutPath));

  if FileExists(FpdPath) then DeleteFile(FpdPath);
  if FileExists(OutPath) then DeleteFile(OutPath);
end;

initialization
  RegisterTest(TFormatCompatTests);

end.
