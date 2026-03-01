unit fpviewhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPViewHelpers;

type
  TFPViewHelpersTests = class(TTestCase)
  published
    procedure PixelGridRequiresExplicitEnable;
    procedure PixelGridRequiresHighZoom;
    procedure PixelGridVisualConstantsStayStable;
  end;

implementation

procedure TFPViewHelpersTests.PixelGridRequiresExplicitEnable;
begin
  AssertFalse('disabled grid must stay hidden', ShouldRenderPixelGrid(False, 16.0));
end;

procedure TFPViewHelpersTests.PixelGridRequiresHighZoom;
begin
  AssertFalse('grid should stay off at low zoom', ShouldRenderPixelGrid(True, 4.0));
  AssertTrue('grid should appear at high zoom', ShouldRenderPixelGrid(True, PixelGridMinScale));
end;

procedure TFPViewHelpersTests.PixelGridVisualConstantsStayStable;
begin
  AssertTrue('minimum scale should be practical', PixelGridMinScale >= 4.0);
  AssertTrue('grid color should be visible', PixelGridColor <> 0);
end;

initialization
  RegisterTest(TFPViewHelpersTests);

end.
