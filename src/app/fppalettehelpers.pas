unit FPPaletteHelpers;

{$mode objfpc}{$H+}

interface

uses
  Types;

type
  TPaletteKind = (
    pkTools,
    pkColors,
    pkHistory,
    pkLayers
  );

function PaletteTitle(APalette: TPaletteKind): string;
function PaletteShortcutDigit(APalette: TPaletteKind): Char;
function PaletteDefaultRect(APalette: TPaletteKind): TRect;
function ToolsPaletteColumnCount: Integer;
function PaletteHeaderHeight: Integer;
function WorkspaceBackgroundColor: LongInt;
function CanvasBackgroundColor: LongInt;
function ToolbarBackgroundColor: LongInt;
function PaletteSurfaceColor(APalette: TPaletteKind; ADragging: Boolean = False): LongInt;
function PaletteHeaderColor(APalette: TPaletteKind; ADragging: Boolean = False): LongInt;
function SnapPaletteRect(const ARect, AWorkspaceRect: TRect; AThreshold: Integer = 18): TRect;

implementation

function PaletteTitle(APalette: TPaletteKind): string;
begin
  case APalette of
    pkTools:
      Result := 'Tools';
    pkColors:
      Result := 'Colors';
    pkHistory:
      Result := 'History';
    pkLayers:
      Result := 'Layers';
  else
    Result := 'Palette';
  end;
end;

function PaletteShortcutDigit(APalette: TPaletteKind): Char;
begin
  case APalette of
    pkTools:
      Result := '1';
    pkColors:
      Result := '2';
    pkHistory:
      Result := '3';
    pkLayers:
      Result := '4';
  else
    Result := '0';
  end;
end;

function PaletteDefaultRect(APalette: TPaletteKind): TRect;
begin
  case APalette of
    pkTools:
      Result := Rect(12, 12, 112, 298);
    pkColors:
      Result := Rect(12, 316, 236, 532);
    pkHistory:
      Result := Rect(1088, 12, 1324, 168);
    pkLayers:
      Result := Rect(1088, 184, 1324, 426);
  else
    Result := Rect(12, 12, 220, 180);
  end;
end;

function ToolsPaletteColumnCount: Integer;
begin
  Result := 2;
end;

function PaletteHeaderHeight: Integer;
begin
  Result := 22;
end;

function WorkspaceBackgroundColor: LongInt;
begin
  Result := $00313842;
end;

function CanvasBackgroundColor: LongInt;
begin
  Result := $00262B33;
end;

function ToolbarBackgroundColor: LongInt;
begin
  Result := $003B4452;
end;

function PaletteSurfaceColor(APalette: TPaletteKind; ADragging: Boolean): LongInt;
begin
  case APalette of
    pkTools:
      if ADragging then
        Result := $00505B6A
      else
        Result := $00404754;
    pkColors:
      if ADragging then
        Result := $00525970
      else
        Result := $0041485A;
    pkHistory:
      if ADragging then
        Result := $00545E68
      else
        Result := $00424A52;
    pkLayers:
      if ADragging then
        Result := $00525C70
      else
        Result := $0041495D;
  else
    if ADragging then
      Result := $00505A68
    else
      Result := $00404754;
  end;
end;

function PaletteHeaderColor(APalette: TPaletteKind; ADragging: Boolean): LongInt;
begin
  case APalette of
    pkTools:
      if ADragging then
        Result := $00626F82
      else
        Result := $00525D70;
    pkColors:
      if ADragging then
        Result := $0067728A
      else
        Result := $0058657A;
    pkHistory:
      if ADragging then
        Result := $00656F79
      else
        Result := $00545E66;
    pkLayers:
      if ADragging then
        Result := $00667388
      else
        Result := $0058657D;
  else
    if ADragging then
      Result := $00626F82
    else
      Result := $00525D70;
  end;
end;

function SnapPaletteRect(const ARect, AWorkspaceRect: TRect; AThreshold: Integer): TRect;
var
  PaletteWidth: Integer;
  PaletteHeight: Integer;
begin
  Result := ARect;
  PaletteWidth := ARect.Right - ARect.Left;
  PaletteHeight := ARect.Bottom - ARect.Top;

  if Abs(Result.Left - AWorkspaceRect.Left) <= AThreshold then
  begin
    Result.Left := AWorkspaceRect.Left;
    Result.Right := Result.Left + PaletteWidth;
  end;

  if Abs(Result.Top - AWorkspaceRect.Top) <= AThreshold then
  begin
    Result.Top := AWorkspaceRect.Top;
    Result.Bottom := Result.Top + PaletteHeight;
  end;

  if Abs(Result.Right - AWorkspaceRect.Right) <= AThreshold then
  begin
    Result.Right := AWorkspaceRect.Right;
    Result.Left := Result.Right - PaletteWidth;
  end;

  if Abs(Result.Bottom - AWorkspaceRect.Bottom) <= AThreshold then
  begin
    Result.Bottom := AWorkspaceRect.Bottom;
    Result.Top := Result.Bottom - PaletteHeight;
  end;
end;

end.
