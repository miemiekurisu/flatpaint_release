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

const
  ToolDisplayOrder: array[0..22] of TToolKind = (
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
      Result := 'Pencil';
    tkBrush:
      Result := 'Brush';
    tkEraser:
      Result := 'Eraser';
    tkFill:
      Result := 'Paint Bucket';
    tkGradient:
      Result := 'Gradient';
    tkLine:
      Result := 'Line';
    tkRectangle:
      Result := 'Rectangle';
    tkRoundedRectangle:
      Result := 'Rounded Rectangle';
    tkEllipseShape:
      Result := 'Ellipse';
    tkFreeformShape:
      Result := 'Freeform Shape';
    tkSelectRect:
      Result := 'Rectangle Select';
    tkSelectEllipse:
      Result := 'Ellipse Select';
    tkSelectLasso:
      Result := 'Lasso Select';
    tkMagicWand:
      Result := 'Magic Wand';
    tkMoveSelection:
      Result := 'Move Selection';
    tkMovePixels:
      Result := 'Move Selected Pixels';
    tkZoom:
      Result := 'Zoom';
    tkPan:
      Result := 'Pan';
    tkColorPicker:
      Result := 'Color Picker';
    tkCrop:
      Result := 'Crop';
    tkText:
      Result := 'Text';
    tkCloneStamp:
      Result := 'Clone Stamp';
    tkRecolor:
      Result := 'Recolor';
  else
    Result := 'Tool';
  end;
end;

function PaintToolHint(ATool: TToolKind): string;
begin
  case ATool of
    tkPencil:
      Result := 'Pencil paints hard-edged strokes';
    tkBrush:
      Result := 'Brush paints with the primary or secondary color';
    tkEraser:
      Result := 'Eraser clears pixels to transparency';
    tkFill:
      Result := 'Paint Bucket floods adjacent pixels from the clicked point';
    tkGradient:
      Result := 'Gradient drags from primary toward secondary color';
    tkLine:
      Result := 'Line drags a straight segment by default; enable the Bezier option to stage handles and keep chaining segments until Enter or right-click';
    tkRectangle:
      Result := 'Rectangle drags an outlined rectangle';
    tkRoundedRectangle:
      Result := 'Rounded Rectangle drags an outlined rounded rectangle';
    tkEllipseShape:
      Result := 'Ellipse drags an outlined ellipse';
    tkFreeformShape:
      Result := 'Freeform Shape traces a closed freeform outline';
    tkSelectRect:
      Result := 'Rectangle Select drags a rectangular selection';
    tkSelectEllipse:
      Result := 'Ellipse Select drags an elliptical selection';
    tkSelectLasso:
      Result := 'Lasso Select traces a freeform polygon';
    tkMagicWand:
      Result := 'Magic Wand selects a contiguous color region';
    tkMoveSelection:
      Result := 'Move Selection repositions the current selection mask';
    tkMovePixels:
      Result := 'Move Selected Pixels repositions selected pixels';
    tkZoom:
      Result := 'Zoom clicks in or out of the canvas view';
    tkPan:
      Result := 'Pan drags the viewport without changing pixels';
    tkColorPicker:
      Result := 'Color Picker samples the composite image';
    tkCrop:
      Result := 'Crop trims the canvas to a dragged rectangle';
    tkText:
      Result := 'Text clicks to type inline on the canvas; right-click or Option-click edits text style';
    tkCloneStamp:
      Result := 'Clone Stamp samples with right-click or Option-click, then paints sampled pixels with the brush';
    tkRecolor:
      Result := 'Recolor swaps active and inactive swatch colors within the brush tolerance';
  else
    Result := 'Ready';
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
    tkZoom:
      Result := 'Z';
    tkPan:
      Result := 'H';
    tkFill:
      Result := 'F';
    tkGradient:
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
      Result := 'L';
    tkRecolor:
      Result := 'R';
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
    Exit('No single-key shortcut is assigned');

  Result := 'Shortcut: ' + KeyLabel;
  if ATool in [
    tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand,
    tkMoveSelection, tkMovePixels,
    tkLine, tkRectangle, tkRoundedRectangle, tkEllipseShape, tkFreeformShape
  ] then
    Result := Result + ' (repeat to cycle related tools, Shift reverses)';
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
begin
  Result := RGBA(ASampledColor.R, ASampledColor.G, ASampledColor.B, ACurrentColor.A);
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
    'F': Cycle := [tkFill];
    'G': Cycle := [tkGradient];
    'B': Cycle := [tkBrush];
    'E': Cycle := [tkEraser];
    'P': Cycle := [tkPencil];
    'K': Cycle := [tkColorPicker];
    'L': Cycle := [tkCloneStamp];
    'R': Cycle := [tkRecolor];
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
