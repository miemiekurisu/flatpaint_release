unit FPDocument;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, Types, FPColor, FPSurface, FPSelection, FPMutationGuard;

type
  TBlendMode = (
    bmNormal,
    bmMultiply,
    bmScreen,
    bmOverlay,
    bmDarken,
    bmLighten,
    bmDifference,
    bmSoftLight
  );

  TRecolorSamplingMode = (
    rsmOnce,
    rsmContinuous,
    rsmSwatchCompat
  );

  TToolKind = (
    tkPencil,
    tkBrush,
    tkEraser,
    tkFill,
    tkGradient,
    tkLine,
    tkRectangle,
    tkRoundedRectangle,
    tkEllipseShape,
    tkFreeformShape,
    tkSelectRect,
    tkSelectEllipse,
    tkSelectLasso,
    tkMagicWand,
    tkMoveSelection,
    tkMovePixels,
    tkZoom,
    tkPan,
    tkColorPicker,
    tkCrop,
    tkText,
    tkCloneStamp,
    tkRecolor,
    tkMosaic
  );

  TRasterLayer = class
  private
    FName: string;
    FVisible: Boolean;
    FLocked: Boolean;
    FOpacity: Byte;
    FBlendMode: TBlendMode;
    FIsBackground: Boolean;
    FOffsetX: Integer;
    FOffsetY: Integer;
    FSurface: TRasterSurface;
  public
    constructor Create(const AName: string; AWidth, AHeight: Integer; AIsBackground: Boolean = False);
    destructor Destroy; override;
    function Clone: TRasterLayer;
    property Name: string read FName write FName;
    property Visible: Boolean read FVisible write FVisible;
    property Locked: Boolean read FLocked write FLocked;
    property Opacity: Byte read FOpacity write FOpacity;
    property BlendMode: TBlendMode read FBlendMode write FBlendMode;
    property IsBackground: Boolean read FIsBackground write FIsBackground;
    property OffsetX: Integer read FOffsetX write FOffsetX;
    property OffsetY: Integer read FOffsetY write FOffsetY;
    property Surface: TRasterSurface read FSurface;
  end;

  TSnapshotKind = (skFullDocument, skLayerRegion);

  TDocumentSnapshot = class
  private
    FKind: TSnapshotKind;
    FRestoreSelectionState: Boolean;
    { Full-document fields (skFullDocument) }
    FLayers: TObjectList;
    FSelection: TSelectionMask;
    FWidth: Integer;
    FHeight: Integer;
    FActiveLayerIndex: Integer;
    { Region fields (skLayerRegion): saves only a rect of one layer }
    FRegionLayerIndex: Integer;
    FRegionSurface: TRasterSurface;
    FDirtyRect: TRect;
  public
    constructor CreateFromDocument(ADocument: TObject);
    { Captures current pixels of ADocument.Layers[ALayerIndex] within ARect. }
    constructor CreateFromRegion(
      ADocument: TObject;
      ALayerIndex: Integer;
      const ARect: TRect;
      AIncludeSelectionState: Boolean = False
    );
    { Takes ownership of APixels (already-captured before-pixels for ARect). }
    constructor WrapRegionPixels(
      ALayerIndex: Integer;
      const ARect: TRect;
      APixels: TRasterSurface;
      ASelection: TSelectionMask = nil;
      AActiveLayerIndex: Integer = -1
    );
    destructor Destroy; override;
    property Kind: TSnapshotKind read FKind;
    property RestoreSelectionState: Boolean read FRestoreSelectionState;
    property Layers: TObjectList read FLayers;
    property Selection: TSelectionMask read FSelection;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property ActiveLayerIndex: Integer read FActiveLayerIndex;
    property RegionLayerIndex: Integer read FRegionLayerIndex;
    property RegionSurface: TRasterSurface read FRegionSurface;
    property DirtyRect: TRect read FDirtyRect;
  end;

  TImageDocument = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FLayers: TObjectList;
    FHistory: TObjectList;
    FRedo: TObjectList;
    FHistoryLabels: TStringList;
    FRedoLabels: TStringList;
    FMaxHistory: Integer;
    FActiveLayerIndex: Integer;
    FSelection: TSelectionMask;
    FStoredSelection: TSelectionMask;
    FHasStoredSelection: Boolean;
    function GetActiveLayer: TRasterLayer;
    function GetLayer(AIndex: Integer): TRasterLayer;
    function PopSnapshot(AStack: TObjectList): TDocumentSnapshot;
    procedure ApplySnapshot(ASnapshot: TDocumentSnapshot);
    function BackgroundReplacementColor(const AColor: TRGBA32): TRGBA32;
    function AnyLayerLocked: Boolean;
    function CanMutateActiveLayerPixels: Boolean;
    function CanMutateDocumentPixels: Boolean;
    function CanvasPointToLayerPoint(ALayer: TRasterLayer; X, Y: Integer): TPoint;
    function TranslateSelectionMask(
      ASource: TSelectionMask;
      ADestWidth, ADestHeight: Integer;
      DeltaX, DeltaY: Integer
    ): TSelectionMask;
    function SelectionInLayerSpace(ALayer: TRasterLayer; ASelection: TSelectionMask): TSelectionMask;
    procedure EnforceLayerInvariant;
  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;
    procedure NewBlank(AWidth, AHeight: Integer);
    procedure ReplaceWithSingleLayer(ASurface: TRasterSurface; const ALayerName: string);
    procedure PushHistory(const ALabel: string = 'Change');
    function BeginActiveLayerMutation(const ALabel: string = 'Change'): Boolean;
    function BeginDocumentMutation(const ALabel: string = 'Change'): Boolean;
    function MutableActiveLayerSurface: TRasterSurface;
    { Push a region snapshot with already-captured before-pixels (ownership is transferred). }
    procedure PushRegionHistory(const ALabel: string; ALayerIndex: Integer; const ADirtyRect: TRect; ABeforePixels: TRasterSurface);
    procedure PushRegionHistoryWithSelection(
      const ALabel: string;
      ALayerIndex: Integer;
      const ADirtyRect: TRect;
      ABeforePixels: TRasterSurface;
      ASelectionBefore: TSelectionMask;
      AActiveLayerIndexBefore: Integer
    );
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    procedure Undo;
    procedure Redo;
    procedure ClearHistory;
    function AddLayer(const AName: string = ''): TRasterLayer;
    procedure MoveLayer(AFromIndex, AToIndex: Integer);
    procedure RenameLayer(AIndex: Integer; const AName: string);
    procedure SetLayerVisibility(AIndex: Integer; AVisible: Boolean);
    procedure SetLayerOpacity(AIndex: Integer; AOpacity: Byte);
    procedure DuplicateActiveLayer;
    procedure DeleteActiveLayer;
    procedure MergeDown;
    procedure Flatten;
    procedure Crop(X, Y, AWidth, AHeight: Integer);
    procedure ResizeImage(ANewWidth, ANewHeight: Integer; AResampleMode: TResampleMode = rmNearestNeighbor);
    procedure ResizeImageNearest(ANewWidth, ANewHeight: Integer);
    procedure ResizeCanvas(ANewWidth, ANewHeight: Integer);
    procedure FlipHorizontal;
    procedure FlipVertical;
    procedure Rotate180;
    procedure Rotate90Clockwise;
    procedure Rotate90CounterClockwise;
    procedure Deselect;
    procedure SelectAll;
    procedure InvertSelection;
    procedure SelectRectangle(
      X1, Y1, X2, Y2: Integer;
      AMode: TSelectionCombineMode = scReplace;
      AAntiAlias: Boolean = False
    );
    procedure SelectEllipse(
      X1, Y1, X2, Y2: Integer;
      AMode: TSelectionCombineMode = scReplace;
      AAntiAlias: Boolean = True
    );
    procedure SelectLasso(
      const APoints: array of TPoint;
      AMode: TSelectionCombineMode = scReplace;
      AAntiAlias: Boolean = True
    );
    procedure SelectMagicWand(X, Y: Integer; Tolerance: Byte = 0; AMode: TSelectionCombineMode = scReplace; UseAllLayers: Boolean = False; Contiguous: Boolean = True);
    function CopySelectionToSurface(ACropToBounds: Boolean = False): TRasterSurface;
    function CopyMergedToSurface(ACropToBounds: Boolean = False): TRasterSurface;
    function CutSelectionToSurface(ACropToBounds: Boolean = False): TRasterSurface; overload;
    function CutSelectionToSurface(ACropToBounds: Boolean; const ABackgroundColor: TRGBA32): TRasterSurface; overload;
    procedure PasteAsNewLayer(ASurface: TRasterSurface; OffsetX: Integer = 0; OffsetY: Integer = 0; const ALayerName: string = 'Pasted Layer');
    procedure PasteSurfaceToActiveLayer(ASurface: TRasterSurface; OffsetX, OffsetY: Integer; Opacity: Byte = 255; ASelection: TSelectionMask = nil);
    procedure FillSelection(const AColor: TRGBA32; Opacity: Byte = 255);
    procedure EraseSelection; overload;
    procedure EraseSelection(const ABackgroundColor: TRGBA32); overload;
    procedure MoveSelectionBy(DeltaX, DeltaY: Integer);
    procedure MoveSelectedPixelsBy(DeltaX, DeltaY: Integer); overload;
    procedure MoveSelectedPixelsBy(DeltaX, DeltaY: Integer; const ABackgroundColor: TRGBA32); overload;
    procedure PixelateRect(X1, Y1, X2, Y2: Integer; BlockSize: Integer; ASelection: TSelectionMask = nil);
    procedure RotateActiveLayer90Clockwise;
    procedure RotateActiveLayer90CounterClockwise;
    procedure RotateActiveLayer180;
    procedure CropToSelection;
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
    procedure Unfocus(Radius: Integer);
    procedure SurfaceBlur(Radius: Integer; Threshold: Byte = 24);
    procedure RadialBlur(Amount: Integer);
    procedure Twist(Amount: Integer);
    procedure Fragment(Offset: Integer);
    procedure Bulge(Amount: Integer);
    procedure Dents(Amount: Integer);
    procedure Relief(Angle: Integer = 45);
    procedure RedEye(Threshold: Byte = 48; Strength: Integer = 100);
    procedure TileReflection(TileSize: Integer);
    procedure Crystallize(CellSize: Integer; Seed: Cardinal = 1);
    procedure InkSketch(InkStrength: Integer = 75; Coloring: Integer = 50);
    procedure RenderMandelbrot(Iterations: Integer = 64; Zoom: Double = 1.0);
    procedure RenderJulia(Iterations: Integer = 64; Zoom: Double = 1.0; CReal: Double = -0.8; CImag: Double = 0.156);
    procedure RecolorBrush(
      X, Y, Radius: Integer;
      SourceColor, NewColor: TRGBA32;
      Tolerance: Byte;
      Opacity: Byte = 255;
      PreserveValue: Boolean = False;
      ASelection: TSelectionMask = nil;
      Mode: TRecolorBlendMode = rbmReplaceRGBCompat
    );
    function HasSelection: Boolean;
    function HasStoredSelection: Boolean;
    procedure StoreSelectionForPaste;
    procedure PasteStoredSelection;
    function ActiveSelectionInLayerSpace: TSelectionMask;
    function SelectionToActiveLayerSpace(ASelection: TSelectionMask): TSelectionMask;
    function Composite: TRasterSurface;
    function LayerCount: Integer;
    function UndoDepth: Integer;
    function RedoDepth: Integer;
    function UndoActionLabel(AIndexFromNewest: Integer = 0): string;
    function RedoActionLabel(AIndexFromNewest: Integer = 0): string;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property ActiveLayerIndex: Integer read FActiveLayerIndex write FActiveLayerIndex;
    property ActiveLayer: TRasterLayer read GetActiveLayer;
    property Layers[AIndex: Integer]: TRasterLayer read GetLayer;
    property MaxHistory: Integer read FMaxHistory write FMaxHistory;
    property Selection: TSelectionMask read FSelection;
  end;

implementation

uses
  Math;

constructor TRasterLayer.Create(const AName: string; AWidth, AHeight: Integer; AIsBackground: Boolean);
begin
  inherited Create;
  FName := AName;
  FVisible := True;
  FOpacity := 255;
  FIsBackground := AIsBackground;
  FOffsetX := 0;
  FOffsetY := 0;
  FSurface := TRasterSurface.Create(AWidth, AHeight);
end;

destructor TRasterLayer.Destroy;
begin
  FSurface.Free;
  inherited Destroy;
end;

function TRasterLayer.Clone: TRasterLayer;
begin
  Result := TRasterLayer.Create(FName, FSurface.Width, FSurface.Height, FIsBackground);
  Result.FVisible := FVisible;
  Result.FLocked := FLocked;
  Result.FOpacity := FOpacity;
  Result.FBlendMode := FBlendMode;
  Result.FOffsetX := FOffsetX;
  Result.FOffsetY := FOffsetY;
  Result.Surface.Assign(FSurface);
end;

constructor TDocumentSnapshot.CreateFromDocument(ADocument: TObject);
var
  Document: TImageDocument;
  Index: Integer;
begin
  inherited Create;
  FKind := skFullDocument;
  FRestoreSelectionState := False;
  Document := TImageDocument(ADocument);
  FLayers := TObjectList.Create(True);
  FSelection := Document.Selection.Clone;
  FWidth := Document.Width;
  FHeight := Document.Height;
  FActiveLayerIndex := Document.ActiveLayerIndex;
  for Index := 0 to Document.LayerCount - 1 do
    FLayers.Add(Document.Layers[Index].Clone);
end;

constructor TDocumentSnapshot.CreateFromRegion(
  ADocument: TObject;
  ALayerIndex: Integer;
  const ARect: TRect;
  AIncludeSelectionState: Boolean
);
var
  Doc: TImageDocument;
  W, H: Integer;
begin
  inherited Create;
  FKind := skLayerRegion;
  FRestoreSelectionState := AIncludeSelectionState;
  Doc := TImageDocument(ADocument);
  FRegionLayerIndex := ALayerIndex;
  FDirtyRect := ARect;
  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;
  FRegionSurface := TRasterSurface.Create(Max(1, W), Max(1, H));
  if (ALayerIndex >= 0) and (ALayerIndex < Doc.LayerCount) then
    Doc.Layers[ALayerIndex].Surface.CopyRegionTo(FRegionSurface, ARect.Left, ARect.Top);
  if AIncludeSelectionState then
  begin
    FSelection := Doc.Selection.Clone;
    FActiveLayerIndex := Doc.ActiveLayerIndex;
  end
  else
    FActiveLayerIndex := -1;
end;

constructor TDocumentSnapshot.WrapRegionPixels(
  ALayerIndex: Integer;
  const ARect: TRect;
  APixels: TRasterSurface;
  ASelection: TSelectionMask;
  AActiveLayerIndex: Integer
);
begin
  inherited Create;
  FKind := skLayerRegion;
  FRestoreSelectionState := Assigned(ASelection);
  FRegionLayerIndex := ALayerIndex;
  FDirtyRect := ARect;
  FRegionSurface := APixels;  { take ownership }
  FSelection := ASelection;   { take ownership }
  if FRestoreSelectionState then
    FActiveLayerIndex := AActiveLayerIndex
  else
    FActiveLayerIndex := -1;
end;

destructor TDocumentSnapshot.Destroy;
begin
  FSelection.Free;
  FLayers.Free;
  FRegionSurface.Free;  { nil for full snapshots; non-nil for region snapshots }
  inherited Destroy;
end;

constructor TImageDocument.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FLayers := TObjectList.Create(True);
  FHistory := TObjectList.Create(True);
  FRedo := TObjectList.Create(True);
  FHistoryLabels := TStringList.Create;
  FRedoLabels := TStringList.Create;
  FSelection := TSelectionMask.Create(AWidth, AHeight);
  FMaxHistory := 32;
  NewBlank(AWidth, AHeight);
end;

destructor TImageDocument.Destroy;
begin
  FStoredSelection.Free;
  FSelection.Free;
  FRedoLabels.Free;
  FHistoryLabels.Free;
  FRedo.Free;
  FHistory.Free;
  FLayers.Free;
  inherited Destroy;
end;

function TImageDocument.GetLayer(AIndex: Integer): TRasterLayer;
begin
  Result := TRasterLayer(FLayers[AIndex]);
end;

function TImageDocument.GetActiveLayer: TRasterLayer;
begin
  EnforceLayerInvariant;
  Result := Layers[FActiveLayerIndex];
end;

function TImageDocument.PopSnapshot(AStack: TObjectList): TDocumentSnapshot;
begin
  Result := nil;
  if AStack.Count = 0 then
    Exit;
  Result := TDocumentSnapshot(AStack.Last);
  AStack.Extract(Result);
end;

procedure TImageDocument.ApplySnapshot(ASnapshot: TDocumentSnapshot);
var
  Index: Integer;
begin
  if ASnapshot = nil then
    Exit;

  if ASnapshot.Kind = skLayerRegion then
  begin
    { Region restore: O(dirty_area) only. Restores the saved sub-rectangle of
      one layer; all other layers and selection are left unchanged. }
    if (ASnapshot.RegionLayerIndex >= 0) and (ASnapshot.RegionLayerIndex < FLayers.Count) then
      TRasterLayer(FLayers[ASnapshot.RegionLayerIndex]).Surface.OverwriteRegion(
        ASnapshot.RegionSurface,
        ASnapshot.DirtyRect.Left,
        ASnapshot.DirtyRect.Top);
    if ASnapshot.RestoreSelectionState and Assigned(ASnapshot.Selection) then
    begin
      FSelection.Assign(ASnapshot.Selection);
      FActiveLayerIndex := EnsureRange(ASnapshot.ActiveLayerIndex, 0, Max(0, FLayers.Count - 1));
      EnforceLayerInvariant;
    end;
    Exit;
  end;

  { Full document restore. Transfer layer object ownership from the snapshot
    instead of cloning — saves one O(layers x pixels) copy per undo/redo since
    the caller frees the snapshot immediately after this call. }
  ASnapshot.Layers.OwnsObjects := False;
  FLayers.Clear;
  FWidth := ASnapshot.Width;
  FHeight := ASnapshot.Height;
  for Index := 0 to ASnapshot.Layers.Count - 1 do
    FLayers.Add(ASnapshot.Layers[Index]);
  FSelection.Assign(ASnapshot.Selection);

  FActiveLayerIndex := EnsureRange(ASnapshot.ActiveLayerIndex, 0, Max(0, FLayers.Count - 1));
  EnforceLayerInvariant;
end;

function TImageDocument.BackgroundReplacementColor(const AColor: TRGBA32): TRGBA32;
begin
  Result := RGBA(AColor.R, AColor.G, AColor.B, 255);
end;

function TImageDocument.AnyLayerLocked: Boolean;
var
  LayerIndex: Integer;
begin
  for LayerIndex := 0 to FLayers.Count - 1 do
    if Layers[LayerIndex].Locked then
      Exit(True);
  Result := False;
end;

function TImageDocument.CanMutateActiveLayerPixels: Boolean;
var
  State: TMutationState;
begin
  State.HasActiveLayer := FLayers.Count > 0;
  State.ActiveLayerLocked := State.HasActiveLayer and ActiveLayer.Locked;
  State.HasAnyLayer := FLayers.Count > 0;
  State.AnyLayerLocked := AnyLayerLocked;
  Result := MutationAllowed(State, msActiveLayerPixels);
end;

function TImageDocument.CanMutateDocumentPixels: Boolean;
var
  State: TMutationState;
begin
  State.HasActiveLayer := FLayers.Count > 0;
  State.ActiveLayerLocked := State.HasActiveLayer and ActiveLayer.Locked;
  State.HasAnyLayer := FLayers.Count > 0;
  State.AnyLayerLocked := AnyLayerLocked;
  Result := MutationAllowed(State, msDocumentPixels);
end;

function TImageDocument.CanvasPointToLayerPoint(ALayer: TRasterLayer; X, Y: Integer): TPoint;
begin
  if ALayer = nil then
    Exit(Point(X, Y));
  Result := Point(X - ALayer.OffsetX, Y - ALayer.OffsetY);
end;

function TImageDocument.TranslateSelectionMask(
  ASource: TSelectionMask;
  ADestWidth, ADestHeight: Integer;
  DeltaX, DeltaY: Integer
): TSelectionMask;
begin
  if ASource = nil then
    Exit(nil);
  Result := TSelectionMask.Create(ADestWidth, ADestHeight);
  ASource.TranslateTo(Result, DeltaX, DeltaY);
end;

function TImageDocument.SelectionInLayerSpace(ALayer: TRasterLayer; ASelection: TSelectionMask): TSelectionMask;
begin
  if (ALayer = nil) or (ASelection = nil) then
    Exit(nil);
  if (ALayer.OffsetX = 0) and (ALayer.OffsetY = 0) and
     (ALayer.Surface.Width = ASelection.Width) and
     (ALayer.Surface.Height = ASelection.Height) then
    Exit(ASelection.Clone);
  Result := TranslateSelectionMask(
    ASelection,
    ALayer.Surface.Width,
    ALayer.Surface.Height,
    -ALayer.OffsetX,
    -ALayer.OffsetY
  );
end;

procedure TImageDocument.EnforceLayerInvariant;
begin
  if FLayers.Count = 0 then
  begin
    FLayers.Add(TRasterLayer.Create('Background', FWidth, FHeight, True));
    TRasterLayer(FLayers[0]).Surface.Clear(RGBA(255, 255, 255, 255));
  end;
  FActiveLayerIndex := EnsureRange(FActiveLayerIndex, 0, FLayers.Count - 1);
end;

procedure TImageDocument.NewBlank(AWidth, AHeight: Integer);
begin
  FWidth := Max(1, AWidth);
  FHeight := Max(1, AHeight);
  FLayers.Clear;
  FLayers.Add(TRasterLayer.Create('Background', FWidth, FHeight, True));
  TRasterLayer(FLayers[0]).Surface.Clear(RGBA(255, 255, 255, 255));
  FSelection.SetSize(FWidth, FHeight);
  FSelection.Clear;
  FActiveLayerIndex := 0;
  ClearHistory;
end;

procedure TImageDocument.ReplaceWithSingleLayer(ASurface: TRasterSurface; const ALayerName: string);
var
  Layer: TRasterLayer;
begin
  if ALayerName = '' then
    Layer := TRasterLayer.Create('Layer 1', ASurface.Width, ASurface.Height)
  else
    Layer := TRasterLayer.Create(ALayerName, ASurface.Width, ASurface.Height);

  Layer.Surface.Assign(ASurface);
  FWidth := ASurface.Width;
  FHeight := ASurface.Height;
  FLayers.Clear;
  FLayers.Add(Layer);
  FSelection.SetSize(FWidth, FHeight);
  FSelection.Clear;
  FActiveLayerIndex := 0;
  ClearHistory;
end;

procedure TImageDocument.PushHistory(const ALabel: string);
begin
  FHistory.Add(TDocumentSnapshot.CreateFromDocument(Self));
  FHistoryLabels.Add(ALabel);
  FRedo.Clear;
  FRedoLabels.Clear;
  while FHistory.Count > FMaxHistory do
  begin
    FHistory.Delete(0);
    FHistoryLabels.Delete(0);
  end;
end;

function TImageDocument.BeginActiveLayerMutation(const ALabel: string): Boolean;
begin
  Result := CanMutateActiveLayerPixels;
  if Result then
    PushHistory(ALabel);
end;

function TImageDocument.BeginDocumentMutation(const ALabel: string): Boolean;
begin
  Result := CanMutateDocumentPixels;
  if Result then
    PushHistory(ALabel);
end;

function TImageDocument.MutableActiveLayerSurface: TRasterSurface;
begin
  if CanMutateActiveLayerPixels then
    Result := ActiveLayer.Surface
  else
    Result := nil;
end;

procedure TImageDocument.PushRegionHistory(const ALabel: string; ALayerIndex: Integer; const ADirtyRect: TRect; ABeforePixels: TRasterSurface);
{ Ownership of ABeforePixels is transferred to the new snapshot. }
begin
  FHistory.Add(TDocumentSnapshot.WrapRegionPixels(ALayerIndex, ADirtyRect, ABeforePixels));
  FHistoryLabels.Add(ALabel);
  FRedo.Clear;
  FRedoLabels.Clear;
  while FHistory.Count > FMaxHistory do
  begin
    FHistory.Delete(0);
    FHistoryLabels.Delete(0);
  end;
end;

procedure TImageDocument.PushRegionHistoryWithSelection(
  const ALabel: string;
  ALayerIndex: Integer;
  const ADirtyRect: TRect;
  ABeforePixels: TRasterSurface;
  ASelectionBefore: TSelectionMask;
  AActiveLayerIndexBefore: Integer
);
{ Ownership of ABeforePixels/ASelectionBefore is transferred to the new snapshot. }
begin
  FHistory.Add(
    TDocumentSnapshot.WrapRegionPixels(
      ALayerIndex,
      ADirtyRect,
      ABeforePixels,
      ASelectionBefore,
      AActiveLayerIndexBefore
    )
  );
  FHistoryLabels.Add(ALabel);
  FRedo.Clear;
  FRedoLabels.Clear;
  while FHistory.Count > FMaxHistory do
  begin
    FHistory.Delete(0);
    FHistoryLabels.Delete(0);
  end;
end;

function TImageDocument.CanUndo: Boolean;
begin
  Result := FHistory.Count > 0;
end;

function TImageDocument.CanRedo: Boolean;
begin
  Result := FRedo.Count > 0;
end;

procedure TImageDocument.Undo;
var
  Snapshot: TDocumentSnapshot;
  RedoSnapshot: TDocumentSnapshot;
  ActionLabel: string;
begin
  if not CanUndo then
    Exit;
  ActionLabel := UndoActionLabel;
  { Allocate redo snapshot before mutating stacks to avoid losing undo entry on OOM. }
  Snapshot := TDocumentSnapshot(FHistory[FHistory.Count - 1]);
  if Snapshot.Kind = skLayerRegion then
    RedoSnapshot := TDocumentSnapshot.CreateFromRegion(
      Self,
      Snapshot.RegionLayerIndex,
      Snapshot.DirtyRect,
      Snapshot.RestoreSelectionState
    )
  else
    RedoSnapshot := TDocumentSnapshot.CreateFromDocument(Self);

  FRedo.Add(RedoSnapshot);
  FRedoLabels.Add(ActionLabel);
  Snapshot := PopSnapshot(FHistory);
  FHistoryLabels.Delete(FHistoryLabels.Count - 1);
  try
    ApplySnapshot(Snapshot);
  finally
    Snapshot.Free;
  end;
end;

procedure TImageDocument.Redo;
var
  Snapshot: TDocumentSnapshot;
  UndoSnapshot: TDocumentSnapshot;
  ActionLabel: string;
begin
  if not CanRedo then
    Exit;
  ActionLabel := RedoActionLabel;
  { Allocate undo snapshot before mutating stacks to avoid losing redo entry on OOM. }
  Snapshot := TDocumentSnapshot(FRedo[FRedo.Count - 1]);
  if Snapshot.Kind = skLayerRegion then
    UndoSnapshot := TDocumentSnapshot.CreateFromRegion(
      Self,
      Snapshot.RegionLayerIndex,
      Snapshot.DirtyRect,
      Snapshot.RestoreSelectionState
    )
  else
    UndoSnapshot := TDocumentSnapshot.CreateFromDocument(Self);

  FHistory.Add(UndoSnapshot);
  FHistoryLabels.Add(ActionLabel);
  Snapshot := PopSnapshot(FRedo);
  FRedoLabels.Delete(FRedoLabels.Count - 1);
  try
    ApplySnapshot(Snapshot);
  finally
    Snapshot.Free;
  end;
end;

procedure TImageDocument.ClearHistory;
begin
  FHistory.Clear;
  FRedo.Clear;
  FHistoryLabels.Clear;
  FRedoLabels.Clear;
end;

function TImageDocument.AddLayer(const AName: string): TRasterLayer;
var
  LayerName: string;
begin
  if AName = '' then
    LayerName := Format('Layer %d', [FLayers.Count + 1])
  else
    LayerName := AName;
  Result := TRasterLayer.Create(LayerName, FWidth, FHeight);
  FLayers.Add(Result);
  FActiveLayerIndex := FLayers.Count - 1;
end;

procedure TImageDocument.MoveLayer(AFromIndex, AToIndex: Integer);
var
  LayerObject: TObject;
begin
  if (AFromIndex < 0) or (AFromIndex >= FLayers.Count) then
    Exit;
  if Layers[AFromIndex].IsBackground then
    Exit;
  AToIndex := EnsureRange(AToIndex, 0, FLayers.Count - 1);
  if (AToIndex = 0) and (FLayers.Count > 0) and Layers[0].IsBackground then
    AToIndex := 1;
  if AFromIndex = AToIndex then
    Exit;

  LayerObject := TObject(FLayers[AFromIndex]);
  FLayers.Extract(LayerObject);
  FLayers.Insert(AToIndex, LayerObject);

  if FActiveLayerIndex = AFromIndex then
    FActiveLayerIndex := AToIndex
  else if (FActiveLayerIndex > AFromIndex) and (FActiveLayerIndex <= AToIndex) then
    Dec(FActiveLayerIndex)
  else if (FActiveLayerIndex < AFromIndex) and (FActiveLayerIndex >= AToIndex) then
    Inc(FActiveLayerIndex);
end;

procedure TImageDocument.RenameLayer(AIndex: Integer; const AName: string);
begin
  if (AIndex < 0) or (AIndex >= FLayers.Count) then
    Exit;
  if Trim(AName) = '' then
    Exit;
  Layers[AIndex].Name := AName;
end;

procedure TImageDocument.SetLayerVisibility(AIndex: Integer; AVisible: Boolean);
begin
  if (AIndex < 0) or (AIndex >= FLayers.Count) then
    Exit;
  Layers[AIndex].Visible := AVisible;
end;

procedure TImageDocument.SetLayerOpacity(AIndex: Integer; AOpacity: Byte);
begin
  if (AIndex < 0) or (AIndex >= FLayers.Count) then
    Exit;
  Layers[AIndex].Opacity := AOpacity;
end;

procedure TImageDocument.DuplicateActiveLayer;
var
  LayerCopy: TRasterLayer;
begin
  LayerCopy := ActiveLayer.Clone;
  LayerCopy.IsBackground := False;
  LayerCopy.Name := ActiveLayer.Name + ' Copy';
  FLayers.Insert(FActiveLayerIndex + 1, LayerCopy);
  Inc(FActiveLayerIndex);
end;

procedure TImageDocument.DeleteActiveLayer;
begin
  if ActiveLayer.IsBackground then
    Exit;
  if FLayers.Count <= 1 then
  begin
    if not CanMutateActiveLayerPixels then
      Exit;
    ActiveLayer.Surface.Clear(TransparentColor);
    Exit;
  end;
  FLayers.Delete(FActiveLayerIndex);
  FActiveLayerIndex := EnsureRange(FActiveLayerIndex - 1, 0, FLayers.Count - 1);
  EnforceLayerInvariant;
end;

procedure TImageDocument.MergeDown;
var
  TopLayer: TRasterLayer;
  BottomLayer: TRasterLayer;
  LocalX: Integer;
  LocalY: Integer;
  CanvasX: Integer;
  CanvasY: Integer;
  BottomX: Integer;
  BottomY: Integer;
begin
  if not CanMutateDocumentPixels then
    Exit;
  if FActiveLayerIndex <= 0 then
    Exit;

  TopLayer := Layers[FActiveLayerIndex];
  BottomLayer := Layers[FActiveLayerIndex - 1];
  for LocalY := 0 to TopLayer.Surface.Height - 1 do
    for LocalX := 0 to TopLayer.Surface.Width - 1 do
    begin
      CanvasX := LocalX + TopLayer.OffsetX;
      CanvasY := LocalY + TopLayer.OffsetY;
      BottomX := CanvasX - BottomLayer.OffsetX;
      BottomY := CanvasY - BottomLayer.OffsetY;
      if not BottomLayer.Surface.InBounds(BottomX, BottomY) then
        Continue;
      BottomLayer.Surface.BlendPixelPremul(BottomX, BottomY, TopLayer.Surface[LocalX, LocalY], TopLayer.Opacity);
    end;

  BottomLayer.Name := BottomLayer.Name + ' + ' + TopLayer.Name;
  FLayers.Delete(FActiveLayerIndex);
  Dec(FActiveLayerIndex);
end;

procedure TImageDocument.Flatten;
var
  CompositeSurface: TRasterSurface;
  FlattenedSurface: TRasterSurface;
begin
  if not CanMutateDocumentPixels then
    Exit;
  CompositeSurface := Composite;
  try
    FlattenedSurface := TRasterSurface.Create(CompositeSurface.Width, CompositeSurface.Height);
    try
      FlattenedSurface.Clear(RGBA(255, 255, 255, 255));
      FlattenedSurface.PasteSurface(CompositeSurface, 0, 0, 255);
      FLayers.Clear;
      FLayers.Add(TRasterLayer.Create('Background', FlattenedSurface.Width, FlattenedSurface.Height, True));
      TRasterLayer(FLayers[0]).Surface.Assign(FlattenedSurface);
      FWidth := FlattenedSurface.Width;
      FHeight := FlattenedSurface.Height;
      FSelection.SetSize(FWidth, FHeight);
      FSelection.Clear;
      FActiveLayerIndex := 0;
      ClearHistory;
    finally
      FlattenedSurface.Free;
    end;
  finally
    CompositeSurface.Free;
  end;
end;

procedure TImageDocument.Crop(X, Y, AWidth, AHeight: Integer);
var
  LayerIndex: Integer;
  Layer: TRasterLayer;
  LocalCropX: Integer;
  LocalCropY: Integer;
  Cropped: TRasterSurface;
  CroppedSelection: TSelectionMask;
begin
  if not CanMutateDocumentPixels then
    Exit;
  AWidth := Max(1, AWidth);
  AHeight := Max(1, AHeight);
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Layer := Layers[LayerIndex];
    LocalCropX := X - Layer.OffsetX;
    LocalCropY := Y - Layer.OffsetY;
    Cropped := Layer.Surface.Crop(LocalCropX, LocalCropY, AWidth, AHeight);
    try
      Layer.Surface.Assign(Cropped);
      { Crop() already remaps each layer into the new document-local
        coordinate space [0..AWidth/Height). Keeping an extra translated
        layer offset here would double-apply the crop origin shift and can
        move all drawable content outside the visible canvas. }
      Layer.OffsetX := 0;
      Layer.OffsetY := 0;
    finally
      Cropped.Free;
    end;
  end;
  FWidth := AWidth;
  FHeight := AHeight;
  CroppedSelection := FSelection.Crop(X, Y, AWidth, AHeight);
  try
    FSelection.Assign(CroppedSelection);
  finally
    CroppedSelection.Free;
  end;
end;

procedure TImageDocument.ResizeImageNearest(ANewWidth, ANewHeight: Integer);
begin
  ResizeImage(ANewWidth, ANewHeight, rmNearestNeighbor);
end;

procedure TImageDocument.ResizeImage(ANewWidth, ANewHeight: Integer; AResampleMode: TResampleMode);
var
  LayerIndex: Integer;
  OldWidth: Integer;
  OldHeight: Integer;
  Resized: TRasterSurface;
  ResizedSelection: TSelectionMask;
begin
  if not CanMutateDocumentPixels then
    Exit;
  OldWidth := FWidth;
  OldHeight := FHeight;
  ANewWidth := Max(1, ANewWidth);
  ANewHeight := Max(1, ANewHeight);
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    case AResampleMode of
      rmBilinear:
        Resized := Layers[LayerIndex].Surface.ResizeBilinear(ANewWidth, ANewHeight);
    else
      Resized := Layers[LayerIndex].Surface.ResizeNearest(ANewWidth, ANewHeight);
    end;
    try
      Layers[LayerIndex].Surface.Assign(Resized);
      Layers[LayerIndex].OffsetX := Round((Layers[LayerIndex].OffsetX * ANewWidth) / Max(1, OldWidth));
      Layers[LayerIndex].OffsetY := Round((Layers[LayerIndex].OffsetY * ANewHeight) / Max(1, OldHeight));
    finally
      Resized.Free;
    end;
  end;
  FWidth := ANewWidth;
  FHeight := ANewHeight;
  ResizedSelection := FSelection.ResizeNearest(ANewWidth, ANewHeight);
  try
    FSelection.Assign(ResizedSelection);
  finally
    ResizedSelection.Free;
  end;
end;

procedure TImageDocument.ResizeCanvas(ANewWidth, ANewHeight: Integer);
begin
  Crop(0, 0, ANewWidth, ANewHeight);
end;

procedure TImageDocument.FlipHorizontal;
var
  LayerIndex: Integer;
  Layer: TRasterLayer;
begin
  if not CanMutateDocumentPixels then
    Exit;
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Layer := Layers[LayerIndex];
    Layer.Surface.FlipHorizontal;
    Layer.OffsetX := (FWidth - Layer.Surface.Width) - Layer.OffsetX;
  end;
  FSelection.FlipHorizontal;
end;

procedure TImageDocument.FlipVertical;
var
  LayerIndex: Integer;
  Layer: TRasterLayer;
begin
  if not CanMutateDocumentPixels then
    Exit;
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Layer := Layers[LayerIndex];
    Layer.Surface.FlipVertical;
    Layer.OffsetY := (FHeight - Layer.Surface.Height) - Layer.OffsetY;
  end;
  FSelection.FlipVertical;
end;

procedure TImageDocument.Rotate180;
begin
  if not CanMutateDocumentPixels then
    Exit;
  FlipHorizontal;
  FlipVertical;
end;

procedure TImageDocument.Rotate90Clockwise;
var
  LayerIndex: Integer;
  Layer: TRasterLayer;
  PreviousOffsetX: Integer;
  PreviousOffsetY: Integer;
  PreviousCanvasWidth: Integer;
  PreviousCanvasHeight: Integer;
  TempSize: Integer;
begin
  if not CanMutateDocumentPixels then
    Exit;
  PreviousCanvasWidth := FWidth;
  PreviousCanvasHeight := FHeight;
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Layer := Layers[LayerIndex];
    PreviousOffsetX := Layer.OffsetX;
    PreviousOffsetY := Layer.OffsetY;
    Layer.Surface.Rotate90Clockwise;
    Layer.OffsetX := PreviousCanvasHeight - PreviousOffsetY - Layer.Surface.Width;
    Layer.OffsetY := PreviousOffsetX;
  end;
  FSelection.Rotate90Clockwise;
  TempSize := PreviousCanvasWidth;
  FWidth := PreviousCanvasHeight;
  FHeight := TempSize;
end;

procedure TImageDocument.Rotate90CounterClockwise;
var
  LayerIndex: Integer;
  Layer: TRasterLayer;
  PreviousOffsetX: Integer;
  PreviousOffsetY: Integer;
  PreviousCanvasWidth: Integer;
  PreviousCanvasHeight: Integer;
  TempSize: Integer;
begin
  if not CanMutateDocumentPixels then
    Exit;
  PreviousCanvasWidth := FWidth;
  PreviousCanvasHeight := FHeight;
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Layer := Layers[LayerIndex];
    PreviousOffsetX := Layer.OffsetX;
    PreviousOffsetY := Layer.OffsetY;
    Layer.Surface.Rotate90CounterClockwise;
    Layer.OffsetX := PreviousOffsetY;
    Layer.OffsetY := PreviousCanvasWidth - PreviousOffsetX - Layer.Surface.Height;
  end;
  FSelection.Rotate90CounterClockwise;
  TempSize := PreviousCanvasWidth;
  FWidth := PreviousCanvasHeight;
  FHeight := TempSize;
end;

procedure TImageDocument.Deselect;
begin
  FSelection.Clear;
end;

procedure TImageDocument.SelectAll;
begin
  FSelection.SelectAll;
end;

procedure TImageDocument.InvertSelection;
begin
  FSelection.Invert;
end;

procedure TImageDocument.SelectRectangle(
  X1, Y1, X2, Y2: Integer;
  AMode: TSelectionCombineMode;
  AAntiAlias: Boolean
);
begin
  FSelection.SelectRectangle(X1, Y1, X2, Y2, AMode, AAntiAlias);
end;

procedure TImageDocument.SelectEllipse(
  X1, Y1, X2, Y2: Integer;
  AMode: TSelectionCombineMode;
  AAntiAlias: Boolean
);
begin
  FSelection.SelectEllipse(X1, Y1, X2, Y2, AMode, AAntiAlias);
end;

procedure TImageDocument.SelectLasso(
  const APoints: array of TPoint;
  AMode: TSelectionCombineMode;
  AAntiAlias: Boolean
);
begin
  FSelection.SelectPolygon(APoints, AMode, AAntiAlias);
end;

procedure TImageDocument.SelectMagicWand(X, Y: Integer; Tolerance: Byte; AMode: TSelectionCombineMode; UseAllLayers: Boolean; Contiguous: Boolean);
var
  SelectionFromWand: TSelectionMask;
  SelectionInCanvasSpace: TSelectionMask;
  SelectX: Integer;
  SelectY: Integer;
  Coverage: Byte;
  ExistingCoverage: Byte;
  SamplePoint: TPoint;
  SampleSurface: TRasterSurface;
  OwnsSampleSurface: Boolean;
begin
  if UseAllLayers then
  begin
    SampleSurface := Composite;
    OwnsSampleSurface := True;
    SamplePoint := Point(X, Y);
  end
  else
  begin
    SampleSurface := ActiveLayer.Surface;
    OwnsSampleSurface := False;
    SamplePoint := CanvasPointToLayerPoint(ActiveLayer, X, Y);
  end;
  if Contiguous then
    SelectionFromWand := SampleSurface.CreateContiguousSelection(SamplePoint.X, SamplePoint.Y, Tolerance)
  else
    SelectionFromWand := SampleSurface.CreateGlobalColorSelection(SamplePoint.X, SamplePoint.Y, Tolerance);
  if OwnsSampleSurface then
    SampleSurface.Free;
  try
    if not UseAllLayers then
    begin
      SelectionInCanvasSpace := TranslateSelectionMask(
        SelectionFromWand,
        FSelection.Width,
        FSelection.Height,
        ActiveLayer.OffsetX,
        ActiveLayer.OffsetY
      );
      SelectionFromWand.Free;
      SelectionFromWand := SelectionInCanvasSpace;
    end;

    case AMode of
      scReplace:
        begin
          FSelection.Assign(SelectionFromWand);
          Exit;
        end;
      scIntersect:
        begin
          FSelection.IntersectWith(SelectionFromWand);
          Exit;
        end;
    end;

    for SelectY := 0 to Min(FSelection.Height, SelectionFromWand.Height) - 1 do
      for SelectX := 0 to Min(FSelection.Width, SelectionFromWand.Width) - 1 do
      begin
        Coverage := SelectionFromWand.Coverage(SelectX, SelectY);
        if Coverage = 0 then
          Continue;
        ExistingCoverage := FSelection.Coverage(SelectX, SelectY);
        case AMode of
          scAdd:
            if Coverage > ExistingCoverage then
              FSelection.SetCoverage(SelectX, SelectY, Coverage);
          scSubtract:
            if Coverage >= ExistingCoverage then
              FSelection.SetCoverage(SelectX, SelectY, 0)
            else
              FSelection.SetCoverage(SelectX, SelectY, ExistingCoverage - Coverage);
        end;
      end;
  finally
    SelectionFromWand.Free;
  end;
end;

function TImageDocument.CopySelectionToSurface(ACropToBounds: Boolean): TRasterSurface;
var
  Copied: TRasterSurface;
  LocalSelection: TSelectionMask;
  Bounds: TRect;
  LocalBounds: TRect;
begin
  if not FSelection.HasSelection then
    Exit(ActiveLayer.Surface.Clone);

  { Keep a structural snapshot for "Paste Selection (Replace)" routes whenever
    copy/cut is selection-scoped, so app paths do not need to remember this. }
  StoreSelectionForPaste;
  LocalSelection := SelectionInLayerSpace(ActiveLayer, FSelection);
  try
    Copied := ActiveLayer.Surface.CopySelection(LocalSelection);
    if not ACropToBounds then
      Exit(Copied);
    try
      Bounds := FSelection.BoundsRect;
      LocalBounds.Left := Bounds.Left - ActiveLayer.OffsetX;
      LocalBounds.Top := Bounds.Top - ActiveLayer.OffsetY;
      LocalBounds.Right := Bounds.Right - ActiveLayer.OffsetX;
      LocalBounds.Bottom := Bounds.Bottom - ActiveLayer.OffsetY;
      Result := Copied.Crop(
        LocalBounds.Left,
        LocalBounds.Top,
        LocalBounds.Right - LocalBounds.Left,
        LocalBounds.Bottom - LocalBounds.Top
      );
    finally
      Copied.Free;
    end;
  finally
    LocalSelection.Free;
  end;
end;

function TImageDocument.CopyMergedToSurface(ACropToBounds: Boolean): TRasterSurface;
var
  CompositeSurface: TRasterSurface;
  Copied: TRasterSurface;
  Bounds: TRect;
begin
  if not FSelection.HasSelection then
    Exit(Composite);

  { Same selection-store contract as layer-only copy path. }
  StoreSelectionForPaste;
  CompositeSurface := Composite;
  try
    Copied := CompositeSurface.CopySelection(FSelection);
    if not ACropToBounds then
      Exit(Copied);

    try
      Bounds := FSelection.BoundsRect;
      Result := Copied.Crop(Bounds.Left, Bounds.Top, Bounds.Right - Bounds.Left, Bounds.Bottom - Bounds.Top);
    finally
      Copied.Free;
    end;
  finally
    CompositeSurface.Free;
  end;
end;

function TImageDocument.CutSelectionToSurface(ACropToBounds: Boolean): TRasterSurface;
begin
  Result := CutSelectionToSurface(ACropToBounds, RGBA(255, 255, 255, 255));
end;

function TImageDocument.CutSelectionToSurface(ACropToBounds: Boolean; const ABackgroundColor: TRGBA32): TRasterSurface;
var
  LocalSelection: TSelectionMask;
begin
  Result := CopySelectionToSurface(ACropToBounds);
  if not CanMutateActiveLayerPixels then
    Exit;
  if FSelection.HasSelection then
  begin
    LocalSelection := SelectionInLayerSpace(ActiveLayer, FSelection);
    try
    if ActiveLayer.IsBackground then
        ActiveLayer.Surface.FillSelection(LocalSelection, BackgroundReplacementColor(ABackgroundColor), 255)
    else
        ActiveLayer.Surface.EraseSelection(LocalSelection);
    finally
      LocalSelection.Free;
    end;
  end
  else if ActiveLayer.IsBackground then
    ActiveLayer.Surface.Clear(BackgroundReplacementColor(ABackgroundColor))
  else
    ActiveLayer.Surface.Clear(TransparentColor);
end;

procedure TImageDocument.PasteAsNewLayer(ASurface: TRasterSurface; OffsetX, OffsetY: Integer; const ALayerName: string);
var
  Layer: TRasterLayer;
begin
  if ASurface = nil then
    Exit;
  Layer := AddLayer(ALayerName);
  Layer.OffsetX := OffsetX;
  Layer.OffsetY := OffsetY;
  Layer.Surface.PasteSurface(ASurface, 0, 0);
end;

procedure TImageDocument.PasteSurfaceToActiveLayer(ASurface: TRasterSurface;
  OffsetX, OffsetY: Integer; Opacity: Byte; ASelection: TSelectionMask);
var
  LocalSelection: TSelectionMask;
begin
  if (ASurface = nil) or not CanMutateActiveLayerPixels then
    Exit;
  LocalSelection := SelectionInLayerSpace(ActiveLayer, ASelection);
  try
    ActiveLayer.Surface.PasteSurface(ASurface, OffsetX, OffsetY, Opacity, LocalSelection);
  finally
    LocalSelection.Free;
  end;
end;

procedure TImageDocument.FillSelection(const AColor: TRGBA32; Opacity: Byte);
var
  LocalSelection: TSelectionMask;
begin
  if not FSelection.HasSelection then
    Exit;
  if not CanMutateActiveLayerPixels then
    Exit;
  LocalSelection := SelectionInLayerSpace(ActiveLayer, FSelection);
  try
    ActiveLayer.Surface.FillSelection(LocalSelection, AColor, Opacity);
  finally
    LocalSelection.Free;
  end;
end;

procedure TImageDocument.EraseSelection;
begin
  EraseSelection(RGBA(255, 255, 255, 255));
end;

procedure TImageDocument.EraseSelection(const ABackgroundColor: TRGBA32);
var
  LocalSelection: TSelectionMask;
begin
  if not FSelection.HasSelection then
    Exit;
  if not CanMutateActiveLayerPixels then
    Exit;
  LocalSelection := SelectionInLayerSpace(ActiveLayer, FSelection);
  try
  if ActiveLayer.IsBackground then
      ActiveLayer.Surface.FillSelection(LocalSelection, BackgroundReplacementColor(ABackgroundColor), 255)
  else
      ActiveLayer.Surface.EraseSelection(LocalSelection);
  finally
    LocalSelection.Free;
  end;
end;

procedure TImageDocument.MoveSelectionBy(DeltaX, DeltaY: Integer);
begin
  if not FSelection.HasSelection then
    Exit;
  FSelection.MoveBy(DeltaX, DeltaY);
end;

procedure TImageDocument.MoveSelectedPixelsBy(DeltaX, DeltaY: Integer);
begin
  MoveSelectedPixelsBy(DeltaX, DeltaY, RGBA(255, 255, 255, 255));
end;

procedure TImageDocument.MoveSelectedPixelsBy(DeltaX, DeltaY: Integer; const ABackgroundColor: TRGBA32);
var
  LocalSelection: TSelectionMask;
  Copied: TRasterSurface;
  X: Integer;
  Y: Integer;
  TargetX: Integer;
  TargetY: Integer;
  Coverage: Byte;
begin
  if not FSelection.HasSelection then
    Exit;
  if not CanMutateActiveLayerPixels then
    Exit;
  LocalSelection := SelectionInLayerSpace(ActiveLayer, FSelection);
  try
  if not ActiveLayer.IsBackground then
  begin
      ActiveLayer.Surface.MoveSelectedPixels(LocalSelection, DeltaX, DeltaY);
    FSelection.MoveBy(DeltaX, DeltaY);
      Exit;
  end;

    Copied := ActiveLayer.Surface.CopySelection(LocalSelection);
  try
      ActiveLayer.Surface.FillSelection(LocalSelection, BackgroundReplacementColor(ABackgroundColor), 255);
      for Y := 0 to Min(ActiveLayer.Surface.Height, LocalSelection.Height) - 1 do
        for X := 0 to Min(ActiveLayer.Surface.Width, LocalSelection.Width) - 1 do
      begin
          Coverage := LocalSelection.Coverage(X, Y);
        if Coverage = 0 then
          Continue;
        TargetX := X + DeltaX;
        TargetY := Y + DeltaY;
        if ActiveLayer.Surface.InBounds(TargetX, TargetY) then
        begin
          if Copied[X, Y].A > 0 then
            ActiveLayer.Surface.BlendPixelPremul(TargetX, TargetY, Copied[X, Y], 255);
        end;
      end;
    finally
      Copied.Free;
    end;
    FSelection.MoveBy(DeltaX, DeltaY);
  finally
    LocalSelection.Free;
  end;
end;

procedure TImageDocument.PixelateRect(X1, Y1, X2, Y2: Integer; BlockSize: Integer; ASelection: TSelectionMask);
var
  LocalStart: TPoint;
  LocalEnd: TPoint;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  LocalStart := CanvasPointToLayerPoint(ActiveLayer, X1, Y1);
  LocalEnd := CanvasPointToLayerPoint(ActiveLayer, X2, Y2);
  ActiveLayer.Surface.PixelateRect(LocalStart.X, LocalStart.Y, LocalEnd.X, LocalEnd.Y, BlockSize, ASelection);
end;

procedure TImageDocument.RotateActiveLayer90Clockwise;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Rotate90Clockwise;
end;

procedure TImageDocument.RotateActiveLayer90CounterClockwise;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Rotate90CounterClockwise;
end;

procedure TImageDocument.RotateActiveLayer180;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Rotate180;
end;

procedure TImageDocument.CropToSelection;
var
  Bounds: TRect;
begin
  if not FSelection.HasSelection then
    Exit;
  if not CanMutateDocumentPixels then
    Exit;
  Bounds := FSelection.BoundsRect;
  Crop(Bounds.Left, Bounds.Top, Bounds.Right - Bounds.Left, Bounds.Bottom - Bounds.Top);
end;

procedure TImageDocument.AutoLevel;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AutoLevel;
end;

procedure TImageDocument.InvertColors;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.InvertColors;
end;

procedure TImageDocument.Grayscale;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Grayscale;
end;

procedure TImageDocument.AdjustHueSaturation(HueDelta: Integer; SaturationDelta: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AdjustHueSaturation(HueDelta, SaturationDelta);
end;

procedure TImageDocument.AdjustGammaCurve(Gamma: Double);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AdjustGammaCurve(Gamma);
end;

procedure TImageDocument.AdjustLevels(InputLow, InputHigh, OutputLow, OutputHigh: Byte);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AdjustLevels(InputLow, InputHigh, OutputLow, OutputHigh);
end;

procedure TImageDocument.AdjustBrightness(Delta: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AdjustBrightness(Delta);
end;

procedure TImageDocument.AdjustContrast(Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AdjustContrast(Amount);
end;

procedure TImageDocument.Sepia;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Sepia;
end;

procedure TImageDocument.BlackAndWhite(Threshold: Byte);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.BlackAndWhite(Threshold);
end;

procedure TImageDocument.Posterize(Levels: Byte);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Posterize(Levels);
end;

procedure TImageDocument.BoxBlur(Radius: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.BoxBlur(Radius);
end;

procedure TImageDocument.Sharpen;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Sharpen;
end;

procedure TImageDocument.AddNoise(Amount: Byte; Seed: Cardinal);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.AddNoise(Amount, Seed);
end;

procedure TImageDocument.DetectEdges;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.DetectEdges;
end;

procedure TImageDocument.Emboss;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Emboss;
end;

procedure TImageDocument.Soften;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Soften;
end;

procedure TImageDocument.RenderClouds(Seed: Cardinal);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.RenderClouds(Seed);
end;

procedure TImageDocument.Pixelate(BlockSize: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Pixelate(BlockSize);
end;

procedure TImageDocument.Vignette(Strength: Double);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Vignette(Strength);
end;

procedure TImageDocument.MotionBlur(Angle: Integer; Distance: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.MotionBlur(Angle, Distance);
end;

procedure TImageDocument.MedianFilter(Radius: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.MedianFilter(Radius);
end;

procedure TImageDocument.OutlineEffect(const AOutlineColor: TRGBA32; Threshold: Byte);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.OutlineEffect(AOutlineColor, Threshold);
end;

procedure TImageDocument.GlowEffect(Radius: Integer; Intensity: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.GlowEffect(Radius, Intensity);
end;

procedure TImageDocument.OilPaint(Radius: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.OilPaint(Radius);
end;

procedure TImageDocument.FrostedGlass(Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.FrostedGlass(Amount);
end;

procedure TImageDocument.ZoomBlur(CenterX: Integer; CenterY: Integer; Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.ZoomBlur(CenterX, CenterY, Amount);
end;

procedure TImageDocument.GaussianBlur(Radius: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.GaussianBlur(Radius);
end;

procedure TImageDocument.Unfocus(Radius: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Unfocus(Radius);
end;

procedure TImageDocument.SurfaceBlur(Radius: Integer; Threshold: Byte);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.SurfaceBlur(Radius, Threshold);
end;

procedure TImageDocument.RadialBlur(Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.RadialBlur(Amount);
end;

procedure TImageDocument.Twist(Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Twist(Amount);
end;

procedure TImageDocument.Fragment(Offset: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Fragment(Offset);
end;

procedure TImageDocument.Bulge(Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Bulge(Amount);
end;

procedure TImageDocument.Dents(Amount: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Dents(Amount);
end;

procedure TImageDocument.Relief(Angle: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Relief(Angle);
end;

procedure TImageDocument.RedEye(Threshold: Byte; Strength: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.RedEye(Threshold, Strength);
end;

procedure TImageDocument.TileReflection(TileSize: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.TileReflection(TileSize);
end;

procedure TImageDocument.Crystallize(CellSize: Integer; Seed: Cardinal);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.Crystallize(CellSize, Seed);
end;

procedure TImageDocument.InkSketch(InkStrength: Integer; Coloring: Integer);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.InkSketch(InkStrength, Coloring);
end;

procedure TImageDocument.RenderMandelbrot(Iterations: Integer; Zoom: Double);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.RenderMandelbrot(Iterations, Zoom);
end;

procedure TImageDocument.RenderJulia(Iterations: Integer; Zoom: Double; CReal: Double; CImag: Double);
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  ActiveLayer.Surface.RenderJulia(Iterations, Zoom, CReal, CImag);
end;

procedure TImageDocument.RecolorBrush(
  X, Y, Radius: Integer;
  SourceColor, NewColor: TRGBA32;
  Tolerance: Byte;
  Opacity: Byte;
  PreserveValue: Boolean;
  ASelection: TSelectionMask;
  Mode: TRecolorBlendMode
);
var
  LocalSelection: TSelectionMask;
  LocalPoint: TPoint;
begin
  if not CanMutateActiveLayerPixels then
    Exit;
  LocalSelection := SelectionInLayerSpace(ActiveLayer, ASelection);
  try
    LocalPoint := CanvasPointToLayerPoint(ActiveLayer, X, Y);
    ActiveLayer.Surface.RecolorBrush(
      LocalPoint.X,
      LocalPoint.Y,
      Radius,
      SourceColor,
      NewColor,
      Tolerance,
      Opacity,
      PreserveValue,
      LocalSelection,
      Mode
    );
  finally
    LocalSelection.Free;
  end;
end;

function TImageDocument.ActiveSelectionInLayerSpace: TSelectionMask;
begin
  if not HasSelection then
    Exit(nil);
  Result := SelectionInLayerSpace(ActiveLayer, FSelection);
end;

function TImageDocument.SelectionToActiveLayerSpace(ASelection: TSelectionMask): TSelectionMask;
begin
  Result := SelectionInLayerSpace(ActiveLayer, ASelection);
end;

function TImageDocument.HasStoredSelection: Boolean;
begin
  Result := FHasStoredSelection and (FStoredSelection <> nil);
end;

procedure TImageDocument.StoreSelectionForPaste;
begin
  FStoredSelection.Free;
  FStoredSelection := FSelection.Clone;
  FHasStoredSelection := True;
end;

procedure TImageDocument.PasteStoredSelection;
begin
  if not HasStoredSelection then
    Exit;
  PushHistory('Paste Selection');
  FSelection.Assign(FStoredSelection);
end;

function TImageDocument.HasSelection: Boolean;
begin
  Result := FSelection.HasSelection;
end;

function TImageDocument.Composite: TRasterSurface;
var
  ResultSurface: TRasterSurface;
  LayerIndex: Integer;
  LocalX: Integer;
  LocalY: Integer;
  CanvasX: Integer;
  CanvasY: Integer;
  Layer: TRasterLayer;
  Dst, Src, SrcStraight, DstStraight: TRGBA32;
  Opacity: Integer;
  Dr, Dg, Db: Integer;
  Sr, Sg, Sb: Integer;
begin
  ResultSurface := TRasterSurface.Create(FWidth, FHeight);
  ResultSurface.Clear(TransparentColor);

  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Layer := Layers[LayerIndex];
    if not Layer.Visible then
      Continue;
    Opacity := Layer.Opacity;
    if Layer.BlendMode = bmNormal then
    begin
      for LocalY := 0 to Layer.Surface.Height - 1 do
      begin
        CanvasY := LocalY + Layer.OffsetY;
        if (CanvasY < 0) or (CanvasY >= FHeight) then
          Continue;
        for LocalX := 0 to Layer.Surface.Width - 1 do
        begin
          CanvasX := LocalX + Layer.OffsetX;
          if (CanvasX < 0) or (CanvasX >= FWidth) then
            Continue;
          ResultSurface.BlendPixelPremul(CanvasX, CanvasY, Layer.Surface[LocalX, LocalY], Opacity);
        end;
      end;
    end
    else
    begin
      for LocalY := 0 to Layer.Surface.Height - 1 do
      begin
        CanvasY := LocalY + Layer.OffsetY;
        if (CanvasY < 0) or (CanvasY >= FHeight) then
          Continue;
        for LocalX := 0 to Layer.Surface.Width - 1 do
        begin
          CanvasX := LocalX + Layer.OffsetX;
          if (CanvasX < 0) or (CanvasX >= FWidth) then
            Continue;
          Src := Layer.Surface[LocalX, LocalY];
          if Src.A = 0 then
            Continue;
          Dst := ResultSurface[CanvasX, CanvasY];
          { Unpremultiply to get straight-alpha values for blend mode formulas }
          SrcStraight := Unpremultiply(Src);
          DstStraight := Unpremultiply(Dst);
          Dr := DstStraight.R; Dg := DstStraight.G; Db := DstStraight.B;
          Sr := SrcStraight.R; Sg := SrcStraight.G; Sb := SrcStraight.B;
          case Layer.BlendMode of
            bmMultiply:
            begin
              Sr := (Dr * Sr) div 255;
              Sg := (Dg * Sg) div 255;
              Sb := (Db * Sb) div 255;
            end;
            bmScreen:
            begin
              Sr := Dr + Sr - (Dr * Sr) div 255;
              Sg := Dg + Sg - (Dg * Sg) div 255;
              Sb := Db + Sb - (Db * Sb) div 255;
            end;
            bmOverlay:
            begin
              if Dr < 128 then Sr := (2 * Dr * Sr) div 255
              else Sr := 255 - 2 * ((255 - Dr) * (255 - Sr)) div 255;
              if Dg < 128 then Sg := (2 * Dg * Sg) div 255
              else Sg := 255 - 2 * ((255 - Dg) * (255 - Sg)) div 255;
              if Db < 128 then Sb := (2 * Db * Sb) div 255
              else Sb := 255 - 2 * ((255 - Db) * (255 - Sb)) div 255;
            end;
            bmDarken:
            begin
              if Dr < Sr then Sr := Dr;
              if Dg < Sg then Sg := Dg;
              if Db < Sb then Sb := Db;
            end;
            bmLighten:
            begin
              if Dr > Sr then Sr := Dr;
              if Dg > Sg then Sg := Dg;
              if Db > Sb then Sb := Db;
            end;
            bmDifference:
            begin
              Sr := Abs(Dr - Sr);
              Sg := Abs(Dg - Sg);
              Sb := Abs(Db - Sb);
            end;
            bmSoftLight:
            begin
              { Pegtop Soft Light, integer approximation }
              Sr := (2 * Dr * Sr div 255) +
                    (Dr * Dr div 255 * (255 - 2 * Sr) div 255);
              Sg := (2 * Dg * Sg div 255) +
                    (Dg * Dg div 255 * (255 - 2 * Sg) div 255);
              Sb := (2 * Db * Sb div 255) +
                    (Db * Db div 255 * (255 - 2 * Sb) div 255);
            end;
          end;
          { Re-premultiply the blended result and composite }
          Src := Premultiply(RGBA(EnsureRange(Sr, 0, 255), EnsureRange(Sg, 0, 255), EnsureRange(Sb, 0, 255), SrcStraight.A));
          ResultSurface.BlendPixelPremul(CanvasX, CanvasY, Src, Opacity);
        end;
      end;
    end;
  end;

  Result := ResultSurface;
end;

function TImageDocument.LayerCount: Integer;
begin
  Result := FLayers.Count;
end;

function TImageDocument.UndoDepth: Integer;
begin
  Result := FHistory.Count;
end;

function TImageDocument.RedoDepth: Integer;
begin
  Result := FRedo.Count;
end;

function TImageDocument.UndoActionLabel(AIndexFromNewest: Integer): string;
var
  LabelIndex: Integer;
begin
  LabelIndex := FHistoryLabels.Count - 1 - AIndexFromNewest;
  if (LabelIndex < 0) or (LabelIndex >= FHistoryLabels.Count) then
    Exit('');
  Result := FHistoryLabels[LabelIndex];
end;

function TImageDocument.RedoActionLabel(AIndexFromNewest: Integer): string;
var
  LabelIndex: Integer;
begin
  LabelIndex := FRedoLabels.Count - 1 - AIndexFromNewest;
  if (LabelIndex < 0) or (LabelIndex >= FRedoLabels.Count) then
    Exit('');
  Result := FRedoLabels[LabelIndex];
end;

end.
