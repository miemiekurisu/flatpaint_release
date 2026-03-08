unit fppalettehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, Types, FPDocument, FPUIHelpers, FPPaletteHelpers;

type
  TFPPaletteHelpersTests = class(TTestCase)
  published
    procedure PaletteTitlesAreNonEmpty;
    procedure DefaultPaletteRectsMatchCornerClusters;
    procedure DefaultPaletteRectsDoNotOverlap;
    procedure WorkspaceAwareDefaultRectsStaySeparated;
    procedure PaletteShortcutsFollowShortcutPolicy;
    procedure PaletteShortcutLabelsStayReadable;
    procedure PaletteChromeMetricsStayCompact;
    procedure LightThemeUsesBrightMacOSChrome;
    procedure ChromeAccentBandsStayDistinct;
    procedure PaletteDragTintDiffersFromRestTint;
    procedure ToolsPaletteUsesNarrowTwoColumnLayout;
    procedure SnapPaletteRectAlignsToNearbyWorkspaceEdges;
    procedure ClampWorkspaceRectReservesRulerBands;
    procedure ClampPaletteRectHonorsRulerBands;
    procedure ColorsPanelFitsSystemPickerAndSliderRows;
    procedure PaletteHeightsFitDeeperPanelControls;
    procedure ToolsPaletteHeightFitsAllVisibleToolRows;
  end;

implementation

function ColorBrightness(AColor: LongInt): Integer;
begin
  Result := (
    (AColor and $FF) +
    ((AColor shr 8) and $FF) +
    ((AColor shr 16) and $FF)
  ) div 3;
end;

procedure TFPPaletteHelpersTests.PaletteTitlesAreNonEmpty;
var
  PaletteKind: TPaletteKind;
begin
  for PaletteKind := Low(TPaletteKind) to High(TPaletteKind) do
    AssertTrue('palette title missing', PaletteTitle(PaletteKind) <> '');
end;

procedure TFPPaletteHelpersTests.DefaultPaletteRectsMatchCornerClusters;
begin
  AssertTrue(
    'tools should be left of layers',
    PaletteDefaultRect(pkTools).Left < PaletteDefaultRect(pkLayers).Left
  );
  AssertTrue(
    'colors should sit below tools',
    PaletteDefaultRect(pkColors).Top > PaletteDefaultRect(pkTools).Top
  );
  AssertTrue(
    'history should sit above layers',
    PaletteDefaultRect(pkHistory).Top < PaletteDefaultRect(pkLayers).Top
  );
end;

procedure TFPPaletteHelpersTests.DefaultPaletteRectsDoNotOverlap;
var
  ToolsRect: TRect;
  ColorsRect: TRect;
  HistoryRect: TRect;
  LayersRect: TRect;
begin
  ToolsRect := PaletteDefaultRect(pkTools);
  ColorsRect := PaletteDefaultRect(pkColors);
  HistoryRect := PaletteDefaultRect(pkHistory);
  LayersRect := PaletteDefaultRect(pkLayers);

  AssertTrue(
    'tools and colors should not overlap',
    (ToolsRect.Right <= ColorsRect.Left) or
    (ColorsRect.Right <= ToolsRect.Left) or
    (ToolsRect.Bottom <= ColorsRect.Top) or
    (ColorsRect.Bottom <= ToolsRect.Top)
  );
  AssertTrue(
    'history and layers should not overlap',
    (HistoryRect.Right <= LayersRect.Left) or
    (LayersRect.Right <= HistoryRect.Left) or
    (HistoryRect.Bottom <= LayersRect.Top) or
    (LayersRect.Bottom <= HistoryRect.Top)
  );
end;

procedure TFPPaletteHelpersTests.WorkspaceAwareDefaultRectsStaySeparated;
var
  ToolsRect: TRect;
  ColorsRect: TRect;
  HistoryRect: TRect;
  LayersRect: TRect;
begin
  ToolsRect := PaletteDefaultRectForWorkspace(pkTools, Rect(0, 0, 1320, 780));
  ColorsRect := PaletteDefaultRectForWorkspace(pkColors, Rect(0, 0, 1320, 780));
  HistoryRect := PaletteDefaultRectForWorkspace(pkHistory, Rect(0, 0, 1320, 780));
  LayersRect := PaletteDefaultRectForWorkspace(pkLayers, Rect(0, 0, 1320, 780));

  AssertTrue(
    'colors should not cover tools',
    (ColorsRect.Top >= ToolsRect.Bottom) or (ColorsRect.Left >= ToolsRect.Right)
  );
  AssertTrue('layers should sit below history', LayersRect.Top >= HistoryRect.Bottom);
  AssertTrue('right stack should stay inside workspace', LayersRect.Right <= 1320);
end;

procedure TFPPaletteHelpersTests.PaletteShortcutsFollowShortcutPolicy;
begin
  AssertEquals('tools shortcut', '1', PaletteShortcutDigit(pkTools));
  AssertEquals('colors shortcut', '2', PaletteShortcutDigit(pkColors));
  AssertEquals('layers shortcut', '3', PaletteShortcutDigit(pkLayers));
  AssertEquals('history shortcut', '4', PaletteShortcutDigit(pkHistory));
end;

procedure TFPPaletteHelpersTests.PaletteShortcutLabelsStayReadable;
begin
  AssertEquals('tools label', 'Cmd+1', PaletteShortcutLabel(pkTools));
  AssertEquals('colors label', 'Cmd+2', PaletteShortcutLabel(pkColors));
  AssertEquals('layers label', 'Cmd+3', PaletteShortcutLabel(pkLayers));
  AssertEquals('history label', 'Cmd+4', PaletteShortcutLabel(pkHistory));
end;

procedure TFPPaletteHelpersTests.PaletteChromeMetricsStayCompact;
begin
  AssertEquals('header height', 22, PaletteHeaderHeight);
  AssertTrue('toolbar should differ from canvas', ToolbarBackgroundColor <> CanvasBackgroundColor);
  AssertTrue('workspace should differ from canvas', WorkspaceBackgroundColor <> CanvasBackgroundColor);
end;

procedure TFPPaletteHelpersTests.LightThemeUsesBrightMacOSChrome;
begin
  AssertTrue('toolbar should be bright', ColorBrightness(ToolbarBackgroundColor) >= 235);
  AssertTrue('workspace should be bright', ColorBrightness(WorkspaceBackgroundColor) >= 230);
  AssertTrue(
    'canvas should stay darker than workspace',
    ColorBrightness(CanvasBackgroundColor) < ColorBrightness(WorkspaceBackgroundColor)
  );
  AssertTrue(
    'palette cards should stay brighter than canvas',
    ColorBrightness(PaletteSurfaceColor(pkTools, False)) > ColorBrightness(CanvasBackgroundColor)
  );
  AssertTrue(
    'palette header should stay distinct from body',
    PaletteHeaderColor(pkTools, False) <> PaletteSurfaceColor(pkTools, False)
  );
end;

procedure TFPPaletteHelpersTests.ChromeAccentBandsStayDistinct;
begin
  AssertTrue('tab strip should differ from toolbar', TabStripBackgroundColor <> ToolbarBackgroundColor);
  AssertTrue('status bar should differ from tab strip', StatusBarBackgroundColor <> TabStripBackgroundColor);
  AssertTrue(
    'selection accent should differ from list background',
    PaletteSelectionColor <> PaletteListBackgroundColor
  );
  AssertTrue(
    'selection text should differ from regular text',
    PaletteSelectionTextColor <> ChromeTextColor
  );
end;

procedure TFPPaletteHelpersTests.PaletteDragTintDiffersFromRestTint;
begin
  AssertTrue(
    'surface drag tint should differ',
    PaletteSurfaceColor(pkTools, False) <> PaletteSurfaceColor(pkTools, True)
  );
  AssertTrue(
    'header drag tint should differ',
    PaletteHeaderColor(pkLayers, False) <> PaletteHeaderColor(pkLayers, True)
  );
end;

procedure TFPPaletteHelpersTests.ToolsPaletteUsesNarrowTwoColumnLayout;
begin
  AssertEquals('tools palette columns', 2, ToolsPaletteColumnCount);
  AssertTrue(
    'tools palette should be visibly narrower than colors',
    (PaletteDefaultRect(pkTools).Right - PaletteDefaultRect(pkTools).Left) <
    (PaletteDefaultRect(pkColors).Right - PaletteDefaultRect(pkColors).Left)
  );
end;

procedure TFPPaletteHelpersTests.SnapPaletteRectAlignsToNearbyWorkspaceEdges;
var
  Snapped: TRect;
begin
  Snapped := SnapPaletteRect(Rect(4, 6, 104, 86), Rect(0, 0, 300, 220));
  AssertEquals('snap left', 0, Snapped.Left);
  AssertEquals('snap top', 0, Snapped.Top);
  AssertEquals('preserve width', 100, Snapped.Right - Snapped.Left);

  Snapped := SnapPaletteRect(Rect(206, 150, 306, 230), Rect(0, 0, 300, 220));
  AssertEquals('snap right', 300, Snapped.Right);
  AssertEquals('snap bottom', 220, Snapped.Bottom);
end;

procedure TFPPaletteHelpersTests.ClampWorkspaceRectReservesRulerBands;
var
  Clamped: TRect;
begin
  Clamped := PaletteClampWorkspaceRect(Rect(0, 0, 300, 220), True);
  AssertEquals('ruler-aware left inset', 18, Clamped.Left);
  AssertEquals('ruler-aware top inset', 18, Clamped.Top);
  AssertEquals('right edge unchanged', 300, Clamped.Right);
  AssertEquals('bottom edge unchanged', 220, Clamped.Bottom);

  Clamped := PaletteClampWorkspaceRect(Rect(0, 0, 300, 220), False);
  AssertEquals('no-ruler left inset', 0, Clamped.Left);
  AssertEquals('no-ruler top inset', 0, Clamped.Top);
end;

procedure TFPPaletteHelpersTests.ClampPaletteRectHonorsRulerBands;
var
  Clamped: TRect;
begin
  Clamped := ClampPaletteRectToWorkspace(
    Rect(0, 0, 100, 80),
    Rect(0, 0, 300, 220),
    True
  );
  AssertEquals('palette left should not cover vertical ruler', 18, Clamped.Left);
  AssertEquals('palette top should not cover horizontal ruler', 18, Clamped.Top);

  Clamped := ClampPaletteRectToWorkspace(
    Rect(-12, -8, 88, 72),
    Rect(0, 0, 300, 220),
    False
  );
  AssertEquals('palette without rulers should clamp to workspace left', 0, Clamped.Left);
  AssertEquals('palette without rulers should clamp to workspace top', 0, Clamped.Top);
end;

procedure TFPPaletteHelpersTests.ColorsPanelFitsSystemPickerAndSliderRows;
var
  R: TRect;
begin
  { Colors now uses a slimmer companion palette around the system picker:
    stacked swatches, compact hex labels, and HSV/A strips. }
  R := PaletteDefaultRect(pkColors);
  AssertTrue('colors panel wide enough for compact controls', (R.Right - R.Left) >= 240);
  AssertTrue('colors panel tall enough for swatches and slider strips', (R.Bottom - R.Top) >= 280);
  AssertTrue('colors panel should stay compact after slimming the picker', (R.Bottom - R.Top) < 340);
end;

procedure TFPPaletteHelpersTests.PaletteHeightsFitDeeperPanelControls;
begin
  AssertTrue(
    'colors palette should be taller than the history panel',
    (PaletteDefaultRect(pkColors).Bottom - PaletteDefaultRect(pkColors).Top) >
    (PaletteDefaultRect(pkHistory).Bottom - PaletteDefaultRect(pkHistory).Top)
  );
  AssertTrue(
    'colors palette should be shorter than the tools palette after slimming the picker',
    (PaletteDefaultRect(pkColors).Bottom - PaletteDefaultRect(pkColors).Top) <
    (PaletteDefaultRect(pkTools).Bottom - PaletteDefaultRect(pkTools).Top)
  );
  AssertTrue(
    'layers palette should be tall enough for inline controls and list',
    (PaletteDefaultRect(pkLayers).Bottom - PaletteDefaultRect(pkLayers).Top) >= 300
  );
end;

procedure TFPPaletteHelpersTests.ToolsPaletteHeightFitsAllVisibleToolRows;
var
  ToolIndex: Integer;
  VisibleTools: Integer;
  RowCount: Integer;
  RequiredHeight: Integer;
  ToolsHeight: Integer;
const
  ContentTop = 30;
  ToolRowStride = 42;
  ToolButtonHeight = 40;
  BottomPadding = 8;
begin
  VisibleTools := 0;
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
    if PaintToolAtDisplayIndex(ToolIndex) <> tkZoom then
      Inc(VisibleTools);
  RowCount := (VisibleTools + ToolsPaletteColumnCount - 1) div ToolsPaletteColumnCount;
  if RowCount < 1 then
    RowCount := 1;
  RequiredHeight := ContentTop + (RowCount - 1) * ToolRowStride + ToolButtonHeight + BottomPadding;
  ToolsHeight := PaletteDefaultRect(pkTools).Bottom - PaletteDefaultRect(pkTools).Top;
  AssertTrue(
    'tools palette height should fit all visible tool rows',
    ToolsHeight >= RequiredHeight
  );
end;

initialization
  RegisterTest(TFPPaletteHelpersTests);

end.
