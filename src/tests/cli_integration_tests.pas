unit cli_integration_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Process, FPColor, FPSurface, FPIO;

type
  TCLIIntegrationTests = class(TTestCase)
  published
    procedure Test_CLI_New_And_Brush;
  end;

implementation

procedure TCLIIntegrationTests.Test_CLI_New_And_Brush;
var
  CliPath: string;
  NewPath: string;
  BrushedPath: string;
  ExitCode: Integer;
  Output: string;
  Surf: TRasterSurface;
  Proc: TProcess;
begin
  CliPath := GetCurrentDir + PathDelim + 'dist' + PathDelim + 'flatpaint_cli';
  NewPath := GetCurrentDir + PathDelim + 'dist' + PathDelim + 'cli_new.png';
  BrushedPath := GetCurrentDir + PathDelim + 'dist' + PathDelim + 'cli_brushed.png';

  if FileExists(NewPath) then DeleteFile(NewPath);
  if FileExists(BrushedPath) then DeleteFile(BrushedPath);

  AssertTrue('CLI binary exists', FileExists(CliPath));

  // create a new 10x10 image using TProcess
  Proc := TProcess.Create(nil);
  try
    Proc.Executable := CliPath;
    Proc.Parameters.Add('new');
    Proc.Parameters.Add('10');
    Proc.Parameters.Add('10');
    Proc.Parameters.Add(NewPath);
    Proc.Options := [poWaitOnExit];
    Proc.Execute;
    ExitCode := Proc.ExitStatus;
  finally
    Proc.Free;
  end;
  AssertEquals('new exit code', 0, ExitCode);
  AssertTrue('new produced file', FileExists(NewPath));

  // brush at center (5,5) with radius 2 and color 10,20,30
  Proc := TProcess.Create(nil);
  try
    Proc.Executable := CliPath;
    Proc.Parameters.Add('brush');
    Proc.Parameters.Add(NewPath);
    Proc.Parameters.Add(BrushedPath);
    Proc.Parameters.Add('5');
    Proc.Parameters.Add('5');
    Proc.Parameters.Add('2');
    Proc.Parameters.Add('10');
    Proc.Parameters.Add('20');
    Proc.Parameters.Add('30');
    Proc.Options := [poWaitOnExit];
    Proc.Execute;
    ExitCode := Proc.ExitStatus;
  finally
    Proc.Free;
  end;
  AssertEquals('brush exit code', 0, ExitCode);
  AssertTrue('brushed produced file', FileExists(BrushedPath));

  Surf := LoadSurfaceFromFile(BrushedPath);
  try
    // expect non-transparent pixel at 5,5 with roughly the painted color
    AssertFalse('pixel not transparent', RGBAEqual(Surf[5,5], TransparentColor));
    AssertEquals('R channel', 10, Surf[5,5].R);
    AssertEquals('G channel', 20, Surf[5,5].G);
    AssertEquals('B channel', 30, Surf[5,5].B);
  finally
    Surf.Free;
  end;

  // cleanup
  DeleteFile(NewPath);
  DeleteFile(BrushedPath);
end;

initialization
  RegisterTest(TCLIIntegrationTests);

end.
