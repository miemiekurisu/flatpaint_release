program FlatPaintTests;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  cwstring,
{$endif}
  fpcunit, testregistry, consoletestrunner,
  fpsurface_tests, fpuihelpers_tests, fpdocument_tests, fppalettehelpers_tests,
  fpio_tests, fpnewimagehelpers_tests, fputilityhelpers_tests,
  fprulerhelpers_tests, fpzoomhelpers_tests, fpviewhelpers_tests,
  fpcurveshelpers_tests, fpposterizehelpers_tests,
  fphuesaturationhelpers_tests, fplevelshelpers_tests,
  fpbrightnesscontrasthelpers_tests,
  fpresizehelpers_tests, fpviewporthelpers_tests, fpstatushelpers_tests;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    DefaultFormat := fPlain;
    DefaultRunAllTests := True;
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
end.
