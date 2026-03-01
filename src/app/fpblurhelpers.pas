unit FPBlurHelpers;

{$mode objfpc}{$H+}

interface

function ClampBlurRadius(AValue: Integer): Integer;
function ParseBlurText(const AText: string; AFallback: Integer): Integer;
function BlurRadiusToSliderPosition(ARadius: Integer): Integer;
function SliderPositionToBlurRadius(APosition: Integer): Integer;

implementation

uses
  SysUtils, Math;

function ClampBlurRadius(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, 1, 64);
end;

function ParseBlurText(const AText: string; AFallback: Integer): Integer;
begin
  Result := ClampBlurRadius(StrToIntDef(Trim(AText), AFallback));
end;

function BlurRadiusToSliderPosition(ARadius: Integer): Integer;
begin
  Result := ClampBlurRadius(ARadius);
end;

function SliderPositionToBlurRadius(APosition: Integer): Integer;
begin
  Result := ClampBlurRadius(APosition);
end;

end.
