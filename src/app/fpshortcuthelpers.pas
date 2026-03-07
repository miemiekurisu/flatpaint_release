unit FPShortcutHelpers;

{$mode objfpc}{$H+}

interface

uses
  Menus, Controls, LCLType;

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

function CoreShortcut(ACommand: TCoreShortcutCommand): Word;
begin
  case ACommand of
    cscCopySelection:
      Result := ShortCut(VK_C, [ssMeta, ssAlt]);
    cscPasteIntoNewLayer:
      Result := ShortCut(VK_V, [ssMeta, ssShift]);
    cscPasteIntoNewImage:
      Result := ShortCut(VK_V, [ssMeta, ssAlt]);
    cscFillSelection:
      Result := ShortCut(VK_DELETE, [ssShift]);
    cscCropToSelection:
      Result := ShortCut(VK_X, [ssMeta, ssAlt]);
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
