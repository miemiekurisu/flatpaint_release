unit FPSelection;

{$mode objfpc}{$H+}

interface

uses
  Types;

type
  TSelectionCombineMode = (
    scReplace,
    scAdd,
    scSubtract
  );

  TSelectionMask = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FData: array of Byte;
    function GetSelected(X, Y: Integer): Boolean;
    procedure SetSelected(X, Y: Integer; AValue: Boolean);
    function IndexOf(X, Y: Integer): Integer; inline;
  public
    constructor Create(AWidth, AHeight: Integer);
    procedure SetSize(AWidth, AHeight: Integer);
    procedure Clear;
    procedure SelectAll;
    procedure Invert;
    procedure Assign(ASource: TSelectionMask);
    function Clone: TSelectionMask;
    function InBounds(X, Y: Integer): Boolean; inline;
    function HasSelection: Boolean;
    procedure SelectRectangle(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode = scReplace);
    procedure SelectEllipse(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode = scReplace);
    procedure SelectPolygon(const APoints: array of TPoint; AMode: TSelectionCombineMode = scReplace);
    procedure MoveBy(DeltaX, DeltaY: Integer);
    procedure FlipHorizontal;
    procedure FlipVertical;
    procedure Rotate90Clockwise;
    procedure Rotate90CounterClockwise;
    function Crop(X, Y, AWidth, AHeight: Integer): TSelectionMask;
    function ResizeNearest(ANewWidth, ANewHeight: Integer): TSelectionMask;
    function BoundsRect: TRect;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Selected[X, Y: Integer]: Boolean read GetSelected write SetSelected; default;
  end;

implementation

uses
  Math, SysUtils;

function PointInsidePolygon(const APoints: array of TPoint; AX, AY: Double): Boolean;
var
  Index: Integer;
  PreviousIndex: Integer;
  CurrentX: Double;
  CurrentY: Double;
  PreviousX: Double;
  PreviousY: Double;
begin
  Result := False;
  if Length(APoints) < 3 then
    Exit;

  PreviousIndex := High(APoints);
  for Index := 0 to High(APoints) do
  begin
    CurrentX := APoints[Index].X + 0.5;
    CurrentY := APoints[Index].Y + 0.5;
    PreviousX := APoints[PreviousIndex].X + 0.5;
    PreviousY := APoints[PreviousIndex].Y + 0.5;
    if ((CurrentY > AY) <> (PreviousY > AY)) and
       (AX < (((PreviousX - CurrentX) * (AY - CurrentY)) / (PreviousY - CurrentY)) + CurrentX) then
      Result := not Result;
    PreviousIndex := Index;
  end;
end;

constructor TSelectionMask.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  SetSize(AWidth, AHeight);
end;

function TSelectionMask.IndexOf(X, Y: Integer): Integer;
begin
  Result := (Y * FWidth) + X;
end;

procedure TSelectionMask.SetSize(AWidth, AHeight: Integer);
begin
  FWidth := Max(1, AWidth);
  FHeight := Max(1, AHeight);
  SetLength(FData, FWidth * FHeight);
  Clear;
end;

procedure TSelectionMask.Clear;
begin
  if Length(FData) > 0 then
    FillChar(FData[0], Length(FData), 0);
end;

procedure TSelectionMask.SelectAll;
begin
  if Length(FData) > 0 then
    FillChar(FData[0], Length(FData), 1);
end;

procedure TSelectionMask.Invert;
var
  Index: Integer;
begin
  for Index := 0 to High(FData) do
    if FData[Index] = 0 then
      FData[Index] := 1
    else
      FData[Index] := 0;
end;

procedure TSelectionMask.Assign(ASource: TSelectionMask);
begin
  if ASource = nil then
    Exit;
  FWidth := ASource.Width;
  FHeight := ASource.Height;
  SetLength(FData, Length(ASource.FData));
  if Length(FData) > 0 then
    Move(ASource.FData[0], FData[0], Length(FData));
end;

function TSelectionMask.Clone: TSelectionMask;
begin
  Result := TSelectionMask.Create(FWidth, FHeight);
  Result.Assign(Self);
end;

function TSelectionMask.InBounds(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (Y >= 0) and (X < FWidth) and (Y < FHeight);
end;

function TSelectionMask.GetSelected(X, Y: Integer): Boolean;
begin
  if not InBounds(X, Y) then
    Exit(False);
  Result := FData[IndexOf(X, Y)] <> 0;
end;

procedure TSelectionMask.SetSelected(X, Y: Integer; AValue: Boolean);
begin
  if not InBounds(X, Y) then
    Exit;
  if AValue then
    FData[IndexOf(X, Y)] := 1
  else
    FData[IndexOf(X, Y)] := 0;
end;

function TSelectionMask.HasSelection: Boolean;
var
  Index: Integer;
begin
  for Index := 0 to High(FData) do
    if FData[Index] <> 0 then
      Exit(True);
  Result := False;
end;

procedure TSelectionMask.SelectRectangle(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode);
var
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  X: Integer;
  Y: Integer;
begin
  LeftX := Max(0, Min(X1, X2));
  RightX := Min(FWidth - 1, Max(X1, X2));
  TopY := Max(0, Min(Y1, Y2));
  BottomY := Min(FHeight - 1, Max(Y1, Y2));

  if AMode = scReplace then
    Clear;

  for Y := TopY to BottomY do
    for X := LeftX to RightX do
      case AMode of
        scReplace, scAdd: Selected[X, Y] := True;
        scSubtract: Selected[X, Y] := False;
      end;
end;

procedure TSelectionMask.SelectEllipse(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode);
var
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  CenterX: Double;
  CenterY: Double;
  RadiusX: Double;
  RadiusY: Double;
  NX: Double;
  NY: Double;
  X: Integer;
  Y: Integer;
begin
  LeftX := Max(0, Min(X1, X2));
  RightX := Min(FWidth - 1, Max(X1, X2));
  TopY := Max(0, Min(Y1, Y2));
  BottomY := Min(FHeight - 1, Max(Y1, Y2));

  if AMode = scReplace then
    Clear;

  CenterX := (LeftX + RightX) / 2.0;
  CenterY := (TopY + BottomY) / 2.0;
  RadiusX := Max(0.5, (RightX - LeftX + 1) / 2.0);
  RadiusY := Max(0.5, (BottomY - TopY + 1) / 2.0);

  for Y := TopY to BottomY do
    for X := LeftX to RightX do
    begin
      NX := (X - CenterX) / RadiusX;
      NY := (Y - CenterY) / RadiusY;
      if (NX * NX) + (NY * NY) <= 1.0 then
        case AMode of
          scReplace, scAdd: Selected[X, Y] := True;
          scSubtract: Selected[X, Y] := False;
        end;
    end;
end;

procedure TSelectionMask.SelectPolygon(const APoints: array of TPoint; AMode: TSelectionCombineMode);
var
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  PointIndex: Integer;
  X: Integer;
  Y: Integer;

  procedure ApplySelectionAt(AX, AY: Integer);
  begin
    if not InBounds(AX, AY) then
      Exit;
    case AMode of
      scReplace, scAdd: Selected[AX, AY] := True;
      scSubtract: Selected[AX, AY] := False;
    end;
  end;

  procedure RasterizeEdge(const AFromPoint, AToPoint: TPoint);
  var
    CurrentX: Integer;
    CurrentY: Integer;
    DeltaX: Integer;
    DeltaY: Integer;
    StepX: Integer;
    StepY: Integer;
    ErrorValue: Integer;
    DoubleError: Integer;
  begin
    CurrentX := AFromPoint.X;
    CurrentY := AFromPoint.Y;
    DeltaX := Abs(AToPoint.X - AFromPoint.X);
    DeltaY := Abs(AToPoint.Y - AFromPoint.Y);
    if AFromPoint.X < AToPoint.X then
      StepX := 1
    else
      StepX := -1;
    if AFromPoint.Y < AToPoint.Y then
      StepY := 1
    else
      StepY := -1;

    ErrorValue := DeltaX - DeltaY;
    while True do
    begin
      ApplySelectionAt(CurrentX, CurrentY);
      if (CurrentX = AToPoint.X) and (CurrentY = AToPoint.Y) then
        Break;
      DoubleError := ErrorValue * 2;
      if DoubleError > -DeltaY then
      begin
        ErrorValue := ErrorValue - DeltaY;
        CurrentX := CurrentX + StepX;
      end;
      if DoubleError < DeltaX then
      begin
        ErrorValue := ErrorValue + DeltaX;
        CurrentY := CurrentY + StepY;
      end;
    end;
  end;

begin
  if AMode = scReplace then
    Clear;

  if Length(APoints) = 0 then
    Exit;

  LeftX := APoints[0].X;
  RightX := APoints[0].X;
  TopY := APoints[0].Y;
  BottomY := APoints[0].Y;
  for PointIndex := 1 to High(APoints) do
  begin
    LeftX := Min(LeftX, APoints[PointIndex].X);
    RightX := Max(RightX, APoints[PointIndex].X);
    TopY := Min(TopY, APoints[PointIndex].Y);
    BottomY := Max(BottomY, APoints[PointIndex].Y);
  end;

  LeftX := Max(0, LeftX);
  RightX := Min(FWidth - 1, RightX);
  TopY := Max(0, TopY);
  BottomY := Min(FHeight - 1, BottomY);
  if (LeftX > RightX) or (TopY > BottomY) then
    Exit;

  if Length(APoints) >= 3 then
    for Y := TopY to BottomY do
      for X := LeftX to RightX do
        if PointInsidePolygon(APoints, X + 0.5, Y + 0.5) then
          ApplySelectionAt(X, Y);

  for PointIndex := 0 to High(APoints) do
    RasterizeEdge(APoints[PointIndex], APoints[(PointIndex + 1) mod Length(APoints)]);
end;

procedure TSelectionMask.MoveBy(DeltaX, DeltaY: Integer);
var
  NewData: array of Byte;
  X: Integer;
  Y: Integer;
  SourceX: Integer;
  SourceY: Integer;
begin
  NewData := nil;
  SetLength(NewData, Length(FData));
  if Length(NewData) > 0 then
    FillChar(NewData[0], Length(NewData), 0);

  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      SourceX := X - DeltaX;
      SourceY := Y - DeltaY;
      if InBounds(SourceX, SourceY) and Selected[SourceX, SourceY] then
        NewData[IndexOf(X, Y)] := 1;
    end;

  if Length(FData) > 0 then
    Move(NewData[0], FData[0], Length(FData));
end;

procedure TSelectionMask.FlipHorizontal;
var
  X: Integer;
  Y: Integer;
  HalfWidth: Integer;
  Temp: Boolean;
begin
  HalfWidth := FWidth div 2;
  for Y := 0 to FHeight - 1 do
    for X := 0 to HalfWidth - 1 do
    begin
      Temp := Selected[X, Y];
      Selected[X, Y] := Selected[FWidth - 1 - X, Y];
      Selected[FWidth - 1 - X, Y] := Temp;
    end;
end;

procedure TSelectionMask.FlipVertical;
var
  X: Integer;
  Y: Integer;
  HalfHeight: Integer;
  Temp: Boolean;
begin
  HalfHeight := FHeight div 2;
  for Y := 0 to HalfHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      Temp := Selected[X, Y];
      Selected[X, Y] := Selected[X, FHeight - 1 - Y];
      Selected[X, FHeight - 1 - Y] := Temp;
    end;
end;

procedure TSelectionMask.Rotate90Clockwise;
var
  Rotated: TSelectionMask;
  X: Integer;
  Y: Integer;
begin
  Rotated := TSelectionMask.Create(FHeight, FWidth);
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
        Rotated[FHeight - 1 - Y, X] := Selected[X, Y];
    Assign(Rotated);
  finally
    Rotated.Free;
  end;
end;

procedure TSelectionMask.Rotate90CounterClockwise;
var
  Rotated: TSelectionMask;
  X: Integer;
  Y: Integer;
begin
  Rotated := TSelectionMask.Create(FHeight, FWidth);
  try
    for Y := 0 to FHeight - 1 do
      for X := 0 to FWidth - 1 do
        Rotated[Y, FWidth - 1 - X] := Selected[X, Y];
    Assign(Rotated);
  finally
    Rotated.Free;
  end;
end;

function TSelectionMask.Crop(X, Y, AWidth, AHeight: Integer): TSelectionMask;
var
  TargetX: Integer;
  TargetY: Integer;
  SourceX: Integer;
  SourceY: Integer;
begin
  AWidth := Max(1, AWidth);
  AHeight := Max(1, AHeight);
  Result := TSelectionMask.Create(AWidth, AHeight);
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
      Result[TargetX, TargetY] := Selected[SourceX, SourceY];
    end;
  end;
end;

function TSelectionMask.ResizeNearest(ANewWidth, ANewHeight: Integer): TSelectionMask;
var
  TargetX: Integer;
  TargetY: Integer;
  SourceX: Integer;
  SourceY: Integer;
begin
  ANewWidth := Max(1, ANewWidth);
  ANewHeight := Max(1, ANewHeight);
  Result := TSelectionMask.Create(ANewWidth, ANewHeight);
  for TargetY := 0 to ANewHeight - 1 do
  begin
    SourceY := Min(FHeight - 1, (TargetY * FHeight) div ANewHeight);
    for TargetX := 0 to ANewWidth - 1 do
    begin
      SourceX := Min(FWidth - 1, (TargetX * FWidth) div ANewWidth);
      Result[TargetX, TargetY] := Selected[SourceX, SourceY];
    end;
  end;
end;

function TSelectionMask.BoundsRect: TRect;
var
  MinX: Integer;
  MinY: Integer;
  MaxX: Integer;
  MaxY: Integer;
  X: Integer;
  Y: Integer;
begin
  if not HasSelection then
    Exit(Rect(0, 0, 0, 0));

  MinX := FWidth - 1;
  MinY := FHeight - 1;
  MaxX := 0;
  MaxY := 0;
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
      if Selected[X, Y] then
      begin
        if X < MinX then
          MinX := X;
        if Y < MinY then
          MinY := Y;
        if X > MaxX then
          MaxX := X;
        if Y > MaxY then
          MaxY := Y;
      end;

  Result := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
end;

end.
