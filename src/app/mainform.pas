unit MainForm;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, Grids,
  ComCtrls, Menus, Spin, Types, Clipbrd, FPColor, FPSurface, FPDocument, FPSelection,
  FPIO,
  FPToolControllers,
  FPPaletteHelpers, FPRulerHelpers, FPTextDialog, FPColorWheelHelpers, FPIconHelpers,
  FPUtilityHelpers, FPToolbarHelpers, FPI18n, FPMarqueeHelpers;

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
    FCanvasPadX: Integer;
    FCanvasPadY: Integer;
    FUpdatingCanvasSize: Boolean;
    FCenterOnNextCanvasUpdate: Boolean;
    FDisplayUnit: TDisplayUnit;
    FCurrentTool: TToolKind;
    FBrushSize: Integer;
    { Per-tool remembered option values }
    FToolSize: array[TToolKind] of Integer;
    FToolOpacity: array[TToolKind] of Integer;
    FToolHardness: array[TToolKind] of Integer;
    FWandTolerance: Integer;
    FPendingSelectionMode: TSelectionCombineMode;
    { 0=Outline, 1=Fill, 2=Outline+Fill }
    FShapeStyle: Integer;
    { 0=Solid, 1=Dashed }
    FShapeLineStyle: Integer;
    { 0=Contiguous, 1=Global }
    FBucketFloodMode: Integer;
    { 0=Current Layer, 1=All Layers }
    FWandSampleSource: Integer;
    { Persisted export options (all formats with backend-adjustable parameters). }
    FSaveSurfaceOptions: TSaveSurfaceOptions;
    FPrimaryColor: TRGBA32;
    FSecondaryColor: TRGBA32;
    FStrokeColor: TRGBA32;
    FPickSecondaryTarget: Boolean;
    FUpdatingToolOption: Boolean;
    FPointerDown: Boolean;
    FIsPanning: Boolean;
    FPointerButton: TMouseButton;
    FDragStart: TPoint;
    FShiftConstrain: Boolean;  { True while Shift is held during shape drag }
    FLineBezierMode: Boolean;
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
    FMarqueeDashPhase: Integer;
    FMarqueeLastTickMS: QWord;
    FMarqueeTimer: TTimer;
    FSelectionMarqueePoints: array of TPoint;
    FSelectionMarqueeContourOffsets: array of Integer;
    FSelectionMarqueeContourLengths: array of Integer;
    FSelectionMarqueeStepMap: array of Integer;
    FSelectionMarqueeCacheValid: Boolean;
    FSelectionMarqueeWidth: Integer;
    FSelectionMarqueeHeight: Integer;
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
    FOptionsBarPanel: TPanel;
    FToolIconImage: TImage;
    FToolNameLabel: TLabel;
    FChromeTitleLabel: TLabel;
    FWorkspacePanel: TPanel;
    FRulerTopBand: TPanel;
    FRulerCorner: TPanel;
    FToolsPanel: TPanel;
    FColorsPanel: TPanel;
    FHistoryPanel: TPanel;
    FRightPanel: TPanel;
    FToolButtons: array[TToolKind] of TSpeedButton;
    FUtilityButtons: array[TUtilityCommandKind] of TSpeedButton;
    FHorizontalRuler: TRulerView;
    FVerticalRuler: TRulerView;
    FCanvasHost: TScrollBox;
    FPaintBox: TCanvasView;
    FStatusBar: TPanel;
    FStatusLabels: array[0..6] of TLabel;
    FStatusProgressBar: TProgressBar;
    FStatusProgressLabel: TLabel;
    FStatusProgressActive: Boolean;
    FStatusDragLastUpdateMS: QWord;
    FStatusZoomTrack: TTrackBar;
    FStatusZoomLabel: TLabel;
    FLayerList: TDrawGrid;
    FHistoryList: TListBox;
    FColorPickButton: TColorButton;
    FActiveColorHexLabel: TLabel;
    FColorsValueLabel: TLabel;
    FBrushSpin: TSpinEdit;
    FTextFontButton: TButton;
    FTextAlignLabel: TLabel;
    FTextAlignCombo: TComboBox;
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
    FDeferredLayoutPassesRemaining: Integer;
    FLastScrollPosition: TPoint;
    FUpdatingZoomControl: Boolean;
    { Temporary-pan support }
    FPreviousTool: TToolKind;
    FTempToolActive: Boolean;
    { Test-only flag: instance was created via NewInstance, bypass inherited Destroy }
    FIsTestInstance: Boolean;

    { New tool and effect state }
    FLastEffectCaption: string;
    FLastEffectProc: TNotifyEvent;
    FRepeatLastEffectItem: TMenuItem;
    FCloneStampSource: TPoint;
    FCloneStampSampled: Boolean;
    FTextLastResult: TTextDialogResult;
    FInlineTextEdit: TMemo;
    FInlineTextAnchor: TPoint;
    FInlineTextColor: TRGBA32;
    FInlineTextCommitting: Boolean;
    FLayerBlendCombo: TComboBox;
    FLayerPropsButton: TSpeedButton;
    FLayerOpacitySpin: TSpinEdit;
    FLayerOpacityLabel: TLabel;
    FUpdatingLayerControls: Boolean;
    FCloneStampSnapshot: TRasterSurface;
    { Tool-session controllers extracted from mainform for A6 decomposition. }
    FStrokeController: TStrokeHistoryController;
    FMovePixelsController: TMovePixelsController;
    FSelectionController: TSelectionToolController;
    FStrokeTool: TToolKind;
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
    { Color wheel picker }
    FColorWheelBox: TPaintBox;
    FColorWheelBitmap: TBitmap;
    FColorSVBitmap: TBitmap;
    FColorSVCachedHue: Double;
    FColorSVRenderedHue: Double;
    FColorWheelDragMode: Integer;  { 0=none, 1=hue ring, 2=SV square }
    FColorExpandButton: TButton;
    FColorExpanded: Boolean;
    FColorDetailBox: TPaintBox;
    FColorDetailDragBar: Integer;  { -1=none, 0..6=R,G,B,H,S,V,A }
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
    FShapeLineStyleCombo: TComboBox;
    FShapeLineStyleLabel: TLabel;
    FLineBezierCheck: TCheckBox;
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
    { Gradient options }
    { 0=Linear, 1=Radial, 2=Conical, 3=Diamond }
    FGradientType: Integer;
    { 0=None, 1=Sawtooth, 2=Triangular }
    FGradientRepeatMode: Integer;
    FGradientReverse: Boolean;
    FGradientTypeCombo: TComboBox;
    FGradientTypeLabel: TLabel;
    FGradientRepeatCombo: TComboBox;
    FGradientRepeatLabel: TLabel;
    FGradientReverseCheck: TCheckBox;
    FCloneAligned: Boolean;
    FCloneAlignedCheck: TCheckBox;
    { Clone sample source: 0=Current Layer, 1=Image }
    FCloneSampleSource: Integer;
    FCloneSampleLabel: TLabel;
    FCloneSampleCombo: TComboBox;
    FRecolorPreserveValue: Boolean;
    FRecolorPreserveValueCheck: TCheckBox;
    FRecolorContiguous: Boolean;
    FRecolorContiguousCheck: TCheckBox;
    FRecolorSamplingMode: TRecolorSamplingMode;
    FRecolorSamplingLabel: TLabel;
    FRecolorSamplingCombo: TComboBox;
    FRecolorBlendMode: TRecolorBlendMode;
    FRecolorModeLabel: TLabel;
    FRecolorModeCombo: TComboBox;
    FRecolorStrokeSourceColor: TRGBA32;
    FRecolorStrokeSourceValid: Boolean;
    FRecolorStrokeSnapshot: TRasterSurface;
    FCloneAlignedOffset: TPoint;
    FCloneAlignedOffsetValid: Boolean;
    { Recolor tool tolerance (separate from FWandTolerance) }
    FRecolorTolerance: Integer;
    { Mosaic tool block size }
    FMosaicBlockSize: Integer;
    FMosaicBlockSpin: TSpinEdit;
    FMosaicBlockLabel: TLabel;
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
    FSelCornerRadius: Integer;
    FSelCornerRadiusLabel: TLabel;
    FSelCornerRadiusSpin: TSpinEdit;
    { Crop tool options }
    { 0=Free, 1=1:1, 2=4:3, 3=16:9, 4=Current Image }
    FCropAspectMode: Integer;
    { 0=None, 1=Rule of Thirds, 2=Center Cross }
    FCropGuideMode: Integer;
    FCropAspectLabel: TLabel;
    FCropAspectCombo: TComboBox;
    FCropGuideLabel: TLabel;
    FCropGuideCombo: TComboBox;
    { Rounded rectangle corner radius }
    FRoundedCornerRadius: Integer;
    FRoundedRadiusLabel: TLabel;
    FRoundedRadiusSpin: TSpinEdit;
    FLayerDragIndex: Integer;
    FLayerDragTargetIndex: Integer;
    FLayerLockClosedIcon: TPicture;
    FLayerLockOpenIcon: TPicture;
    FLayerEyeOnIcon: TPicture;
    FLayerEyeOffIcon: TPicture;
    FLayerRowLockHitRects: array of TRect;
    FLayerRowEyeHitRects: array of TRect;
    FMagnifyInstalled: Boolean;
    FAquaAppearanceApplied: Boolean;
    FScrollElasticityDisabled: Boolean;
    FScreenBackingScale: Integer;
    function ActivePaintColor: TRGBA32;
    function BackgroundToolColor: TRGBA32;
    function ColorForActiveTarget(AAlternate: Boolean = False): TRGBA32;
    function DisplayFileName: string;
    function CanvasToImage(X, Y: Integer): TPoint;
    function PointerViewportPointFromEvent(X, Y: Integer): TPoint;
    function BuildDisplaySurface: TRasterSurface;
    function ToolHintText: string;
    function ImageOriginInViewport: TPoint;
    function ActiveLayerLocalPoint(const APoint: TPoint): TPoint;
    function RecolorSourceAtPoint(const ACanvasPoint: TPoint; out AColor: TRGBA32): Boolean;
    function ConstrainCropPoint(const AOrigin, ACurrent: TPoint): TPoint;
    function DisplayUnitSuffix: string;
    function LocalizedAction(const AAction: string): string;
    function ApplyingActionText(const AAction: string): string;
    function PixelsToDisplayValue(APixels: Integer): Double;
    function FormatMeasurement(APixels: Integer): string;
    procedure ColorsBoxPaint(Sender: TObject);
    procedure ColorsBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorsBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ColorPickButtonChanged(Sender: TObject);
    procedure ColorSliderBoxPaint(Sender: TObject);
    procedure ColorSliderBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorSliderBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ColorSliderBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorWheelBoxPaint(Sender: TObject);
    procedure ColorWheelBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorWheelBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ColorWheelBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorExpandButtonClick(Sender: TObject);
    procedure ColorDetailBoxPaint(Sender: TObject);
    procedure ColorDetailBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorDetailBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ColorDetailBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RebuildColorWheelBitmaps;
    procedure ApplyColorDetailBarAt(X, Y: Integer);
    procedure SwatchBoxPaint(Sender: TObject);
    procedure SwatchBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure AppendLassoPoint(const APoint: TPoint);
    procedure ResetLineCurveSegmentState;
    procedure ResetLineCurveState;
    procedure CommitPendingLineSegment(AContinuePath: Boolean);
    procedure InitializeTextToolDefaults;
    function RunSystemTextFontDialog: Boolean;
    procedure UpdateInlineTextEditStyle;
    procedure UpdateInlineTextEditBounds;
    procedure BeginInlineTextEdit(const APoint: TPoint);
    procedure CommitInlineTextEdit(ACommit: Boolean = True);
    procedure InitializeMinimalState;
    procedure InvalidatePreparedBitmap;
    procedure InvalidateSelectionMarqueeCache;
    procedure EnsureSelectionMarqueeCache;
    procedure RebuildSelectionMarqueeCache;
    procedure RefreshAuxiliaryImageViews(ARefreshLayers: Boolean = False);
    procedure ResetTransientCanvasState;
    procedure SyncSelectionOverlayUI(AMarkDirty: Boolean = True);
    procedure SyncImageMutationUI(ARefreshLayers: Boolean = False; AMarkDirty: Boolean = True);
    procedure SyncDocumentReplacementUI(AMarkDirty: Boolean);
    procedure BeginStatusProgress(const ACaption: string);
    procedure UpdateStatusProgress(APercent: Integer; const ACaption: string = '');
    procedure EndStatusProgress;
    procedure AutoDeselectSelection(const AReason: string);
    procedure MaybeAutoDeselectOnToolSwitch(AOldTool, ANewTool: TToolKind);
    function ShouldAutoDeselectFromBlankClick(
      const APoint: TPoint;
      AButton: TMouseButton;
      AShift: TShiftState
    ): Boolean;
    procedure UpdateToolOptionControl;
    procedure LayoutOptionRow;
    procedure SyncToolButtonSelection;
    procedure SyncUtilityButtonStates;
    procedure ButtonIconOverlayClick(Sender: TObject);
    function FindButtonIconOverlay(AButton: TSpeedButton): TImage;
    procedure PositionButtonIconOverlay(
      AButton: TSpeedButton;
      AIconImage: TImage;
      AContext: TButtonIconContext
    );
    procedure RealignButtonIconOverlay(
      AButton: TSpeedButton;
      AContext: TButtonIconContext
    );
    procedure RelayoutButtonIconOverlays;
    procedure RelayoutTopChrome;
    procedure EnsureLayerRowIcons;
    procedure DrawLayerRowIcon(
      ACanvas: TCanvas;
      const ARect: TRect;
      AIcon: TPicture
    );
    function AttachButtonIconOverlay(
      AButton: TSpeedButton;
      const ACaption: string;
      AContext: TButtonIconContext;
      ABackgroundColor: TColor
    ): Boolean;
    procedure RefreshUnitsMenu;
    procedure BuildMenus;
    procedure BuildTabPopupMenu;
    procedure BuildToolbar;
    procedure BuildSidePanel;
    function CreateButton(const ACaption: string; ALeft, ATop, AWidth: Integer; AHandler: TNotifyEvent; AParent: TWinControl; ATag: Integer = 0; AIconContext: TButtonIconContext = bicAuto): TSpeedButton;
    procedure CreateMenuItem(AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent; AShortcut: TShortCut = 0);
    procedure PaintCanvasTo(ACanvas: TCanvas; const ARect: TRect);
    function ShouldAnimateMarqueeNow: Boolean;
    procedure UpdateMarqueeAnimationState;
    procedure MarqueeTimerTick(Sender: TObject);
    procedure DrawBrushHoverOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
    procedure DrawSquareHoverOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
    procedure DrawEraserHoverOverlay(
      ACanvas: TCanvas;
      const APoint: TPoint;
      ARadius: Integer;
      ASquareShape: Boolean
    );
    procedure DrawPointHoverOverlay(ACanvas: TCanvas; const APoint: TPoint);
    procedure DrawCloneLinkOverlay(ACanvas: TCanvas; const ASourcePoint, ADestPoint: TPoint);
    procedure DrawSelectionMarqueeOverlay(ACanvas: TCanvas);
    procedure DrawMarqueeRectangleOverlay(ACanvas: TCanvas; ALeft, ATop, ARight, ABottom: Integer);
    procedure DrawMarqueeEllipseOverlay(ACanvas: TCanvas; ALeft, ATop, ARight, ABottom: Integer);
    procedure DrawMarqueePolylineOverlay(ACanvas: TCanvas; const APoints: array of TPoint; AClosePath: Boolean);
    procedure DrawCloneSourceOverlay(ACanvas: TCanvas; const APoint: TPoint; ARadius: Integer);
    procedure DrawQuadraticCurvePreview(ACanvas: TCanvas; const AStartPoint, AControlPoint, AEndPoint: TPoint; AStrokeColor: TColor; AStrokeWidth: Integer);
    procedure DrawCubicCurvePreview(ACanvas: TCanvas; const AStartPoint, AControlPoint1, AControlPoint2, AEndPoint: TPoint; AStrokeColor: TColor; AStrokeWidth: Integer);
    procedure RenderMovePixelsTransactionPreview(ASurface: TRasterSurface);
    procedure DrawHoverToolOverlay(ACanvas: TCanvas);
    function ActiveToolOverlayRadius: Integer;
    function TryGetCloneOverlaySourcePoint(out APoint: TPoint): Boolean;
    function TrySelectionMarqueePixelColor(X, Y: Integer; out AColor: TRGBA32): Boolean;
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
    function PaletteRootForControl(AControl: TControl): TControl;
    function ControlBelongsToPalette(AControl, APalette: TControl): Boolean;
    function PointRelativeToControl(AControl, ATarget: TControl; const APoint: TPoint): TPoint;
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
    procedure PublishSurfaceToSystemClipboard(ASurface: TRasterSurface; const AOffset: TPoint);
    function TryLoadSurfaceFromSystemClipboard(out ASurface: TRasterSurface; out AOffset: TPoint): Boolean;
    function TryResolvePasteSurface(out ASurface: TRasterSurface; out AOffset: TPoint): Boolean;
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
    procedure ToggleLayerLockClick(Sender: TObject);
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
    procedure OpenFileInCurrentTab(const AFileName: string);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
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
    procedure ShapeLineStyleComboChanged(Sender: TObject);
    procedure LineBezierChanged(Sender: TObject);
    procedure BucketModeComboChanged(Sender: TObject);
    procedure FillSampleComboChanged(Sender: TObject);
    procedure WandSampleComboChanged(Sender: TObject);
    procedure WandContiguousChanged(Sender: TObject);
    procedure FillTolSpinChanged(Sender: TObject);
    procedure GradientTypeComboChanged(Sender: TObject);
    procedure GradientRepeatComboChanged(Sender: TObject);
    procedure GradientReverseChanged(Sender: TObject);
    procedure CloneAlignedChanged(Sender: TObject);
    procedure CloneSampleComboChanged(Sender: TObject);
    procedure RecolorPreserveValueChanged(Sender: TObject);
    procedure RecolorContiguousChanged(Sender: TObject);
    procedure RecolorSamplingModeChanged(Sender: TObject);
    procedure RecolorModeChanged(Sender: TObject);
    procedure MosaicBlockSpinChanged(Sender: TObject);
    procedure PickerSampleComboChanged(Sender: TObject);
    procedure SelAntiAliasChanged(Sender: TObject);
    procedure SelFeatherSpinChanged(Sender: TObject);
    procedure SelCornerRadiusSpinChanged(Sender: TObject);
    procedure CropAspectComboChanged(Sender: TObject);
    procedure CropGuideComboChanged(Sender: TObject);
    procedure RoundedRadiusSpinChanged(Sender: TObject);
    procedure TextAlignComboChanged(Sender: TObject);
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
    procedure AboutClick(Sender: TObject);
    procedure RefreshLocalizedUI;
    procedure HelpClick(Sender: TObject);
    procedure TogglePaletteViewClick(Sender: TObject);
    procedure ResetPaletteLayoutClick(Sender: TObject);
    procedure HidePaletteClick(Sender: TObject);
    procedure ToolButtonClick(Sender: TObject);
    procedure ToolComboChange(Sender: TObject);
    procedure SyncToolComboSelection;
    procedure ZoomComboChange(Sender: TObject);
    procedure StatusZoomTrackChange(Sender: TObject);
    procedure HistoryListClick(Sender: TObject);
    procedure HistoryListDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure CanvasHostResize(Sender: TObject);
    procedure BrushSizeChanged(Sender: TObject);
    procedure TextFontButtonClick(Sender: TObject);
    procedure LayerListClick(Sender: TObject);
    procedure LayerListDblClick(Sender: TObject);
    procedure LayerListMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LayerListMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure LayerListMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LayerListDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
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
    procedure FormResize(Sender: TObject);
    { Stroke history helpers }
    function StrokeRectIsEmpty(const ARect: TRect): Boolean;
    function StrokeBoundsForSegment(const AFrom, ATo: TPoint; ARadius: Integer): TRect;
    procedure CaptureStrokeBeforeRect(const ARect: TRect);
    procedure ClearStrokeHistoryState;
    function HasPendingStrokeHistory: Boolean;
    procedure SealPendingStrokeHistory;
    procedure BeginStrokeHistory;
    procedure ExpandStrokeDirty(const APoint: TPoint);
    procedure CommitStrokeHistory(const ALabel: string);
    procedure ClearMovePixelsTransactionState;
    procedure BeginMovePixelsTransaction;
    procedure UpdateMovePixelsTransaction(DeltaX, DeltaY: Integer);
    procedure CommitMovePixelsTransaction;
    procedure CancelMovePixelsTransaction;
  public
    { Public constructor / destructor }
    constructor Create(TheOwner: TComponent); override;
    class function CreateForTesting: TMainForm; static;
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
    procedure SimulateMagnifyGestureForTest(AMagnification: Double; ALocationX, ALocationY: Double);
    procedure SimulateToolButtonSwitch(ATool: TToolKind);
    procedure SetPrimaryColorForTest(const AColor: TRGBA32);
    procedure SetSecondaryColorForTest(const AColor: TRGBA32);
    procedure SetRecolorOptionsForTest(
      ASamplingMode: TRecolorSamplingMode;
      ABlendMode: TRecolorBlendMode;
      ATolerance: Integer;
      APreserveValue: Boolean;
      AContiguous: Boolean = False
    );
    procedure SetCloneOptionsForTest(AAligned: Boolean; ASampleSource: Integer);
    procedure SetCropOptionsForTest(AAspectMode, AGuideMode: Integer);
    function CloneSnapshotPixelForTest(X, Y: Integer; out APixel: TRGBA32): Boolean;
    procedure SetBrushSizeForTest(ASize: Integer);
    procedure SetShapeLineStyleForTest(AStyleIndex: Integer);
    property CurrentToolForTest: TToolKind read FCurrentTool write FCurrentTool;
    property TestDocument: TImageDocument read FDocument;
    property ZoomScaleForTest: Double read FZoomScale;
    property RenderRevisionForTest: QWord read FRenderRevision;
    property TempToolActiveForTest: Boolean read FTempToolActive;
    property DirtyForTest: Boolean read FDirty;
    function DisplayPixelForTest(X, Y: Integer): TRGBA32;
    procedure MakeTestSafe; { lightweight test-mode initialization }
  end;

var
  AppMainForm: TMainForm;

implementation

uses
  Math, LCLType, LCLIntf, Printers, FPNativeIO, FPLCLBridge, FPUIHelpers, FPColorWheel,
  FPNewImageDialog, FPResizeDialog, FPSettingsDialog, FPZoomHelpers,
  FPViewHelpers, FPViewportHelpers, FPStatusHelpers, FPHueSaturationDialog,
  FPLevelsDialog, FPBrightnessContrastDialog, FPCurvesDialog, FPPosterizeDialog,
  FPBlurDialog, FPNoiseDialog, FPExportDialog, FPEffectDialog, FPFileMenuHelpers, FPTabHelpers,
  FPTextRenderer, FPLayerPropertiesDialog, FPShortcutHelpers, FPClipboardHelpers,
  FPAboutDialog, FPMenuHelpers, FPAppMenuBridge,
  FPCGRenderBridge,
  FPMagnifyBridge, FPAlphaBridge, FPScrollViewBridge,
  FPListBgBridge, FPAppearanceBridge;

const
  DisplayDPI = 96.0;
  FlatPaintClipboardMetaFormatName = 'com.flatpaint.surface-meta.v1';
  ToolbarLargeCommandCaptionPrefix = '         '; { reserve icon lane for 20px overlay }
  ToolbarLargeCommandIconLeft = 6;
  ToolbarLargeCommandMaxIconSize = 20;
  LayerRowIconSize = 16;
  LayerRowHeight = 36;
  LayerColLockWidth = 28;
  LayerColEyeWidth = 28;
  LayerColThumbWidth = 52;
  LayerColNameMinWidth = 80;
  LayerCellPadX = 4;

procedure LayerGridApplyColumnWidths(AGrid: TDrawGrid);
var
  Remaining: Integer;
begin
  if not Assigned(AGrid) or (AGrid.ColCount < 4) then
    Exit;
  AGrid.ColWidths[0] := LayerColLockWidth;
  AGrid.ColWidths[1] := LayerColEyeWidth;
  AGrid.ColWidths[2] := LayerColThumbWidth;
  Remaining := AGrid.ClientWidth - (LayerColLockWidth + LayerColEyeWidth + LayerColThumbWidth);
  AGrid.ColWidths[3] := Max(LayerColNameMinWidth, Remaining);
end;

function LayerGridRowAtY(AGrid: TDrawGrid; AY: Integer): Integer;
var
  RowOffset: Integer;
begin
  if not Assigned(AGrid) then
    Exit(-1);
  if AY < 0 then
    Exit(-1);
  if AY >= AGrid.ClientHeight then
    Exit(-1);
  RowOffset := AY div Max(1, AGrid.DefaultRowHeight);
  Result := AGrid.TopRow + RowOffset;
  if (Result < 0) or (Result >= AGrid.RowCount) then
    Result := -1;
end;

function LayerGridCenteredIconRect(const ACellRect: TRect): TRect;
var
  IconLeft: Integer;
  IconTop: Integer;
begin
  IconLeft := ACellRect.Left + ((ACellRect.Right - ACellRect.Left - LayerRowIconSize) div 2);
  IconTop := ACellRect.Top + ((ACellRect.Bottom - ACellRect.Top - LayerRowIconSize) div 2);
  Result := Rect(
    IconLeft,
    IconTop,
    IconLeft + LayerRowIconSize,
    IconTop + LayerRowIconSize
  );
end;

procedure FPMagnifyCallbackProc(AContext: Pointer; AMagnification: Double;
  ALocationX, ALocationY: Double); cdecl;
var
  MainForm: TMainForm;
  NewScale: Double;
  VP: TPoint;
begin
  if not Assigned(AContext) then
    Exit;
  MainForm := TMainForm(AContext);
  { magnification is a delta: +0.02 means 2% zoom in per event }
  NewScale := MainForm.FZoomScale * (1.0 + AMagnification);
  if Assigned(MainForm.FCanvasHost) then
    VP := Point(Round(ALocationX), MainForm.FCanvasHost.ClientHeight - Round(ALocationY))
  else
    VP := Point(Round(ALocationX), Round(ALocationY));
  MainForm.ApplyZoomScaleAtViewportPoint(NewScale, VP);
end;

constructor TCanvasView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  { DoubleBuffered removed — Cocoa views are already layer-backed. }
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

procedure TMainForm.InitializeMinimalState;
var
  LoopTool: TToolKind;
begin
  { When created via NewInstance (test path), skip inherited TForm property
    setters (Caption, Width, Height, etc.) which may call into an
    uninitialised LCL/Cocoa widgetset.  Only set our own fields. }
  if not FIsTestInstance then
  begin
    Caption := 'FlatPaint (test)';
    Width := 1360;
    Height := 900;
    Position := poScreenCenter;
    DoubleBuffered := True;
    KeyPreview := True;
  end;

  FPrimaryColor := RGBA(0, 0, 0, 255);
  FSecondaryColor := RGBA(255, 255, 255, 255);
  FStrokeColor := FPrimaryColor;
  FZoomScale := 1.0;
  FDisplayUnit := duPixels;
  FCurrentTool := DefaultStartupTool;
  FStrokeTool := FCurrentTool;
  FPointerButton := mbLeft;
  FBrushSize := 8;
  FWandTolerance := 32;
  FBrushOpacity := 100;
  FBrushHardness := 100;
  for LoopTool := Low(TToolKind) to High(TToolKind) do
  begin
    FToolSize[LoopTool] := FBrushSize;
    FToolOpacity[LoopTool] := FBrushOpacity;
    FToolHardness[LoopTool] := FBrushHardness;
  end;
  { Pen-like pencil default: thinnest + fully hard-edged. }
  FToolSize[tkPencil] := 1;
  { Keep brush/eraser clearly distinct out of box. }
  FToolHardness[tkPencil] := 100;
  FToolHardness[tkBrush] := 72;
  FToolHardness[tkEraser] := 88;
  FBrushHardness := FToolHardness[FCurrentTool];
  FStrokeTool := FCurrentTool;
  FEraserSquareShape := False;
  FShapeStyle := 0;
  FShapeLineStyle := 0;
  FGradientType := 0;
  FGradientRepeatMode := 0;
  FGradientReverse := False;
  FCloneAligned := True;
  FCloneSampleSource := 0;
  FFillSampleSource := 0;
  FWandSampleSource := 0;
  FWandContiguous := True;
  FFillTolerance := 8;
  FPickerSampleSource := 0;
  FSelAntiAlias := True;
  FSelFeather := 0;
  FSelCornerRadius := 0;
  FCropAspectMode := 0;
  FCropGuideMode := 1;
  FRoundedCornerRadius := 16;
  FTextLastResult.Text := '';
  FTextLastResult.FontName := '';
  FTextLastResult.FontSize := 24;
  FTextLastResult.Bold := False;
  FTextLastResult.Italic := False;
  FTextLastResult.Alignment := 0;
  FRenderRevision := 1;
  FPreparedRevision := 0;
  FMarqueeDashPhase := 0;
  FMarqueeLastTickMS := 0;
  FSelectionMarqueeCacheValid := False;
  FSelectionMarqueeWidth := 0;
  FSelectionMarqueeHeight := 0;
  SetLength(FSelectionMarqueePoints, 0);
  SetLength(FSelectionMarqueeContourOffsets, 0);
  SetLength(FSelectionMarqueeContourLengths, 0);
  SetLength(FSelectionMarqueeStepMap, 0);
  FStatusProgressActive := False;
  FStatusDragLastUpdateMS := 0;
  FColorSVCachedHue := -1.0;
  FColorSVRenderedHue := -1.0;

  FScreenBackingScale := Max(1, Round(FPGetScreenBackingScale));
  FDocument := TImageDocument.Create(1024 * FScreenBackingScale, 768 * FScreenBackingScale);
  SetLength(FTabDocuments, 1);
  FNewImageResolutionDPI := 96.0;
  FShowPixelGrid := False;
  FShowRulers := True;
  FDeferredLayoutPass := True;
  FDeferredLayoutPassesRemaining := 3;
  FLastScrollPosition := Point(0, 0);
  FMagnifyInstalled := False;
  FAquaAppearanceApplied := False;
  FScrollElasticityDisabled := False;
  FActiveColorSlider := -1;
  FTabPressedIndex := -1;
  FTabDragOrigin := Point(0, 0);
  FTabDragging := False;
  FLayerDragIndex := -1;
  FLayerDragTargetIndex := -1;
  FStrokeController := TStrokeHistoryController.Create;
  FMovePixelsController := TMovePixelsController.Create;
  FSelectionController := TSelectionToolController.Create;
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
  LoopTool: TToolKind;
begin
  inherited Create(TheOwner);
  { If there is no LCL Application available (headless test run), avoid
    constructing full UI controls which may call into an uninitialized
    widgetset. Create only the minimal objects the tests and core logic
    expect. }
  if not Assigned(Application) then
  begin
    InitializeMinimalState;
    Exit;
  end;
  LoadLanguagePreference;
  Caption := 'FlatPaint';
  Width := 1360;
  Height := 900;
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 480;
  Position := poScreenCenter;
  DoubleBuffered := True;
  KeyPreview := True;
  OnKeyDown := @FormKeyDown;
  OnKeyUp := @FormKeyUp;
  OnCloseQuery := @FormCloseQuery;
  OnResize := @FormResize;
  AllowDropFiles := True;
  OnDropFiles := @FormDropFiles;

  FPrimaryColor := RGBA(0, 0, 0, 255);
  FSecondaryColor := RGBA(255, 255, 255, 255);
  FStrokeColor := FPrimaryColor;
  FZoomScale := 1.0;
  FDisplayUnit := duPixels;
  FCurrentTool := DefaultStartupTool;
  FStrokeTool := FCurrentTool;
  FPointerButton := mbLeft;
  FBrushSize := 8;
  FWandTolerance := 32;
  FBrushOpacity := 100;
  FBrushHardness := 100;
  for LoopTool := Low(TToolKind) to High(TToolKind) do
  begin
    FToolSize[LoopTool] := FBrushSize;
    FToolOpacity[LoopTool] := FBrushOpacity;
    FToolHardness[LoopTool] := FBrushHardness;
  end;
  { Pen-like pencil default: thinnest + fully hard-edged. }
  FToolSize[tkPencil] := 1;
  { Keep brush/eraser clearly distinct out of box. }
  FToolHardness[tkPencil] := 100;
  FToolHardness[tkBrush] := 72;
  FToolHardness[tkEraser] := 88;
  FBrushHardness := FToolHardness[FCurrentTool];
  FStrokeTool := FCurrentTool;
  FEraserSquareShape := False;
  FShapeStyle := 0;
  FShapeLineStyle := 0;
  FBucketFloodMode := 0;
  FLineBezierMode := False;
  FLinePathOpen := False;
  FLineCurvePending := False;
  FLineCurveSecondStage := False;
  FLineCurveEndPoint := Point(0, 0);
  FLineCurveControlPoint := Point(0, 0);
  FLineCurveControlPoint2 := Point(0, 0);
  FFillSampleSource := 0;
  FWandSampleSource := 0;
  FWandContiguous := True;
  FSaveSurfaceOptions := DefaultSaveSurfaceOptions;
  FFillTolerance := 8;
  FGradientType := 0;
  FGradientRepeatMode := 0;
  FGradientReverse := False;
  FCloneAligned := True;
  FCloneSampleSource := 0;
  FRecolorPreserveValue := True;
  FRecolorContiguous := False;
  FRecolorSamplingMode := rsmOnce;
  FRecolorBlendMode := rbmColor;
  FRecolorStrokeSourceColor := FPrimaryColor;
  FRecolorStrokeSourceValid := False;
  FRecolorTolerance := 32;
  FMosaicBlockSize := 10;
  FCloneAlignedOffset := Point(0, 0);
  FCloneAlignedOffsetValid := False;
  FPickerSampleSource := 0;
  FSelAntiAlias := True;
  FSelFeather := 0;
  FSelCornerRadius := 0;
  FCropAspectMode := 0;
  FCropGuideMode := 1;
  FRoundedCornerRadius := 16;
  FTextLastResult.Text := '';
  FTextLastResult.FontName := '';
  FTextLastResult.FontSize := 24;
  FTextLastResult.Bold := False;
  FTextLastResult.Italic := False;
  FTextLastResult.Alignment := 0;
  FInlineTextEdit := nil;
  FInlineTextAnchor := Point(0, 0);
  FInlineTextColor := FPrimaryColor;
  FInlineTextCommitting := False;
  FClipboardOffset := Point(0, 0);
  FPreparedBitmap := TBitmap.Create;
  FRenderRevision := 1;
  FPreparedRevision := 0;
  FStatusProgressActive := False;

  { Create default document at a size appropriate for the display.
    On Retina (2x) screens, use 2048x1536 so one document pixel maps to
    one physical pixel at 100 percent zoom.  On standard displays, keep 1024x768. }
  FScreenBackingScale := Max(1, Round(FPGetScreenBackingScale));
  FDocument := TImageDocument.Create(1024 * FScreenBackingScale, 768 * FScreenBackingScale);
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
  FDeferredLayoutPassesRemaining := 3;
  FLastScrollPosition := Point(0, 0);
  FActiveColorSlider := -1;
  FTabPressedIndex := -1;
  FTabDragOrigin := Point(0, 0);
  FTabDragging := False;
  FLayerDragIndex := -1;
  FLayerDragTargetIndex := -1;
  FStrokeController := TStrokeHistoryController.Create;
  FMovePixelsController := TMovePixelsController.Create;
  FSelectionController := TSelectionToolController.Create;

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

  FMarqueeTimer := TTimer.Create(Self);
  FMarqueeTimer.Enabled := False;
  { Keep smooth cadence and tune apparent speed via phase step so motion
    stays fluid while avoiding abrupt/over-fast ant travel. }
  FMarqueeTimer.Interval := 18;
  FMarqueeTimer.OnTimer := @MarqueeTimerTick;

  FInlineTextEdit := TMemo.Create(FCanvasHost);
  FInlineTextEdit.Parent := FCanvasHost;
  FInlineTextEdit.Visible := False;
  FInlineTextEdit.ScrollBars := ssNone;
  FInlineTextEdit.WordWrap := False;
  FInlineTextEdit.WantReturns := True;
  FInlineTextEdit.WantTabs := False;
  FInlineTextEdit.AutoSize := False;
  FInlineTextEdit.Left := FPaintBox.Left;
  FInlineTextEdit.Top := FPaintBox.Top;
  FInlineTextEdit.Width := 128;
  FInlineTextEdit.Height := 56;
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
  FStatusZoomLabel.Hint := TR('Click to toggle between Fit and Actual Size', '点击切换“适合窗口”和“实际大小”');
  FStatusZoomLabel.ShowHint := True;
  FStatusZoomLabel.OnClick := @StatusZoomToggleClick;
  LayoutStatusBarControls(nil);
  RestorePaletteLayout;
  RefreshPaletteMenuChecks;

  FCenterOnNextCanvasUpdate := True;
  FitDocumentToViewport(True);
  UpdateCanvasSize;
  RefreshLayers;
  RefreshCanvas;
  RefreshStatus(Point(-1, -1));
  UpdateCaption;
  RefreshRulers;
  RefreshTabStrip;
  if Assigned(Application) then
    Application.AddOnIdleHandler(@AppIdle);
end;

class function TMainForm.CreateForTesting: TMainForm;
var
  P: Pointer;
begin
  { Bypass all LCL constructors (TForm.Create, TWinControl.Create, etc.)
    which attempt to allocate Cocoa native handles that crash in headless
    test environments.  Raw GetMem + FillChar + VMT-set gives us a cleanly
    zeroed object whose data-model fields we then initialise via
    InitializeMinimalState. }
  P := GetMem(TMainForm.InstanceSize);
  FillChar(P^, TMainForm.InstanceSize, 0);
  PPointer(P)^ := Pointer(TMainForm);
  Result := TMainForm(P);
  Result.FIsTestInstance := True;
  Result.InitializeMinimalState;
end;

destructor TMainForm.Destroy;
var
  I: Integer;
begin
  if FMagnifyInstalled and Assigned(FCanvasHost) and FCanvasHost.HandleAllocated then
    FPUninstallMagnifyHandler(Pointer(FCanvasHost.Handle));
  FMagnifyInstalled := False;
  FreeAndNil(FMarqueeTimer);
  if Assigned(Application) then
    Application.RemoveOnIdleHandler(@AppIdle);
  FreeAndNil(FRecentFiles);
  FreeAndNil(FPreparedBitmap);
  FreeAndNil(FDisplaySurface);
  FreeAndNil(FClipboardSurface);
  FreeAndNil(FLayerLockClosedIcon);
  FreeAndNil(FLayerLockOpenIcon);
  FreeAndNil(FLayerEyeOnIcon);
  FreeAndNil(FLayerEyeOffIcon);
  FreeAndNil(FCloneStampSnapshot);
  FreeAndNil(FRecolorStrokeSnapshot);
  FreeAndNil(FSelectionController);
  FreeAndNil(FMovePixelsController);
  FreeAndNil(FStrokeController);
  ClearStrokeHistoryState;
  FreeAndNil(FColorWheelBitmap);
  FreeAndNil(FColorSVBitmap);
  { Free all tab documents (FDocument just refers to FTabDocuments[FActiveTabIndex]) }
  for I := 0 to Length(FTabDocuments) - 1 do
    FTabDocuments[I].Free;
  SetLength(FTabDocuments, 0);
  FDocument := nil;
  { Test instances were created via NewInstance (no inherited constructor ran),
    so calling inherited Destroy would crash on uninitialised LCL state. }
  if not FIsTestInstance then
    inherited Destroy;
end;

function TMainForm.ActivePaintColor: TRGBA32;
begin
  if FCurrentTool = tkEraser then
    Exit(TransparentColor);
  Result := FStrokeColor;
end;

function TMainForm.BackgroundToolColor: TRGBA32;
begin
  Result := RGBA(FSecondaryColor.R, FSecondaryColor.G, FSecondaryColor.B, 255);
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
    Result := TR('Untitled', '未命名')
  else
    Result := ExtractFileName(FCurrentFileName);
end;

function TMainForm.CanvasToImage(X, Y: Integer): TPoint;
begin
  Result.X := EnsureRange(Trunc((X - FCanvasPadX) / FZoomScale), 0, FDocument.Width - 1);
  Result.Y := EnsureRange(Trunc((Y - FCanvasPadY) / FZoomScale), 0, FDocument.Height - 1);
end;

function TMainForm.PointerViewportPointFromEvent(X, Y: Integer): TPoint;
var
  ScreenPoint: TPoint;
begin
  if Assigned(FCanvasHost) and FCanvasHost.HandleAllocated then
  begin
    if Assigned(FPaintBox) and FPaintBox.HandleAllocated then
      ScreenPoint := FPaintBox.ClientToScreen(Point(X, Y))
    else
      ScreenPoint := Mouse.CursorPos;
    Exit(FCanvasHost.ScreenToClient(ScreenPoint));
  end;
  Result := Point(X, Y);
end;

function TMainForm.ActiveLayerLocalPoint(const APoint: TPoint): TPoint;
begin
  if (FDocument = nil) or (FDocument.LayerCount <= 0) then
    Exit(APoint);
  Result := Point(
    APoint.X - FDocument.ActiveLayer.OffsetX,
    APoint.Y - FDocument.ActiveLayer.OffsetY
  );
end;

function TMainForm.RecolorSourceAtPoint(const ACanvasPoint: TPoint; out AColor: TRGBA32): Boolean;
var
  LocalPoint: TPoint;
begin
  Result := False;
  AColor := ColorForActiveTarget(not FPickSecondaryTarget);
  if (FDocument = nil) or (FDocument.LayerCount <= 0) then
    Exit;
  LocalPoint := ActiveLayerLocalPoint(ACanvasPoint);
  if Assigned(FRecolorStrokeSnapshot) and
     FRecolorStrokeSnapshot.InBounds(LocalPoint.X, LocalPoint.Y) then
  begin
    AColor := Unpremultiply(FRecolorStrokeSnapshot[LocalPoint.X, LocalPoint.Y]);
    Exit(True);
  end;
  if not FDocument.ActiveLayer.Surface.InBounds(LocalPoint.X, LocalPoint.Y) then
    Exit;
  AColor := Unpremultiply(FDocument.ActiveLayer.Surface[LocalPoint.X, LocalPoint.Y]);
  Result := True;
end;

function TMainForm.ConstrainCropPoint(const AOrigin, ACurrent: TPoint): TPoint;
var
  DeltaX: Integer;
  DeltaY: Integer;
  SignX: Integer;
  SignY: Integer;
  RatioW: Integer;
  RatioH: Integer;
  AbsDX: Integer;
  AbsDY: Integer;
  TargetDX: Integer;
  TargetDY: Integer;
begin
  Result := ACurrent;
  if FCropAspectMode <= 0 then
    Exit;

  case FCropAspectMode of
    1:
      begin
        RatioW := 1;
        RatioH := 1;
      end;
    2:
      begin
        RatioW := 4;
        RatioH := 3;
      end;
    3:
      begin
        RatioW := 16;
        RatioH := 9;
      end;
  else
    begin
      if (FDocument = nil) or (FDocument.Width <= 0) or (FDocument.Height <= 0) then
        Exit;
      RatioW := FDocument.Width;
      RatioH := FDocument.Height;
    end;
  end;

  if (RatioW <= 0) or (RatioH <= 0) then
    Exit;

  DeltaX := ACurrent.X - AOrigin.X;
  DeltaY := ACurrent.Y - AOrigin.Y;
  if (DeltaX = 0) and (DeltaY = 0) then
    Exit;

  if DeltaX < 0 then SignX := -1 else SignX := 1;
  if DeltaY < 0 then SignY := -1 else SignY := 1;
  AbsDX := Abs(DeltaX);
  AbsDY := Abs(DeltaY);

  if (AbsDX * RatioH) >= (AbsDY * RatioW) then
  begin
    TargetDX := Max(1, AbsDX);
    TargetDY := Max(1, Round(TargetDX * RatioH / RatioW));
  end
  else
  begin
    TargetDY := Max(1, AbsDY);
    TargetDX := Max(1, Round(TargetDY * RatioW / RatioH));
  end;

  Result := Point(
    AOrigin.X + (SignX * TargetDX),
    AOrigin.Y + (SignY * TargetDY)
  );
end;

function TMainForm.BuildDisplaySurface: TRasterSurface;
var
  CompositeSurface: TRasterSurface;
  OwnsCompositeSurface: Boolean;
  X: Integer;
  Y: Integer;
  TileColor: TRGBA32;
  CheckerDark: TRGBA32;
  CheckerLight: TRGBA32;
  PixelColor: TRGBA32;
  PixelIndex: Integer;
  BacktrackIndex: Integer;
  NeighborIndex: Integer;
  ContourCount: Integer;
  ContourCapacity: Integer;
  TraceGuard: Integer;
  StartPoint: TPoint;
  CurrentPoint: TPoint;
  NextPoint: TPoint;
  BacktrackPoint: TPoint;
  StartBacktrackPoint: TPoint;
  NeighborFound: Boolean;
  DashIndex: Integer;
  SelectionMask: array of Byte;
  BoundaryMask: array of Byte;
  BoundaryVisited: array of Byte;
  BoundaryContour: array of TPoint;
const
  NeighborDX: array[0..7] of Integer = (-1, 0, 1, 1, 1, 0, -1, -1);
  NeighborDY: array[0..7] of Integer = (-1, -1, -1, 0, 1, 1, 1, 0);

  function SelectionIndex(AX, AY: Integer): Integer; inline;
  begin
    Result := AY * FDisplaySurface.Width + AX;
  end;

  function SelectionInside(AX, AY: Integer): Boolean; inline;
  begin
    if (AX < 0) or (AX >= FDisplaySurface.Width) or
       (AY < 0) or (AY >= FDisplaySurface.Height) then
      Exit(False);
    Result := SelectionMask[SelectionIndex(AX, AY)] <> 0;
  end;

  function BoundaryAt(AX, AY: Integer): Boolean; inline;
  begin
    if (AX < 0) or (AX >= FDisplaySurface.Width) or
       (AY < 0) or (AY >= FDisplaySurface.Height) then
      Exit(False);
    Result := BoundaryMask[SelectionIndex(AX, AY)] <> 0;
  end;

  function NeighborDeltaIndex(ADX, ADY: Integer): Integer;
  var
    Index: Integer;
  begin
    for Index := 0 to 7 do
      if (NeighborDX[Index] = ADX) and (NeighborDY[Index] = ADY) then
        Exit(Index);
    Result := -1;
  end;

  procedure MarkBoundaryPixel(const APoint: TPoint; ADashStep: Integer);
  begin
    if (APoint.X < 0) or (APoint.X >= FDisplaySurface.Width) or
       (APoint.Y < 0) or (APoint.Y >= FDisplaySurface.Height) then
      Exit;
    if not MarqueeStepVisible(ADashStep, FMarqueeDashPhase) then
      Exit;
    if MarqueeStepUsesDarkColor(ADashStep, FMarqueeDashPhase) then
      FDisplaySurface[APoint.X, APoint.Y] := RGBA(0, 0, 0, 255)
    else
      FDisplaySurface[APoint.X, APoint.Y] := RGBA(255, 255, 255, 255);
  end;

  procedure ResetContour;
  begin
    ContourCount := 0;
    ContourCapacity := 0;
    SetLength(BoundaryContour, 0);
  end;

  procedure AppendContourPoint(const APoint: TPoint);
  begin
    if (ContourCount > 0) and
       (BoundaryContour[ContourCount - 1].X = APoint.X) and
       (BoundaryContour[ContourCount - 1].Y = APoint.Y) then
      Exit;
    if ContourCount >= ContourCapacity then
    begin
      if ContourCapacity = 0 then
        ContourCapacity := 64
      else
        ContourCapacity := ContourCapacity * 2;
      SetLength(BoundaryContour, ContourCapacity);
    end;
    BoundaryContour[ContourCount] := APoint;
    Inc(ContourCount);
  end;

  procedure TraceBoundaryContour(const AStartPoint: TPoint);
  var
    LocalSearchIndex: Integer;
    LocalStepIndex: Integer;
  begin
    ResetContour;
    CurrentPoint := AStartPoint;
    BacktrackPoint := Point(CurrentPoint.X - 1, CurrentPoint.Y);
    StartBacktrackPoint := BacktrackPoint;
    TraceGuard := 0;
    repeat
      PixelIndex := SelectionIndex(CurrentPoint.X, CurrentPoint.Y);
      BoundaryVisited[PixelIndex] := 1;
      AppendContourPoint(CurrentPoint);

      BacktrackIndex := NeighborDeltaIndex(
        BacktrackPoint.X - CurrentPoint.X,
        BacktrackPoint.Y - CurrentPoint.Y
      );
      if BacktrackIndex < 0 then
        BacktrackIndex := 7;

      NeighborFound := False;
      for LocalSearchIndex := 1 to 8 do
      begin
        NeighborIndex := (BacktrackIndex + LocalSearchIndex) mod 8;
        NextPoint := Point(
          CurrentPoint.X + NeighborDX[NeighborIndex],
          CurrentPoint.Y + NeighborDY[NeighborIndex]
        );
        if not BoundaryAt(NextPoint.X, NextPoint.Y) then
          Continue;
        BacktrackPoint := Point(
          CurrentPoint.X + NeighborDX[(NeighborIndex + 7) mod 8],
          CurrentPoint.Y + NeighborDY[(NeighborIndex + 7) mod 8]
        );
        CurrentPoint := NextPoint;
        NeighborFound := True;
        Break;
      end;
      if not NeighborFound then
        Break;
      Inc(TraceGuard);
      if TraceGuard > (FDisplaySurface.Width * FDisplaySurface.Height * 4) then
        Break;
    until (CurrentPoint.X = AStartPoint.X) and
          (CurrentPoint.Y = AStartPoint.Y) and
          (BacktrackPoint.X = StartBacktrackPoint.X) and
          (BacktrackPoint.Y = StartBacktrackPoint.Y);

    for LocalStepIndex := 0 to ContourCount - 1 do
      MarkBoundaryPixel(BoundaryContour[LocalStepIndex], LocalStepIndex);
  end;
begin
  if Assigned(FMovePixelsController) and
     FMovePixelsController.Active and
     FMovePixelsController.Moved and
     Assigned(FMovePixelsController.PreviewBaseComposite) then
  begin
    CompositeSurface := FMovePixelsController.PreviewBaseComposite;
    OwnsCompositeSurface := False;
  end
  else
  begin
    CompositeSurface := FDocument.Composite;
    OwnsCompositeSurface := True;
  end;
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
    CheckerDark := RGBA(214, 214, 214, 255);
    CheckerLight := RGBA(245, 245, 245, 255);
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
            TileColor := CheckerDark
          else
            TileColor := CheckerLight;
          if PixelColor.A = 0 then
            FDisplaySurface[X, Y] := TileColor
          else
            FDisplaySurface[X, Y] := BlendNormal(PixelColor, TileColor, 255);
        end;
      end;
  finally
    if OwnsCompositeSurface then
      CompositeSurface.Free;
  end;

  RenderMovePixelsTransactionPreview(FDisplaySurface);

  { Selection outline pass:
    trace boundary contours and apply dash by contour step, avoiding
    coordinate-mod artifacts where diagonal edges collapse into long lines. }
  if False and FDocument.HasSelection then
  begin
    SetLength(SelectionMask, FDisplaySurface.Width * FDisplaySurface.Height);
    SetLength(BoundaryMask, Length(SelectionMask));
    SetLength(BoundaryVisited, Length(SelectionMask));

    for Y := 0 to FDisplaySurface.Height - 1 do
      for X := 0 to FDisplaySurface.Width - 1 do
      begin
        PixelIndex := SelectionIndex(X, Y);
        if FDocument.Selection.Coverage(X, Y) >= 128 then
          SelectionMask[PixelIndex] := 1
        else
          SelectionMask[PixelIndex] := 0;
      end;

    for Y := 0 to FDisplaySurface.Height - 1 do
      for X := 0 to FDisplaySurface.Width - 1 do
      begin
        PixelIndex := SelectionIndex(X, Y);
        if SelectionMask[PixelIndex] = 0 then
          Continue;
        if SelectionInside(X - 1, Y) and SelectionInside(X + 1, Y) and
           SelectionInside(X, Y - 1) and SelectionInside(X, Y + 1) then
          Continue;
        BoundaryMask[PixelIndex] := 1;
      end;

    for Y := 0 to FDisplaySurface.Height - 1 do
      for X := 0 to FDisplaySurface.Width - 1 do
      begin
        PixelIndex := SelectionIndex(X, Y);
        if (BoundaryMask[PixelIndex] = 0) or (BoundaryVisited[PixelIndex] <> 0) then
          Continue;
        StartPoint := Point(X, Y);
        TraceBoundaryContour(StartPoint);
      end;

    DashIndex := 0;
    for Y := 0 to FDisplaySurface.Height - 1 do
      for X := 0 to FDisplaySurface.Width - 1 do
      begin
        PixelIndex := SelectionIndex(X, Y);
        if (BoundaryMask[PixelIndex] = 0) or (BoundaryVisited[PixelIndex] <> 0) then
          Continue;
        MarkBoundaryPixel(Point(X, Y), DashIndex);
        Inc(DashIndex);
      end;
  end;

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
    FPaintBox.Left + FCanvasPadX - FCanvasHost.HorzScrollBar.Position,
    FPaintBox.Top + FCanvasPadY - FCanvasHost.VertScrollBar.Position
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

function TMainForm.LocalizedAction(const AAction: string): string;
begin
  if AAction = 'Add Layer' then
    Exit(TR('Add Layer', '添加图层'))
  else if AAction = 'Add Noise' then
    Exit(TR('Add Noise', '添加噪点'))
  else if AAction = 'Auto-Level' then
    Exit(TR('Auto-Level', '自动色阶'))
  else if AAction = 'Black and White' then
    Exit(TR('Black and White', '黑白'))
  else if AAction = 'Blur' then
    Exit(TR('Blur', '模糊'))
  else if AAction = 'Brightness / Contrast' then
    Exit(TR('Brightness / Contrast', '亮度 / 对比度'))
  else if AAction = 'Bulge' then
    Exit(TR('Bulge', '膨胀'))
  else if AAction = 'Crop' then
    Exit(TR('Crop', '裁剪'))
  else if AAction = 'Crop to Selection' then
    Exit(TR('Crop to Selection', '裁剪到选区'))
  else if AAction = 'Crystallize' then
    Exit(TR('Crystallize', '晶格化'))
  else if AAction = 'Curves' then
    Exit(TR('Curves', '曲线'))
  else if AAction = 'Cut' then
    Exit(TR('Cut', '剪切'))
  else if AAction = 'Delete Layer' then
    Exit(TR('Delete Layer', '删除图层'))
  else if AAction = 'Dents' then
    Exit(TR('Dents', '凹陷'))
  else if AAction = 'Deselect' then
    Exit(TR('Deselect', '取消选择'))
  else if AAction = 'Detect Edges' then
    Exit(TR('Detect Edges', '边缘检测'))
  else if AAction = 'Duplicate Layer' then
    Exit(TR('Duplicate Layer', '复制图层'))
  else if AAction = 'Emboss' then
    Exit(TR('Emboss', '浮雕'))
  else if AAction = 'Erase Selection' then
    Exit(TR('Erase Selection', '擦除选区'))
  else if AAction = 'Fill Selection' then
    Exit(TR('Fill Selection', '填充选区'))
  else if AAction = 'Flatten' then
    Exit(TR('Flatten', '合并图像'))
  else if AAction = 'Flip Horizontal' then
    Exit(TR('Flip Horizontal', '水平翻转'))
  else if AAction = 'Flip Vertical' then
    Exit(TR('Flip Vertical', '垂直翻转'))
  else if AAction = 'Fragment' then
    Exit(TR('Fragment', '碎片'))
  else if AAction = 'Frosted Glass' then
    Exit(TR('Frosted Glass', '磨砂玻璃'))
  else if AAction = 'Gaussian Blur' then
    Exit(TR('Gaussian Blur', '高斯模糊'))
  else if AAction = 'Glow Effect' then
    Exit(TR('Glow Effect', '发光效果'))
  else if AAction = 'Grayscale' then
    Exit(TR('Grayscale', '灰度'))
  else if AAction = 'Hue / Saturation' then
    Exit(TR('Hue / Saturation', '色相 / 饱和度'))
  else if AAction = 'Import Layer' then
    Exit(TR('Import Layer', '导入图层'))
  else if AAction = 'Ink Sketch' then
    Exit(TR('Ink Sketch', '墨水素描'))
  else if AAction = 'Invert Colors' then
    Exit(TR('Invert Colors', '反相'))
  else if AAction = 'Invert Selection' then
    Exit(TR('Invert Selection', '反选'))
  else if AAction = 'Julia Fractal' then
    Exit(TR('Julia Fractal', 'Julia 分形'))
  else if AAction = 'Layer Blend Mode' then
    Exit(TR('Layer Blend Mode', '图层混合模式'))
  else if AAction = 'Layer Opacity' then
    Exit(TR('Layer Opacity', '图层不透明度'))
  else if AAction = 'Layer Properties' then
    Exit(TR('Layer Properties', '图层属性'))
  else if AAction = 'Levels' then
    Exit(TR('Levels', '色阶'))
  else if AAction = 'Magic Wand' then
    Exit(TR('Magic Wand', '魔棒'))
  else if AAction = 'Mandelbrot Fractal' then
    Exit(TR('Mandelbrot Fractal', 'Mandelbrot 分形'))
  else if AAction = 'Median Filter' then
    Exit(TR('Median Filter', '中值滤波'))
  else if AAction = 'Merge Down' then
    Exit(TR('Merge Down', '向下合并'))
  else if AAction = 'Mosaic' then
    Exit(TR('Mosaic', '马赛克'))
  else if AAction = 'Motion Blur' then
    Exit(TR('Motion Blur', '运动模糊'))
  else if AAction = 'Move Layer Down' then
    Exit(TR('Move Layer Down', '下移图层'))
  else if AAction = 'Move Layer Up' then
    Exit(TR('Move Layer Up', '上移图层'))
  else if AAction = 'Move Layer to Bottom' then
    Exit(TR('Move Layer to Bottom', '图层移到底部'))
  else if AAction = 'Move Layer to Top' then
    Exit(TR('Move Layer to Top', '图层移到顶部'))
  else if AAction = 'Oil Paint' then
    Exit(TR('Oil Paint', '油画'))
  else if AAction = 'Outline Effect' then
    Exit(TR('Outline Effect', '轮廓效果'))
  else if AAction = 'Paste' then
    Exit(TR('Paste', '粘贴'))
  else if AAction = 'Paste into New Layer' then
    Exit(TR('Paste into New Layer', '粘贴到新图层'))
  else if AAction = 'Pixelate' then
    Exit(TR('Pixelate', '像素化'))
  else if AAction = 'Posterize' then
    Exit(TR('Posterize', '色调分离'))
  else if AAction = 'Radial Blur' then
    Exit(TR('Radial Blur', '径向模糊'))
  else if AAction = 'Red Eye' then
    Exit(TR('Red Eye', '红眼'))
  else if AAction = 'Relief' then
    Exit(TR('Relief', '浮雕效果'))
  else if AAction = 'Render Clouds' then
    Exit(TR('Render Clouds', '云彩'))
  else if AAction = 'Reorder Layer' then
    Exit(TR('Reorder Layer', '重排图层'))
  else if AAction = 'Resize Canvas' then
    Exit(TR('Resize Canvas', '调整画布大小'))
  else if AAction = 'Resize Image' then
    Exit(TR('Resize Image', '调整图像大小'))
  else if AAction = 'Rotate 180' then
    Exit(TR('Rotate 180', '旋转 180°'))
  else if AAction = 'Rotate 90 Left' then
    Exit(TR('Rotate 90 Left', '向左旋转 90°'))
  else if AAction = 'Rotate 90 Right' then
    Exit(TR('Rotate 90 Right', '向右旋转 90°'))
  else if AAction = 'Rotate Layer' then
    Exit(TR('Rotate Layer', '旋转图层'))
  else if AAction = 'Select All' then
    Exit(TR('Select All', '全选'))
  else if AAction = 'Sepia' then
    Exit(TR('Sepia', '深褐色'))
  else if AAction = 'Sharpen' then
    Exit(TR('Sharpen', '锐化'))
  else if AAction = 'Soften' then
    Exit(TR('Soften', '柔化'))
  else if AAction = 'Surface Blur' then
    Exit(TR('Surface Blur', '表面模糊'))
  else if AAction = 'Text' then
    Exit(TR('Text', '文本'))
  else if AAction = 'Tile Reflection' then
    Exit(TR('Tile Reflection', '瓷砖反射'))
  else if AAction = 'Toggle Layer Visibility' then
    Exit(TR('Toggle Layer Visibility', '切换图层可见性'))
  else if AAction = 'Twist' then
    Exit(TR('Twist', '扭曲'))
  else if AAction = 'Unfocus' then
    Exit(TR('Unfocus', '失焦'))
  else if AAction = 'Vignette' then
    Exit(TR('Vignette', '暗角'))
  else if AAction = 'Zoom Blur' then
    Exit(TR('Zoom Blur', '缩放模糊'));

  Result := AAction;
end;

function TMainForm.ApplyingActionText(const AAction: string): string;
begin
  Result := Format(TR('Applying %s...', '正在应用%s...'), [LocalizedAction(AAction)]);
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

function TMainForm.FormatMeasurement(APixels: Integer): string;
begin
  if FDisplayUnit = duPixels then
    Result := IntToStr(APixels)
  else
    Result := FormatFloat('0.00', PixelsToDisplayValue(APixels));
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
  if not FDocument.BeginActiveLayerMutation(PaintToolName(FCurrentTool)) then
  begin
    ResetLineCurveState;
    RefreshCanvas;
    Exit;
  end;
  CommitShapeTool(FDragStart, FLineCurveEndPoint);
  SetDirty(True);
  InvalidatePreparedBitmap;
  FDragStart := FLineCurveEndPoint;
  FLastImagePoint := FDragStart;
  ResetLineCurveSegmentState;
  FLinePathOpen := AContinuePath;
  RefreshTabCardVisuals(FActiveTabIndex);
  RefreshAuxiliaryImageViews(False);
  RefreshHistoryPanel;
end;

procedure TMainForm.InitializeTextToolDefaults;
begin
  if FTextLastResult.FontName = '' then
    FTextLastResult.FontName := Font.Name;
  if FTextLastResult.FontSize <= 0 then
    FTextLastResult.FontSize := 24;
  FTextLastResult.Alignment := EnsureRange(FTextLastResult.Alignment, 0, 2);
end;

function TMainForm.RunSystemTextFontDialog: Boolean;
var
  FontDialog: TFontDialog;
  FontStyles: TFontStyles;
begin
  InitializeTextToolDefaults;
  FontDialog := TFontDialog.Create(Self);
  try
    FontDialog.Font.Name := FTextLastResult.FontName;
    FontDialog.Font.Size := EnsureRange(FTextLastResult.FontSize, 6, 256);
    FontStyles := [];
    if FTextLastResult.Bold then
      Include(FontStyles, fsBold);
    if FTextLastResult.Italic then
      Include(FontStyles, fsItalic);
    FontDialog.Font.Style := FontStyles;
    Result := FontDialog.Execute;
    if Result then
    begin
      FTextLastResult.FontName := FontDialog.Font.Name;
      FTextLastResult.FontSize := EnsureRange(FontDialog.Font.Size, 6, 256);
      FTextLastResult.Bold := fsBold in FontDialog.Font.Style;
      FTextLastResult.Italic := fsItalic in FontDialog.Font.Style;
      if Assigned(FBrushSpin) and (FCurrentTool = tkText) then
        FBrushSpin.Value := FTextLastResult.FontSize;
      if Assigned(FTextFontButton) then
        FTextFontButton.Caption := Format(TR('Font: %s', '字体：%s'), [FTextLastResult.FontName]);
    end;
  finally
    FontDialog.Free;
  end;
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
  case EnsureRange(FTextLastResult.Alignment, 0, 2) of
    1: FInlineTextEdit.Alignment := taCenter;
    2: FInlineTextEdit.Alignment := taRightJustify;
  else
    FInlineTextEdit.Alignment := taLeftJustify;
  end;
end;

procedure TMainForm.UpdateInlineTextEditBounds;
var
  DisplayFontSize: Integer;
  LineIndex: Integer;
  LongestLineChars: Integer;
  VisibleLineChars: Integer;
  LineCount: Integer;
begin
  if not Assigned(FInlineTextEdit) or not FInlineTextEdit.Visible then
    Exit;
  DisplayFontSize := Max(6, Round(FTextLastResult.FontSize * FZoomScale));
  LongestLineChars := 1;
  LineCount := Max(1, FInlineTextEdit.Lines.Count);
  for LineIndex := 0 to FInlineTextEdit.Lines.Count - 1 do
  begin
    VisibleLineChars := Length(FInlineTextEdit.Lines[LineIndex]);
    if VisibleLineChars <= 0 then
      VisibleLineChars := 1;
    if VisibleLineChars > LongestLineChars then
      LongestLineChars := VisibleLineChars;
  end;
  FInlineTextEdit.Left := FPaintBox.Left + FCanvasPadX + Round(FInlineTextAnchor.X * FZoomScale);
  FInlineTextEdit.Top := FPaintBox.Top + FCanvasPadY + Round(FInlineTextAnchor.Y * FZoomScale);
  FInlineTextEdit.Width := Max(
    140,
    Round((LongestLineChars + 2) * DisplayFontSize * 0.68)
  );
  FInlineTextEdit.Height := Max(56, Round((LineCount + 1) * DisplayFontSize * 1.45));
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
      if FDocument.BeginActiveLayerMutation(LocalizedAction('Text')) then
      begin
        PlaceTextAtPoint(TextResult, FInlineTextAnchor, FInlineTextColor);
        SyncImageMutationUI(False, True);
        DidCommit := True;
      end;
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

procedure TMainForm.InvalidateSelectionMarqueeCache;
begin
  FSelectionMarqueeCacheValid := False;
  FSelectionMarqueeWidth := 0;
  FSelectionMarqueeHeight := 0;
  SetLength(FSelectionMarqueePoints, 0);
  SetLength(FSelectionMarqueeContourOffsets, 0);
  SetLength(FSelectionMarqueeContourLengths, 0);
  SetLength(FSelectionMarqueeStepMap, 0);
end;

procedure TMainForm.EnsureSelectionMarqueeCache;
begin
  if not Assigned(FDocument) then
    Exit;
  if FSelectionMarqueeCacheValid and
     (FSelectionMarqueeWidth = FDocument.Width) and
     (FSelectionMarqueeHeight = FDocument.Height) then
    Exit;
  RebuildSelectionMarqueeCache;
end;

procedure TMainForm.RebuildSelectionMarqueeCache;
var
  WidthPixels: Integer;
  HeightPixels: Integer;
  SelectionMask: array of Byte;
  BoundaryMask: array of Byte;
  BoundaryVisited: array of Byte;
  BoundaryContour: array of TPoint;
  ContourCount: Integer;
  ContourCapacity: Integer;
  X: Integer;
  Y: Integer;
  PixelIndex: Integer;
  NeighborIndex: Integer;
  BacktrackIndex: Integer;
  TraceGuard: Integer;
  StartPoint: TPoint;
  CurrentPoint: TPoint;
  NextPoint: TPoint;
  BacktrackPoint: TPoint;
  StartBacktrackPoint: TPoint;
  NeighborFound: Boolean;
  OffsetIndex: Integer;
  PointIndex: Integer;
  DashIndex: Integer;
  TotalBoundary: Integer;
  MaxTracePerContour: Integer;
  PointsUsed: Integer;
  ContoursUsed: Integer;
  PointsBudget: Integer;
const
  NeighborDX: array[0..7] of Integer = (-1, 0, 1, 1, 1, 0, -1, -1);
  NeighborDY: array[0..7] of Integer = (-1, -1, -1, 0, 1, 1, 1, 0);

  function SelectionIndex(AX, AY: Integer): Integer; inline;
  begin
    Result := AY * WidthPixels + AX;
  end;

  function SelectionInside(AX, AY: Integer): Boolean; inline;
  begin
    if (AX < 0) or (AX >= WidthPixels) or
       (AY < 0) or (AY >= HeightPixels) then
      Exit(False);
    Result := SelectionMask[SelectionIndex(AX, AY)] <> 0;
  end;

  function BoundaryAt(AX, AY: Integer): Boolean; inline;
  begin
    if (AX < 0) or (AX >= WidthPixels) or
       (AY < 0) or (AY >= HeightPixels) then
      Exit(False);
    Result := BoundaryMask[SelectionIndex(AX, AY)] <> 0;
  end;

  function NeighborDeltaIndex(ADX, ADY: Integer): Integer;
  var
    SearchIndex: Integer;
  begin
    for SearchIndex := 0 to 7 do
      if (NeighborDX[SearchIndex] = ADX) and (NeighborDY[SearchIndex] = ADY) then
        Exit(SearchIndex);
    Result := -1;
  end;

  procedure ResetContour;
  begin
    ContourCount := 0;
    ContourCapacity := 0;
    SetLength(BoundaryContour, 0);
  end;

  procedure AppendContourPoint(const APoint: TPoint);
  begin
    if (ContourCount > 0) and
       (BoundaryContour[ContourCount - 1].X = APoint.X) and
       (BoundaryContour[ContourCount - 1].Y = APoint.Y) then
      Exit;
    if ContourCount >= ContourCapacity then
    begin
      if ContourCapacity = 0 then
        ContourCapacity := 64
      else
        ContourCapacity := ContourCapacity * 2;
      SetLength(BoundaryContour, ContourCapacity);
    end;
    BoundaryContour[ContourCount] := APoint;
    Inc(ContourCount);
  end;

  procedure AppendContourToCache;
  var
    CacheOffset: Integer;
    LocalIndex: Integer;
    LocalPoint: TPoint;
    LocalPixelIndex: Integer;
    NewPointsNeeded: Integer;
    NewContoursNeeded: Integer;
  begin
    if ContourCount <= 0 then
      Exit;
    if PointsUsed + ContourCount > PointsBudget then
      Exit;

    NewContoursNeeded := ContoursUsed + 1;
    if NewContoursNeeded > Length(FSelectionMarqueeContourOffsets) then
    begin
      SetLength(FSelectionMarqueeContourOffsets, Max(256, NewContoursNeeded * 2));
      SetLength(FSelectionMarqueeContourLengths, Length(FSelectionMarqueeContourOffsets));
    end;

    CacheOffset := PointsUsed;
    NewPointsNeeded := PointsUsed + ContourCount;
    if NewPointsNeeded > Length(FSelectionMarqueePoints) then
      SetLength(FSelectionMarqueePoints, Max(1024, NewPointsNeeded * 2));

    FSelectionMarqueeContourOffsets[ContoursUsed] := CacheOffset;
    FSelectionMarqueeContourLengths[ContoursUsed] := ContourCount;
    Inc(ContoursUsed);

    for LocalIndex := 0 to ContourCount - 1 do
    begin
      LocalPoint := BoundaryContour[LocalIndex];
      FSelectionMarqueePoints[CacheOffset + LocalIndex] := LocalPoint;
      LocalPixelIndex := SelectionIndex(LocalPoint.X, LocalPoint.Y);
      if (LocalPixelIndex >= 0) and (LocalPixelIndex < Length(FSelectionMarqueeStepMap)) and
         (FSelectionMarqueeStepMap[LocalPixelIndex] < 0) then
        FSelectionMarqueeStepMap[LocalPixelIndex] := LocalIndex;
    end;
    PointsUsed := NewPointsNeeded;
  end;

  procedure TraceBoundaryContour(const AStartPoint: TPoint);
  var
    SearchStep: Integer;
  begin
    ResetContour;
    CurrentPoint := AStartPoint;
    BacktrackPoint := Point(CurrentPoint.X - 1, CurrentPoint.Y);
    StartBacktrackPoint := BacktrackPoint;
    TraceGuard := 0;
    repeat
      PixelIndex := SelectionIndex(CurrentPoint.X, CurrentPoint.Y);
      BoundaryVisited[PixelIndex] := 1;
      AppendContourPoint(CurrentPoint);

      BacktrackIndex := NeighborDeltaIndex(
        BacktrackPoint.X - CurrentPoint.X,
        BacktrackPoint.Y - CurrentPoint.Y
      );
      if BacktrackIndex < 0 then
        BacktrackIndex := 7;

      NeighborFound := False;
      for SearchStep := 1 to 8 do
      begin
        NeighborIndex := (BacktrackIndex + SearchStep) mod 8;
        NextPoint := Point(
          CurrentPoint.X + NeighborDX[NeighborIndex],
          CurrentPoint.Y + NeighborDY[NeighborIndex]
        );
        if not BoundaryAt(NextPoint.X, NextPoint.Y) then
          Continue;
        BacktrackPoint := Point(
          CurrentPoint.X + NeighborDX[(NeighborIndex + 7) mod 8],
          CurrentPoint.Y + NeighborDY[(NeighborIndex + 7) mod 8]
        );
        CurrentPoint := NextPoint;
        NeighborFound := True;
        Break;
      end;
      if not NeighborFound then
        Break;
      Inc(TraceGuard);
      if TraceGuard > MaxTracePerContour then
        Break;
    until (CurrentPoint.X = AStartPoint.X) and
          (CurrentPoint.Y = AStartPoint.Y) and
          (BacktrackPoint.X = StartBacktrackPoint.X) and
          (BacktrackPoint.Y = StartBacktrackPoint.Y);

    AppendContourToCache;
  end;
begin
  InvalidateSelectionMarqueeCache;
  if not Assigned(FDocument) or not FDocument.HasSelection then
  begin
    FSelectionMarqueeCacheValid := True;
    Exit;
  end;

  WidthPixels := FDocument.Width;
  HeightPixels := FDocument.Height;
  if (WidthPixels <= 0) or (HeightPixels <= 0) then
  begin
    FSelectionMarqueeCacheValid := True;
    Exit;
  end;

  FSelectionMarqueeWidth := WidthPixels;
  FSelectionMarqueeHeight := HeightPixels;
  SetLength(SelectionMask, WidthPixels * HeightPixels);
  SetLength(BoundaryMask, WidthPixels * HeightPixels);
  SetLength(BoundaryVisited, WidthPixels * HeightPixels);
  SetLength(FSelectionMarqueeStepMap, WidthPixels * HeightPixels);
  for PixelIndex := 0 to High(FSelectionMarqueeStepMap) do
    FSelectionMarqueeStepMap[PixelIndex] := -1;

  for Y := 0 to HeightPixels - 1 do
    for X := 0 to WidthPixels - 1 do
    begin
      PixelIndex := SelectionIndex(X, Y);
      if FDocument.Selection.Coverage(X, Y) >= 128 then
        SelectionMask[PixelIndex] := 1
      else
        SelectionMask[PixelIndex] := 0;
    end;

  for Y := 0 to HeightPixels - 1 do
    for X := 0 to WidthPixels - 1 do
    begin
      PixelIndex := SelectionIndex(X, Y);
      if SelectionMask[PixelIndex] = 0 then
        Continue;
      if SelectionInside(X - 1, Y) and SelectionInside(X + 1, Y) and
         SelectionInside(X, Y - 1) and SelectionInside(X, Y + 1) then
        Continue;
      BoundaryMask[PixelIndex] := 1;
    end;

  { Count boundary pixels to set reasonable trace and allocation limits }
  TotalBoundary := 0;
  for PixelIndex := 0 to WidthPixels * HeightPixels - 1 do
    if BoundaryMask[PixelIndex] <> 0 then
      Inc(TotalBoundary);

  { Cap per-contour trace at 4× boundary count, hard-capped at 500K to prevent
    degenerate Moore tracing oscillation on noisy selections from allocating
    hundreds of MB and crashing. }
  MaxTracePerContour := Min(Max(TotalBoundary * 4, 4096), 500000);

  { Total points budget: generous but bounded to prevent memory exhaustion }
  PointsBudget := Min(TotalBoundary * 8 + 8192, 2000000);

  { Pre-allocate output arrays with estimated capacity }
  PointsUsed := 0;
  ContoursUsed := 0;
  SetLength(FSelectionMarqueePoints, Min(Max(1024, TotalBoundary * 2), PointsBudget));
  SetLength(FSelectionMarqueeContourOffsets, Max(256, TotalBoundary div 2));
  SetLength(FSelectionMarqueeContourLengths, Length(FSelectionMarqueeContourOffsets));

  for Y := 0 to HeightPixels - 1 do
    for X := 0 to WidthPixels - 1 do
    begin
      PixelIndex := SelectionIndex(X, Y);
      if (BoundaryMask[PixelIndex] = 0) or (BoundaryVisited[PixelIndex] <> 0) then
        Continue;
      if PointsUsed >= PointsBudget then
        Break;
      StartPoint := Point(X, Y);
      TraceBoundaryContour(StartPoint);
    end;

  DashIndex := 0;
  for Y := 0 to HeightPixels - 1 do
    for X := 0 to WidthPixels - 1 do
    begin
      PixelIndex := SelectionIndex(X, Y);
      if (BoundaryMask[PixelIndex] = 0) or (BoundaryVisited[PixelIndex] <> 0) then
        Continue;
      if PointsUsed >= PointsBudget then
        Break;
      if FSelectionMarqueeStepMap[PixelIndex] < 0 then
        FSelectionMarqueeStepMap[PixelIndex] := DashIndex;

      { Append orphan point using pre-allocated arrays }
      if PointsUsed >= Length(FSelectionMarqueePoints) then
        SetLength(FSelectionMarqueePoints, Max(1024, PointsUsed * 2));
      if ContoursUsed >= Length(FSelectionMarqueeContourOffsets) then
      begin
        SetLength(FSelectionMarqueeContourOffsets, Max(256, ContoursUsed * 2));
        SetLength(FSelectionMarqueeContourLengths, Length(FSelectionMarqueeContourOffsets));
      end;
      FSelectionMarqueePoints[PointsUsed] := Point(X, Y);
      FSelectionMarqueeContourOffsets[ContoursUsed] := PointsUsed;
      FSelectionMarqueeContourLengths[ContoursUsed] := 1;
      Inc(PointsUsed);
      Inc(ContoursUsed);
      Inc(DashIndex);
    end;

  { Trim arrays to actual used size }
  SetLength(FSelectionMarqueePoints, PointsUsed);
  SetLength(FSelectionMarqueeContourOffsets, ContoursUsed);
  SetLength(FSelectionMarqueeContourLengths, ContoursUsed);

  FSelectionMarqueeCacheValid := True;
end;

procedure TMainForm.RefreshAuxiliaryImageViews(ARefreshLayers: Boolean);
begin
  if ARefreshLayers then
    RefreshLayers
  else if Assigned(FLayerList) then
    FLayerList.Invalidate;
end;

procedure TMainForm.ResetTransientCanvasState;
begin
  FPointerDown := False;
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;
  ClearMovePixelsTransactionState;
  FPendingSelectionMode := scReplace;
end;

procedure TMainForm.ClearMovePixelsTransactionState;
begin
  if Assigned(FMovePixelsController) then
    FMovePixelsController.Clear;
end;

procedure TMainForm.BeginMovePixelsTransaction;
begin
  if not Assigned(FMovePixelsController) then
    Exit;
  FMovePixelsController.BeginSession(FDocument, BackgroundToolColor);
end;

procedure TMainForm.UpdateMovePixelsTransaction(DeltaX, DeltaY: Integer);
begin
  if not Assigned(FMovePixelsController) then
    Exit;
  if not FMovePixelsController.UpdateDelta(FDocument, DeltaX, DeltaY) then
    Exit;
  SyncSelectionOverlayUI(False);
end;

procedure TMainForm.CommitMovePixelsTransaction;
var
  CommitResult: TMovePixelsCommitResult;
begin
  if not Assigned(FMovePixelsController) then
    Exit;
  CommitResult := FMovePixelsController.Commit(
    FDocument,
    PaintToolName(tkMovePixels),
    BackgroundToolColor
  );
  case CommitResult of
    mpcNoSession:
      Exit;
    mpcNoMove:
      begin
        SyncSelectionOverlayUI(False);
        Exit;
      end;
    mpcBlocked:
      begin
        SyncSelectionOverlayUI(False);
        Exit;
      end;
    mpcCommitted:
      begin
        SyncImageMutationUI(False, True);
        RefreshHistoryPanel;
      end;
  end;
end;

procedure TMainForm.CancelMovePixelsTransaction;
begin
  if not Assigned(FMovePixelsController) then
    Exit;
  if not FMovePixelsController.Active then
    Exit;
  FPointerDown := False;
  if Assigned(FPaintBox) then
    FPaintBox.MouseCapture := False;
  FMovePixelsController.Cancel(FDocument);
  SyncSelectionOverlayUI(False);
end;

procedure TMainForm.SyncSelectionOverlayUI(AMarkDirty: Boolean);
begin
  InvalidateSelectionMarqueeCache;
  if AMarkDirty then
    SetDirty(True);
  RefreshCanvas;
end;

procedure TMainForm.AutoDeselectSelection(const AReason: string);
begin
  if not Assigned(FDocument) or not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory(AReason);
  FDocument.Deselect;
  SyncSelectionOverlayUI(True);
end;

procedure TMainForm.MaybeAutoDeselectOnToolSwitch(AOldTool, ANewTool: TToolKind);
begin
  if not ShouldAutoDeselectOnToolSwitch(AOldTool, ANewTool) then
    Exit;
  AutoDeselectSelection(LocalizedAction('Deselect'));
end;

function TMainForm.ShouldAutoDeselectFromBlankClick(
  const APoint: TPoint;
  AButton: TMouseButton;
  AShift: TShiftState
): Boolean;
begin
  Result := FPUIHelpers.ShouldAutoDeselectFromBlankClick(
    FCurrentTool,
    Assigned(FDocument),
    Assigned(FDocument) and FDocument.HasSelection,
    Assigned(FDocument) and FDocument.Selection[APoint.X, APoint.Y],
    AButton,
    AShift
  );
end;

procedure TMainForm.SyncImageMutationUI(ARefreshLayers: Boolean; AMarkDirty: Boolean);
begin
  if FStatusProgressActive then
    UpdateStatusProgress(82);
  InvalidateSelectionMarqueeCache;
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

procedure TMainForm.SyncDocumentReplacementUI(AMarkDirty: Boolean);
begin
  FitDocumentToViewport(True);
  InvalidateSelectionMarqueeCache;
  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  if AMarkDirty then
    SetDirty(True)
  else
    SetDirty(False);
  RefreshLayers;
  FCenterOnNextCanvasUpdate := True;
  RefreshCanvas;
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
  IsAntiAliasTool: Boolean;
  IsOpacityTool: Boolean;
  IsHardnessTool: Boolean;
  IsEraserShapeTool: Boolean;
  IsShapeTool: Boolean;
  IsLineStyleTool: Boolean;
  IsBucketTool: Boolean;
  IsToleranceTool: Boolean;
  IsFeatherTool: Boolean;
  IsTextTool: Boolean;
  IsGradientTool: Boolean;
  IsCloneTool: Boolean;
  IsCropTool: Boolean;
  IsRoundedRectTool: Boolean;
begin
  if not Assigned(FBrushSpin) or not Assigned(FOptionLabel) then
    Exit;

  FUpdatingToolOption := True;
  try
    { Update tool icon and name in the Options Bar }
    if Assigned(FToolNameLabel) then
      FToolNameLabel.Caption := PaintToolDisplayLabel(FCurrentTool);
    if Assigned(FToolIconImage) then
    begin
      FToolIconImage.Picture.Clear;
      TryLoadButtonIconPicture(PaintToolGlyph(FCurrentTool), bicTool, FToolIconImage.Picture);
    end;

    IsSelTool := FCurrentTool in [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand];
    IsAntiAliasTool := FCurrentTool in [tkSelectRect, tkSelectEllipse, tkSelectLasso];
    IsOpacityTool := FCurrentTool in [tkPencil, tkBrush, tkEraser, tkCloneStamp, tkRecolor];
    IsHardnessTool := FCurrentTool in [tkBrush, tkEraser];
    IsEraserShapeTool := FCurrentTool = tkEraser;
    IsShapeTool := FCurrentTool in [tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape];
    IsLineStyleTool := FCurrentTool in [tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape];
    IsBucketTool := FCurrentTool = tkFill;
    IsToleranceTool := FCurrentTool in [tkFill, tkRecolor];
    IsFeatherTool := IsSelTool;
    IsTextTool := FCurrentTool = tkText;
    IsGradientTool := FCurrentTool = tkGradient;
    IsCloneTool := FCurrentTool = tkCloneStamp;
    IsCropTool := FCurrentTool = tkCrop;
    IsRoundedRectTool := FCurrentTool = tkRoundedRectangle;

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
    if Assigned(FShapeLineStyleLabel) then FShapeLineStyleLabel.Visible := IsLineStyleTool;
    if Assigned(FShapeLineStyleCombo) then FShapeLineStyleCombo.Visible := IsLineStyleTool;
    if Assigned(FShapeLineStyleCombo) then FShapeLineStyleCombo.ItemIndex := FShapeLineStyle;
    if Assigned(FLineBezierCheck) then
    begin
      FLineBezierCheck.Visible := FCurrentTool = tkLine;
      FLineBezierCheck.Checked := FLineBezierMode;
    end;
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
        FFillTolSpin.Value := FRecolorTolerance
      end
      else
      begin
        FFillTolSpin.Value := FFillTolerance;
      end;
      if FCurrentTool = tkRecolor then
        FFillTolSpin.Hint := TR('Recolor tolerance (0=exact, 255=replace broad color range)', '重着色容差 (0=精确, 255=替换更宽颜色范围)')
      else
        FFillTolSpin.Hint := TR('Fill tolerance (0=exact, 255=fill all)', '填充容差 (0=精确, 255=全部填充)');
    end;
    if Assigned(FGradientTypeLabel) then FGradientTypeLabel.Visible := IsGradientTool;
    if Assigned(FGradientTypeCombo) then FGradientTypeCombo.Visible := IsGradientTool;
    if Assigned(FGradientTypeCombo) then FGradientTypeCombo.ItemIndex := EnsureRange(FGradientType, 0, 3);
    if Assigned(FGradientRepeatLabel) then FGradientRepeatLabel.Visible := IsGradientTool;
    if Assigned(FGradientRepeatCombo) then FGradientRepeatCombo.Visible := IsGradientTool;
    if Assigned(FGradientRepeatCombo) then FGradientRepeatCombo.ItemIndex := EnsureRange(FGradientRepeatMode, 0, 2);
    if Assigned(FGradientReverseCheck) then FGradientReverseCheck.Visible := IsGradientTool;
    if Assigned(FGradientReverseCheck) then FGradientReverseCheck.Checked := FGradientReverse;
    if Assigned(FCloneAlignedCheck) then FCloneAlignedCheck.Visible := IsCloneTool;
    if Assigned(FCloneAlignedCheck) then FCloneAlignedCheck.Checked := FCloneAligned;
    if Assigned(FCloneSampleLabel) then FCloneSampleLabel.Visible := IsCloneTool;
    if Assigned(FCloneSampleCombo) then FCloneSampleCombo.Visible := IsCloneTool;
    if Assigned(FCloneSampleCombo) then FCloneSampleCombo.ItemIndex := EnsureRange(FCloneSampleSource, 0, 1);
    if Assigned(FRecolorPreserveValueCheck) then FRecolorPreserveValueCheck.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorPreserveValueCheck) then FRecolorPreserveValueCheck.Checked := FRecolorPreserveValue;
    if Assigned(FRecolorContiguousCheck) then FRecolorContiguousCheck.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorContiguousCheck) then FRecolorContiguousCheck.Checked := FRecolorContiguous;
    if Assigned(FRecolorSamplingLabel) then FRecolorSamplingLabel.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorSamplingCombo) then FRecolorSamplingCombo.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorSamplingCombo) then FRecolorSamplingCombo.ItemIndex := Ord(FRecolorSamplingMode);
    if Assigned(FRecolorModeLabel) then FRecolorModeLabel.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorModeCombo) then FRecolorModeCombo.Visible := FCurrentTool = tkRecolor;
    if Assigned(FRecolorModeCombo) then
      case FRecolorBlendMode of
        rbmColor: FRecolorModeCombo.ItemIndex := 0;
        rbmHue: FRecolorModeCombo.ItemIndex := 1;
        rbmSaturation: FRecolorModeCombo.ItemIndex := 2;
        rbmLuminosity: FRecolorModeCombo.ItemIndex := 3;
      else
        FRecolorModeCombo.ItemIndex := 4;
      end;
    if Assigned(FMosaicBlockLabel) then FMosaicBlockLabel.Visible := FCurrentTool = tkMosaic;
    if Assigned(FMosaicBlockSpin) then FMosaicBlockSpin.Visible := FCurrentTool = tkMosaic;
    if Assigned(FMosaicBlockSpin) then FMosaicBlockSpin.Value := FMosaicBlockSize;
    if Assigned(FCropAspectLabel) then FCropAspectLabel.Visible := IsCropTool;
    if Assigned(FCropAspectCombo) then FCropAspectCombo.Visible := IsCropTool;
    if Assigned(FCropAspectCombo) then FCropAspectCombo.ItemIndex := EnsureRange(FCropAspectMode, 0, 4);
    if Assigned(FCropGuideLabel) then FCropGuideLabel.Visible := IsCropTool;
    if Assigned(FCropGuideCombo) then FCropGuideCombo.Visible := IsCropTool;
    if Assigned(FCropGuideCombo) then FCropGuideCombo.ItemIndex := EnsureRange(FCropGuideMode, 0, 2);
    if Assigned(FRoundedRadiusLabel) then FRoundedRadiusLabel.Visible := IsRoundedRectTool;
    if Assigned(FRoundedRadiusSpin) then FRoundedRadiusSpin.Visible := IsRoundedRectTool;
    if Assigned(FRoundedRadiusSpin) then
      FRoundedRadiusSpin.Value := EnsureRange(FRoundedCornerRadius, FRoundedRadiusSpin.MinValue, FRoundedRadiusSpin.MaxValue);
    if Assigned(FPickerSampleLabel) then FPickerSampleLabel.Visible := FCurrentTool = tkColorPicker;
    if Assigned(FPickerSampleCombo) then FPickerSampleCombo.Visible := FCurrentTool = tkColorPicker;
    if Assigned(FPickerSampleCombo) then FPickerSampleCombo.ItemIndex := FPickerSampleSource;
    if Assigned(FSelAntiAliasCheck) then
    begin
      FSelAntiAliasCheck.Visible := IsAntiAliasTool;
      FSelAntiAliasCheck.Checked := FSelAntiAlias;
    end;
    if Assigned(FSelFeatherLabel) then
      FSelFeatherLabel.Visible := IsFeatherTool;
    if Assigned(FSelFeatherSpin) then
    begin
      FSelFeatherSpin.Visible := IsFeatherTool;
      FSelFeatherSpin.Enabled := True;
      FSelFeatherSpin.Value := EnsureRange(FSelFeather, FSelFeatherSpin.MinValue, FSelFeatherSpin.MaxValue);
    end;
    if Assigned(FSelCornerRadiusLabel) then
      FSelCornerRadiusLabel.Visible := FCurrentTool = tkSelectRect;
    if Assigned(FSelCornerRadiusSpin) then
    begin
      FSelCornerRadiusSpin.Visible := FCurrentTool = tkSelectRect;
      FSelCornerRadiusSpin.Value := EnsureRange(FSelCornerRadius, FSelCornerRadiusSpin.MinValue, FSelCornerRadiusSpin.MaxValue);
    end;
    if Assigned(FTextFontButton) then
    begin
      FTextFontButton.Visible := IsTextTool;
      InitializeTextToolDefaults;
      FTextFontButton.Caption := Format(TR('Font: %s', '字体：%s'), [FTextLastResult.FontName]);
    end;
    if Assigned(FTextAlignLabel) then FTextAlignLabel.Visible := IsTextTool;
    if Assigned(FTextAlignCombo) then FTextAlignCombo.Visible := IsTextTool;
    if Assigned(FTextAlignCombo) then FTextAlignCombo.ItemIndex := EnsureRange(FTextLastResult.Alignment, 0, 2);

    case FCurrentTool of
      tkPencil, tkBrush, tkEraser, tkLine, tkRectangle, tkRoundedRectangle,
      tkEllipseShape, tkFreeformShape, tkCloneStamp, tkRecolor:
        begin
          FOptionLabel.Caption := TR('Size:', '大小：');
          FOptionLabel.Visible := True;
          FBrushSpin.Visible := True;
          FBrushSpin.Enabled := True;
          FBrushSpin.MinValue := 1;
          FBrushSpin.MaxValue := 255;
          FBrushSpin.Value := FBrushSize;
        end;
      tkMagicWand:
        begin
          FOptionLabel.Caption := TR('Tolerance:', '容差：');
          FOptionLabel.Visible := True;
          FBrushSpin.Visible := True;
          FBrushSpin.Enabled := True;
          FBrushSpin.MinValue := 0;
          FBrushSpin.MaxValue := 255;
          FBrushSpin.Value := FWandTolerance;
        end;
      tkText:
        begin
          InitializeTextToolDefaults;
          FOptionLabel.Caption := TR('Size:', '大小：');
          FOptionLabel.Visible := True;
          FBrushSpin.Visible := True;
          FBrushSpin.Enabled := True;
          FBrushSpin.MinValue := 6;
          FBrushSpin.MaxValue := 256;
          FBrushSpin.Value := EnsureRange(FTextLastResult.FontSize, 6, 256);
        end;
      tkSelectRect, tkSelectEllipse, tkSelectLasso:
        begin
          FOptionLabel.Visible := False;
          FBrushSpin.Visible := False;
          { Sync selection mode combo }
          if Assigned(FSelModeCombo) then
            FSelModeCombo.ItemIndex := Ord(FPendingSelectionMode);
        end;
    else
      begin
        FOptionLabel.Visible := False;
        FBrushSpin.Visible := False;
      end;
    end;
  finally
    FUpdatingToolOption := False;
  end;
  LayoutOptionRow;
  SyncToolButtonSelection;
end;

procedure TMainForm.LayoutOptionRow;
{ Dynamically positions all visible tool-option controls left-to-right
  in the Options Bar panel with consistent spacing and vertical centering. }
const
  LabelGap = 4;          { Between a label and its paired control }
  GroupGap = 12;          { Between adjacent control groups }
var
  X: Integer;
  ToolDivider: TControl;

  procedure PlaceLabel(ALabel: TLabel);
  begin
    if not Assigned(ALabel) or not ALabel.Visible then Exit;
    ALabel.Left := X;
    ALabel.Top := (OptionsBarHeight - ALabel.Height) div 2;
    Inc(X, ALabel.Width + LabelGap);
  end;

  procedure PlaceControl(AControl: TControl);
  begin
    if not Assigned(AControl) or not AControl.Visible then Exit;
    AControl.Left := X;
    AControl.Top := (OptionsBarHeight - AControl.Height) div 2;
    Inc(X, AControl.Width + GroupGap);
  end;

begin
  { Vertically center the tool name label }
  if Assigned(FToolNameLabel) then
  begin
    FToolNameLabel.Top := (OptionsBarHeight - FToolNameLabel.Height) div 2;
    X := OptionsBarToolLabelLeft + FToolNameLabel.Width + OptionsBarDividerGap;
  end
  else
    X := OptionsBarToolLabelLeft + 80;
  { Position the vertical divider between tool name and parameters }
  if Assigned(FOptionsBarPanel) then
  begin
    ToolDivider := FOptionsBarPanel.FindChildControl('OptionsBarToolDivider');
    if Assigned(ToolDivider) then
      ToolDivider.Left := X - OptionsBarDividerGap + 2;
  end;
  Inc(X, OptionsBarDividerGap);

  { Size / Tolerance }
  PlaceLabel(FOptionLabel);
  PlaceControl(FBrushSpin);
  PlaceControl(FTextFontButton);
  PlaceLabel(FTextAlignLabel);
  PlaceControl(FTextAlignCombo);

  { Opacity }
  PlaceLabel(FOpacityLabel);
  PlaceControl(FOpacitySpin);

  { Selection Mode }
  PlaceLabel(FSelModeLabel);
  PlaceControl(FSelModeCombo);

  { Shape Style }
  PlaceLabel(FShapeStyleLabel);
  PlaceControl(FShapeStyleCombo);

  { Shape / Line outline style }
  PlaceLabel(FShapeLineStyleLabel);
  PlaceControl(FShapeLineStyleCombo);

  { Line Bezier }
  PlaceControl(FLineBezierCheck);

  { Bucket Fill Mode }
  PlaceLabel(FBucketModeLabel);
  PlaceControl(FBucketModeCombo);

  { Gradient Type }
  PlaceLabel(FGradientTypeLabel);
  PlaceControl(FGradientTypeCombo);
  PlaceLabel(FGradientRepeatLabel);
  PlaceControl(FGradientRepeatCombo);

  { Color Picker Sample }
  PlaceLabel(FPickerSampleLabel);
  PlaceControl(FPickerSampleCombo);

  { Hardness }
  PlaceLabel(FHardnessLabel);
  PlaceControl(FHardnessSpin);

  { Eraser Shape }
  PlaceLabel(FEraserShapeLabel);
  PlaceControl(FEraserShapeCombo);

  { Fill / Recolor Tolerance }
  PlaceLabel(FFillTolLabel);
  PlaceControl(FFillTolSpin);

  { Fill Sample Source }
  PlaceLabel(FFillSampleLabel);
  PlaceControl(FFillSampleCombo);

  { Wand Sample Source }
  PlaceLabel(FWandSampleLabel);
  PlaceControl(FWandSampleCombo);

  { Clone Aligned }
  PlaceControl(FCloneAlignedCheck);
  PlaceLabel(FCloneSampleLabel);
  PlaceControl(FCloneSampleCombo);

  { Recolor Preserve Value }
  PlaceControl(FRecolorPreserveValueCheck);

  { Recolor Limits (Contiguous) }
  PlaceControl(FRecolorContiguousCheck);

  { Recolor Sampling }
  PlaceLabel(FRecolorSamplingLabel);
  PlaceControl(FRecolorSamplingCombo);

  { Recolor Mode }
  PlaceLabel(FRecolorModeLabel);
  PlaceControl(FRecolorModeCombo);

  { Mosaic Block Size }
  PlaceLabel(FMosaicBlockLabel);
  PlaceControl(FMosaicBlockSpin);

  { Crop options }
  PlaceLabel(FCropAspectLabel);
  PlaceControl(FCropAspectCombo);
  PlaceLabel(FCropGuideLabel);
  PlaceControl(FCropGuideCombo);

  { Rounded rectangle radius }
  PlaceLabel(FRoundedRadiusLabel);
  PlaceControl(FRoundedRadiusSpin);

  { Gradient Reverse }
  PlaceControl(FGradientReverseCheck);

  { Selection Anti-alias }
  PlaceControl(FSelAntiAliasCheck);

  { Selection Feather }
  PlaceLabel(FSelFeatherLabel);
  PlaceControl(FSelFeatherSpin);

  { Selection Corner Radius }
  PlaceLabel(FSelCornerRadiusLabel);
  PlaceControl(FSelCornerRadiusSpin);

  { Wand Contiguous }
  PlaceControl(FWandContiguousCheck);
end;

procedure TMainForm.SyncToolButtonSelection;
var
  ToolKind: TToolKind;
  IsActive: Boolean;
begin
  for ToolKind := Low(TToolKind) to High(TToolKind) do
  begin
    if not Assigned(FToolButtons[ToolKind]) then
      Continue;
    IsActive := ToolKind = FCurrentTool;
    { Do NOT set Down:=True — on Cocoa it forces a dark sunken border
      that cannot be themed away.  Instead signal the active tool with
      bold font + selection text colour only. }
    FToolButtons[ToolKind].Down := False;
    FToolButtons[ToolKind].Flat := True;
    if IsActive then
    begin
      FToolButtons[ToolKind].Font.Style := [fsBold];
      FToolButtons[ToolKind].Font.Color := PaletteSelectionTextColor;
    end
    else
    begin
      FToolButtons[ToolKind].Font.Style := [];
      FToolButtons[ToolKind].Font.Color := ChromeTextColor;
    end;
  end;
end;

procedure TMainForm.SyncUtilityButtonStates;
var
  PaletteHost: TPanel;
  procedure ApplyButtonState(AButton: TSpeedButton; AActive: Boolean);
  begin
    if not Assigned(AButton) then
      Exit;
    AButton.Down := AActive;
    AButton.Flat := True;
    if AActive then
    begin
      AButton.Font.Style := [fsBold];
      AButton.Font.Color := PaletteSelectionTextColor;
    end
    else
    begin
      AButton.Font.Style := [];
      AButton.Font.Color := ChromeMutedTextColor;
    end;
  end;
begin
  if Assigned(FUtilityButtons[ucTools]) then
  begin
    PaletteHost := PaletteControl(pkTools);
    ApplyButtonState(FUtilityButtons[ucTools], Assigned(PaletteHost) and PaletteHost.Visible);
  end;
  if Assigned(FUtilityButtons[ucHistory]) then
  begin
    PaletteHost := PaletteControl(pkHistory);
    ApplyButtonState(FUtilityButtons[ucHistory], Assigned(PaletteHost) and PaletteHost.Visible);
  end;
  if Assigned(FUtilityButtons[ucLayers]) then
  begin
    PaletteHost := PaletteControl(pkLayers);
    ApplyButtonState(FUtilityButtons[ucLayers], Assigned(PaletteHost) and PaletteHost.Visible);
  end;
  if Assigned(FUtilityButtons[ucColors]) then
  begin
    PaletteHost := PaletteControl(pkColors);
    ApplyButtonState(FUtilityButtons[ucColors], Assigned(PaletteHost) and PaletteHost.Visible);
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
  if Assigned(FTabPopupMenu) then
    FreeAndNil(FTabPopupMenu);
  FTabPopupMenu := TPopupMenu.Create(Self);
  
  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := TR('&New Tab', '新建标签(&N)');
  Item.OnClick := @TabMenuNewClick;
  FTabPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := '-';
  FTabPopupMenu.Items.Add(Item);
  
  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := TR('&Close', '关闭(&C)');
  Item.OnClick := @TabMenuCloseClick;
  FTabPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := TR('Close &Other Tabs', '关闭其他标签(&O)');
  Item.OnClick := @TabMenuCloseOthersClick;
  FTabPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTabPopupMenu);
  Item.Caption := TR('Close Tabs to the &Right', '关闭右侧标签(&R)');
  Item.OnClick := @TabMenuCloseRightClick;
  FTabPopupMenu.Items.Add(Item);
end;

procedure TMainForm.BuildMenus;
var
  AppMenu: TMenuItem;
  AppAboutMenuItem: TMenuItem;
  AppPreferencesMenuItem: TMenuItem;
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
  AppAboutMenuItem := nil;
  AppPreferencesMenuItem := nil;

  if ShouldCreateExplicitApplicationMenu then
  begin
    AppMenu := TMenuItem.Create(FMainMenu);
    AppMenu.Caption := TR('FlatPaint', 'FlatPaint');
    FMainMenu.Items.Add(AppMenu);
    CreateMenuItem(AppMenu, TR('About FlatPaint', #$E5#$85#$B3#$E4#$BA#$8E' FlatPaint'), @AboutClick);
    CreateMenuItem(AppMenu, '-', nil);
    CreateMenuItem(AppMenu, TR('Preferences...', #$E5#$81#$8F#$E5#$A5#$BD#$E8#$AE#$BE#$E7#$BD#$AE + '...'), @SettingsClick);
  end;

  FileMenu := TMenuItem.Create(FMainMenu);
  FileMenu.Caption := TR('&File', '&' + #$E6#$96#$87#$E4#$BB#$B6);
  FMainMenu.Items.Add(FileMenu);
  CreateMenuItem(FileMenu, TR('&New...', '&' + #$E6#$96#$B0#$E5#$BB#$BA + '...'), @NewDocumentClick, ShortCut(VK_N, [ssMeta]));
  CreateMenuItem(FileMenu, TR('&Open...', '&' + #$E6#$89#$93#$E5#$BC#$80 + '...'), @OpenDocumentClick, ShortCut(VK_O, [ssMeta]));
  FRecentMenu := TMenuItem.Create(FileMenu);
  FRecentMenu.Caption := TR('Open &Recent', #$E6#$89#$93#$E5#$BC#$80#$E6#$9C#$80#$E8#$BF#$91#$E6#$96#$87#$E4#$BB#$B6 + '(&R)');
  FileMenu.Add(FRecentMenu);
  RebuildRecentFilesMenu;
  CreateMenuItem(FileMenu, TR('&Acquire...', '&' + #$E8#$8E#$B7#$E5#$8F#$96 + '...'), @AcquireClick);
  CreateMenuItem(FileMenu, TR('Import as &Layer...', #$E5#$AF#$BC#$E5#$85#$A5#$E4#$B8#$BA#$E5#$9B#$BE#$E5#$B1#$82 + '(&L)...'), @ImportLayerClick, ShortCut(VK_I, [ssMeta, ssShift]));
  FileMenu.AddSeparator;
  CreateMenuItem(FileMenu, TR('&Close', '&' + #$E5#$85#$B3#$E9#$97#$AD), @CloseDocumentClick, ShortCut(VK_W, [ssMeta]));
  FSaveMenuItem := TMenuItem.Create(FileMenu);
  FSaveMenuItem.Caption := SaveCommandCaption(FCurrentFileName <> '');
  FSaveMenuItem.OnClick := @SaveDocumentClick;
  FSaveMenuItem.ShortCut := ShortCut(VK_S, [ssMeta]);
  FileMenu.Add(FSaveMenuItem);
  CreateMenuItem(FileMenu, TR('Save &As...', #$E5#$8F#$A6#$E5#$AD#$98#$E4#$B8#$BA + '(&A)...'), @SaveAsDocumentClick, ShortCut(VK_S, [ssMeta, ssShift]));
  CreateMenuItem(FileMenu, TR('Save A&ll Images', #$E4#$BF#$9D#$E5#$AD#$98#$E5#$85#$A8#$E9#$83#$A8#$E5#$9B#$BE#$E5#$83#$8F + '(&L)'), @SaveAllDocumentsClick, ShortCut(VK_S, [ssMeta, ssAlt]));
  CreateMenuItem(FileMenu, TR('&Print...', '&' + #$E6#$89#$93#$E5#$8D#$B0 + '...'), @PrintDocumentClick, ShortCut(VK_P, [ssMeta]));
  FileMenu.AddSeparator;
  CreateMenuItem(FileMenu, TR('E&xit', #$E9#$80#$80#$E5#$87#$BA + '(&X)'), @ExitApplicationClick, ShortCut(VK_Q, [ssMeta]));

  EditMenu := TMenuItem.Create(FMainMenu);
  EditMenu.Caption := TR('&Edit', '&' + #$E7#$BC#$96#$E8#$BE#$91);
  FMainMenu.Items.Add(EditMenu);
  CreateMenuItem(EditMenu, TR('&Undo', '&' + #$E6#$92#$A4#$E9#$94#$80), @UndoClick, ShortCut(VK_Z, [ssMeta]));
  CreateMenuItem(EditMenu, TR('&Redo', '&' + #$E9#$87#$8D#$E5#$81#$9A), @RedoClick, ShortCut(VK_Z, [ssMeta, ssShift]));
  CreateMenuItem(EditMenu, TR('Cu&t', #$E5#$89#$AA#$E5#$88#$87 + '(&T)'), @CutClick, ShortCut(VK_X, [ssMeta]));
  CreateMenuItem(EditMenu, TR('&Copy', '&' + #$E5#$A4#$8D#$E5#$88#$B6), @CopyClick, ShortCut(VK_C, [ssMeta]));
  CreateMenuItem(
    EditMenu,
    TR('Copy Selection', #$E5#$A4#$8D#$E5#$88#$B6#$E9#$80#$89#$E5#$8C#$BA),
    @CopySelectionClick,
    CoreShortcut(cscCopySelection)
  );
  CreateMenuItem(EditMenu, TR('Copy &Merged', #$E5#$A4#$8D#$E5#$88#$B6#$E5#$90#$88#$E5#$B9#$B6 + '(&M)'), @CopyMergedClick, ShortCut(VK_C, [ssMeta, ssShift]));
  CreateMenuItem(EditMenu, TR('&Paste', '&' + #$E7#$B2#$98#$E8#$B4#$B4), @PasteClick, ShortCut(VK_V, [ssMeta]));
  CreateMenuItem(
    EditMenu,
    TR('Paste into New Layer', #$E7#$B2#$98#$E8#$B4#$B4#$E5#$88#$B0#$E6#$96#$B0#$E5#$9B#$BE#$E5#$B1#$82),
    @PasteIntoNewLayerClick,
    CoreShortcut(cscPasteIntoNewLayer)
  );
  CreateMenuItem(
    EditMenu,
    TR('Paste into New Image', #$E7#$B2#$98#$E8#$B4#$B4#$E5#$88#$B0#$E6#$96#$B0#$E5#$9B#$BE#$E5#$83#$8F),
    @PasteIntoNewImageClick,
    CoreShortcut(cscPasteIntoNewImage)
  );
  CreateMenuItem(EditMenu, TR('Paste &Selection (Replace)', #$E7#$B2#$98#$E8#$B4#$B4#$E9#$80#$89#$E5#$8C#$BA#$EF#$BC#$88#$E6#$9B#$BF#$E6#$8D#$A2#$EF#$BC#$89 + '(&S)'), @PasteSelectionClick);
  CreateMenuItem(EditMenu, TR('Select &All', #$E5#$85#$A8#$E9#$80#$89 + '(&A)'), @SelectAllClick, ShortCut(VK_A, [ssMeta]));
  CreateMenuItem(EditMenu, TR('&Deselect', '&' + #$E5#$8F#$96#$E6#$B6#$88#$E9#$80#$89#$E6#$8B#$A9), @DeselectClick, ShortCut(VK_D, [ssMeta]));
  CreateMenuItem(EditMenu, TR('&Invert Selection', '&' + #$E5#$8F#$8D#$E9#$80#$89), @InvertSelectionClick, ShortCut(VK_I, [ssMeta, ssAlt]));
  CreateMenuItem(
    EditMenu,
    TR('Fill Selection', #$E5#$A1#$AB#$E5#$85#$85#$E9#$80#$89#$E5#$8C#$BA),
    @FillSelectionClick,
    CoreShortcut(cscFillSelection)
  );
  CreateMenuItem(EditMenu, TR('Erase Selection', #$E6#$93#$A6#$E9#$99#$A4#$E9#$80#$89#$E5#$8C#$BA), @EraseSelectionClick, VK_DELETE);
  CreateMenuItem(
    EditMenu,
    TR('Crop To Selection', #$E8#$A3#$81#$E5#$89#$AA#$E5#$88#$B0#$E9#$80#$89#$E5#$8C#$BA),
    @CropToSelectionClick,
    CoreShortcut(cscCropToSelection)
  );
  EditMenu.AddSeparator;
  AppPreferencesMenuItem := TMenuItem.Create(EditMenu);
  AppPreferencesMenuItem.Caption := TR('Preferences...', #$E5#$81#$8F#$E5#$A5#$BD#$E8#$AE#$BE#$E7#$BD#$AE + '...');
  AppPreferencesMenuItem.OnClick := @SettingsClick;
  AppPreferencesMenuItem.ShortCut := ShortCut($BC, [ssMeta]);
  EditMenu.Add(AppPreferencesMenuItem);

  LayerMenu := TMenuItem.Create(FMainMenu);
  LayerMenu.Caption := TR('&Layers', '&' + #$E5#$9B#$BE#$E5#$B1#$82);
  FMainMenu.Items.Add(LayerMenu);
  CreateMenuItem(LayerMenu, TR('&Add Layer', '&' + #$E6#$B7#$BB#$E5#$8A#$A0#$E5#$9B#$BE#$E5#$B1#$82), @AddLayerClick, ShortCut(VK_N, [ssMeta, ssShift]));
  CreateMenuItem(LayerMenu, TR('&Duplicate Layer', '&' + #$E5#$A4#$8D#$E5#$88#$B6#$E5#$9B#$BE#$E5#$B1#$82), @DuplicateLayerClick, ShortCut(VK_D, [ssMeta, ssShift]));
  CreateMenuItem(LayerMenu, TR('&Delete Layer', '&' + #$E5#$88#$A0#$E9#$99#$A4#$E5#$9B#$BE#$E5#$B1#$82), @DeleteLayerClick, ShortCut(VK_DELETE, [ssMeta]));
  CreateMenuItem(LayerMenu, TR('&Rename Layer...', '&' + #$E9#$87#$8D#$E5#$91#$BD#$E5#$90#$8D#$E5#$9B#$BE#$E5#$B1#$82 + '...'), @RenameLayerClick);
  CreateMenuItem(LayerMenu, TR('Move Layer &Up', #$E4#$B8#$8A#$E7#$A7#$BB#$E5#$9B#$BE#$E5#$B1#$82 + '(&U)'), @MoveLayerUpClick);
  CreateMenuItem(LayerMenu, TR('Move Layer &Down', #$E4#$B8#$8B#$E7#$A7#$BB#$E5#$9B#$BE#$E5#$B1#$82 + '(&D)'), @MoveLayerDownClick);
  CreateMenuItem(LayerMenu, TR('&Merge Down', '&' + #$E5#$90#$91#$E4#$B8#$8B#$E5#$90#$88#$E5#$B9#$B6), @MergeDownClick, ShortCut(VK_M, [ssMeta, ssShift]));
  CreateMenuItem(LayerMenu, TR('Toggle &Visibility', #$E5#$88#$87#$E6#$8D#$A2#$E5#$8F#$AF#$E8#$A7#$81#$E6#$80#$A7 + '(&V)'), @ToggleLayerVisibilityClick);
  CreateMenuItem(LayerMenu, TR('Toggle &Lock', #$E5#$88#$87#$E6#$8D#$A2#$E9#$94#$81#$E5#$AE#$9A + '(&L)'), @ToggleLayerLockClick);
  CreateMenuItem(LayerMenu, TR('Layer &Opacity...', #$E5#$9B#$BE#$E5#$B1#$82#$E4#$B8#$8D#$E9#$80#$8F#$E6#$98#$8E#$E5#$BA#$A6 + '(&O)...'), @LayerOpacityClick);
  LayerMenu.AddSeparator;
  CreateMenuItem(LayerMenu, TR('Import From &File...', #$E4#$BB#$8E#$E6#$96#$87#$E4#$BB#$B6#$E5#$AF#$BC#$E5#$85#$A5 + '(&F)...'), @ImportLayerClick);
  CreateMenuItem(LayerMenu, TR('Layer &Properties...', #$E5#$9B#$BE#$E5#$B1#$82#$E5#$B1#$9E#$E6#$80#$A7 + '(&P)...'), @LayerPropertiesClick);
  LayerMenu.AddSeparator;
  CreateMenuItem(LayerMenu, TR('Rotate / &Zoom...', #$E6#$97#$8B#$E8#$BD#$AC' / '#$E7#$BC#$A9#$E6#$94#$BE + '(&Z)...'), @LayerRotateZoomClick);

  ImageMenu := TMenuItem.Create(FMainMenu);
  ImageMenu.Caption := TR('&Image', '&' + #$E5#$9B#$BE#$E5#$83#$8F);
  FMainMenu.Items.Add(ImageMenu);
  CreateMenuItem(ImageMenu, TR('Resize &Image...', #$E8#$B0#$83#$E6#$95#$B4#$E5#$9B#$BE#$E5#$83#$8F#$E5#$A4#$A7#$E5#$B0#$8F + '(&I)...'), @ResizeImageClick);
  CreateMenuItem(ImageMenu, TR('Resize &Canvas...', #$E8#$B0#$83#$E6#$95#$B4#$E7#$94#$BB#$E5#$B8#$83#$E5#$A4#$A7#$E5#$B0#$8F + '(&C)...'), @ResizeCanvasClick);
  CreateMenuItem(ImageMenu, TR('Rotate 90 &Right', #$E5#$90#$91#$E5#$8F#$B3#$E6#$97#$8B#$E8#$BD#$AC'90'#$C2#$B0'(&R)'), @RotateClockwiseClick);
  CreateMenuItem(ImageMenu, TR('Rotate 90 &Left', #$E5#$90#$91#$E5#$B7#$A6#$E6#$97#$8B#$E8#$BD#$AC'90'#$C2#$B0'(&L)'), @RotateCounterClockwiseClick);
  CreateMenuItem(ImageMenu, TR('Rotate &180', #$E6#$97#$8B#$E8#$BD#$AC'&180'#$C2#$B0), @Rotate180Click);
  CreateMenuItem(ImageMenu, TR('Flip &Horizontal', #$E6#$B0#$B4#$E5#$B9#$B3#$E7#$BF#$BB#$E8#$BD#$AC + '(&H)'), @FlipHorizontalClick);
  CreateMenuItem(ImageMenu, TR('Flip &Vertical', #$E5#$9E#$82#$E7#$9B#$B4#$E7#$BF#$BB#$E8#$BD#$AC + '(&V)'), @FlipVerticalClick);
  CreateMenuItem(ImageMenu, TR('&Flatten', '&' + #$E5#$90#$88#$E5#$B9#$B6#$E6#$89#$80#$E6#$9C#$89#$E5#$9B#$BE#$E5#$B1#$82), @FlattenClick, ShortCut(VK_F, [ssMeta, ssShift]));

  ViewMenu := TMenuItem.Create(FMainMenu);
  ViewMenu.Caption := TR('&View', '&' + #$E8#$A7#$86#$E5#$9B#$BE);
  FMainMenu.Items.Add(ViewMenu);
  CreateMenuItem(ViewMenu, TR('Zoom &In', #$E6#$94#$BE#$E5#$A4#$A7 + '(&I)'), @ZoomInClick, ShortCut(Ord('='), [ssMeta]));
  CreateMenuItem(ViewMenu, TR('Zoom &Out', #$E7#$BC#$A9#$E5#$B0#$8F + '(&O)'), @ZoomOutClick, ShortCut(Ord('-'), [ssMeta]));
  CreateMenuItem(ViewMenu, TR('Zoom to &Selection', #$E7#$BC#$A9#$E6#$94#$BE#$E5#$88#$B0#$E9#$80#$89#$E5#$8C#$BA + '(&S)'), @ZoomToSelectionClick);
  CreateMenuItem(ViewMenu, '-', nil);
  CreateMenuItem(ViewMenu, TR('Next Tab', #$E4#$B8#$8B#$E4#$B8#$80#$E4#$B8#$AA#$E6#$A0#$87#$E7#$AD#$BE), @NextTabClick, ShortCut(VK_TAB, [ssCtrl]));
  CreateMenuItem(ViewMenu, TR('Previous Tab', #$E4#$B8#$8A#$E4#$B8#$80#$E4#$B8#$AA#$E6#$A0#$87#$E7#$AD#$BE), @PrevTabClick, ShortCut(VK_TAB, [ssCtrl, ssShift]));
  CreateMenuItem(ViewMenu, '-', nil);
  CreateMenuItem(ViewMenu, TR('&Actual Size', '&' + #$E5#$AE#$9E#$E9#$99#$85#$E5#$A4#$A7#$E5#$B0#$8F), @ActualSizeClick, ShortCut(VK_0, [ssMeta]));
  CreateMenuItem(ViewMenu, TR('Zoom to &Window', #$E7#$BC#$A9#$E6#$94#$BE#$E5#$88#$B0#$E7#$AA#$97#$E5#$8F#$A3 + '(&W)'), @FitToWindowClick, ShortCut(VK_9, [ssMeta]));
  FPixelGridMenuItem := TMenuItem.Create(ViewMenu);
  FPixelGridMenuItem.Caption := TR('Pixel &Grid', #$E5#$83#$8F#$E7#$B4#$A0#$E7#$BD#$91#$E6#$A0#$BC + '(&G)');
  FPixelGridMenuItem.Checked := FShowPixelGrid;
  FPixelGridMenuItem.ShortCut := ShortCut(39, [ssMeta]);
  FPixelGridMenuItem.OnClick := @TogglePixelGridClick;
  ViewMenu.Add(FPixelGridMenuItem);
  FRulersMenuItem := TMenuItem.Create(ViewMenu);
  FRulersMenuItem.Caption := TR('&Rulers', '&' + #$E6#$A0#$87#$E5#$B0#$BA);
  FRulersMenuItem.Checked := FShowRulers;
  FRulersMenuItem.ShortCut := ShortCut(VK_R, [ssMeta, ssAlt]);
  FRulersMenuItem.OnClick := @ToggleRulersClick;
  ViewMenu.Add(FRulersMenuItem);
  FUnitsMenu := TMenuItem.Create(ViewMenu);
  FUnitsMenu.Caption := TR('&Units', '&' + #$E5#$8D#$95#$E4#$BD#$8D);
  ViewMenu.Add(FUnitsMenu);
  FUnitPixelsItem := TMenuItem.Create(FUnitsMenu);
  FUnitPixelsItem.Caption := TR('&Pixels', '&' + #$E5#$83#$8F#$E7#$B4#$A0);
  FUnitPixelsItem.OnClick := @UnitsPixelsClick;
  FUnitsMenu.Add(FUnitPixelsItem);
  FUnitInchesItem := TMenuItem.Create(FUnitsMenu);
  FUnitInchesItem.Caption := TR('&Inches', '&' + #$E8#$8B#$B1#$E5#$AF#$B8);
  FUnitInchesItem.OnClick := @UnitsInchesClick;
  FUnitsMenu.Add(FUnitInchesItem);
  FUnitCentimetersItem := TMenuItem.Create(FUnitsMenu);
  FUnitCentimetersItem.Caption := TR('&Centimeters', '&' + #$E5#$8E#$98#$E7#$B1#$B3);
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
  CreateMenuItem(ViewMenu, TR('Reset Window Layout', #$E9#$87#$8D#$E7#$BD#$AE#$E7#$AA#$97#$E5#$8F#$A3#$E5#$B8#$83#$E5#$B1#$80), @ResetPaletteLayoutClick);

  AdjustMenu := TMenuItem.Create(FMainMenu);
  AdjustMenu.Caption := TR('&Adjustments', '&' + #$E8#$B0#$83#$E6#$95#$B4);
  FMainMenu.Items.Add(AdjustMenu);
  CreateMenuItem(AdjustMenu, TR('&Auto-Level', '&' + #$E8#$87#$AA#$E5#$8A#$A8#$E8#$89#$B2#$E9#$98#$B6), @AutoLevelClick);
  CreateMenuItem(AdjustMenu, TR('&Invert Colors', '&' + #$E5#$8F#$8D#$E8#$BD#$AC#$E9#$A2#$9C#$E8#$89#$B2), @InvertColorsClick);
  CreateMenuItem(AdjustMenu, TR('&Grayscale', '&' + #$E7#$81#$B0#$E5#$BA#$A6), @GrayscaleClick);
  CreateMenuItem(AdjustMenu, TR('&Curves...', '&' + #$E6#$9B#$B2#$E7#$BA#$BF + '...'), @CurvesClick);
  CreateMenuItem(AdjustMenu, TR('&Hue / Saturation...', '&' + #$E8#$89#$B2#$E7#$9B#$B8 + ' / ' + #$E9#$A5#$B1#$E5#$92#$8C#$E5#$BA#$A6 + '...'), @HueSaturationClick);
  CreateMenuItem(AdjustMenu, TR('&Levels...', '&' + #$E8#$89#$B2#$E9#$98#$B6 + '...'), @LevelsClick);
  CreateMenuItem(AdjustMenu, TR('&Brightness / Contrast...', '&' + #$E4#$BA#$AE#$E5#$BA#$A6 + ' / ' + #$E5#$AF#$B9#$E6#$AF#$94#$E5#$BA#$A6 + '...'), @BrightnessContrastClick);
  CreateMenuItem(AdjustMenu, TR('&Sepia', '&' + #$E6#$B7#$B1#$E8#$A4#$90#$E8#$89#$B2), @SepiaClick);
  CreateMenuItem(AdjustMenu, TR('Black and &White...', #$E9#$BB#$91#$E7#$99#$BD + '(&W)...'), @BlackAndWhiteClick);
  CreateMenuItem(AdjustMenu, TR('&Posterize...', '&' + #$E8#$89#$B2#$E8#$B0#$83#$E5#$88#$86#$E7#$A6#$BB + '...'), @PosterizeClick);

  EffectsMenu := TMenuItem.Create(FMainMenu);
  EffectsMenu.Caption := TR('Effe&cts', #$E6#$95#$88#$E6#$9E#$9C + '(&C)');
  FMainMenu.Items.Add(EffectsMenu);
  FRepeatLastEffectItem := TMenuItem.Create(FMainMenu);
  FRepeatLastEffectItem.Caption := TR('Repeat Last Effect', #$E9#$87#$8D#$E5#$A4#$8D#$E4#$B8#$8A#$E6#$AC#$A1#$E6#$95#$88#$E6#$9E#$9C);
  FRepeatLastEffectItem.OnClick := @RepeatLastEffectClick;
  FRepeatLastEffectItem.ShortCut := ShortCut(Ord('F'), [ssMeta]);
  FRepeatLastEffectItem.Enabled := False;
  EffectsMenu.Add(FRepeatLastEffectItem);
  CreateMenuItem(EffectsMenu, '-', nil);
  { ---------- Blurs sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := TR('&Blurs', '&' + #$E6#$A8#$A1#$E7#$B3#$8A);
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, TR('&Box Blur...', '&' + #$E6#$96#$B9#$E6#$A1#$86#$E6#$A8#$A1#$E7#$B3#$8A + '...'), @BlurClick);
  CreateMenuItem(SubMenu, TR('&Gaussian Blur...', '&' + #$E9#$AB#$98#$E6#$96#$AF#$E6#$A8#$A1#$E7#$B3#$8A + '...'), @GaussianBlurClick);
  CreateMenuItem(SubMenu, TR('&Motion Blur...', '&' + #$E8#$BF#$90#$E5#$8A#$A8#$E6#$A8#$A1#$E7#$B3#$8A + '...'), @MotionBlurClick);
  CreateMenuItem(SubMenu, TR('&Radial Blur...', '&' + #$E5#$BE#$84#$E5#$90#$91#$E6#$A8#$A1#$E7#$B3#$8A + '...'), @RadialBlurClick);
  CreateMenuItem(SubMenu, TR('&Surface Blur...', '&' + #$E8#$A1#$A8#$E9#$9D#$A2#$E6#$A8#$A1#$E7#$B3#$8A + '...'), @SurfaceBlurClick);
  CreateMenuItem(SubMenu, TR('&Unfocus...', '&' + #$E5#$A4#$B1#$E7#$84#$A6 + '...'), @UnfocusClick);
  CreateMenuItem(SubMenu, TR('&Zoom Blur...', '&' + #$E7#$BC#$A9#$E6#$94#$BE#$E6#$A8#$A1#$E7#$B3#$8A + '...'), @ZoomBlurClick);
  { ---------- Distort sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := TR('&Distort', '&' + #$E6#$89#$AD#$E6#$9B#$B2);
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, TR('&Fragment...', '&' + #$E7#$A2#$8E#$E7#$89#$87 + '...'), @FragmentClick);
  CreateMenuItem(SubMenu, TR('&Pixelate...', '&' + #$E5#$83#$8F#$E7#$B4#$A0#$E5#$8C#$96 + '...'), @PixelateClick);
  CreateMenuItem(SubMenu, TR('&Twist...', '&' + #$E6#$89#$AD#$E6#$9B#$B2 + '...'), @TwistClick);
  CreateMenuItem(SubMenu, TR('&Bulge...', '&' + #$E8#$86#$A8#$E8#$83#$80 + '...'), @BulgeClick);
  CreateMenuItem(SubMenu, TR('&Dents...', '&' + #$E5#$87#$B9#$E9#$99#$B7 + '...'), @DentsClick);
  CreateMenuItem(SubMenu, TR('Tile &Reflection...', #$E7#$93#$B7#$E7#$A0#$96#$E5#$8F#$8D#$E5#$B0#$84 + '(&R)...'), @TileReflectionClick);
  { ---------- Noise sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := TR('&Noise', '&' + #$E5#$99#$AA#$E7#$82#$B9);
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, TR('Add &Noise...', #$E6#$B7#$BB#$E5#$8A#$A0#$E5#$99#$AA#$E7#$82#$B9 + '(&N)...'), @AddNoiseClick);
  CreateMenuItem(SubMenu, TR('&Median / Denoise...', '&' + #$E4#$B8#$AD#$E5#$80#$BC + ' / ' + #$E9#$99#$8D#$E5#$99#$AA + '...'), @MedianFilterClick);
  { ---------- Photo sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := TR('&Photo', '&' + #$E7#$85#$A7#$E7#$89#$87);
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, TR('&Glow...', '&' + #$E5#$8F#$91#$E5#$85#$89 + '...'), @GlowClick);
  CreateMenuItem(SubMenu, TR('&Oil Paint...', '&' + #$E6#$B2#$B9#$E7#$94#$BB + '...'), @OilPaintClick);
  CreateMenuItem(SubMenu, TR('&Red Eye...', '&' + #$E7#$BA#$A2#$E7#$9C#$BC + '...'), @RedEyeClick);
  CreateMenuItem(SubMenu, TR('&Sharpen', '&' + #$E9#$94#$90#$E5#$8C#$96), @SharpenClick);
  CreateMenuItem(SubMenu, TR('S&often', #$E6#$9F#$94#$E5#$8C#$96 + '(&O)'), @SoftenClick);
  CreateMenuItem(SubMenu, TR('&Vignette...', '&' + #$E6#$9A#$97#$E8#$A7#$92 + '...'), @VignetteClick);
  { ---------- Render sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := TR('&Render', '&' + #$E6#$B8#$B2#$E6#$9F#$93);
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, TR('&Clouds', '&' + #$E4#$BA#$91#$E5#$BD#$A9), @RenderCloudsClick);
  CreateMenuItem(SubMenu, TR('&Frosted Glass...', '&' + #$E7#$A3#$A8#$E7#$A0#$82#$E7#$8E#$BB#$E7#$92#$83 + '...'), @FrostedGlassClick);
  CreateMenuItem(SubMenu, TR('&Mandelbrot Fractal...', '&Mandelbrot ' + #$E5#$88#$86#$E5#$BD#$A2 + '...'), @MandelbrotClick);
  CreateMenuItem(SubMenu, TR('&Julia Fractal...', '&Julia ' + #$E5#$88#$86#$E5#$BD#$A2 + '...'), @JuliaClick);
  { ---------- Stylize sub-menu ---------- }
  SubMenu := TMenuItem.Create(FMainMenu);
  SubMenu.Caption := TR('&Stylize', '&' + #$E9#$A3#$8E#$E6#$A0#$BC#$E5#$8C#$96);
  EffectsMenu.Add(SubMenu);
  CreateMenuItem(SubMenu, TR('&Crystallize...', '&' + #$E6#$99#$B6#$E6#$A0#$BC#$E5#$8C#$96 + '...'), @CrystallizeClick);
  CreateMenuItem(SubMenu, TR('Detect &Edges', #$E8#$BE#$B9#$E7#$BC#$98#$E6#$A3#$80#$E6#$B5#$8B + '(&E)'), @OutlineClick);
  CreateMenuItem(SubMenu, TR('&Emboss', '&' + #$E6#$B5#$AE#$E9#$9B#$95), @EmbossClick);
  CreateMenuItem(SubMenu, TR('&Ink Sketch...', '&' + #$E5#$A2#$A8#$E6#$B0#$B4#$E7#$B4#$A0#$E6#$8F#$8F + '...'), @InkSketchClick);
  CreateMenuItem(SubMenu, TR('&Relief...', '&' + #$E6#$B5#$AE#$E9#$9B#$95#$E6#$95#$88#$E6#$9E#$9C + '...'), @ReliefClick);
  CreateMenuItem(SubMenu, TR('Outline Effe&ct...', #$E8#$BD#$AE#$E5#$BB#$93#$E6#$95#$88#$E6#$9E#$9C + '(&C)...'), @OutlineEffectClick);

  if not ShouldCreateExplicitApplicationMenu then
  begin
    AppAboutMenuItem := TMenuItem.Create(FMainMenu);
    AppAboutMenuItem.Caption := TR('About FlatPaint', #$E5#$85#$B3#$E4#$BA#$8E' FlatPaint');
    AppAboutMenuItem.OnClick := @AboutClick;
    ConfigureSystemAppMenu(AppAboutMenuItem, AppPreferencesMenuItem);
  end;

  Menu := FMainMenu;
end;

procedure TMainForm.BuildToolbar;
var
  ToolIndex: Integer;
  ToolKind: TToolKind;
  UtilityPanel: TPanel;
  FileGroupPanel: TPanel;
  EditGroupPanel: TPanel;
  UndoGroupPanel: TPanel;
  PaletteGroupPanel: TPanel;
  ZoomGroupPanel: TPanel;
  TitleLeadPanel: TPanel;
  TitleTailPanel: TPanel;
  UtilityCommand: TUtilityCommandKind;
  ZoomIndex: Integer;
  Btn: TSpeedButton;
  TitleBand: TPanel;
  DotShape: TShape;
  DividerShape: TShape;
  FileGroupRect: TRect;
  EditGroupRect: TRect;
  UndoGroupRect: TRect;
  PaletteGroupRect: TRect;
  ZoomGroupRect: TRect;
  DividerRect: TRect;
  ZoomButtonRect: TRect;
  ZoomComboRect: TRect;
  HostWidth: Integer;
begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := TopToolbarHeight;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';
  FTopPanel.Color := ToolbarBackgroundColor;
  FTopPanel.ParentColor := False;

  TitleBand := TPanel.Create(FTopPanel);
  TitleBand.Parent := FTopPanel;
  TitleBand.Align := alTop;
  TitleBand.Height := ToolbarTitleBandHeight;
  TitleBand.BevelOuter := bvNone;
  TitleBand.Caption := '';
  TitleBand.Color := ToolbarBackgroundColor;
  TitleBand.ParentColor := False;

  TitleLeadPanel := TPanel.Create(TitleBand);
  TitleLeadPanel.Parent := TitleBand;
  TitleLeadPanel.Align := alLeft;
  TitleLeadPanel.Width := ToolbarTitleRailWidth;
  TitleLeadPanel.BevelOuter := bvNone;
  TitleLeadPanel.Caption := '';
  TitleLeadPanel.Color := ToolbarBackgroundColor;
  TitleLeadPanel.ParentColor := False;

  TitleTailPanel := TPanel.Create(TitleBand);
  TitleTailPanel.Parent := TitleBand;
  TitleTailPanel.Align := alRight;
  TitleTailPanel.Width := ToolbarTitleRailWidth;
  TitleTailPanel.BevelOuter := bvNone;
  TitleTailPanel.Caption := '';
  TitleTailPanel.Color := ToolbarBackgroundColor;
  TitleTailPanel.ParentColor := False;

  DotShape := TShape.Create(TitleLeadPanel);
  DotShape.Parent := TitleLeadPanel;
  DotShape.Left := ToolbarTitleDotLeft;
  DotShape.Top := ToolbarTitleDotTop;
  DotShape.Width := ToolbarTitleDotSize;
  DotShape.Height := ToolbarTitleDotSize;
  DotShape.Shape := stCircle;
  DotShape.Pen.Style := psClear;
  DotShape.Brush.Color := $005F5CF6;

  DotShape := TShape.Create(TitleLeadPanel);
  DotShape.Parent := TitleLeadPanel;
  DotShape.Left := ToolbarTitleDotLeft + ToolbarTitleDotStride;
  DotShape.Top := ToolbarTitleDotTop;
  DotShape.Width := ToolbarTitleDotSize;
  DotShape.Height := ToolbarTitleDotSize;
  DotShape.Shape := stCircle;
  DotShape.Pen.Style := psClear;
  DotShape.Brush.Color := $0059D5F9;

  DotShape := TShape.Create(TitleLeadPanel);
  DotShape.Parent := TitleLeadPanel;
  DotShape.Left := ToolbarTitleDotLeft + (ToolbarTitleDotStride * 2);
  DotShape.Top := ToolbarTitleDotTop;
  DotShape.Width := ToolbarTitleDotSize;
  DotShape.Height := ToolbarTitleDotSize;
  DotShape.Shape := stCircle;
  DotShape.Pen.Style := psClear;
  DotShape.Brush.Color := $0068C85B;

  FChromeTitleLabel := TLabel.Create(TitleBand);
  FChromeTitleLabel.Parent := TitleBand;
  FChromeTitleLabel.Align := alClient;
  FChromeTitleLabel.Alignment := taCenter;
  FChromeTitleLabel.Layout := tlCenter;
  FChromeTitleLabel.Caption := WindowCaptionForDocument(DisplayFileName, FDirty);
  FChromeTitleLabel.Font.Color := ChromeTextColor;
  FChromeTitleLabel.Font.Style := [fsBold];
  FChromeTitleLabel.Font.Size := 9;

  { Toolbar row 1: quick actions + zoom; the tool-options row stays separate below it. }
  HostWidth := FTopPanel.ClientWidth;
  if HostWidth <= 0 then
    HostWidth := ClientWidth;
  if HostWidth <= 0 then
    HostWidth := FPToolbarHelpers.DefaultToolbarHostWidth;
  FileGroupRect := FPToolbarHelpers.ToolbarFileGroupRect;
  EditGroupRect := FPToolbarHelpers.ToolbarEditGroupRect;
  UndoGroupRect := FPToolbarHelpers.ToolbarUndoGroupRect;
  PaletteGroupRect := FPToolbarHelpers.ToolbarPaletteGroupRect(HostWidth);
  ZoomGroupRect := FPToolbarHelpers.ToolbarZoomGroupRect(HostWidth);

  FileGroupPanel := TPanel.Create(FTopPanel);
  FileGroupPanel.Parent := FTopPanel;
  FileGroupPanel.SetBounds(
    FileGroupRect.Left,
    FileGroupRect.Top,
    FileGroupRect.Right - FileGroupRect.Left,
    FileGroupRect.Bottom - FileGroupRect.Top
  );
  FileGroupPanel.BevelOuter := bvNone;
  FileGroupPanel.Caption := '';
  FileGroupPanel.Color := PaletteListBackgroundColor;
  FileGroupPanel.ParentColor := False;

  EditGroupPanel := TPanel.Create(FTopPanel);
  EditGroupPanel.Parent := FTopPanel;
  EditGroupPanel.SetBounds(
    EditGroupRect.Left,
    EditGroupRect.Top,
    EditGroupRect.Right - EditGroupRect.Left,
    EditGroupRect.Bottom - EditGroupRect.Top
  );
  EditGroupPanel.BevelOuter := bvNone;
  EditGroupPanel.Caption := '';
  EditGroupPanel.Color := PaletteListBackgroundColor;
  EditGroupPanel.ParentColor := False;

  UndoGroupPanel := TPanel.Create(FTopPanel);
  UndoGroupPanel.Parent := FTopPanel;
  UndoGroupPanel.SetBounds(
    UndoGroupRect.Left,
    UndoGroupRect.Top,
    UndoGroupRect.Right - UndoGroupRect.Left,
    UndoGroupRect.Bottom - UndoGroupRect.Top
  );
  UndoGroupPanel.BevelOuter := bvNone;
  UndoGroupPanel.Caption := '';
  UndoGroupPanel.Color := PaletteListBackgroundColor;
  UndoGroupPanel.ParentColor := False;

  PaletteGroupPanel := TPanel.Create(FTopPanel);
  PaletteGroupPanel.Parent := FTopPanel;
  PaletteGroupPanel.SetBounds(
    PaletteGroupRect.Left,
    PaletteGroupRect.Top,
    PaletteGroupRect.Right - PaletteGroupRect.Left,
    PaletteGroupRect.Bottom - PaletteGroupRect.Top
  );
  PaletteGroupPanel.BevelOuter := bvNone;
  PaletteGroupPanel.Caption := '';
  PaletteGroupPanel.Color := PaletteListBackgroundColor;
  PaletteGroupPanel.ParentColor := False;
  PaletteGroupPanel.Anchors := [akTop, akRight];

  ZoomGroupPanel := TPanel.Create(FTopPanel);
  ZoomGroupPanel.Parent := FTopPanel;
  ZoomGroupPanel.SetBounds(
    ZoomGroupRect.Left,
    ZoomGroupRect.Top,
    ZoomGroupRect.Right - ZoomGroupRect.Left,
    ZoomGroupRect.Bottom - ZoomGroupRect.Top
  );
  ZoomGroupPanel.BevelOuter := bvNone;
  ZoomGroupPanel.Caption := '';
  ZoomGroupPanel.Color := PaletteListBackgroundColor;
  ZoomGroupPanel.ParentColor := False;
  ZoomGroupPanel.Anchors := [akTop, akRight];

  Btn := CreateButton('New',   4, 2, 72, @NewDocumentClick,   FileGroupPanel, 0, bicCommand);
  if Pos(ToolbarLargeCommandCaptionPrefix, Btn.Caption) = 1 then
    Btn.Caption := ToolbarLargeCommandCaptionPrefix + TR('New', #$E6#$96#$B0#$E5#$BB#$BA)
  else Btn.Caption := TR('New', #$E6#$96#$B0#$E5#$BB#$BA);
  Btn.Hint := TR('New document (Cmd+N)', #$E6#$96#$B0#$E5#$BB#$BA#$E6#$96#$87#$E6#$A1#$A3 + ' (Cmd+N)');
  Btn.Height := ToolbarButtonHeight;

  Btn := CreateButton('Open',  80, 2, 78, @OpenDocumentClick, FileGroupPanel, 0, bicCommand);
  if Pos(ToolbarLargeCommandCaptionPrefix, Btn.Caption) = 1 then
    Btn.Caption := ToolbarLargeCommandCaptionPrefix + TR('Open', #$E6#$89#$93#$E5#$BC#$80)
  else Btn.Caption := TR('Open', #$E6#$89#$93#$E5#$BC#$80);
  Btn.Hint := TR('Open document (Cmd+O)', #$E6#$89#$93#$E5#$BC#$80#$E6#$96#$87#$E6#$A1#$A3 + ' (Cmd+O)');
  Btn.Height := ToolbarButtonHeight;

  Btn := CreateButton('Save', 162, 2, 72, @SaveDocumentClick, FileGroupPanel, 0, bicCommand);
  if Pos(ToolbarLargeCommandCaptionPrefix, Btn.Caption) = 1 then
    Btn.Caption := ToolbarLargeCommandCaptionPrefix + TR('Save', #$E4#$BF#$9D#$E5#$AD#$98)
  else Btn.Caption := TR('Save', #$E4#$BF#$9D#$E5#$AD#$98);
  Btn.Hint := TR('Save document (Cmd+S)', #$E4#$BF#$9D#$E5#$AD#$98#$E6#$96#$87#$E6#$A1#$A3 + ' (Cmd+S)');
  Btn.Height := ToolbarButtonHeight;
  Btn := CreateButton('Cut',    4, 2, ToolbarCompactButtonWidth, @CutClick,          EditGroupPanel, 0, bicCommand); Btn.Hint := TR('Cut selection (Cmd+X)', #$E5#$89#$AA#$E5#$88#$87#$E9#$80#$89#$E5#$8C#$BA + ' (Cmd+X)'); Btn.Height := ToolbarButtonHeight;
  Btn := CreateButton('Copy',  34, 2, ToolbarCompactButtonWidth, @CopyClick,         EditGroupPanel, 0, bicCommand); Btn.Hint := TR('Copy selection (Cmd+C)', #$E5#$A4#$8D#$E5#$88#$B6#$E9#$80#$89#$E5#$8C#$BA + ' (Cmd+C)'); Btn.Height := ToolbarButtonHeight;
  Btn := CreateButton('Paste', 64, 2, ToolbarCompactButtonWidth, @PasteClick,        EditGroupPanel, 0, bicCommand); Btn.Hint := TR('Paste (Cmd+V)', #$E7#$B2#$98#$E8#$B4#$B4 + ' (Cmd+V)'); Btn.Height := ToolbarButtonHeight;
  Btn := CreateButton('Undo',   4, 2, ToolbarCompactButtonWidth, @UndoClick,         UndoGroupPanel, 0, bicCommand); Btn.Hint := TR('Undo last action (Cmd+Z)', #$E6#$92#$A4#$E9#$94#$80 + ' (Cmd+Z)'); Btn.Height := ToolbarButtonHeight;
  Btn := CreateButton('Redo',  34, 2, ToolbarCompactButtonWidth, @RedoClick,         UndoGroupPanel, 0, bicCommand); Btn.Hint := TR('Redo (Cmd+Shift+Z)', #$E9#$87#$8D#$E5#$81#$9A + ' (Cmd+Shift+Z)'); Btn.Height := ToolbarButtonHeight;

  Btn := CreateButton('Tools',  6, 2, ToolbarUtilityButtonWidth, @UtilityButtonClick, PaletteGroupPanel, Ord(ucTools),  bicUtility); Btn.Hint := UtilityCommandHint(ucTools) + ' (' + UtilityCommandShortcutLabel(ucTools) + ')'; Btn.Height := ToolbarButtonHeight;
  FUtilityButtons[ucTools] := Btn;
  Btn := CreateButton('Colors', 34, 2, ToolbarUtilityButtonWidth, @UtilityButtonClick, PaletteGroupPanel, Ord(ucColors), bicUtility); Btn.Hint := UtilityCommandHint(ucColors) + ' (' + UtilityCommandShortcutLabel(ucColors) + ')'; Btn.Height := ToolbarButtonHeight;
  FUtilityButtons[ucColors] := Btn;
  Btn := CreateButton('History', 62, 2, ToolbarUtilityButtonWidth, @UtilityButtonClick, PaletteGroupPanel, Ord(ucHistory), bicUtility); Btn.Hint := UtilityCommandHint(ucHistory) + ' (' + UtilityCommandShortcutLabel(ucHistory) + ')'; Btn.Height := ToolbarButtonHeight;
  FUtilityButtons[ucHistory] := Btn;
  Btn := CreateButton('Layers', 90, 2, ToolbarUtilityButtonWidth, @UtilityButtonClick, PaletteGroupPanel, Ord(ucLayers), bicUtility); Btn.Hint := UtilityCommandHint(ucLayers) + ' (' + UtilityCommandShortcutLabel(ucLayers) + ')'; Btn.Height := ToolbarButtonHeight;
  FUtilityButtons[ucLayers] := Btn;

  ZoomButtonRect := FPToolbarHelpers.ToolbarZoomOutButtonRect(ZoomGroupRect);
  Btn := CreateButton('Zoom-',  ZoomButtonRect.Left - ZoomGroupRect.Left, ZoomButtonRect.Top - ZoomGroupRect.Top, ToolbarZoomButtonWidth, @ZoomOutClick, ZoomGroupPanel, 0, bicCommand); Btn.Hint := TR('Zoom out (Cmd+-)', '缩小 (Cmd+-)'); Btn.Height := ToolbarButtonHeight;

  FZoomCombo := TComboBox.Create(ZoomGroupPanel);
  FZoomCombo.Parent := ZoomGroupPanel;
  ZoomComboRect := FPToolbarHelpers.ToolbarZoomComboRect(ZoomGroupRect);
  FZoomCombo.SetBounds(
    ZoomComboRect.Left - ZoomGroupRect.Left,
    ZoomComboRect.Top - ZoomGroupRect.Top,
    ZoomComboRect.Right - ZoomComboRect.Left,
    ZoomComboRect.Bottom - ZoomComboRect.Top
  );
  FZoomCombo.Style := csDropDownList;
  for ZoomIndex := 0 to ZoomPresetCount - 1 do
    FZoomCombo.Items.Add(ZoomPresetCaption(ZoomIndex));
  FZoomCombo.OnChange := @ZoomComboChange;
  FZoomCombo.Color := clWhite;
  FZoomCombo.ParentFont := False;
  FZoomCombo.Font.Size := 10;
  FZoomCombo.Font.Color := ChromeTextColor;
  FZoomCombo.Hint := TR('Zoom preset', '缩放预设');
  FZoomCombo.ShowHint := True;

  ZoomButtonRect := FPToolbarHelpers.ToolbarZoomInButtonRect(ZoomGroupRect);
  Btn := CreateButton('Zoom+', ZoomButtonRect.Left - ZoomGroupRect.Left, ZoomButtonRect.Top - ZoomGroupRect.Top, ToolbarZoomButtonWidth, @ZoomInClick, ZoomGroupPanel, 0, bicCommand); Btn.Hint := TR('Zoom in (Cmd+=)', '放大 (Cmd+=)'); Btn.Height := ToolbarButtonHeight;

  UtilityPanel := TPanel.Create(FTopPanel);
  UtilityPanel.Parent := FTopPanel;
  UtilityPanel.Left := 0;
  UtilityPanel.Top := ToolbarRowTop;
  UtilityPanel.Width := 0;
  UtilityPanel.Height := 0;
  UtilityPanel.BevelOuter := bvNone;
  UtilityPanel.Caption := '';
  UtilityPanel.Visible := False;

  UtilityCommand := ucTools;
  if Assigned(FUtilityButtons[UtilityCommand]) then
  begin
    FUtilityButtons[UtilityCommand].Font.Size := 12;
    FUtilityButtons[UtilityCommand].Margin := 4;
    FUtilityButtons[UtilityCommand].Spacing := 0;
    FUtilityButtons[UtilityCommand].GroupIndex := 0;
    FUtilityButtons[UtilityCommand].AllowAllUp := False;
  end;
  UtilityCommand := ucColors;
  if Assigned(FUtilityButtons[UtilityCommand]) then
  begin
    FUtilityButtons[UtilityCommand].Font.Size := 12;
    FUtilityButtons[UtilityCommand].Margin := 4;
    FUtilityButtons[UtilityCommand].Spacing := 0;
    FUtilityButtons[UtilityCommand].GroupIndex := 0;
    FUtilityButtons[UtilityCommand].AllowAllUp := False;
  end;
  UtilityCommand := ucHistory;
  if Assigned(FUtilityButtons[UtilityCommand]) then
  begin
    FUtilityButtons[UtilityCommand].Font.Size := 12;
    FUtilityButtons[UtilityCommand].Margin := 4;
    FUtilityButtons[UtilityCommand].Spacing := 0;
    FUtilityButtons[UtilityCommand].GroupIndex := 0;
    FUtilityButtons[UtilityCommand].AllowAllUp := False;
  end;
  UtilityCommand := ucLayers;
  if Assigned(FUtilityButtons[UtilityCommand]) then
  begin
    FUtilityButtons[UtilityCommand].Font.Size := 12;
    FUtilityButtons[UtilityCommand].Margin := 4;
    FUtilityButtons[UtilityCommand].Spacing := 0;
    FUtilityButtons[UtilityCommand].GroupIndex := 0;
    FUtilityButtons[UtilityCommand].AllowAllUp := False;
  end;

  DividerShape := TShape.Create(FTopPanel);
  DividerShape.Parent := FTopPanel;
  DividerShape.Shape := stRectangle;
  DividerShape.Brush.Color := ChromeDividerColor;
  DividerShape.Pen.Style := psClear;
  DividerRect := FPToolbarHelpers.ToolbarDividerAfterRect(FileGroupRect);
  DividerShape.SetBounds(
    DividerRect.Left,
    DividerRect.Top,
    DividerRect.Right - DividerRect.Left,
    DividerRect.Bottom - DividerRect.Top
  );

  DividerShape := TShape.Create(FTopPanel);
  DividerShape.Parent := FTopPanel;
  DividerShape.Shape := stRectangle;
  DividerShape.Brush.Color := ChromeDividerColor;
  DividerShape.Pen.Style := psClear;
  DividerRect := FPToolbarHelpers.ToolbarDividerAfterRect(EditGroupRect);
  DividerShape.SetBounds(
    DividerRect.Left,
    DividerRect.Top,
    DividerRect.Right - DividerRect.Left,
    DividerRect.Bottom - DividerRect.Top
  );

  DividerShape := TShape.Create(FTopPanel);
  DividerShape.Parent := FTopPanel;
  DividerShape.Shape := stRectangle;
  DividerShape.Brush.Color := ChromeDividerColor;
  DividerShape.Pen.Style := psClear;
  DividerRect := FPToolbarHelpers.ToolbarDividerAfterRect(UndoGroupRect);
  DividerShape.SetBounds(
    DividerRect.Left,
    DividerRect.Top,
    DividerRect.Right - DividerRect.Left,
    DividerRect.Bottom - DividerRect.Top
  );

  DividerShape := TShape.Create(FTopPanel);
  DividerShape.Parent := FTopPanel;
  DividerShape.Shape := stRectangle;
  DividerShape.Brush.Color := ChromeDividerColor;
  DividerShape.Pen.Style := psClear;
  DividerRect := FPToolbarHelpers.ToolbarDividerAfterRect(PaletteGroupRect);
  DividerShape.SetBounds(
    DividerRect.Left,
    DividerRect.Top,
    DividerRect.Right - DividerRect.Left,
    DividerRect.Bottom - DividerRect.Top
  );
  DividerShape.Anchors := [akTop, akRight];

  { --- Options Bar: dedicated 32px panel for tool icon + name + parameters --- }
  FOptionsBarPanel := TPanel.Create(FTopPanel);
  FOptionsBarPanel.Parent := FTopPanel;
  FOptionsBarPanel.SetBounds(0, OptionsBarTop, FTopPanel.ClientWidth, OptionsBarHeight);
  FOptionsBarPanel.Anchors := [akTop, akLeft, akRight];
  FOptionsBarPanel.BevelOuter := bvNone;
  FOptionsBarPanel.Caption := '';
  FOptionsBarPanel.Color := ToolbarBackgroundColor;
  FOptionsBarPanel.ParentColor := False;
  FOptionsBarPanel.Font.Size := OptionsBarFontSize;
  FOptionsBarPanel.Font.Color := ChromeTextColor;

  { 1px top divider line }
  DividerShape := TShape.Create(FOptionsBarPanel);
  DividerShape.Parent := FOptionsBarPanel;
  DividerShape.Shape := stRectangle;
  DividerShape.Brush.Color := ChromeDividerColor;
  DividerShape.Pen.Style := psClear;
  DividerShape.SetBounds(0, 0, FOptionsBarPanel.ClientWidth, 1);
  DividerShape.Anchors := [akTop, akLeft, akRight];

  { Current tool icon (20x20) }
  FToolIconImage := TImage.Create(FOptionsBarPanel);
  FToolIconImage.Parent := FOptionsBarPanel;
  FToolIconImage.SetBounds(OptionsBarIconLeft, OptionsBarIconTop, OptionsBarIconSize, OptionsBarIconSize);
  { Keep a stable logical (point) icon box and let @2x assets render into it. }
  FToolIconImage.Stretch := True;
  FToolIconImage.Proportional := True;
  FToolIconImage.Center := True;
  FToolIconImage.Transparent := True;

  { Current tool name label }
  FToolNameLabel := TLabel.Create(FOptionsBarPanel);
  FToolNameLabel.Parent := FOptionsBarPanel;
  FToolNameLabel.Left := OptionsBarToolLabelLeft;
  FToolNameLabel.Top := OptionsBarLabelTop;
  FToolNameLabel.Caption := PaintToolDisplayLabel(FCurrentTool);
  FToolNameLabel.Font.Color := ChromeTextColor;
  FToolNameLabel.Font.Size := OptionsBarFontSize;

  { Vertical divider after tool name — positioned dynamically in LayoutOptionRow }
  DividerShape := TShape.Create(FOptionsBarPanel);
  DividerShape.Parent := FOptionsBarPanel;
  DividerShape.Name := 'OptionsBarToolDivider';
  DividerShape.Shape := stRectangle;
  DividerShape.Brush.Color := ChromeDividerColor;
  DividerShape.Pen.Style := psClear;
  DividerShape.SetBounds(
    OptionsBarToolLabelLeft + FToolNameLabel.Width + OptionsBarDividerGap,
    6, 1, 20
  );

  { Hidden FToolCombo — still needed for programmatic tool-name resolution }
  FToolCombo := TComboBox.Create(FOptionsBarPanel);
  FToolCombo.Parent := FOptionsBarPanel;
  FToolCombo.Visible := False;
  FToolCombo.Left := 0;
  FToolCombo.Top := 0;
  FToolCombo.Width := 164;
  FToolCombo.Style := csDropDownList;
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
  begin
    ToolKind := PaintToolAtDisplayIndex(ToolIndex);
    if ToolKind = tkZoom then
      Continue;
    FToolCombo.Items.AddObject(
      PaintToolDisplayLabel(ToolKind),
      TObject(PtrInt(Ord(ToolKind)))
    );
  end;
  SyncToolComboSelection;
  FToolCombo.OnChange := @ToolComboChange;
  FToolCombo.Color := clWhite;
  FToolCombo.Font.Color := ChromeTextColor;

  { --- Tool-specific option controls (all parented to FOptionsBarPanel) --- }
  FOptionLabel := TLabel.Create(FOptionsBarPanel);
  FOptionLabel.Parent := FOptionsBarPanel;
  FOptionLabel.Caption := TR('Size:', '大小：');
  FOptionLabel.Font.Color := ChromeTextColor;
  FOptionLabel.Font.Size := OptionsBarFontSize;
  FOptionLabel.Left := 220;
  FOptionLabel.Top := OptionsBarLabelTop;

  FBrushSpin := TSpinEdit.Create(FOptionsBarPanel);
  FBrushSpin.Parent := FOptionsBarPanel;
  FBrushSpin.Left := 272;
  FBrushSpin.Top := OptionsBarControlTop;
  FBrushSpin.Height := OptionsBarControlHeight;
  FBrushSpin.Width := 66;
  FBrushSpin.MinValue := 1;
  FBrushSpin.MaxValue := 255;
  FBrushSpin.Value := FBrushSize;
  FBrushSpin.OnChange := @BrushSizeChanged;
  FBrushSpin.Font.Size := OptionsBarFontSize;
  FBrushSpin.Font.Color := ChromeTextColor;

  FTextFontButton := TButton.Create(FOptionsBarPanel);
  FTextFontButton.Parent := FOptionsBarPanel;
  FTextFontButton.Left := 344;
  FTextFontButton.Top := OptionsBarControlTop;
  FTextFontButton.Height := OptionsBarControlHeight;
  FTextFontButton.Width := 156;
  FTextFontButton.Caption := TR('Font...', '字体...');
  FTextFontButton.Visible := False;
  FTextFontButton.OnClick := @TextFontButtonClick;
  FTextFontButton.Hint := TR('Choose font and style', '选择字体和样式');
  FTextFontButton.ShowHint := True;
  FTextFontButton.Font.Size := OptionsBarFontSize;
  FTextFontButton.Font.Color := ChromeTextColor;

  FTextAlignLabel := TLabel.Create(FOptionsBarPanel);
  FTextAlignLabel.Parent := FOptionsBarPanel;
  FTextAlignLabel.Caption := TR('Align:', '对齐：');
  FTextAlignLabel.Font.Color := ChromeTextColor;
  FTextAlignLabel.Font.Size := OptionsBarFontSize;
  FTextAlignLabel.Left := 504;
  FTextAlignLabel.Top := OptionsBarLabelTop;
  FTextAlignLabel.Visible := False;

  FTextAlignCombo := TComboBox.Create(FOptionsBarPanel);
  FTextAlignCombo.Parent := FOptionsBarPanel;
  FTextAlignCombo.Left := 548;
  FTextAlignCombo.Top := OptionsBarControlTop;
  FTextAlignCombo.Height := OptionsBarControlHeight;
  FTextAlignCombo.Width := 108;
  FTextAlignCombo.Style := csDropDownList;
  FTextAlignCombo.Items.Add(TR('Left', '左对齐'));
  FTextAlignCombo.Items.Add(TR('Center', '居中'));
  FTextAlignCombo.Items.Add(TR('Right', '右对齐'));
  FTextAlignCombo.ItemIndex := EnsureRange(FTextLastResult.Alignment, 0, 2);
  FTextAlignCombo.Visible := False;
  FTextAlignCombo.OnChange := @TextAlignComboChanged;
  FTextAlignCombo.Color := clWhite;
  FTextAlignCombo.Font.Size := OptionsBarFontSize;
  FTextAlignCombo.Font.Color := ChromeTextColor;
  FTextAlignCombo.Hint := TR('Text alignment', '文本对齐方式');
  FTextAlignCombo.ShowHint := True;

  FOpacityLabel := TLabel.Create(FOptionsBarPanel);
  FOpacityLabel.Parent := FOptionsBarPanel;
  FOpacityLabel.Caption := TR('Opacity:', '不透明度：');
  FOpacityLabel.Font.Size := OptionsBarFontSize;
  FOpacityLabel.Font.Color := ChromeTextColor;
  FOpacityLabel.Left := 348;
  FOpacityLabel.Top := OptionsBarLabelTop;
  FOpacityLabel.Visible := False;

  FOpacitySpin := TSpinEdit.Create(FOptionsBarPanel);
  FOpacitySpin.Parent := FOptionsBarPanel;
  FOpacitySpin.Left := 408;
  FOpacitySpin.Top := OptionsBarControlTop;
  FOpacitySpin.Height := OptionsBarControlHeight;
  FOpacitySpin.Width := 60;
  FOpacitySpin.MinValue := 1;
  FOpacitySpin.MaxValue := 100;
  FOpacitySpin.Value := 100;
  FOpacitySpin.Visible := False;
  FOpacitySpin.OnChange := @OpacitySpinChanged;
  FOpacitySpin.Font.Size := OptionsBarFontSize;
  FOpacitySpin.Font.Color := ChromeTextColor;
  FOpacitySpin.Hint := TR('Brush opacity (1-100)', '画笔不透明度 (1-100)');
  FOpacitySpin.ShowHint := True;

  FHardnessLabel := TLabel.Create(FOptionsBarPanel);
  FHardnessLabel.Parent := FOptionsBarPanel;
  FHardnessLabel.Caption := TR('Hardness:', '硬度：');
  FHardnessLabel.Font.Size := OptionsBarFontSize;
  FHardnessLabel.Font.Color := ChromeTextColor;
  FHardnessLabel.Left := 480;
  FHardnessLabel.Top := OptionsBarLabelTop;
  FHardnessLabel.Visible := False;

  FHardnessSpin := TSpinEdit.Create(FOptionsBarPanel);
  FHardnessSpin.Parent := FOptionsBarPanel;
  FHardnessSpin.Left := 554;
  FHardnessSpin.Top := OptionsBarControlTop;
  FHardnessSpin.Height := OptionsBarControlHeight;
  FHardnessSpin.Width := 60;
  FHardnessSpin.MinValue := 1;
  FHardnessSpin.MaxValue := 100;
  FHardnessSpin.Value := 100;
  FHardnessSpin.Visible := False;
  FHardnessSpin.OnChange := @HardnessSpinChanged;
  FHardnessSpin.Font.Size := OptionsBarFontSize;
  FHardnessSpin.Font.Color := ChromeTextColor;
  FHardnessSpin.Hint := TR('Brush hardness (1=soft, 100=hard)', '画笔硬度 (1=柔和, 100=硬边)');
  FHardnessSpin.ShowHint := True;

  FEraserShapeLabel := TLabel.Create(FOptionsBarPanel);
  FEraserShapeLabel.Parent := FOptionsBarPanel;
  FEraserShapeLabel.Caption := TR('Shape:', '形状：');
  FEraserShapeLabel.Font.Size := OptionsBarFontSize;
  FEraserShapeLabel.Font.Color := ChromeTextColor;
  FEraserShapeLabel.Left := 628;
  FEraserShapeLabel.Top := OptionsBarLabelTop;
  FEraserShapeLabel.Visible := False;

  FEraserShapeCombo := TComboBox.Create(FOptionsBarPanel);
  FEraserShapeCombo.Parent := FOptionsBarPanel;
  FEraserShapeCombo.Left := 676;
  FEraserShapeCombo.Top := OptionsBarControlTop;
  FEraserShapeCombo.Height := OptionsBarControlHeight;
  FEraserShapeCombo.Width := 92;
  FEraserShapeCombo.Style := csDropDownList;
  FEraserShapeCombo.Items.Add(TR('Round', '圆形'));
  FEraserShapeCombo.Items.Add(TR('Square', '方形'));
  FEraserShapeCombo.ItemIndex := 0;
  FEraserShapeCombo.Visible := False;
  FEraserShapeCombo.OnChange := @EraserShapeComboChanged;
  FEraserShapeCombo.Color := clWhite;
  FEraserShapeCombo.Font.Size := OptionsBarFontSize;
  FEraserShapeCombo.Font.Color := ChromeTextColor;
  FEraserShapeCombo.Hint := TR('Eraser tip shape', '橡皮擦笔头形状');
  FEraserShapeCombo.ShowHint := True;

  FSelModeLabel := TLabel.Create(FOptionsBarPanel);
  FSelModeLabel.Parent := FOptionsBarPanel;
  FSelModeLabel.Caption := TR('Mode:', '模式：');
  FSelModeLabel.Font.Size := OptionsBarFontSize;
  FSelModeLabel.Font.Color := ChromeTextColor;
  FSelModeLabel.Left := 348;
  FSelModeLabel.Top := OptionsBarLabelTop;
  FSelModeLabel.Visible := False;

  FSelModeCombo := TComboBox.Create(FOptionsBarPanel);
  FSelModeCombo.Parent := FOptionsBarPanel;
  FSelModeCombo.Left := 394;
  FSelModeCombo.Top := OptionsBarControlTop;
  FSelModeCombo.Height := OptionsBarControlHeight;
  FSelModeCombo.Width := 96;
  FSelModeCombo.Style := csDropDownList;
  FSelModeCombo.Items.Add(TR('Replace', '替换'));
  FSelModeCombo.Items.Add(TR('Add', '添加'));
  FSelModeCombo.Items.Add(TR('Subtract', '减去'));
  FSelModeCombo.Items.Add(TR('Intersect', '相交'));
  FSelModeCombo.ItemIndex := 0;
  FSelModeCombo.Visible := False;
  FSelModeCombo.OnChange := @SelModeComboChanged;
  FSelModeCombo.Color := clWhite;
  FSelModeCombo.Font.Size := OptionsBarFontSize;
  FSelModeCombo.Font.Color := ChromeTextColor;
  FSelModeCombo.Hint := TR('Selection combination mode', '选区组合模式');
  FSelModeCombo.ShowHint := True;

  { Shape style combo: Outline / Fill / Outline+Fill }
  FShapeStyleLabel := TLabel.Create(FOptionsBarPanel);
  FShapeStyleLabel.Parent := FOptionsBarPanel;
  FShapeStyleLabel.Caption := TR('Draw:', '绘制：');
  FShapeStyleLabel.Font.Size := OptionsBarFontSize;
  FShapeStyleLabel.Font.Color := ChromeTextColor;
  FShapeStyleLabel.Left := 348;
  FShapeStyleLabel.Top := OptionsBarLabelTop;
  FShapeStyleLabel.Visible := False;

  FShapeStyleCombo := TComboBox.Create(FOptionsBarPanel);
  FShapeStyleCombo.Parent := FOptionsBarPanel;
  FShapeStyleCombo.Left := 394;
  FShapeStyleCombo.Top := OptionsBarControlTop;
  FShapeStyleCombo.Height := OptionsBarControlHeight;
  FShapeStyleCombo.Width := 116;
  FShapeStyleCombo.Style := csDropDownList;
  FShapeStyleCombo.Items.Add(TR('Outline', '描边'));
  FShapeStyleCombo.Items.Add(TR('Fill', '填充'));
  FShapeStyleCombo.Items.Add(TR('Outline + Fill', '描边 + 填充'));
  FShapeStyleCombo.ItemIndex := 0;
  FShapeStyleCombo.Visible := False;
  FShapeStyleCombo.OnChange := @ShapeStyleComboChanged;
  FShapeStyleCombo.Color := clWhite;
  FShapeStyleCombo.Font.Size := OptionsBarFontSize;
  FShapeStyleCombo.Font.Color := ChromeTextColor;
  FShapeStyleCombo.Hint := TR('Shape draw style', '形状绘制样式');
  FShapeStyleCombo.ShowHint := True;

  FShapeLineStyleLabel := TLabel.Create(FOptionsBarPanel);
  FShapeLineStyleLabel.Parent := FOptionsBarPanel;
  FShapeLineStyleLabel.Caption := TR('Line:', '线条：');
  FShapeLineStyleLabel.Font.Size := OptionsBarFontSize;
  FShapeLineStyleLabel.Font.Color := ChromeTextColor;
  FShapeLineStyleLabel.Left := 516;
  FShapeLineStyleLabel.Top := OptionsBarLabelTop;
  FShapeLineStyleLabel.Visible := False;

  FShapeLineStyleCombo := TComboBox.Create(FOptionsBarPanel);
  FShapeLineStyleCombo.Parent := FOptionsBarPanel;
  FShapeLineStyleCombo.Left := 554;
  FShapeLineStyleCombo.Top := OptionsBarControlTop;
  FShapeLineStyleCombo.Height := OptionsBarControlHeight;
  FShapeLineStyleCombo.Width := 104;
  FShapeLineStyleCombo.Style := csDropDownList;
  FShapeLineStyleCombo.Items.Add(TR('Solid', '实线'));
  FShapeLineStyleCombo.Items.Add(TR('Dashed', '虚线'));
  FShapeLineStyleCombo.ItemIndex := FShapeLineStyle;
  FShapeLineStyleCombo.Visible := False;
  FShapeLineStyleCombo.OnChange := @ShapeLineStyleComboChanged;
  FShapeLineStyleCombo.Color := clWhite;
  FShapeLineStyleCombo.Font.Size := OptionsBarFontSize;
  FShapeLineStyleCombo.Font.Color := ChromeTextColor;
  FShapeLineStyleCombo.Hint := TR('Outline line style for line/shape tools', '线条/形状工具的描边样式');
  FShapeLineStyleCombo.ShowHint := True;

  FLineBezierCheck := TCheckBox.Create(FOptionsBarPanel);
  FLineBezierCheck.Parent := FOptionsBarPanel;
  FLineBezierCheck.Left := 664;
  FLineBezierCheck.Top := OptionsBarCheckTop;
  FLineBezierCheck.Width := 100;
  FLineBezierCheck.Font.Size := OptionsBarFontSize;
  FLineBezierCheck.Caption := TR('Bezier', '贝塞尔');
  FLineBezierCheck.Checked := FLineBezierMode;
  FLineBezierCheck.Visible := False;
  FLineBezierCheck.OnChange := @LineBezierChanged;
  FLineBezierCheck.Hint := TR('Enable staged Bezier editing for the Line tool', '为直线工具启用分阶段贝塞尔编辑');
  FLineBezierCheck.ShowHint := True;

  { Bucket fill mode combo: Contiguous / Global }
  FBucketModeLabel := TLabel.Create(FOptionsBarPanel);
  FBucketModeLabel.Parent := FOptionsBarPanel;
  FBucketModeLabel.Caption := TR('Fill:', '填充：');
  FBucketModeLabel.Font.Size := OptionsBarFontSize;
  FBucketModeLabel.Font.Color := ChromeTextColor;
  FBucketModeLabel.Left := 348;
  FBucketModeLabel.Top := OptionsBarLabelTop;
  FBucketModeLabel.Visible := False;

  FBucketModeCombo := TComboBox.Create(FOptionsBarPanel);
  FBucketModeCombo.Parent := FOptionsBarPanel;
  FBucketModeCombo.Left := 384;
  FBucketModeCombo.Top := OptionsBarControlTop;
  FBucketModeCombo.Height := OptionsBarControlHeight;
  FBucketModeCombo.Width := 110;
  FBucketModeCombo.Style := csDropDownList;
  FBucketModeCombo.Items.Add(TR('Contiguous', '连续'));
  FBucketModeCombo.Items.Add(TR('Global', '全局'));
  FBucketModeCombo.ItemIndex := 0;
  FBucketModeCombo.Visible := False;
  FBucketModeCombo.OnChange := @BucketModeComboChanged;
  FBucketModeCombo.Color := clWhite;
  FBucketModeCombo.Font.Size := OptionsBarFontSize;
  FBucketModeCombo.Font.Color := ChromeTextColor;
  FBucketModeCombo.Hint := TR('Fill mode', '填充模式');
  FBucketModeCombo.ShowHint := True;

  { Fill sample source combo: Current Layer / All Layers }
  FFillSampleLabel := TLabel.Create(FOptionsBarPanel);
  FFillSampleLabel.Parent := FOptionsBarPanel;
  FFillSampleLabel.Caption := TR('Sample:', '采样：');
  FFillSampleLabel.Font.Size := OptionsBarFontSize;
  FFillSampleLabel.Font.Color := ChromeTextColor;
  FFillSampleLabel.Left := 500;
  FFillSampleLabel.Top := OptionsBarLabelTop;
  FFillSampleLabel.Visible := False;

  FFillSampleCombo := TComboBox.Create(FOptionsBarPanel);
  FFillSampleCombo.Parent := FOptionsBarPanel;
  FFillSampleCombo.Left := 552;
  FFillSampleCombo.Top := OptionsBarControlTop;
  FFillSampleCombo.Height := OptionsBarControlHeight;
  FFillSampleCombo.Width := 120;
  FFillSampleCombo.Style := csDropDownList;
  FFillSampleCombo.Items.Add(TR('Current Layer', '当前图层'));
  FFillSampleCombo.Items.Add(TR('All Layers', '所有图层'));
  FFillSampleCombo.ItemIndex := 0;
  FFillSampleCombo.Visible := False;
  FFillSampleCombo.OnChange := @FillSampleComboChanged;
  FFillSampleCombo.Color := clWhite;
  FFillSampleCombo.Font.Size := OptionsBarFontSize;
  FFillSampleCombo.Font.Color := ChromeTextColor;
  FFillSampleCombo.Hint := TR('Fill sample source', '填充采样来源');
  FFillSampleCombo.ShowHint := True;

  { Magic wand sample source combo: Current Layer / All Layers }
  FWandSampleLabel := TLabel.Create(FOptionsBarPanel);
  FWandSampleLabel.Parent := FOptionsBarPanel;
  FWandSampleLabel.Caption := TR('Sample:', '采样：');
  FWandSampleLabel.Font.Size := OptionsBarFontSize;
  FWandSampleLabel.Font.Color := ChromeTextColor;
  FWandSampleLabel.Left := 730;
  FWandSampleLabel.Top := OptionsBarLabelTop;
  FWandSampleLabel.Visible := False;

  FWandSampleCombo := TComboBox.Create(FOptionsBarPanel);
  FWandSampleCombo.Parent := FOptionsBarPanel;
  FWandSampleCombo.Left := 782;
  FWandSampleCombo.Top := OptionsBarControlTop;
  FWandSampleCombo.Height := OptionsBarControlHeight;
  FWandSampleCombo.Width := 120;
  FWandSampleCombo.Style := csDropDownList;
  FWandSampleCombo.Items.Add(TR('Current Layer', '当前图层'));
  FWandSampleCombo.Items.Add(TR('All Layers', '所有图层'));
  FWandSampleCombo.ItemIndex := 0;
  FWandSampleCombo.Visible := False;
  FWandSampleCombo.OnChange := @WandSampleComboChanged;
  FWandSampleCombo.Color := clWhite;
  FWandSampleCombo.Font.Size := OptionsBarFontSize;
  FWandSampleCombo.Font.Color := ChromeTextColor;
  FWandSampleCombo.Hint := TR('Wand sample source', '魔棒采样来源');
  FWandSampleCombo.ShowHint := True;

  { Wand contiguous checkbox }
  FWandContiguousCheck := TCheckBox.Create(FOptionsBarPanel);
  FWandContiguousCheck.Parent := FOptionsBarPanel;
  FWandContiguousCheck.Left := 910;
  FWandContiguousCheck.Top := OptionsBarCheckTop;
  FWandContiguousCheck.Width := 100;
  FWandContiguousCheck.Font.Size := OptionsBarFontSize;
  FWandContiguousCheck.Caption := TR('Contiguous', '连续');
  FWandContiguousCheck.Checked := FWandContiguous;
  FWandContiguousCheck.Visible := False;
  FWandContiguousCheck.OnChange := @WandContiguousChanged;
  FWandContiguousCheck.Hint := TR('Contiguous: select only connected pixels', '连续：只选择相连像素');
  FWandContiguousCheck.ShowHint := True;

  { Fill tolerance spin }
  FFillTolLabel := TLabel.Create(FOptionsBarPanel);
  FFillTolLabel.Parent := FOptionsBarPanel;
  FFillTolLabel.Caption := TR('Tolerance:', '容差：');
  FFillTolLabel.Font.Size := OptionsBarFontSize;
  FFillTolLabel.Font.Color := ChromeTextColor;
  FFillTolLabel.Left := 348;
  FFillTolLabel.Top := OptionsBarLabelTop;
  FFillTolLabel.Visible := False;

  FFillTolSpin := TSpinEdit.Create(FOptionsBarPanel);
  FFillTolSpin.Parent := FOptionsBarPanel;
  FFillTolSpin.Left := 420;
  FFillTolSpin.Top := OptionsBarControlTop;
  FFillTolSpin.Height := OptionsBarControlHeight;
  FFillTolSpin.Width := 66;
  FFillTolSpin.MinValue := 0;
  FFillTolSpin.MaxValue := 255;
  FFillTolSpin.Value := FFillTolerance;
  FFillTolSpin.Visible := False;
  FFillTolSpin.OnChange := @FillTolSpinChanged;
  FFillTolSpin.Font.Size := OptionsBarFontSize;
  FFillTolSpin.Font.Color := ChromeTextColor;
  FFillTolSpin.Hint := TR('Fill tolerance (0=exact, 255=fill all)', '填充容差 (0=精确, 255=全部)');
  FFillTolSpin.ShowHint := True;

  { Gradient type combo }
  FGradientTypeLabel := TLabel.Create(FOptionsBarPanel);
  FGradientTypeLabel.Parent := FOptionsBarPanel;
  FGradientTypeLabel.Caption := TR('Type:', '类型：');
  FGradientTypeLabel.Font.Size := OptionsBarFontSize;
  FGradientTypeLabel.Font.Color := ChromeTextColor;
  FGradientTypeLabel.Left := 348;
  FGradientTypeLabel.Top := OptionsBarLabelTop;
  FGradientTypeLabel.Visible := False;

  FGradientTypeCombo := TComboBox.Create(FOptionsBarPanel);
  FGradientTypeCombo.Parent := FOptionsBarPanel;
  FGradientTypeCombo.Left := 384;
  FGradientTypeCombo.Top := OptionsBarControlTop;
  FGradientTypeCombo.Height := OptionsBarControlHeight;
  FGradientTypeCombo.Width := 110;
  FGradientTypeCombo.Style := csDropDownList;
  FGradientTypeCombo.Items.Add(TR('Linear', '线性'));
  FGradientTypeCombo.Items.Add(TR('Radial', '径向'));
  FGradientTypeCombo.Items.Add(TR('Conical', '圆锥'));
  FGradientTypeCombo.Items.Add(TR('Diamond', '菱形'));
  FGradientTypeCombo.ItemIndex := EnsureRange(FGradientType, 0, 3);
  FGradientTypeCombo.Visible := False;
  FGradientTypeCombo.OnChange := @GradientTypeComboChanged;
  FGradientTypeCombo.Color := clWhite;
  FGradientTypeCombo.Font.Size := OptionsBarFontSize;
  FGradientTypeCombo.Font.Color := ChromeTextColor;
  FGradientTypeCombo.Hint := TR('Gradient type', '渐变类型');
  FGradientTypeCombo.ShowHint := True;

  { Gradient repeat combo }
  FGradientRepeatLabel := TLabel.Create(FOptionsBarPanel);
  FGradientRepeatLabel.Parent := FOptionsBarPanel;
  FGradientRepeatLabel.Caption := TR('Repeat:', '重复：');
  FGradientRepeatLabel.Font.Size := OptionsBarFontSize;
  FGradientRepeatLabel.Font.Color := ChromeTextColor;
  FGradientRepeatLabel.Left := 500;
  FGradientRepeatLabel.Top := OptionsBarLabelTop;
  FGradientRepeatLabel.Visible := False;

  FGradientRepeatCombo := TComboBox.Create(FOptionsBarPanel);
  FGradientRepeatCombo.Parent := FOptionsBarPanel;
  FGradientRepeatCombo.Left := 558;
  FGradientRepeatCombo.Top := OptionsBarControlTop;
  FGradientRepeatCombo.Height := OptionsBarControlHeight;
  FGradientRepeatCombo.Width := 122;
  FGradientRepeatCombo.Style := csDropDownList;
  FGradientRepeatCombo.Items.Add(TR('None', '无'));
  FGradientRepeatCombo.Items.Add(TR('Sawtooth', '锯齿'));
  FGradientRepeatCombo.Items.Add(TR('Triangular', '三角波'));
  FGradientRepeatCombo.ItemIndex := EnsureRange(FGradientRepeatMode, 0, 2);
  FGradientRepeatCombo.Visible := False;
  FGradientRepeatCombo.OnChange := @GradientRepeatComboChanged;
  FGradientRepeatCombo.Color := clWhite;
  FGradientRepeatCombo.Font.Size := OptionsBarFontSize;
  FGradientRepeatCombo.Font.Color := ChromeTextColor;
  FGradientRepeatCombo.Hint := TR('Gradient repeat mode', '渐变重复模式');
  FGradientRepeatCombo.ShowHint := True;

  { Gradient reverse checkbox }
  FGradientReverseCheck := TCheckBox.Create(FOptionsBarPanel);
  FGradientReverseCheck.Parent := FOptionsBarPanel;
  FGradientReverseCheck.Left := 686;
  FGradientReverseCheck.Top := OptionsBarCheckTop;
  FGradientReverseCheck.Width := 80;
  FGradientReverseCheck.Font.Size := OptionsBarFontSize;
  FGradientReverseCheck.Caption := TR('Reverse', '反向');
  FGradientReverseCheck.Checked := FGradientReverse;
  FGradientReverseCheck.Visible := False;
  FGradientReverseCheck.OnChange := @GradientReverseChanged;
  FGradientReverseCheck.Hint := TR('Reverse gradient direction', '反转渐变方向');
  FGradientReverseCheck.ShowHint := True;

  { Clone aligned checkbox }
  FCloneAlignedCheck := TCheckBox.Create(FOptionsBarPanel);
  FCloneAlignedCheck.Parent := FOptionsBarPanel;
  FCloneAlignedCheck.Left := 480;
  FCloneAlignedCheck.Top := OptionsBarCheckTop;
  FCloneAlignedCheck.Width := 80;
  FCloneAlignedCheck.Font.Size := OptionsBarFontSize;
  FCloneAlignedCheck.Caption := TR('Aligned', '对齐');
  FCloneAlignedCheck.Checked := FCloneAligned;
  FCloneAlignedCheck.Visible := False;
  FCloneAlignedCheck.OnChange := @CloneAlignedChanged;
  FCloneAlignedCheck.Hint := TR('Keep the clone source aligned across multiple strokes', '在多次笔划中保持仿制源对齐');
  FCloneAlignedCheck.ShowHint := True;

  FCloneSampleLabel := TLabel.Create(FOptionsBarPanel);
  FCloneSampleLabel.Parent := FOptionsBarPanel;
  FCloneSampleLabel.Caption := TR('Sample:', '采样：');
  FCloneSampleLabel.Font.Size := OptionsBarFontSize;
  FCloneSampleLabel.Font.Color := ChromeTextColor;
  FCloneSampleLabel.Left := 566;
  FCloneSampleLabel.Top := OptionsBarLabelTop;
  FCloneSampleLabel.Visible := False;

  FCloneSampleCombo := TComboBox.Create(FOptionsBarPanel);
  FCloneSampleCombo.Parent := FOptionsBarPanel;
  FCloneSampleCombo.Left := 618;
  FCloneSampleCombo.Top := OptionsBarControlTop;
  FCloneSampleCombo.Height := OptionsBarControlHeight;
  FCloneSampleCombo.Width := 126;
  FCloneSampleCombo.Style := csDropDownList;
  FCloneSampleCombo.Items.Add(TR('Current Layer', '当前图层'));
  FCloneSampleCombo.Items.Add(TR('Image', '图像合成'));
  FCloneSampleCombo.ItemIndex := EnsureRange(FCloneSampleSource, 0, 1);
  FCloneSampleCombo.Visible := False;
  FCloneSampleCombo.OnChange := @CloneSampleComboChanged;
  FCloneSampleCombo.Color := clWhite;
  FCloneSampleCombo.Font.Size := OptionsBarFontSize;
  FCloneSampleCombo.Font.Color := ChromeTextColor;
  FCloneSampleCombo.Hint := TR('Clone sample source', '仿制采样来源');
  FCloneSampleCombo.ShowHint := True;

  { Recolor preserve-value checkbox }
  FRecolorPreserveValueCheck := TCheckBox.Create(FOptionsBarPanel);
  FRecolorPreserveValueCheck.Parent := FOptionsBarPanel;
  FRecolorPreserveValueCheck.Left := 628;
  FRecolorPreserveValueCheck.Top := OptionsBarCheckTop;
  FRecolorPreserveValueCheck.Width := 120;
  FRecolorPreserveValueCheck.Font.Size := OptionsBarFontSize;
  FRecolorPreserveValueCheck.Caption := TR('Preserve Value', '保持明度');
  FRecolorPreserveValueCheck.Checked := FRecolorPreserveValue;
  FRecolorPreserveValueCheck.Visible := False;
  FRecolorPreserveValueCheck.OnChange := @RecolorPreserveValueChanged;
  FRecolorPreserveValueCheck.Hint := TR('Keep original brightness while shifting the color', '改变颜色时保持原始亮度');
  FRecolorPreserveValueCheck.ShowHint := True;

  FRecolorContiguousCheck := TCheckBox.Create(FOptionsBarPanel);
  FRecolorContiguousCheck.Parent := FOptionsBarPanel;
  FRecolorContiguousCheck.Left := 752;
  FRecolorContiguousCheck.Top := OptionsBarCheckTop;
  FRecolorContiguousCheck.Width := 110;
  FRecolorContiguousCheck.Font.Size := OptionsBarFontSize;
  FRecolorContiguousCheck.Caption := TR('Contiguous', '连续');
  FRecolorContiguousCheck.Checked := FRecolorContiguous;
  FRecolorContiguousCheck.Visible := False;
  FRecolorContiguousCheck.OnChange := @RecolorContiguousChanged;
  FRecolorContiguousCheck.Hint := TR('Only recolor connected pixels in the sampled family', '仅重着色采样族中连通的像素');
  FRecolorContiguousCheck.ShowHint := True;

  FRecolorSamplingLabel := TLabel.Create(FOptionsBarPanel);
  FRecolorSamplingLabel.Parent := FOptionsBarPanel;
  FRecolorSamplingLabel.Caption := TR('Sampling:', '采样：');
  FRecolorSamplingLabel.Font.Size := OptionsBarFontSize;
  FRecolorSamplingLabel.Font.Color := ChromeTextColor;
  FRecolorSamplingLabel.Left := 756;
  FRecolorSamplingLabel.Top := OptionsBarLabelTop;
  FRecolorSamplingLabel.Visible := False;

  FRecolorSamplingCombo := TComboBox.Create(FOptionsBarPanel);
  FRecolorSamplingCombo.Parent := FOptionsBarPanel;
  FRecolorSamplingCombo.Left := 824;
  FRecolorSamplingCombo.Top := OptionsBarControlTop;
  FRecolorSamplingCombo.Height := OptionsBarControlHeight;
  FRecolorSamplingCombo.Width := 126;
  FRecolorSamplingCombo.Style := csDropDownList;
  FRecolorSamplingCombo.Items.Add(TR('Once', '一次'));
  FRecolorSamplingCombo.Items.Add(TR('Continuous', '连续'));
  FRecolorSamplingCombo.Items.Add(TR('Swatch (Compat)', '色板（兼容）'));
  FRecolorSamplingCombo.ItemIndex := Ord(FRecolorSamplingMode);
  FRecolorSamplingCombo.Visible := False;
  FRecolorSamplingCombo.OnChange := @RecolorSamplingModeChanged;
  FRecolorSamplingCombo.Color := clWhite;
  FRecolorSamplingCombo.Font.Size := OptionsBarFontSize;
  FRecolorSamplingCombo.Font.Color := ChromeTextColor;
  FRecolorSamplingCombo.Hint := TR('Source sampling behavior for recolor strokes', '重着色笔划的源采样方式');
  FRecolorSamplingCombo.ShowHint := True;

  FRecolorModeLabel := TLabel.Create(FOptionsBarPanel);
  FRecolorModeLabel.Parent := FOptionsBarPanel;
  FRecolorModeLabel.Caption := TR('Mode:', '模式：');
  FRecolorModeLabel.Font.Size := OptionsBarFontSize;
  FRecolorModeLabel.Font.Color := ChromeTextColor;
  FRecolorModeLabel.Left := 958;
  FRecolorModeLabel.Top := OptionsBarLabelTop;
  FRecolorModeLabel.Visible := False;

  FRecolorModeCombo := TComboBox.Create(FOptionsBarPanel);
  FRecolorModeCombo.Parent := FOptionsBarPanel;
  FRecolorModeCombo.Left := 1004;
  FRecolorModeCombo.Top := OptionsBarControlTop;
  FRecolorModeCombo.Height := OptionsBarControlHeight;
  FRecolorModeCombo.Width := 112;
  FRecolorModeCombo.Style := csDropDownList;
  FRecolorModeCombo.Items.Add(TR('Color', '颜色'));
  FRecolorModeCombo.Items.Add(TR('Hue', '色相'));
  FRecolorModeCombo.Items.Add(TR('Saturation', '饱和度'));
  FRecolorModeCombo.Items.Add(TR('Luminosity', '明度'));
  FRecolorModeCombo.Items.Add(TR('Replace (Compat)', '替换（兼容）'));
  FRecolorModeCombo.ItemIndex := 0;
  FRecolorModeCombo.Visible := False;
  FRecolorModeCombo.OnChange := @RecolorModeChanged;
  FRecolorModeCombo.Color := clWhite;
  FRecolorModeCombo.Font.Size := OptionsBarFontSize;
  FRecolorModeCombo.Font.Color := ChromeTextColor;
  FRecolorModeCombo.Hint := TR('How recolor mixes target color into matching pixels', '重着色将目标色混入匹配像素的方式');
  FRecolorModeCombo.ShowHint := True;

  { Mosaic tool block size }
  FMosaicBlockLabel := TLabel.Create(FOptionsBarPanel);
  FMosaicBlockLabel.Parent := FOptionsBarPanel;
  FMosaicBlockLabel.Left := 0;
  FMosaicBlockLabel.Top := OptionsBarLabelTop;
  FMosaicBlockLabel.Caption := TR('Block:', '块大小：');
  FMosaicBlockLabel.Font.Size := OptionsBarFontSize;
  FMosaicBlockLabel.Font.Color := ChromeTextColor;
  FMosaicBlockLabel.Visible := False;

  FMosaicBlockSpin := TSpinEdit.Create(FOptionsBarPanel);
  FMosaicBlockSpin.Parent := FOptionsBarPanel;
  FMosaicBlockSpin.Left := 0;
  FMosaicBlockSpin.Top := OptionsBarControlTop;
  FMosaicBlockSpin.Width := 60;
  FMosaicBlockSpin.Height := OptionsBarControlHeight;
  FMosaicBlockSpin.Font.Size := OptionsBarFontSize;
  FMosaicBlockSpin.MinValue := 2;
  FMosaicBlockSpin.MaxValue := 64;
  FMosaicBlockSpin.Value := FMosaicBlockSize;
  FMosaicBlockSpin.Visible := False;
  FMosaicBlockSpin.OnChange := @MosaicBlockSpinChanged;

  { Color picker sample source combo }
  FPickerSampleLabel := TLabel.Create(FOptionsBarPanel);
  FPickerSampleLabel.Parent := FOptionsBarPanel;
  FPickerSampleLabel.Caption := TR('Sample:', '采样：');
  FPickerSampleLabel.Font.Size := OptionsBarFontSize;
  FPickerSampleLabel.Font.Color := ChromeTextColor;
  FPickerSampleLabel.Left := 348;
  FPickerSampleLabel.Top := OptionsBarLabelTop;
  FPickerSampleLabel.Visible := False;

  FPickerSampleCombo := TComboBox.Create(FOptionsBarPanel);
  FPickerSampleCombo.Parent := FOptionsBarPanel;
  FPickerSampleCombo.Left := 400;
  FPickerSampleCombo.Top := OptionsBarControlTop;
  FPickerSampleCombo.Height := OptionsBarControlHeight;
  FPickerSampleCombo.Width := 120;
  FPickerSampleCombo.Style := csDropDownList;
  FPickerSampleCombo.Items.Add(TR('Current Layer', '当前图层'));
  FPickerSampleCombo.Items.Add(TR('All Layers', '所有图层'));
  FPickerSampleCombo.ItemIndex := 0;
  FPickerSampleCombo.Visible := False;
  FPickerSampleCombo.OnChange := @PickerSampleComboChanged;
  FPickerSampleCombo.Color := clWhite;
  FPickerSampleCombo.Font.Size := OptionsBarFontSize;
  FPickerSampleCombo.Font.Color := ChromeTextColor;
  FPickerSampleCombo.Hint := TR('Pick color from layer or composite image', '从当前图层或合成图像取色');
  FPickerSampleCombo.ShowHint := True;

  { Crop tool aspect combo }
  FCropAspectLabel := TLabel.Create(FOptionsBarPanel);
  FCropAspectLabel.Parent := FOptionsBarPanel;
  FCropAspectLabel.Caption := TR('Aspect:', '比例：');
  FCropAspectLabel.Font.Size := OptionsBarFontSize;
  FCropAspectLabel.Font.Color := ChromeTextColor;
  FCropAspectLabel.Left := 348;
  FCropAspectLabel.Top := OptionsBarLabelTop;
  FCropAspectLabel.Visible := False;

  FCropAspectCombo := TComboBox.Create(FOptionsBarPanel);
  FCropAspectCombo.Parent := FOptionsBarPanel;
  FCropAspectCombo.Left := 404;
  FCropAspectCombo.Top := OptionsBarControlTop;
  FCropAspectCombo.Height := OptionsBarControlHeight;
  FCropAspectCombo.Width := 132;
  FCropAspectCombo.Style := csDropDownList;
  FCropAspectCombo.Items.Add(TR('Free', '自由'));
  FCropAspectCombo.Items.Add('1:1');
  FCropAspectCombo.Items.Add('4:3');
  FCropAspectCombo.Items.Add('16:9');
  FCropAspectCombo.Items.Add(TR('Current Image', '当前图像'));
  FCropAspectCombo.ItemIndex := EnsureRange(FCropAspectMode, 0, 4);
  FCropAspectCombo.Visible := False;
  FCropAspectCombo.OnChange := @CropAspectComboChanged;
  FCropAspectCombo.Color := clWhite;
  FCropAspectCombo.Font.Size := OptionsBarFontSize;
  FCropAspectCombo.Font.Color := ChromeTextColor;
  FCropAspectCombo.Hint := TR('Crop aspect constraint', '裁剪宽高比例约束');
  FCropAspectCombo.ShowHint := True;

  FCropGuideLabel := TLabel.Create(FOptionsBarPanel);
  FCropGuideLabel.Parent := FOptionsBarPanel;
  FCropGuideLabel.Caption := TR('Guide:', '参考线：');
  FCropGuideLabel.Font.Size := OptionsBarFontSize;
  FCropGuideLabel.Font.Color := ChromeTextColor;
  FCropGuideLabel.Left := 542;
  FCropGuideLabel.Top := OptionsBarLabelTop;
  FCropGuideLabel.Visible := False;

  FCropGuideCombo := TComboBox.Create(FOptionsBarPanel);
  FCropGuideCombo.Parent := FOptionsBarPanel;
  FCropGuideCombo.Left := 596;
  FCropGuideCombo.Top := OptionsBarControlTop;
  FCropGuideCombo.Height := OptionsBarControlHeight;
  FCropGuideCombo.Width := 132;
  FCropGuideCombo.Style := csDropDownList;
  FCropGuideCombo.Items.Add(TR('None', '无'));
  FCropGuideCombo.Items.Add(TR('Thirds', '三分线'));
  FCropGuideCombo.Items.Add(TR('Center', '中心线'));
  FCropGuideCombo.ItemIndex := EnsureRange(FCropGuideMode, 0, 2);
  FCropGuideCombo.Visible := False;
  FCropGuideCombo.OnChange := @CropGuideComboChanged;
  FCropGuideCombo.Color := clWhite;
  FCropGuideCombo.Font.Size := OptionsBarFontSize;
  FCropGuideCombo.Font.Color := ChromeTextColor;
  FCropGuideCombo.Hint := TR('Crop composition guide overlay', '裁剪构图辅助线');
  FCropGuideCombo.ShowHint := True;

  { Rounded rectangle corner radius }
  FRoundedRadiusLabel := TLabel.Create(FOptionsBarPanel);
  FRoundedRadiusLabel.Parent := FOptionsBarPanel;
  FRoundedRadiusLabel.Caption := TR('Corner:', '圆角：');
  FRoundedRadiusLabel.Font.Size := OptionsBarFontSize;
  FRoundedRadiusLabel.Font.Color := ChromeTextColor;
  FRoundedRadiusLabel.Left := 734;
  FRoundedRadiusLabel.Top := OptionsBarLabelTop;
  FRoundedRadiusLabel.Visible := False;

  FRoundedRadiusSpin := TSpinEdit.Create(FOptionsBarPanel);
  FRoundedRadiusSpin.Parent := FOptionsBarPanel;
  FRoundedRadiusSpin.Left := 790;
  FRoundedRadiusSpin.Top := OptionsBarControlTop;
  FRoundedRadiusSpin.Height := OptionsBarControlHeight;
  FRoundedRadiusSpin.Width := 72;
  FRoundedRadiusSpin.MinValue := 1;
  FRoundedRadiusSpin.MaxValue := 1024;
  FRoundedRadiusSpin.Value := FRoundedCornerRadius;
  FRoundedRadiusSpin.Visible := False;
  FRoundedRadiusSpin.OnChange := @RoundedRadiusSpinChanged;
  FRoundedRadiusSpin.Font.Size := OptionsBarFontSize;
  FRoundedRadiusSpin.Font.Color := ChromeTextColor;
  FRoundedRadiusSpin.Hint := TR('Rounded rectangle corner radius (px)', '圆角矩形角半径（像素）');
  FRoundedRadiusSpin.ShowHint := True;

  { Selection anti-alias checkbox }
  FSelAntiAliasCheck := TCheckBox.Create(FOptionsBarPanel);
  FSelAntiAliasCheck.Parent := FOptionsBarPanel;
  FSelAntiAliasCheck.Left := 500;
  FSelAntiAliasCheck.Top := OptionsBarCheckTop;
  FSelAntiAliasCheck.Width := 90;
  FSelAntiAliasCheck.Font.Size := OptionsBarFontSize;
  FSelAntiAliasCheck.Caption := TR('Anti-alias', '抗锯齿');
  FSelAntiAliasCheck.Checked := FSelAntiAlias;
  FSelAntiAliasCheck.Visible := False;
  FSelAntiAliasCheck.OnChange := @SelAntiAliasChanged;
  FSelAntiAliasCheck.Hint := TR('Smooth selection edges', '平滑选区边缘');
  FSelAntiAliasCheck.ShowHint := True;

  FSelFeatherLabel := TLabel.Create(FOptionsBarPanel);
  FSelFeatherLabel.Parent := FOptionsBarPanel;
  FSelFeatherLabel.Caption := TR('Feather:', '羽化：');
  FSelFeatherLabel.Left := 596;
  FSelFeatherLabel.Top := OptionsBarLabelTop;
  FSelFeatherLabel.Font.Size := OptionsBarFontSize;
  FSelFeatherLabel.Font.Color := ChromeTextColor;
  FSelFeatherLabel.Visible := False;

  FSelFeatherSpin := TSpinEdit.Create(FOptionsBarPanel);
  FSelFeatherSpin.Parent := FOptionsBarPanel;
  FSelFeatherSpin.Left := 656;
  FSelFeatherSpin.Top := OptionsBarControlTop;
  FSelFeatherSpin.Height := OptionsBarControlHeight;
  FSelFeatherSpin.Width := 60;
  FSelFeatherSpin.MinValue := 0;
  FSelFeatherSpin.MaxValue := 128;
  FSelFeatherSpin.Value := FSelFeather;
  FSelFeatherSpin.Visible := False;
  FSelFeatherSpin.OnChange := @SelFeatherSpinChanged;
  FSelFeatherSpin.Font.Size := OptionsBarFontSize;
  FSelFeatherSpin.Font.Color := ChromeTextColor;

  { Selection corner radius (rounded rectangle selection) }
  FSelCornerRadiusLabel := TLabel.Create(FOptionsBarPanel);
  FSelCornerRadiusLabel.Parent := FOptionsBarPanel;
  FSelCornerRadiusLabel.Caption := TR('Radius:', '圆角：');
  FSelCornerRadiusLabel.Left := 720;
  FSelCornerRadiusLabel.Top := OptionsBarLabelTop;
  FSelCornerRadiusLabel.Font.Size := OptionsBarFontSize;
  FSelCornerRadiusLabel.Font.Color := ChromeTextColor;
  FSelCornerRadiusLabel.Visible := False;

  FSelCornerRadiusSpin := TSpinEdit.Create(FOptionsBarPanel);
  FSelCornerRadiusSpin.Parent := FOptionsBarPanel;
  FSelCornerRadiusSpin.Left := 780;
  FSelCornerRadiusSpin.Top := OptionsBarControlTop;
  FSelCornerRadiusSpin.Height := OptionsBarControlHeight;
  FSelCornerRadiusSpin.Width := 60;
  FSelCornerRadiusSpin.MinValue := 0;
  FSelCornerRadiusSpin.MaxValue := 500;
  FSelCornerRadiusSpin.Value := FSelCornerRadius;
  FSelCornerRadiusSpin.Visible := False;
  FSelCornerRadiusSpin.OnChange := @SelCornerRadiusSpinChanged;
  FSelCornerRadiusSpin.Font.Size := OptionsBarFontSize;
  FSelCornerRadiusSpin.Font.Color := ChromeTextColor;
  FSelCornerRadiusSpin.Hint := TR('Rounded corner radius for rectangle selection (0=sharp)', '矩形选区圆角半径（0=直角）');
  FSelCornerRadiusSpin.ShowHint := True;

  UpdateToolOptionControl;
  UpdateZoomControls;
end;

procedure TMainForm.BuildSidePanel;
var
  ToolIndex: Integer;
  VisibleToolIndex: Integer;
  ToolKind: TToolKind;
  ColumnIndex: Integer;
  RowIndex: Integer;
  ContentTop: Integer;
  ToolButton: TSpeedButton;
const
  ToolButtonWidth = 44;
  ToolButtonHeight = 40;
  ToolColumnStride = 46;
  ToolRowStride = 42;
begin
  ContentTop := PaletteHeaderHeight + 8;
  VisibleToolIndex := 0;

  FToolsPanel := TPanel.Create(Self);
  CreatePalette(FToolsPanel, pkTools);
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
  begin
    ToolKind := PaintToolAtDisplayIndex(ToolIndex);
    if ToolKind = tkZoom then
      Continue;
    ColumnIndex := VisibleToolIndex mod ToolsPaletteColumnCount;
    RowIndex := VisibleToolIndex div ToolsPaletteColumnCount;
    ToolButton := CreateButton(
      PaintToolGlyph(ToolKind),
      8 + ColumnIndex * ToolColumnStride,
      ContentTop + RowIndex * ToolRowStride,
      ToolButtonWidth,
      @ToolButtonClick,
      FToolsPanel,
      Ord(ToolKind),
      bicTool
    );
    FToolButtons[ToolKind] := ToolButton;
    ToolButton.Height := ToolButtonHeight;
    ToolButton.Flat := True;
    ToolButton.GroupIndex := 1;
    ToolButton.AllowAllUp := False;
    { Set hint BEFORE overlay so the overlay copies the correct text }
    ToolButton.Hint := PaintToolDisplayLabel(ToolKind) + ' — ' + PaintToolHint(ToolKind);
    if AttachButtonIconOverlay(ToolButton, PaintToolGlyph(ToolKind), bicTool, ColorToRGB(FToolsPanel.Color)) then
    begin
      RealignButtonIconOverlay(ToolButton, bicTool);
      ToolButton.Caption := ''
    end
    else
      ToolButton.Caption := PaintToolGlyph(ToolKind);
    ToolButton.Font.Size := 9;
    Inc(VisibleToolIndex);
  end;
  SyncToolButtonSelection;

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
  FColorTargetCombo.Items.Add(TR('Primary', '前景色'));
  FColorTargetCombo.Items.Add(TR('Secondary', '背景色'));
  FColorTargetCombo.ItemIndex := 0;
  FColorTargetCombo.Visible := False;
  FColorTargetCombo.OnChange := @ColorTargetComboChanged;
  { ── FG / BG swatch pair ─────────────────────────────────────────────── }
  FColorsBox := TPaintBox.Create(FColorsPanel);
  FColorsBox.Parent := FColorsPanel;
  FColorsBox.OnPaint := @ColorsBoxPaint;
  FColorsBox.OnMouseDown := @ColorsBoxMouseDown;
  FColorsBox.OnMouseMove := @ColorsBoxMouseMove;

  { Swap / Reset buttons beside the swatch pair }
  ToolButton := CreateButton('Swap', 78, ContentTop, 28, @SwapColorsClick, FColorsPanel, 0, bicCommand);
  ToolButton.Hint := TR('Swap primary and secondary colors (X)', '交换前景色和背景色 (X)');
  ToolButton := CreateButton('Mono', 110, ContentTop, 28, @ResetColorsClick, FColorsPanel, 0, bicCommand);
  ToolButton.Hint := TR('Reset colors to black and white (D)', '重置为黑白默认颜色 (D)');

  { ── Expand / Collapse toggle ──────────────────────────────────────── }
  FColorExpanded := False;
  FColorExpandButton := TButton.Create(FColorsPanel);
  FColorExpandButton.Parent := FColorsPanel;
  FColorExpandButton.Caption := TR('Normal >>', #$E5#$B8#$B8#$E8#$A7#$84 + ' >>');
  FColorExpandButton.OnClick := @ColorExpandButtonClick;
  FColorExpandButton.Font.Size := 9;
  FColorExpandButton.Width := 72;
  FColorExpandButton.Height := 22;

  { ── Color wheel ─────────────────────────────────────────────────────── }
  FColorWheelBox := TPaintBox.Create(FColorsPanel);
  FColorWheelBox.Parent := FColorsPanel;
  FColorWheelBox.OnPaint := @ColorWheelBoxPaint;
  FColorWheelBox.OnMouseDown := @ColorWheelBoxMouseDown;
  FColorWheelBox.OnMouseMove := @ColorWheelBoxMouseMove;
  FColorWheelBox.OnMouseUp := @ColorWheelBoxMouseUp;
  FColorWheelBitmap := TBitmap.Create;
  FColorSVBitmap := TBitmap.Create;
  FColorSVCachedHue := -1.0;
  FColorSVRenderedHue := -1.0;
  FColorWheelDragMode := 0;

  { ── Detail gradient bars (RGB / HSV / Alpha) ────────────────────────── }
  FColorDetailBox := TPaintBox.Create(FColorsPanel);
  FColorDetailBox.Parent := FColorsPanel;
  FColorDetailBox.Visible := False;
  FColorDetailBox.OnPaint := @ColorDetailBoxPaint;
  FColorDetailBox.OnMouseDown := @ColorDetailBoxMouseDown;
  FColorDetailBox.OnMouseMove := @ColorDetailBoxMouseMove;
  FColorDetailBox.OnMouseUp := @ColorDetailBoxMouseUp;
  FColorDetailDragBar := -1;

  { ── RGB spin edits ──────────────────────────────────────────────────── }
  FColorRSpin := TSpinEdit.Create(FColorsPanel);
  FColorRSpin.Parent := FColorsPanel;
  FColorRSpin.MinValue := 0; FColorRSpin.MaxValue := 255;
  FColorRSpin.Width := 52; FColorRSpin.Height := 22;
  FColorRSpin.Visible := False;
  FColorRSpin.Font.Size := 9; FColorRSpin.Font.Color := ChromeTextColor;
  FColorRSpin.Color := clWhite;
  FColorRSpin.OnChange := @ColorSpinChanged;

  FColorGSpin := TSpinEdit.Create(FColorsPanel);
  FColorGSpin.Parent := FColorsPanel;
  FColorGSpin.MinValue := 0; FColorGSpin.MaxValue := 255;
  FColorGSpin.Width := 52; FColorGSpin.Height := 22;
  FColorGSpin.Visible := False;
  FColorGSpin.Font.Size := 9; FColorGSpin.Font.Color := ChromeTextColor;
  FColorGSpin.Color := clWhite;
  FColorGSpin.OnChange := @ColorSpinChanged;

  FColorBSpin := TSpinEdit.Create(FColorsPanel);
  FColorBSpin.Parent := FColorsPanel;
  FColorBSpin.MinValue := 0; FColorBSpin.MaxValue := 255;
  FColorBSpin.Width := 52; FColorBSpin.Height := 22;
  FColorBSpin.Visible := False;
  FColorBSpin.Font.Size := 9; FColorBSpin.Font.Color := ChromeTextColor;
  FColorBSpin.Color := clWhite;
  FColorBSpin.OnChange := @ColorSpinChanged;

  { ── HSV spin edits ──────────────────────────────────────────────────── }
  FColorHSpin := TSpinEdit.Create(FColorsPanel);
  FColorHSpin.Parent := FColorsPanel;
  FColorHSpin.MinValue := 0; FColorHSpin.MaxValue := 360;
  FColorHSpin.Width := 52; FColorHSpin.Height := 22;
  FColorHSpin.Visible := False;
  FColorHSpin.Font.Size := 9; FColorHSpin.Font.Color := ChromeTextColor;
  FColorHSpin.Color := clWhite;
  FColorHSpin.OnChange := @ColorHSVSpinChanged;

  FColorSSpin := TSpinEdit.Create(FColorsPanel);
  FColorSSpin.Parent := FColorsPanel;
  FColorSSpin.MinValue := 0; FColorSSpin.MaxValue := 100;
  FColorSSpin.Width := 52; FColorSSpin.Height := 22;
  FColorSSpin.Visible := False;
  FColorSSpin.Font.Size := 9; FColorSSpin.Font.Color := ChromeTextColor;
  FColorSSpin.Color := clWhite;
  FColorSSpin.OnChange := @ColorHSVSpinChanged;

  FColorVSpin := TSpinEdit.Create(FColorsPanel);
  FColorVSpin.Parent := FColorsPanel;
  FColorVSpin.MinValue := 0; FColorVSpin.MaxValue := 100;
  FColorVSpin.Width := 52; FColorVSpin.Height := 22;
  FColorVSpin.Visible := False;
  FColorVSpin.Font.Size := 9; FColorVSpin.Font.Color := ChromeTextColor;
  FColorVSpin.Color := clWhite;
  FColorVSpin.OnChange := @ColorHSVSpinChanged;

  { ── Alpha spin edit ─────────────────────────────────────────────────── }
  FColorASpin := TSpinEdit.Create(FColorsPanel);
  FColorASpin.Parent := FColorsPanel;
  FColorASpin.MinValue := 0; FColorASpin.MaxValue := 255;
  FColorASpin.Width := 52; FColorASpin.Height := 22;
  FColorASpin.Visible := False;
  FColorASpin.Font.Size := 9; FColorASpin.Font.Color := ChromeTextColor;
  FColorASpin.Color := clWhite;
  FColorASpin.OnChange := @ColorSpinChanged;

  { ── Hex edit ────────────────────────────────────────────────────────── }
  FColorHexEdit := TEdit.Create(FColorsPanel);
  FColorHexEdit.Parent := FColorsPanel;
  FColorHexEdit.Visible := False;
  FColorHexEdit.Width := 80; FColorHexEdit.Height := 22;
  FColorHexEdit.Font.Size := 9; FColorHexEdit.Font.Color := ChromeTextColor;
  FColorHexEdit.Color := clWhite;
  FColorHexEdit.OnEditingDone := @ColorHexChanged;

  { ── Swatch grid (96-colour palette) ─────────────────────────────────── }
  FSwatchBox := TPaintBox.Create(FColorsPanel);
  FSwatchBox.Parent := FColorsPanel;
  FSwatchBox.OnPaint := @SwatchBoxPaint;
  FSwatchBox.OnMouseDown := @SwatchBoxMouseDown;

  FColorsPanel.OnResize := @ColorsPanelResize;
  LayoutColorsPanel;
  RefreshColorsPanel;

  FHistoryPanel := TPanel.Create(Self);
  CreatePalette(FHistoryPanel, pkHistory);
  CreateButton('Undo', 12, ContentTop, 26, @UndoClick, FHistoryPanel, 0, bicCommand);
  CreateButton('Redo', 42, ContentTop, 26, @RedoClick, FHistoryPanel, 0, bicCommand);
  FHistoryList := TListBox.Create(FHistoryPanel);
  FHistoryList.Parent := FHistoryPanel;
  FHistoryList.BorderStyle := bsNone;
  FHistoryList.Left := 12;
  FHistoryList.Top := ContentTop + 30;
  FHistoryList.Width := 212;
  FHistoryList.Height := FHistoryPanel.Height - (ContentTop + 42);
  FHistoryList.Anchors := [akTop, akLeft, akRight, akBottom];
  FHistoryList.Color := PaletteListBackgroundColor;
  FHistoryList.Font.Color := ChromeTextColor;
  FHistoryList.Font.Size := 9;
  FHistoryList.Style := lbOwnerDrawFixed;
  FHistoryList.ItemHeight := 20;
  FHistoryList.OnClick := @HistoryListClick;
  FHistoryList.OnDrawItem := @HistoryListDrawItem;
  FPSetListBackground(Pointer(FHistoryList.Handle), 1.0, 1.0, 1.0);
  RefreshHistoryPanel;

  FRightPanel := TPanel.Create(Self);
  CreatePalette(FRightPanel, pkLayers);

  { Row 1: Add / Duplicate / Delete / Merge / Up / Down }
  CreateButton('+', 12, ContentTop, 26, @AddLayerClick, FRightPanel, 0, bicCommand).Hint := TR('Add new layer', '添加新图层');
  CreateButton('Dup', 42, ContentTop, 26, @DuplicateLayerClick, FRightPanel, 0, bicCommand).Hint := TR('Duplicate layer', '复制图层');
  CreateButton('Del', 72, ContentTop, 26, @DeleteLayerClick, FRightPanel, 0, bicCommand).Hint := TR('Delete layer', '删除图层');
  CreateButton('Mrg', 102, ContentTop, 26, @MergeDownClick, FRightPanel, 0, bicCommand).Hint := TR('Merge down', '向下合并');
  CreateButton('Up', 132, ContentTop, 26, @MoveLayerDownClick, FRightPanel, 0, bicCommand).Hint := TR('Move layer up in list', '图层上移');
  CreateButton('Dn', 162, ContentTop, 26, @MoveLayerUpClick, FRightPanel, 0, bicCommand).Hint := TR('Move layer down in list', '图层下移');

  { Row 2: Flatten / Rename / Properties }
  CreateButton('Flat', 12, ContentTop + 28, 26, @FlattenClick, FRightPanel, 0, bicCommand).Hint := TR('Flatten image', '合并图像');
  CreateButton('Name', 42, ContentTop + 28, 26, @RenameLayerClick, FRightPanel, 0, bicCommand).Hint := TR('Rename layer', '重命名图层');
  FLayerPropsButton := CreateButton('Props', 72, ContentTop + 28, 26, @LayerPropertiesClick, FRightPanel, 0, bicCommand);
  FLayerPropsButton.Hint := TR('Layer properties', '图层属性');

  FLayerBlendCombo := TComboBox.Create(FRightPanel);
  FLayerBlendCombo.Parent := FRightPanel;
  FLayerBlendCombo.Left := 12;
  FLayerBlendCombo.Top := ContentTop + 56;
  FLayerBlendCombo.Width := 220;
  FLayerBlendCombo.Style := csDropDownList;
  FLayerBlendCombo.Items.Add(TR('Normal', '正常'));
  FLayerBlendCombo.Items.Add(TR('Multiply', '正片叠底'));
  FLayerBlendCombo.Items.Add(TR('Screen', '滤色'));
  FLayerBlendCombo.Items.Add(TR('Overlay', '叠加'));
  FLayerBlendCombo.Items.Add(TR('Darken', '变暗'));
  FLayerBlendCombo.Items.Add(TR('Lighten', '变亮'));
  FLayerBlendCombo.Items.Add(TR('Difference', '差值'));
  FLayerBlendCombo.Items.Add(TR('Soft Light', '柔光'));
  FLayerBlendCombo.ItemIndex := 0;
  FLayerBlendCombo.OnChange := @LayerBlendModeChanged;
  FLayerBlendCombo.Color := clWhite;
  FLayerBlendCombo.Font.Color := ChromeTextColor;

  FLayerOpacityLabel := TLabel.Create(FRightPanel);
  FLayerOpacityLabel.Parent := FRightPanel;
  FLayerOpacityLabel.Caption := TR('Opacity:', '不透明度：');
  FLayerOpacityLabel.Font.Color := ChromeTextColor;
  FLayerOpacityLabel.Left := 12;
  FLayerOpacityLabel.Top := ContentTop + 85;

  FLayerOpacitySpin := TSpinEdit.Create(FRightPanel);
  FLayerOpacitySpin.Parent := FRightPanel;
  FLayerOpacitySpin.Left := 68;
  FLayerOpacitySpin.Top := ContentTop + 82;
  FLayerOpacitySpin.Width := 72;
  FLayerOpacitySpin.MinValue := 0;
  FLayerOpacitySpin.MaxValue := 100;
  FLayerOpacitySpin.OnChange := @LayerOpacitySpinChanged;
  FLayerOpacitySpin.Font.Color := ChromeTextColor;

  FLayerList := TDrawGrid.Create(FRightPanel);
  FLayerList.Parent := FRightPanel;
  FLayerList.BorderStyle := bsNone;
  FLayerList.Left := 12;
  FLayerList.Top := ContentTop + 108;
  FLayerList.Width := 220;
  FLayerList.Height := FRightPanel.Height - (ContentTop + 120);
  FLayerList.Anchors := [akTop, akLeft, akRight, akBottom];
  FLayerList.Color := PaletteListBackgroundColor;
  FLayerList.Font.Color := ChromeTextColor;
  FLayerList.Font.Size := 9;
  FLayerList.FixedCols := 0;
  FLayerList.FixedRows := 0;
  FLayerList.ColCount := 4;
  FLayerList.RowCount := 1;
  FLayerList.DefaultRowHeight := LayerRowHeight;
  FLayerList.ScrollBars := ssVertical;
  FLayerList.Options := [goRowSelect, goThumbTracking];
  LayerGridApplyColumnWidths(FLayerList);
  FLayerList.OnDrawCell := @LayerListDrawCell;
  FLayerList.OnClick := @LayerListClick;
  FLayerList.OnDblClick := @LayerListDblClick;
  FLayerList.OnMouseDown := @LayerListMouseDown;
  FLayerList.OnMouseMove := @LayerListMouseMove;
  FLayerList.OnMouseUp := @LayerListMouseUp;
  FPSetListBackground(Pointer(FLayerList.Handle), 1.0, 1.0, 1.0);
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
  else if ACaption = 'Up' then
    Result := '↑'
  else if ACaption = 'Dn' then
    Result := '↓'
  else if ACaption = 'Flat' then
    Result := '▤'
  else if ACaption = 'Name' then
    Result := '✎'
  else if ACaption = 'Props' then
    Result := '⚙';
end;

procedure TMainForm.ButtonIconOverlayClick(Sender: TObject);
var
  TargetButton: TSpeedButton;
begin
  if not (Sender is TControl) then
    Exit;
  if TControl(Sender).Tag = 0 then
    Exit;
  TargetButton := TSpeedButton(Pointer(PtrUInt(TControl(Sender).Tag)));
  if not Assigned(TargetButton) then
    Exit;
  TargetButton.Click;
end;

function TMainForm.FindButtonIconOverlay(AButton: TSpeedButton): TImage;
var
  ControlIndex: Integer;
  ParentControl: TWinControl;
begin
  Result := nil;
  if (AButton = nil) or not Assigned(AButton.Parent) then
    Exit;
  ParentControl := AButton.Parent;
  for ControlIndex := ParentControl.ControlCount - 1 downto 0 do
    if (ParentControl.Controls[ControlIndex] is TImage) and
       (ParentControl.Controls[ControlIndex].Tag = PtrInt(AButton)) then
      Exit(TImage(ParentControl.Controls[ControlIndex]));
end;

procedure TMainForm.PositionButtonIconOverlay(
  AButton: TSpeedButton;
  AIconImage: TImage;
  AContext: TButtonIconContext
);
var
  IconLeft: Integer;
  IconTop: Integer;
  TargetIconSize: Integer;
  ScaledIconSize: Integer;
  FitLimit: Integer;
  IsLargeCommand: Boolean;
  procedure ApplyTargetSize(ASize: Integer);
  begin
    ASize := Max(8, ASize);
    { Keep scaling enabled even after relayout retries: @2x sources may stay
      larger than the logical icon box, and disabling Stretch causes clipping. }
    AIconImage.Stretch := True;
    AIconImage.Proportional := True;
    AIconImage.Center := True;
    if (AIconImage.Width <> ASize) or (AIconImage.Height <> ASize) then
    begin
      AIconImage.Width := ASize;
      AIconImage.Height := ASize;
    end;
  end;
begin
  if (AButton = nil) or (AIconImage = nil) then
    Exit;

  FitLimit := Max(8, Min(AButton.Width, AButton.Height) - 8);
  ScaledIconSize := Max(
    ToolbarLargeCommandMaxIconSize,
    AButton.Scale96ToScreen(ToolbarLargeCommandMaxIconSize)
  );
  IsLargeCommand := (AContext = bicCommand) and (AButton.Width >= 54);
  if IsLargeCommand then
    TargetIconSize := Min(ToolbarLargeCommandMaxIconSize, FitLimit)
  else
    TargetIconSize := Min(ScaledIconSize, FitLimit);
  ApplyTargetSize(TargetIconSize);

  if IsLargeCommand then
  begin
    IconLeft := AButton.Left + ToolbarLargeCommandIconLeft;
  end
  else
    IconLeft := AButton.Left + Max(0, (AButton.Width - AIconImage.Width) div 2);
  IconTop := AButton.Top + Max(0, (AButton.Height - AIconImage.Height) div 2);
  AIconImage.SetBounds(IconLeft, IconTop, AIconImage.Width, AIconImage.Height);
end;

procedure TMainForm.RealignButtonIconOverlay(
  AButton: TSpeedButton;
  AContext: TButtonIconContext
);
var
  IconImage: TImage;
begin
  IconImage := FindButtonIconOverlay(AButton);
  if not Assigned(IconImage) then
    Exit;
  PositionButtonIconOverlay(AButton, IconImage, AContext);
end;

procedure TMainForm.RelayoutButtonIconOverlays;
  function ContextForButton(AButton: TSpeedButton): TButtonIconContext;
  var
    ToolKind: TToolKind;
    UtilityCommand: TUtilityCommandKind;
  begin
    for ToolKind := Low(TToolKind) to High(TToolKind) do
      if FToolButtons[ToolKind] = AButton then
        Exit(bicTool);
    for UtilityCommand := Low(TUtilityCommandKind) to High(TUtilityCommandKind) do
      if FUtilityButtons[UtilityCommand] = AButton then
        Exit(bicUtility);
    Result := bicCommand;
  end;

  procedure RelayoutInControl(AControl: TControl);
  var
    ChildIndex: Integer;
    WinControl: TWinControl;
  begin
    if not Assigned(AControl) then
      Exit;
    if AControl is TSpeedButton then
      RealignButtonIconOverlay(TSpeedButton(AControl), ContextForButton(TSpeedButton(AControl)));
    if AControl is TWinControl then
    begin
      WinControl := TWinControl(AControl);
      for ChildIndex := 0 to WinControl.ControlCount - 1 do
        RelayoutInControl(WinControl.Controls[ChildIndex]);
    end;
  end;
begin
  RelayoutInControl(FTopPanel);
  RelayoutInControl(FToolsPanel);
  RelayoutInControl(FColorsPanel);
  RelayoutInControl(FHistoryPanel);
  RelayoutInControl(FRightPanel);
end;

procedure TMainForm.RelayoutTopChrome;
begin
  if not Assigned(FTopPanel) then
    Exit;
  LayoutOptionRow;
  RelayoutButtonIconOverlays;
end;

function TMainForm.AttachButtonIconOverlay(
  AButton: TSpeedButton;
  const ACaption: string;
  AContext: TButtonIconContext;
  ABackgroundColor: TColor
): Boolean;
var
  IconBitmap: TBitmap;
  IconImage: TImage;
begin
  Result := False;
  if (AButton = nil) or not Assigned(AButton.Parent) then
    Exit;
  IconBitmap := nil;
  IconImage := TImage.Create(AButton.Parent);
  try
    IconImage.Parent := AButton.Parent;
    IconImage.AutoSize := False;
    { Keep scaling/centering enabled from creation time so the first paint
      cannot show cropped @2x quadrants before relayout settles. }
    IconImage.Stretch := True;
    IconImage.Proportional := True;
    IconImage.Center := True;
    IconImage.Transparent := True;
    if TryLoadButtonIconPicture(ACaption, AContext, IconImage.Picture) then
    begin
      IconImage.Width := IconImage.Picture.Width;
      IconImage.Height := IconImage.Picture.Height;
    end
    else
    begin
      IconBitmap := TBitmap.Create;
      if not TryBuildButtonGlyph(ACaption, AContext, IconBitmap, ABackgroundColor) then
        Exit;
      IconImage.Picture.Bitmap.Assign(IconBitmap);
      IconImage.Width := IconBitmap.Width;
      IconImage.Height := IconBitmap.Height;
    end;
    PositionButtonIconOverlay(AButton, IconImage, AContext);
    IconImage.Tag := PtrInt(AButton);
    IconImage.Hint := AButton.Hint;
    IconImage.ShowHint := AButton.ShowHint;
    IconImage.OnClick := nil;
    IconImage.OnDblClick := nil;
    IconImage.Enabled := False;
    Result := True;
  finally
    IconBitmap.Free;
    if not Result then
      IconImage.Free;
  end;
end;

function TMainForm.CreateButton(const ACaption: string; ALeft, ATop, AWidth: Integer; AHandler: TNotifyEvent; AParent: TWinControl; ATag: Integer; AIconContext: TButtonIconContext): TSpeedButton;
  function HostSurfaceColor: TColor;
  begin
    Result := ToolbarBackgroundColor;
    if (AParent = FTopPanel) and (AIconContext in [bicCommand, bicUtility]) then
      Exit(PaletteListBackgroundColor);
    if AParent is TCustomControl then
      Result := ColorToRGB(TCustomControl(AParent).Color);
  end;
var
  ShowIconOverlay: Boolean;
begin
  Result := TSpeedButton.Create(AParent);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  if AIconContext in [bicCommand, bicUtility] then
    Result.Height := ToolbarButtonHeight
  else
    Result.Height := 26;
  Result.Flat := True;
  Result.Tag := ATag;
  Result.OnClick := AHandler;
  Result.ParentFont := False;
  ShowIconOverlay := False;
  if AIconContext in [bicCommand, bicUtility] then
    ShowIconOverlay := AttachButtonIconOverlay(Result, ACaption, AIconContext, HostSurfaceColor);
  if ShowIconOverlay then
  begin
    if (AIconContext = bicCommand) and (AWidth >= 54) then
    begin
      Result.Caption := ToolbarLargeCommandCaptionPrefix + ACaption;
      Result.Font.Size := 10;
      Result.Font.Style := [];
      Result.Margin := 0;
      Result.Spacing := 0;
    end
    else
    begin
      Result.Caption := '';
      Result.Font.Size := 9;
    end;
  end
  else
  begin
    if (AIconContext = bicCommand) and (AWidth >= 54) then
    begin
      Result.Caption := ACaption;
      Result.Font.Size := 10;
      Result.Font.Style := [];
      Result.Margin := 0;
      Result.Spacing := 0;
    end
    else if (AIconContext = bicCommand) and (AWidth > ToolbarCompactButtonWidth) then
    begin
      Result.Caption := ACaption;
      Result.Font.Size := 9;
    end
    else
    begin
      Result.Caption := CompactButtonCaption(ACaption);
      if AIconContext = bicTool then
        Result.Font.Size := 14
      else if AIconContext = bicUtility then
        Result.Font.Size := 12
      else if Length(Result.Caption) <= 4 then
        Result.Font.Size := 10
      else
        Result.Font.Size := 9;
    end;
    if AIconContext = bicTool then
      Result.Font.Size := 14
    else if (AIconContext = bicUtility) and (AWidth < 54) then
      Result.Font.Size := 12
    else if (AIconContext <> bicCommand) and (Length(Result.Caption) <= 4) then
      Result.Font.Size := 10
    else if AIconContext <> bicCommand then
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

function TMainForm.TrySelectionMarqueePixelColor(X, Y: Integer; out AColor: TRGBA32): Boolean;
var
  PixelIndex: Integer;
  DashStep: Integer;
begin
  Result := False;
  if not Assigned(FDocument) or not FDocument.HasSelection then
    Exit;
  EnsureSelectionMarqueeCache;
  if (X < 0) or (Y < 0) or
     (X >= FSelectionMarqueeWidth) or (Y >= FSelectionMarqueeHeight) then
    Exit;
  PixelIndex := Y * FSelectionMarqueeWidth + X;
  if (PixelIndex < 0) or (PixelIndex >= Length(FSelectionMarqueeStepMap)) then
    Exit;
  DashStep := FSelectionMarqueeStepMap[PixelIndex];
  if DashStep < 0 then
    Exit;
  if not MarqueeStepVisible(DashStep, FMarqueeDashPhase) then
    Exit;
  if MarqueeStepUsesDarkColor(DashStep, FMarqueeDashPhase) then
    AColor := RGBA(0, 0, 0, 255)
  else
    AColor := RGBA(255, 255, 255, 255);
  Result := True;
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

  if FCurrentTool = tkCloneStamp then
  begin
    DrawMarqueeEllipseOverlay(ACanvas, LeftX, TopY, RightX, BottomY);
    Exit;
  end;
  if FCurrentTool = tkMagicWand then
  begin
    DrawMarqueeRectangleOverlay(ACanvas, LeftX, TopY, RightX, BottomY);
    Exit;
  end;

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

  if FCurrentTool = tkCloneStamp then
  begin
    DrawMarqueeEllipseOverlay(ACanvas, LeftX, TopY, RightX, BottomY);
    Exit;
  end;

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

procedure TMainForm.DrawEraserHoverOverlay(
  ACanvas: TCanvas;
  const APoint: TPoint;
  ARadius: Integer;
  ASquareShape: Boolean
);
var
  LeftX: Integer;
  TopY: Integer;
  RightX: Integer;
  BottomY: Integer;
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
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Color := clBlack;
  if ASquareShape then
    ACanvas.Rectangle(LeftX, TopY, RightX, BottomY)
  else
    ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);
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
  ACanvas.Pen.Style := psDot;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := clGray;
  ACanvas.MoveTo(SourceX, SourceY);
  ACanvas.LineTo(DestX, DestY);
  ACanvas.Pen.Style := psSolid;
end;

procedure TMainForm.DrawSelectionMarqueeOverlay(ACanvas: TCanvas);
var
  TotalContours: Integer;
  TotalPoints: Integer;
  ContourIndex: Integer;
  Offset: Integer;
  SegmentCount: Integer;
  I: Integer;
  P: TPoint;
  PointsXY: array of Double;
  BatchOffsets: array of LongInt;
  BatchLengths: array of LongInt;
  BatchClosed: array of LongInt;
  DestOffset: Integer;
begin
  if not Assigned(FDocument) or not FDocument.HasSelection then
    Exit;

  EnsureSelectionMarqueeCache;
  TotalContours := Length(FSelectionMarqueeContourOffsets);
  if TotalContours = 0 then
    Exit;

  { Calculate total point count across all contours }
  TotalPoints := 0;
  for ContourIndex := 0 to TotalContours - 1 do
  begin
    SegmentCount := FSelectionMarqueeContourLengths[ContourIndex];
    if SegmentCount <= 0 then
      Continue;
    if SegmentCount = 1 then
      Inc(TotalPoints, 2)  { single-pixel contour: emit 2-point micro-segment }
    else
      Inc(TotalPoints, SegmentCount);
  end;
  if TotalPoints = 0 then
    Exit;

  { Build flat coordinate array and per-contour metadata }
  SetLength(PointsXY, TotalPoints * 2);
  SetLength(BatchOffsets, TotalContours);
  SetLength(BatchLengths, TotalContours);
  SetLength(BatchClosed, TotalContours);

  DestOffset := 0;
  for ContourIndex := 0 to TotalContours - 1 do
  begin
    Offset := FSelectionMarqueeContourOffsets[ContourIndex];
    SegmentCount := FSelectionMarqueeContourLengths[ContourIndex];
    BatchOffsets[ContourIndex] := DestOffset;
    if SegmentCount <= 0 then
    begin
      BatchLengths[ContourIndex] := 0;
      BatchClosed[ContourIndex] := 0;
      Continue;
    end;
    if SegmentCount = 1 then
    begin
      P := FSelectionMarqueePoints[Offset];
      PointsXY[DestOffset * 2] := (P.X + 0.5) * FZoomScale;
      PointsXY[DestOffset * 2 + 1] := (P.Y + 0.5) * FZoomScale;
      PointsXY[(DestOffset + 1) * 2] := (P.X + 0.5) * FZoomScale + 1;
      PointsXY[(DestOffset + 1) * 2 + 1] := (P.Y + 0.5) * FZoomScale;
      BatchLengths[ContourIndex] := 2;
      BatchClosed[ContourIndex] := 0;
      Inc(DestOffset, 2);
    end
    else
    begin
      for I := 0 to SegmentCount - 1 do
      begin
        P := FSelectionMarqueePoints[Offset + I];
        PointsXY[(DestOffset + I) * 2] := (P.X + 0.5) * FZoomScale;
        PointsXY[(DestOffset + I) * 2 + 1] := (P.Y + 0.5) * FZoomScale;
      end;
      BatchLengths[ContourIndex] := SegmentCount;
      BatchClosed[ContourIndex] := 1;
      Inc(DestOffset, SegmentCount);
    end;
  end;

  FPDrawMarchingAntsMultiContour(@PointsXY[0],
    @BatchOffsets[0], @BatchLengths[0], @BatchClosed[0],
    TotalContours, MarqueeSegmentLength, FMarqueeDashPhase);
end;

procedure TMainForm.DrawMarqueeRectangleOverlay(
  ACanvas: TCanvas;
  ALeft, ATop, ARight, ABottom: Integer
);
var
  RectPts: array[0..9] of Double;
begin
  if (ARight <= ALeft) or (ABottom <= ATop) then
    Exit;
  RectPts[0] := ALeft;        RectPts[1] := ATop;
  RectPts[2] := ARight - 1;   RectPts[3] := ATop;
  RectPts[4] := ARight - 1;   RectPts[5] := ABottom - 1;
  RectPts[6] := ALeft;        RectPts[7] := ABottom - 1;
  RectPts[8] := ALeft;        RectPts[9] := ATop;
  FPDrawMarchingAntsPolyline(@RectPts[0], 5,
    MarqueeSegmentLength, FMarqueeDashPhase, 0);
end;

procedure TMainForm.DrawMarqueeEllipseOverlay(
  ACanvas: TCanvas;
  ALeft, ATop, ARight, ABottom: Integer
);
var
  WidthPixels: Integer;
  HeightPixels: Integer;
  RadiusX: Double;
  RadiusY: Double;
  CenterX: Double;
  CenterY: Double;
  StepCount: Integer;
  I: Integer;
  Theta: Double;
  EllipsePts: array of Double;
begin
  WidthPixels := ARight - ALeft;
  HeightPixels := ABottom - ATop;
  if (WidthPixels <= 1) or (HeightPixels <= 1) then
  begin
    DrawMarqueeRectangleOverlay(ACanvas, ALeft, ATop, ARight, ABottom);
    Exit;
  end;

  CenterX := (ALeft + ARight - 1) * 0.5;
  CenterY := (ATop + ABottom - 1) * 0.5;
  RadiusX := Max(0.5, WidthPixels * 0.5);
  RadiusY := Max(0.5, HeightPixels * 0.5);
  StepCount := Max(24, Round(2.0 * Pi * Max(RadiusX, RadiusY)));

  SetLength(EllipsePts, StepCount * 2);
  for I := 0 to StepCount - 1 do
  begin
    Theta := 2.0 * Pi * I / StepCount;
    EllipsePts[I * 2] := CenterX + Cos(Theta) * RadiusX;
    EllipsePts[I * 2 + 1] := CenterY + Sin(Theta) * RadiusY;
  end;
  FPDrawMarchingAntsPolyline(@EllipsePts[0], StepCount,
    MarqueeSegmentLength, FMarqueeDashPhase, 1);
end;

procedure TMainForm.DrawMarqueePolylineOverlay(
  ACanvas: TCanvas;
  const APoints: array of TPoint;
  AClosePath: Boolean
);
var
  I: Integer;
  PtCount: Integer;
  PointsXY: array of Double;
  ClosedFlag: LongInt;
begin
  PtCount := Length(APoints);
  if PtCount < 2 then
    Exit;

  SetLength(PointsXY, PtCount * 2);
  for I := 0 to PtCount - 1 do
  begin
    PointsXY[I * 2] := (APoints[I].X + 0.5) * FZoomScale;
    PointsXY[I * 2 + 1] := (APoints[I].Y + 0.5) * FZoomScale;
  end;
  if AClosePath then
    ClosedFlag := 1
  else
    ClosedFlag := 0;
  FPDrawMarchingAntsPolyline(@PointsXY[0], PtCount,
    MarqueeSegmentLength, FMarqueeDashPhase, ClosedFlag);
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

  if ARadius <= 0 then
    DrawMarqueeRectangleOverlay(ACanvas, LeftX, TopY, RightX, BottomY)
  else
    DrawMarqueeEllipseOverlay(ACanvas, LeftX, TopY, RightX, BottomY);

  CenterX := Round((APoint.X + 0.5) * FZoomScale);
  CenterY := Round((APoint.Y + 0.5) * FZoomScale);
  CrossHalf := Max(3, Round(FZoomScale));
  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(CenterX - CrossHalf, CenterY);
  ACanvas.LineTo(CenterX + CrossHalf + 1, CenterY);
  ACanvas.MoveTo(CenterX, CenterY - CrossHalf);
  ACanvas.LineTo(CenterX, CenterY + CrossHalf + 1);
  if CrossHalf > 2 then
  begin
    ACanvas.Pen.Color := clWhite;
    ACanvas.MoveTo(CenterX - (CrossHalf - 1), CenterY);
    ACanvas.LineTo(CenterX + CrossHalf, CenterY);
    ACanvas.MoveTo(CenterX, CenterY - (CrossHalf - 1));
    ACanvas.LineTo(CenterX, CenterY + CrossHalf);
  end;
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

procedure TMainForm.RenderMovePixelsTransactionPreview(ASurface: TRasterSurface);
begin
  if Assigned(FMovePixelsController) then
    FMovePixelsController.RenderPreview(ASurface);
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
    if FCurrentTool = tkEraser then
      DrawEraserHoverOverlay(
        ACanvas,
        FLastImagePoint,
        ActiveToolOverlayRadius,
        FEraserSquareShape
      )
    else
      DrawBrushHoverOverlay(ACanvas, FLastImagePoint, ActiveToolOverlayRadius);
  end
  else
    DrawPointHoverOverlay(ACanvas, FLastImagePoint);

  if (FCurrentTool = tkCloneStamp) and TryGetCloneOverlaySourcePoint(SourcePoint) then
  begin
    if FPointerDown then
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
  OldOrg: TPoint;
  ContentW: Integer;
  ContentH: Integer;
begin
  ACanvas.Brush.Color := CanvasBackgroundColor;
  ACanvas.FillRect(ARect);

  if not Assigned(FPreparedBitmap) or not Assigned(FDocument) then
    Exit;

  { Shift the canvas origin so all drawing code (overlays, pixel grid, etc.)
    can use plain Round(X * FZoomScale) coordinates without adding FCanvasPadX.
    SetWindowOrgEx(-PadX, -PadY) makes logical (0,0) appear at device (PadX,PadY). }
  SetWindowOrgEx(ACanvas.Handle, -FCanvasPadX, -FCanvasPadY, @OldOrg);

  if (FPreparedRevision <> FRenderRevision) or
     (FPreparedBitmap.Width <> FDocument.Width) or
     (FPreparedBitmap.Height <> FDocument.Height) then
  begin
    DisplaySurface := BuildDisplaySurface;  { returns FDisplaySurface — do NOT free }
    CopySurfaceToBitmap(DisplaySurface, FPreparedBitmap);
    FPreparedRevision := FRenderRevision;
  end;

  if not FPreparedBitmap.Empty then
  begin
    ContentW := Max(1, Round(FDocument.Width * FZoomScale));
    ContentH := Max(1, Round(FDocument.Height * FZoomScale));
    { Keep anti-aliased edges visible for modest zoom-ins, and only switch
      back to nearest-neighbor for deep pixel-inspection zoom levels. }
    FPSetInterpolationQuality(DisplayInterpolationQualityForZoom(FZoomScale));
    ACanvas.StretchDraw(Rect(0, 0, ContentW, ContentH), FPreparedBitmap);
  end;

  if ShouldRenderPixelGrid(FShowPixelGrid, FZoomScale) then
  begin
    ACanvas.Pen.Color := PixelGridColor;
    ACanvas.Pen.Width := 1;
    for GridIndex := 1 to FDocument.Width - 1 do
    begin
      LeftX := Round(GridIndex * FZoomScale);
      ACanvas.MoveTo(LeftX, 0);
      ACanvas.LineTo(LeftX, Round(FDocument.Height * FZoomScale));
    end;
    for GridIndex := 1 to FDocument.Height - 1 do
    begin
      TopY := Round(GridIndex * FZoomScale);
      ACanvas.MoveTo(0, TopY);
      ACanvas.LineTo(Round(FDocument.Width * FZoomScale), TopY);
    end;
  end;

  DrawSelectionMarqueeOverlay(ACanvas);

  if (FCurrentTool = tkLine) and FLineBezierMode and FLinePathOpen and (not FLineCurvePending) and
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

  if FLineBezierMode and FLineCurvePending and (FCurrentTool = tkLine) then
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
          if FShapeLineStyle = 1 then
            ACanvas.Pen.Style := psDash
          else
            ACanvas.Pen.Style := psSolid;
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
          if FGradientType = 2 then
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
          if FGradientType = 3 then
          begin
            LeftX := Round(FDragStart.X * FZoomScale);
            TopY := Round(FDragStart.Y * FZoomScale);
            RightX := Round(FLastImagePoint.X * FZoomScale);
            BottomY := Round(FLastImagePoint.Y * FZoomScale);
            ACanvas.MoveTo(LeftX, Min(TopY, BottomY));
            ACanvas.LineTo(Max(LeftX, RightX), TopY);
            ACanvas.LineTo(LeftX, Max(TopY, BottomY));
            ACanvas.LineTo(Min(LeftX, RightX), TopY);
            ACanvas.LineTo(LeftX, Min(TopY, BottomY));
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
              if FShapeLineStyle = 1 then
                ACanvas.Pen.Style := psDash
              else
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
            ACanvas.Pen.Width := 1;
            ACanvas.Pen.Color := clBlack;
            ACanvas.Pen.Style := psSolid;
            ACanvas.Brush.Style := bsClear;
          end;
          LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
          TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
          RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
          BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
          ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);
          if FCurrentTool = tkSelectRect then
            DrawMarqueeRectangleOverlay(ACanvas, LeftX, TopY, RightX, BottomY);
        end;
      tkCrop:
        begin
          LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
          TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
          RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
          BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
          { Dim the area outside the crop rectangle with a hatch overlay }
          ACanvas.Brush.Color := RGBToColor(0, 0, 0);
          ACanvas.Brush.Style := bsFDiagonal;
          ACanvas.Pen.Style := psClear;
          if TopY > 0 then
            ACanvas.FillRect(0, 0, FPaintBox.Width, TopY);
          if BottomY < FPaintBox.Height then
            ACanvas.FillRect(0, BottomY, FPaintBox.Width, FPaintBox.Height);
          if LeftX > 0 then
            ACanvas.FillRect(0, TopY, LeftX, BottomY);
          if RightX < FPaintBox.Width then
            ACanvas.FillRect(RightX, TopY, FPaintBox.Width, BottomY);
          ACanvas.Brush.Style := bsClear;
          { Crop border: solid black outline + dashed white for contrast on any background }
          ACanvas.Pen.Style := psSolid;
          ACanvas.Pen.Color := clBlack;
          ACanvas.Pen.Width := 1;
          ACanvas.Rectangle(LeftX - 1, TopY - 1, RightX + 1, BottomY + 1);
          ACanvas.Pen.Style := psDash;
          ACanvas.Pen.Color := clWhite;
          ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);
          if FCropGuideMode > 0 then
          begin
            ACanvas.Pen.Style := psDot;
            ACanvas.Pen.Color := clWhite;
            if FCropGuideMode = 1 then
            begin
              { Rule of thirds guides }
              ACanvas.MoveTo(LeftX + (RightX - LeftX) div 3, TopY);
              ACanvas.LineTo(LeftX + (RightX - LeftX) div 3, BottomY);
              ACanvas.MoveTo(LeftX + ((RightX - LeftX) * 2) div 3, TopY);
              ACanvas.LineTo(LeftX + ((RightX - LeftX) * 2) div 3, BottomY);
              ACanvas.MoveTo(LeftX, TopY + (BottomY - TopY) div 3);
              ACanvas.LineTo(RightX, TopY + (BottomY - TopY) div 3);
              ACanvas.MoveTo(LeftX, TopY + ((BottomY - TopY) * 2) div 3);
              ACanvas.LineTo(RightX, TopY + ((BottomY - TopY) * 2) div 3);
            end
            else
            begin
              { Center cross guide }
              ACanvas.MoveTo((LeftX + RightX) div 2, TopY);
              ACanvas.LineTo((LeftX + RightX) div 2, BottomY);
              ACanvas.MoveTo(LeftX, (TopY + BottomY) div 2);
              ACanvas.LineTo(RightX, (TopY + BottomY) div 2);
            end;
          end;
        end;
      tkRoundedRectangle:
        begin
          PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
          if ShapePreviewOutline then
          begin
            if FShapeLineStyle = 1 then
              ACanvas.Pen.Style := psDash
            else
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
            EnsureRange(
              Round(FRoundedCornerRadius * FZoomScale),
              2,
              Max(2, Min((RightX - LeftX) div 2, (BottomY - TopY) div 2))
            ),
            EnsureRange(
              Round(FRoundedCornerRadius * FZoomScale),
              2,
              Max(2, Min((RightX - LeftX) div 2, (BottomY - TopY) div 2))
            )
          );
        end;
      tkEllipseShape, tkSelectEllipse:
        begin
          if FCurrentTool = tkEllipseShape then
          begin
            PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
            if ShapePreviewOutline then
            begin
              if FShapeLineStyle = 1 then
                ACanvas.Pen.Style := psDash
              else
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
            ACanvas.Pen.Width := 1;
            ACanvas.Pen.Color := clBlack;
            ACanvas.Pen.Style := psSolid;
            ACanvas.Brush.Style := bsClear;
          end;
          LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
          TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
          RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
          BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
          ACanvas.Ellipse(LeftX, TopY, RightX, BottomY);
          if FCurrentTool = tkSelectEllipse then
            DrawMarqueeEllipseOverlay(ACanvas, LeftX, TopY, RightX, BottomY);
        end;
      tkSelectLasso, tkFreeformShape:
        if Length(FLassoPoints) > 1 then
        begin
          if FCurrentTool = tkFreeformShape then
          begin
            PreviewStrokeWidth := Min(20, Max(1, Round(Max(1, FBrushSize div 3) * FZoomScale)));
            if ShapePreviewOutline then
            begin
              if FShapeLineStyle = 1 then
                ACanvas.Pen.Style := psDash
              else
                ACanvas.Pen.Style := psSolid;
              ACanvas.Pen.Width := PreviewStrokeWidth;
            end
            else
              ACanvas.Pen.Style := psClear;
          end
          else
          begin
            ACanvas.Pen.Color := clBlack;
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
          if FCurrentTool = tkSelectLasso then
            DrawMarqueePolylineOverlay(ACanvas, FLassoPoints, True);
          if (FCurrentTool = tkFreeformShape) and (Length(FLassoPoints) > 2) then
            ACanvas.LineTo(
              Round((FLassoPoints[0].X + 0.5) * FZoomScale),
              Round((FLassoPoints[0].Y + 0.5) * FZoomScale)
            );
        end;
      tkMosaic:
        begin
          LeftX := Round(Min(FDragStart.X, FLastImagePoint.X) * FZoomScale);
          TopY := Round(Min(FDragStart.Y, FLastImagePoint.Y) * FZoomScale);
          RightX := Round((Max(FDragStart.X, FLastImagePoint.X) + 1) * FZoomScale);
          BottomY := Round((Max(FDragStart.Y, FLastImagePoint.Y) + 1) * FZoomScale);
          { Dashed border around the mosaic area }
          ACanvas.Pen.Style := psSolid;
          ACanvas.Pen.Color := clBlack;
          ACanvas.Pen.Width := 1;
          ACanvas.Brush.Style := bsClear;
          ACanvas.Rectangle(LeftX - 1, TopY - 1, RightX + 1, BottomY + 1);
          ACanvas.Pen.Style := psDash;
          ACanvas.Pen.Color := clWhite;
          ACanvas.Rectangle(LeftX, TopY, RightX, BottomY);
        end;
    end;

    case FCurrentTool of
      tkLine, tkGradient, tkRectangle, tkRoundedRectangle, tkEllipseShape,
      tkSelectRect, tkSelectEllipse, tkCrop, tkMosaic:
        DrawPointHoverOverlay(ACanvas, FDragStart);
      tkSelectLasso, tkFreeformShape:
        if Length(FLassoPoints) > 0 then
          DrawPointHoverOverlay(ACanvas, FLassoPoints[0]);
    end;
  end;

  DrawHoverToolOverlay(ACanvas);

  { Restore the canvas origin that was shifted at the top of this method }
  SetWindowOrgEx(ACanvas.Handle, OldOrg.X, OldOrg.Y, nil);
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
  ClampedHorizontal: Integer;
  ClampedVertical: Integer;
  ContentW: Integer;
  ContentH: Integer;
  ViewW: Integer;
  ViewH: Integer;
  BoxW: Integer;
  BoxH: Integer;
begin
  if FUpdatingCanvasSize then Exit;
  if not Assigned(FPaintBox) then
  begin
    UpdateInlineTextEditBounds;
    Exit;
  end;
  if not Assigned(FDocument) then Exit;
  FUpdatingCanvasSize := True;
  try
    ContentW := Max(1, Round(FDocument.Width * FZoomScale));
    ContentH := Max(1, Round(FDocument.Height * FZoomScale));
    if Assigned(FCanvasHost) then
    begin
      ViewW := FCanvasHost.ClientWidth;
      ViewH := FCanvasHost.ClientHeight;
      { Always add half-viewport padding on each side so the canvas edge
        can be scrolled to the viewport centre.  This mirrors the scroll
        range that image editors like GIMP provide (OVERPAN_FACTOR = 0.5).
        Using a constant factor (not conditional on content > viewport)
        avoids threshold discontinuities that cause visible "bounce". }
      FCanvasPadX := Max(0, ViewW div 2);
      FCanvasPadY := Max(0, ViewH div 2);
      BoxW := ContentW + FCanvasPadX * 2;
      BoxH := ContentH + FCanvasPadY * 2;
      LeftOffset := CenteredContentOffset(ViewW, BoxW);
      TopOffset := CenteredContentOffset(ViewH, BoxH);
      FPaintBox.SetBounds(LeftOffset, TopOffset, BoxW, BoxH);
      if FCenterOnNextCanvasUpdate and (ViewW > 0) and (ViewH > 0) then
      begin
        { Place the image centre at the viewport centre.
          Keep the flag alive if the viewport has zero size (form not yet
          shown) so that the first real UpdateCanvasSize centres properly. }
        FCenterOnNextCanvasUpdate := False;
        ClampedHorizontal := ClampViewportScrollPosition(
          FPaintBox.Left + FCanvasPadX + ContentW div 2 - FCanvasHost.ClientWidth div 2,
          FPaintBox.Left,
          FPaintBox.Width,
          FCanvasHost.ClientWidth
        );
        ClampedVertical := ClampViewportScrollPosition(
          FPaintBox.Top + FCanvasPadY + ContentH div 2 - FCanvasHost.ClientHeight div 2,
          FPaintBox.Top,
          FPaintBox.Height,
          FCanvasHost.ClientHeight
        );
      end
      else
      begin
        { Re-read ClientWidth/ClientHeight because scrollbar visibility may
          have changed after SetBounds. }
        ClampedHorizontal := ClampViewportScrollPosition(
          FCanvasHost.HorzScrollBar.Position,
          FPaintBox.Left,
          FPaintBox.Width,
          FCanvasHost.ClientWidth
        );
        ClampedVertical := ClampViewportScrollPosition(
          FCanvasHost.VertScrollBar.Position,
          FPaintBox.Top,
          FPaintBox.Height,
          FCanvasHost.ClientHeight
        );
      end;
      if ClampedHorizontal <> FCanvasHost.HorzScrollBar.Position then
        FCanvasHost.HorzScrollBar.Position := ClampedHorizontal;
      if ClampedVertical <> FCanvasHost.VertScrollBar.Position then
        FCanvasHost.VertScrollBar.Position := ClampedVertical;
      FLastScrollPosition := Point(
        FCanvasHost.HorzScrollBar.Position,
        FCanvasHost.VertScrollBar.Position
      );
    end
    else
    begin
      FCanvasPadX := 0;
      FCanvasPadY := 0;
      FPaintBox.SetBounds(FPaintBox.Left, FPaintBox.Top, ContentW, ContentH);
    end;
  finally
    FUpdatingCanvasSize := False;
  end;
  UpdateInlineTextEditBounds;
end;

procedure TMainForm.CanvasHostResize(Sender: TObject);
begin
  if FIsPanning then Exit;
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
  if not Assigned(FDocument) then
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
  if FIsTestInstance then Exit;
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
  TargetRow: Integer;
begin
  if not Assigned(FDocument) then Exit;
  if not Assigned(FLayerList) then Exit;
  FLayerDragIndex := -1;
  FLayerDragTargetIndex := -1;
  FLayerList.BeginUpdate;
  try
    FLayerList.ColCount := 4;
    LayerGridApplyColumnWidths(FLayerList);
    FLayerList.RowCount := Max(1, FDocument.LayerCount);
    SetLength(FLayerRowLockHitRects, FDocument.LayerCount);
    SetLength(FLayerRowEyeHitRects, FDocument.LayerCount);
    if FDocument.LayerCount > 0 then
      TargetRow := EnsureRange(FDocument.ActiveLayerIndex, 0, FDocument.LayerCount - 1)
    else
      TargetRow := 0;
    FLayerList.Row := TargetRow;
  finally
    FLayerList.EndUpdate(False);
  end;
  FLayerList.Invalidate;
  { Sync inline layer controls to the active layer }
  if FDocument.LayerCount > 0 then
  begin
    FUpdatingLayerControls := True;
    try
      if Assigned(FLayerBlendCombo) then
        FLayerBlendCombo.ItemIndex := Ord(FDocument.ActiveLayer.BlendMode);
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
      TR('FG #%2.2x%2.2x%2.2x%2.2x   BG #%2.2x%2.2x%2.2x%2.2x',
         '前景 #%2.2x%2.2x%2.2x%2.2x   背景 #%2.2x%2.2x%2.2x%2.2x'),
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
        TR('Active: Foreground  #%2.2x%2.2x%2.2x%2.2x',
           '当前：前景色  #%2.2x%2.2x%2.2x%2.2x'),
        [
          FPrimaryColor.R,
          FPrimaryColor.G,
          FPrimaryColor.B,
          FPrimaryColor.A
        ]
      )
    else
      FActiveColorHexLabel.Caption := Format(
        TR('Active: Background  #%2.2x%2.2x%2.2x%2.2x',
           '当前：背景色  #%2.2x%2.2x%2.2x%2.2x'),
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
      FColorPickButton.Hint := TR('Open the system color palette for the foreground swatch', '打开系统调色板以编辑前景色样本')
    else
      FColorPickButton.Hint := TR('Open the system color palette for the background swatch', '打开系统调色板以编辑背景色样本');
  end;
  if Assigned(FColorTargetCombo) and (FColorTargetCombo.ItemIndex <> FColorEditTarget) then
    FColorTargetCombo.ItemIndex := FColorEditTarget;
  UpdateColorSpins;
  if Assigned(FColorsBox) then
    FColorsBox.Invalidate;
  if Assigned(FColorWheelBox) then
    FColorWheelBox.Invalidate;
  if Assigned(FColorDetailBox) and FColorDetailBox.Visible then
    FColorDetailBox.Invalidate;
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
  TextLeft: Integer;
  procedure PaintAlphaSwatch(const ASwatchRect: TRect; const AColor: TRGBA32);
  var
    TileX: Integer;
    TileY: Integer;
    TileColor: TRGBA32;
    DisplayColor: TRGBA32;
  begin
    for TileY := Max(0, ASwatchRect.Top - 3) to Min(PB.Height - 1, ASwatchRect.Bottom + 3) do
      for TileX := Max(0, ASwatchRect.Left - 3) to Min(PB.Width - 1, ASwatchRect.Right + 3) do
      begin
        if (((TileX - ASwatchRect.Left) div TileSize) + ((TileY - ASwatchRect.Top) div TileSize)) mod 2 = 0 then
          TileColor := RGBA(236, 238, 242, 255)
        else
          TileColor := RGBA(214, 217, 223, 255);
        if (TileX >= ASwatchRect.Left) and (TileX < ASwatchRect.Right) and
           (TileY >= ASwatchRect.Top) and (TileY < ASwatchRect.Bottom) then
          DisplayColor := BlendNormal(AColor, TileColor, 255)
        else
          DisplayColor := TileColor;
        C.Pixels[TileX, TileY] := RGBToColor(DisplayColor.R, DisplayColor.G, DisplayColor.B);
      end;
    C.Brush.Style := bsClear;
    C.Pen.Color := ChromeDividerColor;
    C.Rectangle(ASwatchRect.Left, ASwatchRect.Top, ASwatchRect.Right, ASwatchRect.Bottom);
    C.Brush.Style := bsSolid;
  end;
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

  { Paint inactive swatch first, active swatch on top }
  if FColorEditTarget = 0 then
  begin
    PaintAlphaSwatch(BackRect, FSecondaryColor);
    PaintAlphaSwatch(FrontRect, FPrimaryColor);
  end
  else
  begin
    PaintAlphaSwatch(FrontRect, FPrimaryColor);
    PaintAlphaSwatch(BackRect, FSecondaryColor);
  end;

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
    C.TextOut(TextLeft, 18, TR('Editing foreground', '正在编辑前景色'))
  else
    C.TextOut(TextLeft, 18, TR('Editing background', '正在编辑背景色'));
  C.Font.Color := ChromeMutedTextColor;
  C.TextOut(TextLeft, 38, TR('Click either swatch to switch', '点击任一色块即可切换'));
  C.TextOut(TextLeft, 56, TR('System picker stays in sync', '系统取色器保持同步'));
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
      255
    )
  else
    FSecondaryColor := RGBA(
      Byte(PickedColor and $FF),
      Byte((PickedColor shr 8) and $FF),
      Byte((PickedColor shr 16) and $FF),
      255
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

{ ── Color Wheel handlers ─────────────────────────────────────────────────── }

procedure TMainForm.RebuildColorWheelBitmaps;
var
  WSize: Integer;
  OuterR, InnerR: Integer;
begin
  if not Assigned(FColorWheelBox) then Exit;
  if not Assigned(FColorWheelBitmap) then Exit;
  WSize := FColorWheelBox.Width;
  if WSize < 20 then Exit;
  OuterR := (WSize div 2) - 2;
  InnerR := OuterR - 18;
  if InnerR < 10 then InnerR := 10;
  { Rebuild hue ring only when size changes }
  if (FColorWheelBitmap.Width <> WSize) or (FColorWheelBitmap.Height <> WSize) then
    RenderHueRing(FColorWheelBitmap, WSize, InnerR, OuterR);
end;

procedure TMainForm.ColorWheelBoxPaint(Sender: TObject);
var
  PB: TPaintBox;
  WSize: Integer;
  CX, CY, OuterR, InnerR, SVSize, SVLeft, SVTop: Integer;
  EditColor: TRGBA32;
  CurH, CurS, CurV: Double;
  MarkerX, MarkerY: Integer;
begin
  if not Assigned(Sender) then Exit;
  PB := TPaintBox(Sender);
  WSize := PB.Width;
  if WSize < 20 then Exit;

  PB.Canvas.Brush.Color := PaletteSurfaceColor(pkColors, False);
  PB.Canvas.FillRect(Rect(0, 0, PB.Width, PB.Height));

  CX := WSize div 2;
  CY := WSize div 2;
  OuterR := CX - 2;
  InnerR := OuterR - 18;
  if InnerR < 10 then InnerR := 10;

  { Draw hue ring from cached bitmap }
  RebuildColorWheelBitmaps;
  if Assigned(FColorWheelBitmap) and (FColorWheelBitmap.Width > 0) and (FColorWheelBitmap.Height > 0) then
    PB.Canvas.Draw(0, 0, FColorWheelBitmap);

  { Get current edit colour and HSV }
  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);
  { Use cached hue when saturation drops to zero to avoid snap-to-red }
  if (CurS < 0.001) and (FColorSVCachedHue >= 0.0) then
    CurH := FColorSVCachedHue;
  if CurS >= 0.001 then
    FColorSVCachedHue := CurH;

  { Draw SV square inside the ring }
  SVSize := Round((InnerR - 4) * 1.414);
  if SVSize < 8 then SVSize := 8;
  SVLeft := CX - SVSize div 2;
  SVTop := CY - SVSize div 2;

  { Rebuild SV square if hue changed or first render }
  if Assigned(FColorSVBitmap) then
  begin
    if ShouldRebuildSVSquare(
      FColorSVRenderedHue,
      CurH,
      FColorSVBitmap.Width,
      FColorSVBitmap.Height,
      SVSize
    ) then
    begin
      RenderSVSquare(FColorSVBitmap, CurH, SVSize);
      FColorSVRenderedHue := CurH;
    end;
    if (FColorSVBitmap.Width > 0) and (FColorSVBitmap.Height > 0) then
      PB.Canvas.Draw(SVLeft, SVTop, FColorSVBitmap);
  end;

  { SV square border }
  PB.Canvas.Brush.Style := bsClear;
  PB.Canvas.Pen.Color := RGBToColor(200, 200, 200);
  PB.Canvas.Rectangle(SVLeft, SVTop, SVLeft + SVSize, SVTop + SVSize);
  PB.Canvas.Brush.Style := bsSolid;

  { Hue marker on the ring }
  DrawHueMarker(PB.Canvas, CurH, CX, CY, (OuterR + InnerR) div 2, 5);

  { SV marker inside the square }
  MarkerX := SVLeft + Round(CurS * Max(1, SVSize - 1));
  MarkerY := SVTop + Round((1.0 - CurV) * Max(1, SVSize - 1));
  if CurV > 0.5 then
    DrawCircleMarker(PB.Canvas, MarkerX, MarkerY, 5, clBlack, clWhite)
  else
    DrawCircleMarker(PB.Canvas, MarkerX, MarkerY, 5, clWhite, clBlack);
end;

procedure TMainForm.ColorWheelBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  WSize, CX, CY, OuterR, InnerR, SVSize, SVLeft, SVTop: Integer;
  NewHue, NewSat, NewVal: Double;
  EditColor: TRGBA32;
  CurH, CurS, CurV: Double;
  R, G, B: Byte;
begin
  if Button <> mbLeft then Exit;
  if not Assigned(FColorWheelBox) then Exit;
  WSize := FColorWheelBox.Width;
  CX := WSize div 2;
  CY := WSize div 2;
  OuterR := CX - 2;
  InnerR := OuterR - 18;
  if InnerR < 10 then InnerR := 10;
  SVSize := Round((InnerR - 4) * 1.414);
  if SVSize < 8 then SVSize := 8;
  SVLeft := CX - SVSize div 2;
  SVTop := CY - SVSize div 2;

  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);
  if (CurS < 0.001) and (FColorSVCachedHue >= 0.0) then
    CurH := FColorSVCachedHue;

  if HitTestHueRing(X, Y, CX, CY, InnerR, OuterR, NewHue) then
  begin
    FColorWheelDragMode := 1;
    FColorSVCachedHue := NewHue;
    HSVToRGB(NewHue, CurS, CurV, R, G, B);
    EditColor := RGBA(R, G, B, EditColor.A);
    if FColorEditTarget = 0 then FPrimaryColor := EditColor
    else FSecondaryColor := EditColor;
    RefreshColorsPanel;
  end
  else if HitTestSVSquare(X, Y, SVLeft, SVTop, SVSize, NewSat, NewVal) then
  begin
    FColorWheelDragMode := 2;
    HSVToRGB(CurH, NewSat, NewVal, R, G, B);
    EditColor := RGBA(R, G, B, EditColor.A);
    if FColorEditTarget = 0 then FPrimaryColor := EditColor
    else FSecondaryColor := EditColor;
    RefreshColorsPanel;
  end
  else
    FColorWheelDragMode := 0;
end;

procedure TMainForm.ColorWheelBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  WSize, CX, CY, OuterR, InnerR, SVSize, SVLeft, SVTop: Integer;
  NewHue, NewSat, NewVal: Double;
  EditColor: TRGBA32;
  CurH, CurS, CurV: Double;
  R, G, B: Byte;
begin
  if not (ssLeft in Shift) then Exit;
  if FColorWheelDragMode = 0 then Exit;
  if not Assigned(FColorWheelBox) then Exit;

  WSize := FColorWheelBox.Width;
  CX := WSize div 2;
  CY := WSize div 2;
  OuterR := CX - 2;
  InnerR := OuterR - 18;
  if InnerR < 10 then InnerR := 10;
  SVSize := Round((InnerR - 4) * 1.414);
  if SVSize < 8 then SVSize := 8;
  SVLeft := CX - SVSize div 2;
  SVTop := CY - SVSize div 2;

  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);
  if (CurS < 0.001) and (FColorSVCachedHue >= 0.0) then
    CurH := FColorSVCachedHue;

  if FColorWheelDragMode = 1 then
  begin
    { Hue ring drag — always compute angle from centre }
    NewHue := ArcTan2(-(Y - CY), X - CX) / (2.0 * Pi);
    if NewHue < 0 then NewHue := NewHue + 1.0;
    FColorSVCachedHue := NewHue;
    HSVToRGB(NewHue, CurS, CurV, R, G, B);
    EditColor := RGBA(R, G, B, EditColor.A);
    if FColorEditTarget = 0 then FPrimaryColor := EditColor
    else FSecondaryColor := EditColor;
    RefreshColorsPanel;
  end
  else if FColorWheelDragMode = 2 then
  begin
    { SV square drag — clamp to square bounds }
    NewSat := EnsureRange((X - SVLeft) / Max(1, SVSize - 1), 0.0, 1.0);
    NewVal := EnsureRange(1.0 - (Y - SVTop) / Max(1, SVSize - 1), 0.0, 1.0);
    HSVToRGB(CurH, NewSat, NewVal, R, G, B);
    EditColor := RGBA(R, G, B, EditColor.A);
    if FColorEditTarget = 0 then FPrimaryColor := EditColor
    else FSecondaryColor := EditColor;
    RefreshColorsPanel;
  end;
end;

procedure TMainForm.ColorWheelBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    FColorWheelDragMode := 0;
end;

{ ── Expand / Collapse toggle ──────────────────────────────────────────────── }

procedure TMainForm.ColorExpandButtonClick(Sender: TObject);
const
  CollapsedWidth = 220;
  ExpandedWidth = 440;
begin
  FColorExpanded := not FColorExpanded;
  if FColorExpanded then
    FColorsPanel.Width := ExpandedWidth
  else
    FColorsPanel.Width := CollapsedWidth;
  LayoutColorsPanel;
  RefreshColorsPanel;
end;

{ ── Detail gradient-bar panel (RGB / HSV / Alpha) ─────────────────────────── }

procedure TMainForm.ColorDetailBoxPaint(Sender: TObject);
const
  BarLabelW = 24;
  BarHeight = 14;
  RowHeight = 22;
  HeaderHeight = 18;
  HeaderGap = 4;
var
  PB: TPaintBox;
  EditColor: TRGBA32;
  CurH, CurS, CurV: Double;
  BarLeft, BarW: Integer;
  Y: Integer;
  procedure DrawHeader(const AText: string; AY: Integer);
  begin
    PB.Canvas.Font.Style := [fsBold];
    PB.Canvas.Font.Color := ChromeTextColor;
    PB.Canvas.Font.Size := 9;
    PB.Canvas.TextOut(0, AY + 1, AText);
    PB.Canvas.Font.Style := [];
  end;
  procedure DrawBarRow(const ALabel: string; AKind: TGradientBarKind; AMarker: Double; ARowY: Integer);
  begin
    PB.Canvas.Font.Color := ChromeTextColor;
    PB.Canvas.Font.Size := 9;
    PB.Canvas.TextOut(2, ARowY + 1, ALabel);
    PaintGradientBar(PB.Canvas, AKind, EditColor, AMarker,
      BarLeft, ARowY, BarW, BarHeight);
  end;
begin
  if not Assigned(Sender) then Exit;
  PB := TPaintBox(Sender);
  PB.Canvas.Brush.Color := PaletteSurfaceColor(pkColors, False);
  PB.Canvas.FillRect(Rect(0, 0, PB.Width, PB.Height));

  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);

  BarLeft := BarLabelW;
  BarW := Max(24, PB.Width - BarLabelW);

  { RGB section }
  Y := 0;
  DrawHeader(TR('RGB', 'RGB'), Y);
  Y := Y + HeaderHeight;
  DrawBarRow(TR('R', #$E7#$BA#$A2), gbkRed, EditColor.R / 255.0, Y);
  Y := Y + RowHeight;
  DrawBarRow(TR('G', #$E7#$BB#$BF), gbkGreen, EditColor.G / 255.0, Y);
  Y := Y + RowHeight;
  DrawBarRow(TR('B', #$E8#$93#$9D), gbkBlue, EditColor.B / 255.0, Y);
  Y := Y + RowHeight;

  { Hex label }
  Y := Y + HeaderGap;
  PB.Canvas.Font.Color := ChromeMutedTextColor;
  PB.Canvas.Font.Size := 8;
  PB.Canvas.TextOut(2, Y + 2, TR('Hex:', #$E5#$8D#$81#$E5#$85#$AD#$E8#$BF#$9B#$E5#$88#$B6 + ':'));
  Y := Y + 24;

  { HSV section }
  Y := Y + HeaderGap;
  DrawHeader(TR('HSV', 'HSV'), Y);
  Y := Y + HeaderHeight;
  DrawBarRow('H', gbkHue, CurH, Y);
  Y := Y + RowHeight;
  DrawBarRow('S', gbkSaturation, CurS, Y);
  Y := Y + RowHeight;
  DrawBarRow('V', gbkValue, CurV, Y);
  Y := Y + RowHeight;

  { Alpha section }
  Y := Y + HeaderGap;
  DrawHeader(TR('Alpha', #$E4#$B8#$8D#$E9#$80#$8F#$E6#$98#$8E#$E5#$BA#$A6), Y);
  Y := Y + HeaderHeight;
  DrawBarRow('A', gbkAlpha, EditColor.A / 255.0, Y);
end;

procedure TMainForm.ApplyColorDetailBarAt(X, Y: Integer);
const
  BarLabelW = 24;
  BarHeight = 14;
  RowHeight = 22;
  HeaderHeight = 18;
  HeaderGap = 4;
var
  EditColor: TRGBA32;
  CurH, CurS, CurV: Double;
  BarLeft, BarW: Integer;
  Frac: Double;
  RowY: Integer;
  BarIdx: Integer;
  R, G, B: Byte;
begin
  if not Assigned(FColorDetailBox) then Exit;
  BarIdx := -1;
  BarLeft := BarLabelW;
  BarW := Max(24, FColorDetailBox.Width - BarLabelW);
  Frac := EnsureRange((X - BarLeft) / Max(1, BarW - 1), 0.0, 1.0);

  if FColorEditTarget = 0 then
    EditColor := FPrimaryColor
  else
    EditColor := FSecondaryColor;
  RGBToHSV(EditColor.R, EditColor.G, EditColor.B, CurH, CurS, CurV);

  { Determine which bar was hit based on FColorDetailDragBar or Y position }
  if FColorDetailDragBar >= 0 then
    BarIdx := FColorDetailDragBar
  else
  begin
    { Compute bar index from Y coordinate }
    RowY := HeaderHeight;                          { R starts here }
    if Y < RowY then Exit;
    if Y < RowY + RowHeight then begin BarIdx := 0; end              { R }
    else if Y < RowY + RowHeight * 2 then begin BarIdx := 1; end     { G }
    else if Y < RowY + RowHeight * 3 then begin BarIdx := 2; end     { B }
    else begin
      { HSV starts after: 3 rows + hex + gap + header }
      RowY := HeaderHeight + RowHeight * 3 + HeaderGap + 24 + HeaderGap + HeaderHeight;
      if Y < RowY then Exit;
      if Y < RowY + RowHeight then begin BarIdx := 3; end            { H }
      else if Y < RowY + RowHeight * 2 then begin BarIdx := 4; end   { S }
      else if Y < RowY + RowHeight * 3 then begin BarIdx := 5; end   { V }
      else begin
        { Alpha starts after HSV + gap + header }
        RowY := RowY + RowHeight * 3 + HeaderGap + HeaderHeight;
        if Y < RowY then Exit;
        BarIdx := 6;                                                   { A }
      end;
    end;
    FColorDetailDragBar := BarIdx;  { lock to this bar for subsequent drag moves }
  end;

  case BarIdx of
    0: EditColor := RGBA(EnsureRange(Round(Frac * 255), 0, 255), EditColor.G, EditColor.B, EditColor.A);
    1: EditColor := RGBA(EditColor.R, EnsureRange(Round(Frac * 255), 0, 255), EditColor.B, EditColor.A);
    2: EditColor := RGBA(EditColor.R, EditColor.G, EnsureRange(Round(Frac * 255), 0, 255), EditColor.A);
    3: begin
         HSVToRGB(Frac, CurS, CurV, R, G, B);
         EditColor := RGBA(R, G, B, EditColor.A);
         FColorSVCachedHue := Frac;
       end;
    4: begin
         HSVToRGB(CurH, Frac, CurV, R, G, B);
         EditColor := RGBA(R, G, B, EditColor.A);
       end;
    5: begin
         HSVToRGB(CurH, CurS, Frac, R, G, B);
         EditColor := RGBA(R, G, B, EditColor.A);
       end;
    6: EditColor := RGBA(EditColor.R, EditColor.G, EditColor.B, EnsureRange(Round(Frac * 255), 0, 255));
  else
    Exit;
  end;

  if FColorEditTarget = 0 then
    FPrimaryColor := EditColor
  else
    FSecondaryColor := EditColor;
  RefreshColorsPanel;
end;

procedure TMainForm.ColorDetailBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FColorDetailDragBar := -1;
  ApplyColorDetailBarAt(X, Y);
end;

procedure TMainForm.ColorDetailBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not (ssLeft in Shift) then Exit;
  ApplyColorDetailBarAt(X, Y);
end;

procedure TMainForm.ColorDetailBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    FColorDetailDragBar := -1;
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
  UndoCount: Integer;
  RedoCount: Integer;
  RowIndex: Integer;
  OpIndex: Integer;
begin
  if not Assigned(FHistoryList) then Exit;
  if not Assigned(FDocument) then Exit;
  FHistoryList.OnClick := nil;
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
    FHistoryList.Items.Add(TR('0. (initial)', '0.（初始）'));
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
    { Highlight current state at row = UndoCount.
      Disconnect OnClick while setting ItemIndex to prevent the Cocoa widgetset
      from firing HistoryListClick, which would spuriously undo the operation. }
    FHistoryList.ItemIndex := UndoCount;
  finally
    FHistoryList.Items.EndUpdate;
    FHistoryList.OnClick := @HistoryListClick;
  end;
end;

procedure TMainForm.RefreshStatus(const ACursorPoint: TPoint);
var
  SelectionText: string;
  SelectionBounds: TRect;
begin
  if not Assigned(FStatusBar) then
    Exit;
  if not Assigned(FDocument) then
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
    SelectionText := TR('none', '无');

  FStatusLabels[0].Caption := Format('%s — %s', [PaintToolName(FCurrentTool), ToolHintText]);
  FStatusLabels[1].Caption := Format(
    TR('Image: %s × %s %s', '图像：%s × %s %s'),
    [
      FormatMeasurement(FDocument.Width),
      FormatMeasurement(FDocument.Height),
      DisplayUnitSuffix
    ]
  );
  FStatusLabels[2].Caption := TR('Selection: ', '选区：') + SelectionText;
  if (ACursorPoint.X >= 0) and (ACursorPoint.Y >= 0) then
    FStatusLabels[3].Caption := Format(
      TR('Cursor: %s, %s %s', '光标：%s，%s %s'),
      [
        FormatMeasurement(ACursorPoint.X),
        FormatMeasurement(ACursorPoint.Y),
        DisplayUnitSuffix
      ]
    )
  else
    FStatusLabels[3].Caption := TR('Cursor: —', '光标：—');
  FStatusLabels[4].Caption := Format(
    TR('Layer: %d/%d', '图层：%d/%d'),
    [FDocument.ActiveLayerIndex + 1, FDocument.LayerCount]
  );
  FStatusLabels[5].Caption := TR('Units: ', '单位：') + DisplayUnitSuffix;
  FStatusLabels[6].Caption := '';
  UpdateZoomControls;
  LayoutStatusBarControls(nil);
end;

procedure TMainForm.UpdateStatusForTool;
begin
  RefreshStatus(Point(-1, -1));
end;

procedure TMainForm.SyncToolComboSelection;
var
  ToolIndex: Integer;
begin
  if not Assigned(FToolCombo) then
    Exit;
  FToolCombo.ItemIndex := -1;
  for ToolIndex := 0 to FToolCombo.Items.Count - 1 do
    if TToolKind(PtrInt(FToolCombo.Items.Objects[ToolIndex])) = FCurrentTool then
    begin
      FToolCombo.ItemIndex := ToolIndex;
      Exit;
    end;
end;

procedure TMainForm.ActivateTempPan;
begin
  SealPendingStrokeHistory;
  if not TryActivateTemporaryPan(FCurrentTool, FPreviousTool, FTempToolActive) then
    Exit;
  SyncToolComboSelection;
  UpdateToolOptionControl;
  UpdateStatusForTool;
end;

procedure TMainForm.DeactivateTempPan;
begin
  if not TryDeactivateTemporaryPan(FCurrentTool, FPreviousTool, FTempToolActive) then
    Exit;
  SyncToolComboSelection;
  UpdateToolOptionControl;
  UpdateStatusForTool;
end;

procedure TMainForm.ToggleColorEditTarget;
begin
  SealPendingStrokeHistory;
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
  if not TryActivateTemporaryPan(FCurrentTool, FPreviousTool, FTempToolActive) then
    Exit;
  SyncToolComboSelection;
end;

procedure TMainForm.StopTempPan;
begin
  if not TryDeactivateTemporaryPan(FCurrentTool, FPreviousTool, FTempToolActive) then
    Exit;
  SyncToolComboSelection;
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
var
  ToolIndex: Integer;
  ToolKind: TToolKind;
begin
  { Ensure minimal widgets for tests so they don't need to exercise full UI }
  if not Assigned(FToolCombo) then
  begin
    FToolCombo := TComboBox.Create(nil);
    for ToolIndex := 0 to PaintToolDisplayCount - 1 do
    begin
      ToolKind := PaintToolAtDisplayIndex(ToolIndex);
      if ToolKind = tkZoom then
        Continue;
      FToolCombo.Items.AddObject(
        PaintToolDisplayLabel(ToolKind),
        TObject(PtrInt(Ord(ToolKind)))
      );
    end;
  end;
  if not Assigned(FColorTargetCombo) then
  begin
    FColorTargetCombo := TComboBox.Create(nil);
    FColorTargetCombo.Style := csDropDownList;
    if FColorTargetCombo.Items.Count = 0 then
    begin
      FColorTargetCombo.Items.Add(TR('Primary', '前景色'));
      FColorTargetCombo.Items.Add(TR('Secondary', '背景色'));
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

function TMainForm.DisplayPixelForTest(X, Y: Integer): TRGBA32;
var
  DisplaySurface: TRasterSurface;
  OverlayColor: TRGBA32;
begin
  Result := TransparentColor;
  if not Assigned(FDocument) then
    Exit;
  DisplaySurface := BuildDisplaySurface;
  if not Assigned(DisplaySurface) or not DisplaySurface.InBounds(X, Y) then
    Exit;
  Result := DisplaySurface[X, Y];
  if TrySelectionMarqueePixelColor(X, Y, OverlayColor) then
    Result := OverlayColor;
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
      FZoomCombo.Hint := TR('Zoom: ', '缩放：') + ZoomCaptionForScale(FZoomScale);
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
  SealPendingStrokeHistory;
  if not Assigned(FDocument) then Exit;
  if not Assigned(FHistoryList) then Exit;
  ClickedIndex := FHistoryList.ItemIndex;
  if ClickedIndex < 0 then Exit;
  { Row layout: 0=(initial), 1..UndoDepth=(past ops), UndoDepth=(current), UndoDepth+1..=(redo)
    So the current position is always at index UndoDepth. }
  CurrentIndex := FDocument.UndoDepth;
  if ClickedIndex = CurrentIndex then
  begin
    { paint.net-style before/after toggle: clicking the current entry jumps to the
      state just before it, so clicking that same row again immediately redoes it. }
    if CurrentIndex > 0 then
    begin
      FDocument.Undo;
      SyncImageMutationUI(True, False);
    end;
    Exit;
  end;
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
  if FIsTestInstance then Exit;
  Caption := WindowCaptionForDocument(DisplayFileName, FDirty);
  if Assigned(FChromeTitleLabel) then
    FChromeTitleLabel.Caption := Caption;
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
    MenuItem.Caption := TR('(Empty)', '（空）');
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

function TMainForm.PaletteRootForControl(AControl: TControl): TControl;
begin
  Result := AControl;
  while Result <> nil do
  begin
    if (Result = FToolsPanel) or
       (Result = FColorsPanel) or
       (Result = FHistoryPanel) or
       (Result = FRightPanel) then
      Exit;
    Result := Result.Parent;
  end;
end;

function TMainForm.ControlBelongsToPalette(AControl, APalette: TControl): Boolean;
begin
  Result := False;
  while AControl <> nil do
  begin
    if AControl = APalette then
      Exit(True);
    AControl := AControl.Parent;
  end;
end;

function TMainForm.PointRelativeToControl(AControl, ATarget: TControl; const APoint: TPoint): TPoint;
begin
  Result := APoint;
  while (AControl <> nil) and (AControl <> ATarget) do
  begin
    Inc(Result.X, AControl.Left);
    Inc(Result.Y, AControl.Top);
    AControl := AControl.Parent;
  end;
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
  SyncUtilityButtonStates;
end;

procedure TMainForm.RestorePaletteLayout;
var
  PaletteKind: TPaletteKind;
  PaletteHost: TPanel;
  PaletteRect: TRect;
  WorkspaceRect: TRect;
begin
  for PaletteKind := Low(TPaletteKind) to High(TPaletteKind) do
  begin
    PaletteHost := PaletteControl(PaletteKind);
    if not Assigned(PaletteHost) then
      Continue;
    if Assigned(FWorkspacePanel) and (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
    begin
      WorkspaceRect := PaletteClampWorkspaceRect(
        Rect(0, 0, FWorkspacePanel.ClientWidth, FWorkspacePanel.ClientHeight),
        FShowRulers
      );
      PaletteRect := PaletteDefaultRectForWorkspace(
        PaletteKind,
        WorkspaceRect
      )
    end
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
var
  ClampedRect: TRect;
begin
  if (APalette = nil) or (FWorkspacePanel = nil) then
    Exit;
  ClampedRect := ClampPaletteRectToWorkspace(
    Rect(
      APalette.Left,
      APalette.Top,
      APalette.Left + APalette.Width,
      APalette.Top + APalette.Height
    ),
    Rect(0, 0, FWorkspacePanel.ClientWidth, FWorkspacePanel.ClientHeight),
    FShowRulers
  );
  APalette.SetBounds(
    ClampedRect.Left,
    ClampedRect.Top,
    ClampedRect.Right - ClampedRect.Left,
    ClampedRect.Bottom - ClampedRect.Top
  );
end;

procedure TMainForm.CreatePaletteHeader(ATarget: TPanel; AKind: TPaletteKind);
var
  HeaderPanel: TPanel;
  TitleLabel: TLabel;
  HeaderIcon: TImage;
  ShortcutLabel: TLabel;
  CloseButton: TSpeedButton;
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

  HeaderIcon := TImage.Create(HeaderPanel);
  HeaderIcon.Parent := HeaderPanel;
  HeaderIcon.Left := 6;
  HeaderIcon.Top := 5;
  HeaderIcon.Width := 12;
  HeaderIcon.Height := 12;
  HeaderIcon.Stretch := True;
  HeaderIcon.Proportional := True;
  HeaderIcon.Center := True;
  HeaderIcon.Transparent := True;
  if not TryLoadButtonIconPicture(
    PaletteTitle(AKind),
    bicUtility,
    HeaderIcon.Picture
  ) then
    TryBuildLineButtonGlyph(
      PaletteTitle(AKind),
      bicUtility,
      HeaderIcon.Picture.Bitmap,
      PaletteHeaderColor(AKind)
    );
  HeaderIcon.OnMouseDown := @PaletteMouseDown;
  HeaderIcon.OnMouseMove := @PaletteMouseMove;
  HeaderIcon.OnMouseUp := @PaletteMouseUp;

  TitleLabel := TLabel.Create(HeaderPanel);
  TitleLabel.Parent := HeaderPanel;
  TitleLabel.Caption := PaletteTitle(AKind);
  TitleLabel.Left := 24;
  TitleLabel.Top := 4;
  TitleLabel.Width := Max(24, ATarget.Width - 54);
  TitleLabel.AutoSize := False;
  TitleLabel.Anchors := [akLeft, akTop, akRight];
  TitleLabel.Transparent := True;
  TitleLabel.Font.Color := ChromeTextColor;
  TitleLabel.Font.Style := [fsBold];
  TitleLabel.OnMouseDown := @PaletteMouseDown;
  TitleLabel.OnMouseMove := @PaletteMouseMove;
  TitleLabel.OnMouseUp := @PaletteMouseUp;

  ShortcutLabel := TLabel.Create(HeaderPanel);
  ShortcutLabel.Parent := HeaderPanel;
  ShortcutLabel.Caption := PaletteShortcutDigit(AKind);
  ShortcutLabel.Left := ATarget.Width - 42;
  ShortcutLabel.Top := 5;
  ShortcutLabel.Width := 10;
  ShortcutLabel.Height := 12;
  ShortcutLabel.AutoSize := False;
  ShortcutLabel.Alignment := taCenter;
  ShortcutLabel.Anchors := [akTop, akRight];
  ShortcutLabel.Transparent := True;
  ShortcutLabel.Font.Color := ChromeMutedTextColor;
  ShortcutLabel.Font.Size := 7;
  ShortcutLabel.OnMouseDown := @PaletteMouseDown;
  ShortcutLabel.OnMouseMove := @PaletteMouseMove;
  ShortcutLabel.OnMouseUp := @PaletteMouseUp;

  if AKind <> pkTools then
  begin
    CloseButton := CreateButton(
      '×',
      ATarget.Width - 28,
      2,
      24,
      @HidePaletteClick,
      HeaderPanel,
      Ord(AKind),
      bicCommand
    );
    CloseButton.Height := 18;
    CloseButton.Anchors := [akTop, akRight];
    CloseButton.Hint := Format(
      TR('Close %s palette (%s toggles it)', '关闭%s面板（%s可切换）'),
      [PaletteTitle(AKind), PaletteShortcutLabel(AKind)]
    );
  end;
end;

procedure TMainForm.CreatePalette(ATarget: TPanel; AKind: TPaletteKind);
var
  PaletteRect: TRect;
  WorkspaceRect: TRect;
begin
  if Assigned(FWorkspacePanel) and (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
  begin
    WorkspaceRect := PaletteClampWorkspaceRect(
      Rect(0, 0, FWorkspacePanel.ClientWidth, FWorkspacePanel.ClientHeight),
      FShowRulers
    );
    PaletteRect := PaletteDefaultRectForWorkspace(
      AKind,
      WorkspaceRect
    )
  end
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
  ContentTop = 30;
  BottomMargin = 8;
  { Left column sizes }
  SwatchBoxW = 60;
  SwatchBoxH = 56;
  WheelSize = 160;
  PaletteRowH = 48;
  { Right-column (detail) constants }
  DetailLeftX = 180;
  DetailBarH = 14;
  DetailRowH = 22;
  DetailHeaderH = 18;
  SpinW = 52;
  SpinH = 22;
  HexW = 80;
var
  LeftColW: Integer;
  WheelTop: Integer;
  SwatchTop: Integer;
  ShowDetail: Boolean;
  DetailW: Integer;
  DetailTop: Integer;
  BarGradLeft: Integer;
  BarGradW: Integer;
  SpinX: Integer;
  RowY: Integer;
  procedure PositionSpin(ASpin: TSpinEdit; ARowY: Integer);
  begin
    if Assigned(ASpin) then
    begin
      ASpin.Left := SpinX;
      ASpin.Top := DetailTop + ARowY;
      ASpin.Width := SpinW;
      ASpin.Height := SpinH;
      ASpin.Visible := ShowDetail;
    end;
  end;
begin
  if not Assigned(FColorsPanel) then
    Exit;

  ShowDetail := FColorExpanded;
  LeftColW := FColorsPanel.Width - Margin * 2;
  if ShowDetail then
    LeftColW := Min(LeftColW, DetailLeftX - Margin);

  { ── FG/BG swatch pair ────────────────────────────────────────────────── }
  if Assigned(FColorsBox) then
  begin
    FColorsBox.Left := Margin;
    FColorsBox.Top := ContentTop;
    FColorsBox.Width := SwatchBoxW;
    FColorsBox.Height := SwatchBoxH;
  end;

  { ── Expand button ────────────────────────────────────────────────────── }
  if Assigned(FColorExpandButton) then
  begin
    if ShowDetail then
      FColorExpandButton.Caption := TR('<< Normal', '<< ' + #$E5#$B8#$B8#$E8#$A7#$84)
    else
      FColorExpandButton.Caption := TR('Normal >>', #$E5#$B8#$B8#$E8#$A7#$84 + ' >>');
    FColorExpandButton.Left := FColorsPanel.Width - Margin - 72;
    FColorExpandButton.Top := ContentTop;
    FColorExpandButton.Width := 72;
    FColorExpandButton.Height := 22;
  end;

  { ── Color wheel ──────────────────────────────────────────────────────── }
  WheelTop := ContentTop + SwatchBoxH + 6;
  if Assigned(FColorWheelBox) then
  begin
    FColorWheelBox.Left := Margin;
    FColorWheelBox.Top := WheelTop;
    FColorWheelBox.Width := Min(WheelSize, LeftColW);
    FColorWheelBox.Height := Min(WheelSize, LeftColW);
  end;

  { ── Swatch grid ──────────────────────────────────────────────────────── }
  SwatchTop := WheelTop + Min(WheelSize, LeftColW) + 6;
  if Assigned(FSwatchBox) then
  begin
    FSwatchBox.Left := Margin;
    FSwatchBox.Top := SwatchTop;
    FSwatchBox.Width := LeftColW;
    FSwatchBox.Height := PaletteRowH;
    FSwatchBox.Visible := True;
  end;

  { ── Detail panel (right side, visible when expanded) ─────────────────── }
  if ShowDetail then
  begin
    DetailW := FColorsPanel.Width - DetailLeftX - Margin;
    DetailTop := ContentTop + 4;
    BarGradLeft := 24;
    BarGradW := Max(24, DetailW - BarGradLeft - SpinW - 6);
    SpinX := DetailLeftX + DetailW - SpinW;
    if Assigned(FColorDetailBox) then
    begin
      FColorDetailBox.Left := DetailLeftX;
      FColorDetailBox.Top := DetailTop;
      FColorDetailBox.Width := DetailW - SpinW - 6;
      FColorDetailBox.Height := 260;
      FColorDetailBox.Visible := True;
    end;
    { R, G, B spins }
    PositionSpin(FColorRSpin, DetailHeaderH);
    PositionSpin(FColorGSpin, DetailHeaderH + DetailRowH);
    PositionSpin(FColorBSpin, DetailHeaderH + DetailRowH * 2);
    { Hex edit }
    if Assigned(FColorHexEdit) then
    begin
      FColorHexEdit.Left := DetailLeftX + BarGradLeft;
      FColorHexEdit.Top := DetailTop + DetailHeaderH + DetailRowH * 3 + 4;
      FColorHexEdit.Width := HexW;
      FColorHexEdit.Height := SpinH;
      FColorHexEdit.Visible := True;
    end;
    { H, S, V spins }
    RowY := DetailHeaderH * 2 + DetailRowH * 3 + 8 + SpinH;
    PositionSpin(FColorHSpin, RowY);
    PositionSpin(FColorSSpin, RowY + DetailRowH);
    PositionSpin(FColorVSpin, RowY + DetailRowH * 2);
    { Alpha }
    RowY := RowY + DetailRowH * 3 + DetailHeaderH;
    PositionSpin(FColorASpin, RowY);
  end
  else
  begin
    { Hide all detail controls when collapsed }
    if Assigned(FColorDetailBox) then
      FColorDetailBox.Visible := False;
    if Assigned(FColorRSpin) then FColorRSpin.Visible := False;
    if Assigned(FColorGSpin) then FColorGSpin.Visible := False;
    if Assigned(FColorBSpin) then FColorBSpin.Visible := False;
    if Assigned(FColorHSpin) then FColorHSpin.Visible := False;
    if Assigned(FColorSSpin) then FColorSSpin.Visible := False;
    if Assigned(FColorVSpin) then FColorVSpin.Visible := False;
    if Assigned(FColorASpin) then FColorASpin.Visible := False;
    if Assigned(FColorHexEdit) then FColorHexEdit.Visible := False;
  end;
end;

procedure TMainForm.LayoutLayersPanel;
const
  Margin = 12;
  ContentTop = 30;
  ListTop = ContentTop + 108;
  BottomMargin = 12;
begin
  if not Assigned(FRightPanel) or not Assigned(FLayerList) then
    Exit;
  FLayerList.Left := Margin;
  FLayerList.Top := ListTop;
  FLayerList.Width := FRightPanel.Width - Margin * 2;
  FLayerList.Height := Max(80, FRightPanel.Height - ListTop - BottomMargin);
  LayerGridApplyColumnWidths(FLayerList);
end;

procedure TMainForm.ColorsPanelResize(Sender: TObject);
begin
  LayoutColorsPanel;
  if Assigned(FColorsBox) then
    FColorsBox.Invalidate;
  if Assigned(FColorWheelBox) then
    FColorWheelBox.Invalidate;
  if Assigned(FColorDetailBox) then
    FColorDetailBox.Invalidate;
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
    TR('Save Changes', '保存更改'),
    Format(
      TR('The current document has unsaved changes. Save before %s?',
         '当前文档有未保存的更改。是否在%s之前保存？'),
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
  Ext: string;
  ExportFormat: TExportFormat;
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

  SaveOpts := FSaveSurfaceOptions;
  Ext := LowerCase(ExtractFileExt(ResolvedFileName));

  Surface := FDocument.Composite;
  try
    if TryExportFormatForExtension(Ext, ExportFormat) then
    begin
      if not RunExportOptionsDialog(Self, ExportFormat, Surface, SaveOpts) then
        Exit;
    end;

    FSaveSurfaceOptions := SaveOpts;

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
  SealPendingStrokeHistory;
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
  ResetTransientCanvasState;
  SyncDocumentReplacementUI(False);
  RegisterRecentFile(FCurrentFileName);
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

function FlatPaintClipboardMetaFormatID: TClipboardFormat;
begin
  Result := RegisterClipboardFormat(FlatPaintClipboardMetaFormatName);
end;

procedure TMainForm.PublishSurfaceToSystemClipboard(ASurface: TRasterSurface; const AOffset: TPoint);
var
  Bitmap: TBitmap;
begin
  if ASurface = nil then
    Exit;
  Bitmap := nil;
  try
    Bitmap := SurfaceToBitmap(ASurface);
    PublishBitmapToClipboardWithMeta(
      Clipboard,
      Bitmap,
      FlatPaintClipboardMetaFormatID,
      AOffset,
      ASurface.Width,
      ASurface.Height
    );
  except
    { Keep in-app clipboard routes usable even if system clipboard access fails. }
  end;
  Bitmap.Free;
end;

function TMainForm.TryLoadSurfaceFromSystemClipboard(
  out ASurface: TRasterSurface;
  out AOffset: TPoint
): Boolean;
var
  ClipboardPicture: TPicture;
  ClipboardBitmap: TBitmap;
  MetaStream: TMemoryStream;
  LoadedOffset: TPoint;
begin
  Result := False;
  ASurface := nil;
  AOffset := Point(0, 0);
  if not Clipboard.HasPictureFormat then
    Exit;

  ClipboardPicture := nil;
  ClipboardBitmap := nil;
  MetaStream := nil;
  try
    ClipboardPicture := TPicture.Create;
    Clipboard.AssignTo(ClipboardPicture);
    if (ClipboardPicture.Graphic = nil) or ClipboardPicture.Graphic.Empty then
      Exit;

    ClipboardBitmap := TBitmap.Create;
    ClipboardBitmap.Assign(ClipboardPicture.Graphic);
    ASurface := BitmapToSurface(ClipboardBitmap);
    if ASurface = nil then
      Exit;

    MetaStream := TMemoryStream.Create;
    if Clipboard.GetFormat(FlatPaintClipboardMetaFormatID, MetaStream) then
    begin
      if TryReadClipboardSurfaceMeta(
        MetaStream,
        LoadedOffset,
        ASurface.Width,
        ASurface.Height
      ) then
        AOffset := LoadedOffset;
    end;
    Result := True;
  except
    FreeAndNil(ASurface);
    AOffset := Point(0, 0);
    Result := False;
  end;
  MetaStream.Free;
  ClipboardBitmap.Free;
  ClipboardPicture.Free;
end;

function TMainForm.TryResolvePasteSurface(out ASurface: TRasterSurface; out AOffset: TPoint): Boolean;
var
  LoadedSurface: TRasterSurface;
begin
  LoadedSurface := nil;
  if TryLoadSurfaceFromSystemClipboard(LoadedSurface, AOffset) then
  begin
    FreeAndNil(FClipboardSurface);
    FClipboardSurface := LoadedSurface;
    FClipboardOffset := AOffset;
  end;

  Result := FClipboardSurface <> nil;
  if Result then
  begin
    ASurface := FClipboardSurface;
    AOffset := FClipboardOffset;
    { When the clipboard image exactly matches the document canvas size,
      paste at origin so the image fills the canvas without offset.
      This covers: cross-tab paste after New (sized to clipboard),
      and external paste into a matching-size canvas. }
    if Assigned(FDocument) and
       (ASurface.Width = FDocument.Width) and
       (ASurface.Height = FDocument.Height) then
      AOffset := Point(0, 0);
  end
  else
  begin
    ASurface := nil;
    AOffset := Point(0, 0);
  end;
end;

procedure TMainForm.ApplyZoomScale(ANewScale: Double);
begin
  ANewScale := ClampZoomScale(ANewScale);
  if ZoomScaleEffectivelyEqual(ANewScale, FZoomScale) then
    Exit;
  if Assigned(FCanvasHost) then
    ApplyZoomScaleAtViewportPoint(
      ANewScale,
      Point(Max(0, FCanvasHost.ClientWidth div 2), Max(0, FCanvasHost.ClientHeight div 2))
    )
  else
  begin
    FZoomScale := ANewScale;
    RefreshCanvas;
  end;
end;

procedure TMainForm.ApplyZoomScaleAtViewportPoint(ANewScale: Double; const AViewportPoint: TPoint);
var
  AnchorImagePoint: TPoint;
  AnchorViewportPoint: TPoint;
  TargetHorizontal: Integer;
  TargetVertical: Integer;
begin
  ANewScale := ClampZoomScale(ANewScale);
  if ZoomScaleEffectivelyEqual(ANewScale, FZoomScale) then
    Exit;

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
        FPaintBox.Left + FCanvasPadX,
        FZoomScale,
        FDocument.Width
      ),
      ViewportImageCoordinate(
        FCanvasHost.VertScrollBar.Position,
        AnchorViewportPoint.Y,
        FPaintBox.Top + FCanvasPadY,
        FZoomScale,
        FDocument.Height
      )
    )
  else
    AnchorImagePoint := Point(Max(0, FDocument.Width div 2), Max(0, FDocument.Height div 2));

  FZoomScale := ANewScale;
  UpdateCanvasSize;
  if Assigned(FCanvasHost) then
  begin
    if FPaintBox.Width <= FCanvasHost.ClientWidth then
      TargetHorizontal := 0
    else
      TargetHorizontal := ScrollPositionForAnchor(
        AnchorImagePoint.X,
        FZoomScale,
        FPaintBox.Left + FCanvasPadX,
        AnchorViewportPoint.X
      );
    TargetHorizontal := ClampViewportScrollPosition(
      TargetHorizontal,
      FPaintBox.Left,
      FPaintBox.Width,
      FCanvasHost.ClientWidth
    );
    if TargetHorizontal <> FCanvasHost.HorzScrollBar.Position then
      FCanvasHost.HorzScrollBar.Position := TargetHorizontal;

    if FPaintBox.Height <= FCanvasHost.ClientHeight then
      TargetVertical := 0
    else
      TargetVertical := ScrollPositionForAnchor(
        AnchorImagePoint.Y,
        FZoomScale,
        FPaintBox.Top + FCanvasPadY,
        AnchorViewportPoint.Y
      );
    TargetVertical := ClampViewportScrollPosition(
      TargetVertical,
      FPaintBox.Top,
      FPaintBox.Height,
      FCanvasHost.ClientHeight
    );
    if TargetVertical <> FCanvasHost.VertScrollBar.Position then
      FCanvasHost.VertScrollBar.Position := TargetVertical;

    FLastScrollPosition := Point(
      FCanvasHost.HorzScrollBar.Position,
      FCanvasHost.VertScrollBar.Position
    );
  end;
  RefreshCanvas;
end;

function ToolPaintPathUsesActiveSelection(ATool: TToolKind): Boolean;
begin
  { All paint/draw/shape tools honour the active selection mask so strokes
    and fills are clipped to the selected region, matching paint.net/
    Photoshop/GIMP behaviour.  Only non-paint tools are excluded. }
  Result := not (ATool in [
    tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand,
    tkMoveSelection, tkMovePixels,
    tkZoom, tkPan, tkColorPicker, tkCrop, tkText
  ]);
end;

procedure TMainForm.ApplyImmediateTool(const APoint: TPoint);
var
  CompositeSurface: TRasterSurface;
  SampleSurface: TRasterSurface;
  FillMask: TSelectionMask;
  LocalFillMask: TSelectionMask;
  PaintSelection: TSelectionMask;
  OwnedPaintSelection: TSelectionMask;
  Radius: Integer;
  DestX: Integer;
  DestY: Integer;
  DestCanvasX: Integer;
  DestCanvasY: Integer;
  SourceX: Integer;
  SourceY: Integer;
  PickedColor: TRGBA32;
  { Stroke interpolation variables }
  StrokeDX, StrokeDY: Double;
  StrokeDist: Double;
  StrokeSpacing: Integer;
  StrokeSteps: Integer;
  StrokeStep: Integer;
  StepCanvasPoint: TPoint;
  StepLocalPoint: TPoint;
  LocalPoint: TPoint;
  LocalLastPoint: TPoint;
  LocalDragStart: TPoint;
  LocalCloneSource: TPoint;
  StrokeRadius: Integer;
  MutableSurface: TRasterSurface;
  RecolorSourceColor: TRGBA32;
  BrushHardnessByte: Byte;
  FillMaskIsLayerSpace: Boolean;
begin
  OwnedPaintSelection := nil;
  SampleSurface := nil;
  FillMask := nil;
  LocalFillMask := nil;
  FillMaskIsLayerSpace := False;
  try
    if ToolPaintPathUsesActiveSelection(FCurrentTool) and FDocument.HasSelection then
      OwnedPaintSelection := FDocument.ActiveSelectionInLayerSpace;
    PaintSelection := OwnedPaintSelection;
    LocalPoint := ActiveLayerLocalPoint(APoint);
    LocalLastPoint := ActiveLayerLocalPoint(FLastImagePoint);
    LocalDragStart := ActiveLayerLocalPoint(FDragStart);
    LocalCloneSource := ActiveLayerLocalPoint(FCloneStampSource);

    case FCurrentTool of
      tkPencil:
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            StrokeRadius := Max(0, (FBrushSize - 1) div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, StrokeRadius));
            MutableSurface.DrawLine(
              LocalLastPoint.X,
              LocalLastPoint.Y,
              LocalPoint.X,
              LocalPoint.Y,
              StrokeRadius,
              ActivePaintColor,
              FBrushOpacity * 255 div 100,
              255, { pencil always hard }
              PaintSelection
            );
          end;
        end;
      tkBrush:
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            { Brush stays slightly soft even at 100% hardness;
              pencil remains the fully hard-edged tool. }
            BrushHardnessByte := EnsureRange((FBrushHardness * 240) div 100, 1, 240);
            StrokeRadius := Max(1, FBrushSize div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, StrokeRadius));
            MutableSurface.DrawSpacedLine(
              LocalLastPoint.X,
              LocalLastPoint.Y,
              LocalPoint.X,
              LocalPoint.Y,
              StrokeRadius,
              ActivePaintColor,
              FBrushOpacity * 255 div 100,
              BrushHardnessByte,
              PaintSelection
            );
          end;
        end;
      tkEraser:
        if FDocument.ActiveLayer.IsBackground then
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            StrokeRadius := Max(1, FBrushSize div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, StrokeRadius));
            if FEraserSquareShape then
              MutableSurface.DrawSquareLine(
                LocalLastPoint.X,
                LocalLastPoint.Y,
                LocalPoint.X,
                LocalPoint.Y,
                StrokeRadius,
                BackgroundToolColor,
                FBrushOpacity * 255 div 100,
                FBrushHardness * 255 div 100,
                PaintSelection
              )
            else
              MutableSurface.DrawSpacedLine(
                LocalLastPoint.X,
                LocalLastPoint.Y,
                LocalPoint.X,
                LocalPoint.Y,
                StrokeRadius,
                BackgroundToolColor,
                FBrushOpacity * 255 div 100,
                FBrushHardness * 255 div 100,
                PaintSelection
              );
          end;
        end
        else if FEraserSquareShape then
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            StrokeRadius := Max(1, FBrushSize div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, StrokeRadius));
            MutableSurface.EraseSquareLine(
              LocalLastPoint.X,
              LocalLastPoint.Y,
              LocalPoint.X,
              LocalPoint.Y,
              StrokeRadius,
              FBrushOpacity * 255 div 100,
              FBrushHardness * 255 div 100,
              PaintSelection
            );
          end;
        end
        else
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            StrokeRadius := Max(1, FBrushSize div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, StrokeRadius));
            MutableSurface.EraseSpacedLine(
              LocalLastPoint.X,
              LocalLastPoint.Y,
              LocalPoint.X,
              LocalPoint.Y,
              StrokeRadius,
              FBrushOpacity * 255 div 100,
              FBrushHardness * 255 div 100,
              PaintSelection
            );
          end;
        end;
      tkFill:
        begin
          try
            { Selection-first bucket semantics: when a selection is active and
              the click is inside it, fill the full selected coverage. }
            if PaintSelection <> nil then
            begin
              FillMask := PaintSelection.Clone;
              FillMaskIsLayerSpace := True;
            end
            else
            begin
              if FFillSampleSource = 1 then
                SampleSurface := FDocument.Composite
              else
                { Use the layer surface directly; do NOT free it later. }
                SampleSurface := nil;

              if FBucketFloodMode = 1 then
              begin
                if FFillSampleSource = 1 then
                  FillMask := SampleSurface.CreateGlobalColorSelection(
                    APoint.X,
                    APoint.Y,
                    EnsureRange(FFillTolerance, 0, 255)
                  )
                else
                  FillMask := FDocument.ActiveLayer.Surface.CreateGlobalColorSelection(
                    LocalPoint.X,
                    LocalPoint.Y,
                    EnsureRange(FFillTolerance, 0, 255)
                  );
                FillMaskIsLayerSpace := FFillSampleSource = 0;
              end
              else
              begin
                if FFillSampleSource = 1 then
                  FillMask := SampleSurface.CreateContiguousSelection(
                    APoint.X,
                    APoint.Y,
                    EnsureRange(FFillTolerance, 0, 255)
                  )
                else
                  FillMask := FDocument.ActiveLayer.Surface.CreateContiguousSelection(
                    LocalPoint.X,
                    LocalPoint.Y,
                    EnsureRange(FFillTolerance, 0, 255)
                  );
                FillMaskIsLayerSpace := FFillSampleSource = 0;
              end;
            end;

            if FillMask <> nil then
            begin
              if (FFillSampleSource = 1) and (not FillMaskIsLayerSpace) then
              begin
                if FDocument.HasSelection then
                  FillMask.IntersectWith(FDocument.Selection);
                LocalFillMask := FDocument.SelectionToActiveLayerSpace(FillMask);
                FillMask.Free;
                FillMask := LocalFillMask;
                LocalFillMask := nil;
                FillMaskIsLayerSpace := True;
              end
              else if (PaintSelection <> nil) and (not FillMaskIsLayerSpace) then
                FillMask.IntersectWith(PaintSelection);
            end;

            MutableSurface := FDocument.MutableActiveLayerSurface;
            if (MutableSurface <> nil) and (FillMask <> nil) then
              MutableSurface.FillSelection(
                FillMask,
                ActivePaintColor,
                255
              );
          finally
            FillMask.Free;
            FillMask := nil;
            if SampleSurface <> nil then
            begin
              SampleSurface.Free;
              SampleSurface := nil;
            end;
          end;
        end;
      tkColorPicker:
        begin
          PickedColor := ColorForActiveTarget(FPickSecondaryTarget);
          if FPickerSampleSource = 1 then
          begin
            { Sample from composite image }
            CompositeSurface := FDocument.Composite;
            try
              PickedColor := Unpremultiply(CompositeSurface[APoint.X, APoint.Y]);
            finally
              CompositeSurface.Free;
            end;
          end
          else
          begin
            { Sample from current layer only }
            if FDocument.ActiveLayer.Surface.InBounds(LocalPoint.X, LocalPoint.Y) then
              PickedColor := Unpremultiply(FDocument.ActiveLayer.Surface[LocalPoint.X, LocalPoint.Y]);
          end;
          if FPickSecondaryTarget then
            FSecondaryColor := AdoptSampledRGBPreservingAlpha(FSecondaryColor, PickedColor)
          else
            FPrimaryColor := AdoptSampledRGBPreservingAlpha(FPrimaryColor, PickedColor);
        end;
      tkRecolor:
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            Radius := Max(1, FBrushSize div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, Radius));
            StrokeSpacing := Max(1, Radius div 2);
            StrokeDX := APoint.X - FLastImagePoint.X;
            StrokeDY := APoint.Y - FLastImagePoint.Y;
            StrokeDist := Sqrt(StrokeDX * StrokeDX + StrokeDY * StrokeDY);
            if StrokeDist < 1 then
              StrokeSteps := 1
            else
              StrokeSteps := Max(1, Round(StrokeDist / StrokeSpacing));
            for StrokeStep := 0 to StrokeSteps - 1 do
            begin
              if StrokeSteps = 1 then
                StepCanvasPoint := APoint
              else
                StepCanvasPoint := Point(
                  FLastImagePoint.X + Round(StrokeDX * (StrokeStep + 1) / StrokeSteps),
                  FLastImagePoint.Y + Round(StrokeDY * (StrokeStep + 1) / StrokeSteps)
                );
              StepLocalPoint := ActiveLayerLocalPoint(StepCanvasPoint);

              case FRecolorSamplingMode of
                rsmContinuous:
                  begin
                    if not RecolorSourceAtPoint(StepCanvasPoint, RecolorSourceColor) and
                       FRecolorStrokeSourceValid then
                      RecolorSourceColor := FRecolorStrokeSourceColor;
                  end;
                rsmSwatchCompat:
                  RecolorSourceColor := ColorForActiveTarget(not FPickSecondaryTarget);
              else
                begin
                  if not FRecolorStrokeSourceValid then
                  begin
                    if RecolorSourceAtPoint(FDragStart, FRecolorStrokeSourceColor) then
                      FRecolorStrokeSourceValid := True
                    else
                      FRecolorStrokeSourceColor := ColorForActiveTarget(not FPickSecondaryTarget);
                  end;
                  RecolorSourceColor := FRecolorStrokeSourceColor;
                end;
              end;

              MutableSurface.RecolorBrush(
                StepLocalPoint.X,
                StepLocalPoint.Y,
                Radius,
                RecolorSourceColor,
                ActivePaintColor,
                EnsureRange(FRecolorTolerance, 0, 255),
                FBrushOpacity * 255 div 100,
                FRecolorPreserveValue,
                PaintSelection,
                FRecolorBlendMode,
                FRecolorContiguous,
                FRecolorStrokeSnapshot
              );
            end;
          end;
        end;
      tkCloneStamp:
        if FCloneStampSampled and (FCloneStampSnapshot <> nil) then
        begin
          MutableSurface := FDocument.MutableActiveLayerSurface;
          if MutableSurface <> nil then
          begin
            Radius := Max(1, FBrushSize div 2);
            CaptureStrokeBeforeRect(StrokeBoundsForSegment(LocalLastPoint, LocalPoint, Radius));
            StrokeSpacing := Max(1, Radius div 2);
            StrokeDX := APoint.X - FLastImagePoint.X;
            StrokeDY := APoint.Y - FLastImagePoint.Y;
            StrokeDist := Sqrt(StrokeDX * StrokeDX + StrokeDY * StrokeDY);
            if StrokeDist < 1 then
              StrokeSteps := 1
            else
              StrokeSteps := Max(1, Round(StrokeDist / StrokeSpacing));
            for StrokeStep := 0 to StrokeSteps - 1 do
            begin
              if StrokeSteps = 1 then
                StepCanvasPoint := APoint
              else
                StepCanvasPoint := Point(
                  FLastImagePoint.X + Round(StrokeDX * (StrokeStep + 1) / StrokeSteps),
                  FLastImagePoint.Y + Round(StrokeDY * (StrokeStep + 1) / StrokeSteps)
                );
              StepLocalPoint := ActiveLayerLocalPoint(StepCanvasPoint);
              for DestY := Max(0, StepLocalPoint.Y - Radius) to Min(MutableSurface.Height - 1, StepLocalPoint.Y + Radius) do
                for DestX := Max(0, StepLocalPoint.X - Radius) to Min(MutableSurface.Width - 1, StepLocalPoint.X + Radius) do
                begin
                  if Round(Sqrt(Sqr(DestX - StepLocalPoint.X) + Sqr(DestY - StepLocalPoint.Y))) > Radius then
                    Continue;
                  if FCloneSampleSource = 1 then
                  begin
                    DestCanvasX := DestX + FDocument.ActiveLayer.OffsetX;
                    DestCanvasY := DestY + FDocument.ActiveLayer.OffsetY;
                    if FCloneAligned and FCloneAlignedOffsetValid then
                    begin
                      SourceX := DestCanvasX + FCloneAlignedOffset.X;
                      SourceY := DestCanvasY + FCloneAlignedOffset.Y;
                    end
                    else
                    begin
                      SourceX := FCloneStampSource.X + (DestCanvasX - FDragStart.X);
                      SourceY := FCloneStampSource.Y + (DestCanvasY - FDragStart.Y);
                    end;
                  end
                  else if FCloneAligned and FCloneAlignedOffsetValid then
                  begin
                    SourceX := DestX + FCloneAlignedOffset.X;
                    SourceY := DestY + FCloneAlignedOffset.Y;
                  end
                  else
                  begin
                    SourceX := LocalCloneSource.X + (DestX - LocalDragStart.X);
                    SourceY := LocalCloneSource.Y + (DestY - LocalDragStart.Y);
                  end;
                  if not FCloneStampSnapshot.InBounds(SourceX, SourceY) then
                    Continue;
                  MutableSurface.BlendPixelPremul(
                    DestX,
                    DestY,
                    FCloneStampSnapshot[SourceX, SourceY],
                    FBrushOpacity * 255 div 100,
                    PaintSelection
                  );
                end;
            end;
          end;
        end;
    end;
  finally
    OwnedPaintSelection.Free;
  end;
  FLastImagePoint := APoint;
end;

{ ConstrainShapePoint — apply Shift-key constraints (Photoshop-style).
  For rectangles/ellipses: force equal width and height (square/circle).
  For lines: snap angle to nearest 45 degree increment. }
function ConstrainShapePoint(const AOrigin, ACurrent: TPoint; ATool: TToolKind): TPoint;
var
  DX, DY: Integer;
  Dist: Integer;
  Angle: Double;
  SnapAngle: Double;
  Len: Double;
begin
  DX := ACurrent.X - AOrigin.X;
  DY := ACurrent.Y - AOrigin.Y;
  case ATool of
    tkRectangle, tkRoundedRectangle, tkSelectRect, tkCrop:
      begin
        { Square constraint — use the larger dimension for both axes }
        Dist := Max(Abs(DX), Abs(DY));
        if DX < 0 then
          Result.X := AOrigin.X - Dist
        else
          Result.X := AOrigin.X + Dist;
        if DY < 0 then
          Result.Y := AOrigin.Y - Dist
        else
          Result.Y := AOrigin.Y + Dist;
      end;
    tkEllipseShape, tkSelectEllipse:
      begin
        { Circle constraint — use the larger dimension for both axes }
        Dist := Max(Abs(DX), Abs(DY));
        if DX < 0 then
          Result.X := AOrigin.X - Dist
        else
          Result.X := AOrigin.X + Dist;
        if DY < 0 then
          Result.Y := AOrigin.Y - Dist
        else
          Result.Y := AOrigin.Y + Dist;
      end;
    tkLine, tkGradient:
      begin
        { Snap angle to nearest 45-degree increment }
        Len := Sqrt(Sqr(Double(DX)) + Sqr(Double(DY)));
        if Len < 1 then
        begin
          Result := ACurrent;
          Exit;
        end;
        Angle := ArcTan2(-DY, DX);  { Standard math: Y up = positive }
        SnapAngle := Round(Angle / (Pi / 4)) * (Pi / 4);
        Result.X := AOrigin.X + Round(Len * Cos(SnapAngle));
        Result.Y := AOrigin.Y - Round(Len * Sin(SnapAngle));
      end;
  else
    Result := ACurrent;
  end;
end;

procedure TMainForm.CommitShapeTool(const AStartPoint, AEndPoint: TPoint);
var
  DoFill: Boolean;
  DoOutline: Boolean;
  UseDashedOutline: Boolean;
  FillColor: TRGBA32;
  PaintSelection: TSelectionMask;
  OwnedPaintSelection: TSelectionMask;
  MutableSurface: TRasterSurface;
  LocalStartPoint: TPoint;
  LocalEndPoint: TPoint;
  LocalCurveEndPoint: TPoint;
  LocalCurveControlPoint: TPoint;
  LocalCurveControlPoint2: TPoint;
  LocalLassoPoints: array of TPoint;
  CurvePoints: array of TPoint;
  SegmentCount: Integer;
  Step: Integer;
  TValue: Double;
  InverseT: Double;
  LeftX: Integer;
  RightX: Integer;
  TopY: Integer;
  BottomY: Integer;
  CenterX: Double;
  CenterY: Double;
  RadiusX: Double;
  RadiusY: Double;
  CornerRadius: Integer;
  StrokeWidth: Integer;
  DashLength: Integer;
  GapLength: Integer;
  LineRadius: Integer;
  LassoIndex: Integer;
  procedure DrawDashedRectangleOutline(
    const AFromPoint, AToPoint: TPoint;
    AStrokeWidth: Integer
  );
  var
    RectPoints: array[0..3] of TPoint;
  begin
    LeftX := Min(AFromPoint.X, AToPoint.X);
    RightX := Max(AFromPoint.X, AToPoint.X);
    TopY := Min(AFromPoint.Y, AToPoint.Y);
    BottomY := Max(AFromPoint.Y, AToPoint.Y);
    RectPoints[0] := Point(LeftX, TopY);
    RectPoints[1] := Point(RightX, TopY);
    RectPoints[2] := Point(RightX, BottomY);
    RectPoints[3] := Point(LeftX, BottomY);
    MutableSurface.DrawDashedPolyline(
      RectPoints,
      AStrokeWidth,
      ActivePaintColor,
      True,
      DashLength,
      GapLength,
      255,
      255,
      PaintSelection
    );
  end;
  procedure DrawDashedEllipseOutline(
    const AFromPoint, AToPoint: TPoint;
    AStrokeWidth: Integer
  );
  var
    EllipseStep: Integer;
  begin
    LeftX := Min(AFromPoint.X, AToPoint.X);
    RightX := Max(AFromPoint.X, AToPoint.X);
    TopY := Min(AFromPoint.Y, AToPoint.Y);
    BottomY := Max(AFromPoint.Y, AToPoint.Y);
    CenterX := (LeftX + RightX) / 2.0;
    CenterY := (TopY + BottomY) / 2.0;
    RadiusX := Max(0.5, (RightX - LeftX + 1) / 2.0);
    RadiusY := Max(0.5, (BottomY - TopY + 1) / 2.0);
    SegmentCount := Max(24, Round(2.0 * Pi * Max(RadiusX, RadiusY)));
    SetLength(CurvePoints, SegmentCount);
    for EllipseStep := 0 to SegmentCount - 1 do
    begin
      TValue := (2.0 * Pi * EllipseStep) / SegmentCount;
      CurvePoints[EllipseStep] := Point(
        Round(CenterX + (Cos(TValue) * RadiusX)),
        Round(CenterY + (Sin(TValue) * RadiusY))
      );
    end;
    MutableSurface.DrawDashedPolyline(
      CurvePoints,
      AStrokeWidth,
      ActivePaintColor,
      True,
      DashLength,
      GapLength,
      255,
      255,
      PaintSelection
    );
  end;
  procedure DrawDashedRoundedRectangleOutline(
    const AFromPoint, AToPoint: TPoint;
    AStrokeWidth: Integer;
    ACornerRadius: Integer
  );
  var
    ArcSteps: Integer;
    ArcStep: Integer;
    Theta: Double;
    PointCount: Integer;
    procedure AppendPoint(AX, AY: Integer);
    begin
      Inc(PointCount);
      SetLength(CurvePoints, PointCount);
      CurvePoints[PointCount - 1] := Point(AX, AY);
    end;
  begin
    LeftX := Min(AFromPoint.X, AToPoint.X);
    RightX := Max(AFromPoint.X, AToPoint.X);
    TopY := Min(AFromPoint.Y, AToPoint.Y);
    BottomY := Max(AFromPoint.Y, AToPoint.Y);
    if ACornerRadius > 0 then
      CornerRadius := ACornerRadius
    else
      CornerRadius := Max(2, Min((RightX - LeftX + 1) div 4, (BottomY - TopY + 1) div 4));
    CornerRadius := EnsureRange(
      CornerRadius,
      1,
      Max(1, Min((RightX - LeftX + 1) div 2, (BottomY - TopY + 1) div 2))
    );
    CornerRadius := Max(CornerRadius, AStrokeWidth);
    ArcSteps := Max(4, Round(CornerRadius * Pi / 4.0));
    PointCount := 0;
    SetLength(CurvePoints, 0);

    AppendPoint(LeftX + CornerRadius, TopY);
    AppendPoint(RightX - CornerRadius, TopY);
    for ArcStep := 1 to ArcSteps do
    begin
      Theta := (-Pi / 2.0) + ((Pi / 2.0) * ArcStep / ArcSteps);
      AppendPoint(
        Round((RightX - CornerRadius) + (Cos(Theta) * CornerRadius)),
        Round((TopY + CornerRadius) + (Sin(Theta) * CornerRadius))
      );
    end;

    AppendPoint(RightX, BottomY - CornerRadius);
    for ArcStep := 1 to ArcSteps do
    begin
      Theta := (Pi / 2.0) * ArcStep / ArcSteps;
      AppendPoint(
        Round((RightX - CornerRadius) + (Cos(Theta) * CornerRadius)),
        Round((BottomY - CornerRadius) + (Sin(Theta) * CornerRadius))
      );
    end;

    AppendPoint(LeftX + CornerRadius, BottomY);
    for ArcStep := 1 to ArcSteps do
    begin
      Theta := (Pi / 2.0) + ((Pi / 2.0) * ArcStep / ArcSteps);
      AppendPoint(
        Round((LeftX + CornerRadius) + (Cos(Theta) * CornerRadius)),
        Round((BottomY - CornerRadius) + (Sin(Theta) * CornerRadius))
      );
    end;

    AppendPoint(LeftX, TopY + CornerRadius);
    for ArcStep := 1 to ArcSteps do
    begin
      Theta := Pi + ((Pi / 2.0) * ArcStep / ArcSteps);
      AppendPoint(
        Round((LeftX + CornerRadius) + (Cos(Theta) * CornerRadius)),
        Round((TopY + CornerRadius) + (Sin(Theta) * CornerRadius))
      );
    end;

    if Length(CurvePoints) > 1 then
      MutableSurface.DrawDashedPolyline(
        CurvePoints,
        AStrokeWidth,
        ActivePaintColor,
        True,
        DashLength,
        GapLength,
        255,
        255,
        PaintSelection
      );
  end;
  procedure DrawSolidLineWithNativeAA(
    const AFromPoint, AToPoint: TPoint;
    ARadius: Integer
  );
var
  TempSurface: TRasterSurface;
  PathPoints: array[0..3] of Double;
  StrokeWidth: Double;
begin
{$IFDEF TESTING}
  { Headless tests compile bridge calls to no-op stubs. Keep deterministic
    raster output in tests by using the existing pure-Pascal path. }
  MutableSurface.DrawLine(
    AFromPoint.X,
    AFromPoint.Y,
    AToPoint.X,
    AToPoint.Y,
    ARadius,
    ActivePaintColor,
    255,
    255,
    PaintSelection
  );
{$ELSE}
  try
    if (MutableSurface.Width <= 0) or (MutableSurface.Height <= 0) then
      raise Exception.Create('invalid target surface dimensions');
    StrokeWidth := Max(1.0, (Max(1, ARadius) * 2.0) + 1.0);
    TempSurface := TRasterSurface.Create(MutableSurface.Width, MutableSurface.Height);
    try
      TempSurface.Clear(TransparentColor);
      PathPoints[0] := AFromPoint.X + 0.5;
      PathPoints[1] := AFromPoint.Y + 0.5;
      PathPoints[2] := AToPoint.X + 0.5;
      PathPoints[3] := AToPoint.Y + 0.5;
      FPCGRenderStrokedPath(
        TempSurface.RawPixels,
        TempSurface.Width,
        TempSurface.Height,
        @PathPoints[0],
        2,
        0,
        StrokeWidth,
        ActivePaintColor.R,
        ActivePaintColor.G,
        ActivePaintColor.B,
        ActivePaintColor.A
      );
      MutableSurface.PasteSurface(TempSurface, 0, 0, 255, PaintSelection);
    finally
      TempSurface.Free;
    end;
  except
    { Safety fallback keeps previous raster behavior if native AA path fails. }
    MutableSurface.DrawLine(
      AFromPoint.X,
      AFromPoint.Y,
      AToPoint.X,
      AToPoint.Y,
      ARadius,
      ActivePaintColor,
      255,
      255,
      PaintSelection
    );
  end;
{$ENDIF}
end;
begin
  { FShapeStyle: 0=Outline, 1=Fill, 2=Outline+Fill }
  DoOutline := FShapeStyle in [0, 2];
  DoFill := FShapeStyle in [1, 2];
  UseDashedOutline := DoOutline and (FShapeLineStyle = 1);
  FillColor := RGBA(ActivePaintColor.R, ActivePaintColor.G, ActivePaintColor.B, ActivePaintColor.A);
  StrokeWidth := Max(1, FBrushSize div 3);
  DashLength := Max(6, FBrushSize * 2);
  GapLength := Max(6, FBrushSize * 2);
  MutableSurface := FDocument.MutableActiveLayerSurface;
  if MutableSurface = nil then
    Exit;
  OwnedPaintSelection := nil;
  if ToolPaintPathUsesActiveSelection(FCurrentTool) and FDocument.HasSelection then
    OwnedPaintSelection := FDocument.ActiveSelectionInLayerSpace;
  PaintSelection := OwnedPaintSelection;
  LocalStartPoint := ActiveLayerLocalPoint(AStartPoint);
  LocalEndPoint := ActiveLayerLocalPoint(AEndPoint);
  LocalCurveEndPoint := ActiveLayerLocalPoint(FLineCurveEndPoint);
  LocalCurveControlPoint := ActiveLayerLocalPoint(FLineCurveControlPoint);
  LocalCurveControlPoint2 := ActiveLayerLocalPoint(FLineCurveControlPoint2);
  try
    case FCurrentTool of
      tkLine:
        begin
          LineRadius := Max(1, FBrushSize div 2);
          if FLineCurvePending then
          begin
            if UseDashedOutline then
            begin
              if FLineCurveSecondStage then
                SegmentCount := Max(
                  8,
                  Max(
                    Abs(LocalCurveControlPoint.X - LocalStartPoint.X) + Abs(LocalCurveControlPoint.Y - LocalStartPoint.Y),
                    Max(
                      Abs(LocalCurveControlPoint2.X - LocalCurveControlPoint.X) + Abs(LocalCurveControlPoint2.Y - LocalCurveControlPoint.Y),
                      Abs(LocalCurveEndPoint.X - LocalCurveControlPoint2.X) + Abs(LocalCurveEndPoint.Y - LocalCurveControlPoint2.Y)
                    )
                  ) * 2
                )
              else
                SegmentCount := Max(
                  8,
                  Max(
                    Abs(LocalCurveControlPoint.X - LocalStartPoint.X) + Abs(LocalCurveControlPoint.Y - LocalStartPoint.Y),
                    Abs(LocalCurveEndPoint.X - LocalCurveControlPoint.X) + Abs(LocalCurveEndPoint.Y - LocalCurveControlPoint.Y)
                  ) * 2
                );

              SetLength(CurvePoints, SegmentCount + 1);
              CurvePoints[0] := LocalStartPoint;
              for Step := 1 to SegmentCount do
              begin
                TValue := Step / SegmentCount;
                InverseT := 1.0 - TValue;
                if FLineCurveSecondStage then
                  CurvePoints[Step] := Point(
                    Round(
                      (InverseT * InverseT * InverseT * LocalStartPoint.X) +
                      (3.0 * InverseT * InverseT * TValue * LocalCurveControlPoint.X) +
                      (3.0 * InverseT * TValue * TValue * LocalCurveControlPoint2.X) +
                      (TValue * TValue * TValue * LocalCurveEndPoint.X)
                    ),
                    Round(
                      (InverseT * InverseT * InverseT * LocalStartPoint.Y) +
                      (3.0 * InverseT * InverseT * TValue * LocalCurveControlPoint.Y) +
                      (3.0 * InverseT * TValue * TValue * LocalCurveControlPoint2.Y) +
                      (TValue * TValue * TValue * LocalCurveEndPoint.Y)
                    )
                  )
                else
                  CurvePoints[Step] := Point(
                    Round(
                      (InverseT * InverseT * LocalStartPoint.X) +
                      (2.0 * InverseT * TValue * LocalCurveControlPoint.X) +
                      (TValue * TValue * LocalCurveEndPoint.X)
                    ),
                    Round(
                      (InverseT * InverseT * LocalStartPoint.Y) +
                      (2.0 * InverseT * TValue * LocalCurveControlPoint.Y) +
                      (TValue * TValue * LocalCurveEndPoint.Y)
                    )
                  );
              end;
              MutableSurface.DrawDashedPolyline(
                CurvePoints,
                Max(1, FBrushSize),
                ActivePaintColor,
                False,
                DashLength,
                GapLength,
                255,
                255,
                PaintSelection
              );
            end
            else if FLineCurveSecondStage then
              MutableSurface.DrawCubicBezier(
                LocalStartPoint.X,
                LocalStartPoint.Y,
                LocalCurveControlPoint.X,
                LocalCurveControlPoint.Y,
                LocalCurveControlPoint2.X,
                LocalCurveControlPoint2.Y,
                LocalCurveEndPoint.X,
                LocalCurveEndPoint.Y,
                LineRadius,
                ActivePaintColor,
                255,
                255,
                PaintSelection
              )
            else
              MutableSurface.DrawQuadraticBezier(
                LocalStartPoint.X,
                LocalStartPoint.Y,
                LocalCurveControlPoint.X,
                LocalCurveControlPoint.Y,
                LocalCurveEndPoint.X,
                LocalCurveEndPoint.Y,
                LineRadius,
                ActivePaintColor,
                255,
                255,
                PaintSelection
              );
          end
          else if UseDashedOutline then
            MutableSurface.DrawDashedLine(
              LocalStartPoint.X,
              LocalStartPoint.Y,
              LocalEndPoint.X,
              LocalEndPoint.Y,
              LineRadius,
              ActivePaintColor,
              DashLength,
              GapLength,
              255,
              255,
              PaintSelection
            )
          else
            DrawSolidLineWithNativeAA(
              LocalStartPoint,
              LocalEndPoint,
              LineRadius
            );
        end;
      tkGradient:
        begin
          if FGradientReverse then
            MutableSurface.FillGradientAdvanced(
              LocalStartPoint.X,
              LocalStartPoint.Y,
              LocalEndPoint.X,
              LocalEndPoint.Y,
              FSecondaryColor,
              FPrimaryColor,
              TGradientKind(EnsureRange(FGradientType, 0, Ord(High(TGradientKind)))),
              TGradientRepeatMode(EnsureRange(FGradientRepeatMode, 0, Ord(High(TGradientRepeatMode)))),
              PaintSelection
            )
          else
            MutableSurface.FillGradientAdvanced(
              LocalStartPoint.X,
              LocalStartPoint.Y,
              LocalEndPoint.X,
              LocalEndPoint.Y,
              FPrimaryColor,
              FSecondaryColor,
              TGradientKind(EnsureRange(FGradientType, 0, Ord(High(TGradientKind)))),
              TGradientRepeatMode(EnsureRange(FGradientRepeatMode, 0, Ord(High(TGradientRepeatMode)))),
              PaintSelection
            );
        end;
      tkRectangle:
        begin
          if DoFill then
            MutableSurface.DrawRectangle(
              LocalStartPoint.X, LocalStartPoint.Y, LocalEndPoint.X, LocalEndPoint.Y,
              StrokeWidth, FillColor, True, 255, PaintSelection);
          if DoOutline then
            if UseDashedOutline then
              DrawDashedRectangleOutline(LocalStartPoint, LocalEndPoint, StrokeWidth)
            else
              MutableSurface.DrawRectangle(
                LocalStartPoint.X, LocalStartPoint.Y, LocalEndPoint.X, LocalEndPoint.Y,
                StrokeWidth, ActivePaintColor, False, 255, PaintSelection
              );
        end;
      tkRoundedRectangle:
        begin
          if DoFill then
            MutableSurface.DrawRoundedRectangle(
              LocalStartPoint.X, LocalStartPoint.Y, LocalEndPoint.X, LocalEndPoint.Y,
              StrokeWidth, FillColor, True, 255, PaintSelection, FRoundedCornerRadius);
          if DoOutline then
            if UseDashedOutline then
              DrawDashedRoundedRectangleOutline(LocalStartPoint, LocalEndPoint, StrokeWidth, FRoundedCornerRadius)
            else
              MutableSurface.DrawRoundedRectangle(
                LocalStartPoint.X, LocalStartPoint.Y, LocalEndPoint.X, LocalEndPoint.Y,
                StrokeWidth, ActivePaintColor, False, 255, PaintSelection, FRoundedCornerRadius
              );
        end;
      tkEllipseShape:
        begin
          if DoFill then
            MutableSurface.DrawEllipse(
              LocalStartPoint.X, LocalStartPoint.Y, LocalEndPoint.X, LocalEndPoint.Y,
              StrokeWidth, FillColor, True, 255, PaintSelection);
          if DoOutline then
            if UseDashedOutline then
              DrawDashedEllipseOutline(LocalStartPoint, LocalEndPoint, StrokeWidth)
            else
              MutableSurface.DrawEllipse(
                LocalStartPoint.X, LocalStartPoint.Y, LocalEndPoint.X, LocalEndPoint.Y,
                StrokeWidth, ActivePaintColor, False, 255, PaintSelection
              );
        end;
      tkFreeformShape:
        begin
          SetLength(LocalLassoPoints, Length(FLassoPoints));
          for LassoIndex := 0 to High(FLassoPoints) do
            LocalLassoPoints[LassoIndex] := ActiveLayerLocalPoint(FLassoPoints[LassoIndex]);
          if DoFill then
            MutableSurface.FillPolygon(LocalLassoPoints, FillColor, 255, PaintSelection);
          if DoOutline then
            if UseDashedOutline and (Length(LocalLassoPoints) > 1) then
              MutableSurface.DrawDashedPolyline(
                LocalLassoPoints,
                StrokeWidth,
                ActivePaintColor,
                True,
                DashLength,
                GapLength,
                255,
                255,
                PaintSelection
              )
            else
              MutableSurface.DrawPolygon(
                LocalLassoPoints,
                StrokeWidth,
                ActivePaintColor,
                True,
                255,
                PaintSelection
              );
        end;
    end;
  finally
    OwnedPaintSelection.Free;
  end;
end;

procedure TMainForm.ResetDocument(AWidth, AHeight: Integer);
begin
  SealPendingStrokeHistory;
  CommitInlineTextEdit(True);
  FDocument.NewBlank(AWidth, AHeight);
  FCurrentFileName := '';
  ResetTransientCanvasState;
  SyncDocumentReplacementUI(False);
end;

procedure TMainForm.NewDocumentClick(Sender: TObject);
var
  TargetWidth: Integer;
  TargetHeight: Integer;
  NewDoc: TImageDocument;
  ClipPic: TPicture;
begin
  { Determine default dimensions: prefer clipboard image size, then DPI-scaled default }
  TargetWidth := 1024 * FScreenBackingScale;
  TargetHeight := 768 * FScreenBackingScale;
  if Clipboard.HasPictureFormat then
  begin
    ClipPic := TPicture.Create;
    try
      try
        Clipboard.AssignTo(ClipPic);
        if Assigned(ClipPic.Graphic) and (not ClipPic.Graphic.Empty) and
           (ClipPic.Width > 0) and (ClipPic.Height > 0) then
        begin
          TargetWidth := ClipPic.Width;
          TargetHeight := ClipPic.Height;
        end;
      except
        { Ignore clipboard read errors; keep the fixed default }
      end;
    finally
      ClipPic.Free;
    end;
  end;
  if not RunNewImageDialog(Self, TargetWidth, TargetHeight, FNewImageResolutionDPI) then
    Exit;
  CommitInlineTextEdit(True);
  NewDoc := TImageDocument.Create(TargetWidth, TargetHeight);
  AddDocumentTab(NewDoc, '', False);
  ResetTransientCanvasState;
  SyncDocumentReplacementUI(False);
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
      TR('Open Recent', '打开最近文件'),
      Format(TR('The file "%s" is no longer available.', '文件“%s”已不可用。'), [FileName]),
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
    Choice := MessageDlg(TR('Save Changes', '保存更改'),
      Format(TR('Do you want to save changes to "%s"?', '是否保存对“%s”的更改？'), [TabDocumentDisplayName(FActiveTabIndex)]),
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
      'FlatPaint Project|*.fpd|PNG|*.png|JPEG|*.jpg;*.jpeg|Bitmap|*.bmp|TIFF|*.tif;*.tiff|' +
      'PCX|*.pcx|PNM/PBM/PGM/PPM|*.pnm;*.pbm;*.pgm;*.ppm|TGA|*.tga|XPM|*.xpm';
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
var
  I: Integer;
  OriginalTabIndex: Integer;
  TabCount: Integer;
begin
  TabCount := Length(FTabDocuments);
  if TabCount = 0 then
    Exit;

  OriginalTabIndex := FActiveTabIndex;
  if Length(FTabFileNames) > FActiveTabIndex then
    FTabFileNames[FActiveTabIndex] := FCurrentFileName;
  if Length(FTabDirtyFlags) > FActiveTabIndex then
    FTabDirtyFlags[FActiveTabIndex] := FDirty;

  try
    for I := 0 to TabCount - 1 do
    begin
      if I <> FActiveTabIndex then
        SwitchToTab(I);

      if not FDirty then
        Continue;

      if SaveAllFallsBackToSaveAs(FCurrentFileName) then
      begin
        SaveAsDocumentClick(Sender);
        if FDirty then
          Break;
      end
      else
      begin
        SaveToPath(FCurrentFileName);
        if FDirty then
          Break;
      end;
    end;
  finally
    if (OriginalTabIndex >= 0) and
       (OriginalTabIndex < Length(FTabDocuments)) and
       (OriginalTabIndex <> FActiveTabIndex) then
      SwitchToTab(OriginalTabIndex);
  end;
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
      MessageDlg(TR('Print', '打印'), TR('Printing failed: ', '打印失败：') + E.Message, mtError, [mbOK], 0);
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
        if not ConfirmDocumentReplacement(TR('replace the current document from the clipboard', '使用剪贴板内容替换当前文档')) then
          Exit;
        SealPendingStrokeHistory;
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
              FDocument.ReplaceWithSingleLayer(ImportedSurface, TR('Acquired Image', '获取的图像'));
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
        ResetTransientCanvasState;
        SyncDocumentReplacementUI(True);
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
        FDocument.PushHistory(LocalizedAction('Import Layer'));
        FDocument.PasteAsNewLayer(Surface, 0, 0, ExtractFileName(Dialog.FileName));
        SyncImageMutationUI(True, True);
      finally
        Surface.Free;
      end;
    except
      on E: Exception do
        MessageDlg(TR('Import as Layer', '导入为图层'), TR('Import failed: ', '导入失败：') + E.Message, mtError, [mbOK], 0);
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.UndoClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.Undo;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.RedoClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.Redo;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.CutClick(Sender: TObject);
var
  Bounds: TRect;
begin
  SealPendingStrokeHistory;
  if not FDocument.BeginActiveLayerMutation(LocalizedAction('Cut')) then
    Exit;
  FreeAndNil(FClipboardSurface);
  if FDocument.HasSelection then
  begin
    Bounds := FDocument.Selection.BoundsRect;
    FClipboardOffset := Point(Bounds.Left, Bounds.Top);
    FClipboardSurface := FDocument.CutSelectionToSurface(True, BackgroundToolColor);
  end
  else
  begin
    FClipboardOffset := Point(0, 0);
    FClipboardSurface := FDocument.CutSelectionToSurface(False, BackgroundToolColor);
  end;
  PublishSurfaceToSystemClipboard(FClipboardSurface, FClipboardOffset);
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.CopyClick(Sender: TObject);
var
  Bounds: TRect;
begin
  SealPendingStrokeHistory;
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
  PublishSurfaceToSystemClipboard(FClipboardSurface, FClipboardOffset);
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
  PublishSurfaceToSystemClipboard(FClipboardSurface, FClipboardOffset);
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.PasteClick(Sender: TObject);
var
  PasteSurface: TRasterSurface;
  PasteOffset: TPoint;
begin
  SealPendingStrokeHistory;
  if not TryResolvePasteSurface(PasteSurface, PasteOffset) then
    Exit;
  if not FDocument.BeginActiveLayerMutation(LocalizedAction('Paste')) then
    Exit;
  { Paste onto the active layer through core guarded mutation route. }
  FDocument.PasteSurfaceToActiveLayer(
    PasteSurface,
    PasteOffset.X - FDocument.ActiveLayer.OffsetX,
    PasteOffset.Y - FDocument.ActiveLayer.OffsetY
  );
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.PasteIntoNewLayerClick(Sender: TObject);
var
  PasteSurface: TRasterSurface;
  PasteOffset: TPoint;
begin
  SealPendingStrokeHistory;
  if not TryResolvePasteSurface(PasteSurface, PasteOffset) then
    Exit;
  FDocument.PushHistory(LocalizedAction('Paste into New Layer'));
  FDocument.PasteAsNewLayer(
    PasteSurface,
    PasteOffset.X,
    PasteOffset.Y,
    TR('Pasted Layer', '粘贴图层')
  );
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.PasteIntoNewImageClick(Sender: TObject);
var
  PasteSurface: TRasterSurface;
begin
  if not TryResolvePasteSurface(PasteSurface, FClipboardOffset) then
    Exit;
  SealPendingStrokeHistory;
  FDocument.ReplaceWithSingleLayer(PasteSurface, TR('Pasted Layer', '粘贴图层'));
  FCurrentFileName := '';
  ResetTransientCanvasState;
  SyncDocumentReplacementUI(True);
end;

procedure TMainForm.AddLayerClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Add Layer'));
  FDocument.AddLayer;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.DuplicateLayerClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Duplicate Layer'));
  FDocument.DuplicateActiveLayer;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.DeleteLayerClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Delete Layer'));
  FDocument.DeleteActiveLayer;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.RenameLayerClick(Sender: TObject);
var
  ValueText: string;
begin
  SealPendingStrokeHistory;
  ValueText := FDocument.ActiveLayer.Name;
  if not InputQuery(TR('Rename Layer', '重命名图层'), TR('Layer name', '图层名称'), ValueText) then
    Exit;
  if Trim(ValueText) = '' then
    Exit;
  FDocument.PushHistory(LocalizedAction('Rename Layer'));
  FDocument.RenameLayer(FDocument.ActiveLayerIndex, ValueText);
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.MoveLayerUpClick(Sender: TObject);
var
  TargetIndex: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount <= 1 then
    Exit;
  if FDocument.ActiveLayer.IsBackground then
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
    FDocument.PushHistory(LocalizedAction('Move Layer to Top'))
  else
    FDocument.PushHistory(LocalizedAction('Move Layer Up'));
  FDocument.MoveLayer(FDocument.ActiveLayerIndex, TargetIndex);
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.MoveLayerDownClick(Sender: TObject);
var
  TargetIndex: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount <= 1 then
    Exit;
  if FDocument.ActiveLayer.IsBackground then
    Exit;
  if ssCtrl in GetKeyShiftState then
    TargetIndex := 0
  else
    TargetIndex := FDocument.ActiveLayerIndex - 1;
  if TargetIndex < 0 then
    TargetIndex := 0;
  if (TargetIndex = 0) and (FDocument.LayerCount > 0) and FDocument.Layers[0].IsBackground then
    TargetIndex := 1;
  if TargetIndex = FDocument.ActiveLayerIndex then
    Exit;
  if TargetIndex = 0 then
    FDocument.PushHistory(LocalizedAction('Move Layer to Bottom'))
  else
    FDocument.PushHistory(LocalizedAction('Move Layer Down'));
  FDocument.MoveLayer(FDocument.ActiveLayerIndex, TargetIndex);
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.MergeDownClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.ActiveLayerIndex = 0 then
    Exit;
  FDocument.PushHistory(LocalizedAction('Merge Down'));
  FDocument.MergeDown;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.FlattenClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Flatten'));
  FDocument.Flatten;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.ToggleLayerVisibilityClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Toggle Layer Visibility'));
  FDocument.SetLayerVisibility(
    FDocument.ActiveLayerIndex,
    not FDocument.Layers[FDocument.ActiveLayerIndex].Visible
  );
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.ToggleLayerLockClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  FDocument.ActiveLayer.Locked := not FDocument.ActiveLayer.Locked;
  if Assigned(FLayerList) then
    FLayerList.Invalidate;
end;

procedure TMainForm.LayerOpacityClick(Sender: TObject);
var
  ValueText: string;
begin
  SealPendingStrokeHistory;
  ValueText := IntToStr(LayerOpacityPercentFromByte(FDocument.ActiveLayer.Opacity));
  if not InputQuery(TR('Layer Opacity', '图层不透明度'), TR('Opacity (0 to 100%)', '不透明度（0 到 100%）'), ValueText) then
    Exit;
  FDocument.PushHistory(LocalizedAction('Layer Opacity'));
  FDocument.SetLayerOpacity(
    FDocument.ActiveLayerIndex,
    LayerOpacityByteFromPercent(
      StrToIntDef(ValueText, LayerOpacityPercentFromByte(FDocument.ActiveLayer.Opacity))
    )
  );
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.LayerVisibleCheckChanged(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FUpdatingLayerControls then
    Exit;
  if FDocument.LayerCount = 0 then
    Exit;
end;

procedure TMainForm.LayerOpacitySpinChanged(Sender: TObject);
var
  NewOpacity: Byte;
begin
  SealPendingStrokeHistory;
  if FUpdatingLayerControls then
    Exit;
  if not Assigned(FDocument) then
    Exit;
  if not Assigned(FLayerOpacitySpin) or (FDocument.LayerCount = 0) then
    Exit;
  NewOpacity := LayerOpacityByteFromPercent(FLayerOpacitySpin.Value);
  if FDocument.ActiveLayer.Opacity = NewOpacity then
    Exit;
  FDocument.PushHistory(LocalizedAction('Layer Opacity'));
  FDocument.SetLayerOpacity(FDocument.ActiveLayerIndex, NewOpacity);
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.ResizeImageClick(Sender: TObject);
var
  TargetWidth: Integer;
  TargetHeight: Integer;
  ResampleMode: TResampleMode;
begin
  SealPendingStrokeHistory;
  TargetWidth := FDocument.Width;
  TargetHeight := FDocument.Height;
  ResampleMode := rmNearestNeighbor;
  if not RunResizeImageDialog(Self, TargetWidth, TargetHeight, ResampleMode) then
    Exit;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Resize Image')) then
    Exit;
  FDocument.ResizeImage(TargetWidth, TargetHeight, ResampleMode);
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.ResizeCanvasClick(Sender: TObject);
var
  TargetWidth: Integer;
  TargetHeight: Integer;
begin
  SealPendingStrokeHistory;
  TargetWidth := FDocument.Width;
  TargetHeight := FDocument.Height;
  if not RunResizeCanvasDialog(Self, TargetWidth, TargetHeight) then
    Exit;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Resize Canvas')) then
    Exit;
  FDocument.ResizeCanvas(TargetWidth, TargetHeight);
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.RotateClockwiseClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Rotate 90 Right')) then
    Exit;
  FDocument.Rotate90Clockwise;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.RotateCounterClockwiseClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Rotate 90 Left')) then
    Exit;
  FDocument.Rotate90CounterClockwise;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.Rotate180Click(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Rotate 180')) then
    Exit;
  FDocument.Rotate180;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.FlipHorizontalClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Flip Horizontal')) then
    Exit;
  FDocument.FlipHorizontal;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.FlipVerticalClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Flip Vertical')) then
    Exit;
  FDocument.FlipVertical;
  SyncImageMutationUI(False, True);
end;

procedure TMainForm.AutoLevelClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  BeginStatusProgress(ApplyingActionText('Auto-Level'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Auto-Level')) then
      Exit;
    FDocument.AutoLevel;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.InvertColorsClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  BeginStatusProgress(ApplyingActionText('Invert Colors'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Invert Colors')) then
      Exit;
    FDocument.InvertColors;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.GrayscaleClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  BeginStatusProgress(ApplyingActionText('Grayscale'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Grayscale')) then
      Exit;
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
  SealPendingStrokeHistory;
  GammaValue := 1.0;
  if not RunCurvesDialog(Self, GammaValue) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Curves'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Curves')) then
      Exit;
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
  SealPendingStrokeHistory;
  HueDelta := 0;
  SaturationDelta := 0;
  if not RunHueSaturationDialog(Self, HueDelta, SaturationDelta) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Hue / Saturation'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Hue / Saturation')) then
      Exit;
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
  SealPendingStrokeHistory;
  InputLow := 0;
  InputHigh := 255;
  OutputLow := 0;
  OutputHigh := 255;
  if not RunLevelsDialog(Self, InputLow, InputHigh, OutputLow, OutputHigh) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Levels'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Levels')) then
      Exit;
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
  SealPendingStrokeHistory;
  Brightness := 0;
  Contrast := 0;
  if not RunBrightnessContrastDialog(Self, Brightness, Contrast) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Brightness / Contrast'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Brightness / Contrast')) then
      Exit;
    FDocument.AdjustBrightness(Brightness);
    FDocument.AdjustContrast(Contrast);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.SepiaClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  BeginStatusProgress(ApplyingActionText('Sepia'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Sepia')) then
      Exit;
    FDocument.Sepia;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.BlackAndWhiteClick(Sender: TObject);
var
  Val: Integer;
begin
  SealPendingStrokeHistory;
  Val := 127;
  if not RunEffectDialog1(Self,
    TR('Black and White', #$E9#$BB#$91#$E7#$99#$BD),
    TR('Threshold', #$E9#$98#$88#$E5#$80#$BC),
    0, 255, 127, Val) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Black and White'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Black and White')) then
      Exit;
    FDocument.BlackAndWhite(Val);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
end;

procedure TMainForm.PosterizeClick(Sender: TObject);
var
  Levels: Integer;
begin
  SealPendingStrokeHistory;
  Levels := 6;
  if not RunPosterizeDialog(Self, Levels) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Posterize'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Posterize')) then
      Exit;
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
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  Radius := 2;
  if not RunBlurDialog(Self, Radius) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Blur'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Blur')) then
      Exit;
    FDocument.BoxBlur(Radius);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Blur', #$E6#$A8#$A1#$E7#$B3#$8A);
  FLastEffectProc := @BlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.SharpenClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  BeginStatusProgress(ApplyingActionText('Sharpen'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Sharpen')) then
      Exit;
    FDocument.Sharpen;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Sharpen', #$E9#$94#$90#$E5#$8C#$96);
  FLastEffectProc := @SharpenClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.AddNoiseClick(Sender: TObject);
var
  Amount: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  Amount := 24;
  if not RunNoiseDialog(Self, Amount) then
    Exit;
  BeginStatusProgress(ApplyingActionText('Add Noise'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Add Noise')) then
      Exit;
    FDocument.AddNoise(Amount);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Add Noise', #$E6#$B7#$BB#$E5#$8A#$A0#$E5#$99#$AA#$E7#$82#$B9);
  FLastEffectProc := @AddNoiseClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.OutlineClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  BeginStatusProgress(ApplyingActionText('Detect Edges'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Detect Edges')) then
      Exit;
    FDocument.DetectEdges;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Detect Edges', #$E8#$BE#$B9#$E7#$BC#$98#$E6#$A3#$80#$E6#$B5#$8B);
  FLastEffectProc := @OutlineClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.OutlineEffectClick(Sender: TObject);
var
  ThresholdVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  ThresholdVal := 10;
  if not RunEffectDialog1(Self,
    TR('Outline Effect', #$E8#$BD#$AE#$E5#$BB#$93#$E6#$95#$88#$E6#$9E#$9C),
    TR('Alpha Threshold', 'Alpha '#$E9#$98#$88#$E5#$80#$BC),
    0, 255, 10, ThresholdVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Outline Effect'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Outline Effect')) then
      Exit;
    FDocument.OutlineEffect(FPrimaryColor, ThresholdVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Outline Effect', #$E8#$BD#$AE#$E5#$BB#$93#$E6#$95#$88#$E6#$9E#$9C);
  FLastEffectProc := @OutlineEffectClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.DeselectClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.HasSelection then
    Exit;
  FDocument.PushHistory(LocalizedAction('Deselect'));
  FDocument.Deselect;
  SyncSelectionOverlayUI(True);
end;

procedure TMainForm.SelectAllClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Select All'));
  FDocument.SelectAll;
  SyncSelectionOverlayUI(True);
end;

procedure TMainForm.InvertSelectionClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FDocument.PushHistory(LocalizedAction('Invert Selection'));
  FDocument.InvertSelection;
  SyncSelectionOverlayUI(True);
end;

procedure TMainForm.FillSelectionClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.HasSelection then
    Exit;
  if not FDocument.BeginActiveLayerMutation(LocalizedAction('Fill Selection')) then
    Exit;
  FDocument.FillSelection(FPrimaryColor);
  SyncImageMutationUI;
end;

procedure TMainForm.EraseSelectionClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.HasSelection then
    Exit;
  if not FDocument.BeginActiveLayerMutation(LocalizedAction('Erase Selection')) then
    Exit;
  FDocument.EraseSelection(BackgroundToolColor);
  SyncImageMutationUI;
end;

procedure TMainForm.CropToSelectionClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.HasSelection then
    Exit;
  if not FDocument.BeginDocumentMutation(LocalizedAction('Crop to Selection')) then
    Exit;
  FDocument.CropToSelection;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.SwapColorsClick(Sender: TObject);
var
  TempColor: TRGBA32;
begin
  SealPendingStrokeHistory;
  TempColor := FPrimaryColor;
  FPrimaryColor := FSecondaryColor;
  FSecondaryColor := TempColor;
  RefreshColorsPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.ResetColorsClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  FPrimaryColor := RGBA(0, 0, 0, 255);
  FSecondaryColor := RGBA(255, 255, 255, 255);
  RefreshColorsPanel;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.PrimaryColorClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if Assigned(FColorPickButton) then
    FColorPickButton.Click;
end;

procedure TMainForm.SecondaryColorClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
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
  FCenterOnNextCanvasUpdate := True;
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
  TargetHorizontal: Integer;
  TargetVertical: Integer;
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
  TargetHorizontal := ClampViewportScrollPosition(
    FPaintBox.Left + FCanvasPadX + Round(SelectionCenterX * FZoomScale) - (FCanvasHost.ClientWidth div 2),
    FPaintBox.Left,
    FPaintBox.Width,
    FCanvasHost.ClientWidth
  );
  TargetVertical := ClampViewportScrollPosition(
    FPaintBox.Top + FCanvasPadY + Round(SelectionCenterY * FZoomScale) - (FCanvasHost.ClientHeight div 2),
    FPaintBox.Top,
    FPaintBox.Height,
    FCanvasHost.ClientHeight
  );
  if TargetHorizontal <> FCanvasHost.HorzScrollBar.Position then
    FCanvasHost.HorzScrollBar.Position := TargetHorizontal;
  if TargetVertical <> FCanvasHost.VertScrollBar.Position then
    FCanvasHost.VertScrollBar.Position := TargetVertical;
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
  ClampPaletteToWorkspace(FToolsPanel);
  ClampPaletteToWorkspace(FColorsPanel);
  ClampPaletteToWorkspace(FHistoryPanel);
  ClampPaletteToWorkspace(FRightPanel);
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
  SealPendingStrokeHistory;
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
  ChosenLanguage: TAppLanguage;
  LanguageChanged: Boolean;
begin
  SealPendingStrokeHistory;
  DisplayUnitIndex := Ord(FDisplayUnit);
  ChosenLanguage := AppLanguage;
  if not RunSettingsDialog(Self, FNewImageResolutionDPI, DisplayUnitIndex, ChosenLanguage) then
    Exit;
  FDisplayUnit := TDisplayUnit(DisplayUnitIndex);
  LanguageChanged := (ChosenLanguage <> AppLanguage);
  if LanguageChanged then
  begin
    AppLanguage := ChosenLanguage;
    SaveLanguagePreference;
  end;
  RefreshUnitsMenu;
  if LanguageChanged then
    RefreshLocalizedUI;
end;

procedure TMainForm.AboutClick(Sender: TObject);
begin
  ShowAboutDialog(Self);
end;

procedure TMainForm.RefreshLocalizedUI;
var
  OldMenu: TMainMenu;
  ToolIndex: Integer;
  ToolKind: TToolKind;
  UtilityCommand: TUtilityCommandKind;
  PaletteKind: TPaletteKind;
  TitleLabel: TLabel;
  PalettePanel: TPanel;
  HeaderPanel: TPanel;
  ChildIndex: Integer;
  GrandChildIndex: Integer;
  LayerBlendIndex: Integer;
  RecolorModeIndex: Integer;
  OptionUpdating: Boolean;
  LayerUpdating: Boolean;
  Button: TSpeedButton;
  HostControl: TWinControl;
  OverlayImage: TImage;
  function SameNotify(const ALeft, ARight: TNotifyEvent): Boolean;
  begin
    Result := (TMethod(ALeft).Code = TMethod(ARight).Code) and
      (TMethod(ALeft).Data = TMethod(ARight).Data);
  end;
  procedure UpdateButtonHint(AButton: TSpeedButton; const AHint: string);
  begin
    if not Assigned(AButton) then
      Exit;
    AButton.Hint := AHint;
    OverlayImage := FindButtonIconOverlay(AButton);
    if Assigned(OverlayImage) then
    begin
      OverlayImage.Hint := AHint;
      OverlayImage.ShowHint := AButton.ShowHint;
    end;
  end;
  procedure ResetComboItems(ACombo: TComboBox; const AItems: array of string;
    AItemIndex: Integer = -1);
  var
    I: Integer;
    TargetIndex: Integer;
  begin
    if not Assigned(ACombo) then
      Exit;
    TargetIndex := AItemIndex;
    if TargetIndex < 0 then
      TargetIndex := ACombo.ItemIndex;
    ACombo.Items.BeginUpdate;
    try
      ACombo.Items.Clear;
      for I := 0 to High(AItems) do
        ACombo.Items.Add(AItems[I]);
      if ACombo.Items.Count = 0 then
        ACombo.ItemIndex := -1
      else
        ACombo.ItemIndex := EnsureRange(TargetIndex, 0, ACombo.Items.Count - 1);
    finally
      ACombo.Items.EndUpdate;
    end;
  end;
begin
  { 1. Rebuild the main menu bar }
  OldMenu := FMainMenu;
  BuildMenus;
  if Assigned(OldMenu) then
    OldMenu.Free;

  { 2. Rebuild tab context menu + attach to rebuilt cards }
  BuildTabPopupMenu;
  RefreshTabStrip;

  { 3. Refresh tool combo items (preserve tool objects) }
  if Assigned(FToolCombo) then
  begin
    FToolCombo.Items.BeginUpdate;
    try
      FToolCombo.Items.Clear;
      for ToolIndex := 0 to PaintToolDisplayCount - 1 do
      begin
        ToolKind := PaintToolAtDisplayIndex(ToolIndex);
        if ToolKind = tkZoom then
          Continue;
        FToolCombo.Items.AddObject(
          PaintToolDisplayLabel(ToolKind),
          TObject(PtrInt(Ord(ToolKind)))
        );
      end;
    finally
      FToolCombo.Items.EndUpdate;
    end;
    SyncToolComboSelection;
  end;

  { 4. Refresh top/side button hints that were set only at construction time }
  if Assigned(FTopPanel) then
    for ChildIndex := 0 to FTopPanel.ControlCount - 1 do
      if FTopPanel.Controls[ChildIndex] is TWinControl then
      begin
        HostControl := TWinControl(FTopPanel.Controls[ChildIndex]);
        for GrandChildIndex := 0 to HostControl.ControlCount - 1 do
          if HostControl.Controls[GrandChildIndex] is TSpeedButton then
          begin
            Button := TSpeedButton(HostControl.Controls[GrandChildIndex]);
            if SameNotify(Button.OnClick, @NewDocumentClick) then
              UpdateButtonHint(Button, TR('New document (Cmd+N)', #$E6#$96#$B0#$E5#$BB#$BA#$E6#$96#$87#$E6#$A1#$A3 + ' (Cmd+N)'))
            else if SameNotify(Button.OnClick, @OpenDocumentClick) then
              UpdateButtonHint(Button, TR('Open document (Cmd+O)', #$E6#$89#$93#$E5#$BC#$80#$E6#$96#$87#$E6#$A1#$A3 + ' (Cmd+O)'))
            else if SameNotify(Button.OnClick, @SaveDocumentClick) then
              UpdateButtonHint(Button, TR('Save document (Cmd+S)', #$E4#$BF#$9D#$E5#$AD#$98#$E6#$96#$87#$E6#$A1#$A3 + ' (Cmd+S)'))
            else if SameNotify(Button.OnClick, @CutClick) then
              UpdateButtonHint(Button, TR('Cut selection (Cmd+X)', #$E5#$89#$AA#$E5#$88#$87#$E9#$80#$89#$E5#$8C#$BA + ' (Cmd+X)'))
            else if SameNotify(Button.OnClick, @CopyClick) then
              UpdateButtonHint(Button, TR('Copy selection (Cmd+C)', #$E5#$A4#$8D#$E5#$88#$B6#$E9#$80#$89#$E5#$8C#$BA + ' (Cmd+C)'))
            else if SameNotify(Button.OnClick, @PasteClick) then
              UpdateButtonHint(Button, TR('Paste (Cmd+V)', #$E7#$B2#$98#$E8#$B4#$B4 + ' (Cmd+V)'))
            else if SameNotify(Button.OnClick, @UndoClick) then
              UpdateButtonHint(Button, TR('Undo last action (Cmd+Z)', #$E6#$92#$A4#$E9#$94#$80 + ' (Cmd+Z)'))
            else if SameNotify(Button.OnClick, @RedoClick) then
              UpdateButtonHint(Button, TR('Redo (Cmd+Shift+Z)', #$E9#$87#$8D#$E5#$81#$9A + ' (Cmd+Shift+Z)'))
            else if SameNotify(Button.OnClick, @ZoomOutClick) then
              UpdateButtonHint(Button, TR('Zoom out (Cmd+-)', #$E7#$BC#$A9#$E5#$B0#$8F + ' (Cmd+-)'))
            else if SameNotify(Button.OnClick, @ZoomInClick) then
              UpdateButtonHint(Button, TR('Zoom in (Cmd+=)', #$E6#$94#$BE#$E5#$A4#$A7 + ' (Cmd+=)'))
            else if SameNotify(Button.OnClick, @UtilityButtonClick) and
              (Button.Tag >= Ord(Low(TUtilityCommandKind))) and
              (Button.Tag <= Ord(High(TUtilityCommandKind))) then
              UpdateButtonHint(
                Button,
                UtilityCommandHint(TUtilityCommandKind(Button.Tag)) + ' (' +
                  UtilityCommandShortcutLabel(TUtilityCommandKind(Button.Tag)) + ')'
              );
          end;
      end;
  if Assigned(FHistoryPanel) then
    for ChildIndex := 0 to FHistoryPanel.ControlCount - 1 do
      if FHistoryPanel.Controls[ChildIndex] is TSpeedButton then
      begin
        Button := TSpeedButton(FHistoryPanel.Controls[ChildIndex]);
        if SameNotify(Button.OnClick, @UndoClick) then
          UpdateButtonHint(Button, TR('Undo last action (Cmd+Z)', #$E6#$92#$A4#$E9#$94#$80 + ' (Cmd+Z)'))
        else if SameNotify(Button.OnClick, @RedoClick) then
          UpdateButtonHint(Button, TR('Redo (Cmd+Shift+Z)', #$E9#$87#$8D#$E5#$81#$9A + ' (Cmd+Shift+Z)'));
      end;
  if Assigned(FColorsPanel) then
    for ChildIndex := 0 to FColorsPanel.ControlCount - 1 do
      if FColorsPanel.Controls[ChildIndex] is TSpeedButton then
      begin
        Button := TSpeedButton(FColorsPanel.Controls[ChildIndex]);
        if SameNotify(Button.OnClick, @SwapColorsClick) then
          UpdateButtonHint(Button, TR('Swap primary and secondary colors (X)', '交换前景色和背景色 (X)'))
        else if SameNotify(Button.OnClick, @ResetColorsClick) then
          UpdateButtonHint(Button, TR('Reset colors to black and white (D)', '重置为黑白默认颜色 (D)'));
      end;
  if Assigned(FRightPanel) then
    for ChildIndex := 0 to FRightPanel.ControlCount - 1 do
      if FRightPanel.Controls[ChildIndex] is TSpeedButton then
      begin
        Button := TSpeedButton(FRightPanel.Controls[ChildIndex]);
        if SameNotify(Button.OnClick, @AddLayerClick) then
          UpdateButtonHint(Button, TR('Add new layer', '添加新图层'))
        else if SameNotify(Button.OnClick, @DuplicateLayerClick) then
          UpdateButtonHint(Button, TR('Duplicate layer', '复制图层'))
        else if SameNotify(Button.OnClick, @DeleteLayerClick) then
          UpdateButtonHint(Button, TR('Delete layer', '删除图层'))
        else if SameNotify(Button.OnClick, @MergeDownClick) then
          UpdateButtonHint(Button, TR('Merge down', '向下合并'))
        else if SameNotify(Button.OnClick, @MoveLayerDownClick) then
          UpdateButtonHint(Button, TR('Move layer up in list', '图层上移'))
        else if SameNotify(Button.OnClick, @MoveLayerUpClick) then
          UpdateButtonHint(Button, TR('Move layer down in list', '图层下移'))
        else if SameNotify(Button.OnClick, @FlattenClick) then
          UpdateButtonHint(Button, TR('Flatten image', '合并图像'))
        else if SameNotify(Button.OnClick, @RenameLayerClick) then
          UpdateButtonHint(Button, TR('Rename layer', '重命名图层'))
        else if SameNotify(Button.OnClick, @LayerPropertiesClick) then
          UpdateButtonHint(Button, TR('Layer properties', '图层属性'));
      end;
  for UtilityCommand := Low(TUtilityCommandKind) to High(TUtilityCommandKind) do
    if Assigned(FUtilityButtons[UtilityCommand]) then
      UpdateButtonHint(
        FUtilityButtons[UtilityCommand],
        UtilityCommandHint(UtilityCommand) + ' (' + UtilityCommandShortcutLabel(UtilityCommand) + ')'
      );
  for ToolKind := Low(TToolKind) to High(TToolKind) do
    if Assigned(FToolButtons[ToolKind]) then
      UpdateButtonHint(FToolButtons[ToolKind], PaintToolDisplayLabel(ToolKind) + ' — ' + PaintToolHint(ToolKind));

  { 5. Refresh tool/options and palette controls that were created once }
  OptionUpdating := FUpdatingToolOption;
  FUpdatingToolOption := True;
  try
    if Assigned(FOptionLabel) then
      FOptionLabel.Caption := TR('Size:', '大小：');
    if Assigned(FTextAlignLabel) then
      FTextAlignLabel.Caption := TR('Align:', '对齐：');
    ResetComboItems(FTextAlignCombo,
      [TR('Left', '左对齐'), TR('Center', '居中'), TR('Right', '右对齐')],
      EnsureRange(FTextLastResult.Alignment, 0, 2));
    if Assigned(FTextAlignCombo) then
      FTextAlignCombo.Hint := TR('Text alignment', '文本对齐方式');
    if Assigned(FTextFontButton) then
      FTextFontButton.Hint := TR('Choose font and style', '选择字体和样式');
    if Assigned(FOpacityLabel) then
      FOpacityLabel.Caption := TR('Opacity:', '不透明度：');
    if Assigned(FOpacitySpin) then
      FOpacitySpin.Hint := TR('Brush opacity (1-100)', '画笔不透明度 (1-100)');
    if Assigned(FHardnessLabel) then
      FHardnessLabel.Caption := TR('Hardness:', '硬度：');
    if Assigned(FHardnessSpin) then
      FHardnessSpin.Hint := TR('Brush hardness (1=soft, 100=hard)', '画笔硬度 (1=柔和, 100=硬边)');
    if Assigned(FEraserShapeLabel) then
      FEraserShapeLabel.Caption := TR('Shape:', '形状：');
    ResetComboItems(FEraserShapeCombo, [TR('Round', '圆形'), TR('Square', '方形')],
      Ord(FEraserSquareShape));
    if Assigned(FEraserShapeCombo) then
      FEraserShapeCombo.Hint := TR('Eraser tip shape', '橡皮擦笔头形状');
    if Assigned(FSelModeLabel) then
      FSelModeLabel.Caption := TR('Mode:', '模式：');
    ResetComboItems(
      FSelModeCombo,
      [TR('Replace', '替换'), TR('Add', '添加'), TR('Subtract', '减去'), TR('Intersect', '相交')],
      Ord(FPendingSelectionMode)
    );
    if Assigned(FSelModeCombo) then
      FSelModeCombo.Hint := TR('Selection combination mode', '选区组合模式');
    if Assigned(FShapeStyleLabel) then
      FShapeStyleLabel.Caption := TR('Draw:', '绘制：');
    ResetComboItems(FShapeStyleCombo,
      [TR('Outline', '描边'), TR('Fill', '填充'), TR('Outline + Fill', '描边 + 填充')],
      FShapeStyle);
    if Assigned(FShapeStyleCombo) then
      FShapeStyleCombo.Hint := TR('Shape draw style', '形状绘制样式');
    if Assigned(FShapeLineStyleLabel) then
      FShapeLineStyleLabel.Caption := TR('Line:', '线条：');
    ResetComboItems(FShapeLineStyleCombo,
      [TR('Solid', '实线'), TR('Dashed', '虚线')],
      FShapeLineStyle);
    if Assigned(FShapeLineStyleCombo) then
      FShapeLineStyleCombo.Hint := TR('Outline line style for line/shape tools', '线条/形状工具的描边样式');
    if Assigned(FLineBezierCheck) then
    begin
      FLineBezierCheck.Caption := TR('Bezier', '贝塞尔');
      FLineBezierCheck.Hint := TR('Enable staged Bezier editing for the Line tool', '为直线工具启用分阶段贝塞尔编辑');
    end;
    if Assigned(FBucketModeLabel) then
      FBucketModeLabel.Caption := TR('Fill:', '填充：');
    ResetComboItems(FBucketModeCombo,
      [TR('Contiguous', '连续'), TR('Global', '全局')],
      FBucketFloodMode);
    if Assigned(FBucketModeCombo) then
      FBucketModeCombo.Hint := TR('Fill mode', '填充模式');
    if Assigned(FFillSampleLabel) then
      FFillSampleLabel.Caption := TR('Sample:', '采样：');
    ResetComboItems(FFillSampleCombo,
      [TR('Current Layer', '当前图层'), TR('All Layers', '所有图层')],
      FFillSampleSource);
    if Assigned(FFillSampleCombo) then
      FFillSampleCombo.Hint := TR('Fill sample source', '填充采样来源');
    if Assigned(FWandSampleLabel) then
      FWandSampleLabel.Caption := TR('Sample:', '采样：');
    ResetComboItems(FWandSampleCombo,
      [TR('Current Layer', '当前图层'), TR('All Layers', '所有图层')],
      FWandSampleSource);
    if Assigned(FWandSampleCombo) then
      FWandSampleCombo.Hint := TR('Wand sample source', '魔棒采样来源');
    if Assigned(FWandContiguousCheck) then
    begin
      FWandContiguousCheck.Caption := TR('Contiguous', '连续');
      FWandContiguousCheck.Hint := TR('Contiguous: select only connected pixels', '连续：只选择相连像素');
    end;
    if Assigned(FFillTolLabel) then
      FFillTolLabel.Caption := TR('Tolerance:', '容差：');
    if Assigned(FGradientTypeLabel) then
      FGradientTypeLabel.Caption := TR('Type:', '类型：');
    ResetComboItems(FGradientTypeCombo,
      [TR('Linear', '线性'), TR('Radial', '径向'), TR('Conical', '圆锥'), TR('Diamond', '菱形')],
      EnsureRange(FGradientType, 0, 3));
    if Assigned(FGradientTypeCombo) then
      FGradientTypeCombo.Hint := TR('Gradient type', '渐变类型');
    if Assigned(FGradientRepeatLabel) then
      FGradientRepeatLabel.Caption := TR('Repeat:', '重复：');
    ResetComboItems(FGradientRepeatCombo,
      [TR('None', '无'), TR('Sawtooth', '锯齿'), TR('Triangular', '三角波')],
      EnsureRange(FGradientRepeatMode, 0, 2));
    if Assigned(FGradientRepeatCombo) then
      FGradientRepeatCombo.Hint := TR('Gradient repeat mode', '渐变重复模式');
    if Assigned(FGradientReverseCheck) then
    begin
      FGradientReverseCheck.Caption := TR('Reverse', '反向');
      FGradientReverseCheck.Hint := TR('Reverse gradient direction', '反转渐变方向');
    end;
    if Assigned(FCloneAlignedCheck) then
    begin
      FCloneAlignedCheck.Caption := TR('Aligned', '对齐');
      FCloneAlignedCheck.Hint := TR('Keep the clone source aligned across multiple strokes', '在多次笔划中保持仿制源对齐');
    end;
    if Assigned(FCloneSampleLabel) then
      FCloneSampleLabel.Caption := TR('Sample:', '采样：');
    ResetComboItems(FCloneSampleCombo,
      [TR('Current Layer', '当前图层'), TR('Image', '图像合成')],
      EnsureRange(FCloneSampleSource, 0, 1));
    if Assigned(FCloneSampleCombo) then
      FCloneSampleCombo.Hint := TR('Clone sample source', '仿制采样来源');
    if Assigned(FRecolorPreserveValueCheck) then
    begin
      FRecolorPreserveValueCheck.Caption := TR('Preserve Value', '保持明度');
      FRecolorPreserveValueCheck.Hint := TR('Keep original brightness while shifting the color', '改变颜色时保持原始亮度');
    end;
    if Assigned(FRecolorContiguousCheck) then
    begin
      FRecolorContiguousCheck.Caption := TR('Contiguous', '连续');
      FRecolorContiguousCheck.Hint := TR('Only recolor connected pixels in the sampled family', '仅重着色采样族中连通的像素');
    end;
    if Assigned(FRecolorSamplingLabel) then
      FRecolorSamplingLabel.Caption := TR('Sampling:', '采样：');
    ResetComboItems(
      FRecolorSamplingCombo,
      [TR('Once', '一次'), TR('Continuous', '连续'), TR('Swatch (Compat)', '色板（兼容）')],
      Ord(FRecolorSamplingMode)
    );
    if Assigned(FRecolorSamplingCombo) then
      FRecolorSamplingCombo.Hint := TR('Source sampling behavior for recolor strokes', '重着色笔划的源采样方式');
    if Assigned(FRecolorModeLabel) then
      FRecolorModeLabel.Caption := TR('Mode:', '模式：');
    RecolorModeIndex := 4;
    case FRecolorBlendMode of
      rbmColor: RecolorModeIndex := 0;
      rbmHue: RecolorModeIndex := 1;
      rbmSaturation: RecolorModeIndex := 2;
      rbmLuminosity: RecolorModeIndex := 3;
    end;
    ResetComboItems(
      FRecolorModeCombo,
      [
        TR('Color', '颜色'),
        TR('Hue', '色相'),
        TR('Saturation', '饱和度'),
        TR('Luminosity', '明度'),
        TR('Replace (Compat)', '替换（兼容）')
      ],
      RecolorModeIndex
    );
    if Assigned(FRecolorModeCombo) then
      FRecolorModeCombo.Hint := TR('How recolor mixes target color into matching pixels', '重着色将目标色混入匹配像素的方式');
    if Assigned(FMosaicBlockLabel) then
      FMosaicBlockLabel.Caption := TR('Block:', '块大小：');
    if Assigned(FCropAspectLabel) then
      FCropAspectLabel.Caption := TR('Aspect:', '比例：');
    ResetComboItems(
      FCropAspectCombo,
      [TR('Free', '自由'), '1:1', '4:3', '16:9', TR('Current Image', '当前图像')],
      EnsureRange(FCropAspectMode, 0, 4)
    );
    if Assigned(FCropAspectCombo) then
      FCropAspectCombo.Hint := TR('Crop aspect constraint', '裁剪宽高比例约束');
    if Assigned(FCropGuideLabel) then
      FCropGuideLabel.Caption := TR('Guide:', '参考线：');
    ResetComboItems(
      FCropGuideCombo,
      [TR('None', '无'), TR('Thirds', '三分线'), TR('Center', '中心线')],
      EnsureRange(FCropGuideMode, 0, 2)
    );
    if Assigned(FCropGuideCombo) then
      FCropGuideCombo.Hint := TR('Crop composition guide overlay', '裁剪构图辅助线');
    if Assigned(FRoundedRadiusLabel) then
      FRoundedRadiusLabel.Caption := TR('Corner:', '圆角：');
    if Assigned(FRoundedRadiusSpin) then
      FRoundedRadiusSpin.Hint := TR('Rounded rectangle corner radius (px)', '圆角矩形角半径（像素）');
    if Assigned(FPickerSampleLabel) then
      FPickerSampleLabel.Caption := TR('Sample:', '采样：');
    ResetComboItems(FPickerSampleCombo,
      [TR('Current Layer', '当前图层'), TR('All Layers', '所有图层')],
      FPickerSampleSource);
    if Assigned(FPickerSampleCombo) then
      FPickerSampleCombo.Hint := TR('Pick color from layer or composite image', '从当前图层或合成图像取色');
    if Assigned(FSelAntiAliasCheck) then
    begin
      FSelAntiAliasCheck.Caption := TR('Anti-alias', '抗锯齿');
      FSelAntiAliasCheck.Hint := TR('Smooth selection edges', '平滑选区边缘');
    end;
    if Assigned(FSelFeatherLabel) then
      FSelFeatherLabel.Caption := TR('Feather:', '羽化：');
    ResetComboItems(FColorTargetCombo,
      [TR('Primary', '前景色'), TR('Secondary', '背景色')],
      FColorEditTarget);
    if Assigned(FColorExpandButton) then
      FColorExpandButton.Caption := TR('Normal >>', #$E5#$B8#$B8#$E8#$A7#$84 + ' >>');
    if Assigned(FLayerOpacityLabel) then
      FLayerOpacityLabel.Caption := TR('Opacity:', '不透明度：');
    LayerUpdating := FUpdatingLayerControls;
    FUpdatingLayerControls := True;
    try
      LayerBlendIndex := -1;
      if Assigned(FDocument) and (FDocument.LayerCount > 0) then
        LayerBlendIndex := Ord(FDocument.ActiveLayer.BlendMode)
      else if Assigned(FLayerBlendCombo) then
        LayerBlendIndex := FLayerBlendCombo.ItemIndex;
      ResetComboItems(
        FLayerBlendCombo,
        [
          TR('Normal', '正常'),
          TR('Multiply', '正片叠底'),
          TR('Screen', '滤色'),
          TR('Overlay', '叠加'),
          TR('Darken', '变暗'),
          TR('Lighten', '变亮'),
          TR('Difference', '差值'),
          TR('Soft Light', '柔光')
        ],
        LayerBlendIndex
      );
    finally
      FUpdatingLayerControls := LayerUpdating;
    end;
  finally
    FUpdatingToolOption := OptionUpdating;
  end;

  { 6. Refresh palette panel headers }
  for PaletteKind := Low(TPaletteKind) to High(TPaletteKind) do
  begin
    PalettePanel := PaletteControl(PaletteKind);
    if not Assigned(PalettePanel) then
      Continue;
    HeaderPanel := PaletteHeaderControl(PalettePanel);
    if not Assigned(HeaderPanel) then
      Continue;
    for ChildIndex := 0 to HeaderPanel.ControlCount - 1 do
    begin
      if HeaderPanel.Controls[ChildIndex] is TLabel then
      begin
        TitleLabel := TLabel(HeaderPanel.Controls[ChildIndex]);
        TitleLabel.Caption := PaletteTitle(PaletteKind);
        Break;
      end;
    end;
  end;

  { 7. Refresh status/tool text and dependent dynamic labels }
  if Assigned(FStatusZoomLabel) then
    FStatusZoomLabel.Hint := TR('Click to toggle between Fit and Actual Size', '点击切换“适合窗口”和“实际大小”');
  if Assigned(FLastEffectProc) and Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
  LayoutColorsPanel;
  RefreshColorsPanel;
  UpdateToolOptionControl;
  RefreshPaletteMenuChecks;
  SyncUtilityButtonStates;
  UpdateStatusForTool;
  UpdateCaption;
end;

procedure TMainForm.HelpClick(Sender: TObject);
begin
  MessageDlg(
    TR('FlatPaint Help', 'FlatPaint ' + #$E5#$B8#$AE#$E5#$8A#$A9),
    TR('Primary shortcuts:'#13#10 +
    'Cmd+1 Tools  Cmd+2 Colors  Cmd+3 Layers  Cmd+4 History'#13#10 +
    'Cmd+'' Pixel Grid  Cmd+Option+R Rulers'#13#10 +
    'Cmd+N New  Cmd+O Open  Cmd+S Save  Cmd+W Close'#13#10 +
    'Supported open formats:'#13#10 +
    'FlatPaint (.fpd), XCF, PSD, PNG, JPEG, BMP, TIFF, GIF, PCX, PNM, TGA, XPM, XWD',
    #$E4#$B8#$BB#$E8#$A6#$81#$E5#$BF#$AB#$E6#$8D#$B7#$E9#$94#$AE#$EF#$BC#$9A#13#10 +
    'Cmd+1 ' + #$E5#$B7#$A5#$E5#$85#$B7 + '  Cmd+2 ' + #$E9#$A2#$9C#$E8#$89#$B2 + '  Cmd+3 ' + #$E5#$9B#$BE#$E5#$B1#$82 + '  Cmd+4 ' + #$E5#$8E#$86#$E5#$8F#$B2#13#10 +
    'Cmd+'' ' + #$E5#$83#$8F#$E7#$B4#$A0#$E7#$BD#$91#$E6#$A0#$BC + '  Cmd+Option+R ' + #$E6#$A0#$87#$E5#$B0#$BA#13#10 +
    'Cmd+N ' + #$E6#$96#$B0#$E5#$BB#$BA + '  Cmd+O ' + #$E6#$89#$93#$E5#$BC#$80 + '  Cmd+S ' + #$E4#$BF#$9D#$E5#$AD#$98 + '  Cmd+W ' + #$E5#$85#$B3#$E9#$97#$AD#13#10 +
    #$E6#$94#$AF#$E6#$8C#$81#$E7#$9A#$84#$E6#$89#$93#$E5#$BC#$80#$E6#$A0#$BC#$E5#$BC#$8F#$EF#$BC#$9A#13#10 +
    'FlatPaint (.fpd), XCF, PSD, PNG, JPEG, BMP, TIFF, GIF, PCX, PNM, TGA, XPM, XWD'),
    mtInformation,
    [mbOK],
    0
  );
end;

procedure TMainForm.StatusZoomToggleClick(Sender: TObject);
begin
  if QuickSizeToggleTargetsFit(FZoomScale) then
    FitToWindowClick(Sender)
  else
    ActualSizeClick(Sender);
end;

function TMainForm.ShouldAnimateMarqueeNow: Boolean;
var
  PointerInCanvas: Boolean;
  HasSelectionMarquee: Boolean;
begin
  PointerInCanvas := Assigned(FDocument) and
    (FLastImagePoint.X >= 0) and (FLastImagePoint.Y >= 0) and
    (FLastImagePoint.X < FDocument.Width) and (FLastImagePoint.Y < FDocument.Height);
  HasSelectionMarquee := Assigned(FDocument) and FDocument.HasSelection;
  Result := ShouldAnimateMarqueeOverlay(
    FCurrentTool,
    HasSelectionMarquee,
    FCloneStampSampled,
    PointerInCanvas
  );
end;

procedure TMainForm.UpdateMarqueeAnimationState;
var
  ShouldAnimate: Boolean;
begin
  if not Assigned(FMarqueeTimer) then
    Exit;
  ShouldAnimate := ShouldAnimateMarqueeNow;
  if not ShouldAnimate then
    FMarqueeLastTickMS := 0;
  if FMarqueeTimer.Enabled <> ShouldAnimate then
    FMarqueeTimer.Enabled := ShouldAnimate;
end;

procedure TMainForm.MarqueeTimerTick(Sender: TObject);
var
  PhaseStep: Integer;
const
  { Half-speed tuning: keep frame cadence, reduce phase stride. }
  MarqueePhaseAdvancePerTick = 1;
begin
  if not Assigned(FPaintBox) then
    Exit;
  if not ShouldAnimateMarqueeNow then
  begin
    if Assigned(FMarqueeTimer) then
      FMarqueeTimer.Enabled := False;
    FMarqueeLastTickMS := 0;
    Exit;
  end;
  FMarqueeLastTickMS := GetTickCount64;
  for PhaseStep := 1 to MarqueePhaseAdvancePerTick do
    FMarqueeDashPhase := NextMarqueePhase(FMarqueeDashPhase);
  FPaintBox.Invalidate;
end;

procedure TMainForm.AppIdle(Sender: TObject; var Done: Boolean);
var
  ScrollPosition: TPoint;
begin
  { Keep idle loop event-driven; marquee uses a dedicated timer so animation
    remains smooth even without pointer movement. }
  Done := not FDeferredLayoutPass;
  if not Assigned(FCanvasHost) then
    Exit;

  if FDeferredLayoutPass and Assigned(FWorkspacePanel) and
     (FWorkspacePanel.ClientWidth > 0) and (FWorkspacePanel.ClientHeight > 0) then
  begin
    RestorePaletteLayout;
    LayoutStatusBarControls(nil);
    RelayoutTopChrome;
    Dec(FDeferredLayoutPassesRemaining);
    FDeferredLayoutPass := FDeferredLayoutPassesRemaining > 0;
    if not FDeferredLayoutPass then
    begin
      { All deferred layout passes complete — the viewport now has its final
        dimensions.  Fit the document then re-center the canvas so the image
        is centred inside the post-layout viewport rather than the smaller
        pre-layout viewport that consumed the original flag. }
      FitDocumentToViewport(True);
      FCenterOnNextCanvasUpdate := True;
      UpdateCanvasSize;
    end;
  end;

  { Disable Cocoa rubber-band bounce for the canvas scroll view so viewport
    edges stay static under repeated boundary-direction wheel input. }
  if (not FScrollElasticityDisabled) and FCanvasHost.HandleAllocated then
  begin
    FPDisableScrollElasticity(Pointer(FCanvasHost.Handle));
    FScrollElasticityDisabled := True;
  end;

  { Install native pinch-to-zoom handler once handles are ready }
  if (not FMagnifyInstalled) and FCanvasHost.HandleAllocated then
  begin
    FPInstallMagnifyHandler(Pointer(FCanvasHost.Handle),
      @FPMagnifyCallbackProc,
      Self);
    FMagnifyInstalled := True;
  end;

  { Force light (Aqua) appearance so all native dropdowns/popups render
    with a white background instead of a dark translucent material. }
  if (not FAquaAppearanceApplied) and HandleAllocated then
  begin
    FPForceAquaAppearance(Pointer(Handle));
    FAquaAppearanceApplied := True;
  end;

  UpdateMarqueeAnimationState;

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
  ScrollDelta: Integer;
  ClampedDelta: Integer;
begin
  if not Assigned(FCanvasHost) then
    Exit;
  if ZoomWheelUsesViewportZoom(Shift) then
  begin
    ViewportPoint := FCanvasHost.ScreenToClient(MousePos);
    if WheelDelta < 0 then
      ApplyZoomScaleAtViewportPoint(NextZoomOutScale(FZoomScale), ViewportPoint)
    else if WheelDelta > 0 then
      ApplyZoomScaleAtViewportPoint(NextZoomInScale(FZoomScale), ViewportPoint);
    Handled := WheelDelta <> 0;
    Exit;
  end;

  if not Assigned(FPaintBox) then
    Exit;

  ScrollDelta := WheelScrollPixels(WheelDelta);
  if ScrollDelta = 0 then
  begin
    Handled := False;
    Exit;
  end;

  if ssShift in Shift then
  begin
    ClampedDelta := ClampViewportScrollDelta(
      FCanvasHost.HorzScrollBar.Position,
      ScrollDelta,
      FPaintBox.Left,
      FPaintBox.Width,
      FCanvasHost.ClientWidth
    );
    if ClampedDelta <> 0 then
      FCanvasHost.HorzScrollBar.Position := FCanvasHost.HorzScrollBar.Position + ClampedDelta;
  end
  else
  begin
    ClampedDelta := ClampViewportScrollDelta(
      FCanvasHost.VertScrollBar.Position,
      ScrollDelta,
      FPaintBox.Top,
      FPaintBox.Height,
      FCanvasHost.ClientHeight
    );
    if ClampedDelta <> 0 then
      FCanvasHost.VertScrollBar.Position := FCanvasHost.VertScrollBar.Position + ClampedDelta;
  end;

  FLastScrollPosition := Point(
    FCanvasHost.HorzScrollBar.Position,
    FCanvasHost.VertScrollBar.Position
  );
  RefreshRulers;
  Handled := WheelDelta <> 0;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  I: Integer;
  DirtyCount: Integer;
  Choice: Integer;
begin
  SealPendingStrokeHistory;
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
      TR('Save Changes', '保存更改'),
      Format(TR('You have %d document(s) with unsaved changes. Save before quitting?',
                '有 %d 个文档尚未保存。是否在退出前保存？'), [DirtyCount]),
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
  SealPendingStrokeHistory;
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
  SealPendingStrokeHistory;
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
var
  NewTool: TToolKind;
  ResolvedSize: Integer;
  ResolvedOpacity: Integer;
  ResolvedHardness: Integer;
begin
  SealPendingStrokeHistory;
  CommitInlineTextEdit(True);
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;
  FTempToolActive := False;
  NewTool := TToolKind(TControl(Sender).Tag);
  MaybeAutoDeselectOnToolSwitch(FCurrentTool, NewTool);
  ApplyToolOptionSwitch(
    FCurrentTool,
    NewTool,
    FBrushSize,
    FBrushOpacity,
    FBrushHardness,
    FToolSize,
    FToolOpacity,
    FToolHardness,
    ResolvedSize,
    ResolvedOpacity,
    ResolvedHardness
  );
  FCurrentTool := NewTool;
  FBrushSize := ResolvedSize;
  FBrushOpacity := ResolvedOpacity;
  FBrushHardness := ResolvedHardness;
  SyncToolComboSelection;
  UpdateToolOptionControl;
  RefreshCanvas;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.ToolComboChange(Sender: TObject);
var
  NewTool: TToolKind;
  ResolvedSize: Integer;
  ResolvedOpacity: Integer;
  ResolvedHardness: Integer;
begin
  SealPendingStrokeHistory;
  CommitInlineTextEdit(True);
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;
  FTempToolActive := False;
  if FToolCombo.ItemIndex >= 0 then
  begin
    NewTool := TToolKind(PtrInt(FToolCombo.Items.Objects[FToolCombo.ItemIndex]));
    MaybeAutoDeselectOnToolSwitch(FCurrentTool, NewTool);
    ApplyToolOptionSwitch(
      FCurrentTool,
      NewTool,
      FBrushSize,
      FBrushOpacity,
      FBrushHardness,
      FToolSize,
      FToolOpacity,
      FToolHardness,
      ResolvedSize,
      ResolvedOpacity,
      ResolvedHardness
    );
    FCurrentTool := NewTool;
    FBrushSize := ResolvedSize;
    FBrushOpacity := ResolvedOpacity;
    FBrushHardness := ResolvedHardness;
  end;
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
    tkText:
      begin
        InitializeTextToolDefaults;
        FTextLastResult.FontSize := EnsureRange(FBrushSpin.Value, 6, 256);
        if Assigned(FInlineTextEdit) and FInlineTextEdit.Visible then
        begin
          UpdateInlineTextEditStyle;
          UpdateInlineTextEditBounds;
        end;
      end;
  end;
  RefreshCanvas;
end;

procedure TMainForm.TextFontButtonClick(Sender: TObject);
begin
  if FUpdatingToolOption then
    Exit;
  if not RunSystemTextFontDialog then
    Exit;
  if Assigned(FInlineTextEdit) and FInlineTextEdit.Visible then
  begin
    UpdateInlineTextEditStyle;
    UpdateInlineTextEditBounds;
  end;
  UpdateToolOptionControl;
  RefreshCanvas;
end;

procedure TMainForm.EnsureLayerRowIcons;
  procedure EnsureIcon(const ACaption: string; var APicture: TPicture);
  begin
    if Assigned(APicture) and Assigned(APicture.Graphic) and (not APicture.Graphic.Empty) then
      Exit;
    if not Assigned(APicture) then
      APicture := TPicture.Create;
    APicture.Clear;
    if not TryLoadButtonIconPicture(ACaption, bicCommand, APicture) then
      APicture.Clear;
  end;
begin
  EnsureIcon('Lock', FLayerLockClosedIcon);
  EnsureIcon('Unlock', FLayerLockOpenIcon);
  EnsureIcon('Vis', FLayerEyeOnIcon);
  EnsureIcon('VisOff', FLayerEyeOffIcon);
end;

procedure TMainForm.DrawLayerRowIcon(
  ACanvas: TCanvas;
  const ARect: TRect;
  AIcon: TPicture
);
begin
  if (AIcon = nil) or (AIcon.Graphic = nil) or AIcon.Graphic.Empty then
    Exit;
  ACanvas.StretchDraw(ARect, AIcon.Graphic);
end;

procedure TMainForm.LayerListDrawCell(Sender: TObject; ACol, ARow: Integer;
  ARect: TRect; AState: TGridDrawState);
const
  ThumbMarginY = 4;
  NameLeftPad = 6;
var
  Grid: TDrawGrid;
  Layer: TRasterLayer;
  NameText: string;
  BgCol: TColor;
  TextCol: TColor;
  ThumbSurf: TRasterSurface;
  ThumbBmp: TBitmap;
  Src: TRasterSurface;
  SW: Integer;
  SH: Integer;
  ThumbRect: TRect;
  IconRect: TRect;
  OldFont: TFont;
begin
  Grid := TDrawGrid(Sender);
  if not Assigned(FDocument) then
    Exit;

  if (ARow < 0) or (ARow >= FDocument.LayerCount) then
  begin
    Grid.Canvas.Brush.Color := Grid.Color;
    Grid.Canvas.FillRect(ARect);
    Exit;
  end;

  Layer := FDocument.Layers[ARow];

  if (ARow = Grid.Row) or (gdSelected in AState) then
  begin
    BgCol := PaletteSelectionColor;
    TextCol := PaletteSelectionTextColor;
  end
  else if (FLayerDragIndex >= 0) and (FLayerDragTargetIndex = ARow) then
  begin
    BgCol := PaletteActiveRowColor;
    TextCol := ChromeTextColor;
  end
  else
  begin
    BgCol := Grid.Color;
    TextCol := ChromeTextColor;
  end;

  Grid.Canvas.Brush.Color := BgCol;
  Grid.Canvas.FillRect(ARect);

  EnsureLayerRowIcons;
  case ACol of
    0:
      begin
        IconRect := LayerGridCenteredIconRect(ARect);
        if (ARow >= 0) and (ARow < Length(FLayerRowLockHitRects)) then
          FLayerRowLockHitRects[ARow] := IconRect;
        if Layer.Locked then
          DrawLayerRowIcon(Grid.Canvas, IconRect, FLayerLockClosedIcon)
        else
        begin
          DrawLayerRowIcon(Grid.Canvas, IconRect, FLayerLockOpenIcon);
          Grid.Canvas.Pen.Color := ChromeTextColor;
          Grid.Canvas.Pen.Width := 1;
          Grid.Canvas.MoveTo(IconRect.Right - 5, IconRect.Top + 2);
          Grid.Canvas.LineTo(IconRect.Right - 1, IconRect.Top + 6);
        end;
      end;
    1:
      begin
        IconRect := LayerGridCenteredIconRect(ARect);
        if (ARow >= 0) and (ARow < Length(FLayerRowEyeHitRects)) then
          FLayerRowEyeHitRects[ARow] := IconRect;
        if Layer.Visible then
          DrawLayerRowIcon(Grid.Canvas, IconRect, FLayerEyeOnIcon)
        else
          DrawLayerRowIcon(Grid.Canvas, IconRect, FLayerEyeOffIcon);
      end;
    2:
      begin
        ThumbRect := Rect(
          ARect.Left + LayerCellPadX,
          ARect.Top + ThumbMarginY,
          ARect.Right - LayerCellPadX,
          ARect.Bottom - ThumbMarginY
        );
        Grid.Canvas.Brush.Color := ChromeDividerColor;
        Grid.Canvas.FillRect(ThumbRect);

        Src := Layer.Surface;
        if Assigned(Src) and (Src.Width > 0) and (Src.Height > 0) then
        begin
          if Src.Width * (ThumbRect.Bottom - ThumbRect.Top) >
             Src.Height * (ThumbRect.Right - ThumbRect.Left) then
          begin
            SW := Max(1, ThumbRect.Right - ThumbRect.Left);
            SH := Max(1, Src.Height * SW div Src.Width);
          end
          else
          begin
            SH := Max(1, ThumbRect.Bottom - ThumbRect.Top);
            SW := Max(1, Src.Width * SH div Src.Height);
          end;
          ThumbSurf := Src.ResizeBilinear(SW, SH);
          try
            ThumbBmp := SurfaceToBitmap(ThumbSurf);
            try
              Grid.Canvas.Draw(
                ThumbRect.Left + ((ThumbRect.Right - ThumbRect.Left - SW) div 2),
                ThumbRect.Top + ((ThumbRect.Bottom - ThumbRect.Top - SH) div 2),
                ThumbBmp
              );
            finally
              ThumbBmp.Free;
            end;
          finally
            ThumbSurf.Free;
          end;
        end;

        Grid.Canvas.Brush.Style := bsClear;
        Grid.Canvas.Pen.Color := ChromeDividerColor;
        Grid.Canvas.Rectangle(ThumbRect.Left, ThumbRect.Top, ThumbRect.Right, ThumbRect.Bottom);
        Grid.Canvas.Brush.Style := bsSolid;
      end;
    3:
      begin
        NameText := Layer.Name;
        if Layer.IsBackground then
          NameText := NameText + ' [Background]';
        if Layer.Opacity < 255 then
          NameText := NameText + Format(' %d%%', [LayerOpacityPercentFromByte(Layer.Opacity)]);
        if Layer.Locked then
          NameText := NameText + ' [Locked]';

        OldFont := TFont.Create;
        try
          OldFont.Assign(Grid.Canvas.Font);
          Grid.Canvas.Font.Color := TextCol;
          if (ARow = Grid.Row) or (gdSelected in AState) then
            Grid.Canvas.Font.Style := [fsBold]
          else
            Grid.Canvas.Font.Style := [];
          Grid.Canvas.Brush.Style := bsClear;
          Grid.Canvas.TextOut(
            ARect.Left + NameLeftPad,
            ARect.Top + ((ARect.Bottom - ARect.Top - Grid.Canvas.TextHeight('Ag')) div 2),
            NameText
          );
          Grid.Canvas.Brush.Style := bsSolid;
        finally
          Grid.Canvas.Font.Assign(OldFont);
          OldFont.Free;
        end;
      end;
  end;
end;

procedure TMainForm.LayerListClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if (FDocument.LayerCount > 0) and
     (FLayerList.Row >= 0) and
     (FLayerList.Row < FDocument.LayerCount) then
    FDocument.ActiveLayerIndex := FLayerList.Row;
  if FDocument.LayerCount > 0 then
  begin
    FUpdatingLayerControls := True;
    try
      if Assigned(FLayerBlendCombo) then
        FLayerBlendCombo.ItemIndex := Ord(FDocument.ActiveLayer.BlendMode);
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
  { Keep layer-row double-click side-effect free.
    Visibility must be controlled only by the eye icon to avoid
    lock/visibility gesture coupling under rapid clicks. }
end;

procedure TMainForm.LayerListMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
type
  TLayerHitTarget = (lhtNone, lhtLock, lhtEye);
var
  HitCol: Integer;
  HitIndex: Integer;
  LockRect: TRect;
  EyeRect: TRect;
  HitPoint: TPoint;
  HitTarget: TLayerHitTarget;

  function HitAtPoint(const APoint: TPoint): TLayerHitTarget;
  begin
    if PtInRect(LockRect, APoint) then
      Exit(lhtLock);
    if PtInRect(EyeRect, APoint) then
      Exit(lhtEye);
    Result := lhtNone;
  end;
begin
  if (Button <> mbLeft) or not Assigned(FLayerList) then
    Exit;
  if FDocument.LayerCount <= 0 then
    Exit;
  FLayerList.MouseToCell(X, Y, HitCol, HitIndex);
  if (HitIndex < 0) or (HitIndex >= FDocument.LayerCount) then
    Exit;
  if HitCol = 0 then
    LockRect := LayerGridCenteredIconRect(FLayerList.CellRect(0, HitIndex))
  else
    LockRect := Rect(0, 0, 0, 0);
  if HitCol = 1 then
    EyeRect := LayerGridCenteredIconRect(FLayerList.CellRect(1, HitIndex))
  else
    EyeRect := Rect(0, 0, 0, 0);
  HitPoint := Point(X, Y);
  HitTarget := HitAtPoint(HitPoint);

  { Click lock icon -> toggle lock only (no visibility side-effects). }
  if HitTarget = lhtLock then
  begin
    FDocument.Layers[HitIndex].Locked := not FDocument.Layers[HitIndex].Locked;
    FLayerList.Invalidate;
    Exit;
  end;

  { Click eye icon -> toggle visibility only (no lock side-effects). }
  if HitTarget = lhtEye then
  begin
    FDocument.SetLayerVisibility(HitIndex, not FDocument.Layers[HitIndex].Visible);
    InvalidatePreparedBitmap;
    RefreshCanvas;
    FLayerList.Invalidate;
    Exit;
  end;

  FLayerDragIndex := HitIndex;
  FLayerDragTargetIndex := HitIndex;
  FLayerList.Row := HitIndex;
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
  HoverIndex := LayerGridRowAtY(FLayerList, Y);
  if HoverIndex < 0 then
  begin
    if Y < 0 then
      HoverIndex := 0
    else
      HoverIndex := FDocument.LayerCount - 1;
  end;
  HoverIndex := EnsureRange(HoverIndex, 0, FDocument.LayerCount - 1);
  if (FLayerDragIndex = 0) and (FDocument.LayerCount > 0) and FDocument.Layers[0].IsBackground then
    HoverIndex := 0;
  if (HoverIndex = 0) and (FLayerDragIndex > 0) and (FDocument.LayerCount > 0) and
     FDocument.Layers[0].IsBackground then
    HoverIndex := 1;
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
  DropIndex := LayerGridRowAtY(FLayerList, Y);
  if DropIndex < 0 then
    DropIndex := FLayerDragTargetIndex;
  DropIndex := EnsureRange(DropIndex, 0, FDocument.LayerCount - 1);
  if (FLayerDragIndex = 0) and (FDocument.LayerCount > 0) and FDocument.Layers[0].IsBackground then
    DropIndex := 0;
  if (DropIndex = 0) and (FLayerDragIndex > 0) and (FDocument.LayerCount > 0) and
     FDocument.Layers[0].IsBackground then
    DropIndex := 1;
  if (DropIndex <> FLayerDragIndex) and (DropIndex >= 0) then
  begin
    FDocument.PushHistory(LocalizedAction('Reorder Layer'));
    FDocument.MoveLayer(FLayerDragIndex, DropIndex);
    SyncImageMutationUI(True, True);
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
  FDraggingPalette := PaletteRootForControl(DragControl);
  if FDraggingPalette = nil then
    Exit;
  FPaletteDragOffset := PointRelativeToControl(DragControl, FDraggingPalette, Point(X, Y));
  FDraggingPalette.BringToFront;
  ApplyPaletteVisualState(FDraggingPalette, True);
end;

procedure TMainForm.PaletteMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  LocalPoint: TPoint;
begin
  if (FDraggingPalette = nil) or not (Sender is TControl) then
    Exit;
  if not ControlBelongsToPalette(TControl(Sender), FDraggingPalette) then
    Exit;
  LocalPoint := PointRelativeToControl(TControl(Sender), FDraggingPalette, Point(X, Y));
  FDraggingPalette.Left := FDraggingPalette.Left + LocalPoint.X - FPaletteDragOffset.X;
  FDraggingPalette.Top := FDraggingPalette.Top + LocalPoint.Y - FPaletteDragOffset.Y;
  ClampPaletteToWorkspace(FDraggingPalette);
end;

procedure TMainForm.PaletteMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  SnappedRect: TRect;
  WorkspaceRect: TRect;
begin
  if (FDraggingPalette <> nil) and (Sender is TControl) and
     ControlBelongsToPalette(TControl(Sender), FDraggingPalette) then
  begin
    WorkspaceRect := PaletteClampWorkspaceRect(FWorkspacePanel.ClientRect, FShowRulers);
    SnappedRect := SnapPaletteRect(
      Rect(
        FDraggingPalette.Left,
        FDraggingPalette.Top,
        FDraggingPalette.Left + FDraggingPalette.Width,
        FDraggingPalette.Top + FDraggingPalette.Height
      ),
      WorkspaceRect
    );
    FDraggingPalette.SetBounds(
      SnappedRect.Left,
      SnappedRect.Top,
      SnappedRect.Right - SnappedRect.Left,
      SnappedRect.Bottom - SnappedRect.Top
    );
    ClampPaletteToWorkspace(FDraggingPalette);
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
  TargetTabIndex: Integer;
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
    TargetTabIndex := NextCycledTabIndex(
      FActiveTabIndex,
      Length(FTabDocuments),
      ssShift in Shift
    );
    if TargetTabIndex <> FActiveTabIndex then
      SwitchToTab(TargetTabIndex);
    Key := 0;
    Exit;
  end;

  if (Key = VK_ESCAPE) and Assigned(FMovePixelsController) and FMovePixelsController.Active then
  begin
    FPointerDown := False;
    if Assigned(FPaintBox) then
      FPaintBox.MouseCapture := False;
    CancelMovePixelsTransaction;
    Key := 0;
    Exit;
  end;

  if (FCurrentTool = tkLine) and FLineBezierMode and (FLineCurvePending or FLinePathOpen) then
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

  { Esc deselects the active selection (paint.net / Photoshop convention) }
  if (Key = VK_ESCAPE) and FDocument.HasSelection then
  begin
    DeselectClick(nil);
    Key := 0;
    Exit;
  end;

  { Single-letter color shortcuts should only run on plain keypresses.
    Command/Ctrl/Alt combinations belong to menu shortcuts.
    Skip entirely when an inline text edit is active so typing works. }
  if ToolShortcutUsesPlainKeyOnly(Shift)
     and not (Assigned(FInlineTextEdit) and FInlineTextEdit.Visible) then
  begin
    case UpCase(Char(Key)) of
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

procedure TMainForm.SimulateMagnifyGestureForTest(AMagnification: Double;
  ALocationX, ALocationY: Double);
begin
  FPMagnifyCallbackProc(Self, AMagnification, ALocationX, ALocationY);
end;

procedure TMainForm.SimulateToolButtonSwitch(ATool: TToolKind);
var
  SenderComponent: TComponent;
begin
  SenderComponent := TComponent.Create(nil);
  try
    SenderComponent.Tag := Ord(ATool);
    ToolButtonClick(SenderComponent);
  finally
    SenderComponent.Free;
  end;
end;

procedure TMainForm.SetPrimaryColorForTest(const AColor: TRGBA32);
begin
  FPrimaryColor := AColor;
  SyncStrokeColorToActiveTarget;
end;

procedure TMainForm.SetSecondaryColorForTest(const AColor: TRGBA32);
begin
  FSecondaryColor := AColor;
end;

procedure TMainForm.SetRecolorOptionsForTest(
  ASamplingMode: TRecolorSamplingMode;
  ABlendMode: TRecolorBlendMode;
  ATolerance: Integer;
  APreserveValue: Boolean;
  AContiguous: Boolean
);
begin
  FRecolorSamplingMode := ASamplingMode;
  FRecolorBlendMode := ABlendMode;
  FRecolorTolerance := EnsureRange(ATolerance, 0, 255);
  FRecolorPreserveValue := APreserveValue;
  FRecolorContiguous := AContiguous;
  FRecolorStrokeSourceValid := False;
end;

procedure TMainForm.SetCloneOptionsForTest(AAligned: Boolean; ASampleSource: Integer);
begin
  FCloneAligned := AAligned;
  FCloneSampleSource := EnsureRange(ASampleSource, 0, 1);
  if not FCloneAligned then
    FCloneAlignedOffsetValid := False;
end;

procedure TMainForm.SetCropOptionsForTest(AAspectMode, AGuideMode: Integer);
begin
  FCropAspectMode := EnsureRange(AAspectMode, 0, 4);
  FCropGuideMode := EnsureRange(AGuideMode, 0, 2);
end;

function TMainForm.CloneSnapshotPixelForTest(X, Y: Integer; out APixel: TRGBA32): Boolean;
begin
  Result := Assigned(FCloneStampSnapshot) and FCloneStampSnapshot.InBounds(X, Y);
  if Result then
    APixel := FCloneStampSnapshot[X, Y]
  else
    APixel := TransparentColor;
end;

procedure TMainForm.SetBrushSizeForTest(ASize: Integer);
begin
  FBrushSize := Max(1, ASize);
end;

procedure TMainForm.SetShapeLineStyleForTest(AStyleIndex: Integer);
begin
  FShapeLineStyle := EnsureRange(AStyleIndex, 0, 1);
end;

function TMainForm.StrokeRectIsEmpty(const ARect: TRect): Boolean;
begin
  Result := (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top);
end;

function TMainForm.StrokeBoundsForSegment(const AFrom, ATo: TPoint; ARadius: Integer): TRect;
var
  Margin: Integer;
begin
  Margin := Max(2, ARadius + 2);
  Result.Left := Min(AFrom.X, ATo.X) - Margin;
  Result.Top := Min(AFrom.Y, ATo.Y) - Margin;
  Result.Right := Max(AFrom.X, ATo.X) + Margin + 1;
  Result.Bottom := Max(AFrom.Y, ATo.Y) + Margin + 1;
end;

procedure TMainForm.CaptureStrokeBeforeRect(const ARect: TRect);
begin
  if Assigned(FStrokeController) then
    FStrokeController.CaptureBeforeRect(FDocument, ARect);
end;

procedure TMainForm.ClearStrokeHistoryState;
begin
  if Assigned(FStrokeController) then
    FStrokeController.Clear;
end;

function TMainForm.HasPendingStrokeHistory: Boolean;
begin
  Result := Assigned(FStrokeController) and FStrokeController.HasPending;
end;

procedure TMainForm.SealPendingStrokeHistory;
begin
  if Assigned(FMovePixelsController) and FMovePixelsController.Active then
    CancelMovePixelsTransaction;
  if not HasPendingStrokeHistory then
    Exit;
  if Assigned(FPaintBox) then
    FPaintBox.MouseCapture := False;
  FPointerDown := False;
  CommitStrokeHistory(PaintToolName(FStrokeTool));
end;

procedure TMainForm.BeginStrokeHistory;
begin
  if ShouldCommitPendingStrokeOnMouseDown(HasPendingStrokeHistory) then
    SealPendingStrokeHistory;
  FStrokeTool := FCurrentTool;
  if Assigned(FStrokeController) then
    FStrokeController.BeginSession(FDocument, FCurrentTool, FDocument.ActiveLayerIndex);
end;

procedure TMainForm.ExpandStrokeDirty(const APoint: TPoint);
begin
  { Dirty bounds are now tracked inside FStrokeController via capture rects.
    Keep this method as a compatibility no-op for existing call sites. }
end;

procedure TMainForm.CommitStrokeHistory(const ALabel: string);
begin
  if not Assigned(FStrokeController) then
    Exit;
  if FStrokeController.CommitToHistory(FDocument, ALabel) then
  begin
    RefreshTabCardVisuals(FActiveTabIndex);
    RefreshAuxiliaryImageViews(False);
    RefreshHistoryPanel;
  end;
  if FStrokeTool = tkRecolor then
  begin
    FRecolorStrokeSourceValid := False;
    FreeAndNil(FRecolorStrokeSnapshot);
  end;
end;

procedure TMainForm.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
begin
  { Guard: block editing on locked layers (allow non-destructive tools) }
  if Assigned(FDocument) and (FDocument.LayerCount > 0) and
     FDocument.ActiveLayer.Locked and
     not (FCurrentTool in [tkZoom, tkPan, tkColorPicker, tkSelectRect,
       tkSelectEllipse, tkSelectLasso, tkMagicWand, tkMoveSelection]) then
    Exit;
  if ShouldCommitPendingStrokeOnMouseDown(HasPendingStrokeHistory) then
    SealPendingStrokeHistory;
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
  if FCurrentTool = tkPan then
    FLastPointerPoint := PointerViewportPointFromEvent(X, Y)
  else
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
  if ShouldAutoDeselectFromBlankClick(ImagePoint, Button, Shift) then
    AutoDeselectSelection(LocalizedAction('Deselect'));
  { Only override combo-selected mode when modifier keys are held }
  if (ssShift in Shift) or (ssAlt in Shift) then
    FPendingSelectionMode := TSelectionToolController.ModeFromModifiers(
      ssShift in Shift,
      ssAlt in Shift
    );
  FPointerButton := Button;
  FPointerDown := True;
  if Assigned(FPaintBox) then
    FPaintBox.MouseCapture := True;

  case FCurrentTool of
    tkPencil, tkBrush, tkEraser:
      begin
        BeginStrokeHistory;
        ApplyImmediateTool(ImagePoint);
        ExpandStrokeDirty(ImagePoint);
        InvalidatePreparedBitmap;
        SetDirty(True);
        RefreshCanvas;
      end;
    tkFill:
      begin
        if FDocument.HasSelection and not FDocument.Selection[ImagePoint.X, ImagePoint.Y] then
        begin
          FPointerDown := False;
          if Assigned(FPaintBox) then
            FPaintBox.MouseCapture := False;
          RefreshStatus(ImagePoint);
          Exit;
        end;
        if FDocument.BeginActiveLayerMutation(PaintToolName(FCurrentTool)) then
        begin
          ApplyImmediateTool(ImagePoint);
          SyncImageMutationUI(False, True);
        end;
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
        if Assigned(FSelectionController) then
          FSelectionController.CommitMagicWandSelection(
            FDocument,
            ImagePoint,
            FWandTolerance,
            FPendingSelectionMode,
            FWandSampleSource = 1,
            FWandContiguous,
            FSelFeather,
            'Magic Wand'
          )
        else
        begin
          FDocument.PushHistory(LocalizedAction('Magic Wand'));
          FDocument.SelectMagicWand(
            ImagePoint.X,
            ImagePoint.Y,
            EnsureRange(FWandTolerance, 0, 255),
            FPendingSelectionMode,
            FWandSampleSource = 1,
            FWandContiguous
          );
        end;
        SyncSelectionOverlayUI(True);
        FPointerDown := False;
      end;
    tkText:
      begin
        if (Button = mbRight) or (ssAlt in Shift) then
        begin
          if RunSystemTextFontDialog and
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
          if FCloneSampleSource = 1 then
            FCloneStampSnapshot := FDocument.Composite
          else
            FCloneStampSnapshot := FDocument.ActiveLayer.Surface.Clone;
          FPointerDown := False;
          if Assigned(FPaintBox) then
          begin
            FPaintBox.MouseCapture := False;
            FPaintBox.Invalidate;
          end;
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
          InvalidatePreparedBitmap;
          SetDirty(True);
          RefreshCanvas;
        end
        else
          FPointerDown := False;
      end;
    tkRecolor:
      begin
        FreeAndNil(FRecolorStrokeSnapshot);
        FRecolorStrokeSnapshot := FDocument.ActiveLayer.Surface.Clone;
        FRecolorStrokeSourceValid := False;
        case FRecolorSamplingMode of
          rsmOnce:
            begin
              if RecolorSourceAtPoint(ImagePoint, FRecolorStrokeSourceColor) then
                FRecolorStrokeSourceValid := True
              else
                FRecolorStrokeSourceColor := ColorForActiveTarget(not FPickSecondaryTarget);
            end;
          rsmSwatchCompat:
            begin
              FRecolorStrokeSourceColor := ColorForActiveTarget(not FPickSecondaryTarget);
              FRecolorStrokeSourceValid := True;
            end;
        end;
        BeginStrokeHistory;
        ApplyImmediateTool(ImagePoint);
        ExpandStrokeDirty(ImagePoint);
        InvalidatePreparedBitmap;
        SetDirty(True);
        RefreshCanvas;
      end;
    tkCrop:
      begin
        { Crop: drag rectangle on mouse up }
        RefreshCanvas;
      end;
    tkMosaic:
      begin
        { Mosaic: drag rectangle, pixelate on mouse up }
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
        else if FCurrentTool = tkMoveSelection then
        begin
          if Assigned(FSelectionController) then
            FSelectionController.BeginMoveSelection(FDocument, PaintToolName(FCurrentTool))
          else
            FDocument.PushHistory(PaintToolName(FCurrentTool));
        end;
        if FPointerDown and (FCurrentTool = tkMovePixels) then
          BeginMovePixelsTransaction;
      end;
  end;
  if Assigned(FPaintBox) then
    FPaintBox.MouseCapture := FPointerDown;
end;

procedure TMainForm.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
  CurrentPointerPoint: TPoint;
  DeltaX: Integer;
  DeltaY: Integer;
  ButtonStillDown: Boolean;
  PannedHorizontal: Integer;
  PannedVertical: Integer;
  TickNow: QWord;
begin
  ImagePoint := CanvasToImage(X, Y);
  DeltaX := ImagePoint.X - FLastImagePoint.X;
  DeltaY := ImagePoint.Y - FLastImagePoint.Y;
  if FPointerDown then
  begin
    ButtonStillDown := DragButtonIsStillPressed(FPointerButton, Shift);
    if not ButtonStillDown then
    begin
      PaintBoxMouseUp(Sender, FPointerButton, Shift, X, Y);
      Exit;
    end;
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
          CurrentPointerPoint := PointerViewportPointFromEvent(X, Y);
          if Assigned(FCanvasHost) then
          begin
            FIsPanning := True;
            try
              PannedHorizontal := PannedScrollPosition(
                FCanvasHost.HorzScrollBar.Position,
                CurrentPointerPoint.X,
                FLastPointerPoint.X
              );
              PannedVertical := PannedScrollPosition(
                FCanvasHost.VertScrollBar.Position,
                CurrentPointerPoint.Y,
                FLastPointerPoint.Y
              );
              PannedHorizontal := ClampViewportScrollPosition(
                PannedHorizontal,
                FPaintBox.Left,
                FPaintBox.Width,
                FCanvasHost.ClientWidth
              );
              PannedVertical := ClampViewportScrollPosition(
                PannedVertical,
                FPaintBox.Top,
                FPaintBox.Height,
                FCanvasHost.ClientHeight
              );
              if PannedHorizontal <> FCanvasHost.HorzScrollBar.Position then
                FCanvasHost.HorzScrollBar.Position := PannedHorizontal;
              if PannedVertical <> FCanvasHost.VertScrollBar.Position then
                FCanvasHost.VertScrollBar.Position := PannedVertical;
            finally
              FIsPanning := False;
            end;
            FLastScrollPosition := Point(
              FCanvasHost.HorzScrollBar.Position,
              FCanvasHost.VertScrollBar.Position
            );
            RefreshRulers;
          end;
          FLastPointerPoint := CurrentPointerPoint;
        end;
      tkMoveSelection:
        if Assigned(FSelectionController) and
           FSelectionController.MoveSelectionStep(FDocument, DeltaX, DeltaY) then
        begin
          FLastImagePoint := ImagePoint;
          SyncSelectionOverlayUI(True);
        end;
      tkMovePixels:
        if (DeltaX <> 0) or (DeltaY <> 0) then
        begin
          UpdateMovePixelsTransaction(DeltaX, DeltaY);
          FLastImagePoint := ImagePoint;
        end;
      tkSelectLasso, tkFreeformShape:
        begin
          AppendLassoPoint(ImagePoint);
          FLastImagePoint := ImagePoint;
          RefreshCanvas;
        end;
      tkGradient, tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkSelectRect, tkSelectEllipse, tkCrop, tkMosaic:
        begin
          FShiftConstrain := ssShift in Shift;
          if (FCurrentTool = tkCrop) and (FCropAspectMode > 0) then
            FLastImagePoint := ConstrainCropPoint(FDragStart, ImagePoint)
          else if FShiftConstrain then
            FLastImagePoint := ConstrainShapePoint(FDragStart, ImagePoint, FCurrentTool)
          else
            FLastImagePoint := ImagePoint;
          RefreshCanvas;
        end;
      tkRecolor:
        begin
          ApplyImmediateTool(ImagePoint);
          ExpandStrokeDirty(ImagePoint);
          InvalidatePreparedBitmap;
          RefreshCanvas;
        end;
      tkCloneStamp:
        if FCloneStampSampled then
        begin
          ApplyImmediateTool(ImagePoint);
          ExpandStrokeDirty(ImagePoint);
          InvalidatePreparedBitmap;
          RefreshCanvas;
        end;
    end;
  end;
  if (not FPointerDown) and (FCurrentTool = tkLine) and FLineBezierMode and FLineCurvePending then
  begin
    if FLineCurveSecondStage then
      FLineCurveControlPoint2 := ImagePoint
    else
      FLineCurveControlPoint := ImagePoint;
  end;
  if not FPointerDown or not (FCurrentTool in [tkPencil, tkBrush, tkEraser, tkMoveSelection, tkMovePixels,
    tkGradient, tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkSelectRect, tkSelectEllipse, tkCrop, tkMosaic]) then
    FLastImagePoint := ImagePoint;
  if (not FPointerDown) and Assigned(FPaintBox) and
     (
       PaintToolHasCanvasHoverOverlay(FCurrentTool) or
       ((FCurrentTool = tkLine) and FLineBezierMode and (FLineCurvePending or FLinePathOpen))
     ) then
    FPaintBox.Invalidate;
  if FPointerDown then
  begin
    TickNow := GetTickCount64;
    { Throttle drag-time status relayout to reduce high-frequency UI churn
      on large canvases / older Apple Silicon machines. }
    if (FStatusDragLastUpdateMS = 0) or (TickNow - FStatusDragLastUpdateMS >= 33) then
    begin
      FStatusDragLastUpdateMS := TickNow;
      RefreshStatus(ImagePoint);
    end;
  end
  else
  begin
    FStatusDragLastUpdateMS := 0;
    RefreshStatus(ImagePoint);
  end;
end;

procedure TMainForm.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
  MosaicSelection: TSelectionMask;
begin
  if not FPointerDown then
  begin
    if Assigned(FPaintBox) then
      FPaintBox.MouseCapture := False;
    Exit;
  end;
  if Button = mbMiddle then
    DeactivateTempPan;
  FPointerDown := False;
  if FCurrentTool = tkRecolor then
  begin
    FRecolorStrokeSourceValid := False;
    FreeAndNil(FRecolorStrokeSnapshot);
  end;
  if Assigned(FPaintBox) then
    FPaintBox.MouseCapture := False;
  { Finalise stroke-based region history for painting tools }
  if HasPendingStrokeHistory then
  begin
    CommitStrokeHistory(PaintToolName(FStrokeTool));
  end;
  ImagePoint := CanvasToImage(X, Y);
  { Apply Shift-key constraint for shape tools }
  if (FCurrentTool = tkCrop) and (FCropAspectMode > 0) then
    ImagePoint := ConstrainCropPoint(FDragStart, ImagePoint)
  else if (ssShift in Shift) and (FCurrentTool in [tkLine, tkGradient,
    tkRectangle, tkRoundedRectangle, tkEllipseShape,
    tkSelectRect, tkSelectEllipse, tkCrop]) then
    ImagePoint := ConstrainShapePoint(FDragStart, ImagePoint, FCurrentTool);
  FShiftConstrain := False;
  FLastImagePoint := ImagePoint;

  if FCurrentTool = tkLine then
  begin
    if not FLineCurvePending then
    begin
      if LineReleaseStartsBezier(FLineBezierMode, FDragStart, ImagePoint) then
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
        RefreshCanvas;
      end
      else
      begin
        if FDocument.BeginActiveLayerMutation(PaintToolName(FCurrentTool)) then
        begin
          CommitShapeTool(FDragStart, ImagePoint);
          SyncImageMutationUI(False, True);
        end;
      end;
    end;
    RefreshStatus(ImagePoint);
    Exit;
  end;
  if FCurrentTool in [tkGradient, tkRectangle, tkRoundedRectangle, tkEllipseShape] then
  begin
    if FDocument.BeginActiveLayerMutation(PaintToolName(FCurrentTool)) then
    begin
      CommitShapeTool(FDragStart, ImagePoint);
      SyncImageMutationUI(False, True);
    end;
  end;
  if FCurrentTool = tkCrop then
  begin
    { Commit crop if drag was meaningful }
    if (Abs(ImagePoint.X - FDragStart.X) > 2) and (Abs(ImagePoint.Y - FDragStart.Y) > 2) then
    begin
      if FDocument.BeginDocumentMutation(LocalizedAction('Crop')) then
      begin
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
  end;
  if FCurrentTool = tkMosaic then
  begin
    { Commit mosaic if drag was meaningful }
    if (Abs(ImagePoint.X - FDragStart.X) > 2) and (Abs(ImagePoint.Y - FDragStart.Y) > 2) then
      if FDocument.BeginActiveLayerMutation(LocalizedAction('Mosaic')) then
      begin
      MosaicSelection := nil;
      if FDocument.HasSelection then
        MosaicSelection := FDocument.ActiveSelectionInLayerSpace;
      try
      FDocument.PixelateRect(
        Min(FDragStart.X, ImagePoint.X),
        Min(FDragStart.Y, ImagePoint.Y),
        Max(FDragStart.X, ImagePoint.X),
        Max(FDragStart.Y, ImagePoint.Y),
        FMosaicBlockSize,
        MosaicSelection
      );
      finally
        MosaicSelection.Free;
      end;
      InvalidatePreparedBitmap;
      SyncImageMutationUI(False, True);
      end;
  end;
  if FCurrentTool = tkFreeformShape then
  begin
    AppendLassoPoint(ImagePoint);
    if Length(FLassoPoints) > 1 then
    begin
      if FDocument.BeginActiveLayerMutation(PaintToolName(FCurrentTool)) then
      begin
        CommitShapeTool(FDragStart, ImagePoint);
        SyncImageMutationUI(False, True);
      end;
    end;
    SetLength(FLassoPoints, 0);
    RefreshCanvas;
  end;
  if FCurrentTool = tkSelectRect then
  begin
    if Assigned(FSelectionController) then
      FSelectionController.CommitRectangleSelection(
        FDocument,
        FDragStart,
        ImagePoint,
        FPendingSelectionMode,
        FSelAntiAlias,
        FSelFeather,
        FSelCornerRadius,
        PaintToolName(FCurrentTool)
      )
    else
    begin
      FDocument.PushHistory(PaintToolName(FCurrentTool));
      FDocument.SelectRectangle(
        FDragStart.X,
        FDragStart.Y,
        ImagePoint.X,
        ImagePoint.Y,
        FPendingSelectionMode,
        FSelAntiAlias,
        FSelCornerRadius
      );
    end;
    SyncSelectionOverlayUI(True);
  end;
  if FCurrentTool = tkSelectEllipse then
  begin
    if Assigned(FSelectionController) then
      FSelectionController.CommitEllipseSelection(
        FDocument,
        FDragStart,
        ImagePoint,
        FPendingSelectionMode,
        FSelAntiAlias,
        FSelFeather,
        PaintToolName(FCurrentTool)
      )
    else
    begin
      FDocument.PushHistory(PaintToolName(FCurrentTool));
      FDocument.SelectEllipse(
        FDragStart.X,
        FDragStart.Y,
        ImagePoint.X,
        ImagePoint.Y,
        FPendingSelectionMode,
        FSelAntiAlias
      );
    end;
    SyncSelectionOverlayUI(True);
  end;
  if FCurrentTool = tkSelectLasso then
  begin
    AppendLassoPoint(ImagePoint);
    if Assigned(FSelectionController) then
      FSelectionController.CommitLassoSelection(
        FDocument,
        FLassoPoints,
        FPendingSelectionMode,
        FSelAntiAlias,
        FSelFeather,
        PaintToolName(FCurrentTool)
      )
    else
    begin
      FDocument.PushHistory(PaintToolName(FCurrentTool));
      FDocument.SelectLasso(FLassoPoints, FPendingSelectionMode, FSelAntiAlias);
    end;
    SetLength(FLassoPoints, 0);
    SyncSelectionOverlayUI(True);
  end;
  if FCurrentTool = tkMovePixels then
  begin
    CommitMovePixelsTransaction;
    RefreshTabCardVisuals(FActiveTabIndex);
    RefreshAuxiliaryImageViews(True);
  end;
  FStatusDragLastUpdateMS := 0;
  RefreshStatus(ImagePoint);
end;

procedure TMainForm.PaintBoxMouseLeave(Sender: TObject);
begin
  FLastImagePoint := Point(-1, -1);
  if Assigned(FPaintBox) then
    FPaintBox.Invalidate;
  RefreshStatus(FLastImagePoint);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  RelayoutTopChrome;
  LayoutStatusBarControls(nil);
  ClampPaletteToWorkspace(FToolsPanel);
  ClampPaletteToWorkspace(FColorsPanel);
  ClampPaletteToWorkspace(FHistoryPanel);
  ClampPaletteToWorkspace(FRightPanel);
end;

procedure TMainForm.PlaceTextAtPoint(const AResult: TTextDialogResult;
  APoint: TPoint; AColor: TRGBA32);
var
  TextSurface: TRasterSurface;
  PaintSelection: TSelectionMask;
  LocalPoint: TPoint;
begin
  TextSurface := RenderTextToSurface(AResult, AColor);
  if TextSurface = nil then
    Exit;
  try
    if FDocument.HasSelection then
      PaintSelection := FDocument.Selection
    else
      PaintSelection := nil;
    LocalPoint := ActiveLayerLocalPoint(APoint);
    FDocument.PasteSurfaceToActiveLayer(
      TextSurface,
      LocalPoint.X,
      LocalPoint.Y,
      255,
      PaintSelection
    );
  finally
    TextSurface.Free;
  end;
end;

procedure TMainForm.EmbossClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  BeginStatusProgress(ApplyingActionText('Emboss'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Emboss')) then
      Exit;
    FDocument.Emboss;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Emboss', #$E6#$B5#$AE#$E9#$9B#$95);
  FLastEffectProc := @EmbossClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.SoftenClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  BeginStatusProgress(ApplyingActionText('Soften'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Soften')) then
      Exit;
    FDocument.Soften;
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Soften', #$E6#$9F#$94#$E5#$8C#$96);
  FLastEffectProc := @SoftenClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RenderCloudsClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  BeginStatusProgress(ApplyingActionText('Render Clouds'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Render Clouds')) then
      Exit;
    FDocument.RenderClouds(1);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Render Clouds', #$E4#$BA#$91#$E5#$BD#$A9);
  FLastEffectProc := @RenderCloudsClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.PixelateClick(Sender: TObject);
var
  Val: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  Val := 10;
  if not RunEffectDialog1(Self,
    TR('Pixelate', #$E5#$83#$8F#$E7#$B4#$A0#$E5#$8C#$96),
    TR('Block Size', #$E5#$9D#$97#$E5#$A4#$A7#$E5#$B0#$8F),
    1, 100, 10, Val) then Exit;
  BeginStatusProgress(ApplyingActionText('Pixelate'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Pixelate')) then
      Exit;
    FDocument.Pixelate(Val);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Pixelate', #$E5#$83#$8F#$E7#$B4#$A0#$E5#$8C#$96);
  FLastEffectProc := @PixelateClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.VignetteClick(Sender: TObject);
var
  Val: Integer;
  Strength: Double;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  Val := 50;
  if not RunEffectDialog1(Self,
    TR('Vignette', #$E6#$9A#$97#$E8#$A7#$92),
    TR('Strength', #$E5#$BC#$BA#$E5#$BA#$A6),
    0, 100, 50, Val) then Exit;
  Strength := Val / 100.0;
  BeginStatusProgress(ApplyingActionText('Vignette'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Vignette')) then
      Exit;
    FDocument.Vignette(Strength);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Vignette', #$E6#$9A#$97#$E8#$A7#$92);
  FLastEffectProc := @VignetteClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.MotionBlurClick(Sender: TObject);
var
  AngleVal, DistVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AngleVal := 0;
  DistVal := 10;
  if not RunEffectDialog2(Self, TR('Motion Blur', #$E8#$BF#$90#$E5#$8A#$A8#$E6#$A8#$A1#$E7#$B3#$8A),
    TR('Angle (degrees)', #$E8#$A7#$92#$E5#$BA#$A6#$EF#$BC#$88#$E5#$BA#$A6#$EF#$BC#$89), 0, 359, 0,
    TR('Distance (pixels)', #$E8#$B7#$9D#$E7#$A6#$BB#$EF#$BC#$88#$E5#$83#$8F#$E7#$B4#$A0#$EF#$BC#$89), 1, 100, 10,
    AngleVal, DistVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Motion Blur'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Motion Blur')) then
      Exit;
    FDocument.MotionBlur(AngleVal, DistVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Motion Blur', #$E8#$BF#$90#$E5#$8A#$A8#$E6#$A8#$A1#$E7#$B3#$8A);
  FLastEffectProc := @MotionBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.MedianFilterClick(Sender: TObject);
var
  RadiusVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  RadiusVal := 1;
  if not RunEffectDialog1(Self,
    TR('Median Filter (Denoise)', #$E4#$B8#$AD#$E5#$80#$BC#$E6#$BB#$A4#$E6#$B3#$A2#$EF#$BC#$88#$E9#$99#$8D#$E5#$99#$AA#$EF#$BC#$89),
    TR('Radius', #$E5#$8D#$8A#$E5#$BE#$84),
    1, 2, 1, RadiusVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Median Filter'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Median Filter')) then
      Exit;
    FDocument.MedianFilter(RadiusVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Median Filter', #$E4#$B8#$AD#$E5#$80#$BC#$E6#$BB#$A4#$E6#$B3#$A2);
  FLastEffectProc := @MedianFilterClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.GlowClick(Sender: TObject);
var
  RadVal, IntVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  RadVal := 3;
  IntVal := 80;
  if not RunEffectDialog2(Self, TR('Glow Effect', #$E5#$8F#$91#$E5#$85#$89#$E6#$95#$88#$E6#$9E#$9C),
    TR('Radius', #$E5#$8D#$8A#$E5#$BE#$84), 1, 10, 3,
    TR('Intensity', #$E5#$BC#$BA#$E5#$BA#$A6), 0, 200, 80,
    RadVal, IntVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Glow Effect'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Glow Effect')) then
      Exit;
    FDocument.GlowEffect(RadVal, IntVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Glow Effect', #$E5#$8F#$91#$E5#$85#$89#$E6#$95#$88#$E6#$9E#$9C);
  FLastEffectProc := @GlowClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.OilPaintClick(Sender: TObject);
var
  RadVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  RadVal := 4;
  if not RunEffectDialog1(Self,
    TR('Oil Paint', #$E6#$B2#$B9#$E7#$94#$BB),
    TR('Brush Radius', #$E7#$AC#$94#$E5#$88#$B7#$E5#$8D#$8A#$E5#$BE#$84),
    1, 8, 4, RadVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Oil Paint'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Oil Paint')) then
      Exit;
    FDocument.OilPaint(RadVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Oil Paint', #$E6#$B2#$B9#$E7#$94#$BB);
  FLastEffectProc := @OilPaintClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.FrostedGlassClick(Sender: TObject);
var
  AmtVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AmtVal := 4;
  if not RunEffectDialog1(Self,
    TR('Frosted Glass', #$E7#$A3#$A8#$E7#$A0#$82#$E7#$8E#$BB#$E7#$92#$83),
    TR('Amount', #$E6#$95#$B0#$E9#$87#$8F),
    1, 20, 4, AmtVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Frosted Glass'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Frosted Glass')) then
      Exit;
    FDocument.FrostedGlass(AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Frosted Glass', #$E7#$A3#$A8#$E7#$A0#$82#$E7#$8E#$BB#$E7#$92#$83);
  FLastEffectProc := @FrostedGlassClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.ZoomBlurClick(Sender: TObject);
var
  AmtVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AmtVal := 8;
  if not RunEffectDialog1(Self,
    TR('Zoom Blur', #$E7#$BC#$A9#$E6#$94#$BE#$E6#$A8#$A1#$E7#$B3#$8A),
    TR('Amount', #$E6#$95#$B0#$E9#$87#$8F),
    1, 30, 8, AmtVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Zoom Blur'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Zoom Blur')) then
      Exit;
    FDocument.ZoomBlur(FDocument.Width div 2, FDocument.Height div 2, AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Zoom Blur', #$E7#$BC#$A9#$E6#$94#$BE#$E6#$A8#$A1#$E7#$B3#$8A);
  FLastEffectProc := @ZoomBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.GaussianBlurClick(Sender: TObject);
var
  RadVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  RadVal := 3;
  if not RunEffectDialog1(Self,
    TR('Gaussian Blur', #$E9#$AB#$98#$E6#$96#$AF#$E6#$A8#$A1#$E7#$B3#$8A),
    TR('Radius', #$E5#$8D#$8A#$E5#$BE#$84),
    1, 30, 3, RadVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Gaussian Blur'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Gaussian Blur')) then
      Exit;
    FDocument.GaussianBlur(RadVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Gaussian Blur', #$E9#$AB#$98#$E6#$96#$AF#$E6#$A8#$A1#$E7#$B3#$8A);
  FLastEffectProc := @GaussianBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.UnfocusClick(Sender: TObject);
var
  RadiusValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  RadiusValue := 4;
  if not RunEffectDialog1(Self,
    TR('Unfocus', #$E5#$A4#$B1#$E7#$84#$A6),
    TR('Radius', #$E5#$8D#$8A#$E5#$BE#$84),
    1, 24, 4, RadiusValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Unfocus'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Unfocus')) then
      Exit;
    FDocument.Unfocus(RadiusValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Unfocus', #$E5#$A4#$B1#$E7#$84#$A6);
  FLastEffectProc := @UnfocusClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.SurfaceBlurClick(Sender: TObject);
var
  RadiusValue: Integer;
  ThresholdValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  RadiusValue := 3;
  ThresholdValue := 24;
  if not RunEffectDialog2(Self, TR('Surface Blur', #$E8#$A1#$A8#$E9#$9D#$A2#$E6#$A8#$A1#$E7#$B3#$8A),
    TR('Radius', #$E5#$8D#$8A#$E5#$BE#$84), 1, 24, 3,
    TR('Edge Threshold', #$E8#$BE#$B9#$E7#$BC#$98#$E9#$98#$88#$E5#$80#$BC), 0, 255, 24,
    RadiusValue, ThresholdValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Surface Blur'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Surface Blur')) then
      Exit;
    FDocument.SurfaceBlur(RadiusValue, ThresholdValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Surface Blur', #$E8#$A1#$A8#$E9#$9D#$A2#$E6#$A8#$A1#$E7#$B3#$8A);
  FLastEffectProc := @SurfaceBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RadialBlurClick(Sender: TObject);
var
  AmtVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AmtVal := 15;
  if not RunEffectDialog1(Self,
    TR('Radial Blur', #$E5#$BE#$84#$E5#$90#$91#$E6#$A8#$A1#$E7#$B3#$8A),
    TR('Sweep Angle (degrees)', #$E6#$89#$AB#$E6#$8E#$A0#$E8#$A7#$92#$E5#$BA#$A6#$EF#$BC#$88#$E5#$BA#$A6#$EF#$BC#$89),
    1, 60, 15, AmtVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Radial Blur'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Radial Blur')) then
      Exit;
    FDocument.RadialBlur(AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Radial Blur', #$E5#$BE#$84#$E5#$90#$91#$E6#$A8#$A1#$E7#$B3#$8A);
  FLastEffectProc := @RadialBlurClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.TwistClick(Sender: TObject);
var
  AmtVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AmtVal := 90;
  if not RunEffectDialog1(Self,
    TR('Twist', #$E6#$89#$AD#$E6#$9B#$B2),
    TR('Angle (degrees)', #$E8#$A7#$92#$E5#$BA#$A6#$EF#$BC#$88#$E5#$BA#$A6#$EF#$BC#$89),
    -360, 360, 90, AmtVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Twist'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Twist')) then
      Exit;
    FDocument.Twist(AmtVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Twist', #$E6#$89#$AD#$E6#$9B#$B2);
  FLastEffectProc := @TwistClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.FragmentClick(Sender: TObject);
var
  OffVal: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  OffVal := 8;
  if not RunEffectDialog1(Self,
    TR('Fragment', #$E7#$A2#$8E#$E7#$89#$87),
    TR('Offset (pixels)', #$E5#$81#$8F#$E7#$A7#$BB#$EF#$BC#$88#$E5#$83#$8F#$E7#$B4#$A0#$EF#$BC#$89),
    1, 40, 8, OffVal) then Exit;
  BeginStatusProgress(ApplyingActionText('Fragment'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Fragment')) then
      Exit;
    FDocument.Fragment(OffVal);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Fragment', #$E7#$A2#$8E#$E7#$89#$87);
  FLastEffectProc := @FragmentClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.BulgeClick(Sender: TObject);
var
  AmountValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AmountValue := 50;
  if not RunEffectDialog1(Self,
    TR('Bulge', #$E8#$86#$A8#$E8#$83#$80),
    TR('Strength', #$E5#$BC#$BA#$E5#$BA#$A6),
    1, 100, 50, AmountValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Bulge'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Bulge')) then
      Exit;
    FDocument.Bulge(AmountValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Bulge', #$E8#$86#$A8#$E8#$83#$80);
  FLastEffectProc := @BulgeClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.DentsClick(Sender: TObject);
var
  AmountValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AmountValue := 50;
  if not RunEffectDialog1(Self,
    TR('Dents', #$E5#$87#$B9#$E9#$99#$B7),
    TR('Strength', #$E5#$BC#$BA#$E5#$BA#$A6),
    1, 100, 50, AmountValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Dents'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Dents')) then
      Exit;
    FDocument.Dents(AmountValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Dents', #$E5#$87#$B9#$E9#$99#$B7);
  FLastEffectProc := @DentsClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.ReliefClick(Sender: TObject);
var
  AngleValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  AngleValue := 45;
  if not RunEffectDialog1(Self,
    TR('Relief', #$E6#$B5#$AE#$E9#$9B#$95#$E6#$95#$88#$E6#$9E#$9C),
    TR('Light Angle (degrees)', #$E5#$85#$89#$E7#$85#$A7#$E8#$A7#$92#$E5#$BA#$A6#$EF#$BC#$88#$E5#$BA#$A6#$EF#$BC#$89),
    0, 359, 45, AngleValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Relief'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Relief')) then
      Exit;
    FDocument.Relief(AngleValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Relief', #$E6#$B5#$AE#$E9#$9B#$95#$E6#$95#$88#$E6#$9E#$9C);
  FLastEffectProc := @ReliefClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RedEyeClick(Sender: TObject);
var
  ThresholdValue: Integer;
  StrengthValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  ThresholdValue := 48;
  StrengthValue := 100;
  if not RunEffectDialog2(Self, TR('Red Eye', #$E7#$BA#$A2#$E7#$9C#$BC),
    TR('Red Threshold', #$E7#$BA#$A2#$E8#$89#$B2#$E9#$98#$88#$E5#$80#$BC), 0, 255, 48,
    TR('Reduction Strength', #$E4#$BF#$AE#$E6#$AD#$A3#$E5#$BC#$BA#$E5#$BA#$A6), 0, 100, 100,
    ThresholdValue, StrengthValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Red Eye'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Red Eye')) then
      Exit;
    FDocument.RedEye(ThresholdValue, StrengthValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Red Eye', #$E7#$BA#$A2#$E7#$9C#$BC);
  FLastEffectProc := @RedEyeClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.TileReflectionClick(Sender: TObject);
var
  TileValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  TileValue := 32;
  if not RunEffectDialog1(Self,
    TR('Tile Reflection', #$E7#$93#$B7#$E7#$A0#$96#$E5#$8F#$8D#$E5#$B0#$84),
    TR('Tile Size (pixels)', #$E7#$93#$B7#$E7#$A0#$96#$E5#$A4#$A7#$E5#$B0#$8F#$EF#$BC#$88#$E5#$83#$8F#$E7#$B4#$A0#$EF#$BC#$89),
    2, 256, 32, TileValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Tile Reflection'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Tile Reflection')) then
      Exit;
    FDocument.TileReflection(TileValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Tile Reflection', #$E7#$93#$B7#$E7#$A0#$96#$E5#$8F#$8D#$E5#$B0#$84);
  FLastEffectProc := @TileReflectionClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.CrystallizeClick(Sender: TObject);
var
  CellValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  CellValue := 24;
  if not RunEffectDialog1(Self,
    TR('Crystallize', #$E6#$99#$B6#$E6#$A0#$BC#$E5#$8C#$96),
    TR('Cell Size (pixels)', #$E6#$99#$B6#$E6#$A0#$BC#$E5#$A4#$A7#$E5#$B0#$8F#$EF#$BC#$88#$E5#$83#$8F#$E7#$B4#$A0#$EF#$BC#$89),
    2, 128, 24, CellValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Crystallize'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Crystallize')) then
      Exit;
    FDocument.Crystallize(CellValue, 1);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Crystallize', #$E6#$99#$B6#$E6#$A0#$BC#$E5#$8C#$96);
  FLastEffectProc := @CrystallizeClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.InkSketchClick(Sender: TObject);
var
  InkValue: Integer;
  ColorValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  InkValue := 100;
  ColorValue := 45;
  if not RunEffectDialog2(Self, TR('Ink Sketch', #$E5#$A2#$A8#$E6#$B0#$B4#$E7#$B4#$A0#$E6#$8F#$8F),
    TR('Ink Strength', #$E5#$A2#$A8#$E7#$BA#$BF#$E5#$BC#$BA#$E5#$BA#$A6), 0, 200, 100,
    TR('Color Retention', #$E9#$A2#$9C#$E8#$89#$B2#$E4#$BF#$9D#$E7#$95#$99), 0, 100, 45,
    InkValue, ColorValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Ink Sketch'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Ink Sketch')) then
      Exit;
    FDocument.InkSketch(InkValue, ColorValue);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Ink Sketch', #$E5#$A2#$A8#$E6#$B0#$B4#$E7#$B4#$A0#$E6#$8F#$8F);
  FLastEffectProc := @InkSketchClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.MandelbrotClick(Sender: TObject);
var
  IterationValue: Integer;
  ZoomValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  IterationValue := 64;
  ZoomValue := 100;
  if not RunEffectDialog2(Self, TR('Mandelbrot Fractal', 'Mandelbrot '#$E5#$88#$86#$E5#$BD#$A2),
    TR('Iterations', #$E8#$BF#$AD#$E4#$BB#$A3#$E6#$AC#$A1#$E6#$95#$B0), 8, 512, 64,
    TR('Zoom Percent', #$E7#$BC#$A9#$E6#$94#$BE#$E7#$99#$BE#$E5#$88#$86#$E6#$AF#$94), 25, 400, 100,
    IterationValue, ZoomValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Mandelbrot Fractal'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Mandelbrot Fractal')) then
      Exit;
    FDocument.RenderMandelbrot(IterationValue, ZoomValue / 100.0);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Mandelbrot Fractal', 'Mandelbrot '#$E5#$88#$86#$E5#$BD#$A2);
  FLastEffectProc := @MandelbrotClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.JuliaClick(Sender: TObject);
var
  IterationValue: Integer;
  ZoomValue: Integer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then Exit;
  IterationValue := 64;
  ZoomValue := 100;
  if not RunEffectDialog2(Self, TR('Julia Fractal', 'Julia '#$E5#$88#$86#$E5#$BD#$A2),
    TR('Iterations', #$E8#$BF#$AD#$E4#$BB#$A3#$E6#$AC#$A1#$E6#$95#$B0), 8, 512, 64,
    TR('Zoom Percent', #$E7#$BC#$A9#$E6#$94#$BE#$E7#$99#$BE#$E5#$88#$86#$E6#$AF#$94), 25, 400, 100,
    IterationValue, ZoomValue) then Exit;
  BeginStatusProgress(ApplyingActionText('Julia Fractal'));
  try
    if not FDocument.BeginActiveLayerMutation(LocalizedAction('Julia Fractal')) then
      Exit;
    FDocument.RenderJulia(IterationValue, ZoomValue / 100.0);
    SyncImageMutationUI;
  finally
    EndStatusProgress;
  end;
  FLastEffectCaption := TR('Julia Fractal', 'Julia '#$E5#$88#$86#$E5#$BD#$A2);
  FLastEffectProc := @JuliaClick;
  if Assigned(FRepeatLastEffectItem) then
  begin
    FRepeatLastEffectItem.Caption := TR('Repeat: ', '重复：') + FLastEffectCaption;
    FRepeatLastEffectItem.Enabled := True;
  end;
end;

procedure TMainForm.RepeatLastEffectClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if Assigned(FLastEffectProc) then
    FLastEffectProc(Sender);
end;

procedure TMainForm.LayerPropertiesClick(Sender: TObject);
var
  DialogResult: TLayerPropertiesResult;
  Layer: TRasterLayer;
begin
  SealPendingStrokeHistory;
  if FDocument.LayerCount = 0 then
    Exit;
  Layer := FDocument.ActiveLayer;
  DialogResult.Name := Layer.Name;
  DialogResult.Visible := Layer.Visible;
  DialogResult.Opacity := Layer.Opacity;
  DialogResult.BlendMode := Layer.BlendMode;
  if not RunLayerPropertiesDialog(Self, DialogResult) then
    Exit;
  FDocument.PushHistory(LocalizedAction('Layer Properties'));
  Layer.Name := DialogResult.Name;
  Layer.Visible := DialogResult.Visible;
  Layer.Opacity := DialogResult.Opacity;
  Layer.BlendMode := DialogResult.BlendMode;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.PasteSelectionClick(Sender: TObject);
begin
  SealPendingStrokeHistory;
  if not FDocument.HasStoredSelection then
    Exit;
  FDocument.PasteStoredSelection;
  SyncImageMutationUI(True, True);
end;

procedure TMainForm.LayerBlendModeChanged(Sender: TObject);
var
  NewMode: TBlendMode;
begin
  SealPendingStrokeHistory;
  if FUpdatingLayerControls then
    Exit;
  if not Assigned(FLayerBlendCombo) then
    Exit;
  if FDocument.LayerCount = 0 then
    Exit;
  if (FLayerBlendCombo.ItemIndex < 0) or
     (FLayerBlendCombo.ItemIndex > Ord(High(TBlendMode))) then
    Exit;
  NewMode := TBlendMode(FLayerBlendCombo.ItemIndex);
  if FDocument.ActiveLayer.BlendMode = NewMode then
    Exit;
  FDocument.PushHistory(LocalizedAction('Layer Blend Mode'));
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
  if RunSystemTextFontDialog then
  begin
    UpdateInlineTextEditStyle;
    UpdateInlineTextEditBounds;
  end;
end;

procedure TMainForm.InlineTextEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and ((ssMeta in Shift) or (ssCtrl in Shift)) then
  begin
    CommitInlineTextEdit(True);
    Key := 0;
    Exit;
  end;
  case Key of
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
    Exit(TR('Untitled', '未命名'));
  if FTabFileNames[AIndex] = '' then
    N := TR('Untitled', '未命名')
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
  SealPendingStrokeHistory;
  CancelMovePixelsTransaction;
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

  InvalidateSelectionMarqueeCache;
  InvalidatePreparedBitmap;
  RefreshTabStrip;
  UpdateCaption;
end;

procedure TMainForm.SwitchToTab(AIndex: Integer);
begin
  if AIndex = FActiveTabIndex then Exit;
  if (AIndex < 0) or (AIndex >= Length(FTabDocuments)) then Exit;
  SealPendingStrokeHistory;
  CancelMovePixelsTransaction;
  CommitInlineTextEdit(True);

  { Save current state }
  FTabFileNames[FActiveTabIndex] := FCurrentFileName;
  FTabDirtyFlags[FActiveTabIndex] := FDirty;

  FActiveTabIndex := AIndex;
  FDocument := FTabDocuments[FActiveTabIndex];
  FCurrentFileName := FTabFileNames[FActiveTabIndex];
  FDirty := FTabDirtyFlags[FActiveTabIndex];

  { Reset transient tool state that doesn't belong to the new document }
  FreeAndNil(FCloneStampSnapshot);
  FCloneStampSampled := False;
  FCloneAlignedOffsetValid := False;
  FreeAndNil(FRecolorStrokeSnapshot);
  FRecolorStrokeSourceValid := False;
  SetLength(FLassoPoints, 0);
  ResetLineCurveState;

  InvalidateSelectionMarqueeCache;
  InvalidatePreparedBitmap;
  FLastImagePoint := Point(-1, -1);
  FPointerDown := False;
  FitDocumentToViewport(False);
  FCenterOnNextCanvasUpdate := True;
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
  if AIndex = FActiveTabIndex then
    SealPendingStrokeHistory;
  CancelMovePixelsTransaction;
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
  FCenterOnNextCanvasUpdate := True;
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
      CloseBtn.Caption := '×';
      CloseBtn.Margin := 0;
      CloseBtn.Tag := I;
      CloseBtn.ParentFont := False;
      CloseBtn.Font.Size := 9;
      CloseBtn.Font.Color := ChromeTextColor;
      CloseBtn.OnClick := @TabCloseButtonClick;
      CloseBtn.Hint := TR('Close document', '关闭文档');
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
    AddBtn.Caption := '+';
    AddBtn.Margin := 0;
    AddBtn.ParentFont := False;
    AddBtn.Font.Size := 13;
    AddBtn.Font.Color := ChromeTextColor;
    AddBtn.Hint := TR('New document', '新建文档');
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
  Choice: Integer;
begin
  if not (Sender is TControl) then Exit;
  Idx := TControl(Sender).Tag;
  if (Idx < 0) or (Idx >= Length(FTabDocuments)) then Exit;
  if FTabDirtyFlags[Idx] then
  begin
    Choice := MessageDlg(TR('Save Changes', #$E4#$BF#$9D#$E5#$AD#$98#$E6#$9B#$B4#$E6#$94#$B9),
      Format(TR('Do you want to save changes to "%s"?',
        #$E6#$98#$AF#$E5#$90#$A6#$E4#$BF#$9D#$E5#$AD#$98#$E5#$AF#$B9' "%s" '#$E7#$9A#$84#$E6#$9B#$B4#$E6#$94#$B9#$EF#$BC#$9F),
        [TabDocumentDisplayName(Idx)]),
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    case Choice of
      mrYes:
        begin
          { Switch to the tab so Save works on it }
          SwitchToTab(Idx);
          SaveDocumentClick(nil);
          if FDirty then Exit; { Save cancelled }
        end;
      mrNo: ; { Discard }
    else
      Exit; { Cancel }
    end;
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
  Choice: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  Popup := TMenuItem(Sender).GetParentMenu as TPopupMenu;
  if Assigned(Popup) and Assigned(Popup.PopupComponent) then
  begin
    Idx := Popup.PopupComponent.Tag;
    if (Idx < 0) or (Idx >= Length(FTabDocuments)) then Exit;
    if FTabDirtyFlags[Idx] then
    begin
      Choice := MessageDlg(TR('Save Changes', #$E4#$BF#$9D#$E5#$AD#$98#$E6#$9B#$B4#$E6#$94#$B9),
        Format(TR('Do you want to save changes to "%s"?',
          #$E6#$98#$AF#$E5#$90#$A6#$E4#$BF#$9D#$E5#$AD#$98#$E5#$AF#$B9' "%s" '#$E7#$9A#$84#$E6#$9B#$B4#$E6#$94#$B9#$EF#$BC#$9F),
          [TabDocumentDisplayName(Idx)]),
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      case Choice of
        mrYes:
          begin
            SwitchToTab(Idx);
            SaveDocumentClick(nil);
            if FDirty then Exit;
          end;
        mrNo: ;
      else
        Exit;
      end;
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
        if MessageDlg(TR('Close Document', '关闭文档'),
          Format(TR('Discard unsaved changes to "%s"?', '放弃对“%s”的未保存更改？'), [TabDocumentDisplayName(I)]),
          mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Continue;
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
        if MessageDlg(TR('Close Document', '关闭文档'),
          Format(TR('Discard unsaved changes to "%s"?', '放弃对“%s”的未保存更改？'), [TabDocumentDisplayName(I)]),
          mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Continue;
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
      MessageDlg(TR('Open', '打开'), TR('Open failed: ', '打开失败：') + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.OpenFileInCurrentTab(const AFileName: string);
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
    end
    else if TryLoadDocumentFromFile(ResolvedFileName, LoadedDocument) then
      { loaded }
    else
    begin
      LoadedDocument := TImageDocument.Create(1, 1);
      Surface := LoadSurfaceFromFile(ResolvedFileName);
      try
        LoadedDocument.ReplaceWithSingleLayer(Surface, ExtractFileName(ResolvedFileName));
      finally
        Surface.Free;
      end;
    end;
    { Replace current tab's document in-place }
    FDocument.Free;
    FDocument := LoadedDocument;
    FTabDocuments[FActiveTabIndex] := FDocument;
    FCurrentFileName := ResolvedFileName;
    FTabFileNames[FActiveTabIndex] := ResolvedFileName;
    FTabDirtyFlags[FActiveTabIndex] := False;
    FDirty := False;
    RegisterRecentFile(ResolvedFileName);
    ResetTransientCanvasState;
    SyncDocumentReplacementUI(False);
    RefreshTabStrip;
    UpdateCaption;
  except
    on E: Exception do
      MessageDlg(TR('Open', '打开'), TR('Open failed: ', '打开失败：') + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  I: Integer;
  FirstInCurrent: Boolean;
begin
  if Length(FileNames) = 0 then
    Exit;
  { First file: open in current tab if it is an untouched new document }
  FirstInCurrent := (FCurrentFileName = '') and (not FDirty);
  if FirstInCurrent then
    OpenFileInCurrentTab(FileNames[0])
  else
    OpenFileInNewTab(FileNames[0]);
  { Remaining files always open in new tabs }
  for I := 1 to High(FileNames) do
    OpenFileInNewTab(FileNames[I]);
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
  SealPendingStrokeHistory;
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

procedure TMainForm.ShapeLineStyleComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FShapeLineStyleCombo) then Exit;
  FShapeLineStyle := EnsureRange(FShapeLineStyleCombo.ItemIndex, 0, 1);
  RefreshCanvas;
end;

procedure TMainForm.LineBezierChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FLineBezierCheck) then Exit;
  FLineBezierMode := FLineBezierCheck.Checked;
  if not FLineBezierMode then
    ResetLineCurveState;
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
      FRecolorTolerance := EnsureRange(FFillTolSpin.Value, 0, 255);
  else
    FFillTolerance := EnsureRange(FFillTolSpin.Value, 0, 255);
  end;
  RefreshCanvas;
end;

procedure TMainForm.GradientTypeComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FGradientTypeCombo) then Exit;
  FGradientType := EnsureRange(FGradientTypeCombo.ItemIndex, 0, 3);
  RefreshCanvas;
end;

procedure TMainForm.GradientRepeatComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FGradientRepeatCombo) then Exit;
  FGradientRepeatMode := EnsureRange(FGradientRepeatCombo.ItemIndex, 0, 2);
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

procedure TMainForm.CloneSampleComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FCloneSampleCombo) then Exit;
  FCloneSampleSource := EnsureRange(FCloneSampleCombo.ItemIndex, 0, 1);
  RefreshCanvas;
end;

procedure TMainForm.RecolorPreserveValueChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FRecolorPreserveValueCheck) then Exit;
  FRecolorPreserveValue := FRecolorPreserveValueCheck.Checked;
  RefreshCanvas;
end;

procedure TMainForm.RecolorContiguousChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FRecolorContiguousCheck) then Exit;
  FRecolorContiguous := FRecolorContiguousCheck.Checked;
  RefreshCanvas;
end;

procedure TMainForm.RecolorSamplingModeChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FRecolorSamplingCombo) then Exit;
  case EnsureRange(FRecolorSamplingCombo.ItemIndex, 0, 2) of
    0: FRecolorSamplingMode := rsmOnce;
    1: FRecolorSamplingMode := rsmContinuous;
  else
    FRecolorSamplingMode := rsmSwatchCompat;
  end;
  FRecolorStrokeSourceValid := False;
  RefreshCanvas;
end;

procedure TMainForm.RecolorModeChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FRecolorModeCombo) then Exit;
  case EnsureRange(FRecolorModeCombo.ItemIndex, 0, 4) of
    0: FRecolorBlendMode := rbmColor;
    1: FRecolorBlendMode := rbmHue;
    2: FRecolorBlendMode := rbmSaturation;
    3: FRecolorBlendMode := rbmLuminosity;
  else
    FRecolorBlendMode := rbmReplaceRGBCompat;
  end;
  RefreshCanvas;
end;

procedure TMainForm.MosaicBlockSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FMosaicBlockSpin) then Exit;
  FMosaicBlockSize := EnsureRange(FMosaicBlockSpin.Value, 2, 64);
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

procedure TMainForm.SelCornerRadiusSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FSelCornerRadiusSpin) then Exit;
  FSelCornerRadius := EnsureRange(FSelCornerRadiusSpin.Value, 0, 500);
  RefreshCanvas;
end;

procedure TMainForm.CropAspectComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FCropAspectCombo) then Exit;
  FCropAspectMode := EnsureRange(FCropAspectCombo.ItemIndex, 0, 4);
  RefreshCanvas;
end;

procedure TMainForm.CropGuideComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FCropGuideCombo) then Exit;
  FCropGuideMode := EnsureRange(FCropGuideCombo.ItemIndex, 0, 2);
  RefreshCanvas;
end;

procedure TMainForm.RoundedRadiusSpinChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FRoundedRadiusSpin) then Exit;
  FRoundedCornerRadius := EnsureRange(FRoundedRadiusSpin.Value, 1, 1024);
  RefreshCanvas;
end;

procedure TMainForm.TextAlignComboChanged(Sender: TObject);
begin
  if FUpdatingToolOption then Exit;
  if not Assigned(FTextAlignCombo) then Exit;
  FTextLastResult.Alignment := EnsureRange(FTextAlignCombo.ItemIndex, 0, 2);
  if Assigned(FInlineTextEdit) and FInlineTextEdit.Visible then
  begin
    UpdateInlineTextEditStyle;
    UpdateInlineTextEditBounds;
  end;
  RefreshCanvas;
end;

{ ── Layer Rotate / Zoom ──────────────────────────────────────────────────── }

procedure TMainForm.LayerRotateZoomClick(Sender: TObject);
var
  Choice: Integer;
begin
  if FDocument.LayerCount = 0 then Exit;
  if FDocument.ActiveLayer.Locked then
    Exit;
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
  if Choice = mrCancel then
    Exit;
  if not FDocument.BeginActiveLayerMutation(LocalizedAction('Rotate Layer')) then
    Exit;
  case Choice of
    mrYes:
      FDocument.RotateActiveLayer90Clockwise;
    mrNo:
      FDocument.RotateActiveLayer90CounterClockwise;
    mrOK:
      FDocument.RotateActiveLayer180;
  end;
  SyncImageMutationUI;
end;

end.
