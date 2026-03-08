unit FPMenuHelpers;

{$mode objfpc}{$H+}

interface

function ShouldCreateExplicitApplicationMenu: Boolean;

implementation

function ShouldCreateExplicitApplicationMenu: Boolean;
begin
  {$IFDEF DARWIN}
  Result := False;
  {$ELSE}
  Result := True;
  {$ENDIF}
end;

end.
