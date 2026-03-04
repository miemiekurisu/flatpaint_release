unit FPStatusHelpers;

{$mode objfpc}{$H+}

interface

const
  StatusPanelCount = 7;

type
  TStatusPanelWidthArray = array[0..StatusPanelCount - 1] of Integer;

procedure ComputeStatusPanelWidths(ATotalWidth: Integer; out AWidths: TStatusPanelWidthArray);
function ZoomStatusPanelLeft(const AWidths: TStatusPanelWidthArray): Integer;
function ProgressStatusPanelLeft(const AWidths: TStatusPanelWidthArray): Integer;
function ProgressStatusPanelWidth(const AWidths: TStatusPanelWidthArray): Integer;
function ProgressLabelWidth(AProgressPanelWidth: Integer): Integer;
function ProgressBarWidth(AProgressPanelWidth: Integer): Integer;
function ZoomLabelWidth(AZoomPanelWidth: Integer): Integer;
function ZoomTrackWidth(AZoomPanelWidth: Integer): Integer;

implementation

uses
  Math;

const
  StatusTextPanelWeights: array[0..StatusPanelCount - 2] of Integer = (
    24, 17, 16, 15, 10, 8
  );
  StatusTextPanelWeightTotal = 90;
  ZoomPanelMinWidth = 176;
  ZoomPanelPreferredWidth = 204;
  ZoomPanelMaxWidth = 236;

procedure ComputeStatusPanelWidths(ATotalWidth: Integer; out AWidths: TStatusPanelWidthArray);
var
  AvailableWidth: Integer;
  TextWidth: Integer;
  ZoomWidth: Integer;
  PanelIndex: Integer;
  ConsumedWidth: Integer;
begin
  AvailableWidth := Max(0, ATotalWidth);
  if AvailableWidth < ZoomPanelMinWidth then
    ZoomWidth := AvailableWidth
  else
    ZoomWidth := EnsureRange(
      Min(AvailableWidth, ZoomPanelPreferredWidth),
      ZoomPanelMinWidth,
      Min(AvailableWidth, ZoomPanelMaxWidth)
    );
  TextWidth := Max(0, AvailableWidth - ZoomWidth);
  ConsumedWidth := 0;
  for PanelIndex := 0 to StatusPanelCount - 2 do
  begin
    AWidths[PanelIndex] := (TextWidth * StatusTextPanelWeights[PanelIndex]) div StatusTextPanelWeightTotal;
    Inc(ConsumedWidth, AWidths[PanelIndex]);
  end;
  AWidths[StatusPanelCount - 1] := Max(0, AvailableWidth - ConsumedWidth);
end;

function ZoomStatusPanelLeft(const AWidths: TStatusPanelWidthArray): Integer;
var
  PanelIndex: Integer;
begin
  Result := 0;
  for PanelIndex := 0 to StatusPanelCount - 2 do
    Inc(Result, Max(0, AWidths[PanelIndex]));
end;

function ProgressStatusPanelLeft(const AWidths: TStatusPanelWidthArray): Integer;
begin
  Result := Max(0, AWidths[0]) +
            Max(0, AWidths[1]) +
            Max(0, AWidths[2]) +
            Max(0, AWidths[3]);
end;

function ProgressStatusPanelWidth(const AWidths: TStatusPanelWidthArray): Integer;
begin
  Result := Max(0, AWidths[4]) + Max(0, AWidths[5]);
end;

function ProgressLabelWidth(AProgressPanelWidth: Integer): Integer;
begin
  Result := EnsureRange(Max(0, AProgressPanelWidth) div 3, 56, 98);
  if Result > Max(0, AProgressPanelWidth) then
    Result := Max(0, AProgressPanelWidth);
end;

function ProgressBarWidth(AProgressPanelWidth: Integer): Integer;
begin
  Result := Max(0, AProgressPanelWidth) - ProgressLabelWidth(AProgressPanelWidth) - 12;
  if Result < 0 then
    Result := 0;
end;

function ZoomLabelWidth(AZoomPanelWidth: Integer): Integer;
begin
  Result := EnsureRange(Max(0, AZoomPanelWidth) div 3, 44, 60);
end;

function ZoomTrackWidth(AZoomPanelWidth: Integer): Integer;
begin
  Result := Max(72, Max(0, AZoomPanelWidth) - ZoomLabelWidth(AZoomPanelWidth) - 14);
end;

end.
