unit FPColorWheelHelpers;

{$mode objfpc}{$H+}

interface

uses
  FPColor;

procedure HSVToRGB(H, S, V: Double; out R, G, B: Byte);
procedure RGBToHSV(R, G, B: Byte; out H, S, V: Double);
function ColorFromHSV(H, S, V: Double): TRGBA32;

implementation

uses
  Math;

procedure HSVToRGB(H, S, V: Double; out R, G, B: Byte);
var
  I: Integer;
  F, P, Q, T: Double;
  RR, GG, BB: Double;
begin
  H := H - Floor(H);
  if H < 0 then H := H + 1.0;
  S := EnsureRange(S, 0.0, 1.0);
  V := EnsureRange(V, 0.0, 1.0);
  if S = 0 then
  begin
    R := Round(V * 255);
    G := R;
    B := R;
    Exit;
  end;
  H := H * 6.0;
  I := Trunc(H);
  F := H - I;
  P := V * (1.0 - S);
  Q := V * (1.0 - S * F);
  T := V * (1.0 - S * (1.0 - F));
  case I mod 6 of
    0: begin RR := V; GG := T; BB := P; end;
    1: begin RR := Q; GG := V; BB := P; end;
    2: begin RR := P; GG := V; BB := T; end;
    3: begin RR := P; GG := Q; BB := V; end;
    4: begin RR := T; GG := P; BB := V; end;
  else begin RR := V; GG := P; BB := Q; end;
  end;
  R := EnsureRange(Round(RR * 255), 0, 255);
  G := EnsureRange(Round(GG * 255), 0, 255);
  B := EnsureRange(Round(BB * 255), 0, 255);
end;

procedure RGBToHSV(R, G, B: Byte; out H, S, V: Double);
var
  RR, GG, BB: Double;
  CMax, CMin, Delta: Double;
begin
  RR := R / 255.0;
  GG := G / 255.0;
  BB := B / 255.0;
  CMax := Max(RR, Max(GG, BB));
  CMin := Min(RR, Min(GG, BB));
  Delta := CMax - CMin;
  V := CMax;
  if CMax = 0 then
    S := 0
  else
    S := Delta / CMax;
  if Delta = 0 then
    H := 0
  else if CMax = RR then
    H := (GG - BB) / Delta / 6.0
  else if CMax = GG then
    H := ((BB - RR) / Delta + 2.0) / 6.0
  else
    H := ((RR - GG) / Delta + 4.0) / 6.0;
  if H < 0 then
    H := H + 1.0;
end;

function ColorFromHSV(H, S, V: Double): TRGBA32;
var
  R, G, B: Byte;
begin
  HSVToRGB(H, S, V, R, G, B);
  Result := RGBA(R, G, B, 255);
end;

end.
