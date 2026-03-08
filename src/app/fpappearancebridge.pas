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
{$ELSE}
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl; external;
function FPGetScreenBackingScale: Double; cdecl; external;
procedure FPSetInterpolationQuality(AQuality: LongInt); cdecl; external;

{$LINK fp_appearance.o}
{$ENDIF}

end.
