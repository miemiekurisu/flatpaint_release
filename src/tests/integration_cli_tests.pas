unit integration_cli_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Process;

type
  TIntegrationCLITests = class(TTestCase)
  published
    procedure Test_CLI_Help_ExitsZero;
  end;

implementation

procedure TIntegrationCLITests.Test_CLI_Help_ExitsZero;
var
  P: TProcess;
  Cmd: string;
begin
  Cmd := ExpandFileName('dist/flatpaint');
  if not FileExists(Cmd) then
    Cmd := ExpandFileName('flatpaint');

  P := TProcess.Create(nil);
  try
    P.Executable := Cmd;
    P.Parameters.Add('--help');
    P.Options := P.Options + [poWaitOnExit];
    P.Execute;
    AssertEquals('CLI --help should exit 0', 0, P.ExitStatus);
  finally
    P.Free;
  end;
end;

initialization
  RegisterTest(TIntegrationCLITests);

end.
