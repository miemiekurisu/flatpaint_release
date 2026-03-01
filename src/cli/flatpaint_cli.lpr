program FlatPaintCLI;

{$mode objfpc}{$H+}

uses
  SysUtils, Types, FPColor, FPSurface, FPDocument, FPIO, FPNativeIO;

type
  TPointArray = array of TPoint;

procedure PrintUsage;
begin
  WriteLn('FlatPaintCLI');
  WriteLn('Usage:');
  WriteLn('  flatpaint_cli new <width> <height> <output>');
  WriteLn('  flatpaint_cli brush <input> <output> <x> <y> <radius> <r> <g> <b>');
  WriteLn('  flatpaint_cli erase <input> <output> <x> <y> <radius>');
  WriteLn('  flatpaint_cli fill <input> <output> <x> <y> <r> <g> <b>');
  WriteLn('  flatpaint_cli gradient <input> <output> <x1> <y1> <x2> <y2> <r1> <g1> <b1> <r2> <g2> <b2>');
  WriteLn('  flatpaint_cli line <input> <output> <x1> <y1> <x2> <y2> <size> <r> <g> <b>');
  WriteLn('  flatpaint_cli rect <input> <output> <x1> <y1> <x2> <y2> <size> <r> <g> <b>');
  WriteLn('  flatpaint_cli ellipse <input> <output> <x1> <y1> <x2> <y2> <size> <r> <g> <b>');
  WriteLn('  flatpaint_cli fillrect <input> <output> <x1> <y1> <x2> <y2> <r> <g> <b>');
  WriteLn('  flatpaint_cli fillellipse <input> <output> <x1> <y1> <x2> <y2> <r> <g> <b>');
  WriteLn('  flatpaint_cli eraserect <input> <output> <x1> <y1> <x2> <y2>');
  WriteLn('  flatpaint_cli movepixelsrect <input> <output> <x1> <y1> <x2> <y2> <dx> <dy>');
  WriteLn('  flatpaint_cli croprect <input> <output> <x1> <y1> <x2> <y2>');
  WriteLn('  flatpaint_cli filllasso <input> <output> <r> <g> <b> <x1> <y1> [<x2> <y2> ...]');
  WriteLn('  flatpaint_cli eraselasso <input> <output> <x1> <y1> [<x2> <y2> ...]');
  WriteLn('  flatpaint_cli movepixelslasso <input> <output> <dx> <dy> <x1> <y1> [<x2> <y2> ...]');
  WriteLn('  flatpaint_cli croplasso <input> <output> <x1> <y1> [<x2> <y2> ...]');
  WriteLn('  flatpaint_cli extractrect <input> <output> <x1> <y1> <x2> <y2>');
  WriteLn('  flatpaint_cli extractlasso <input> <output> <x1> <y1> [<x2> <y2> ...]');
  WriteLn('  flatpaint_cli fillwand <input> <output> <x> <y> <tolerance> <r> <g> <b>');
  WriteLn('  flatpaint_cli erasewand <input> <output> <x> <y> <tolerance>');
  WriteLn('  flatpaint_cli movepixelswand <input> <output> <x> <y> <tolerance> <dx> <dy>');
  WriteLn('  flatpaint_cli cropwand <input> <output> <x> <y> <tolerance>');
  WriteLn('  flatpaint_cli extractwand <input> <output> <x> <y> <tolerance>');
  WriteLn('  flatpaint_cli crop <input> <output> <x> <y> <width> <height>');
  WriteLn('  flatpaint_cli resize <input> <output> <width> <height>');
  WriteLn('  flatpaint_cli fliph <input> <output>');
  WriteLn('  flatpaint_cli flipv <input> <output>');
  WriteLn('  flatpaint_cli rot180 <input> <output>');
  WriteLn('  flatpaint_cli rotcw <input> <output>');
  WriteLn('  flatpaint_cli rotccw <input> <output>');
  WriteLn('  flatpaint_cli autolevel <input> <output>');
  WriteLn('  flatpaint_cli invert <input> <output>');
  WriteLn('  flatpaint_cli grayscale <input> <output>');
  WriteLn('  flatpaint_cli brightness <input> <output> <delta>');
  WriteLn('  flatpaint_cli contrast <input> <output> <amount>');
  WriteLn('  flatpaint_cli sepia <input> <output>');
  WriteLn('  flatpaint_cli blackwhite <input> <output> <threshold>');
  WriteLn('  flatpaint_cli posterize <input> <output> <levels>');
  WriteLn('  flatpaint_cli blur <input> <output> <radius>');
  WriteLn('  flatpaint_cli sharpen <input> <output>');
  WriteLn('  flatpaint_cli noise <input> <output> <amount>');
  WriteLn('  flatpaint_cli outline <input> <output>');
  WriteLn('  flatpaint_cli wrapdoc <input-image> <output-fpd>');
  WriteLn('  flatpaint_cli exportdoc <input-fpd> <output-image>');
  WriteLn('  flatpaint_cli exportlayerdoc <input-fpd> <layer-index> <output-image>');
  WriteLn('  flatpaint_cli addlayerdoc <input-fpd> <layer-image> <output-fpd>');
  WriteLn('  flatpaint_cli pastedoc <input-fpd> <image> <x> <y> <output-fpd>');
  WriteLn('  flatpaint_cli autoleveldoc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli invertdoc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli grayscaledoc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli brightnessdoc <input-fpd> <delta> <output-fpd>');
  WriteLn('  flatpaint_cli contrastdoc <input-fpd> <amount> <output-fpd>');
  WriteLn('  flatpaint_cli sepiadoc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli blackwhitedoc <input-fpd> <threshold> <output-fpd>');
  WriteLn('  flatpaint_cli posterizedoc <input-fpd> <levels> <output-fpd>');
  WriteLn('  flatpaint_cli blurdoc <input-fpd> <radius> <output-fpd>');
  WriteLn('  flatpaint_cli sharpendoc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli noisedoc <input-fpd> <amount> <output-fpd>');
  WriteLn('  flatpaint_cli outlinedoc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli setactivedoc <input-fpd> <layer-index> <output-fpd>');
  WriteLn('  flatpaint_cli duplayerdoc <input-fpd> <layer-index> <output-fpd>');
  WriteLn('  flatpaint_cli deletelayerdoc <input-fpd> <layer-index> <output-fpd>');
  WriteLn('  flatpaint_cli movelayerdoc <input-fpd> <from-index> <to-index> <output-fpd>');
  WriteLn('  flatpaint_cli renamelayerdoc <input-fpd> <layer-index> <new-name> <output-fpd>');
  WriteLn('  flatpaint_cli setvisibledoc <input-fpd> <layer-index> <0|1> <output-fpd>');
  WriteLn('  flatpaint_cli setopacitydoc <input-fpd> <layer-index> <opacity> <output-fpd>');
  WriteLn('  flatpaint_cli rot180doc <input-fpd> <output-fpd>');
  WriteLn('  flatpaint_cli mergedowndoc <input-fpd> <layer-index> <output-fpd>');
  WriteLn('  flatpaint_cli flattendoc <input-fpd> <output-fpd>');
end;

function ArgInt(AIndex: Integer): Integer;
begin
  Result := StrToInt(ParamStr(AIndex));
end;

function ArgByte(AIndex: Integer): Byte;
var
  Value: Integer;
begin
  Value := ArgInt(AIndex);
  if (Value < 0) or (Value > 255) then
    raise Exception.CreateFmt('Argument %d must be between 0 and 255', [AIndex]);
  Result := Value;
end;

function LoadSurface(const AFileName: string): TRasterSurface;
begin
  Result := LoadSurfaceFromFile(AFileName);
end;

function LoadSingleLayerDocument(const AFileName: string): TImageDocument;
var
  Surface: TRasterSurface;
begin
  Surface := LoadSurface(AFileName);
  try
    Result := TImageDocument.Create(Surface.Width, Surface.Height);
    Result.ReplaceWithSingleLayer(Surface, 'Layer 1');
  finally
    Surface.Free;
  end;
end;

function ParsePolygonPoints(AStartIndex: Integer): TPointArray;
var
  CoordinateCount: Integer;
  PointCount: Integer;
  PointIndex: Integer;
  ArgIndex: Integer;
begin
  Result := nil;
  CoordinateCount := ParamCount - AStartIndex + 1;
  if (CoordinateCount < 6) or ((CoordinateCount mod 2) <> 0) then
    raise Exception.Create('Polygon commands require at least 3 coordinate pairs');

  PointCount := CoordinateCount div 2;
  SetLength(Result, PointCount);
  ArgIndex := AStartIndex;
  for PointIndex := 0 to PointCount - 1 do
  begin
    Result[PointIndex].X := ArgInt(ArgIndex);
    Result[PointIndex].Y := ArgInt(ArgIndex + 1);
    Inc(ArgIndex, 2);
  end;
end;

procedure SaveSurface(ASurface: TRasterSurface; const AFileName: string);
begin
  SaveSurfaceToFile(AFileName, ASurface);
end;

procedure SaveDocumentComposite(ADocument: TImageDocument; const AFileName: string);
var
  Surface: TRasterSurface;
begin
  Surface := ADocument.Composite;
  try
    SaveSurface(Surface, AFileName);
  finally
    Surface.Free;
  end;
end;

procedure RequireLayerIndex(ADocument: TImageDocument; AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= ADocument.LayerCount) then
    raise Exception.CreateFmt('Layer index %d is out of range', [AIndex]);
end;

procedure RunNew;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for new');
  Surface := TRasterSurface.Create(ArgInt(2), ArgInt(3));
  try
    Surface.Clear(TransparentColor);
    SaveSurface(Surface, ParamStr(4));
  finally
    Surface.Free;
  end;
end;

procedure RunBrush;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 9 then
    raise Exception.Create('Invalid parameter count for brush');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.DrawBrush(
      ArgInt(4),
      ArgInt(5),
      ArgInt(6),
      RGBA(ArgInt(7), ArgInt(8), ArgInt(9), 255)
    );
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunErase;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 6 then
    raise Exception.Create('Invalid parameter count for erase');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.DrawBrush(ArgInt(4), ArgInt(5), ArgInt(6), TransparentColor);
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunFill;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 8 then
    raise Exception.Create('Invalid parameter count for fill');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.FloodFill(
      ArgInt(4),
      ArgInt(5),
      RGBA(ArgInt(6), ArgInt(7), ArgInt(8), 255),
      8
    );
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunGradient;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 13 then
    raise Exception.Create('Invalid parameter count for gradient');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.FillGradient(
      ArgInt(4),
      ArgInt(5),
      ArgInt(6),
      ArgInt(7),
      RGBA(ArgInt(8), ArgInt(9), ArgInt(10), 255),
      RGBA(ArgInt(11), ArgInt(12), ArgInt(13), 255)
    );
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunLine;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 11 then
    raise Exception.Create('Invalid parameter count for line');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.DrawLine(
      ArgInt(4),
      ArgInt(5),
      ArgInt(6),
      ArgInt(7),
      ArgInt(8),
      RGBA(ArgInt(9), ArgInt(10), ArgInt(11), 255)
    );
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunRect;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 11 then
    raise Exception.Create('Invalid parameter count for rect');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.DrawRectangle(
      ArgInt(4),
      ArgInt(5),
      ArgInt(6),
      ArgInt(7),
      ArgInt(8),
      RGBA(ArgInt(9), ArgInt(10), ArgInt(11), 255),
      False
    );
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunEllipse;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 11 then
    raise Exception.Create('Invalid parameter count for ellipse');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.DrawEllipse(
      ArgInt(4),
      ArgInt(5),
      ArgInt(6),
      ArgInt(7),
      ArgInt(8),
      RGBA(ArgInt(9), ArgInt(10), ArgInt(11), 255),
      False
    );
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunFillRectSelection;
var
  Surface: TRasterSurface;
  Document: TImageDocument;
begin
  if ParamCount <> 10 then
    raise Exception.Create('Invalid parameter count for fillrect');
  Surface := LoadSurface(ParamStr(2));
  try
    Document := TImageDocument.Create(Surface.Width, Surface.Height);
    try
      Document.ReplaceWithSingleLayer(Surface, 'Layer 1');
      Document.SelectRectangle(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
      Document.FillSelection(RGBA(ArgInt(8), ArgInt(9), ArgInt(10), 255));
      SaveDocumentComposite(Document, ParamStr(3));
    finally
      Document.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunFillEllipseSelection;
var
  Surface: TRasterSurface;
  Document: TImageDocument;
begin
  if ParamCount <> 10 then
    raise Exception.Create('Invalid parameter count for fillellipse');
  Surface := LoadSurface(ParamStr(2));
  try
    Document := TImageDocument.Create(Surface.Width, Surface.Height);
    try
      Document.ReplaceWithSingleLayer(Surface, 'Layer 1');
      Document.SelectEllipse(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
      Document.FillSelection(RGBA(ArgInt(8), ArgInt(9), ArgInt(10), 255));
      SaveDocumentComposite(Document, ParamStr(3));
    finally
      Document.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunEraseRectSelection;
var
  Surface: TRasterSurface;
  Document: TImageDocument;
begin
  if ParamCount <> 7 then
    raise Exception.Create('Invalid parameter count for eraserect');
  Surface := LoadSurface(ParamStr(2));
  try
    Document := TImageDocument.Create(Surface.Width, Surface.Height);
    try
      Document.ReplaceWithSingleLayer(Surface, 'Layer 1');
      Document.SelectRectangle(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
      Document.EraseSelection;
      SaveDocumentComposite(Document, ParamStr(3));
    finally
      Document.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunMovePixelsRect;
var
  Surface: TRasterSurface;
  Document: TImageDocument;
begin
  if ParamCount <> 9 then
    raise Exception.Create('Invalid parameter count for movepixelsrect');
  Surface := LoadSurface(ParamStr(2));
  try
    Document := TImageDocument.Create(Surface.Width, Surface.Height);
    try
      Document.ReplaceWithSingleLayer(Surface, 'Layer 1');
      Document.SelectRectangle(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
      Document.MoveSelectedPixelsBy(ArgInt(8), ArgInt(9));
      SaveDocumentComposite(Document, ParamStr(3));
    finally
      Document.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunCropRect;
var
  Surface: TRasterSurface;
  Document: TImageDocument;
begin
  if ParamCount <> 7 then
    raise Exception.Create('Invalid parameter count for croprect');
  Surface := LoadSurface(ParamStr(2));
  try
    Document := TImageDocument.Create(Surface.Width, Surface.Height);
    try
      Document.ReplaceWithSingleLayer(Surface, 'Layer 1');
      Document.SelectRectangle(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
      Document.CropToSelection;
      SaveDocumentComposite(Document, ParamStr(3));
    finally
      Document.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunFillLassoSelection;
var
  Document: TImageDocument;
  Points: TPointArray;
begin
  if ParamCount < 12 then
    raise Exception.Create('Invalid parameter count for filllasso');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Points := ParsePolygonPoints(7);
    Document.SelectLasso(Points);
    Document.FillSelection(RGBA(ArgInt(4), ArgInt(5), ArgInt(6), 255));
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunEraseLassoSelection;
var
  Document: TImageDocument;
  Points: TPointArray;
begin
  if ParamCount < 9 then
    raise Exception.Create('Invalid parameter count for eraselasso');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Points := ParsePolygonPoints(4);
    Document.SelectLasso(Points);
    Document.EraseSelection;
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunMovePixelsLasso;
var
  Document: TImageDocument;
  Points: TPointArray;
begin
  if ParamCount < 11 then
    raise Exception.Create('Invalid parameter count for movepixelslasso');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Points := ParsePolygonPoints(6);
    Document.SelectLasso(Points);
    Document.MoveSelectedPixelsBy(ArgInt(4), ArgInt(5));
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunCropLasso;
var
  Document: TImageDocument;
  Points: TPointArray;
begin
  if ParamCount < 9 then
    raise Exception.Create('Invalid parameter count for croplasso');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Points := ParsePolygonPoints(4);
    Document.SelectLasso(Points);
    Document.CropToSelection;
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunExtractRectSelection;
var
  Document: TImageDocument;
  Surface: TRasterSurface;
begin
  if ParamCount <> 7 then
    raise Exception.Create('Invalid parameter count for extractrect');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Document.SelectRectangle(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
    Surface := Document.CopySelectionToSurface(True);
    try
      SaveSurface(Surface, ParamStr(3));
    finally
      Surface.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure RunExtractLassoSelection;
var
  Document: TImageDocument;
  Points: TPointArray;
  Surface: TRasterSurface;
begin
  if ParamCount < 9 then
    raise Exception.Create('Invalid parameter count for extractlasso');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Points := ParsePolygonPoints(4);
    Document.SelectLasso(Points);
    Surface := Document.CopySelectionToSurface(True);
    try
      SaveSurface(Surface, ParamStr(3));
    finally
      Surface.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure RunFillWandSelection;
var
  Document: TImageDocument;
begin
  if ParamCount <> 9 then
    raise Exception.Create('Invalid parameter count for fillwand');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Document.SelectMagicWand(ArgInt(4), ArgInt(5), ArgByte(6));
    Document.FillSelection(RGBA(ArgInt(7), ArgInt(8), ArgInt(9), 255));
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunEraseWandSelection;
var
  Document: TImageDocument;
begin
  if ParamCount <> 6 then
    raise Exception.Create('Invalid parameter count for erasewand');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Document.SelectMagicWand(ArgInt(4), ArgInt(5), ArgByte(6));
    Document.EraseSelection;
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunMovePixelsWand;
var
  Document: TImageDocument;
begin
  if ParamCount <> 8 then
    raise Exception.Create('Invalid parameter count for movepixelswand');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Document.SelectMagicWand(ArgInt(4), ArgInt(5), ArgByte(6));
    Document.MoveSelectedPixelsBy(ArgInt(7), ArgInt(8));
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunCropWand;
var
  Document: TImageDocument;
begin
  if ParamCount <> 6 then
    raise Exception.Create('Invalid parameter count for cropwand');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Document.SelectMagicWand(ArgInt(4), ArgInt(5), ArgByte(6));
    Document.CropToSelection;
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunExtractWandSelection;
var
  Document: TImageDocument;
  Surface: TRasterSurface;
begin
  if ParamCount <> 6 then
    raise Exception.Create('Invalid parameter count for extractwand');
  Document := LoadSingleLayerDocument(ParamStr(2));
  try
    Document.SelectMagicWand(ArgInt(4), ArgInt(5), ArgByte(6));
    Surface := Document.CopySelectionToSurface(True);
    try
      SaveSurface(Surface, ParamStr(3));
    finally
      Surface.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure RunCrop;
var
  Surface: TRasterSurface;
  Cropped: TRasterSurface;
begin
  if ParamCount <> 7 then
    raise Exception.Create('Invalid parameter count for crop');
  Surface := LoadSurface(ParamStr(2));
  try
    Cropped := Surface.Crop(ArgInt(4), ArgInt(5), ArgInt(6), ArgInt(7));
    try
      SaveSurface(Cropped, ParamStr(3));
    finally
      Cropped.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunResize;
var
  Surface: TRasterSurface;
  Resized: TRasterSurface;
begin
  if ParamCount <> 5 then
    raise Exception.Create('Invalid parameter count for resize');
  Surface := LoadSurface(ParamStr(2));
  try
    Resized := Surface.ResizeNearest(ArgInt(4), ArgInt(5));
    try
      SaveSurface(Resized, ParamStr(3));
    finally
      Resized.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunFlipHorizontal;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for fliph');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.FlipHorizontal;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunFlipVertical;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for flipv');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.FlipVertical;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunRotate180;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for rot180');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Rotate180;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunRotateClockwise;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for rotcw');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Rotate90Clockwise;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunRotateCounterClockwise;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for rotccw');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Rotate90CounterClockwise;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunAutoLevel;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for autolevel');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.AutoLevel;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunInvert;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for invert');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.InvertColors;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunGrayscale;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for grayscale');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Grayscale;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunBrightness;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for brightness');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.AdjustBrightness(ArgInt(4));
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunContrast;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for contrast');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.AdjustContrast(ArgInt(4));
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunSepia;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for sepia');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Sepia;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunBlackAndWhite;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for blackwhite');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.BlackAndWhite(ArgByte(4));
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunPosterize;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for posterize');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Posterize(ArgByte(4));
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunBlur;
var
  Surface: TRasterSurface;
  Radius: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for blur');
  Radius := ArgInt(4);
  if Radius < 1 then
    Radius := 1;
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.BoxBlur(Radius);
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunSharpen;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for sharpen');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.Sharpen;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunNoise;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for noise');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.AddNoise(ArgByte(4));
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunOutline;
var
  Surface: TRasterSurface;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for outline');
  Surface := LoadSurface(ParamStr(2));
  try
    Surface.DetectEdges;
    SaveSurface(Surface, ParamStr(3));
  finally
    Surface.Free;
  end;
end;

procedure RunWrapDoc;
var
  Surface: TRasterSurface;
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for wrapdoc');
  Surface := LoadSurface(ParamStr(2));
  try
    Document := TImageDocument.Create(Surface.Width, Surface.Height);
    try
      Document.ReplaceWithSingleLayer(Surface, ExtractFileName(ParamStr(2)));
      SaveNativeDocumentToFile(ParamStr(3), Document);
    finally
      Document.Free;
    end;
  finally
    Surface.Free;
  end;
end;

procedure RunExportDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for exportdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    SaveDocumentComposite(Document, ParamStr(3));
  finally
    Document.Free;
  end;
end;

procedure RunExportLayerDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for exportlayerdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    RequireLayerIndex(Document, LayerIndex);
    SaveSurface(Document.Layers[LayerIndex].Surface, ParamStr(4));
  finally
    Document.Free;
  end;
end;

procedure RunAddLayerDoc;
var
  Document: TImageDocument;
  Surface: TRasterSurface;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for addlayerdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Surface := LoadSurface(ParamStr(3));
    try
      Document.PasteAsNewLayer(Surface, 0, 0, ExtractFileName(ParamStr(3)));
      SaveNativeDocumentToFile(ParamStr(4), Document);
    finally
      Surface.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure RunPasteDoc;
var
  Document: TImageDocument;
  Surface: TRasterSurface;
begin
  if ParamCount <> 6 then
    raise Exception.Create('Invalid parameter count for pastedoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Surface := LoadSurface(ParamStr(3));
    try
      Document.PasteAsNewLayer(Surface, ArgInt(4), ArgInt(5), ExtractFileName(ParamStr(3)));
      SaveNativeDocumentToFile(ParamStr(6), Document);
    finally
      Surface.Free;
    end;
  finally
    Document.Free;
  end;
end;

procedure RunAutoLevelDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for autoleveldoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.AutoLevel;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunInvertDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for invertdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.InvertColors;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunGrayscaleDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for grayscaledoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.Grayscale;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunBrightnessDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for brightnessdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.AdjustBrightness(ArgInt(3));
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunContrastDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for contrastdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.AdjustContrast(ArgInt(3));
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunSepiaDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for sepiadoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.Sepia;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunBlackAndWhiteDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for blackwhitedoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.BlackAndWhite(ArgByte(3));
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunPosterizeDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for posterizedoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.Posterize(ArgByte(3));
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunBlurDoc;
var
  Document: TImageDocument;
  Radius: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for blurdoc');
  Radius := ArgInt(3);
  if Radius < 1 then
    Radius := 1;
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.BoxBlur(Radius);
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunSharpenDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for sharpendoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.Sharpen;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunNoiseDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for noisedoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.AddNoise(ArgByte(3));
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunOutlineDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for outlinedoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.DetectEdges;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunSetActiveDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for setactivedoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    RequireLayerIndex(Document, LayerIndex);
    Document.ActiveLayerIndex := LayerIndex;
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunDuplicateLayerDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for duplayerdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    RequireLayerIndex(Document, LayerIndex);
    Document.ActiveLayerIndex := LayerIndex;
    Document.DuplicateActiveLayer;
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunDeleteLayerDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for deletelayerdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    RequireLayerIndex(Document, LayerIndex);
    Document.ActiveLayerIndex := LayerIndex;
    Document.DeleteActiveLayer;
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunMoveLayerDoc;
var
  Document: TImageDocument;
  FromIndex: Integer;
  ToIndex: Integer;
begin
  if ParamCount <> 5 then
    raise Exception.Create('Invalid parameter count for movelayerdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    FromIndex := ArgInt(3);
    ToIndex := ArgInt(4);
    RequireLayerIndex(Document, FromIndex);
    RequireLayerIndex(Document, ToIndex);
    Document.MoveLayer(FromIndex, ToIndex);
    SaveNativeDocumentToFile(ParamStr(5), Document);
  finally
    Document.Free;
  end;
end;

procedure RunRenameLayerDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
  LayerName: string;
begin
  if ParamCount <> 5 then
    raise Exception.Create('Invalid parameter count for renamelayerdoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    LayerName := ParamStr(4);
    RequireLayerIndex(Document, LayerIndex);
    if Trim(LayerName) = '' then
      raise Exception.Create('Layer name cannot be blank');
    Document.RenameLayer(LayerIndex, LayerName);
    SaveNativeDocumentToFile(ParamStr(5), Document);
  finally
    Document.Free;
  end;
end;

procedure RunSetVisibleDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
  VisibleValue: Integer;
begin
  if ParamCount <> 5 then
    raise Exception.Create('Invalid parameter count for setvisibledoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    VisibleValue := ArgInt(4);
    RequireLayerIndex(Document, LayerIndex);
    if (VisibleValue <> 0) and (VisibleValue <> 1) then
      raise Exception.Create('Visibility must be 0 or 1');
    Document.SetLayerVisibility(LayerIndex, VisibleValue <> 0);
    SaveNativeDocumentToFile(ParamStr(5), Document);
  finally
    Document.Free;
  end;
end;

procedure RunSetOpacityDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
begin
  if ParamCount <> 5 then
    raise Exception.Create('Invalid parameter count for setopacitydoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    RequireLayerIndex(Document, LayerIndex);
    Document.SetLayerOpacity(LayerIndex, ArgByte(4));
    SaveNativeDocumentToFile(ParamStr(5), Document);
  finally
    Document.Free;
  end;
end;

procedure RunRotate180Doc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for rot180doc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.Rotate180;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

procedure RunMergeDownDoc;
var
  Document: TImageDocument;
  LayerIndex: Integer;
begin
  if ParamCount <> 4 then
    raise Exception.Create('Invalid parameter count for mergedowndoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    LayerIndex := ArgInt(3);
    RequireLayerIndex(Document, LayerIndex);
    if LayerIndex = 0 then
      raise Exception.Create('Cannot merge the bottom layer down');
    Document.ActiveLayerIndex := LayerIndex;
    Document.MergeDown;
    SaveNativeDocumentToFile(ParamStr(4), Document);
  finally
    Document.Free;
  end;
end;

procedure RunFlattenDoc;
var
  Document: TImageDocument;
begin
  if ParamCount <> 3 then
    raise Exception.Create('Invalid parameter count for flattendoc');
  Document := LoadNativeDocumentFromFile(ParamStr(2));
  try
    Document.Flatten;
    SaveNativeDocumentToFile(ParamStr(3), Document);
  finally
    Document.Free;
  end;
end;

var
  CommandName: string;
begin
  if ParamCount = 0 then
  begin
    PrintUsage;
    Halt(1);
  end;

  CommandName := LowerCase(ParamStr(1));
  try
    if CommandName = 'new' then
      RunNew
    else if CommandName = 'brush' then
      RunBrush
    else if CommandName = 'erase' then
      RunErase
    else if CommandName = 'fill' then
      RunFill
    else if CommandName = 'gradient' then
      RunGradient
    else if CommandName = 'line' then
      RunLine
    else if CommandName = 'rect' then
      RunRect
    else if CommandName = 'ellipse' then
      RunEllipse
    else if CommandName = 'fillrect' then
      RunFillRectSelection
    else if CommandName = 'fillellipse' then
      RunFillEllipseSelection
    else if CommandName = 'eraserect' then
      RunEraseRectSelection
    else if CommandName = 'movepixelsrect' then
      RunMovePixelsRect
    else if CommandName = 'croprect' then
      RunCropRect
    else if CommandName = 'filllasso' then
      RunFillLassoSelection
    else if CommandName = 'eraselasso' then
      RunEraseLassoSelection
    else if CommandName = 'movepixelslasso' then
      RunMovePixelsLasso
    else if CommandName = 'croplasso' then
      RunCropLasso
    else if CommandName = 'extractrect' then
      RunExtractRectSelection
    else if CommandName = 'extractlasso' then
      RunExtractLassoSelection
    else if CommandName = 'fillwand' then
      RunFillWandSelection
    else if CommandName = 'erasewand' then
      RunEraseWandSelection
    else if CommandName = 'movepixelswand' then
      RunMovePixelsWand
    else if CommandName = 'cropwand' then
      RunCropWand
    else if CommandName = 'extractwand' then
      RunExtractWandSelection
    else if CommandName = 'crop' then
      RunCrop
    else if CommandName = 'resize' then
      RunResize
    else if CommandName = 'fliph' then
      RunFlipHorizontal
    else if CommandName = 'flipv' then
      RunFlipVertical
    else if CommandName = 'rot180' then
      RunRotate180
    else if CommandName = 'rotcw' then
      RunRotateClockwise
    else if CommandName = 'rotccw' then
      RunRotateCounterClockwise
    else if CommandName = 'autolevel' then
      RunAutoLevel
    else if CommandName = 'invert' then
      RunInvert
    else if CommandName = 'grayscale' then
      RunGrayscale
    else if CommandName = 'brightness' then
      RunBrightness
    else if CommandName = 'contrast' then
      RunContrast
    else if CommandName = 'sepia' then
      RunSepia
    else if CommandName = 'blackwhite' then
      RunBlackAndWhite
    else if CommandName = 'posterize' then
      RunPosterize
    else if CommandName = 'blur' then
      RunBlur
    else if CommandName = 'sharpen' then
      RunSharpen
    else if CommandName = 'noise' then
      RunNoise
    else if CommandName = 'outline' then
      RunOutline
    else if CommandName = 'wrapdoc' then
      RunWrapDoc
    else if CommandName = 'exportdoc' then
      RunExportDoc
    else if CommandName = 'exportlayerdoc' then
      RunExportLayerDoc
    else if CommandName = 'addlayerdoc' then
      RunAddLayerDoc
    else if CommandName = 'pastedoc' then
      RunPasteDoc
    else if CommandName = 'autoleveldoc' then
      RunAutoLevelDoc
    else if CommandName = 'invertdoc' then
      RunInvertDoc
    else if CommandName = 'grayscaledoc' then
      RunGrayscaleDoc
    else if CommandName = 'brightnessdoc' then
      RunBrightnessDoc
    else if CommandName = 'contrastdoc' then
      RunContrastDoc
    else if CommandName = 'sepiadoc' then
      RunSepiaDoc
    else if CommandName = 'blackwhitedoc' then
      RunBlackAndWhiteDoc
    else if CommandName = 'posterizedoc' then
      RunPosterizeDoc
    else if CommandName = 'blurdoc' then
      RunBlurDoc
    else if CommandName = 'sharpendoc' then
      RunSharpenDoc
    else if CommandName = 'noisedoc' then
      RunNoiseDoc
    else if CommandName = 'outlinedoc' then
      RunOutlineDoc
    else if CommandName = 'setactivedoc' then
      RunSetActiveDoc
    else if CommandName = 'duplayerdoc' then
      RunDuplicateLayerDoc
    else if CommandName = 'deletelayerdoc' then
      RunDeleteLayerDoc
    else if CommandName = 'movelayerdoc' then
      RunMoveLayerDoc
    else if CommandName = 'renamelayerdoc' then
      RunRenameLayerDoc
    else if CommandName = 'setvisibledoc' then
      RunSetVisibleDoc
    else if CommandName = 'setopacitydoc' then
      RunSetOpacityDoc
    else if CommandName = 'rot180doc' then
      RunRotate180Doc
    else if CommandName = 'mergedowndoc' then
      RunMergeDownDoc
    else if CommandName = 'flattendoc' then
      RunFlattenDoc
    else
      raise Exception.Create('Unknown command: ' + CommandName);
  except
    on E: Exception do
    begin
      WriteLn(StdErr, E.Message);
      PrintUsage;
      Halt(1);
    end;
  end;
end.
