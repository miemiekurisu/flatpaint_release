unit fpstatushelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPStatusHelpers;

type
  TFPStatusHelpersTests = class(TTestCase)
  published
    procedure ComputedPanelWidthsStayWithinAvailableWidth;
    procedure ZoomPanelLeftEqualsLeadingPanelWidths;
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

procedure TFPStatusHelpersTests.ZoomTrackWidthStaysInsideZoomPanel;
begin
  AssertEquals('minimum track width', 72, ZoomTrackWidth(40));
  AssertEquals('track leaves room for label', 122, ZoomTrackWidth(180));
end;

initialization
  RegisterTest(TFPStatusHelpersTests);
end.
