program FlatPaintTests;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  cwstring,
{$endif}
  fpcunit, testregistry, consoletestrunner, SysUtils,
  fpsurface_tests, fpuihelpers_tests, fpdocument_tests, fpselection_tests, fppalettehelpers_tests,
  fpio_tests, fpnewimagehelpers_tests, fputilityhelpers_tests,
  cli_integration_tests, integration_document_flow_tests, integration_native_roundtrip_tests,
  fprulerhelpers_tests, fpzoomhelpers_tests, fpviewhelpers_tests,
  fpcurveshelpers_tests, fpposterizehelpers_tests, fpblurhelpers_tests,
  fpnoisehelpers_tests, fphuesaturationhelpers_tests, fplevelshelpers_tests,
  fpbrightnesscontrasthelpers_tests, fpresizehelpers_tests, fpviewporthelpers_tests,
  fpstatushelpers_tests, fpfilemenuhelpers_tests;

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
