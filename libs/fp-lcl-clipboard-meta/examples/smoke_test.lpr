program smoke_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  Types,
  FPClipboardHelpers;

var
  Stream: TMemoryStream;
  OffsetIn: TPoint;
  OffsetOut: TPoint;
begin
  Stream := TMemoryStream.Create;
  try
    OffsetIn := Point(12, 24);
    WriteClipboardSurfaceMeta(Stream, OffsetIn, 256, 128);
    if not TryReadClipboardSurfaceMeta(Stream, OffsetOut, 256, 128) then
      raise Exception.Create('meta decode failed');
    if (OffsetOut.X <> OffsetIn.X) or (OffsetOut.Y <> OffsetIn.Y) then
      raise Exception.Create('meta offset mismatch');
  finally
    Stream.Free;
  end;
end.
