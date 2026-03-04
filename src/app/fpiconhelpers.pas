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
function ButtonIconCanLoadRenderedAsset(const ACaption: string; AContext: TButtonIconContext): Boolean;
function TryLoadButtonIconPicture(
  const ACaption: string;
  AContext: TButtonIconContext;
  APicture: TPicture
): Boolean;
function TryBuildButtonGlyph(
  const ACaption: string;
  AContext: TButtonIconContext;
  AGlyph: TBitmap;
  ABackgroundColor: TColor = clBtnFace
): Boolean;
function TryBuildLineButtonGlyph(
  const ACaption: string;
  AContext: TButtonIconContext;
  AGlyph: TBitmap;
  ABackgroundColor: TColor = clBtnFace
): Boolean;

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
    bikSwap,
    bikMono,
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
  IconBitmapSize = 20;
  IconForegroundColor = TColor($00323232);
  MaxIconRootSearchDepth = 6;

var
  GCachedRenderedIconDir: string = '';
  GCachedRenderedIconDirKnown: Boolean = False;

function NormalizeCaption(const ACaption: string): string;
begin
  Result := UpperCase(Trim(ACaption));
end;

function RenderedIconAssetName(AKind: TButtonIconKind): string;
begin
  case AKind of
    bikNew:
      Result := 'file-plus-2.svg.png';
    bikOpen:
      Result := 'folder-open.svg.png';
    bikSave:
      Result := 'save.svg.png';
    bikCut:
      Result := 'scissors.svg.png';
    bikCopy:
      Result := 'copy.svg.png';
    bikPaste:
      Result := 'clipboard-paste.svg.png';
    bikUndo:
      Result := 'undo.svg.png';
    bikRedo:
      Result := 'redo.svg.png';
    bikZoomIn:
      Result := 'zoom-in.svg.png';
    bikZoomOut:
      Result := 'zoom-out.svg.png';
    bikAdd:
      Result := 'plus.svg.png';
    bikDuplicate:
      Result := 'copy-plus.svg.png';
    bikDelete:
      Result := 'trash-2.svg.png';
    bikMerge:
      Result := 'combine.svg.png';
    bikVisibility:
      Result := 'eye.svg.png';
    bikArrowUp:
      Result := 'arrow-up.svg.png';
    bikArrowDown:
      Result := 'arrow-down.svg.png';
    bikFade:
      Result := 'blend.svg.png';
    bikFlatten:
      Result := 'layers-2.svg.png';
    bikRename:
      Result := 'pen.svg.png';
    bikProperties:
      Result := 'sliders-horizontal.svg.png';
    bikSwap:
      Result := 'arrow-left-right.svg.png';
    bikMono:
      Result := 'contrast.svg.png';
    bikTools:
      Result := 'wrench.svg.png';
    bikHistory:
      Result := 'history.svg.png';
    bikLayers:
      Result := 'layers.svg.png';
    bikColors:
      Result := 'palette.svg.png';
    bikSettings:
      Result := 'settings.svg.png';
    bikHelp:
      Result := 'circle-help.svg.png';
    bikSelectRect:
      Result := 'square-dashed.svg.png';
    bikSelectEllipse:
      Result := 'circle-dashed.svg.png';
    bikSelectLasso:
      Result := 'lasso.svg.png';
    bikMagicWand:
      Result := 'wand.svg.png';
    bikMoveSelection:
      Result := 'move.svg.png';
    bikMovePixels:
      Result := 'pointer.svg.png';
    bikZoomTool:
      Result := 'search.svg.png';
    bikPan:
      Result := 'hand.svg.png';
    bikFill:
      Result := 'paint-bucket.svg.png';
    bikGradient:
      Result := 'blend.svg.png';
    bikPencil:
      Result := 'pencil.svg.png';
    bikBrush:
      Result := 'paintbrush.svg.png';
    bikEraser:
      Result := 'eraser.svg.png';
    bikPicker:
      Result := 'pipette.svg.png';
    bikClone:
      Result := 'stamp.svg.png';
    bikRecolor:
      Result := 'droplets.svg.png';
    bikLine:
      Result := 'slash.svg.png';
    bikRectangle:
      Result := 'square.svg.png';
    bikRoundedRect:
      Result := 'square-round-corner.svg.png';
    bikEllipse:
      Result := 'circle.svg.png';
    bikFreeform:
      Result := 'spline.svg.png';
    bikCrop:
      Result := 'crop.svg.png';
    bikText:
      Result := 'type.svg.png';
  else
    Result := '';
  end;
end;

function ResolveRenderedIconDir: string;
var
  BaseDir: string;
  ParentDir: string;
  Candidate: string;
  Depth: Integer;
begin
  if GCachedRenderedIconDirKnown then
    Exit(GCachedRenderedIconDir);

  GCachedRenderedIconDirKnown := True;
  GCachedRenderedIconDir := '';
  BaseDir := ExpandFileName(ExtractFileDir(ParamStr(0)));

  Candidate := ExpandFileName(
    BaseDir + PathDelim + '..' + PathDelim + 'Resources' + PathDelim + 'icons' + PathDelim + 'rendered'
  );
  if DirectoryExists(Candidate) then
  begin
    GCachedRenderedIconDir := Candidate;
    Exit(GCachedRenderedIconDir);
  end;

  Candidate := ExpandFileName(GetCurrentDir + PathDelim + 'assets' + PathDelim + 'icons' + PathDelim + 'rendered');
  if DirectoryExists(Candidate) then
  begin
    GCachedRenderedIconDir := Candidate;
    Exit(GCachedRenderedIconDir);
  end;

  for Depth := 0 to MaxIconRootSearchDepth do
  begin
    Candidate := IncludeTrailingPathDelimiter(BaseDir) + 'assets' + PathDelim + 'icons' + PathDelim + 'rendered';
    if DirectoryExists(Candidate) then
    begin
      GCachedRenderedIconDir := Candidate;
      Exit(GCachedRenderedIconDir);
    end;
    ParentDir := ExpandFileName(BaseDir + PathDelim + '..');
    if ParentDir = BaseDir then
      Break;
    BaseDir := ParentDir;
  end;

  Result := GCachedRenderedIconDir;
end;

procedure PrepareGlyphBitmap(AGlyph: TBitmap; ABackgroundColor: TColor);
const
  TransparentGlyphColor = TColor($00FF00FF);
begin
  AGlyph.SetSize(IconBitmapSize, IconBitmapSize);
  AGlyph.Canvas.Brush.Color := TransparentGlyphColor;
  AGlyph.Canvas.FillRect(0, 0, IconBitmapSize, IconBitmapSize);
  AGlyph.TransparentColor := TransparentGlyphColor;
  AGlyph.Transparent := True;
  AGlyph.Canvas.Pen.Color := IconForegroundColor;
  AGlyph.Canvas.Pen.Width := 1;
  AGlyph.Canvas.Brush.Style := bsClear;
  AGlyph.Canvas.Font.Color := IconForegroundColor;
  AGlyph.Canvas.Font.Size := 8;
  AGlyph.Canvas.Font.Style := [fsBold];
  if ABackgroundColor = clNone then
    AGlyph.Canvas.Pen.Color := IconForegroundColor;
end;

function TryLoadRenderedIcon(AKind: TButtonIconKind; AGlyph: TBitmap): Boolean;
var
  AssetName: string;
  AssetPath: string;
  RenderedIcon: TPortableNetworkGraphic;
begin
  Result := False;
  if AGlyph = nil then
    Exit;

  AssetName := RenderedIconAssetName(AKind);
  if AssetName = '' then
    Exit;

  AssetPath := ResolveRenderedIconDir;
  if AssetPath = '' then
    Exit;

  AssetPath := IncludeTrailingPathDelimiter(AssetPath) + AssetName;
  if not FileExists(AssetPath) then
    Exit;

  RenderedIcon := TPortableNetworkGraphic.Create;
  try
    try
      RenderedIcon.LoadFromFile(AssetPath);
      PrepareGlyphBitmap(AGlyph, clNone);
      if (RenderedIcon.Width = IconBitmapSize) and (RenderedIcon.Height = IconBitmapSize) then
        AGlyph.Canvas.Draw(0, 0, RenderedIcon)
      else
        AGlyph.Canvas.StretchDraw(Rect(0, 0, IconBitmapSize, IconBitmapSize), RenderedIcon);
      Result := True;
    except
      Result := False;
    end;
  finally
    RenderedIcon.Free;
  end;
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
  if Key = 'ZOOM+' then Exit(bikZoomIn);
  if Key = 'ZOOM-' then Exit(bikZoomOut);
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
  if Key = 'SWAP' then Exit(bikSwap);
  if Key = 'MONO' then Exit(bikMono);
  if Key = 'X' then Exit(bikDelete);
  Result := bikNone;
end;

function ResolveUtilityIconKind(const ACaption: string): TButtonIconKind;
var
  Key: string;
begin
  Key := NormalizeCaption(ACaption);
  if (ACaption = '▦') or (Key = 'TOOLS') then Exit(bikTools);
  if (ACaption = '↺') or (Key = 'HISTORY') then Exit(bikHistory);
  if (ACaption = '▤') or (Key = 'LAYERS') then Exit(bikLayers);
  if (ACaption = '◍') or (Key = 'COLORS') then Exit(bikColors);
  if (ACaption = '⚙') or (Key = 'SETTINGS') then Exit(bikSettings);
  if (ACaption = '?') or (Key = 'HELP') then Exit(bikHelp);
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
        C.Pen.Width := 2;
        C.Polyline([Point(5, 2), Point(10, 2), Point(13, 5), Point(13, 14), Point(5, 14), Point(5, 2)]);
        C.Line(10, 2, 10, 5);
        C.Line(10, 5, 13, 5);
        C.Line(9, 9, 9, 12);
        C.Line(7, 11, 11, 11);
      end;
    bikOpen:
      begin
        C.Pen.Width := 2;
        C.Polyline([Point(3, 6), Point(3, 4), Point(7, 4), Point(9, 6), Point(13, 6)]);
        C.Polyline([Point(3, 8), Point(13, 8), Point(11, 13), Point(4, 13), Point(3, 8)]);
      end;
    bikSave:
      begin
        C.Pen.Width := 2;
        C.Polyline([Point(3, 2), Point(12, 2), Point(14, 4), Point(14, 14), Point(3, 14), Point(3, 2)]);
        C.Line(5, 4, 11, 4);
        C.Polyline([Point(6, 9), Point(11, 9), Point(11, 14)]);
        C.Line(11, 2, 11, 6);
      end;
    bikCut:
      begin
        C.Pen.Width := 2;
        C.Ellipse(2, 2, 7, 7);
        C.Ellipse(2, 9, 7, 14);
        C.Line(7, 6, 13, 2);
        C.Line(8, 9, 13, 14);
      end;
    bikCopy:
      begin
        C.Pen.Width := 2;
        C.RoundRect(4, 5, 11, 12, 2, 2);
        C.RoundRect(7, 2, 14, 9, 2, 2);
      end;
    bikPaste:
      begin
        C.Pen.Width := 2;
        C.RoundRect(4, 4, 13, 14, 2, 2);
        C.RoundRect(6, 2, 11, 5, 2, 2);
        C.Line(7, 8, 11, 8);
        C.Line(7, 11, 10, 11);
      end;
    bikUndo:
      begin
        C.Pen.Width := 2;
        C.Polyline([Point(7, 4), Point(3, 8), Point(7, 12)]);
        C.Polyline([Point(4, 8), Point(10, 8), Point(13, 11)]);
      end;
    bikRedo:
      begin
        C.Pen.Width := 2;
        C.Polyline([Point(9, 4), Point(13, 8), Point(9, 12)]);
        C.Polyline([Point(12, 8), Point(6, 8), Point(3, 11)]);
      end;
    bikZoomIn, bikZoomTool:
      begin
        C.Pen.Width := 2;
        C.Ellipse(2, 2, 11, 11);
        C.Line(9, 9, 14, 14);
        C.Line(5, 6, 8, 6);
        C.Line(6, 5, 6, 8);
      end;
    bikZoomOut:
      begin
        C.Pen.Width := 2;
        C.Ellipse(2, 2, 11, 11);
        C.Line(9, 9, 14, 14);
        C.Line(5, 6, 8, 6);
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
    bikSwap:
      begin
        C.Line(3, 5, 11, 5);
        C.Line(9, 3, 11, 5);
        C.Line(9, 7, 11, 5);
        C.Line(13, 11, 5, 11);
        C.Line(7, 9, 5, 11);
        C.Line(7, 13, 5, 11);
      end;
    bikMono:
      begin
        C.Ellipse(3, 3, 13, 13);
        C.Line(8, 3, 8, 13);
        C.Brush.Style := bsSolid;
        C.Brush.Color := IconForegroundColor;
        C.Pie(3, 3, 13, 13, 8, 3, 8, 13);
        C.Brush.Style := bsClear;
      end;
    bikTools:
      begin
        C.Pen.Width := 2;
        C.Line(11, 3, 13, 5);
        C.Line(9, 5, 11, 3);
        C.Line(9, 5, 11, 7);
        C.Line(8, 6, 4, 10);
        C.Line(4, 10, 6, 12);
        C.Line(3, 11, 5, 13);
      end;
    bikHistory:
      begin
        C.Pen.Width := 2;
        C.Arc(2, 2, 14, 14, 4, 4, 3, 9);
        C.Line(3, 9, 5, 7);
        C.Line(3, 9, 5, 11);
        C.Line(8, 5, 8, 8);
        C.Line(8, 8, 10, 10);
      end;
    bikLayers:
      begin
        C.Pen.Width := 2;
        C.Polygon([Point(8, 2), Point(13, 5), Point(8, 8), Point(3, 5)]);
        C.Polygon([Point(8, 6), Point(13, 9), Point(8, 12), Point(3, 9)]);
        C.Polygon([Point(8, 10), Point(13, 13), Point(8, 15), Point(3, 13)]);
      end;
    bikColors:
      begin
        C.Pen.Width := 2;
        C.Ellipse(2, 3, 13, 13);
        C.Ellipse(8, 8, 11, 11);
        C.Ellipse(5, 5, 7, 7);
        C.Ellipse(8, 4, 10, 6);
        C.Ellipse(10, 7, 12, 9);
      end;
    bikHelp:
      DrawCenteredText(C, '?');
    bikSelectRect:
      begin
        C.Pen.Width := 2;
        C.Rectangle(5, 4, 13, 12);
        C.Line(2, 2, 6, 9);
        C.Line(2, 2, 5, 3);
        C.Line(2, 2, 3, 5);
      end;
    bikSelectEllipse:
      begin
        C.Pen.Width := 2;
        C.Ellipse(3, 3, 13, 12);
      end;
    bikSelectLasso:
      begin
        C.Pen.Width := 2;
        C.Polyline([Point(3, 10), Point(5, 4), Point(9, 3), Point(12, 6), Point(10, 11), Point(6, 12), Point(3, 10)]);
      end;
    bikMagicWand:
      begin
        C.Pen.Width := 2;
        C.Line(4, 12, 10, 6);
        C.Line(9, 2, 9, 4);
        C.Line(9, 8, 9, 10);
        C.Line(7, 6, 5, 6);
        C.Line(11, 6, 13, 6);
        C.Line(11, 3, 12, 4);
        C.Line(11, 9, 12, 8);
      end;
    bikMoveSelection:
      begin
        C.Pen.Width := 2;
        C.Rectangle(5, 5, 11, 11);
        C.Line(8, 2, 8, 14);
        C.Line(2, 8, 14, 8);
        C.Line(8, 2, 6, 4);
        C.Line(8, 2, 10, 4);
        C.Line(8, 14, 6, 12);
        C.Line(8, 14, 10, 12);
        C.Line(2, 8, 4, 6);
        C.Line(2, 8, 4, 10);
        C.Line(14, 8, 12, 6);
        C.Line(14, 8, 12, 10);
      end;
    bikMovePixels:
      begin
        C.Pen.Width := 2;
        C.Line(8, 2, 8, 14);
        C.Line(2, 8, 14, 8);
        C.Line(8, 2, 6, 4);
        C.Line(8, 2, 10, 4);
        C.Line(8, 14, 6, 12);
        C.Line(8, 14, 10, 12);
        C.Line(2, 8, 4, 6);
        C.Line(2, 8, 4, 10);
        C.Line(14, 8, 12, 6);
        C.Line(14, 8, 12, 10);
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
        C.Pen.Width := 2;
        C.Polyline([Point(3, 5), Point(8, 2), Point(12, 6), Point(7, 9), Point(3, 5)]);
        C.Line(8, 9, 12, 9);
        C.Ellipse(10, 10, 13, 13);
      end;
    bikGradient:
      begin
        C.Pen.Width := 2;
        C.Rectangle(2, 4, 13, 11);
        C.Line(4, 10, 11, 5);
      end;
    bikPencil:
      begin
        C.Pen.Width := 2;
        C.Line(3, 12, 11, 4);
        C.Line(10, 3, 12, 5);
        C.Line(3, 12, 5, 12);
      end;
    bikBrush:
      begin
        C.Pen.Width := 2;
        C.Line(5, 12, 8, 9);
        C.Line(8, 9, 11, 5);
        C.Line(10, 4, 12, 6);
        C.Line(6, 11, 8, 13);
        C.Line(4, 13, 7, 15);
      end;
    bikEraser:
      begin
        C.Pen.Width := 2;
        C.Polygon([Point(4, 11), Point(8, 5), Point(12, 9), Point(8, 13)]);
      end;
    bikPicker:
      begin
        C.Pen.Width := 2;
        C.Ellipse(7, 2, 11, 6);
        C.Line(10, 5, 5, 10);
        C.Line(5, 10, 3, 12);
        C.Line(4, 13, 6, 11);
      end;
    bikClone:
      begin
        C.Pen.Width := 2;
        C.Rectangle(3, 5, 8, 10);
        C.Rectangle(7, 3, 12, 8);
        C.Line(9, 9, 13, 13);
      end;
    bikRecolor:
      begin
        C.Pen.Width := 2;
        C.Ellipse(3, 3, 12, 12);
        C.Line(7, 3, 7, 12);
        C.Line(7, 8, 12, 8);
      end;
    bikLine:
      begin
        C.Pen.Width := 2;
        C.Line(3, 12, 13, 4);
        C.Ellipse(2, 11, 5, 14);
        C.Ellipse(11, 2, 14, 5);
      end;
    bikRectangle:
      C.Rectangle(3, 4, 13, 12);
    bikRoundedRect:
      begin
        C.RoundRect(3, 4, 13, 12, 4, 4);
      end;
    bikEllipse:
      C.Ellipse(3, 4, 13, 12);
    bikFreeform:
      begin
        C.Pen.Width := 2;
        C.Polyline([Point(2, 10), Point(4, 5), Point(7, 7), Point(10, 3), Point(13, 8)]);
      end;
    bikCrop:
      begin
        C.Pen.Width := 2;
        C.Line(4, 2, 4, 10);
        C.Line(4, 10, 12, 10);
        C.Line(8, 4, 8, 12);
        C.Line(8, 4, 14, 4);
      end;
    bikText:
      begin
        DrawCenteredText(C, 'T', -1);
        C.Pen.Width := 2;
        C.Line(4, 13, 12, 13);
      end;
  end;
end;

function ButtonIconSupported(const ACaption: string; AContext: TButtonIconContext): Boolean;
begin
  Result := ResolveButtonIconKind(ACaption, AContext) <> bikNone;
end;

function ButtonIconCanLoadRenderedAsset(const ACaption: string; AContext: TButtonIconContext): Boolean;
var
  IconKind: TButtonIconKind;
  AssetName: string;
  AssetPath: string;
  RenderedIcon: TPortableNetworkGraphic;
begin
  Result := False;
  IconKind := ResolveButtonIconKind(ACaption, AContext);
  if IconKind = bikNone then
    Exit;

  AssetName := RenderedIconAssetName(IconKind);
  if AssetName = '' then
    Exit;

  AssetPath := ResolveRenderedIconDir;
  if AssetPath = '' then
    Exit;

  AssetPath := IncludeTrailingPathDelimiter(AssetPath) + AssetName;
  if not FileExists(AssetPath) then
    Exit;

  RenderedIcon := TPortableNetworkGraphic.Create;
  try
    try
      RenderedIcon.LoadFromFile(AssetPath);
      Result := (RenderedIcon.Width > 0) and (RenderedIcon.Height > 0);
    except
      Result := False;
    end;
  finally
    RenderedIcon.Free;
  end;
end;

function TryLoadButtonIconPicture(
  const ACaption: string;
  AContext: TButtonIconContext;
  APicture: TPicture
): Boolean;
var
  IconKind: TButtonIconKind;
  AssetName: string;
  AssetPath: string;
  RenderedIcon: TPortableNetworkGraphic;
begin
  Result := False;
  if APicture = nil then
    Exit;

  IconKind := ResolveButtonIconKind(ACaption, AContext);
  if IconKind = bikNone then
    Exit;

  AssetName := RenderedIconAssetName(IconKind);
  if AssetName = '' then
    Exit;

  AssetPath := ResolveRenderedIconDir;
  if AssetPath = '' then
    Exit;

  AssetPath := IncludeTrailingPathDelimiter(AssetPath) + AssetName;
  if not FileExists(AssetPath) then
    Exit;

  RenderedIcon := TPortableNetworkGraphic.Create;
  try
    try
      RenderedIcon.LoadFromFile(AssetPath);
      APicture.Assign(RenderedIcon);
      Result := True;
    except
      Result := False;
    end;
  finally
    RenderedIcon.Free;
  end;
end;

function TryBuildButtonGlyph(
  const ACaption: string;
  AContext: TButtonIconContext;
  AGlyph: TBitmap;
  ABackgroundColor: TColor
): Boolean;
var
  IconKind: TButtonIconKind;
begin
  if AGlyph = nil then
    Exit(False);
  IconKind := ResolveButtonIconKind(ACaption, AContext);
  Result := IconKind <> bikNone;
  if not Result then
    Exit;
  { Prefer the pre-rendered asset-backed icon set generated from the canonical
    local Lucide stroke SVGs. If an asset is missing, fall back to the built-in
    line glyph so the UI remains usable. }
  if TryLoadRenderedIcon(IconKind, AGlyph) then
    Exit(True);
  PrepareGlyphBitmap(AGlyph, ABackgroundColor);
  DrawIcon(IconKind, AGlyph);
end;

function TryBuildLineButtonGlyph(
  const ACaption: string;
  AContext: TButtonIconContext;
  AGlyph: TBitmap;
  ABackgroundColor: TColor
): Boolean;
var
  IconKind: TButtonIconKind;
begin
  if AGlyph = nil then
    Exit(False);
  IconKind := ResolveButtonIconKind(ACaption, AContext);
  Result := IconKind <> bikNone;
  if not Result then
    Exit;
  PrepareGlyphBitmap(AGlyph, ABackgroundColor);
  DrawIcon(IconKind, AGlyph);
end;

end.
