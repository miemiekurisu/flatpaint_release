unit FPIconHelpers;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Graphics;

type
  TButtonIconContext = (
    bicAuto,
    bicCommand,
    bicTool,
    bicUtility
  );

function ButtonIconSupported(const ACaption: string; AContext: TButtonIconContext): Boolean;
function TryBuildButtonGlyph(const ACaption: string; AContext: TButtonIconContext; AGlyph: TBitmap): Boolean;

implementation

uses
  Math;

type
  TButtonIconKind = (
    bikNone,
    bikNew,
    bikOpen,
    bikSave,
    bikCut,
    bikCopy,
    bikPaste,
    bikUndo,
    bikRedo,
    bikZoomIn,
    bikZoomOut,
    bikAdd,
    bikDuplicate,
    bikDelete,
    bikMerge,
    bikVisibility,
    bikArrowUp,
    bikArrowDown,
    bikFade,
    bikFlatten,
    bikRename,
    bikProperties,
    bikTools,
    bikHistory,
    bikLayers,
    bikColors,
    bikSettings,
    bikHelp,
    bikSelectRect,
    bikSelectEllipse,
    bikSelectLasso,
    bikMagicWand,
    bikMoveSelection,
    bikMovePixels,
    bikZoomTool,
    bikPan,
    bikFill,
    bikGradient,
    bikPencil,
    bikBrush,
    bikEraser,
    bikPicker,
    bikClone,
    bikRecolor,
    bikLine,
    bikRectangle,
    bikRoundedRect,
    bikEllipse,
    bikFreeform,
    bikCrop,
    bikText
  );

const
  IconBitmapSize = 16;
  IconBackgroundColor = clFuchsia;
  IconForegroundColor = TColor($00323232);

function NormalizeCaption(const ACaption: string): string;
begin
  Result := UpperCase(Trim(ACaption));
end;

procedure PrepareGlyphBitmap(AGlyph: TBitmap);
begin
  AGlyph.SetSize(IconBitmapSize, IconBitmapSize);
  AGlyph.Canvas.Brush.Color := IconBackgroundColor;
  AGlyph.Canvas.FillRect(0, 0, IconBitmapSize, IconBitmapSize);
  AGlyph.Transparent := True;
  AGlyph.TransparentColor := IconBackgroundColor;
  AGlyph.Canvas.Pen.Color := IconForegroundColor;
  AGlyph.Canvas.Pen.Width := 1;
  AGlyph.Canvas.Brush.Style := bsClear;
  AGlyph.Canvas.Font.Color := IconForegroundColor;
  AGlyph.Canvas.Font.Size := 8;
  AGlyph.Canvas.Font.Style := [fsBold];
end;

procedure DrawArrow(ACanvas: TCanvas; const APoints: array of TPoint);
begin
  if Length(APoints) >= 2 then
    ACanvas.Polyline(APoints);
end;

procedure DrawCenteredText(ACanvas: TCanvas; const AText: string; ATopAdjust: Integer = 0);
var
  W: Integer;
  H: Integer;
begin
  W := ACanvas.TextWidth(AText);
  H := ACanvas.TextHeight(AText);
  ACanvas.TextOut(
    Max(0, (IconBitmapSize - W) div 2),
    Max(0, ((IconBitmapSize - H) div 2) + ATopAdjust),
    AText
  );
end;

function ResolveCommandIconKind(const ACaption: string): TButtonIconKind;
var
  Key: string;
begin
  Key := NormalizeCaption(ACaption);
  if Key = 'NEW' then Exit(bikNew);
  if Key = 'OPEN' then Exit(bikOpen);
  if Key = 'SAVE' then Exit(bikSave);
  if Key = 'CUT' then Exit(bikCut);
  if Key = 'COPY' then Exit(bikCopy);
  if Key = 'PASTE' then Exit(bikPaste);
  if Key = 'UNDO' then Exit(bikUndo);
  if Key = 'REDO' then Exit(bikRedo);
  if Key = '+' then Exit(bikAdd);
  if Key = '-' then Exit(bikZoomOut);
  if Key = 'DUP' then Exit(bikDuplicate);
  if Key = 'DEL' then Exit(bikDelete);
  if Key = 'MRG' then Exit(bikMerge);
  if Key = 'VIS' then Exit(bikVisibility);
  if Key = 'UP' then Exit(bikArrowUp);
  if Key = 'DN' then Exit(bikArrowDown);
  if Key = 'FADE' then Exit(bikFade);
  if Key = 'FLAT' then Exit(bikFlatten);
  if Key = 'NAME' then Exit(bikRename);
  if Key = 'PROPS' then Exit(bikProperties);
  if Key = 'X' then Exit(bikDelete);
  Result := bikNone;
end;

function ResolveUtilityIconKind(const ACaption: string): TButtonIconKind;
begin
  if ACaption = '▦' then Exit(bikTools);
  if ACaption = '↺' then Exit(bikHistory);
  if ACaption = '▤' then Exit(bikLayers);
  if ACaption = '◍' then Exit(bikColors);
  if ACaption = '⚙' then Exit(bikSettings);
  if ACaption = '?' then Exit(bikHelp);
  Result := bikNone;
end;

function ResolveToolIconKind(const ACaption: string): TButtonIconKind;
begin
  if ACaption = '▭' then Exit(bikSelectRect);
  if ACaption = '◌' then Exit(bikSelectEllipse);
  if ACaption = '⌒' then Exit(bikSelectLasso);
  if ACaption = '✦' then Exit(bikMagicWand);
  if ACaption = '⊞' then Exit(bikMoveSelection);
  if ACaption = '✣' then Exit(bikMovePixels);
  if ACaption = '⌕' then Exit(bikZoomTool);
  if ACaption = '↕' then Exit(bikPan);
  if ACaption = '▧' then Exit(bikFill);
  if ACaption = '◫' then Exit(bikGradient);
  if ACaption = '✎' then Exit(bikPencil);
  if ACaption = '◍' then Exit(bikBrush);
  if ACaption = '⌫' then Exit(bikEraser);
  if ACaption = '⌖' then Exit(bikPicker);
  if ACaption = '⧉' then Exit(bikClone);
  if ACaption = '◐' then Exit(bikRecolor);
  if ACaption = '／' then Exit(bikLine);
  if ACaption = '□' then Exit(bikRectangle);
  if ACaption = '▢' then Exit(bikRoundedRect);
  if ACaption = '○' then Exit(bikEllipse);
  if ACaption = '〰' then Exit(bikFreeform);
  if ACaption = '⌗' then Exit(bikCrop);
  if ACaption = 'T' then Exit(bikText);
  Result := bikNone;
end;

function ResolveAutoIconKind(const ACaption: string): TButtonIconKind;
begin
  Result := ResolveCommandIconKind(ACaption);
end;

function ResolveButtonIconKind(const ACaption: string; AContext: TButtonIconContext): TButtonIconKind;
begin
  case AContext of
    bicCommand:
      Result := ResolveCommandIconKind(ACaption);
    bicTool:
      Result := ResolveToolIconKind(ACaption);
    bicUtility:
      Result := ResolveUtilityIconKind(ACaption);
  else
    Result := ResolveAutoIconKind(ACaption);
  end;
end;

procedure DrawIcon(AKind: TButtonIconKind; AGlyph: TBitmap);
var
  C: TCanvas;
begin
  C := AGlyph.Canvas;
  case AKind of
    bikNew:
      begin
        C.Rectangle(3, 2, 12, 14);
        C.Line(9, 2, 12, 5);
        C.Line(9, 2, 9, 5);
        C.Line(6, 8, 9, 8);
        C.Line(7, 7, 7, 10);
      end;
    bikOpen:
      begin
        C.Line(2, 6, 5, 6);
        C.Line(5, 6, 6, 4);
        C.Line(6, 4, 13, 4);
        C.Rectangle(2, 6, 13, 12);
      end;
    bikSave:
      begin
        C.Rectangle(2, 2, 14, 14);
        C.Line(4, 4, 10, 4);
        C.Rectangle(5, 8, 11, 12);
        C.Line(10, 2, 10, 6);
      end;
    bikCut:
      begin
        C.Ellipse(2, 9, 6, 13);
        C.Ellipse(6, 9, 10, 13);
        C.Line(4, 10, 12, 3);
        C.Line(8, 10, 13, 13);
      end;
    bikCopy:
      begin
        C.Rectangle(3, 4, 11, 12);
        C.Rectangle(6, 2, 14, 10);
      end;
    bikPaste:
      begin
        C.Rectangle(3, 4, 13, 14);
        C.Rectangle(5, 2, 11, 5);
        C.Line(6, 7, 10, 7);
        C.Line(6, 9, 10, 9);
      end;
    bikUndo:
      begin
        DrawArrow(C, [Point(10, 4), Point(5, 4), Point(3, 6)]);
        DrawArrow(C, [Point(5, 4), Point(7, 2)]);
        DrawArrow(C, [Point(5, 4), Point(7, 6)]);
        C.Line(10, 4, 12, 6);
      end;
    bikRedo:
      begin
        DrawArrow(C, [Point(5, 4), Point(10, 4), Point(12, 6)]);
        DrawArrow(C, [Point(10, 4), Point(8, 2)]);
        DrawArrow(C, [Point(10, 4), Point(8, 6)]);
        C.Line(5, 4, 3, 6);
      end;
    bikZoomIn, bikZoomTool:
      begin
        C.Ellipse(2, 2, 10, 10);
        C.Line(8, 8, 13, 13);
        C.Line(4, 6, 8, 6);
        C.Line(6, 4, 6, 8);
      end;
    bikZoomOut:
      begin
        C.Ellipse(2, 2, 10, 10);
        C.Line(8, 8, 13, 13);
        C.Line(4, 6, 8, 6);
      end;
    bikAdd:
      begin
        C.Line(3, 8, 13, 8);
        C.Line(8, 3, 8, 13);
      end;
    bikDuplicate:
      begin
        C.Rectangle(3, 5, 10, 12);
        C.Rectangle(6, 2, 13, 9);
      end;
    bikDelete:
      begin
        C.Line(4, 4, 12, 12);
        C.Line(12, 4, 4, 12);
      end;
    bikMerge:
      begin
        C.Line(3, 4, 9, 4);
        C.Line(5, 8, 11, 8);
        C.Line(11, 8, 8, 11);
        C.Line(11, 8, 8, 5);
      end;
    bikVisibility:
      begin
        C.Ellipse(2, 4, 14, 12);
        C.Ellipse(6, 6, 10, 10);
      end;
    bikArrowUp:
      begin
        DrawArrow(C, [Point(8, 3), Point(4, 7), Point(6, 7)]);
        C.Line(8, 3, 12, 7);
        C.Line(8, 3, 8, 13);
      end;
    bikArrowDown:
      begin
        DrawArrow(C, [Point(8, 13), Point(4, 9), Point(6, 9)]);
        C.Line(8, 13, 12, 9);
        C.Line(8, 3, 8, 13);
      end;
    bikFade:
      begin
        C.Ellipse(3, 3, 13, 13);
        C.Brush.Style := bsSolid;
        C.Brush.Color := IconForegroundColor;
        C.Pie(3, 3, 13, 13, 8, 3, 8, 13);
        C.Brush.Style := bsClear;
      end;
    bikFlatten:
      begin
        C.Rectangle(3, 3, 12, 6);
        C.Rectangle(4, 7, 13, 10);
        C.Rectangle(5, 11, 14, 14);
      end;
    bikRename:
      begin
        C.Line(3, 12, 12, 3);
        C.Line(10, 3, 12, 5);
        C.Line(3, 12, 5, 12);
      end;
    bikProperties, bikSettings:
      begin
        C.Ellipse(5, 5, 11, 11);
        C.Line(8, 1, 8, 4);
        C.Line(8, 12, 8, 15);
        C.Line(1, 8, 4, 8);
        C.Line(12, 8, 15, 8);
        C.Line(3, 3, 5, 5);
        C.Line(11, 11, 13, 13);
        C.Line(11, 5, 13, 3);
        C.Line(3, 13, 5, 11);
      end;
    bikTools:
      begin
        C.Rectangle(2, 2, 6, 6);
        C.Rectangle(8, 2, 12, 6);
        C.Rectangle(2, 8, 6, 12);
        C.Rectangle(8, 8, 12, 12);
      end;
    bikHistory:
      begin
        C.Arc(2, 2, 13, 13, 4, 3, 2, 8);
        C.Line(2, 8, 5, 6);
        C.Line(2, 8, 5, 10);
      end;
    bikLayers:
      begin
        C.Polygon([Point(8, 2), Point(13, 5), Point(8, 8), Point(3, 5)]);
        C.Polygon([Point(8, 6), Point(13, 9), Point(8, 12), Point(3, 9)]);
      end;
    bikColors:
      begin
        C.Ellipse(2, 4, 9, 11);
        C.Ellipse(7, 4, 14, 11);
      end;
    bikHelp:
      DrawCenteredText(C, '?');
    bikSelectRect:
      C.Rectangle(3, 3, 13, 12);
    bikSelectEllipse:
      C.Ellipse(3, 3, 13, 12);
    bikSelectLasso:
      C.Polyline([Point(3, 9), Point(5, 4), Point(9, 3), Point(12, 6), Point(10, 11), Point(6, 12), Point(3, 9)]);
    bikMagicWand:
      begin
        C.Line(4, 12, 10, 6);
        C.Line(10, 2, 10, 4);
        C.Line(10, 8, 10, 10);
        C.Line(8, 6, 6, 6);
        C.Line(12, 6, 14, 6);
      end;
    bikMoveSelection:
      begin
        C.Rectangle(4, 4, 12, 12);
        C.Line(8, 2, 8, 14);
        C.Line(2, 8, 14, 8);
      end;
    bikMovePixels:
      begin
        C.Rectangle(4, 4, 8, 8);
        C.Rectangle(8, 8, 12, 12);
        C.Line(2, 8, 14, 8);
      end;
    bikPan:
      begin
        C.Line(8, 2, 8, 14);
        C.Line(2, 8, 14, 8);
        C.Line(8, 2, 6, 4);
        C.Line(8, 2, 10, 4);
        C.Line(8, 14, 6, 12);
        C.Line(8, 14, 10, 12);
      end;
    bikFill:
      begin
        C.Polygon([Point(4, 4), Point(9, 2), Point(12, 7), Point(7, 9)]);
        C.Line(8, 10, 12, 10);
        C.Line(9, 12, 11, 12);
      end;
    bikGradient:
      begin
        C.Rectangle(2, 4, 13, 11);
        C.Line(4, 5, 11, 10);
      end;
    bikPencil:
      begin
        C.Line(3, 12, 11, 4);
        C.Line(10, 3, 12, 5);
        C.Line(3, 12, 5, 12);
      end;
    bikBrush:
      begin
        C.Ellipse(3, 3, 10, 10);
        C.Line(8, 9, 12, 13);
      end;
    bikEraser:
      begin
        C.Polygon([Point(4, 11), Point(8, 5), Point(12, 9), Point(8, 13)]);
      end;
    bikPicker:
      begin
        C.Ellipse(4, 3, 9, 8);
        C.Line(8, 7, 12, 11);
        C.Line(12, 11, 10, 13);
      end;
    bikClone:
      begin
        C.Rectangle(3, 5, 8, 10);
        C.Rectangle(7, 3, 12, 8);
        C.Line(9, 9, 13, 13);
      end;
    bikRecolor:
      begin
        C.Ellipse(3, 3, 12, 12);
        C.Line(7, 3, 7, 12);
        C.Line(7, 8, 12, 8);
      end;
    bikLine:
      C.Line(3, 12, 13, 4);
    bikRectangle:
      C.Rectangle(3, 4, 13, 12);
    bikRoundedRect:
      begin
        C.RoundRect(3, 4, 13, 12, 4, 4);
      end;
    bikEllipse:
      C.Ellipse(3, 4, 13, 12);
    bikFreeform:
      C.Polyline([Point(2, 10), Point(4, 5), Point(7, 7), Point(10, 3), Point(13, 8)]);
    bikCrop:
      begin
        C.Line(4, 2, 4, 10);
        C.Line(4, 10, 12, 10);
        C.Line(8, 4, 8, 12);
        C.Line(8, 4, 14, 4);
      end;
    bikText:
      DrawCenteredText(C, 'T', -1);
  end;
end;

function ButtonIconSupported(const ACaption: string; AContext: TButtonIconContext): Boolean;
begin
  Result := ResolveButtonIconKind(ACaption, AContext) <> bikNone;
end;

function TryBuildButtonGlyph(const ACaption: string; AContext: TButtonIconContext; AGlyph: TBitmap): Boolean;
var
  IconKind: TButtonIconKind;
begin
  if AGlyph = nil then
    Exit(False);
  IconKind := ResolveButtonIconKind(ACaption, AContext);
  Result := IconKind <> bikNone;
  if not Result then
    Exit;
  PrepareGlyphBitmap(AGlyph);
  DrawIcon(IconKind, AGlyph);
end;

end.
