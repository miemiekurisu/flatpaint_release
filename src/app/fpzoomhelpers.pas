unit FPZoomHelpers;

{$mode objfpc}{$H+}

interface

function ZoomPresetCount: Integer;
function ZoomPresetScale(AIndex: Integer): Double;
function ZoomPresetCaption(AIndex: Integer): string;
function ZoomCaptionForScale(AScale: Double): string;
function NearestZoomPresetIndex(AScale: Double): Integer;
function NextZoomInScale(ACurrentScale: Double): Double;
function NextZoomOutScale(ACurrentScale: Double): Double;

implementation

uses
  Math, SysUtils;

const
  ZoomPresetValues: array[0..9] of Double = (
    0.125, 0.25, 0.5, 0.667, 1.0, 1.5, 2.0, 4.0, 8.0, 16.0
  );
  ZoomMatchEpsilon = 0.02;

function ZoomPresetCount: Integer;
begin
  Result := Length(ZoomPresetValues);
end;

function ZoomPresetScale(AIndex: Integer): Double;
begin
  Result := ZoomPresetValues[EnsureRange(AIndex, Low(ZoomPresetValues), High(ZoomPresetValues))];
end;

function ZoomPresetCaption(AIndex: Integer): string;
begin
  Result := ZoomCaptionForScale(ZoomPresetScale(AIndex));
end;

function ZoomCaptionForScale(AScale: Double): string;
var
  PercentValue: Double;
begin
  PercentValue := Max(0.1, AScale) * 100.0;
  if Abs(PercentValue - Round(PercentValue)) <= 0.05 then
    Result := Format('%d%%', [Round(PercentValue)])
  else
    Result := FormatFloat('0.0', PercentValue) + '%';
end;

function NearestZoomPresetIndex(AScale: Double): Integer;
var
  PresetIndex: Integer;
  BestDelta: Double;
  CandidateDelta: Double;
begin
  Result := 0;
  BestDelta := Abs(ZoomPresetValues[0] - AScale);
  for PresetIndex := 1 to High(ZoomPresetValues) do
  begin
    CandidateDelta := Abs(ZoomPresetValues[PresetIndex] - AScale);
    if CandidateDelta < BestDelta then
    begin
      BestDelta := CandidateDelta;
      Result := PresetIndex;
    end;
  end;
end;

function NextZoomInScale(ACurrentScale: Double): Double;
var
  PresetIndex: Integer;
begin
  for PresetIndex := Low(ZoomPresetValues) to High(ZoomPresetValues) do
    if ZoomPresetValues[PresetIndex] > (ACurrentScale + ZoomMatchEpsilon) then
      Exit(ZoomPresetValues[PresetIndex]);
  Result := ZoomPresetValues[High(ZoomPresetValues)];
end;

function NextZoomOutScale(ACurrentScale: Double): Double;
var
  PresetIndex: Integer;
begin
  for PresetIndex := High(ZoomPresetValues) downto Low(ZoomPresetValues) do
    if ZoomPresetValues[PresetIndex] < (ACurrentScale - ZoomMatchEpsilon) then
      Exit(ZoomPresetValues[PresetIndex]);
  Result := ZoomPresetValues[Low(ZoomPresetValues)];
end;

end.
