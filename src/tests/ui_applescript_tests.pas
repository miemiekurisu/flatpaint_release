unit ui_applescript_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Process;

type
  TUIAppleScriptTests = class(TTestCase)
  published
    procedure Test_Try_Run_UI_Script_If_App_Present;
  end;

implementation

procedure TUIAppleScriptTests.Test_Try_Run_UI_Script_If_App_Present;
var
  AppPath: string;
  P: TProcess;
begin
  AppPath := ExpandFileName('flatpaint.app');
  if not FileExists(AppPath) then
    AppPath := ExpandFileName('dist/flatpaint.app');

  // If app is not present locally, skip UI automation (pass test)
  if not FileExists(AppPath) then
  begin
    Exit;
  end;

  P := TProcess.Create(nil);
  try
    P.Executable := '/usr/bin/osascript';
    P.Parameters.Add('-e');
    P.Parameters.Add(Format('tell application "Finder" to open POSIX file "%s"', [AppPath]));
    P.Options := P.Options + [poWaitOnExit];
    P.Execute;
    AssertEquals('osascript open app exit code', 0, P.ExitStatus);
  finally
    P.Free;
  end;
end;

initialization
  RegisterTest(TUIAppleScriptTests);

end.
