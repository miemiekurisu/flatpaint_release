program smoke_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  FPColor,
  FPSelection,
  FPSurface;

var
  Surface: TRasterSurface;
  Pixel: TRGBA32;
begin
  Surface := TRasterSurface.Create(64, 64);
  try
    Surface.Clear(RGBA_Premul(255, 255, 255, 255));
    Surface.DrawLine(4, 4, 60, 60, 2, RGBA(0, 0, 0, 255), 255);
    Pixel := Unpremultiply(Surface[32, 32]);
    if Pixel.A = 0 then
      raise Exception.Create('smoke test failed: center pixel is transparent');
  finally
    Surface.Free;
  end;
end.
