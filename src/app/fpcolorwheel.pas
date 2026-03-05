unit FPColorWheel;

{$mode objfpc}{$H+}

{ Standalone rendering helpers for the colour-wheel picker.
  All routines are pure functions – no UI state, no dependencies on LCL forms.
  Paint into TBitmap via the lightweight TRasterSurface → CopySurfaceToBitmap
  bridge so we keep Rule-16/17 performance hygiene (prepared bitmap reuse,
  no per-paint heap churn). }

interface

uses
  Graphics, FPColor, FPSurface;

{ ── Hue Ring ──────────────────────────────────────────────────────────────── }

{ Render a circular hue ring centred at (ASize div 2, ASize div 2).
  The ring runs from AInnerRadius to AOuterRadius.
  ABitmap is resized to ASize × ASize; transparent elsewhere. }
procedure RenderHueRing(ABitmap: TBitmap; ASize, AInnerRadius, AOuterRadius: Integer);

{ ── Saturation / Value Square ────────────────────────────────────────────── }

{ Render a square gradient for the given hue:
    X axis → saturation 0..1 (left-to-right)
    Y axis → value 1..0 (top-to-bottom)
  ABitmap is resized to ASize × ASize. }
procedure RenderSVSquare(ABitmap: TBitmap; AHue: Double; ASize: Integer);

{ ── Hit-testing ──────────────────────────────────────────────────────────── }

{ Returns True when (X,Y) lands inside the hue ring.
  On True the normalised hue (0..1) is written to AHue. }
function HitTestHueRing(X, Y, ACenterX, ACenterY,
  AInnerR, AOuterR: Integer; out AHue: Double): Boolean;

{ Returns True when (X,Y) lands inside the SV square.
  On True, ASat (0..1) and AVal (0..1) are returned. }
function HitTestSVSquare(X, Y, ALeft, ATop, ASize: Integer;
  out ASat, AVal: Double): Boolean;

{ ── Drawing helpers ──────────────────────────────────────────────────────── }

{ Draw a small hollow circle marker at (MX, MY) on ACanvas.
  Used for the SV indicator inside the square. }
procedure DrawCircleMarker(ACanvas: TCanvas; MX, MY, ARadius: Integer;
  AOuterColor, AInnerColor: TColor);

{ Draw a wedge marker on the hue ring at the given angle (hue 0..1).
  ACenterX/Y is the ring centre, ARadius the mid-ring radius. }
procedure DrawHueMarker(ACanvas: TCanvas; AHue: Double;
  ACenterX, ACenterY, AMidRadius, AThickness: Integer);

{ ── Gradient-bar rendering (single horizontal bar) ───────────────────────── }

type
  TGradientBarKind = (
    gbkRed,        { varies R keeping current G,B }
    gbkGreen,      { varies G keeping current R,B }
    gbkBlue,       { varies B keeping current R,G }
    gbkHue,        { rainbow }
    gbkSaturation, { varies S keeping current H,V }
    gbkValue,      { varies V keeping current H,S }
    gbkAlpha       { grey ramp 0..255 }
  );

{ Paint a single gradient bar of the given kind.
  AColor is the current TRGBA32 colour (used for the non-varying channels).
  The bar is drawn from (ALeft, ATop) with size (AWidth × AHeight).
  AMarkerPos is the normalised 0..1 position for the current value marker. }
procedure PaintGradientBar(ACanvas: TCanvas; AKind: TGradientBarKind;
  AColor: TRGBA32; AMarkerPos: Double;
  ALeft, ATop, AWidth, AHeight: Integer);

implementation

uses
  Math, FPColorWheelHelpers, FPLCLBridge;

{ ── Hue Ring ──────────────────────────────────────────────────────────────── }

procedure RenderHueRing(ABitmap: TBitmap; ASize, AInnerRadius, AOuterRadius: Integer);
var
  Surface: TRasterSurface;
  CX, CY, PX, PY: Integer;
  DX, DY: Double;
  DistSq, InnerR2, OuterR2: Double;
  Dist, Angle, Hue, EdgeDist: Double;
  R, G, B, Alpha: Byte;
begin
  if ASize < 4 then
    Exit;
  Surface := TRasterSurface.Create(ASize, ASize);
  try
    Surface.Clear(RGBA(0, 0, 0, 0));
    CX := ASize div 2;
    CY := ASize div 2;
    InnerR2 := Sqr(Double(AInnerRadius));
    OuterR2 := Sqr(Double(AOuterRadius));
    for PY := 0 to ASize - 1 do
      for PX := 0 to ASize - 1 do
      begin
        DX := PX - CX;
        DY := PY - CY;
        DistSq := Sqr(DX) + Sqr(DY);
        if (DistSq >= InnerR2) and (DistSq <= OuterR2) then
        begin
          Dist := Sqrt(DistSq);
          Angle := ArcTan2(-DY, DX);        { -DY: screen Y is down }
          Hue := Angle / (2.0 * Pi);
          if Hue < 0 then
            Hue := Hue + 1.0;
          HSVToRGB(Hue, 1.0, 1.0, R, G, B);
          { 1-pixel anti-alias at inner and outer edge }
          EdgeDist := Min(Dist - AInnerRadius, AOuterRadius - Dist);
          if EdgeDist < 1.0 then
            Alpha := EnsureRange(Round(EdgeDist * 255), 0, 255)
          else
            Alpha := 255;
          Surface[PX, PY] := RGBA(R, G, B, Alpha);
        end;
      end;
    CopySurfaceToBitmap(Surface, ABitmap);
  finally
    Surface.Free;
  end;
end;

{ ── SV Square ─────────────────────────────────────────────────────────────── }

procedure RenderSVSquare(ABitmap: TBitmap; AHue: Double; ASize: Integer);
var
  Surface: TRasterSurface;
  PX, PY: Integer;
  S, V: Double;
  R, G, B: Byte;
begin
  if ASize < 2 then
    Exit;
  Surface := TRasterSurface.Create(ASize, ASize);
  try
    for PY := 0 to ASize - 1 do
    begin
      V := 1.0 - PY / Max(1, ASize - 1);
      for PX := 0 to ASize - 1 do
      begin
        S := PX / Max(1, ASize - 1);
        HSVToRGB(AHue, S, V, R, G, B);
        Surface[PX, PY] := RGBA(R, G, B, 255);
      end;
    end;
    CopySurfaceToBitmap(Surface, ABitmap);
  finally
    Surface.Free;
  end;
end;

{ ── Hit-testing ──────────────────────────────────────────────────────────── }

function HitTestHueRing(X, Y, ACenterX, ACenterY,
  AInnerR, AOuterR: Integer; out AHue: Double): Boolean;
var
  DX, DY, Dist: Double;
begin
  DX := X - ACenterX;
  DY := Y - ACenterY;
  Dist := Sqrt(Sqr(DX) + Sqr(DY));
  { Allow a small tolerance outside the ring for easier grabbing }
  Result := (Dist >= AInnerR - 3) and (Dist <= AOuterR + 3);
  if Result then
  begin
    AHue := ArcTan2(-DY, DX) / (2.0 * Pi);
    if AHue < 0 then
      AHue := AHue + 1.0;
  end;
end;

function HitTestSVSquare(X, Y, ALeft, ATop, ASize: Integer;
  out ASat, AVal: Double): Boolean;
begin
  Result := (X >= ALeft) and (X < ALeft + ASize) and
            (Y >= ATop) and (Y < ATop + ASize);
  if Result then
  begin
    ASat := EnsureRange((X - ALeft) / Max(1, ASize - 1), 0.0, 1.0);
    AVal := EnsureRange(1.0 - (Y - ATop) / Max(1, ASize - 1), 0.0, 1.0);
  end;
end;

{ ── Drawing helpers ──────────────────────────────────────────────────────── }

procedure DrawCircleMarker(ACanvas: TCanvas; MX, MY, ARadius: Integer;
  AOuterColor, AInnerColor: TColor);
begin
  ACanvas.Pen.Width := 2;
  ACanvas.Pen.Color := AOuterColor;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Ellipse(MX - ARadius, MY - ARadius, MX + ARadius, MY + ARadius);
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := AInnerColor;
  ACanvas.Ellipse(MX - ARadius + 1, MY - ARadius + 1,
                  MX + ARadius - 1, MY + ARadius - 1);
  ACanvas.Brush.Style := bsSolid;
end;

procedure DrawHueMarker(ACanvas: TCanvas; AHue: Double;
  ACenterX, ACenterY, AMidRadius, AThickness: Integer);
var
  Angle: Double;
  MX, MY: Integer;
begin
  Angle := AHue * 2.0 * Pi;
  MX := ACenterX + Round(Cos(Angle) * AMidRadius);
  MY := ACenterY - Round(Sin(Angle) * AMidRadius);
  ACanvas.Pen.Width := 2;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Ellipse(MX - AThickness, MY - AThickness,
                  MX + AThickness, MY + AThickness);
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clBlack;
  ACanvas.Ellipse(MX - AThickness - 1, MY - AThickness - 1,
                  MX + AThickness + 1, MY + AThickness + 1);
  ACanvas.Brush.Style := bsSolid;
end;

{ ── Gradient Bars ─────────────────────────────────────────────────────────── }

procedure PaintGradientBar(ACanvas: TCanvas; AKind: TGradientBarKind;
  AColor: TRGBA32; AMarkerPos: Double;
  ALeft, ATop, AWidth, AHeight: Integer);
var
  X: Integer;
  Frac: Double;
  CurH, CurS, CurV: Double;
  R, G, B: Byte;
  MarkerX: Integer;
begin
  RGBToHSV(AColor.R, AColor.G, AColor.B, CurH, CurS, CurV);

  for X := 0 to AWidth - 1 do
  begin
    Frac := X / Max(1, AWidth - 1);
    case AKind of
      gbkRed:
        begin
          R := EnsureRange(Round(Frac * 255), 0, 255);
          G := AColor.G;
          B := AColor.B;
        end;
      gbkGreen:
        begin
          R := AColor.R;
          G := EnsureRange(Round(Frac * 255), 0, 255);
          B := AColor.B;
        end;
      gbkBlue:
        begin
          R := AColor.R;
          G := AColor.G;
          B := EnsureRange(Round(Frac * 255), 0, 255);
        end;
      gbkHue:
        HSVToRGB(Frac, 1.0, 1.0, R, G, B);
      gbkSaturation:
        HSVToRGB(CurH, Frac, CurV, R, G, B);
      gbkValue:
        HSVToRGB(CurH, CurS, Frac, R, G, B);
      gbkAlpha:
        begin
          R := EnsureRange(Round(Frac * 255), 0, 255);
          G := R;
          B := R;
        end;
    end;
    ACanvas.Pen.Color := RGBToColor(R, G, B);
    ACanvas.MoveTo(ALeft + X, ATop);
    ACanvas.LineTo(ALeft + X, ATop + AHeight);
  end;

  { Border }
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := RGBToColor(200, 200, 200);
  ACanvas.Rectangle(ALeft, ATop, ALeft + AWidth, ATop + AHeight);
  ACanvas.Brush.Style := bsSolid;

  { Marker — small triangle or line }
  MarkerX := ALeft + EnsureRange(Round(AMarkerPos * Max(1, AWidth - 1)), 0, AWidth - 1);
  ACanvas.Pen.Color := clWhite;
  ACanvas.Pen.Width := 2;
  ACanvas.MoveTo(MarkerX, ATop - 1);
  ACanvas.LineTo(MarkerX, ATop + AHeight + 1);
  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := 1;
  ACanvas.MoveTo(MarkerX - 1, ATop - 2);
  ACanvas.LineTo(MarkerX - 1, ATop + AHeight + 2);
  ACanvas.MoveTo(MarkerX + 1, ATop - 2);
  ACanvas.LineTo(MarkerX + 1, ATop + AHeight + 2);
end;

end.
