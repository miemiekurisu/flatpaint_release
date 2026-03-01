unit FPViewHelpers;

{$mode objfpc}{$H+}

interface

function PixelGridMinScale: Double;
function PixelGridColor: LongInt;
function ShouldRenderPixelGrid(AEnabled: Boolean; AScale: Double): Boolean;

implementation

function PixelGridMinScale: Double;
begin
  Result := 8.0;
end;

function PixelGridColor: LongInt;
begin
  Result := $009A9A9A;
end;

function ShouldRenderPixelGrid(AEnabled: Boolean; AScale: Double): Boolean;
begin
  Result := AEnabled and (AScale >= PixelGridMinScale);
end;

end.
