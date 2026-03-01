program FlatPaint;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  {$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}
  {$ENDIF}
  Interfaces,
  Forms,
  MainForm;

begin
  RequireDerivedFormResource := False;
  Application.Title := 'FlatPaint';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, AppMainForm);
  Application.Run;
end.
