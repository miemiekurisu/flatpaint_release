unit FPCurvesHelpers;

{$mode objfpc}{$H+}

interface

function ClampGammaValue(AValue: Double): Double;
function ParseGammaText(const AText: string; AFallback: Double): Double;
function GammaToSliderPosition(AGamma: Double): Integer;
function SliderPositionToGamma(APosition: Integer): Double;
function FormatGammaText(AGamma: Double): string;

implementation

uses
  SysUtils, Math;

function ClampGammaValue(AValue: Double): Double;
begin
  Result := EnsureRange(AValue, 0.1, 5.0);
end;

function ParseGammaText(const AText: string; AFallback: Double): Double;
var
  Parsed: Double;
  DotFormatSettings: TFormatSettings;
begin
  if TryStrToFloat(Trim(AText), Parsed) then
    Exit(ClampGammaValue(Parsed));

  DotFormatSettings := DefaultFormatSettings;
  DotFormatSettings.DecimalSeparator := '.';
  if TryStrToFloat(Trim(AText), Parsed, DotFormatSettings) then
    Exit(ClampGammaValue(Parsed));

  Result := ClampGammaValue(AFallback);
end;

function GammaToSliderPosition(AGamma: Double): Integer;
begin
  Result := EnsureRange(Round(ClampGammaValue(AGamma) * 100.0), 10, 500);
end;

function SliderPositionToGamma(APosition: Integer): Double;
begin
  Result := EnsureRange(APosition, 10, 500) / 100.0;
end;

function FormatGammaText(AGamma: Double): string;
begin
  Result := FormatFloat('0.00', ClampGammaValue(AGamma));
end;

end.
