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
function TabAddButtonWidth: Integer;
function TabCardLeft(AIndex: Integer): Integer;
function TabContentWidth(ATabCount: Integer): Integer;
function TabDropIndexAtX(AX, ACount: Integer): Integer;
function ScrollPositionForVisibleTab(AIndex, AViewportWidth, ACurrentScroll, ATabCount: Integer): Integer;
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

function TabAddButtonWidth: Integer;
begin
  Result := 24;
end;

function TabCardLeft(AIndex: Integer): Integer;
begin
  Result := TabStripInset + (Max(0, AIndex) * (TabCardWidth + TabCardSpacing));
end;

function TabContentWidth(ATabCount: Integer): Integer;
begin
  Result := TabCardLeft(Max(0, ATabCount)) + TabAddButtonWidth + TabStripInset;
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

function ScrollPositionForVisibleTab(AIndex, AViewportWidth, ACurrentScroll, ATabCount: Integer): Integer;
var
  TabLeft: Integer;
  TabRight: Integer;
  MaxScroll: Integer;
begin
  if (ATabCount <= 0) or (AViewportWidth <= 0) then
    Exit(0);

  TabLeft := TabCardLeft(EnsureRange(AIndex, 0, ATabCount - 1));
  TabRight := TabLeft + TabCardWidth;
  MaxScroll := Max(0, TabContentWidth(ATabCount) - AViewportWidth);

  Result := EnsureRange(ACurrentScroll, 0, MaxScroll);
  if TabLeft < Result then
    Result := TabLeft
  else if TabRight > Result + AViewportWidth then
    Result := TabRight - AViewportWidth;
  Result := EnsureRange(Result, 0, MaxScroll);
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
