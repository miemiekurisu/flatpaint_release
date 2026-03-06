unit FPNativeIO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FPColor, FPDocument;

procedure SaveNativeDocumentToFile(const AFileName: string; ADocument: TImageDocument);
function LoadNativeDocumentFromFile(const AFileName: string): TImageDocument;

implementation

const
  NativeMagicV1: array[0..6] of Char = ('F', 'P', 'D', 'O', 'C', '0', '1');
  NativeMagicV2: array[0..6] of Char = ('F', 'P', 'D', 'O', 'C', '0', '2');
  NativeMagicV3: array[0..6] of Char = ('F', 'P', 'D', 'O', 'C', '0', '3');
  NativeMagicV4: array[0..6] of Char = ('F', 'P', 'D', 'O', 'C', '0', '4');

procedure WriteInt32(AStream: TStream; AValue: LongInt);
begin
  AStream.WriteBuffer(AValue, SizeOf(AValue));
end;

function ReadInt32(AStream: TStream): LongInt;
begin
  Result := 0;
  AStream.ReadBuffer(Result, SizeOf(Result));
end;

procedure WriteByteValue(AStream: TStream; AValue: Byte);
begin
  AStream.WriteBuffer(AValue, SizeOf(AValue));
end;

function ReadByteValue(AStream: TStream): Byte;
begin
  Result := 0;
  AStream.ReadBuffer(Result, SizeOf(Result));
end;

procedure WriteUTF8String(AStream: TStream; const AValue: string);
var
  Raw: UTF8String;
  LengthValue: LongInt;
begin
  Raw := UTF8String(AValue);
  LengthValue := Length(Raw);
  WriteInt32(AStream, LengthValue);
  if LengthValue > 0 then
    AStream.WriteBuffer(Raw[1], LengthValue);
end;

function ReadUTF8String(AStream: TStream): string;
var
  Raw: UTF8String;
  LengthValue: LongInt;
begin
  LengthValue := ReadInt32(AStream);
  Raw := '';
  SetLength(Raw, LengthValue);
  if LengthValue > 0 then
    AStream.ReadBuffer(Raw[1], LengthValue);
  Result := string(Raw);
end;

procedure SaveNativeDocumentToFile(const AFileName: string; ADocument: TImageDocument);
var
  Stream: TFileStream;
  LayerIndex: Integer;
  X: Integer;
  Y: Integer;
  Pixel: TRGBA32;
  MaskByte: Byte;
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    Stream.WriteBuffer(NativeMagicV4, SizeOf(NativeMagicV4));
    WriteInt32(Stream, ADocument.Width);
    WriteInt32(Stream, ADocument.Height);
    WriteInt32(Stream, ADocument.ActiveLayerIndex);
    WriteInt32(Stream, ADocument.LayerCount);

    for Y := 0 to ADocument.Height - 1 do
      for X := 0 to ADocument.Width - 1 do
      begin
        MaskByte := ADocument.Selection.Coverage(X, Y);
        WriteByteValue(Stream, MaskByte);
      end;

    for LayerIndex := 0 to ADocument.LayerCount - 1 do
    begin
      WriteUTF8String(Stream, ADocument.Layers[LayerIndex].Name);
      if ADocument.Layers[LayerIndex].Visible then
        WriteByteValue(Stream, 1)
      else
        WriteByteValue(Stream, 0);
      WriteByteValue(Stream, ADocument.Layers[LayerIndex].Opacity);
      if ADocument.Layers[LayerIndex].IsBackground then
        WriteByteValue(Stream, 1)
      else
        WriteByteValue(Stream, 0);
      WriteInt32(Stream, ADocument.Layers[LayerIndex].OffsetX);
      WriteInt32(Stream, ADocument.Layers[LayerIndex].OffsetY);

      for Y := 0 to ADocument.Height - 1 do
        for X := 0 to ADocument.Width - 1 do
        begin
          Pixel := ADocument.Layers[LayerIndex].Surface[X, Y];
          Stream.WriteBuffer(Pixel, SizeOf(Pixel));
        end;
    end;
  finally
    Stream.Free;
  end;
end;

function LoadNativeDocumentFromFile(const AFileName: string): TImageDocument;
var
  Stream: TFileStream;
  MagicRead: array[0..6] of Char;
  WidthValue: LongInt;
  HeightValue: LongInt;
  ActiveLayer: LongInt;
  LayerCount: LongInt;
  LayerIndex: Integer;
  X: Integer;
  Y: Integer;
  Pixel: TRGBA32;
  NewLayer: TRasterLayer;
  VisibleByte: Byte;
  BackgroundByte: Byte;
  MaskByte: Byte;
  UsesV2: Boolean;
  UsesV3: Boolean;
  UsesV4: Boolean;
  OffsetX: LongInt;
  OffsetY: LongInt;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Stream.ReadBuffer(MagicRead, SizeOf(MagicRead));
    UsesV4 := CompareMem(@MagicRead[0], @NativeMagicV4[0], SizeOf(NativeMagicV4));
    UsesV3 := CompareMem(@MagicRead[0], @NativeMagicV3[0], SizeOf(NativeMagicV3));
    UsesV2 := CompareMem(@MagicRead[0], @NativeMagicV2[0], SizeOf(NativeMagicV2));
    if (not UsesV4) and (not UsesV3) and (not UsesV2) and
       (CompareMem(@MagicRead[0], @NativeMagicV1[0], SizeOf(NativeMagicV1)) = False) then
      raise Exception.Create('Unsupported native document format');

    WidthValue := ReadInt32(Stream);
    HeightValue := ReadInt32(Stream);
    ActiveLayer := ReadInt32(Stream);
    LayerCount := ReadInt32(Stream);

    if LayerCount <= 0 then
      raise Exception.Create('Native document contains no layers');

    Result := TImageDocument.Create(WidthValue, HeightValue);
    try
      Result.Deselect;
      for Y := 0 to HeightValue - 1 do
        for X := 0 to WidthValue - 1 do
        begin
          MaskByte := ReadByteValue(Stream);
          if UsesV3 or UsesV4 then
            Result.Selection.SetCoverage(X, Y, MaskByte)
          else
            Result.Selection[X, Y] := MaskByte <> 0;
        end;

      for LayerIndex := 0 to LayerCount - 1 do
      begin
        if LayerIndex = 0 then
          NewLayer := Result.Layers[0]
        else
          NewLayer := Result.AddLayer;

        NewLayer.Name := ReadUTF8String(Stream);
        VisibleByte := ReadByteValue(Stream);
        NewLayer.Visible := VisibleByte <> 0;
        NewLayer.Opacity := ReadByteValue(Stream);
        if UsesV2 or UsesV3 or UsesV4 then
          BackgroundByte := ReadByteValue(Stream)
        else
          BackgroundByte := 0;
        NewLayer.IsBackground := BackgroundByte <> 0;
        if UsesV4 then
        begin
          OffsetX := ReadInt32(Stream);
          OffsetY := ReadInt32(Stream);
        end
        else
        begin
          OffsetX := 0;
          OffsetY := 0;
        end;
        NewLayer.OffsetX := OffsetX;
        NewLayer.OffsetY := OffsetY;

        Pixel := TransparentColor;
        for Y := 0 to HeightValue - 1 do
          for X := 0 to WidthValue - 1 do
          begin
            Stream.ReadBuffer(Pixel, SizeOf(Pixel));
            NewLayer.Surface[X, Y] := Pixel;
          end;
      end;

      if (not UsesV2) and (not UsesV3) and (not UsesV4) and (Result.LayerCount > 0) and
         SameText(Result.Layers[0].Name, 'Background') then
        Result.Layers[0].IsBackground := True;

      Result.ActiveLayerIndex := ActiveLayer;
      Result.ClearHistory;
    except
      Result.Free;
      raise;
    end;
  finally
    Stream.Free;
  end;
end;

end.
