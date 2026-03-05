unit FPDocument;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, Types, FPColor, FPSurface, FPSelection;

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
    tkRecolor
  );

  TRasterLayer = class
  private
    FName: string;
    FVisible: Boolean;
    FOpacity: Byte;
    FBlendMode: TBlendMode;
    FIsBackground: Boolean;
    FSurface: TRasterSurface;
  public
    constructor Create(const AName: string; AWidth, AHeight: Integer; AIsBackground: Boolean = False);
    destructor Destroy; override;
    function Clone: TRasterLayer;
    property Name: string read FName write FName;
    property Visible: Boolean read FVisible write FVisible;
    property Opacity: Byte read FOpacity write FOpacity;
    property BlendMode: TBlendMode read FBlendMode write FBlendMode;
    property IsBackground: Boolean read FIsBackground write FIsBackground;
    property Surface: TRasterSurface read FSurface;
  end;

  TSnapshotKind = (skFullDocument, skLayerRegion);

  TDocumentSnapshot = class
  private
    FKind: TSnapshotKind;
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
    constructor CreateFromRegion(ADocument: TObject; ALayerIndex: Integer; const ARect: TRect);
    { Takes ownership of APixels (already-captured before-pixels for ARect). }
    constructor WrapRegionPixels(ALayerIndex: Integer; const ARect: TRect; APixels: TRasterSurface);
    destructor Destroy; override;
    property Kind: TSnapshotKind read FKind;
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
    procedure EnforceLayerInvariant;
  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;
    procedure NewBlank(AWidth, AHeight: Integer);
    procedure ReplaceWithSingleLayer(ASurface: TRasterSurface; const ALayerName: string);
    procedure PushHistory(const ALabel: string = 'Change');
    { Push a region snapshot with already-captured before-pixels (ownership is transferred). }
    procedure PushRegionHistory(const ALabel: string; ALayerIndex: Integer; const ADirtyRect: TRect; ABeforePixels: TRasterSurface);
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
    procedure SelectRectangle(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode = scReplace);
    procedure SelectEllipse(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode = scReplace);
    procedure SelectLasso(const APoints: array of TPoint; AMode: TSelectionCombineMode = scReplace);
    procedure SelectMagicWand(X, Y: Integer; Tolerance: Byte = 0; AMode: TSelectionCombineMode = scReplace; UseAllLayers: Boolean = False; Contiguous: Boolean = True);
    function CopySelectionToSurface(ACropToBounds: Boolean = False): TRasterSurface;
    function CopyMergedToSurface(ACropToBounds: Boolean = False): TRasterSurface;
    function CutSelectionToSurface(ACropToBounds: Boolean = False): TRasterSurface; overload;
    function CutSelectionToSurface(ACropToBounds: Boolean; const ABackgroundColor: TRGBA32): TRasterSurface; overload;
    procedure PasteAsNewLayer(ASurface: TRasterSurface; OffsetX: Integer = 0; OffsetY: Integer = 0; const ALayerName: string = 'Pasted Layer');
    procedure FillSelection(const AColor: TRGBA32; Opacity: Byte = 255);
    procedure EraseSelection; overload;
    procedure EraseSelection(const ABackgroundColor: TRGBA32); overload;
    procedure MoveSelectionBy(DeltaX, DeltaY: Integer);
    procedure MoveSelectedPixelsBy(DeltaX, DeltaY: Integer); overload;
    procedure MoveSelectedPixelsBy(DeltaX, DeltaY: Integer; const ABackgroundColor: TRGBA32); overload;
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
    procedure RecolorBrush(X, Y, Radius: Integer; SourceColor, NewColor: TRGBA32; Tolerance: Byte; Opacity: Byte = 255; PreserveValue: Boolean = False; ASelection: TSelectionMask = nil);
    function HasSelection: Boolean;
    function HasStoredSelection: Boolean;
    procedure StoreSelectionForPaste;
    procedure PasteStoredSelection;
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
  Result.FOpacity := FOpacity;
  Result.FBlendMode := FBlendMode;
  Result.Surface.Assign(FSurface);
end;

constructor TDocumentSnapshot.CreateFromDocument(ADocument: TObject);
var
  Document: TImageDocument;
  Index: Integer;
begin
  inherited Create;
  FKind := skFullDocument;
  Document := TImageDocument(ADocument);
  FLayers := TObjectList.Create(True);
  FSelection := Document.Selection.Clone;
  FWidth := Document.Width;
  FHeight := Document.Height;
  FActiveLayerIndex := Document.ActiveLayerIndex;
  for Index := 0 to Document.LayerCount - 1 do
    FLayers.Add(Document.Layers[Index].Clone);
end;

constructor TDocumentSnapshot.CreateFromRegion(ADocument: TObject; ALayerIndex: Integer; const ARect: TRect);
var
  Doc: TImageDocument;
  W, H: Integer;
begin
  inherited Create;
  FKind := skLayerRegion;
  Doc := TImageDocument(ADocument);
  FRegionLayerIndex := ALayerIndex;
  FDirtyRect := ARect;
  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;
  FRegionSurface := TRasterSurface.Create(Max(1, W), Max(1, H));
  if (ALayerIndex >= 0) and (ALayerIndex < Doc.LayerCount) then
    Doc.Layers[ALayerIndex].Surface.CopyRegionTo(FRegionSurface, ARect.Left, ARect.Top);
end;

constructor TDocumentSnapshot.WrapRegionPixels(ALayerIndex: Integer; const ARect: TRect; APixels: TRasterSurface);
begin
  inherited Create;
  FKind := skLayerRegion;
  FRegionLayerIndex := ALayerIndex;
  FDirtyRect := ARect;
  FRegionSurface := APixels;  { take ownership }
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
  ActionLabel: string;
begin
  if not CanUndo then
    Exit;
  ActionLabel := UndoActionLabel;
  { Pop first so we can inspect the kind before allocating the redo entry }
  Snapshot := PopSnapshot(FHistory);
  FHistoryLabels.Delete(FHistoryLabels.Count - 1);
  try
    { Save current state for redo: region snapshot if undo is region-based }
    if Snapshot.Kind = skLayerRegion then
      FRedo.Add(TDocumentSnapshot.CreateFromRegion(Self, Snapshot.RegionLayerIndex, Snapshot.DirtyRect))
    else
      FRedo.Add(TDocumentSnapshot.CreateFromDocument(Self));
    FRedoLabels.Add(ActionLabel);
    ApplySnapshot(Snapshot);
  finally
    Snapshot.Free;
  end;
end;

procedure TImageDocument.Redo;
var
  Snapshot: TDocumentSnapshot;
  ActionLabel: string;
begin
  if not CanRedo then
    Exit;
  ActionLabel := RedoActionLabel;
  Snapshot := PopSnapshot(FRedo);
  FRedoLabels.Delete(FRedoLabels.Count - 1);
  try
    { Save current state for undo: region snapshot if redo is region-based }
    if Snapshot.Kind = skLayerRegion then
      FHistory.Add(TDocumentSnapshot.CreateFromRegion(Self, Snapshot.RegionLayerIndex, Snapshot.DirtyRect))
    else
      FHistory.Add(TDocumentSnapshot.CreateFromDocument(Self));
    FHistoryLabels.Add(ActionLabel);
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
  X: Integer;
  Y: Integer;
begin
  if FActiveLayerIndex <= 0 then
    Exit;

  TopLayer := Layers[FActiveLayerIndex];
  BottomLayer := Layers[FActiveLayerIndex - 1];
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
      BottomLayer.Surface.BlendPixel(X, Y, TopLayer.Surface[X, Y], TopLayer.Opacity);

  BottomLayer.Name := BottomLayer.Name + ' + ' + TopLayer.Name;
  FLayers.Delete(FActiveLayerIndex);
  Dec(FActiveLayerIndex);
end;

procedure TImageDocument.Flatten;
var
  CompositeSurface: TRasterSurface;
  FlattenedSurface: TRasterSurface;
begin
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
  Cropped: TRasterSurface;
  CroppedSelection: TSelectionMask;
begin
  AWidth := Max(1, AWidth);
  AHeight := Max(1, AHeight);
  for LayerIndex := 0 to FLayers.Count - 1 do
  begin
    Cropped := Layers[LayerIndex].Surface.Crop(X, Y, AWidth, AHeight);
    try
      Layers[LayerIndex].Surface.Assign(Cropped);
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
  Resized: TRasterSurface;
  ResizedSelection: TSelectionMask;
begin
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
begin
  for LayerIndex := 0 to FLayers.Count - 1 do
    Layers[LayerIndex].Surface.FlipHorizontal;
  FSelection.FlipHorizontal;
end;

procedure TImageDocument.FlipVertical;
var
  LayerIndex: Integer;
begin
  for LayerIndex := 0 to FLayers.Count - 1 do
    Layers[LayerIndex].Surface.FlipVertical;
  FSelection.FlipVertical;
end;

procedure TImageDocument.Rotate180;
begin
  FlipHorizontal;
  FlipVertical;
end;

procedure TImageDocument.Rotate90Clockwise;
var
  LayerIndex: Integer;
  TempSize: Integer;
begin
  for LayerIndex := 0 to FLayers.Count - 1 do
    Layers[LayerIndex].Surface.Rotate90Clockwise;
  FSelection.Rotate90Clockwise;
  TempSize := FWidth;
  FWidth := FHeight;
  FHeight := TempSize;
end;

procedure TImageDocument.Rotate90CounterClockwise;
var
  LayerIndex: Integer;
  TempSize: Integer;
begin
  for LayerIndex := 0 to FLayers.Count - 1 do
    Layers[LayerIndex].Surface.Rotate90CounterClockwise;
  FSelection.Rotate90CounterClockwise;
  TempSize := FWidth;
  FWidth := FHeight;
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

procedure TImageDocument.SelectRectangle(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode);
begin
  FSelection.SelectRectangle(X1, Y1, X2, Y2, AMode);
end;

procedure TImageDocument.SelectEllipse(X1, Y1, X2, Y2: Integer; AMode: TSelectionCombineMode);
begin
  FSelection.SelectEllipse(X1, Y1, X2, Y2, AMode);
end;

procedure TImageDocument.SelectLasso(const APoints: array of TPoint; AMode: TSelectionCombineMode);
begin
  FSelection.SelectPolygon(APoints, AMode);
end;

procedure TImageDocument.SelectMagicWand(X, Y: Integer; Tolerance: Byte; AMode: TSelectionCombineMode; UseAllLayers: Boolean; Contiguous: Boolean);
var
  SelectionFromWand: TSelectionMask;
  SelectX: Integer;
  SelectY: Integer;
  SampleSurface: TRasterSurface;
  OwnsSampleSurface: Boolean;
begin
  if UseAllLayers then
  begin
    SampleSurface := Composite;
    OwnsSampleSurface := True;
  end
  else
  begin
    SampleSurface := ActiveLayer.Surface;
    OwnsSampleSurface := False;
  end;
  if Contiguous then
    SelectionFromWand := SampleSurface.CreateContiguousSelection(X, Y, Tolerance)
  else
    SelectionFromWand := SampleSurface.CreateGlobalColorSelection(X, Y, Tolerance);
  if OwnsSampleSurface then
    SampleSurface.Free;
  try
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
        if SelectionFromWand[SelectX, SelectY] then
          case AMode of
            scAdd: FSelection[SelectX, SelectY] := True;
            scSubtract: FSelection[SelectX, SelectY] := False;
          end;
  finally
    SelectionFromWand.Free;
  end;
end;

function TImageDocument.CopySelectionToSurface(ACropToBounds: Boolean): TRasterSurface;
var
  Copied: TRasterSurface;
  Bounds: TRect;
begin
  if not FSelection.HasSelection then
    Exit(ActiveLayer.Surface.Clone);

  Copied := ActiveLayer.Surface.CopySelection(FSelection);
  if not ACropToBounds then
    Exit(Copied);

  try
    Bounds := FSelection.BoundsRect;
    Result := Copied.Crop(Bounds.Left, Bounds.Top, Bounds.Right - Bounds.Left, Bounds.Bottom - Bounds.Top);
  finally
    Copied.Free;
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
begin
  Result := CopySelectionToSurface(ACropToBounds);
  if FSelection.HasSelection then
  begin
    if ActiveLayer.IsBackground then
      ActiveLayer.Surface.FillSelection(FSelection, BackgroundReplacementColor(ABackgroundColor), 255)
    else
      ActiveLayer.Surface.EraseSelection(FSelection);
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
  Layer.Surface.PasteSurface(ASurface, OffsetX, OffsetY);
end;

procedure TImageDocument.FillSelection(const AColor: TRGBA32; Opacity: Byte);
begin
  if not FSelection.HasSelection then
    Exit;
  ActiveLayer.Surface.FillSelection(FSelection, AColor, Opacity);
end;

procedure TImageDocument.EraseSelection;
begin
  EraseSelection(RGBA(255, 255, 255, 255));
end;

procedure TImageDocument.EraseSelection(const ABackgroundColor: TRGBA32);
begin
  if not FSelection.HasSelection then
    Exit;
  if ActiveLayer.IsBackground then
    ActiveLayer.Surface.FillSelection(FSelection, BackgroundReplacementColor(ABackgroundColor), 255)
  else
    ActiveLayer.Surface.EraseSelection(FSelection);
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
  Copied: TRasterSurface;
  X: Integer;
  Y: Integer;
  TargetX: Integer;
  TargetY: Integer;
begin
  if not FSelection.HasSelection then
    Exit;
  if not ActiveLayer.IsBackground then
  begin
    ActiveLayer.Surface.MoveSelectedPixels(FSelection, DeltaX, DeltaY);
    FSelection.MoveBy(DeltaX, DeltaY);
    Exit;
  end;

  Copied := ActiveLayer.Surface.CopySelection(FSelection);
  try
    ActiveLayer.Surface.FillSelection(FSelection, BackgroundReplacementColor(ABackgroundColor), 255);
    for Y := 0 to Min(ActiveLayer.Surface.Height, FSelection.Height) - 1 do
      for X := 0 to Min(ActiveLayer.Surface.Width, FSelection.Width) - 1 do
        if FSelection[X, Y] then
        begin
          TargetX := X + DeltaX;
          TargetY := Y + DeltaY;
          if ActiveLayer.Surface.InBounds(TargetX, TargetY) then
          begin
            if Copied[X, Y].A = 255 then
              ActiveLayer.Surface[TargetX, TargetY] := Copied[X, Y]
            else if Copied[X, Y].A > 0 then
              ActiveLayer.Surface.BlendPixel(TargetX, TargetY, Copied[X, Y], 255);
          end;
        end;
  finally
    Copied.Free;
  end;
  FSelection.MoveBy(DeltaX, DeltaY);
end;

procedure TImageDocument.CropToSelection;
var
  Bounds: TRect;
begin
  if not FSelection.HasSelection then
    Exit;
  Bounds := FSelection.BoundsRect;
  Crop(Bounds.Left, Bounds.Top, Bounds.Right - Bounds.Left, Bounds.Bottom - Bounds.Top);
end;

procedure TImageDocument.AutoLevel;
begin
  ActiveLayer.Surface.AutoLevel;
end;

procedure TImageDocument.InvertColors;
begin
  ActiveLayer.Surface.InvertColors;
end;

procedure TImageDocument.Grayscale;
begin
  ActiveLayer.Surface.Grayscale;
end;

procedure TImageDocument.AdjustHueSaturation(HueDelta: Integer; SaturationDelta: Integer);
begin
  ActiveLayer.Surface.AdjustHueSaturation(HueDelta, SaturationDelta);
end;

procedure TImageDocument.AdjustGammaCurve(Gamma: Double);
begin
  ActiveLayer.Surface.AdjustGammaCurve(Gamma);
end;

procedure TImageDocument.AdjustLevels(InputLow, InputHigh, OutputLow, OutputHigh: Byte);
begin
  ActiveLayer.Surface.AdjustLevels(InputLow, InputHigh, OutputLow, OutputHigh);
end;

procedure TImageDocument.AdjustBrightness(Delta: Integer);
begin
  ActiveLayer.Surface.AdjustBrightness(Delta);
end;

procedure TImageDocument.AdjustContrast(Amount: Integer);
begin
  ActiveLayer.Surface.AdjustContrast(Amount);
end;

procedure TImageDocument.Sepia;
begin
  ActiveLayer.Surface.Sepia;
end;

procedure TImageDocument.BlackAndWhite(Threshold: Byte);
begin
  ActiveLayer.Surface.BlackAndWhite(Threshold);
end;

procedure TImageDocument.Posterize(Levels: Byte);
begin
  ActiveLayer.Surface.Posterize(Levels);
end;

procedure TImageDocument.BoxBlur(Radius: Integer);
begin
  ActiveLayer.Surface.BoxBlur(Radius);
end;

procedure TImageDocument.Sharpen;
begin
  ActiveLayer.Surface.Sharpen;
end;

procedure TImageDocument.AddNoise(Amount: Byte; Seed: Cardinal);
begin
  ActiveLayer.Surface.AddNoise(Amount, Seed);
end;

procedure TImageDocument.DetectEdges;
begin
  ActiveLayer.Surface.DetectEdges;
end;

procedure TImageDocument.Emboss;
begin
  ActiveLayer.Surface.Emboss;
end;

procedure TImageDocument.Soften;
begin
  ActiveLayer.Surface.Soften;
end;

procedure TImageDocument.RenderClouds(Seed: Cardinal);
begin
  ActiveLayer.Surface.RenderClouds(Seed);
end;

procedure TImageDocument.Pixelate(BlockSize: Integer);
begin
  ActiveLayer.Surface.Pixelate(BlockSize);
end;

procedure TImageDocument.Vignette(Strength: Double);
begin
  ActiveLayer.Surface.Vignette(Strength);
end;

procedure TImageDocument.MotionBlur(Angle: Integer; Distance: Integer);
begin
  ActiveLayer.Surface.MotionBlur(Angle, Distance);
end;

procedure TImageDocument.MedianFilter(Radius: Integer);
begin
  ActiveLayer.Surface.MedianFilter(Radius);
end;

procedure TImageDocument.OutlineEffect(const AOutlineColor: TRGBA32; Threshold: Byte);
begin
  ActiveLayer.Surface.OutlineEffect(AOutlineColor, Threshold);
end;

procedure TImageDocument.GlowEffect(Radius: Integer; Intensity: Integer);
begin
  ActiveLayer.Surface.GlowEffect(Radius, Intensity);
end;

procedure TImageDocument.OilPaint(Radius: Integer);
begin
  ActiveLayer.Surface.OilPaint(Radius);
end;

procedure TImageDocument.FrostedGlass(Amount: Integer);
begin
  ActiveLayer.Surface.FrostedGlass(Amount);
end;

procedure TImageDocument.ZoomBlur(CenterX: Integer; CenterY: Integer; Amount: Integer);
begin
  ActiveLayer.Surface.ZoomBlur(CenterX, CenterY, Amount);
end;

procedure TImageDocument.GaussianBlur(Radius: Integer);
begin
  ActiveLayer.Surface.GaussianBlur(Radius);
end;

procedure TImageDocument.Unfocus(Radius: Integer);
begin
  ActiveLayer.Surface.Unfocus(Radius);
end;

procedure TImageDocument.SurfaceBlur(Radius: Integer; Threshold: Byte);
begin
  ActiveLayer.Surface.SurfaceBlur(Radius, Threshold);
end;

procedure TImageDocument.RadialBlur(Amount: Integer);
begin
  ActiveLayer.Surface.RadialBlur(Amount);
end;

procedure TImageDocument.Twist(Amount: Integer);
begin
  ActiveLayer.Surface.Twist(Amount);
end;

procedure TImageDocument.Fragment(Offset: Integer);
begin
  ActiveLayer.Surface.Fragment(Offset);
end;

procedure TImageDocument.Bulge(Amount: Integer);
begin
  ActiveLayer.Surface.Bulge(Amount);
end;

procedure TImageDocument.Dents(Amount: Integer);
begin
  ActiveLayer.Surface.Dents(Amount);
end;

procedure TImageDocument.Relief(Angle: Integer);
begin
  ActiveLayer.Surface.Relief(Angle);
end;

procedure TImageDocument.RedEye(Threshold: Byte; Strength: Integer);
begin
  ActiveLayer.Surface.RedEye(Threshold, Strength);
end;

procedure TImageDocument.TileReflection(TileSize: Integer);
begin
  ActiveLayer.Surface.TileReflection(TileSize);
end;

procedure TImageDocument.Crystallize(CellSize: Integer; Seed: Cardinal);
begin
  ActiveLayer.Surface.Crystallize(CellSize, Seed);
end;

procedure TImageDocument.InkSketch(InkStrength: Integer; Coloring: Integer);
begin
  ActiveLayer.Surface.InkSketch(InkStrength, Coloring);
end;

procedure TImageDocument.RenderMandelbrot(Iterations: Integer; Zoom: Double);
begin
  ActiveLayer.Surface.RenderMandelbrot(Iterations, Zoom);
end;

procedure TImageDocument.RenderJulia(Iterations: Integer; Zoom: Double; CReal: Double; CImag: Double);
begin
  ActiveLayer.Surface.RenderJulia(Iterations, Zoom, CReal, CImag);
end;

procedure TImageDocument.RecolorBrush(X, Y, Radius: Integer; SourceColor, NewColor: TRGBA32; Tolerance: Byte; Opacity: Byte; PreserveValue: Boolean; ASelection: TSelectionMask);
begin
  ActiveLayer.Surface.RecolorBrush(X, Y, Radius, SourceColor, NewColor, Tolerance, Opacity, PreserveValue, ASelection);
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
  X: Integer;
  Y: Integer;
  Layer: TRasterLayer;
  Dst, Src: TRGBA32;
  A, InvA, Opacity: Integer;
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
      for Y := 0 to FHeight - 1 do
        for X := 0 to FWidth - 1 do
          ResultSurface.BlendPixel(X, Y, Layer.Surface[X, Y], Opacity);
    end
    else
    begin
      for Y := 0 to FHeight - 1 do
        for X := 0 to FWidth - 1 do
        begin
          Dst := ResultSurface[X, Y];
          Src := Layer.Surface[X, Y];
          if Src.A = 0 then
            Continue;
          A := (Src.A * Opacity) div 255;
          InvA := 255 - A;
          Dr := Dst.R; Dg := Dst.G; Db := Dst.B;
          Sr := Src.R; Sg := Src.G; Sb := Src.B;
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
          Src.R := EnsureRange(Sr, 0, 255);
          Src.G := EnsureRange(Sg, 0, 255);
          Src.B := EnsureRange(Sb, 0, 255);
          ResultSurface.BlendPixel(X, Y, Src, Opacity);
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
