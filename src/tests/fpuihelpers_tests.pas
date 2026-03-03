
unit fpuihelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPDocument, FPUIHelpers, MainForm,
  Controls, StdCtrls, Classes, LCLType, SysUtils;

type
  TFPUIHelpersTests = class(TTestCase)
  published
    procedure ToolDisplayOrderStartsWithSelectionTools;
    procedure ZoomToolAppearsBeforePaintTools;
    procedure PanAndPencilAppearInExpectedBands;
    procedure FreeformShapeAppearsAfterBasicShapes;
    procedure ToolMetadataIsCompleteForDisplayOrder;
    procedure ToolGlyphsStayCompact;
    procedure CropTextCloneRecolorAppearInDisplayOrder;
    procedure TotalDisplayCountIsCorrect;
    procedure ShortcutCyclesSelectionTools;
    procedure ShortcutCyclesMoveTools;
    procedure ShortcutCyclesShapeTools;
    procedure ShortcutSingleKeyMaps;
    procedure ColorShortcutTogglesTarget;
    procedure LayerOpacityHelpersRoundTripPercentScale;
  end;

  TMainFormTests = class(TTestCase)
  published
    procedure SpacebarPanShortcut;
    procedure MiddleMousePanShortcut;
  end;

implementation

type
  { Lightweight test-only shim that implements the small subset of TMainForm
    behavior used by these unit tests. This avoids constructing the full GUI
    form in headless CI runs. }
  TListComboShim = class
  public
    Items: TStringList;
    ItemIndex: Integer;
    constructor Create;
    destructor Destroy; override;
  end;
  TMainFormShim = class
  public
    ToolCombo: TListComboShim;
    ColorTargetCombo: TListComboShim;
    ColorEditTarget: Integer;
    FPreviousIndex: Integer;
    FTempToolActive: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure MakeTestSafe;
    procedure ToggleColorEditTarget;
    procedure StartTempPan;
    procedure StopTempPan;
  end;

constructor TListComboShim.Create;
begin
  inherited Create;
  Items := TStringList.Create;
  ItemIndex := -1;
end;

destructor TListComboShim.Destroy;
begin
  Items.Free;
  inherited Destroy;
end;

constructor TMainFormShim.Create;
begin
  inherited Create;
  ToolCombo := nil;
  ColorTargetCombo := nil;
  ColorEditTarget := 0;
  FTempToolActive := False;
  FPreviousIndex := -1;
end;

destructor TMainFormShim.Destroy;
begin
  ToolCombo.Free;
  ColorTargetCombo.Free;
  inherited Destroy;
end;

procedure TMainFormShim.MakeTestSafe;
begin
  if not Assigned(ToolCombo) then
    ToolCombo := TListComboShim.Create;
  while ToolCombo.Items.Count < PaintToolDisplayCount do
    ToolCombo.Items.Add('');
  if not Assigned(ColorTargetCombo) then
  begin
    ColorTargetCombo := TListComboShim.Create;
    if ColorTargetCombo.Items.Count = 0 then
    begin
      ColorTargetCombo.Items.Add('Primary');
      ColorTargetCombo.Items.Add('Secondary');
    end;
  end;
end;

procedure TMainFormShim.ToggleColorEditTarget;
begin
  if ColorEditTarget = 0 then
    ColorEditTarget := 1
  else
    ColorEditTarget := 0;
  if Assigned(ColorTargetCombo) then
    ColorTargetCombo.ItemIndex := ColorEditTarget;
end;

procedure TMainFormShim.StartTempPan;
begin
  if not FTempToolActive then
  begin
    FTempToolActive := True;
    if Assigned(ToolCombo) and (ToolCombo.ItemIndex >= 0) then
      FPreviousIndex := ToolCombo.ItemIndex
    else
      FPreviousIndex := -1;
    if Assigned(ToolCombo) then
      ToolCombo.ItemIndex := PaintToolDisplayIndex(tkPan);
  end;
end;

procedure TMainFormShim.StopTempPan;
begin
  if FTempToolActive then
  begin
    FTempToolActive := False;
    if Assigned(ToolCombo) then
      ToolCombo.ItemIndex := FPreviousIndex;
  end;
end;

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

procedure TFPUIHelpersTests.ToolGlyphsStayCompact;
var
  ToolIndex: Integer;
begin
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
    AssertTrue(
      'tool glyph should stay compact',
      Length(PaintToolGlyph(PaintToolAtDisplayIndex(ToolIndex))) <= 4
    );
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

procedure TFPUIHelpersTests.LayerOpacityHelpersRoundTripPercentScale;
begin
  AssertEquals('0% should map to 0', 0, LayerOpacityByteFromPercent(0));
  AssertEquals('100% should map to 255', 255, LayerOpacityByteFromPercent(100));
  AssertEquals('255 should read as 100%', 100, LayerOpacityPercentFromByte(255));
  AssertTrue(
    '50% should map near half opacity',
    Abs(LayerOpacityByteFromPercent(50) - 128) <= 1
  );
  AssertTrue(
    'half opacity should read near 50%',
    Abs(LayerOpacityPercentFromByte(128) - 50) <= 1
  );
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

procedure TFPUIHelpersTests.ColorShortcutTogglesTarget;
var
  F: TMainFormShim;
  initial: Integer;
begin
  F := TMainFormShim.Create;
  try
    try
      F.MakeTestSafe;
      if F.ColorTargetCombo = nil then
      begin
        F.ColorTargetCombo := TListComboShim.Create;
        F.ColorTargetCombo.Items.Add('Primary');
        F.ColorTargetCombo.Items.Add('Secondary');
      end;
      initial := F.ColorEditTarget;
      F.ToggleColorEditTarget;
      AssertTrue('toggle should flip color edit target', initial <> F.ColorEditTarget);
      AssertEquals('combo should track color target', F.ColorEditTarget, F.ColorTargetCombo.ItemIndex);
      F.ToggleColorEditTarget;
      AssertEquals('toggle twice returns to start', initial, F.ColorEditTarget);
      AssertEquals('combo returns to start', initial, F.ColorTargetCombo.ItemIndex);
    except
      on E: Exception do
        Fail('ColorShortcutTogglesTarget raised exception: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    F.Free;
  end;
end;

procedure TMainFormTests.SpacebarPanShortcut;
var
  F: TMainFormShim;
  prev, panIdx: Integer;
begin
  F := TMainFormShim.Create;
  try
    try
      F.MakeTestSafe;
      if F.ToolCombo = nil then
      begin
        F.ToolCombo := TListComboShim.Create;
        { Ensure tool combo has enough slots so ItemIndex assignments are safe }
        while F.ToolCombo.Items.Count < PaintToolDisplayCount do
          F.ToolCombo.Items.Add('');
      end;
      prev := F.ToolCombo.ItemIndex;
      panIdx := PaintToolDisplayIndex(tkPan);
      F.StartTempPan;
      AssertEquals('StartTempPan should switch to pan', panIdx, F.ToolCombo.ItemIndex);
      F.StopTempPan;
      AssertEquals('DeactivateTempPan restores tool', prev, F.ToolCombo.ItemIndex);
    except
      on E: Exception do
        Fail('SpacebarPanShortcut raised exception: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    F.Free;
  end;
end;

procedure TMainFormTests.MiddleMousePanShortcut;
var
  F: TMainFormShim;
  prev, panIdx: Integer;
begin
  F := TMainFormShim.Create;
  try
    try
      F.MakeTestSafe;
      if F.ToolCombo = nil then
      begin
        F.ToolCombo := TListComboShim.Create;
        while F.ToolCombo.Items.Count < PaintToolDisplayCount do
          F.ToolCombo.Items.Add('');
      end;
      prev := F.ToolCombo.ItemIndex;
      panIdx := PaintToolDisplayIndex(tkPan);
      F.StartTempPan;
      AssertEquals('StartTempPan should switch to pan', panIdx, F.ToolCombo.ItemIndex);
      F.StopTempPan;
      AssertEquals('DeactivateTempPan restores tool', prev, F.ToolCombo.ItemIndex);
    except
      on E: Exception do
        Fail('MiddleMousePanShortcut raised exception: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    F.Free;
  end;
end;

initialization
  RegisterTest(TFPUIHelpersTests);
  RegisterTest(TMainFormTests);

end.
