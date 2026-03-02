unit perf_snapshot_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPDocument, FPColor;

type
  TPerfSnapshotTests = class(TTestCase)
  published
    procedure Test_PushHistory_MultipleSnapshots_NoException;
  end;

implementation

procedure TPerfSnapshotTests.Test_PushHistory_MultipleSnapshots_NoException;
var
  Doc: TImageDocument;
  i: Integer;
begin
  Doc := TImageDocument.Create(800, 800);
  try
    for i := 1 to 20 do
    begin
      Doc.ActiveLayer.Surface.DrawBrush( (i mod 50), (i mod 50), 2, RGBA(i*5 mod 256, (i*7) mod 256, (i*11) mod 256, 255));
      Doc.PushHistory(Format('snap %d',[i]));
    end;
    AssertTrue('History depth >= 20', Doc.UndoDepth >= 20);
  finally
    Doc.Free;
  end;
end;

initialization
  RegisterTest(TPerfSnapshotTests);

end.
