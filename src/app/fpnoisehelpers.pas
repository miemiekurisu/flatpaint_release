unit FPNoiseHelpers;

{$mode objfpc}{$H+}

interface

function ClampNoiseAmount(AValue: Integer): Integer;
function ParseNoiseText(const AText: string; AFallback: Integer): Integer;
function NoiseAmountToSliderPosition(AAmount: Integer): Integer;
function SliderPositionToNoiseAmount(APosition: Integer): Integer;

implementation

uses
  SysUtils, Math;

function ClampNoiseAmount(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, 0, 255);
end;

function ParseNoiseText(const AText: string; AFallback: Integer): Integer;
begin
  Result := ClampNoiseAmount(StrToIntDef(Trim(AText), AFallback));
end;

function NoiseAmountToSliderPosition(AAmount: Integer): Integer;
begin
  Result := ClampNoiseAmount(AAmount);
end;

function SliderPositionToNoiseAmount(APosition: Integer): Integer;
begin
  Result := ClampNoiseAmount(APosition);
end;

end.
