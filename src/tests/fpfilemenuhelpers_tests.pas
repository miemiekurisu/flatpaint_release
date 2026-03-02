unit fpfilemenuhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPFileMenuHelpers;

type
  TFPFileMenuHelpersTests = class(TTestCase)
  published
    procedure AcquirePrefersClipboardWhenImageExists;
    procedure AcquireFallsBackToFileWhenClipboardIsEmpty;
    procedure SaveAllUsesSaveAsForUntitledDocument;
    procedure SaveAllUsesDirectSaveForBoundDocument;
  end;

implementation

procedure TFPFileMenuHelpersTests.AcquirePrefersClipboardWhenImageExists;
begin
  AssertEquals('clipboard route', Ord(amClipboard), Ord(ResolveAcquireMode(True)));
end;

procedure TFPFileMenuHelpersTests.AcquireFallsBackToFileWhenClipboardIsEmpty;
begin
  AssertEquals('file route', Ord(amOpenFile), Ord(ResolveAcquireMode(False)));
end;

procedure TFPFileMenuHelpersTests.SaveAllUsesSaveAsForUntitledDocument;
begin
  AssertTrue('untitled should prompt', SaveAllFallsBackToSaveAs(''));
end;

procedure TFPFileMenuHelpersTests.SaveAllUsesDirectSaveForBoundDocument;
begin
  AssertFalse('named doc should save directly', SaveAllFallsBackToSaveAs('/tmp/example.fpd'));
end;

initialization
  RegisterTest(TFPFileMenuHelpersTests);
end.
