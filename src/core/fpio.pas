unit FPIO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FPImage, FPColor, FPSurface;

type
  { Options passed to SaveSurfaceToFileWithOpts.
    JpegQuality: 1..100 (default 90 if 0).
    JpegProgressive: whether JPEG should use progressive encoding.
    PngCompressionLevel: 0..9 user-facing scale mapped onto zlib levels.
    PngUseAlpha: whether PNG should preserve alpha data. }
  TSaveSurfaceOptions = record
    JpegQuality: Integer;
    JpegProgressive: Boolean;
    PngCompressionLevel: Integer;
    PngUseAlpha: Boolean;
  end;

function DefaultSaveSurfaceOptions: TSaveSurfaceOptions;
function LoadSurfaceFromFile(const AFileName: string): TRasterSurface;
procedure SaveSurfaceToFile(const AFileName: string; ASurface: TRasterSurface);
procedure SaveSurfaceToFileWithOpts(const AFileName: string; ASurface: TRasterSurface; const AOpts: TSaveSurfaceOptions);
function SupportedSurfaceOpenPattern: string;
function SupportedOpenDialogFilter: string;
function SupportedImportDialogFilter: string;

implementation

uses
  FPKRAIO,
  FPXCFIO,
  FPPDNIO,
  FPReadBMP, FPReadGIF, FPReadJPEG, FPReadPCX, FPReadPNG, FPReadPNM, FPReadPSD,
  FPReadTGA, FPReadTiff, FPReadXPM, FPReadXWD,
  FPWriteBMP, FPWriteJPEG, FPWritePCX, FPWritePNG, FPWritePNM, FPWriteTGA,
  FPWriteTiff, FPWriteXPM, ZStream;

const
  SurfaceOpenPattern =
    '*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff;*.gif;*.psd;*.pcx;*.pnm;*.pbm;*.pgm;*.ppm;*.tga;*.xpm;*.xwd;*.xcf;*.kra;*.pdn';

function CreateReader(const AExtension: string): TFPCustomImageReader;
begin
  if (AExtension = '.png') then
    Exit(TFPReaderPNG.Create);
  if (AExtension = '.jpg') or (AExtension = '.jpeg') then
    Exit(TFPReaderJPEG.Create);
  if (AExtension = '.bmp') then
    Exit(TFPReaderBMP.Create);
  if (AExtension = '.tif') or (AExtension = '.tiff') then
    Exit(TFPReaderTiff.Create);
  if (AExtension = '.gif') then
    Exit(TFPReaderGIF.Create);
  if (AExtension = '.pcx') then
    Exit(TFPReaderPCX.Create);
  if (AExtension = '.pnm') or (AExtension = '.pbm') or
     (AExtension = '.pgm') or (AExtension = '.ppm') then
    Exit(TFPReaderPNM.Create);
  if (AExtension = '.psd') then
    Exit(TFPReaderPSD.Create);
  if (AExtension = '.tga') then
    Exit(TFPReaderTarga.Create);
  if (AExtension = '.xpm') then
    Exit(TFPReaderXPM.Create);
  if (AExtension = '.xwd') then
    Exit(TFPReaderXWD.Create);
  Result := nil;
end;

function CreateReaderByIndex(AIndex: Integer): TFPCustomImageReader;
begin
  case AIndex of
    0: Result := TFPReaderPNG.Create;
    1: Result := TFPReaderJPEG.Create;
    2: Result := TFPReaderBMP.Create;
    3: Result := TFPReaderTiff.Create;
    4: Result := TFPReaderGIF.Create;
    5: Result := TFPReaderPCX.Create;
    6: Result := TFPReaderPNM.Create;
    7: Result := TFPReaderPSD.Create;
    8: Result := TFPReaderTarga.Create;
    9: Result := TFPReaderXPM.Create;
    10: Result := TFPReaderXWD.Create;
  else
    Result := nil;
  end;
end;

function TryLoadSurfaceWithReader(const AFileName: string; AReader: TFPCustomImageReader; out ASurface: TRasterSurface): Boolean;
var
  Image: TFPMemoryImage;
  Stream: TFileStream;
  X: Integer;
  Y: Integer;
  Pixel: TFPColor;
begin
  Result := False;
  ASurface := nil;
  if AReader = nil then
    Exit;

  Image := TFPMemoryImage.Create(0, 0);
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    try
      Image.LoadFromStream(Stream, AReader);
      ASurface := TRasterSurface.Create(Image.Width, Image.Height);
      for Y := 0 to Image.Height - 1 do
        for X := 0 to Image.Width - 1 do
        begin
          Pixel := Image.Colors[X, Y];
          ASurface[X, Y] := RGBA(Pixel.Red shr 8, Pixel.Green shr 8, Pixel.Blue shr 8, Pixel.Alpha shr 8);
        end;
      Result := True;
    except
      FreeAndNil(ASurface);
      Result := False;
    end;
  finally
    Stream.Free;
    Image.Free;
    AReader.Free;
  end;
end;

function LoadSurfaceUsingKnownReaders(const AFileName, APreferredExtension: string): TRasterSurface;
var
  ReaderIndex: Integer;
  PreferredReader: TFPCustomImageReader;
begin
  { Krita .kra files are ZIP archives; try Krita's merged PNG preview first. }
  if SameText(APreferredExtension, '.kra') then
  begin
    if TryLoadFlattenedKRASurface(AFileName, Result) then
      Exit;
    raise Exception.Create(
      'Krita (.kra) file could not be imported.' + LineEnding +
      'This file may not contain a readable merged PNG preview.' + LineEnding +
      'To open Krita artwork in FlatPaint, save with a merged image preview or export a flattened PNG from Krita first.');
  end;

  { Paint.NET .pdn files: attempt ZIP-based flattened PNG extraction first }
  if SameText(APreferredExtension, '.pdn') then
  begin
    if TryLoadFlattenedPDNSurface(AFileName, Result) then
      Exit;
    raise Exception.Create(
      'Paint.NET (.pdn) file could not be imported.' + LineEnding +
      'This file may use an older non-ZIP format.' + LineEnding +
      'To open Paint.NET artwork in FlatPaint, export a flattened PNG from Paint.NET first.');
  end;

  if SameText(APreferredExtension, '.xcf') and TryLoadFlattenedXCFSurface(AFileName, Result) then
    Exit;

  PreferredReader := CreateReader(APreferredExtension);
  if TryLoadSurfaceWithReader(AFileName, PreferredReader, Result) then
    Exit;

  for ReaderIndex := 0 to 10 do
    if TryLoadSurfaceWithReader(AFileName, CreateReaderByIndex(ReaderIndex), Result) then
      Exit;

  if TryLoadFlattenedXCFSurface(AFileName, Result) then
    Exit;

  raise Exception.CreateFmt(
    'Unsupported or unreadable image format: %s',
    [ExtractFileExt(AFileName)]
  );
end;

function CreateWriter(const AExtension: string): TFPCustomImageWriter;
begin
  if (AExtension = '.png') then
    Exit(TFPWriterPNG.Create);
  if (AExtension = '.jpg') or (AExtension = '.jpeg') then
    Exit(TFPWriterJPEG.Create);
  if (AExtension = '.bmp') then
    Exit(TFPWriterBMP.Create);
  if (AExtension = '.tif') or (AExtension = '.tiff') then
    Exit(TFPWriterTiff.Create);
  if (AExtension = '.pcx') then
    Exit(TFPWriterPCX.Create);
  if (AExtension = '.pnm') or (AExtension = '.pbm') or
     (AExtension = '.pgm') or (AExtension = '.ppm') then
    Exit(TFPWriterPNM.Create);
  if (AExtension = '.tga') then
    Exit(TFPWriterTarga.Create);
  if (AExtension = '.xpm') then
    Exit(TFPWriterXPM.Create);
  raise Exception.CreateFmt('Unsupported image format: %s', [AExtension]);
end;

function LoadSurfaceFromFile(const AFileName: string): TRasterSurface;
begin
  Result := LoadSurfaceUsingKnownReaders(AFileName, LowerCase(ExtractFileExt(AFileName)));
end;

function SupportedSurfaceOpenPattern: string;
begin
  Result := SurfaceOpenPattern;
end;

function SupportedOpenDialogFilter: string;
begin
  Result :=
    'All Supported Files|*.fpd;' + SurfaceOpenPattern + '|' +
    'FlatPaint and Compatible Projects|*.fpd;*.xcf|' +
    'Supported Images and Imported Projects|' + SurfaceOpenPattern + '|' +
    'Krita Files (partial)|*.kra|' +
    'Paint.NET Files (partial)|*.pdn';
end;

function SupportedImportDialogFilter: string;
begin
  Result :=
    'All Importable Files|*.fpd;' + SurfaceOpenPattern + '|' +
    'FlatPaint Project|*.fpd|' +
    'Supported Images and Imported Projects|' + SurfaceOpenPattern;
end;

procedure SaveSurfaceToFile(const AFileName: string; ASurface: TRasterSurface);
var
  Opts: TSaveSurfaceOptions;
begin
  Opts := DefaultSaveSurfaceOptions;
  SaveSurfaceToFileWithOpts(AFileName, ASurface, Opts);
end;

procedure SaveSurfaceToFileWithOpts(const AFileName: string; ASurface: TRasterSurface; const AOpts: TSaveSurfaceOptions);
var
  Writer: TFPCustomImageWriter;
  Image: TFPMemoryImage;
  Stream: TFileStream;
  X: Integer;
  Y: Integer;
  Pixel: TRGBA32;
  Extension: string;
  JpegQuality: Integer;
  PngLevel: Integer;
  PngCompression: TCompressionLevel;
begin
  Extension := LowerCase(ExtractFileExt(AFileName));
  Writer := CreateWriter(Extension);
  Image := TFPMemoryImage.Create(ASurface.Width, ASurface.Height);
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    { Configure writer options }
    if Writer is TFPWriterJPEG then
    begin
      JpegQuality := AOpts.JpegQuality;
      if JpegQuality <= 0 then JpegQuality := 90;
      TFPWriterJPEG(Writer).CompressionQuality := JpegQuality;
      TFPWriterJPEG(Writer).ProgressiveEncoding := AOpts.JpegProgressive;
    end
    else if Writer is TFPWriterPNG then
    begin
      PngLevel := AOpts.PngCompressionLevel;
      if PngLevel <= 0 then
        PngCompression := clNone
      else if PngLevel <= 3 then
        PngCompression := clFastest
      else if PngLevel >= 8 then
        PngCompression := clMax
      else
        PngCompression := clDefault;
      TFPWriterPNG(Writer).UseAlpha := AOpts.PngUseAlpha;
      TFPWriterPNG(Writer).CompressionLevel := PngCompression;
    end;

    for Y := 0 to ASurface.Height - 1 do
      for X := 0 to ASurface.Width - 1 do
      begin
        Pixel := ASurface[X, Y];
        Image.Colors[X, Y] := FPImage.FPColor(Pixel.R shl 8, Pixel.G shl 8, Pixel.B shl 8, Pixel.A shl 8);
      end;
    Image.SaveToStream(Stream, Writer);
  finally
    Stream.Free;
    Image.Free;
    Writer.Free;
  end;
end;

function DefaultSaveSurfaceOptions: TSaveSurfaceOptions;
begin
  Result.JpegQuality := 90;
  Result.JpegProgressive := False;
  Result.PngCompressionLevel := 6;
  Result.PngUseAlpha := True;
end;

end.
