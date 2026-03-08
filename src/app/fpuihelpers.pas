unit FPUIHelpers;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, Controls, Types, FPColor, FPDocument;

function PaintToolName(ATool: TToolKind): string;
function PaintToolHint(ATool: TToolKind): string;
function PaintToolGlyph(ATool: TToolKind): string;
function PaintToolShortcutKey(ATool: TToolKind): string;
function PaintToolShortcutHint(ATool: TToolKind): string;
function PaintToolDisplayLabel(ATool: TToolKind): string;
function PaintToolHasCanvasHoverOverlay(ATool: TToolKind): Boolean;
function PaintToolUsesBrushOverlay(ATool: TToolKind): Boolean;
function LayerOpacityPercentFromByte(AOpacity: Byte): Integer;
function LayerOpacityByteFromPercent(APercent: Integer): Byte;
function PaintToolDisplayCount: Integer;
function PaintToolAtDisplayIndex(AIndex: Integer): TToolKind;
function PaintToolDisplayIndex(ATool: TToolKind): Integer;
function DefaultStartupTool: TToolKind;
function ToolShortcutUsesPlainKeyOnly(const AShift: TShiftState): Boolean;
function AdoptSampledRGBPreservingAlpha(const ACurrentColor, ASampledColor: TRGBA32): TRGBA32;
function DragButtonIsStillPressed(AButton: TMouseButton; const AShift: TShiftState): Boolean;
function ShouldCommitPendingStrokeOnMouseDown(AHasPendingStroke: Boolean): Boolean;
function LineReleaseStartsBezier(ABezierEnabled: Boolean; const AStartPoint, AEndPoint: TPoint): Boolean;
function IsSelectionTool(ATool: TToolKind): Boolean;

{ Given a key and a reverse-flag (Shift held), compute the new tool.  }
function NextToolForKey(AKey: Char; AReverse: Boolean; ACurrent: TToolKind): TToolKind;

implementation

uses
  FPI18n;

const
  ToolDisplayOrder: array[0..23] of TToolKind = (
    tkSelectRect,
    tkSelectEllipse,
    tkSelectLasso,
    tkMagicWand,
    tkMoveSelection,
    tkMovePixels,
    tkCrop,
    tkZoom,
    tkPan,
    tkFill,
    tkGradient,
    tkPencil,
    tkBrush,
    tkEraser,
    tkColorPicker,
    tkCloneStamp,
    tkRecolor,
    tkMosaic,
    tkLine,
    tkRectangle,
    tkRoundedRectangle,
    tkEllipseShape,
    tkFreeformShape,
    tkText
  );

function PaintToolName(ATool: TToolKind): string;
begin
  case ATool of
    tkPencil:
      Result := TR('Pencil', #$E9#$93#$85#$E7#$AC#$94);
    tkBrush:
      Result := TR('Brush', #$E7#$94#$BB#$E7#$AC#$94);
    tkEraser:
      Result := TR('Eraser', #$E6#$A9#$A1#$E7#$9A#$AE#$E6#$93#$A6);
    tkFill:
      Result := TR('Paint Bucket', #$E6#$B2#$B9#$E6#$BC#$86#$E6#$A1#$B6);
    tkGradient:
      Result := TR('Gradient', #$E6#$B8#$90#$E5#$8F#$98);
    tkLine:
      Result := TR('Line', #$E7#$9B#$B4#$E7#$BA#$BF);
    tkRectangle:
      Result := TR('Rectangle', #$E7#$9F#$A9#$E5#$BD#$A2);
    tkRoundedRectangle:
      Result := TR('Rounded Rectangle', #$E5#$9C#$86#$E8#$A7#$92#$E7#$9F#$A9#$E5#$BD#$A2);
    tkEllipseShape:
      Result := TR('Ellipse', #$E6#$A4#$AD#$E5#$9C#$86);
    tkFreeformShape:
      Result := TR('Freeform Shape', #$E8#$87#$AA#$E7#$94#$B1#$E5#$BD#$A2#$E7#$8A#$B6);
    tkSelectRect:
      Result := TR('Rectangle Select', #$E7#$9F#$A9#$E5#$BD#$A2#$E9#$80#$89#$E6#$8B#$A9);
    tkSelectEllipse:
      Result := TR('Ellipse Select', #$E6#$A4#$AD#$E5#$9C#$86#$E9#$80#$89#$E6#$8B#$A9);
    tkSelectLasso:
      Result := TR('Lasso Select', #$E5#$A5#$97#$E7#$B4#$A2#$E9#$80#$89#$E6#$8B#$A9);
    tkMagicWand:
      Result := TR('Magic Wand', #$E9#$AD#$94#$E6#$A3#$92);
    tkMoveSelection:
      Result := TR('Move Selection', #$E7#$A7#$BB#$E5#$8A#$A8#$E9#$80#$89#$E5#$8C#$BA);
    tkMovePixels:
      Result := TR('Move Selected Pixels', #$E7#$A7#$BB#$E5#$8A#$A8#$E5#$83#$8F#$E7#$B4#$A0);
    tkZoom:
      Result := TR('Zoom', #$E7#$BC#$A9#$E6#$94#$BE);
    tkPan:
      Result := TR('Pan', #$E5#$B9#$B3#$E7#$A7#$BB);
    tkColorPicker:
      Result := TR('Color Picker', #$E5#$8F#$96#$E8#$89#$B2#$E5#$99#$A8);
    tkCrop:
      Result := TR('Crop', #$E8#$A3#$81#$E5#$89#$AA);
    tkText:
      Result := TR('Text', #$E6#$96#$87#$E6#$9C#$AC);
    tkCloneStamp:
      Result := TR('Clone Stamp', #$E4#$BB#$BF#$E5#$88#$B6#$E5#$9B#$BE#$E7#$AB#$A0);
    tkRecolor:
      Result := TR('Recolor', #$E9#$87#$8D#$E6#$96#$B0#$E7#$9D#$80#$E8#$89#$B2);
    tkMosaic:
      Result := TR('Mosaic', #$E9#$A9#$AC#$E8#$B5#$9B#$E5#$85#$8B);
  else
    Result := TR('Tool', #$E5#$B7#$A5#$E5#$85#$B7);
  end;
end;

function PaintToolHint(ATool: TToolKind): string;
begin
  case ATool of
    tkPencil:
      Result := TR('Draws hard-edged freehand strokes', #$E7#$BB#$98#$E5#$88#$B6#$E7#$A1#$AC#$E8#$BE#$B9#$E7#$BC#$98#$E8#$87#$AA#$E7#$94#$B1#$E7#$AC#$94#$E8#$A7#$A6);
    tkBrush:
      Result := TR('Paints soft brush strokes with the foreground color', #$E4#$BD#$BF#$E7#$94#$A8#$E5#$89#$8D#$E6#$99#$AF#$E8#$89#$B2#$E7#$BB#$98#$E5#$88#$B6#$E6#$9F#$94#$E5#$92#$8C#$E7#$AC#$94#$E8#$A7#$A6);
    tkEraser:
      Result := TR('Erases pixels to transparency', #$E5#$B0#$86#$E5#$83#$8F#$E7#$B4#$A0#$E6#$93#$A6#$E9#$99#$A4#$E4#$B8#$BA#$E9#$80#$8F#$E6#$98#$8E);
    tkFill:
      Result := TR('Fills similarly colored areas with the foreground color', #$E7#$94#$A8#$E5#$89#$8D#$E6#$99#$AF#$E8#$89#$B2#$E5#$A1#$AB#$E5#$85#$85#$E7#$9B#$B8#$E4#$BC#$BC#$E9#$A2#$9C#$E8#$89#$B2#$E5#$8C#$BA#$E5#$9F#$9F);
    tkGradient:
      Result := TR('Creates a gradual blend between two colors', #$E5#$9C#$A8#$E4#$B8#$A4#$E7#$A7#$8D#$E9#$A2#$9C#$E8#$89#$B2#$E4#$B9#$8B#$E9#$97#$B4#$E5#$88#$9B#$E5#$BB#$BA#$E6#$B8#$90#$E5#$8F#$98#$E6#$B7#$B7#$E5#$90#$88);
    tkLine:
      Result := TR('Draws straight line segments; enable Bezier to add curve handles', #$E7#$BB#$98#$E5#$88#$B6#$E7#$9B#$B4#$E7#$BA#$BF#$E6#$AE#$B5#$EF#$BC#$9B#$E5#$90#$AF#$E7#$94#$A8#$E8#$B4#$9D#$E5#$A1#$9E#$E5#$B0#$94#$E5#$8F#$AF#$E6#$B7#$BB#$E5#$8A#$A0#$E6#$9B#$B2#$E7#$BA#$BF#$E6#$89#$8B#$E6#$9F#$84);
    tkRectangle:
      Result := TR('Draws rectangular shapes with optional fill', #$E7#$BB#$98#$E5#$88#$B6#$E7#$9F#$A9#$E5#$BD#$A2#$EF#$BC#$8C#$E5#$8F#$AF#$E9#$80#$89#$E5#$A1#$AB#$E5#$85#$85);
    tkRoundedRectangle:
      Result := TR('Draws rounded rectangular shapes with optional fill', #$E7#$BB#$98#$E5#$88#$B6#$E5#$9C#$86#$E8#$A7#$92#$E7#$9F#$A9#$E5#$BD#$A2#$EF#$BC#$8C#$E5#$8F#$AF#$E9#$80#$89#$E5#$A1#$AB#$E5#$85#$85);
    tkEllipseShape:
      Result := TR('Draws ellipses and circles with optional fill', #$E7#$BB#$98#$E5#$88#$B6#$E6#$A4#$AD#$E5#$9C#$86#$E5#$92#$8C#$E5#$9C#$86#$EF#$BC#$8C#$E5#$8F#$AF#$E9#$80#$89#$E5#$A1#$AB#$E5#$85#$85);
    tkFreeformShape:
      Result := TR('Draws a closed freehand shape with optional fill', #$E7#$BB#$98#$E5#$88#$B6#$E5#$B0#$81#$E9#$97#$AD#$E8#$87#$AA#$E7#$94#$B1#$E5#$BD#$A2#$E7#$8A#$B6#$EF#$BC#$8C#$E5#$8F#$AF#$E9#$80#$89#$E5#$A1#$AB#$E5#$85#$85);
    tkSelectRect:
      Result := TR('Creates a rectangular selection', #$E5#$88#$9B#$E5#$BB#$BA#$E7#$9F#$A9#$E5#$BD#$A2#$E9#$80#$89#$E5#$8C#$BA);
    tkSelectEllipse:
      Result := TR('Creates an elliptical selection', #$E5#$88#$9B#$E5#$BB#$BA#$E6#$A4#$AD#$E5#$9C#$86#$E9#$80#$89#$E5#$8C#$BA);
    tkSelectLasso:
      Result := TR('Draws a freehand selection border', #$E7#$BB#$98#$E5#$88#$B6#$E8#$87#$AA#$E7#$94#$B1#$E9#$80#$89#$E5#$8C#$BA#$E8#$BE#$B9#$E7#$95#$8C);
    tkMagicWand:
      Result := TR('Selects similarly colored connected areas', #$E9#$80#$89#$E6#$8B#$A9#$E9#$A2#$9C#$E8#$89#$B2#$E7#$9B#$B8#$E4#$BC#$BC#$E7#$9A#$84#$E8#$BF#$9E#$E6#$8E#$A5#$E5#$8C#$BA#$E5#$9F#$9F);
    tkMoveSelection:
      Result := TR('Moves the selection boundary without affecting pixels', #$E7#$A7#$BB#$E5#$8A#$A8#$E9#$80#$89#$E5#$8C#$BA#$E8#$BE#$B9#$E7#$95#$8C#$EF#$BC#$8C#$E4#$B8#$8D#$E5#$BD#$B1#$E5#$93#$8D#$E5#$83#$8F#$E7#$B4#$A0);
    tkMovePixels:
      Result := TR('Moves the selected pixels to a new location', #$E5#$B0#$86#$E9#$80#$89#$E4#$B8#$AD#$E7#$9A#$84#$E5#$83#$8F#$E7#$B4#$A0#$E7#$A7#$BB#$E5#$8A#$A8#$E5#$88#$B0#$E6#$96#$B0#$E4#$BD#$8D#$E7#$BD#$AE);
    tkZoom:
      Result := TR('Magnifies or reduces the view of the canvas', #$E6#$94#$BE#$E5#$A4#$A7#$E6#$88#$96#$E7#$BC#$A9#$E5#$B0#$8F#$E7#$94#$BB#$E5#$B8#$83#$E8#$A7#$86#$E5#$9B#$BE);
    tkPan:
      Result := TR('Scrolls the canvas within the window', #$E5#$9C#$A8#$E7#$AA#$97#$E5#$8F#$A3#$E5#$86#$85#$E6#$BB#$9A#$E5#$8A#$A8#$E7#$94#$BB#$E5#$B8#$83);
    tkColorPicker:
      Result := TR('Samples a color from the canvas', #$E4#$BB#$8E#$E7#$94#$BB#$E5#$B8#$83#$E4#$B8#$8A#$E9#$87#$87#$E6#$A0#$B7#$E9#$A2#$9C#$E8#$89#$B2);
    tkCrop:
      Result := TR('Trims the canvas to a selected area', #$E5#$B0#$86#$E7#$94#$BB#$E5#$B8#$83#$E8#$A3#$81#$E5#$89#$AA#$E5#$88#$B0#$E9#$80#$89#$E5#$AE#$9A#$E5#$8C#$BA#$E5#$9F#$9F);
    tkText:
      Result := TR('Adds and edits inline text on the canvas', #$E5#$9C#$A8#$E7#$94#$BB#$E5#$B8#$83#$E4#$B8#$8A#$E6#$B7#$BB#$E5#$8A#$A0#$E5#$92#$8C#$E7#$BC#$96#$E8#$BE#$91#$E6#$96#$87#$E6#$9C#$AC);
    tkCloneStamp:
      Result := TR('Paints with a sampled area of the image; Option-click to set source', #$E4#$BD#$BF#$E7#$94#$A8#$E5#$9B#$BE#$E5#$83#$8F#$E7#$9A#$84#$E9#$87#$87#$E6#$A0#$B7#$E5#$8C#$BA#$E5#$9F#$9F#$E7#$BB#$98#$E5#$88#$B6#$EF#$BC#$9B'Option+'#$E5#$8D#$95#$E5#$87#$BB#$E8#$AE#$BE#$E7#$BD#$AE#$E6#$BA#$90);
    tkRecolor:
      Result := TR('Replaces a specific color with the foreground color within tolerance', #$E5#$9C#$A8#$E5#$AE#$B9#$E5#$B7#$AE#$E8#$8C#$83#$E5#$9B#$B4#$E5#$86#$85#$E7#$94#$A8#$E5#$89#$8D#$E6#$99#$AF#$E8#$89#$B2#$E6#$9B#$BF#$E6#$8D#$A2#$E7#$89#$B9#$E5#$AE#$9A#$E9#$A2#$9C#$E8#$89#$B2);
    tkMosaic:
      Result := TR('Drag a rectangle to pixelate an area', #$E6#$8B#$96#$E6#$8B#$BD#$E7#$9F#$A9#$E5#$BD#$A2#$E5#$8C#$BA#$E5#$9F#$9F#$E8#$BF#$9B#$E8#$A1#$8C#$E5#$83#$8F#$E7#$B4#$A0#$E5#$8C#$96);
  else
    Result := TR('Ready', #$E5#$B0#$B1#$E7#$BB#$AA);
  end;
end;

function PaintToolGlyph(ATool: TToolKind): string;
begin
  case ATool of
    tkSelectRect:
      Result := '▭';
    tkSelectEllipse:
      Result := '◌';
    tkSelectLasso:
      Result := '⌒';
    tkMagicWand:
      Result := '✦';
    tkMoveSelection:
      Result := '⊞';
    tkMovePixels:
      Result := '✣';
    tkZoom:
      Result := '⌕';
    tkPan:
      Result := '↕';
    tkFill:
      Result := '▧';
    tkGradient:
      Result := '◫';
    tkPencil:
      Result := '✎';
    tkBrush:
      Result := '◍';
    tkEraser:
      Result := '⌫';
    tkColorPicker:
      Result := '⌖';
    tkCloneStamp:
      Result := '⧉';
    tkRecolor:
      Result := '◐';
    tkMosaic:
      Result := '▦';
    tkLine:
      Result := '／';
    tkRectangle:
      Result := '□';
    tkRoundedRectangle:
      Result := '▢';
    tkEllipseShape:
      Result := '○';
    tkFreeformShape:
      Result := '〰';
    tkCrop:
      Result := '⌗';
    tkText:
      Result := 'T';
  else
    Result := 'Tool';
  end;
end;

function PaintToolShortcutKey(ATool: TToolKind): string;
begin
  case ATool of
    tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand:
      Result := 'S';
    tkMoveSelection, tkMovePixels:
      Result := 'M';
    tkCrop:
      Result := '';
    tkZoom:
      Result := 'Z';
    tkPan:
      Result := 'H';
    tkFill, tkGradient:
      Result := 'G';
    tkPencil:
      Result := 'P';
    tkBrush:
      Result := 'B';
    tkEraser:
      Result := 'E';
    tkColorPicker:
      Result := 'K';
    tkCloneStamp:
      Result := 'C';
    tkRecolor, tkMosaic:
      Result := 'J';
    tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape:
      Result := 'O';
    tkText:
      Result := 'T';
  else
    Result := '';
  end;
end;

function PaintToolShortcutHint(ATool: TToolKind): string;
var
  KeyLabel: string;
begin
  KeyLabel := PaintToolShortcutKey(ATool);
  if KeyLabel = '' then
    Exit(TR('No single-key shortcut is assigned',
            #$E6#$9C#$AA#$E5#$88#$86#$E9#$85#$8D#$E5#$8D#$95#$E9#$94#$AE#$E5#$BF#$AB#$E6#$8D#$B7#$E9#$94#$AE));

  Result := TR('Shortcut: ', #$E5#$BF#$AB#$E6#$8D#$B7#$E9#$94#$AE#$EF#$BC#$9A) + KeyLabel;
  if ATool in [
    tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand,
    tkMoveSelection, tkMovePixels,
    tkFill, tkGradient,
    tkRecolor, tkMosaic,
    tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape
  ] then
    Result := Result + TR(' (repeat to cycle related tools, Shift reverses)',
                          ' (' + #$E9#$87#$8D#$E5#$A4#$8D#$E6#$8C#$89#$E9#$94#$AE#$E5#$88#$87#$E6#$8D#$A2#$E7#$9B#$B8#$E5#$85#$B3#$E5#$B7#$A5#$E5#$85#$B7#$EF#$BC#$8C'Shift'#$E5#$8F#$8D#$E5#$90#$91 + ')');
end;

function PaintToolDisplayLabel(ATool: TToolKind): string;
var
  KeyLabel: string;
begin
  Result := PaintToolName(ATool);
  KeyLabel := PaintToolShortcutKey(ATool);
  if KeyLabel <> '' then
    Result := Result + ' (' + KeyLabel + ')';
end;

function PaintToolHasCanvasHoverOverlay(ATool: TToolKind): Boolean;
begin
  Result := not (ATool in [tkMoveSelection, tkMovePixels, tkPan]);
end;

function PaintToolUsesBrushOverlay(ATool: TToolKind): Boolean;
begin
  Result := ATool in [tkPencil, tkBrush, tkEraser, tkCloneStamp, tkRecolor];
end;

function LayerOpacityPercentFromByte(AOpacity: Byte): Integer;
begin
  Result := (Integer(AOpacity) * 100 + 127) div 255;
end;

function LayerOpacityByteFromPercent(APercent: Integer): Byte;
var
  Clamped: Integer;
begin
  Clamped := APercent;
  if Clamped < 0 then
    Clamped := 0
  else if Clamped > 100 then
    Clamped := 100;
  Result := (Clamped * 255 + 50) div 100;
end;

function PaintToolDisplayCount: Integer;
begin
  Result := Length(ToolDisplayOrder);
end;

function PaintToolAtDisplayIndex(AIndex: Integer): TToolKind;
begin
  if AIndex < Low(ToolDisplayOrder) then
    Exit(ToolDisplayOrder[Low(ToolDisplayOrder)]);
  if AIndex > High(ToolDisplayOrder) then
    Exit(ToolDisplayOrder[High(ToolDisplayOrder)]);
  Result := ToolDisplayOrder[AIndex];
end;

function PaintToolDisplayIndex(ATool: TToolKind): Integer;
var
  Index: Integer;
begin
  for Index := Low(ToolDisplayOrder) to High(ToolDisplayOrder) do
    if ToolDisplayOrder[Index] = ATool then
      Exit(Index);
  Result := 0;
end;

function DefaultStartupTool: TToolKind;
begin
  Result := ToolDisplayOrder[0];
end;

function ToolShortcutUsesPlainKeyOnly(const AShift: TShiftState): Boolean;
begin
  Result := not ((ssMeta in AShift) or (ssCtrl in AShift) or (ssAlt in AShift));
end;

function AdoptSampledRGBPreservingAlpha(const ACurrentColor, ASampledColor: TRGBA32): TRGBA32;
var
  StraightSample: TRGBA32;
begin
  StraightSample := Unpremultiply(ASampledColor);
  Result := RGBA(StraightSample.R, StraightSample.G, StraightSample.B, ACurrentColor.A);
end;

function DragButtonIsStillPressed(AButton: TMouseButton; const AShift: TShiftState): Boolean;
begin
  case AButton of
    mbRight:
      Result := ssRight in AShift;
    mbMiddle:
      Result := ssMiddle in AShift;
  else
    Result := ssLeft in AShift;
  end;
end;

function ShouldCommitPendingStrokeOnMouseDown(AHasPendingStroke: Boolean): Boolean;
begin
  { A fresh press should never silently discard an unfinished brush-like stroke. }
  Result := AHasPendingStroke;
end;

function LineReleaseStartsBezier(ABezierEnabled: Boolean; const AStartPoint, AEndPoint: TPoint): Boolean;
begin
  Result := ABezierEnabled and
    ((AStartPoint.X <> AEndPoint.X) or (AStartPoint.Y <> AEndPoint.Y));
end;

function IsSelectionTool(ATool: TToolKind): Boolean;
begin
  Result := ATool in [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand,
                      tkMoveSelection, tkMovePixels];
end;

function NextToolForKey(AKey: Char; AReverse: Boolean; ACurrent: TToolKind): TToolKind;
var
  Cycle: array of TToolKind;
  I, Index: Integer;
  Rev: Boolean;
begin
  Result := ACurrent;
  Rev := AReverse;
  case UpCase(AKey) of
    'S': Cycle := [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand];
    'M': Cycle := [tkMoveSelection, tkMovePixels];
    'Z': Cycle := [tkZoom];
    'H': Cycle := [tkPan];
    'G': Cycle := [tkFill, tkGradient];
    'B': Cycle := [tkBrush];
    'E': Cycle := [tkEraser];
    'P': Cycle := [tkPencil];
    'K': Cycle := [tkColorPicker];
    'C': Cycle := [tkCloneStamp];
    'J': Cycle := [tkRecolor, tkMosaic];
    'T': Cycle := [tkText];
    'O': Cycle := [tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape];
  else
    Exit;
  end;

  { locate current tool in cycle }
  Index := -1;
  for I := 0 to High(Cycle) do
    if Cycle[I] = ACurrent then
    begin
      Index := I;
      Break;
    end;

  if Index = -1 then
  begin
    if Rev then
      Result := Cycle[High(Cycle)]
    else
      Result := Cycle[0];
    Exit;
  end;

  if Rev then
  begin
    Dec(Index);
    if Index < 0 then
      Index := High(Cycle);
  end
  else
  begin
    Inc(Index);
    if Index > High(Cycle) then
      Index := 0;
  end;
  Result := Cycle[Index];
end;

end.
