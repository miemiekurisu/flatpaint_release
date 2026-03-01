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
  Math;

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
      Result := 'Bilinear';
  else
    Result := 'Nearest Neighbor';
  end;
end;

end.
