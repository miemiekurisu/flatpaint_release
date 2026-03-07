unit fpio_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPColor, FPSurface, FPDocument, FPIO, FPKRAIO, FPPDNIO, Zipper;

type
  TFPIOTests = class(TTestCase)
  private
    function UniqueTempFile(const AExtension: string): string;
    procedure WriteBE32(AStream: TStream; AValue: Cardinal);
    procedure PatchBE32(AStream: TStream; APosition: Int64; AValue: Cardinal);
    procedure WriteXCFString(AStream: TStream; const AValue: string);
    procedure CreateMinimalXCFFIle(
      const AFileName: string;
      AImageWidth: Cardinal = 2;
      AImageHeight: Cardinal = 1;
      ALayerOffsetX: Integer = 0;
      ALayerOffsetY: Integer = 0
    );
  published
    procedure DefaultSaveOptionsExposeRealFormatControls;
    procedure LoaderCanSniffPngWithUnknownExtension;
    procedure PngRoundTripPreservesAlphaByDefault;
    procedure TargaRoundTripPreservesPixels;
    procedure LoaderCanReadMinimalXCFProject;
    procedure XcfCanLoadLayeredDocument;
    procedure XcfImportPreservesLayerOffsetMetadata;
    procedure UnifiedOpenFilterIncludesProjectsAndPSD;
    procedure KraLoadRaisesDescriptiveError;
    procedure KraZipLoadExtractsMergedImage;
    procedure PdnLoadRaisesDescriptiveError;
    procedure PdnZipLoadExtractsPNG;
  end;

implementation

procedure TFPIOTests.DefaultSaveOptionsExposeRealFormatControls;
var
  Opts: TSaveSurfaceOptions;
begin
  Opts := DefaultSaveSurfaceOptions;
  AssertEquals('jpeg quality default', 90, Opts.JpegQuality);
  AssertFalse('jpeg progressive default', Opts.JpegProgressive);
  AssertEquals('png compression default', 6, Opts.PngCompressionLevel);
  AssertTrue('png alpha enabled by default', Opts.PngUseAlpha);
end;

function TFPIOTests.UniqueTempFile(const AExtension: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    Format('flatpaint-fpio-%d%s', [GetTickCount64, AExtension]);
end;

procedure TFPIOTests.WriteBE32(AStream: TStream; AValue: Cardinal);
var
  Bytes: array[0..3] of Byte;
begin
  Bytes[0] := (AValue shr 24) and $FF;
  Bytes[1] := (AValue shr 16) and $FF;
  Bytes[2] := (AValue shr 8) and $FF;
  Bytes[3] := AValue and $FF;
  AStream.WriteBuffer(Bytes, SizeOf(Bytes));
end;

procedure TFPIOTests.PatchBE32(AStream: TStream; APosition: Int64; AValue: Cardinal);
var
  RestorePosition: Int64;
begin
  RestorePosition := AStream.Position;
  AStream.Position := APosition;
  WriteBE32(AStream, AValue);
  AStream.Position := RestorePosition;
end;

procedure TFPIOTests.WriteXCFString(AStream: TStream; const AValue: string);
var
  Encoded: RawByteString;
  Terminator: Byte;
begin
  Encoded := UTF8Encode(AValue);
  WriteBE32(AStream, Length(Encoded) + 1);
  if Length(Encoded) > 0 then
    AStream.WriteBuffer(Encoded[1], Length(Encoded));
  Terminator := 0;
  AStream.WriteBuffer(Terminator, SizeOf(Terminator));
end;

procedure TFPIOTests.CreateMinimalXCFFIle(
  const AFileName: string;
  AImageWidth: Cardinal;
  AImageHeight: Cardinal;
  ALayerOffsetX: Integer;
  ALayerOffsetY: Integer
);
var
  Stream: TFileStream;
  LayerOffsetPos: Int64;
  HierarchyOffsetPos: Int64;
  LevelOffsetPos: Int64;
  TileOffsetPos: Int64;
  MagicText: RawByteString;
  VersionText: RawByteString;
  ZeroByte: Byte;
const
  PixelBytes: array[0..7] of Byte = (
    255, 0, 0, 255,
    0, 255, 0, 128
  );
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    MagicText := 'gimp xcf ';
    VersionText := 'file';
    ZeroByte := 0;
    Stream.WriteBuffer(MagicText[1], Length(MagicText));
    Stream.WriteBuffer(VersionText[1], Length(VersionText));
    Stream.WriteBuffer(ZeroByte, SizeOf(ZeroByte));
    WriteBE32(Stream, AImageWidth);
    WriteBE32(Stream, AImageHeight);
    WriteBE32(Stream, 0);

    WriteBE32(Stream, 17);
    WriteBE32(Stream, 1);
    Stream.WriteByte(0);
    WriteBE32(Stream, 0);
    WriteBE32(Stream, 0);

    LayerOffsetPos := Stream.Position;
    WriteBE32(Stream, 0);
    WriteBE32(Stream, 0);

    PatchBE32(Stream, LayerOffsetPos, Cardinal(Stream.Position));
    WriteBE32(Stream, 2);
    WriteBE32(Stream, 1);
    WriteBE32(Stream, 1);
    WriteXCFString(Stream, 'Layer 1');
    WriteBE32(Stream, 15);
    WriteBE32(Stream, 8);
    WriteBE32(Stream, Cardinal(ALayerOffsetX));
    WriteBE32(Stream, Cardinal(ALayerOffsetY));
    WriteBE32(Stream, 6);
    WriteBE32(Stream, 4);
    WriteBE32(Stream, 255);
    WriteBE32(Stream, 8);
    WriteBE32(Stream, 4);
    WriteBE32(Stream, 1);
    WriteBE32(Stream, 0);
    WriteBE32(Stream, 0);

    HierarchyOffsetPos := Stream.Position;
    WriteBE32(Stream, 0);
    WriteBE32(Stream, 0);

    PatchBE32(Stream, HierarchyOffsetPos, Cardinal(Stream.Position));
    WriteBE32(Stream, 2);
    WriteBE32(Stream, 1);
    WriteBE32(Stream, 4);

    LevelOffsetPos := Stream.Position;
    WriteBE32(Stream, 0);
    WriteBE32(Stream, 0);

    PatchBE32(Stream, LevelOffsetPos, Cardinal(Stream.Position));
    WriteBE32(Stream, 2);
    WriteBE32(Stream, 1);

    TileOffsetPos := Stream.Position;
    WriteBE32(Stream, 0);
    WriteBE32(Stream, 0);

    PatchBE32(Stream, TileOffsetPos, Cardinal(Stream.Position));
    Stream.WriteBuffer(PixelBytes, SizeOf(PixelBytes));
  finally
    Stream.Free;
  end;
end;

procedure TFPIOTests.LoaderCanSniffPngWithUnknownExtension;
var
  SourceSurface: TRasterSurface;
  LoadedSurface: TRasterSurface;
  PngPath: string;
  UnknownPath: string;
begin
  SourceSurface := TRasterSurface.Create(3, 2);
  try
    SourceSurface.Clear(TransparentColor);
    SourceSurface[1, 1] := RGBA(12, 34, 56, 255);
    PngPath := UniqueTempFile('.png');
    UnknownPath := ChangeFileExt(PngPath, '.dat');
    SaveSurfaceToFile(PngPath, SourceSurface);
    AssertTrue('rename to unknown extension', RenameFile(PngPath, UnknownPath));

    LoadedSurface := LoadSurfaceFromFile(UnknownPath);
    try
      AssertEquals('loaded width', 3, LoadedSurface.Width);
      AssertEquals('loaded height', 2, LoadedSurface.Height);
      AssertTrue(
        'pixel survives sniffed load',
        RGBAEqual(LoadedSurface[1, 1], RGBA(12, 34, 56, 255))
      );
    finally
      LoadedSurface.Free;
      DeleteFile(UnknownPath);
    end;
  finally
    SourceSurface.Free;
  end;
end;

procedure TFPIOTests.PngRoundTripPreservesAlphaByDefault;
var
  SourceSurface: TRasterSurface;
  LoadedSurface: TRasterSurface;
  PngPath: string;
  Opts: TSaveSurfaceOptions;
begin
  SourceSurface := TRasterSurface.Create(1, 1);
  try
    SourceSurface[0, 0] := RGBA(10, 20, 30, 123);
    PngPath := UniqueTempFile('.png');
    Opts := DefaultSaveSurfaceOptions;
    SaveSurfaceToFileWithOpts(PngPath, SourceSurface, Opts);

    LoadedSurface := LoadSurfaceFromFile(PngPath);
    try
      AssertTrue(
        'png alpha-preserving save round-trips the exact pixel',
        RGBAEqual(LoadedSurface[0, 0], SourceSurface[0, 0])
      );
    finally
      LoadedSurface.Free;
      DeleteFile(PngPath);
    end;
  finally
    SourceSurface.Free;
  end;
end;

procedure TFPIOTests.TargaRoundTripPreservesPixels;
var
  SourceSurface: TRasterSurface;
  LoadedSurface: TRasterSurface;
  TgaPath: string;
begin
  SourceSurface := TRasterSurface.Create(2, 2);
  try
    SourceSurface.Clear(TransparentColor);
    SourceSurface[0, 0] := RGBA(220, 10, 40, 255);
    SourceSurface[1, 1] := RGBA(5, 180, 90, 255);
    TgaPath := UniqueTempFile('.tga');
    SaveSurfaceToFile(TgaPath, SourceSurface);

    LoadedSurface := LoadSurfaceFromFile(TgaPath);
    try
      AssertTrue('tga pixel 1', RGBAEqual(LoadedSurface[0, 0], SourceSurface[0, 0]));
      AssertTrue('tga pixel 2', RGBAEqual(LoadedSurface[1, 1], SourceSurface[1, 1]));
    finally
      LoadedSurface.Free;
      DeleteFile(TgaPath);
    end;
  finally
    SourceSurface.Free;
  end;
end;

procedure TFPIOTests.LoaderCanReadMinimalXCFProject;
var
  XCFPath: string;
  LoadedSurface: TRasterSurface;
begin
  XCFPath := UniqueTempFile('.xcf');
  CreateMinimalXCFFIle(XCFPath);

  LoadedSurface := LoadSurfaceFromFile(XCFPath);
  try
    AssertEquals('xcf width', 2, LoadedSurface.Width);
    AssertEquals('xcf height', 1, LoadedSurface.Height);
    AssertTrue('xcf pixel 1', RGBAEqual(LoadedSurface[0, 0], RGBA(255, 0, 0, 255)));
    AssertTrue('xcf pixel 2', RGBAEqual(LoadedSurface[1, 0], RGBA(0, 255, 0, 128)));
  finally
    LoadedSurface.Free;
    DeleteFile(XCFPath);
  end;
end;

procedure TFPIOTests.XcfCanLoadLayeredDocument;
var
  XCFPath: string;
  LoadedDocument: TImageDocument;
begin
  XCFPath := UniqueTempFile('.xcf');
  CreateMinimalXCFFIle(XCFPath);
  LoadedDocument := nil;
  try
    AssertTrue(
      'xcf should load as a layered document',
      TryLoadDocumentFromFile(XCFPath, LoadedDocument)
    );
    AssertNotNull('document should not be nil', LoadedDocument);
    AssertEquals('xcf doc width', 2, LoadedDocument.Width);
    AssertEquals('xcf doc height', 1, LoadedDocument.Height);
    AssertEquals('xcf doc layer count', 1, LoadedDocument.LayerCount);
    AssertTrue(
      'xcf layer pixel should survive',
      RGBAEqual(LoadedDocument.Layers[0].Surface[0, 0], RGBA(255, 0, 0, 255))
    );
    AssertTrue(
      'xcf second pixel alpha should survive',
      RGBAEqual(LoadedDocument.Layers[0].Surface[1, 0], RGBA(0, 255, 0, 128))
    );
  finally
    LoadedDocument.Free;
    DeleteFile(XCFPath);
  end;
end;

procedure TFPIOTests.XcfImportPreservesLayerOffsetMetadata;
var
  XCFPath: string;
  LoadedDocument: TImageDocument;
begin
  XCFPath := UniqueTempFile('.xcf');
  CreateMinimalXCFFIle(XCFPath, 2, 1, -1, 0);
  LoadedDocument := nil;
  try
    AssertTrue(
      'xcf should load as a layered document',
      TryLoadDocumentFromFile(XCFPath, LoadedDocument)
    );
    AssertNotNull('document should not be nil', LoadedDocument);
    AssertEquals('imported layer offset x is preserved', -1, LoadedDocument.Layers[0].OffsetX);
    AssertEquals('imported layer offset y is preserved', 0, LoadedDocument.Layers[0].OffsetY);
    AssertTrue(
      'stamped payload reflects negative x offset clipping behavior',
      RGBAEqual(LoadedDocument.Layers[0].Surface[0, 0], RGBA(0, 255, 0, 128))
    );
  finally
    LoadedDocument.Free;
    DeleteFile(XCFPath);
  end;
end;

procedure TFPIOTests.UnifiedOpenFilterIncludesProjectsAndPSD;
var
  FilterText: string;
begin
  FilterText := SupportedOpenDialogFilter;
  AssertTrue('filter includes native project', Pos('*.fpd', FilterText) > 0);
  AssertTrue('filter includes xcf', Pos('*.xcf', FilterText) > 0);
  AssertTrue('filter includes psd', Pos('*.psd', FilterText) > 0);
  AssertTrue('filter includes kra', Pos('*.kra', FilterText) > 0);
  AssertTrue('filter includes pdn', Pos('*.pdn', FilterText) > 0);
  AssertTrue('filter starts with unified label', Pos('All Supported Files|', FilterText) = 1);
end;

procedure TFPIOTests.KraLoadRaisesDescriptiveError;
var
  KraPath: string;
  GotException: Boolean;
  ExceptionMsg: string;
begin
  KraPath := UniqueTempFile('.kra');
  { Write a fake kra file (empty content) so the loader tries to read it }
  with TFileStream.Create(KraPath, fmCreate) do Free;
  GotException := False;
  ExceptionMsg := '';
  try
    LoadSurfaceFromFile(KraPath);
  except
    on E: Exception do
    begin
      GotException := True;
      ExceptionMsg := E.Message;
    end;
  end;
  DeleteFile(KraPath);
  AssertTrue('kra load must raise', GotException);
  AssertTrue('kra error mentions kra', Pos('.kra', ExceptionMsg) > 0);
end;

procedure TFPIOTests.KraZipLoadExtractsMergedImage;
var
  KraPath: string;
  PngPath: string;
  Surface: TRasterSurface;
  LoadedSurface: TRasterSurface;
  ZipperObj: TZipper;
begin
  KraPath := UniqueTempFile('.kra');
  PngPath := UniqueTempFile('.png');
  Surface := TRasterSurface.Create(1, 1);
  LoadedSurface := nil;
  try
    Surface[0, 0] := RGBA(12, 34, 56, 255);
    SaveSurfaceToFile(PngPath, Surface);

    ZipperObj := TZipper.Create;
    try
      ZipperObj.FileName := KraPath;
      ZipperObj.Entries.AddFileEntry(PngPath, 'mergedimage.png');
      ZipperObj.ZipAllFiles;
    finally
      ZipperObj.Free;
    end;

    LoadedSurface := LoadSurfaceFromFile(KraPath);
    AssertNotNull('kra load should return a surface', LoadedSurface);
    AssertEquals('kra width', 1, LoadedSurface.Width);
    AssertEquals('kra height', 1, LoadedSurface.Height);
    AssertTrue('kra pixel should match merged image', RGBAEqual(LoadedSurface[0, 0], RGBA(12, 34, 56, 255)));
  finally
    LoadedSurface.Free;
    Surface.Free;
    DeleteFile(PngPath);
    DeleteFile(KraPath);
  end;
end;

procedure TFPIOTests.PdnLoadRaisesDescriptiveError;
var
  PdnPath: string;
  GotException: Boolean;
  ExceptionMsg: string;
begin
  PdnPath := UniqueTempFile('.pdn');
  with TFileStream.Create(PdnPath, fmCreate) do Free;
  GotException := False;
  ExceptionMsg := '';
  try
    LoadSurfaceFromFile(PdnPath);
  except
    on E: Exception do
    begin
      GotException := True;
      ExceptionMsg := E.Message;
    end;
  end;
  DeleteFile(PdnPath);
  AssertTrue('pdn load must raise', GotException);
  AssertTrue('pdn error mentions pdn', Pos('.pdn', ExceptionMsg) > 0);
end;

procedure TFPIOTests.PdnZipLoadExtractsPNG;
{ Writes a ZIP that contains a 1×1 PNG named 'merged.png' (matching the
  preferred-entry heuristic) and verifies that TryLoadFlattenedPDNSurface
  successfully extracts it into a valid TRasterSurface. }
const
  { Minimal ZIP containing a 1×1 RGB PNG named 'merged.png' }
  MiniPdnZip: array[0..186] of Byte = (
    80,75,3,4,20,0,0,0,0,0,226,161,98,92,81,15,
    218,2,69,0,0,0,69,0,0,0,10,0,0,0,109,101,
    114,103,101,100,46,112,110,103,137,80,78,71,13,10,26,10,
    0,0,0,13,73,72,68,82,0,0,0,1,0,0,0,1,
    8,2,0,0,0,144,119,83,222,0,0,0,12,73,68,65,
    84,120,156,99,248,207,192,0,0,3,1,1,0,201,254,146,
    239,0,0,0,0,73,69,78,68,174,66,96,130,80,75,1,
    2,20,3,20,0,0,0,0,0,226,161,98,92,81,15,218,
    2,69,0,0,0,69,0,0,0,10,0,0,0,0,0,0,
    0,0,0,0,0,128,1,0,0,0,0,109,101,114,103,101,
    100,46,112,110,103,80,75,5,6,0,0,0,0,1,0,1,
    0,56,0,0,0,109,0,0,0,0,0
  );
var
  PdnPath: string;
  FS: TFileStream;
  Surface: TRasterSurface;
  Ok: Boolean;
begin
  PdnPath := UniqueTempFile('.pdn');
  FS := TFileStream.Create(PdnPath, fmCreate);
  try
    FS.WriteBuffer(MiniPdnZip[0], SizeOf(MiniPdnZip));
  finally
    FS.Free;
  end;
  Surface := nil;
  Ok := False;
  try
    Ok := TryLoadFlattenedPDNSurface(PdnPath, Surface);
    AssertTrue('pdn zip should load successfully', Ok);
    AssertNotNull('surface should not be nil', Surface);
    AssertEquals('width should be 1', 1, Surface.Width);
    AssertEquals('height should be 1', 1, Surface.Height);
  finally
    Surface.Free;
    DeleteFile(PdnPath);
  end;
end;

initialization
  RegisterTest(TFPIOTests);

end.
