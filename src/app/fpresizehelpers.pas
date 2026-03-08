unit FPResizeHelpers;

{$mode objfpc}{$H+}

interface

uses
  FPSurface;

function ClampResizePixels(AValue: Integer): Integer;
function LinkedResizeValue(AChangedValue, AChangedBase, ALinkedBase: Integer): Integer;
function ResampleModeCaption(AMode: TResampleMode): string;

implementation

uses
  Math, FPi18n;

function ClampResizePixels(AValue: Integer): Integer;
begin
  Result := Max(1, AValue);
end;

function LinkedResizeValue(AChangedValue, AChangedBase, ALinkedBase: Integer): Integer;
begin
  AChangedValue := ClampResizePixels(AChangedValue);
  AChangedBase := ClampResizePixels(AChangedBase);
  ALinkedBase := ClampResizePixels(ALinkedBase);
  Result := ClampResizePixels(Round((AChangedValue / AChangedBase) * ALinkedBase));
end;

function ResampleModeCaption(AMode: TResampleMode): string;
begin
  case AMode of
    rmBilinear:
      Result := TR('Bilinear', #$E5#$8F#$8C#$E7#$BA#$BF#$E6#$80#$A7);
  else
    Result := TR('Nearest Neighbor', #$E9#$82#$BB#$E8#$BF#$91#$E9#$87#$87#$E6#$A0#$B7);
  end;
end;

end.
