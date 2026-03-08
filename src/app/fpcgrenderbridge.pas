unit FPCGRenderBridge;

{$mode objfpc}{$H+}

interface

{$LINKLIB objc}

{ Core Graphics anti-aliased rendering bridge.

  All functions render directly into a premultiplied BGRA pixel buffer
  (matching TRasterSurface.RawPixels layout). Color values r/g/b/a are
  straight-alpha 0-255; CG handles premultiplication internally.

  The buffer format is kCGImageAlphaPremultipliedFirst with byte order
  32Little, which is the native TRGBA32 layout (B, G, R, A). }

{ Render a filled ellipse with CG anti-aliasing.
  cx,cy = center; rx,ry = radii. }
procedure FPCGRenderFilledEllipse(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  ACX, ACY, ARX, ARY: Double;
  AR, AG, AB, AA: LongInt); cdecl;

{ Render a stroked ellipse with CG anti-aliasing. }
procedure FPCGRenderStrokedEllipse(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  ACX, ACY, ARX, ARY: Double;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl;

{ Render a filled polygon path with CG anti-aliasing.
  APointsXY = interleaved doubles [x0,y0, x1,y1, ...].
  ACount = number of points (array has ACount*2 doubles). }
procedure FPCGRenderFilledPath(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  APointsXY: PDouble; ACount: LongInt;
  AR, AG, AB, AA: LongInt); cdecl;

{ Render a stroked cubic Bezier curve with CG anti-aliasing. }
procedure FPCGRenderStrokedBezier(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  AX1, AY1, ACX1, ACY1, ACX2, ACY2, AX2, AY2: Double;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl;

{ Render a stroked polyline with CG anti-aliasing.
  If AClosed <> 0, the path is closed. }
procedure FPCGRenderStrokedPath(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  APointsXY: PDouble; ACount: LongInt; AClosed: LongInt;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl;

implementation

{$IFDEF TESTING}
procedure FPCGRenderFilledEllipse(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  ACX, ACY, ARX, ARY: Double;
  AR, AG, AB, AA: LongInt); cdecl;
begin
  { no-op in headless test environment }
end;

procedure FPCGRenderStrokedEllipse(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  ACX, ACY, ARX, ARY: Double;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl;
begin
  { no-op in headless test environment }
end;

procedure FPCGRenderFilledPath(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  APointsXY: PDouble; ACount: LongInt;
  AR, AG, AB, AA: LongInt); cdecl;
begin
  { no-op in headless test environment }
end;

procedure FPCGRenderStrokedBezier(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  AX1, AY1, ACX1, ACY1, ACX2, ACY2, AX2, AY2: Double;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl;
begin
  { no-op in headless test environment }
end;

procedure FPCGRenderStrokedPath(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  APointsXY: PDouble; ACount: LongInt; AClosed: LongInt;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl;
begin
  { no-op in headless test environment }
end;

{$ELSE}
procedure FPCGRenderFilledEllipse(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  ACX, ACY, ARX, ARY: Double;
  AR, AG, AB, AA: LongInt); cdecl; external;

procedure FPCGRenderStrokedEllipse(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  ACX, ACY, ARX, ARY: Double;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl; external;

procedure FPCGRenderFilledPath(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  APointsXY: PDouble; ACount: LongInt;
  AR, AG, AB, AA: LongInt); cdecl; external;

procedure FPCGRenderStrokedBezier(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  AX1, AY1, ACX1, ACY1, ACX2, ACY2, AX2, AY2: Double;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl; external;

procedure FPCGRenderStrokedPath(APixelBuffer: Pointer;
  AWidth, AHeight: LongInt;
  APointsXY: PDouble; ACount: LongInt; AClosed: LongInt;
  AStrokeWidth: Double;
  AR, AG, AB, AA: LongInt); cdecl; external;

{$LINK fp_cgrender.o}
{$ENDIF}

end.
