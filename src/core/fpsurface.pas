unit FPSurface;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, FPColor, FPSelection;

type
  TResampleMode = (
    rmNearestNeighbor,
    rmBilinear
  );

  TRasterSurface = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FPixels: array of TRGBA32;
    function GetPixel(X, Y: Integer): TRGBA32;
    procedure SetPixel(X, Y: Integer; const AValue: TRGBA32);
    function IndexOf(X, Y: Integer): Integer; inline;
  public
    constructor Create(AWidth, AHeight: Integer); overload;
    constructor Create; overload;
    procedure SetSize(AWidth, AHeight: Integer);
    procedure Assign(ASource: TRasterSurface);
    function Clone: TRasterSurface;
    function InBounds(X, Y: Integer): Boolean; inline;
    procedure Clear(const AColor: TRGBA32);
    procedure BlendPixel(X, Y: Integer; const AColor: TRGBA32; Opacity: Byte = 255);
    procedure DrawBrush(X, Y, Radius: Integer; const AColor: TRGBA32; Opacity: Byte = 255; Hardness: Byte = 255);
    procedure DrawLine(X1, Y1, X2, Y2, Radius: Integer; const AColor: TRGBA32; Opacity: Byte = 255; Hardness: Byte = 255);
    procedure DrawRectangle(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte = 255);
    procedure DrawRoundedRectangle(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte = 255);
    procedure DrawEllipse(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte = 255);
    procedure DrawPolygon(const APoints: array of TPoint; StrokeWidth: Integer; const AColor: TRGBA32; Closed: Boolean = True; Opacity: Byte = 255);
    procedure FillPolygon(const APoints: array of TPoint; const AColor: TRGBA32; Opacity: Byte = 255);
    procedure FloodFill(X, Y: Integer; const AColor: TRGBA32; Tolerance: Byte = 0);
    procedure FillGradient(X1, Y1, X2, Y2: Integer; const StartColor, EndColor: TRGBA32);
    procedure FillRadialGradient(CenterX, CenterY, Radius: Integer; const StartColor, EndColor: TRGBA32);
    procedure PasteSurface(ASource: TRasterSurface; OffsetX, OffsetY: Integer; Opacity: Byte = 255);
    { Region copy: copies ASource.Width × ASource.Height pixels from Self at (SrcX, SrcY) into ADest at (0,0). Direct overwrite, no blending. }
    procedure CopyRegionTo(ADest: TRasterSurface; SrcX, SrcY: Integer);
    { Region overwrite: writes ASource.Width × ASource.Height pixels from ASource into Self at (DstX, DstY). Direct overwrite, no blending. }
    procedure OverwriteRegion(ASource: TRasterSurface; DstX, DstY: Integer);
    procedure FlipHorizontal;
    procedure FlipVertical;
    procedure Rotate180;
    procedure Rotate90Clockwise;
    procedure Rotate90CounterClockwise;
    procedure AutoLevel;
    procedure InvertColors;
    procedure Grayscale;
    procedure AdjustHueSaturation(HueDelta: Integer; SaturationDelta: Integer);
    procedure AdjustGammaCurve(Gamma: Double);
    procedure AdjustLevels(InputLow, InputHigh, OutputLow, OutputHigh: Byte);
    procedure AdjustBrightness(Delta: Integer);
    procedure AdjustContrast(Amount: Integer);
    procedure Sepia;
    procedure BlackAndWhite(Threshold: Byte = 127);
    procedure Posterize(Levels: Byte);
    procedure BoxBlur(Radius: Integer);
    procedure Sharpen;
    procedure AddNoise(Amount: Byte; Seed: Cardinal = 1);
    procedure DetectEdges;
    procedure Emboss;
    procedure Soften;
    procedure RenderClouds(Seed: Cardinal = 1);
    procedure Pixelate(BlockSize: Integer);
    procedure Vignette(Strength: Double);
    procedure MotionBlur(Angle: Integer; Distance: Integer);
    procedure MedianFilter(Radius: Integer);
    procedure OutlineEffect(const AOutlineColor: TRGBA32; Threshold: Byte = 10);
    procedure GlowEffect(Radius: Integer = 3; Intensity: Integer = 80);
    procedure OilPaint(Radius: Integer = 4);
    procedure FrostedGlass(Amount: Integer = 4);
    procedure ZoomBlur(CenterX: Integer; CenterY: Integer; Amount: Integer = 8);
    procedure GaussianBlur(Radius: Integer);
    procedure RadialBlur(Amount: Integer);
    procedure Twist(Amount: Integer);
    procedure Fragment(Offset: Integer);
    procedure RecolorBrush(X, Y, Radius: Integer; SourceColor, NewColor: TRGBA32; Tolerance: Byte; Opacity: Byte = 255);
    procedure FillSelection(ASelection: TSelectionMask; const AColor: TRGBA32; Opacity: Byte = 255);
    procedure EraseSelection(ASelection: TSelectionMask);
    function CopySelection(ASelection: TSelectionMask): TRasterSurface;
    function CreateContiguousSelection(X, Y: Integer; Tolerance: Byte = 0): TSelectionMask;
    function CreateGlobalColorSelection(X, Y: Integer; Tolerance: Byte = 0): TSelectionMask;
    procedure MoveSelectedPixels(ASelection: TSelectionMask; DeltaX, DeltaY: Integer);
    function Crop(X, Y, AWidth, AHeight: Integer): TRasterSurface;
    function ResizeNearest(ANewWidth, ANewHeight: Integer): TRasterSurface;
    function ResizeBilinear(ANewWidth, ANewHeight: Integer): TRasterSurface;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Pixels[X, Y: Integer]: TRGBA32 read GetPixel write SetPixel; default;
  end;

implementation

uses
  Math;

function ClampChannel(Value: Integer): Byte; inline;
begin
  if Value < 0 then
    Exit(0);
  if Value > 255 then
    Exit(255);
  Result := Value;
end;

function ColorsCloseEnough(const AColor, BColor: TRGBA32; Tolerance: Byte): Boolean; inline;
begin
  Result :=
    (Abs(AColor.R - BColor.R) <= Tolerance) and
    (Abs(AColor.G - BColor.G) <= Tolerance) and
    (Abs(AColor.B - BColor.B) <= Tolerance) and
    (Abs(AColor.A - BColor.A) <= Tolerance);
end;

function LumaOfColor(const AColor: TRGBA32): Integer; inline;
begin
  Result := (AColor.R * 77 + AColor.G * 150 + AColor.B * 29) div 256;
end;

procedure RGBToHSV(const AColor: TRGBA32; out H, S, V: Double); inline;
var
  RedValue: Double;
  GreenValue: Double;
  BlueValue: Double;
  MaxValue: Double;
  MinValue: Double;
  Delta: Double;
begin
  RedValue := AColor.R / 255.0;
  GreenValue := AColor.G / 255.0;
  BlueValue := AColor.B / 255.0;

  MaxValue := Max(RedValue, Max(GreenValue, BlueValue));
  MinValue := Min(RedValue, Min(GreenValue, BlueValue));
  Delta := MaxValue - MinValue;

  V := MaxValue;
  if MaxValue <= 0.0 then
    S := 0.0
  else
    S := Delta / MaxValue;

  if Delta <= 0.0 then
  begin
    H := 0.0;
    Exit;
  end;

  if SameValue(MaxValue, RedValue) then
    H := 60.0 * ((GreenValue - BlueValue) / Delta)
  else if SameValue(MaxValue, GreenValue) then
    H := 60.0 * (2.0 + ((BlueValue - RedValue) / Delta))
  else
    H := 60.0 * (4.0 + ((RedValue - GreenValue) / Delta));

  while H < 0.0 do
    H := H + 360.0;
  while H >= 360.0 do
    H := H - 360.0;
end;

function HSVToRGBA(H, S, V: Double; Alpha: Byte): TRGBA32; inline;
var
  NormalizedHue: Double;
  HueSector: Integer;
  Fraction: Double;
  PValue: Double;
  QValue: Double;
  TValue: Double;
  RedValue: Double;
  GreenValue: Double;
  BlueValue: Double;
begin
  S := EnsureRange(S, 0.0, 1.0);
  V := EnsureRange(V, 0.0, 1.0);

  if S <= 0.0 then
    Exit(RGBA(
      ClampChannel(Round(V * 255.0)),
      ClampChannel(Round(V * 255.0)),
      ClampChannel(Round(V * 255.0)),
      Alpha
    ));

  NormalizedHue := H;
  while NormalizedHue < 0.0 do
    NormalizedHue := NormalizedHue + 360.0;
  while NormalizedHue >= 360.0 do
    NormalizedHue := NormalizedHue - 360.0;

  NormalizedHue := NormalizedHue / 60.0;
  HueSector := Floor(NormalizedHue);
  Fraction := NormalizedHue - HueSector;

  PValue := V * (1.0 - S);
  QValue := V * (1.0 - (S * Fraction));
  TValue := V * (1.0 - (S * (1.0 - Fraction)));

  case HueSector of
    0:
      begin
        RedValue := V;
        GreenValue := TValue;
        BlueValue := PValue;
      end;
    1:
      begin
        RedValue := QValue;
        GreenValue := V;
        BlueValue := PValue;
      end;
    2:
      begin
        RedValue := PValue;
        GreenValue := V;
        BlueValue := TValue;
      end;
    3:
      begin
        RedValue := PValue;
        GreenValue := QValue;
        BlueValue := V;
      end;
    4:
      begin
        RedValue := TValue;
        GreenValue := PValue;
        BlueValue := V;
      end;
  else
    begin
      RedValue := V;
      GreenValue := PValue;
      BlueValue := QValue;
    end;
  end;

  Result := RGBA(
    ClampChannel(Round(RedValue * 255.0)),
    ClampChannel(Round(GreenValue * 255.0)),
    ClampChannel(Round(BlueValue * 255.0)),
    Alpha
  );
end;

function NextNoiseValue(var AState: Cardinal): Integer; inline;
begin
  if AState = 0 then
    AState := 1;
  AState := AState xor (AState shl 13);
  AState := AState xor (AState shr 17);
  AState := AState xor (AState shl 5);
  Result := Integer(AState and $7FFFFFFF);
end;

function PixelAtClamped(ASurface: TRasterSurface; X, Y: Integer): TRGBA32; inline;
var
  ClampedX: Integer;
  ClampedY: Integer;
begin
  if X < 0 then
    ClampedX := 0
  else if X >= ASurface.Width then
    ClampedX := ASurface.Width - 1
  else
    ClampedX := X;

  if Y < 0 then
    ClampedY := 0
  else if Y >= ASurface.Height then
    ClampedY := ASurface.Height - 1
  else
    ClampedY := Y;

  Result := ASurface.FPixels[
    ASurface.IndexOf(
      ClampedX,
      ClampedY
    )
  ];
end;

constructor TRasterSurface.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  SetSize(AWidth, AHeight);
end;

constructor TRasterSurface.Create;
begin
  inherited Create;
  SetSize(1, 1);
end;

function TRasterSurface.IndexOf(X, Y: Integer): Integer;
begin
  Result := (Y * FWidth) + X;
end;

procedure TRasterSurface.SetSize(AWidth, AHeight: Integer);
begin
  FWidth := Max(1, AWidth);
  FHeight := Max(1, AHeight);
  SetLength(FPixels, FWidth * FHeight);
  Clear(TransparentColor);
end;

procedure TRasterSurface.Assign(ASource: TRasterSurface);
var
  ByteCount: SizeInt;
begin
  if ASource = nil then
    Exit;
  FWidth := ASource.Width;
  FHeight := ASource.Height;
  SetLength(FPixels, FWidth * FHeight);
  ByteCount := Length(FPixels) * SizeOf(TRGBA32);
  if ByteCount > 0 then
    Move(ASource.FPixels[0], FPixels[0], ByteCount);
end;

function TRasterSurface.Clone: TRasterSurface;
begin
  Result := TRasterSurface.Create;
  Result.Assign(Self);
end;

function TRasterSurface.InBounds(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (Y >= 0) and (X < FWidth) and (Y < FHeight);
end;

procedure TRasterSurface.Clear(const AColor: TRGBA32);
var
  Index: Integer;
begin
  for Index := 0 to High(FPixels) do
    FPixels[Index] := AColor;
end;

function TRasterSurface.GetPixel(X, Y: Integer): TRGBA32;
begin
  if not InBounds(X, Y) then
    Exit(TransparentColor);
  Result := FPixels[IndexOf(X, Y)];
end;

procedure TRasterSurface.SetPixel(X, Y: Integer; const AValue: TRGBA32);
begin
  if not InBounds(X, Y) then
    Exit;
  FPixels[IndexOf(X, Y)] := AValue;
end;

procedure TRasterSurface.BlendPixel(X, Y: Integer; const AColor: TRGBA32; Opacity: Byte);
var
  PixelIndex: Integer;
begin
  if not InBounds(X, Y) then
    Exit;
  PixelIndex := IndexOf(X, Y);
  FPixels[PixelIndex] := BlendNormal(AColor, FPixels[PixelIndex], Opacity);
end;

procedure TRasterSurface.DrawBrush(X, Y, Radius: Integer; const AColor: TRGBA32; Opacity: Byte; Hardness: Byte);
var
  DrawX: Integer;
  DrawY: Integer;
  RadiusSquared: Integer;
  DeltaX: Integer;
  DeltaY: Integer;
  DistSquared: Integer;
  EdgeRadius: Integer;
  EdgeSquared: Integer;
  EffectiveOpacity: Integer;
begin
  Radius := Max(0, Radius);
  RadiusSquared := Radius * Radius;
  EdgeRadius := Radius * Hardness div 255;
  EdgeSquared := EdgeRadius * EdgeRadius;
  for DrawY := Y - Radius to Y + Radius do
  begin
    for DrawX := X - Radius to X + Radius do
    begin
      DeltaX := DrawX - X;
      DeltaY := DrawY - Y;
      DistSquared := (DeltaX * DeltaX) + (DeltaY * DeltaY);
      if DistSquared > RadiusSquared then
        Continue;
      if (Hardness >= 255) or (DistSquared <= EdgeSquared) then
        EffectiveOpacity := Opacity
      else if RadiusSquared > EdgeSquared then
        EffectiveOpacity := Opacity * (RadiusSquared - DistSquared) div (RadiusSquared - EdgeSquared)
      else
        EffectiveOpacity := 0;
      if EffectiveOpacity > 0 then
        BlendPixel(DrawX, DrawY, AColor, Min(255, EffectiveOpacity));
    end;
  end;
end;

procedure TRasterSurface.DrawLine(X1, Y1, X2, Y2, Radius: Integer; const AColor: TRGBA32; Opacity: Byte; Hardness: Byte);
var
  DX: Integer;
  DY: Integer;
  StepX: Integer;
  StepY: Integer;
  ErrorValue: Integer;
  DoubleError: Integer;
begin
  DX := Abs(X2 - X1);
  DY := Abs(Y2 - Y1);
  if X1 < X2 then
    StepX := 1
  else
    StepX := -1;
  if Y1 < Y2 then
    StepY := 1
  else
    StepY := -1;

  ErrorValue := DX - DY;
  while True do
  begin
    DrawBrush(X1, Y1, Radius, AColor, Opacity, Hardness);
    if (X1 = X2) and (Y1 = Y2) then
      Break;
    DoubleError := ErrorValue * 2;
    if DoubleError > -DY then
    begin
      ErrorValue := ErrorValue - DY;
      X1 := X1 + StepX;
    end;
    if DoubleError < DX then
    begin
      ErrorValue := ErrorValue + DX;
      Y1 := Y1 + StepY;
    end;
  end;
end;

procedure TRasterSurface.DrawRectangle(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte);
var
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  X: Integer;
  Y: Integer;
begin
  LeftX := Min(X1, X2);
  RightX := Max(X1, X2);
  TopY := Min(Y1, Y2);
  BottomY := Max(Y1, Y2);

  if Filled then
  begin
    for Y := TopY to BottomY do
      for X := LeftX to RightX do
        BlendPixel(X, Y, AColor, Opacity);
    Exit;
  end;

  StrokeWidth := Max(1, StrokeWidth);
  for Y := TopY to BottomY do
  begin
    for X := LeftX to RightX do
    begin
      if (X < LeftX + StrokeWidth) or
         (X > RightX - StrokeWidth) or
         (Y < TopY + StrokeWidth) or
         (Y > BottomY - StrokeWidth) then
        BlendPixel(X, Y, AColor, Opacity);
    end;
  end;
end;

procedure TRasterSurface.DrawRoundedRectangle(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte);
var
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  X: Integer;
  Y: Integer;
  CornerRadius: Integer;
  InnerLeft: Integer;
  InnerRight: Integer;
  InnerTop: Integer;
  InnerBottom: Integer;
  InnerRadius: Integer;
  PixelCenterX: Double;
  PixelCenterY: Double;
  DrawPixel: Boolean;
  function InsideRoundedRect(AX, AY: Double; ALeft, ATop, ARight, ABottom, ARadius: Integer): Boolean;
  var
    CenterX: Double;
    CenterY: Double;
  begin
    if (ALeft > ARight) or (ATop > ABottom) then
      Exit(False);
    ARadius := Max(0, Min(ARadius, Min((ARight - ALeft + 1) div 2, (ABottom - ATop + 1) div 2)));
    if (AX >= ALeft + ARadius) and (AX <= ARight - ARadius) then
      Exit((AY >= ATop) and (AY <= ABottom));
    if (AY >= ATop + ARadius) and (AY <= ABottom - ARadius) then
      Exit((AX >= ALeft) and (AX <= ARight));
    if AX < ALeft + ARadius then
      CenterX := ALeft + ARadius
    else
      CenterX := ARight - ARadius;
    if AY < ATop + ARadius then
      CenterY := ATop + ARadius
    else
      CenterY := ABottom - ARadius;
    Result := Sqr(AX - CenterX) + Sqr(AY - CenterY) <= Sqr(ARadius);
  end;
begin
  LeftX := Min(X1, X2);
  RightX := Max(X1, X2);
  TopY := Min(Y1, Y2);
  BottomY := Max(Y1, Y2);
  StrokeWidth := Max(1, StrokeWidth);
  CornerRadius := Max(2, Min((RightX - LeftX + 1) div 4, (BottomY - TopY + 1) div 4));
  CornerRadius := Max(CornerRadius, StrokeWidth);

  InnerLeft := LeftX + StrokeWidth;
  InnerRight := RightX - StrokeWidth;
  InnerTop := TopY + StrokeWidth;
  InnerBottom := BottomY - StrokeWidth;
  InnerRadius := Max(0, CornerRadius - StrokeWidth);

  for Y := TopY to BottomY do
    for X := LeftX to RightX do
    begin
      PixelCenterX := X + 0.5;
      PixelCenterY := Y + 0.5;
      DrawPixel := InsideRoundedRect(PixelCenterX, PixelCenterY, LeftX, TopY, RightX, BottomY, CornerRadius);
      if DrawPixel and (not Filled) and (InnerLeft <= InnerRight) and (InnerTop <= InnerBottom) then
        DrawPixel := not InsideRoundedRect(PixelCenterX, PixelCenterY, InnerLeft, InnerTop, InnerRight, InnerBottom, InnerRadius);
      if DrawPixel then
        BlendPixel(X, Y, AColor, Opacity);
    end;
end;

procedure TRasterSurface.DrawEllipse(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte);
var
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  CenterX: Double;
  CenterY: Double;
  RadiusX: Double;
  RadiusY: Double;
  InnerRadiusX: Double;
  InnerRadiusY: Double;
  NX: Double;
  NY: Double;
  InnerNX: Double;
  InnerNY: Double;
  DistanceValue: Double;
  InnerDistanceValue: Double;
  X: Integer;
  Y: Integer;
begin
  LeftX := Min(X1, X2);
  RightX := Max(X1, X2);
  TopY := Min(Y1, Y2);
  BottomY := Max(Y1, Y2);

  CenterX := (LeftX + RightX) / 2.0;
  CenterY := (TopY + BottomY) / 2.0;
  RadiusX := Max(0.5, (RightX - LeftX + 1) / 2.0);
  RadiusY := Max(0.5, (BottomY - TopY + 1) / 2.0);

  if Filled then
  begin
    for Y := TopY to BottomY do
      for X := LeftX to RightX do
      begin
        NX := (X - CenterX) / RadiusX;
        NY := (Y - CenterY) / RadiusY;
        if (NX * NX) + (NY * NY) <= 1.0 then
          BlendPixel(X, Y, AColor, Opacity);
      end;
    Exit;
  end;

  StrokeWidth := Max(1, StrokeWidth);
  InnerRadiusX := RadiusX - StrokeWidth;
  InnerRadiusY := RadiusY - StrokeWidth;
  if (InnerRadiusX <= 0.0) or (InnerRadiusY <= 0.0) then
  begin
    DrawEllipse(X1, Y1, X2, Y2, StrokeWidth, AColor, True, Opacity);
    Exit;
  end;

  for Y := TopY to BottomY do
    for X := LeftX to RightX do
    begin
      NX := (X - CenterX) / RadiusX;
      NY := (Y - CenterY) / RadiusY;
      DistanceValue := (NX * NX) + (NY * NY);
      if DistanceValue > 1.0 then
        Continue;

      InnerNX := (X - CenterX) / InnerRadiusX;
      InnerNY := (Y - CenterY) / InnerRadiusY;
      InnerDistanceValue := (InnerNX * InnerNX) + (InnerNY * InnerNY);
      if InnerDistanceValue >= 1.0 then
        BlendPixel(X, Y, AColor, Opacity);
    end;
end;

procedure TRasterSurface.DrawPolygon(const APoints: array of TPoint; StrokeWidth: Integer; const AColor: TRGBA32; Closed: Boolean; Opacity: Byte);
var
  PointIndex: Integer;
  LineRadius: Integer;
begin
  if High(APoints) < 1 then
    Exit;

  LineRadius := Max(1, (Max(1, StrokeWidth) + 1) div 2);
  for PointIndex := 0 to High(APoints) - 1 do
    DrawLine(
      APoints[PointIndex].X,
      APoints[PointIndex].Y,
      APoints[PointIndex + 1].X,
      APoints[PointIndex + 1].Y,
      LineRadius,
      AColor,
      Opacity
    );

  if Closed and (High(APoints) >= 2) then
    DrawLine(
      APoints[High(APoints)].X,
      APoints[High(APoints)].Y,
      APoints[0].X,
      APoints[0].Y,
      LineRadius,
      AColor,
      Opacity
    );
end;

procedure TRasterSurface.FillPolygon(const APoints: array of TPoint; const AColor: TRGBA32; Opacity: Byte);
var
  MinY: Integer;
  MaxY: Integer;
  Y: Integer;
  PointIndex: Integer;
  NextIndex: Integer;
  X1: Integer;
  Y1: Integer;
  X2: Integer;
  Y2: Integer;
  CrossX: Integer;
  FillX: Integer;
  InsertAt: Integer;
  SwapValue: Integer;
  Intersections: array of Integer;
begin
  if High(APoints) < 2 then
    Exit;

  MinY := APoints[0].Y;
  MaxY := APoints[0].Y;
  for PointIndex := 1 to High(APoints) do
  begin
    if APoints[PointIndex].Y < MinY then
      MinY := APoints[PointIndex].Y;
    if APoints[PointIndex].Y > MaxY then
      MaxY := APoints[PointIndex].Y;
  end;

  for Y := Max(0, MinY) to Min(FHeight - 1, MaxY) do
  begin
    SetLength(Intersections, 0);
    for PointIndex := 0 to High(APoints) do
    begin
      NextIndex := PointIndex + 1;
      if NextIndex > High(APoints) then
        NextIndex := 0;
      X1 := APoints[PointIndex].X;
      Y1 := APoints[PointIndex].Y;
      X2 := APoints[NextIndex].X;
      Y2 := APoints[NextIndex].Y;
      if Y1 = Y2 then
        Continue;
      if (Y < Min(Y1, Y2)) or (Y >= Max(Y1, Y2)) then
        Continue;
      CrossX := X1 + Round((Y - Y1) * (X2 - X1) / (Y2 - Y1));
      InsertAt := Length(Intersections);
      SetLength(Intersections, InsertAt + 1);
      while (InsertAt > 0) and (Intersections[InsertAt - 1] > CrossX) do
      begin
        SwapValue := Intersections[InsertAt - 1];
        Intersections[InsertAt] := SwapValue;
        Dec(InsertAt);
      end;
      Intersections[InsertAt] := CrossX;
    end;

    PointIndex := 0;
    while PointIndex + 1 < Length(Intersections) do
    begin
      for FillX := Max(0, Intersections[PointIndex]) to Min(FWidth - 1, Intersections[PointIndex + 1]) do
        BlendPixel(FillX, Y, AColor, Opacity);
      Inc(PointIndex, 2);
    end;
  end;
end;

procedure TRasterSurface.FloodFill(X, Y: Integer; const AColor: TRGBA32; Tolerance: Byte);
var
  TargetColor: TRGBA32;
  Queue: array of Integer;
  Head: Integer;
  Tail: Integer;
  CurrentIndex: Integer;
  CurrentX: Integer;
  CurrentY: Integer;

  procedure EnqueueIfMatch(AX, AY: Integer);
  var
    PixelIndex: Integer;
  begin
    if not InBounds(AX, AY) then
      Exit;
    PixelIndex := IndexOf(AX, AY);
    if not ColorsCloseEnough(FPixels[PixelIndex], TargetColor, Tolerance) then
      Exit;
    if RGBAEqual(FPixels[PixelIndex], AColor) then
      Exit;
    FPixels[PixelIndex] := AColor;
    Queue[Tail] := PixelIndex;
    Inc(Tail);
  end;

begin
  if not InBounds(X, Y) then
    Exit;

  TargetColor := Pixels[X, Y];
  if ColorsCloseEnough(TargetColor, AColor, Tolerance) then
    Exit;

  Queue := nil;
  SetLength(Queue, FWidth * FHeight);
  Head := 0;
  Tail := 0;
  FPixels[IndexOf(X, Y)] := AColor;
  Queue[Tail] := IndexOf(X, Y);
  Inc(Tail);

  while Head < Tail do
  begin
    CurrentIndex := Queue[Head];
    Inc(Head);
    CurrentY := CurrentIndex div FWidth;
    CurrentX := CurrentIndex - (CurrentY * FWidth);
    EnqueueIfMatch(CurrentX - 1, CurrentY);
    EnqueueIfMatch(CurrentX + 1, CurrentY);
    EnqueueIfMatch(CurrentX, CurrentY - 1);
    EnqueueIfMatch(CurrentX, CurrentY + 1);
  end;
end;

procedure TRasterSurface.FillGradient(X1, Y1, X2, Y2: Integer; const StartColor, EndColor: TRGBA32);
var
  X: Integer;
  Y: Integer;
  DX: Double;
  DY: Double;
  LengthSquared: Double;
  Projection: Double;
begin
  DX := X2 - X1;
  DY := Y2 - Y1;
  LengthSquared := (DX * DX) + (DY * DY);

  if LengthSquared <= 0.0 then
  begin
    Clear(StartColor);
    Exit;
  end;

  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Projection := (((X - X1) * DX) + ((Y - Y1) * DY)) / LengthSquared;
      Pixels[X, Y] := LerpColor(StartColor, EndColor, Projection);
    end;
end;

procedure TRasterSurface.FillRadialGradient(CenterX, CenterY, Radius: Integer; const StartColor, EndColor: TRGBA32);
var
  X: Integer;
  Y: Integer;
  Dist: Double;
  T: Double;
begin
  if Radius <= 0 then
  begin
    Clear(StartColor);
    Exit;
  end;
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Dist := Sqrt(((X - CenterX) * (X - CenterX)) + ((Y - CenterY) * (Y - CenterY)));
      T := Dist / Radius;
      Pixels[X, Y] := LerpColor(StartColor, EndColor, T);
    end;
end;

procedure TRasterSurface.PasteSurface(ASource: TRasterSurface; OffsetX, OffsetY: Integer; Opacity: Byte);
var
  SourceX: Integer;
  SourceY: Integer;
  TargetX: Integer;
  TargetY: Integer;
begin
  if ASource = nil then
    Exit;
  for SourceY := 0 to ASource.Height - 1 do
  begin
    TargetY := SourceY + OffsetY;
    if (TargetY < 0) or (TargetY >= FHeight) then
      Continue;
    for SourceX := 0 to ASource.Width - 1 do
    begin
      TargetX := SourceX + OffsetX;
      if (TargetX < 0) or (TargetX >= FWidth) then
        Continue;
      BlendPixel(TargetX, TargetY, ASource[SourceX, SourceY], Opacity);
    end;
  end;
end;

procedure TRasterSurface.CopyRegionTo(ADest: TRasterSurface; SrcX, SrcY: Integer);
{ Copies ADest.Width × ADest.Height pixels from Self starting at (SrcX, SrcY) into
  ADest at (0, 0). Used to snapshot a dirty region before a paint operation. }
var
  Row: Integer;
  W: Integer;
begin
  if ADest = nil then Exit;
  W := ADest.FWidth;
  for Row := 0 to ADest.FHeight - 1 do
  begin
    if (SrcY + Row < 0) or (SrcY + Row >= FHeight) then Continue;
    if (SrcX < 0) or (SrcX + W > FWidth) then Continue;
    Move(FPixels[IndexOf(SrcX, SrcY + Row)],
         ADest.FPixels[Row * W],
         W * SizeOf(TRGBA32));
  end;
end;

procedure TRasterSurface.OverwriteRegion(ASource: TRasterSurface; DstX, DstY: Integer);
{ Writes ASource.Width × ASource.Height pixels from ASource into Self at (DstX, DstY).
  Direct overwrite — no blending. Used to restore a saved region snapshot on undo. }
var
  Row: Integer;
  W: Integer;
begin
  if ASource = nil then Exit;
  W := ASource.FWidth;
  for Row := 0 to ASource.FHeight - 1 do
  begin
    if (DstY + Row < 0) or (DstY + Row >= FHeight) then Continue;
    if (DstX < 0) or (DstX + W > FWidth) then Continue;
    Move(ASource.FPixels[Row * W],
         FPixels[IndexOf(DstX, DstY + Row)],
         W * SizeOf(TRGBA32));
  end;
end;

procedure TRasterSurface.FlipHorizontal;
var
  X: Integer;
  Y: Integer;
  HalfWidth: Integer;
  Temp: TRGBA32;
begin
  HalfWidth := FWidth div 2;
  for Y := 0 to FHeight - 1 do
    for X := 0 to HalfWidth - 1 do
    begin
      Temp := Pixels[X, Y];
      Pixels[X, Y] := Pixels[FWidth - 1 - X, Y];
      Pixels[FWidth - 1 - X, Y] := Temp;
    end;
end;

procedure TRasterSurface.FlipVertical;
var
  X: Integer;
  Y: Integer;
  HalfHeight: Integer;
  Temp: TRGBA32;
begin
  HalfHeight := FHeight div 2;
  for Y := 0 to HalfHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Temp := Pixels[X, Y];
      Pixels[X, Y] := Pixels[X, FHeight - 1 - Y];
      Pixels[X, FHeight - 1 - Y] := Temp;
    end;
end;

procedure TRasterSurface.Rotate180;
begin
  FlipHorizontal;
  FlipVertical;
end;

procedure TRasterSurface.Rotate90Clockwise;
var
  NewSurface: TRasterSurface;
  X: Integer;
  Y: Integer;
begin
  NewSurface := TRasterSurface.Create(FHeight, FWidth);
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
        NewSurface[FHeight - 1 - Y, X] := Pixels[X, Y];
    Assign(NewSurface);
  finally
    NewSurface.Free;
  end;
end;

procedure TRasterSurface.Rotate90CounterClockwise;
var
  NewSurface: TRasterSurface;
  X: Integer;
  Y: Integer;
begin
  NewSurface := TRasterSurface.Create(FHeight, FWidth);
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
        NewSurface[Y, FWidth - 1 - X] := Pixels[X, Y];
    Assign(NewSurface);
  finally
    NewSurface.Free;
  end;
end;

procedure TRasterSurface.AutoLevel;
var
  Index: Integer;
  HasVisiblePixel: Boolean;
  MinR: Integer;
  MinG: Integer;
  MinB: Integer;
  MaxR: Integer;
  MaxG: Integer;
  MaxB: Integer;

  function StretchChannel(ChannelValue, MinValue, MaxValue: Integer): Byte;
  begin
    if MaxValue <= MinValue then
      Exit(ClampChannel(ChannelValue));
    Result := ClampChannel(
      Round(((ChannelValue - MinValue) * 255.0) / (MaxValue - MinValue))
    );
  end;

begin
  HasVisiblePixel := False;
  MinR := 255;
  MinG := 255;
  MinB := 255;
  MaxR := 0;
  MaxG := 0;
  MaxB := 0;

  for Index := 0 to High(FPixels) do
  begin
    if FPixels[Index].A = 0 then
      Continue;
    HasVisiblePixel := True;
    if FPixels[Index].R < MinR then
      MinR := FPixels[Index].R;
    if FPixels[Index].G < MinG then
      MinG := FPixels[Index].G;
    if FPixels[Index].B < MinB then
      MinB := FPixels[Index].B;
    if FPixels[Index].R > MaxR then
      MaxR := FPixels[Index].R;
    if FPixels[Index].G > MaxG then
      MaxG := FPixels[Index].G;
    if FPixels[Index].B > MaxB then
      MaxB := FPixels[Index].B;
  end;

  if not HasVisiblePixel then
    Exit;

  for Index := 0 to High(FPixels) do
  begin
    if FPixels[Index].A = 0 then
      Continue;
    FPixels[Index].R := StretchChannel(FPixels[Index].R, MinR, MaxR);
    FPixels[Index].G := StretchChannel(FPixels[Index].G, MinG, MaxG);
    FPixels[Index].B := StretchChannel(FPixels[Index].B, MinB, MaxB);
  end;
end;

procedure TRasterSurface.InvertColors;
var
  Index: Integer;
begin
  for Index := 0 to High(FPixels) do
  begin
    FPixels[Index].R := 255 - FPixels[Index].R;
    FPixels[Index].G := 255 - FPixels[Index].G;
    FPixels[Index].B := 255 - FPixels[Index].B;
  end;
end;

procedure TRasterSurface.Grayscale;
var
  Index: Integer;
  Luma: Integer;
begin
  for Index := 0 to High(FPixels) do
  begin
    Luma := (FPixels[Index].R * 77 + FPixels[Index].G * 150 + FPixels[Index].B * 29) div 256;
    FPixels[Index].R := ClampChannel(Luma);
    FPixels[Index].G := ClampChannel(Luma);
    FPixels[Index].B := ClampChannel(Luma);
  end;
end;

procedure TRasterSurface.AdjustHueSaturation(HueDelta: Integer; SaturationDelta: Integer);
var
  Index: Integer;
  HueValue: Double;
  SaturationValue: Double;
  ValueLevel: Double;
begin
  for Index := 0 to High(FPixels) do
  begin
    if FPixels[Index].A = 0 then
      Continue;
    RGBToHSV(FPixels[Index], HueValue, SaturationValue, ValueLevel);
    HueValue := HueValue + HueDelta;
    SaturationValue := EnsureRange(
      SaturationValue + (SaturationDelta / 100.0),
      0.0,
      1.0
    );
    FPixels[Index] := HSVToRGBA(HueValue, SaturationValue, ValueLevel, FPixels[Index].A);
  end;
end;

procedure TRasterSurface.AdjustGammaCurve(Gamma: Double);
var
  Index: Integer;
  EffectiveGamma: Double;
  function MapChannel(Channel: Byte): Byte;
  var
    Normalized: Double;
  begin
    Normalized := Channel / 255.0;
    Result := ClampChannel(Round(Power(Normalized, EffectiveGamma) * 255.0));
  end;
begin
  EffectiveGamma := EnsureRange(Gamma, 0.1, 5.0);
  for Index := 0 to High(FPixels) do
  begin
    if FPixels[Index].A = 0 then
      Continue;
    FPixels[Index].R := MapChannel(FPixels[Index].R);
    FPixels[Index].G := MapChannel(FPixels[Index].G);
    FPixels[Index].B := MapChannel(FPixels[Index].B);
  end;
end;

procedure TRasterSurface.AdjustLevels(InputLow, InputHigh, OutputLow, OutputHigh: Byte);
var
  Index: Integer;
  ClampedInputLow: Integer;
  ClampedInputHigh: Integer;
  InputRange: Integer;
  OutputRange: Integer;
  function MapChannel(Channel: Byte): Byte;
  var
    Normalized: Double;
  begin
    if Channel <= ClampedInputLow then
      Exit(OutputLow);
    if Channel >= ClampedInputHigh then
      Exit(OutputHigh);
    Normalized := (Channel - ClampedInputLow) / InputRange;
    Result := ClampChannel(OutputLow + Round(Normalized * OutputRange));
  end;
begin
  ClampedInputLow := EnsureRange(InputLow, 0, 254);
  ClampedInputHigh := EnsureRange(InputHigh, ClampedInputLow + 1, 255);
  InputRange := Max(1, ClampedInputHigh - ClampedInputLow);
  OutputRange := OutputHigh - OutputLow;

  for Index := 0 to High(FPixels) do
  begin
    if FPixels[Index].A = 0 then
      Continue;
    FPixels[Index].R := MapChannel(FPixels[Index].R);
    FPixels[Index].G := MapChannel(FPixels[Index].G);
    FPixels[Index].B := MapChannel(FPixels[Index].B);
  end;
end;

procedure TRasterSurface.AdjustBrightness(Delta: Integer);
var
  Index: Integer;
begin
  for Index := 0 to High(FPixels) do
  begin
    FPixels[Index].R := ClampChannel(FPixels[Index].R + Delta);
    FPixels[Index].G := ClampChannel(FPixels[Index].G + Delta);
    FPixels[Index].B := ClampChannel(FPixels[Index].B + Delta);
  end;
end;

procedure TRasterSurface.AdjustContrast(Amount: Integer);
var
  Index: Integer;
  ContrastValue: Integer;
  Factor: Double;
begin
  ContrastValue := EnsureRange(Amount, -255, 254);
  Factor := (259.0 * (ContrastValue + 255.0)) / (255.0 * (259.0 - ContrastValue));
  for Index := 0 to High(FPixels) do
  begin
    FPixels[Index].R := ClampChannel(Round(Factor * (FPixels[Index].R - 128) + 128));
    FPixels[Index].G := ClampChannel(Round(Factor * (FPixels[Index].G - 128) + 128));
    FPixels[Index].B := ClampChannel(Round(Factor * (FPixels[Index].B - 128) + 128));
  end;
end;

procedure TRasterSurface.Sepia;
var
  Index: Integer;
  OriginalR: Integer;
  OriginalG: Integer;
  OriginalB: Integer;
begin
  for Index := 0 to High(FPixels) do
  begin
    OriginalR := FPixels[Index].R;
    OriginalG := FPixels[Index].G;
    OriginalB := FPixels[Index].B;
    FPixels[Index].R := ClampChannel(Round(OriginalR * 0.393 + OriginalG * 0.769 + OriginalB * 0.189));
    FPixels[Index].G := ClampChannel(Round(OriginalR * 0.349 + OriginalG * 0.686 + OriginalB * 0.168));
    FPixels[Index].B := ClampChannel(Round(OriginalR * 0.272 + OriginalG * 0.534 + OriginalB * 0.131));
  end;
end;

procedure TRasterSurface.BlackAndWhite(Threshold: Byte);
var
  Index: Integer;
  Luma: Integer;
  ChannelValue: Byte;
begin
  for Index := 0 to High(FPixels) do
  begin
    Luma := (FPixels[Index].R * 77 + FPixels[Index].G * 150 + FPixels[Index].B * 29) div 256;
    if Luma >= Threshold then
      ChannelValue := 255
    else
      ChannelValue := 0;
    FPixels[Index].R := ChannelValue;
    FPixels[Index].G := ChannelValue;
    FPixels[Index].B := ChannelValue;
  end;
end;

procedure TRasterSurface.Posterize(Levels: Byte);
var
  Index: Integer;
  LevelCount: Integer;
  ScaleValue: Double;

  function PosterizeChannel(Channel: Byte): Byte;
  var
    Quantized: Integer;
  begin
    Quantized := Round((Channel / 255.0) * LevelCount);
    Result := ClampChannel(Round(Quantized * ScaleValue));
  end;

begin
  LevelCount := EnsureRange(Levels, 2, 64) - 1;
  ScaleValue := 255.0 / LevelCount;
  for Index := 0 to High(FPixels) do
  begin
    FPixels[Index].R := PosterizeChannel(FPixels[Index].R);
    FPixels[Index].G := PosterizeChannel(FPixels[Index].G);
    FPixels[Index].B := PosterizeChannel(FPixels[Index].B);
  end;
end;

procedure TRasterSurface.BoxBlur(Radius: Integer);
var
  Temp: TRasterSurface;
  X: Integer;
  Y: Integer;
  SampleIndex: Integer;
  WindowSize: Integer;
  SumR: Integer;
  SumG: Integer;
  SumB: Integer;
  SumA: Integer;
  PixelValue: TRGBA32;
  RemovePixel: TRGBA32;
  AddPixel: TRGBA32;
begin
  if Radius < 1 then
    Radius := 1
  else if Radius > 64 then
    Radius := 64;
  Temp := TRasterSurface.Create(FWidth, FHeight);
  try
    WindowSize := (Radius * 2) + 1;

    for Y := 0 to FHeight - 1 do
    begin
      SumR := 0;
      SumG := 0;
      SumB := 0;
      SumA := 0;
      for SampleIndex := -Radius to Radius do
      begin
        PixelValue := PixelAtClamped(Self, SampleIndex, Y);
        Inc(SumR, PixelValue.R);
        Inc(SumG, PixelValue.G);
        Inc(SumB, PixelValue.B);
        Inc(SumA, PixelValue.A);
      end;

      for X := 0 to FWidth - 1 do
      begin
        Temp.FPixels[Temp.IndexOf(X, Y)] := RGBA(
          ClampChannel(SumR div WindowSize),
          ClampChannel(SumG div WindowSize),
          ClampChannel(SumB div WindowSize),
          ClampChannel(SumA div WindowSize)
        );

        RemovePixel := PixelAtClamped(Self, X - Radius, Y);
        AddPixel := PixelAtClamped(Self, X + Radius + 1, Y);
        Dec(SumR, RemovePixel.R);
        Dec(SumG, RemovePixel.G);
        Dec(SumB, RemovePixel.B);
        Dec(SumA, RemovePixel.A);
        Inc(SumR, AddPixel.R);
        Inc(SumG, AddPixel.G);
        Inc(SumB, AddPixel.B);
        Inc(SumA, AddPixel.A);
      end;
    end;

    for X := 0 to FWidth - 1 do
    begin
      SumR := 0;
      SumG := 0;
      SumB := 0;
      SumA := 0;
      for SampleIndex := -Radius to Radius do
      begin
        PixelValue := PixelAtClamped(Temp, X, SampleIndex);
        Inc(SumR, PixelValue.R);
        Inc(SumG, PixelValue.G);
        Inc(SumB, PixelValue.B);
        Inc(SumA, PixelValue.A);
      end;

      for Y := 0 to FHeight - 1 do
      begin
        FPixels[IndexOf(X, Y)] := RGBA(
          ClampChannel(SumR div WindowSize),
          ClampChannel(SumG div WindowSize),
          ClampChannel(SumB div WindowSize),
          ClampChannel(SumA div WindowSize)
        );

        RemovePixel := PixelAtClamped(Temp, X, Y - Radius);
        AddPixel := PixelAtClamped(Temp, X, Y + Radius + 1);
        Dec(SumR, RemovePixel.R);
        Dec(SumG, RemovePixel.G);
        Dec(SumB, RemovePixel.B);
        Dec(SumA, RemovePixel.A);
        Inc(SumR, AddPixel.R);
        Inc(SumG, AddPixel.G);
        Inc(SumB, AddPixel.B);
        Inc(SumA, AddPixel.A);
      end;
    end;
  finally
    Temp.Free;
  end;
end;

procedure TRasterSurface.Sharpen;
const
  Kernel: array[0..8] of Integer = (
     0, -1,  0,
    -1,  5, -1,
     0, -1,  0
  );
var
  Source: TRasterSurface;
  X: Integer;
  Y: Integer;
  SampleX: Integer;
  SampleY: Integer;
  KernelIndex: Integer;
  SumR: Integer;
  SumG: Integer;
  SumB: Integer;
  PixelValue: TRGBA32;
begin
  Source := Clone;
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
      begin
        SumR := 0;
        SumG := 0;
        SumB := 0;
        KernelIndex := 0;
        for SampleY := -1 to 1 do
          for SampleX := -1 to 1 do
          begin
            PixelValue := PixelAtClamped(Source, X + SampleX, Y + SampleY);
            Inc(SumR, PixelValue.R * Kernel[KernelIndex]);
            Inc(SumG, PixelValue.G * Kernel[KernelIndex]);
            Inc(SumB, PixelValue.B * Kernel[KernelIndex]);
            Inc(KernelIndex);
          end;

        PixelValue := Source.FPixels[Source.IndexOf(X, Y)];
        PixelValue.R := ClampChannel(SumR);
        PixelValue.G := ClampChannel(SumG);
        PixelValue.B := ClampChannel(SumB);
        FPixels[IndexOf(X, Y)] := PixelValue;
      end;
  finally
    Source.Free;
  end;
end;

procedure TRasterSurface.AddNoise(Amount: Byte; Seed: Cardinal);
var
  Index: Integer;
  State: Cardinal;
  Span: Integer;
  Delta: Integer;
begin
  if Amount = 0 then
    Exit;

  State := Seed;
  if State = 0 then
    State := 1;
  Span := Integer(Amount) * 2 + 1;

  for Index := 0 to High(FPixels) do
  begin
    Delta := (NextNoiseValue(State) mod Span) - Amount;
    FPixels[Index].R := ClampChannel(FPixels[Index].R + Delta);
    Delta := (NextNoiseValue(State) mod Span) - Amount;
    FPixels[Index].G := ClampChannel(FPixels[Index].G + Delta);
    Delta := (NextNoiseValue(State) mod Span) - Amount;
    FPixels[Index].B := ClampChannel(FPixels[Index].B + Delta);
  end;
end;

procedure TRasterSurface.DetectEdges;
const
  KernelX: array[0..8] of Integer = (
    -1, 0, 1,
    -2, 0, 2,
    -1, 0, 1
  );
  KernelY: array[0..8] of Integer = (
    -1, -2, -1,
     0,  0,  0,
     1,  2,  1
  );
var
  Source: TRasterSurface;
  X: Integer;
  Y: Integer;
  SampleX: Integer;
  SampleY: Integer;
  KernelIndex: Integer;
  GX: Integer;
  GY: Integer;
  EdgeStrength: Integer;
  PixelValue: TRGBA32;
begin
  Source := Clone;
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
      begin
        GX := 0;
        GY := 0;
        KernelIndex := 0;
        for SampleY := -1 to 1 do
          for SampleX := -1 to 1 do
          begin
            PixelValue := PixelAtClamped(Source, X + SampleX, Y + SampleY);
            Inc(GX, LumaOfColor(PixelValue) * KernelX[KernelIndex]);
            Inc(GY, LumaOfColor(PixelValue) * KernelY[KernelIndex]);
            Inc(KernelIndex);
          end;

        EdgeStrength := ClampChannel((Abs(GX) + Abs(GY)) div 4);
        PixelValue := Source.FPixels[Source.IndexOf(X, Y)];
        PixelValue.R := EdgeStrength;
        PixelValue.G := EdgeStrength;
        PixelValue.B := EdgeStrength;
        FPixels[IndexOf(X, Y)] := PixelValue;
      end;
  finally
    Source.Free;
  end;
end;

procedure TRasterSurface.Emboss;
const
  Kernel: array[0..8] of Integer = (
    -2, -1, 0,
    -1,  0, 1,
     0,  1, 2
  );
var
  Source: TRasterSurface;
  X, Y: Integer;
  SampleX, SampleY: Integer;
  KernelIndex: Integer;
  SumR, SumG, SumB: Integer;
  Src: TRGBA32;
begin
  Source := Clone;
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
      begin
        SumR := 128; SumG := 128; SumB := 128;
        KernelIndex := 0;
        for SampleY := -1 to 1 do
          for SampleX := -1 to 1 do
          begin
            Src := PixelAtClamped(Source, X + SampleX, Y + SampleY);
            Inc(SumR, Src.R * Kernel[KernelIndex]);
            Inc(SumG, Src.G * Kernel[KernelIndex]);
            Inc(SumB, Src.B * Kernel[KernelIndex]);
            Inc(KernelIndex);
          end;
        Src := Source.FPixels[Source.IndexOf(X, Y)];
        Src.R := ClampChannel(SumR);
        Src.G := ClampChannel(SumG);
        Src.B := ClampChannel(SumB);
        FPixels[IndexOf(X, Y)] := Src;
      end;
  finally
    Source.Free;
  end;
end;

procedure TRasterSurface.Soften;
const
  Kernel: array[0..8] of Integer = (
    1, 2, 1,
    2, 4, 2,
    1, 2, 1
  );
var
  Source: TRasterSurface;
  X, Y: Integer;
  SampleX, SampleY: Integer;
  KernelIndex: Integer;
  SumR, SumG, SumB, SumA: Integer;
  Src: TRGBA32;
begin
  Source := Clone;
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
      begin
        SumR := 0; SumG := 0; SumB := 0; SumA := 0;
        KernelIndex := 0;
        for SampleY := -1 to 1 do
          for SampleX := -1 to 1 do
          begin
            Src := PixelAtClamped(Source, X + SampleX, Y + SampleY);
            Inc(SumR, Src.R * Kernel[KernelIndex]);
            Inc(SumG, Src.G * Kernel[KernelIndex]);
            Inc(SumB, Src.B * Kernel[KernelIndex]);
            Inc(SumA, Src.A * Kernel[KernelIndex]);
            Inc(KernelIndex);
          end;
        Src := Source.FPixels[Source.IndexOf(X, Y)];
        Src.R := ClampChannel(SumR div 16);
        Src.G := ClampChannel(SumG div 16);
        Src.B := ClampChannel(SumB div 16);
        Src.A := ClampChannel(SumA div 16);
        FPixels[IndexOf(X, Y)] := Src;
      end;
  finally
    Source.Free;
  end;
end;

procedure TRasterSurface.RenderClouds(Seed: Cardinal);
var
  X, Y: Integer;
  V: Double;
  Scale: Double;
  C: TRGBA32;
  Phase: Double;
begin
  Phase := Seed mod 1000 * 0.001 * 6.283;
  Scale := 0.03 + (Seed mod 17) * 0.002;
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      V := Sin(X * Scale + Phase) +
           Sin(Y * Scale + Phase * 1.3) +
           Sin((X + Y) * Scale * 0.7 + Phase * 0.7) +
           Sin(Sqrt((X - FWidth / 2) * (X - FWidth / 2) +
                    (Y - FHeight / 2) * (Y - FHeight / 2)) * Scale + Phase);
      V := (V * 0.25 + 1.0) * 0.5;
      C.R := ClampChannel(Round(V * 80 + 120));
      C.G := ClampChannel(Round(V * 120 + 80));
      C.B := ClampChannel(Round(V * 160 + 40));
      C.A := 255;
      FPixels[IndexOf(X, Y)] := C;
    end;
end;

procedure TRasterSurface.Pixelate(BlockSize: Integer);
var
  X, Y: Integer;
  BX, BY: Integer;
  BlockEndX, BlockEndY: Integer;
  Count: Integer;
  SumR, SumG, SumB, SumA: Integer;
  AvgColor: TRGBA32;
  Source: TRasterSurface;
begin
  if BlockSize <= 1 then Exit;
  Source := Clone;
  try
    Y := 0;
    while Y < FHeight do
    begin
      BlockEndY := Min(FHeight - 1, Y + BlockSize - 1);
      X := 0;
      while X < FWidth do
      begin
        BlockEndX := Min(FWidth - 1, X + BlockSize - 1);
        SumR := 0; SumG := 0; SumB := 0; SumA := 0;
        Count := 0;
        for BY := Y to BlockEndY do
          for BX := X to BlockEndX do
          begin
            Inc(SumR, Source.FPixels[Source.IndexOf(BX, BY)].R);
            Inc(SumG, Source.FPixels[Source.IndexOf(BX, BY)].G);
            Inc(SumB, Source.FPixels[Source.IndexOf(BX, BY)].B);
            Inc(SumA, Source.FPixels[Source.IndexOf(BX, BY)].A);
            Inc(Count);
          end;
        if Count > 0 then
        begin
          AvgColor.R := SumR div Count;
          AvgColor.G := SumG div Count;
          AvgColor.B := SumB div Count;
          AvgColor.A := SumA div Count;
          for BY := Y to BlockEndY do
            for BX := X to BlockEndX do
              FPixels[IndexOf(BX, BY)] := AvgColor;
        end;
        Inc(X, BlockSize);
      end;
      Inc(Y, BlockSize);
    end;
  finally
    Source.Free;
  end;
end;

procedure TRasterSurface.Vignette(Strength: Double);
var
  X, Y: Integer;
  CenterX, CenterY: Double;
  Radius: Double;
  Dist: Double;
  Factor: Double;
  Pix: TRGBA32;
begin
  CenterX := FWidth / 2.0;
  CenterY := FHeight / 2.0;
  Radius := Sqrt(CenterX * CenterX + CenterY * CenterY);
  if Radius <= 0 then Exit;
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Dist := Sqrt((X - CenterX) * (X - CenterX) + (Y - CenterY) * (Y - CenterY));
      Factor := 1.0 - (Dist / Radius) * Strength;
      if Factor < 0.0 then Factor := 0.0;
      if Factor > 1.0 then Factor := 1.0;
      Pix := FPixels[IndexOf(X, Y)];
      Pix.R := ClampChannel(Round(Pix.R * Factor));
      Pix.G := ClampChannel(Round(Pix.G * Factor));
      Pix.B := ClampChannel(Round(Pix.B * Factor));
      FPixels[IndexOf(X, Y)] := Pix;
    end;
end;

procedure TRasterSurface.MotionBlur(Angle: Integer; Distance: Integer);
var
  OffX, OffY: Double;
  AngleRad: Double;
  Src: array of TRGBA32;
  X, Y, Step: Integer;
  SumR, SumG, SumB, SumA, Count: Integer;
  SX, SY: Integer;
begin
  if Distance <= 0 then Exit;
  AngleRad := Angle * Pi / 180.0;
  OffX := Cos(AngleRad);
  OffY := Sin(AngleRad);
  SetLength(Src, FWidth * FHeight);
  Move(FPixels[0], Src[0], FWidth * FHeight * SizeOf(TRGBA32));
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      SumR := 0; SumG := 0; SumB := 0; SumA := 0; Count := 0;
      for Step := -Distance to Distance do
      begin
        SX := X + Round(OffX * Step);
        SY := Y + Round(OffY * Step);
        if (SX >= 0) and (SX < FWidth) and (SY >= 0) and (SY < FHeight) then
        begin
          Inc(SumR, Src[SY * FWidth + SX].R);
          Inc(SumG, Src[SY * FWidth + SX].G);
          Inc(SumB, Src[SY * FWidth + SX].B);
          Inc(SumA, Src[SY * FWidth + SX].A);
          Inc(Count);
        end;
      end;
      if Count > 0 then
      begin
        FPixels[Y * FWidth + X].R := SumR div Count;
        FPixels[Y * FWidth + X].G := SumG div Count;
        FPixels[Y * FWidth + X].B := SumB div Count;
        FPixels[Y * FWidth + X].A := SumA div Count;
      end;
    end;
end;

procedure TRasterSurface.MedianFilter(Radius: Integer);
{ 3x3 or 5x5 fast approximate median: uses sorting with a small fixed-size window }
var
  Src: array of TRGBA32;
  X, Y, KX, KY: Integer;
  RVals, GVals, BVals: array[0..24] of Byte;
  Count, Mid: Integer;
  Tmp: Byte;
  I, J: Integer;
begin
  if Radius <= 0 then Exit;
  Radius := Min(Radius, 2); { cap at 2 (5x5 kernel) }
  SetLength(Src, FWidth * FHeight);
  Move(FPixels[0], Src[0], FWidth * FHeight * SizeOf(TRGBA32));
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Count := 0;
      for KY := -Radius to Radius do
        for KX := -Radius to Radius do
        begin
          if (X + KX >= 0) and (X + KX < FWidth) and (Y + KY >= 0) and (Y + KY < FHeight) then
          begin
            RVals[Count] := Src[(Y + KY) * FWidth + (X + KX)].R;
            GVals[Count] := Src[(Y + KY) * FWidth + (X + KX)].G;
            BVals[Count] := Src[(Y + KY) * FWidth + (X + KX)].B;
            Inc(Count);
          end;
        end;
      if Count = 0 then Continue;
      { Insertion sort each channel }
      for I := 1 to Count - 1 do
      begin
        Tmp := RVals[I]; J := I - 1;
        while (J >= 0) and (RVals[J] > Tmp) do begin RVals[J + 1] := RVals[J]; Dec(J); end;
        RVals[J + 1] := Tmp;
        Tmp := GVals[I]; J := I - 1;
        while (J >= 0) and (GVals[J] > Tmp) do begin GVals[J + 1] := GVals[J]; Dec(J); end;
        GVals[J + 1] := Tmp;
        Tmp := BVals[I]; J := I - 1;
        while (J >= 0) and (BVals[J] > Tmp) do begin BVals[J + 1] := BVals[J]; Dec(J); end;
        BVals[J + 1] := Tmp;
      end;
      Mid := Count div 2;
      FPixels[Y * FWidth + X].R := RVals[Mid];
      FPixels[Y * FWidth + X].G := GVals[Mid];
      FPixels[Y * FWidth + X].B := BVals[Mid];
    end;
end;

procedure TRasterSurface.OutlineEffect(const AOutlineColor: TRGBA32; Threshold: Byte);
{ Finds edges using Sobel-style approach: pixels adjacent to a pixel with alpha
  difference >= Threshold get painted with AOutlineColor on a transparent canvas. }
var
  Src: array of TRGBA32;
  X, Y: Integer;
  MaxDiff: Integer;
  DX, DY: Integer;
  Neighbor: TRGBA32;
  Center: TRGBA32;
  Diff: Integer;
begin
  SetLength(Src, FWidth * FHeight);
  Move(FPixels[0], Src[0], FWidth * FHeight * SizeOf(TRGBA32));
  Clear(TransparentColor);
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Center := Src[Y * FWidth + X];
      MaxDiff := 0;
      for DY := -1 to 1 do
        for DX := -1 to 1 do
        begin
          if (DX = 0) and (DY = 0) then Continue;
          if (X + DX < 0) or (X + DX >= FWidth) then Continue;
          if (Y + DY < 0) or (Y + DY >= FHeight) then Continue;
          Neighbor := Src[(Y + DY) * FWidth + (X + DX)];
          Diff := Abs(Integer(Center.A) - Integer(Neighbor.A)) +
                  Abs(Integer(Center.R) - Integer(Neighbor.R)) div 3 +
                  Abs(Integer(Center.G) - Integer(Neighbor.G)) div 3 +
                  Abs(Integer(Center.B) - Integer(Neighbor.B)) div 3;
          if Diff > MaxDiff then MaxDiff := Diff;
        end;
      if MaxDiff >= Threshold then
        FPixels[Y * FWidth + X] := AOutlineColor;
    end;
end;

procedure TRasterSurface.GlowEffect(Radius: Integer; Intensity: Integer);
{ Adds a soft diffuse glow by blending a blurred copy onto the original using
  additive-style clamped blending. }
var
  Blurred: TRasterSurface;
  SrcCopy: array of TRGBA32;
  X, Y: Integer;
  Orig, Blur: TRGBA32;
  GlowR, GlowG, GlowB: Integer;
  IntensityFrac: Integer;
begin
  if Radius <= 0 then Exit;
  IntensityFrac := EnsureRange(Intensity, 0, 200);
  { snapshot original pixels before blurring }
  SetLength(SrcCopy, FWidth * FHeight);
  Move(FPixels[0], SrcCopy[0], FWidth * FHeight * SizeOf(TRGBA32));
  Blurred := TRasterSurface.Create(FWidth, FHeight);
  try
    Move(SrcCopy[0], Blurred.FPixels[0], FWidth * FHeight * SizeOf(TRGBA32));
    Blurred.BoxBlur(Radius);
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
      begin
        Orig := SrcCopy[Y * FWidth + X];
        Blur := Blurred.FPixels[Y * FWidth + X];
        GlowR := EnsureRange(Integer(Orig.R) + Integer(Blur.R) * IntensityFrac div 100, 0, 255);
        GlowG := EnsureRange(Integer(Orig.G) + Integer(Blur.G) * IntensityFrac div 100, 0, 255);
        GlowB := EnsureRange(Integer(Orig.B) + Integer(Blur.B) * IntensityFrac div 100, 0, 255);
        FPixels[Y * FWidth + X] := RGBA(GlowR, GlowG, GlowB, Orig.A);
      end;
  finally
    Blurred.Free;
  end;
end;

procedure TRasterSurface.OilPaint(Radius: Integer);
{ Stylize effect: for each output pixel, find the most-commonly-occurring
  luminosity bucket among neighbours and output the average color of that bucket. }
const
  BucketCount = 8;
var
  SnapW, SnapH: Integer;
  Snap: array of TRGBA32;
  X, Y, DX, DY: Integer;
  BX, BY: Integer;
  Bucket: array[0..BucketCount - 1] of record
    SumR, SumG, SumB: Integer;
    Count: Integer;
  end;
  Pix: TRGBA32;
  Luma, BucketIdx, BestBucket, B: Integer;
begin
  if Radius < 1 then Radius := 1;
  SnapW := FWidth;
  SnapH := FHeight;
  SetLength(Snap, SnapW * SnapH);
  Move(FPixels[0], Snap[0], SnapW * SnapH * SizeOf(TRGBA32));
  for Y := 0 to SnapH - 1 do
    for X := 0 to SnapW - 1 do
    begin
      FillChar(Bucket, SizeOf(Bucket), 0);
      for DY := -Radius to Radius do
      begin
        BY := Y + DY;
        if (BY < 0) or (BY >= SnapH) then Continue;
        for DX := -Radius to Radius do
        begin
          BX := X + DX;
          if (BX < 0) or (BX >= SnapW) then Continue;
          Pix := Snap[BY * SnapW + BX];
          Luma := (Pix.R * 77 + Pix.G * 150 + Pix.B * 29) div 256;
          BucketIdx := (Luma * BucketCount) div 256;
          if BucketIdx >= BucketCount then BucketIdx := BucketCount - 1;
          Inc(Bucket[BucketIdx].SumR, Pix.R);
          Inc(Bucket[BucketIdx].SumG, Pix.G);
          Inc(Bucket[BucketIdx].SumB, Pix.B);
          Inc(Bucket[BucketIdx].Count);
        end;
      end;
      BestBucket := 0;
      for B := 1 to BucketCount - 1 do
        if Bucket[B].Count > Bucket[BestBucket].Count then
          BestBucket := B;
      if Bucket[BestBucket].Count > 0 then
      begin
        Pix := Snap[Y * SnapW + X];
        Pix.R := Bucket[BestBucket].SumR div Bucket[BestBucket].Count;
        Pix.G := Bucket[BestBucket].SumG div Bucket[BestBucket].Count;
        Pix.B := Bucket[BestBucket].SumB div Bucket[BestBucket].Count;
        FPixels[Y * SnapW + X] := Pix;
      end;
    end;
end;

procedure TRasterSurface.FrostedGlass(Amount: Integer);
{ Distort: displace each sample by a random offset within [-Amount..Amount]
  on both axes using a per-pixel deterministic noise state. }
var
  Snap: array of TRGBA32;
  X, Y: Integer;
  OffX, OffY: Integer;
  SX, SY: Integer;
  NoiseState: Cardinal;
begin
  if Amount < 1 then Amount := 1;
  SetLength(Snap, FWidth * FHeight);
  Move(FPixels[0], Snap[0], FWidth * FHeight * SizeOf(TRGBA32));
  NoiseState := Cardinal(1317);
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      { deterministic per-pixel noise from NextNoiseValue }
      OffX := (NextNoiseValue(NoiseState) mod (Amount * 2 + 1)) - Amount;
      OffY := (NextNoiseValue(NoiseState) mod (Amount * 2 + 1)) - Amount;
      SX := EnsureRange(X + OffX, 0, FWidth - 1);
      SY := EnsureRange(Y + OffY, 0, FHeight - 1);
      FPixels[Y * FWidth + X] := Snap[SY * FWidth + SX];
    end;
end;

procedure TRasterSurface.ZoomBlur(CenterX: Integer; CenterY: Integer; Amount: Integer);
{ Radial zoom blur: for each pixel, average Samples samples taken along
  the direction from the center outward at increasing zoom fractions. }
const
  Samples = 8;
var
  Snap: array of TRGBA32;
  X, Y, S: Integer;
  DX, DY: Double;
  Dist, Scale: Double;
  SX, SY: Integer;
  SumR, SumG, SumB, SumA, Count: Integer;
  Pix: TRGBA32;
begin
  if Amount <= 0 then Exit;
  SetLength(Snap, FWidth * FHeight);
  Move(FPixels[0], Snap[0], FWidth * FHeight * SizeOf(TRGBA32));
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      DX := X - CenterX;
      DY := Y - CenterY;
      Dist := Sqrt(DX * DX + DY * DY);
      SumR := 0; SumG := 0; SumB := 0; SumA := 0; Count := 0;
      for S := 0 to Samples - 1 do
      begin
        if Dist < 0.5 then Scale := 1.0
        else Scale := 1.0 + (Amount * S / (Samples * Max(1, Round(Dist))));
        SX := EnsureRange(CenterX + Round(DX * Scale), 0, FWidth - 1);
        SY := EnsureRange(CenterY + Round(DY * Scale), 0, FHeight - 1);
        Pix := Snap[SY * FWidth + SX];
        Inc(SumR, Pix.R);
        Inc(SumG, Pix.G);
        Inc(SumB, Pix.B);
        Inc(SumA, Pix.A);
        Inc(Count);
      end;
      Pix := Snap[Y * FWidth + X];
      if Count > 0 then
        FPixels[Y * FWidth + X] := RGBA(SumR div Count, SumG div Count, SumB div Count, SumA div Count)
      else
        FPixels[Y * FWidth + X] := Pix;
    end;
end;

procedure TRasterSurface.GaussianBlur(Radius: Integer);
{ Approximate Gaussian blur via three passes of box blur. Three passes of a
  box blur with the same radius give a very good Gaussian approximation:
  sigma ≈ radius * sqrt(1/3).  Works in O(3 * W * H) regardless of radius. }
begin
  if Radius < 1 then Radius := 1;
  BoxBlur(Radius);
  BoxBlur(Radius);
  BoxBlur(Radius);
end;

procedure TRasterSurface.RadialBlur(Amount: Integer);
{ Spin blur: samples pixels at slight angular offsets around the image centre
  and averages them, producing a rotational motion-blur impression.
  Amount is the total sweep angle in degrees (typical range 1-60). }
const
  Samples = 9;
var
  Snap: array of TRGBA32;
  X, Y, S: Integer;
  DX, DY, Dist, BaseAngle, RotAngle, ThetaStep: Double;
  SX, SY: Integer;
  SumR, SumG, SumB, SumA: Integer;
  Pix: TRGBA32;
  CX, CY: Integer;
begin
  if Amount <= 0 then Exit;
  CX := FWidth div 2;
  CY := FHeight div 2;
  ThetaStep := Amount * Pi / (180.0 * Max(1, Samples - 1));
  SetLength(Snap, FWidth * FHeight);
  Move(FPixels[0], Snap[0], FWidth * FHeight * SizeOf(TRGBA32));
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      DX := X - CX;
      DY := Y - CY;
      Dist := Sqrt(DX * DX + DY * DY);
      if Dist < 0.5 then Continue;
      BaseAngle := ArcTan2(DY, DX);
      SumR := 0; SumG := 0; SumB := 0; SumA := 0;
      for S := 0 to Samples - 1 do
      begin
        RotAngle := BaseAngle + (S - Samples div 2) * ThetaStep;
        SX := EnsureRange(CX + Round(Dist * Cos(RotAngle)), 0, FWidth - 1);
        SY := EnsureRange(CY + Round(Dist * Sin(RotAngle)), 0, FHeight - 1);
        Pix := Snap[SY * FWidth + SX];
        Inc(SumR, Pix.R); Inc(SumG, Pix.G);
        Inc(SumB, Pix.B); Inc(SumA, Pix.A);
      end;
      FPixels[Y * FWidth + X] := RGBA(SumR div Samples, SumG div Samples,
                                       SumB div Samples, SumA div Samples);
    end;
end;

procedure TRasterSurface.Twist(Amount: Integer);
{ Twirl / twist distortion: each pixel is rotated around the image centre by
  an angle that falls off from Amount degrees at the centre to 0 at the edge.
  Negative Amount twists counter-clockwise. }
var
  Snap: array of TRGBA32;
  X, Y: Integer;
  DX, DY, Dist, MaxDist, TwistAngle, NewAngle, Factor: Double;
  SX, SY: Integer;
  CX, CY: Integer;
begin
  if Amount = 0 then Exit;
  CX := FWidth div 2;
  CY := FHeight div 2;
  MaxDist := Sqrt(CX * CX + CY * CY);
  if MaxDist < 1 then Exit;
  Factor := Amount * Pi / 180.0;
  SetLength(Snap, FWidth * FHeight);
  Move(FPixels[0], Snap[0], FWidth * FHeight * SizeOf(TRGBA32));
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      DX := X - CX;
      DY := Y - CY;
      Dist := Sqrt(DX * DX + DY * DY);
      TwistAngle := Factor * (1.0 - Min(1.0, Dist / MaxDist));
      NewAngle := ArcTan2(DY, DX) + TwistAngle;
      SX := EnsureRange(CX + Round(Dist * Cos(NewAngle)), 0, FWidth - 1);
      SY := EnsureRange(CY + Round(Dist * Sin(NewAngle)), 0, FHeight - 1);
      FPixels[Y * FWidth + X] := Snap[SY * FWidth + SX];
    end;
end;

procedure TRasterSurface.Fragment(Offset: Integer);
{ Fragment: averages four shifted copies of the image (offset to NW, NE, SW, SE)
  producing a fractured / shattered glass feel similar to Paint.NET's Fragment. }
var
  Snap: array of TRGBA32;
  X, Y: Integer;
  HO: Integer;
  X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer;
  R, G, B, A: Integer;
  P: TRGBA32;
begin
  HO := Max(1, Offset);
  SetLength(Snap, FWidth * FHeight);
  Move(FPixels[0], Snap[0], FWidth * FHeight * SizeOf(TRGBA32));
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      X1 := EnsureRange(X - HO, 0, FWidth - 1);  Y1 := EnsureRange(Y - HO, 0, FHeight - 1);
      X2 := EnsureRange(X + HO, 0, FWidth - 1);  Y2 := Y1;
      X3 := X1;                                   Y3 := EnsureRange(Y + HO, 0, FHeight - 1);
      X4 := X2;                                   Y4 := Y3;
      P := Snap[Y1 * FWidth + X1]; R := P.R; G := P.G; B := P.B; A := P.A;
      P := Snap[Y2 * FWidth + X2]; Inc(R, P.R); Inc(G, P.G); Inc(B, P.B); Inc(A, P.A);
      P := Snap[Y3 * FWidth + X3]; Inc(R, P.R); Inc(G, P.G); Inc(B, P.B); Inc(A, P.A);
      P := Snap[Y4 * FWidth + X4]; Inc(R, P.R); Inc(G, P.G); Inc(B, P.B); Inc(A, P.A);
      FPixels[Y * FWidth + X] := RGBA(R shr 2, G shr 2, B shr 2, A shr 2);
    end;
end;

procedure TRasterSurface.RecolorBrush(X, Y, Radius: Integer; SourceColor, NewColor: TRGBA32; Tolerance: Byte; Opacity: Byte);
var
  BX, BY: Integer;
  Dist: Integer;
  Pix: TRGBA32;
  DR, DG, DB: Integer;
  ColorDist: Integer;
begin
  for BY := Max(0, Y - Radius) to Min(FHeight - 1, Y + Radius) do
    for BX := Max(0, X - Radius) to Min(FWidth - 1, X + Radius) do
    begin
      Dist := Round(Sqrt((BX - X) * (BX - X) + (BY - Y) * (BY - Y)));
      if Dist > Radius then
        Continue;
      Pix := FPixels[IndexOf(BX, BY)];
      DR := Pix.R - SourceColor.R;
      DG := Pix.G - SourceColor.G;
      DB := Pix.B - SourceColor.B;
      ColorDist := (Abs(DR) + Abs(DG) + Abs(DB)) div 3;
      if ColorDist <= Tolerance then
      begin
        if Opacity >= 255 then
        begin
          Pix.R := NewColor.R;
          Pix.G := NewColor.G;
          Pix.B := NewColor.B;
        end
        else
        begin
          Pix.R := (Pix.R * (255 - Opacity) + NewColor.R * Opacity + 127) div 255;
          Pix.G := (Pix.G * (255 - Opacity) + NewColor.G * Opacity + 127) div 255;
          Pix.B := (Pix.B * (255 - Opacity) + NewColor.B * Opacity + 127) div 255;
        end;
        FPixels[IndexOf(BX, BY)] := Pix;
      end;
    end;
end;

procedure TRasterSurface.FillSelection(ASelection: TSelectionMask; const AColor: TRGBA32; Opacity: Byte);
var
  X: Integer;
  Y: Integer;
begin
  if ASelection = nil then
    Exit;
  for Y := 0 to Min(FHeight, ASelection.Height) - 1 do
    for X := 0 to Min(FWidth, ASelection.Width) - 1 do
      if ASelection[X, Y] then
        BlendPixel(X, Y, AColor, Opacity);
end;

procedure TRasterSurface.EraseSelection(ASelection: TSelectionMask);
var
  X: Integer;
  Y: Integer;
begin
  if ASelection = nil then
    Exit;
  for Y := 0 to Min(FHeight, ASelection.Height) - 1 do
    for X := 0 to Min(FWidth, ASelection.Width) - 1 do
      if ASelection[X, Y] then
        Pixels[X, Y] := TransparentColor;
end;

function TRasterSurface.CopySelection(ASelection: TSelectionMask): TRasterSurface;
var
  X: Integer;
  Y: Integer;
begin
  Result := TRasterSurface.Create(FWidth, FHeight);
  Result.Clear(TransparentColor);
  if ASelection = nil then
    Exit;
  for Y := 0 to Min(FHeight, ASelection.Height) - 1 do
    for X := 0 to Min(FWidth, ASelection.Width) - 1 do
      if ASelection[X, Y] then
        Result[X, Y] := Pixels[X, Y];
end;

function TRasterSurface.CreateContiguousSelection(X, Y: Integer; Tolerance: Byte): TSelectionMask;
var
  TargetColor: TRGBA32;
  Queue: array of Integer;
  Visited: array of Byte;
  Head: Integer;
  Tail: Integer;
  CurrentIndex: Integer;
  CurrentX: Integer;
  CurrentY: Integer;

  procedure EnqueueIfMatch(AX, AY: Integer);
  var
    PixelIndex: Integer;
  begin
    if not InBounds(AX, AY) then
      Exit;
    PixelIndex := IndexOf(AX, AY);
    if Visited[PixelIndex] <> 0 then
      Exit;
    Visited[PixelIndex] := 1;
    if not ColorsCloseEnough(FPixels[PixelIndex], TargetColor, Tolerance) then
      Exit;
    Result[AX, AY] := True;
    Queue[Tail] := PixelIndex;
    Inc(Tail);
  end;

begin
  Result := TSelectionMask.Create(FWidth, FHeight);
  if not InBounds(X, Y) then
    Exit;

  TargetColor := Pixels[X, Y];
  Queue := nil;
  Visited := nil;
  SetLength(Queue, FWidth * FHeight);
  SetLength(Visited, FWidth * FHeight);
  Head := 0;
  Tail := 0;
  EnqueueIfMatch(X, Y);

  while Head < Tail do
  begin
    CurrentIndex := Queue[Head];
    Inc(Head);
    CurrentY := CurrentIndex div FWidth;
    CurrentX := CurrentIndex - (CurrentY * FWidth);
    EnqueueIfMatch(CurrentX - 1, CurrentY);
    EnqueueIfMatch(CurrentX + 1, CurrentY);
    EnqueueIfMatch(CurrentX, CurrentY - 1);
    EnqueueIfMatch(CurrentX, CurrentY + 1);
  end;
end;

function TRasterSurface.CreateGlobalColorSelection(X, Y: Integer; Tolerance: Byte): TSelectionMask;
{ Non-contiguous magic wand: selects every pixel in the surface whose color
  is within Tolerance of the sampled pixel, regardless of adjacency. }
var
  TargetColor: TRGBA32;
  IX, IY: Integer;
begin
  Result := TSelectionMask.Create(FWidth, FHeight);
  if not InBounds(X, Y) then
    Exit;
  TargetColor := Pixels[X, Y];
  for IY := 0 to FHeight - 1 do
    for IX := 0 to FWidth - 1 do
      if ColorsCloseEnough(FPixels[IndexOf(IX, IY)], TargetColor, Tolerance) then
        Result[IX, IY] := True;
end;

procedure TRasterSurface.MoveSelectedPixels(ASelection: TSelectionMask; DeltaX, DeltaY: Integer);
var
  Copied: TRasterSurface;
  X: Integer;
  Y: Integer;
  TargetX: Integer;
  TargetY: Integer;
begin
  if ASelection = nil then
    Exit;

  Copied := CopySelection(ASelection);
  try
    EraseSelection(ASelection);
    for Y := 0 to Min(FHeight, ASelection.Height) - 1 do
      for X := 0 to Min(FWidth, ASelection.Width) - 1 do
        if ASelection[X, Y] then
        begin
          TargetX := X + DeltaX;
          TargetY := Y + DeltaY;
          if InBounds(TargetX, TargetY) then
            Pixels[TargetX, TargetY] := Copied[X, Y];
        end;
  finally
    Copied.Free;
  end;
end;

function TRasterSurface.Crop(X, Y, AWidth, AHeight: Integer): TRasterSurface;
var
  SourceX: Integer;
  SourceY: Integer;
  TargetX: Integer;
  TargetY: Integer;
begin
  AWidth := Max(1, AWidth);
  AHeight := Max(1, AHeight);
  Result := TRasterSurface.Create(AWidth, AHeight);
  Result.Clear(TransparentColor);
  for TargetY := 0 to AHeight - 1 do
  begin
    SourceY := Y + TargetY;
    if (SourceY < 0) or (SourceY >= FHeight) then
      Continue;
    for TargetX := 0 to AWidth - 1 do
    begin
      SourceX := X + TargetX;
      if (SourceX < 0) or (SourceX >= FWidth) then
        Continue;
      Result[TargetX, TargetY] := Pixels[SourceX, SourceY];
    end;
  end;
end;

function TRasterSurface.ResizeNearest(ANewWidth, ANewHeight: Integer): TRasterSurface;
var
  TargetX: Integer;
  TargetY: Integer;
  SourceX: Integer;
  SourceY: Integer;
begin
  ANewWidth := Max(1, ANewWidth);
  ANewHeight := Max(1, ANewHeight);
  Result := TRasterSurface.Create(ANewWidth, ANewHeight);
  for TargetY := 0 to ANewHeight - 1 do
  begin
    SourceY := Min(FHeight - 1, (TargetY * FHeight) div ANewHeight);
    for TargetX := 0 to ANewWidth - 1 do
    begin
      SourceX := Min(FWidth - 1, (TargetX * FWidth) div ANewWidth);
      Result[TargetX, TargetY] := Pixels[SourceX, SourceY];
    end;
  end;
end;

function TRasterSurface.ResizeBilinear(ANewWidth, ANewHeight: Integer): TRasterSurface;
var
  TargetX: Integer;
  TargetY: Integer;
  SourceX: Double;
  SourceY: Double;
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  FX: Double;
  FY: Double;
  TopLeft: TRGBA32;
  TopRight: TRGBA32;
  BottomLeft: TRGBA32;
  BottomRight: TRGBA32;
  function InterpolateChannel(ATopLeft, ATopRight, ABottomLeft, ABottomRight: Byte): Byte;
  var
    TopValue: Double;
    BottomValue: Double;
  begin
    TopValue := ATopLeft + ((ATopRight - ATopLeft) * FX);
    BottomValue := ABottomLeft + ((ABottomRight - ABottomLeft) * FX);
    Result := ClampChannel(Round(TopValue + ((BottomValue - TopValue) * FY)));
  end;
begin
  ANewWidth := Max(1, ANewWidth);
  ANewHeight := Max(1, ANewHeight);
  Result := TRasterSurface.Create(ANewWidth, ANewHeight);
  for TargetY := 0 to ANewHeight - 1 do
  begin
    SourceY := ((TargetY + 0.5) * FHeight / ANewHeight) - 0.5;
    if SourceY < 0.0 then
      SourceY := 0.0
    else if SourceY > FHeight - 1 then
      SourceY := FHeight - 1;
    TopY := Trunc(SourceY);
    BottomY := Min(FHeight - 1, TopY + 1);
    FY := SourceY - TopY;

    for TargetX := 0 to ANewWidth - 1 do
    begin
      SourceX := ((TargetX + 0.5) * FWidth / ANewWidth) - 0.5;
      if SourceX < 0.0 then
        SourceX := 0.0
      else if SourceX > FWidth - 1 then
        SourceX := FWidth - 1;
      LeftX := Trunc(SourceX);
      RightX := Min(FWidth - 1, LeftX + 1);
      FX := SourceX - LeftX;

      TopLeft := Pixels[LeftX, TopY];
      TopRight := Pixels[RightX, TopY];
      BottomLeft := Pixels[LeftX, BottomY];
      BottomRight := Pixels[RightX, BottomY];

      Result[TargetX, TargetY] := RGBA(
        InterpolateChannel(TopLeft.R, TopRight.R, BottomLeft.R, BottomRight.R),
        InterpolateChannel(TopLeft.G, TopRight.G, BottomLeft.G, BottomRight.G),
        InterpolateChannel(TopLeft.B, TopRight.B, BottomLeft.B, BottomRight.B),
        InterpolateChannel(TopLeft.A, TopRight.A, BottomLeft.A, BottomRight.A)
      );
    end;
  end;
end;

end.
