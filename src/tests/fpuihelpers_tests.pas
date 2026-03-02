unit fpuihelpers_tests;

{$mode objfpc}{$H+}

// tests run with a custom symbol to enable testing-only code paths
{$DEFINE TESTING}

interface

uses
  fpcunit, testregistry, FPDocument, FPUIHelpers, MainForm,
  Controls, LCLType;  { for TMouseButton and VK_SPACE }

{$IFDEF TESTING}
// we will provide our own stubs for any LCL widgetset registration symbols
{$ENDIF}

type
  TFPUIHelpersTests = class(TTestCase)
  published
    procedure ToolDisplayOrderStartsWithSelectionTools;
    procedure ZoomToolAppearsBeforePaintTools;
    procedure PanAndPencilAppearInExpectedBands;
    procedure FreeformShapeAppearsAfterBasicShapes;
    procedure ToolMetadataIsCompleteForDisplayOrder;
    procedure CropTextCloneRecolorAppearInDisplayOrder;
    procedure TotalDisplayCountIsCorrect;
    procedure ShortcutCyclesSelectionTools;
    procedure ShortcutCyclesMoveTools;
    procedure ShortcutCyclesShapeTools;
    procedure ShortcutSingleKeyMaps;
  end;

  TMainFormTests = class(TTestCase)
  published
    procedure SpacebarPanShortcut;
    procedure MiddleMousePanShortcut;
  end;

implementation

{$IFDEF TESTING}
procedure FPInstallMagnifyHandler(ANSViewHandle: Pointer; ACallback: Pointer); cdecl;
begin
  { no-op }
end;

// stub out registration methods so LCL initialization can succeed without
// pulling in the full widgetset
function WSRegisterBevel: Boolean; cdecl; begin Result := True; end;
function WSRegisterButtonControl: Boolean; cdecl; begin Result := True; end;
function WSRegisterCalculatorDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterCalculatorForm: Boolean; cdecl; begin Result := True; end;
function WSRegisterCalendarDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterColorButton: Boolean; cdecl; begin Result := True; end;
function WSRegisterColorDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterCommonDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterControl: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomBitBtn: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomButton: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomCheckBox: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomCheckGroup: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomComboBox: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomControl: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomEdit: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomFloatSpinEdit: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomForm: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomFrame: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomGrid: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomImage: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomImageListResolution: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomLabel: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomLabeledEdit: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomListBox: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomListView: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomMemo: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomNotebook: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomPage: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomPanel: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomPairSplitter: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomProgressBar: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomRadioGroup: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomScrollBar: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomShape: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomShellListView: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomShellTreeView: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomSpeedButton: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomSplitter: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomToolButton: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomTrayIcon: Boolean; cdecl; begin Result := True; end;
function WSRegisterCustomUpDown: Boolean; cdecl; begin Result := True; end;
function WSRegisterDragImageListResolution: Boolean; cdecl; begin Result := True; end;
function WSRegisterFontDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterFileDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterHintWindow: Boolean; cdecl; begin Result := True; end;
function WSRegisterLazAccessibleObject: Boolean; cdecl; begin Result := True; end;
function WSRegisterLazDeviceAPIs: Boolean; cdecl; begin Result := True; end;
function WSRegisterMainMenu: Boolean; cdecl; begin Result := True; end;
function WSRegisterMenu: Boolean; cdecl; begin Result := True; end;
function WSRegisterMenuItem: Boolean; cdecl; begin Result := True; end;
function WSRegisterOpenDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterPageControl: Boolean; cdecl; begin Result := True; end;
function WSRegisterPairSplitterSide: Boolean; cdecl; begin Result := True; end;
function WSRegisterPreviewFileControl: Boolean; cdecl; begin Result := True; end;
function WSRegisterPreviewFileDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterRadioButton: Boolean; cdecl; begin Result := True; end;
function WSRegisterSaveDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterScrollBox: Boolean; cdecl; begin Result := True; end;
function WSRegisterSelectDirectoryDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterStatusBar: Boolean; cdecl; begin Result := True; end;
function WSRegisterTabSheet: Boolean; cdecl; begin Result := True; end;
function WSRegisterTaskDialog: Boolean; cdecl; begin Result := True; end;
function WSRegisterToggleBox: Boolean; cdecl; begin Result := True; end;
function WSRegisterToolBar: Boolean; cdecl; begin Result := True; end;
function WSRegisterTrackBar: Boolean; cdecl; begin Result := True; end;
function WSRegisterTreeView: Boolean; cdecl; begin Result := True; end;
{$ENDIF}

procedure TFPUIHelpersTests.ToolDisplayOrderStartsWithSelectionTools;
begin
  AssertEquals('first tool', Ord(tkSelectRect), Ord(PaintToolAtDisplayIndex(0)));
  AssertEquals('second tool', Ord(tkSelectEllipse), Ord(PaintToolAtDisplayIndex(1)));
  AssertEquals('third tool', Ord(tkSelectLasso), Ord(PaintToolAtDisplayIndex(2)));
  AssertEquals('fourth tool', Ord(tkMagicWand), Ord(PaintToolAtDisplayIndex(3)));
end;

procedure TFPUIHelpersTests.ZoomToolAppearsBeforePaintTools;
begin
  AssertTrue(
    'zoom should appear before fill in the display order',
    PaintToolDisplayIndex(tkZoom) < PaintToolDisplayIndex(tkFill)
  );
end;

procedure TFPUIHelpersTests.PanAndPencilAppearInExpectedBands;
begin
  AssertTrue(
    'pan should sit after zoom',
    PaintToolDisplayIndex(tkPan) > PaintToolDisplayIndex(tkZoom)
  );
  AssertTrue(
    'pan should stay before fill',
    PaintToolDisplayIndex(tkPan) < PaintToolDisplayIndex(tkFill)
  );
  AssertTrue(
    'pencil should appear before brush',
    PaintToolDisplayIndex(tkPencil) < PaintToolDisplayIndex(tkBrush)
  );
end;

procedure TFPUIHelpersTests.FreeformShapeAppearsAfterBasicShapes;
begin
  AssertTrue(
    'freeform shape should appear after ellipse shape',
    PaintToolDisplayIndex(tkFreeformShape) > PaintToolDisplayIndex(tkEllipseShape)
  );
end;

procedure TFPUIHelpersTests.ToolMetadataIsCompleteForDisplayOrder;
var
  ToolIndex: Integer;
  ToolKind: TToolKind;
begin
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
  begin
    ToolKind := PaintToolAtDisplayIndex(ToolIndex);
    AssertTrue('tool name missing', PaintToolName(ToolKind) <> '');
    AssertTrue('tool hint missing', PaintToolHint(ToolKind) <> '');
    AssertTrue('tool glyph missing', PaintToolGlyph(ToolKind) <> '');
    AssertEquals(
      'display index roundtrip',
      ToolIndex,
      PaintToolDisplayIndex(ToolKind)
    );
  end;
end;

procedure TFPUIHelpersTests.CropTextCloneRecolorAppearInDisplayOrder;
begin
  AssertTrue('crop has display index', PaintToolDisplayIndex(tkCrop) >= 0);
  AssertTrue('text has display index', PaintToolDisplayIndex(tkText) >= 0);
  AssertTrue('clone stamp has display index', PaintToolDisplayIndex(tkCloneStamp) >= 0);
  AssertTrue('recolor has display index', PaintToolDisplayIndex(tkRecolor) >= 0);
  AssertTrue('text metadata complete', PaintToolName(tkText) <> '');
  AssertTrue('clone glyph present', PaintToolGlyph(tkCloneStamp) <> '');
  AssertTrue('recolor hint present', PaintToolHint(tkRecolor) <> '');
end;

procedure TFPUIHelpersTests.TotalDisplayCountIsCorrect;
begin
  AssertEquals('total tool display count', 23, PaintToolDisplayCount);
end;

procedure TFPUIHelpersTests.ShortcutCyclesSelectionTools;
var
  t: TToolKind;
begin
  t := tkSelectRect;
  t := NextToolForKey('S', False, t);
  AssertEquals(Ord(tkSelectEllipse), Ord(t));
  t := NextToolForKey('S', False, t);
  AssertEquals(Ord(tkSelectLasso), Ord(t));
  t := NextToolForKey('S', False, t);
  AssertEquals(Ord(tkMagicWand), Ord(t));
  t := NextToolForKey('S', False, t);
  AssertEquals(Ord(tkSelectRect), Ord(t));
  { reverse }
  t := NextToolForKey('S', True, t);
  AssertEquals(Ord(tkMagicWand), Ord(t));
  t := NextToolForKey('S', True, t);
  AssertEquals(Ord(tkSelectLasso), Ord(t));
end;

procedure TFPUIHelpersTests.ShortcutCyclesMoveTools;
var
  t: TToolKind;
begin
  t := tkMoveSelection;
  t := NextToolForKey('M', False, t);
  AssertEquals(Ord(tkMovePixels), Ord(t));
  t := NextToolForKey('M', False, t);
  AssertEquals(Ord(tkMoveSelection), Ord(t));
  { reverse }
  t := NextToolForKey('M', True, t);
  AssertEquals(Ord(tkMovePixels), Ord(t));
end;

procedure TFPUIHelpersTests.ShortcutCyclesShapeTools;
var
  t: TToolKind;
begin
  t := tkLine;
  t := NextToolForKey('O', False, t);
  AssertEquals(Ord(tkRectangle), Ord(t));
  t := NextToolForKey('O', False, t);
  AssertEquals(Ord(tkRoundedRectangle), Ord(t));
  t := NextToolForKey('O', False, t);
  AssertEquals(Ord(tkEllipseShape), Ord(t));
  t := NextToolForKey('O', False, t);
  AssertEquals(Ord(tkFreeformShape), Ord(t));
  t := NextToolForKey('O', False, t);
  AssertEquals(Ord(tkLine), Ord(t));
  { reverse }
  t := NextToolForKey('O', True, t);
  AssertEquals(Ord(tkFreeformShape), Ord(t));
end;

procedure TFPUIHelpersTests.ShortcutSingleKeyMaps;
var
  t: TToolKind;
begin
  t := tkBrush;
  t := NextToolForKey('B', False, t);
  AssertEquals(Ord(tkBrush), Ord(t));
  t := NextToolForKey('Z', False, t);
  AssertEquals(Ord(tkZoom), Ord(t));
  t := NextToolForKey('K', False, t);
  AssertEquals(Ord(tkColorPicker), Ord(t));
  { unrelated key leaves unchanged }
  t := NextToolForKey('Q', False, t);
  AssertEquals(Ord(tkColorPicker), Ord(t));
end;

procedure TMainFormTests.SpacebarPanShortcut;
var
  F: TMainForm;
  prev, panIdx: Integer;
begin
  F := TMainForm.Create(nil);
  try
    prev := F.ToolCombo.ItemIndex;
    panIdx := PaintToolDisplayIndex(tkPan);
    F.SimulateKeyDown(VK_SPACE, []);
    AssertEquals('spacebar should switch to pan', panIdx, F.ToolCombo.ItemIndex);
    F.SimulateKeyUp(VK_SPACE, []);
    AssertEquals('spacebar release restores tool', prev, F.ToolCombo.ItemIndex);
  finally
    F.Free;
  end;
end;

procedure TMainFormTests.MiddleMousePanShortcut;
var
  F: TMainForm;
  prev, panIdx: Integer;
begin
  F := TMainForm.Create(nil);
  try
    prev := F.ToolCombo.ItemIndex;
    panIdx := PaintToolDisplayIndex(tkPan);
    F.SimulateMouseDown(mbMiddle, [], 10, 10);
    AssertEquals('middle button should switch to pan', panIdx, F.ToolCombo.ItemIndex);
    F.SimulateMouseUp(mbMiddle, [], 10, 10);
    AssertEquals('middle button release restores tool', prev, F.ToolCombo.ItemIndex);
  finally
    F.Free;
  end;
end;

initialization
  RegisterTest(TFPUIHelpersTests);
  RegisterTest(TMainFormTests);

end.
