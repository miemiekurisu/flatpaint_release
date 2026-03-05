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
function PaletteShortcutLabel(APalette: TPaletteKind): string;
function PaletteDefaultRect(APalette: TPaletteKind): TRect;
function PaletteDefaultRectForWorkspace(APalette: TPaletteKind; const AWorkspaceRect: TRect): TRect;
function ToolsPaletteColumnCount: Integer;
function PaletteHeaderHeight: Integer;
function WorkspaceBackgroundColor: LongInt;
function CanvasBackgroundColor: LongInt;
function ToolbarBackgroundColor: LongInt;
function TabStripBackgroundColor: LongInt;
function StatusBarBackgroundColor: LongInt;
function ChromeTextColor: LongInt;
function ChromeMutedTextColor: LongInt;
function ChromeFaintTextColor: LongInt;
function ChromeDividerColor: LongInt;
function PaletteListBackgroundColor: LongInt;
function PaletteSelectionColor: LongInt;
function PaletteActiveRowColor: LongInt;
function PaletteSelectionTextColor: LongInt;
function PaletteSurfaceColor(APalette: TPaletteKind; ADragging: Boolean = False): LongInt;
function PaletteHeaderColor(APalette: TPaletteKind; ADragging: Boolean = False): LongInt;
function ToolButtonActiveColor: LongInt;
function SnapPaletteRect(const ARect, AWorkspaceRect: TRect; AThreshold: Integer = 18): TRect;

implementation

uses
  Math, FPI18n;

const
  PaletteMargin = 12;
  PaletteGap = 14;
  ToolsPaletteWidth = 108;
  ToolsPaletteHeight = 500;
  ColorsPaletteWidth = 220;
  ColorsPaletteHeight = 320;
  HistoryPaletteWidth = 236;
  HistoryPaletteHeight = 220;
  LayersPaletteWidth = 236;
  LayersPaletteHeight = 320;

function RgbColor(ARed, AGreen, ABlue: Byte): LongInt; inline;
begin
  Result := ARed or (AGreen shl 8) or (ABlue shl 16);
end;

function PaletteTitle(APalette: TPaletteKind): string;
begin
  case APalette of
    pkTools:
      Result := TR('Tools', #$E5#$B7#$A5#$E5#$85#$B7);
    pkColors:
      Result := TR('Colors', #$E9#$A2#$9C#$E8#$89#$B2);
    pkHistory:
      Result := TR('History', #$E5#$8E#$86#$E5#$8F#$B2);
    pkLayers:
      Result := TR('Layers', #$E5#$9B#$BE#$E5#$B1#$82);
  else
    Result := TR('Palette', #$E8#$B0#$83#$E8#$89#$B2#$E6#$9D#$BF);
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

function PaletteShortcutLabel(APalette: TPaletteKind): string;
var
  ShortcutDigit: Char;
begin
  ShortcutDigit := PaletteShortcutDigit(APalette);
  if ShortcutDigit = '0' then
    Exit('');
  Result := 'Cmd+' + ShortcutDigit;
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
      Result := Rect(1088, 246, 1088 + LayersPaletteWidth, 246 + LayersPaletteHeight);
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
  Result := RgbColor(241, 243, 246);
end;

function CanvasBackgroundColor: LongInt;
begin
  Result := RgbColor(228, 231, 235);
end;

function ToolbarBackgroundColor: LongInt;
begin
  Result := RgbColor(248, 249, 251);
end;

function TabStripBackgroundColor: LongInt;
begin
  Result := RgbColor(234, 237, 241);
end;

function StatusBarBackgroundColor: LongInt;
begin
  Result := RgbColor(241, 243, 246);
end;

function ChromeTextColor: LongInt;
begin
  Result := RgbColor(39, 39, 42);
end;

function ChromeMutedTextColor: LongInt;
begin
  Result := RgbColor(82, 82, 91);
end;

function ChromeFaintTextColor: LongInt;
begin
  Result := RgbColor(113, 113, 122);
end;

function ChromeDividerColor: LongInt;
begin
  Result := RgbColor(212, 212, 216);
end;

function PaletteListBackgroundColor: LongInt;
begin
  Result := RgbColor(255, 255, 255);
end;

function PaletteSelectionColor: LongInt;
begin
  { macOS-style soft blue highlight (unemphasized selected content) }
  Result := RgbColor(211, 227, 252);
end;

function PaletteActiveRowColor: LongInt;
begin
  { macOS alternating content background — neutral warm gray }
  Result := RgbColor(244, 245, 246);
end;

function PaletteSelectionTextColor: LongInt;
begin
  Result := RgbColor(30, 41, 59);
end;

function PaletteSurfaceColor(APalette: TPaletteKind; ADragging: Boolean): LongInt;
begin
  { macOS window-background inspired: light neutral gray, consistent across panels }
  if ADragging then
    Result := RgbColor(232, 234, 237)
  else
    Result := RgbColor(246, 246, 248);
end;

function PaletteHeaderColor(APalette: TPaletteKind; ADragging: Boolean): LongInt;
begin
  { macOS toolbar-background inspired: neutral header, consistent across panels }
  if ADragging then
    Result := RgbColor(224, 226, 230)
  else
    Result := RgbColor(238, 239, 241);
end;

function ToolButtonActiveColor: LongInt;
begin
  { macOS selectedContentBackgroundColor-inspired soft blue for active tool }
  Result := RgbColor(211, 227, 252);
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
