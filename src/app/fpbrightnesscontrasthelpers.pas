unit FPBrightnessContrastHelpers;

{$mode objfpc}{$H+}

interface

type
  TBrightnessContrastSettings = record
    Brightness: Integer;
    Contrast: Integer;
  end;

function DefaultBrightnessContrastSettings: TBrightnessContrastSettings;
function ClampBrightnessDelta(AValue: Integer): Integer;
function ClampContrastAmount(AValue: Integer): Integer;
function ParseAdjustmentText(const AText: string; AFallback, AMin, AMax: Integer): Integer;

implementation

uses
  SysUtils, Math;

function DefaultBrightnessContrastSettings: TBrightnessContrastSettings;
begin
  Result.Brightness := 0;
  Result.Contrast := 0;
end;

function ClampBrightnessDelta(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, -255, 255);
end;

function ClampContrastAmount(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, -255, 254);
end;

function ParseAdjustmentText(const AText: string; AFallback, AMin, AMax: Integer): Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(AText), AFallback), AMin, AMax);
end;

end.
