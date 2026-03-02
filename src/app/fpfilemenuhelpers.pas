unit FPFileMenuHelpers;

{$mode objfpc}{$H+}

interface

type
  TAcquireMode = (
    amClipboard,
    amOpenFile
  );

function ResolveAcquireMode(AHasClipboardImage: Boolean): TAcquireMode;
function SaveAllFallsBackToSaveAs(const ACurrentFileName: string): Boolean;

implementation

uses
  SysUtils;

function ResolveAcquireMode(AHasClipboardImage: Boolean): TAcquireMode;
begin
  if AHasClipboardImage then
    Result := amClipboard
  else
    Result := amOpenFile;
end;

function SaveAllFallsBackToSaveAs(const ACurrentFileName: string): Boolean;
begin
  Result := Trim(ACurrentFileName) = '';
end;

end.
