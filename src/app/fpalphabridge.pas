unit FPAlphaBridge;

{$mode objfpc}{$H+}

interface

{$LINKLIB objc}

{ Set the Cocoa NSView alpha value for the control whose platform handle is
  ANSViewHandle.  AAlpha must be in the range [0.0 .. 1.0]:
    1.0 = fully opaque (normal)
    0.0 = fully invisible
  Values outside the range are clamped by AppKit. }
procedure FPSetViewAlpha(ANSViewHandle: Pointer; AAlpha: Double); cdecl;

implementation

{$IFDEF TESTING}
procedure FPSetViewAlpha(ANSViewHandle: Pointer; AAlpha: Double); cdecl;
begin
  { no-op in headless test environment }
end;
{$ELSE}
procedure FPSetViewAlpha(ANSViewHandle: Pointer; AAlpha: Double); cdecl; external;

{$LINK fp_alpha.o}
{$ENDIF}

end.
