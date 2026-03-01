unit FPHueSaturationHelpers;

{$mode objfpc}{$H+}

interface

function ClampHueDelta(AValue: Integer): Integer;
function ClampSaturationDelta(AValue: Integer): Integer;
function ParseDeltaText(const AText: string; AFallback, AMin, AMax: Integer): Integer;

implementation

uses
  SysUtils, Math;

function ClampHueDelta(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, -180, 180);
end;

function ClampSaturationDelta(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, -100, 100);
end;

function ParseDeltaText(const AText: string; AFallback, AMin, AMax: Integer): Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(AText), AFallback), AMin, AMax);
end;

end.
