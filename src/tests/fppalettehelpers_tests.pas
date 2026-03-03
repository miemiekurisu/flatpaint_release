unit fppalettehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, Types, FPPaletteHelpers;

type
  TFPPaletteHelpersTests = class(TTestCase)
  published
    procedure PaletteTitlesAreNonEmpty;
    procedure DefaultPaletteRectsMatchCornerClusters;
    procedure DefaultPaletteRectsDoNotOverlap;
    procedure WorkspaceAwareDefaultRectsStaySeparated;
    procedure PaletteShortcutsFollowShortcutPolicy;
    procedure PaletteChromeMetricsStayCompact;
    procedure LightThemeUsesBrightMacOSChrome;
    procedure ChromeAccentBandsStayDistinct;
    procedure PaletteDragTintDiffersFromRestTint;
    procedure ToolsPaletteUsesNarrowTwoColumnLayout;
    procedure SnapPaletteRectAlignsToNearbyWorkspaceEdges;
    procedure ColorsPanelFitsRGBASpinsAndHexField;
    procedure PaletteHeightsFitDeeperPanelControls;
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

procedure TFPPaletteHelpersTests.ColorsPanelFitsRGBASpinsAndHexField;
var
  R: TRect;
begin
  { Colors panel was expanded to fit RGB/RGBA edits plus deeper controls.
    Minimum width required for the current control grid is about 240px. }
  R := PaletteDefaultRect(pkColors);
  AssertTrue('colors panel wide enough for RGBA spins', (R.Right - R.Left) >= 240);
  AssertTrue('colors panel tall enough for RGB/HSV rows', (R.Bottom - R.Top) >= 360);
end;

procedure TFPPaletteHelpersTests.PaletteHeightsFitDeeperPanelControls;
begin
  AssertTrue(
    'colors palette should be taller than the history panel',
    (PaletteDefaultRect(pkColors).Bottom - PaletteDefaultRect(pkColors).Top) >
    (PaletteDefaultRect(pkHistory).Bottom - PaletteDefaultRect(pkHistory).Top)
  );
  AssertTrue(
    'layers palette should be tall enough for inline controls and list',
    (PaletteDefaultRect(pkLayers).Bottom - PaletteDefaultRect(pkLayers).Top) >= 300
  );
end;

initialization
  RegisterTest(TFPPaletteHelpersTests);

end.
