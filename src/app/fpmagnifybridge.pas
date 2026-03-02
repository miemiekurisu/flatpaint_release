unit FPMagnifyBridge;

{$mode objfpc}{$H+}

interface

{$LINKLIB objc}

type
  { Callback signature matching the C typedef in fp_magnify.m }
  TFPMagnifyCallback = procedure(AMagnification: Double;
    ALocationX, ALocationY: Double); cdecl;

{ Install the native magnifyWithEvent: handler on the NSView whose handle
  is ANSViewHandle. ACallback will be invoked on every pinch-to-zoom event. }
procedure FPInstallMagnifyHandler(ANSViewHandle: Pointer;
  ACallback: Pointer); cdecl;

implementation

{$IFDEF TESTING}
procedure FPInstallMagnifyHandler(ANSViewHandle: Pointer; ACallback: Pointer); cdecl;
begin
  { no-op for tests }
end;
{$ELSE}
procedure FPInstallMagnifyHandler(ANSViewHandle: Pointer; ACallback: Pointer); cdecl; external;

{$LINK fp_magnify.o}
{$ENDIF}

end.
