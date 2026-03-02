unit tools_select_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, fpcunit, testregistry, FPDocument, FPSelection, FPColor;

type
  TToolsSelectTests = class(TTestCase)
  published
    procedure Document_SelectRectangle_ReplaceAndIntersect;
    procedure Document_SelectEllipse_BasicAndSubtract;
    procedure Document_SelectLasso_PolygonReplace;
  end;

implementation

procedure TToolsSelectTests.Document_SelectRectangle_ReplaceAndIntersect;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(8, 8);
  try
    Doc.SelectRectangle(1, 1, 3, 3, scReplace);
    AssertTrue('center selected', Doc.Selection[2,2]);
    Doc.SelectRectangle(2, 2, 6, 6, scIntersect);
    AssertTrue('overlap remains', Doc.Selection[2,2]);
    AssertFalse('old-only cleared', Doc.Selection[1,1]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsSelectTests.Document_SelectEllipse_BasicAndSubtract;
var
  Doc: TImageDocument;
begin
  Doc := TImageDocument.Create(7, 7);
  try
    Doc.SelectEllipse(1,1,5,5, scReplace);
    AssertTrue('ellipse center selected', Doc.Selection[3,3]);
    Doc.SelectEllipse(2,2,4,4, scSubtract);
    AssertFalse('inner removed', Doc.Selection[3,3]);
  finally
    Doc.Free;
  end;
end;

procedure TToolsSelectTests.Document_SelectLasso_PolygonReplace;
var
  Doc: TImageDocument;
  P: array[0..3] of TPoint;
begin
  Doc := TImageDocument.Create(10, 10);
  try
    P[0] := Point(2,2);
    P[1] := Point(4,2);
    P[2] := Point(4,4);
    P[3] := Point(2,4);
    Doc.SelectLasso(P, scReplace);
    AssertTrue('lasso center selected', Doc.Selection[3,3]);
    AssertFalse('outside clear', Doc.Selection[1,1]);
  finally
    Doc.Free;
  end;
end;

initialization
  RegisterTest(TToolsSelectTests);

end.
