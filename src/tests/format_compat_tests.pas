unit format_compat_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPSurface, FPColor, FPIO;

type
  TFormatCompatTests = class(TTestCase)
  published
    procedure Test_PNG_RoundTrip_PreservesPixel;
  end;

implementation

procedure TFormatCompatTests.Test_PNG_RoundTrip_PreservesPixel;
var
  S: TRasterSurface;
  TempPath: string;
  Pixel: TRGBA32;
begin
  TempPath := 'dist/tmp_roundtrip.png';
  if DirectoryExists('dist') = False then
    ForceDirectories('dist');

  S := TRasterSurface.Create(5,5);
  try
    S.Clear(TransparentColor);
    S.DrawBrush(2,2,1, RGBA(123, 45, 67, 255));
    SaveSurfaceToFile(TempPath, S);
  finally
    S.Free;
  end;

  S := LoadSurfaceFromFile(TempPath);
  try
    Pixel := S[2,2];
    AssertEquals('Roundtrip R', 123, Pixel.R);
    AssertEquals('Roundtrip G', 45, Pixel.G);
    AssertEquals('Roundtrip B', 67, Pixel.B);
  finally
    S.Free;
  end;

  if FileExists(TempPath) then
    DeleteFile(TempPath);
end;

initialization
  RegisterTest(TFormatCompatTests);

end.
