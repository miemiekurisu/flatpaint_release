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
    procedure PaletteShortcutsFollowUtilityOrder;
    procedure PaletteChromeMetricsStayCompact;
    procedure PaletteDragTintDiffersFromRestTint;
    procedure ToolsPaletteUsesNarrowTwoColumnLayout;
    procedure SnapPaletteRectAlignsToNearbyWorkspaceEdges;
  end;

implementation

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

procedure TFPPaletteHelpersTests.PaletteShortcutsFollowUtilityOrder;
begin
  AssertEquals('tools shortcut', '1', PaletteShortcutDigit(pkTools));
  AssertEquals('colors shortcut', '2', PaletteShortcutDigit(pkColors));
  AssertEquals('history shortcut', '3', PaletteShortcutDigit(pkHistory));
  AssertEquals('layers shortcut', '4', PaletteShortcutDigit(pkLayers));
end;

procedure TFPPaletteHelpersTests.PaletteChromeMetricsStayCompact;
begin
  AssertEquals('header height', 22, PaletteHeaderHeight);
  AssertTrue('toolbar should differ from canvas', ToolbarBackgroundColor <> CanvasBackgroundColor);
  AssertTrue('workspace should differ from canvas', WorkspaceBackgroundColor <> CanvasBackgroundColor);
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

initialization
  RegisterTest(TFPPaletteHelpersTests);

end.
