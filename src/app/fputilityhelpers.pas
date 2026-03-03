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

implementation

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
      Result := 'Show or hide the Tools window';
    ucHistory:
      Result := 'Show or hide the History window';
    ucLayers:
      Result := 'Show or hide the Layers window';
    ucColors:
      Result := 'Show or hide the Colors window';
    ucSettings:
      Result := 'Open workspace settings';
    ucHelp:
      Result := 'Show quick help and supported formats';
  else
    Result := 'Command';
  end;
end;

end.
