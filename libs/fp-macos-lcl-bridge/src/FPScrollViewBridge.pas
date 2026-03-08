unit FPScrollViewBridge;

{$mode objfpc}{$H+}

interface

{$LINKLIB objc}

{ Disable Cocoa NSScrollView elasticity (rubber-band bounce) for the control
  whose platform handle is ANSViewHandle. }
procedure FPDisableScrollElasticity(ANSViewHandle: Pointer); cdecl;

implementation

{$IFDEF TESTING}
procedure FPDisableScrollElasticity(ANSViewHandle: Pointer); cdecl;
begin
  { no-op in headless test builds }
end;
{$ELSE}
procedure FPDisableScrollElasticity(ANSViewHandle: Pointer); cdecl; external;

{$LINK fp_scrollview.o}
{$ENDIF}

end.
