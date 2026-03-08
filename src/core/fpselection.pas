unit FPSelection;

{$mode objfpc}{$H+}

interface

uses
  Types;

type
  TSelectionCombineMode = (
    scReplace,
    scAdd,
    scSubtract,
    scIntersect
  );

  TSelectionMask = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FData: array of Byte;
    FSelectedCount: Integer;
    FBoundsCache: TRect;
    FBoundsDirty: Boolean;
    function GetSelected(X, Y: Integer): Boolean;
    procedure SetSelected(X, Y: Integer; AValue: Boolean);
    function IndexOf(X, Y: Integer): Integer; inline;
    procedure RebuildSelectionCache;
  public
    constructor Create(AWidth, AHeight: Integer);
    procedure SetSize(AWidth, AHeight: Integer);
    procedure Clear;
    procedure SelectAll;
    procedure Invert;
    procedure Assign(ASource: TSelectionMask);
    function Clone: TSelectionMask;
    procedure IntersectWith(AMask: TSelectionMask);
    function InBounds(X, Y: Integer): Boolean; inline;
    function HasSelection: Boolean;
    procedure SelectRectangle(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode = scReplace);
    procedure SelectEllipse(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode = scReplace);
    procedure SelectPolygon(const APoints: array of TPoint; AMode: TSelectionCombineMode = scReplace);
    procedure MoveBy(DeltaX, DeltaY: Integer);
    procedure TranslateTo(ADest: TSelectionMask; DeltaX, DeltaY: Integer);
    procedure FlipHorizontal;
    procedure FlipVertical;
    procedure Rotate90Clockwise;
    procedure Rotate90CounterClockwise;
    function Crop(X, Y, AWidth, AHeight: Integer): TSelectionMask;
    function ResizeNearest(ANewWidth, ANewHeight: Integer): TSelectionMask;
    function BoundsRect: TRect;
    procedure Feather(ARadius: Integer);
    function Coverage(X, Y: Integer): Byte;
    procedure SetCoverage(X, Y: Integer; AValue: Byte);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Selected[X, Y: Integer]: Boolean read GetSelected write SetSelected; default;
  end;

implementation

uses
  Math, SysUtils;

{ --- SDF Anti-Aliasing Helpers (duplicated from fpsurface for dependency isolation) --- }

function SDFCoverage(DistPixels: Double): Byte; inline;
var
  Coverage: Double;
begin
  Coverage := DistPixels + 0.5;
  if Coverage <= 0.0 then
    Exit(0);
  if Coverage >= 1.0 then
    Exit(255);
  Result := Round(Coverage * 255.0);
end;

function EllipseSDF(PX, PY, CX, CY, RX, RY: Double): Double; inline;
var
  NX, NY, NLen: Double;
begin
  if (RX <= 0.0) or (RY <= 0.0) then
    Exit(-1.0);
  NX := (PX - CX) / RX;
  NY := (PY - CY) / RY;
  NLen := Sqrt(NX * NX + NY * NY);
  if NLen < 1.0e-12 then
    Exit(Min(RX, RY));
  Result := (1.0 - NLen) * Min(RX, RY) * (NLen / Sqrt((NX * NX) / (RX * RX) + (NY * NY) / (RY * RY)));
end;

function DistToSegment(PX, PY, AX, AY, BX, BY: Double): Double;
var
  DX, DY, T, ProjX, ProjY: Double;
begin
  DX := BX - AX;
  DY := BY - AY;
  if (DX = 0.0) and (DY = 0.0) then
    Exit(Sqrt(Sqr(PX - AX) + Sqr(PY - AY)));
  T := ((PX - AX) * DX + (PY - AY) * DY) / (DX * DX + DY * DY);
  if T < 0.0 then T := 0.0
  else if T > 1.0 then T := 1.0;
  ProjX := AX + T * DX;
  ProjY := AY + T * DY;
  Result := Sqrt(Sqr(PX - ProjX) + Sqr(PY - ProjY));
end;

{ --- End SDF Helpers --- }

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

procedure TSelectionMask.RebuildSelectionCache;
var
  X: Integer;
  Y: Integer;
  DataIndex: Integer;
  MinX: Integer;
  MinY: Integer;
  MaxX: Integer;
  MaxY: Integer;
begin
  FSelectedCount := 0;
  MinX := FWidth;
  MinY := FHeight;
  MaxX := -1;
  MaxY := -1;
  DataIndex := 0;
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      if FData[DataIndex] <> 0 then
      begin
        Inc(FSelectedCount);
        if X < MinX then
          MinX := X;
        if Y < MinY then
          MinY := Y;
        if X > MaxX then
          MaxX := X;
        if Y > MaxY then
          MaxY := Y;
      end;
      Inc(DataIndex);
    end;

  if FSelectedCount = 0 then
    FBoundsCache := Rect(0, 0, 0, 0)
  else
    FBoundsCache := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
  FBoundsDirty := False;
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
  FSelectedCount := 0;
  FBoundsCache := Rect(0, 0, 0, 0);
  FBoundsDirty := False;
end;

procedure TSelectionMask.SelectAll;
begin
  if Length(FData) > 0 then
    FillChar(FData[0], Length(FData), 255);
  FSelectedCount := Length(FData);
  if FSelectedCount > 0 then
    FBoundsCache := Rect(0, 0, FWidth, FHeight)
  else
    FBoundsCache := Rect(0, 0, 0, 0);
  FBoundsDirty := False;
end;

procedure TSelectionMask.Invert;
var
  Index: Integer;
begin
  for Index := 0 to High(FData) do
    FData[Index] := 255 - FData[Index];
  RebuildSelectionCache;
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
  FSelectedCount := ASource.FSelectedCount;
  FBoundsCache := ASource.FBoundsCache;
  FBoundsDirty := ASource.FBoundsDirty;
end;

function TSelectionMask.Clone: TSelectionMask;
begin
  Result := TSelectionMask.Create(FWidth, FHeight);
  Result.Assign(Self);
end;

procedure TSelectionMask.IntersectWith(AMask: TSelectionMask);
var
  X: Integer;
  Y: Integer;
begin
  if AMask = nil then
  begin
    Clear;
    Exit;
  end;

  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
      FData[IndexOf(X, Y)] := Min(FData[IndexOf(X, Y)], AMask.Coverage(X, Y));
  RebuildSelectionCache;
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
  if AValue then
    SetCoverage(X, Y, 255)
  else
    SetCoverage(X, Y, 0);
end;

function TSelectionMask.HasSelection: Boolean;
begin
  Result := FSelectedCount > 0;
end;

function TSelectionMask.Coverage(X, Y: Integer): Byte;
begin
  if not InBounds(X, Y) then
    Exit(0);
  Result := FData[IndexOf(X, Y)];
end;

procedure TSelectionMask.SetCoverage(X, Y: Integer; AValue: Byte);
var
  PixelIndex: Integer;
  OldSelected: Boolean;
  NewSelected: Boolean;
begin
  if not InBounds(X, Y) then
    Exit;
  PixelIndex := IndexOf(X, Y);
  if FData[PixelIndex] = AValue then
    Exit;

  OldSelected := FData[PixelIndex] <> 0;
  NewSelected := AValue <> 0;
  FData[PixelIndex] := AValue;

  if OldSelected = NewSelected then
    Exit;

  if NewSelected then
  begin
    Inc(FSelectedCount);
    if FSelectedCount = 1 then
    begin
      FBoundsCache := Rect(X, Y, X + 1, Y + 1);
      FBoundsDirty := False;
    end
    else if not FBoundsDirty then
    begin
      if X < FBoundsCache.Left then
        FBoundsCache.Left := X;
      if Y < FBoundsCache.Top then
        FBoundsCache.Top := Y;
      if X >= FBoundsCache.Right then
        FBoundsCache.Right := X + 1;
      if Y >= FBoundsCache.Bottom then
        FBoundsCache.Bottom := Y + 1;
    end;
  end
  else
  begin
    if FSelectedCount > 0 then
      Dec(FSelectedCount);
    if FSelectedCount = 0 then
    begin
      FBoundsCache := Rect(0, 0, 0, 0);
      FBoundsDirty := False;
    end
    else
      FBoundsDirty := True;
  end;
end;

procedure TSelectionMask.Feather(ARadius: Integer);
const
  LargeDistance = 1 shl 20;
var
  Radius: Integer;
  Len: Integer;
  Index: Integer;
  DistInside: array of Integer;
  DistOutside: array of Integer;
  SelectedFlag: array of Boolean;
  X: Integer;
  Y: Integer;
  CurrentIndex: Integer;
  CoverageValue: Integer;
begin
  Radius := Max(0, ARadius);
  Len := Length(FData);
  if (Radius <= 0) or (Len = 0) then
    Exit;

  SetLength(DistInside, Len);
  SetLength(DistOutside, Len);
  SetLength(SelectedFlag, Len);
  for Index := 0 to Len - 1 do
  begin
    SelectedFlag[Index] := FData[Index] <> 0;
    if SelectedFlag[Index] then
    begin
      DistInside[Index] := LargeDistance;
      DistOutside[Index] := 0;
    end
    else
    begin
      DistInside[Index] := 0;
      DistOutside[Index] := LargeDistance;
    end;
  end;

  for Y := 0 to FHeight - 1 do
  begin
    for X := 0 to FWidth - 1 do
    begin
      CurrentIndex := IndexOf(X, Y);
      if X > 0 then
        DistInside[CurrentIndex] := Min(DistInside[CurrentIndex], DistInside[CurrentIndex - 1] + 1);
      if Y > 0 then
        DistInside[CurrentIndex] := Min(DistInside[CurrentIndex], DistInside[CurrentIndex - FWidth] + 1);
      if X > 0 then
        DistOutside[CurrentIndex] := Min(DistOutside[CurrentIndex], DistOutside[CurrentIndex - 1] + 1);
      if Y > 0 then
        DistOutside[CurrentIndex] := Min(DistOutside[CurrentIndex], DistOutside[CurrentIndex - FWidth] + 1);
    end;
  end;

  for Y := FHeight - 1 downto 0 do
  begin
    for X := FWidth - 1 downto 0 do
    begin
      CurrentIndex := IndexOf(X, Y);
      if X < FWidth - 1 then
        DistInside[CurrentIndex] := Min(DistInside[CurrentIndex], DistInside[CurrentIndex + 1] + 1);
      if Y < FHeight - 1 then
        DistInside[CurrentIndex] := Min(DistInside[CurrentIndex], DistInside[CurrentIndex + FWidth] + 1);
      if X < FWidth - 1 then
        DistOutside[CurrentIndex] := Min(DistOutside[CurrentIndex], DistOutside[CurrentIndex + 1] + 1);
      if Y < FHeight - 1 then
        DistOutside[CurrentIndex] := Min(DistOutside[CurrentIndex], DistOutside[CurrentIndex + FWidth] + 1);
    end;
  end;

  for Index := 0 to Len - 1 do
  begin
    if SelectedFlag[Index] then
      CoverageValue := Round(255.0 * Min(DistInside[Index], Radius) / Radius)
    else if DistOutside[Index] <= Radius then
      CoverageValue := 255 - Round(255.0 * DistOutside[Index] / Radius)
    else
      CoverageValue := 0;
    FData[Index] := EnsureRange(CoverageValue, 0, 255);
  end;
  RebuildSelectionCache;
end;

procedure TSelectionMask.SelectRectangle(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode);
var
  IntersectMask: TSelectionMask;
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  X: Integer;
  Y: Integer;
begin
  if AMode = scIntersect then
  begin
    IntersectMask := TSelectionMask.Create(FWidth, FHeight);
    try
      IntersectMask.SelectRectangle(X1, Y1, X2, Y2, scReplace);
      IntersectWith(IntersectMask);
    finally
      IntersectMask.Free;
    end;
    Exit;
  end;

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
  IntersectMask: TSelectionMask;
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  CenterX: Double;
  CenterY: Double;
  RadiusX: Double;
  RadiusY: Double;
  X: Integer;
  Y: Integer;
  Dist: Double;
  Cov: Byte;
  Existing: Byte;
begin
  if AMode = scIntersect then
  begin
    IntersectMask := TSelectionMask.Create(FWidth, FHeight);
    try
      IntersectMask.SelectEllipse(X1, Y1, X2, Y2, scReplace);
      IntersectWith(IntersectMask);
    finally
      IntersectMask.Free;
    end;
    Exit;
  end;

  LeftX := Max(0, Min(X1, X2));
  RightX := Min(FWidth - 1, Max(X1, X2));
  TopY := Max(0, Min(Y1, Y2));
  BottomY := Min(FHeight - 1, Max(Y1, Y2));

  if AMode = scReplace then
    Clear;

  CenterX := (LeftX + RightX + 1) / 2.0;
  CenterY := (TopY + BottomY + 1) / 2.0;
  RadiusX := Max(0.5, (RightX - LeftX + 1) / 2.0);
  RadiusY := Max(0.5, (BottomY - TopY + 1) / 2.0);

  for Y := Max(0, TopY - 1) to Min(FHeight - 1, BottomY + 1) do
    for X := Max(0, LeftX - 1) to Min(FWidth - 1, RightX + 1) do
    begin
      Dist := EllipseSDF(X + 0.5, Y + 0.5, CenterX, CenterY, RadiusX, RadiusY);
      Cov := SDFCoverage(Dist);
      if Cov = 0 then
        Continue;
      case AMode of
        scReplace, scAdd:
        begin
          Existing := Coverage(X, Y);
          if Cov > Existing then
            SetCoverage(X, Y, Cov);
        end;
        scSubtract:
        begin
          Existing := Coverage(X, Y);
          if Existing > 0 then
          begin
            if Cov >= Existing then
              SetCoverage(X, Y, 0)
            else
              SetCoverage(X, Y, Existing - Cov);
          end;
        end;
      end;
    end;
end;

procedure TSelectionMask.SelectPolygon(const APoints: array of TPoint; AMode: TSelectionCombineMode);
var
  IntersectMask: TSelectionMask;
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  PointIndex: Integer;
  NextIndex: Integer;
  X: Integer;
  Y: Integer;
  PX, PY: Double;
  MinDist, EdgeDist: Double;
  Inside: Boolean;
  SignedDist: Double;
  Cov: Byte;
  Existing: Byte;

  procedure ApplyCoverage(AX, AY: Integer; ACov: Byte);
  begin
    if not InBounds(AX, AY) then
      Exit;
    if ACov = 0 then
      Exit;
    case AMode of
      scReplace, scAdd:
      begin
        Existing := Coverage(AX, AY);
        if ACov > Existing then
          SetCoverage(AX, AY, ACov);
      end;
      scSubtract:
      begin
        Existing := Coverage(AX, AY);
        if Existing > 0 then
        begin
          if ACov >= Existing then
            SetCoverage(AX, AY, 0)
          else
            SetCoverage(AX, AY, Existing - ACov);
        end;
      end;
    end;
  end;

begin
  if AMode = scIntersect then
  begin
    IntersectMask := TSelectionMask.Create(FWidth, FHeight);
    try
      IntersectMask.SelectPolygon(APoints, scReplace);
      IntersectWith(IntersectMask);
    finally
      IntersectMask.Free;
    end;
    Exit;
  end;

  if AMode = scReplace then
    Clear;

  if Length(APoints) < 3 then
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

  LeftX := Max(0, LeftX - 1);
  RightX := Min(FWidth - 1, RightX + 1);
  TopY := Max(0, TopY - 1);
  BottomY := Min(FHeight - 1, BottomY + 1);
  if (LeftX > RightX) or (TopY > BottomY) then
    Exit;

  for Y := TopY to BottomY do
    for X := LeftX to RightX do
    begin
      PX := X + 0.5;
      PY := Y + 0.5;
      Inside := PointInsidePolygon(APoints, PX, PY);
      MinDist := 1.0e30;
      for PointIndex := 0 to High(APoints) do
      begin
        NextIndex := (PointIndex + 1) mod Length(APoints);
        EdgeDist := DistToSegment(PX, PY,
          APoints[PointIndex].X + 0.5, APoints[PointIndex].Y + 0.5,
          APoints[NextIndex].X + 0.5, APoints[NextIndex].Y + 0.5);
        if EdgeDist < MinDist then
          MinDist := EdgeDist;
      end;
      if Inside then
        SignedDist := MinDist
      else
        SignedDist := -MinDist;
      Cov := SDFCoverage(SignedDist);
      ApplyCoverage(X, Y, Cov);
    end;
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
      if InBounds(SourceX, SourceY) then
        NewData[IndexOf(X, Y)] := Coverage(SourceX, SourceY);
    end;

  if Length(FData) > 0 then
    Move(NewData[0], FData[0], Length(FData));
  RebuildSelectionCache;
end;

procedure TSelectionMask.TranslateTo(ADest: TSelectionMask; DeltaX, DeltaY: Integer);
var
  DestY: Integer;
  SourceY: Integer;
  DestStartX: Integer;
  SourceStartX: Integer;
  CopyLen: Integer;
begin
  if ADest = nil then
    Exit;
  if ADest = Self then
  begin
    MoveBy(DeltaX, DeltaY);
    Exit;
  end;

  ADest.Clear;
  if (FSelectedCount = 0) or (Length(FData) = 0) then
    Exit;

  for DestY := 0 to ADest.FHeight - 1 do
  begin
    SourceY := DestY - DeltaY;
    if (SourceY < 0) or (SourceY >= FHeight) then
      Continue;

    SourceStartX := -DeltaX;
    DestStartX := 0;
    if SourceStartX < 0 then
    begin
      DestStartX := -SourceStartX;
      SourceStartX := 0;
    end;

    CopyLen := Min(FWidth - SourceStartX, ADest.FWidth - DestStartX);
    if CopyLen <= 0 then
      Continue;

    Move(
      FData[SourceY * FWidth + SourceStartX],
      ADest.FData[DestY * ADest.FWidth + DestStartX],
      CopyLen
    );
  end;
  ADest.RebuildSelectionCache;
end;

procedure TSelectionMask.FlipHorizontal;
var
  X: Integer;
  Y: Integer;
  HalfWidth: Integer;
  LeftIndex: Integer;
  RightIndex: Integer;
  Temp: Byte;
begin
  HalfWidth := FWidth div 2;
  for Y := 0 to FHeight - 1 do
    for X := 0 to HalfWidth - 1 do
    begin
      LeftIndex := IndexOf(X, Y);
      RightIndex := IndexOf(FWidth - 1 - X, Y);
      Temp := FData[LeftIndex];
      FData[LeftIndex] := FData[RightIndex];
      FData[RightIndex] := Temp;
    end;
  if FSelectedCount > 0 then
    FBoundsDirty := True;
end;

procedure TSelectionMask.FlipVertical;
var
  X: Integer;
  Y: Integer;
  HalfHeight: Integer;
  TopIndex: Integer;
  BottomIndex: Integer;
  Temp: Byte;
begin
  HalfHeight := FHeight div 2;
  for Y := 0 to HalfHeight - 1 do
    for X := 0 to FWidth - 1 do
    begin
      TopIndex := IndexOf(X, Y);
      BottomIndex := IndexOf(X, FHeight - 1 - Y);
      Temp := FData[TopIndex];
      FData[TopIndex] := FData[BottomIndex];
      FData[BottomIndex] := Temp;
    end;
  if FSelectedCount > 0 then
    FBoundsDirty := True;
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
        Rotated.SetCoverage(FHeight - 1 - Y, X, Coverage(X, Y));
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
        Rotated.SetCoverage(Y, FWidth - 1 - X, Coverage(X, Y));
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
      Result.SetCoverage(TargetX, TargetY, Coverage(SourceX, SourceY));
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
      Result.SetCoverage(TargetX, TargetY, Coverage(SourceX, SourceY));
    end;
  end;
end;

function TSelectionMask.BoundsRect: TRect;
begin
  if FSelectedCount = 0 then
    Exit(Rect(0, 0, 0, 0));
  if FBoundsDirty then
    RebuildSelectionCache;
  Result := FBoundsCache;
end;

end.
