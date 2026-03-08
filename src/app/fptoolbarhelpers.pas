unit FPToolbarHelpers;

{$mode objfpc}{$H+}

interface

uses
  Types;

const
  DefaultToolbarHostWidth = 1360;

  TopToolbarHeight = 88;         { Title (24) + commands (30) + 2px divider + options bar (32) }
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

  { Options Bar — dedicated 32px row at the bottom of the top panel }
  OptionsBarHeight = 32;
  OptionsBarTop = 56;             { Title (24) + commands (30) + 2px gap }
  OptionsBarIconLeft = 8;
  OptionsBarIconSize = 20;
  OptionsBarIconTop = 6;          { (32 - 20) / 2 }
  OptionsBarToolLabelLeft = 32;   { IconLeft (8) + IconSize (20) + 4px gap }
  OptionsBarDividerGap = 8;
  OptionsBarControlHeight = 20;   { macOS "small" NSPopUpButton / NSTextField height }
  OptionsBarControlTop = 6;       { (32 - 20) / 2 }
  OptionsBarLabelTop = 9;         { (32 - ~13) / 2 for 11pt labels }
  OptionsBarCheckTop = 9;
  OptionsBarFontSize = 11;        { macOS "small" control size — matches combo/spin text }

  { Legacy aliases kept for any external references }
  ToolbarOptionRowTop = 56;
  ToolbarOptionLabelTop = 60;
  ToolbarOptionCheckTop = 60;

  ToolbarZoomButtonInsetLeft = 4;
  ToolbarZoomButtonTop = 2;
  ToolbarZoomButtonWidth = 26;
  ToolbarZoomComboLeft = 36;
  ToolbarZoomComboTop = 3;        { Nudged 1 px up from geometric centre (4) to match macOS NSPopUpButton visual baseline }
  ToolbarZoomComboWidth = 84;
  ToolbarZoomComboHeight = 24;
  ToolbarZoomInButtonLeft = 126;

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
