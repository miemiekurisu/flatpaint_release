unit FPHistoryTransaction;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, FPDocument, FPSurface;

type
  TRegionHistoryTransaction = class
  private
    FPreMutationSnapshot: TRasterSurface;
    FCaptureRect: TRect;
    FLayerIndex: Integer;
    FActive: Boolean;
    function RectIsEmpty(const ARect: TRect): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function HasPending: Boolean;
    procedure BeginSession(ADocument: TImageDocument; ALayerIndex: Integer);
    procedure CaptureBeforeRect(ADocument: TImageDocument; const ARect: TRect);
    function CommitToHistory(ADocument: TImageDocument; const ALabel: string): Boolean;
  end;

implementation

uses
  Math;

function EmptyRectSentinel: TRect;
begin
  Result := Rect(MaxInt, MaxInt, 0, 0);
end;

constructor TRegionHistoryTransaction.Create;
begin
  inherited Create;
  Clear;
end;

destructor TRegionHistoryTransaction.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TRegionHistoryTransaction.RectIsEmpty(const ARect: TRect): Boolean;
begin
  Result := (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top);
end;

procedure TRegionHistoryTransaction.Clear;
begin
  FreeAndNil(FPreMutationSnapshot);
  FCaptureRect := EmptyRectSentinel;
  FLayerIndex := -1;
  FActive := False;
end;

function TRegionHistoryTransaction.HasPending: Boolean;
begin
  Result := FActive;
end;

procedure TRegionHistoryTransaction.BeginSession(ADocument: TImageDocument; ALayerIndex: Integer);
begin
  Clear;
  if (ADocument = nil) or (ADocument.LayerCount <= 0) then
    Exit;
  FLayerIndex := EnsureRange(ALayerIndex, 0, ADocument.LayerCount - 1);
  FActive := True;
end;

procedure TRegionHistoryTransaction.CaptureBeforeRect(ADocument: TImageDocument;
  const ARect: TRect);
var
  CaptureRect: TRect;
  OldRect: TRect;
  UnionRect: TRect;
  NewSnapshot: TRasterSurface;
  SourceLayer: TRasterLayer;
begin
  if not FActive then
    Exit;
  if (ADocument = nil) or (FLayerIndex < 0) or (FLayerIndex >= ADocument.LayerCount) then
    Exit;

  CaptureRect := ARect;
  CaptureRect.Left := Max(0, CaptureRect.Left);
  CaptureRect.Top := Max(0, CaptureRect.Top);
  CaptureRect.Right := Min(ADocument.Width, CaptureRect.Right);
  CaptureRect.Bottom := Min(ADocument.Height, CaptureRect.Bottom);
  if RectIsEmpty(CaptureRect) then
    Exit;

  SourceLayer := ADocument.Layers[FLayerIndex];
  if not Assigned(FPreMutationSnapshot) then
  begin
    FCaptureRect := CaptureRect;
    FPreMutationSnapshot := TRasterSurface.Create(
      FCaptureRect.Right - FCaptureRect.Left,
      FCaptureRect.Bottom - FCaptureRect.Top
    );
    SourceLayer.Surface.CopyRegionTo(FPreMutationSnapshot, FCaptureRect.Left, FCaptureRect.Top);
    Exit;
  end;

  OldRect := FCaptureRect;
  if (CaptureRect.Left >= OldRect.Left) and (CaptureRect.Top >= OldRect.Top) and
     (CaptureRect.Right <= OldRect.Right) and (CaptureRect.Bottom <= OldRect.Bottom) then
    Exit;

  UnionRect.Left := Min(OldRect.Left, CaptureRect.Left);
  UnionRect.Top := Min(OldRect.Top, CaptureRect.Top);
  UnionRect.Right := Max(OldRect.Right, CaptureRect.Right);
  UnionRect.Bottom := Max(OldRect.Bottom, CaptureRect.Bottom);

  NewSnapshot := TRasterSurface.Create(
    UnionRect.Right - UnionRect.Left,
    UnionRect.Bottom - UnionRect.Top
  );
  try
    SourceLayer.Surface.CopyRegionTo(NewSnapshot, UnionRect.Left, UnionRect.Top);
    NewSnapshot.OverwriteRegion(
      FPreMutationSnapshot,
      OldRect.Left - UnionRect.Left,
      OldRect.Top - UnionRect.Top
    );
    FreeAndNil(FPreMutationSnapshot);
    FPreMutationSnapshot := NewSnapshot;
    NewSnapshot := nil;
    FCaptureRect := UnionRect;
  finally
    NewSnapshot.Free;
  end;
end;

function TRegionHistoryTransaction.CommitToHistory(ADocument: TImageDocument;
  const ALabel: string): Boolean;
var
  CommitRect: TRect;
  BeforePixels: TRasterSurface;
begin
  Result := False;
  if not FActive then
    Exit;
  try
    if (ADocument = nil) or not Assigned(FPreMutationSnapshot) or RectIsEmpty(FCaptureRect) then
      Exit;

    CommitRect := FCaptureRect;
    CommitRect.Left := Max(0, CommitRect.Left);
    CommitRect.Top := Max(0, CommitRect.Top);
    CommitRect.Right := Min(ADocument.Width, CommitRect.Right);
    CommitRect.Bottom := Min(ADocument.Height, CommitRect.Bottom);
    if RectIsEmpty(CommitRect) then
      Exit;

    BeforePixels := TRasterSurface.Create(CommitRect.Right - CommitRect.Left, CommitRect.Bottom - CommitRect.Top);
    FPreMutationSnapshot.CopyRegionTo(
      BeforePixels,
      CommitRect.Left - FCaptureRect.Left,
      CommitRect.Top - FCaptureRect.Top
    );
    ADocument.PushRegionHistory(ALabel, FLayerIndex, CommitRect, BeforePixels);
    Result := True;
  finally
    Clear;
  end;
end;

end.
