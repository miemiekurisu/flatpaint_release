program smoke_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Graphics,
  FPColor,
  FPSurface,
  FPLCLBridge;

var
  Surface: TRasterSurface;
  Bitmap: TBitmap;
begin
  Surface := TRasterSurface.Create(16, 16);
  Bitmap := TBitmap.Create;
  try
    Surface.Clear(RGBA_Premul(255, 0, 0, 255));
    CopySurfaceToBitmap(Surface, Bitmap);
    if (Bitmap.Width <> 16) or (Bitmap.Height <> 16) then
      raise Exception.Create('bitmap size mismatch');
  finally
    Bitmap.Free;
    Surface.Free;
  end;
end.
