unit FPLevelsHelpers;

{$mode objfpc}{$H+}

interface

type
  TLevelsSettings = record
    InputLow: Integer;
    InputHigh: Integer;
    OutputLow: Integer;
    OutputHigh: Integer;
  end;

function DefaultLevelsSettings: TLevelsSettings;
function ClampInputLow(AValue, ACurrentInputHigh: Integer): Integer;
function ClampInputHigh(AValue, ACurrentInputLow: Integer): Integer;
function ClampOutputLow(AValue: Integer): Integer;
function ClampOutputHigh(AValue: Integer): Integer;
function ParseLevelText(const AText: string; AFallback, AMin, AMax: Integer): Integer;
procedure NormalizeLevels(var ASettings: TLevelsSettings);

implementation

uses
  SysUtils, Math;

function DefaultLevelsSettings: TLevelsSettings;
begin
  Result.InputLow := 0;
  Result.InputHigh := 255;
  Result.OutputLow := 0;
  Result.OutputHigh := 255;
end;

function ClampInputLow(AValue, ACurrentInputHigh: Integer): Integer;
var
  HighBound: Integer;
begin
  HighBound := EnsureRange(ACurrentInputHigh, 1, 255);
  Result := EnsureRange(AValue, 0, HighBound - 1);
end;

function ClampInputHigh(AValue, ACurrentInputLow: Integer): Integer;
var
  LowBound: Integer;
begin
  LowBound := EnsureRange(ACurrentInputLow, 0, 254);
  Result := EnsureRange(AValue, LowBound + 1, 255);
end;

function ClampOutputLow(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, 0, 254);
end;

function ClampOutputHigh(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, 1, 255);
end;

function ParseLevelText(const AText: string; AFallback, AMin, AMax: Integer): Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(AText), AFallback), AMin, AMax);
end;

procedure NormalizeLevels(var ASettings: TLevelsSettings);
begin
  ASettings.InputLow := ClampInputLow(ASettings.InputLow, ASettings.InputHigh);
  ASettings.InputHigh := ClampInputHigh(ASettings.InputHigh, ASettings.InputLow);
  ASettings.OutputLow := ClampOutputLow(ASettings.OutputLow);
  ASettings.OutputHigh := ClampOutputHigh(ASettings.OutputHigh);
end;

end.
