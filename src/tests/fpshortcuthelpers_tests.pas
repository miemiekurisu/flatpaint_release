unit fpshortcuthelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, Menus, LCLType, FPShortcutHelpers;

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
    ShortCut(VK_C, [ssMeta, ssAlt]),
    CoreShortcut(cscCopySelection)
  );
  AssertEquals(
    'paste into new layer shortcut',
    ShortCut(VK_V, [ssMeta, ssShift]),
    CoreShortcut(cscPasteIntoNewLayer)
  );
  AssertEquals(
    'paste into new image shortcut',
    ShortCut(VK_V, [ssMeta, ssAlt]),
    CoreShortcut(cscPasteIntoNewImage)
  );
  AssertEquals(
    'fill selection shortcut',
    ShortCut(VK_DELETE, [ssShift]),
    CoreShortcut(cscFillSelection)
  );
  AssertEquals(
    'crop to selection shortcut',
    ShortCut(VK_X, [ssMeta, ssAlt]),
    CoreShortcut(cscCropToSelection)
  );

  AssertTrue('copy selection label should be visible', CoreShortcutLabel(cscCopySelection) <> '');
  AssertTrue('paste into new layer label should be visible', CoreShortcutLabel(cscPasteIntoNewLayer) <> '');
  AssertTrue('paste into new image label should be visible', CoreShortcutLabel(cscPasteIntoNewImage) <> '');
end;

initialization
  RegisterTest(TFPShortcutHelpersTests);

end.

