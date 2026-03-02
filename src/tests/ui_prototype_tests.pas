unit ui_prototype_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Process;

type
  TUIPrototypeTests = class(TTestCase)
  published
    procedure Test_Osascript_Available;
  end;

implementation

procedure TUIPrototypeTests.Test_Osascript_Available;
var
  P: TProcess;
  Cmd: string;
begin
  Cmd := '/usr/bin/osascript';
  if not FileExists(Cmd) then
    Cmd := 'osascript';

  P := TProcess.Create(nil);
  try
    P.Executable := Cmd;
    P.Parameters.Add('-e');
    P.Parameters.Add('return true');
    P.Options := P.Options + [poWaitOnExit];
    P.Execute;
    AssertEquals('osascript should exit 0', 0, P.ExitStatus);
  finally
    P.Free;
  end;
end;

initialization
  RegisterTest(TUIPrototypeTests);

end.
