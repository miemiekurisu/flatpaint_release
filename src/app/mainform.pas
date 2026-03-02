unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, Spin, Types, Clipbrd, FPColor, FPSurface, FPDocument, FPSelection,
  FPPaletteHelpers, FPRulerHelpers, FPTextDialog;

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
    FStatusBar: TStatusBar;
    FStatusZoomOutButton: TButton;
    FStatusZoomInButton: TButton;
    FStatusZoomTrack: TTrackBar;
    FStatusZoomLabel: TLabel;
    FLayerList: TListBox;
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
    FUpdatingTabs: Boolean;
    { Colors panel RGBA }
    FColorRSpin: TSpinEdit;
    FColorGSpin: TSpinEdit;
    FColorBSpin: TSpinEdit;
    FColorASpin: TSpinEdit;
    FColorHexEdit: TEdit;
    FUpdatingColorSpins: Boolean;
    { Tool options — opacity and selection mode }
    FOpacitySpin: TSpinEdit;
    FOpacityLabel: TLabel;
    FBrushOpacity: Integer;
    FSelModeCombo: TComboBox;
    FSelModeLabel: TLabel;
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
    procedure EmbossClick(Sender: TObject);
    procedure SoftenClick(Sender: TObject);
    procedure RenderCloudsClick(Sender: TObject);
    procedure RepeatLastEffectClick(Sender: TObject);
    procedure LayerPropertiesClick(Sender: TObject);
    procedure PasteSelectionClick(Sender: TObject);
    procedure LayerBlendModeChanged(Sender: TObject);
    procedure PlaceTextAtPoint(const AResult: TTextDialogResult; APoint: TPoint; AColor: TRGBA32);
    { Document tab management }
    procedure TabButtonClick(Sender: TObject);
    procedure TabCloseButtonClick(Sender: TObject);
    procedure AddDocumentTab(ADoc: TImageDocument; const AFileName: string;
      ADirty: Boolean = False);
    procedure CloseDocumentTab(AIndex: Integer);
    procedure SwitchToTab(AIndex: Integer);
    procedure RefreshTabStrip;
    function TabDocumentDisplayName(AIndex: Integer): string;
    procedure OpenFileInNewTab(const AFileName: string);
    { Colors panel RGBA controls }
    procedure UpdateColorSpins;
    procedure ColorSpinChanged(Sender: TObject);
    procedure ColorHexChanged(Sender: TObject);
    { Tool option handlers }
    procedure OpacitySpinChanged(Sender: TObject);
    procedure SelModeComboChanged(Sender: TObject);
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
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
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
  FPTextRenderer, FPLayerPropertiesDialog;

const
  DisplayDPI = 96.0;

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
  StatusPanel: TStatusPanel;
begin
  inherited Create(TheOwner);
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

  FStatusBar := TStatusBar.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.Align := alBottom;
  FStatusBar.SimplePanel := False;
  FStatusBar.Height := 24;
  FStatusBar.Color := $00EFEFEF;
  FStatusBar.ParentColor := False;
  FStatusBar.OnResize := @LayoutStatusBarControls;

  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 280;
  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 210;
  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 200;
  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 170;
  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 96;
  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 80;
  StatusPanel := FStatusBar.Panels.Add;
  StatusPanel.Width := 190;

  FStatusZoomOutButton := TButton.Create(FStatusBar);
  FStatusZoomOutButton.Parent := FStatusBar;
  FStatusZoomOutButton.Caption := '-';
  FStatusZoomOutButton.OnClick := @ZoomOutClick;
  FStatusZoomOutButton.Visible := False;

  FStatusZoomInButton := TButton.Create(FStatusBar);
  FStatusZoomInButton.Parent := FStatusBar;
  FStatusZoomInButton.Caption := '+';
  FStatusZoomInButton.OnClick := @ZoomInClick;
  FStatusZoomInButton.Visible := False;

  FStatusZoomTrack := TTrackBar.Create(FStatusBar);
  FStatusZoomTrack.Parent := FStatusBar;
  FStatusZoomTrack.Min := ZoomSliderMin;
  FStatusZoomTrack.Max := ZoomSliderMax;
  FStatusZoomTrack.TickStyle := tsNone;
  FStatusZoomTrack.LineSize := 1;
  FStatusZoomTrack.PageSize := 1;
  FStatusZoomTrack.OnChange := @StatusZoomTrackChange;

  FStatusZoomLabel := TLabel.Create(FStatusBar);
  FStatusZoomLabel.Parent := FStatusBar;
  FStatusZoomLabel.Alignment := taCenter;
  FStatusZoomLabel.Layout := tlCenter;
  FStatusZoomLabel.Transparent := True;
  FStatusZoomLabel.Cursor := crHandPoint;
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
  Application.AddOnIdleHandler(@AppIdle);
end;

destructor TMainForm.Destroy;
var
  I: Integer;
begin
  Application.RemoveOnIdleHandler(@AppIdle);
  FRecentFiles.Free;
  FPreparedBitmap.Free;
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
  for Y := 0 to CompositeSurface.Height - 1 do
  begin
    for X := 0 to CompositeSurface.Width - 1 do
    begin
      if ((X div 8) + (Y div 8)) mod 2 = 0 then
        TileColor := RGBA(214, 214, 214, 255)
      else
        TileColor := RGBA(245, 245, 245, 255);
      PixelColor := CompositeSurface[X, Y];
      if PixelColor.A = 0 then
        CompositeSurface[X, Y] := TileColor
      else if PixelColor.A < 255 then
        CompositeSurface[X, Y] := BlendNormal(PixelColor, TileColor, 255);
    end;
  end;
  if FDocument.HasSelection then
    for Y := 0 to CompositeSurface.Height - 1 do
      for X := 0 to CompositeSurface.Width - 1 do
        if FDocument.Selection[X, Y] and
           (
             (not FDocument.Selection[X - 1, Y]) or
             (not FDocument.Selection[X + 1, Y]) or
             (not FDocument.Selection[X, Y - 1]) or
             (not FDocument.Selection[X, Y + 1])
           ) then
          if ((X + Y) and 1) = 0 then
            CompositeSurface[X, Y] := RGBA(0, 0, 0, 255)
          else
            CompositeSurface[X, Y] := RGBA(255, 255, 255, 255);
  Result := CompositeSurface;
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
begin
  if not Assigned(FBrushSpin) or not Assigned(FOptionLabel) then
    Exit;

  IsSelTool := FCurrentTool in [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand];
  IsOpacityTool := FCurrentTool in [tkPencil, tkBrush, tkEraser, tkCloneStamp, tkRecolor];
  IsSizeTool := FCurrentTool in [tkPencil, tkBrush, tkEraser, tkLine,
    tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape,
    tkCloneStamp, tkRecolor, tkMagicWand];

  if Assigned(FSelModeLabel) then FSelModeLabel.Visible := IsSelTool;
  if Assigned(FSelModeCombo) then FSelModeCombo.Visible := IsSelTool;
  if Assigned(FOpacityLabel) then FOpacityLabel.Visible := IsOpacityTool;
  if Assigned(FOpacitySpin) then FOpacitySpin.Visible := IsOpacityTool;
  if Assigned(FOpacitySpin) then FOpacitySpin.Value := FBrushOpacity;

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
  CreateMenuItem(EditMenu, 'Paste &Selection', @PasteSelectionClick);
  CreateMenuItem(EditMenu, 'Select &All', @SelectAllClick, ShortCut(VK_A, [ssMeta]));
  CreateMenuItem(EditMenu, '&Deselect', @DeselectClick, ShortCut(VK_D, [ssMeta]));
  CreateMenuItem(EditMenu, '&Invert Selection', @InvertSelectionClick, ShortCut(VK_I, [ssMeta, ssShift]));
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
  CreateMenuItem(ImageMenu, '&Flatten', @FlattenClick);

  ViewMenu := TMenuItem.Create(FMainMenu);
  ViewMenu.Caption := '&View';
  FMainMenu.Items.Add(ViewMenu);
  CreateMenuItem(ViewMenu, 'Zoom &In', @ZoomInClick, ShortCut(Ord('='), [ssMeta]));
  CreateMenuItem(ViewMenu, 'Zoom &Out', @ZoomOutClick, ShortCut(Ord('-'), [ssMeta]));
  CreateMenuItem(ViewMenu, 'Zoom to &Selection', @ZoomToSelectionClick);
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
  CreateMenuItem(EffectsMenu, '&Outline', @OutlineClick);
  CreateMenuItem(EffectsMenu, '-', nil);
  CreateMenuItem(EffectsMenu, '&Emboss', @EmbossClick);
  CreateMenuItem(EffectsMenu, 'S&often', @SoftenClick);
  CreateMenuItem(EffectsMenu, 'Render &Clouds', @RenderCloudsClick);

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

  Btn := CreateButton('New', 10, 8, 52, @NewDocumentClick, FTopPanel);   Btn.Hint := 'New document (Ctrl+N)';
  Btn := CreateButton('Open', 66, 8, 52, @OpenDocumentClick, FTopPanel);  Btn.Hint := 'Open document (Ctrl+O)';
  Btn := CreateButton('Save', 122, 8, 52, @SaveDocumentClick, FTopPanel); Btn.Hint := 'Save document (Ctrl+S)';
  Btn := CreateButton('Print', 178, 8, 56, @PrintDocumentClick, FTopPanel); Btn.Hint := 'Print (Ctrl+P)';
  Btn := CreateButton('Cut', 238, 8, 48, @CutClick, FTopPanel);   Btn.Hint := 'Cut selection (Ctrl+X)';
  Btn := CreateButton('Copy', 290, 8, 52, @CopyClick, FTopPanel);  Btn.Hint := 'Copy selection (Ctrl+C)';
  Btn := CreateButton('Paste', 346, 8, 52, @PasteClick, FTopPanel); Btn.Hint := 'Paste (Ctrl+V)';
  Btn := CreateButton('Crop', 402, 8, 50, @CropToSelectionClick, FTopPanel); Btn.Hint := 'Crop canvas to selection';
  Btn := CreateButton('Desel', 456, 8, 56, @DeselectClick, FTopPanel); Btn.Hint := 'Deselect all (Ctrl+D)';
  Btn := CreateButton('Undo', 516, 8, 52, @UndoClick, FTopPanel);  Btn.Hint := 'Undo last action (Ctrl+Z)';
  Btn := CreateButton('Redo', 572, 8, 52, @RedoClick, FTopPanel);  Btn.Hint := 'Redo (Ctrl+Y)';
  Btn := CreateButton('Z-', 628, 8, 34, @ZoomOutClick, FTopPanel); Btn.Hint := 'Zoom out ([)';

  FZoomCombo := TComboBox.Create(FTopPanel);
  FZoomCombo.Parent := FTopPanel;
  FZoomCombo.Left := 666;
  FZoomCombo.Top := 8;
  FZoomCombo.Width := 74;
  FZoomCombo.Style := csDropDownList;
  for ZoomIndex := 0 to ZoomPresetCount - 1 do
    FZoomCombo.Items.Add(ZoomPresetCaption(ZoomIndex));
  FZoomCombo.OnChange := @ZoomComboChange;

  Btn := CreateButton('Z+', 744, 8, 34, @ZoomInClick, FTopPanel);     Btn.Hint := 'Zoom in (])';
  Btn := CreateButton('Import', 782, 8, 60, @ImportLayerClick, FTopPanel); Btn.Hint := 'Import layer from file';
  Btn := CreateButton('Fore', 846, 8, 46, @PrimaryColorClick, FTopPanel);   Btn.Hint := 'Set foreground (primary) color';
  Btn := CreateButton('Back', 896, 8, 46, @SecondaryColorClick, FTopPanel); Btn.Hint := 'Set background (secondary) color';
  Btn := CreateButton('Swap', 946, 8, 50, @SwapColorsClick, FTopPanel);     Btn.Hint := 'Swap foreground and background colors (X)';
  Btn := CreateButton('B/W', 1000, 8, 50, @ResetColorsClick, FTopPanel);    Btn.Hint := 'Reset to black foreground and white background (D)';
  Btn := CreateButton('Grid', 1054, 8, 42, @TogglePixelGridClick, FTopPanel); Btn.Hint := 'Toggle pixel grid';
  Btn := CreateButton('Ruler', 1100, 8, 50, @ToggleRulersClick, FTopPanel);  Btn.Hint := 'Toggle rulers';

  UtilityPanel := TPanel.Create(FTopPanel);
  UtilityPanel.Parent := FTopPanel;
  UtilityPanel.Left := 1140;
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
      10 + ColumnIndex * 42,
      ContentTop + RowIndex * 28,
      36,
      @ToolButtonClick,
      FToolsPanel,
      Ord(ToolKind)
    );
    ToolButton.Hint := PaintToolName(ToolKind) + ' — ' + PaintToolHint(ToolKind);
  end;

  FColorsPanel := TPanel.Create(Self);
  CreatePalette(FColorsPanel, pkColors);
  CreateButton('Primary', 12, ContentTop, 110, @PrimaryColorClick, FColorsPanel);
  CreateButton('Secondary', 128, ContentTop, 110, @SecondaryColorClick, FColorsPanel);
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
  FColorHexEdit.Hint := 'Primary color as RRGGBBAA hex';
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
  CreateButton('Undo', 12, ContentTop, 100, @UndoClick, FHistoryPanel);
  CreateButton('Redo', 124, ContentTop, 100, @RedoClick, FHistoryPanel);
  FHistoryValueLabel := TLabel.Create(FHistoryPanel);
  FHistoryValueLabel.Parent := FHistoryPanel;
  FHistoryValueLabel.Left := 12;
  FHistoryValueLabel.Top := ContentTop + 32;
  FHistoryValueLabel.Width := 220;
  FHistoryValueLabel.Height := 56;
  FHistoryValueLabel.WordWrap := True;
  FHistoryValueLabel.Font.Color := clWhite;
  RefreshHistoryPanel;

  FRightPanel := TPanel.Create(Self);
  CreatePalette(FRightPanel, pkLayers);

  CreateButton('Add', 12, ContentTop, 52, @AddLayerClick, FRightPanel);
  CreateButton('Dup', 68, ContentTop, 52, @DuplicateLayerClick, FRightPanel);
  CreateButton('Del', 124, ContentTop, 52, @DeleteLayerClick, FRightPanel);
  CreateButton('Merge', 180, ContentTop, 52, @MergeDownClick, FRightPanel);
  CreateButton('Vis', 12, ContentTop + 30, 52, @ToggleLayerVisibilityClick, FRightPanel);
  CreateButton('Opac', 68, ContentTop + 30, 52, @LayerOpacityClick, FRightPanel);
  CreateButton('Name', 124, ContentTop + 30, 52, @RenameLayerClick, FRightPanel);
  CreateButton('Flat', 180, ContentTop + 30, 52, @FlattenClick, FRightPanel);
  CreateButton('Up', 12, ContentTop + 60, 52, @MoveLayerUpClick, FRightPanel);
  CreateButton('Down', 68, ContentTop + 60, 52, @MoveLayerDownClick, FRightPanel);
  FLayerPropsButton := CreateButton('Props', 124, ContentTop + 60, 114, @LayerPropertiesClick, FRightPanel);

  FLayerBlendCombo := TComboBox.Create(FRightPanel);
  FLayerBlendCombo.Parent := FRightPanel;
  FLayerBlendCombo.Left := 12;
  FLayerBlendCombo.Top := ContentTop + 90;
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
  FLayerList.Top := ContentTop + 120;
  FLayerList.Width := 220;
  FLayerList.Height := FRightPanel.Height - (ContentTop + 132);
  FLayerList.Anchors := [akTop, akLeft, akRight, akBottom];
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
    DisplaySurface := BuildDisplaySurface;
    try
      CopySurfaceToBitmap(DisplaySurface, FPreparedBitmap);
    finally
      DisplaySurface.Free;
    end;
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
begin
  FLayerList.Items.BeginUpdate;
  try
    FLayerList.Items.Clear;
    for Index := 0 to FDocument.LayerCount - 1 do
    begin
      if FDocument.Layers[Index].Visible then
        CaptionText := '[x] '
      else
        CaptionText := '[ ] ';
      CaptionText := CaptionText + FDocument.Layers[Index].Name;
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
begin
  if Assigned(FColorsValueLabel) then
  begin
    FColorsValueLabel.Caption := Format(
      'Secondary: #%2.2x%2.2x%2.2x',
      [
        FSecondaryColor.R,
        FSecondaryColor.G,
        FSecondaryColor.B
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
  Cols, Rows: Integer;
  Pad: Integer;
  Sw, Sh: Integer;
  R, G, B: Integer;
  I, X, Y: Integer;
  Colors: array of TRGBA32;
  Idx: Integer;
  CellRect: TRect;
begin
  if not Assigned(Sender) then Exit;
  PB := TPaintBox(Sender);
  C := PB.Canvas;
  W := PB.Width;
  H := PB.Height;
  C.Brush.Style := bsSolid;
  C.Brush.Color := PaletteSurfaceColor(pkColors, False);
  C.FillRect(Rect(0,0,W,H));

  // simple generated palette (3x3 RGB levels)
  SetLength(Colors, 0);
  for R := 0 to 2 do
    for G := 0 to 2 do
      for B := 0 to 2 do
      begin
        Idx := Length(Colors);
        SetLength(Colors, Idx + 1);
        Colors[Idx] := RGBA(R * 128, G * 128, B * 128, 255);
      end;

  Cols := 6;
  Rows := ((Length(Colors) + Cols - 1) div Cols);
  Pad := 6;
  Sw := Max(8, (W - (Pad * (Cols + 1))) div Cols);
  Sh := Max(8, (H - (Pad * (Rows + 1))) div Rows);

  Idx := 0;
  for Y := 0 to Rows - 1 do
  begin
    for X := 0 to Cols - 1 do
    begin
      if Idx >= Length(Colors) then Break;
      CellRect.Left := Pad + X * (Sw + Pad);
      CellRect.Top := Pad + Y * (Sh + Pad);
      CellRect.Right := CellRect.Left + Sw;
      CellRect.Bottom := CellRect.Top + Sh;
      C.Brush.Color := RGBToColor(Colors[Idx].R, Colors[Idx].G, Colors[Idx].B);
      C.FillRect(CellRect);
      C.Pen.Color := clBlack;
      C.Rectangle(CellRect.Left, CellRect.Top, CellRect.Right, CellRect.Bottom);
      Inc(Idx);
    end;
  end;

  // draw primary/secondary indicators
  C.Brush.Style := bsClear;
  C.Pen.Color := clWhite;
  C.Rectangle(2, 2, 28, 20);
  C.Brush.Color := RGBToColor(FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B);
  C.FillRect(Rect(4,4,18,18));
  C.Brush.Color := RGBToColor(FSecondaryColor.R, FSecondaryColor.G, FSecondaryColor.B);
  C.FillRect(Rect(12,8,26,16));
end;

procedure TMainForm.ColorsBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  PB: TPaintBox;
  W, H: Integer;
  Cols, Rows: Integer;
  Pad: Integer;
  Sw, Sh: Integer;
  R, G, B: Integer;
  Colors: array of TRGBA32;
  ColIdx, RowIdx, Idx: Integer;
  ClickIndex: Integer;
begin
  if not Assigned(Sender) then Exit;
  PB := TPaintBox(Sender);
  W := PB.Width;
  H := PB.Height;

  // build same palette as paint
  SetLength(Colors, 0);
  for R := 0 to 2 do
    for G := 0 to 2 do
      for B := 0 to 2 do
      begin
        Idx := Length(Colors);
        SetLength(Colors, Idx + 1);
        Colors[Idx] := RGBA(R * 128, G * 128, B * 128, 255);
      end;

  Cols := 6;
  Rows := ((Length(Colors) + Cols - 1) div Cols);
  Pad := 6;
  Sw := Max(8, (W - (Pad * (Cols + 1))) div Cols);
  Sh := Max(8, (H - (Pad * (Rows + 1))) div Rows);

  ColIdx := X div (Sw + Pad);
  RowIdx := Y div (Sh + Pad);
  if (ColIdx < 0) or (ColIdx >= Cols) or (RowIdx < 0) or (RowIdx >= Rows) then Exit;
  Idx := RowIdx * Cols + ColIdx;
  if Idx < 0 then Exit;
  if Idx >= Length(Colors) then Exit;

  ClickIndex := Idx;

  if Button = mbLeft then
    FPrimaryColor := Colors[ClickIndex]
  else
    FSecondaryColor := Colors[ClickIndex];
  RefreshColorsPanel;
  PB.Invalidate;
end;

procedure TMainForm.RefreshHistoryPanel;
var
  UndoLabel: string;
  RedoLabel: string;
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
      'Undo: %d (%s)'#13#10'Redo: %d (%s)',
      [FDocument.UndoDepth, UndoLabel, FDocument.RedoDepth, RedoLabel]
    );
  end;
end;

procedure TMainForm.RefreshStatus(const ACursorPoint: TPoint);
var
  SelectionText: string;
  SelectionBounds: TRect;
begin
  if FStatusBar.Panels.Count < 7 then
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

  FStatusBar.Panels[0].Text := Format('%s — %s', [PaintToolName(FCurrentTool), ToolHintText]);
  FStatusBar.Panels[1].Text := Format(
    'Image: %s × %s %s',
    [
      FormatMeasurement(FDocument.Width),
      FormatMeasurement(FDocument.Height),
      DisplayUnitSuffix
    ]
  );
  FStatusBar.Panels[2].Text := 'Selection: ' + SelectionText;
  if (ACursorPoint.X >= 0) and (ACursorPoint.Y >= 0) then
    FStatusBar.Panels[3].Text := Format(
      'Cursor: %s, %s %s',
      [
        FormatMeasurement(ACursorPoint.X),
        FormatMeasurement(ACursorPoint.Y),
        DisplayUnitSuffix
      ]
    )
  else
    FStatusBar.Panels[3].Text := 'Cursor: —';
  FStatusBar.Panels[4].Text := Format(
    'Layer: %d/%d',
    [FDocument.ActiveLayerIndex + 1, FDocument.LayerCount]
  );
  FStatusBar.Panels[5].Text := 'Units: ' + DisplayUnitSuffix;
  FStatusBar.Panels[6].Text := '';
  UpdateZoomControls;
  LayoutStatusBarControls(nil);
end;

procedure TMainForm.LayoutStatusBarControls(Sender: TObject);
var
  PanelWidths: TStatusPanelWidthArray;
  PanelIndex: Integer;
  ZoomAreaLeft: Integer;
  ZoomAreaWidth: Integer;
  LabelWidth: Integer;
  TrackWidth: Integer;
begin
  if not Assigned(FStatusBar) or
     not Assigned(FStatusZoomTrack) or
     not Assigned(FStatusZoomLabel) or
     (FStatusBar.Panels.Count < 7) then
    Exit;

  ComputeStatusPanelWidths(Max(0, FStatusBar.ClientWidth - 4), PanelWidths);
  for PanelIndex := 0 to StatusPanelCount - 1 do
    FStatusBar.Panels[PanelIndex].Width := PanelWidths[PanelIndex];

  ZoomAreaWidth := PanelWidths[6];
  ZoomAreaLeft := Max(0, FStatusBar.ClientWidth - ZoomAreaWidth - 2);
  LabelWidth := ZoomLabelWidth(ZoomAreaWidth);
  TrackWidth := ZoomTrackWidth(ZoomAreaWidth);

  FStatusZoomTrack.SetBounds(
    Max(ZoomAreaLeft + 4, ZoomAreaLeft + ZoomAreaWidth - LabelWidth - TrackWidth - 8),
    1,
    TrackWidth,
    Max(20, FStatusBar.Height - 2)
  );
  FStatusZoomLabel.SetBounds(
    Max(ZoomAreaLeft + 4, ZoomAreaLeft + ZoomAreaWidth - LabelWidth - 4),
    2,
    LabelWidth,
    Max(18, FStatusBar.Height - 6)
  );
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
begin
  if not NeedsDiscardConfirmation(FDirty) then
    Exit(True);

  Result := MessageDlg(
    'Unsaved Changes',
    Format(
      'The current document has unsaved changes. Discard them and %s?',
      [AAction]
    ),
    mtConfirmation,
    [mbYes, mbNo],
    0
  ) = mrYes;
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

  Surface := FDocument.Composite;
  try
    SaveSurfaceToFile(ResolvedFileName, Surface);
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
        FBrushOpacity * 255 div 100
      );
    tkBrush, tkEraser:
      FDocument.ActiveLayer.Surface.DrawLine(
        FLastImagePoint.X,
        FLastImagePoint.Y,
        APoint.X,
        APoint.Y,
        Max(1, FBrushSize div 2),
        ActivePaintColor,
        FBrushOpacity * 255 div 100
      );
    tkFill:
      FDocument.ActiveLayer.Surface.FloodFill(
        APoint.X,
        APoint.Y,
        ActivePaintColor,
        8
      );
    tkColorPicker:
      begin
        CompositeSurface := FDocument.Composite;
        try
          if FPickSecondaryTarget then
            FSecondaryColor := CompositeSurface[APoint.X, APoint.Y]
          else
            FPrimaryColor := CompositeSurface[APoint.X, APoint.Y];
        finally
          CompositeSurface.Free;
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
begin
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
      FDocument.ActiveLayer.Surface.FillGradient(
        AStartPoint.X,
        AStartPoint.Y,
        AEndPoint.X,
        AEndPoint.Y,
        FPrimaryColor,
        FSecondaryColor
      );
    tkRectangle:
      FDocument.ActiveLayer.Surface.DrawRectangle(
        AStartPoint.X,
        AStartPoint.Y,
        AEndPoint.X,
        AEndPoint.Y,
        Max(1, FBrushSize div 3),
        ActivePaintColor,
        False
      );
    tkRoundedRectangle:
      FDocument.ActiveLayer.Surface.DrawRoundedRectangle(
        AStartPoint.X,
        AStartPoint.Y,
        AEndPoint.X,
        AEndPoint.Y,
        Max(1, FBrushSize div 3),
        ActivePaintColor,
        False
      );
    tkEllipseShape:
      FDocument.ActiveLayer.Surface.DrawEllipse(
        AStartPoint.X,
        AStartPoint.Y,
        AEndPoint.X,
        AEndPoint.Y,
        Max(1, FBrushSize div 3),
        ActivePaintColor,
        False
      );
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
begin
  if FDirty then
  begin
    if MessageDlg('Close Document',
      Format('Discard unsaved changes to "%s"?', [TabDocumentDisplayName(FActiveTabIndex)]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
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
  FDocument.PushHistory('Outline');
  FDocument.DetectEdges;
  InvalidatePreparedBitmap;
  SetDirty(True);
  RefreshCanvas;
  FLastEffectCaption := 'Outline';
  FLastEffectProc := @OutlineClick;
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
begin
  Dialog := TColorDialog.Create(Self);
  try
    Dialog.Color := RGBToColor(FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B);
    if Dialog.Execute then
      FPrimaryColor := UIToRGBA(Dialog.Color);
  finally
    Dialog.Free;
  end;
  RefreshColorsPanel;
end;

procedure TMainForm.SecondaryColorClick(Sender: TObject);
var
  Dialog: TColorDialog;
begin
  Dialog := TColorDialog.Create(Self);
  try
    Dialog.Color := RGBToColor(FSecondaryColor.R, FSecondaryColor.G, FSecondaryColor.B);
    if Dialog.Execute then
      FSecondaryColor := UIToRGBA(Dialog.Color);
  finally
    Dialog.Free;
  end;
  RefreshColorsPanel;
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
    CanClose := MessageDlg(
      'Quit FlatPaint',
      Format('You have %d document(s) with unsaved changes. Quit anyway?', [DirtyCount]),
      mtConfirmation,
      [mbYes, mbNo],
      0
    ) = mrYes;
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

procedure TMainForm.StatusZoomTrackChange(Sender: TObject);
begin
  if FUpdatingZoomControl then
    Exit;
  if not Assigned(FStatusZoomTrack) then
    Exit;
  ApplyZoomScale(ZoomScaleForSliderPosition(FStatusZoomTrack.Position));
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
begin
  if Shift <> [] then
    Exit;

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

procedure TMainForm.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ImagePoint: TPoint;
begin
  FPickSecondaryTarget := Button = mbRight;
  if FPickSecondaryTarget then
    FStrokeColor := FSecondaryColor
  else
    FStrokeColor := FPrimaryColor;

  ImagePoint := CanvasToImage(X, Y);
  FLastPointerPoint := Point(X, Y);
  FLastImagePoint := ImagePoint;
  FDragStart := ImagePoint;
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
        FDocument.SelectMagicWand(ImagePoint.X, ImagePoint.Y, EnsureRange(FWandTolerance, 0, 255), FPendingSelectionMode);
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
begin
  if FUpdatingColorSpins then Exit;
  FUpdatingColorSpins := True;
  try
    if Assigned(FColorRSpin) then FColorRSpin.Value := FPrimaryColor.R;
    if Assigned(FColorGSpin) then FColorGSpin.Value := FPrimaryColor.G;
    if Assigned(FColorBSpin) then FColorBSpin.Value := FPrimaryColor.B;
    if Assigned(FColorASpin) then FColorASpin.Value := FPrimaryColor.A;
    if Assigned(FColorHexEdit) then
      FColorHexEdit.Text := Format('%2.2x%2.2x%2.2x%2.2x',
        [FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B, FPrimaryColor.A]);
  finally
    FUpdatingColorSpins := False;
  end;
end;

procedure TMainForm.ColorSpinChanged(Sender: TObject);
begin
  if FUpdatingColorSpins then Exit;
  if not Assigned(FColorRSpin) then Exit;
  FPrimaryColor := RGBA(
    FColorRSpin.Value,
    FColorGSpin.Value,
    FColorBSpin.Value,
    FColorASpin.Value
  );
  FUpdatingColorSpins := True;
  try
    if Assigned(FColorHexEdit) then
      FColorHexEdit.Text := Format('%2.2x%2.2x%2.2x%2.2x',
        [FPrimaryColor.R, FPrimaryColor.G, FPrimaryColor.B, FPrimaryColor.A]);
  finally
    FUpdatingColorSpins := False;
  end;
  if Assigned(FColorsBox) then FColorsBox.Invalidate;
end;

procedure TMainForm.ColorHexChanged(Sender: TObject);
var
  HexStr: string;
  R, G, B, A: Integer;
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
    FPrimaryColor := RGBA(
      EnsureRange(R, 0, 255),
      EnsureRange(G, 0, 255),
      EnsureRange(B, 0, 255),
      EnsureRange(A, 0, 255)
    );
    FUpdatingColorSpins := True;
    try
      if Assigned(FColorRSpin) then FColorRSpin.Value := FPrimaryColor.R;
      if Assigned(FColorGSpin) then FColorGSpin.Value := FPrimaryColor.G;
      if Assigned(FColorBSpin) then FColorBSpin.Value := FPrimaryColor.B;
      if Assigned(FColorASpin) then FColorASpin.Value := FPrimaryColor.A;
    finally
      FUpdatingColorSpins := False;
    end;
    if Assigned(FColorsBox) then FColorsBox.Invalidate;
  except
    { Invalid hex input — silently ignore }
  end;
end;

{ ── Tool Option Handlers ─────────────────────────────────────────────────── }

procedure TMainForm.OpacitySpinChanged(Sender: TObject);
begin
  if not Assigned(FOpacitySpin) then Exit;
  FBrushOpacity := EnsureRange(FOpacitySpin.Value, 1, 100);
end;

procedure TMainForm.SelModeComboChanged(Sender: TObject);
begin
  if not Assigned(FSelModeCombo) then Exit;
  FPendingSelectionMode := TSelectionCombineMode(FSelModeCombo.ItemIndex);
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
