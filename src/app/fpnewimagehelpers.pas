unit FPNewImageHelpers;

{$mode objfpc}{$H+}

interface

type
  TPrintMeasurementUnit = (
    pmInches,
    pmCentimeters
  );

function ClampResolutionDPI(AValue: Double): Double;
function EstimateNewImageBytes(APixelWidth, APixelHeight: Integer): Int64;
function FormatEstimatedImageSize(APixelWidth, APixelHeight: Integer): string;
function PixelsToPrintValue(APixels: Integer; AResolutionDPI: Double; AUnit: TPrintMeasurementUnit): Double;
function PrintValueToPixels(AValue: Double; AResolutionDPI: Double; AUnit: TPrintMeasurementUnit): Integer;

implementation

uses
  Math, SysUtils;

function ClampResolutionDPI(AValue: Double): Double;
begin
  Result := Max(1.0, AValue);
end;

function EstimateNewImageBytes(APixelWidth, APixelHeight: Integer): Int64;
begin
  Result := Max(1, APixelWidth) * Max(1, APixelHeight) * 4;
end;

function FormatEstimatedImageSize(APixelWidth, APixelHeight: Integer): string;
var
  SizeBytes: Double;
begin
  SizeBytes := EstimateNewImageBytes(APixelWidth, APixelHeight);
  Result := FormatFloat('0.0', SizeBytes / (1024.0 * 1024.0)) + ' MB';
end;

function PixelsToPrintValue(APixels: Integer; AResolutionDPI: Double; AUnit: TPrintMeasurementUnit): Double;
begin
  Result := APixels / ClampResolutionDPI(AResolutionDPI);
  if AUnit = pmCentimeters then
    Result := Result * 2.54;
end;

function PrintValueToPixels(AValue: Double; AResolutionDPI: Double; AUnit: TPrintMeasurementUnit): Integer;
var
  InchesValue: Double;
begin
  if AUnit = pmCentimeters then
    InchesValue := AValue / 2.54
  else
    InchesValue := AValue;
  Result := Max(1, Round(InchesValue * ClampResolutionDPI(AResolutionDPI)));
end;

end.
