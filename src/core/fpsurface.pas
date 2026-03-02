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
    procedure DrawBrush(X, Y, Radius: Integer; const AColor: TRGBA32; Opacity: Byte = 255);
    procedure DrawLine(X1, Y1, X2, Y2, Radius: Integer; const AColor: TRGBA32; Opacity: Byte = 255);
    procedure DrawRectangle(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte = 255);
    procedure DrawRoundedRectangle(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte = 255);
    procedure DrawEllipse(X1, Y1, X2, Y2, StrokeWidth: Integer; const AColor: TRGBA32; Filled: Boolean; Opacity: Byte = 255);
    procedure DrawPolygon(const APoints: array of TPoint; StrokeWidth: Integer; const AColor: TRGBA32; Closed: Boolean = True; Opacity: Byte = 255);
    procedure FloodFill(X, Y: Integer; const AColor: TRGBA32; Tolerance: Byte = 0);
    procedure FillGradient(X1, Y1, X2, Y2: Integer; const StartColor, EndColor: TRGBA32);
    procedure PasteSurface(ASource: TRasterSurface; OffsetX, OffsetY: Integer; Opacity: Byte = 255);
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
    procedure FillSelection(ASelection: TSelectionMask; const AColor: TRGBA32; Opacity: Byte = 255);
    procedure EraseSelection(ASelection: TSelectionMask);
    function CopySelection(ASelection: TSelectionMask): TRasterSurface;
    function CreateContiguousSelection(X, Y: Integer; Tolerance: Byte = 0): TSelectionMask;
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

procedure TRasterSurface.DrawBrush(X, Y, Radius: Integer; const AColor: TRGBA32; Opacity: Byte);
var
  DrawX: Integer;
  DrawY: Integer;
  RadiusSquared: Integer;
  DeltaX: Integer;
  DeltaY: Integer;
begin
  Radius := Max(0, Radius);
  RadiusSquared := Radius * Radius;
  for DrawY := Y - Radius to Y + Radius do
  begin
    for DrawX := X - Radius to X + Radius do
    begin
      DeltaX := DrawX - X;
      DeltaY := DrawY - Y;
      if (DeltaX * DeltaX) + (DeltaY * DeltaY) <= RadiusSquared then
        BlendPixel(DrawX, DrawY, AColor, Opacity);
    end;
  end;
end;

procedure TRasterSurface.DrawLine(X1, Y1, X2, Y2, Radius: Integer; const AColor: TRGBA32; Opacity: Byte);
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
    DrawBrush(X1, Y1, Radius, AColor, Opacity);
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
