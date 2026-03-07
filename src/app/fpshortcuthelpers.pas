unit FPShortcutHelpers;

{$mode objfpc}{$H+}

interface

uses
  Menus, LCLType;

type
  TCoreShortcutCommand = (
    cscCopySelection,
    cscPasteIntoNewLayer,
    cscPasteIntoNewImage,
    cscFillSelection,
    cscCropToSelection
  );

function CoreShortcut(ACommand: TCoreShortcutCommand): Word;
function CoreShortcutLabel(ACommand: TCoreShortcutCommand): string;

implementation

const
  ShortcutShiftFlag = $2000;
  ShortcutAltFlag = $8000;

function CoreShortcut(ACommand: TCoreShortcutCommand): Word;
begin
  case ACommand of
    cscCopySelection:
      Result := VK_C or scMeta or ShortcutAltFlag;
    cscPasteIntoNewLayer:
      Result := VK_V or scMeta or ShortcutShiftFlag;
    cscPasteIntoNewImage:
      Result := VK_V or scMeta or ShortcutAltFlag;
    cscFillSelection:
      Result := VK_DELETE or ShortcutShiftFlag;
    cscCropToSelection:
      Result := VK_X or scMeta or ShortcutAltFlag;
  else
    Result := 0;
  end;
end;

function CoreShortcutLabel(ACommand: TCoreShortcutCommand): string;
begin
  case ACommand of
    cscCopySelection:
      Result := 'Cmd+Opt+C';
    cscPasteIntoNewLayer:
      Result := 'Cmd+Shift+V';
    cscPasteIntoNewImage:
      Result := 'Cmd+Opt+V';
    cscFillSelection:
      Result := 'Shift+Delete';
    cscCropToSelection:
      Result := 'Cmd+Opt+X';
  else
    Result := '';
  end;
end;

end.
