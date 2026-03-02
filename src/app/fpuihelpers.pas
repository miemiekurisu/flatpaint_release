unit FPUIHelpers;

{$mode objfpc}{$H+}

interface

uses
  FPDocument;

function PaintToolName(ATool: TToolKind): string;
function PaintToolHint(ATool: TToolKind): string;
function PaintToolGlyph(ATool: TToolKind): string;
function PaintToolDisplayCount: Integer;
function PaintToolAtDisplayIndex(AIndex: Integer): TToolKind;
function PaintToolDisplayIndex(ATool: TToolKind): Integer;

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
      Result := 'Line drags a straight stroke between two points';
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
      Result := 'Text places a text string onto the active layer';
    tkCloneStamp:
      Result := 'Clone Stamp copies pixels from a sampled source point';
    tkRecolor:
      Result := 'Recolor replaces the source color under the brush with the target color';
  else
    Result := 'Ready';
  end;
end;

function PaintToolGlyph(ATool: TToolKind): string;
begin
  case ATool of
    tkPencil:
      Result := '✐';
    tkSelectRect:
      Result := '▭';
    tkSelectEllipse:
      Result := '◯';
    tkSelectLasso:
      Result := '⌁';
    tkMagicWand:
      Result := '✦';
    tkMoveSelection:
      Result := '⇱';
    tkMovePixels:
      Result := '✥';
    tkZoom:
      Result := '⊕';
    tkPan:
      Result := '✋';
    tkFill:
      Result := '▨';
    tkGradient:
      Result := '◢';
    tkBrush:
      Result := '✎';
    tkEraser:
      Result := '⌫';
    tkColorPicker:
      Result := '⊙';
    tkLine:
      Result := '╱';
    tkRectangle:
      Result := '□';
    tkRoundedRectangle:
      Result := '▢';
    tkEllipseShape:
      Result := '○';
    tkFreeformShape:
      Result := '⬠';
    tkCrop:
      Result := '⊹';
    tkText:
      Result := 'T';
    tkCloneStamp:
      Result := '✦';
    tkRecolor:
      Result := '☁';
  else
    Result := '?';
  end;
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

end.
