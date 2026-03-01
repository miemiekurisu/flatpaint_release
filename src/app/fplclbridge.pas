unit FPLCLBridge;

{$mode objfpc}{$H+}

interface

uses
  Graphics, GraphType, FPColor, FPSurface;

function UIToRGBA(AColor: TColor; Alpha: Byte = 255): TRGBA32;
function SurfaceToBitmap(ASurface: TRasterSurface): TBitmap;

implementation

function UIToRGBA(AColor: TColor; Alpha: Byte): TRGBA32;
begin
  Result := IntColorToRGBA(ColorToRGB(AColor), Alpha);
end;

function SurfaceToBitmap(ASurface: TRasterSurface): TBitmap;
var
  RawImage: TRawImage;
  Buffer: Pointer;
  ByteCount: PtrUInt;
  X: Integer;
  Y: Integer;
  PixelPtr: ^TRGBA32;
begin
  RawImage.Init;
  RawImage.Description.Init_BPP32_B8G8R8A8_BIO_TTB(ASurface.Width, ASurface.Height);
  ByteCount := PtrUInt(ASurface.Width) * PtrUInt(ASurface.Height) * SizeOf(TRGBA32);
  GetMem(Buffer, ByteCount);
  PixelPtr := Buffer;
  for Y := 0 to ASurface.Height - 1 do
    for X := 0 to ASurface.Width - 1 do
    begin
      PixelPtr^ := ASurface[X, Y];
      Inc(PixelPtr);
    end;
  RawImage.Data := Buffer;
  RawImage.DataSize := ByteCount;
  Result := TBitmap.Create;
  Result.LoadFromRawImage(RawImage, True);
end;

end.
