unit FPToolbarHelpers;

{$mode objfpc}{$H+}

interface

uses
  Types;

const
  DefaultToolbarHostWidth = 1360;

  TopToolbarHeight = 84;
  ToolbarTitleBandHeight = 24;
  ToolbarTitleRailWidth = 72;
  ToolbarTitleDotLeft = 12;
  ToolbarTitleDotTop = 8;
  ToolbarTitleDotSize = 10;
  ToolbarTitleDotStride = 16;

  ToolbarRowTop = 24;
  ToolbarRowHeight = 30;
  ToolbarButtonHeight = 28;
  ToolbarCompactButtonWidth = 26;
  ToolbarUtilityButtonWidth = 24;

  ToolbarLeftMargin = 8;
  ToolbarRightMargin = 12;
  ToolbarSectionGap = 8;

  ToolbarFileGroupWidth = 242;
  ToolbarEditGroupWidth = 92;
  ToolbarUndoGroupWidth = 64;
  ToolbarPaletteGroupWidth = 122;
  ToolbarZoomGroupWidth = 156;

  ToolbarDividerWidth = 1;
  ToolbarDividerHeight = 22;
  ToolbarDividerTopOffset = 4;

  ToolbarOptionRowTop = 56;
  ToolbarOptionLabelTop = 60;
  ToolbarOptionCheckTop = 59;

  ToolbarZoomButtonInsetLeft = 6;
  ToolbarZoomButtonTop = 2;
  ToolbarZoomButtonWidth = 26;
  ToolbarZoomComboLeft = 38;
  ToolbarZoomComboTop = 2;
  ToolbarZoomComboWidth = 84;
  ToolbarZoomComboHeight = 24;
  ToolbarZoomInButtonLeft = 128;

function ToolbarFileGroupRect: TRect;
function ToolbarEditGroupRect: TRect;
function ToolbarUndoGroupRect: TRect;
function ToolbarPaletteGroupRect(AHostWidth: Integer = DefaultToolbarHostWidth): TRect;
function ToolbarZoomGroupRect(AHostWidth: Integer = DefaultToolbarHostWidth): TRect;
function ToolbarDividerAfterRect(const AGroupRect: TRect): TRect;
function ToolbarZoomOutButtonRect(const AZoomGroupRect: TRect): TRect;
function ToolbarZoomComboRect(const AZoomGroupRect: TRect): TRect;
function ToolbarZoomInButtonRect(const AZoomGroupRect: TRect): TRect;

implementation

function MakeRect(ALeft, ATop, AWidth, AHeight: Integer): TRect;
begin
  Result := Rect(ALeft, ATop, ALeft + AWidth, ATop + AHeight);
end;

function ToolbarFileGroupRect: TRect;
begin
  Result := MakeRect(ToolbarLeftMargin, ToolbarRowTop, ToolbarFileGroupWidth, ToolbarRowHeight);
end;

function ToolbarEditGroupRect: TRect;
var
  PrevRect: TRect;
begin
  PrevRect := ToolbarFileGroupRect;
  Result := MakeRect(PrevRect.Right + ToolbarSectionGap, ToolbarRowTop, ToolbarEditGroupWidth, ToolbarRowHeight);
end;

function ToolbarUndoGroupRect: TRect;
var
  PrevRect: TRect;
begin
  PrevRect := ToolbarEditGroupRect;
  Result := MakeRect(PrevRect.Right + ToolbarSectionGap, ToolbarRowTop, ToolbarUndoGroupWidth, ToolbarRowHeight);
end;

function ToolbarZoomGroupRect(AHostWidth: Integer): TRect;
begin
  Result := MakeRect(
    AHostWidth - ToolbarRightMargin - ToolbarZoomGroupWidth,
    ToolbarRowTop,
    ToolbarZoomGroupWidth,
    ToolbarRowHeight
  );
end;

function ToolbarPaletteGroupRect(AHostWidth: Integer): TRect;
var
  ZoomRect: TRect;
begin
  ZoomRect := ToolbarZoomGroupRect(AHostWidth);
  Result := MakeRect(
    ZoomRect.Left - ToolbarSectionGap - ToolbarPaletteGroupWidth,
    ToolbarRowTop,
    ToolbarPaletteGroupWidth,
    ToolbarRowHeight
  );
end;

function ToolbarDividerAfterRect(const AGroupRect: TRect): TRect;
begin
  Result := MakeRect(
    AGroupRect.Right + (ToolbarSectionGap div 2),
    ToolbarRowTop + ToolbarDividerTopOffset,
    ToolbarDividerWidth,
    ToolbarDividerHeight
  );
end;

function ToolbarZoomOutButtonRect(const AZoomGroupRect: TRect): TRect;
begin
  Result := MakeRect(
    AZoomGroupRect.Left + ToolbarZoomButtonInsetLeft,
    AZoomGroupRect.Top + ToolbarZoomButtonTop,
    ToolbarZoomButtonWidth,
    ToolbarButtonHeight
  );
end;

function ToolbarZoomComboRect(const AZoomGroupRect: TRect): TRect;
begin
  Result := MakeRect(
    AZoomGroupRect.Left + ToolbarZoomComboLeft,
    AZoomGroupRect.Top + ToolbarZoomComboTop,
    ToolbarZoomComboWidth,
    ToolbarZoomComboHeight
  );
end;

function ToolbarZoomInButtonRect(const AZoomGroupRect: TRect): TRect;
begin
  Result := MakeRect(
    AZoomGroupRect.Left + ToolbarZoomInButtonLeft,
    AZoomGroupRect.Top + ToolbarZoomButtonTop,
    ToolbarZoomButtonWidth,
    ToolbarButtonHeight
  );
end;

end.
