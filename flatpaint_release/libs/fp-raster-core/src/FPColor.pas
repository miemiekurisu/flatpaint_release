unit FPColor;

{$mode objfpc}{$H+}

interface

type
  TRGBA32 = packed record
    B: Byte;
    G: Byte;
    R: Byte;
    A: Byte;
  end;

function RGBA(R, G, B: Byte; A: Byte = 255): TRGBA32;
function TransparentColor: TRGBA32;
function IntColorToRGBA(AColor: LongInt; Alpha: Byte = 255): TRGBA32;
function RGBAEqual(const AColor, BColor: TRGBA32): Boolean;
{ Premultiplied alpha source-over blend. Both Src and Dst must be premultiplied.
  Opacity scales the source contribution (0=invisible, 255=full). }
function BlendNormal(const Src, Dst: TRGBA32; Opacity: Byte = 255): TRGBA32;
function LerpColor(const AColor, BColor: TRGBA32; Position: Double): TRGBA32;
{ Convert straight-alpha pixel to premultiplied alpha. }
function Premultiply(const C: TRGBA32): TRGBA32;
{ Convert premultiplied-alpha pixel back to straight alpha. }
function Unpremultiply(const C: TRGBA32): TRGBA32;
{ Create a premultiplied pixel directly from straight-alpha components. }
function RGBA_Premul(R, G, B: Byte; A: Byte = 255): TRGBA32;

implementation

uses
  Math;

function ClampByte(Value: Integer): Byte; inline;
begin
  if Value < 0 then
    Exit(0);
  if Value > 255 then
    Exit(255);
  Result := Value;
end;

function RGBA(R, G, B: Byte; A: Byte): TRGBA32;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
  Result.A := A;
end;

function TransparentColor: TRGBA32;
begin
  Result := RGBA(0, 0, 0, 0);
end;

function IntColorToRGBA(AColor: LongInt; Alpha: Byte): TRGBA32;
begin
  Result.R := AColor and $FF;
  Result.G := (AColor shr 8) and $FF;
  Result.B := (AColor shr 16) and $FF;
  Result.A := Alpha;
end;

function RGBAEqual(const AColor, BColor: TRGBA32): Boolean;
begin
  Result :=
    (AColor.R = BColor.R) and
    (AColor.G = BColor.G) and
    (AColor.B = BColor.B) and
    (AColor.A = BColor.A);
end;

function BlendNormal(const Src, Dst: TRGBA32; Opacity: Byte): TRGBA32;
var
  SrcA: Integer;
  InvA: Integer;
begin
  { Premultiplied source-over: Result = Src * opacity/255 + Dst * (1 - SrcA*opacity/255) }
  SrcA := (Src.A * Opacity + 127) div 255;
  if SrcA <= 0 then
    Exit(Dst);
  if (SrcA >= 255) and (Opacity >= 255) then
    Exit(Src);

  InvA := 255 - SrcA;
  Result.R := ClampByte((Src.R * Opacity + 127) div 255 + (Dst.R * InvA + 127) div 255);
  Result.G := ClampByte((Src.G * Opacity + 127) div 255 + (Dst.G * InvA + 127) div 255);
  Result.B := ClampByte((Src.B * Opacity + 127) div 255 + (Dst.B * InvA + 127) div 255);
  Result.A := ClampByte(SrcA + (Dst.A * InvA + 127) div 255);
end;

function LerpColor(const AColor, BColor: TRGBA32; Position: Double): TRGBA32;
var
  T: Double;
begin
  T := EnsureRange(Position, 0.0, 1.0);
  Result.R := ClampByte(Round(AColor.R + ((BColor.R - AColor.R) * T)));
  Result.G := ClampByte(Round(AColor.G + ((BColor.G - AColor.G) * T)));
  Result.B := ClampByte(Round(AColor.B + ((BColor.B - AColor.B) * T)));
  Result.A := ClampByte(Round(AColor.A + ((BColor.A - AColor.A) * T)));
end;

function Premultiply(const C: TRGBA32): TRGBA32;
begin
  if C.A = 0 then
    Exit(TransparentColor);
  if C.A = 255 then
    Exit(C);
  Result.R := (C.R * C.A + 127) div 255;
  Result.G := (C.G * C.A + 127) div 255;
  Result.B := (C.B * C.A + 127) div 255;
  Result.A := C.A;
end;

function Unpremultiply(const C: TRGBA32): TRGBA32;
begin
  if C.A = 0 then
    Exit(TransparentColor);
  if C.A = 255 then
    Exit(C);
  Result.R := ClampByte((C.R * 255 + C.A div 2) div C.A);
  Result.G := ClampByte((C.G * 255 + C.A div 2) div C.A);
  Result.B := ClampByte((C.B * 255 + C.A div 2) div C.A);
  Result.A := C.A;
end;

function RGBA_Premul(R, G, B: Byte; A: Byte): TRGBA32;
begin
  if A = 0 then
    Exit(TransparentColor);
  if A = 255 then
  begin
    Result.R := R;
    Result.G := G;
    Result.B := B;
    Result.A := 255;
    Exit;
  end;
  Result.R := (R * A + 127) div 255;
  Result.G := (G * A + 127) div 255;
  Result.B := (B * A + 127) div 255;
  Result.A := A;
end;

end.
