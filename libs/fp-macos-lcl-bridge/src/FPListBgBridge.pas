unit FPListBgBridge;

{$mode objfpc}{$H+}

interface

{$LINKLIB objc}

{ Set the Cocoa NSScrollView background color for a TListBox whose
  platform handle is ANSViewHandle.  R, G, B are in [0.0 .. 1.0].
  Fixes the black empty-area issue on macOS Cocoa when using
  lbOwnerDrawFixed style with bsNone border. }
procedure FPSetListBackground(ANSViewHandle: Pointer; R, G, B: Double); cdecl;

implementation

{$IFDEF TESTING}
procedure FPSetListBackground(ANSViewHandle: Pointer; R, G, B: Double); cdecl;
begin
  { no-op in headless test environment }
end;
{$ELSE}
procedure FPSetListBackground(ANSViewHandle: Pointer; R, G, B: Double); cdecl; external;

{$LINK fp_listbg.o}
{$ENDIF}

end.
