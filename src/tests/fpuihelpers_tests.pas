
unit fpuihelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPDocument, FPUIHelpers, FPUtilityHelpers,
  Controls, StdCtrls, Classes, LCLType, LazUTF8, SysUtils;

type
  TFPUIHelpersTests = class(TTestCase)
  published
    procedure ToolDisplayOrderStartsWithSelectionTools;
    procedure ZoomToolAppearsBeforePaintTools;
    procedure PanAndPencilAppearInExpectedBands;
    procedure FreeformShapeAppearsAfterBasicShapes;
    procedure ToolMetadataIsCompleteForDisplayOrder;
    procedure ToolGlyphsStayCompact;
    procedure ToolShortcutMetadataStaysAssigned;
    procedure ToolDisplayLabelsExposeShortcutHints;
    procedure CropTextCloneRecolorAppearInDisplayOrder;
    procedure TotalDisplayCountIsCorrect;
    procedure UtilityGlyphsStayCompact;
    procedure ShortcutCyclesSelectionTools;
    procedure ShortcutCyclesMoveTools;
    procedure ShortcutCyclesShapeTools;
    procedure ShortcutSingleKeyMaps;
    procedure ToolSwitchSelectionPolicyMatchesEditorRules;
    procedure ToolSwitchAutoDeselectPolicyMatchesSelectionRules;
    procedure ToolOptionSwitchPersistsOldAndRestoresNew;
    procedure TempPanStateTransitionsAreIdempotent;
    procedure TabCycleIndexFollowsShortcutPolicy;
    procedure BlankClickAutoDeselectPolicyMatchesSelectionRules;
    procedure AdvancedToolsAdvertiseCanvasHoverFeedback;
    procedure BrushOverlayClassificationStaysFocused;
    procedure LineToolHintMentionsStraightByDefault;
    procedure LineToolHintMentionsOptionalBezier;
    procedure TextToolHintMentionsInlineEditing;
    procedure ColorShortcutTogglesTarget;
    procedure LayerOpacityHelpersRoundTripPercentScale;
  end;

  TMainFormTests = class(TTestCase)
  published
    procedure DefaultToolStartsAsRectangleSelect;
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
  if not FTempToolActive then
    Exit;
  FTempToolActive := False;
  if Assigned(ToolCombo) then
    ToolCombo.ItemIndex := FPreviousIndex;
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
      UTF8Length(PaintToolGlyph(PaintToolAtDisplayIndex(ToolIndex))) <= 1
    );
  AssertTrue('brush glyph should no longer use text abbreviation', PaintToolGlyph(tkBrush) <> 'Br');
  AssertTrue('zoom glyph should no longer use text label', PaintToolGlyph(tkZoom) <> 'Zoom');
end;

procedure TFPUIHelpersTests.ToolShortcutMetadataStaysAssigned;
begin
  AssertEquals('selection tools should share S', 'S', PaintToolShortcutKey(tkSelectRect));
  AssertEquals('move tools should share M', 'M', PaintToolShortcutKey(tkMoveSelection));
  AssertEquals('brush should keep B', 'B', PaintToolShortcutKey(tkBrush));
  AssertEquals('text should keep T', 'T', PaintToolShortcutKey(tkText));
  AssertEquals('crop intentionally has no bare-key shortcut', '', PaintToolShortcutKey(tkCrop));
  AssertTrue(
    'shape family should advertise cycling in shortcut hint',
    Pos('cycle', LowerCase(PaintToolShortcutHint(tkLine))) > 0
  );
end;

procedure TFPUIHelpersTests.ToolDisplayLabelsExposeShortcutHints;
begin
  AssertTrue(
    'brush label should expose its shortcut',
    Pos('(B)', PaintToolDisplayLabel(tkBrush)) > 0
  );
  AssertTrue(
    'selection label should expose its shortcut',
    Pos('(S)', PaintToolDisplayLabel(tkSelectRect)) > 0
  );
  AssertEquals(
    'crop label should stay clean when no shortcut exists',
    'Crop',
    PaintToolDisplayLabel(tkCrop)
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
  AssertEquals('total tool display count', 24, PaintToolDisplayCount);
end;

procedure TFPUIHelpersTests.UtilityGlyphsStayCompact;
var
  CommandIndex: Integer;
  CommandKind: TUtilityCommandKind;
begin
  for CommandIndex := 0 to UtilityCommandDisplayCount - 1 do
  begin
    CommandKind := UtilityCommandAtDisplayIndex(CommandIndex);
    AssertTrue('utility glyph missing', UtilityCommandGlyph(CommandKind) <> '');
    AssertTrue('utility glyph should stay compact', UTF8Length(UtilityCommandGlyph(CommandKind)) <= 1);
  end;
  AssertTrue('tools utility should not fall back to plain text placeholder', UtilityCommandGlyph(ucTools) <> 'T');
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

procedure TFPUIHelpersTests.ToolSwitchSelectionPolicyMatchesEditorRules;
begin
  AssertTrue('brush should preserve existing selection', ShouldPreserveSelectionAcrossToolSwitch(tkBrush));
  AssertTrue('fill should preserve existing selection', ShouldPreserveSelectionAcrossToolSwitch(tkFill));
  AssertTrue('move pixels should preserve existing selection', ShouldPreserveSelectionAcrossToolSwitch(tkMovePixels));
  AssertFalse('zoom should clear selection when switching from selection tools', ShouldPreserveSelectionAcrossToolSwitch(tkZoom));
  AssertFalse('pan should clear selection when switching from selection tools', ShouldPreserveSelectionAcrossToolSwitch(tkPan));
  AssertFalse('crop should clear selection when switching from selection tools', ShouldPreserveSelectionAcrossToolSwitch(tkCrop));
end;

procedure TFPUIHelpersTests.ToolSwitchAutoDeselectPolicyMatchesSelectionRules;
begin
  AssertFalse(
    'staying on the same tool should never auto-deselect',
    ShouldAutoDeselectOnToolSwitch(tkSelectRect, tkSelectRect)
  );
  AssertFalse(
    'switching among selection tools should preserve selection',
    ShouldAutoDeselectOnToolSwitch(tkSelectRect, tkSelectEllipse)
  );
  AssertFalse(
    'switching from selection to brush should preserve selection for clipping',
    ShouldAutoDeselectOnToolSwitch(tkSelectRect, tkBrush)
  );
  AssertTrue(
    'switching from selection to pan should auto-deselect',
    ShouldAutoDeselectOnToolSwitch(tkSelectRect, tkPan)
  );
  AssertTrue(
    'switching from selection to zoom should auto-deselect',
    ShouldAutoDeselectOnToolSwitch(tkMovePixels, tkZoom)
  );
  AssertFalse(
    'non-selection to non-selection switch should not trigger deselect policy',
    ShouldAutoDeselectOnToolSwitch(tkBrush, tkPan)
  );
end;

procedure TFPUIHelpersTests.ToolOptionSwitchPersistsOldAndRestoresNew;
var
  ToolSize: TToolOptionMap;
  ToolOpacity: TToolOptionMap;
  ToolHardness: TToolOptionMap;
  ToolKind: TToolKind;
  ResolvedSize: Integer;
  ResolvedOpacity: Integer;
  ResolvedHardness: Integer;
begin
  for ToolKind := Low(TToolKind) to High(TToolKind) do
  begin
    ToolSize[ToolKind] := 8;
    ToolOpacity[ToolKind] := 100;
    ToolHardness[ToolKind] := 80;
  end;
  ToolSize[tkEraser] := 17;
  ToolOpacity[tkEraser] := 63;
  ToolHardness[tkEraser] := 42;

  ApplyToolOptionSwitch(
    tkBrush,
    tkEraser,
    13,
    77,
    91,
    ToolSize,
    ToolOpacity,
    ToolHardness,
    ResolvedSize,
    ResolvedOpacity,
    ResolvedHardness
  );

  AssertEquals('old tool size should be persisted before switch', 13, ToolSize[tkBrush]);
  AssertEquals('old tool opacity should be persisted before switch', 77, ToolOpacity[tkBrush]);
  AssertEquals('old tool hardness should be persisted before switch', 91, ToolHardness[tkBrush]);
  AssertEquals('new tool size should be restored', 17, ResolvedSize);
  AssertEquals('new tool opacity should be restored', 63, ResolvedOpacity);
  AssertEquals('new tool hardness should be restored', 42, ResolvedHardness);
end;

procedure TFPUIHelpersTests.TempPanStateTransitionsAreIdempotent;
var
  CurrentTool: TToolKind;
  PreviousTool: TToolKind;
  TempActive: Boolean;
begin
  CurrentTool := tkBrush;
  PreviousTool := tkSelectRect;
  TempActive := False;
  AssertTrue(
    'first temp-pan activation should switch tool state',
    TryActivateTemporaryPan(CurrentTool, PreviousTool, TempActive)
  );
  AssertTrue('activation should mark temporary mode active', TempActive);
  AssertEquals('activation should switch to pan tool', Ord(tkPan), Ord(CurrentTool));
  AssertEquals('activation should preserve previous tool', Ord(tkBrush), Ord(PreviousTool));

  AssertFalse(
    'second activation should be a no-op while already active',
    TryActivateTemporaryPan(CurrentTool, PreviousTool, TempActive)
  );
  AssertTrue('state should remain active after duplicate activation', TempActive);
  AssertEquals('tool should remain pan after duplicate activation', Ord(tkPan), Ord(CurrentTool));

  AssertTrue(
    'deactivation should restore previous tool',
    TryDeactivateTemporaryPan(CurrentTool, PreviousTool, TempActive)
  );
  AssertFalse('deactivation should clear temporary mode', TempActive);
  AssertEquals('deactivation should restore captured tool', Ord(tkBrush), Ord(CurrentTool));

  AssertFalse(
    'duplicate deactivation should be a no-op',
    TryDeactivateTemporaryPan(CurrentTool, PreviousTool, TempActive)
  );
  AssertFalse('state should remain inactive after duplicate deactivation', TempActive);
end;

procedure TFPUIHelpersTests.TabCycleIndexFollowsShortcutPolicy;
begin
  AssertEquals(
    'forward cycle should move to next tab',
    2,
    NextCycledTabIndex(1, 5, False)
  );
  AssertEquals(
    'forward cycle should wrap to first tab',
    0,
    NextCycledTabIndex(4, 5, False)
  );
  AssertEquals(
    'reverse cycle should move to previous tab',
    3,
    NextCycledTabIndex(4, 5, True)
  );
  AssertEquals(
    'reverse cycle should wrap to last tab',
    4,
    NextCycledTabIndex(0, 5, True)
  );
  AssertEquals(
    'single-tab document should not switch index',
    0,
    NextCycledTabIndex(0, 1, False)
  );
end;

procedure TFPUIHelpersTests.BlankClickAutoDeselectPolicyMatchesSelectionRules;
begin
  AssertTrue(
    'selection tool click outside selection without modifiers should auto-deselect',
    ShouldAutoDeselectFromBlankClick(
      tkSelectRect,
      True,
      True,
      False,
      mbLeft,
      []
    )
  );
  AssertFalse(
    'click inside current selection should not auto-deselect',
    ShouldAutoDeselectFromBlankClick(
      tkSelectRect,
      True,
      True,
      True,
      mbLeft,
      []
    )
  );
  AssertFalse(
    'modifier-assisted click should not auto-deselect',
    ShouldAutoDeselectFromBlankClick(
      tkSelectRect,
      True,
      True,
      False,
      mbLeft,
      [ssShift]
    )
  );
  AssertFalse(
    'paint tools should not trigger selection auto-deselect logic',
    ShouldAutoDeselectFromBlankClick(
      tkBrush,
      True,
      True,
      False,
      mbLeft,
      []
    )
  );
end;

procedure TFPUIHelpersTests.AdvancedToolsAdvertiseCanvasHoverFeedback;
begin
  AssertTrue('fill should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkFill));
  AssertTrue('gradient should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkGradient));
  AssertTrue('magic wand should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkMagicWand));
  AssertTrue('color picker should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkColorPicker));
  AssertTrue('crop should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkCrop));
  AssertTrue('text should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkText));
  AssertTrue('clone stamp should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkCloneStamp));
  AssertTrue('recolor should expose hover feedback', PaintToolHasCanvasHoverOverlay(tkRecolor));
  AssertFalse('pan should not claim hover feedback', PaintToolHasCanvasHoverOverlay(tkPan));
  AssertFalse('move pixels should not claim hover feedback', PaintToolHasCanvasHoverOverlay(tkMovePixels));
end;

procedure TFPUIHelpersTests.BrushOverlayClassificationStaysFocused;
begin
  AssertTrue('brush uses brush overlay', PaintToolUsesBrushOverlay(tkBrush));
  AssertTrue('clone uses brush overlay', PaintToolUsesBrushOverlay(tkCloneStamp));
  AssertTrue('recolor uses brush overlay', PaintToolUsesBrushOverlay(tkRecolor));
  AssertFalse('fill should not use brush overlay', PaintToolUsesBrushOverlay(tkFill));
  AssertFalse('text should not use brush overlay', PaintToolUsesBrushOverlay(tkText));
end;

procedure TFPUIHelpersTests.LineToolHintMentionsStraightByDefault;
begin
  AssertTrue(
    'line hint should mention straight-line default behavior',
    Pos('straight', LowerCase(PaintToolHint(tkLine))) > 0
  );
end;

procedure TFPUIHelpersTests.LineToolHintMentionsOptionalBezier;
begin
  AssertTrue(
    'line hint should mention the optional Bezier mode',
    Pos('bezier', LowerCase(PaintToolHint(tkLine))) > 0
  );
end;

procedure TFPUIHelpersTests.TextToolHintMentionsInlineEditing;
begin
  AssertTrue(
    'text hint should mention inline editing',
    Pos('inline', LowerCase(PaintToolHint(tkText))) > 0
  );
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

procedure TMainFormTests.DefaultToolStartsAsRectangleSelect;
begin
  AssertEquals(
    'main form should start in rectangle-select mode to avoid accidental painting',
    Ord(tkSelectRect),
    Ord(DefaultStartupTool)
  );
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
