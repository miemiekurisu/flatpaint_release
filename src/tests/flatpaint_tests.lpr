program FlatPaintTests;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  cwstring,
{$endif}
  fpcunit, testregistry, consoletestrunner, SysUtils, Forms,
  fpsurface_tests, fpuihelpers_tests, mainform_integration_tests, fpdocument_tests, tools_move_tests, tools_select_tests, fpselection_tests, fppalettehelpers_tests,
  fptabhelpers_tests,
  fpio_tests, fpnewimagehelpers_tests, fputilityhelpers_tests,
  cli_integration_tests, integration_document_flow_tests, integration_native_roundtrip_tests, format_compat_tests,
  ui_applescript_tests, ui_prototype_tests, perf_snapshot_tests,
  fprulerhelpers_tests, fpzoomhelpers_tests, fpviewhelpers_tests,
  fpiconhelpers_tests,
  fptoolbarhelpers_tests,
  fpcurveshelpers_tests, fpposterizehelpers_tests, fpblurhelpers_tests,
  fpnoisehelpers_tests, fphuesaturationhelpers_tests, fplevelshelpers_tests,
  fpbrightnesscontrasthelpers_tests, fpresizehelpers_tests, fpviewporthelpers_tests,
  fpstatushelpers_tests, fpfilemenuhelpers_tests;

var
  Runner: TTestRunner;
  AppCreated: Boolean;
procedure LogMsg(const S: string);
var
  F: TextFile;
begin
  try
    AssignFile(F, '/tmp/flatpaint_tests_debug.log');
    if FileExists('/tmp/flatpaint_tests_debug.log') then
      Append(F)
    else
      Rewrite(F);
    Writeln(F, Format('%s: %s', [DateTimeToStr(Now), S]));
    CloseFile(F);
  except
    { ignore logging errors }
  end;
end;

begin
  { Initialize a real LCL Application so UI tests can create forms/controls }
  try
    LogMsg('starting: attempting Application create/initialize');
    AppCreated := False;
    try
      try
        Application := TApplication.Create(nil);
        AppCreated := True;
        LogMsg('after create, initializing Application');
        Application.Initialize;
        LogMsg('after initialize, set formats');
      except
        on E: Exception do
        begin
          LogMsg('Application init failed: ' + E.ClassName + ': ' + E.Message);
          { continue without LCL Application, tests may still run }
        end;
      end;

      { Ensure console runner defaults are set even if Application failed }
      DefaultFormat := fPlain;
      DefaultRunAllTests := True;

      LogMsg('creating Runner');
      Runner := TTestRunner.Create(nil);
      try
        LogMsg('initializing Runner');
        Runner.Initialize;
        LogMsg('about to run Runner');
        Runner.Run;
        LogMsg('runner returned');
      finally
        Runner.Free;
        LogMsg('runner freed');
      end;
    finally
      if AppCreated then
      begin
        Application.Free;
        LogMsg('application freed');
      end
      else
        LogMsg('application was not created, skipping free');
    end;
  except
    on E: Exception do
    begin
      LogMsg('UNCAUGHT EXC: ' + E.ClassName + ': ' + E.Message);
      raise;
    end;
  end;
end.
