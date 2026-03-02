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
function PaletteDefaultRectForWorkspace(APalette: TPaletteKind; const AWorkspaceRect: TRect): TRect;
function ToolsPaletteColumnCount: Integer;
function PaletteHeaderHeight: Integer;
function WorkspaceBackgroundColor: LongInt;
function CanvasBackgroundColor: LongInt;
function ToolbarBackgroundColor: LongInt;
function PaletteSurfaceColor(APalette: TPaletteKind; ADragging: Boolean = False): LongInt;
function PaletteHeaderColor(APalette: TPaletteKind; ADragging: Boolean = False): LongInt;
function SnapPaletteRect(const ARect, AWorkspaceRect: TRect; AThreshold: Integer = 18): TRect;

implementation

uses
  Math;

const
  PaletteMargin = 12;
  PaletteGap = 14;
  ToolsPaletteWidth = 100;
  ToolsPaletteHeight = 324;
  ColorsPaletteWidth = 224;
  ColorsPaletteHeight = 216;
  HistoryPaletteWidth = 236;
  HistoryPaletteHeight = 156;
  LayersPaletteWidth = 236;
  LayersPaletteHeight = 242;

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
    pkLayers:
      Result := '3';
    pkHistory:
      Result := '4';
  else
    Result := '0';
  end;
end;

function PaletteDefaultRect(APalette: TPaletteKind): TRect;
begin
  case APalette of
    pkTools:
      Result := Rect(PaletteMargin, PaletteMargin, PaletteMargin + ToolsPaletteWidth, PaletteMargin + ToolsPaletteHeight);
    pkColors:
      Result := Rect(
        PaletteMargin,
        PaletteMargin + ToolsPaletteHeight + PaletteGap,
        PaletteMargin + ColorsPaletteWidth,
        PaletteMargin + ToolsPaletteHeight + PaletteGap + ColorsPaletteHeight
      );
    pkHistory:
      Result := Rect(1088, PaletteMargin, 1088 + HistoryPaletteWidth, PaletteMargin + HistoryPaletteHeight);
    pkLayers:
      Result := Rect(1088, 184, 1088 + LayersPaletteWidth, 184 + LayersPaletteHeight);
  else
    Result := Rect(12, 12, 220, 180);
  end;
end;

function PaletteDefaultRectForWorkspace(APalette: TPaletteKind; const AWorkspaceRect: TRect): TRect;
var
  WorkspaceWidth: Integer;
  WorkspaceHeight: Integer;
  LeftEdge: Integer;
  RightEdge: Integer;
  TopEdge: Integer;
  BottomEdge: Integer;
  PaletteWidth: Integer;
  PaletteHeight: Integer;
  LeftPos: Integer;
  TopPos: Integer;
begin
  WorkspaceWidth := Max(0, AWorkspaceRect.Right - AWorkspaceRect.Left);
  WorkspaceHeight := Max(0, AWorkspaceRect.Bottom - AWorkspaceRect.Top);
  if (WorkspaceWidth = 0) or (WorkspaceHeight = 0) then
    Exit(PaletteDefaultRect(APalette));

  LeftEdge := AWorkspaceRect.Left + PaletteMargin;
  RightEdge := AWorkspaceRect.Right - PaletteMargin;
  TopEdge := AWorkspaceRect.Top + PaletteMargin;
  BottomEdge := AWorkspaceRect.Bottom - PaletteMargin;

  case APalette of
    pkTools:
      begin
        PaletteWidth := ToolsPaletteWidth;
        PaletteHeight := ToolsPaletteHeight;
        LeftPos := LeftEdge;
        TopPos := TopEdge;
      end;
    pkColors:
      begin
        PaletteWidth := ColorsPaletteWidth;
        PaletteHeight := ColorsPaletteHeight;
        LeftPos := LeftEdge;
        TopPos := BottomEdge - PaletteHeight;
        if TopPos < TopEdge + ToolsPaletteHeight + PaletteGap then
        begin
          if WorkspaceWidth >= (PaletteMargin * 3) + ToolsPaletteWidth + ColorsPaletteWidth then
            LeftPos := LeftEdge + ToolsPaletteWidth + PaletteGap
          else
            TopPos := TopEdge + ToolsPaletteHeight + PaletteGap;
        end;
      end;
    pkHistory:
      begin
        PaletteWidth := HistoryPaletteWidth;
        PaletteHeight := HistoryPaletteHeight;
        LeftPos := RightEdge - PaletteWidth;
        TopPos := TopEdge;
      end;
    pkLayers:
      begin
        PaletteWidth := LayersPaletteWidth;
        PaletteHeight := LayersPaletteHeight;
        LeftPos := RightEdge - PaletteWidth;
        TopPos := BottomEdge - PaletteHeight;
        if TopPos < TopEdge + HistoryPaletteHeight + PaletteGap then
          TopPos := TopEdge + HistoryPaletteHeight + PaletteGap;
      end;
  else
    begin
      PaletteWidth := 220;
      PaletteHeight := 180;
      LeftPos := LeftEdge;
      TopPos := TopEdge;
    end;
  end;

  LeftPos := EnsureRange(
    LeftPos,
    AWorkspaceRect.Left,
    Max(AWorkspaceRect.Left, AWorkspaceRect.Right - PaletteWidth)
  );
  TopPos := EnsureRange(
    TopPos,
    AWorkspaceRect.Top,
    Max(AWorkspaceRect.Top, AWorkspaceRect.Bottom - PaletteHeight)
  );
  Result := Rect(LeftPos, TopPos, LeftPos + PaletteWidth, TopPos + PaletteHeight);
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
