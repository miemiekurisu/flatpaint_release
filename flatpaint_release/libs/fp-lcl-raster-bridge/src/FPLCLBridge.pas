unit FPLCLBridge;

{$mode objfpc}{$H+}

interface

uses
  Graphics, GraphType, FPColor, FPSurface;

function UIToRGBA(AColor: TColor; Alpha: Byte = 255): TRGBA32;
procedure CopySurfaceToBitmap(ASurface: TRasterSurface; ABitmap: TBitmap);
function SurfaceToBitmap(ASurface: TRasterSurface): TBitmap;
function BitmapToSurface(ABitmap: TBitmap): TRasterSurface;
{ Sets pixels whose RGB is within Tolerance of ABackgroundColor to transparent. }
procedure TransparentizeSurface(ASurface: TRasterSurface; ABackgroundColor: TRGBA32; Tolerance: Byte = 0);

implementation

uses
  Math;

function UIToRGBA(AColor: TColor; Alpha: Byte): TRGBA32;
begin
  Result := IntColorToRGBA(ColorToRGB(AColor), Alpha);
end;

procedure CopySurfaceToBitmap(ASurface: TRasterSurface; ABitmap: TBitmap);
var
  RawImage: TRawImage;
  Buffer: Pointer;
  ByteCount: PtrUInt;
  PixelCount: PtrUInt;
  PixelIndex: PtrUInt;
  SourcePtr: ^TRGBA32;
  DestPtr: ^TRGBA32;
begin
  if (ASurface = nil) or (ABitmap = nil) then
    Exit;
  RawImage.Init;
  RawImage.Description.Init_BPP32_B8G8R8A8_BIO_TTB(ASurface.Width, ASurface.Height);
  PixelCount := PtrUInt(ASurface.Width) * PtrUInt(ASurface.Height);
  ByteCount := PixelCount * SizeOf(TRGBA32);
  GetMem(Buffer, ByteCount);
  SourcePtr := ASurface.RawPixels;
  DestPtr := Buffer;
  if PixelCount > 0 then
    for PixelIndex := 0 to PixelCount - 1 do
    begin
      DestPtr^ := Unpremultiply(SourcePtr^);
      Inc(DestPtr);
      Inc(SourcePtr);
    end;
  RawImage.Data := Buffer;
  RawImage.DataSize := ByteCount;
  try
    ABitmap.LoadFromRawImage(RawImage, True);
    Buffer := nil; { ownership transferred to bitmap internals }
  finally
    if Buffer <> nil then
      FreeMem(Buffer);
  end;
end;

function SurfaceToBitmap(ASurface: TRasterSurface): TBitmap;
begin
  Result := TBitmap.Create;
  CopySurfaceToBitmap(ASurface, Result);
end;

function BitmapToSurface(ABitmap: TBitmap): TRasterSurface;
var
  X: Integer;
  Y: Integer;
begin
  if (ABitmap = nil) or (ABitmap.Width <= 0) or (ABitmap.Height <= 0) then
    Exit(TRasterSurface.Create(1, 1));

  Result := TRasterSurface.Create(Max(1, ABitmap.Width), Max(1, ABitmap.Height));
  for Y := 0 to ABitmap.Height - 1 do
    for X := 0 to ABitmap.Width - 1 do
      Result[X, Y] := Premultiply(IntColorToRGBA(ColorToRGB(ABitmap.Canvas.Pixels[X, Y]), 255));
end;

procedure TransparentizeSurface(ASurface: TRasterSurface; ABackgroundColor: TRGBA32; Tolerance: Byte);
var
  X, Y: Integer;
  Pix: TRGBA32;
  DR, DG, DB, Dist: Integer;
begin
  if ASurface = nil then Exit;
  for Y := 0 to ASurface.Height - 1 do
    for X := 0 to ASurface.Width - 1 do
    begin
      Pix := ASurface[X, Y];
      DR := Abs(Pix.R - ABackgroundColor.R);
      DG := Abs(Pix.G - ABackgroundColor.G);
      DB := Abs(Pix.B - ABackgroundColor.B);
      Dist := (DR + DG + DB) div 3;
      if Dist <= Tolerance then
        ASurface[X, Y] := TransparentColor;
    end;
end;

end.
