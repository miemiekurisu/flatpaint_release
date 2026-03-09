unit FPAppearanceBridge;

{$mode objfpc}{$H+}

interface

{ Forces the main window to use NSAppearanceNameAqua (light mode).
  Call once after the main form handle is allocated to ensure all
  native dropdown popups, context menus, and other system controls
  render with a white background / dark text as expected. }
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl;

{ Return the main screen's backing scale factor (e.g. 2.0 on Retina). }
function FPGetScreenBackingScale: Double; cdecl;

{ Set the interpolation quality for the current NSGraphicsContext.
  0 = none (nearest-neighbor), 1 = low, 2 = medium, 3 = high. }
procedure FPSetInterpolationQuality(AQuality: LongInt); cdecl;

{ Draw a marching-ants polyline on the current NSGraphicsContext.
  Two passes: white solid base + black dashed overlay.
  APointsXY = interleaved doubles [x0,y0, x1,y1, ...].
  ACount    = number of points (array has ACount*2 doubles).
  AClosed   = non-zero to close the path. }
procedure FPDrawMarchingAntsPolyline(APointsXY: PDouble; ACount: LongInt;
  ADashLength: Double; ADashPhase: Double; AClosed: LongInt); cdecl;

{ Draw multiple marching-ants contours in a single batched CGPath.
  All contours are combined into one CGPath with multiple subpaths
  and stroked in exactly 2 passes (white + black dash). }
procedure FPDrawMarchingAntsMultiContour(APointsXY: PDouble;
  AContourOffsets, AContourLengths, AClosedFlags: PLongInt;
  AContourCount: LongInt;
  ADashLength: Double; ADashPhase: Double); cdecl;

implementation

{$IFDEF TESTING}
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl;
begin
  { no-op in headless test builds }
end;

function FPGetScreenBackingScale: Double; cdecl;
begin
  Result := 1.0;
end;

procedure FPSetInterpolationQuality(AQuality: LongInt); cdecl;
begin
  { no-op in headless test builds }
end;

procedure FPDrawMarchingAntsPolyline(APointsXY: PDouble; ACount: LongInt;
  ADashLength: Double; ADashPhase: Double; AClosed: LongInt); cdecl;
begin
  { no-op in headless test builds }
end;

procedure FPDrawMarchingAntsMultiContour(APointsXY: PDouble;
  AContourOffsets, AContourLengths, AClosedFlags: PLongInt;
  AContourCount: LongInt;
  ADashLength: Double; ADashPhase: Double); cdecl;
begin
  { no-op in headless test builds }
end;
{$ELSE}
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl; external;
function FPGetScreenBackingScale: Double; cdecl; external;
procedure FPSetInterpolationQuality(AQuality: LongInt); cdecl; external;
procedure FPDrawMarchingAntsPolyline(APointsXY: PDouble; ACount: LongInt;
  ADashLength: Double; ADashPhase: Double; AClosed: LongInt); cdecl; external;
procedure FPDrawMarchingAntsMultiContour(APointsXY: PDouble;
  AContourOffsets, AContourLengths, AClosedFlags: PLongInt;
  AContourCount: LongInt;
  ADashLength: Double; ADashPhase: Double); cdecl; external;

{$LINK fp_appearance.o}
{$ENDIF}

end.
