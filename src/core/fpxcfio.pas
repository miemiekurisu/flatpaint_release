unit FPXCFIO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FPSurface;

function LoadFlattenedXCFSurface(const AFileName: string): TRasterSurface;
function TryLoadFlattenedXCFSurface(const AFileName: string; out ASurface: TRasterSurface): Boolean;

implementation

uses
  Math, FPColor;

const
  XCFMagic = 'gimp xcf ';

  PROP_END = 0;
  PROP_COLORMAP = 1;
  PROP_OPACITY = 6;
  PROP_VISIBLE = 8;
  PROP_OFFSETS = 15;
  PROP_COMPRESSION = 17;
  PROP_GROUP_ITEM = 29;

  COMPRESS_NONE = 0;
  COMPRESS_RLE = 1;

  GIMP_RGB_IMAGE = 0;
  GIMP_RGBA_IMAGE = 1;
  GIMP_GRAY_IMAGE = 2;
  GIMP_GRAYA_IMAGE = 3;
  GIMP_INDEXED_IMAGE = 4;
  GIMP_INDEXEDA_IMAGE = 5;

type
  TInt64Array = array of Int64;

  TXCFContext = record
    Version: Integer;
    PointerSize: Integer;
    Width: Integer;
    Height: Integer;
    Compression: Byte;
    Precision: Cardinal;
    ColorMap: array of Byte;
  end;

  TXCFLayerInfo = record
    Width: Integer;
    Height: Integer;
    LayerType: Cardinal;
    OffsetX: Integer;
    OffsetY: Integer;
    Visible: Boolean;
    Opacity: Byte;
    IsGroup: Boolean;
    HierarchyOffset: Int64;
  end;

function ReadUInt32BE(AStream: TStream): Cardinal;
var
  Bytes: array[0..3] of Byte;
begin
  AStream.ReadBuffer(Bytes, SizeOf(Bytes));
  Result :=
    (Cardinal(Bytes[0]) shl 24) or
    (Cardinal(Bytes[1]) shl 16) or
    (Cardinal(Bytes[2]) shl 8) or
    Cardinal(Bytes[3]);
end;

function ReadUInt16BE(AStream: TStream): Word;
var
  Bytes: array[0..1] of Byte;
begin
  AStream.ReadBuffer(Bytes, SizeOf(Bytes));
  Result := (Word(Bytes[0]) shl 8) or Word(Bytes[1]);
end;

function ReadInt32BE(AStream: TStream): Integer;
begin
  Result := Integer(ReadUInt32BE(AStream));
end;

function ReadUInt64BE(AStream: TStream): QWord;
var
  Bytes: array[0..7] of Byte;
begin
  AStream.ReadBuffer(Bytes, SizeOf(Bytes));
  Result :=
    (QWord(Bytes[0]) shl 56) or
    (QWord(Bytes[1]) shl 48) or
    (QWord(Bytes[2]) shl 40) or
    (QWord(Bytes[3]) shl 32) or
    (QWord(Bytes[4]) shl 24) or
    (QWord(Bytes[5]) shl 16) or
    (QWord(Bytes[6]) shl 8) or
    QWord(Bytes[7]);
end;

function ReadPointerValue(AStream: TStream; APointerSize: Integer): Int64;
begin
  if APointerSize = 8 then
    Result := Int64(ReadUInt64BE(AStream))
  else
    Result := Int64(ReadUInt32BE(AStream));
end;

function ReadByteValue(AStream: TStream): Byte;
begin
  AStream.ReadBuffer(Result, SizeOf(Result));
end;

procedure SkipBytes(AStream: TStream; ACount: Int64);
begin
  if ACount <= 0 then
    Exit;
  AStream.Position := AStream.Position + ACount;
end;

function ReadXCFVersion(AStream: TStream): Integer;
var
  VersionBytes: array[0..7] of Byte;
  Index: Integer;
  VersionText: string;
begin
  FillChar(VersionBytes, SizeOf(VersionBytes), 0);
  for Index := 0 to High(VersionBytes) do
  begin
    VersionBytes[Index] := ReadByteValue(AStream);
    if VersionBytes[Index] = 0 then
      Break;
  end;

  SetString(VersionText, PChar(@VersionBytes[0]), StrLen(PChar(@VersionBytes[0])));
  if VersionText = 'file' then
    Exit(0);
  if (Length(VersionText) = 4) and (VersionText[1] = 'v') then
    Exit(StrToIntDef(Copy(VersionText, 2, 3), 0));
  raise Exception.CreateFmt('Unsupported XCF version tag: %s', [VersionText]);
end;

function ReadXCFString(AStream: TStream): string;
var
  LengthWithTerminator: Cardinal;
  Bytes: array of Byte;
begin
  LengthWithTerminator := ReadUInt32BE(AStream);
  if LengthWithTerminator = 0 then
    Exit('');
  SetLength(Bytes, LengthWithTerminator);
  AStream.ReadBuffer(Bytes[0], LengthWithTerminator);
  if Bytes[LengthWithTerminator - 1] = 0 then
    SetString(Result, PChar(@Bytes[0]), LengthWithTerminator - 1)
  else
    SetString(Result, PChar(@Bytes[0]), LengthWithTerminator);
end;

procedure ReadImageProperties(AStream: TStream; var AContext: TXCFContext);
var
  PropertyType: Cardinal;
  PropertySize: Cardinal;
  ColorCount: Cardinal;
  BytesToRead: Cardinal;
begin
  while True do
  begin
    PropertyType := ReadUInt32BE(AStream);
    PropertySize := ReadUInt32BE(AStream);
    if PropertyType = PROP_END then
      Exit;

    case PropertyType of
      PROP_COMPRESSION:
        begin
          if PropertySize > 0 then
          begin
            AContext.Compression := ReadByteValue(AStream);
            SkipBytes(AStream, PropertySize - 1);
          end;
        end;
      PROP_COLORMAP:
        begin
          if PropertySize >= 4 then
          begin
            ColorCount := ReadUInt32BE(AStream);
            BytesToRead := Min(ColorCount * 3, PropertySize - 4);
            SetLength(AContext.ColorMap, BytesToRead);
            if BytesToRead > 0 then
              AStream.ReadBuffer(AContext.ColorMap[0], BytesToRead);
            SkipBytes(AStream, PropertySize - 4 - BytesToRead);
          end
          else
            SkipBytes(AStream, PropertySize);
        end;
    else
      SkipBytes(AStream, PropertySize);
    end;
  end;
end;

function ReadPointerArray(AStream: TStream; APointerSize: Integer): TInt64Array;
var
  PointerValue: Int64;
  Values: TInt64Array;
begin
  SetLength(Values, 0);
  while True do
  begin
    PointerValue := ReadPointerValue(AStream, APointerSize);
    if PointerValue = 0 then
      Break;
    SetLength(Values, Length(Values) + 1);
    Values[High(Values)] := PointerValue;
  end;
  Result := Values;
end;

procedure ReadLayerProperties(AStream: TStream; var ALayer: TXCFLayerInfo);
var
  PropertyType: Cardinal;
  PropertySize: Cardinal;
begin
  while True do
  begin
    PropertyType := ReadUInt32BE(AStream);
    PropertySize := ReadUInt32BE(AStream);
    if PropertyType = PROP_END then
      Exit;

    case PropertyType of
      PROP_OPACITY:
        begin
          if PropertySize >= 4 then
          begin
            ALayer.Opacity := EnsureRange(ReadUInt32BE(AStream), 0, 255);
            SkipBytes(AStream, PropertySize - 4);
          end
          else
            SkipBytes(AStream, PropertySize);
        end;
      PROP_VISIBLE:
        begin
          if PropertySize >= 4 then
          begin
            ALayer.Visible := ReadUInt32BE(AStream) <> 0;
            SkipBytes(AStream, PropertySize - 4);
          end
          else
            SkipBytes(AStream, PropertySize);
        end;
      PROP_OFFSETS:
        begin
          if PropertySize >= 8 then
          begin
            ALayer.OffsetX := ReadInt32BE(AStream);
            ALayer.OffsetY := ReadInt32BE(AStream);
            SkipBytes(AStream, PropertySize - 8);
          end
          else
            SkipBytes(AStream, PropertySize);
        end;
      PROP_GROUP_ITEM:
        begin
          ALayer.IsGroup := True;
          SkipBytes(AStream, PropertySize);
        end;
    else
      SkipBytes(AStream, PropertySize);
    end;
  end;
end;

function ReadLayerInfo(AStream: TStream; const AContext: TXCFContext; AOffset: Int64): TXCFLayerInfo;
var
  IgnoredPointer: Int64;
begin
  AStream.Position := AOffset;
  Result.Width := ReadUInt32BE(AStream);
  Result.Height := ReadUInt32BE(AStream);
  Result.LayerType := ReadUInt32BE(AStream);
  ReadXCFString(AStream);
  Result.OffsetX := 0;
  Result.OffsetY := 0;
  Result.Visible := True;
  Result.Opacity := 255;
  Result.IsGroup := False;
  ReadLayerProperties(AStream, Result);
  Result.HierarchyOffset := ReadPointerValue(AStream, AContext.PointerSize);
  IgnoredPointer := ReadPointerValue(AStream, AContext.PointerSize);
  if AContext.Version >= 20 then
    repeat
      IgnoredPointer := ReadPointerValue(AStream, AContext.PointerSize);
    until IgnoredPointer = 0;
end;

function BytesPerPixelForLayerType(ALayerType: Cardinal): Integer;
begin
  case ALayerType of
    GIMP_RGB_IMAGE:
      Result := 3;
    GIMP_RGBA_IMAGE:
      Result := 4;
    GIMP_GRAY_IMAGE:
      Result := 1;
    GIMP_GRAYA_IMAGE:
      Result := 2;
    GIMP_INDEXED_IMAGE:
      Result := 1;
    GIMP_INDEXEDA_IMAGE:
      Result := 2;
  else
    Result := 0;
  end;
end;

function DecodeRLEChannel(AStream: TStream; AExpectedCount: Integer): TBytes;
var
  ControlByte: Byte;
  RepeatByte: Byte;
  RunLength: Integer;
  OutputIndex: Integer;
  Decoded: TBytes;
begin
  SetLength(Decoded, AExpectedCount);
  OutputIndex := 0;
  while OutputIndex < AExpectedCount do
  begin
    ControlByte := ReadByteValue(AStream);
    if ControlByte <= 126 then
    begin
      RunLength := ControlByte + 1;
      if OutputIndex + RunLength > AExpectedCount then
        raise Exception.Create('Invalid XCF RLE literal run');
      AStream.ReadBuffer(Decoded[OutputIndex], RunLength);
      Inc(OutputIndex, RunLength);
    end
    else if ControlByte = 127 then
    begin
      RunLength := ReadUInt16BE(AStream);
      if OutputIndex + RunLength > AExpectedCount then
        raise Exception.Create('Invalid XCF long literal run');
      AStream.ReadBuffer(Decoded[OutputIndex], RunLength);
      Inc(OutputIndex, RunLength);
    end
    else if ControlByte = 128 then
    begin
      RunLength := ReadUInt16BE(AStream);
      RepeatByte := ReadByteValue(AStream);
      if OutputIndex + RunLength > AExpectedCount then
        raise Exception.Create('Invalid XCF long repeat run');
      FillByte(Decoded[OutputIndex], RunLength, RepeatByte);
      Inc(OutputIndex, RunLength);
    end
    else
    begin
      RunLength := 256 - ControlByte;
      RepeatByte := ReadByteValue(AStream);
      if OutputIndex + RunLength > AExpectedCount then
        raise Exception.Create('Invalid XCF repeat run');
      FillByte(Decoded[OutputIndex], RunLength, RepeatByte);
      Inc(OutputIndex, RunLength);
    end;
  end;
  Result := Decoded;
end;

function DecodeTileBytes(
  AStream: TStream;
  ATileOffset: Int64;
  APixelCount: Integer;
  ABytesPerPixel: Integer;
  ACompression: Byte
): TBytes;
var
  ChannelIndex: Integer;
  PixelIndex: Integer;
  ChannelData: array of Byte;
  Decoded: TBytes;
begin
  AStream.Position := ATileOffset;
  SetLength(Decoded, APixelCount * ABytesPerPixel);
  case ACompression of
    COMPRESS_NONE:
      if Length(Decoded) > 0 then
        AStream.ReadBuffer(Decoded[0], Length(Decoded));
    COMPRESS_RLE:
      begin
        for ChannelIndex := 0 to ABytesPerPixel - 1 do
        begin
          ChannelData := DecodeRLEChannel(AStream, APixelCount);
          for PixelIndex := 0 to APixelCount - 1 do
            Decoded[(PixelIndex * ABytesPerPixel) + ChannelIndex] := ChannelData[PixelIndex];
        end;
      end;
  else
    raise Exception.CreateFmt('Unsupported XCF compression: %d', [ACompression]);
  end;
  Result := Decoded;
end;

function PixelFromLayerBytes(
  const ABytes: array of Byte;
  APixelIndex: Integer;
  ALayerType: Cardinal;
  const AColorMap: array of Byte
): TRGBA32;
var
  ByteIndex: Integer;
  PaletteIndex: Integer;
  GrayValue: Byte;
begin
  ByteIndex := APixelIndex * BytesPerPixelForLayerType(ALayerType);
  case ALayerType of
    GIMP_RGB_IMAGE:
      Result := RGBA(ABytes[ByteIndex], ABytes[ByteIndex + 1], ABytes[ByteIndex + 2], 255);
    GIMP_RGBA_IMAGE:
      Result := RGBA(ABytes[ByteIndex], ABytes[ByteIndex + 1], ABytes[ByteIndex + 2], ABytes[ByteIndex + 3]);
    GIMP_GRAY_IMAGE:
      begin
        GrayValue := ABytes[ByteIndex];
        Result := RGBA(GrayValue, GrayValue, GrayValue, 255);
      end;
    GIMP_GRAYA_IMAGE:
      begin
        GrayValue := ABytes[ByteIndex];
        Result := RGBA(GrayValue, GrayValue, GrayValue, ABytes[ByteIndex + 1]);
      end;
    GIMP_INDEXED_IMAGE:
      begin
        PaletteIndex := ABytes[ByteIndex] * 3;
        if PaletteIndex + 2 >= Length(AColorMap) then
          Exit(TransparentColor);
        Result := RGBA(AColorMap[PaletteIndex], AColorMap[PaletteIndex + 1], AColorMap[PaletteIndex + 2], 255);
      end;
    GIMP_INDEXEDA_IMAGE:
      begin
        PaletteIndex := ABytes[ByteIndex] * 3;
        if PaletteIndex + 2 >= Length(AColorMap) then
          Exit(TransparentColor);
        Result := RGBA(
          AColorMap[PaletteIndex],
          AColorMap[PaletteIndex + 1],
          AColorMap[PaletteIndex + 2],
          ABytes[ByteIndex + 1]
        );
      end;
  else
    Result := TransparentColor;
  end;
end;

procedure BlendStraightPixel(ATarget: TRasterSurface; X, Y: Integer; const ASource: TRGBA32; AOpacity: Byte);
var
  Destination: TRGBA32;
  SourceAlpha: Double;
  DestinationAlpha: Double;
  OutputAlpha: Double;
  SourceWeight: Double;
  DestinationWeight: Double;
begin
  if not ATarget.InBounds(X, Y) then
    Exit;
  SourceAlpha := (ASource.A * AOpacity) / (255.0 * 255.0);
  if SourceAlpha <= 0.0 then
    Exit;

  Destination := ATarget[X, Y];
  DestinationAlpha := Destination.A / 255.0;
  OutputAlpha := SourceAlpha + (DestinationAlpha * (1.0 - SourceAlpha));
  if OutputAlpha <= 0.0 then
    Exit;

  SourceWeight := SourceAlpha / OutputAlpha;
  DestinationWeight := (DestinationAlpha * (1.0 - SourceAlpha)) / OutputAlpha;
  ATarget[X, Y] := RGBA(
    EnsureRange(Round((ASource.R * SourceWeight) + (Destination.R * DestinationWeight)), 0, 255),
    EnsureRange(Round((ASource.G * SourceWeight) + (Destination.G * DestinationWeight)), 0, 255),
    EnsureRange(Round((ASource.B * SourceWeight) + (Destination.B * DestinationWeight)), 0, 255),
    EnsureRange(Round(OutputAlpha * 255.0), 0, 255)
  );
end;

function DecodeLayerSurface(AStream: TStream; const AContext: TXCFContext; const ALayer: TXCFLayerInfo): TRasterSurface;
var
  HierarchyWidth: Integer;
  HierarchyHeight: Integer;
  BytesPerPixel: Integer;
  LevelOffset: Int64;
  TilePointers: TInt64Array;
  TileIndex: Integer;
  TileX: Integer;
  TileY: Integer;
  TileWidth: Integer;
  TileHeight: Integer;
  PixelCount: Integer;
  TileBytes: TBytes;
  PixelIndex: Integer;
  LocalX: Integer;
  LocalY: Integer;
begin
  Result := TRasterSurface.Create(ALayer.Width, ALayer.Height);
  Result.Clear(TransparentColor);
  if ALayer.HierarchyOffset = 0 then
    Exit;

  BytesPerPixel := BytesPerPixelForLayerType(ALayer.LayerType);
  if BytesPerPixel = 0 then
    raise Exception.CreateFmt('Unsupported XCF layer type: %d', [ALayer.LayerType]);

  AStream.Position := ALayer.HierarchyOffset;
  HierarchyWidth := ReadUInt32BE(AStream);
  HierarchyHeight := ReadUInt32BE(AStream);
  if (HierarchyWidth <> ALayer.Width) or (HierarchyHeight <> ALayer.Height) then
    raise Exception.Create('XCF hierarchy dimensions do not match layer dimensions');
  if ReadUInt32BE(AStream) <> Cardinal(BytesPerPixel) then
    raise Exception.Create('Unsupported XCF bytes-per-pixel layout');

  LevelOffset := ReadPointerValue(AStream, AContext.PointerSize);
  if LevelOffset = 0 then
    Exit;

  AStream.Position := LevelOffset;
  ReadUInt32BE(AStream);
  ReadUInt32BE(AStream);
  TilePointers := ReadPointerArray(AStream, AContext.PointerSize);

  for TileIndex := 0 to High(TilePointers) do
  begin
    TileY := TileIndex div Max(1, (ALayer.Width + 63) div 64);
    TileX := TileIndex mod Max(1, (ALayer.Width + 63) div 64);
    TileWidth := Min(64, ALayer.Width - (TileX * 64));
    TileHeight := Min(64, ALayer.Height - (TileY * 64));
    PixelCount := TileWidth * TileHeight;
    TileBytes := DecodeTileBytes(AStream, TilePointers[TileIndex], PixelCount, BytesPerPixel, AContext.Compression);

    for PixelIndex := 0 to PixelCount - 1 do
    begin
      LocalX := (TileX * 64) + (PixelIndex mod TileWidth);
      LocalY := (TileY * 64) + (PixelIndex div TileWidth);
      Result[LocalX, LocalY] := PixelFromLayerBytes(TileBytes, PixelIndex, ALayer.LayerType, AContext.ColorMap);
    end;
  end;
end;

function TryLoadFlattenedXCFSurface(const AFileName: string; out ASurface: TRasterSurface): Boolean;
var
  Stream: TFileStream;
  MagicBytes: array[0..Length(XCFMagic) - 1] of Byte;
  MagicText: string;
  Context: TXCFContext;
  LayerOffsets: TInt64Array;
  LayerIndex: Integer;
  LayerInfo: TXCFLayerInfo;
  LayerSurface: TRasterSurface;
  X: Integer;
  Y: Integer;
  Pixel: TRGBA32;
begin
  Result := False;
  ASurface := nil;
  if not FileExists(AFileName) then
    Exit;

  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Size < 32 then
      Exit;

    Stream.ReadBuffer(MagicBytes, SizeOf(MagicBytes));
    SetString(MagicText, PChar(@MagicBytes[0]), Length(XCFMagic));
    if MagicText <> XCFMagic then
      Exit;

    FillChar(Context, SizeOf(Context), 0);
    Context.Version := ReadXCFVersion(Stream);
    if Context.Version >= 11 then
      Context.PointerSize := 8
    else
      Context.PointerSize := 4;
    Context.Width := ReadUInt32BE(Stream);
    Context.Height := ReadUInt32BE(Stream);
    ReadUInt32BE(Stream);
    if Context.Version >= 4 then
      Context.Precision := ReadUInt32BE(Stream)
    else
      Context.Precision := 150;
    if (Context.Precision <> 100) and (Context.Precision <> 150) then
      raise Exception.CreateFmt('Unsupported XCF precision: %d', [Context.Precision]);

    ReadImageProperties(Stream, Context);
    LayerOffsets := ReadPointerArray(Stream, Context.PointerSize);
    ReadPointerArray(Stream, Context.PointerSize);
    if Context.Version >= 11 then
      ReadPointerArray(Stream, Context.PointerSize);

    ASurface := TRasterSurface.Create(Context.Width, Context.Height);
    ASurface.Clear(TransparentColor);

    for LayerIndex := High(LayerOffsets) downto Low(LayerOffsets) do
    begin
      LayerInfo := ReadLayerInfo(Stream, Context, LayerOffsets[LayerIndex]);
      if (not LayerInfo.Visible) or LayerInfo.IsGroup or (LayerInfo.HierarchyOffset = 0) then
        Continue;

      LayerSurface := DecodeLayerSurface(Stream, Context, LayerInfo);
      try
        for Y := 0 to LayerSurface.Height - 1 do
          for X := 0 to LayerSurface.Width - 1 do
          begin
            Pixel := LayerSurface[X, Y];
            if Pixel.A = 0 then
              Continue;
            BlendStraightPixel(ASurface, X + LayerInfo.OffsetX, Y + LayerInfo.OffsetY, Pixel, LayerInfo.Opacity);
          end;
      finally
        LayerSurface.Free;
      end;
    end;

    Result := True;
  except
    FreeAndNil(ASurface);
    Result := False;
  end;
  Stream.Free;
end;

function LoadFlattenedXCFSurface(const AFileName: string): TRasterSurface;
begin
  if not TryLoadFlattenedXCFSurface(AFileName, Result) then
    raise Exception.Create('Unsupported or unreadable XCF file');
end;

end.
