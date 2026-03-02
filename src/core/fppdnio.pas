unit FPPDNIO;

{$mode objfpc}{$H+}

{ Provides a best-effort flattened import for Paint.NET .pdn files.
  Paint.NET 4.x saves .pdn as a ZIP archive containing layer bitmaps in a
  proprietary format. This unit:
    1. Tries to open the file as a ZIP and extract the first PNG-encoded entry
       whose name matches "bitmap\d+.png" or any "*.png".
    2. Falls back to a descriptive error message if the ZIP approach fails.
  Deeper layer-preserving import requires a full .pdn format decoder and is
  deferred to a future phase. }

interface

uses
  Classes, SysUtils, FPSurface;

function TryLoadFlattenedPDNSurface(const AFileName: string; out ASurface: TRasterSurface): Boolean;
function LoadFlattenedPDNSurface(const AFileName: string): TRasterSurface;

implementation

uses
  Zipper, FPImage, FPReadPNG, FPColor;

{ ─────────────────────────────────────────────────────────────────────────── }
{ Stream-capture helper for TUnZipper                                          }
{ ─────────────────────────────────────────────────────────────────────────── }

type
  { Captures a single ZIP entry into a TMemoryStream via OnCreateStream event }
  TUnzipStreamHolder = class
  private
    FTargetEntry: string;
    FStream: TMemoryStream;
  public
    constructor Create(const ATargetEntry: string);
    destructor Destroy; override;
    procedure OnCreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    procedure OnDoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    property Stream: TMemoryStream read FStream;
  end;

constructor TUnzipStreamHolder.Create(const ATargetEntry: string);
begin
  inherited Create;
  FTargetEntry := ATargetEntry;
  FStream := nil;
end;

destructor TUnzipStreamHolder.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TUnzipStreamHolder.OnCreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  if SameText(AItem.ArchiveFileName, FTargetEntry) then
  begin
    FStream := TMemoryStream.Create;
    AStream := FStream;
  end
  else
    AStream := TMemoryStream.Create; { discard other entries }
end;

procedure TUnzipStreamHolder.OnDoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  { Only free streams that are NOT our captured stream }
  if AStream <> FStream then
    AStream.Free;
  AStream := nil;
end;

{ ─────────────────────────────────────────────────────────────────────────── }
{ Helpers                                                                      }
{ ─────────────────────────────────────────────────────────────────────────── }

function FPImageToSurface(AImage: TFPCustomImage): TRasterSurface;
var
  X, Y: Integer;
  C: TFPColor;
begin
  Result := TRasterSurface.Create(AImage.Width, AImage.Height);
  for Y := 0 to AImage.Height - 1 do
    for X := 0 to AImage.Width - 1 do
    begin
      C := AImage.Colors[X, Y];
      Result[X, Y] := RGBA(
        C.Red shr 8,
        C.Green shr 8,
        C.Blue shr 8,
        C.Alpha shr 8
      );
    end;
end;

{ ─────────────────────────────────────────────────────────────────────────── }
{ ZIP-based extraction                                                         }
{ ─────────────────────────────────────────────────────────────────────────── }

function TryLoadFlattenedPDNSurface(const AFileName: string; out ASurface: TRasterSurface): Boolean;
var
  Unzip: TUnZipper;
  Entries: TFullZipFileEntries;
  I: Integer;
  EntryName: string;
  BestEntry: string;
  StreamHolder: TUnzipStreamHolder;
  PNGReader: TFPReaderPNG;
  FPImg: TFPMemoryImage;
  FS: TFileStream;
  Sig: Word;
begin
  Result := False;
  ASurface := nil;
  if not FileExists(AFileName) then
    Exit;

  { Quick signature check: ZIP starts with PK (0x50 0x4B) }
  Sig := 0;
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size >= 2 then
        FS.Read(Sig, 2);
    finally
      FS.Free;
    end;
  except
    Exit;
  end;
  if Sig <> $4B50 then { 'PK' little-endian }
    Exit;

  Unzip := TUnZipper.Create;
  try
    Unzip.FileName := AFileName;
    try
      Unzip.Examine;
    except
      Exit;
    end;
    Entries := Unzip.Entries;
    BestEntry := '';
    { prefer 'merged.png' or 'flattened.png', otherwise take first PNG }
    for I := 0 to Entries.Count - 1 do
    begin
      EntryName := LowerCase(Entries[I].ArchiveFileName);
      if SameText(ExtractFileExt(EntryName), '.png') then
      begin
        if (Pos('merged', EntryName) > 0) or (Pos('flatten', EntryName) > 0) then
        begin
          BestEntry := Entries[I].ArchiveFileName;
          Break;
        end;
        if BestEntry = '' then
          BestEntry := Entries[I].ArchiveFileName;
      end;
    end;
    if BestEntry = '' then
      Exit;

    { Use OnCreateStream event to capture the target entry into a MemoryStream }
    StreamHolder := TUnzipStreamHolder.Create(BestEntry);
    try
      Unzip.OnCreateStream := @StreamHolder.OnCreateStream;
      Unzip.OnDoneStream := @StreamHolder.OnDoneStream;
      try
        Unzip.UnZipFile(BestEntry);
      except
        Exit;
      end;
      if StreamHolder.Stream = nil then
        Exit;
      StreamHolder.Stream.Position := 0;
      PNGReader := TFPReaderPNG.Create;
      FPImg := TFPMemoryImage.Create(0, 0);
      try
        FPImg.LoadFromStream(StreamHolder.Stream, PNGReader);
        ASurface := FPImageToSurface(FPImg);
        Result := True;
      finally
        FPImg.Free;
        PNGReader.Free;
      end;
    finally
      StreamHolder.Free;
    end;
  finally
    Unzip.Free;
  end;
end;

function LoadFlattenedPDNSurface(const AFileName: string): TRasterSurface;
begin
  if not TryLoadFlattenedPDNSurface(AFileName, Result) then
    raise Exception.Create(
      'Paint.NET (.pdn) files could not be imported.' + LineEnding +
      'This file may use an older format not based on ZIP.' + LineEnding +
      'To open Paint.NET artwork in FlatPaint, export a flattened PNG from Paint.NET first.');
end;

end.
