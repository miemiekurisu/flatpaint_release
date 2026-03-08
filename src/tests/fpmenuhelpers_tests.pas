unit fpmenuhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPMenuHelpers;

type
  TFPMenuHelpersTests = class(TTestCase)
  published
    procedure ExplicitApplicationMenuStrategyMatchesPlatform;
  end;

implementation

procedure TFPMenuHelpersTests.ExplicitApplicationMenuStrategyMatchesPlatform;
begin
  {$IFDEF DARWIN}
  AssertFalse(
    'macOS should rely on the system-managed application menu to avoid duplicates',
    ShouldCreateExplicitApplicationMenu
  );
  {$ELSE}
  AssertTrue(
    'non-mac platforms should keep explicit application menu entries',
    ShouldCreateExplicitApplicationMenu
  );
  {$ENDIF}
end;

initialization
  RegisterTest(TFPMenuHelpersTests);
end.
