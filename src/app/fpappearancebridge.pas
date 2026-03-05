unit FPAppearanceBridge;

{$mode objfpc}{$H+}

interface

{ Forces the main window to use NSAppearanceNameAqua (light mode).
  Call once after the main form handle is allocated to ensure all
  native dropdown popups, context menus, and other system controls
  render with a white background / dark text as expected. }
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl;

implementation

{$IFDEF TESTING}
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl;
begin
  { no-op in headless test builds }
end;
{$ELSE}
procedure FPForceAquaAppearance(ANSViewHandle: Pointer); cdecl; external;

{$LINK fp_appearance.o}
{$ENDIF}

end.
