unit fpclipboardhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpcunit, testregistry, Types, FPClipboardHelpers;

type
  TFPClipboardHelpersTests = class(TTestCase)
  published
    procedure ClipboardSurfaceMetaRoundTripsOffset;
    procedure ClipboardSurfaceMetaRejectsDimensionMismatch;
    procedure ClipboardSurfaceMetaRejectsInvalidSignature;
    procedure PublishBitmapToClipboardWithMetaRejectsInvalidInputs;
  end;

implementation

procedure TFPClipboardHelpersTests.ClipboardSurfaceMetaRoundTripsOffset;
var
  Stream: TMemoryStream;
  OffsetIn: TPoint;
  OffsetOut: TPoint;
begin
  Stream := TMemoryStream.Create;
  try
    OffsetIn := Point(12, 34);
    WriteClipboardSurfaceMeta(Stream, OffsetIn, 128, 96);
    AssertTrue(
      'metadata should parse when dimensions match',
      TryReadClipboardSurfaceMeta(Stream, OffsetOut, 128, 96)
    );
    AssertEquals('offset x roundtrip', OffsetIn.X, OffsetOut.X);
    AssertEquals('offset y roundtrip', OffsetIn.Y, OffsetOut.Y);
  finally
    Stream.Free;
  end;
end;

procedure TFPClipboardHelpersTests.ClipboardSurfaceMetaRejectsDimensionMismatch;
var
  Stream: TMemoryStream;
  OffsetOut: TPoint;
begin
  Stream := TMemoryStream.Create;
  try
    WriteClipboardSurfaceMeta(Stream, Point(5, 6), 64, 64);
    AssertFalse(
      'metadata should be ignored for different dimensions',
      TryReadClipboardSurfaceMeta(Stream, OffsetOut, 65, 64)
    );
  finally
    Stream.Free;
  end;
end;

procedure TFPClipboardHelpersTests.ClipboardSurfaceMetaRejectsInvalidSignature;
var
  Stream: TMemoryStream;
  Bogus: LongWord;
  OffsetOut: TPoint;
begin
  Stream := TMemoryStream.Create;
  try
    Bogus := $11223344;
    Stream.WriteBuffer(Bogus, SizeOf(Bogus));
    Stream.Position := 0;
    AssertFalse(
      'invalid payload should not parse',
      TryReadClipboardSurfaceMeta(Stream, OffsetOut, 1, 1)
    );
  finally
    Stream.Free;
  end;
end;

procedure TFPClipboardHelpersTests.PublishBitmapToClipboardWithMetaRejectsInvalidInputs;
begin
  AssertFalse(
    'nil clipboard should be rejected safely',
    PublishBitmapToClipboardWithMeta(
      nil,
      nil,
      1,
      Point(0, 0),
      1,
      1
    )
  );
  AssertFalse(
    'non-positive dimensions should still be rejected when clipboard/bitmap are nil',
    PublishBitmapToClipboardWithMeta(
      nil,
      nil,
      1,
      Point(0, 0),
      0,
      1
    )
  );
end;

initialization
  RegisterTest(TFPClipboardHelpersTests);
end.
