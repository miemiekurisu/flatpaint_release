unit FPTabHelpers;

{$mode objfpc}{$H+}

interface

function TabStripInset: Integer;
function TabStripHeight: Integer;
function TabCardWidth: Integer;
function TabCardHeight: Integer;
function TabCardSpacing: Integer;
function TabThumbnailWidth: Integer;
function TabThumbnailHeight: Integer;
function TabCardLeft(AIndex: Integer): Integer;
function TabDropIndexAtX(AX, ACount: Integer): Integer;
function MoveIndexAfterReorder(AActiveIndex, AFromIndex, AToIndex: Integer): Integer;

implementation

uses
  Math;

function TabStripInset: Integer;
begin
  Result := 4;
end;

function TabStripHeight: Integer;
begin
  Result := 52;
end;

function TabCardWidth: Integer;
begin
  Result := 170;
end;

function TabCardHeight: Integer;
begin
  Result := 44;
end;

function TabCardSpacing: Integer;
begin
  Result := 4;
end;

function TabThumbnailWidth: Integer;
begin
  Result := 40;
end;

function TabThumbnailHeight: Integer;
begin
  Result := 28;
end;

function TabCardLeft(AIndex: Integer): Integer;
begin
  Result := TabStripInset + (Max(0, AIndex) * (TabCardWidth + TabCardSpacing));
end;

function TabDropIndexAtX(AX, ACount: Integer): Integer;
var
  SlotWidth: Integer;
begin
  if ACount <= 0 then
    Exit(0);
  SlotWidth := TabCardWidth + TabCardSpacing;
  Result := EnsureRange(
    (AX - TabStripInset + (SlotWidth div 2)) div Max(1, SlotWidth),
    0,
    ACount - 1
  );
end;

function MoveIndexAfterReorder(AActiveIndex, AFromIndex, AToIndex: Integer): Integer;
begin
  Result := AActiveIndex;
  if (AFromIndex = AToIndex) or (AFromIndex < 0) or (AToIndex < 0) then
    Exit;

  if AActiveIndex = AFromIndex then
    Exit(AToIndex);

  if AFromIndex < AToIndex then
  begin
    if (AActiveIndex > AFromIndex) and (AActiveIndex <= AToIndex) then
      Dec(Result);
  end
  else
  begin
    if (AActiveIndex >= AToIndex) and (AActiveIndex < AFromIndex) then
      Inc(Result);
  end;
end;

end.
