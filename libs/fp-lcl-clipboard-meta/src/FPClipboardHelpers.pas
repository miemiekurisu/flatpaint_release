unit FPClipboardHelpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, Types, Clipbrd, Graphics, LCLType;

procedure WriteClipboardSurfaceMeta(
  AStream: TStream;
  const AOffset: TPoint;
  AWidth, AHeight: Integer
);
function TryReadClipboardSurfaceMeta(
  AStream: TStream;
  out AOffset: TPoint;
  AExpectedWidth, AExpectedHeight: Integer
): Boolean;
function PublishBitmapToClipboardWithMeta(
  AClipboard: TClipboard;
  ABitmap: TBitmap;
  AMetaFormatID: TClipboardFormat;
  const AOffset: TPoint;
  AWidth, AHeight: Integer
): Boolean;

implementation

const
  ClipboardMetaSignature = Cardinal($54414C46); { 'FLAT' }
  ClipboardMetaVersion = Cardinal(1);

type
  TClipboardSurfaceMeta = packed record
    Signature: Cardinal;
    Version: Cardinal;
    OffsetX: LongInt;
    OffsetY: LongInt;
    Width: LongInt;
    Height: LongInt;
  end;

procedure WriteClipboardSurfaceMeta(
  AStream: TStream;
  const AOffset: TPoint;
  AWidth, AHeight: Integer
);
var
  Meta: TClipboardSurfaceMeta;
begin
  if AStream = nil then
    Exit;
  Meta.Signature := ClipboardMetaSignature;
  Meta.Version := ClipboardMetaVersion;
  Meta.OffsetX := AOffset.X;
  Meta.OffsetY := AOffset.Y;
  Meta.Width := AWidth;
  Meta.Height := AHeight;
  AStream.Size := 0;
  AStream.Position := 0;
  AStream.WriteBuffer(Meta, SizeOf(Meta));
  AStream.Position := 0;
end;

function TryReadClipboardSurfaceMeta(
  AStream: TStream;
  out AOffset: TPoint;
  AExpectedWidth, AExpectedHeight: Integer
): Boolean;
var
  Meta: TClipboardSurfaceMeta;
begin
  Result := False;
  AOffset := Point(0, 0);
  if AStream = nil then
    Exit;
  if AStream.Size < SizeOf(Meta) then
    Exit;
  AStream.Position := 0;
  AStream.ReadBuffer(Meta, SizeOf(Meta));
  if Meta.Signature <> ClipboardMetaSignature then
    Exit;
  if Meta.Version <> ClipboardMetaVersion then
    Exit;
  if (Meta.Width <> AExpectedWidth) or (Meta.Height <> AExpectedHeight) then
    Exit;
  AOffset := Point(Meta.OffsetX, Meta.OffsetY);
  Result := True;
end;

function PublishBitmapToClipboardWithMeta(
  AClipboard: TClipboard;
  ABitmap: TBitmap;
  AMetaFormatID: TClipboardFormat;
  const AOffset: TPoint;
  AWidth, AHeight: Integer
): Boolean;
var
  MetaStream: TMemoryStream;
begin
  Result := False;
  if (AClipboard = nil) or (ABitmap = nil) then
    Exit;
  if (AWidth <= 0) or (AHeight <= 0) then
    Exit;

  MetaStream := TMemoryStream.Create;
  try
    WriteClipboardSurfaceMeta(MetaStream, AOffset, AWidth, AHeight);
    AClipboard.Open;
    try
      AClipboard.Assign(ABitmap);
      Result := AClipboard.HasPictureFormat;
      if AMetaFormatID <> 0 then
      begin
        MetaStream.Position := 0;
        AClipboard.AddFormat(AMetaFormatID, MetaStream);
      end;
    finally
      AClipboard.Close;
    end;
  finally
    MetaStream.Free;
  end;
end;

end.
