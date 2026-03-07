unit fpshortcuthelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, Menus, LCLType, FPShortcutHelpers;

const
  ShortcutShiftFlag = $2000;
  ShortcutAltFlag = $8000;

type
  TFPShortcutHelpersTests = class(TTestCase)
  published
    procedure CoreEditShortcutsFollowPolicy;
  end;

implementation

procedure TFPShortcutHelpersTests.CoreEditShortcutsFollowPolicy;
begin
  AssertEquals(
    'copy selection shortcut',
    VK_C or scMeta or ShortcutAltFlag,
    CoreShortcut(cscCopySelection)
  );
  AssertEquals(
    'paste into new layer shortcut',
    VK_V or scMeta or ShortcutShiftFlag,
    CoreShortcut(cscPasteIntoNewLayer)
  );
  AssertEquals(
    'paste into new image shortcut',
    VK_V or scMeta or ShortcutAltFlag,
    CoreShortcut(cscPasteIntoNewImage)
  );
  AssertEquals(
    'fill selection shortcut',
    VK_DELETE or ShortcutShiftFlag,
    CoreShortcut(cscFillSelection)
  );
  AssertEquals(
    'crop to selection shortcut',
    VK_X or scMeta or ShortcutAltFlag,
    CoreShortcut(cscCropToSelection)
  );

  AssertTrue('copy selection label should be visible', CoreShortcutLabel(cscCopySelection) <> '');
  AssertTrue('paste into new layer label should be visible', CoreShortcutLabel(cscPasteIntoNewLayer) <> '');
  AssertTrue('paste into new image label should be visible', CoreShortcutLabel(cscPasteIntoNewImage) <> '');
end;

initialization
  RegisterTest(TFPShortcutHelpersTests);

end.
