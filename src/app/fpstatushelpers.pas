unit FPStatusHelpers;

{$mode objfpc}{$H+}

interface

const
  StatusPanelCount = 7;

type
  TStatusPanelWidthArray = array[0..StatusPanelCount - 1] of Integer;

procedure ComputeStatusPanelWidths(ATotalWidth: Integer; out AWidths: TStatusPanelWidthArray);
function ZoomStatusPanelLeft(const AWidths: TStatusPanelWidthArray): Integer;
function ZoomTrackWidth(AZoomPanelWidth: Integer): Integer;

implementation

uses
  Math;

const
  StatusPanelWeights: array[0..StatusPanelCount - 1] of Integer = (
    24, 17, 16, 15, 10, 8, 20
  );
  StatusPanelWeightTotal = 110;

procedure ComputeStatusPanelWidths(ATotalWidth: Integer; out AWidths: TStatusPanelWidthArray);
var
  AvailableWidth: Integer;
  PanelIndex: Integer;
  ConsumedWidth: Integer;
begin
  AvailableWidth := Max(0, ATotalWidth);
  ConsumedWidth := 0;
  for PanelIndex := 0 to StatusPanelCount - 1 do
  begin
    if PanelIndex = StatusPanelCount - 1 then
      AWidths[PanelIndex] := Max(0, AvailableWidth - ConsumedWidth)
    else
    begin
      AWidths[PanelIndex] := (AvailableWidth * StatusPanelWeights[PanelIndex]) div StatusPanelWeightTotal;
      Inc(ConsumedWidth, AWidths[PanelIndex]);
    end;
  end;
end;

function ZoomStatusPanelLeft(const AWidths: TStatusPanelWidthArray): Integer;
var
  PanelIndex: Integer;
begin
  Result := 0;
  for PanelIndex := 0 to StatusPanelCount - 2 do
    Inc(Result, Max(0, AWidths[PanelIndex]));
end;

function ZoomTrackWidth(AZoomPanelWidth: Integer): Integer;
begin
  Result := Max(72, Max(0, AZoomPanelWidth) - 58);
end;

end.
