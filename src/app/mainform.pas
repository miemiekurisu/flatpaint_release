unit MainForm;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons,
  ComCtrls, Menus, Spin, Types, Clipbrd, FPColor, FPSurface, FPDocument, FPSelection,
  FPPaletteHelpers, FPRulerHelpers, FPTextDialog, FPColorWheelHelpers, FPIconHelpers;

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
    FJpegProgressive: Boolean;
    { PNG export compression 0-9; persisted per session }
    FPngCompressionLevel: Integer;
    FPrimaryColor: TRGBA32;
    FSecondaryColor: TRGBA32;
    FStrokeColor: TRGBA32;
    FPickSecondaryTarget: Boolean;
    FUpdatingToolOption: Boolean;
    FPointerDown: Boolean;
    FDragStart: TPoint;
    FLinePathOpen: Boolean;
    FLineCurvePending: Boolean;
    FLineCurveSecondStage: Boolean;
    FLineCurveEndPoint: TPoint;
    FLineCurveControlPoint: TPoint;
    FLineCurveControlPoint2: TPoint;
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
    FStatusProgressBar: TProgressBar;
    FStatusProgressLabel: TLabel;
    FStatusProgressActive: Boolean;
    FStatusZoomTrack: TTrackBar;
    FStatusZoomLabel: TLabel;
    FLayerList: TListBox;
    FHistoryList: TListBox;
    FColorPickButton: TColorButton;
    FActiveColorHexLabel: TLabel;
    FColorsValueLabel: TLabel;
    FHistoryValueLabel: TLabel;
    FBrushSpin: TSpinEdit;
    FToolCombo: TComboBox;
    FZoomCombo: TComboBox;
    FOptionLabel: TLabel;
    FColorsBox: TPaintBox;
    FColorSliderBox: TPaintBox;
    FSwatchBox: TPaintBox;
    FSwatchColors: array[0..95] of TRGBA32;
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
    FInlineTextEdit: TEdit;
    FInlineTextAnchor: TPoint;
    FInlineTextColor: TRGBA32;
    FInlineTextCommitting: Boolean;
    FLayerBlendCombo: TComboBox;
    FLayerPropsButton: TSpeedButton;
    FLayerVisibleCheck: TCheckBox;
    FLayerOpacitySpin: TSpinEdit;
    FLayerOpacityLabel: TLabel;
    FUpdatingLayerControls: Boolean;
    FCloneStampSnapshot: TRasterSurface;
    { Pre-stroke snapshot for efficient region-based undo (brush/pencil/eraser/recolor/clone).
      FPreStrokeSnapshot holds a clone of the active layer taken at stroke start.
      On mouse-up we crop it to FStrokeDirtyRect and push a region history entry. }
    FPreStrokeSnapshot: TRasterSurface;
    FStrokeDirtyRect: TRect;
    FStrokeLayerIndex: Integer;
    { Document tab management }
    FTabDocuments: array of TImageDocument;
    FTabFileNames: array of string;
    FTabDirtyFlags: array of Boolean;
    FActiveTabIndex: Integer;
    FTabStripHost: TScrollBox;
    FTabStrip: TPanel;
    FTabPopupMenu: TPopupMenu;
    FPopupTabIndex: Integer;
    FUpdatingTabs: Boolean;
    FTabPressedIndex: Integer;
    FTabDragOrigin: TPoint;
    FTabDragging: Boolean;
    { Colors panel RGBA }
    FColorRSpin: TSpinEdit;
    FColorGSpin: TSpinEdit;
    FColorBSpin: TSpinEdit;
    FColorASpin: TSpinEdit;
    FColorHSpin: TSpinEdit;
    FColorSSpin: TSpinEdit;
    FColorVSpin: TSpinEdit;
    FColorHexEdit: TEdit;
    FUpdatingColorSpins: Boolean;
    FColorEditTarget: Integer; { 0=Primary, 1=Secondary }
    FActiveColorSlider: Integer;
    FColorTargetCombo: TComboBox;
    { Tool options — opacity and selection mode }
    FOpacitySpin: TSpinEdit;
    FOpacityLabel: TLabel;
    FBrushOpacity: Integer;
    FHardnessSpin: TSpinEdit;
    FHardnessLabel: TLabel;
    FBrushHardness: Integer;
    FEraserSquareShape: Boolean;
    FEraserShapeLabel: TLabel;
    FEraserShapeCombo: TComboBox;
    FSelModeCombo: TComboBox;
    FSelModeLabel: TLabel;
    FShapeStyleCombo: TComboBox;
    FShapeStyleLabel: TLabel;
    FBucketModeCombo: TComboBox;
    FBucketModeLabel: TLabel;
    FFillSampleCombo: TComboBox;
    FFillSampleLabel: TLabel;
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
    FCloneAligned: Boolean;
    FCloneAlignedCheck: TCheckBox;
    FRecolorPreserveValue: Boolean;
    FRecolorPreserveValueCheck: TCheckBox;
    FCloneAlignedOffset: TPoint;
    FCloneAlignedOffsetValid: Boolean;
    { Fill sample source: 0=Current Layer, 1=All Layers }
    FFillSampleSource: Integer;
    { Color picker sample source: 0=Current Layer, 1=All Layers }
    FPickerSampleSource: Integer;
    FPickerSampleCombo: TComboBox;
    FPickerSampleLabel: TLabel;
    { Selection anti-alias }
    FSelAntiAlias: Boolean;
    FSelAntiAliasCheck: TCheckBox;
    FSelFeather: Integer;
    FSelFeatherLabel: TLabel;
    FSelFeatherSpin: TSpinEdit;
    FLayerDragIndex: Integer;
    FLayerDragTargetIndex: Integer;
    FMagnifyInstalled: Boolean;
    function ActivePaintColor: TRGBA32;
    function ColorForActiveTarget(AAlternate: Boolean = False): TRGBA32;
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
    procedure ColorsBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ColorPickButtonChanged(Sender: TObject);
    procedure ColorSliderBoxPaint(Sender: TObject);
    procedure ColorSliderBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorSliderBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ColorSliderBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SwatchBoxPaint(Sender: TObject);
    procedure SwatchBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    function ParseMeasurementText(const AText: string; AFallbackPixels: Integer): Integer;
    function PromptForSize(const ATitle: string; out AWidth, AHeight: Integer): Boolean;
    function SelectionModeFromShift(const Shift: TShiftState): TSelectionCombineMode;
    procedure AppendLassoPoint(const APoint: TPoint);
    procedure ResetLineCurveSegmentState;
    procedure ResetLineCurveState;
    procedure CommitPendingLineSegment(AContinuePath: Boolean);
    procedure ApplySelectionFeather;
    procedure InitializeTextToolDefaults;
    procedure UpdateInlineTextEditStyle;
    procedure UpdateInlineTextEditBounds;
    procedure BeginInlineTextEdit(const APoint: TPoint);
    procedure CommitInlineTextEdit(ACommit: Boolean = True);
    procedure InvalidatePreparedBitmap;
    procedure RefreshAuxiliaryImageViews(ARefreshLayers: Boolean = False);
    procedure SyncImageMutationUI(ARefreshLayers: Boolean = False; AMarkDirty: Boolean = True);
    procedure BeginStatusProgress(const ACaption: string);
    procedure UpdateStatusProgress(APercent: Integer; const ACaption: string = '');
    procedure EndStatusProgress;
    procedure UpdateToolOptionControl;
    procedure RefreshUnitsMenu;
    procedure BuildMenus;
    procedure BuildTabPopupMenu;
    procedure BuildToolbar;
    procedure BuildSidePanel;
    function CreateButton(const ACaption: string; ALeft, ATop, AWidth: Integer; AHandler: TNotifyEvent; AParent: TWinControl; ATag: Integer = 0; AIconContext: TButtonIconContext = bicAuto): TSpeedButton;
    procedure CreateMenuItem(AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent; AShortcut: TShortCut = 0);
    procedure PaintCanvasTo(ACanvas: TCanvas; const ARect: TRect);
    procedure DrawBrushHoverOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
    procedure DrawSquareHoverOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
    procedure DrawPointHoverOverlay(ACanvas: TCanvas; const APoint: TPoint);
    procedure DrawCloneLinkOverlay(ACanvas: TCanvas; const ASourcePoint, ADestPoint: TPoint);
    procedure DrawCloneSourceOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
    procedure DrawQuadraticCurvePreview(ACanvas: TCanvas; const AStartPoint, AControlPoint, AEndPoint: TPoint; AStrokeColor: TColor; AStrokeWidth: Integer);
    procedure DrawCubicCurvePreview(ACanvas: TCanvas; const AStartPoint, AControlPoint1, AControlPoint2, AEndPoint: TPoint; AStrokeColor: TColor; AStrokeWidth: Integer);
    procedure DrawHoverToolOverlay(ACanvas: TCanvas);
    function ActiveToolOverlayRadius: Integer;
    function TryGetCloneOverlaySourcePoint(out APoint: TPoint): Boolean;
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
    procedure SyncStrokeColorToActiveTarget;

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
    procedure ApplyColorSliderAt(X, Y: Integer);
    procedure LayoutColorsPanel;
    procedure LayoutLayersPanel;
    procedure ColorsPanelResize(Sender: TObject);
    procedure LayersPanelResize(Sender: TObject);
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
    procedure LayerVisibleCheckChanged(Sender: TObject);
    procedure LayerOpacitySpinChanged(Sender: TObject);
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
    procedure GaussianBlurClick(Sender: TObject);
    procedure UnfocusClick(Sender: TObject);
    procedure SurfaceBlurClick(Sender: TObject);
    procedure RadialBlurClick(Sender: TObject);
    procedure TwistClick(Sender: TObject);
    procedure FragmentClick(Sender: TObject);
    procedure BulgeClick(Sender: TObject);
    procedure DentsClick(Sender: TObject);
    procedure ReliefClick(Sender: TObject);
    procedure RedEyeClick(Sender: TObject);
    procedure TileReflectionClick(Sender: TObject);
    procedure CrystallizeClick(Sender: TObject);
    procedure InkSketchClick(Sender: TObject);
    procedure MandelbrotClick(Sender: TObject);
    procedure JuliaClick(Sender: TObject);
    procedure RepeatLastEffectClick(Sender: TObject);
    procedure LayerPropertiesClick(Sender: TObject);
    procedure PasteSelectionClick(Sender: TObject);
    procedure LayerBlendModeChanged(Sender: TObject);
    procedure InlineTextEditChange(Sender: TObject);
    procedure InlineTextEditMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure InlineTextEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InlineTextEditExit(Sender: TObject);
    procedure PlaceTextAtPoint(const AResult: TTextDialogResult; APoint: TPoint; AColor: TRGBA32);
    { Document tab management }
    procedure TabButtonClick(Sender: TObject);
    procedure TabCardMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TabCardMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TabCardMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
    procedure MoveDocumentTab(AFromIndex, AToIndex: Integer);
    function PointToTabStrip(AControl: TControl; X, Y: Integer): TPoint;
    procedure BuildTabThumbnail(AIndex: Integer; AImage: TImage);
    procedure RefreshTabCardVisuals(AIndex: Integer);
    { Colors panel RGBA controls }
    procedure UpdateColorSpins;
    procedure ColorSpinChanged(Sender: TObject);
    procedure ColorHSVSpinChanged(Sender: TObject);
    procedure ColorHexChanged(Sender: TObject);
    procedure ColorTargetComboChanged(Sender: TObject);
    { Tool option handlers }
    procedure OpacitySpinChanged(Sender: TObject);
    procedure HardnessSpinChanged(Sender: TObject);
    procedure EraserShapeComboChanged(Sender: TObject);
    procedure SelModeComboChanged(Sender: TObject);
    procedure ShapeStyleComboChanged(Sender: TObject);
    procedure BucketModeComboChanged(Sender: TObject);
    procedure FillSampleComboChanged(Sender: TObject);
    procedure WandSampleComboChanged(Sender: TObject);
    procedure WandContiguousChanged(Sender: TObject);
    procedure FillTolSpinChanged(Sender: TObject);
    procedure GradientTypeComboChanged(Sender: TObject);
    procedure GradientReverseChanged(Sender: TObject);
    procedure CloneAlignedChanged(Sender: TObject);
    procedure RecolorPreserveValueChanged(Sender: TObject);
    procedure PickerSampleComboChanged(Sender: TObject);
    procedure SelAntiAliasChanged(Sender: TObject);
    procedure SelFeatherSpinChanged(Sender: TObject);
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
    procedure LayerListMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LayerListMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure LayerListMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LayerListDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
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
    procedure PaintBoxMouseLeave(Sender: TObject);
    { Stroke history helpers }
    procedure BeginStrokeHistory;
    procedure ExpandStrokeDirty(const APoint: TPoint);
    procedure CommitStrokeHistory(const ALabel: string);
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
    procedure SimulateMouseMove(Shift: TShiftState; X, Y: Integer);
    procedure SimulateMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    property CurrentToolForTest: TToolKind read FCurrentTool write FCurrentTool;
    property TestDocument: TImageDocument read FDocument;
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
  FPBlurDialog, FPNoiseDialog, FPFileMenuHelpers, FPTabHelpers,
  FPTextRenderer, FPLayerPropertiesDialog, FPMagnifyBridge, FPAlphaBridge;

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
  ColIndex: Integer;
  I: Integer;
  PaletteIndex: Integer;
  RowIndex: Integer;
  Hue: Double;
  Sat: Double;
  Val: Double;
  SwatchR: Byte;
  SwatchG: Byte;
  SwatchB: Byte;
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
    FCurrentTool := DefaultStartupTool;
    FBrushSize := 8;
    FWandTolerance := 32;
    FBrushOpacity := 100;
    FBrushHardness := 100;
    FEraserSquareShape := False;
    FShapeStyle := 0;
    FBucketFloodMode := 0;
    FLinePathOpen := False;
    FLineCurvePending := False;
    FLineCurveSecondStage := False;
    FLineCurveEndPoint := Point(0, 0);
    FLineCurveControlPoint := Point(0, 0);
    FLineCurveControlPoint2 := Point(0, 0);
    FFillSampleSource := 0;
    FWandSampleSource := 0;
    FWandContiguous := True;
    FJpegQuality := 90;
    FJpegProgressive := False;
    FPngCompressionLevel := 6;
    FFillTolerance := 8;
    FGradientType := 0;
    FGradientReverse := False;
    FCloneAligned := True;
    FRecolorPreserveValue := True;
    FCloneAlignedOffset := Point(0, 0);
    FCloneAlignedOffsetValid := False;
    FPickerSampleSource := 0;
    FSelAntiAlias := True;
    FSelFeather := 0;
    FTextLastResult.Text := '';
    FTextLastResult.FontName := '';
    FTextLastResult.FontSize := 24;
    FTextLastResult.Bold := False;
    FTextLastResult.Italic := False;
    FInlineTextEdit := nil;
    FInlineTextAnchor := Point(0, 0);
    FInlineTextColor := FPrimaryColor;
    FInlineTextCommitting := False;
    FClipboardOffset := Point(0, 0);
    FPreparedBitmap := TBitmap.Create;
    FRenderRevision := 1;
    FPreparedRevision := 0;
    FStatusProgressActive := False;

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
    FActiveColorSlider := -1;
    FTabPressedIndex := -1;
    FTabDragOrigin := Point(0, 0);
    FTabDragging := False;
    FLayerDragIndex := -1;
    FLayerDragTargetIndex := -1;
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
  FCurrentTool := DefaultStartupTool;
  FBrushSize := 8;
  FWandTolerance := 32;
  FBrushOpacity := 100;
  FBrushHardness := 100;
  FEraserSquareShape := False;
  FShapeStyle := 0;
  FBucketFloodMode := 0;
  FLinePathOpen := False;
  FLineCurvePending := False;
  FLineCurveSecondStage := False;
  FLineCurveEndPoint := Point(0, 0);
  FLineCurveControlPoint := Point(0, 0);
  FLineCurveControlPoint2 := Point(0, 0);
  FFillSampleSource := 0;
  FWandSampleSource := 0;
  FWandContiguous := True;
  FJpegQuality := 90;
  FJpegProgressive := False;
  FPngCompressionLevel := 6;
  FFillTolerance := 8;
  FGradientType := 0;
  FGradientReverse := False;
  FCloneAligned := True;
  FRecolorPreserveValue := True;
  FCloneAlignedOffset := Point(0, 0);
  FCloneAlignedOffsetValid := False;
  FPickerSampleSource := 0;
  FSelAntiAlias := True;
  FSelFeather := 0;
  FTextLastResult.Text := '';
  FTextLastResult.FontName := '';
  FTextLastResult.FontSize := 24;
  FTextLastResult.Bold := False;
  FTextLastResult.Italic := False;
  FInlineTextEdit := nil;
  FInlineTextAnchor := Point(0, 0);
  FInlineTextColor := FPrimaryColor;
  FInlineTextCommitting := False;
  FClipboardOffset := Point(0, 0);
  FPreparedBitmap := TBitmap.Create;
  FRenderRevision := 1;
  FPreparedRevision := 0;
  FStatusProgressActive := False;

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
  FActiveColorSlider := -1;
  FTabPressedIndex := -1;
  FTabDragOrigin := Point(0, 0);
  FTabDragging := False;
  FLayerDragIndex := -1;
  FLayerDragTargetIndex := -1;

  { Default 96-colour swatch palette:
    1 grayscale band + 7 hue bands covering dark, mid, bright and pastel ramps. }
  for ColIndex := 0 to 11 do
  begin
    Val := ColIndex / 11.0;
    SwatchR := EnsureRange(Round(Val * 255.0), 0, 255);
    FSwatchColors[ColIndex] := RGBA(SwatchR, SwatchR, SwatchR, 255);
  end;
  PaletteIndex := 12;
  for RowIndex := 0 to 6 do
    for ColIndex := 0 to 11 do
    begin
      Hue := ColIndex / 12.0;
      case RowIndex of
        0:
          begin
            Sat := 0.35;
            Val := 0.35;
          end;
        1:
          begin
            Sat := 0.65;
            Val := 0.48;
          end;
        2:
          begin
            Sat := 0.82;
            Val := 0.64;
          end;
        3:
          begin
            Sat := 0.95;
            Val := 0.82;
          end;
        4:
          begin
            Sat := 1.0;
            Val := 1.0;
          end;
        5:
          begin
            Sat := 0.60;
            Val := 0.92;
          end;
      else
        begin
          Sat := 0.34;
          Val := 0.98;
        end;
      end;
      HSVToRGB(Hue, Sat, Val, SwatchR, SwatchG, SwatchB);
      FSwatchColors[PaletteIndex] := RGBA(SwatchR, SwatchG, SwatchB, 255);
      Inc(PaletteIndex);
    end;

  BuildTabPopupMenu;
  BuildMenus;
  BuildToolbar;

  { Tab strip — inserted between toolbar and workspace }
  FTabStripHost := TScrollBox.Create(Self);
  FTabStripHost.Parent := Self;
  FTabStripHost.Align := alTop;
  FTabStripHost.Height := TabStripHeight;
  FTabStripHost.BorderStyle := bsNone;
  FTabStripHost.Color := TabStripBackgroundColor;
  FTabStripHost.ParentColor := False;
  FTabStripHost.HorzScrollBar.Tracking := True;
  FTabStripHost.VertScrollBar.Visible := False;

  FTabStrip := TPanel.Create(FTabStripHost);
  FTabStrip.Parent := FTabStripHost;
  FTabStrip.Left := 0;
  FTabStrip.Top := 0;
  FTabStrip.Width := FTabStripHost.ClientWidth;
  FTabStrip.Height := TabStripHeight;
  FTabStrip.BevelOuter := bvNone;
  FTabStrip.Caption := '';
  FTabStrip.Color := TabStripBackgroundColor;
  FTabStrip.ParentColor := False;
  FTabStrip.OnMouseMove := @TabCardMouseMove;
  FTabStrip.OnMouseUp := @TabCardMouseUp;

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
  FPaintBox.OnMouseLeave := @PaintBoxMouseLeave;

  FInlineTextEdit := TEdit.Create(FCanvasHost);
  FInlineTextEdit.Parent := FCanvasHost;
  FInlineTextEdit.Visible := False;
  FInlineTextEdit.AutoSize := False;
  FInlineTextEdit.Left := FPaintBox.Left;
  FInlineTextEdit.Top := FPaintBox.Top;
  FInlineTextEdit.Width := 128;
  FInlineTextEdit.Height := 30;
  FInlineTextEdit.OnChange := @InlineTextEditChange;
  FInlineTextEdit.OnMouseDown := @InlineTextEditMouseDown;
  FInlineTextEdit.OnKeyDown := @InlineTextEditKeyDown;
  FInlineTextEdit.OnExit := @InlineTextEditExit;

  BuildSidePanel;
  RefreshPaletteMenuChecks;

  FStatusBar := TPanel.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.Align := alBottom;
  FStatusBar.Height := 24;
  FStatusBar.Color := StatusBarBackgroundColor;
  FStatusBar.ParentColor := False;
  FStatusBar.BevelOuter := bvNone;
  FStatusBar.OnResize := @LayoutStatusBarControls;

  for I := 0 to 6 do
  begin
    FStatusLabels[I] := TLabel.Create(FStatusBar);
    FStatusLabels[I].Parent := FStatusBar;
    FStatusLabels[I].Layout := tlCenter;
    FStatusLabels[I].Font.Size := 9;
    FStatusLabels[I].Font.Color := ChromeTextColor;
    FStatusLabels[I].Transparent := True;
    FStatusLabels[I].AutoSize := False;
  end;

  FStatusProgressLabel := TLabel.Create(FStatusBar);
  FStatusProgressLabel.Parent := FStatusBar;
  FStatusProgressLabel.Layout := tlCenter;
  FStatusProgressLabel.Font.Size := 9;
  FStatusProgressLabel.Font.Color := ChromeTextColor;
  FStatusProgressLabel.Transparent := True;
  FStatusProgressLabel.AutoSize := False;
  FStatusProgressLabel.Visible := False;

  FStatusProgressBar := TProgressBar.Create(FStatusBar);
  FStatusProgressBar.Parent := FStatusBar;
  FStatusProgressBar.Min := 0;
  FStatusProgressBar.Max := 100;
  FStatusProgressBar.Position := 0;
  FStatusProgressBar.Visible := False;

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
  FPreStrokeSnapshot.Free;  { defensive cleanup in case a stroke was interrupted }
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

function TMainForm.ColorForActiveTarget(AAlternate: Boolean): TRGBA32;
var
  UseSecondary: Boolean;
begin
  UseSecondary := FColorEditTarget = 1;
  if AAlternate then
    UseSecondary := not UseSecondary;
  if UseSecondary then
    Result := FSecondaryColor
  else
    Result := FPrimaryColor;
end;

procedure TMainForm.SyncStrokeColorToActiveTarget;
begin
  if FPointerDown then
    Exit;
  FStrokeColor := ColorForActiveTarget(False);
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

procedure TMainForm.ResetLineCurveSegmentState;
begin
  FLineCurvePending := False;
  FLineCurveSecondStage := False;
  FLineCurveEndPoint := Point(0, 0);
  FLineCurveControlPoint := Point(0, 0);
  FLineCurveControlPoint2 := Point(0, 0);
end;

procedure TMainForm.ResetLineCurveState;
begin
  FLinePathOpen := False;
  ResetLineCurveSegmentState;
end;

procedure TMainForm.CommitPendingLineSegment(AContinuePath: Boolean);
begin
  if not FLineCurvePending then
    Exit;
  FDocument.PushHistory(PaintToolName(FCurrentTool));
  CommitShapeTool(FDragStart, FLineCurveEndPoint);
  SetDirty(True);
  FDragStart := FLineCurveEndPoint;
  FLastImagePoint := FDragStart;
  ResetLineCurveSegmentState;
  FLinePathOpen := AContinuePath;
end;

procedure TMainForm.ApplySelectionFeather;
begin
  if (not FSelAntiAlias) or (FSelFeather <= 0) or (not Assigned(FDocument)) or (not FDocument.HasSelection) then
    Exit;
  FDocument.Selection.Feather(FSelFeather);
end;

procedure TMainForm.InitializeTextToolDefaults;
begin
  if FTextLastResult.FontName = '' then
    FTextLastResult.FontName := Font.Name;
  if FTextLastResult.FontSize <= 0 then
    FTextLastResult.FontSize := 24;
end;

procedure TMainForm.UpdateInlineTextEditStyle;
var
  DisplayFontSize: Integer;
  FontStyles: TFontStyles;
begin
  if not Assigned(FInlineTextEdit) then
    Exit;
  InitializeTextToolDefaults;
  DisplayFontSize := Max(6, Round(FTextLastResult.FontSize * FZoomScale));
  FInlineTextEdit.Font.Name := FTextLastResult.FontName;
  FInlineTextEdit.Font.Size := DisplayFontSize;
  FontStyles := [];
  if FTextLastResult.Bold then
    Include(FontStyles, fsBold);
  if FTextLastResult.Italic then
    Include(FontStyles, fsItalic);
  FInlineTextEdit.Font.Style := FontStyles;
  FInlineTextEdit.Font.Color := RGBToColor(
    FInlineTextColor.R,
    FInlineTextColor.G,
    FInlineTextColor.B
  );
end;

procedure TMainForm.UpdateInlineTextEditBounds;
var
  DisplayFontSize: Integer;
  VisibleText: string;
begin
  if not Assigned(FInlineTextEdit) or not FInlineTextEdit.Visible then
    Exit;
  DisplayFontSize := Max(6, Round(FTextLastResult.FontSize * FZoomScale));
  VisibleText := FInlineTextEdit.Text;
  if VisibleText = '' then
    VisibleText := 'W';
  FInlineTextEdit.Left := FPaintBox.Left + Round(FInlineTextAnchor.X * FZoomScale);
  FInlineTextEdit.Top := FPaintBox.Top + Round(FInlineTextAnchor.Y * FZoomScale);
  FInlineTextEdit.Width := Max(
    120,
    Round((Length(VisibleText) + 3) * DisplayFontSize * 0.7)
  );
  FInlineTextEdit.Height := Max(28, Round(DisplayFontSize * 1.9));
end;

procedure TMainForm.BeginInlineTextEdit(const APoint: TPoint);
begin
  if not Assigned(FInlineTextEdit) then
    Exit;
  CommitInlineTextEdit(True);
  InitializeTextToolDefaults;
  FInlineTextAnchor := Point(
    EnsureRange(APoint.X, 0, Max(0, FDocument.Width - 1)),
    EnsureRange(APoint.Y, 0, Max(0, FDocument.Height - 1))
  );
  FInlineTextColor := ActivePaintColor;
  FInlineTextEdit.Text := '';
  FInlineTextEdit.Visible := True;
  UpdateInlineTextEditStyle;
  UpdateInlineTextEditBounds;
  FInlineTextEdit.SelectAll;
  FInlineTextEdit.SetFocus;
  if Assigned(FPaintBox) then
    FPaintBox.Invalidate;
end;

procedure TMainForm.CommitInlineTextEdit(ACommit: Boolean);
var
  TextResult: TTextDialogResult;
  DidCommit: Boolean;
begin
  if not Assigned(FInlineTextEdit) or not FInlineTextEdit.Visible or FInlineTextCommitting then
    Exit;
  FInlineTextCommitting := True;
  DidCommit := False;
  try
    if ACommit and (Trim(FInlineTextEdit.Text) <> '') then
    begin
      InitializeTextToolDefaults;
      TextResult := FTextLastResult;
      TextResult.Text := FInlineTextEdit.Text;
      FTextLastResult.Text := FInlineTextEdit.Text;
      FDocument.PushHistory('Text');
      PlaceTextAtPoint(TextResult, FInlineTextAnchor, FInlineTextColor);
      SyncImageMutationUI(False, True);
      DidCommit := True;
    end;
    FInlineTextEdit.Visible := False;
    FInlineTextEdit.Text := '';
    if not DidCommit then
      RefreshCanvas;
  finally
    FInlineTextCommitting := False;
  end;
end;

procedure TMainForm.InvalidatePreparedBitmap;
begin
  Inc(FRenderRevision);
end;

procedure TMainForm.RefreshAuxiliaryImageViews(ARefreshLayers: Boolean);
begin
  if ARefreshLayers then
    RefreshLayers
  else if Assigned(FLayerList) then
    FLayerList.Invalidate;
end;

procedure TMainForm.SyncImageMutationUI(ARefreshLayers: Boolean; AMarkDirty: Boolean);
begin
  if FStatusProgressActive then
    UpdateStatusProgress(82);
  InvalidatePreparedBitmap;
  if AMarkDirty then
    SetDirty(True)
  else
    RefreshTabCardVisuals(FActiveTabIndex);
  RefreshAuxiliaryImageViews(ARefreshLayers);
  RefreshCanvas;
  if FStatusProgressActive then
    UpdateStatusProgress(94);
end;

procedure TMainForm.BeginStatusProgress(const ACaption: string);
begin
  if not Assigned(FStatusBar) then
    Exit;
  FStatusProgressActive := True;
  if Assigned(FStatusProgressLabel) then
  begin
    FStatusProgressLabel.Caption := ACaption;
    FStatusProgressLabel.Visible := True;
  end;
  if Assigned(FStatusProgressBar) then
  begin
    FStatusProgressBar.Position := 8;
    FStatusProgressBar.Visible := True;
  end;
  if Assigned(FStatusLabels[4]) then
    FStatusLabels[4].Visible := False;
  if Assigned(FStatusLabels[5]) then
    FStatusLabels[5].Visible := False;
  LayoutStatusBarControls(nil);
  FStatusBar.Invalidate;
  FStatusBar.Update;
  Application.ProcessMessages;
end;

procedure TMainForm.UpdateStatusProgress(APercent: Integer; const ACaption: string);
begin
  if not FStatusProgressActive or not Assigned(FStatusBar) then
    Exit;
  if (ACaption <> '') and Assigned(FStatusProgressLabel) then
    FStatusProgressLabel.Caption := ACaption;
  if Assigned(FStatusProgressBar) then
    FStatusProgressBar.Position := EnsureRange(APercent, 0, 100);
  FStatusBar.Invalidate;
  FStatusBar.Update;
  Application.ProcessMessages;
end;

procedure TMainForm.EndStatusProgress;
begin
  if not FStatusProgressActive then
    Exit;
  if Assigned(FStatusProgressBar) then
    FStatusProgressBar.Position := 100;
  if Assigned(FStatusBar) then
  begin
    FStatusBar.Invalidate;
    FStatusBar.Update;
    Application.ProcessMessages;
  end;
  FStatusProgressActive := False;
  if Assigned(FStatusProgressLabel) then
  begin
    FStatusProgressLabel.Caption := '';
    FStatusProgressLabel.Visible := False;
  end;
  if Assigned(FStatusProgressBar) then
  begin
    FStatusProgressBar.Position := 0;
    FStatusProgressBar.Visible := False;
  end;
  if Assigned(FStatusLabels[4]) then
    FStatusLabels[4].Visible := True;
  if Assigned(FStatusLabels[5]) then
    FStatusLabels[5].Visible := True;
  LayoutStatusBarControls(nil);
  if Assigned(FStatusBar) then
    FStatusBar.Invalidate;
end;

procedure TMainForm.UpdateToolOptionControl;
var
  IsSelTool: Boolean;
  IsOpacityTool: Boolean;
  IsHardnessTool: Boolean;
  IsEraserShapeTool: Boolean;
  IsShapeTool: Boolean;
  IsBucketTool: Boolean;
  IsToleranceTool: Boolean;
  IsFeatherTool: Boolean;
begin
  if not Assigned(FBrushSpin) or not Assigned(FOptionLabel) then
    Exit;

  FUpdatingToolOption := True;
  try
    IsSelTool := FCurrentTool in [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand];
    IsOpacityTool := FCurrentTool in [tkPencil, tkBrush, tkEraser, tkCloneStamp, tkRecolor];
    IsHardnessTool := FCurrentTool in [tkBrush, tkEraser];
    IsEraserShapeTool := FCurrentTool = tkEraser;
    IsShapeTool := FCurrentTool in [tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape];
    IsBucketTool := FCurrentTool = tkFill;
    IsToleranceTool := FCurrentTool in [tkFill, tkRecolor];
    IsFeatherTool := IsSelTool;

    if Assigned(FSelModeLabel) then FSelModeLabel.Visible := IsSelTool;
    if Assigned(FSelModeCombo) then FSelModeCombo.Visible := IsSelTool;
    if Assigned(FOpacityLabel) then FOpacityLabel.Visible := IsOpacityTool;
    if Assigned(FOpacitySpin) then FOpacitySpin.Visible := IsOpacityTool;
    if Assigned(FOpacitySpin) then FOpacitySpin.Value := FBrushOpacity;
    if Assigned(FHardnessLabel) then FHardnessLabel.Visible := IsHardnessTool;
    if Assigned(FHardnessSpin) then FHardnessSpin.Visible := IsHardnessTool;
    if Assigned(FHardnessSpin) then FHardnessSpin.Value := FBrushHardness;
    if Assigned(FEraserShapeLabel) then FEraserShapeLabel.Visible := IsEraserShapeTool;
    if Assigned(FEraserShapeCombo) then FEraserShapeCombo.Visible := IsEraserShapeTool;
    if Assigned(FEraserShapeCombo) then FEraserShapeCombo.ItemIndex := Ord(FEraserSquareShape);
    if Assigned(FShapeStyleLabel) then FShapeStyleLabel.Visible := IsShapeTool;
    if Assigned(FShapeStyleCombo) then FShapeStyleCombo.Visible := IsShapeTool;
    if Assigned(FShapeStyleCombo) then FShapeStyleCombo.ItemIndex := FShapeStyle;
    if Assigned(FBucketModeLabel) then FBucketModeLabel.Visible := IsBucketTool;
    if Assigned(FBucketModeCombo) then FBucketModeCombo.Visible := IsBucketTool;
    if Assigned(FBucketModeCombo) then FBucketModeCombo.ItemIndex := FBucketFloodMode;
    if Assigned(FFillSampleLabel) then FFillSampleLabel.Visible := IsBucketTool;
    if Assigned(FFillSampleCombo) then FFillSampleCombo.Visible := IsBucketTool;
    if Assigned(FFillSampleCombo) then FFillSampleCombo.ItemIndex := FFillSampleSource;
    if Assigned(FWandSampleLabel) then FWandSampleLabel.Visible := FCurrentTool = tkMagicWand;
    if Assigned(FWandSampleCombo) then FWandSampleCombo.Visible := FCurrentTool = tkMagicWand;
    if Assigned(FWandSampleCombo) then FWandSampleCombo.ItemIndex := FWandSampleSource;
    if Assigned(FWandContiguousCheck) then FWandContiguousCheck.Visible := FCurrentTool = tkMagicWand;
    if Assigned(FWandContiguousCheck) then FWandContiguousCheck.Checked := FWandContiguous;
    if Assigned(FFillTolLabel) then FFillTolLabel.Visible := IsToleranceTool;
    if Assigned(FFillTolSpin) then FFillTolSpin.Visible := IsToleranceTool;
    if Assigned(FFillTolSpin) then
    begin
      if FCurrentTool = tkRecolor then
      begin
        FFillTolLabel.Left := 480;
        FFillTolSpin.Left := 552;
        FFillTolSpin.Value := FWandTolerance
      end
      else
      begin
        FFillTolLabel.Left := 348;
        FFillTolSpin.Left := 420;
        FFillTolSpin.Value := FFillTolerance;
      end;
      if FCurrentTool = tkRecolor then
        FFillTolSpin.Hint := 'Recolor tolerance (0=exact, 255=replace broad color range)'
      else
        FFillTolSpin.Hint := 'Fill tolerance (0=exact, 255=fill all)';
    end;
    if Assigned(FGradientTypeLabel) then FGradientTypeLabel.Visible := FCurrentTool = tkGradient;
    if Assigned(FGradientTypeCombo) then FGradientTypeCombo.Visible := FCurrentTool = tkGradient;
    if Assigned(FGradientTypeCombo) then FGradientTypeCombo.ItemIndex := FGradientType;
    if Assigned(FGradientReverseCheck) then FGradientReverseCheck.Visible := FCurrentTool = tkGradient;
    if Assigned(FGradientReverseCheck) then FGradientReverseCheck.Checked := FGradientReverse;
    if Assigned(FCloneAlignedCheck) then FCloneAlignedCheck.Visible := FCurrentTool = tkCloneStamp;
    if Assigned(FCloneAlignedCheck) then FCloneAlignedCheck.Checked := FCloneAligned;
    if Assigned(FRecolorPreserveValueCheck) then FRecolorPreserveValueCheck.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorPreserveValueCheck) then FRecolorPreserveValueCheck.Checked := FRecolorPreserveValue;
    if Assigned(FPickerSampleLabel) then FPickerSampleLabel.Visible := FCurrentTool = tkColorPicker;
    if Assigned(FPickerSampleCombo) then FPickerSampleCombo.Visible := FCurrentTool = tkColorPicker;
    if Assigned(FPickerSampleCombo) then FPickerSampleCombo.ItemIndex := FPickerSampleSource;
    if Assigned(FSelAntiAliasCheck) then
    begin
      FSelAntiAliasCheck.Visible := IsSelTool;
      FSelAntiAliasCheck.Checked := FSelAntiAlias;
    end;
    if Assigned(FSelFeatherLabel) then
      FSelFeatherLabel.Visible := IsFeatherTool;
    if Assigned(FSelFeatherSpin) then
    begin
      FSelFeatherSpin.Visible := IsFeatherTool;
      FSelFeatherSpin.Enabled := FSelAntiAlias;
      FSelFeatherSpin.Value := EnsureRange(FSelFeather, FSelFeatherSpin.MinValue, FSelFeatherSpin.MaxValue);
    end;

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
  SubMenu: TMenuItem;
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
  { ---------- Blurs sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := '&Blurs';
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, '&Box Blur...', @BlurClick);
  CreateMenuItem(SubMenu, '&Gaussian Blur...', @GaussianBlurClick);
  CreateMenuItem(SubMenu, '&Motion Blur...', @MotionBlurClick);
  CreateMenuItem(SubMenu, '&Radial Blur...', @RadialBlurClick);
  CreateMenuItem(SubMenu, '&Surface Blur...', @SurfaceBlurClick);
  CreateMenuItem(SubMenu, '&Unfocus...', @UnfocusClick);
  CreateMenuItem(SubMenu, '&Zoom Blur...', @ZoomBlurClick);
  { ---------- Distort sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := '&Distort';
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, '&Fragment...', @FragmentClick);
  CreateMenuItem(SubMenu, '&Pixelate...', @PixelateClick);
  CreateMenuItem(SubMenu, '&Twist...', @TwistClick);
  CreateMenuItem(SubMenu, '&Bulge...', @BulgeClick);
  CreateMenuItem(SubMenu, '&Dents...', @DentsClick);
  CreateMenuItem(SubMenu, 'Tile &Reflection...', @TileReflectionClick);
  { ---------- Noise sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := '&Noise';
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, 'Add &Noise...', @AddNoiseClick);
  CreateMenuItem(SubMenu, '&Median / Denoise...', @MedianFilterClick);
  { ---------- Photo sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := '&Photo';
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, '&Glow...', @GlowClick);
  CreateMenuItem(SubMenu, '&Oil Paint...', @OilPaintClick);
  CreateMenuItem(SubMenu, '&Red Eye...', @RedEyeClick);
  CreateMenuItem(SubMenu, '&Sharpen', @SharpenClick);
  CreateMenuItem(SubMenu, 'S&often', @SoftenClick);
  CreateMenuItem(SubMenu, '&Vignette...', @VignetteClick);
  { ---------- Render sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := '&Render';
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, '&Clouds', @RenderCloudsClick);
  CreateMenuItem(SubMenu, '&Frosted Glass...', @FrostedGlassClick);
  CreateMenuItem(SubMenu, '&Mandelbrot Fractal...', @MandelbrotClick);
  CreateMenuItem(SubMenu, '&Julia Fractal...', @JuliaClick);
  { ---------- Stylize sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := '&Stylize';
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, '&Crystallize...', @CrystallizeClick);
  CreateMenuItem(SubMenu, 'Detect &Edges', @OutlineClick);
  CreateMenuItem(SubMenu, '&Emboss', @EmbossClick);
  CreateMenuItem(SubMenu, '&Ink Sketch...', @InkSketchClick);
  CreateMenuItem(SubMenu, '&Relief...', @ReliefClick);
  CreateMenuItem(SubMenu, 'Outline Effe&ct...', @OutlineEffectClick);

  Menu := FMainMenu;
end;

procedure TMainForm.BuildToolbar;
var
  LabelCtrl: TLabel;
  ToolIndex: Integer;
  ToolKind: TToolKind;
  UtilityPanel: TPanel;
  UtilityButton: TSpeedButton;
  UtilityIndex: Integer;
  UtilityCommand: TUtilityCommandKind;
  ZoomIndex: Integer;
  Btn: TSpeedButton;
begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 66;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';
  FTopPanel.Color := ToolbarBackgroundColor;
  FTopPanel.ParentColor := False;

  { Toolbar row 1: quick actions + zoom; the tool-options row stays separate below it. }
  Btn := CreateButton('New',   10,  8, 26, @NewDocumentClick,  FTopPanel, 0, bicCommand); Btn.Hint := 'New document (Cmd+N)';
  Btn := CreateButton('Open',  40,  8, 26, @OpenDocumentClick,  FTopPanel, 0, bicCommand); Btn.Hint := 'Open document (Cmd+O)';
  Btn := CreateButton('Save',  70,  8, 26, @SaveDocumentClick,  FTopPanel, 0, bicCommand); Btn.Hint := 'Save document (Cmd+S)';
  Btn := CreateButton('Cut',  110,  8, 26, @CutClick,           FTopPanel, 0, bicCommand); Btn.Hint := 'Cut selection (Cmd+X)';
  Btn := CreateButton('Copy', 140,  8, 26, @CopyClick,          FTopPanel, 0, bicCommand); Btn.Hint := 'Copy selection (Cmd+C)';
  Btn := CreateButton('Paste',170,  8, 26, @PasteClick,         FTopPanel, 0, bicCommand); Btn.Hint := 'Paste (Cmd+V)';
  Btn := CreateButton('Undo', 214,  8, 26, @UndoClick,          FTopPanel, 0, bicCommand); Btn.Hint := 'Undo last action (Cmd+Z)';
  Btn := CreateButton('Redo', 244,  8, 26, @RedoClick,          FTopPanel, 0, bicCommand); Btn.Hint := 'Redo (Cmd+Shift+Z)';
  Btn := CreateButton('-',    288,  8, 26, @ZoomOutClick,       FTopPanel, 0, bicCommand); Btn.Hint := 'Zoom out';

  FZoomCombo := TComboBox.Create(FTopPanel);
  FZoomCombo.Parent := FTopPanel;
  FZoomCombo.Left := 318;
  FZoomCombo.Top := 8;
  FZoomCombo.Width := 82;
  FZoomCombo.Style := csDropDownList;
  for ZoomIndex := 0 to ZoomPresetCount - 1 do
    FZoomCombo.Items.Add(ZoomPresetCaption(ZoomIndex));
  FZoomCombo.OnChange := @ZoomComboChange;

  Btn := CreateButton('+', 404, 8, 26, @ZoomInClick, FTopPanel, 0, bicCommand); Btn.Hint := 'Zoom in';

  UtilityPanel := TPanel.Create(FTopPanel);
  UtilityPanel.Parent := FTopPanel;
  UtilityPanel.Left := 1180;
  UtilityPanel.Top := 8;
  UtilityPanel.Width := 172;
  UtilityPanel.Height := 26;
  UtilityPanel.BevelOuter := bvNone;
  UtilityPanel.Caption := '';
  UtilityPanel.Color := ToolbarBackgroundColor;
  UtilityPanel.Anchors := [akTop, akRight];
  for UtilityIndex := 0 to UtilityCommandDisplayCount - 1 do
  begin
    UtilityCommand := UtilityCommandAtDisplayIndex(UtilityIndex);
    UtilityButton := CreateButton(
      UtilityCommandGlyph(UtilityCommand),
      UtilityIndex * 28,
      0,
      26,
      @UtilityButtonClick,
      UtilityPanel,
      Ord(UtilityCommand),
      bicUtility
    );
    UtilityButton.Hint := UtilityCommandHint(UtilityCommand);
  end;

  LabelCtrl := TLabel.Create(FTopPanel);
  LabelCtrl.Parent := FTopPanel;
  LabelCtrl.Caption := 'Tool:';
  LabelCtrl.Font.Color := ChromeTextColor;
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
  FOptionLabel.Font.Color := ChromeTextColor;
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
  FOpacityLabel.Font.Color := ChromeTextColor;
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
  FHardnessLabel.Font.Color := ChromeTextColor;
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

  FEraserShapeLabel := TLabel.Create(FTopPanel);
  FEraserShapeLabel.Parent := FTopPanel;
  FEraserShapeLabel.Caption := 'Shape:';
  FEraserShapeLabel.Font.Color := ChromeTextColor;
  FEraserShapeLabel.Left := 628;
  FEraserShapeLabel.Top := 41;
  FEraserShapeLabel.Visible := False;

  FEraserShapeCombo := TComboBox.Create(FTopPanel);
  FEraserShapeCombo.Parent := FTopPanel;
  FEraserShapeCombo.Left := 676;
  FEraserShapeCombo.Top := 36;
  FEraserShapeCombo.Width := 92;
  FEraserShapeCombo.Style := csDropDownList;
  FEraserShapeCombo.Items.Add('Round');
  FEraserShapeCombo.Items.Add('Square');
  FEraserShapeCombo.ItemIndex := 0;
  FEraserShapeCombo.Visible := False;
  FEraserShapeCombo.OnChange := @EraserShapeComboChanged;
  FEraserShapeCombo.Hint := 'Eraser tip shape';
  FEraserShapeCombo.ShowHint := True;

  FSelModeLabel := TLabel.Create(FTopPanel);
  FSelModeLabel.Parent := FTopPanel;
  FSelModeLabel.Caption := 'Mode:';
  FSelModeLabel.Font.Color := ChromeTextColor;
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
  FShapeStyleLabel.Font.Color := ChromeTextColor;
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
  FBucketModeLabel.Font.Color := ChromeTextColor;
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

  { Fill sample source combo: Current Layer / All Layers }
  FFillSampleLabel := TLabel.Create(FTopPanel);
  FFillSampleLabel.Parent := FTopPanel;
  FFillSampleLabel.Caption := 'Sample:';
  FFillSampleLabel.Font.Color := ChromeTextColor;
  FFillSampleLabel.Left := 500;
  FFillSampleLabel.Top := 41;
  FFillSampleLabel.Visible := False;

  FFillSampleCombo := TComboBox.Create(FTopPanel);
  FFillSampleCombo.Parent := FTopPanel;
  FFillSampleCombo.Left := 552;
  FFillSampleCombo.Top := 36;
  FFillSampleCombo.Width := 120;
  FFillSampleCombo.Style := csDropDownList;
  FFillSampleCombo.Items.Add('Current Layer');
  FFillSampleCombo.Items.Add('All Layers');
  FFillSampleCombo.ItemIndex := 0;
  FFillSampleCombo.Visible := False;
  FFillSampleCombo.OnChange := @FillSampleComboChanged;
  FFillSampleCombo.Hint := 'Fill sample source';
  FFillSampleCombo.ShowHint := True;

  { Magic wand sample source combo: Current Layer / All Layers }
  FWandSampleLabel := TLabel.Create(FTopPanel);
  FWandSampleLabel.Parent := FTopPanel;
  FWandSampleLabel.Caption := 'Sample:';
  FWandSampleLabel.Font.Color := ChromeTextColor;
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
  FFillTolLabel.Font.Color := ChromeTextColor;
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
  FGradientTypeLabel.Font.Color := ChromeTextColor;
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

  { Clone aligned checkbox }
  FCloneAlignedCheck := TCheckBox.Create(FTopPanel);
  FCloneAlignedCheck.Parent := FTopPanel;
  FCloneAlignedCheck.Left := 480;
  FCloneAlignedCheck.Top := 38;
  FCloneAlignedCheck.Width := 80;
  FCloneAlignedCheck.Caption := 'Aligned';
  FCloneAlignedCheck.Checked := FCloneAligned;
  FCloneAlignedCheck.Visible := False;
  FCloneAlignedCheck.OnChange := @CloneAlignedChanged;
  FCloneAlignedCheck.Hint := 'Keep the clone source aligned across multiple strokes';
  FCloneAlignedCheck.ShowHint := True;

  { Recolor preserve-value checkbox }
  FRecolorPreserveValueCheck := TCheckBox.Create(FTopPanel);
  FRecolorPreserveValueCheck.Parent := FTopPanel;
  FRecolorPreserveValueCheck.Left := 628;
  FRecolorPreserveValueCheck.Top := 38;
  FRecolorPreserveValueCheck.Width := 120;
  FRecolorPreserveValueCheck.Caption := 'Preserve Value';
  FRecolorPreserveValueCheck.Checked := FRecolorPreserveValue;
  FRecolorPreserveValueCheck.Visible := False;
  FRecolorPreserveValueCheck.OnChange := @RecolorPreserveValueChanged;
  FRecolorPreserveValueCheck.Hint := 'Keep original brightness while shifting the color';
  FRecolorPreserveValueCheck.ShowHint := True;

  { Color picker sample source combo }
  FPickerSampleLabel := TLabel.Create(FTopPanel);
  FPickerSampleLabel.Parent := FTopPanel;
  FPickerSampleLabel.Caption := 'Sample:';
  FPickerSampleLabel.Font.Color := ChromeTextColor;
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

  FSelFeatherLabel := TLabel.Create(FTopPanel);
  FSelFeatherLabel.Parent := FTopPanel;
  FSelFeatherLabel.Caption := 'Feather:';
  FSelFeatherLabel.Left := 596;
  FSelFeatherLabel.Top := 40;
  FSelFeatherLabel.Font.Color := ChromeTextColor;
  FSelFeatherLabel.Visible := False;

  FSelFeatherSpin := TSpinEdit.Create(FTopPanel);
  FSelFeatherSpin.Parent := FTopPanel;
  FSelFeatherSpin.Left := 656;
  FSelFeatherSpin.Top := 34;
  FSelFeatherSpin.Width := 52;
  FSelFeatherSpin.MinValue := 0;
  FSelFeatherSpin.MaxValue := 128;
  FSelFeatherSpin.Value := FSelFeather;
  FSelFeatherSpin.Visible := False;
  FSelFeatherSpin.OnChange := @SelFeatherSpinChanged;

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
  ToolButton: TSpeedButton;
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
      Ord(ToolKind),
      bicTool
    );
    ToolButton.Hint := PaintToolName(ToolKind) + ' — ' + PaintToolHint(ToolKind);
  end;

  FColorsPanel := TPanel.Create(Self);
  CreatePalette(FColorsPanel, pkColors);

  { Keep a hidden combo for keyboard shortcuts and tests that already depend on
    the primary/secondary target state. The visible interaction is the stacked
    swatch pair inside the colors palette. }
  FColorEditTarget := 0;
  FColorTargetCombo := TComboBox.Create(FColorsPanel);
  FColorTargetCombo.Parent := FColorsPanel;
  FColorTargetCombo.Style := csDropDownList;
  FColorTargetCombo.Left := 0;
  FColorTargetCombo.Top := 0;
  FColorTargetCombo.Width := 0;
  FColorTargetCombo.Items.Add('Primary');
  FColorTargetCombo.Items.Add('Secondary');
  FColorTargetCombo.ItemIndex := 0;
  FColorTargetCombo.Visible := False;
  FColorTargetCombo.OnChange := @ColorTargetComboChanged;
  FColorPickButton := TColorButton.Create(FColorsPanel);
  FColorPickButton.Parent := FColorsPanel;
  FColorPickButton.Left := 12;
  FColorPickButton.Top := ContentTop;
  FColorPickButton.Width := 56;
  FColorPickButton.Height := 26;
  FColorPickButton.Caption := '';
  FColorPickButton.Flat := True;
  FColorPickButton.BorderWidth := 1;
  FColorPickButton.Hint := 'Open the system color palette for the active swatch';
  FColorPickButton.ShowHint := True;
  FColorPickButton.OnColorChanged := @ColorPickButtonChanged;
  FColorPickButton.ButtonColor := RGBToColor(FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B);

  CreateButton('Swap', 74, ContentTop, 40, @SwapColorsClick, FColorsPanel);
  CreateButton('Mono', 120, ContentTop, 40, @ResetColorsClick, FColorsPanel);

  FColorsBox := TPaintBox.Create(FColorsPanel);
  FColorsBox.Parent := FColorsPanel;
  FColorsBox.Left := 12;
  FColorsBox.Top := ContentTop + 34;
  FColorsBox.Width := FColorsPanel.Width - 24;
  FColorsBox.Height := 84;
  FColorsBox.Anchors := [akLeft, akRight, akTop];
  FColorsBox.OnPaint := @ColorsBoxPaint;
  FColorsBox.OnMouseDown := @ColorsBoxMouseDown;
  FColorsBox.OnMouseMove := @ColorsBoxMouseMove;

  FActiveColorHexLabel := TLabel.Create(FColorsPanel);
  FActiveColorHexLabel.Parent := FColorsPanel;
  FActiveColorHexLabel.Left := 12;
  FActiveColorHexLabel.Top := FColorsBox.Top + FColorsBox.Height + 4;
  FActiveColorHexLabel.Width := FColorsPanel.Width - 24;
  FActiveColorHexLabel.Height := 16;
  FActiveColorHexLabel.Font.Color := ChromeTextColor;
  FActiveColorHexLabel.Font.Size := 9;

  FColorsValueLabel := TLabel.Create(FColorsPanel);
  FColorsValueLabel.Parent := FColorsPanel;
  FColorsValueLabel.Left := 12;
  FColorsValueLabel.Top := FActiveColorHexLabel.Top + 18;
  FColorsValueLabel.Width := FColorsPanel.Width - 24;
  FColorsValueLabel.Height := 14;
  FColorsValueLabel.Font.Color := ChromeMutedTextColor;
  FColorsValueLabel.Font.Size := 8;

  FColorSliderBox := TPaintBox.Create(FColorsPanel);
  FColorSliderBox.Parent := FColorsPanel;
  FColorSliderBox.Left := 12;
  FColorSliderBox.Top := FColorsValueLabel.Top + 18;
  FColorSliderBox.Width := FColorsPanel.Width - 24;
  FColorSliderBox.Height := 68;
  FColorSliderBox.Anchors := [akLeft, akRight, akTop];
  FColorSliderBox.OnPaint := @ColorSliderBoxPaint;
  FColorSliderBox.OnMouseDown := @ColorSliderBoxMouseDown;
  FColorSliderBox.OnMouseMove := @ColorSliderBoxMouseMove;
  FColorSliderBox.OnMouseUp := @ColorSliderBoxMouseUp;
  FColorSliderBox.Hint := 'Drag H, S, V and A strips to tune the active swatch';
  FColorSliderBox.ShowHint := True;
  FColorsPanel.OnResize := @ColorsPanelResize;
  LayoutColorsPanel;
  RefreshColorsPanel;

  FHistoryPanel := TPanel.Create(Self);
  CreatePalette(FHistoryPanel, pkHistory);
  CreateButton('Undo', 12, ContentTop, 26, @UndoClick, FHistoryPanel, 0, bicCommand);
  CreateButton('Redo', 42, ContentTop, 26, @RedoClick, FHistoryPanel, 0, bicCommand);
  FHistoryValueLabel := TLabel.Create(FHistoryPanel);
  FHistoryValueLabel.Parent := FHistoryPanel;
  FHistoryValueLabel.Left := 12;
  FHistoryValueLabel.Top := ContentTop + 30;
  FHistoryValueLabel.Width := 212;
  FHistoryValueLabel.Height := 14;
  FHistoryValueLabel.Font.Color := ChromeMutedTextColor;
  FHistoryValueLabel.Font.Size := 8;
  FHistoryList := TListBox.Create(FHistoryPanel);
  FHistoryList.Parent := FHistoryPanel;
  FHistoryList.Left := 12;
  FHistoryList.Top := ContentTop + 48;
  FHistoryList.Width := 212;
  FHistoryList.Height := FHistoryPanel.Height - (ContentTop + 60);
  FHistoryList.Anchors := [akTop, akLeft, akRight, akBottom];
  FHistoryList.Color := PaletteListBackgroundColor;
  FHistoryList.Font.Color := ChromeTextColor;
  FHistoryList.Font.Size := 9;
  FHistoryList.Style := lbOwnerDrawFixed;
  FHistoryList.ItemHeight := 20;
  FHistoryList.OnClick := @HistoryListClick;
  FHistoryList.OnDrawItem := @HistoryListDrawItem;
  RefreshHistoryPanel;

  FRightPanel := TPanel.Create(Self);
  CreatePalette(FRightPanel, pkLayers);

  { Row 1: Add / Duplicate / Delete / Merge }
  CreateButton('+', 12, ContentTop, 26, @AddLayerClick, FRightPanel, 0, bicCommand);
  CreateButton('Dup', 42, ContentTop, 26, @DuplicateLayerClick, FRightPanel, 0, bicCommand);
  CreateButton('Del', 72, ContentTop, 26, @DeleteLayerClick, FRightPanel, 0, bicCommand);
  CreateButton('Mrg', 102, ContentTop, 26, @MergeDownClick, FRightPanel, 0, bicCommand);
  { Row 1 right: Vis / Up / Down }
  CreateButton('Vis', 132, ContentTop, 26, @ToggleLayerVisibilityClick, FRightPanel, 0, bicCommand);
  CreateButton('Up', 162, ContentTop, 26, @MoveLayerUpClick, FRightPanel, 0, bicCommand);
  CreateButton('Dn', 192, ContentTop, 26, @MoveLayerDownClick, FRightPanel, 0, bicCommand);

  { Row 2: Opacity / Flatten / Rename / Properties }
  CreateButton('Fade', 12, ContentTop + 28, 26, @LayerOpacityClick, FRightPanel, 0, bicCommand);
  CreateButton('Flat', 42, ContentTop + 28, 26, @FlattenClick, FRightPanel, 0, bicCommand);
  CreateButton('Name', 72, ContentTop + 28, 26, @RenameLayerClick, FRightPanel, 0, bicCommand);
  FLayerPropsButton := CreateButton('Props', 102, ContentTop + 28, 26, @LayerPropertiesClick, FRightPanel, 0, bicCommand);

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

  FLayerVisibleCheck := TCheckBox.Create(FRightPanel);
  FLayerVisibleCheck.Parent := FRightPanel;
  FLayerVisibleCheck.Left := 12;
  FLayerVisibleCheck.Top := ContentTop + 88;
  FLayerVisibleCheck.Width := 84;
  FLayerVisibleCheck.Caption := 'Visible';
  FLayerVisibleCheck.OnChange := @LayerVisibleCheckChanged;

  FLayerOpacityLabel := TLabel.Create(FRightPanel);
  FLayerOpacityLabel.Parent := FRightPanel;
  FLayerOpacityLabel.Caption := 'Opacity:';
  FLayerOpacityLabel.Font.Color := ChromeTextColor;
  FLayerOpacityLabel.Left := 106;
  FLayerOpacityLabel.Top := ContentTop + 93;

  FLayerOpacitySpin := TSpinEdit.Create(FRightPanel);
  FLayerOpacitySpin.Parent := FRightPanel;
  FLayerOpacitySpin.Left := 160;
  FLayerOpacitySpin.Top := ContentTop + 88;
  FLayerOpacitySpin.Width := 72;
  FLayerOpacitySpin.MinValue := 0;
  FLayerOpacitySpin.MaxValue := 100;
  FLayerOpacitySpin.OnChange := @LayerOpacitySpinChanged;

  FLayerList := TListBox.Create(FRightPanel);
  FLayerList.Parent := FRightPanel;
  FLayerList.Left := 12;
  FLayerList.Top := ContentTop + 118;
  FLayerList.Width := 220;
  FLayerList.Height := FRightPanel.Height - (ContentTop + 130);
  FLayerList.Anchors := [akTop, akLeft, akRight, akBottom];
  FLayerList.Color := PaletteListBackgroundColor;
  FLayerList.Font.Color := ChromeTextColor;
  FLayerList.Font.Size := 9;
  FLayerList.Style := lbOwnerDrawFixed;
  FLayerList.ItemHeight := 36;
  FLayerList.OnDrawItem := @LayerListDrawItem;
  FLayerList.OnClick := @LayerListClick;
  FLayerList.OnDblClick := @LayerListDblClick;
  FLayerList.OnMouseDown := @LayerListMouseDown;
  FLayerList.OnMouseMove := @LayerListMouseMove;
  FLayerList.OnMouseUp := @LayerListMouseUp;
  FRightPanel.OnResize := @LayersPanelResize;
  LayoutLayersPanel;
end;

function CompactButtonCaption(const ACaption: string): string;
begin
  Result := ACaption;
  if ACaption = 'New' then
    Result := '✚'
  else if ACaption = 'Open' then
    Result := '↥'
  else if ACaption = 'Save' then
    Result := '↧'
  else if ACaption = 'Cut' then
    Result := '✂'
  else if ACaption = 'Copy' then
    Result := '⧉'
  else if ACaption = 'Paste' then
    Result := '▣'
  else if ACaption = 'Undo' then
    Result := '↶'
  else if ACaption = 'Redo' then
    Result := '↷'
  else if ACaption = 'Pick...' then
    Result := '⌾'
  else if ACaption = 'Swap' then
    Result := '⇄'
  else if ACaption = 'Mono' then
    Result := '◐'
  else if ACaption = 'Dup' then
    Result := '⧉'
  else if ACaption = 'Del' then
    Result := '−'
  else if ACaption = 'Mrg' then
    Result := '⇣'
  else if ACaption = 'Vis' then
    Result := '◉'
  else if ACaption = 'Up' then
    Result := '↑'
  else if ACaption = 'Dn' then
    Result := '↓'
  else if ACaption = 'Fade' then
    Result := '◔'
  else if ACaption = 'Flat' then
    Result := '▤'
  else if ACaption = 'Name' then
    Result := '✎'
  else if ACaption = 'Props' then
    Result := '⚙';
end;

function TMainForm.CreateButton(const ACaption: string; ALeft, ATop, AWidth: Integer; AHandler: TNotifyEvent; AParent: TWinControl; ATag: Integer; AIconContext: TButtonIconContext): TSpeedButton;
begin
  Result := TSpeedButton.Create(AParent);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := 26;
  Result.Flat := True;
  Result.Tag := ATag;
  Result.OnClick := AHandler;
  Result.ParentFont := False;
  if TryBuildButtonGlyph(ACaption, AIconContext, Result.Glyph) then
  begin
    Result.Caption := '';
    Result.NumGlyphs := 1;
    Result.Margin := 4;
    Result.Spacing := 0;
    Result.Font.Size := 9;
  end
  else
  begin
    Result.Caption := CompactButtonCaption(ACaption);
    if Length(Result.Caption) <= 4 then
      Result.Font.Size := 10
    else
      Result.Font.Size := 9;
  end;
  Result.Font.Color := ChromeTextColor;
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

function TMainForm.ActiveToolOverlayRadius: Integer;
begin
  case FCurrentTool of
    tkPencil:
      Result := Max(0, (FBrushSize - 1) div 2);
    tkBrush, tkEraser, tkCloneStamp, tkRecolor:
      Result := Max(1, FBrushSize div 2);
  else
    Result := 0;
  end;
end;

function TMainForm.TryGetCloneOverlaySourcePoint(out APoint: TPoint): Boolean;
begin
  Result := False;
  if not FCloneStampSampled then
    Exit;

  if FCloneAligned and FCloneAlignedOffsetValid and
     (FLastImagePoint.X >= 0) and (FLastImagePoint.Y >= 0) then
    APoint := Point(
      FLastImagePoint.X + FCloneAlignedOffset.X,
      FLastImagePoint.Y + FCloneAlignedOffset.Y
    )
  else
    APoint := FCloneStampSource;

  Result := (APoint.X >= 0) and (APoint.Y >= 0) and
    (APoint.X < FDocument.Width) and (APoint.Y < FDocument.Height);
end;

procedure TMainForm.DrawPointHoverOverlay(ACanvas: TCanvas; const APoint: TPoint);
var
  LeftX: Integer;
  TopY: Integer;
  RightX: Integer;
  BottomY: Integer;
  CenterX: Integer;
  CenterY: Integer;
  CrossHalf: Integer;
begin
  if (APoint.X < 0) or (APoint.Y < 0) then
    Exit;

  LeftX := Round(APoint.X * FZoomScale);
  TopY := Round(APoint.Y * FZoomScale);
  RightX := Round((APoint.X + 1) * FZoomScale);
  BottomY := Round((APoint.Y + 1) * FZoomScale);
  if RightX <= LeftX then
    RightX := LeftX + 1;
  if BottomY <= TopY then
    BottomY := TopY + 1;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);

  CenterX := (LeftX + RightX) div 2;
  CenterY := (TopY + BottomY) div 2;
  CrossHalf := Max(2, Round(FZoomScale));
  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(CenterX - CrossHalf, CenterY);
  ACanvas.LineTo(CenterX + CrossHalf + 1, CenterY);
  ACanvas.MoveTo(CenterX, CenterY - CrossHalf);
  ACanvas.LineTo(CenterX, CenterY + CrossHalf + 1);
end;

procedure TMainForm.DrawBrushHoverOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
var
  LeftX: Integer;
  TopY: Integer;
  RightX: Integer;
  BottomY: Integer;
  CenterX: Integer;
  CenterY: Integer;
  CrossHalf: Integer;
begin
  if ARadius <= 0 then
  begin
    DrawPointHoverOverlay(ACanvas, APoint);
    Exit;
  end;

  LeftX := Round((APoint.X - ARadius) * FZoomScale);
  TopY := Round((APoint.Y - ARadius) * FZoomScale);
  RightX := Round((APoint.X + ARadius + 1) * FZoomScale);
  BottomY := Round((APoint.Y + ARadius + 1) * FZoomScale);
  if RightX <= LeftX then
    RightX := LeftX + 1;
  if BottomY <= TopY then
    BottomY := TopY + 1;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);

  CenterX := Round((APoint.X + 0.5) * FZoomScale);
  CenterY := Round((APoint.Y + 0.5) * FZoomScale);
  CrossHalf := Max(2, Round(FZoomScale));
  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(CenterX - CrossHalf, CenterY);
  ACanvas.LineTo(CenterX + CrossHalf + 1, CenterY);
  ACanvas.MoveTo(CenterX, CenterY - CrossHalf);
  ACanvas.LineTo(CenterX, CenterY + CrossHalf + 1);
end;

procedure TMainForm.DrawSquareHoverOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
var
  LeftX: Integer;
  TopY: Integer;
  RightX: Integer;
  BottomY: Integer;
  CenterX: Integer;
  CenterY: Integer;
  CrossHalf: Integer;
begin
  if ARadius <= 0 then
  begin
    DrawPointHoverOverlay(ACanvas, APoint);
    Exit;
  end;

  LeftX := Round((APoint.X - ARadius) * FZoomScale);
  TopY := Round((APoint.Y - ARadius) * FZoomScale);
  RightX := Round((APoint.X + ARadius + 1) * FZoomScale);
  BottomY := Round((APoint.Y + ARadius + 1) * FZoomScale);
  if RightX <= LeftX then
    RightX := LeftX + 1;
  if BottomY <= TopY then
    BottomY := TopY + 1;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);

  CenterX := Round((APoint.X + 0.5) * FZoomScale);
  CenterY := Round((APoint.Y + 0.5) * FZoomScale);
  CrossHalf := Max(2, Round(FZoomScale));
  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(CenterX - CrossHalf, CenterY);
  ACanvas.LineTo(CenterX + CrossHalf + 1, CenterY);
  ACanvas.MoveTo(CenterX, CenterY - CrossHalf);
  ACanvas.LineTo(CenterX, CenterY + CrossHalf + 1);
end;

procedure TMainForm.DrawCloneLinkOverlay(ACanvas: TCanvas; const ASourcePoint, ADestPoint: TPoint);
var
  SourceX: Integer;
  SourceY: Integer;
  DestX: Integer;
  DestY: Integer;
begin
  SourceX := Round((ASourcePoint.X + 0.5) * FZoomScale);
  SourceY := Round((ASourcePoint.Y + 0.5) * FZoomScale);
  DestX := Round((ADestPoint.X + 0.5) * FZoomScale);
  DestY := Round((ADestPoint.Y + 0.5) * FZoomScale);

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psDash;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clRed;
  ACanvas.MoveTo(SourceX, SourceY);
  ACanvas.LineTo(DestX, DestY);
  ACanvas.Pen.Style := psSolid;
end;

procedure TMainForm.DrawCloneSourceOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
var
  LeftX: Integer;
  TopY: Integer;
  RightX: Integer;
  BottomY: Integer;
  CenterX: Integer;
  CenterY: Integer;
  CrossHalf: Integer;
begin
  if ARadius <= 0 then
  begin
    LeftX := Round(APoint.X * FZoomScale);
    TopY := Round(APoint.Y * FZoomScale);
    RightX := Round((APoint.X + 1) * FZoomScale);
    BottomY := Round((APoint.Y + 1) * FZoomScale);
  end
  else
  begin
    LeftX := Round((APoint.X - ARadius) * FZoomScale);
    TopY := Round((APoint.Y - ARadius) * FZoomScale);
    RightX := Round((APoint.X + ARadius + 1) * FZoomScale);
    BottomY := Round((APoint.Y + ARadius + 1) * FZoomScale);
  end;

  if RightX <= LeftX then
    RightX := LeftX + 1;
  if BottomY <= TopY then
    BottomY := TopY + 1;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clRed;
  if ARadius <= 0 then
    ACanvas.Rectangle(LeftX, TopY, RightX, BottomY)
  else
    ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);

  CenterX := Round((APoint.X + 0.5) * FZoomScale);
  CenterY := Round((APoint.Y + 0.5) * FZoomScale);
  CrossHalf := Max(3, Round(FZoomScale * 1.5));
  ACanvas.MoveTo(CenterX - CrossHalf, CenterY);
  ACanvas.LineTo(CenterX + CrossHalf + 1, CenterY);
  ACanvas.MoveTo(CenterX, CenterY - CrossHalf);
  ACanvas.LineTo(CenterX, CenterY + CrossHalf + 1);
end;

procedure TMainForm.DrawQuadraticCurvePreview(ACanvas: TCanvas; const AStartPoint, AControlPoint, AEndPoint: TPoint; AStrokeColor: TColor; AStrokeWidth: Integer);
var
  SegmentCount: Integer;
  Step: Integer;
  TValue: Double;
  InverseT: Double;
  PrevPoint: TPoint;
  NextPoint: TPoint;
begin
  SegmentCount := Max(
    8,
    Max(
      Abs(AControlPoint.X - AStartPoint.X) + Abs(AControlPoint.Y - AStartPoint.Y),
      Abs(AEndPoint.X - AControlPoint.X) + Abs(AEndPoint.Y - AControlPoint.Y)
    ) * 2
  );

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psDot;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clSilver;
  ACanvas.MoveTo(
    Round((AStartPoint.X + 0.5) * FZoomScale),
    Round((AStartPoint.Y + 0.5) * FZoomScale)
  );
  ACanvas.LineTo(
    Round((AControlPoint.X + 0.5) * FZoomScale),
    Round((AControlPoint.Y + 0.5) * FZoomScale)
  );
  ACanvas.MoveTo(
    Round((AEndPoint.X + 0.5) * FZoomScale),
    Round((AEndPoint.Y + 0.5) * FZoomScale)
  );
  ACanvas.LineTo(
    Round((AControlPoint.X + 0.5) * FZoomScale),
    Round((AControlPoint.Y + 0.5) * FZoomScale)
  );

  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := AStrokeWidth;
  ACanvas.Pen.Color := AStrokeColor;
  PrevPoint := AStartPoint;
  for Step := 1 to SegmentCount do
  begin
    TValue := Step / SegmentCount;
    InverseT := 1.0 - TValue;
    NextPoint := Point(
      Round(
        (InverseT * InverseT * AStartPoint.X) +
        (2.0 * InverseT * TValue * AControlPoint.X) +
        (TValue * TValue * AEndPoint.X)
      ),
      Round(
        (InverseT * InverseT * AStartPoint.Y) +
        (2.0 * InverseT * TValue * AControlPoint.Y) +
        (TValue * TValue * AEndPoint.Y)
      )
    );
    ACanvas.MoveTo(
      Round((PrevPoint.X + 0.5) * FZoomScale),
      Round((PrevPoint.Y + 0.5) * FZoomScale)
    );
    ACanvas.LineTo(
      Round((NextPoint.X + 0.5) * FZoomScale),
      Round((NextPoint.Y + 0.5) * FZoomScale)
    );
    PrevPoint := NextPoint;
  end;
end;

procedure TMainForm.DrawCubicCurvePreview(ACanvas: TCanvas; const AStartPoint,
  AControlPoint1, AControlPoint2, AEndPoint: TPoint; AStrokeColor: TColor;
  AStrokeWidth: Integer);
var
  SegmentCount: Integer;
  Step: Integer;
  TValue: Double;
  InverseT: Double;
  PrevPoint: TPoint;
  NextPoint: TPoint;
begin
  SegmentCount := Max(
    8,
    Max(
      Abs(AControlPoint1.X - AStartPoint.X) + Abs(AControlPoint1.Y - AStartPoint.Y),
      Max(
        Abs(AControlPoint2.X - AControlPoint1.X) + Abs(AControlPoint2.Y - AControlPoint1.Y),
        Abs(AEndPoint.X - AControlPoint2.X) + Abs(AEndPoint.Y - AControlPoint2.Y)
      )
    ) * 2
  );

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psDot;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clSilver;
  ACanvas.MoveTo(
    Round((AStartPoint.X + 0.5) * FZoomScale),
    Round((AStartPoint.Y + 0.5) * FZoomScale)
  );
  ACanvas.LineTo(
    Round((AControlPoint1.X + 0.5) * FZoomScale),
    Round((AControlPoint1.Y + 0.5) * FZoomScale)
  );
  ACanvas.MoveTo(
    Round((AEndPoint.X + 0.5) * FZoomScale),
    Round((AEndPoint.Y + 0.5) * FZoomScale)
  );
  ACanvas.LineTo(
    Round((AControlPoint2.X + 0.5) * FZoomScale),
    Round((AControlPoint2.Y + 0.5) * FZoomScale)
  );

  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := AStrokeWidth;
  ACanvas.Pen.Color := AStrokeColor;
  PrevPoint := AStartPoint;
  for Step := 1 to SegmentCount do
  begin
    TValue := Step / SegmentCount;
    InverseT := 1.0 - TValue;
    NextPoint := Point(
      Round(
        (InverseT * InverseT * InverseT * AStartPoint.X) +
        (3.0 * InverseT * InverseT * TValue * AControlPoint1.X) +
        (3.0 * InverseT * TValue * TValue * AControlPoint2.X) +
        (TValue * TValue * TValue * AEndPoint.X)
      ),
      Round(
        (InverseT * InverseT * InverseT * AStartPoint.Y) +
        (3.0 * InverseT * InverseT * TValue * AControlPoint1.Y) +
        (3.0 * InverseT * TValue * TValue * AControlPoint2.Y) +
        (TValue * TValue * TValue * AEndPoint.Y)
      )
    );
    ACanvas.MoveTo(
      Round((PrevPoint.X + 0.5) * FZoomScale),
      Round((PrevPoint.Y + 0.5) * FZoomScale)
    );
    ACanvas.LineTo(
      Round((NextPoint.X + 0.5) * FZoomScale),
      Round((NextPoint.Y + 0.5) * FZoomScale)
    );
    PrevPoint := NextPoint;
  end;
end;

procedure TMainForm.DrawHoverToolOverlay(ACanvas: TCanvas);
var
  SourcePoint: TPoint;
begin
  if not PaintToolHasCanvasHoverOverlay(FCurrentTool) then
    Exit;
  if (FLastImagePoint.X < 0) or (FLastImagePoint.Y < 0) then
    Exit;
  if (FLastImagePoint.X >= FDocument.Width) or (FLastImagePoint.Y >= FDocument.Height) then
    Exit;

  if PaintToolUsesBrushOverlay(FCurrentTool) then
  begin
    if (FCurrentTool = tkEraser) and FEraserSquareShape then
      DrawSquareHoverOverlay(ACanvas, FLastImagePoint, ActiveToolOverlayRadius)
    else
      DrawBrushHoverOverlay(ACanvas, FLastImagePoint, ActiveToolOverlayRadius);
  end
  else
    DrawPointHoverOverlay(ACanvas, FLastImagePoint);

  if (FCurrentTool = tkCloneStamp) and TryGetCloneOverlaySourcePoint(SourcePoint) then
  begin
    DrawCloneLinkOverlay(ACanvas, SourcePoint, FLastImagePoint);
    DrawCloneSourceOverlay(ACanvas, SourcePoint, ActiveToolOverlayRadius);
  end;
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
  PreviewRadius: Integer;
  PreviewStrokeColor: TColor;
  PreviewStrokeWidth: Integer;
  ShapePreviewFill: Boolean;
  ShapePreviewOutline: Boolean;
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

  if (FCurrentTool = tkLine) and FLinePathOpen and (not FLineCurvePending) and
     (FLastImagePoint.X >= 0) and (FLastImagePoint.Y >= 0) then
  begin
    PreviewStrokeColor := RGBToColor(ActivePaintColor.R, ActivePaintColor.G, ActivePaintColor.B);
    PreviewStrokeWidth := Min(24, Max(1, Round(Max(1, FBrushSize div 2) * FZoomScale)));
    ACanvas.Pen.Color := PreviewStrokeColor;
    ACanvas.Pen.Width := PreviewStrokeWidth;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Style := bsClear;
    ACanvas.MoveTo(
      Round((FDragStart.X + 0.5) * FZoomScale),
      Round((FDragStart.Y + 0.5) * FZoomScale)
    );
    ACanvas.LineTo(
      Round((FLastImagePoint.X + 0.5) * FZoomScale),
      Round((FLastImagePoint.Y + 0.5) * FZoomScale)
    );
    DrawPointHoverOverlay(ACanvas, FDragStart);
    if (FLastImagePoint.X <> FDragStart.X) or (FLastImagePoint.Y <> FDragStart.Y) then
      DrawPointHoverOverlay(ACanvas, FLastImagePoint);
  end;

  if FLineCurvePending and (FCurrentTool = tkLine) then
  begin
    PreviewStrokeColor := RGBToColor(ActivePaintColor.R, ActivePaintColor.G, ActivePaintColor.B);
    PreviewStrokeWidth := Min(24, Max(1, Round(Max(1, FBrushSize div 2) * FZoomScale)));
    if FLineCurveSecondStage then
      DrawCubicCurvePreview(
        ACanvas,
        FDragStart,
        FLineCurveControlPoint,
        FLineCurveControlPoint2,
        FLineCurveEndPoint,
        PreviewStrokeColor,
        PreviewStrokeWidth
      )
    else
      DrawQuadraticCurvePreview(
        ACanvas,
        FDragStart,
        FLineCurveControlPoint,
        FLineCurveEndPoint,
        PreviewStrokeColor,
        PreviewStrokeWidth
      );
    DrawPointHoverOverlay(ACanvas, FDragStart);
    DrawPointHoverOverlay(ACanvas, FLineCurveEndPoint);
    if FLineCurveSecondStage then
    begin
      DrawCloneSourceOverlay(ACanvas, FLineCurveControlPoint, 0);
      DrawPointHoverOverlay(ACanvas, FLineCurveControlPoint2);
    end
    else
      DrawCloneSourceOverlay(ACanvas, FLineCurveControlPoint, 0);
  end;

  if FPointerDown then
  begin
    PreviewStrokeColor := RGBToColor(ActivePaintColor.R, ActivePaintColor.G, ActivePaintColor.B);
    ShapePreviewFill := FShapeStyle in [1, 2];
    ShapePreviewOutline := FShapeStyle in [0, 2];
    ACanvas.Pen.Color := PreviewStrokeColor;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Brush.Color := PreviewStrokeColor;
    case FCurrentTool of
      tkLine:
        begin
          PreviewStrokeWidth := Min(24, Max(1, Round(Max(1, FBrushSize div 2) * FZoomScale)));
          ACanvas.Pen.Width := PreviewStrokeWidth;
          ACanvas.MoveTo(
            Round((FDragStart.X + 0.5) * FZoomScale),
            Round((FDragStart.Y + 0.5) * FZoomScale)
          );
          ACanvas.LineTo(
            Round((FLastImagePoint.X + 0.5) * FZoomScale),
            Round((FLastImagePoint.Y + 0.5) * FZoomScale)
          );
        end;
      tkGradient:
        begin
          if FGradientType = 1 then
          begin
            PreviewRadius := Round(Sqrt(
              Sqr(FLastImagePoint.X - FDragStart.X) +
              Sqr(FLastImagePoint.Y - FDragStart.Y)
            ));
            LeftX := Round((FDragStart.X - PreviewRadius) * FZoomScale);
            TopY := Round((FDragStart.Y - PreviewRadius) * FZoomScale);
            RightX := Round((FDragStart.X + PreviewRadius + 1) * FZoomScale);
            BottomY := Round((FDragStart.Y + PreviewRadius + 1) * FZoomScale);
            ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);
          end;
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
          if FCurrentTool = tkRectangle then
          begin
            PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
            if ShapePreviewOutline then
            begin
              ACanvas.Pen.Style := psSolid;
              ACanvas.Pen.Width := PreviewStrokeWidth;
            end
            else
              ACanvas.Pen.Style := psClear;
            if ShapePreviewFill then
              ACanvas.Brush.Style := bsDiagCross
            else
              ACanvas.Brush.Style := bsClear;
          end
          else
          begin
            ACanvas.Pen.Style := psSolid;
            ACanvas.Pen.Width := 1;
            ACanvas.Brush.Style := bsClear;
          end;
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
          PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
          if ShapePreviewOutline then
          begin
            ACanvas.Pen.Style := psSolid;
            ACanvas.Pen.Width := PreviewStrokeWidth;
          end
          else
            ACanvas.Pen.Style := psClear;
          if ShapePreviewFill then
            ACanvas.Brush.Style := bsDiagCross
          else
            ACanvas.Brush.Style := bsClear;
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
          if FCurrentTool = tkEllipseShape then
          begin
            PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
            if ShapePreviewOutline then
            begin
              ACanvas.Pen.Style := psSolid;
              ACanvas.Pen.Width := PreviewStrokeWidth;
            end
            else
              ACanvas.Pen.Style := psClear;
            if ShapePreviewFill then
              ACanvas.Brush.Style := bsDiagCross
            else
              ACanvas.Brush.Style := bsClear;
          end
          else
          begin
            ACanvas.Pen.Style := psSolid;
            ACanvas.Pen.Width := 1;
            ACanvas.Brush.Style := bsClear;
          end;
          LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
          TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
          RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
          BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
          ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);
        end;
      tkSelectLasso, tkFreeformShape:
        if Length(FLassoPoints) > 1 then
        begin
          if FCurrentTool = tkFreeformShape then
          begin
            PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
            if ShapePreviewOutline then
            begin
              ACanvas.Pen.Style := psSolid;
              ACanvas.Pen.Width := PreviewStrokeWidth;
            end
            else
              ACanvas.Pen.Style := psClear;
          end
          else
          begin
            ACanvas.Pen.Style := psSolid;
            ACanvas.Pen.Width := 1;
          end;
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

    case FCurrentTool of
      tkLine, tkGradient, tkRectangle, tkRoundedRectangle, tkEllipseShape,
      tkSelectRect, tkSelectEllipse, tkCrop:
        DrawPointHoverOverlay(ACanvas, FDragStart);
      tkSelectLasso, tkFreeformShape:
        if Length(FLassoPoints) > 0 then
          DrawPointHoverOverlay(ACanvas, FLassoPoints[0]);
    end;
  end;

  DrawHoverToolOverlay(ACanvas);
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
  UpdateInlineTextEditBounds;
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
  if Assigned(FPaintBox) then
  begin
    UpdateCanvasSize;
    FPaintBox.Invalidate;
  end
  else
    UpdateInlineTextEditBounds;
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
  FLayerDragIndex := -1;
  FLayerDragTargetIndex := -1;
  FLayerList.Items.BeginUpdate;
  try
    FLayerList.Items.Clear;
    for Index := 0 to FDocument.LayerCount - 1 do
    begin
      Layer := FDocument.Layers[Index];
      if Layer.Visible then
        CaptionText := 'On  '
      else
        CaptionText := 'Off ';
      CaptionText := CaptionText + Layer.Name;
      if Layer.Opacity < 255 then
        CaptionText := CaptionText + Format(' (%d%%)', [LayerOpacityPercentFromByte(Layer.Opacity)]);
      FLayerList.Items.Add(CaptionText);
    end;
    FLayerList.ItemIndex := FDocument.ActiveLayerIndex;
  finally
    FLayerList.Items.EndUpdate;
  end;
  { Sync inline layer controls to the active layer }
  if FDocument.LayerCount > 0 then
  begin
    FUpdatingLayerControls := True;
    try
      if Assigned(FLayerBlendCombo) then
        FLayerBlendCombo.ItemIndex := Ord(FDocument.ActiveLayer.BlendMode);
      if Assigned(FLayerVisibleCheck) then
        FLayerVisibleCheck.Checked := FDocument.ActiveLayer.Visible;
      if Assigned(FLayerOpacitySpin) then
        FLayerOpacitySpin.Value := LayerOpacityPercentFromByte(FDocument.ActiveLayer.Opacity);
    finally
      FUpdatingLayerControls := False;
    end;
  end;
  RefreshHistoryPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.RefreshColorsPanel;
begin
  SyncStrokeColorToActiveTarget;
  if Assigned(FColorsValueLabel) then
    FColorsValueLabel.Caption := Format(
      'FG #%2.2x%2.2x%2.2x%2.2x   BG #%2.2x%2.2x%2.2x%2.2x',
      [
        FPrimaryColor.R,
        FPrimaryColor.G,
        FPrimaryColor.B,
        FPrimaryColor.A,
        FSecondaryColor.R,
        FSecondaryColor.G,
        FSecondaryColor.B,
        FSecondaryColor.A
      ]
    );
  if Assigned(FActiveColorHexLabel) then
  begin
    if FColorEditTarget = 0 then
      FActiveColorHexLabel.Caption := Format(
        'Active: Foreground  #%2.2x%2.2x%2.2x%2.2x',
        [
          FPrimaryColor.R,
          FPrimaryColor.G,
          FPrimaryColor.B,
          FPrimaryColor.A
        ]
      )
    else
      FActiveColorHexLabel.Caption := Format(
        'Active: Background  #%2.2x%2.2x%2.2x%2.2x',
        [
          FSecondaryColor.R,
          FSecondaryColor.G,
          FSecondaryColor.B,
          FSecondaryColor.A
        ]
      );
  end;
  if Assigned(FColorPickButton) then
  begin
    if FColorEditTarget = 0 then
      FColorPickButton.Hint := 'Open the system color palette for the foreground swatch'
    else
      FColorPickButton.Hint := 'Open the system color palette for the background swatch';
  end;
  if Assigned(FColorTargetCombo) and (FColorTargetCombo.ItemIndex <> FColorEditTarget) then
    FColorTargetCombo.ItemIndex := FColorEditTarget;
  UpdateColorSpins;
  if Assigned(FColorsBox) then
    FColorsBox.Invalidate;
  if Assigned(FColorSliderBox) then
    FColorSliderBox.Invalidate;
  if Assigned(FSwatchBox) then
    FSwatchBox.Invalidate;
end;

procedure TMainForm.ColorsBoxPaint(Sender: TObject);
const
  SwatchMargin = 10;
  SwatchOffset = 16;
  TileSize = 6;
var
  PB: TPaintBox;
  C: TCanvas;
  SwatchSize: Integer;
  FrontRect: TRect;
  BackRect: TRect;
  TileX: Integer;
  TileY: Integer;
  TextLeft: Integer;
begin
  if not Assigned(Sender) then
    Exit;
  PB := TPaintBox(Sender);
  C := PB.Canvas;
  C.Brush.Style := bsSolid;
  C.Brush.Color := PaletteSurfaceColor(pkColors, False);
  C.FillRect(Rect(0, 0, PB.Width, PB.Height));

  SwatchSize := Min(46, Max(26, PB.Height - 24));
  BackRect := Rect(
    SwatchMargin,
    PB.Height - SwatchMargin - SwatchSize,
    SwatchMargin + SwatchSize,
    PB.Height - SwatchMargin
  );
  FrontRect := Rect(
    SwatchMargin + SwatchOffset,
    SwatchMargin,
    SwatchMargin + SwatchOffset + SwatchSize,
    SwatchMargin + SwatchSize
  );

  for TileY := Max(0, BackRect.Top - 3) to Min(PB.Height - 1, BackRect.Bottom + 3) do
    for TileX := Max(0, BackRect.Left - 3) to Min(PB.Width - 1, BackRect.Right + 3) do
    begin
      if (((TileX - BackRect.Left) div TileSize) + ((TileY - BackRect.Top) div TileSize)) mod 2 = 0 then
        C.Pixels[TileX, TileY] := RGBToColor(236, 238, 242)
      else
        C.Pixels[TileX, TileY] := RGBToColor(214, 217, 223);
    end;
  for TileY := Max(0, FrontRect.Top - 3) to Min(PB.Height - 1, FrontRect.Bottom + 3) do
    for TileX := Max(0, FrontRect.Left - 3) to Min(PB.Width - 1, FrontRect.Right + 3) do
    begin
      if (((TileX - FrontRect.Left) div TileSize) + ((TileY - FrontRect.Top) div TileSize)) mod 2 = 0 then
        C.Pixels[TileX, TileY] := RGBToColor(236, 238, 242)
      else
        C.Pixels[TileX, TileY] := RGBToColor(214, 217, 223);
    end;

  C.Brush.Color := RGBToColor(FSecondaryColor.R, FSecondaryColor.G, FSecondaryColor.B);
  C.Pen.Color := ChromeDividerColor;
  C.Rectangle(BackRect.Left, BackRect.Top, BackRect.Right, BackRect.Bottom);

  C.Brush.Color := RGBToColor(FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B);
  C.Pen.Color := ChromeDividerColor;
  C.Rectangle(FrontRect.Left, FrontRect.Top, FrontRect.Right, FrontRect.Bottom);

  C.Brush.Style := bsClear;
  C.Pen.Width := 2;
  C.Pen.Color := PaletteSelectionColor;
  if FColorEditTarget = 0 then
    C.Rectangle(FrontRect.Left - 2, FrontRect.Top - 2, FrontRect.Right + 2, FrontRect.Bottom + 2)
  else
    C.Rectangle(BackRect.Left - 2, BackRect.Top - 2, BackRect.Right + 2, BackRect.Bottom + 2);
  C.Pen.Width := 1;
  C.Pen.Color := ChromeDividerColor;

  TextLeft := FrontRect.Right + 18;
  C.Font.Color := ChromeTextColor;
  if FColorEditTarget = 0 then
    C.TextOut(TextLeft, 18, 'Editing foreground')
  else
    C.TextOut(TextLeft, 18, 'Editing background');
  C.Font.Color := ChromeMutedTextColor;
  C.TextOut(TextLeft, 38, 'Click either swatch to switch');
  C.TextOut(TextLeft, 56, 'System picker stays in sync');
end;

procedure TMainForm.ColorsBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  SwatchMargin = 10;
  SwatchOffset = 16;
var
  PB: TPaintBox;
  SwatchSize: Integer;
  FrontRect: TRect;
  BackRect: TRect;
begin
  if Button <> mbLeft then
    Exit;
  if not Assigned(Sender) then
    Exit;
  PB := TPaintBox(Sender);
  SwatchSize := Min(46, Max(26, PB.Height - 24));
  BackRect := Rect(
    SwatchMargin,
    PB.Height - SwatchMargin - SwatchSize,
    SwatchMargin + SwatchSize,
    PB.Height - SwatchMargin
  );
  FrontRect := Rect(
    SwatchMargin + SwatchOffset,
    SwatchMargin,
    SwatchMargin + SwatchOffset + SwatchSize,
    SwatchMargin + SwatchSize
  );

  if (X >= FrontRect.Left) and (X < FrontRect.Right) and
     (Y >= FrontRect.Top) and (Y < FrontRect.Bottom) then
    FColorEditTarget := 0
  else if (X >= BackRect.Left) and (X < BackRect.Right) and
          (Y >= BackRect.Top) and (Y < BackRect.Bottom) then
    FColorEditTarget := 1
  else
    Exit;
  RefreshColorsPanel;
end;

procedure TMainForm.ColorsBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if ssLeft in Shift then
    ColorsBoxMouseDown(Sender, mbLeft, Shift, X, Y);
end;

procedure TMainForm.ColorPickButtonChanged(Sender: TObject);
var
  PickedColor: TColor;
begin
  if FUpdatingColorSpins then
    Exit;
  if not Assigned(FColorPickButton) then
    Exit;
  PickedColor := ColorToRGB(FColorPickButton.ButtonColor);
  if FColorEditTarget = 0 then
    FPrimaryColor := RGBA(
      Byte(PickedColor and $FF),
      Byte((PickedColor shr 8) and $FF),
      Byte((PickedColor shr 16) and $FF),
      FPrimaryColor.A
    )
  else
    FSecondaryColor := RGBA(
      Byte(PickedColor and $FF),
      Byte((PickedColor shr 8) and $FF),
      Byte((PickedColor shr 16) and $FF),
      FSecondaryColor.A
    );
  RefreshColorsPanel;
end;

procedure TMainForm.ColorSliderBoxPaint(Sender: TObject);
var
  PB: TPaintBox;
  BarIndex: Integer;
  BarTop: Integer;
  BarHeight: Integer;
  BarGap: Integer;
  BarLeft: Integer;
  BarWidth: Integer;
  X: Integer;
  CurH: Double;
  CurS: Double;
  CurV: Double;
  R: Byte;
  G: Byte;
  B: Byte;
  EditColor: TRGBA32;
  MarkerX: Integer;
  LabelText: string;
  AlphaShade: Byte;
begin
  if not Assigned(Sender) then
    Exit;
  PB := TPaintBox(Sender);
  PB.Canvas.Brush.Color := PaletteSurfaceColor(pkColors, False);
  PB.Canvas.FillRect(Rect(0, 0, PB.Width, PB.Height));

  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);

  BarHeight := 13;
  BarGap := 3;
  BarLeft := 18;
  BarWidth := Max(24, PB.Width - BarLeft - 6);
  for BarIndex := 0 to 3 do
  begin
    BarTop := 2 + BarIndex * (BarHeight + BarGap);
    case BarIndex of
      0:
        for X := 0 to BarWidth - 1 do
        begin
          HSVToRGB(X / Max(1, BarWidth - 1), 1.0, 1.0, R, G, B);
          PB.Canvas.Pen.Color := RGBToColor(R, G, B);
          PB.Canvas.MoveTo(BarLeft + X, BarTop);
          PB.Canvas.LineTo(BarLeft + X, BarTop + BarHeight);
        end;
      1:
        for X := 0 to BarWidth - 1 do
        begin
          HSVToRGB(CurH, X / Max(1, BarWidth - 1), CurV, R, G, B);
          PB.Canvas.Pen.Color := RGBToColor(R, G, B);
          PB.Canvas.MoveTo(BarLeft + X, BarTop);
          PB.Canvas.LineTo(BarLeft + X, BarTop + BarHeight);
        end;
      2:
        for X := 0 to BarWidth - 1 do
        begin
          HSVToRGB(CurH, CurS, X / Max(1, BarWidth - 1), R, G, B);
          PB.Canvas.Pen.Color := RGBToColor(R, G, B);
          PB.Canvas.MoveTo(BarLeft + X, BarTop);
          PB.Canvas.LineTo(BarLeft + X, BarTop + BarHeight);
        end;
    else
      for X := 0 to BarWidth - 1 do
      begin
        AlphaShade := EnsureRange(Round(X * 255.0 / Max(1, BarWidth - 1)), 0, 255);
        PB.Canvas.Pen.Color := RGBToColor(AlphaShade, AlphaShade, AlphaShade);
        PB.Canvas.MoveTo(BarLeft + X, BarTop);
        PB.Canvas.LineTo(BarLeft + X, BarTop + BarHeight);
      end;
    end;
    PB.Canvas.Brush.Style := bsClear;
    PB.Canvas.Pen.Color := ChromeDividerColor;
    PB.Canvas.Rectangle(BarLeft, BarTop, BarLeft + BarWidth, BarTop + BarHeight);
    case BarIndex of
      0: LabelText := 'H';
      1: LabelText := 'S';
      2: LabelText := 'V';
    else
      LabelText := 'A';
    end;
    PB.Canvas.Font.Color := ChromeTextColor;
    PB.Canvas.TextOut(4, BarTop, LabelText);
    case BarIndex of
      0:
        MarkerX := BarLeft + Round(CurH * Max(1, BarWidth - 1));
      1:
        MarkerX := BarLeft + Round(CurS * Max(1, BarWidth - 1));
      2:
        MarkerX := BarLeft + Round(CurV * Max(1, BarWidth - 1));
    else
      MarkerX := BarLeft + Round(EditColor.A * Max(1, BarWidth - 1) / 255.0);
    end;
    PB.Canvas.Pen.Color := clWhite;
    PB.Canvas.Pen.Width := 2;
    PB.Canvas.MoveTo(MarkerX, BarTop - 1);
    PB.Canvas.LineTo(MarkerX, BarTop + BarHeight + 1);
    PB.Canvas.Pen.Width := 1;
    PB.Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TMainForm.ColorSliderBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FActiveColorSlider := EnsureRange(Y div 16, 0, 3);
  ApplyColorSliderAt(X, Y);
end;

procedure TMainForm.ColorSliderBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (ssLeft in Shift) and (FActiveColorSlider >= 0) then
    ApplyColorSliderAt(X, Y);
end;

procedure TMainForm.ColorSliderBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    FActiveColorSlider := -1;
end;

procedure TMainForm.SwatchBoxPaint(Sender: TObject);
{ Draw 8 rows × 12 columns of colour swatches; separating gaps are 1 px. }
const
  Cols = 12;
  Rows = 8;
var
  PB: TPaintBox;
  CellW, CellH, Gap, Row, Col, Idx: Integer;
  SR: TRect;
  C: TRGBA32;
begin
  PB := TPaintBox(Sender);
  Gap := 1;
  CellW := (PB.Width - Gap * (Cols - 1)) div Cols;
  CellH := (PB.Height - Gap * (Rows - 1)) div Rows;
  if (CellW < 1) or (CellH < 1) then Exit;
  for Row := 0 to Rows - 1 do
    for Col := 0 to Cols - 1 do
    begin
      Idx := Row * Cols + Col;
      if (Idx < Low(FSwatchColors)) or (Idx > High(FSwatchColors)) then Continue;
      C := FSwatchColors[Idx];
      SR.Left   := Col * (CellW + Gap);
      SR.Top    := Row * (CellH + Gap);
      SR.Right  := SR.Left + CellW;
      SR.Bottom := SR.Top  + CellH;
      PB.Canvas.Brush.Color := RGBToColor(C.R, C.G, C.B);
      PB.Canvas.Pen.Color   := $00202020;
      PB.Canvas.Pen.Width   := 1;
      PB.Canvas.Rectangle(SR.Left, SR.Top, SR.Right + 1, SR.Bottom + 1);
    end;
end;

procedure TMainForm.SwatchBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
{ Left-click sets primary; right-click sets secondary. }
const
  Cols = 12;
  Rows = 8;
var
  PB: TPaintBox;
  CellW, CellH, Gap, Col, Row, Idx: Integer;
  C: TRGBA32;
begin
  if not (Button in [mbLeft, mbRight]) then Exit;
  PB := TPaintBox(Sender);
  Gap := 1;
  CellW := (PB.Width - Gap * (Cols - 1)) div Cols;
  CellH := (PB.Height - Gap * (Rows - 1)) div Rows;
  if CellW < 1 then Exit;
  Col := EnsureRange(X div Max(1, CellW + Gap), 0, Cols - 1);
  Row := EnsureRange(Y div Max(1, CellH + Gap), 0, Rows - 1);
  Idx := Row * Cols + Col;
  if (Idx < Low(FSwatchColors)) or (Idx > High(FSwatchColors)) then Exit;
  C := FSwatchColors[Idx];
  if Button = mbLeft then
  begin
    FPrimaryColor := C;
    FColorEditTarget := 0;
  end
  else
  begin
    FSecondaryColor := C;
    FColorEditTarget := 1;
  end;
  if Assigned(FColorTargetCombo) then
    FColorTargetCombo.ItemIndex := FColorEditTarget;
  RefreshColorsPanel;
  if Assigned(FColorsBox) then
    FColorsBox.Invalidate;
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
  { Current live state is always at row UndoDepth (0 = initial, 1..N = past ops,
    N = current, N+1.. = future redo ops) }
  CurrentIndex := FDocument.UndoDepth;
  if odSelected in State then
  begin
    BgCol := PaletteSelectionColor;
    TextCol := PaletteSelectionTextColor;
  end
  else if Index > CurrentIndex then
  begin
    BgCol := LB.Color;
    TextCol := ChromeFaintTextColor;
  end
  else if Index = CurrentIndex then
  begin
    BgCol := PaletteActiveRowColor;
    TextCol := ChromeTextColor;
  end
  else
  begin
    BgCol := LB.Color;
    TextCol := ChromeMutedTextColor;
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
  RowIndex: Integer;
  OpIndex: Integer;
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
  if not Assigned(FHistoryList) then Exit;
  FHistoryList.Items.BeginUpdate;
  try
    FHistoryList.Items.Clear;
    UndoCount := FDocument.UndoDepth;
    RedoCount := FDocument.RedoDepth;
    { --- Timeline layout ---
      Row 0            : initial state (always present)
      Row 1..UndoCount : states produced by each recorded operation (oldest→newest)
      Row UndoCount    : live current state ← highlighted / selected
      Row UndoCount+1..: redo (future) states, dimmed
    }
    { Row 0: initial state }
    FHistoryList.Items.Add('0. (initial)');
    { Rows 1..UndoCount: past operations, oldest first }
    for RowIndex := 1 to UndoCount do
    begin
      OpIndex := UndoCount - RowIndex;   { 0 = newest, UndoCount-1 = oldest }
      FHistoryList.Items.Add(Format('%d. %s', [RowIndex, FDocument.UndoActionLabel(OpIndex)]));
    end;
    { Rows UndoCount+1..UndoCount+RedoCount: future redo states, oldest redo first }
    for RowIndex := 1 to RedoCount do
    begin
      OpIndex := RowIndex - 1;    { 0 = next redo, RedoCount-1 = furthest }
      FHistoryList.Items.Add(Format('%d. %s', [UndoCount + RowIndex, FDocument.RedoActionLabel(OpIndex)]));
    end;
    { Highlight current state at row = UndoCount }
    FHistoryList.ItemIndex := UndoCount;
  finally
    FHistoryList.Items.EndUpdate;
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
  SyncStrokeColorToActiveTarget;
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
  ProgressLeft: Integer;
  ProgressWidth: Integer;
  ProgressLabelW: Integer;
  ProgressBarW: Integer;
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

  ProgressLeft := 4 + ProgressStatusPanelLeft(PanelWidths);
  ProgressWidth := ProgressStatusPanelWidth(PanelWidths);
  ProgressLabelW := ProgressLabelWidth(ProgressWidth);
  ProgressBarW := ProgressBarWidth(ProgressWidth);
  if Assigned(FStatusProgressLabel) then
    FStatusProgressLabel.SetBounds(
      ProgressLeft + 4,
      0,
      Max(0, ProgressLabelW - 4),
      FStatusBar.Height
    );
  if Assigned(FStatusProgressBar) then
    FStatusProgressBar.SetBounds(
      ProgressLeft + ProgressLabelW + 4,
      4,
      Max(0, ProgressBarW),
      Max(12, FStatusBar.Height - 8)
    );

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
  { Row layout: 0=(initial), 1..UndoDepth=(past ops), UndoDepth=(current), UndoDepth+1..=(redo)
    So the current position is always at index UndoDepth. }
  CurrentIndex := FDocument.UndoDepth;
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
  SyncImageMutationUI(True, False);
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
const
  DragAlpha   = 0.60;  { semi-transparent while dragging }
  NormalAlpha = 1.00;  { fully opaque at rest }
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
  { Set Cocoa-level alpha so the panel is genuinely see-through during drag }
  if APalette is TWinControl then
    FPSetViewAlpha(Pointer(TWinControl(APalette).Handle),
                   IfThen(ADragging, DragAlpha, NormalAlpha));
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
  TitleLabel.Font.Color := ChromeTextColor;
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
  CloseButton.ParentFont := False;
  CloseButton.Font.Size := 8;
  CloseButton.Font.Color := ChromeTextColor;
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
  ATarget.BevelOuter := bvNone;
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

procedure TMainForm.ApplyColorSliderAt(X, Y: Integer);
var
  EditColor: TRGBA32;
  BarIndex: Integer;
  BarLeft: Integer;
  BarWidth: Integer;
  HueValue: Double;
  SatValue: Double;
  ValValue: Double;
  AlphaValue: Integer;
  NewR: Byte;
  NewG: Byte;
  NewB: Byte;
begin
  if not Assigned(FColorSliderBox) then
    Exit;
  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, HueValue, SatValue, ValValue);
  if FActiveColorSlider >= 0 then
    BarIndex := FActiveColorSlider
  else
    BarIndex := EnsureRange(Y div 16, 0, 3);
  BarLeft := 18;
  BarWidth := Max(24, FColorSliderBox.Width - BarLeft - 6);
  case BarIndex of
    0:
      HueValue := EnsureRange((X - BarLeft) / Max(1, BarWidth - 1), 0.0, 1.0);
    1:
      SatValue := EnsureRange((X - BarLeft) / Max(1, BarWidth - 1), 0.0, 1.0);
    2:
      ValValue := EnsureRange((X - BarLeft) / Max(1, BarWidth - 1), 0.0, 1.0);
  else
    AlphaValue := EnsureRange(Round((X - BarLeft) * 255.0 / Max(1, BarWidth - 1)), 0, 255);
    EditColor := RGBA(EditColor.R, EditColor.G, EditColor.B, AlphaValue);
  end;
  if BarIndex <> 3 then
  begin
    HSVToRGB(HueValue, SatValue, ValValue, NewR, NewG, NewB);
    EditColor := RGBA(NewR, NewG, NewB, EditColor.A);
  end;
  if FColorEditTarget = 0 then
    FPrimaryColor := EditColor
  else
    FSecondaryColor := EditColor;
  RefreshColorsPanel;
end;

procedure TMainForm.LayoutColorsPanel;
const
  Margin = 12;
  Gap = 6;
  BottomMargin = 12;
  ButtonHeight = 26;
  SwatchHeight = 84;
  SliderHeight = 68;
  ContentTop = 30;
begin
  if not Assigned(FColorsPanel) then
    Exit;
  if Assigned(FColorPickButton) then
  begin
    FColorPickButton.Left := Margin;
    FColorPickButton.Top := ContentTop;
    FColorPickButton.Width := 56;
    FColorPickButton.Height := ButtonHeight;
  end;
  if Assigned(FColorPickButton) and Assigned(FColorsBox) then
  begin
    FColorsBox.Left := Margin;
    FColorsBox.Top := FColorPickButton.Top + ButtonHeight + Gap;
    FColorsBox.Width := FColorsPanel.Width - Margin * 2;
    FColorsBox.Height := SwatchHeight;
  end;
  if Assigned(FActiveColorHexLabel) and Assigned(FColorsBox) then
  begin
    FActiveColorHexLabel.Left := Margin;
    FActiveColorHexLabel.Top := FColorsBox.Top + FColorsBox.Height + 4;
    FActiveColorHexLabel.Width := FColorsPanel.Width - Margin * 2;
  end;
  if Assigned(FColorsValueLabel) then
  begin
    FColorsValueLabel.Left := Margin;
    if Assigned(FActiveColorHexLabel) then
      FColorsValueLabel.Top := FActiveColorHexLabel.Top + FActiveColorHexLabel.Height + 2
    else
      FColorsValueLabel.Top := ContentTop + ButtonHeight + Gap + SwatchHeight + 22;
    FColorsValueLabel.Width := FColorsPanel.Width - Margin * 2;
  end;
  if Assigned(FColorSliderBox) then
  begin
    FColorSliderBox.Left := Margin;
    FColorSliderBox.Top := FColorsValueLabel.Top + FColorsValueLabel.Height + Gap;
    FColorSliderBox.Width := FColorsPanel.Width - Margin * 2;
    FColorSliderBox.Height := Min(
      SliderHeight,
      Max(48, FColorsPanel.Height - FColorSliderBox.Top - BottomMargin)
    );
  end;
  if Assigned(FSwatchBox) then
  begin
    FSwatchBox.Left := Margin;
    if Assigned(FColorSliderBox) then
      FSwatchBox.Top := FColorSliderBox.Top + FColorSliderBox.Height + Gap
    else
      FSwatchBox.Top := ContentTop + ButtonHeight + Gap + SwatchHeight + Gap + SliderHeight;
    FSwatchBox.Width := FColorsPanel.Width - Margin * 2;
    FSwatchBox.Height := 0;
    FSwatchBox.Visible := False;
  end;
end;

procedure TMainForm.LayoutLayersPanel;
const
  Margin = 12;
  ContentTop = 30;
  ListTop = ContentTop + 118;
  BottomMargin = 12;
begin
  if not Assigned(FRightPanel) or not Assigned(FLayerList) then
    Exit;
  FLayerList.Left := Margin;
  FLayerList.Top := ListTop;
  FLayerList.Width := FRightPanel.Width - Margin * 2;
  FLayerList.Height := Max(80, FRightPanel.Height - ListTop - BottomMargin);
end;

procedure TMainForm.ColorsPanelResize(Sender: TObject);
begin
  LayoutColorsPanel;
  if Assigned(FColorsBox) then
    FColorsBox.Invalidate;
  if Assigned(FColorSliderBox) then
    FColorSliderBox.Invalidate;
  if Assigned(FSwatchBox) then
    FSwatchBox.Invalidate;
end;

procedure TMainForm.LayersPanelResize(Sender: TObject);
begin
  LayoutLayersPanel;
  if Assigned(FLayerList) then
    FLayerList.Invalidate;
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
  if (FDirty = AValue) and
     (Length(FTabDirtyFlags) > FActiveTabIndex) and
     (FTabDirtyFlags[FActiveTabIndex] = AValue) then
  begin
    FDirty := AValue;
    UpdateCaption;
    RefreshTabCardVisuals(FActiveTabIndex);
    Exit;
  end;
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
  PngLevelStr: string;
  ParsedQuality: Integer;
  ParsedPngLevel: Integer;
  ProgressiveChoice: Integer;
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
  SaveOpts.JpegQuality := FJpegQuality;
  SaveOpts.JpegProgressive := FJpegProgressive;
  SaveOpts.PngCompressionLevel := FPngCompressionLevel;

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
    ProgressiveChoice := MessageDlg(
      'JPEG Export',
      'Use progressive encoding?',
      mtConfirmation,
      [mbYes, mbNo, mbCancel],
      0
    );
    case ProgressiveChoice of
      mrYes:
        FJpegProgressive := True;
      mrNo:
        FJpegProgressive := False;
    else
      Exit;
    end;
    SaveOpts.JpegProgressive := FJpegProgressive;
  end
  else if Ext = '.png' then
  begin
    PngLevelStr := IntToStr(FPngCompressionLevel);
    if not InputQuery(
      'PNG Export',
      'Compression level (0-9, higher = smaller file / slower save):',
      PngLevelStr
    ) then
      Exit;
    ParsedPngLevel := StrToIntDef(Trim(PngLevelStr), FPngCompressionLevel);
    ParsedPngLevel := EnsureRange(ParsedPngLevel, 0, 9);
    FPngCompressionLevel := ParsedPngLevel;
    SaveOpts.PngCompressionLevel := FPngCompressionLevel;
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
  else if TryLoadDocumentFromFile(ResolvedFileName, LoadedDocument) then
  begin
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
  ResetLineCurveState;
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
  SampleSurface: TRasterSurface;
  FillMask: TSelectionMask;
  PaintSelection: TSelectionMask;
  Radius: Integer;
  DestX: Integer;
  DestY: Integer;
  SourceX: Integer;
  SourceY: Integer;
begin
  if FDocument.HasSelection then
    PaintSelection := FDocument.Selection
  else
    PaintSelection := nil;
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
        255, { pencil always hard }
        PaintSelection
      );
    tkBrush:
      FDocument.ActiveLayer.Surface.DrawLine(
        FLastImagePoint.X,
        FLastImagePoint.Y,
        APoint.X,
        APoint.Y,
        Max(1, FBrushSize div 2),
        ActivePaintColor,
        FBrushOpacity * 255 div 100,
        FBrushHardness * 255 div 100,
        PaintSelection
      );
    tkEraser:
      if FEraserSquareShape then
        FDocument.ActiveLayer.Surface.DrawSquareLine(
          FLastImagePoint.X,
          FLastImagePoint.Y,
          APoint.X,
          APoint.Y,
          Max(1, FBrushSize div 2),
          ActivePaintColor,
          FBrushOpacity * 255 div 100,
          FBrushHardness * 255 div 100,
          PaintSelection
        )
      else
        FDocument.ActiveLayer.Surface.DrawLine(
          FLastImagePoint.X,
          FLastImagePoint.Y,
          APoint.X,
          APoint.Y,
          Max(1, FBrushSize div 2),
          ActivePaintColor,
          FBrushOpacity * 255 div 100,
          FBrushHardness * 255 div 100,
          PaintSelection
        );
    tkFill:
      begin
        if FFillSampleSource = 1 then
          SampleSurface := FDocument.Composite
        else
          SampleSurface := FDocument.ActiveLayer.Surface;
        try
          if FBucketFloodMode = 1 then
            FillMask := SampleSurface.CreateGlobalColorSelection(
              APoint.X,
              APoint.Y,
              EnsureRange(FFillTolerance, 0, 255)
            )
          else
            FillMask := SampleSurface.CreateContiguousSelection(
              APoint.X,
              APoint.Y,
              EnsureRange(FFillTolerance, 0, 255)
            );
          try
            if PaintSelection <> nil then
              FillMask.IntersectWith(PaintSelection);
            FDocument.ActiveLayer.Surface.FillSelection(
              FillMask,
              ActivePaintColor,
              255
            );
          finally
            FillMask.Free;
          end;
        finally
          if FFillSampleSource = 1 then
            SampleSurface.Free;
        end;
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
        ColorForActiveTarget(not FPickSecondaryTarget),
        ActivePaintColor,
        EnsureRange(FWandTolerance, 0, 255),
        FBrushOpacity * 255 div 100,
        FRecolorPreserveValue,
        PaintSelection
      );
    tkCloneStamp:
      if FCloneStampSampled and (FCloneStampSnapshot <> nil) then
      begin
        { Clone only within the active brush radius, keeping the source offset stable
          across the stroke. }
        Radius := Max(1, FBrushSize div 2);
        for DestY := Max(0, APoint.Y - Radius) to Min(FDocument.Height - 1, APoint.Y + Radius) do
          for DestX := Max(0, APoint.X - Radius) to Min(FDocument.Width - 1, APoint.X + Radius) do
          begin
            if Round(Sqrt(Sqr(DestX - APoint.X) + Sqr(DestY - APoint.Y))) > Radius then
              Continue;
            if FCloneAligned and FCloneAlignedOffsetValid then
            begin
              SourceX := DestX + FCloneAlignedOffset.X;
              SourceY := DestY + FCloneAlignedOffset.Y;
            end
            else
            begin
              SourceX := FCloneStampSource.X + (DestX - FDragStart.X);
              SourceY := FCloneStampSource.Y + (DestY - FDragStart.Y);
            end;
            if not FCloneStampSnapshot.InBounds(SourceX, SourceY) then
              Continue;
            FDocument.ActiveLayer.Surface.BlendPixel(
              DestX,
              DestY,
              FCloneStampSnapshot[SourceX, SourceY],
              FBrushOpacity * 255 div 100,
              PaintSelection
            );
          end;
      end;
  end;
  FLastImagePoint := APoint;
end;

procedure TMainForm.CommitShapeTool(const AStartPoint, AEndPoint: TPoint);
var
  DoFill: Boolean;
  DoOutline: Boolean;
  FillColor: TRGBA32;
  PaintSelection: TSelectionMask;
begin
  { FShapeStyle: 0=Outline, 1=Fill, 2=Outline+Fill }
  DoOutline := FShapeStyle in [0, 2];
  DoFill := FShapeStyle in [1, 2];
  FillColor := RGBA(ActivePaintColor.R, ActivePaintColor.G, ActivePaintColor.B, ActivePaintColor.A);
  if FDocument.HasSelection then
    PaintSelection := FDocument.Selection
  else
    PaintSelection := nil;
  case FCurrentTool of
    tkLine:
      if FLineCurvePending then
        if FLineCurveSecondStage then
          FDocument.ActiveLayer.Surface.DrawCubicBezier(
            AStartPoint.X,
            AStartPoint.Y,
            FLineCurveControlPoint.X,
            FLineCurveControlPoint.Y,
            FLineCurveControlPoint2.X,
            FLineCurveControlPoint2.Y,
            FLineCurveEndPoint.X,
            FLineCurveEndPoint.Y,
            Max(1, FBrushSize div 2),
            ActivePaintColor,
            255,
            255,
            PaintSelection
          )
        else
          FDocument.ActiveLayer.Surface.DrawQuadraticBezier(
            AStartPoint.X,
            AStartPoint.Y,
            FLineCurveControlPoint.X,
            FLineCurveControlPoint.Y,
            FLineCurveEndPoint.X,
            FLineCurveEndPoint.Y,
            Max(1, FBrushSize div 2),
            ActivePaintColor,
            255,
            255,
            PaintSelection
          )
      else
        FDocument.ActiveLayer.Surface.DrawLine(
          AStartPoint.X,
          AStartPoint.Y,
          AEndPoint.X,
          AEndPoint.Y,
          Max(1, FBrushSize div 2),
          ActivePaintColor,
          255,
          255,
          PaintSelection
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
              FPrimaryColor,
              PaintSelection
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
              FPrimaryColor,
              PaintSelection
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
              FSecondaryColor,
              PaintSelection
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
              FSecondaryColor,
              PaintSelection
            );
          end;
        end;
      end;
    tkRectangle:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.DrawRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), FillColor, True, 255, PaintSelection);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), ActivePaintColor, False, 255, PaintSelection);
      end;
    tkRoundedRectangle:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.DrawRoundedRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), FillColor, True, 255, PaintSelection);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawRoundedRectangle(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), ActivePaintColor, False, 255, PaintSelection);
      end;
    tkEllipseShape:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.DrawEllipse(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), FillColor, True, 255, PaintSelection);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawEllipse(
            AStartPoint.X, AStartPoint.Y, AEndPoint.X, AEndPoint.Y,
            Max(1, FBrushSize div 3), ActivePaintColor, False, 255, PaintSelection);
      end;
    tkFreeformShape:
      begin
        if DoFill then
          FDocument.ActiveLayer.Surface.FillPolygon(FLassoPoints, FillColor, 255, PaintSelection);
        if DoOutline then
          FDocument.ActiveLayer.Surface.DrawPolygon(
            FLassoPoints,
            Max(1, FBrushSize div 3),
            ActivePaintColor,
            True,
            255,
            PaintSelection
          );
      end;
  end;
end;

procedure TMainForm.ResetDocument(AWidth, AHeight: Integer);
begin
  CommitInlineTextEdit(True);
  FDocument.NewBlank(AWidth, AHeight);
  ResetLineCurveState;
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
  CommitInlineTextEdit(True);
  NewDoc := TImageDocument.Create(TargetWidth, TargetHeight);
  AddDocumentTab(NewDoc, '', False);
  FPointerDown := False;
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;
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
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.RedoClick(Sender: TObject);
begin
  FDocument.Redo;
  SyncImageMutationUI(True, True);
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
  SyncImageMutationUI(False, True);
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
  SyncImageMutationUI(True, True);
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
var
  TargetIndex: Integer;
begin
  if FDocument.LayerCount <= 1 then
    Exit;
  if ssCtrl in GetKeyShiftState then
    TargetIndex := FDocument.LayerCount - 1
  else
    TargetIndex := FDocument.ActiveLayerIndex + 1;
  if TargetIndex > FDocument.LayerCount - 1 then
    TargetIndex := FDocument.LayerCount - 1;
  if TargetIndex = FDocument.ActiveLayerIndex then
    Exit;
  if TargetIndex = FDocument.LayerCount - 1 then
    FDocument.PushHistory('Move Layer to Top')
  else
    FDocument.PushHistory('Move Layer Up');
  FDocument.MoveLayer(FDocument.ActiveLayerIndex, TargetIndex);
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.MoveLayerDownClick(Sender: TObject);
var
  TargetIndex: Integer;
begin
  if FDocument.LayerCount <= 1 then
    Exit;
  if ssCtrl in GetKeyShiftState then
    TargetIndex := 0
  else
    TargetIndex := FDocument.ActiveLayerIndex - 1;
  if TargetIndex < 0 then
    TargetIndex := 0;
  if TargetIndex = FDocument.ActiveLayerIndex then
    Exit;
  if TargetIndex = 0 then
    FDocument.PushHistory('Move Layer to Bottom')
  else
    FDocument.PushHistory('Move Layer Down');
  FDocument.MoveLayer(FDocument.ActiveLayerIndex, TargetIndex);
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
  ValueText := IntToStr(LayerOpacityPercentFromByte(FDocument.ActiveLayer.Opacity));
  if not InputQuery('Layer Opacity', 'Opacity (0 to 100%)', ValueText) then
    Exit;
  FDocument.PushHistory('Layer Opacity');
  FDocument.SetLayerOpacity(
    FDocument.ActiveLayerIndex,
    LayerOpacityByteFromPercent(
      StrToIntDef(ValueText, LayerOpacityPercentFromByte(FDocument.ActiveLayer.Opacity))
    )
  );
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.LayerVisibleCheckChanged(Sender: TObject);
begin
  if FUpdatingLayerControls then
    Exit;
  if not Assigned(FLayerVisibleCheck) or (FDocument.LayerCount = 0) then
    Exit;
  if FDocument.ActiveLayer.Visible = FLayerVisibleCheck.Checked then
    Exit;
  FDocument.PushHistory('Toggle Layer Visibility');
  FDocument.SetLayerVisibility(FDocument.ActiveLayerIndex, FLayerVisibleCheck.Checked);
  SetDirty(True);
  RefreshLayers;
  RefreshCanvas;
end;

procedure TMainForm.LayerOpacitySpinChanged(Sender: TObject);
var
  NewOpacity: Byte;
begin
  if FUpdatingLayerControls then
    Exit;
  if not Assigned(FLayerOpacitySpin) or (FDocument.LayerCount = 0) then
    Exit;
  NewOpacity := LayerOpacityByteFromPercent(FLayerOpacitySpin.Value);
  if FDocument.ActiveLayer.Opacity = NewOpacity then
    Exit;
  FDocument.PushHistory('Layer Opacity');
  FDocument.SetLayerOpacity(FDocument.ActiveLayerIndex, NewOpacity);
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
  SyncImageMutationUI(False, True);
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
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.RotateClockwiseClick(Sender: TObject);
begin
  FDocument.PushHistory('Rotate 90 Right');
  FDocument.Rotate90Clockwise;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.RotateCounterClockwiseClick(Sender: TObject);
begin
  FDocument.PushHistory('Rotate 90 Left');
  FDocument.Rotate90CounterClockwise;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.Rotate180Click(Sender: TObject);
begin
  FDocument.PushHistory('Rotate 180');
  FDocument.Rotate180;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.FlipHorizontalClick(Sender: TObject);
begin
  FDocument.PushHistory('Flip Horizontal');
  FDocument.FlipHorizontal;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.FlipVerticalClick(Sender: TObject);
begin
  FDocument.PushHistory('Flip Vertical');
  FDocument.FlipVertical;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.AutoLevelClick(Sender: TObject);
begin
  BeginStatusProgress('Applying Auto-Level...');
  try
    FDocument.PushHistory('Auto-Level');
    FDocument.AutoLevel;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.InvertColorsClick(Sender: TObject);
begin
  BeginStatusProgress('Applying Invert Colors...');
  try
    FDocument.PushHistory('Invert Colors');
    FDocument.InvertColors;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.GrayscaleClick(Sender: TObject);
begin
  BeginStatusProgress('Applying Grayscale...');
  try
    FDocument.PushHistory('Grayscale');
    FDocument.Grayscale;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.CurvesClick(Sender: TObject);
var
  GammaValue: Double;
begin
  GammaValue := 1.0;
  if not RunCurvesDialog(Self, GammaValue) then
    Exit;
  BeginStatusProgress('Applying Curves...');
  try
    FDocument.PushHistory('Curves');
    FDocument.AdjustGammaCurve(GammaValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Hue / Saturation...');
  try
    FDocument.PushHistory('Hue / Saturation');
    FDocument.AdjustHueSaturation(HueDelta, SaturationDelta);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Levels...');
  try
    FDocument.PushHistory('Levels');
    FDocument.AdjustLevels(
      InputLow,
      InputHigh,
      OutputLow,
      OutputHigh
    );
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Brightness / Contrast...');
  try
    FDocument.PushHistory('Brightness / Contrast');
    FDocument.AdjustBrightness(Brightness);
    FDocument.AdjustContrast(Contrast);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.SepiaClick(Sender: TObject);
begin
  BeginStatusProgress('Applying Sepia...');
  try
    FDocument.PushHistory('Sepia');
    FDocument.Sepia;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.BlackAndWhiteClick(Sender: TObject);
var
  ValueText: string;
begin
  ValueText := '127';
  if not InputQuery('Black and White', 'Threshold (0 to 255)', ValueText) then
    Exit;
  BeginStatusProgress('Applying Black and White...');
  try
    FDocument.PushHistory('Black and White');
    FDocument.BlackAndWhite(EnsureRange(StrToIntDef(ValueText, 127), 0, 255));
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.PosterizeClick(Sender: TObject);
var
  Levels: Integer;
begin
  Levels := 6;
  if not RunPosterizeDialog(Self, Levels) then
    Exit;
  BeginStatusProgress('Applying Posterize...');
  try
    FDocument.PushHistory('Posterize');
    FDocument.Posterize(Levels);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.BlurClick(Sender: TObject);
var
  Radius: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  Radius := 2;
  if not RunBlurDialog(Self, Radius) then
    Exit;
  BeginStatusProgress('Applying Blur...');
  try
    FDocument.PushHistory('Blur');
    FDocument.BoxBlur(Radius);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Sharpen...');
  try
    FDocument.PushHistory('Sharpen');
    FDocument.Sharpen;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Add Noise...');
  try
    FDocument.PushHistory('Add Noise');
    FDocument.AddNoise(Amount);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Detect Edges...');
  try
    FDocument.PushHistory('Detect Edges');
    FDocument.DetectEdges;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Outline Effect...');
  try
    FDocument.PushHistory('Outline Effect');
    FDocument.OutlineEffect(FPrimaryColor, ThresholdVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  SyncImageMutationUI;
end;

procedure TMainForm.EraseSelectionClick(Sender: TObject);
begin
  if not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory('Erase Selection');
  FDocument.EraseSelection;
  SyncImageMutationUI;
end;

procedure TMainForm.CropToSelectionClick(Sender: TObject);
begin
  if not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory('Crop to Selection');
  FDocument.CropToSelection;
  SyncImageMutationUI(True, True);
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
begin
  if Assigned(FColorPickButton) then
    FColorPickButton.Click;
end;

procedure TMainForm.SecondaryColorClick(Sender: TObject);
begin
  FColorEditTarget := 1;
  RefreshColorsPanel;
  if Assigned(FColorPickButton) then
    FColorPickButton.Click;
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
  CommitInlineTextEdit(True);
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
  CommitInlineTextEdit(True);
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;
  FCurrentTool := TToolKind(TControl(Sender).Tag);
  FToolCombo.ItemIndex := PaintToolDisplayIndex(FCurrentTool);
  UpdateToolOptionControl;
  RefreshCanvas;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.ToolComboChange(Sender: TObject);
begin
  CommitInlineTextEdit(True);
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;
  if FToolCombo.ItemIndex >= 0 then
    FCurrentTool := TToolKind(PtrInt(FToolCombo.Items.Objects[FToolCombo.ItemIndex]));
  UpdateToolOptionControl;
  RefreshCanvas;
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
    tkPencil, tkBrush, tkEraser, tkLine, tkRectangle, tkRoundedRectangle,
    tkEllipseShape, tkFreeformShape, tkCloneStamp, tkRecolor:
      FBrushSize := Max(1, FBrushSpin.Value);
  end;
  RefreshCanvas;
end;

procedure TMainForm.LayerListDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
{ Renders one layer row: a scaled thumbnail on the left, then the layer name
  (bold when selected) with opacity % if < 100, and a dim eye indicator. }
const
  ThumbW  = 36;
  ThumbH  = 28;
  ThumbMarginX = 4;
  ThumbMarginY = 4;
  NameLeft = ThumbW + ThumbMarginX * 2 + 4;
var
  LB: TListBox;
  Layer: TRasterLayer;
  Surf: TRasterSurface;
  NameText: string;
  BgCol: TColor;
  TextCol: TColor;
  ThumbSurf: TRasterSurface;
  ThumbBmp: TBitmap;
  Src: TRasterSurface;
  SW, SH, TX, TY: Integer;
  ThumbR: TRect;
  OldFont: TFont;
begin
  LB := TListBox(Control);
  if not Assigned(FDocument) then Exit;
  if (Index < 0) or (Index >= FDocument.LayerCount) then Exit;

  Layer := FDocument.Layers[Index];

  { Background }
  if odSelected in State then
  begin
    BgCol  := PaletteSelectionColor;
    TextCol := PaletteSelectionTextColor;
  end
  else if (FLayerDragIndex >= 0) and (FLayerDragTargetIndex = Index) then
  begin
    BgCol := PaletteActiveRowColor;
    TextCol := ChromeTextColor;
  end
  else
  begin
    BgCol  := LB.Color;
    TextCol := ChromeTextColor;
  end;
  LB.Canvas.Brush.Color := BgCol;
  LB.Canvas.FillRect(ARect);

  { Thumbnail — checkerboard background then the layer pixels }
  TX := ARect.Left + ThumbMarginX;
  TY := ARect.Top  + ThumbMarginY;
  ThumbR := Rect(TX, TY, TX + ThumbW, TY + ThumbH);
  { Draw a grey/white checker for transparency }
  LB.Canvas.Brush.Color := ChromeDividerColor;
  LB.Canvas.FillRect(ThumbR);

  Src := Layer.Surface;
  if Assigned(Src) and (Src.Width > 0) and (Src.Height > 0) then
  begin
    { Scale to fit within ThumbW x ThumbH keeping aspect ratio }
    if Src.Width * ThumbH > Src.Height * ThumbW then
    begin
      SW := ThumbW;
      SH := Max(1, Src.Height * ThumbW div Src.Width);
    end
    else
    begin
      SH := ThumbH;
      SW := Max(1, Src.Width * ThumbH div Src.Height);
    end;
    ThumbSurf := Src.ResizeBilinear(SW, SH);
    try
      ThumbBmp := SurfaceToBitmap(ThumbSurf);
      try
        LB.Canvas.Draw(
          TX + (ThumbW - SW) div 2,
          TY + (ThumbH - SH) div 2,
          ThumbBmp);
      finally
        ThumbBmp.Free;
      end;
    finally
      ThumbSurf.Free;
    end;
  end;
  { Thumbnail border }
  LB.Canvas.Brush.Style := bsClear;
  LB.Canvas.Pen.Color := ChromeDividerColor;
  LB.Canvas.Rectangle(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom);
  LB.Canvas.Brush.Style := bsSolid;

  { Layer name – bold for selected / active }
  NameText := Layer.Name;
  if Layer.Opacity < 255 then
    NameText := NameText + Format(' %d%%', [LayerOpacityPercentFromByte(Layer.Opacity)]);
  if not Layer.Visible then
    NameText := 'Off ' + NameText
  else
    NameText := 'On  ' + NameText;

  OldFont := TFont.Create;
  try
    OldFont.Assign(LB.Canvas.Font);
    LB.Canvas.Font.Color := TextCol;
    if odSelected in State then
      LB.Canvas.Font.Style := [fsBold]
    else
      LB.Canvas.Font.Style := [];
    LB.Canvas.Brush.Style := bsClear;
    LB.Canvas.TextOut(
      ARect.Left + NameLeft,
      ARect.Top + (ARect.Bottom - ARect.Top - LB.Canvas.TextHeight('Ag')) div 2,
      NameText);
    LB.Canvas.Brush.Style := bsSolid;
  finally
    LB.Canvas.Font.Assign(OldFont);
    OldFont.Free;
  end;
end;

procedure TMainForm.LayerListClick(Sender: TObject);
begin
  if FLayerList.ItemIndex >= 0 then
    FDocument.ActiveLayerIndex := FLayerList.ItemIndex;
  if FDocument.LayerCount > 0 then
  begin
    FUpdatingLayerControls := True;
    try
      if Assigned(FLayerBlendCombo) then
        FLayerBlendCombo.ItemIndex := Ord(FDocument.ActiveLayer.BlendMode);
      if Assigned(FLayerVisibleCheck) then
        FLayerVisibleCheck.Checked := FDocument.ActiveLayer.Visible;
      if Assigned(FLayerOpacitySpin) then
        FLayerOpacitySpin.Value := LayerOpacityPercentFromByte(FDocument.ActiveLayer.Opacity);
    finally
      FUpdatingLayerControls := False;
    end;
  end;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.LayerListDblClick(Sender: TObject);
begin
  ToggleLayerVisibilityClick(Sender);
end;

procedure TMainForm.LayerListMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  HitIndex: Integer;
begin
  if (Button <> mbLeft) or not Assigned(FLayerList) then
    Exit;
  HitIndex := FLayerList.ItemAtPos(Point(4, Y), True);
  if (HitIndex < 0) or (HitIndex >= FDocument.LayerCount) then
    Exit;
  FLayerDragIndex := HitIndex;
  FLayerDragTargetIndex := HitIndex;
  FLayerList.ItemIndex := HitIndex;
  LayerListClick(Sender);
  FLayerList.Invalidate;
end;

procedure TMainForm.LayerListMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  HoverIndex: Integer;
begin
  if not Assigned(FLayerList) then
    Exit;
  if (FLayerDragIndex >= 0) and not (ssLeft in Shift) then
  begin
    FLayerDragIndex := -1;
    FLayerDragTargetIndex := -1;
    FLayerList.Invalidate;
    Exit;
  end;
  if (FLayerDragIndex < 0) or not (ssLeft in Shift) then
    Exit;
  HoverIndex := FLayerList.ItemAtPos(Point(4, Y), True);
  if HoverIndex < 0 then
  begin
    if Y < 0 then
      HoverIndex := 0
    else
      HoverIndex := FDocument.LayerCount - 1;
  end;
  HoverIndex := EnsureRange(HoverIndex, 0, FDocument.LayerCount - 1);
  if HoverIndex = FLayerDragTargetIndex then
    Exit;
  FLayerDragTargetIndex := HoverIndex;
  FLayerList.Invalidate;
end;

procedure TMainForm.LayerListMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  DropIndex: Integer;
begin
  if (Button <> mbLeft) or not Assigned(FLayerList) then
    Exit;
  if FLayerDragIndex < 0 then
    Exit;
  DropIndex := FLayerList.ItemAtPos(Point(4, Y), True);
  if DropIndex < 0 then
    DropIndex := FLayerDragTargetIndex;
  DropIndex := EnsureRange(DropIndex, 0, FDocument.LayerCount - 1);
  if (DropIndex <> FLayerDragIndex) and (DropIndex >= 0) then
  begin
    FDocument.PushHistory('Reorder Layer');
    FDocument.MoveLayer(FLayerDragIndex, DropIndex);
    SetDirty(True);
    RefreshLayers;
    RefreshCanvas;
  end;
  FLayerDragIndex := -1;
  FLayerDragTargetIndex := -1;
  FLayerList.Invalidate;
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

  if (FCurrentTool = tkLine) and (FLineCurvePending or FLinePathOpen) then
    case Key of
      VK_ESCAPE:
        begin
          if FLineCurvePending and FLinePathOpen then
            ResetLineCurveSegmentState
          else
            ResetLineCurveState;
          RefreshCanvas;
          Key := 0;
          Exit;
        end;
      VK_RETURN:
        begin
          if FLineCurvePending then
            CommitPendingLineSegment(False)
          else
            ResetLineCurveState;
          RefreshCanvas;
          Key := 0;
          Exit;
        end;
    end;

  { Tool shortcuts and color swap/reset only; modifiers are allowed for
    cycling (Shift reverses order) }  
  NewTool := NextToolForKey(Char(Key), ssShift in Shift, FCurrentTool);
  if NewTool <> FCurrentTool then
  begin
    CommitInlineTextEdit(True);
    ResetLineCurveState;
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
        { toggle which color the active paint tools use }
        ToggleColorEditTarget;
        RefreshColorsPanel;
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

procedure TMainForm.SimulateMouseMove(Shift: TShiftState; X, Y: Integer);
begin
  PaintBoxMouseMove(nil, Shift, X, Y);
end;

procedure TMainForm.SimulateMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  PaintBoxMouseUp(nil, Button, Shift, X, Y);
end;

procedure TMainForm.BeginStrokeHistory;
begin
  FreeAndNil(FPreStrokeSnapshot);  { defensive: discard any incomplete previous stroke }
  FStrokeLayerIndex := FDocument.ActiveLayerIndex;
  FPreStrokeSnapshot := FDocument.ActiveLayer.Surface.Clone;
  FStrokeDirtyRect := Rect(MaxInt, MaxInt, 0, 0);  { empty sentinel: Left > Right }
end;

procedure TMainForm.ExpandStrokeDirty(const APoint: TPoint);
var
  R: Integer;
begin
  R := Max(2, (FBrushSize + 1) div 2 + 2);  { brush radius + a small margin }
  if FStrokeDirtyRect.Left > FStrokeDirtyRect.Right then
  begin
    FStrokeDirtyRect := Rect(APoint.X - R, APoint.Y - R,
                             APoint.X + R + 1, APoint.Y + R + 1);
  end
  else
  begin
    if APoint.X - R     < FStrokeDirtyRect.Left   then FStrokeDirtyRect.Left   := APoint.X - R;
    if APoint.Y - R     < FStrokeDirtyRect.Top    then FStrokeDirtyRect.Top    := APoint.Y - R;
    if APoint.X + R + 1 > FStrokeDirtyRect.Right  then FStrokeDirtyRect.Right  := APoint.X + R + 1;
    if APoint.Y + R + 1 > FStrokeDirtyRect.Bottom then FStrokeDirtyRect.Bottom := APoint.Y + R + 1;
  end;
end;

procedure TMainForm.CommitStrokeHistory(const ALabel: string);
var
  BeforePixels: TRasterSurface;
  CR: TRect;
begin
  if not Assigned(FPreStrokeSnapshot) then Exit;
  { Clamp dirty rect to document bounds }
  CR.Left   := Max(0, FStrokeDirtyRect.Left);
  CR.Top    := Max(0, FStrokeDirtyRect.Top);
  CR.Right  := Min(FDocument.Width,  FStrokeDirtyRect.Right);
  CR.Bottom := Min(FDocument.Height, FStrokeDirtyRect.Bottom);
  if (CR.Right <= CR.Left) or (CR.Bottom <= CR.Top) then
  begin
    FreeAndNil(FPreStrokeSnapshot);
    Exit;
  end;
  { Crop the pre-stroke layer copy to just the dirty sub-rectangle }
  BeforePixels := TRasterSurface.Create(CR.Right - CR.Left, CR.Bottom - CR.Top);
  FPreStrokeSnapshot.CopyRegionTo(BeforePixels, CR.Left, CR.Top);
  { PushRegionHistory takes ownership of BeforePixels }
  FDocument.PushRegionHistory(ALabel, FStrokeLayerIndex, CR, BeforePixels);
  FreeAndNil(FPreStrokeSnapshot);
  RefreshTabCardVisuals(FActiveTabIndex);
  RefreshAuxiliaryImageViews(False);
end;

procedure TMainForm.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
begin
  if Button = mbMiddle then
  begin
    ActivateTempPan;
    FPickSecondaryTarget := False;
    FStrokeColor := ColorForActiveTarget(False);
  end
  else
  begin
    FStrokeColor := ColorForActiveTarget(Button = mbRight);
    case FCurrentTool of
      tkColorPicker:
        begin
          FPickSecondaryTarget := FColorEditTarget = 1;
          if Button = mbRight then
            FPickSecondaryTarget := not FPickSecondaryTarget;
        end;
      tkRecolor:
        FPickSecondaryTarget := Button = mbRight;
      tkCloneStamp:
        FPickSecondaryTarget := (Button = mbRight) or
          ((Button = mbLeft) and (ssAlt in Shift));
      tkZoom:
        FPickSecondaryTarget := Button = mbRight;
    else
      FPickSecondaryTarget := False;
    end;
  end;

  ImagePoint := CanvasToImage(X, Y);
  FLastPointerPoint := Point(X, Y);
  FLastImagePoint := ImagePoint;
  if (FCurrentTool = tkLine) and (Button = mbRight) and (FLineCurvePending or FLinePathOpen) then
  begin
    if FLineCurvePending and FLinePathOpen then
      ResetLineCurveSegmentState
    else
      ResetLineCurveState;
    RefreshCanvas;
    RefreshStatus(ImagePoint);
    Exit;
  end;
  if (FCurrentTool = tkLine) and FLineCurvePending then
  begin
    if not FLineCurveSecondStage then
    begin
      FLineCurveControlPoint := ImagePoint;
      FLineCurveSecondStage := True;
      FLineCurveControlPoint2 := ImagePoint;
    end
    else
    begin
      FLineCurveControlPoint2 := ImagePoint;
      CommitPendingLineSegment(True);
    end;
    RefreshCanvas;
    RefreshStatus(ImagePoint);
    Exit;
  end;
  if (FCurrentTool = tkLine) and FLinePathOpen then
  begin
    if (ImagePoint.X <> FDragStart.X) or (ImagePoint.Y <> FDragStart.Y) then
    begin
      FLineCurvePending := True;
      FLineCurveSecondStage := False;
      FLineCurveEndPoint := ImagePoint;
      FLineCurveControlPoint := Point(
        (FDragStart.X + ImagePoint.X) div 2,
        (FDragStart.Y + ImagePoint.Y) div 2
      );
      FLineCurveControlPoint2 := FLineCurveControlPoint;
    end;
    RefreshCanvas;
    RefreshStatus(ImagePoint);
    Exit;
  end;
  FDragStart := ImagePoint;
  { Only override combo-selected mode when modifier keys are held }
  if (ssShift in Shift) or (ssAlt in Shift) then
    FPendingSelectionMode := SelectionModeFromShift(Shift);
  FPointerDown := True;

  case FCurrentTool of
    tkPencil, tkBrush, tkEraser:
      begin
        BeginStrokeHistory;
        ApplyImmediateTool(ImagePoint);
        ExpandStrokeDirty(ImagePoint);
        SetDirty(True);
        RefreshCanvas;
      end;
    tkFill:
      begin
        FDocument.PushHistory(PaintToolName(FCurrentTool));
        ApplyImmediateTool(ImagePoint);
        SyncImageMutationUI(False, True);
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
        ApplySelectionFeather;
        SetDirty(True);
        RefreshCanvas;
        FPointerDown := False;
      end;
    tkText:
      begin
        if (Button = mbRight) or (ssAlt in Shift) then
        begin
          InitializeTextToolDefaults;
          if RunTextDialog(Self, FTextLastResult) and
             Assigned(FInlineTextEdit) and FInlineTextEdit.Visible then
          begin
            UpdateInlineTextEditStyle;
            UpdateInlineTextEditBounds;
          end;
        end
        else
          BeginInlineTextEdit(ImagePoint);
        FPointerDown := False;
      end;
    tkCloneStamp:
      begin
        if FPickSecondaryTarget then
        begin
          { Right-click = set clone source }
          FCloneStampSource := ImagePoint;
          FCloneStampSampled := True;
          FCloneAlignedOffsetValid := False;
          FCloneStampSnapshot.Free;
          FCloneStampSnapshot := FDocument.ActiveLayer.Surface.Clone;
          FPointerDown := False;
          if Assigned(FPaintBox) then
            FPaintBox.Invalidate;
        end
        else if FCloneStampSampled then
        begin
          if FCloneAligned and not FCloneAlignedOffsetValid then
          begin
            FCloneAlignedOffset := Point(
              FCloneStampSource.X - ImagePoint.X,
              FCloneStampSource.Y - ImagePoint.Y
            );
            FCloneAlignedOffsetValid := True;
          end;
          BeginStrokeHistory;
          ApplyImmediateTool(ImagePoint);
          ExpandStrokeDirty(ImagePoint);
          SetDirty(True);
          RefreshCanvas;
        end
        else
          FPointerDown := False;
      end;
    tkRecolor:
      begin
        BeginStrokeHistory;
        ApplyImmediateTool(ImagePoint);
        ExpandStrokeDirty(ImagePoint);
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
        FPointerDown := False;
        RefreshColorsPanel;
        if Assigned(FPaintBox) then
          FPaintBox.Invalidate;
        RefreshStatus(ImagePoint);
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
          ExpandStrokeDirty(ImagePoint);
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
          ExpandStrokeDirty(ImagePoint);
          SetDirty(True);
          RefreshCanvas;
        end;
      tkCloneStamp:
        if FCloneStampSampled then
        begin
          ApplyImmediateTool(ImagePoint);
          ExpandStrokeDirty(ImagePoint);
          SetDirty(True);
          RefreshCanvas;
        end;
    end;
  if (not FPointerDown) and (FCurrentTool = tkLine) and FLineCurvePending then
  begin
    if FLineCurveSecondStage then
      FLineCurveControlPoint2 := ImagePoint
    else
      FLineCurveControlPoint := ImagePoint;
  end;
  if not FPointerDown or not (FCurrentTool in [tkPencil, tkBrush, tkEraser, tkMoveSelection, tkMovePixels]) then
    FLastImagePoint := ImagePoint;
  if (not FPointerDown) and Assigned(FPaintBox) and
     (
       PaintToolHasCanvasHoverOverlay(FCurrentTool) or
       ((FCurrentTool = tkLine) and (FLineCurvePending or FLinePathOpen))
     ) then
    FPaintBox.Invalidate;
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
  { Finalise stroke-based region history for painting tools }
  if Assigned(FPreStrokeSnapshot) then
    CommitStrokeHistory(PaintToolName(FCurrentTool));
  ImagePoint := CanvasToImage(X, Y);
  FLastImagePoint := ImagePoint;

  if FCurrentTool = tkLine then
  begin
    if not FLineCurvePending then
    begin
      if (ImagePoint.X = FDragStart.X) and (ImagePoint.Y = FDragStart.Y) then
      begin
        FDocument.PushHistory(PaintToolName(FCurrentTool));
        CommitShapeTool(FDragStart, ImagePoint);
        SyncImageMutationUI(False, True);
      end
      else
      begin
        FLinePathOpen := False;
        FLineCurvePending := True;
        FLineCurveSecondStage := False;
        FLineCurveEndPoint := ImagePoint;
        FLineCurveControlPoint := Point(
          (FDragStart.X + ImagePoint.X) div 2,
          (FDragStart.Y + ImagePoint.Y) div 2
        );
        FLineCurveControlPoint2 := FLineCurveControlPoint;
      end;
      RefreshCanvas;
    end;
  end;
  if FCurrentTool in [tkGradient, tkRectangle, tkRoundedRectangle, tkEllipseShape] then
  begin
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    CommitShapeTool(FDragStart, ImagePoint);
    SyncImageMutationUI(False, True);
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
      UpdateCanvasSize;
      SyncImageMutationUI(True, True);
    end;
  end;
  if FCurrentTool = tkFreeformShape then
  begin
    AppendLassoPoint(ImagePoint);
    if Length(FLassoPoints) > 1 then
    begin
      FDocument.PushHistory(PaintToolName(FCurrentTool));
      CommitShapeTool(FDragStart, ImagePoint);
      SyncImageMutationUI(False, True);
    end;
    SetLength(FLassoPoints, 0);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectRect then
  begin
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    FDocument.SelectRectangle(FDragStart.X, FDragStart.Y, ImagePoint.X, ImagePoint.Y, FPendingSelectionMode);
    ApplySelectionFeather;
    SetDirty(True);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectEllipse then
  begin
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    FDocument.SelectEllipse(FDragStart.X, FDragStart.Y, ImagePoint.X, ImagePoint.Y, FPendingSelectionMode);
    ApplySelectionFeather;
    SetDirty(True);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectLasso then
  begin
    AppendLassoPoint(ImagePoint);
    FDocument.PushHistory(PaintToolName(FCurrentTool));
    FDocument.SelectLasso(FLassoPoints, FPendingSelectionMode);
    ApplySelectionFeather;
    SetLength(FLassoPoints, 0);
    SetDirty(True);
    RefreshCanvas;
  end;
  RefreshStatus(ImagePoint);
end;

procedure TMainForm.PaintBoxMouseLeave(Sender: TObject);
begin
  FLastImagePoint := Point(-1, -1);
  if Assigned(FPaintBox) then
    FPaintBox.Invalidate;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.PlaceTextAtPoint(const AResult: TTextDialogResult;
  APoint: TPoint; AColor: TRGBA32);
var
  TextSurface: TRasterSurface;
  PaintSelection: TSelectionMask;
begin
  TextSurface := RenderTextToSurface(AResult, AColor);
  if TextSurface = nil then
    Exit;
  try
    if FDocument.HasSelection then
      PaintSelection := FDocument.Selection
    else
      PaintSelection := nil;
    FDocument.ActiveLayer.Surface.PasteSurface(TextSurface,
      APoint.X, APoint.Y, 255, PaintSelection);
  finally
    TextSurface.Free;
  end;
end;

procedure TMainForm.EmbossClick(Sender: TObject);
begin
  if FDocument.LayerCount = 0 then Exit;
  BeginStatusProgress('Applying Emboss...');
  try
    FDocument.PushHistory('Emboss');
    FDocument.Emboss;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Soften...');
  try
    FDocument.PushHistory('Soften');
    FDocument.Soften;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Render Clouds...');
  try
    FDocument.PushHistory('Render Clouds');
    FDocument.RenderClouds(1);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Pixelate...');
  try
    FDocument.PushHistory('Pixelate');
    FDocument.Pixelate(Val);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Vignette...');
  try
    FDocument.PushHistory('Vignette');
    FDocument.Vignette(Strength);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Motion Blur...');
  try
    FDocument.PushHistory('Motion Blur');
    FDocument.MotionBlur(AngleVal, DistVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Median Filter...');
  try
    FDocument.PushHistory('Median Filter');
    FDocument.MedianFilter(RadiusVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Glow Effect...');
  try
    FDocument.PushHistory('Glow Effect');
    FDocument.GlowEffect(RadVal, IntVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Oil Paint...');
  try
    FDocument.PushHistory('Oil Paint');
    FDocument.OilPaint(RadVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Frosted Glass...');
  try
    FDocument.PushHistory('Frosted Glass');
    FDocument.FrostedGlass(AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
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
  BeginStatusProgress('Applying Zoom Blur...');
  try
    FDocument.PushHistory('Zoom Blur');
    FDocument.ZoomBlur(FDocument.Width div 2, FDocument.Height div 2, AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Zoom Blur';
  FLastEffectProc := @ZoomBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.GaussianBlurClick(Sender: TObject);
var
  RadStr: string;
  RadVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  RadStr := '3';
  if not InputQuery('Gaussian Blur', 'Radius (1–30):', RadStr) then Exit;
  RadVal := EnsureRange(StrToIntDef(Trim(RadStr), 3), 1, 30);
  BeginStatusProgress('Applying Gaussian Blur...');
  try
    FDocument.PushHistory('Gaussian Blur');
    FDocument.GaussianBlur(RadVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Gaussian Blur';
  FLastEffectProc := @GaussianBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.UnfocusClick(Sender: TObject);
var
  RadiusText: string;
  RadiusValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  RadiusText := '4';
  if not InputQuery('Unfocus', 'Radius (1-24):', RadiusText) then Exit;
  RadiusValue := EnsureRange(StrToIntDef(Trim(RadiusText), 4), 1, 24);
  BeginStatusProgress('Applying Unfocus...');
  try
    FDocument.PushHistory('Unfocus');
    FDocument.Unfocus(RadiusValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Unfocus';
  FLastEffectProc := @UnfocusClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.SurfaceBlurClick(Sender: TObject);
var
  RadiusText: string;
  ThresholdText: string;
  RadiusValue: Integer;
  ThresholdValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  RadiusText := '3';
  if not InputQuery('Surface Blur', 'Radius (1-24):', RadiusText) then Exit;
  RadiusValue := EnsureRange(StrToIntDef(Trim(RadiusText), 3), 1, 24);
  ThresholdText := '24';
  if not InputQuery('Surface Blur', 'Edge threshold (0-255):', ThresholdText) then Exit;
  ThresholdValue := EnsureRange(StrToIntDef(Trim(ThresholdText), 24), 0, 255);
  BeginStatusProgress('Applying Surface Blur...');
  try
    FDocument.PushHistory('Surface Blur');
    FDocument.SurfaceBlur(RadiusValue, ThresholdValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Surface Blur';
  FLastEffectProc := @SurfaceBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RadialBlurClick(Sender: TObject);
var
  AmtStr: string;
  AmtVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AmtStr := '15';
  if not InputQuery('Radial Blur', 'Sweep angle in degrees (1–60):', AmtStr) then Exit;
  AmtVal := EnsureRange(StrToIntDef(Trim(AmtStr), 15), 1, 60);
  BeginStatusProgress('Applying Radial Blur...');
  try
    FDocument.PushHistory('Radial Blur');
    FDocument.RadialBlur(AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Radial Blur';
  FLastEffectProc := @RadialBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.TwistClick(Sender: TObject);
var
  AmtStr: string;
  AmtVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AmtStr := '90';
  if not InputQuery('Twist', 'Angle in degrees (-360 to 360):', AmtStr) then Exit;
  AmtVal := EnsureRange(StrToIntDef(Trim(AmtStr), 90), -360, 360);
  BeginStatusProgress('Applying Twist...');
  try
    FDocument.PushHistory('Twist');
    FDocument.Twist(AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Twist';
  FLastEffectProc := @TwistClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.FragmentClick(Sender: TObject);
var
  OffStr: string;
  OffVal: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  OffStr := '8';
  if not InputQuery('Fragment', 'Offset in pixels (1–40):', OffStr) then Exit;
  OffVal := EnsureRange(StrToIntDef(Trim(OffStr), 8), 1, 40);
  BeginStatusProgress('Applying Fragment...');
  try
    FDocument.PushHistory('Fragment');
    FDocument.Fragment(OffVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Fragment';
  FLastEffectProc := @FragmentClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.BulgeClick(Sender: TObject);
var
  AmountText: string;
  AmountValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AmountText := '50';
  if not InputQuery('Bulge', 'Strength (1-100):', AmountText) then Exit;
  AmountValue := EnsureRange(StrToIntDef(Trim(AmountText), 50), 1, 100);
  BeginStatusProgress('Applying Bulge...');
  try
    FDocument.PushHistory('Bulge');
    FDocument.Bulge(AmountValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Bulge';
  FLastEffectProc := @BulgeClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.DentsClick(Sender: TObject);
var
  AmountText: string;
  AmountValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AmountText := '50';
  if not InputQuery('Dents', 'Strength (1-100):', AmountText) then Exit;
  AmountValue := EnsureRange(StrToIntDef(Trim(AmountText), 50), 1, 100);
  BeginStatusProgress('Applying Dents...');
  try
    FDocument.PushHistory('Dents');
    FDocument.Dents(AmountValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Dents';
  FLastEffectProc := @DentsClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.ReliefClick(Sender: TObject);
var
  AngleText: string;
  AngleValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  AngleText := '45';
  if not InputQuery('Relief', 'Light angle in degrees (0-359):', AngleText) then Exit;
  AngleValue := EnsureRange(StrToIntDef(Trim(AngleText), 45), 0, 359);
  BeginStatusProgress('Applying Relief...');
  try
    FDocument.PushHistory('Relief');
    FDocument.Relief(AngleValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Relief';
  FLastEffectProc := @ReliefClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RedEyeClick(Sender: TObject);
var
  ThresholdText: string;
  StrengthText: string;
  ThresholdValue: Integer;
  StrengthValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  ThresholdText := '48';
  if not InputQuery('Red Eye', 'Red threshold (0-255):', ThresholdText) then Exit;
  ThresholdValue := EnsureRange(StrToIntDef(Trim(ThresholdText), 48), 0, 255);
  StrengthText := '100';
  if not InputQuery('Red Eye', 'Reduction strength (0-100):', StrengthText) then Exit;
  StrengthValue := EnsureRange(StrToIntDef(Trim(StrengthText), 100), 0, 100);
  BeginStatusProgress('Applying Red Eye...');
  try
    FDocument.PushHistory('Red Eye');
    FDocument.RedEye(ThresholdValue, StrengthValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Red Eye';
  FLastEffectProc := @RedEyeClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.TileReflectionClick(Sender: TObject);
var
  TileText: string;
  TileValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  TileText := '32';
  if not InputQuery('Tile Reflection', 'Tile size in pixels (2-256):', TileText) then Exit;
  TileValue := EnsureRange(StrToIntDef(Trim(TileText), 32), 2, 256);
  BeginStatusProgress('Applying Tile Reflection...');
  try
    FDocument.PushHistory('Tile Reflection');
    FDocument.TileReflection(TileValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Tile Reflection';
  FLastEffectProc := @TileReflectionClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.CrystallizeClick(Sender: TObject);
var
  CellText: string;
  CellValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  CellText := '24';
  if not InputQuery('Crystallize', 'Cell size in pixels (2-128):', CellText) then Exit;
  CellValue := EnsureRange(StrToIntDef(Trim(CellText), 24), 2, 128);
  BeginStatusProgress('Applying Crystallize...');
  try
    FDocument.PushHistory('Crystallize');
    FDocument.Crystallize(CellValue, 1);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Crystallize';
  FLastEffectProc := @CrystallizeClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.InkSketchClick(Sender: TObject);
var
  InkText: string;
  ColorText: string;
  InkValue: Integer;
  ColorValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  InkText := '100';
  if not InputQuery('Ink Sketch', 'Ink strength (0-200):', InkText) then Exit;
  InkValue := EnsureRange(StrToIntDef(Trim(InkText), 100), 0, 200);
  ColorText := '45';
  if not InputQuery('Ink Sketch', 'Color retention (0-100):', ColorText) then Exit;
  ColorValue := EnsureRange(StrToIntDef(Trim(ColorText), 45), 0, 100);
  BeginStatusProgress('Applying Ink Sketch...');
  try
    FDocument.PushHistory('Ink Sketch');
    FDocument.InkSketch(InkValue, ColorValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Ink Sketch';
  FLastEffectProc := @InkSketchClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.MandelbrotClick(Sender: TObject);
var
  IterationText: string;
  ZoomText: string;
  IterationValue: Integer;
  ZoomValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  IterationText := '64';
  if not InputQuery('Mandelbrot Fractal', 'Iterations (8-512):', IterationText) then Exit;
  IterationValue := EnsureRange(StrToIntDef(Trim(IterationText), 64), 8, 512);
  ZoomText := '100';
  if not InputQuery('Mandelbrot Fractal', 'Zoom percent (25-400):', ZoomText) then Exit;
  ZoomValue := EnsureRange(StrToIntDef(Trim(ZoomText), 100), 25, 400);
  BeginStatusProgress('Applying Mandelbrot Fractal...');
  try
    FDocument.PushHistory('Mandelbrot Fractal');
    FDocument.RenderMandelbrot(IterationValue, ZoomValue / 100.0);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Mandelbrot Fractal';
  FLastEffectProc := @MandelbrotClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := 'Repeat: ' + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.JuliaClick(Sender: TObject);
var
  IterationText: string;
  ZoomText: string;
  IterationValue: Integer;
  ZoomValue: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  IterationText := '64';
  if not InputQuery('Julia Fractal', 'Iterations (8-512):', IterationText) then Exit;
  IterationValue := EnsureRange(StrToIntDef(Trim(IterationText), 64), 8, 512);
  ZoomText := '100';
  if not InputQuery('Julia Fractal', 'Zoom percent (25-400):', ZoomText) then Exit;
  ZoomValue := EnsureRange(StrToIntDef(Trim(ZoomText), 100), 25, 400);
  BeginStatusProgress('Applying Julia Fractal...');
  try
    FDocument.PushHistory('Julia Fractal');
    FDocument.RenderJulia(IterationValue, ZoomValue / 100.0);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := 'Julia Fractal';
  FLastEffectProc := @JuliaClick;
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
  DialogResult.Visible := Layer.Visible;
  DialogResult.Opacity := Layer.Opacity;
  DialogResult.BlendMode := Layer.BlendMode;
  if not RunLayerPropertiesDialog(Self, DialogResult) then
    Exit;
  FDocument.PushHistory('Layer Properties');
  Layer.Name := DialogResult.Name;
  Layer.Visible := DialogResult.Visible;
  Layer.Opacity := DialogResult.Opacity;
  Layer.BlendMode := DialogResult.BlendMode;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.PasteSelectionClick(Sender: TObject);
begin
  if not FDocument.HasStoredSelection then
    Exit;
  FDocument.PasteStoredSelection;
  SyncImageMutationUI(True, True);
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
  SyncImageMutationUI;
end;

procedure TMainForm.InlineTextEditChange(Sender: TObject);
begin
  UpdateInlineTextEditBounds;
end;

procedure TMainForm.InlineTextEditMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (X < 0) or (Y < 0) then
    Exit;
  if (Button <> mbRight) and not (ssAlt in Shift) then
    Exit;
  InitializeTextToolDefaults;
  if RunTextDialog(Self, FTextLastResult) then
  begin
    UpdateInlineTextEditStyle;
    UpdateInlineTextEditBounds;
  end;
end;

procedure TMainForm.InlineTextEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssShift in Shift) then
  begin
    CommitInlineTextEdit(True);
    Key := 0;
    Exit;
  end;
  case Key of
    VK_RETURN:
      begin
        CommitInlineTextEdit(True);
        Key := 0;
      end;
    VK_ESCAPE:
      begin
        CommitInlineTextEdit(False);
        Key := 0;
      end;
  end;
end;

procedure TMainForm.InlineTextEditExit(Sender: TObject);
begin
  if FInlineTextCommitting then
    Exit;
  CommitInlineTextEdit(True);
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
  CommitInlineTextEdit(True);

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
  CommitInlineTextEdit(True);
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

function TMainForm.PointToTabStrip(AControl: TControl; X, Y: Integer): TPoint;
begin
  Result := Point(X, Y);
  while Assigned(AControl) and (AControl <> FTabStrip) do
  begin
    Inc(Result.X, AControl.Left);
    Inc(Result.Y, AControl.Top);
    AControl := AControl.Parent;
  end;
end;

procedure TMainForm.BuildTabThumbnail(AIndex: Integer; AImage: TImage);
var
  CompositeSurf: TRasterSurface;
  ThumbSurf: TRasterSurface;
  ThumbBmp: TBitmap;
  DrawW: Integer;
  DrawH: Integer;
begin
  if not Assigned(AImage) then
    Exit;
  AImage.Picture.Clear;
  if (AIndex < 0) or (AIndex >= Length(FTabDocuments)) then
    Exit;
  if not Assigned(FTabDocuments[AIndex]) then
    Exit;

  CompositeSurf := FTabDocuments[AIndex].Composite;
  try
    if (CompositeSurf.Width <= 0) or (CompositeSurf.Height <= 0) then
      Exit;
    if CompositeSurf.Width * TabThumbnailHeight > CompositeSurf.Height * TabThumbnailWidth then
    begin
      DrawW := TabThumbnailWidth;
      DrawH := Max(1, CompositeSurf.Height * TabThumbnailWidth div CompositeSurf.Width);
    end
    else
    begin
      DrawH := TabThumbnailHeight;
      DrawW := Max(1, CompositeSurf.Width * TabThumbnailHeight div CompositeSurf.Height);
    end;
    ThumbSurf := CompositeSurf.ResizeBilinear(DrawW, DrawH);
    try
      ThumbBmp := SurfaceToBitmap(ThumbSurf);
      try
        AImage.Picture.Assign(ThumbBmp);
      finally
        ThumbBmp.Free;
      end;
    finally
      ThumbSurf.Free;
    end;
  finally
    CompositeSurf.Free;
  end;
end;

procedure TMainForm.RefreshTabCardVisuals(AIndex: Integer);
var
  I: Integer;
  ChildIndex: Integer;
  Card: TPanel;
  ChildControl: TControl;
  TabCaption: string;
  TabHint: string;
begin
  if not Assigned(FTabStrip) then
    Exit;
  if (AIndex < 0) or
     (AIndex >= Length(FTabDocuments)) or
     (AIndex >= Length(FTabDirtyFlags)) or
     (AIndex >= Length(FTabFileNames)) then
    Exit;

  if FTabDirtyFlags[AIndex] then
    TabCaption := TabDocumentDisplayName(AIndex) + ' *'
  else
    TabCaption := TabDocumentDisplayName(AIndex);
  if FTabFileNames[AIndex] <> '' then
    TabHint := FTabFileNames[AIndex]
  else
    TabHint := TabCaption;

  for I := 0 to FTabStrip.ControlCount - 1 do
  begin
    if not (FTabStrip.Controls[I] is TPanel) then
      Continue;
    Card := TPanel(FTabStrip.Controls[I]);
    if Card.Tag <> AIndex then
      Continue;

    Card.Hint := TabHint;
    if AIndex = FActiveTabIndex then
      Card.Color := PaletteActiveRowColor
    else
      Card.Color := PaletteListBackgroundColor;

    for ChildIndex := 0 to Card.ControlCount - 1 do
    begin
      ChildControl := Card.Controls[ChildIndex];
      ChildControl.Hint := TabHint;
      if ChildControl is TImage then
        BuildTabThumbnail(AIndex, TImage(ChildControl))
      else if ChildControl is TLabel then
      begin
        if ChildControl.Top <= 10 then
        begin
          TLabel(ChildControl).Caption := TabCaption;
          if AIndex = FActiveTabIndex then
            TLabel(ChildControl).Font.Style := [fsBold]
          else
            TLabel(ChildControl).Font.Style := [];
        end
        else
          TLabel(ChildControl).Caption := Format(
            '%d x %d px',
            [FTabDocuments[AIndex].Width, FTabDocuments[AIndex].Height]
          );
      end;
    end;
    Card.Invalidate;
    Exit;
  end;
end;

procedure TMainForm.MoveDocumentTab(AFromIndex, AToIndex: Integer);
var
  DocTemp: TImageDocument;
  NameTemp: string;
  DirtyTemp: Boolean;
  I: Integer;
begin
  if Length(FTabDocuments) <= 1 then
    Exit;
  if (AFromIndex < 0) or (AFromIndex >= Length(FTabDocuments)) then
    Exit;
  AToIndex := EnsureRange(AToIndex, 0, Length(FTabDocuments) - 1);
  if AFromIndex = AToIndex then
    Exit;

  if Length(FTabFileNames) > FActiveTabIndex then
    FTabFileNames[FActiveTabIndex] := FCurrentFileName;
  if Length(FTabDirtyFlags) > FActiveTabIndex then
    FTabDirtyFlags[FActiveTabIndex] := FDirty;

  DocTemp := FTabDocuments[AFromIndex];
  NameTemp := FTabFileNames[AFromIndex];
  DirtyTemp := FTabDirtyFlags[AFromIndex];

  if AFromIndex < AToIndex then
  begin
    for I := AFromIndex to AToIndex - 1 do
    begin
      FTabDocuments[I] := FTabDocuments[I + 1];
      FTabFileNames[I] := FTabFileNames[I + 1];
      FTabDirtyFlags[I] := FTabDirtyFlags[I + 1];
    end;
  end
  else
  begin
    for I := AFromIndex downto AToIndex + 1 do
    begin
      FTabDocuments[I] := FTabDocuments[I - 1];
      FTabFileNames[I] := FTabFileNames[I - 1];
      FTabDirtyFlags[I] := FTabDirtyFlags[I - 1];
    end;
  end;

  FTabDocuments[AToIndex] := DocTemp;
  FTabFileNames[AToIndex] := NameTemp;
  FTabDirtyFlags[AToIndex] := DirtyTemp;

  FActiveTabIndex := MoveIndexAfterReorder(FActiveTabIndex, AFromIndex, AToIndex);
  FDocument := FTabDocuments[FActiveTabIndex];
  FCurrentFileName := FTabFileNames[FActiveTabIndex];
  FDirty := FTabDirtyFlags[FActiveTabIndex];

  RefreshTabStrip;
  UpdateCaption;
end;

procedure TMainForm.RefreshTabStrip;
var
  I: Integer;
  Card: TPanel;
  Thumb: TImage;
  TitleLabel: TLabel;
  InfoLabel: TLabel;
  AddBtn: TSpeedButton;
  CloseBtn: TSpeedButton;
  CardLeftPos: Integer;
  RequiredWidth: Integer;
  ViewportWidth: Integer;
  NewScrollPos: Integer;
  TabCaption: string;
  TabHint: string;
begin
  if not Assigned(FTabStrip) then Exit;
  if FUpdatingTabs then Exit;
  FUpdatingTabs := True;
  try
    { Remove all existing tab controls }
    while FTabStrip.ControlCount > 0 do
      FTabStrip.Controls[0].Free;

    CardLeftPos := TabStripInset;
    for I := 0 to Length(FTabDocuments) - 1 do
    begin
      TabCaption := TabDocumentDisplayName(I);
      if FTabDirtyFlags[I] then
        TabCaption := TabCaption + ' *';
      if FTabFileNames[I] <> '' then
        TabHint := FTabFileNames[I]
      else
        TabHint := TabCaption;

      Card := TPanel.Create(FTabStrip);
      Card.Parent := FTabStrip;
      Card.Left := CardLeftPos;
      Card.Top := 4;
      Card.Width := TabCardWidth;
      Card.Height := TabCardHeight;
      Card.BevelOuter := bvNone;
      Card.Caption := '';
      Card.Tag := I;
      Card.ParentColor := False;
      if I = FActiveTabIndex then
        Card.Color := PaletteActiveRowColor
      else
        Card.Color := PaletteListBackgroundColor;
      Card.PopupMenu := FTabPopupMenu;
      Card.Hint := TabHint;
      Card.ShowHint := True;
      Card.OnMouseDown := @TabCardMouseDown;
      Card.OnMouseMove := @TabCardMouseMove;
      Card.OnMouseUp := @TabCardMouseUp;

      Thumb := TImage.Create(Card);
      Thumb.Parent := Card;
      Thumb.Left := 6;
      Thumb.Top := 8;
      Thumb.Width := TabThumbnailWidth;
      Thumb.Height := TabThumbnailHeight;
      Thumb.Center := True;
      Thumb.Proportional := True;
      Thumb.Stretch := True;
      Thumb.Tag := I;
      Thumb.PopupMenu := FTabPopupMenu;
      Thumb.Hint := TabHint;
      Thumb.ShowHint := True;
      Thumb.OnMouseDown := @TabCardMouseDown;
      Thumb.OnMouseMove := @TabCardMouseMove;
      Thumb.OnMouseUp := @TabCardMouseUp;
      BuildTabThumbnail(I, Thumb);

      TitleLabel := TLabel.Create(Card);
      TitleLabel.Parent := Card;
      TitleLabel.Left := 52;
      TitleLabel.Top := 7;
      TitleLabel.Width := 92;
      TitleLabel.Height := 14;
      TitleLabel.AutoSize := False;
      TitleLabel.Caption := TabCaption;
      TitleLabel.Transparent := True;
      TitleLabel.Tag := I;
      TitleLabel.PopupMenu := FTabPopupMenu;
      TitleLabel.Hint := TabHint;
      TitleLabel.ShowHint := True;
      TitleLabel.ParentFont := False;
      TitleLabel.Font.Size := 9;
      TitleLabel.Font.Color := ChromeTextColor;
      if I = FActiveTabIndex then
        TitleLabel.Font.Style := [fsBold]
      else
        TitleLabel.Font.Style := [];
      TitleLabel.OnMouseDown := @TabCardMouseDown;
      TitleLabel.OnMouseMove := @TabCardMouseMove;
      TitleLabel.OnMouseUp := @TabCardMouseUp;

      InfoLabel := TLabel.Create(Card);
      InfoLabel.Parent := Card;
      InfoLabel.Left := 52;
      InfoLabel.Top := 24;
      InfoLabel.Width := 98;
      InfoLabel.Height := 12;
      InfoLabel.AutoSize := False;
      InfoLabel.Caption := Format(
        '%d x %d px',
        [FTabDocuments[I].Width, FTabDocuments[I].Height]
      );
      InfoLabel.Transparent := True;
      InfoLabel.Tag := I;
      InfoLabel.PopupMenu := FTabPopupMenu;
      InfoLabel.Hint := TabHint;
      InfoLabel.ShowHint := True;
      InfoLabel.ParentFont := False;
      InfoLabel.Font.Size := 8;
      InfoLabel.Font.Color := ChromeMutedTextColor;
      InfoLabel.OnMouseDown := @TabCardMouseDown;
      InfoLabel.OnMouseMove := @TabCardMouseMove;
      InfoLabel.OnMouseUp := @TabCardMouseUp;

      CloseBtn := TSpeedButton.Create(Card);
      CloseBtn.Parent := Card;
      CloseBtn.Left := Card.Width - 22;
      CloseBtn.Top := 4;
      CloseBtn.Width := 18;
      CloseBtn.Height := 18;
      CloseBtn.Flat := True;
      if TryBuildButtonGlyph('x', bicCommand, CloseBtn.Glyph) then
      begin
        CloseBtn.Caption := '';
        CloseBtn.NumGlyphs := 1;
        CloseBtn.Margin := 2;
      end
      else
        CloseBtn.Caption := 'x';
      CloseBtn.Tag := I;
      CloseBtn.ParentFont := False;
      CloseBtn.Font.Size := 8;
      CloseBtn.Font.Color := ChromeTextColor;
      CloseBtn.OnClick := @TabCloseButtonClick;
      CloseBtn.Hint := 'Close document';
      CloseBtn.ShowHint := True;

      CardLeftPos := CardLeftPos + TabCardWidth + TabCardSpacing;
    end;

    AddBtn := TSpeedButton.Create(FTabStrip);
    AddBtn.Parent := FTabStrip;
    AddBtn.Left := CardLeftPos;
    AddBtn.Top := 14;
    AddBtn.Width := 24;
    AddBtn.Height := 24;
    AddBtn.Flat := True;
    if TryBuildButtonGlyph('+', bicCommand, AddBtn.Glyph) then
    begin
      AddBtn.Caption := '';
      AddBtn.NumGlyphs := 1;
      AddBtn.Margin := 4;
    end
    else
      AddBtn.Caption := '+';
    AddBtn.ParentFont := False;
    AddBtn.Font.Size := 11;
    AddBtn.Font.Color := ChromeTextColor;
    AddBtn.Hint := 'New document';
    AddBtn.ShowHint := True;
    AddBtn.OnClick := @NewDocumentClick;

    RequiredWidth := Max(
      TabContentWidth(Length(FTabDocuments)),
      Max(1, FTabStripHost.ClientWidth)
    );
    FTabStrip.Width := RequiredWidth;
    ViewportWidth := Max(1, FTabStripHost.ClientWidth);
    NewScrollPos := ScrollPositionForVisibleTab(
      FActiveTabIndex,
      ViewportWidth,
      FTabStripHost.HorzScrollBar.Position,
      Length(FTabDocuments)
    );
    FTabStripHost.HorzScrollBar.Position := NewScrollPos;
  finally
    FUpdatingTabs := False;
  end;
end;

procedure TMainForm.TabButtonClick(Sender: TObject);
begin
  if not (Sender is TControl) then Exit;
  SwitchToTab(TControl(Sender).Tag);
end;

procedure TMainForm.TabCardMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  if not (Sender is TControl) then
    Exit;
  FTabPressedIndex := TControl(Sender).Tag;
  FTabDragOrigin := PointToTabStrip(TControl(Sender), X, Y);
  FTabDragging := False;
end;

procedure TMainForm.TabCardMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  CurrentPoint: TPoint;
begin
  if (FTabPressedIndex < 0) or not (ssLeft in Shift) then
    Exit;
  if Sender is TControl then
    CurrentPoint := PointToTabStrip(TControl(Sender), X, Y)
  else
    CurrentPoint := Point(X, Y);
  if Abs(CurrentPoint.X - FTabDragOrigin.X) >= 6 then
    FTabDragging := True;
end;

procedure TMainForm.TabCardMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ReleasePoint: TPoint;
  TargetIndex: Integer;
begin
  if Button <> mbLeft then
  begin
    FTabPressedIndex := -1;
    FTabDragging := False;
    Exit;
  end;
  if FTabPressedIndex < 0 then
    Exit;

  if Sender is TControl then
    ReleasePoint := PointToTabStrip(TControl(Sender), X, Y)
  else
    ReleasePoint := Point(X, Y);

  if FTabDragging then
  begin
    TargetIndex := TabDropIndexAtX(ReleasePoint.X, Length(FTabDocuments));
    MoveDocumentTab(FTabPressedIndex, TargetIndex);
  end
  else
    SwitchToTab(FTabPressedIndex);

  FTabPressedIndex := -1;
  FTabDragging := False;
end;

procedure TMainForm.TabCloseButtonClick(Sender: TObject);
var
  Idx: Integer;
begin
  if not (Sender is TControl) then Exit;
  Idx := TControl(Sender).Tag;
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
    else if TryLoadDocumentFromFile(ResolvedFileName, LoadedDocument) then
      AddDocumentTab(LoadedDocument, ResolvedFileName, False)
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
    ResetLineCurveState;
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
  HueValue: Double;
  SatValue: Double;
  ValValue: Double;
begin
  if FUpdatingColorSpins then Exit;
  FUpdatingColorSpins := True;
  try
    if FColorEditTarget = 0 then
      EditColor := FPrimaryColor
    else
      EditColor := FSecondaryColor;
    if Assigned(FColorPickButton) then
      FColorPickButton.ButtonColor := RGBToColor(EditColor.R, EditColor.G, EditColor.B);
    if Assigned(FColorRSpin) then FColorRSpin.Value := EditColor.R;
    if Assigned(FColorGSpin) then FColorGSpin.Value := EditColor.G;
    if Assigned(FColorBSpin) then FColorBSpin.Value := EditColor.B;
    if Assigned(FColorASpin) then FColorASpin.Value := EditColor.A;
    RGBToHSV(EditColor.R, EditColor.G, EditColor.B, HueValue, SatValue, ValValue);
    if Assigned(FColorHSpin) then FColorHSpin.Value := EnsureRange(Round(HueValue * 360.0), 0, 360);
    if Assigned(FColorSSpin) then FColorSSpin.Value := EnsureRange(Round(SatValue * 100.0), 0, 100);
    if Assigned(FColorVSpin) then FColorVSpin.Value := EnsureRange(Round(ValValue * 100.0), 0, 100);
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
  RefreshColorsPanel;
end;

procedure TMainForm.ColorHSVSpinChanged(Sender: TObject);
var
  EditColor: TRGBA32;
  NewColor: TRGBA32;
  HueValue: Double;
  SatValue: Double;
  ValValue: Double;
  NewR: Byte;
  NewG: Byte;
  NewB: Byte;
begin
  if FUpdatingColorSpins then Exit;
  if not Assigned(FColorHSpin) then Exit;
  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;

  HueValue := EnsureRange(FColorHSpin.Value, 0, 360) / 360.0;
  SatValue := EnsureRange(FColorSSpin.Value, 0, 100) / 100.0;
  ValValue := EnsureRange(FColorVSpin.Value, 0, 100) / 100.0;
  HSVToRGB(HueValue, SatValue, ValValue, NewR, NewG, NewB);
  NewColor := RGBA(NewR, NewG, NewB, EditColor.A);

  if FColorEditTarget = 0 then
    FPrimaryColor := NewColor
  else
    FSecondaryColor := NewColor;
  RefreshColorsPanel;
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
    RefreshColorsPanel;
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
  if FUpdatingToolOption then Exit;
  if not Assigned(FOpacitySpin) then Exit;
  FBrushOpacity := EnsureRange(FOpacitySpin.Value, 1, 100);
  RefreshCanvas;
end;

procedure TMainForm.HardnessSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FHardnessSpin) then Exit;
  FBrushHardness := EnsureRange(FHardnessSpin.Value, 1, 100);
  RefreshCanvas;
end;

procedure TMainForm.EraserShapeComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FEraserShapeCombo) then Exit;
  FEraserSquareShape := FEraserShapeCombo.ItemIndex = 1;
  RefreshCanvas;
end;

procedure TMainForm.SelModeComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FSelModeCombo) then Exit;
  FPendingSelectionMode := TSelectionCombineMode(FSelModeCombo.ItemIndex);
  RefreshCanvas;
end;

procedure TMainForm.ShapeStyleComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FShapeStyleCombo) then Exit;
  FShapeStyle := FShapeStyleCombo.ItemIndex;
  RefreshCanvas;
end;

procedure TMainForm.BucketModeComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FBucketModeCombo) then Exit;
  FBucketFloodMode := FBucketModeCombo.ItemIndex;
  RefreshCanvas;
end;

procedure TMainForm.FillSampleComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FFillSampleCombo) then Exit;
  FFillSampleSource := FFillSampleCombo.ItemIndex;
  RefreshCanvas;
end;

procedure TMainForm.WandSampleComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FWandSampleCombo) then Exit;
  FWandSampleSource := FWandSampleCombo.ItemIndex;
  RefreshCanvas;
end;

procedure TMainForm.WandContiguousChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FWandContiguousCheck) then Exit;
  FWandContiguous := FWandContiguousCheck.Checked;
  RefreshCanvas;
end;

procedure TMainForm.FillTolSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FFillTolSpin) then Exit;
  case FCurrentTool of
    tkRecolor:
      FWandTolerance := EnsureRange(FFillTolSpin.Value, 0, 255);
  else
    FFillTolerance := EnsureRange(FFillTolSpin.Value, 0, 255);
  end;
  RefreshCanvas;
end;

procedure TMainForm.GradientTypeComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FGradientTypeCombo) then Exit;
  FGradientType := FGradientTypeCombo.ItemIndex;
  RefreshCanvas;
end;

procedure TMainForm.GradientReverseChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FGradientReverseCheck) then Exit;
  FGradientReverse := FGradientReverseCheck.Checked;
  RefreshCanvas;
end;

procedure TMainForm.CloneAlignedChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FCloneAlignedCheck) then Exit;
  FCloneAligned := FCloneAlignedCheck.Checked;
  if not FCloneAligned then
    FCloneAlignedOffsetValid := False;
  RefreshCanvas;
end;

procedure TMainForm.RecolorPreserveValueChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FRecolorPreserveValueCheck) then Exit;
  FRecolorPreserveValue := FRecolorPreserveValueCheck.Checked;
  RefreshCanvas;
end;

procedure TMainForm.PickerSampleComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FPickerSampleCombo) then Exit;
  FPickerSampleSource := FPickerSampleCombo.ItemIndex;
  RefreshCanvas;
end;

procedure TMainForm.SelAntiAliasChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FSelAntiAliasCheck) then Exit;
  FSelAntiAlias := FSelAntiAliasCheck.Checked;
  RefreshCanvas;
end;

procedure TMainForm.SelFeatherSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FSelFeatherSpin) then Exit;
  FSelFeather := EnsureRange(FSelFeatherSpin.Value, 0, 128);
  RefreshCanvas;
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
  SyncImageMutationUI;
end;

end.
