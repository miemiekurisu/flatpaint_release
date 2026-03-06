unit FPToolControllers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, FPColor, FPSurface, FPSelection, FPDocument;

type
  TMovePixelsCommitResult = (mpcNoSession, mpcNoMove, mpcCommitted);

  TStrokeHistoryController = class
  private
    FPreStrokeSnapshot: TRasterSurface;
    FCaptureRect: TRect;
    FLayerIndex: Integer;
    FToolKind: TToolKind;
    FActive: Boolean;
    function RectIsEmpty(const ARect: TRect): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function HasPending: Boolean;
    function BoundsForSegment(const AFrom, ATo: TPoint; ARadius: Integer): TRect;
    procedure BeginSession(ADocument: TImageDocument; AToolKind: TToolKind; ALayerIndex: Integer);
    procedure CaptureBeforeRect(ADocument: TImageDocument; const ARect: TRect);
    function CommitToHistory(ADocument: TImageDocument; const ALabel: string): Boolean;
    property ToolKind: TToolKind read FToolKind;
  end;

  TSelectionToolController = class
  private
    procedure ApplyFeatherIfNeeded(
      ADocument: TImageDocument;
      AEnableFeather: Boolean;
      AFeatherRadius: Integer
    );
  public
    class function ModeFromModifiers(
      AShiftPressed: Boolean;
      AAltPressed: Boolean
    ): TSelectionCombineMode; static;
    function BeginMoveSelection(
      ADocument: TImageDocument;
      const AHistoryLabel: string
    ): Boolean;
    function MoveSelectionStep(
      ADocument: TImageDocument;
      DeltaX, DeltaY: Integer
    ): Boolean;
    function CommitRectangleSelection(
      ADocument: TImageDocument;
      const AStartPoint, AEndPoint: TPoint;
      AMode: TSelectionCombineMode;
      AEnableFeather: Boolean;
      AFeatherRadius: Integer;
      const AHistoryLabel: string
    ): Boolean;
    function CommitEllipseSelection(
      ADocument: TImageDocument;
      const AStartPoint, AEndPoint: TPoint;
      AMode: TSelectionCombineMode;
      AEnableFeather: Boolean;
      AFeatherRadius: Integer;
      const AHistoryLabel: string
    ): Boolean;
    function CommitLassoSelection(
      ADocument: TImageDocument;
      const APoints: array of TPoint;
      AMode: TSelectionCombineMode;
      AEnableFeather: Boolean;
      AFeatherRadius: Integer;
      const AHistoryLabel: string
    ): Boolean;
    function CommitMagicWandSelection(
      ADocument: TImageDocument;
      const APoint: TPoint;
      ATolerance: Integer;
      AMode: TSelectionCombineMode;
      ASampleAllLayers: Boolean;
      AContiguous: Boolean;
      AEnableFeather: Boolean;
      AFeatherRadius: Integer;
      const AHistoryLabel: string
    ): Boolean;
  end;

  TMovePixelsController = class
  private
    FActive: Boolean;
    FMoved: Boolean;
    FLayerIndex: Integer;
    FDelta: TPoint;
    FBaseSelection: TSelectionMask;
    FFloatingPixels: TRasterSurface;
    FPreviewBaseComposite: TRasterSurface;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure BeginSession(ADocument: TImageDocument; const ABackgroundColor: TRGBA32);
    function UpdateDelta(ADocument: TImageDocument; DeltaX, DeltaY: Integer): Boolean;
    function Commit(ADocument: TImageDocument; const AHistoryLabel: string; const ABackgroundColor: TRGBA32): TMovePixelsCommitResult;
    function Cancel(ADocument: TImageDocument): Boolean;
    procedure RenderPreview(ASurface: TRasterSurface);
    property Active: Boolean read FActive;
    property Moved: Boolean read FMoved;
    property Delta: TPoint read FDelta;
    property PreviewBaseComposite: TRasterSurface read FPreviewBaseComposite;
  end;

implementation

uses
  Math;

function EmptyRectSentinel: TRect;
begin
  Result := Rect(MaxInt, MaxInt, 0, 0);
end;

{ TStrokeHistoryController }

constructor TStrokeHistoryController.Create;
begin
  inherited Create;
  Clear;
end;

destructor TStrokeHistoryController.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TStrokeHistoryController.RectIsEmpty(const ARect: TRect): Boolean;
begin
  Result := (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top);
end;

procedure TStrokeHistoryController.Clear;
begin
  FreeAndNil(FPreStrokeSnapshot);
  FCaptureRect := EmptyRectSentinel;
  FLayerIndex := -1;
  FToolKind := tkPencil;
  FActive := False;
end;

function TStrokeHistoryController.HasPending: Boolean;
begin
  Result := FActive;
end;

function TStrokeHistoryController.BoundsForSegment(const AFrom, ATo: TPoint; ARadius: Integer): TRect;
var
  Margin: Integer;
begin
  Margin := Max(2, ARadius + 2);
  Result.Left := Min(AFrom.X, ATo.X) - Margin;
  Result.Top := Min(AFrom.Y, ATo.Y) - Margin;
  Result.Right := Max(AFrom.X, ATo.X) + Margin + 1;
  Result.Bottom := Max(AFrom.Y, ATo.Y) + Margin + 1;
end;

procedure TStrokeHistoryController.BeginSession(ADocument: TImageDocument; AToolKind: TToolKind; ALayerIndex: Integer);
begin
  Clear;
  if (ADocument = nil) or (ADocument.LayerCount <= 0) then
    Exit;
  FToolKind := AToolKind;
  FLayerIndex := EnsureRange(ALayerIndex, 0, ADocument.LayerCount - 1);
  FActive := True;
end;

procedure TStrokeHistoryController.CaptureBeforeRect(ADocument: TImageDocument; const ARect: TRect);
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
  if not Assigned(FPreStrokeSnapshot) then
  begin
    FCaptureRect := CaptureRect;
    FPreStrokeSnapshot := TRasterSurface.Create(
      FCaptureRect.Right - FCaptureRect.Left,
      FCaptureRect.Bottom - FCaptureRect.Top
    );
    SourceLayer.Surface.CopyRegionTo(FPreStrokeSnapshot, FCaptureRect.Left, FCaptureRect.Top);
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
      FPreStrokeSnapshot,
      OldRect.Left - UnionRect.Left,
      OldRect.Top - UnionRect.Top
    );
    FreeAndNil(FPreStrokeSnapshot);
    FPreStrokeSnapshot := NewSnapshot;
    NewSnapshot := nil;
    FCaptureRect := UnionRect;
  finally
    NewSnapshot.Free;
  end;
end;

function TStrokeHistoryController.CommitToHistory(ADocument: TImageDocument; const ALabel: string): Boolean;
var
  CommitRect: TRect;
  BeforePixels: TRasterSurface;
begin
  Result := False;
  if not FActive then
    Exit;
  try
    if (ADocument = nil) or not Assigned(FPreStrokeSnapshot) or RectIsEmpty(FCaptureRect) then
      Exit;

    CommitRect := FCaptureRect;
    CommitRect.Left := Max(0, CommitRect.Left);
    CommitRect.Top := Max(0, CommitRect.Top);
    CommitRect.Right := Min(ADocument.Width, CommitRect.Right);
    CommitRect.Bottom := Min(ADocument.Height, CommitRect.Bottom);
    if RectIsEmpty(CommitRect) then
      Exit;

    BeforePixels := TRasterSurface.Create(CommitRect.Right - CommitRect.Left, CommitRect.Bottom - CommitRect.Top);
    FPreStrokeSnapshot.CopyRegionTo(
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

{ TSelectionToolController }

procedure TSelectionToolController.ApplyFeatherIfNeeded(
  ADocument: TImageDocument;
  AEnableFeather: Boolean;
  AFeatherRadius: Integer
);
begin
  if (ADocument = nil) or not AEnableFeather or (AFeatherRadius <= 0) or
     (not ADocument.HasSelection) then
    Exit;
  ADocument.Selection.Feather(AFeatherRadius);
end;

class function TSelectionToolController.ModeFromModifiers(
  AShiftPressed: Boolean;
  AAltPressed: Boolean
): TSelectionCombineMode;
begin
  if AShiftPressed and AAltPressed then
    Exit(scIntersect);
  if AAltPressed then
    Exit(scSubtract);
  if AShiftPressed then
    Exit(scAdd);
  Result := scReplace;
end;

function TSelectionToolController.BeginMoveSelection(
  ADocument: TImageDocument;
  const AHistoryLabel: string
): Boolean;
begin
  Result := (ADocument <> nil) and ADocument.HasSelection;
  if not Result then
    Exit;
  ADocument.PushHistory(AHistoryLabel);
end;

function TSelectionToolController.MoveSelectionStep(
  ADocument: TImageDocument;
  DeltaX, DeltaY: Integer
): Boolean;
begin
  Result := False;
  if (ADocument = nil) or not ADocument.HasSelection then
    Exit;
  if (DeltaX = 0) and (DeltaY = 0) then
    Exit;
  ADocument.MoveSelectionBy(DeltaX, DeltaY);
  Result := True;
end;

function TSelectionToolController.CommitRectangleSelection(
  ADocument: TImageDocument;
  const AStartPoint, AEndPoint: TPoint;
  AMode: TSelectionCombineMode;
  AEnableFeather: Boolean;
  AFeatherRadius: Integer;
  const AHistoryLabel: string
): Boolean;
begin
  Result := ADocument <> nil;
  if not Result then
    Exit;
  ADocument.PushHistory(AHistoryLabel);
  ADocument.SelectRectangle(
    AStartPoint.X,
    AStartPoint.Y,
    AEndPoint.X,
    AEndPoint.Y,
    AMode
  );
  ApplyFeatherIfNeeded(ADocument, AEnableFeather, AFeatherRadius);
end;

function TSelectionToolController.CommitEllipseSelection(
  ADocument: TImageDocument;
  const AStartPoint, AEndPoint: TPoint;
  AMode: TSelectionCombineMode;
  AEnableFeather: Boolean;
  AFeatherRadius: Integer;
  const AHistoryLabel: string
): Boolean;
begin
  Result := ADocument <> nil;
  if not Result then
    Exit;
  ADocument.PushHistory(AHistoryLabel);
  ADocument.SelectEllipse(
    AStartPoint.X,
    AStartPoint.Y,
    AEndPoint.X,
    AEndPoint.Y,
    AMode
  );
  ApplyFeatherIfNeeded(ADocument, AEnableFeather, AFeatherRadius);
end;

function TSelectionToolController.CommitLassoSelection(
  ADocument: TImageDocument;
  const APoints: array of TPoint;
  AMode: TSelectionCombineMode;
  AEnableFeather: Boolean;
  AFeatherRadius: Integer;
  const AHistoryLabel: string
): Boolean;
begin
  Result := ADocument <> nil;
  if not Result then
    Exit;
  ADocument.PushHistory(AHistoryLabel);
  ADocument.SelectLasso(APoints, AMode);
  ApplyFeatherIfNeeded(ADocument, AEnableFeather, AFeatherRadius);
end;

function TSelectionToolController.CommitMagicWandSelection(
  ADocument: TImageDocument;
  const APoint: TPoint;
  ATolerance: Integer;
  AMode: TSelectionCombineMode;
  ASampleAllLayers: Boolean;
  AContiguous: Boolean;
  AEnableFeather: Boolean;
  AFeatherRadius: Integer;
  const AHistoryLabel: string
): Boolean;
begin
  Result := ADocument <> nil;
  if not Result then
    Exit;
  ADocument.PushHistory(AHistoryLabel);
  ADocument.SelectMagicWand(
    APoint.X,
    APoint.Y,
    EnsureRange(ATolerance, 0, 255),
    AMode,
    ASampleAllLayers,
    AContiguous
  );
  ApplyFeatherIfNeeded(ADocument, AEnableFeather, AFeatherRadius);
end;

{ TMovePixelsController }

constructor TMovePixelsController.Create;
begin
  inherited Create;
  Clear;
end;

destructor TMovePixelsController.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TMovePixelsController.Clear;
begin
  FreeAndNil(FBaseSelection);
  FreeAndNil(FFloatingPixels);
  FreeAndNil(FPreviewBaseComposite);
  FActive := False;
  FMoved := False;
  FLayerIndex := -1;
  FDelta := Point(0, 0);
end;

procedure TMovePixelsController.BeginSession(ADocument: TImageDocument; const ABackgroundColor: TRGBA32);
var
  SourceSnapshot: TRasterSurface;
begin
  Clear;
  if (ADocument = nil) or not ADocument.HasSelection or (ADocument.LayerCount <= 0) then
    Exit;

  FBaseSelection := ADocument.Selection.Clone;
  FFloatingPixels := ADocument.ActiveLayer.Surface.CopySelection(FBaseSelection);
  FLayerIndex := ADocument.ActiveLayerIndex;

  SourceSnapshot := ADocument.ActiveLayer.Surface.Clone;
  try
    if ADocument.ActiveLayer.IsBackground then
      ADocument.ActiveLayer.Surface.FillSelection(FBaseSelection, ABackgroundColor, 255)
    else
      ADocument.ActiveLayer.Surface.EraseSelection(FBaseSelection);
    FPreviewBaseComposite := ADocument.Composite;
  finally
    ADocument.ActiveLayer.Surface.Assign(SourceSnapshot);
    SourceSnapshot.Free;
  end;

  FDelta := Point(0, 0);
  FMoved := False;
  FActive := True;
end;

function TMovePixelsController.UpdateDelta(ADocument: TImageDocument; DeltaX, DeltaY: Integer): Boolean;
begin
  Result := False;
  if not FActive or (ADocument = nil) or not Assigned(FBaseSelection) then
    Exit;
  if (DeltaX = 0) and (DeltaY = 0) then
    Exit;

  Inc(FDelta.X, DeltaX);
  Inc(FDelta.Y, DeltaY);
  FMoved := (FDelta.X <> 0) or (FDelta.Y <> 0);

  ADocument.Selection.Assign(FBaseSelection);
  if FMoved then
    ADocument.Selection.MoveBy(FDelta.X, FDelta.Y);
  Result := True;
end;

function TMovePixelsController.Commit(ADocument: TImageDocument; const AHistoryLabel: string; const ABackgroundColor: TRGBA32): TMovePixelsCommitResult;
var
  TargetLayer: TRasterLayer;
begin
  if not FActive then
    Exit(mpcNoSession);
  if (ADocument = nil) or not Assigned(FBaseSelection) or not Assigned(FFloatingPixels) then
  begin
    Clear;
    Exit(mpcNoSession);
  end;

  if not FMoved then
  begin
    ADocument.Selection.Assign(FBaseSelection);
    Clear;
    Exit(mpcNoMove);
  end;

  if (FLayerIndex < 0) or (FLayerIndex >= ADocument.LayerCount) then
    TargetLayer := ADocument.ActiveLayer
  else
    TargetLayer := ADocument.Layers[FLayerIndex];

  ADocument.PushHistory(AHistoryLabel);
  if TargetLayer.IsBackground then
    TargetLayer.Surface.FillSelection(FBaseSelection, ABackgroundColor, 255)
  else
    TargetLayer.Surface.EraseSelection(FBaseSelection);
  TargetLayer.Surface.PasteSurface(FFloatingPixels, FDelta.X, FDelta.Y);

  ADocument.Selection.Assign(FBaseSelection);
  ADocument.Selection.MoveBy(FDelta.X, FDelta.Y);
  Clear;
  Result := mpcCommitted;
end;

function TMovePixelsController.Cancel(ADocument: TImageDocument): Boolean;
begin
  Result := FActive;
  if not FActive then
    Exit;
  if (ADocument <> nil) and Assigned(FBaseSelection) then
    ADocument.Selection.Assign(FBaseSelection);
  Clear;
end;

procedure TMovePixelsController.RenderPreview(ASurface: TRasterSurface);
var
  X: Integer;
  Y: Integer;
  TargetX: Integer;
  TargetY: Integer;
  PixelColor: TRGBA32;
begin
  if not FActive or not FMoved or (ASurface = nil) or (FFloatingPixels = nil) then
    Exit;

  for Y := 0 to FFloatingPixels.Height - 1 do
    for X := 0 to FFloatingPixels.Width - 1 do
    begin
      PixelColor := FFloatingPixels[X, Y];
      if PixelColor.A = 0 then
        Continue;
      TargetX := X + FDelta.X;
      TargetY := Y + FDelta.Y;
      if not ASurface.InBounds(TargetX, TargetY) then
        Continue;
      ASurface[TargetX, TargetY] := BlendNormal(PixelColor, ASurface[TargetX, TargetY], 255);
    end;
end;

end.
