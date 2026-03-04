unit FPKRAIO;

{$mode objfpc}{$H+}

{ Provides a best-effort flattened import for Krita .kra files.
  Krita stores .kra as a ZIP archive. This unit:
    1. Opens the file as ZIP.
    2. Prefers Krita's merged image entries such as "mergedimage.png".
    3. Falls back to "preview.png" or the first PNG entry.
  Full layer-preserving import remains deferred. }

interface

uses
  Classes, SysUtils, FPSurface;

function TryLoadFlattenedKRASurface(const AFileName: string; out ASurface: TRasterSurface): Boolean;
function LoadFlattenedKRASurface(const AFileName: string): TRasterSurface;

implementation

uses
  Zipper, FPImage, FPReadPNG, FPColor;

type
  TKraUnzipStreamHolder = class
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

constructor TKraUnzipStreamHolder.Create(const ATargetEntry: string);
begin
  inherited Create;
  FTargetEntry := ATargetEntry;
  FStream := nil;
end;

destructor TKraUnzipStreamHolder.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TKraUnzipStreamHolder.OnCreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  if SameText(AItem.ArchiveFileName, FTargetEntry) then
  begin
    FStream := TMemoryStream.Create;
    AStream := FStream;
  end
  else
    AStream := TMemoryStream.Create;
end;

procedure TKraUnzipStreamHolder.OnDoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  if AStream <> FStream then
    AStream.Free;
  AStream := nil;
end;

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

function TryLoadFlattenedKRASurface(const AFileName: string; out ASurface: TRasterSurface): Boolean;
var
  Unzip: TUnZipper;
  Entries: TFullZipFileEntries;
  I: Integer;
  EntryName: string;
  BestEntry: string;
  StreamHolder: TKraUnzipStreamHolder;
  PNGReader: TFPReaderPNG;
  FPImg: TFPMemoryImage;
  FS: TFileStream;
  Sig: Word;
begin
  Result := False;
  ASurface := nil;
  if not FileExists(AFileName) then
    Exit;

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
  if Sig <> $4B50 then
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
    for I := 0 to Entries.Count - 1 do
    begin
      EntryName := LowerCase(Entries[I].ArchiveFileName);
      if SameText(ExtractFileExt(EntryName), '.png') then
      begin
        if SameText(EntryName, 'mergedimage.png') or
           SameText(EntryName, 'preview.png') or
           (Pos('/mergedimage.png', EntryName) > 0) or
           (Pos('/preview.png', EntryName) > 0) then
        begin
          BestEntry := Entries[I].ArchiveFileName;
          Break;
        end;
        if (Pos('mergedimage', EntryName) > 0) or (Pos('preview', EntryName) > 0) then
          BestEntry := Entries[I].ArchiveFileName
        else if BestEntry = '' then
          BestEntry := Entries[I].ArchiveFileName;
      end;
    end;
    if BestEntry = '' then
      Exit;

    StreamHolder := TKraUnzipStreamHolder.Create(BestEntry);
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

function LoadFlattenedKRASurface(const AFileName: string): TRasterSurface;
begin
  if not TryLoadFlattenedKRASurface(AFileName, Result) then
    raise Exception.Create(
      'Krita (.kra) file could not be imported.' + LineEnding +
      'This file may not contain a readable merged PNG preview.' + LineEnding +
      'To open Krita artwork in FlatPaint, save with a merged image preview or export a flattened PNG from Krita first.');
end;

end.
