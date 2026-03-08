unit fptoolbarhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, Types, FPToolbarHelpers;

type
  TFPToolbarHelpersTests = class(TTestCase)
  published
    procedure ToolbarVerticalBandsStayAligned;
    procedure LeftCommandGroupsUseConsistentSpacing;
    procedure FileGroupStaysWideEnoughForIconLabels;
    procedure RightClustersStayAnchoredAndSeparated;
    procedure ZoomControlsFitInsideZoomCluster;
  end;

implementation

procedure TFPToolbarHelpersTests.ToolbarVerticalBandsStayAligned;
begin
  AssertEquals('top toolbar height accommodates options bar', 88, TopToolbarHeight);
  AssertEquals('title band should stay at mac-style compact height', 24, ToolbarTitleBandHeight);
  AssertEquals('command row should begin just below the title band', ToolbarTitleBandHeight, ToolbarRowTop);
  AssertTrue('command row should fit inside top panel',
    ToolbarRowTop + ToolbarRowHeight <= TopToolbarHeight);
  AssertEquals('options bar should sit below command row', 56, OptionsBarTop);
  AssertEquals('options bar should have comfortable height', 32, OptionsBarHeight);
  AssertTrue('options bar should fit inside top panel',
    OptionsBarTop + OptionsBarHeight <= TopToolbarHeight);
end;

procedure TFPToolbarHelpersTests.LeftCommandGroupsUseConsistentSpacing;
var
  FileRect: TRect;
  EditRect: TRect;
  UndoRect: TRect;
begin
  FileRect := ToolbarFileGroupRect;
  EditRect := ToolbarEditGroupRect;
  UndoRect := ToolbarUndoGroupRect;

  AssertEquals('file group keeps left margin', ToolbarLeftMargin, FileRect.Left);
  AssertEquals('file->edit gap stays even', ToolbarSectionGap, EditRect.Left - FileRect.Right);
  AssertEquals('edit->undo gap stays even', ToolbarSectionGap, UndoRect.Left - EditRect.Right);
  AssertEquals('file/edit heights match', FileRect.Bottom - FileRect.Top, EditRect.Bottom - EditRect.Top);
  AssertEquals('edit/undo heights match', EditRect.Bottom - EditRect.Top, UndoRect.Bottom - UndoRect.Top);
  AssertEquals('all left command groups share row top', ToolbarRowTop, FileRect.Top);
  AssertEquals('all left command groups share row top', ToolbarRowTop, EditRect.Top);
  AssertEquals('all left command groups share row top', ToolbarRowTop, UndoRect.Top);
end;

procedure TFPToolbarHelpersTests.FileGroupStaysWideEnoughForIconLabels;
begin
  AssertTrue(
    'file group should stay wide enough for icon-plus-label buttons',
    ToolbarFileGroupWidth >= 240
  );
end;

procedure TFPToolbarHelpersTests.RightClustersStayAnchoredAndSeparated;
var
  PaletteRect: TRect;
  ZoomRect: TRect;
  DividerRect: TRect;
begin
  PaletteRect := ToolbarPaletteGroupRect;
  ZoomRect := ToolbarZoomGroupRect;
  DividerRect := ToolbarDividerAfterRect(PaletteRect);

  AssertEquals('zoom cluster should be anchored to the right edge margin',
    DefaultToolbarHostWidth - ToolbarRightMargin,
    ZoomRect.Right);
  AssertEquals('palette->zoom gap stays even',
    ToolbarSectionGap,
    ZoomRect.Left - PaletteRect.Right);
  AssertEquals('palette divider should sit in the middle of the palette->zoom gap',
    PaletteRect.Right + (ToolbarSectionGap div 2),
    DividerRect.Left);
  AssertEquals('right clusters share row top', ToolbarRowTop, PaletteRect.Top);
  AssertEquals('right clusters share row top', ToolbarRowTop, ZoomRect.Top);
end;

procedure TFPToolbarHelpersTests.ZoomControlsFitInsideZoomCluster;
var
  ZoomRect: TRect;
  ZoomOutRect: TRect;
  ZoomComboRect: TRect;
  ZoomInRect: TRect;
begin
  ZoomRect := ToolbarZoomGroupRect;
  ZoomOutRect := ToolbarZoomOutButtonRect(ZoomRect);
  ZoomComboRect := ToolbarZoomComboRect(ZoomRect);
  ZoomInRect := ToolbarZoomInButtonRect(ZoomRect);

  AssertTrue('zoom out button should stay inside zoom group', (ZoomOutRect.Left >= ZoomRect.Left) and (ZoomOutRect.Right <= ZoomRect.Right));
  AssertTrue('zoom combo should stay inside zoom group', (ZoomComboRect.Left >= ZoomRect.Left) and (ZoomComboRect.Right <= ZoomRect.Right));
  AssertTrue('zoom in button should stay inside zoom group', (ZoomInRect.Left >= ZoomRect.Left) and (ZoomInRect.Right <= ZoomRect.Right));
  AssertTrue('zoom out should stay left of combo', ZoomOutRect.Right < ZoomComboRect.Left);
  AssertTrue('zoom combo should stay left of zoom in', ZoomComboRect.Right < ZoomInRect.Left);
  AssertEquals('zoom buttons share standard height', ToolbarButtonHeight, ZoomOutRect.Bottom - ZoomOutRect.Top);
  AssertEquals('zoom buttons share standard height', ToolbarButtonHeight, ZoomInRect.Bottom - ZoomInRect.Top);
  AssertEquals('zoom combo keeps compact control height', ToolbarZoomComboHeight, ZoomComboRect.Bottom - ZoomComboRect.Top);
  AssertTrue('zoom combo vertical center within 1 px of button center (macOS visual nudge)',
    Abs(((ZoomOutRect.Top + ZoomOutRect.Bottom) div 2) -
        ((ZoomComboRect.Top + ZoomComboRect.Bottom) div 2)) <= 1);
end;

initialization
  RegisterTest(TFPToolbarHelpersTests);
end.
