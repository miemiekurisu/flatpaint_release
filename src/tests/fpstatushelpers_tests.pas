unit fpstatushelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPStatusHelpers;

type
  TFPStatusHelpersTests = class(TTestCase)
  published
    procedure ComputedPanelWidthsStayWithinAvailableWidth;
    procedure ZoomPanelStaysAsDedicatedRightCluster;
    procedure ZoomPanelLeftEqualsLeadingPanelWidths;
    procedure ProgressPanelBridgesLayerAndUnitSlots;
    procedure ProgressWidgetsStayInsideProgressPanel;
    procedure ZoomLabelWidthLeavesReadableCaptionSpace;
    procedure ZoomTrackWidthStaysInsideZoomPanel;
  end;

implementation

procedure TFPStatusHelpersTests.ComputedPanelWidthsStayWithinAvailableWidth;
var
  Widths: TStatusPanelWidthArray;
  PanelIndex: Integer;
  TotalWidth: Integer;
begin
  ComputeStatusPanelWidths(960, Widths);
  TotalWidth := 0;
  for PanelIndex := Low(Widths) to High(Widths) do
  begin
    AssertTrue('width should be non-negative', Widths[PanelIndex] >= 0);
    Inc(TotalWidth, Widths[PanelIndex]);
  end;
  AssertEquals('panel widths should fully partition available width', 960, TotalWidth);
end;

procedure TFPStatusHelpersTests.ZoomPanelStaysAsDedicatedRightCluster;
var
  Widths: TStatusPanelWidthArray;
begin
  ComputeStatusPanelWidths(960, Widths);
  AssertTrue('zoom cluster should remain wide enough', Widths[6] >= 176);
  AssertTrue('zoom cluster should stay bounded', Widths[6] <= 236);
end;

procedure TFPStatusHelpersTests.ZoomPanelLeftEqualsLeadingPanelWidths;
var
  Widths: TStatusPanelWidthArray;
begin
  ComputeStatusPanelWidths(1024, Widths);
  AssertEquals(
    'zoom panel starts after the first six panels',
    Widths[0] + Widths[1] + Widths[2] + Widths[3] + Widths[4] + Widths[5],
    ZoomStatusPanelLeft(Widths)
  );
end;

procedure TFPStatusHelpersTests.ProgressPanelBridgesLayerAndUnitSlots;
var
  Widths: TStatusPanelWidthArray;
begin
  ComputeStatusPanelWidths(1024, Widths);
  AssertEquals(
    'progress region should start after the first four panels',
    Widths[0] + Widths[1] + Widths[2] + Widths[3],
    ProgressStatusPanelLeft(Widths)
  );
  AssertEquals(
    'progress region should consume the layer and units slots',
    Widths[4] + Widths[5],
    ProgressStatusPanelWidth(Widths)
  );
end;

procedure TFPStatusHelpersTests.ProgressWidgetsStayInsideProgressPanel;
var
  Widths: TStatusPanelWidthArray;
  ProgressWidth: Integer;
begin
  ComputeStatusPanelWidths(960, Widths);
  ProgressWidth := ProgressStatusPanelWidth(Widths);
  AssertTrue('progress panel should be visible', ProgressWidth > 0);
  AssertTrue(
    'progress label should fit inside progress panel',
    ProgressLabelWidth(ProgressWidth) <= ProgressWidth
  );
  AssertTrue(
    'progress bar should fit beside the label',
    ProgressLabelWidth(ProgressWidth) + ProgressBarWidth(ProgressWidth) + 12 <= ProgressWidth
  );
end;

procedure TFPStatusHelpersTests.ZoomLabelWidthLeavesReadableCaptionSpace;
begin
  AssertEquals('small label width', 44, ZoomLabelWidth(90));
  AssertEquals('large label width', 60, ZoomLabelWidth(180));
end;

procedure TFPStatusHelpersTests.ZoomTrackWidthStaysInsideZoomPanel;
begin
  AssertEquals('minimum track width', 72, ZoomTrackWidth(40));
  AssertEquals('track leaves room for label', 106, ZoomTrackWidth(180));
end;

initialization
  RegisterTest(TFPStatusHelpersTests);
end.
