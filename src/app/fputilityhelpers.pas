unit FPUtilityHelpers;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

type
  TUtilityCommandKind = (
    ucTools,
    ucHistory,
    ucLayers,
    ucColors,
    ucSettings,
    ucHelp
  );

function UtilityCommandDisplayCount: Integer;
function UtilityCommandAtDisplayIndex(AIndex: Integer): TUtilityCommandKind;
function UtilityCommandGlyph(ACommand: TUtilityCommandKind): string;
function UtilityCommandHint(ACommand: TUtilityCommandKind): string;
function UtilityCommandShortcutLabel(ACommand: TUtilityCommandKind): string;

implementation

uses
  FPPaletteHelpers, FPI18n;

const
  UtilityDisplayOrder: array[0..5] of TUtilityCommandKind = (
    ucTools,
    ucHistory,
    ucLayers,
    ucColors,
    ucSettings,
    ucHelp
  );

function UtilityCommandDisplayCount: Integer;
begin
  Result := Length(UtilityDisplayOrder);
end;

function UtilityCommandAtDisplayIndex(AIndex: Integer): TUtilityCommandKind;
begin
  if AIndex < Low(UtilityDisplayOrder) then
    Exit(UtilityDisplayOrder[Low(UtilityDisplayOrder)]);
  if AIndex > High(UtilityDisplayOrder) then
    Exit(UtilityDisplayOrder[High(UtilityDisplayOrder)]);
  Result := UtilityDisplayOrder[AIndex];
end;

function UtilityCommandGlyph(ACommand: TUtilityCommandKind): string;
begin
  case ACommand of
    ucTools:
      Result := '▦';
    ucHistory:
      Result := '↺';
    ucLayers:
      Result := '▤';
    ucColors:
      Result := '◍';
    ucSettings:
      Result := '⚙';
    ucHelp:
      Result := '?';
  else
    Result := '.';
  end;
end;

function UtilityCommandHint(ACommand: TUtilityCommandKind): string;
begin
  case ACommand of
    ucTools:
      Result := TR('Show or hide the Tools window', '显示或隐藏工具面板');
    ucHistory:
      Result := TR('Show or hide the History window', '显示或隐藏历史面板');
    ucLayers:
      Result := TR('Show or hide the Layers window', '显示或隐藏图层面板');
    ucColors:
      Result := TR('Show or hide the Colors window', '显示或隐藏颜色面板');
    ucSettings:
      Result := TR('Open workspace settings', '打开工作区设置');
    ucHelp:
      Result := TR('Show quick help and supported formats', '显示快捷帮助和支持格式');
  else
    Result := TR('Command', '命令');
  end;
end;

function UtilityCommandShortcutLabel(ACommand: TUtilityCommandKind): string;
begin
  case ACommand of
    ucTools:
      Result := PaletteShortcutLabel(pkTools);
    ucHistory:
      Result := PaletteShortcutLabel(pkHistory);
    ucLayers:
      Result := PaletteShortcutLabel(pkLayers);
    ucColors:
      Result := PaletteShortcutLabel(pkColors);
  else
    Result := '';
  end;
end;

end.
