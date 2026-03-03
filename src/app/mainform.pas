unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, Spin, Types, Clipbrd, FPColor, FPSurface, FPDocument, FPSelection,
  FPPaletteHelpers, FPRulerHelpers, FPTextDialog, FPColorWheelHelpers;

type
  TMainForm = class;
  TDisplayUnit = (
    duPixels,
    duInches,
    duCentimeters
  );

  TCanvasView = class(TCustomControl)
  private
    FOwnerForm: TMainForm;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property OwnerForm: TMainForm read FOwnerForm write FOwnerForm;
  end;

  TRulerView = class(TCustomControl)
  private
    FOwnerForm: TMainForm;
    FOrientation: TRulerOrientation;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property OwnerForm: TMainForm read FOwnerForm write FOwnerForm;
    property Orientation: TRulerOrientation read FOrientation write FOrientation;
  end;

  TMainForm = class(TForm)
  private
    FDocument: TImageDocument;
    FCurrentFileName: string;
    FRecentFiles: TStringList;
    FDirty: Boolean;
    FNewImageResolutionDPI: Double;
    FZoomScale: Double;
    FDisplayUnit: TDisplayUnit;
    FCurrentTool: TToolKind;
    FBrushSize: Integer;
    FWandTolerance: Integer;
    FPendingSelectionMode: TSelectionCombineMode;
    { 0=Outline, 1=Fill, 2=Outline+Fill }
    FShapeStyle: Integer;
    { 0=Contiguous, 1=Global }
    FBucketFloodMode: Integer;
    { 0=Current Layer, 1=All Layers }
    FWandSampleSource: Integer;
    { JPEG export quality 1-100; persisted per session }
    FJpegQuality: Integer;
    FPrimaryColor: TRGBA32;
    FSecondaryColor: TRGBA32;
    FStrokeColor: TRGBA32;
    FPickSecondaryTarget: Boolean;
    FUpdatingToolOption: Boolean;
    FPointerDown: Boolean;
    FDragStart: TPoint;
    FLastImagePoint: TPoint;
    FLastPointerPoint: TPoint;
    FLassoPoints: array of TPoint;
    FClipboardSurface: TRasterSurface;
    FClipboardOffset: TPoint;
    FPreparedBitmap: TBitmap;
    FDisplaySurface: TRasterSurface;  { persistent buffer; reused across repaints to avoid per-repaint heap alloc }
    FRenderRevision: QWord;
    FPreparedRevision: QWord;
    FMainMenu: TMainMenu;
    FRecentMenu: TMenuItem;
    FSaveMenuItem: TMenuItem;
    FUnitsMenu: TMenuItem;
    FUnitPixelsItem: TMenuItem;
    FUnitInchesItem: TMenuItem;
    FUnitCentimetersItem: TMenuItem;
    FPixelGridMenuItem: TMenuItem;
    FRulersMenuItem: TMenuItem;
    FTopPanel: TPanel;
    FWorkspacePanel: TPanel;
    FRulerTopBand: TPanel;
    FRulerCorner: TPanel;
    FToolsPanel: TPanel;
    FColorsPanel: TPanel;
    FHistoryPanel: TPanel;
    FRightPanel: TPanel;
    FHorizontalRuler: TRulerView;
    FVerticalRuler: TRulerView;
    FCanvasHost: TScrollBox;
    FPaintBox: TCanvasView;
    FStatusBar: TPanel;
    FStatusLabels: array[0..6] of TLabel;
    FStatusZoomTrack: TTrackBar;
    FStatusZoomLabel: TLabel;
    FLayerList: TListBox;
    FHistoryList: TListBox;
    FColorsValueLabel: TLabel;
    FHistoryValueLabel: TLabel;
    FBrushSpin: TSpinEdit;
    FToolCombo: TComboBox;
    FZoomCombo: TComboBox;
    FOptionLabel: TLabel;
    FColorsBox: TPaintBox;
    FDraggingPalette: TControl;
    FPaletteDragOffset: TPoint;
    FPaletteViewItems: array[TPaletteKind] of TMenuItem;
    FShowPixelGrid: Boolean;
    FShowRulers: Boolean;
    FDeferredLayoutPass: Boolean;
    FLastScrollPosition: TPoint;
    FUpdatingZoomControl: Boolean;
    { Temporary-pan support }
    FPreviousTool: TToolKind;
    FTempToolActive: Boolean;

    { New tool and effect state }
    FLastEffectCaption: string;
    FLastEffectProc: TNotifyEvent;
    FRepeatLastEffectItem: TMenuItem;
    FCloneStampSource: TPoint;
    FCloneStampSampled: Boolean;
    FTextLastResult: TTextDialogResult;
    FLayerBlendCombo: TComboBox;
    FLayerPropsButton: TButton;
    FCloneStampSnapshot: TRasterSurface;
    { Document tab management }
    FTabDocuments: array of TImageDocument;
    FTabFileNames: array of string;
    FTabDirtyFlags: array of Boolean;
    FActiveTabIndex: Integer;
    FTabStrip: TPanel;
    FTabPopupMenu: TPopupMenu;
    FPopupTabIndex: Integer;
    FUpdatingTabs: Boolean;
    { Colors panel RGBA }
    FColorRSpin: TSpinEdit;
    FColorGSpin: TSpinEdit;
    FColorBSpin: TSpinEdit;
    FColorASpin: TSpinEdit;
    FColorHexEdit: TEdit;
    FUpdatingColorSpins: Boolean;
    FColorEditTarget: Integer; { 0=Primary, 1=Secondary }
    FColorTargetCombo: TComboBox;
    { Tool options — opacity and selection mode }
    FOpacitySpin: TSpinEdit;
    FOpacityLabel: TLabel;
    FBrushOpacity: Integer;
    FHardnessSpin: TSpinEdit;
    FHardnessLabel: TLabel;
    FBrushHardness: Integer;
    FSelModeCombo: TComboBox;
    FSelModeLabel: TLabel;
    FShapeStyleCombo: TComboBox;
    FShapeStyleLabel: TLabel;
    FBucketModeCombo: TComboBox;
    FBucketModeLabel: TLabel;
    FWandSampleCombo: TComboBox;
    FWandSampleLabel: TLabel;
    { Wand contiguous toggle }
    FWandContiguous: Boolean;
    FWandContiguousCheck: TCheckBox;
    { Fill tolerance }
    FFillTolerance: Integer;
    FFillTolSpin: TSpinEdit;
    FFillTolLabel: TLabel;
    { Gradient type and reverse }
    { 0=Linear, 1=Radial }
    FGradientType: Integer;
    FGradientReverse: Boolean;
    FGradientTypeCombo: TComboBox;
    FGradientTypeLabel: TLabel;
    FGradientReverseCheck: TCheckBox;
    { Color picker sample source: 0=Current Layer, 1=All Layers }
    FPickerSampleSource: Integer;
    FPickerSampleCombo: TComboBox;
    FPickerSampleLabel: TLabel;
    { Selection anti-alias }
    FSelAntiAlias: Boolean;
    FSelAntiAliasCheck: TCheckBox;
    FMagnifyInstalled: Boolean;
    function ActivePaintColor: TRGBA32;
    function DisplayFileName: string;
    function CanvasToImage(X, Y: Integer): TPoint;
    function BuildDisplaySurface: TRasterSurface;
    function ToolHintText: string;
    function ImageOriginInViewport: TPoint;
    function DisplayUnitSuffix: string;
    function PixelsToDisplayValue(APixels: Integer): Double;
    function DisplayValueToPixels(AValue: Double): Double;
    function FormatMeasurement(APixels: Integer): string;
    procedure ColorsBoxPaint(Sender: TObject);
    procedure ColorsBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    function ParseMeasurementText(const AText: string; AFallbackPixels: Integer): Integer;
    function PromptForSize(const ATitle: string; out AWidth, AHeight: Integer): Boolean;
    function SelectionModeFromShift(const Shift: TShiftState): TSelectionCombineMode;
    procedure AppendLassoPoint(const APoint: TPoint);
    procedure InvalidatePreparedBitmap;
    procedure UpdateToolOptionControl;
    procedure RefreshUnitsMenu;
    procedure BuildMenus;
    procedure BuildTabPopupMenu;
    procedure BuildToolbar;
    procedure BuildSidePanel;
    function CreateButton(const ACaption: string; ALeft, ATop, AWidth: Integer; AHandler: TNotifyEvent; AParent: TWinControl; ATag: Integer = 0): TButton;
    procedure CreateMenuItem(AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent; AShortcut: TShortCut = 0);
    procedure PaintCanvasTo(ACanvas: TCanvas; const ARect: TRect);
    procedure PaintRuler(ACanvas: TCanvas; const ARect: TRect; AOrientation: TRulerOrientation);
    procedure UpdateCanvasSize;
    procedure FitDocumentToViewport(AOnlyShrink: Boolean);
    procedure RefreshCanvas;
    procedure RefreshRulers;
    procedure RefreshLayers;
    procedure RefreshColorsPanel;
    procedure RefreshHistoryPanel;
    procedure RefreshStatus(const ACursorPoint: TPoint);
    procedure UpdateStatusForTool;  { call when current tool changes }

    procedure ActivateTempPan;
    procedure DeactivateTempPan;

    procedure LayoutStatusBarControls(Sender: TObject);
    procedure UpdateZoomControls;
    procedure UpdateCaption;
    procedure UpdateSaveCommandCaption;
    function RecentFilesStorePath: string;
    procedure LoadRecentFiles;
    procedure SaveRecentFiles;
    procedure RegisterRecentFile(const AFileName: string);
    procedure RebuildRecentFilesMenu;
    procedure ClampPaletteToWorkspace(APalette: TControl);
    function PaletteControl(AKind: TPaletteKind): TPanel;
    function PaletteKindForControl(AControl: TControl): TPaletteKind;
    function PaletteHeaderControl(APalette: TControl): TPanel;
    procedure ApplyPaletteVisualState(APalette: TControl; ADragging: Boolean);
    procedure CreatePaletteHeader(ATarget: TPanel; AKind: TPaletteKind);
    procedure RefreshPaletteMenuChecks;
    procedure RestorePaletteLayout;
    procedure CreatePalette(ATarget: TPanel; AKind: TPaletteKind);
    function ConfirmDocumentReplacement(const AAction: string): Boolean;
    procedure SetDirty(AValue: Boolean);
    procedure SaveToPath(const AFileName: string);
    procedure LoadDocumentFromPath(const AFileName: string);
    function LoadSurfaceForImportPath(const AFileName: string): TRasterSurface;
    procedure ApplyZoomScale(ANewScale: Double);
    procedure ApplyZoomScaleAtViewportPoint(ANewScale: Double; const AViewportPoint: TPoint);
    procedure ApplyImmediateTool(const APoint: TPoint);
    procedure CommitShapeTool(const AStartPoint, AEndPoint: TPoint);
    procedure ResetDocument(AWidth, AHeight: Integer);
    procedure NewDocumentClick(Sender: TObject);
    procedure OpenDocumentClick(Sender: TObject);
    procedure OpenRecentFileClick(Sender: TObject);
    procedure CloseDocumentClick(Sender: TObject);
    procedure ExitApplicationClick(Sender: TObject);
    procedure SaveDocumentClick(Sender: TObject);
    procedure SaveAsDocumentClick(Sender: TObject);
    procedure SaveAllDocumentsClick(Sender: TObject);
    procedure PrintDocumentClick(Sender: TObject);
    procedure AcquireClick(Sender: TObject);
    procedure ImportLayerClick(Sender: TObject);
    procedure UndoClick(Sender: TObject);
    procedure RedoClick(Sender: TObject);
    procedure CutClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure CopySelectionClick(Sender: TObject);
    procedure CopyMergedClick(Sender: TObject);
    procedure PasteClick(Sender: TObject);
    procedure PasteIntoNewLayerClick(Sender: TObject);
    procedure PasteIntoNewImageClick(Sender: TObject);
    procedure AddLayerClick(Sender: TObject);
    procedure DuplicateLayerClick(Sender: TObject);
    procedure DeleteLayerClick(Sender: TObject);
    procedure RenameLayerClick(Sender: TObject);
    procedure MoveLayerUpClick(Sender: TObject);
    procedure MoveLayerDownClick(Sender: TObject);
    procedure MergeDownClick(Sender: TObject);
    procedure FlattenClick(Sender: TObject);
    procedure ToggleLayerVisibilityClick(Sender: TObject);
    procedure LayerOpacityClick(Sender: TObject);
    procedure ResizeImageClick(Sender: TObject);
    procedure ResizeCanvasClick(Sender: TObject);
    procedure RotateClockwiseClick(Sender: TObject);
    procedure RotateCounterClockwiseClick(Sender: TObject);
    procedure Rotate180Click(Sender: TObject);
    procedure FlipHorizontalClick(Sender: TObject);
    procedure FlipVerticalClick(Sender: TObject);
    procedure AutoLevelClick(Sender: TObject);
    procedure InvertColorsClick(Sender: TObject);
    procedure GrayscaleClick(Sender: TObject);
    procedure CurvesClick(Sender: TObject);
    procedure HueSaturationClick(Sender: TObject);
    procedure LevelsClick(Sender: TObject);
    procedure BrightnessContrastClick(Sender: TObject);
    procedure SepiaClick(Sender: TObject);
    procedure BlackAndWhiteClick(Sender: TObject);
    procedure PosterizeClick(Sender: TObject);
    procedure BlurClick(Sender: TObject);
    procedure SharpenClick(Sender: TObject);
    procedure AddNoiseClick(Sender: TObject);
    procedure OutlineClick(Sender: TObject);
    procedure OutlineEffectClick(Sender: TObject);
    procedure EmbossClick(Sender: TObject);
    procedure SoftenClick(Sender: TObject);
    procedure RenderCloudsClick(Sender: TObject);
    procedure PixelateClick(Sender: TObject);
    procedure VignetteClick(Sender: TObject);
    procedure MotionBlurClick(Sender: TObject);
    procedure MedianFilterClick(Sender: TObject);
    procedure GlowClick(Sender: TObject);
    procedure OilPaintClick(Sender: TObject);
    procedure FrostedGlassClick(Sender: TObject);
    procedure ZoomBlurClick(Sender: TObject);
    procedure RepeatLastEffectClick(Sender: TObject);
    procedure LayerPropertiesClick(Sender: TObject);
    procedure PasteSelectionClick(Sender: TObject);
    procedure LayerBlendModeChanged(Sender: TObject);
    procedure PlaceTextAtPoint(const AResult: TTextDialogResult; APoint: TPoint; AColor: TRGBA32);
    { Document tab management }
    procedure TabButtonClick(Sender: TObject);
    procedure TabCloseButtonClick(Sender: TObject);
    procedure TabMenuCloseClick(Sender: TObject);
    procedure TabMenuCloseOthersClick(Sender: TObject);
    procedure TabMenuCloseRightClick(Sender: TObject);
    procedure TabMenuNewClick(Sender: TObject);
    procedure AddDocumentTab(ADoc: TImageDocument; const AFileName: string;
      ADirty: Boolean = False);
    procedure CloseDocumentTab(AIndex: Integer);
    procedure SwitchToTab(AIndex: Integer);
    procedure NextTabClick(Sender: TObject);
    procedure PrevTabClick(Sender: TObject);
    procedure RefreshTabStrip;
    function TabDocumentDisplayName(AIndex: Integer): string;
    procedure OpenFileInNewTab(const AFileName: string);
    { Colors panel RGBA controls }
    procedure UpdateColorSpins;
    procedure ColorSpinChanged(Sender: TObject);
    procedure ColorHexChanged(Sender: TObject);
    procedure ColorTargetComboChanged(Sender: TObject);
    { Tool option handlers }
    procedure OpacitySpinChanged(Sender: TObject);
    procedure HardnessSpinChanged(Sender: TObject);
    procedure SelModeComboChanged(Sender: TObject);
    procedure ShapeStyleComboChanged(Sender: TObject);
    procedure BucketModeComboChanged(Sender: TObject);
    procedure WandSampleComboChanged(Sender: TObject);
    procedure WandContiguousChanged(Sender: TObject);
    procedure FillTolSpinChanged(Sender: TObject);
    procedure GradientTypeComboChanged(Sender: TObject);
    procedure GradientReverseChanged(Sender: TObject);
    procedure PickerSampleComboChanged(Sender: TObject);
    procedure SelAntiAliasChanged(Sender: TObject);
    { Layer operations }
    procedure LayerRotateZoomClick(Sender: TObject);
    procedure DeselectClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure InvertSelectionClick(Sender: TObject);
    procedure FillSelectionClick(Sender: TObject);
    procedure EraseSelectionClick(Sender: TObject);
    procedure CropToSelectionClick(Sender: TObject);
    procedure SwapColorsClick(Sender: TObject);
    procedure ResetColorsClick(Sender: TObject);
    procedure PrimaryColorClick(Sender: TObject);
    procedure SecondaryColorClick(Sender: TObject);
    procedure ZoomInClick(Sender: TObject);
    procedure ZoomOutClick(Sender: TObject);
    procedure ActualSizeClick(Sender: TObject);
    procedure FitToWindowClick(Sender: TObject);
    procedure ZoomToSelectionClick(Sender: TObject);
    procedure TogglePixelGridClick(Sender: TObject);
    procedure ToggleRulersClick(Sender: TObject);
    procedure UnitsPixelsClick(Sender: TObject);
    procedure UnitsInchesClick(Sender: TObject);
    procedure UnitsCentimetersClick(Sender: TObject);
    procedure UtilityButtonClick(Sender: TObject);
    procedure SettingsClick(Sender: TObject);
    procedure HelpClick(Sender: TObject);
    procedure TogglePaletteViewClick(Sender: TObject);
    procedure ResetPaletteLayoutClick(Sender: TObject);
    procedure HidePaletteClick(Sender: TObject);
    procedure ToolButtonClick(Sender: TObject);
    procedure ToolComboChange(Sender: TObject);
    procedure ZoomComboChange(Sender: TObject);
    procedure StatusZoomTrackChange(Sender: TObject);
    procedure HistoryListClick(Sender: TObject);
    procedure HistoryListDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure CanvasHostResize(Sender: TObject);
    procedure BrushSizeChanged(Sender: TObject);
    procedure LayerListClick(Sender: TObject);
    procedure LayerListDblClick(Sender: TObject);
    procedure PaletteMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaletteMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaletteMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxPaint(Sender: TObject);
    procedure StatusZoomToggleClick(Sender: TObject);
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure ViewportMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    { Public constructor / destructor }
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    { Testing helpers - exposed so unit tests can drive the form without relying
      on private fields or event handler visibility. These are not used by the
      production application. }
    property ToolCombo: TComboBox read FToolCombo write FToolCombo;
    property ColorTargetCombo: TComboBox read FColorTargetCombo write FColorTargetCombo;
    property ColorEditTarget: Integer read FColorEditTarget;
    procedure ToggleColorEditTarget;
    procedure StartTempPan;
    procedure StopTempPan;
    procedure SimulateKeyDown(Key: Word; Shift: TShiftState);
    procedure SimulateKeyUp(Key: Word; Shift: TShiftState);
    procedure SimulateMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SimulateMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MakeTestSafe; { lightweight test-mode initialization }
  end;

var
  AppMainForm: TMainForm;

implementation

uses
  Math, LCLType, Printers, FPIO, FPNativeIO, FPLCLBridge, FPUIHelpers,
  FPNewImageDialog, FPResizeDialog, FPUtilityHelpers, FPSettingsDialog, FPZoomHelpers,
  FPViewHelpers, FPViewportHelpers, FPStatusHelpers, FPHueSaturationDialog,
  FPLevelsDialog, FPBrightnessContrastDialog, FPCurvesDialog, FPPosterizeDialog,
  FPBlurDialog, FPNoiseDialog, FPFileMenuHelpers,
  FPTextRenderer, FPLayerPropertiesDialog, FPMagnifyBridge;

const
  DisplayDPI = 96.0;

var
  GMainForm: TMainForm = nil;

procedure FPMagnifyCallbackProc(AMagnification: Double;
  ALocationX, ALocationY: Double); cdecl;
var
  NewScale: Double;
  VP: TPoint;
begin
  if not Assigned(GMainForm) then Exit;
  if not Assigned(GMainForm.FCanvasHost) then Exit;
  { magnification is a delta: +0.02 means 2% zoom in per event }
  NewScale := GMainForm.FZoomScale * (1.0 + AMagnification);
  VP := Point(Round(ALocationX), GMainForm.FCanvasHost.ClientHeight - Round(ALocationY));
  GMainForm.ApplyZoomScaleAtViewportPoint(NewScale, VP);
end;

constructor TCanvasView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
end;

procedure TCanvasView.Paint;
begin
  inherited Paint;
  if Assigned(FOwnerForm) then
    FOwnerForm.PaintCanvasTo(Canvas, ClientRect);
end;

constructor TRulerView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
end;

procedure TRulerView.Paint;
begin
  inherited Paint;
  if Assigned(FOwnerForm) then
    FOwnerForm.PaintRuler(Canvas, ClientRect, FOrientation);
end;

constructor TMainForm.Create(TheOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(TheOwner);
  { If there is no LCL Application available (headless test run), avoid
    constructing full UI controls which may call into an uninitialized
    widgetset. Create only the minimal objects the tests and core logic
    expect. }
  if not Assigned(Application) then
  begin
    Caption := 'FlatPaint (test)';
    Width := 1360;
    Height := 900;
    Position := poScreenCenter;
    DoubleBuffered := True;
    KeyPreview := True;

    FPrimaryColor := RGBA(0, 0, 0, 255);
    FSecondaryColor := RGBA(255, 255, 255, 255);
    FStrokeColor := FPrimaryColor;
    FZoomScale := 1.0;
    FDisplayUnit := duPixels;
    FCurrentTool := tkBrush;
    FBrushSize := 8;
    FWandTolerance := 32;
    FBrushOpacity := 100;
    FBrushHardness := 100;
    FShapeStyle := 0;
    FBucketFloodMode := 0;
    FWandSampleSource := 0;
    FWandContiguous := True;
    FJpegQuality := 90;
    FFillTolerance := 8;
    FGradientType := 0;
    FGradientReverse := False;
    FPickerSampleSource := 0;
    FSelAntiAlias := True;
    FClipboardOffset := Point(0, 0);
    FPreparedBitmap := TBitmap.Create;
    FRenderRevision := 1;
    FPreparedRevision := 0;

    FDocument := TImageDocument.Create(1024, 768);
    SetLength(FTabDocuments, 1);
    SetLength(FTabFileNames, 1);
    SetLength(FTabDirtyFlags, 1);
    FTabDocuments[0] := FDocument;
    FTabFileNames[0] := '';
    FTabDirtyFlags[0] := False;
    FActiveTabIndex := 0;
    FCurrentFileName := '';
    FRecentFiles := TStringList.Create;
    FRecentFiles.CaseSensitive := False;
    FDirty := False;
    FNewImageResolutionDPI := 96.0;
    FShowPixelGrid := False;
    FShowRulers := True;
    FDeferredLayoutPass := True;
    FLastScrollPosition := Point(0, 0);
    GMainForm := Self;
    Exit;
  end;
  Caption := 'FlatPaint';
  Width := 1360;
  Height := 900;
  Position := poScreenCenter;
  DoubleBuffered := True;
  KeyPreview := True;
  OnKeyDown := @FormKeyDown;
  OnCloseQuery := @FormCloseQuery;

  FPrimaryColor := RGBA(0, 0, 0, 255);
  FSecondaryColor := RGBA(255, 255, 255, 255);
  FStrokeColor := FPrimaryColor;
  FZoomScale := 1.0;
  FDisplayUnit := duPixels;
  FCurrentTool := tkBrush;
  FBrushSize := 8;
  FWandTolerance := 32;
  FBrushOpacity := 100;
  FBrushHardness := 100;
  FShapeStyle := 0;
  FBucketFloodMode := 0;
  FWandSampleSource := 0;
  FWandContiguous := True;
  FJpegQuality := 90;
  FFillTolerance := 8;
  FGradientType := 0;
  FGradientReverse := False;
  FPickerSampleSource := 0;
  FSelAntiAlias := True;
  FClipboardOffset := Point(0, 0);
  FPreparedBitmap := TBitmap.Create;
  FRenderRevision := 1;
  FPreparedRevision := 0;

  FDocument := TImageDocument.Create(1024, 768);
  { Initialize tab arrays with the first document }
  SetLength(FTabDocuments, 1);
  SetLength(FTabFileNames, 1);
  SetLength(FTabDirtyFlags, 1);
  FTabDocuments[0] := FDocument;
  FTabFileNames[0] := '';
  FTabDirtyFlags[0] := False;
  FActiveTabIndex := 0;
  FCurrentFileName := '';
  FRecentFiles := TStringList.Create;
  FRecentFiles.CaseSensitive := False;
  LoadRecentFiles;
  FDirty := False;
  FNewImageResolutionDPI := 96.0;
  FShowPixelGrid := False;
  FShowRulers := True;
  FDeferredLayoutPass := True;
  FLastScrollPosition := Point(0, 0);

  BuildTabPopupMenu;
  BuildMenus;
  BuildToolbar;

  { Tab strip — inserted between toolbar and workspace }
  FTabStrip := TPanel.Create(Self);
  FTabStrip.Parent := Self;
  FTabStrip.Align := alTop;
  FTabStrip.Height := 28;
  FTabStrip.BevelOuter := bvNone;
  FTabStrip.Caption := '';
  FTabStrip.Color := $00252C35;
  FTabStrip.ParentColor := False;

  FWorkspacePanel := TPanel.Create(Self);
  FWorkspacePanel.Parent := Self;
  FWorkspacePanel.Align := alClient;
  FWorkspacePanel.BevelOuter := bvNone;
  FWorkspacePanel.Caption := '';
  FWorkspacePanel.Color := WorkspaceBackgroundColor;

  FRulerTopBand := TPanel.Create(FWorkspacePanel);
  FRulerTopBand.Parent := FWorkspacePanel;
  FRulerTopBand.Align := alTop;
  FRulerTopBand.Height := RulerThickness;
  FRulerTopBand.BevelOuter := bvNone;
  FRulerTopBand.Caption := '';
  FRulerTopBand.Color := RulerBackgroundColor;
  FRulerTopBand.ParentColor := False;

  FRulerCorner := TPanel.Create(FRulerTopBand);
  FRulerCorner.Parent := FRulerTopBand;
  FRulerCorner.Align := alLeft;
  FRulerCorner.Width := RulerThickness;
  FRulerCorner.BevelOuter := bvNone;
  FRulerCorner.Caption := '';
  FRulerCorner.Color := RulerBackgroundColor;
  FRulerCorner.ParentColor := False;

  FHorizontalRuler := TRulerView.Create(FRulerTopBand);
  FHorizontalRuler.Parent := FRulerTopBand;
  FHorizontalRuler.Align := alClient;
  FHorizontalRuler.OwnerForm := Self;
  FHorizontalRuler.Orientation := roHorizontal;

  FVerticalRuler := TRulerView.Create(FWorkspacePanel);
  FVerticalRuler.Parent := FWorkspacePanel;
  FVerticalRuler.Align := alLeft;
  FVerticalRuler.Width := RulerThickness;
  FVerticalRuler.OwnerForm := Self;
  FVerticalRuler.Orientation := roVertical;

  FCanvasHost := TScrollBox.Create(FWorkspacePanel);
  FCanvasHost.Parent := FWorkspacePanel;
  FCanvasHost.Align := alClient;
  FCanvasHost.BorderStyle := bsNone;
  FCanvasHost.HorzScrollBar.Tracking := True;
  FCanvasHost.VertScrollBar.Tracking := True;
  FCanvasHost.Color := CanvasBackgroundColor;
  FCanvasHost.OnMouseWheel := @ViewportMouseWheel;
  FCanvasHost.OnResize := @CanvasHostResize;

  FPaintBox := TCanvasView.Create(FCanvasHost);
  FPaintBox.Parent := FCanvasHost;
  FPaintBox.OwnerForm := Self;
  FPaintBox.Left := 16;
  FPaintBox.Top := 16;
  FPaintBox.OnMouseWheel := @ViewportMouseWheel;
  FPaintBox.OnMouseDown := @PaintBoxMouseDown;
  FPaintBox.OnMouseMove := @PaintBoxMouseMove;
  FPaintBox.OnMouseUp := @PaintBoxMouseUp;

  BuildSidePanel;
  RefreshPaletteMenuChecks;

  FStatusBar := TPanel.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.Align := alBottom;
  FStatusBar.Height := 24;
  FStatusBar.Color := $00EFEFEF;
  FStatusBar.ParentColor := False;
  FStatusBar.BevelOuter := bvNone;
  FStatusBar.OnResize := @LayoutStatusBarControls;

  for I := 0 to 6 do
  begin
    FStatusLabels[I] := TLabel.Create(FStatusBar);
    FStatusLabels[I].Parent := FStatusBar;
    FStatusLabels[I].Layout := tlCenter;
    FStatusLabels[I].Font.Size := 9;
    FStatusLabels[I].Font.Color := clBlack;
    FStatusLabels[I].Transparent := True;
    FStatusLabels[I].AutoSize := False;
  end;

  FStatusZoomTrack := TTrackBar.Create(FStatusBar);
  FStatusZoomTrack.Parent := FStatusBar;
  FStatusZoomTrack.Min := ZoomSliderMin;
  FStatusZoomTrack.Max := ZoomSliderMax;
  FStatusZoomTrack.Position := ZoomSliderPositionForScale(FZoomScale);
  FStatusZoomTrack.TickStyle := tsNone;
  FStatusZoomTrack.OnChange := @StatusZoomTrackChange;

  FStatusZoomLabel := TLabel.Create(FStatusBar);
  FStatusZoomLabel.Parent := FStatusBar;
  FStatusZoomLabel.Alignment := taCenter;
  FStatusZoomLabel.Layout := tlCenter;
  FStatusZoomLabel.Transparent := True;
  FStatusZoomLabel.Cursor := crHandPoint;
  FStatusZoomLabel.Font.Size := 9;
  FStatusZoomLabel.Font.Color := clBlack;
  FStatusZoomLabel.Hint := 'Click to toggle between Fit and Actual Size';
  FStatusZoomLabel.ShowHint := True;
  FStatusZoomLabel.OnClick := @StatusZoomToggleClick;
  LayoutStatusBarControls(nil);
  RestorePaletteLayout;
  RefreshPaletteMenuChecks;

  UpdateCanvasSize;
  RefreshLayers;
  RefreshCanvas;
  RefreshStatus(Point(-1, -1));
  UpdateCaption;
  RefreshRulers;
  RefreshTabStrip;
  if Assigned(Application) then
    Application.AddOnIdleHandler(@AppIdle);
  GMainForm := Self;
end;

destructor TMainForm.Destroy;
var
  I: Integer;
begin
  if Assigned(Application) then
    Application.RemoveOnIdleHandler(@AppIdle);
  FRecentFiles.Free;
  FPreparedBitmap.Free;
  FDisplaySurface.Free;
  FClipboardSurface.Free;
  FCloneStampSnapshot.Free;
  { Free all tab documents (FDocument just refers to FTabDocuments[FActiveTabIndex]) }
  for I := 0 to Length(FTabDocuments) - 1 do
    FTabDocuments[I].Free;
  SetLength(FTabDocuments, 0);
  inherited Destroy;
end;

function TMainForm.ActivePaintColor: TRGBA32;
begin
  if FCurrentTool = tkEraser then
    Exit(TransparentColor);
  Result := FStrokeColor;
end;

function TMainForm.DisplayFileName: string;
begin
  if FCurrentFileName = '' then
    Result := 'Untitled'
  else
    Result := ExtractFileName(FCurrentFileName);
end;

function TMainForm.CanvasToImage(X, Y: Integer): TPoint;
begin
  Result.X := EnsureRange(Trunc(X / FZoomScale), 0, FDocument.Width - 1);
  Result.Y := EnsureRange(Trunc(Y / FZoomScale), 0, FDocument.Height - 1);
end;

function TMainForm.BuildDisplaySurface: TRasterSurface;
var
  CompositeSurface: TRasterSurface;
  X: Integer;
  Y: Integer;
  TileColor: TRGBA32;
  PixelColor: TRGBA32;
begin
  CompositeSurface := FDocument.Composite;
  try
    { Reuse FDisplaySurface to avoid a heap alloc + free on every repaint trigger.
      Only reallocate when the document dimensions change. }
    if (FDisplaySurface = nil) or
       (FDisplaySurface.Width <> CompositeSurface.Width) or
       (FDisplaySurface.Height <> CompositeSurface.Height) then
    begin
      FreeAndNil(FDisplaySurface);
      FDisplaySurface := TRasterSurface.Create(CompositeSurface.Width, CompositeSurface.Height);
    end;

    { Checkerboard + alpha blend in a single pass.
      Early-exit for fully-opaque pixels (the common case) avoids two div+mod
      and a branch per pixel, and defers TileColor calculation to only when
      the pixel is actually transparent or semi-transparent. }
    for Y := 0 to CompositeSurface.Height - 1 do
      for X := 0 to CompositeSurface.Width - 1 do
      begin
        PixelColor := CompositeSurface[X, Y];
        if PixelColor.A = 255 then
          FDisplaySurface[X, Y] := PixelColor  { fully opaque — copy directly }
        else
        begin
          { Compute tile colour only when the pixel is transparent or blended }
          if ((X shr 3) + (Y shr 3)) and 1 = 0 then
            TileColor := RGBA(214, 214, 214, 255)
          else
            TileColor := RGBA(245, 245, 245, 255);
          if PixelColor.A = 0 then
            FDisplaySurface[X, Y] := TileColor
          else
            FDisplaySurface[X, Y] := BlendNormal(PixelColor, TileColor, 255);
        end;
      end;
  finally
    CompositeSurface.Free;
  end;

  { Selection outline pass }
  if FDocument.HasSelection then
    for Y := 0 to FDisplaySurface.Height - 1 do
      for X := 0 to FDisplaySurface.Width - 1 do
        if FDocument.Selection[X, Y] and
           (
             (not FDocument.Selection[X - 1, Y]) or
             (not FDocument.Selection[X + 1, Y]) or
             (not FDocument.Selection[X, Y - 1]) or
             (not FDocument.Selection[X, Y + 1])
           ) then
          if ((X + Y) and 1) = 0 then
            FDisplaySurface[X, Y] := RGBA(0, 0, 0, 255)
          else
            FDisplaySurface[X, Y] := RGBA(255, 255, 255, 255);

  { Return the cached surface — caller must NOT free it }
  Result := FDisplaySurface;
end;

function TMainForm.ToolHintText: string;
begin
  Result := PaintToolHint(FCurrentTool);
end;

function TMainForm.ImageOriginInViewport: TPoint;
begin
  if not Assigned(FCanvasHost) or not Assigned(FPaintBox) then
    Exit(Point(0, 0));
  Result := Point(
    FPaintBox.Left - FCanvasHost.HorzScrollBar.Position,
    FPaintBox.Top - FCanvasHost.VertScrollBar.Position
  );
end;

function TMainForm.DisplayUnitSuffix: string;
begin
  case FDisplayUnit of
    duInches:
      Result := 'in';
    duCentimeters:
      Result := 'cm';
  else
    Result := 'px';
  end;
end;

function TMainForm.PixelsToDisplayValue(APixels: Integer): Double;
begin
  case FDisplayUnit of
    duInches:
      Result := APixels / DisplayDPI;
    duCentimeters:
      Result := (APixels / DisplayDPI) * 2.54;
  else
    Result := APixels;
  end;
end;

function TMainForm.DisplayValueToPixels(AValue: Double): Double;
begin
  case FDisplayUnit of
    duInches:
      Result := AValue * DisplayDPI;
    duCentimeters:
      Result := (AValue / 2.54) * DisplayDPI;
  else
    Result := AValue;
  end;
end;

function TMainForm.FormatMeasurement(APixels: Integer): string;
begin
  if FDisplayUnit = duPixels then
    Result := IntToStr(APixels)
  else
    Result := FormatFloat('0.00', PixelsToDisplayValue(APixels));
end;

function TMainForm.ParseMeasurementText(const AText: string; AFallbackPixels: Integer): Integer;
var
  ParsedValue: Double;
  FormatSettings: TFormatSettings;
  NormalizedText: string;
begin
  if FDisplayUnit = duPixels then
    Exit(Max(1, StrToIntDef(Trim(AText), AFallbackPixels)));

  NormalizedText := Trim(AText);
  if NormalizedText = '' then
    Exit(Max(1, AFallbackPixels));

  FormatSettings := DefaultFormatSettings;
  if FormatSettings.DecimalSeparator = ',' then
    NormalizedText := StringReplace(NormalizedText, '.', ',', [rfReplaceAll])
  else
    NormalizedText := StringReplace(NormalizedText, ',', '.', [rfReplaceAll]);

  if not TryStrToFloat(NormalizedText, ParsedValue, FormatSettings) then
    Exit(Max(1, AFallbackPixels));
  Result := Max(1, Round(DisplayValueToPixels(ParsedValue)));
end;

function TMainForm.PromptForSize(const ATitle: string; out AWidth, AHeight: Integer): Boolean;
var
  WidthText: string;
  HeightText: string;
  PromptSuffix: string;
begin
  WidthText := FormatMeasurement(FDocument.Width);
  HeightText := FormatMeasurement(FDocument.Height);
  PromptSuffix := DisplayUnitSuffix;
  Result := False;
  if not InputQuery(ATitle, 'Width in ' + PromptSuffix, WidthText) then
    Exit;
  if not InputQuery(ATitle, 'Height in ' + PromptSuffix, HeightText) then
    Exit;
  AWidth := ParseMeasurementText(WidthText, FDocument.Width);
  AHeight := ParseMeasurementText(HeightText, FDocument.Height);
  Result := True;
end;

function TMainForm.SelectionModeFromShift(const Shift: TShiftState): TSelectionCombineMode;
begin
  // Map modifiers similar to GIMP: Shift = Add, Ctrl = Subtract, Shift+Ctrl = Intersect
  // Map modifiers to Photoshop habit: Shift = Add, Alt/Option = Subtract, Shift+Alt = Intersect
  if (ssShift in Shift) and (ssAlt in Shift) then
    Result := scIntersect
  else if ssAlt in Shift then
    Result := scSubtract
  else if ssShift in Shift then
    Result := scAdd
  else
    Result := scReplace;
end;

procedure TMainForm.AppendLassoPoint(const APoint: TPoint);
var
  PointCount: Integer;
begin
  PointCount := Length(FLassoPoints);
  if (PointCount > 0) and
     (FLassoPoints[PointCount - 1].X = APoint.X) and
     (FLassoPoints[PointCount - 1].Y = APoint.Y) then
    Exit;
  SetLength(FLassoPoints, PointCount + 1);
  FLassoPoints[PointCount] := APoint;
end;

procedure TMainForm.InvalidatePreparedBitmap;
begin
  Inc(FRenderRevision);
end;

procedure TMainForm.UpdateToolOptionControl;
var
  IsSelTool: Boolean;
  IsSizeTool: Boolean;
  IsOpacityTool: Boolean;
  IsHardnessTool: Boolean;
  IsShapeTool: Boolean;
  IsBucketTool: Boolean;
begin
  if not Assigned(FBrushSpin) or not Assigned(FOptionLabel) then
    Exit;

  IsSelTool := FCurrentTool in [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand];
  IsOpacityTool := FCurrentTool in [tkPencil, tkBrush, tkEraser, tkCloneStamp, tkRecolor];
  IsHardnessTool := FCurrentTool in [tkBrush, tkEraser];
  IsShapeTool := FCurrentTool in [tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape];
  IsBucketTool := FCurrentTool = tkFill;
  IsSizeTool := FCurrentTool in [tkPencil, tkBrush, tkEraser, tkLine,
    tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape,
    tkCloneStamp, tkRecolor, tkMagicWand];

  if Assigned(FSelModeLabel) then FSelModeLabel.Visible := IsSelTool;
  if Assigned(FSelModeCombo) then FSelModeCombo.Visible := IsSelTool;
  if Assigned(FOpacityLabel) then FOpacityLabel.Visible := IsOpacityTool;
  if Assigned(FOpacitySpin) then FOpacitySpin.Visible := IsOpacityTool;
  if Assigned(FOpacitySpin) then FOpacitySpin.Value := FBrushOpacity;
  if Assigned(FHardnessLabel) then FHardnessLabel.Visible := IsHardnessTool;
  if Assigned(FHardnessSpin) then FHardnessSpin.Visible := IsHardnessTool;
  if Assigned(FHardnessSpin) then FHardnessSpin.Value := FBrushHardness;
  if Assigned(FShapeStyleLabel) then FShapeStyleLabel.Visible := IsShapeTool;
  if Assigned(FShapeStyleCombo) then FShapeStyleCombo.Visible := IsShapeTool;
  if Assigned(FShapeStyleCombo) then FShapeStyleCombo.ItemIndex := FShapeStyle;
  if Assigned(FBucketModeLabel) then FBucketModeLabel.Visible := IsBucketTool;
  if Assigned(FBucketModeCombo) then FBucketModeCombo.Visible := IsBucketTool;
  if Assigned(FBucketModeCombo) then FBucketModeCombo.ItemIndex := FBucketFloodMode;
  if Assigned(FWandSampleLabel) then FWandSampleLabel.Visible := FCurrentTool = tkMagicWand;
  if Assigned(FWandSampleCombo) then FWandSampleCombo.Visible := FCurrentTool = tkMagicWand;
  if Assigned(FWandSampleCombo) then FWandSampleCombo.ItemIndex := FWandSampleSource;
  if Assigned(FWandContiguousCheck) then FWandContiguousCheck.Visible := FCurrentTool = tkMagicWand;
  if Assigned(FWandContiguousCheck) then FWandContiguousCheck.Checked := FWandContiguous;
  if Assigned(FFillTolLabel) then FFillTolLabel.Visible := IsBucketTool;
  if Assigned(FFillTolSpin) then FFillTolSpin.Visible := IsBucketTool;
  if Assigned(FFillTolSpin) then FFillTolSpin.Value := FFillTolerance;
  if Assigned(FGradientTypeLabel) then FGradientTypeLabel.Visible := FCurrentTool = tkGradient;
  if Assigned(FGradientTypeCombo) then FGradientTypeCombo.Visible := FCurrentTool = tkGradient;
  if Assigned(FGradientTypeCombo) then FGradientTypeCombo.ItemIndex := FGradientType;
  if Assigned(FGradientReverseCheck) then FGradientReverseCheck.Visible := FCurrentTool = tkGradient;
  if Assigned(FGradientReverseCheck) then FGradientReverseCheck.Checked := FGradientReverse;
  if Assigned(FPickerSampleLabel) then FPickerSampleLabel.Visible := FCurrentTool = tkColorPicker;
  if Assigned(FPickerSampleCombo) then FPickerSampleCombo.Visible := FCurrentTool = tkColorPicker;
  if Assigned(FPickerSampleCombo) then FPickerSampleCombo.ItemIndex := FPickerSampleSource;
  if Assigned(FSelAntiAliasCheck) then FSelAntiAliasCheck.Visible := FCurrentTool in [tkSelectRect, tkSelectEllipse, tkSelectLasso];

  FUpdatingToolOption := True;
  try
    case FCurrentTool of
      tkPencil, tkBrush, tkEraser, tkLine, tkRectangle, tkRoundedRectangle,
      tkEllipseShape, tkFreeformShape, tkCloneStamp, tkRecolor:
        begin
          FOptionLabel.Caption := 'Size:';
          FBrushSpin.Enabled := True;
          FBrushSpin.MinValue := 1;
          FBrushSpin.MaxValue := 255;
          FBrushSpin.Value := FBrushSize;
        end;
      tkMagicWand:
        begin
          FOptionLabel.Caption := 'Tolerance:';
          FBrushSpin.Enabled := True;
          FBrushSpin.MinValue := 0;
          FBrushSpin.MaxValue := 255;
          FBrushSpin.Value := FWandTolerance;
        end;
      tkSelectRect, tkSelectEllipse, tkSelectLasso:
        begin
          FOptionLabel.Caption := '';
          FBrushSpin.Enabled := False;
          FBrushSpin.Value := 0;
          { Sync selection mode combo }
          if Assigned(FSelModeCombo) then
            FSelModeCombo.ItemIndex := Ord(FPendingSelectionMode);
        end;
    else
      begin
        FOptionLabel.Caption := '';
        FBrushSpin.Enabled := False;
        FBrushSpin.Value := FBrushSize;
      end;
    end;
  finally
    FUpdatingToolOption := False;
  end;
end;

procedure TMainForm.RefreshUnitsMenu;
begin
  if Assigned(FUnitPixelsItem) then
    FUnitPixelsItem.Checked := FDisplayUnit = duPixels;
  if Assigned(FUnitInchesItem) then
    FUnitInchesItem.Checked := FDisplayUnit = duInches;
  if Assigned(FUnitCentimetersItem) then
    FUnitCentimetersItem.Checked := FDisplayUnit = duCentimeters;
  if Assigned(FStatusBar) then
    RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.BuildTabPopupMenu;
var
  Item: TMenuItem;
begin
  FTabPopupMenu := TPopupMenu.Create(Self);
  
  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := '&New Tab';
  Item.OnClick := @TabMenuNewClick;
  FTabPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := '-';
  FTabPopupMenu.Items.Add(Item);
  
  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := '&Close';
  Item.OnClick := @TabMenuCloseClick;
  FTabPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := 'Close &Other Tabs';
  Item.OnClick := @TabMenuCloseOthersClick;
  FTabPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := 'Close Tabs to the &Right';
  Item.OnClick := @TabMenuCloseRightClick;
  FTabPopupMenu.Items.Add(Item);
end;

procedure TMainForm.BuildMenus;
var
  FileMenu: TMenuItem;
  EditMenu: TMenuItem;
  LayerMenu: TMenuItem;
  ImageMenu: TMenuItem;
  ViewMenu: TMenuItem;
  AdjustMenu: TMenuItem;
  EffectsMenu: TMenuItem;
  PaletteMenuItem: TMenuItem;
  PaletteKind: TPaletteKind;
begin
  FMainMenu := TMainMenu.Create(Self);

  FileMenu := TMenuItem.Create(FMainMenu);
  FileMenu.Caption := '&File';
  FMainMenu.Items.Add(FileMenu);
  CreateMenuItem(FileMenu, '&New...', @NewDocumentClick, ShortCut(VK_N, [ssMeta]));
  CreateMenuItem(FileMenu, '&Open...', @OpenDocumentClick, ShortCut(VK_O, [ssMeta]));
  FRecentMenu := TMenuItem.Create(FileMenu);
  FRecentMenu.Caption := 'Open &Recent';
  FileMenu.Add(FRecentMenu);
  RebuildRecentFilesMenu;
  CreateMenuItem(FileMenu, '&Acquire...', @AcquireClick);
  CreateMenuItem(FileMenu, 'Import as &Layer...', @ImportLayerClick, ShortCut(VK_I, [ssMeta, ssShift]));
  FileMenu.AddSeparator;
  CreateMenuItem(FileMenu, '&Close', @CloseDocumentClick, ShortCut(VK_W, [ssMeta]));
  FSaveMenuItem := TMenuItem.Create(FileMenu);
  FSaveMenuItem.Caption := SaveCommandCaption(FCurrentFileName <> '');
  FSaveMenuItem.OnClick := @SaveDocumentClick;
  FSaveMenuItem.ShortCut := ShortCut(VK_S, [ssMeta]);
  FileMenu.Add(FSaveMenuItem);
  CreateMenuItem(FileMenu, 'Save &As...', @SaveAsDocumentClick, ShortCut(VK_S, [ssMeta, ssShift]));
  CreateMenuItem(FileMenu, 'Save A&ll Images', @SaveAllDocumentsClick, ShortCut(VK_S, [ssMeta, ssAlt]));
  CreateMenuItem(FileMenu, '&Print...', @PrintDocumentClick, ShortCut(VK_P, [ssMeta]));
  FileMenu.AddSeparator;
  CreateMenuItem(FileMenu, 'E&xit', @ExitApplicationClick, ShortCut(VK_Q, [ssMeta]));

  EditMenu := TMenuItem.Create(FMainMenu);
  EditMenu.Caption := '&Edit';
  FMainMenu.Items.Add(EditMenu);
  CreateMenuItem(EditMenu, '&Undo', @UndoClick, ShortCut(VK_Z, [ssMeta]));
  CreateMenuItem(EditMenu, '&Redo', @RedoClick, ShortCut(VK_Z, [ssMeta, ssShift]));
  CreateMenuItem(EditMenu, 'Cu&t', @CutClick, ShortCut(VK_X, [ssMeta]));
  CreateMenuItem(EditMenu, '&Copy', @CopyClick, ShortCut(VK_C, [ssMeta]));
  CreateMenuItem(EditMenu, 'Copy Selection', @CopySelectionClick);
  CreateMenuItem(EditMenu, 'Copy &Merged', @CopyMergedClick, ShortCut(VK_C, [ssMeta, ssShift]));
  CreateMenuItem(EditMenu, '&Paste', @PasteClick, ShortCut(VK_V, [ssMeta]));
  CreateMenuItem(EditMenu, 'Paste into New Layer', @PasteIntoNewLayerClick);
  CreateMenuItem(EditMenu, 'Paste into New Image', @PasteIntoNewImageClick);
  CreateMenuItem(EditMenu, 'Paste &Selection (Replace)', @PasteSelectionClick);
  CreateMenuItem(EditMenu, 'Select &All', @SelectAllClick, ShortCut(VK_A, [ssMeta]));
  CreateMenuItem(EditMenu, '&Deselect', @DeselectClick, ShortCut(VK_D, [ssMeta]));
  CreateMenuItem(EditMenu, '&Invert Selection', @InvertSelectionClick, ShortCut(VK_I, [ssMeta, ssAlt]));
  CreateMenuItem(EditMenu, 'Fill Selection', @FillSelectionClick);
  CreateMenuItem(EditMenu, 'Erase Selection', @EraseSelectionClick, VK_DELETE);
  CreateMenuItem(EditMenu, 'Crop To Selection', @CropToSelectionClick);

  LayerMenu := TMenuItem.Create(FMainMenu);
  LayerMenu.Caption := '&Layers';
  FMainMenu.Items.Add(LayerMenu);
  CreateMenuItem(LayerMenu, '&Add Layer', @AddLayerClick, ShortCut(VK_N, [ssMeta, ssShift]));
  CreateMenuItem(LayerMenu, '&Duplicate Layer', @DuplicateLayerClick, ShortCut(VK_D, [ssMeta, ssShift]));
  CreateMenuItem(LayerMenu, '&Delete Layer', @DeleteLayerClick, ShortCut(VK_DELETE, [ssMeta]));
  CreateMenuItem(LayerMenu, '&Rename Layer...', @RenameLayerClick);
  CreateMenuItem(LayerMenu, 'Move Layer &Up', @MoveLayerUpClick);
  CreateMenuItem(LayerMenu, 'Move Layer &Down', @MoveLayerDownClick);
  CreateMenuItem(LayerMenu, '&Merge Down', @MergeDownClick, ShortCut(VK_M, [ssMeta, ssShift]));
  CreateMenuItem(LayerMenu, 'Toggle &Visibility', @ToggleLayerVisibilityClick);
  CreateMenuItem(LayerMenu, 'Layer &Opacity...', @LayerOpacityClick);
  LayerMenu.AddSeparator;
  CreateMenuItem(LayerMenu, 'Import From &File...', @ImportLayerClick);
  CreateMenuItem(LayerMenu, 'Layer &Properties...', @LayerPropertiesClick);
  LayerMenu.AddSeparator;
  CreateMenuItem(LayerMenu, 'Rotate / &Zoom...', @LayerRotateZoomClick);

  ImageMenu := TMenuItem.Create(FMainMenu);
  ImageMenu.Caption := '&Image';
  FMainMenu.Items.Add(ImageMenu);
  CreateMenuItem(ImageMenu, 'Resize &Image...', @ResizeImageClick);
  CreateMenuItem(ImageMenu, 'Resize &Canvas...', @ResizeCanvasClick);
  CreateMenuItem(ImageMenu, 'Rotate 90 &Right', @RotateClockwiseClick);
  CreateMenuItem(ImageMenu, 'Rotate 90 &Left', @RotateCounterClockwiseClick);
  CreateMenuItem(ImageMenu, 'Rotate &180', @Rotate180Click);
  CreateMenuItem(ImageMenu, 'Flip &Horizontal', @FlipHorizontalClick);
  CreateMenuItem(ImageMenu, 'Flip &Vertical', @FlipVerticalClick);
  CreateMenuItem(ImageMenu, '&Flatten', @FlattenClick, ShortCut(VK_F, [ssMeta, ssShift]));

  ViewMenu := TMenuItem.Create(FMainMenu);
  ViewMenu.Caption := '&View';
  FMainMenu.Items.Add(ViewMenu);
  CreateMenuItem(ViewMenu, 'Zoom &In', @ZoomInClick, ShortCut(Ord('='), [ssMeta]));
  CreateMenuItem(ViewMenu, 'Zoom &Out', @ZoomOutClick, ShortCut(Ord('-'), [ssMeta]));
  CreateMenuItem(ViewMenu, 'Zoom to &Selection', @ZoomToSelectionClick);
  CreateMenuItem(ViewMenu, '-', nil);
  CreateMenuItem(ViewMenu, 'Next Tab', @NextTabClick, ShortCut(VK_TAB, [ssCtrl]));
  CreateMenuItem(ViewMenu, 'Previous Tab', @PrevTabClick, ShortCut(VK_TAB, [ssCtrl, ssShift]));
  CreateMenuItem(ViewMenu, '-', nil);
  CreateMenuItem(ViewMenu, '&Actual Size', @ActualSizeClick, ShortCut(VK_0, [ssMeta]));
  CreateMenuItem(ViewMenu, 'Zoom to &Window', @FitToWindowClick, ShortCut(VK_9, [ssMeta]));
  FPixelGridMenuItem := TMenuItem.Create(ViewMenu);
  FPixelGridMenuItem.Caption := 'Pixel &Grid';
  FPixelGridMenuItem.Checked := FShowPixelGrid;
  FPixelGridMenuItem.ShortCut := ShortCut(39, [ssMeta]);
  FPixelGridMenuItem.OnClick := @TogglePixelGridClick;
  ViewMenu.Add(FPixelGridMenuItem);
  FRulersMenuItem := TMenuItem.Create(ViewMenu);
  FRulersMenuItem.Caption := '&Rulers';
  FRulersMenuItem.Checked := FShowRulers;
  FRulersMenuItem.ShortCut := ShortCut(VK_R, [ssMeta, ssAlt]);
  FRulersMenuItem.OnClick := @ToggleRulersClick;
  ViewMenu.Add(FRulersMenuItem);
  FUnitsMenu := TMenuItem.Create(ViewMenu);
  FUnitsMenu.Caption := '&Units';
  ViewMenu.Add(FUnitsMenu);
  FUnitPixelsItem := TMenuItem.Create(FUnitsMenu);
  FUnitPixelsItem.Caption := '&Pixels';
  FUnitPixelsItem.OnClick := @UnitsPixelsClick;
  FUnitsMenu.Add(FUnitPixelsItem);
  FUnitInchesItem := TMenuItem.Create(FUnitsMenu);
  FUnitInchesItem.Caption := '&Inches';
  FUnitInchesItem.OnClick := @UnitsInchesClick;
  FUnitsMenu.Add(FUnitInchesItem);
  FUnitCentimetersItem := TMenuItem.Create(FUnitsMenu);
  FUnitCentimetersItem.Caption := '&Centimeters';
  FUnitCentimetersItem.OnClick := @UnitsCentimetersClick;
  FUnitsMenu.Add(FUnitCentimetersItem);
  RefreshUnitsMenu;
  ViewMenu.AddSeparator;
  for PaletteKind := Low(TPaletteKind) to High(TPaletteKind) do
  begin
    PaletteMenuItem := TMenuItem.Create(ViewMenu);
    PaletteMenuItem.Caption := PaletteTitle(PaletteKind);
    PaletteMenuItem.Tag := Ord(PaletteKind);
    PaletteMenuItem.ShortCut := ShortCut(Ord(PaletteShortcutDigit(PaletteKind)), [ssMeta]);
    PaletteMenuItem.OnClick := @TogglePaletteViewClick;
    ViewMenu.Add(PaletteMenuItem);
    FPaletteViewItems[PaletteKind] := PaletteMenuItem;
  end;
  CreateMenuItem(ViewMenu, 'Reset Window Layout', @ResetPaletteLayoutClick);

  AdjustMenu := TMenuItem.Create(FMainMenu);
  AdjustMenu.Caption := '&Adjustments';
  FMainMenu.Items.Add(AdjustMenu);
  CreateMenuItem(AdjustMenu, '&Auto-Level', @AutoLevelClick);
  CreateMenuItem(AdjustMenu, '&Invert Colors', @InvertColorsClick);
  CreateMenuItem(AdjustMenu, '&Grayscale', @GrayscaleClick);
  CreateMenuItem(AdjustMenu, '&Curves...', @CurvesClick);
  CreateMenuItem(AdjustMenu, '&Hue / Saturation...', @HueSaturationClick);
  CreateMenuItem(AdjustMenu, '&Levels...', @LevelsClick);
  CreateMenuItem(AdjustMenu, '&Brightness / Contrast...', @BrightnessContrastClick);
  CreateMenuItem(AdjustMenu, '&Sepia', @SepiaClick);
  CreateMenuItem(AdjustMenu, 'Black and &White...', @BlackAndWhiteClick);
  CreateMenuItem(AdjustMenu, '&Posterize...', @PosterizeClick);

  EffectsMenu := TMenuItem.Create(FMainMenu);
  EffectsMenu.Caption := 'Effe&cts';
  FMainMenu.Items.Add(EffectsMenu);
  FRepeatLastEffectItem := TMenuItem.Create(FMainMenu);
  FRepeatLastEffectItem.Caption := 'Repeat Last Effect';
  FRepeatLastEffectItem.OnClick := @RepeatLastEffectClick;
  FRepeatLastEffectItem.ShortCut := ShortCut(Ord('F'), [ssMeta]);
  FRepeatLastEffectItem.Enabled := False;
  EffectsMenu.Add(FRepeatLastEffectItem);
  CreateMenuItem(EffectsMenu, '-', nil);
  CreateMenuItem(EffectsMenu, '&Blur...', @BlurClick);
  CreateMenuItem(EffectsMenu, '&Sharpen', @SharpenClick);
  CreateMenuItem(EffectsMenu, 'Add &Noise...', @AddNoiseClick);
  CreateMenuItem(EffectsMenu, 'Detect &Edges', @OutlineClick);
  CreateMenuItem(EffectsMenu, 'Outline Effe&ct...', @OutlineEffectClick);
  CreateMenuItem(EffectsMenu, '-', nil);
  CreateMenuItem(EffectsMenu, '&Emboss', @EmbossClick);
  CreateMenuItem(EffectsMenu, 'S&often', @SoftenClick);
  CreateMenuItem(EffectsMenu, 'Render &Clouds', @RenderCloudsClick);
  CreateMenuItem(EffectsMenu, '-', nil);
  CreateMenuItem(EffectsMenu, '&Pixelate...', @PixelateClick);
  CreateMenuItem(EffectsMenu, '&Vignette...', @VignetteClick);
  CreateMenuItem(EffectsMenu, '&Motion Blur...', @MotionBlurClick);
  CreateMenuItem(EffectsMenu, '&Median / Denoise...', @MedianFilterClick);
  CreateMenuItem(EffectsMenu, '&Glow...', @GlowClick);
  CreateMenuItem(EffectsMenu, '&Oil Paint...', @OilPaintClick);
  CreateMenuItem(EffectsMenu, '&Frosted Glass...', @FrostedGlassClick);
  CreateMenuItem(EffectsMenu, '&Zoom Blur...', @ZoomBlurClick);

  Menu := FMainMenu;
end;

procedure TMainForm.BuildToolbar;
var
  LabelCtrl: TLabel;
  ToolIndex: Integer;
  ToolKind: TToolKind;
  UtilityPanel: TPanel;
  UtilityButton: TButton;
  UtilityIndex: Integer;
  UtilityCommand: TUtilityCommandKind;
  ZoomIndex: Integer;
  Btn: TButton;
begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 66;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';
  FTopPanel.Color := ToolbarBackgroundColor;
  FTopPanel.ParentColor := False;

  { Toolbar row 1: File | Edit | Undo/Redo | Zoom  (~730 px total, all <= 1280-wide windows) }
  Btn := CreateButton('📄 New',   10,  8, 62, @NewDocumentClick,  FTopPanel); Btn.Hint := 'New document (Cmd+N)';
  Btn := CreateButton('📂 Open',  76,  8, 66, @OpenDocumentClick,  FTopPanel); Btn.Hint := 'Open document (Cmd+O)';
  Btn := CreateButton('💾 Save', 146,  8, 62, @SaveDocumentClick,  FTopPanel); Btn.Hint := 'Save document (Cmd+S)';
  Btn := CreateButton('✂️ Cut',  220,  8, 56, @CutClick,           FTopPanel); Btn.Hint := 'Cut selection (Cmd+X)';
  Btn := CreateButton('📋 Copy', 280,  8, 62, @CopyClick,          FTopPanel); Btn.Hint := 'Copy selection (Cmd+C)';
  Btn := CreateButton('📌 Paste',346,  8, 66, @PasteClick,         FTopPanel); Btn.Hint := 'Paste (Cmd+V)';
  Btn := CreateButton('↩ Undo',  424,  8, 62, @UndoClick,          FTopPanel); Btn.Hint := 'Undo last action (Cmd+Z)';
  Btn := CreateButton('↪ Redo',  490,  8, 62, @RedoClick,          FTopPanel); Btn.Hint := 'Redo (Cmd+Shift+Z)';
  Btn := CreateButton('🔎-',     560,  8, 42, @ZoomOutClick,       FTopPanel); Btn.Hint := 'Zoom out';

  FZoomCombo := TComboBox.Create(FTopPanel);
  FZoomCombo.Parent := FTopPanel;
  FZoomCombo.Left := 606;
  FZoomCombo.Top := 8;
  FZoomCombo.Width := 74;
  FZoomCombo.Style := csDropDownList;
  for ZoomIndex := 0 to ZoomPresetCount - 1 do
    FZoomCombo.Items.Add(ZoomPresetCaption(ZoomIndex));
  FZoomCombo.OnChange := @ZoomComboChange;

  Btn := CreateButton('🔎+', 684, 8, 42, @ZoomInClick, FTopPanel); Btn.Hint := 'Zoom in';

  UtilityPanel := TPanel.Create(FTopPanel);
  UtilityPanel.Parent := FTopPanel;
  UtilityPanel.Left := 1194;
  UtilityPanel.Top := 8;
  UtilityPanel.Width := 158;
  UtilityPanel.Height := 24;
  UtilityPanel.BevelOuter := bvNone;
  UtilityPanel.Caption := '';
  UtilityPanel.Color := ToolbarBackgroundColor;
  UtilityPanel.Anchors := [akTop, akRight];
  for UtilityIndex := 0 to UtilityCommandDisplayCount - 1 do
  begin
    UtilityCommand := UtilityCommandAtDisplayIndex(UtilityIndex);
    UtilityButton := TButton.Create(UtilityPanel);
    UtilityButton.Parent := UtilityPanel;
    UtilityButton.Left := UtilityIndex * 26;
    UtilityButton.Top := 0;
    UtilityButton.Width := 24;
    UtilityButton.Height := 24;
    UtilityButton.Caption := UtilityCommandGlyph(UtilityCommand);
    UtilityButton.Tag := Ord(UtilityCommand);
    UtilityButton.Hint := UtilityCommandHint(UtilityCommand);
    UtilityButton.ShowHint := True;
    UtilityButton.OnClick := @UtilityButtonClick;
  end;

  LabelCtrl := TLabel.Create(FTopPanel);
  LabelCtrl.Parent := FTopPanel;
  LabelCtrl.Caption := 'Tool:';
  LabelCtrl.Font.Color := clWhite;
  LabelCtrl.Left := 10;
  LabelCtrl.Top := 41;

  FToolCombo := TComboBox.Create(FTopPanel);
  FToolCombo.Parent := FTopPanel;
  FToolCombo.Left := 46;
  FToolCombo.Top := 36;
  FToolCombo.Width := 164;
  FToolCombo.Style := csDropDownList;
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
  begin
    ToolKind := PaintToolAtDisplayIndex(ToolIndex);
    FToolCombo.Items.AddObject(
      PaintToolName(ToolKind),
      TObject(PtrInt(Ord(ToolKind)))
    );
  end;
  FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
  FToolCombo.OnChange := @ToolComboChange;
  FToolCombo.Hint := 'Choose the active tool';
  FToolCombo.ShowHint := True;

  FOptionLabel := TLabel.Create(FTopPanel);
  FOptionLabel.Parent := FTopPanel;
  FOptionLabel.Caption := 'Size:';
  FOptionLabel.Font.Color := clWhite;
  FOptionLabel.Left := 220;
  FOptionLabel.Top := 41;

  FBrushSpin := TSpinEdit.Create(FTopPanel);
  FBrushSpin.Parent := FTopPanel;
  FBrushSpin.Left := 272;
  FBrushSpin.Top := 36;
  FBrushSpin.Width := 66;
  FBrushSpin.MinValue := 1;
  FBrushSpin.MaxValue := 255;
  FBrushSpin.Value := FBrushSize;
  FBrushSpin.OnChange := @BrushSizeChanged;

  FOpacityLabel := TLabel.Create(FTopPanel);
  FOpacityLabel.Parent := FTopPanel;
  FOpacityLabel.Caption := 'Opacity:';
  FOpacityLabel.Font.Color := clWhite;
  FOpacityLabel.Left := 348;
  FOpacityLabel.Top := 41;
  FOpacityLabel.Visible := False;

  FOpacitySpin := TSpinEdit.Create(FTopPanel);
  FOpacitySpin.Parent := FTopPanel;
  FOpacitySpin.Left := 408;
  FOpacitySpin.Top := 36;
  FOpacitySpin.Width := 60;
  FOpacitySpin.MinValue := 1;
  FOpacitySpin.MaxValue := 100;
  FOpacitySpin.Value := 100;
  FOpacitySpin.Visible := False;
  FOpacitySpin.OnChange := @OpacitySpinChanged;
  FOpacitySpin.Hint := 'Brush opacity (1-100)';
  FOpacitySpin.ShowHint := True;

  FHardnessLabel := TLabel.Create(FTopPanel);
  FHardnessLabel.Parent := FTopPanel;
  FHardnessLabel.Caption := 'Hardness:';
  FHardnessLabel.Font.Color := clWhite;
  FHardnessLabel.Left := 480;
  FHardnessLabel.Top := 41;
  FHardnessLabel.Visible := False;

  FHardnessSpin := TSpinEdit.Create(FTopPanel);
  FHardnessSpin.Parent := FTopPanel;
  FHardnessSpin.Left := 554;
  FHardnessSpin.Top := 36;
  FHardnessSpin.Width := 60;
  FHardnessSpin.MinValue := 1;
  FHardnessSpin.MaxValue := 100;
  FHardnessSpin.Value := 100;
  FHardnessSpin.Visible := False;
  FHardnessSpin.OnChange := @HardnessSpinChanged;
  FHardnessSpin.Hint := 'Brush hardness (1=soft, 100=hard)';
  FHardnessSpin.ShowHint := True;

  FSelModeLabel := TLabel.Create(FTopPanel);
  FSelModeLabel.Parent := FTopPanel;
  FSelModeLabel.Caption := 'Mode:';
  FSelModeLabel.Font.Color := clWhite;
  FSelModeLabel.Left := 348;
  FSelModeLabel.Top := 41;
  FSelModeLabel.Visible := False;

  FSelModeCombo := TComboBox.Create(FTopPanel);
  FSelModeCombo.Parent := FTopPanel;
  FSelModeCombo.Left := 394;
  FSelModeCombo.Top := 36;
  FSelModeCombo.Width := 96;
  FSelModeCombo.Style := csDropDownList;
  FSelModeCombo.Items.Add('Replace');
  FSelModeCombo.Items.Add('Add');
  FSelModeCombo.Items.Add('Subtract');
  FSelModeCombo.Items.Add('Intersect');
  FSelModeCombo.ItemIndex := 0;
  FSelModeCombo.Visible := False;
  FSelModeCombo.OnChange := @SelModeComboChanged;
  FSelModeCombo.Hint := 'Selection combination mode';
  FSelModeCombo.ShowHint := True;

  { Shape style combo: Outline / Fill / Outline+Fill }
  FShapeStyleLabel := TLabel.Create(FTopPanel);
  FShapeStyleLabel.Parent := FTopPanel;
  FShapeStyleLabel.Caption := 'Draw:';
  FShapeStyleLabel.Font.Color := clWhite;
  FShapeStyleLabel.Left := 348;
  FShapeStyleLabel.Top := 41;
  FShapeStyleLabel.Visible := False;

  FShapeStyleCombo := TComboBox.Create(FTopPanel);
  FShapeStyleCombo.Parent := FTopPanel;
  FShapeStyleCombo.Left := 394;
  FShapeStyleCombo.Top := 36;
  FShapeStyleCombo.Width := 116;
  FShapeStyleCombo.Style := csDropDownList;
  FShapeStyleCombo.Items.Add('Outline');
  FShapeStyleCombo.Items.Add('Fill');
  FShapeStyleCombo.Items.Add('Outline + Fill');
  FShapeStyleCombo.ItemIndex := 0;
  FShapeStyleCombo.Visible := False;
  FShapeStyleCombo.OnChange := @ShapeStyleComboChanged;
  FShapeStyleCombo.Hint := 'Shape draw style';
  FShapeStyleCombo.ShowHint := True;

  { Bucket fill mode combo: Contiguous / Global }
  FBucketModeLabel := TLabel.Create(FTopPanel);
  FBucketModeLabel.Parent := FTopPanel;
  FBucketModeLabel.Caption := 'Fill:';
  FBucketModeLabel.Font.Color := clWhite;
  FBucketModeLabel.Left := 348;
  FBucketModeLabel.Top := 41;
  FBucketModeLabel.Visible := False;

  FBucketModeCombo := TComboBox.Create(FTopPanel);
  FBucketModeCombo.Parent := FTopPanel;
  FBucketModeCombo.Left := 384;
  FBucketModeCombo.Top := 36;
  FBucketModeCombo.Width := 110;
  FBucketModeCombo.Style := csDropDownList;
  FBucketModeCombo.Items.Add('Contiguous');
  FBucketModeCombo.Items.Add('Global');
  FBucketModeCombo.ItemIndex := 0;
  FBucketModeCombo.Visible := False;
  FBucketModeCombo.OnChange := @BucketModeComboChanged;
  FBucketModeCombo.Hint := 'Fill mode';
  FBucketModeCombo.ShowHint := True;

  { Magic wand sample source combo: Current Layer / All Layers }
  FWandSampleLabel := TLabel.Create(FTopPanel);
  FWandSampleLabel.Parent := FTopPanel;
  FWandSampleLabel.Caption := 'Sample:';
  FWandSampleLabel.Font.Color := clWhite;
  FWandSampleLabel.Left := 348;
  FWandSampleLabel.Top := 41;
  FWandSampleLabel.Visible := False;

  FWandSampleCombo := TComboBox.Create(FTopPanel);
  FWandSampleCombo.Parent := FTopPanel;
  FWandSampleCombo.Left := 400;
  FWandSampleCombo.Top := 36;
  FWandSampleCombo.Width := 120;
  FWandSampleCombo.Style := csDropDownList;
  FWandSampleCombo.Items.Add('Current Layer');
  FWandSampleCombo.Items.Add('All Layers');
  FWandSampleCombo.ItemIndex := 0;
  FWandSampleCombo.Visible := False;
  FWandSampleCombo.OnChange := @WandSampleComboChanged;
  FWandSampleCombo.Hint := 'Wand sample source';
  FWandSampleCombo.ShowHint := True;

  { Wand contiguous checkbox }
  FWandContiguousCheck := TCheckBox.Create(FTopPanel);
  FWandContiguousCheck.Parent := FTopPanel;
  FWandContiguousCheck.Left := 529;
  FWandContiguousCheck.Top := 38;
  FWandContiguousCheck.Width := 100;
  FWandContiguousCheck.Caption := 'Contiguous';
  FWandContiguousCheck.Checked := FWandContiguous;
  FWandContiguousCheck.Visible := False;
  FWandContiguousCheck.OnChange := @WandContiguousChanged;
  FWandContiguousCheck.Hint := 'Contiguous: select only connected pixels';
  FWandContiguousCheck.ShowHint := True;

  { Fill tolerance spin }
  FFillTolLabel := TLabel.Create(FTopPanel);
  FFillTolLabel.Parent := FTopPanel;
  FFillTolLabel.Caption := 'Tolerance:';
  FFillTolLabel.Font.Color := clWhite;
  FFillTolLabel.Left := 348;
  FFillTolLabel.Top := 41;
  FFillTolLabel.Visible := False;

  FFillTolSpin := TSpinEdit.Create(FTopPanel);
  FFillTolSpin.Parent := FTopPanel;
  FFillTolSpin.Left := 420;
  FFillTolSpin.Top := 36;
  FFillTolSpin.Width := 66;
  FFillTolSpin.MinValue := 0;
  FFillTolSpin.MaxValue := 255;
  FFillTolSpin.Value := FFillTolerance;
  FFillTolSpin.Visible := False;
  FFillTolSpin.OnChange := @FillTolSpinChanged;
  FFillTolSpin.Hint := 'Fill tolerance (0=exact, 255=fill all)';
  FFillTolSpin.ShowHint := True;

  { Gradient type combo: Linear / Radial }
  FGradientTypeLabel := TLabel.Create(FTopPanel);
  FGradientTypeLabel.Parent := FTopPanel;
  FGradientTypeLabel.Caption := 'Type:';
  FGradientTypeLabel.Font.Color := clWhite;
  FGradientTypeLabel.Left := 348;
  FGradientTypeLabel.Top := 41;
  FGradientTypeLabel.Visible := False;

  FGradientTypeCombo := TComboBox.Create(FTopPanel);
  FGradientTypeCombo.Parent := FTopPanel;
  FGradientTypeCombo.Left := 384;
  FGradientTypeCombo.Top := 36;
  FGradientTypeCombo.Width := 90;
  FGradientTypeCombo.Style := csDropDownList;
  FGradientTypeCombo.Items.Add('Linear');
  FGradientTypeCombo.Items.Add('Radial');
  FGradientTypeCombo.ItemIndex := 0;
  FGradientTypeCombo.Visible := False;
  FGradientTypeCombo.OnChange := @GradientTypeComboChanged;
  FGradientTypeCombo.Hint := 'Gradient type';
  FGradientTypeCombo.ShowHint := True;

  { Gradient reverse checkbox }
  FGradientReverseCheck := TCheckBox.Create(FTopPanel);
  FGradientReverseCheck.Parent := FTopPanel;
  FGradientReverseCheck.Left := 480;
  FGradientReverseCheck.Top := 38;
  FGradientReverseCheck.Width := 80;
  FGradientReverseCheck.Caption := 'Reverse';
  FGradientReverseCheck.Checked := FGradientReverse;
  FGradientReverseCheck.Visible := False;
  FGradientReverseCheck.OnChange := @GradientReverseChanged;
  FGradientReverseCheck.Hint := 'Reverse gradient direction';
  FGradientReverseCheck.ShowHint := True;

  { Color picker sample source combo }
  FPickerSampleLabel := TLabel.Create(FTopPanel);
  FPickerSampleLabel.Parent := FTopPanel;
  FPickerSampleLabel.Caption := 'Sample:';
  FPickerSampleLabel.Font.Color := clWhite;
  FPickerSampleLabel.Left := 348;
  FPickerSampleLabel.Top := 41;
  FPickerSampleLabel.Visible := False;

  FPickerSampleCombo := TComboBox.Create(FTopPanel);
  FPickerSampleCombo.Parent := FTopPanel;
  FPickerSampleCombo.Left := 400;
  FPickerSampleCombo.Top := 36;
  FPickerSampleCombo.Width := 120;
  FPickerSampleCombo.Style := csDropDownList;
  FPickerSampleCombo.Items.Add('Current Layer');
  FPickerSampleCombo.Items.Add('All Layers');
  FPickerSampleCombo.ItemIndex := 0;
  FPickerSampleCombo.Visible := False;
  FPickerSampleCombo.OnChange := @PickerSampleComboChanged;
  FPickerSampleCombo.Hint := 'Pick color from layer or composite image';
  FPickerSampleCombo.ShowHint := True;

  { Selection anti-alias checkbox }
  FSelAntiAliasCheck := TCheckBox.Create(FTopPanel);
  FSelAntiAliasCheck.Parent := FTopPanel;
  FSelAntiAliasCheck.Left := 500;
  FSelAntiAliasCheck.Top := 38;
  FSelAntiAliasCheck.Width := 90;
  FSelAntiAliasCheck.Caption := 'Anti-alias';
  FSelAntiAliasCheck.Checked := FSelAntiAlias;
  FSelAntiAliasCheck.Visible := False;
  FSelAntiAliasCheck.OnChange := @SelAntiAliasChanged;
  FSelAntiAliasCheck.Hint := 'Smooth selection edges';
  FSelAntiAliasCheck.ShowHint := True;

  UpdateToolOptionControl;
  UpdateZoomControls;
end;

procedure TMainForm.BuildSidePanel;
var
  ToolIndex: Integer;
  ToolKind: TToolKind;
  ColumnIndex: Integer;
  RowIndex: Integer;
  ContentTop: Integer;
  ToolButton: TButton;
begin
  ContentTop := PaletteHeaderHeight + 8;

  FToolsPanel := TPanel.Create(Self);
  CreatePalette(FToolsPanel, pkTools);
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
  begin
    ToolKind := PaintToolAtDisplayIndex(ToolIndex);
    ColumnIndex := ToolIndex mod ToolsPaletteColumnCount;
    RowIndex := ToolIndex div ToolsPaletteColumnCount;
    ToolButton := CreateButton(
      PaintToolGlyph(ToolKind),
      8 + ColumnIndex * 46,
      ContentTop + RowIndex * 28,
      40,
      @ToolButtonClick,
      FToolsPanel,
      Ord(ToolKind)
    );
    ToolButton.Hint := PaintToolName(ToolKind) + ' — ' + PaintToolHint(ToolKind);
  end;

  FColorsPanel := TPanel.Create(Self);
  CreatePalette(FColorsPanel, pkColors);

  { Color target selector — switch between editing Primary or Secondary }
  FColorEditTarget := 0;
  FColorTargetCombo := TComboBox.Create(FColorsPanel);
  FColorTargetCombo.Parent := FColorsPanel;
  FColorTargetCombo.Style := csDropDownList;
  FColorTargetCombo.Left := 12;
  FColorTargetCombo.Top := ContentTop;
  FColorTargetCombo.Width := 130;
  FColorTargetCombo.Items.Add('Primary');
  FColorTargetCombo.Items.Add('Secondary');
  FColorTargetCombo.ItemIndex := 0;
  FColorTargetCombo.OnChange := @ColorTargetComboChanged;
  CreateButton('More…', 148, ContentTop, 90, @PrimaryColorClick, FColorsPanel);
  CreateButton('↔ Swap', 12, ContentTop + 28, 110, @SwapColorsClick, FColorsPanel);
  CreateButton('B/W', 128, ContentTop + 28, 110, @ResetColorsClick, FColorsPanel);

  { R/G/B row }
  with TLabel.Create(FColorsPanel) do begin Parent := FColorsPanel;
    Caption := 'R:'; Font.Color := clWhite; Left := 12; Top := ContentTop + 62; end;
  FColorRSpin := TSpinEdit.Create(FColorsPanel);
  FColorRSpin.Parent := FColorsPanel;
  FColorRSpin.Left := 28; FColorRSpin.Top := ContentTop + 59;
  FColorRSpin.Width := 56; FColorRSpin.MinValue := 0; FColorRSpin.MaxValue := 255;
  FColorRSpin.OnChange := @ColorSpinChanged;

  with TLabel.Create(FColorsPanel) do begin Parent := FColorsPanel;
    Caption := 'G:'; Font.Color := clWhite; Left := 90; Top := ContentTop + 62; end;
  FColorGSpin := TSpinEdit.Create(FColorsPanel);
  FColorGSpin.Parent := FColorsPanel;
  FColorGSpin.Left := 106; FColorGSpin.Top := ContentTop + 59;
  FColorGSpin.Width := 56; FColorGSpin.MinValue := 0; FColorGSpin.MaxValue := 255;
  FColorGSpin.OnChange := @ColorSpinChanged;

  with TLabel.Create(FColorsPanel) do begin Parent := FColorsPanel;
    Caption := 'B:'; Font.Color := clWhite; Left := 168; Top := ContentTop + 62; end;
  FColorBSpin := TSpinEdit.Create(FColorsPanel);
  FColorBSpin.Parent := FColorsPanel;
  FColorBSpin.Left := 184; FColorBSpin.Top := ContentTop + 59;
  FColorBSpin.Width := 56; FColorBSpin.MinValue := 0; FColorBSpin.MaxValue := 255;
  FColorBSpin.OnChange := @ColorSpinChanged;

  { Alpha row }
  with TLabel.Create(FColorsPanel) do begin Parent := FColorsPanel;
    Caption := 'A:'; Font.Color := clWhite; Left := 12; Top := ContentTop + 90; end;
  FColorASpin := TSpinEdit.Create(FColorsPanel);
  FColorASpin.Parent := FColorsPanel;
  FColorASpin.Left := 28; FColorASpin.Top := ContentTop + 87;
  FColorASpin.Width := 56; FColorASpin.MinValue := 0; FColorASpin.MaxValue := 255;
  FColorASpin.OnChange := @ColorSpinChanged;

  { Hex field }
  with TLabel.Create(FColorsPanel) do begin Parent := FColorsPanel;
    Caption := '#:'; Font.Color := clWhite; Left := 90; Top := ContentTop + 90; end;
  FColorHexEdit := TEdit.Create(FColorsPanel);
  FColorHexEdit.Parent := FColorsPanel;
  FColorHexEdit.Left := 108; FColorHexEdit.Top := ContentTop + 87;
  FColorHexEdit.Width := 130; FColorHexEdit.MaxLength := 8;
  FColorHexEdit.Font.Color := clBlack;
  FColorHexEdit.OnChange := @ColorHexChanged;
  FColorHexEdit.Hint := 'Selected color as RRGGBBAA hex';
  FColorHexEdit.ShowHint := True;

  { Secondary color indicator label }
  FColorsValueLabel := TLabel.Create(FColorsPanel);
  FColorsValueLabel.Parent := FColorsPanel;
  FColorsValueLabel.Left := 12;
  FColorsValueLabel.Top := ContentTop + 118;
  FColorsValueLabel.Width := 226;
  FColorsValueLabel.Height := 14;
  FColorsValueLabel.Font.Color := clSilver;
  FColorsValueLabel.Font.Size := 8;

  RefreshColorsPanel;

  { Color swatch box }
  FColorsBox := TPaintBox.Create(FColorsPanel);
  FColorsBox.Parent := FColorsPanel;
  FColorsBox.Left := 12;
  FColorsBox.Top := ContentTop + 136;
  FColorsBox.Width := FColorsPanel.Width - 24;
  FColorsBox.Height := FColorsPanel.Height - (ContentTop + 148);
  FColorsBox.Anchors := [akLeft, akRight, akTop, akBottom];
  FColorsBox.OnPaint := @ColorsBoxPaint;
  FColorsBox.OnMouseDown := @ColorsBoxMouseDown;

  FHistoryPanel := TPanel.Create(Self);
  CreatePalette(FHistoryPanel, pkHistory);
  CreateButton('↩ Undo', 12, ContentTop, 104, @UndoClick, FHistoryPanel);
  CreateButton('↪ Redo', 120, ContentTop, 104, @RedoClick, FHistoryPanel);
  FHistoryValueLabel := TLabel.Create(FHistoryPanel);
  FHistoryValueLabel.Parent := FHistoryPanel;
  FHistoryValueLabel.Left := 12;
  FHistoryValueLabel.Top := ContentTop + 30;
  FHistoryValueLabel.Width := 212;
  FHistoryValueLabel.Height := 14;
  FHistoryValueLabel.Font.Color := clSilver;
  FHistoryValueLabel.Font.Size := 8;
  FHistoryList := TListBox.Create(FHistoryPanel);
  FHistoryList.Parent := FHistoryPanel;
  FHistoryList.Left := 12;
  FHistoryList.Top := ContentTop + 48;
  FHistoryList.Width := 212;
  FHistoryList.Height := FHistoryPanel.Height - (ContentTop + 60);
  FHistoryList.Anchors := [akTop, akLeft, akRight, akBottom];
  FHistoryList.Color := $00353D4A;
  FHistoryList.Font.Color := clWhite;
  FHistoryList.Font.Size := 9;
  FHistoryList.Style := lbOwnerDrawFixed;
  FHistoryList.ItemHeight := 20;
  FHistoryList.OnClick := @HistoryListClick;
  FHistoryList.OnDrawItem := @HistoryListDrawItem;
  RefreshHistoryPanel;

  FRightPanel := TPanel.Create(Self);
  CreatePalette(FRightPanel, pkLayers);

  { Row 1: Add / Duplicate / Delete / Merge }
  CreateButton('➕', 12, ContentTop, 30, @AddLayerClick, FRightPanel);
  CreateButton('📋', 44, ContentTop, 30, @DuplicateLayerClick, FRightPanel);
  CreateButton('🗑', 76, ContentTop, 30, @DeleteLayerClick, FRightPanel);
  CreateButton('⤵', 108, ContentTop, 30, @MergeDownClick, FRightPanel);
  { Row 1 right: Vis / Up / Down }
  CreateButton('👁', 144, ContentTop, 30, @ToggleLayerVisibilityClick, FRightPanel);
  CreateButton('⬆', 176, ContentTop, 30, @MoveLayerUpClick, FRightPanel);
  CreateButton('⬇', 208, ContentTop, 30, @MoveLayerDownClick, FRightPanel);

  { Row 2: Opacity / Flatten / Rename / Properties }
  CreateButton('Opac', 12, ContentTop + 28, 52, @LayerOpacityClick, FRightPanel);
  CreateButton('Flat', 68, ContentTop + 28, 52, @FlattenClick, FRightPanel);
  CreateButton('Name', 124, ContentTop + 28, 52, @RenameLayerClick, FRightPanel);
  FLayerPropsButton := CreateButton('Props', 180, ContentTop + 28, 56, @LayerPropertiesClick, FRightPanel);

  FLayerBlendCombo := TComboBox.Create(FRightPanel);
  FLayerBlendCombo.Parent := FRightPanel;
  FLayerBlendCombo.Left := 12;
  FLayerBlendCombo.Top := ContentTop + 56;
  FLayerBlendCombo.Width := 220;
  FLayerBlendCombo.Style := csDropDownList;
  FLayerBlendCombo.Items.Add('Normal');
  FLayerBlendCombo.Items.Add('Multiply');
  FLayerBlendCombo.Items.Add('Screen');
  FLayerBlendCombo.Items.Add('Overlay');
  FLayerBlendCombo.Items.Add('Darken');
  FLayerBlendCombo.Items.Add('Lighten');
  FLayerBlendCombo.Items.Add('Difference');
  FLayerBlendCombo.Items.Add('Soft Light');
  FLayerBlendCombo.ItemIndex := 0;
  FLayerBlendCombo.OnChange := @LayerBlendModeChanged;

  FLayerList := TListBox.Create(FRightPanel);
  FLayerList.Parent := FRightPanel;
  FLayerList.Left := 12;
  FLayerList.Top := ContentTop + 84;
  FLayerList.Width := 220;
  FLayerList.Height := FRightPanel.Height - (ContentTop + 96);
  FLayerList.Anchors := [akTop, akLeft, akRight, akBottom];
  FLayerList.Color := $00353D4A;
  FLayerList.Font.Color := clWhite;
  FLayerList.Font.Size := 9;
  FLayerList.OnClick := @LayerListClick;
  FLayerList.OnDblClick := @LayerListDblClick;
end;

function TMainForm.CreateButton(const ACaption: string; ALeft, ATop, AWidth: Integer; AHandler: TNotifyEvent; AParent: TWinControl; ATag: Integer): TButton;
begin
  Result := TButton.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := 24;
  Result.Tag := ATag;
  Result.OnClick := AHandler;
  Result.Hint := ACaption;
  Result.ShowHint := True;
end;

procedure TMainForm.CreateMenuItem(AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent; AShortcut: TShortCut);
var
  MenuItem: TMenuItem;
begin
  MenuItem := TMenuItem.Create(AParent);
  MenuItem.Caption := ACaption;
  MenuItem.OnClick := AHandler;
  if AShortcut <> 0 then
    MenuItem.ShortCut := AShortcut;
  AParent.Add(MenuItem);
end;

procedure TMainForm.PaintCanvasTo(ACanvas: TCanvas; const ARect: TRect);
var
  DisplaySurface: TRasterSurface;
  LeftX: Integer;
  TopY: Integer;
  RightX: Integer;
  BottomY: Integer;
  PointIndex: Integer;
  GridIndex: Integer;
begin
  ACanvas.Brush.Color := CanvasBackgroundColor;
  ACanvas.FillRect(ARect);

  if (FPreparedRevision <> FRenderRevision) or
     (FPreparedBitmap.Width <> FDocument.Width) or
     (FPreparedBitmap.Height <> FDocument.Height) then
  begin
    DisplaySurface := BuildDisplaySurface;  { returns FDisplaySurface — do NOT free }
    CopySurfaceToBitmap(DisplaySurface, FPreparedBitmap);
    FPreparedRevision := FRenderRevision;
  end;

  if not FPreparedBitmap.Empty then
    ACanvas.StretchDraw(Rect(0, 0, FPaintBox.Width, FPaintBox.Height), FPreparedBitmap);

  if ShouldRenderPixelGrid(FShowPixelGrid, FZoomScale) then
  begin
    ACanvas.Pen.Color := PixelGridColor;
    ACanvas.Pen.Width := 1;
    for GridIndex := 1 to FDocument.Width - 1 do
    begin
      LeftX := Round(GridIndex * FZoomScale);
      ACanvas.MoveTo(LeftX, 0);
      ACanvas.LineTo(LeftX, FPaintBox.Height);
    end;
    for GridIndex := 1 to FDocument.Height - 1 do
    begin
      TopY := Round(GridIndex * FZoomScale);
      ACanvas.MoveTo(0, TopY);
      ACanvas.LineTo(FPaintBox.Width, TopY);
    end;
  end;

  if not FPointerDown then
    Exit;

  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsClear;
  case FCurrentTool of
    tkLine, tkGradient:
      begin
        ACanvas.MoveTo(
          Round((FDragStart.X + 0.5) * FZoomScale),
          Round((FDragStart.Y + 0.5) * FZoomScale)
        );
        ACanvas.LineTo(
          Round((FLastImagePoint.X + 0.5) * FZoomScale),
          Round((FLastImagePoint.Y + 0.5) * FZoomScale)
        );
      end;
    tkRectangle, tkSelectRect:
      begin
        LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
        TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
        RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
        BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
        ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);
      end;
    tkCrop:
      begin
        LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
        TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
        RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
        BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
        ACanvas.Pen.Style := psDash;
        ACanvas.Pen.Color := clWhite;
        ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);
        ACanvas.Pen.Style := psSolid;
        ACanvas.Pen.Color := clBlack;
        ACanvas.Rectangle(LeftX - 1, TopY - 1, RightX + 1, BottomY + 1);
      end;
    tkRoundedRectangle:
      begin
        LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
        TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
        RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
        BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
        ACanvas.RoundRect(
          LeftX,
          TopY,
          RightX,
          BottomY,
          Max(6, (RightX - LeftX) div 4),
          Max(6, (BottomY - TopY) div 4)
        );
      end;
    tkEllipseShape, tkSelectEllipse:
      begin
        LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
        TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
        RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
        BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
        ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);
      end;
    tkSelectLasso, tkFreeformShape:
      if Length(FLassoPoints) > 1 then
      begin
        ACanvas.MoveTo(
          Round((FLassoPoints[0].X + 0.5) * FZoomScale),
          Round((FLassoPoints[0].Y + 0.5) * FZoomScale)
        );
        for PointIndex := 1 to High(FLassoPoints) do
          ACanvas.LineTo(
            Round((FLassoPoints[PointIndex].X + 0.5) * FZoomScale),
            Round((FLassoPoints[PointIndex].Y + 0.5) * FZoomScale)
          );
        if (FCurrentTool = tkFreeformShape) and (Length(FLassoPoints) > 2) then
          ACanvas.LineTo(
            Round((FLassoPoints[0].X + 0.5) * FZoomScale),
            Round((FLassoPoints[0].Y + 0.5) * FZoomScale)
          );
      end;
  end;
end;

procedure TMainForm.PaintRuler(ACanvas: TCanvas; const ARect: TRect; AOrientation: TRulerOrientation);
var
  MajorStep: Integer;
  MinorStep: Integer;
  MajorDivision: Integer;
  Origin: Integer;
  ScreenLength: Integer;
  TickValue: Integer;
  StartTick: Integer;
  EndValue: Integer;
  ScreenPosition: Integer;
  TickLength: Integer;
begin
  ACanvas.Brush.Color := RulerBackgroundColor;
  ACanvas.FillRect(ARect);
  ACanvas.Pen.Color := RulerBorderColor;
  if AOrientation = roHorizontal then
  begin
    ACanvas.MoveTo(ARect.Left, ARect.Bottom - 1);
    ACanvas.LineTo(ARect.Right, ARect.Bottom - 1);
  end
  else
  begin
    ACanvas.MoveTo(ARect.Right - 1, ARect.Top);
    ACanvas.LineTo(ARect.Right - 1, ARect.Bottom);
  end;

  if not FShowRulers then
    Exit;

  MajorStep := RulerMajorStep(FZoomScale);
  MinorStep := RulerMinorStep(FZoomScale);
  MajorDivision := Max(1, MajorStep div MinorStep);
  ACanvas.Pen.Color := RulerTickColor;
  ACanvas.Font.Color := RulerTextColor;
  ACanvas.Font.Size := 7;

  if AOrientation = roHorizontal then
  begin
    Origin := ImageOriginInViewport.X;
    ScreenLength := ARect.Right - ARect.Left;
  end
  else
  begin
    Origin := ImageOriginInViewport.Y;
    ScreenLength := ARect.Bottom - ARect.Top;
  end;

  StartTick := Trunc((-Origin) / FZoomScale);
  if StartTick >= 0 then
    StartTick := (StartTick div MinorStep) * MinorStep
  else
    StartTick := -(((-StartTick + MinorStep - 1) div MinorStep) * MinorStep);
  EndValue := Trunc((ScreenLength - Origin) / FZoomScale) + MajorStep;

  TickValue := StartTick;
  while TickValue <= EndValue do
  begin
    ScreenPosition := Origin + Round(TickValue * FZoomScale);
    if (ScreenPosition >= -24) and (ScreenPosition <= ScreenLength + 24) then
    begin
      if (TickValue mod MajorStep) = 0 then
      begin
        TickLength := RulerThickness - 4;
        if AOrientation = roHorizontal then
        begin
          ACanvas.MoveTo(ScreenPosition, ARect.Bottom - 1);
          ACanvas.LineTo(ScreenPosition, ARect.Bottom - TickLength);
          if ScreenPosition <= ARect.Right - 20 then
            ACanvas.TextOut(ScreenPosition + 2, 1, IntToStr(TickValue));
        end
        else
        begin
          ACanvas.MoveTo(ARect.Right - 1, ScreenPosition);
          ACanvas.LineTo(ARect.Right - TickLength, ScreenPosition);
          if ScreenPosition <= ARect.Bottom - 12 then
            ACanvas.TextOut(1, ScreenPosition + 1, IntToStr(TickValue));
        end;
      end
      else
      begin
        if (TickValue mod (MinorStep * Max(1, MajorDivision div 2))) = 0 then
          TickLength := 8
        else
          TickLength := 5;
        if AOrientation = roHorizontal then
        begin
          ACanvas.MoveTo(ScreenPosition, ARect.Bottom - 1);
          ACanvas.LineTo(ScreenPosition, ARect.Bottom - TickLength);
        end
        else
        begin
          ACanvas.MoveTo(ARect.Right - 1, ScreenPosition);
          ACanvas.LineTo(ARect.Right - TickLength, ScreenPosition);
        end;
      end;
    end;
    Inc(TickValue, MinorStep);
  end;
end;

procedure TMainForm.UpdateCanvasSize;
var
  LeftOffset: Integer;
  TopOffset: Integer;
begin
  FPaintBox.Width := Max(1, Round(FDocument.Width * FZoomScale));
  FPaintBox.Height := Max(1, Round(FDocument.Height * FZoomScale));
  if Assigned(FCanvasHost) then
  begin
    LeftOffset := CenteredContentOffset(FCanvasHost.ClientWidth, FPaintBox.Width);
    TopOffset := CenteredContentOffset(FCanvasHost.ClientHeight, FPaintBox.Height);
    FPaintBox.Left := LeftOffset;
    FPaintBox.Top := TopOffset;
    if LeftOffset > 0 then
      FCanvasHost.HorzScrollBar.Position := 0;
    if TopOffset > 0 then
      FCanvasHost.VertScrollBar.Position := 0;
  end;
end;

procedure TMainForm.CanvasHostResize(Sender: TObject);
begin
  { Re-center the canvas whenever the viewport area changes size }
  UpdateCanvasSize;
end;

procedure TMainForm.FitDocumentToViewport(AOnlyShrink: Boolean);
var
  AvailableWidth: Integer;
  AvailableHeight: Integer;
  TargetScale: Double;
begin
  if not Assigned(FCanvasHost) then
    Exit;

  AvailableWidth := Max(64, FCanvasHost.ClientWidth - 32);
  AvailableHeight := Max(64, FCanvasHost.ClientHeight - 32);
  if (FDocument.Width <= 0) or (FDocument.Height <= 0) then
    Exit;

  TargetScale := Min(AvailableWidth / FDocument.Width, AvailableHeight / FDocument.Height);
  if AOnlyShrink then
    TargetScale := Min(1.0, TargetScale);
  FZoomScale := Max(0.1, Min(16.0, TargetScale));
end;

procedure TMainForm.RefreshCanvas;
begin
  UpdateCanvasSize;
  FPaintBox.Invalidate;
  RefreshRulers;
  RefreshHistoryPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.RefreshRulers;
begin
  if Assigned(FRulerTopBand) then
    FRulerTopBand.Visible := FShowRulers;
  if Assigned(FVerticalRuler) then
    FVerticalRuler.Visible := FShowRulers;
  if Assigned(FRulersMenuItem) then
    FRulersMenuItem.Checked := FShowRulers;
  if Assigned(FHorizontalRuler) then
    FHorizontalRuler.Invalidate;
  if Assigned(FVerticalRuler) then
    FVerticalRuler.Invalidate;
end;

procedure TMainForm.RefreshLayers;
var
  Index: Integer;
  CaptionText: string;
  Layer: TRasterLayer;
begin
  FLayerList.Items.BeginUpdate;
  try
    FLayerList.Items.Clear;
    for Index := 0 to FDocument.LayerCount - 1 do
    begin
      Layer := FDocument.Layers[Index];
      if Layer.Visible then
        CaptionText := '👁 '
      else
        CaptionText := '   ';
      CaptionText := CaptionText + Layer.Name;
      if Layer.Opacity < 255 then
        CaptionText := CaptionText + Format(' (%d%%)', [Layer.Opacity * 100 div 255]);
      FLayerList.Items.Add(CaptionText);
    end;
    FLayerList.ItemIndex := FDocument.ActiveLayerIndex;
  finally
    FLayerList.Items.EndUpdate;
  end;
  { Sync blend mode combo to active layer }
  if Assigned(FLayerBlendCombo) and (FDocument.LayerCount > 0) then
  begin
    FLayerBlendCombo.ItemIndex := Ord(FDocument.ActiveLayer.BlendMode);
  end;
  RefreshHistoryPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.RefreshColorsPanel;
var
  OtherColor: TRGBA32;
  OtherName: string;
begin
  if FColorEditTarget = 0 then
  begin
    OtherColor := FSecondaryColor;
    OtherName := 'Secondary';
  end
  else
  begin
    OtherColor := FPrimaryColor;
    OtherName := 'Primary';
  end;
  if Assigned(FColorsValueLabel) then
  begin
    FColorsValueLabel.Caption := Format(
      '%s: #%2.2x%2.2x%2.2x',
      [
        OtherName,
        OtherColor.R,
        OtherColor.G,
        OtherColor.B
      ]
    );
  end;
  UpdateColorSpins;
  if Assigned(FColorsBox) then
    FColorsBox.Invalidate;
end;

procedure TMainForm.ColorsBoxPaint(Sender: TObject);
var
  PB: TPaintBox;
  C: TCanvas;
  W, H: Integer;
  CenterX, CenterY: Integer;
  Radius: Integer;
  X, Y: Integer;
  DX, DY: Double;
  Dist, Angle: Double;
  Hue, Sat: Double;
  R, G, B: Byte;
  SliderLeft, SliderTop, SliderWidth, SliderHeight: Integer;
  CurH, CurS, CurV: Double;
  MarkerX, MarkerY: Integer;
  ValY: Integer;
  EditColor: TRGBA32;
begin
  if not Assigned(Sender) then Exit;
  PB := TPaintBox(Sender);
  C := PB.Canvas;
  W := PB.Width;
  H := PB.Height;
  C.Brush.Style := bsSolid;
  C.Brush.Color := PaletteSurfaceColor(pkColors, False);
  C.FillRect(Rect(0, 0, W, H));

  { Draw circular HSV wheel based on the currently selected edit color }
  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;

  Radius := Min(W - 24, H - 36) div 2;
  if Radius < 10 then Exit;
  CenterX := W div 2;
  CenterY := Radius + 2;

  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);

  for Y := CenterY - Radius to CenterY + Radius do
    for X := CenterX - Radius to CenterX + Radius do
    begin
      DX := X - CenterX;
      DY := Y - CenterY;
      Dist := Sqrt(DX * DX + DY * DY);
      if Dist > Radius then Continue;
      Angle := ArcTan2(DY, DX);
      if Angle < 0 then Angle := Angle + 2 * Pi;
      Hue := Angle / (2 * Pi);
      Sat := Dist / Radius;
      HSVToRGB(Hue, Sat, CurV, R, G, B);
      C.Pixels[X, Y] := RGBToColor(R, G, B);
    end;

  { Current color marker on wheel }
  MarkerX := CenterX + Round(CurS * Radius * Cos(CurH * 2 * Pi));
  MarkerY := CenterY + Round(CurS * Radius * Sin(CurH * 2 * Pi));
  C.Pen.Color := clWhite;
  C.Pen.Width := 2;
  C.Brush.Style := bsClear;
  C.Ellipse(MarkerX - 5, MarkerY - 5, MarkerX + 5, MarkerY + 5);
  C.Pen.Color := clBlack;
  C.Pen.Width := 1;
  C.Ellipse(MarkerX - 6, MarkerY - 6, MarkerX + 6, MarkerY + 6);

  { Draw value (brightness) slider below the wheel }
  SliderLeft := CenterX - Radius;
  SliderTop := CenterY + Radius + 6;
  SliderWidth := Radius * 2;
  SliderHeight := 14;
  for X := SliderLeft to SliderLeft + SliderWidth - 1 do
  begin
    HSVToRGB(CurH, CurS, (X - SliderLeft) / Max(1, SliderWidth - 1), R, G, B);
    C.Pen.Color := RGBToColor(R, G, B);
    C.MoveTo(X, SliderTop);
    C.LineTo(X, SliderTop + SliderHeight);
  end;
  C.Brush.Style := bsClear;
  C.Pen.Color := clGray;
  C.Rectangle(SliderLeft, SliderTop, SliderLeft + SliderWidth, SliderTop + SliderHeight);
  { Value position indicator }
  ValY := SliderLeft + Round(CurV * Max(1, SliderWidth - 1));
  C.Pen.Color := clWhite;
  C.Pen.Width := 2;
  C.MoveTo(ValY, SliderTop - 1);
  C.LineTo(ValY, SliderTop + SliderHeight + 1);
  C.Pen.Width := 1;

  { Primary/secondary color preview rectangles }
  C.Brush.Style := bsSolid;
  C.Pen.Color := clGray;
  C.Brush.Color := RGBToColor(FSecondaryColor.R, FSecondaryColor.G, FSecondaryColor.B);
  C.Rectangle(W - 30, SliderTop + SliderHeight + 6, W - 6, SliderTop + SliderHeight + 26);
  C.Brush.Color := RGBToColor(FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B);
  C.Rectangle(6, SliderTop + SliderHeight + 6, 30, SliderTop + SliderHeight + 26);

  { Active slot indicator notch (small triangle) }
  C.Pen.Width := 1;
  C.Brush.Style := bsSolid;
  C.Brush.Color := clWhite;
  if FColorEditTarget = 0 then
  begin
    { mark primary rectangle top-left corner }
    C.Polygon([Point(6, SliderTop + SliderHeight + 6),
               Point(12, SliderTop + SliderHeight + 6),
               Point(6, SliderTop + SliderHeight + 12)]);
  end
  else
  begin
    { mark secondary rectangle top-left of its box }
    C.Polygon([Point(W - 30, SliderTop + SliderHeight + 6),
               Point(W - 24, SliderTop + SliderHeight + 6),
               Point(W - 30, SliderTop + SliderHeight + 12)]);
  end;
  C.Brush.Style := bsClear;
  C.Pen.Color := clBlack;
  { reset pen width if caller relies on default }
  C.Pen.Width := 1;
end;

procedure TMainForm.ColorsBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  PB: TPaintBox;
  W, H: Integer;
  Radius: Integer;
  CenterX, CenterY: Integer;
  DX, DY, Dist, Angle: Double;
  CurH, CurS, CurV: Double;
  NewH, NewS, NewV: Double;
  SliderLeft, SliderTop, SliderWidth, SliderHeight: Integer;
  PickedR, PickedG, PickedB: Byte;
  EditColor: TRGBA32;
begin
  if not Assigned(Sender) then Exit;
  PB := TPaintBox(Sender);
  W := PB.Width;
  H := PB.Height;

  Radius := Min(W - 24, H - 36) div 2;
  if Radius < 10 then Exit;
  CenterX := W div 2;
  CenterY := Radius + 2;

  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;

  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);

  { Check if click is on the value slider }
  SliderLeft := CenterX - Radius;
  SliderTop := CenterY + Radius + 6;
  SliderWidth := Radius * 2;
  SliderHeight := 14;

  if (Y >= SliderTop) and (Y <= SliderTop + SliderHeight) and
     (X >= SliderLeft) and (X <= SliderLeft + SliderWidth) then
  begin
    { Adjust value/brightness for whichever color is currently selected }
    NewV := EnsureRange((X - SliderLeft) / Max(1, SliderWidth - 1), 0.0, 1.0);
    HSVToRGB(CurH, CurS, NewV, PickedR, PickedG, PickedB);
    if FColorEditTarget = 0 then
      FPrimaryColor := RGBA(PickedR, PickedG, PickedB, FPrimaryColor.A)
    else
      FSecondaryColor := RGBA(PickedR, PickedG, PickedB, FSecondaryColor.A);
    RefreshColorsPanel;
    PB.Invalidate;
    Exit;
  end;

  { Check if click is in the wheel area }
  DX := X - CenterX;
  DY := Y - CenterY;
  Dist := Sqrt(DX * DX + DY * DY);
  if Dist <= Radius then
  begin
    Angle := ArcTan2(DY, DX);
    if Angle < 0 then Angle := Angle + 2 * Pi;
    NewH := Angle / (2 * Pi);
    NewS := EnsureRange(Dist / Radius, 0.0, 1.0);
    HSVToRGB(NewH, NewS, CurV, PickedR, PickedG, PickedB);
    if FColorEditTarget = 0 then
      FPrimaryColor := RGBA(PickedR, PickedG, PickedB, FPrimaryColor.A)
    else
      FSecondaryColor := RGBA(PickedR, PickedG, PickedB, FSecondaryColor.A);
    RefreshColorsPanel;
    PB.Invalidate;
  end;

  { Check if click is on the primary preview rectangle (bottom left) }
  SliderLeft := CenterX - Radius;
  SliderTop := CenterY + Radius + 6;
  SliderWidth := Radius * 2;
  SliderHeight := 14;
  if (X >= 6) and (X <= 30) and
     (Y >= SliderTop + SliderHeight + 6) and (Y <= SliderTop + SliderHeight + 26) then
  begin
    FColorEditTarget := 0;
    if Assigned(FColorTargetCombo) then FColorTargetCombo.ItemIndex := 0;
    RefreshColorsPanel;
    Exit;
  end;
  { Check if click is on the secondary preview rectangle (bottom right) }
  if (X >= W - 30) and (X <= W - 6) and
     (Y >= SliderTop + SliderHeight + 6) and (Y <= SliderTop + SliderHeight + 26) then
  begin
    FColorEditTarget := 1;
    if Assigned(FColorTargetCombo) then FColorTargetCombo.ItemIndex := 1;
    RefreshColorsPanel;
    Exit;
  end;
end;

procedure TMainForm.HistoryListDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  LB: TListBox;
  CurrentIndex: Integer;
  TextCol: TColor;
  BgCol: TColor;
begin
  LB := TListBox(Control);
  if not Assigned(FDocument) then Exit;
  CurrentIndex := FDocument.UndoDepth - 1;
  if odSelected in State then
  begin
    BgCol := $00705848;  { warm selection highlight }
    TextCol := clWhite;
  end
  else if Index > CurrentIndex then
  begin
    BgCol := LB.Color;
    TextCol := $00666666;  { future / redo items: dimmed }
  end
  else if Index = CurrentIndex then
  begin
    BgCol := $00454D5A;  { current state: slightly lighter background }
    TextCol := clWhite;
  end
  else
  begin
    BgCol := LB.Color;
    TextCol := $00AAAAAA;  { past states: readable but subdued }
  end;
  LB.Canvas.Brush.Color := BgCol;
  LB.Canvas.FillRect(ARect);
  LB.Canvas.Font.Color := TextCol;
  LB.Canvas.TextOut(ARect.Left + 4, ARect.Top + 2, LB.Items[Index]);
end;

procedure TMainForm.RefreshHistoryPanel;
var
  UndoLabel: string;
  RedoLabel: string;
  UndoCount: Integer;
  RedoCount: Integer;
  Index: Integer;
begin
  if Assigned(FHistoryValueLabel) then
  begin
    UndoLabel := FDocument.UndoActionLabel;
    RedoLabel := FDocument.RedoActionLabel;
    if UndoLabel = '' then
      UndoLabel := '—';
    if RedoLabel = '' then
      RedoLabel := '—';
    FHistoryValueLabel.Caption := Format(
      'Undo: %s  |  Redo: %s',
      [UndoLabel, RedoLabel]
    );
  end;
  if Assigned(FHistoryList) then
  begin
    FHistoryList.Items.BeginUpdate;
    try
      FHistoryList.Items.Clear;
      UndoCount := FDocument.UndoDepth;
      RedoCount := FDocument.RedoDepth;
      { Undo items: oldest first (label index from newest = UndoCount-1 downto 0) }
      for Index := UndoCount - 1 downto 0 do
        FHistoryList.Items.Add(Format('%d. %s', [UndoCount - Index, FDocument.UndoActionLabel(Index)]));
      { Redo items: closest future first (label index from newest = 0 to RedoCount-1) }
      for Index := 0 to RedoCount - 1 do
        FHistoryList.Items.Add(Format('%d. %s', [UndoCount + Index + 1, FDocument.RedoActionLabel(Index)]));
      { Highlight the last undo item as the current state }
      if UndoCount > 0 then
        FHistoryList.ItemIndex := UndoCount - 1
      else
        FHistoryList.ItemIndex := -1;
    finally
      FHistoryList.Items.EndUpdate;
    end;
  end;
end;

procedure TMainForm.RefreshStatus(const ACursorPoint: TPoint);
var
  SelectionText: string;
  SelectionBounds: TRect;
begin
  if not Assigned(FStatusBar) then
    Exit;

  if FDocument.HasSelection then
  begin
    SelectionBounds := FDocument.Selection.BoundsRect;
    SelectionText := Format(
      '%s × %s %s',
      [
        FormatMeasurement(Max(1, SelectionBounds.Right - SelectionBounds.Left)),
        FormatMeasurement(Max(1, SelectionBounds.Bottom - SelectionBounds.Top)),
        DisplayUnitSuffix
      ]
    );
  end
  else
    SelectionText := 'none';

  FStatusLabels[0].Caption := Format('%s — %s', [PaintToolName(FCurrentTool), ToolHintText]);
  FStatusLabels[1].Caption := Format(
    'Image: %s × %s %s',
    [
      FormatMeasurement(FDocument.Width),
      FormatMeasurement(FDocument.Height),
      DisplayUnitSuffix
    ]
  );
  FStatusLabels[2].Caption := 'Selection: ' + SelectionText;
  if (ACursorPoint.X >= 0) and (ACursorPoint.Y >= 0) then
    FStatusLabels[3].Caption := Format(
      'Cursor: %s, %s %s',
      [
        FormatMeasurement(ACursorPoint.X),
        FormatMeasurement(ACursorPoint.Y),
        DisplayUnitSuffix
      ]
    )
  else
    FStatusLabels[3].Caption := 'Cursor: —';
  FStatusLabels[4].Caption := Format(
    'Layer: %d/%d',
    [FDocument.ActiveLayerIndex + 1, FDocument.LayerCount]
  );
  FStatusLabels[5].Caption := 'Units: ' + DisplayUnitSuffix;
  FStatusLabels[6].Caption := '';
  UpdateZoomControls;
  LayoutStatusBarControls(nil);
end;

procedure TMainForm.UpdateStatusForTool;
begin
  RefreshStatus(Point(-1, -1));
end;

procedure TMainForm.ActivateTempPan;
begin
  if not FTempToolActive then
  begin
    FTempToolActive := True;
    FPreviousTool := FCurrentTool;
    FCurrentTool := tkPan;
    if Assigned(FToolCombo) then
      FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
    UpdateToolOptionControl;
    UpdateStatusForTool;
  end;
end;

procedure TMainForm.DeactivateTempPan;
begin
  if FTempToolActive then
  begin
    FTempToolActive := False;
    FCurrentTool := FPreviousTool;
    if Assigned(FToolCombo) then
      FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
    UpdateToolOptionControl;
    UpdateStatusForTool;
  end;
end;

procedure TMainForm.ToggleColorEditTarget;
begin
  if FColorEditTarget = 0 then
    FColorEditTarget := 1
  else
    FColorEditTarget := 0;
  if Assigned(FColorTargetCombo) then
    FColorTargetCombo.ItemIndex := FColorEditTarget;
  { Avoid triggering heavier UI/paint logic during headless tests; tests
    only need the state and combo to be updated. } 
end;

procedure TMainForm.StartTempPan;
begin
  { Lightweight temp-pan activation for tests: set internal state and update
    the tool combo without invoking UI refresh logic that relies on a
    fully-initialized widgetset. }
  if not FTempToolActive then
  begin
    FTempToolActive := True;
    FPreviousTool := FCurrentTool;
    FCurrentTool := tkPan;
    if Assigned(FToolCombo) then
      FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
  end;
end;

procedure TMainForm.StopTempPan;
begin
  if FTempToolActive then
  begin
    FTempToolActive := False;
    FCurrentTool := FPreviousTool;
    if Assigned(FToolCombo) then
      FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
  end;
end;

procedure TMainForm.LayoutStatusBarControls(Sender: TObject);
var
  PanelWidths: TStatusPanelWidthArray;
  PanelIndex: Integer;
  LeftPos: Integer;
  TrackW, LblW: Integer;
begin
  if not Assigned(FStatusBar) or
     not Assigned(FStatusZoomLabel) then
    Exit;

  ComputeStatusPanelWidths(Max(0, FStatusBar.ClientWidth - 4), PanelWidths);

  { Position text labels for panels 0..5 }
  LeftPos := 4;
  for PanelIndex := 0 to 5 do
  begin
    FStatusLabels[PanelIndex].SetBounds(
      LeftPos + 4,
      0,
      Max(0, PanelWidths[PanelIndex] - 8),
      FStatusBar.Height
    );
    Inc(LeftPos, PanelWidths[PanelIndex]);
  end;

  { Panel 6: zoom trackbar + zoom percentage label }
  TrackW := ZoomTrackWidth(PanelWidths[6]);
  LblW := ZoomLabelWidth(PanelWidths[6]);
  if Assigned(FStatusZoomTrack) then
    FStatusZoomTrack.SetBounds(
      LeftPos + 4,
      2,
      TrackW,
      FStatusBar.Height - 4
    );
  FStatusZoomLabel.SetBounds(
    LeftPos + TrackW + 8,
    0,
    LblW,
    FStatusBar.Height
  );
end;

procedure TMainForm.MakeTestSafe;
begin
  { Ensure minimal widgets for tests so they don't need to exercise full UI }
  if not Assigned(FToolCombo) then
  begin
    FToolCombo := TComboBox.Create(nil);
    while FToolCombo.Items.Count < PaintToolDisplayCount do
      FToolCombo.Items.Add('');
  end;
  if not Assigned(FColorTargetCombo) then
  begin
    FColorTargetCombo := TComboBox.Create(nil);
    FColorTargetCombo.Style := csDropDownList;
    if FColorTargetCombo.Items.Count = 0 then
    begin
      FColorTargetCombo.Items.Add('Primary');
      FColorTargetCombo.Items.Add('Secondary');
    end;
  end;
  { Remove idle handler if present to avoid callbacks into partially-initialized app }
  if Assigned(Application) then
  begin
    try
      Application.RemoveOnIdleHandler(@AppIdle);
    except
      { ignore }
    end;
  end;
end;

procedure TMainForm.UpdateZoomControls;
var
  NearestIndex: Integer;
begin
  if Assigned(FStatusZoomLabel) then
    FStatusZoomLabel.Caption := ZoomCaptionForScale(FZoomScale);

  FUpdatingZoomControl := True;
  try
    NearestIndex := NearestZoomPresetIndex(FZoomScale);
    if Assigned(FZoomCombo) then
    begin
      FZoomCombo.ItemIndex := NearestIndex;
      FZoomCombo.Hint := 'Zoom: ' + ZoomCaptionForScale(FZoomScale);
      FZoomCombo.ShowHint := True;
    end;
    if Assigned(FStatusZoomTrack) then
      FStatusZoomTrack.Position := ZoomSliderPositionForScale(FZoomScale);
  finally
    FUpdatingZoomControl := False;
  end;
end;

procedure TMainForm.StatusZoomTrackChange(Sender: TObject);
begin
  if FUpdatingZoomControl then Exit;
  ApplyZoomScale(ZoomScaleForSliderPosition(FStatusZoomTrack.Position));
end;

procedure TMainForm.HistoryListClick(Sender: TObject);
var
  ClickedIndex: Integer;
  CurrentIndex: Integer;
  StepsDelta: Integer;
  I: Integer;
begin
  if not Assigned(FDocument) then Exit;
  if not Assigned(FHistoryList) then Exit;
  ClickedIndex := FHistoryList.ItemIndex;
  if ClickedIndex < 0 then Exit;
  { Items before CurrentIndex are past states (undo); items after are future (redo).
    CurrentIndex = last undo item = UndoDepth - 1 }
  CurrentIndex := FDocument.UndoDepth - 1;
  if ClickedIndex = CurrentIndex then Exit;
  StepsDelta := ClickedIndex - CurrentIndex;
  if StepsDelta < 0 then
  begin
    { Navigate backward: undo |StepsDelta| times }
    for I := 1 to Abs(StepsDelta) do
    begin
      if FDocument.UndoDepth = 0 then Break;
      FDocument.Undo;
    end;
  end
  else
  begin
    { Navigate forward: redo StepsDelta times }
    for I := 1 to StepsDelta do
    begin
      if FDocument.RedoDepth = 0 then Break;
      FDocument.Redo;
    end;
  end;
  RefreshLayers;
  RefreshCanvas;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.UpdateCaption;
begin
  Caption := WindowCaptionForDocument(DisplayFileName, FDirty);
  UpdateSaveCommandCaption;
end;

procedure TMainForm.UpdateSaveCommandCaption;
begin
  if Assigned(FSaveMenuItem) then
    FSaveMenuItem.Caption := SaveCommandCaption(FCurrentFileName <> '');
end;

function TMainForm.RecentFilesStorePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'recent-files.txt';
end;

procedure TMainForm.LoadRecentFiles;
var
  StorePath: string;
  Index: Integer;
begin
  StorePath := RecentFilesStorePath;
  if not FileExists(StorePath) then
    Exit;

  try
    FRecentFiles.LoadFromFile(StorePath);
    for Index := FRecentFiles.Count - 1 downto 0 do
      if not FileExists(FRecentFiles[Index]) then
        FRecentFiles.Delete(Index);
    while FRecentFiles.Count > 10 do
      FRecentFiles.Delete(FRecentFiles.Count - 1);
  except
    FRecentFiles.Clear;
  end;
end;

procedure TMainForm.SaveRecentFiles;
var
  StorePath: string;
  StoreDir: string;
begin
  StorePath := RecentFilesStorePath;
  StoreDir := ExtractFileDir(StorePath);
  try
    if (StoreDir <> '') and (not DirectoryExists(StoreDir)) then
      ForceDirectories(StoreDir);
    FRecentFiles.SaveToFile(StorePath);
  except
    // Recent-file persistence should never block editing.
  end;
end;

procedure TMainForm.RebuildRecentFilesMenu;
var
  Index: Integer;
  MenuItem: TMenuItem;
  CaptionText: string;
begin
  if not Assigned(FRecentMenu) then
    Exit;

  FRecentMenu.Clear;
  if FRecentFiles.Count = 0 then
  begin
    MenuItem := TMenuItem.Create(FRecentMenu);
    MenuItem.Caption := '(Empty)';
    MenuItem.Enabled := False;
    FRecentMenu.Add(MenuItem);
    Exit;
  end;

  for Index := 0 to FRecentFiles.Count - 1 do
  begin
    if Index < 9 then
      CaptionText := Format('&%d %s', [Index + 1, FRecentFiles[Index]])
    else
      CaptionText := FRecentFiles[Index];
    MenuItem := TMenuItem.Create(FRecentMenu);
    MenuItem.Caption := CaptionText;
    MenuItem.Tag := Index;
    MenuItem.OnClick := @OpenRecentFileClick;
    FRecentMenu.Add(MenuItem);
  end;
end;

procedure TMainForm.RegisterRecentFile(const AFileName: string);
var
  ResolvedFileName: string;
  ExistingIndex: Integer;
begin
  if AFileName = '' then
    Exit;

  ResolvedFileName := ExpandFileName(AFileName);
  ExistingIndex := FRecentFiles.IndexOf(ResolvedFileName);
  if ExistingIndex >= 0 then
    FRecentFiles.Delete(ExistingIndex);
  FRecentFiles.Insert(0, ResolvedFileName);
  while FRecentFiles.Count > 10 do
    FRecentFiles.Delete(FRecentFiles.Count - 1);
  SaveRecentFiles;
  RebuildRecentFilesMenu;
end;

function TMainForm.PaletteControl(AKind: TPaletteKind): TPanel;
begin
  case AKind of
    pkTools:
      Result := FToolsPanel;
    pkColors:
      Result := FColorsPanel;
    pkHistory:
      Result := FHistoryPanel;
    pkLayers:
      Result := FRightPanel;
  else
    Result := nil;
  end;
end;

function TMainForm.PaletteKindForControl(AControl: TControl): TPaletteKind;
begin
  if (AControl = FToolsPanel) or ((AControl <> nil) and (AControl.Parent = FToolsPanel)) then
    Exit(pkTools);
  if (AControl = FColorsPanel) or ((AControl <> nil) and (AControl.Parent = FColorsPanel)) then
    Exit(pkColors);
  if (AControl = FHistoryPanel) or ((AControl <> nil) and (AControl.Parent = FHistoryPanel)) then
    Exit(pkHistory);
  if (AControl = FRightPanel) or ((AControl <> nil) and (AControl.Parent = FRightPanel)) then
    Exit(pkLayers);
  Result := pkTools;
end;

function TMainForm.PaletteHeaderControl(APalette: TControl): TPanel;
begin
  Result := nil;
  if not (APalette is TWinControl) then
    Exit;
  if (TWinControl(APalette).ControlCount = 0) or
     not (TWinControl(APalette).Controls[0] is TPanel) then
    Exit;
  Result := TPanel(TWinControl(APalette).Controls[0]);
end;

procedure TMainForm.ApplyPaletteVisualState(APalette: TControl; ADragging: Boolean);
var
  PaletteKind: TPaletteKind;
  HeaderPanel: TPanel;
begin
  if not (APalette is TPanel) then
    Exit;
  PaletteKind := PaletteKindForControl(APalette);
  TPanel(APalette).Color := PaletteSurfaceColor(PaletteKind, ADragging);
  HeaderPanel := PaletteHeaderControl(APalette);
  if Assigned(HeaderPanel) then
    HeaderPanel.Color := PaletteHeaderColor(PaletteKind, ADragging);
end;

procedure TMainForm.RefreshPaletteMenuChecks;
var
  PaletteKind: TPaletteKind;
  PaletteHost: TPanel;
begin
  for PaletteKind := Low(TPaletteKind) to High(TPaletteKind) do
  begin
    if not Assigned(FPaletteViewItems[PaletteKind]) then
      Continue;
    PaletteHost := PaletteControl(PaletteKind);
    FPaletteViewItems[PaletteKind].Checked := Assigned(PaletteHost) and PaletteHost.Visible;
  end;
end;

procedure TMainForm.RestorePaletteLayout;
var
  PaletteKind: TPaletteKind;
  PaletteHost: TPanel;
  PaletteRect: TRect;
begin
  for PaletteKind := Low(TPaletteKind) to High(TPaletteKind) do
  begin
    PaletteHost := PaletteControl(PaletteKind);
    if not Assigned(PaletteHost) then
      Continue;
    if Assigned(FWorkspacePanel) and (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
      PaletteRect := PaletteDefaultRectForWorkspace(
        PaletteKind,
        Rect(0, 0, FWorkspacePanel.ClientWidth, FWorkspacePanel.ClientHeight)
      )
    else
      PaletteRect := PaletteDefaultRect(PaletteKind);
    PaletteHost.SetBounds(
      PaletteRect.Left,
      PaletteRect.Top,
      PaletteRect.Right - PaletteRect.Left,
      PaletteRect.Bottom - PaletteRect.Top
    );
    ClampPaletteToWorkspace(PaletteHost);
    PaletteHost.Visible := True;
    ApplyPaletteVisualState(PaletteHost, False);
  end;
  RefreshPaletteMenuChecks;
end;

procedure TMainForm.ClampPaletteToWorkspace(APalette: TControl);
begin
  if (APalette = nil) or (FWorkspacePanel = nil) then
    Exit;
  APalette.Left := EnsureRange(
    APalette.Left,
    0,
    Max(0, FWorkspacePanel.ClientWidth - APalette.Width)
  );
  APalette.Top := EnsureRange(
    APalette.Top,
    0,
    Max(0, FWorkspacePanel.ClientHeight - APalette.Height)
  );
end;

procedure TMainForm.CreatePaletteHeader(ATarget: TPanel; AKind: TPaletteKind);
var
  HeaderPanel: TPanel;
  TitleLabel: TLabel;
  CloseButton: TButton;
begin
  HeaderPanel := TPanel.Create(ATarget);
  HeaderPanel.Parent := ATarget;
  HeaderPanel.Align := alTop;
  HeaderPanel.Height := PaletteHeaderHeight;
  HeaderPanel.BevelOuter := bvNone;
  HeaderPanel.Caption := '';
  HeaderPanel.ParentColor := False;
  HeaderPanel.Tag := Ord(AKind);
  HeaderPanel.OnMouseDown := @PaletteMouseDown;
  HeaderPanel.OnMouseMove := @PaletteMouseMove;
  HeaderPanel.OnMouseUp := @PaletteMouseUp;

  TitleLabel := TLabel.Create(HeaderPanel);
  TitleLabel.Parent := HeaderPanel;
  TitleLabel.Caption := PaletteTitle(AKind);
  TitleLabel.Left := 8;
  TitleLabel.Top := 4;
  TitleLabel.Font.Color := clWhite;
  TitleLabel.Font.Style := [fsBold];

  CloseButton := TButton.Create(HeaderPanel);
  CloseButton.Parent := HeaderPanel;
  CloseButton.Caption := '×';
  CloseButton.Width := 24;
  CloseButton.Height := 18;
  CloseButton.Left := ATarget.Width - CloseButton.Width - 4;
  CloseButton.Top := 2;
  CloseButton.Anchors := [akTop, akRight];
  CloseButton.Tag := Ord(AKind);
  CloseButton.OnClick := @HidePaletteClick;
end;

procedure TMainForm.CreatePalette(ATarget: TPanel; AKind: TPaletteKind);
var
  PaletteRect: TRect;
begin
  if Assigned(FWorkspacePanel) and (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
    PaletteRect := PaletteDefaultRectForWorkspace(
      AKind,
      Rect(0, 0, FWorkspacePanel.ClientWidth, FWorkspacePanel.ClientHeight)
    )
  else
    PaletteRect := PaletteDefaultRect(AKind);
  ATarget.Parent := FWorkspacePanel;
  ATarget.Caption := '';
  ATarget.BevelOuter := bvRaised;
  ATarget.ParentColor := False;
  ATarget.Tag := Ord(AKind);
  ATarget.Left := PaletteRect.Left;
  ATarget.Top := PaletteRect.Top;
  ATarget.Width := PaletteRect.Right - PaletteRect.Left;
  ATarget.Height := PaletteRect.Bottom - PaletteRect.Top;
  CreatePaletteHeader(ATarget, AKind);
  ApplyPaletteVisualState(ATarget, False);
  if Assigned(FWorkspacePanel) and (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
    ClampPaletteToWorkspace(ATarget);
end;

function TMainForm.ConfirmDocumentReplacement(const AAction: string): Boolean;
var
  Choice: Integer;
begin
  if not NeedsDiscardConfirmation(FDirty) then
    Exit(True);

  Choice := MessageDlg(
    'Save Changes',
    Format(
      'The current document has unsaved changes. Save before %s?',
      [AAction]
    ),
    mtConfirmation,
    [mbYes, mbNo, mbCancel],
    0
  );
  case Choice of
    mrYes:
      begin
        SaveDocumentClick(nil);
        Result := not FDirty; { proceed only if save succeeded }
      end;
    mrNo:
      Result := True; { discard and proceed }
  else
    Result := False; { cancel }
  end;
end;

procedure TMainForm.SetDirty(AValue: Boolean);
begin
  if AValue then
    InvalidatePreparedBitmap;
  FDirty := AValue;
  if (Length(FTabDirtyFlags) > FActiveTabIndex) then
    FTabDirtyFlags[FActiveTabIndex] := AValue;
  UpdateCaption;
  RefreshTabStrip;
end;

procedure TMainForm.SaveToPath(const AFileName: string);
var
  Surface: TRasterSurface;
  ResolvedFileName: string;
  SaveOpts: TSaveSurfaceOptions;
  QualityStr: string;
  ParsedQuality: Integer;
  Ext: string;
begin
  ResolvedFileName := ExpandFileName(AFileName);

  if SameText(ExtractFileExt(ResolvedFileName), '.fpd') then
  begin
    SaveNativeDocumentToFile(ResolvedFileName, FDocument);
    FCurrentFileName := ResolvedFileName;
    if Length(FTabFileNames) > FActiveTabIndex then
      FTabFileNames[FActiveTabIndex] := FCurrentFileName;
    RegisterRecentFile(FCurrentFileName);
    SetDirty(False);
    Exit;
  end;

  SaveOpts := DefaultSaveSurfaceOptions;
  Ext := LowerCase(ExtractFileExt(ResolvedFileName));

  { Show JPEG quality prompt }
  if (Ext = '.jpg') or (Ext = '.jpeg') then
  begin
    QualityStr := IntToStr(FJpegQuality);
    if not InputQuery('JPEG Quality', 'Quality (1–100, higher = better quality / larger file):', QualityStr) then
      Exit;
    ParsedQuality := StrToIntDef(Trim(QualityStr), FJpegQuality);
    ParsedQuality := EnsureRange(ParsedQuality, 1, 100);
    FJpegQuality := ParsedQuality;
    SaveOpts.JpegQuality := FJpegQuality;
  end;

  Surface := FDocument.Composite;
  try
    SaveSurfaceToFileWithOpts(ResolvedFileName, Surface, SaveOpts);
    FCurrentFileName := ResolvedFileName;
    if Length(FTabFileNames) > FActiveTabIndex then
      FTabFileNames[FActiveTabIndex] := FCurrentFileName;
    RegisterRecentFile(FCurrentFileName);
    SetDirty(False);
  finally
    Surface.Free;
  end;
end;

procedure TMainForm.LoadDocumentFromPath(const AFileName: string);
var
  Surface: TRasterSurface;
  LoadedDocument: TImageDocument;
  ResolvedFileName: string;
begin
  ResolvedFileName := ExpandFileName(AFileName);
  if SameText(ExtractFileExt(ResolvedFileName), '.fpd') then
  begin
    LoadedDocument := LoadNativeDocumentFromFile(ResolvedFileName);
    { Replace active tab's document }
    FTabDocuments[FActiveTabIndex].Free;
    FTabDocuments[FActiveTabIndex] := LoadedDocument;
    FDocument := LoadedDocument;
  end
  else
  begin
    Surface := LoadSurfaceFromFile(ResolvedFileName);
    try
      FDocument.ReplaceWithSingleLayer(Surface, ExtractFileName(ResolvedFileName));
    finally
      Surface.Free;
    end;
  end;

  FCurrentFileName := ResolvedFileName;
  if Length(FTabFileNames) > FActiveTabIndex then
    FTabFileNames[FActiveTabIndex] := FCurrentFileName;
  FPointerDown := False;
  SetLength(FLassoPoints, 0);
  FPendingSelectionMode := scReplace;
  FitDocumentToViewport(True);
  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  SetDirty(False);
  RegisterRecentFile(FCurrentFileName);
  RefreshLayers;
  RefreshCanvas;
  RefreshTabStrip;
end;

function TMainForm.LoadSurfaceForImportPath(const AFileName: string): TRasterSurface;
var
  ImportedDocument: TImageDocument;
  ResolvedFileName: string;
begin
  ResolvedFileName := ExpandFileName(AFileName);
  if SameText(ExtractFileExt(ResolvedFileName), '.fpd') then
  begin
    ImportedDocument := LoadNativeDocumentFromFile(ResolvedFileName);
    try
      Result := ImportedDocument.Composite;
    finally
      ImportedDocument.Free;
    end;
  end
  else
    Result := LoadSurfaceFromFile(ResolvedFileName);
end;

procedure TMainForm.ApplyZoomScale(ANewScale: Double);
begin
  if Assigned(FCanvasHost) then
    ApplyZoomScaleAtViewportPoint(
      ANewScale,
      Point(Max(0, FCanvasHost.ClientWidth div 2), Max(0, FCanvasHost.ClientHeight div 2))
    )
  else
  begin
    FZoomScale := Max(0.1, Min(16.0, ANewScale));
    RefreshCanvas;
  end;
end;

procedure TMainForm.ApplyZoomScaleAtViewportPoint(ANewScale: Double; const AViewportPoint: TPoint);
var
  AnchorImagePoint: TPoint;
  AnchorViewportPoint: TPoint;
begin
  AnchorViewportPoint := AViewportPoint;
  if Assigned(FCanvasHost) then
  begin
    AnchorViewportPoint.X := EnsureRange(AnchorViewportPoint.X, 0, Max(0, FCanvasHost.ClientWidth));
    AnchorViewportPoint.Y := EnsureRange(AnchorViewportPoint.Y, 0, Max(0, FCanvasHost.ClientHeight));
  end;

  if Assigned(FCanvasHost) and Assigned(FPaintBox) then
    AnchorImagePoint := Point(
      ViewportImageCoordinate(
        FCanvasHost.HorzScrollBar.Position,
        AnchorViewportPoint.X,
        FPaintBox.Left,
        FZoomScale,
        FDocument.Width
      ),
      ViewportImageCoordinate(
        FCanvasHost.VertScrollBar.Position,
        AnchorViewportPoint.Y,
        FPaintBox.Top,
        FZoomScale,
        FDocument.Height
      )
    )
  else
    AnchorImagePoint := Point(Max(0, FDocument.Width div 2), Max(0, FDocument.Height div 2));

  FZoomScale := Max(0.1, Min(16.0, ANewScale));
  UpdateCanvasSize;
  if Assigned(FCanvasHost) then
  begin
    if FPaintBox.Width <= FCanvasHost.ClientWidth then
      FCanvasHost.HorzScrollBar.Position := 0
    else
      FCanvasHost.HorzScrollBar.Position := ScrollPositionForAnchor(
        AnchorImagePoint.X,
        FZoomScale,
        FPaintBox.Left,
        AnchorViewportPoint.X
      );
    if FPaintBox.Height <= FCanvasHost.ClientHeight then
      FCanvasHost.VertScrollBar.Position := 0
    else
      FCanvasHost.VertScrollBar.Position := ScrollPositionForAnchor(
        AnchorImagePoint.Y,
        FZoomScale,
        FPaintBox.Top,
        AnchorViewportPoint.Y
      );
    FLastScrollPosition := Point(
      FCanvasHost.HorzScrollBar.Position,
      FCanvasHost.VertScrollBar.Position
    );
  end;
  RefreshCanvas;
end;

procedure TMainForm.ApplyImmediateTool(const APoint: TPoint);
var
  CompositeSurface: TRasterSurface;
begin
  case FCurrentTool of
    tkPencil:
      FDocument.ActiveLayer.Surface.DrawLine(
        FLastImagePoint.X,
        FLastImagePoint.Y,
        APoint.X,
        APoint.Y,
        Max(0, (FBrushSize - 1) div 2),
        ActivePaintColor,
        FBrushOpacity * 255 div 100,
        255 { pencil always hard }
      );
    tkBrush, tkEraser:
      FDocument.ActiveLayer.Surface.DrawLine(
        FLastImagePoint.X,
        FLastImagePoint.Y,
        APoint.X,
        APoint.Y,
        Max(1, FBrushSize div 2),
        ActivePaintColor,
        FBrushOpacity * 255 div 100,
        FBrushHardness * 255 div 100
      );
    tkFill:
      begin
        if FBucketFloodMode = 1 then
          { Global: fill entire layer with paint color }
          FDocument.ActiveLayer.Surface.Clear(ActivePaintColor)
        else
          FDocument.ActiveLayer.Surface.FloodFill(
            APoint.X,
            APoint.Y,
            ActivePaintColor,
            EnsureRange(FFillTolerance, 0, 255)
          );
      end;
    tkColorPicker:
      begin
        if FPickerSampleSource = 1 then
        begin
          { Sample from composite image }
          CompositeSurface := FDocument.Composite;
          try
            if FPickSecondaryTarget then
              FSecondaryColor := CompositeSurface[APoint.X, APoint.Y]
            else
              FPrimaryColor := CompositeSurface[APoint.X, APoint.Y];
          finally
            CompositeSurface.Free;
          end;
        end
        else
        begin
          { Sample from current layer only }
          if FDocument.ActiveLayer.Surface.InBounds(APoint.X, APoint.Y) then
          begin
            if FPickSecondaryTarget then
              FSecondaryColor := FDocument.ActiveLayer.Surface[APoint.X, APoint.Y]
            else
              FPrimaryColor := FDocument.ActiveLayer.Surface[APoint.X, APoint.Y];
          end;
        end;
      end;
    tkRecolor:
      FDocument.ActiveLayer.Surface.RecolorBrush(
        APoint.X,
        APoint.Y,
        Max(1, FBrushSize div 2),
        FPrimaryColor,
        FSecondaryColor,
        EnsureRange(FWandTolerance, 0, 255)
      );
    tkCloneStamp:
      if FCloneStampSampled and (FCloneStampSnapshot <> nil) then
      begin
        { Paint from snapshot at the offset relative to source point }
        FDocument.ActiveLayer.Surface.PasteSurface(
          FCloneStampSnapshot,
          FCloneStampSource.X + (APoint.X - FDragStart.X) - Max(1, FBrushSize div 2),
          FCloneStampSource.Y + (APoint.Y - FDragStart.Y) - Max(1, FBrushSize div 2),
          255
        );
      end;
  end;
  FLastImagePoint := APoint;
end;

procedure TMainForm.CommitShapeTool(const AStartPoint, AEndPoint: TPoint);
var
  DoFill: Boolean;
  DoOutline: Boolean;
  FillColor: TRGBA32;
begin
  { FShapeStyle: 0=Outline, 1=Fill, 2=Outline+Fill }
  DoOutline := FShapeStyle in [0, 2];
  DoFill := FShapeStyle in [1, 2];
  FillColor := RGBA(ActivePaintColor.R, ActivePaintColor.G, ActivePaintColor.B, ActivePaintColor.A);
  case FCurrentTool of
    tkLine:
      FDocument.ActiveLayer.Surface.DrawLine(
        AStartPoint.X,
        AStartPoint.Y,
        AEndPoint.X,
        AEndPoint.Y,
        Max(1, FBrushSize div 2),
        ActivePaintColor
      );
    tkGradient:
      begin
        if FGradientReverse then
        begin
          if FGradientType = 1 then
          begin
            { Radial reversed: secondary in center, primary at edge }
            FDocument.ActiveLayer.Surface.FillRadialGradient(
              AStartPoint.X,
              AStartPoint.Y,
              Round(Sqrt(Sqr(AEndPoint.X - AStartPoint.X) + Sqr(AEndPoint.Y - AStartPoint.Y))),
              FSecondaryColor,
              FPrimaryColor
            );
          end
          else
          begin
            FDocument.ActiveLayer.Surface.FillGradient(
              AStartPoint.X,
              AStartPoint.Y,
              AEndPoint.X,
              AEndPoint.Y,
              FSecondaryColor,
              FPrimaryColor
            );
          end;
        end
        else
        begin
          if FGradientType = 1 then
          begin
            { Radial: primary in center, secondary at edge }
            FDocument.ActiveLayer.Surface.FillRadialGradient(
              AStartPoint.X,
              AStartPoint.Y,
              Round(Sqrt(Sqr(AEndPoint.X - AStartPoint.X) + Sqr(AEndPoint.Y - AStartPoint.Y))),
              FPrimaryColor,
              FSecondaryColor
            );
          end
          else
          begin
            FDocument.ActiveLayer.Surface.FillGradient(
              AStartPoint.X,
              AStartPoint.Y,
              AEndPoint.X,
              AEndPoint.Y,
              FPrimaryColor,
              FSecondaryColor
            );
          end;
        end;
      end;
    tkRectangle:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.DrawRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), FillColor, True);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), ActivePaintColor, False);
      end;
    tkRoundedRectangle:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.DrawRoundedRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), FillColor, True);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawRoundedRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), ActivePaintColor, False);
      end;
    tkEllipseShape:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.DrawEllipse(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), FillColor, True);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawEllipse(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), ActivePaintColor, False);
      end;
    tkFreeformShape:
      FDocument.ActiveLayer.Surface.DrawPolygon(
        FLassoPoints,
        Max(1, FBrushSize div 3),
        ActivePaintColor,
        True
      );
  end;
end;

procedure TMainForm.ResetDocument(AWidth, AHeight: Integer);
begin
  FDocument.NewBlank(AWidth, AHeight);
  FCurrentFileName := '';
  FitDocumentToViewport(True);
  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  SetDirty(False);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.NewDocumentClick(Sender: TObject);
var
  TargetWidth: Integer;
  TargetHeight: Integer;
  NewDoc: TImageDocument;
begin
  TargetWidth := FDocument.Width;
  TargetHeight := FDocument.Height;
  if not RunNewImageDialog(Self, TargetWidth, TargetHeight, FNewImageResolutionDPI) then
    Exit;
  NewDoc := TImageDocument.Create(TargetWidth, TargetHeight);
  AddDocumentTab(NewDoc, '', False);
  FPointerDown := False;
  SetLength(FLassoPoints, 0);
  FPendingSelectionMode := scReplace;
  FitDocumentToViewport(True);
  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.OpenDocumentClick(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := SupportedOpenDialogFilter;
    if not Dialog.Execute then
      Exit;
    OpenFileInNewTab(Dialog.FileName);
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.OpenRecentFileClick(Sender: TObject);
var
  MenuItem: TMenuItem;
  Index: Integer;
  FileName: string;
begin
  if not (Sender is TMenuItem) then
    Exit;

  MenuItem := TMenuItem(Sender);
  Index := MenuItem.Tag;
  if (Index < 0) or (Index >= FRecentFiles.Count) then
    Exit;

  FileName := FRecentFiles[Index];
  if not FileExists(FileName) then
  begin
    FRecentFiles.Delete(Index);
    SaveRecentFiles;
    RebuildRecentFilesMenu;
    MessageDlg(
      'Open Recent',
      Format('The file "%s" is no longer available.', [FileName]),
      mtWarning,
      [mbOK],
      0
    );
    Exit;
  end;

  OpenFileInNewTab(FileName);
end;

procedure TMainForm.CloseDocumentClick(Sender: TObject);
var
  Choice: Integer;
begin
  if FDirty then
  begin
    Choice := MessageDlg('Save Changes',
      Format('Do you want to save changes to "%s"?', [TabDocumentDisplayName(FActiveTabIndex)]),
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    case Choice of
      mrYes:
        begin
          SaveDocumentClick(Sender);
          { If still dirty after save attempt (user cancelled save-as), abort close }
          if FDirty then Exit;
        end;
      mrNo: ; { Proceed without saving }
    else
      Exit; { Cancel — don't close }
    end;
  end;
  CloseDocumentTab(FActiveTabIndex);
end;

procedure TMainForm.ExitApplicationClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.SaveDocumentClick(Sender: TObject);
begin
  if FCurrentFileName = '' then
  begin
    SaveAsDocumentClick(Sender);
    Exit;
  end;
  SaveToPath(FCurrentFileName);
end;

procedure TMainForm.SaveAsDocumentClick(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Filter :=
      'FlatPaint Project|*.fpd|PNG|*.png|JPEG|*.jpg|Bitmap|*.bmp|TIFF|*.tif|' +
      'PCX|*.pcx|PNM|*.pnm|TGA|*.tga|XPM|*.xpm';
    Dialog.DefaultExt := 'fpd';
    if FCurrentFileName <> '' then
      Dialog.FileName := FCurrentFileName
    else
      Dialog.FileName := DisplayFileName + '.fpd';
    if not Dialog.Execute then
      Exit;
    SaveToPath(Dialog.FileName);
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.SaveAllDocumentsClick(Sender: TObject);
begin
  if SaveAllFallsBackToSaveAs(FCurrentFileName) then
    SaveAsDocumentClick(Sender)
  else
    SaveToPath(FCurrentFileName);
end;

procedure TMainForm.PrintDocumentClick(Sender: TObject);
var
  Surface: TRasterSurface;
  Bitmap: TBitmap;
  Scale: Double;
  DrawWidth: Integer;
  DrawHeight: Integer;
  LeftX: Integer;
  TopY: Integer;
begin
  try
    Surface := FDocument.Composite;
    try
      Bitmap := SurfaceToBitmap(Surface);
      try
        Scale := Min(Printer.PageWidth / Bitmap.Width, Printer.PageHeight / Bitmap.Height);
        DrawWidth := Max(1, Round(Bitmap.Width * Scale));
        DrawHeight := Max(1, Round(Bitmap.Height * Scale));
        LeftX := Max(0, (Printer.PageWidth - DrawWidth) div 2);
        TopY := Max(0, (Printer.PageHeight - DrawHeight) div 2);
        Printer.BeginDoc;
        try
          Printer.Canvas.StretchDraw(Rect(LeftX, TopY, LeftX + DrawWidth, TopY + DrawHeight), Bitmap);
        finally
          Printer.EndDoc;
        end;
      finally
        Bitmap.Free;
      end;
    finally
      Surface.Free;
    end;
  except
    on E: Exception do
      MessageDlg('Print', 'Printing failed: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.AcquireClick(Sender: TObject);
var
  ClipboardPicture: TPicture;
  ClipboardBitmap: TBitmap;
  ImportedSurface: TRasterSurface;
begin
  case ResolveAcquireMode(Clipboard.HasPictureFormat) of
    amClipboard:
      begin
        if not ConfirmDocumentReplacement('replace the current document from the clipboard') then
          Exit;
        ClipboardPicture := TPicture.Create;
        try
          Clipboard.AssignTo(ClipboardPicture);
          if (ClipboardPicture.Graphic = nil) or ClipboardPicture.Graphic.Empty then
            Exit;
          ClipboardBitmap := TBitmap.Create;
          try
            ClipboardBitmap.Assign(ClipboardPicture.Graphic);
            ImportedSurface := BitmapToSurface(ClipboardBitmap);
            try
              FDocument.ReplaceWithSingleLayer(ImportedSurface, 'Acquired Image');
            finally
              ImportedSurface.Free;
            end;
          finally
            ClipboardBitmap.Free;
          end;
        finally
          ClipboardPicture.Free;
        end;
        FCurrentFileName := '';
        FitDocumentToViewport(True);
        InvalidatePreparedBitmap;
        FLastImagePoint := Point(-1, -1);
        SetDirty(True);
        RefreshLayers;
        RefreshCanvas;
      end;
    amOpenFile:
      OpenDocumentClick(Sender);
  end;
end;

procedure TMainForm.ImportLayerClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  Surface: TRasterSurface;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := SupportedImportDialogFilter;
    if not Dialog.Execute then
      Exit;
    try
      Surface := LoadSurfaceForImportPath(Dialog.FileName);
      try
        FDocument.PushHistory('Import Layer');
        FDocument.PasteAsNewLayer(Surface, 0, 0, ExtractFileName(Dialog.FileName));
        SetDirty(True);
        RefreshLayers;
        RefreshCanvas;
      finally
        Surface.Free;
      end;
    except
      on E: Exception do
        MessageDlg('Import as Layer', 'Import failed: ' + E.Message, mtError, [mbOK], 0);
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.UndoClick(Sender: TObject);
begin
  FDocument.Undo;
  RefreshLayers;
  RefreshCanvas;
  SetDirty(True);
end;

procedure TMainForm.RedoClick(Sender: TObject);
begin
  FDocument.Redo;
  RefreshLayers;
  RefreshCanvas;
  SetDirty(True);
end;

procedure TMainForm.CutClick(Sender: TObject);
var
  Bounds: TRect;
begin
  FDocument.PushHistory('Cut');
  FreeAndNil(FClipboardSurface);
  if FDocument.HasSelection then
  begin
    Bounds := FDocument.Selection.BoundsRect;
    FClipboardOffset := Point(Bounds.Left, Bounds.Top);
    FClipboardSurface := FDocument.CutSelectionToSurface(True);
  end
  else
  begin
    FClipboardOffset := Point(0, 0);
    FClipboardSurface := FDocument.CutSelectionToSurface(False);
  end;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.CopyClick(Sender: TObject);
var
  Bounds: TRect;
begin
  FreeAndNil(FClipboardSurface);
  if FDocument.HasSelection then
  begin
    Bounds := FDocument.Selection.BoundsRect;
    FClipboardOffset := Point(Bounds.Left, Bounds.Top);
    FClipboardSurface := FDocument.CopySelectionToSurface(True);
  end
  else
  begin
    FClipboardOffset := Point(0, 0);
    FClipboardSurface := FDocument.CopySelectionToSurface(False);
  end;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.CopySelectionClick(Sender: TObject);
begin
  if not FDocument.HasSelection then
    Exit;
  CopyClick(Sender);
end;

procedure TMainForm.CopyMergedClick(Sender: TObject);
var
  Bounds: TRect;
begin
  FreeAndNil(FClipboardSurface);
  if FDocument.HasSelection then
  begin
    Bounds := FDocument.Selection.BoundsRect;
    FClipboardOffset := Point(Bounds.Left, Bounds.Top);
    FClipboardSurface := FDocument.CopyMergedToSurface(True);
  end
  else
  begin
    FClipboardOffset := Point(0, 0);
    FClipboardSurface := FDocument.CopyMergedToSurface(False);
  end;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.PasteClick(Sender: TObject);
begin
  if FClipboardSurface = nil then
    Exit;
  FDocument.PushHistory('Paste');
  FDocument.PasteAsNewLayer(FClipboardSurface, FClipboardOffset.X, FClipboardOffset.Y, 'Pasted Layer');
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.PasteIntoNewLayerClick(Sender: TObject);
begin
  PasteClick(Sender);
end;

procedure TMainForm.PasteIntoNewImageClick(Sender: TObject);
begin
  if FClipboardSurface = nil then
    Exit;
  FDocument.ReplaceWithSingleLayer(FClipboardSurface, 'Pasted Layer');
  FCurrentFileName := '';
  FitDocumentToViewport(True);
  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.AddLayerClick(Sender: TObject);
begin
  FDocument.PushHistory('Add Layer');
  FDocument.AddLayer;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.DuplicateLayerClick(Sender: TObject);
begin
  FDocument.PushHistory('Duplicate Layer');
  FDocument.DuplicateActiveLayer;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.DeleteLayerClick(Sender: TObject);
begin
  FDocument.PushHistory('Delete Layer');
  FDocument.DeleteActiveLayer;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.RenameLayerClick(Sender: TObject);
var
  ValueText: string;
begin
  ValueText := FDocument.ActiveLayer.Name;
  if not InputQuery('Rename Layer', 'Layer name', ValueText) then
    Exit;
  if Trim(ValueText) = '' then
    Exit;
  FDocument.PushHistory('Rename Layer');
  FDocument.RenameLayer(FDocument.ActiveLayerIndex, ValueText);
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.MoveLayerUpClick(Sender: TObject);
begin
  if FDocument.ActiveLayerIndex >= FDocument.LayerCount - 1 then
    Exit;
  FDocument.PushHistory('Move Layer Up');
  FDocument.MoveLayer(FDocument.ActiveLayerIndex, FDocument.ActiveLayerIndex + 1);
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.MoveLayerDownClick(Sender: TObject);
begin
  if FDocument.ActiveLayerIndex <= 0 then
    Exit;
  FDocument.PushHistory('Move Layer Down');
  FDocument.MoveLayer(FDocument.ActiveLayerIndex, FDocument.ActiveLayerIndex - 1);
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.MergeDownClick(Sender: TObject);
begin
  if FDocument.ActiveLayerIndex = 0 then
    Exit;
  FDocument.PushHistory('Merge Down');
  FDocument.MergeDown;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.FlattenClick(Sender: TObject);
begin
  FDocument.PushHistory('Flatten');
  FDocument.Flatten;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.ToggleLayerVisibilityClick(Sender: TObject);
begin
  FDocument.PushHistory('Toggle Layer Visibility');
  FDocument.SetLayerVisibility(
    FDocument.ActiveLayerIndex,
    not FDocument.Layers[FDocument.ActiveLayerIndex].Visible
  );
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.LayerOpacityClick(Sender: TObject);
var
  ValueText: string;
begin
  ValueText := IntToStr(FDocument.ActiveLayer.Opacity);
  if not InputQuery('Layer Opacity', 'Opacity (0 to 255)', ValueText) then
    Exit;
  FDocument.PushHistory('Layer Opacity');
  FDocument.SetLayerOpacity(
    FDocument.ActiveLayerIndex,
    EnsureRange(StrToIntDef(ValueText, FDocument.ActiveLayer.Opacity), 0, 255)
  );
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.ResizeImageClick(Sender: TObject);
var
  TargetWidth: Integer;
  TargetHeight: Integer;
  ResampleMode: TResampleMode;
begin
  TargetWidth := FDocument.Width;
  TargetHeight := FDocument.Height;
  ResampleMode := rmNearestNeighbor;
  if not RunResizeImageDialog(Self, TargetWidth, TargetHeight, ResampleMode) then
    Exit;
  FDocument.PushHistory('Resize Image');
  FDocument.ResizeImage(TargetWidth, TargetHeight, ResampleMode);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.ResizeCanvasClick(Sender: TObject);
var
  TargetWidth: Integer;
  TargetHeight: Integer;
begin
  if not PromptForSize('Resize Canvas', TargetWidth, TargetHeight) then
    Exit;
  FDocument.PushHistory('Resize Canvas');
  FDocument.ResizeCanvas(TargetWidth, TargetHeight);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.RotateClockwiseClick(Sender: TObject);
begin
  FDocument.PushHistory('Rotate 90 Right');
  FDocument.Rotate90Clockwise;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.RotateCounterClockwiseClick(Sender: TObject);
begin
  FDocument.PushHistory('Rotate 90 Left');
  FDocument.Rotate90CounterClockwise;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.Rotate180Click(Sender: TObject);
begin
  FDocument.PushHistory('Rotate 180');
  FDocument.Rotate180;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.FlipHorizontalClick(Sender: TObject);
begin
  FDocument.PushHistory('Flip Horizontal');
  FDocument.FlipHorizontal;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.FlipVerticalClick(Sender: TObject);
begin
  FDocument.PushHistory('Flip Vertical');
  FDocument.FlipVertical;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.AutoLevelClick(Sender: TObject);
begin
  FDocument.PushHistory('Auto-Level');
  FDocument.AutoLevel;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.InvertColorsClick(Sender: TObject);
begin
  FDocument.PushHistory('Invert Colors');
  FDocument.InvertColors;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.GrayscaleClick(Sender: TObject);
begin
  FDocument.PushHistory('Grayscale');
  FDocument.Grayscale;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.CurvesClick(Sender: TObject);
var
  GammaValue: Double;
begin
  GammaValue := 1.0;
  if not RunCurvesDialog(Self, GammaValue) then
    Exit;
  FDocument.PushHistory('Curves');
  FDocument.AdjustGammaCurve(GammaValue);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.HueSaturationClick(Sender: TObject);
var
  HueDelta: Integer;
  SaturationDelta: Integer;
begin
  HueDelta := 0;
  SaturationDelta := 0;
  if not RunHueSaturationDialog(Self, HueDelta, SaturationDelta) then
    Exit;
  FDocument.PushHistory('Hue / Saturation');
  FDocument.AdjustHueSaturation(HueDelta, SaturationDelta);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.LevelsClick(Sender: TObject);
var
  InputLow: Integer;
  InputHigh: Integer;
  OutputLow: Integer;
  OutputHigh: Integer;
begin
  InputLow := 0;
  InputHigh := 255;
  OutputLow := 0;
  OutputHigh := 255;
  if not RunLevelsDialog(Self, InputLow, InputHigh, OutputLow, OutputHigh) then
    Exit;
  FDocument.PushHistory('Levels');
  FDocument.AdjustLevels(
    InputLow,
    InputHigh,
    OutputLow,
    OutputHigh
  );
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.BrightnessContrastClick(Sender: TObject);
var
  Brightness: Integer;
  Contrast: Integer;
begin
  Brightness := 0;
  Contrast := 0;
  if not RunBrightnessContrastDialog(Self, Brightness, Contrast) then
    Exit;
  FDocument.PushHistory('Brightness / Contrast');
  FDocument.AdjustBrightness(Brightness);
  FDocument.AdjustContrast(Contrast);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.SepiaClick(Sender: TObject);
begin
  FDocument.PushHistory('Sepia');
  FDocument.Sepia;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.BlackAndWhiteClick(Sender: TObject);
var
  ValueText: string;
begin
  ValueText := '127';
  if not InputQuery('Black and White', 'Threshold (0 to 255)', ValueText) then
    Exit;
  FDocument.PushHistory('Black and White');
  FDocument.BlackAndWhite(EnsureRange(StrToIntDef(ValueText, 127), 0, 255));
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.PosterizeClick(Sender: TObject);
var
  Levels: Integer;
begin
  Levels := 6;
  if not RunPosterizeDialog(Self, Levels) then
    Exit;
  FDocument.PushHistory('Posterize');
  FDocument.Posterize(Levels);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.BlurClick(Sender: TObject);
var
  Radius: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  Radius := 2;
  if not RunBlurDialog(Self, Radius) then
    Exit;
  FDocument.PushHistory('Blur');
  FDocument.BoxBlur(Radius);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Blur';
  FLastEffectProc := @BlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.SharpenClick(Sender: TObject);
begin
  if FDocument.LayerCount = 0 then Exit;
  FDocument.PushHistory('Sharpen');
  FDocument.Sharpen;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Sharpen';
  FLastEffectProc := @SharpenClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.AddNoiseClick(Sender: TObject);
var
  Amount: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  Amount := 24;
  if not RunNoiseDialog(Self, Amount) then
    Exit;
  FDocument.PushHistory('Add Noise');
  FDocument.AddNoise(Amount);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Add Noise';
  FLastEffectProc := @AddNoiseClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.OutlineClick(Sender: TObject);
begin
  if FDocument.LayerCount = 0 then Exit;
  FDocument.PushHistory('Detect Edges');
  FDocument.DetectEdges;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Detect Edges';
  FLastEffectProc := @OutlineClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.OutlineEffectClick(Sender: TObject);
var
  AStr: string;
  ThresholdVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AStr := '10';
  if not InputQuery('Outline Effect', 'Alpha threshold (0–255):', AStr) then Exit;
  ThresholdVal := EnsureRange(StrToIntDef(AStr, 10), 0, 255);
  FDocument.PushHistory('Outline Effect');
  FDocument.OutlineEffect(FPrimaryColor, ThresholdVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Outline Effect';
  FLastEffectProc := @OutlineEffectClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.DeselectClick(Sender: TObject);
begin
  FDocument.PushHistory('Deselect');
  FDocument.Deselect;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.SelectAllClick(Sender: TObject);
begin
  FDocument.PushHistory('Select All');
  FDocument.SelectAll;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.InvertSelectionClick(Sender: TObject);
begin
  FDocument.PushHistory('Invert Selection');
  FDocument.InvertSelection;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.FillSelectionClick(Sender: TObject);
begin
  if not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory('Fill Selection');
  FDocument.FillSelection(FPrimaryColor);
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.EraseSelectionClick(Sender: TObject);
begin
  if not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory('Erase Selection');
  FDocument.EraseSelection;
  SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.CropToSelectionClick(Sender: TObject);
begin
  if not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory('Crop to Selection');
  FDocument.CropToSelection;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.SwapColorsClick(Sender: TObject);
var
  TempColor: TRGBA32;
begin
  TempColor := FPrimaryColor;
  FPrimaryColor := FSecondaryColor;
  FSecondaryColor := TempColor;
  RefreshColorsPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.ResetColorsClick(Sender: TObject);
begin
  FPrimaryColor := RGBA(0, 0, 0, 255);
  FSecondaryColor := RGBA(255, 255, 255, 255);
  RefreshColorsPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.PrimaryColorClick(Sender: TObject);
var
  Dialog: TColorDialog;
  SelectedColor: TRGBA32;
begin
  Dialog := TColorDialog.Create(Self);
  try
    if FColorEditTarget = 0 then
      SelectedColor := FPrimaryColor
    else
      SelectedColor := FSecondaryColor;
    Dialog.Color := RGBToColor(SelectedColor.R, SelectedColor.G, SelectedColor.B);
    if Dialog.Execute then
    begin
      if FColorEditTarget = 0 then
        FPrimaryColor := UIToRGBA(Dialog.Color)
      else
        FSecondaryColor := UIToRGBA(Dialog.Color);
    end;
  finally
    Dialog.Free;
  end;
  RefreshColorsPanel;
end;

procedure TMainForm.SecondaryColorClick(Sender: TObject);
begin
  { Legacy handler — now unused; color selection uses the combo dropdown }
  if Assigned(FColorTargetCombo) then
  begin
    FColorTargetCombo.ItemIndex := 1;
    ColorTargetComboChanged(FColorTargetCombo);
  end;
end;

procedure TMainForm.ZoomInClick(Sender: TObject);
begin
  ApplyZoomScale(NextZoomInScale(FZoomScale));
end;

procedure TMainForm.ZoomOutClick(Sender: TObject);
begin
  ApplyZoomScale(NextZoomOutScale(FZoomScale));
end;

procedure TMainForm.ActualSizeClick(Sender: TObject);
begin
  ApplyZoomScale(1.0);
end;

procedure TMainForm.FitToWindowClick(Sender: TObject);
begin
  FitDocumentToViewport(False);
  RefreshCanvas;
end;

procedure TMainForm.ZoomToSelectionClick(Sender: TObject);
var
  Bounds: TRect;
  SelectionWidth: Integer;
  SelectionHeight: Integer;
  AvailableWidth: Integer;
  AvailableHeight: Integer;
  TargetScale: Double;
  SelectionCenterX: Double;
  SelectionCenterY: Double;
begin
  if not FDocument.HasSelection then
    Exit;

  Bounds := FDocument.Selection.BoundsRect;
  SelectionWidth := Max(1, Bounds.Right - Bounds.Left);
  SelectionHeight := Max(1, Bounds.Bottom - Bounds.Top);
  AvailableWidth := Max(64, FCanvasHost.ClientWidth - 32);
  AvailableHeight := Max(64, FCanvasHost.ClientHeight - 32);
  TargetScale := Min(AvailableWidth / SelectionWidth, AvailableHeight / SelectionHeight);
  FZoomScale := Max(0.1, Min(16.0, TargetScale));
  UpdateCanvasSize;
  SelectionCenterX := Bounds.Left + (SelectionWidth / 2.0);
  SelectionCenterY := Bounds.Top + (SelectionHeight / 2.0);
  FCanvasHost.HorzScrollBar.Position := Max(
    0,
    FPaintBox.Left + Round(SelectionCenterX * FZoomScale) - (FCanvasHost.ClientWidth div 2)
  );
  FCanvasHost.VertScrollBar.Position := Max(
    0,
    FPaintBox.Top + Round(SelectionCenterY * FZoomScale) - (FCanvasHost.ClientHeight div 2)
  );
  FLastScrollPosition := Point(
    FCanvasHost.HorzScrollBar.Position,
    FCanvasHost.VertScrollBar.Position
  );
  FPaintBox.Invalidate;
  RefreshRulers;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.TogglePixelGridClick(Sender: TObject);
begin
  FShowPixelGrid := not FShowPixelGrid;
  if Assigned(FPixelGridMenuItem) then
    FPixelGridMenuItem.Checked := FShowPixelGrid;
  RefreshCanvas;
end;

procedure TMainForm.ToggleRulersClick(Sender: TObject);
begin
  FShowRulers := not FShowRulers;
  RefreshRulers;
end;

procedure TMainForm.UnitsPixelsClick(Sender: TObject);
begin
  FDisplayUnit := duPixels;
  RefreshUnitsMenu;
end;

procedure TMainForm.UnitsInchesClick(Sender: TObject);
begin
  FDisplayUnit := duInches;
  RefreshUnitsMenu;
end;

procedure TMainForm.UnitsCentimetersClick(Sender: TObject);
begin
  FDisplayUnit := duCentimeters;
  RefreshUnitsMenu;
end;

procedure TMainForm.UtilityButtonClick(Sender: TObject);
var
  UtilityCommand: TUtilityCommandKind;
  PaletteKind: TPaletteKind;
begin
  if not (Sender is TControl) then
    Exit;
  UtilityCommand := TUtilityCommandKind(TControl(Sender).Tag);
  case UtilityCommand of
    ucTools: PaletteKind := pkTools;
    ucHistory: PaletteKind := pkHistory;
    ucLayers: PaletteKind := pkLayers;
    ucColors: PaletteKind := pkColors;
    ucSettings:
      begin
        SettingsClick(Sender);
        Exit;
      end;
    ucHelp:
      begin
        HelpClick(Sender);
        Exit;
      end;
  else
    Exit;
  end;
  TogglePaletteViewClick(PaletteControl(PaletteKind));
end;

procedure TMainForm.SettingsClick(Sender: TObject);
var
  DisplayUnitIndex: Integer;
begin
  DisplayUnitIndex := Ord(FDisplayUnit);
  if not RunSettingsDialog(Self, FNewImageResolutionDPI, DisplayUnitIndex) then
    Exit;
  FDisplayUnit := TDisplayUnit(DisplayUnitIndex);
  RefreshUnitsMenu;
end;

procedure TMainForm.HelpClick(Sender: TObject);
begin
  MessageDlg(
    'FlatPaint Help',
    'Primary shortcuts:'#13#10 +
    'Cmd+1 Tools  Cmd+2 Colors  Cmd+3 Layers  Cmd+4 History'#13#10 +
    'Cmd+'' Pixel Grid  Cmd+Option+R Rulers'#13#10 +
    'Cmd+N New  Cmd+O Open  Cmd+S Save  Cmd+W Close'#13#10 +
    'Supported open formats:'#13#10 +
    'FlatPaint (.fpd), XCF, PSD, PNG, JPEG, BMP, TIFF, GIF, PCX, PNM, TGA, XPM, XWD',
    mtInformation,
    [mbOK],
    0
  );
end;

procedure TMainForm.StatusZoomToggleClick(Sender: TObject);
begin
  if Abs(FZoomScale - 1.0) <= 0.01 then
    FitToWindowClick(Sender)
  else
    ActualSizeClick(Sender);
end;

procedure TMainForm.AppIdle(Sender: TObject; var Done: Boolean);
var
  ScrollPosition: TPoint;
begin
  Done := True;
  if not Assigned(FCanvasHost) then
    Exit;

  if FDeferredLayoutPass and Assigned(FWorkspacePanel) and
     (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
  begin
    RestorePaletteLayout;
    LayoutStatusBarControls(nil);
    FDeferredLayoutPass := False;
  end;

  { Install native pinch-to-zoom handler once handles are ready }
  if (not FMagnifyInstalled) and FCanvasHost.HandleAllocated then
  begin
    FPInstallMagnifyHandler(Pointer(FCanvasHost.Handle),
      @FPMagnifyCallbackProc);
    FMagnifyInstalled := True;
  end;

  ScrollPosition := Point(
    FCanvasHost.HorzScrollBar.Position,
    FCanvasHost.VertScrollBar.Position
  );
  if (ScrollPosition.X <> FLastScrollPosition.X) or
     (ScrollPosition.Y <> FLastScrollPosition.Y) then
  begin
    FLastScrollPosition := ScrollPosition;
    RefreshRulers;
  end;
end;

procedure TMainForm.ViewportMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  ViewportPoint: TPoint;
begin
  if not Assigned(FCanvasHost) then
    Exit;
  if not ZoomWheelUsesViewportZoom(Shift) then
    Exit;

  ViewportPoint := FCanvasHost.ScreenToClient(MousePos);
  if WheelDelta < 0 then
    ApplyZoomScaleAtViewportPoint(NextZoomOutScale(FZoomScale), ViewportPoint)
  else if WheelDelta > 0 then
    ApplyZoomScaleAtViewportPoint(NextZoomInScale(FZoomScale), ViewportPoint);
  Handled := WheelDelta <> 0;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  I: Integer;
  DirtyCount: Integer;
  Choice: Integer;
begin
  { Sync current tab dirty flag }
  if Length(FTabDirtyFlags) > FActiveTabIndex then
    FTabDirtyFlags[FActiveTabIndex] := FDirty;
  DirtyCount := 0;
  for I := 0 to Length(FTabDirtyFlags) - 1 do
    if FTabDirtyFlags[I] then
      Inc(DirtyCount);
  if DirtyCount = 0 then
    CanClose := True
  else
  begin
    Choice := MessageDlg(
      'Save Changes',
      Format('You have %d document(s) with unsaved changes. Save before quitting?', [DirtyCount]),
      mtConfirmation,
      [mbYes, mbNo, mbCancel],
      0
    );
    case Choice of
      mrYes:
        begin
          SaveAllDocumentsClick(Sender);
          CanClose := True;
        end;
      mrNo:
        CanClose := True;
    else
      CanClose := False;
    end;
  end;
end;

procedure TMainForm.TogglePaletteViewClick(Sender: TObject);
var
  PaletteKind: TPaletteKind;
  PaletteHost: TPanel;
begin
  if Sender is TMenuItem then
    PaletteKind := TPaletteKind(TMenuItem(Sender).Tag)
  else if Sender is TControl then
    PaletteKind := TPaletteKind(TControl(Sender).Tag)
  else
    Exit;
  if not (PaletteKind in [pkTools, pkColors, pkHistory, pkLayers]) then
    Exit;
  PaletteHost := PaletteControl(PaletteKind);
  if not Assigned(PaletteHost) then
    Exit;
  PaletteHost.Visible := not PaletteHost.Visible;
  if PaletteHost.Visible then
  begin
    ApplyPaletteVisualState(PaletteHost, False);
    PaletteHost.BringToFront;
  end;
  RefreshPaletteMenuChecks;
end;

procedure TMainForm.ResetPaletteLayoutClick(Sender: TObject);
begin
  RestorePaletteLayout;
end;

procedure TMainForm.HidePaletteClick(Sender: TObject);
var
  PaletteKind: TPaletteKind;
  PaletteHost: TPanel;
begin
  if not (Sender is TControl) then
    Exit;
  PaletteKind := TPaletteKind(TControl(Sender).Tag);
  PaletteHost := PaletteControl(PaletteKind);
  if not Assigned(PaletteHost) then
    Exit;
  PaletteHost.Visible := False;
  RefreshPaletteMenuChecks;
end;

procedure TMainForm.ToolButtonClick(Sender: TObject);
begin
  SetLength(FLassoPoints, 0);
  FCurrentTool := TToolKind(TControl(Sender).Tag);
  FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
  UpdateToolOptionControl;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.ToolComboChange(Sender: TObject);
begin
  SetLength(FLassoPoints, 0);
  if FToolCombo.ItemIndex >= 0 then
    FCurrentTool := TToolKind(PtrInt(FToolCombo.Items.Objects[FToolCombo.ItemIndex]));
  UpdateToolOptionControl;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.ZoomComboChange(Sender: TObject);
begin
  if FUpdatingZoomControl then
    Exit;
  if not Assigned(FZoomCombo) or (FZoomCombo.ItemIndex < 0) then
    Exit;
  ApplyZoomScale(ZoomPresetScale(FZoomCombo.ItemIndex));
end;

procedure TMainForm.BrushSizeChanged(Sender: TObject);
begin
  if FUpdatingToolOption then
    Exit;
  case FCurrentTool of
    tkMagicWand:
      FWandTolerance := EnsureRange(FBrushSpin.Value, 0, 255);
    tkPencil, tkBrush, tkEraser, tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape:
      FBrushSize := Max(1, FBrushSpin.Value);
  end;
end;

procedure TMainForm.LayerListClick(Sender: TObject);
begin
  if FLayerList.ItemIndex >= 0 then
    FDocument.ActiveLayerIndex := FLayerList.ItemIndex;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.LayerListDblClick(Sender: TObject);
begin
  ToggleLayerVisibilityClick(Sender);
end;

procedure TMainForm.PaletteMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DragControl: TControl;
begin
  if (Button <> mbLeft) or not (Sender is TControl) then
    Exit;
  DragControl := TControl(Sender);
  if (DragControl.Parent <> nil) and (DragControl.Parent is TPanel) then
    FDraggingPalette := TControl(DragControl.Parent)
  else
    FDraggingPalette := DragControl;
  FPaletteDragOffset := Point(X, Y);
  FDraggingPalette.BringToFront;
  ApplyPaletteVisualState(FDraggingPalette, True);
end;

procedure TMainForm.PaletteMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (FDraggingPalette = nil) or not (Sender is TControl) then
    Exit;
  if (TControl(Sender) <> FDraggingPalette) and (TControl(Sender).Parent <> FDraggingPalette) then
    Exit;
  FDraggingPalette.Left := FDraggingPalette.Left + X - FPaletteDragOffset.X;
  FDraggingPalette.Top := FDraggingPalette.Top + Y - FPaletteDragOffset.Y;
  ClampPaletteToWorkspace(FDraggingPalette);
end;

procedure TMainForm.PaletteMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  SnappedRect: TRect;
begin
  if (FDraggingPalette <> nil) and (Sender is TControl) and
     ((TControl(Sender) = FDraggingPalette) or (TControl(Sender).Parent = FDraggingPalette)) then
  begin
    SnappedRect := SnapPaletteRect(
      Rect(
        FDraggingPalette.Left,
        FDraggingPalette.Top,
        FDraggingPalette.Left + FDraggingPalette.Width,
        FDraggingPalette.Top + FDraggingPalette.Height
      ),
      FWorkspacePanel.ClientRect
    );
    FDraggingPalette.SetBounds(
      SnappedRect.Left,
      SnappedRect.Top,
      SnappedRect.Right - SnappedRect.Left,
      SnappedRect.Bottom - SnappedRect.Top
    );
    ApplyPaletteVisualState(FDraggingPalette, False);
    FDraggingPalette := nil;
  end;
end;

procedure TMainForm.PaintBoxPaint(Sender: TObject);
begin
  PaintCanvasTo(FPaintBox.Canvas, FPaintBox.ClientRect);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  NewTool: TToolKind;
begin
  { spacebar pan begins }
  if Key = VK_SPACE then
  begin
    ActivateTempPan;
    Key := 0;
    Exit;
  end;

  { Ctrl+Tab / Ctrl+Shift+Tab — cycle document tabs }
  if (ssCtrl in Shift) and (Key = VK_TAB) then
  begin
    if ssShift in Shift then
    begin
      { Previous tab }
      if Length(FTabDocuments) > 1 then
        SwitchToTab((FActiveTabIndex - 1 + Length(FTabDocuments)) mod Length(FTabDocuments));
    end
    else
    begin
      { Next tab }
      if Length(FTabDocuments) > 1 then
        SwitchToTab((FActiveTabIndex + 1) mod Length(FTabDocuments));
    end;
    Key := 0;
    Exit;
  end;

  { Tool shortcuts and color swap/reset only; modifiers are allowed for
    cycling (Shift reverses order) }  
  NewTool := NextToolForKey(Char(Key), ssShift in Shift, FCurrentTool);
  if NewTool <> FCurrentTool then
  begin
    FCurrentTool := NewTool;
    if Assigned(FToolCombo) then
      FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
    UpdateToolOptionControl;
    UpdateStatusForTool; { refresh label/hint etc }
    Key := 0;
    Exit;
  end;

  { Only handle the single-letter color shortcuts when no other tool key
    consumed the event; modifiers are ignored above except for Shift }  
  case UpCase(Char(Key)) of
    'C':
      begin
        { toggle which color the wheel edits }
        if FColorEditTarget = 0 then
          FColorEditTarget := 1
        else
          FColorEditTarget := 0;
        if Assigned(FColorTargetCombo) then
          FColorTargetCombo.ItemIndex := FColorEditTarget;
        RefreshColorsPanel;
        if Assigned(FColorsBox) then
          FColorsBox.Invalidate;
        Key := 0;
      end;
    'X':
      begin
        SwapColorsClick(Sender);
        Key := 0;
      end;
    'D':
      begin
        ResetColorsClick(Sender);
        Key := 0;
      end;
  end;
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    DeactivateTempPan;
end;

{------------------------------------------------------------------------------}
{ Testing simulation helpers }

procedure TMainForm.SimulateKeyDown(Key: Word; Shift: TShiftState);
begin
  { call the same handler the form uses internally; Sender can be Self }
  FormKeyDown(Self, Key, Shift);
end;

procedure TMainForm.SimulateKeyUp(Key: Word; Shift: TShiftState);
begin
  FormKeyUp(Self, Key, Shift);
end;

procedure TMainForm.SimulateMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  PaintBoxMouseDown(nil, Button, Shift, X, Y);
end;

procedure TMainForm.SimulateMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  PaintBoxMouseUp(nil, Button, Shift, X, Y);
end;

procedure TMainForm.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
begin
  if Button = mbMiddle then
  begin
    ActivateTempPan;
    FPickSecondaryTarget := False;
    FStrokeColor := FPrimaryColor;
  end
  else
  begin
    FPickSecondaryTarget := Button = mbRight;
    if FPickSecondaryTarget then
      FStrokeColor := FSecondaryColor
    else
      FStrokeColor := FPrimaryColor;
  end;

  ImagePoint := CanvasToImage(X, Y);
  FLastPointerPoint := Point(X, Y);
  FLastImagePoint := ImagePoint;
  FDragStart := ImagePoint;
  { Only override combo-selected mode when modifier keys are held }
  if (ssShift in Shift) or (ssAlt in Shift) then
    FPendingSelectionMode := SelectionModeFromShift(Shift);
  FPointerDown := True;

  case FCurrentTool of
    tkPencil, tkBrush, tkEraser:
      begin
        FDocument.PushHistory(PaintToolName(FCurrentTool));
        ApplyImmediateTool(ImagePoint);
        SetDirty(True);
        RefreshCanvas;
      end;
    tkFill:
      begin
        FDocument.PushHistory(PaintToolName(FCurrentTool));
        ApplyImmediateTool(ImagePoint);
        SetDirty(True);
        RefreshCanvas;
        FPointerDown := False;
      end;
    tkSelectLasso:
      begin
        SetLength(FLassoPoints, 0);
        AppendLassoPoint(ImagePoint);
        RefreshCanvas;
      end;
    tkFreeformShape:
      begin
        SetLength(FLassoPoints, 0);
        AppendLassoPoint(ImagePoint);
        RefreshCanvas;
      end;
    tkMagicWand:
      begin
        FDocument.PushHistory('Magic Wand');
        FDocument.SelectMagicWand(ImagePoint.X, ImagePoint.Y, EnsureRange(FWandTolerance, 0, 255), FPendingSelectionMode, FWandSampleSource = 1, FWandContiguous);
        SetDirty(True);
        RefreshCanvas;
        FPointerDown := False;
      end;
    tkText:
      begin
        { Text tool: show dialog on click }
        if RunTextDialog(Self, FTextLastResult) then
        begin
          FDocument.PushHistory('Text');
          PlaceTextAtPoint(FTextLastResult, ImagePoint, FPrimaryColor);
          SetDirty(True);
          InvalidatePreparedBitmap;
          RefreshCanvas;
        end;
        FPointerDown := False;
      end;
    tkCloneStamp:
      begin
        if FPickSecondaryTarget then
        begin
          { Right-click = set clone source }
          FCloneStampSource := ImagePoint;
          FCloneStampSampled := True;
          FCloneStampSnapshot.Free;
          FCloneStampSnapshot := FDocument.ActiveLayer.Surface.Clone;
          FPointerDown := False;
        end
        else if FCloneStampSampled then
        begin
          FDocument.PushHistory('Clone Stamp');
          ApplyImmediateTool(ImagePoint);
          SetDirty(True);
          RefreshCanvas;
        end
        else
          FPointerDown := False;
      end;
    tkRecolor:
      begin
        FDocument.PushHistory('Recolor');
        ApplyImmediateTool(ImagePoint);
        SetDirty(True);
        RefreshCanvas;
      end;
    tkCrop:
      begin
        { Crop: drag rectangle on mouse up }
        RefreshCanvas;
      end;
    tkZoom:
      begin
        if FPickSecondaryTarget then
          ApplyZoomScaleAtViewportPoint(
            NextZoomOutScale(FZoomScale),
            Point(ImageOriginInViewport.X + X, ImageOriginInViewport.Y + Y)
          )
        else
          ApplyZoomScaleAtViewportPoint(
            NextZoomInScale(FZoomScale),
            Point(ImageOriginInViewport.X + X, ImageOriginInViewport.Y + Y)
          );
        FPointerDown := False;
      end;
    tkPan:
      begin
        FPickSecondaryTarget := False;
      end;
    tkColorPicker:
      begin
        ApplyImmediateTool(ImagePoint);
        RefreshStatus(ImagePoint);
        FPointerDown := False;
      end;
    tkMoveSelection, tkMovePixels:
      begin
        if not FDocument.HasSelection then
          FPointerDown := False
        else
          FDocument.PushHistory(PaintToolName(FCurrentTool));
      end;
  end;
end;

procedure TMainForm.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
  DeltaX: Integer;
  DeltaY: Integer;
begin
  ImagePoint := CanvasToImage(X, Y);
  DeltaX := ImagePoint.X - FLastImagePoint.X;
  DeltaY := ImagePoint.Y - FLastImagePoint.Y;
  if FPointerDown then
    case FCurrentTool of
      tkPencil, tkBrush, tkEraser:
        begin
          ApplyImmediateTool(ImagePoint);
          InvalidatePreparedBitmap;
          RefreshCanvas;
        end;
      tkPan:
        begin
          if Assigned(FCanvasHost) then
          begin
            FCanvasHost.HorzScrollBar.Position := PannedScrollPosition(
              FCanvasHost.HorzScrollBar.Position,
              X,
              FLastPointerPoint.X
            );
            FCanvasHost.VertScrollBar.Position := PannedScrollPosition(
              FCanvasHost.VertScrollBar.Position,
              Y,
              FLastPointerPoint.Y
            );
            FLastScrollPosition := Point(
              FCanvasHost.HorzScrollBar.Position,
              FCanvasHost.VertScrollBar.Position
            );
            RefreshRulers;
          end;
          FLastPointerPoint := Point(X, Y);
        end;
      tkMoveSelection:
        if (DeltaX <> 0) or (DeltaY <> 0) then
        begin
          FDocument.MoveSelectionBy(DeltaX, DeltaY);
          FLastImagePoint := ImagePoint;
          SetDirty(True);
          RefreshCanvas;
        end;
      tkMovePixels:
        if (DeltaX <> 0) or (DeltaY <> 0) then
        begin
          FDocument.MoveSelectedPixelsBy(DeltaX, DeltaY);
          FLastImagePoint := ImagePoint;
          SetDirty(True);
          RefreshCanvas;
        end;
      tkSelectLasso, tkFreeformShape:
        begin
          AppendLassoPoint(ImagePoint);
          FLastImagePoint := ImagePoint;
          RefreshCanvas;
        end;
      tkGradient, tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkSelectRect, tkSelectEllipse, tkCrop:
        begin
          FLastImagePoint := ImagePoint;
          RefreshCanvas;
        end;
      tkRecolor:
        begin
          ApplyImmediateTool(ImagePoint);
          SetDirty(True);
          RefreshCanvas;
        end;
      tkCloneStamp:
        if FCloneStampSampled then
        begin
          ApplyImmediateTool(ImagePoint);
          SetDirty(True);
          RefreshCanvas;
        end;
    end;
  if not FPointerDown or not (FCurrentTool in [tkPencil, tkBrush, tkEraser, tkMoveSelection, tkMovePixels]) then
    FLastImagePoint := ImagePoint;
  RefreshStatus(ImagePoint);
end;

procedure TMainForm.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
begin
  if not FPointerDown then
    Exit;
  if Button = mbMiddle then
    DeactivateTempPan;
  FPointerDown := False;
  ImagePoint := CanvasToImage(X, Y);
  FLastImagePoint := ImagePoint;

  if FCurrentTool in [tkGradient, tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape] then
  begin
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    CommitShapeTool(FDragStart, ImagePoint);
    SetDirty(True);
    RefreshCanvas;
  end;
  if FCurrentTool = tkCrop then
  begin
    { Commit crop if drag was meaningful }
    if (Abs(ImagePoint.X - FDragStart.X) > 2) and (Abs(ImagePoint.Y - FDragStart.Y) > 2) then
    begin
      FDocument.PushHistory('Crop');
      FDocument.Crop(
        Min(FDragStart.X, ImagePoint.X),
        Min(FDragStart.Y, ImagePoint.Y),
        Abs(ImagePoint.X - FDragStart.X),
        Abs(ImagePoint.Y - FDragStart.Y)
      );
      SetDirty(True);
      UpdateCanvasSize;
      InvalidatePreparedBitmap;
      RefreshLayers;
      RefreshCanvas;
    end;
  end;
  if FCurrentTool = tkFreeformShape then
  begin
    AppendLassoPoint(ImagePoint);
    if Length(FLassoPoints) > 1 then
    begin
      FDocument.PushHistory(PaintToolName(FCurrentTool));
      CommitShapeTool(FDragStart, ImagePoint);
      SetDirty(True);
    end;
    SetLength(FLassoPoints, 0);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectRect then
  begin
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    FDocument.SelectRectangle(FDragStart.X, FDragStart.Y, ImagePoint.X, ImagePoint.Y, FPendingSelectionMode);
    SetDirty(True);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectEllipse then
  begin
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    FDocument.SelectEllipse(FDragStart.X, FDragStart.Y, ImagePoint.X, ImagePoint.Y, FPendingSelectionMode);
    SetDirty(True);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectLasso then
  begin
    AppendLassoPoint(ImagePoint);
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    FDocument.SelectLasso(FLassoPoints, FPendingSelectionMode);
    SetLength(FLassoPoints, 0);
    SetDirty(True);
    RefreshCanvas;
  end;
  RefreshStatus(ImagePoint);
end;

procedure TMainForm.PlaceTextAtPoint(const AResult: TTextDialogResult;
  APoint: TPoint; AColor: TRGBA32);
var
  TextSurface: TRasterSurface;
begin
  TextSurface := RenderTextToSurface(AResult, AColor);
  if TextSurface = nil then
    Exit;
  try
    FDocument.ActiveLayer.Surface.PasteSurface(TextSurface,
      APoint.X, APoint.Y);
  finally
    TextSurface.Free;
  end;
end;

procedure TMainForm.EmbossClick(Sender: TObject);
begin
  if FDocument.LayerCount = 0 then Exit;
  FDocument.PushHistory('Emboss');
  FDocument.Emboss;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Emboss';
  FLastEffectProc := @EmbossClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.SoftenClick(Sender: TObject);
begin
  if FDocument.LayerCount = 0 then Exit;
  FDocument.PushHistory('Soften');
  FDocument.Soften;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Soften';
  FLastEffectProc := @SoftenClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RenderCloudsClick(Sender: TObject);
begin
  if FDocument.LayerCount = 0 then Exit;
  FDocument.PushHistory('Render Clouds');
  FDocument.RenderClouds(1);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Render Clouds';
  FLastEffectProc := @RenderCloudsClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.PixelateClick(Sender: TObject);
var
  AStr: string;
  Val: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AStr := '10';
  if not InputQuery('Pixelate', 'Block Size (1 to 100)', AStr) then Exit;
  Val := EnsureRange(StrToIntDef(AStr, 10), 1, 100);
  FDocument.PushHistory('Pixelate');
  FDocument.Pixelate(Val);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Pixelate';
  FLastEffectProc := @PixelateClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.VignetteClick(Sender: TObject);
var
  AStr: string;
  Val: Integer;
  Strength: Double;
begin
  if FDocument.LayerCount = 0 then Exit;
  AStr := '50';
  if not InputQuery('Vignette', 'Strength (0 to 100)', AStr) then Exit;
  Val := EnsureRange(StrToIntDef(AStr, 50), 0, 100);
  Strength := Val / 100.0;
  FDocument.PushHistory('Vignette');
  FDocument.Vignette(Strength);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Vignette';
  FLastEffectProc := @VignetteClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.MotionBlurClick(Sender: TObject);
var
  AStr: string;
  AngleVal, DistVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AStr := '0';
  if not InputQuery('Motion Blur', 'Angle in degrees (0-359)', AStr) then Exit;
  AngleVal := EnsureRange(StrToIntDef(AStr, 0), 0, 359);
  AStr := '10';
  if not InputQuery('Motion Blur', 'Distance in pixels (1-100)', AStr) then Exit;
  DistVal := EnsureRange(StrToIntDef(AStr, 10), 1, 100);
  FDocument.PushHistory('Motion Blur');
  FDocument.MotionBlur(AngleVal, DistVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Motion Blur';
  FLastEffectProc := @MotionBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.MedianFilterClick(Sender: TObject);
var
  AStr: string;
  RadiusVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AStr := '1';
  if not InputQuery('Median Filter (Denoise)', 'Radius (1=3x3, 2=5x5)', AStr) then Exit;
  RadiusVal := EnsureRange(StrToIntDef(AStr, 1), 1, 2);
  FDocument.PushHistory('Median Filter');
  FDocument.MedianFilter(RadiusVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Median Filter';
  FLastEffectProc := @MedianFilterClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.GlowClick(Sender: TObject);
var
  RadStr, IntStr: string;
  RadVal, IntVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  RadStr := '3';
  if not InputQuery('Glow Effect', 'Radius (1–10):', RadStr) then Exit;
  RadVal := EnsureRange(StrToIntDef(Trim(RadStr), 3), 1, 10);
  IntStr := '80';
  if not InputQuery('Glow Effect', 'Intensity (0–200):', IntStr) then Exit;
  IntVal := EnsureRange(StrToIntDef(Trim(IntStr), 80), 0, 200);
  FDocument.PushHistory('Glow Effect');
  FDocument.GlowEffect(RadVal, IntVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Glow Effect';
  FLastEffectProc := @GlowClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.OilPaintClick(Sender: TObject);
var
  RadStr: string;
  RadVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  RadStr := '4';
  if not InputQuery('Oil Paint', 'Brush radius (1–8):', RadStr) then Exit;
  RadVal := EnsureRange(StrToIntDef(Trim(RadStr), 4), 1, 8);
  FDocument.PushHistory('Oil Paint');
  FDocument.OilPaint(RadVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Oil Paint';
  FLastEffectProc := @OilPaintClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.FrostedGlassClick(Sender: TObject);
var
  AmtStr: string;
  AmtVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AmtStr := '4';
  if not InputQuery('Frosted Glass', 'Amount (1–20):', AmtStr) then Exit;
  AmtVal := EnsureRange(StrToIntDef(Trim(AmtStr), 4), 1, 20);
  FDocument.PushHistory('Frosted Glass');
  FDocument.FrostedGlass(AmtVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Frosted Glass';
  FLastEffectProc := @FrostedGlassClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.ZoomBlurClick(Sender: TObject);
var
  AmtStr: string;
  AmtVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AmtStr := '8';
  if not InputQuery('Zoom Blur', 'Amount (1–30):', AmtStr) then Exit;
  AmtVal := EnsureRange(StrToIntDef(Trim(AmtStr), 8), 1, 30);
  FDocument.PushHistory('Zoom Blur');
  FDocument.ZoomBlur(FDocument.Width div 2, FDocument.Height div 2, AmtVal);
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Zoom Blur';
  FLastEffectProc := @ZoomBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RepeatLastEffectClick(Sender: TObject);
begin
  if Assigned(FLastEffectProc) then
    FLastEffectProc(Sender);
end;

procedure TMainForm.LayerPropertiesClick(Sender: TObject);
var
  DialogResult: TLayerPropertiesResult;
  Layer: TRasterLayer;
begin
  if FDocument.LayerCount = 0 then
    Exit;
  Layer := FDocument.ActiveLayer;
  DialogResult.Name := Layer.Name;
  DialogResult.Opacity := Layer.Opacity;
  DialogResult.BlendMode := Layer.BlendMode;
  if not RunLayerPropertiesDialog(Self, DialogResult) then
    Exit;
  FDocument.PushHistory('Layer Properties');
  Layer.Name := DialogResult.Name;
  Layer.Opacity := DialogResult.Opacity;
  Layer.BlendMode := DialogResult.BlendMode;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.PasteSelectionClick(Sender: TObject);
begin
  if not FDocument.HasStoredSelection then
    Exit;
  FDocument.PasteStoredSelection;
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.LayerBlendModeChanged(Sender: TObject);
var
  NewMode: TBlendMode;
begin
  if not Assigned(FLayerBlendCombo) then
    Exit;
  if FDocument.LayerCount = 0 then
    Exit;
  if (FLayerBlendCombo.ItemIndex < 0) or
     (FLayerBlendCombo.ItemIndex > Ord(High(TBlendMode))) then
    Exit;
  NewMode := TBlendMode(FLayerBlendCombo.ItemIndex);
  FDocument.ActiveLayer.BlendMode := NewMode;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
end;

{ ── Document Tab Management ─────────────────────────────────────────────── }

function TMainForm.TabDocumentDisplayName(AIndex: Integer): string;
var
  N: string;
begin
  if (AIndex < 0) or (AIndex >= Length(FTabFileNames)) then
    Exit('Untitled');
  if FTabFileNames[AIndex] = '' then
    N := 'Untitled'
  else
    N := ExtractFileName(FTabFileNames[AIndex]);
  if Length(N) > 14 then
    N := Copy(N, 1, 13) + Chr($E2) + Chr($80) + Chr($A6);  { UTF-8 ellipsis }
  Result := N;
end;

procedure TMainForm.AddDocumentTab(ADoc: TImageDocument; const AFileName: string;
  ADirty: Boolean = False);
var
  N: Integer;
begin
  { Flush current state to arrays }
  if Length(FTabDocuments) > 0 then
  begin
    FTabFileNames[FActiveTabIndex] := FCurrentFileName;
    FTabDirtyFlags[FActiveTabIndex] := FDirty;
  end;

  N := Length(FTabDocuments);
  SetLength(FTabDocuments, N + 1);
  SetLength(FTabFileNames, N + 1);
  SetLength(FTabDirtyFlags, N + 1);
  FTabDocuments[N] := ADoc;
  FTabFileNames[N] := AFileName;
  FTabDirtyFlags[N] := ADirty;

  FActiveTabIndex := N;
  FDocument := ADoc;
  FCurrentFileName := AFileName;
  FDirty := ADirty;

  InvalidatePreparedBitmap;
  RefreshTabStrip;
  UpdateCaption;
end;

procedure TMainForm.SwitchToTab(AIndex: Integer);
begin
  if AIndex = FActiveTabIndex then Exit;
  if (AIndex < 0) or (AIndex >= Length(FTabDocuments)) then Exit;

  { Save current state }
  FTabFileNames[FActiveTabIndex] := FCurrentFileName;
  FTabDirtyFlags[FActiveTabIndex] := FDirty;

  FActiveTabIndex := AIndex;
  FDocument := FTabDocuments[FActiveTabIndex];
  FCurrentFileName := FTabFileNames[FActiveTabIndex];
  FDirty := FTabDirtyFlags[FActiveTabIndex];

  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  FPointerDown := False;
  FitDocumentToViewport(False);
  RefreshTabStrip;
  RefreshLayers;
  RefreshCanvas;
  UpdateCaption;
end;

procedure TMainForm.NextTabClick(Sender: TObject);
begin
  if Length(FTabDocuments) <= 1 then Exit;
  SwitchToTab((FActiveTabIndex + 1) mod Length(FTabDocuments));
end;

procedure TMainForm.PrevTabClick(Sender: TObject);
begin
  if Length(FTabDocuments) <= 1 then Exit;
  if FActiveTabIndex = 0 then
    SwitchToTab(Length(FTabDocuments) - 1)
  else
    SwitchToTab(FActiveTabIndex - 1);
end;

procedure TMainForm.CloseDocumentTab(AIndex: Integer);
var
  I, N: Integer;
begin
  N := Length(FTabDocuments);
  if N <= 1 then
  begin
    { Cannot close the last tab — reset to blank instead }
    FDocument.NewBlank(800, 600);
    FCurrentFileName := '';
    FTabFileNames[0] := '';
    FTabDirtyFlags[0] := False;
    SetDirty(False);
    FPointerDown := False;
    SetLength(FLassoPoints, 0);
    FitDocumentToViewport(True);
    RefreshLayers;
    RefreshCanvas;
    RefreshTabStrip;
    Exit;
  end;

  FTabDocuments[AIndex].Free;

  { Shift arrays down }
  for I := AIndex to N - 2 do
  begin
    FTabDocuments[I] := FTabDocuments[I + 1];
    FTabFileNames[I] := FTabFileNames[I + 1];
    FTabDirtyFlags[I] := FTabDirtyFlags[I + 1];
  end;
  SetLength(FTabDocuments, N - 1);
  SetLength(FTabFileNames, N - 1);
  SetLength(FTabDirtyFlags, N - 1);

  if FActiveTabIndex >= Length(FTabDocuments) then
    FActiveTabIndex := Length(FTabDocuments) - 1;

  FDocument := FTabDocuments[FActiveTabIndex];
  FCurrentFileName := FTabFileNames[FActiveTabIndex];
  FDirty := FTabDirtyFlags[FActiveTabIndex];

  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  FPointerDown := False;
  FitDocumentToViewport(False);
  RefreshTabStrip;
  RefreshLayers;
  RefreshCanvas;
  UpdateCaption;
end;

procedure TMainForm.RefreshTabStrip;
var
  I: Integer;
  Btn: TButton;
  CloseBtn: TButton;
  BtnLeft: Integer;
  TabW: Integer;
  TabCaption: string;
begin
  if not Assigned(FTabStrip) then Exit;
  if FUpdatingTabs then Exit;
  FUpdatingTabs := True;
  try
    { Remove all existing tab buttons }
    while FTabStrip.ControlCount > 0 do
      FTabStrip.Controls[0].Free;

    BtnLeft := 4;
    TabW := 130;

    for I := 0 to Length(FTabDocuments) - 1 do
    begin
      TabCaption := TabDocumentDisplayName(I);
      if FTabDirtyFlags[I] then
        TabCaption := TabCaption + ' *';

      Btn := TButton.Create(FTabStrip);
      Btn.Parent := FTabStrip;
      Btn.Left := BtnLeft;
      Btn.Top := 3;
      Btn.Width := TabW - 24;
      Btn.Height := 22;
      Btn.Caption := TabCaption;
      Btn.Tag := I;
      Btn.OnClick := @TabButtonClick;
      Btn.PopupMenu := FTabPopupMenu;
      Btn.Hint := FTabFileNames[I];
      Btn.ShowHint := True;
      if I = FActiveTabIndex then
        Btn.Font.Style := [fsBold]
      else
        Btn.Font.Style := [];

      CloseBtn := TButton.Create(FTabStrip);
      CloseBtn.Parent := FTabStrip;
      CloseBtn.Left := BtnLeft + TabW - 22;
      CloseBtn.Top := 3;
      CloseBtn.Width := 20;
      CloseBtn.Height := 22;
      CloseBtn.Caption := 'x';
      CloseBtn.Tag := I;
      CloseBtn.OnClick := @TabCloseButtonClick;
      CloseBtn.Hint := 'Close document';
      CloseBtn.ShowHint := True;

      BtnLeft := BtnLeft + TabW + 2;
    end;

    { "+" button to create a new document }
    Btn := TButton.Create(FTabStrip);
    Btn.Parent := FTabStrip;
    Btn.Left := BtnLeft;
    Btn.Top := 3;
    Btn.Width := 26;
    Btn.Height := 22;
    Btn.Caption := '+';
    Btn.Hint := 'New document';
    Btn.ShowHint := True;
    Btn.OnClick := @NewDocumentClick;
  finally
    FUpdatingTabs := False;
  end;
end;

procedure TMainForm.TabButtonClick(Sender: TObject);
begin
  if not (Sender is TButton) then Exit;
  SwitchToTab(TButton(Sender).Tag);
end;

procedure TMainForm.TabCloseButtonClick(Sender: TObject);
var
  Idx: Integer;
begin
  if not (Sender is TButton) then Exit;
  Idx := TButton(Sender).Tag;
  if (Idx < 0) or (Idx >= Length(FTabDocuments)) then Exit;
  if FTabDirtyFlags[Idx] then
  begin
    if MessageDlg('Close Document',
      Format('Discard unsaved changes to "%s"?', [TabDocumentDisplayName(Idx)]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;
  CloseDocumentTab(Idx);
end;

procedure TMainForm.TabMenuNewClick(Sender: TObject);
begin
  NewDocumentClick(Sender);
end;

procedure TMainForm.TabMenuCloseClick(Sender: TObject);
var
  Popup: TPopupMenu;
  Idx: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  Popup := TMenuItem(Sender).GetParentMenu as TPopupMenu;
  if Assigned(Popup) and Assigned(Popup.PopupComponent) then
  begin
    Idx := Popup.PopupComponent.Tag;
    if (Idx < 0) or (Idx >= Length(FTabDocuments)) then Exit;
    if FTabDirtyFlags[Idx] then
    begin
      if MessageDlg('Close Document', Format('Discard unsaved changes to "%s"?', [TabDocumentDisplayName(Idx)]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    end;
    CloseDocumentTab(Idx);
  end;
end;

procedure TMainForm.TabMenuCloseOthersClick(Sender: TObject);
var
  Popup: TPopupMenu;
  Idx, I: Integer;
  TargetDoc: TImageDocument;
begin
  if not (Sender is TMenuItem) then Exit;
  Popup := TMenuItem(Sender).GetParentMenu as TPopupMenu;
  if Assigned(Popup) and Assigned(Popup.PopupComponent) then
  begin
    Idx := Popup.PopupComponent.Tag;
    if (Idx < 0) or (Idx >= Length(FTabDocuments)) then Exit;
    TargetDoc := FTabDocuments[Idx];
    for I := High(FTabDocuments) downto 0 do
    begin
      if FTabDocuments[I] = TargetDoc then Continue;
      if FTabDirtyFlags[I] then
      begin
        if MessageDlg('Close Document', Format('Discard unsaved changes to "%s"?', [TabDocumentDisplayName(I)]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Continue;
      end;
      CloseDocumentTab(I);
    end;
  end;
end;

procedure TMainForm.TabMenuCloseRightClick(Sender: TObject);
var
  Popup: TPopupMenu;
  Idx, I: Integer;
  TargetDoc: TImageDocument;
begin
  if not (Sender is TMenuItem) then Exit;
  Popup := TMenuItem(Sender).GetParentMenu as TPopupMenu;
  if Assigned(Popup) and Assigned(Popup.PopupComponent) then
  begin
    Idx := Popup.PopupComponent.Tag;
    if (Idx < 0) or (Idx >= Length(FTabDocuments)) then Exit;
    TargetDoc := FTabDocuments[Idx];
    for I := High(FTabDocuments) downto Idx + 1 do
    begin
      if FTabDirtyFlags[I] then
      begin
        if MessageDlg('Close Document', Format('Discard unsaved changes to "%s"?', [TabDocumentDisplayName(I)]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Continue;
      end;
      CloseDocumentTab(I);
    end;
  end;
end;

procedure TMainForm.OpenFileInNewTab(const AFileName: string);
var
  Surface: TRasterSurface;
  LoadedDocument: TImageDocument;
  ResolvedFileName: string;
begin
  ResolvedFileName := ExpandFileName(AFileName);
  try
    if SameText(ExtractFileExt(ResolvedFileName), '.fpd') then
    begin
      LoadedDocument := LoadNativeDocumentFromFile(ResolvedFileName);
      AddDocumentTab(LoadedDocument, ResolvedFileName, False);
    end
    else
    begin
      LoadedDocument := TImageDocument.Create(1, 1);
      Surface := LoadSurfaceFromFile(ResolvedFileName);
      try
        LoadedDocument.ReplaceWithSingleLayer(Surface, ExtractFileName(ResolvedFileName));
      finally
        Surface.Free;
      end;
      AddDocumentTab(LoadedDocument, ResolvedFileName, False);
    end;
    RegisterRecentFile(ResolvedFileName);
    FPointerDown := False;
    SetLength(FLassoPoints, 0);
    FPendingSelectionMode := scReplace;
    FitDocumentToViewport(True);
    InvalidatePreparedBitmap;
    FLastImagePoint := Point(-1, -1);
    RefreshLayers;
    RefreshCanvas;
  except
    on E: Exception do
      MessageDlg('Open', 'Open failed: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

{ ── Colors Panel RGBA Controls ───────────────────────────────────────────── }

procedure TMainForm.UpdateColorSpins;
var
  EditColor: TRGBA32;
begin
  if FUpdatingColorSpins then Exit;
  FUpdatingColorSpins := True;
  try
    if FColorEditTarget = 0 then
      EditColor := FPrimaryColor
    else
      EditColor := FSecondaryColor;
    if Assigned(FColorRSpin) then FColorRSpin.Value := EditColor.R;
    if Assigned(FColorGSpin) then FColorGSpin.Value := EditColor.G;
    if Assigned(FColorBSpin) then FColorBSpin.Value := EditColor.B;
    if Assigned(FColorASpin) then FColorASpin.Value := EditColor.A;
    if Assigned(FColorHexEdit) then
      FColorHexEdit.Text := Format('%2.2x%2.2x%2.2x%2.2x',
        [EditColor.R, EditColor.G, EditColor.B, EditColor.A]);
  finally
    FUpdatingColorSpins := False;
  end;
end;

procedure TMainForm.ColorSpinChanged(Sender: TObject);
var
  NewColor: TRGBA32;
begin
  if FUpdatingColorSpins then Exit;
  if not Assigned(FColorRSpin) then Exit;
  NewColor := RGBA(
    FColorRSpin.Value,
    FColorGSpin.Value,
    FColorBSpin.Value,
    FColorASpin.Value
  );
  if FColorEditTarget = 0 then
    FPrimaryColor := NewColor
  else
    FSecondaryColor := NewColor;
  FUpdatingColorSpins := True;
  try
    if Assigned(FColorHexEdit) then
      FColorHexEdit.Text := Format('%2.2x%2.2x%2.2x%2.2x',
        [NewColor.R, NewColor.G, NewColor.B, NewColor.A]);
  finally
    FUpdatingColorSpins := False;
  end;
  if Assigned(FColorsBox) then FColorsBox.Invalidate;
end;

procedure TMainForm.ColorHexChanged(Sender: TObject);
var
  HexStr: string;
  R, G, B, A: Integer;
  NewColor: TRGBA32;
begin
  if FUpdatingColorSpins then Exit;
  if not Assigned(FColorHexEdit) then Exit;
  HexStr := Trim(FColorHexEdit.Text);
  if Length(HexStr) > 0 then
    if HexStr[1] = '#' then
      HexStr := Copy(HexStr, 2, 8);
  if Length(HexStr) < 6 then Exit;
  if Length(HexStr) = 6 then HexStr := HexStr + 'ff';
  try
    R := StrToInt('$' + Copy(HexStr, 1, 2));
    G := StrToInt('$' + Copy(HexStr, 3, 2));
    B := StrToInt('$' + Copy(HexStr, 5, 2));
    A := StrToInt('$' + Copy(HexStr, 7, 2));
    NewColor := RGBA(
      EnsureRange(R, 0, 255),
      EnsureRange(G, 0, 255),
      EnsureRange(B, 0, 255),
      EnsureRange(A, 0, 255)
    );
    if FColorEditTarget = 0 then
      FPrimaryColor := NewColor
    else
      FSecondaryColor := NewColor;
    FUpdatingColorSpins := True;
    try
      if Assigned(FColorRSpin) then FColorRSpin.Value := NewColor.R;
      if Assigned(FColorGSpin) then FColorGSpin.Value := NewColor.G;
      if Assigned(FColorBSpin) then FColorBSpin.Value := NewColor.B;
      if Assigned(FColorASpin) then FColorASpin.Value := NewColor.A;
    finally
      FUpdatingColorSpins := False;
    end;
    if Assigned(FColorsBox) then FColorsBox.Invalidate;
  except
    { Invalid hex input — silently ignore }
  end;
end;

procedure TMainForm.ColorTargetComboChanged(Sender: TObject);
begin
  if Assigned(FColorTargetCombo) then
    FColorEditTarget := FColorTargetCombo.ItemIndex;
  RefreshColorsPanel;
end;

{ ── Tool Option Handlers ─────────────────────────────────────────────────── }

procedure TMainForm.OpacitySpinChanged(Sender: TObject);
begin
  if not Assigned(FOpacitySpin) then Exit;
  FBrushOpacity := EnsureRange(FOpacitySpin.Value, 1, 100);
end;

procedure TMainForm.HardnessSpinChanged(Sender: TObject);
begin
  if not Assigned(FHardnessSpin) then Exit;
  FBrushHardness := EnsureRange(FHardnessSpin.Value, 1, 100);
end;

procedure TMainForm.SelModeComboChanged(Sender: TObject);
begin
  if not Assigned(FSelModeCombo) then Exit;
  FPendingSelectionMode := TSelectionCombineMode(FSelModeCombo.ItemIndex);
end;

procedure TMainForm.ShapeStyleComboChanged(Sender: TObject);
begin
  if not Assigned(FShapeStyleCombo) then Exit;
  FShapeStyle := FShapeStyleCombo.ItemIndex;
end;

procedure TMainForm.BucketModeComboChanged(Sender: TObject);
begin
  if not Assigned(FBucketModeCombo) then Exit;
  FBucketFloodMode := FBucketModeCombo.ItemIndex;
end;

procedure TMainForm.WandSampleComboChanged(Sender: TObject);
begin
  if not Assigned(FWandSampleCombo) then Exit;
  FWandSampleSource := FWandSampleCombo.ItemIndex;
end;

procedure TMainForm.WandContiguousChanged(Sender: TObject);
begin
  if not Assigned(FWandContiguousCheck) then Exit;
  FWandContiguous := FWandContiguousCheck.Checked;
end;

procedure TMainForm.FillTolSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FFillTolSpin) then Exit;
  FFillTolerance := EnsureRange(FFillTolSpin.Value, 0, 255);
end;

procedure TMainForm.GradientTypeComboChanged(Sender: TObject);
begin
  if not Assigned(FGradientTypeCombo) then Exit;
  FGradientType := FGradientTypeCombo.ItemIndex;
end;

procedure TMainForm.GradientReverseChanged(Sender: TObject);
begin
  if not Assigned(FGradientReverseCheck) then Exit;
  FGradientReverse := FGradientReverseCheck.Checked;
end;

procedure TMainForm.PickerSampleComboChanged(Sender: TObject);
begin
  if not Assigned(FPickerSampleCombo) then Exit;
  FPickerSampleSource := FPickerSampleCombo.ItemIndex;
end;

procedure TMainForm.SelAntiAliasChanged(Sender: TObject);
begin
  if not Assigned(FSelAntiAliasCheck) then Exit;
  FSelAntiAlias := FSelAntiAliasCheck.Checked;
end;

{ ── Layer Rotate / Zoom ──────────────────────────────────────────────────── }

procedure TMainForm.LayerRotateZoomClick(Sender: TObject);
var
  Choice: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  Choice := MessageDlg(
    'Layer Rotate / Zoom',
    'Choose rotation:'#13#10#13#10 +
    '  Yes  = Rotate 90' + Chr($C2) + Chr($B0) + ' Clockwise'#13#10 +
    '  No   = Rotate 90' + Chr($C2) + Chr($B0) + ' Counter-Clockwise'#13#10 +
    '  OK   = Rotate 180' + Chr($C2) + Chr($B0),
    mtInformation,
    [mbYes, mbNo, mbOK, mbCancel],
    0
  );
  case Choice of
    mrYes:
      FDocument.ActiveLayer.Surface.Rotate90Clockwise;
    mrNo:
      FDocument.ActiveLayer.Surface.Rotate90CounterClockwise;
    mrOK:
      FDocument.ActiveLayer.Surface.Rotate180;
    mrCancel:
      Exit;
  end;
  FDocument.PushHistory('Rotate Layer');
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
end;

end.
