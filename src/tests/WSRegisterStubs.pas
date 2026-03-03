unit WSRegisterStubs;

{$mode objfpc}{$H+}

interface

{ simple stubs for every WSRegister* symbol used by the LCL widgetset.
  Tests compile with these definitions when TESTING is defined; the
  production application never links against this unit. }

function WSRegisterBevel: Boolean; cdecl; export;
function WSRegisterButtonControl: Boolean; cdecl; export;
function WSRegisterCalculatorDialog: Boolean; cdecl; export;
function WSRegisterCalculatorForm: Boolean; cdecl; export;
function WSRegisterCalendarDialog: Boolean; cdecl; export;
function WSRegisterColorButton: Boolean; cdecl; export;
function WSRegisterColorDialog: Boolean; cdecl; export;
function WSRegisterCommonDialog: Boolean; cdecl; export;
function WSRegisterControl: Boolean; cdecl; export;
function WSRegisterCustomBitBtn: Boolean; cdecl; export;
function WSRegisterCustomButton: Boolean; cdecl; export;
function WSRegisterCustomCheckBox: Boolean; cdecl; export;
function WSRegisterCustomCheckGroup: Boolean; cdecl; export;
function WSRegisterCustomComboBox: Boolean; cdecl; export;
function WSRegisterCustomControl: Boolean; cdecl; export;
function WSRegisterCustomEdit: Boolean; cdecl; export;
function WSRegisterCustomFloatSpinEdit: Boolean; cdecl; export;
function WSRegisterCustomForm: Boolean; cdecl; export;
function WSRegisterCustomFrame: Boolean; cdecl; export;
function WSRegisterCustomGrid: Boolean; cdecl; export;
function WSRegisterCustomImage: Boolean; cdecl; export;
function WSRegisterCustomImageListResolution: Boolean; cdecl; export;
function WSRegisterCustomLabel: Boolean; cdecl; export;
function WSRegisterCustomLabeledEdit: Boolean; cdecl; export;
function WSRegisterCustomListBox: Boolean; cdecl; export;
function WSRegisterCustomListView: Boolean; cdecl; export;
function WSRegisterCustomMemo: Boolean; cdecl; export;
function WSRegisterCustomNotebook: Boolean; cdecl; export;
function WSRegisterCustomPage: Boolean; cdecl; export;
function WSRegisterCustomPanel: Boolean; cdecl; export;
function WSRegisterCustomProgressBar: Boolean; cdecl; export;
function WSRegisterCustomRadioGroup: Boolean; cdecl; export;
function WSRegisterCustomScrollBar: Boolean; cdecl; export;
function WSRegisterCustomShape: Boolean; cdecl; export;
function WSRegisterCustomSpeedButton: Boolean; cdecl; export;
function WSRegisterCustomSplitter: Boolean; cdecl; export;
function WSRegisterCustomStaticText: Boolean; cdecl; export;
function WSRegisterCustomToolButton: Boolean; cdecl; export;
function WSRegisterCustomTrayIcon: Boolean; cdecl; export;
function WSRegisterCustomTreeView: Boolean; cdecl; export;
function WSRegisterCustomUpDown: Boolean; cdecl; export;
function WSRegisterDragImageListResolution: Boolean; cdecl; export;
function WSRegisterFileDialog: Boolean; cdecl; export;
function WSRegisterFontDialog: Boolean; cdecl; export;
function WSRegisterGraphicControl: Boolean; cdecl; export;
function WSRegisterHintWindow: Boolean; cdecl; export;
function WSRegisterLazAccessibleObject: Boolean; cdecl; export;
function WSRegisterMainMenu: Boolean; cdecl; export;
function WSRegisterMenu: Boolean; cdecl; export;
function WSRegisterMenuItem: Boolean; cdecl; export;
function WSRegisterOpenDialog: Boolean; cdecl; export;
function WSRegisterPageControl: Boolean; cdecl; export;
function WSRegisterPaintBox: Boolean; cdecl; export;
function WSRegisterPopupMenu: Boolean; cdecl; export;
function WSRegisterRadioButton: Boolean; cdecl; export;
function WSRegisterSaveDialog: Boolean; cdecl; export;
function WSRegisterScrollBox: Boolean; cdecl; export;
function WSRegisterScrollingWinControl: Boolean; cdecl; export;
function WSRegisterSelectDirectoryDialog: Boolean; cdecl; export;
function WSRegisterStatusBar: Boolean; cdecl; export;
function WSRegisterTabSheet: Boolean; cdecl; export;
function WSRegisterTaskDialog: Boolean; cdecl; export;
function WSRegisterToggleBox: Boolean; cdecl; export;
function WSRegisterToolBar: Boolean; cdecl; export;
function WSRegisterWinControl: Boolean; cdecl; export;

implementation

{ stub implementations just return True so the linker is happy }

function WSRegisterBevel: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterButtonControl: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCalculatorDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCalculatorForm: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCalendarDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterColorButton: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterColorDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCommonDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterControl: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomBitBtn: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomButton: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomCheckBox: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomCheckGroup: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomComboBox: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomControl: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomEdit: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomFloatSpinEdit: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomForm: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomFrame: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomGrid: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomImage: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomImageListResolution: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomLabel: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomLabeledEdit: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomListBox: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomListView: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomMemo: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomNotebook: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomPage: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomPanel: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomProgressBar: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomRadioGroup: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomScrollBar: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomShape: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomSpeedButton: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomSplitter: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomStaticText: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomToolButton: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomTrayIcon: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomTreeView: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterCustomUpDown: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterDragImageListResolution: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterFileDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterFontDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterGraphicControl: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterHintWindow: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterLazAccessibleObject: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterMainMenu: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterMenu: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterMenuItem: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterOpenDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterPageControl: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterPaintBox: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterPopupMenu: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterRadioButton: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterSaveDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterScrollBox: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterScrollingWinControl: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterSelectDirectoryDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterStatusBar: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterTabSheet: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterTaskDialog: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterToggleBox: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterToolBar: Boolean; cdecl; export; begin Result := True; end;
function WSRegisterWinControl: Boolean; cdecl; export; begin Result := True; end;

var
  DummyPtr: Pointer;

initialization
  { reference each stub so the smart linker includes this unit when other
    modules (LCL object files) contain unresolved externals. }
  DummyPtr := @WSRegisterBevel;
  DummyPtr := @WSRegisterButtonControl;
  DummyPtr := @WSRegisterCalculatorDialog;
  DummyPtr := @WSRegisterCalculatorForm;
  DummyPtr := @WSRegisterCalendarDialog;
  DummyPtr := @WSRegisterColorButton;
  DummyPtr := @WSRegisterColorDialog;
  DummyPtr := @WSRegisterCommonDialog;
  DummyPtr := @WSRegisterControl;
  DummyPtr := @WSRegisterCustomBitBtn;
  DummyPtr := @WSRegisterCustomButton;
  DummyPtr := @WSRegisterCustomCheckBox;
  DummyPtr := @WSRegisterCustomCheckGroup;
  DummyPtr := @WSRegisterCustomComboBox;
  DummyPtr := @WSRegisterCustomControl;
  DummyPtr := @WSRegisterCustomEdit;
  DummyPtr := @WSRegisterCustomFloatSpinEdit;
  DummyPtr := @WSRegisterCustomForm;
  DummyPtr := @WSRegisterCustomFrame;
  DummyPtr := @WSRegisterCustomGrid;
  DummyPtr := @WSRegisterCustomImage;
  DummyPtr := @WSRegisterCustomImageListResolution;
  DummyPtr := @WSRegisterCustomLabel;
  DummyPtr := @WSRegisterCustomLabeledEdit;
  DummyPtr := @WSRegisterCustomListBox;
  DummyPtr := @WSRegisterCustomListView;
  DummyPtr := @WSRegisterCustomMemo;
  DummyPtr := @WSRegisterCustomNotebook;
  DummyPtr := @WSRegisterCustomPage;
  DummyPtr := @WSRegisterCustomPanel;
  DummyPtr := @WSRegisterCustomProgressBar;
  DummyPtr := @WSRegisterCustomRadioGroup;
  DummyPtr := @WSRegisterCustomScrollBar;
  DummyPtr := @WSRegisterCustomShape;
  DummyPtr := @WSRegisterCustomSpeedButton;
  DummyPtr := @WSRegisterCustomSplitter;
  DummyPtr := @WSRegisterCustomStaticText;
  DummyPtr := @WSRegisterCustomToolButton;
  DummyPtr := @WSRegisterCustomTrayIcon;
  DummyPtr := @WSRegisterCustomTreeView;
  DummyPtr := @WSRegisterCustomUpDown;
  DummyPtr := @WSRegisterDragImageListResolution;
  DummyPtr := @WSRegisterFileDialog;
  DummyPtr := @WSRegisterFontDialog;
  DummyPtr := @WSRegisterGraphicControl;
  DummyPtr := @WSRegisterHintWindow;
  DummyPtr := @WSRegisterLazAccessibleObject;
  DummyPtr := @WSRegisterMainMenu;
  DummyPtr := @WSRegisterMenu;
  DummyPtr := @WSRegisterMenuItem;
  DummyPtr := @WSRegisterOpenDialog;
  DummyPtr := @WSRegisterPageControl;
  DummyPtr := @WSRegisterPaintBox;
  DummyPtr := @WSRegisterPopupMenu;
  DummyPtr := @WSRegisterRadioButton;
  DummyPtr := @WSRegisterSaveDialog;
  DummyPtr := @WSRegisterScrollBox;
  DummyPtr := @WSRegisterScrollingWinControl;
  DummyPtr := @WSRegisterSelectDirectoryDialog;
  DummyPtr := @WSRegisterStatusBar;
  DummyPtr := @WSRegisterTabSheet;
  DummyPtr := @WSRegisterTaskDialog;
  DummyPtr := @WSRegisterToggleBox;
  DummyPtr := @WSRegisterToolBar;
  DummyPtr := @WSRegisterWinControl;
end.
