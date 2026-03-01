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
    procedure SaveCaptionUsesEllipsisOnlyWhenAFilePromptIsNeeded;
    procedure DiscardConfirmationTracksDirtyState;
    procedure WindowCaptionUsesEditedSuffixForDirtyDocuments;
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

procedure TFPViewHelpersTests.SaveCaptionUsesEllipsisOnlyWhenAFilePromptIsNeeded;
begin
  AssertEquals('bound file save caption', '&Save', SaveCommandCaption(True));
  AssertEquals('prompted save caption', '&Save...', SaveCommandCaption(False));
end;

procedure TFPViewHelpersTests.DiscardConfirmationTracksDirtyState;
begin
  AssertTrue('dirty documents should warn before replacement', NeedsDiscardConfirmation(True));
  AssertFalse('clean documents should not warn before replacement', NeedsDiscardConfirmation(False));
end;

procedure TFPViewHelpersTests.WindowCaptionUsesEditedSuffixForDirtyDocuments;
begin
  AssertEquals(
    'clean caption',
    'FlatPaint - Untitled',
    WindowCaptionForDocument('Untitled', False)
  );
  AssertEquals(
    'dirty caption',
    'FlatPaint - Untitled (Edited)',
    WindowCaptionForDocument('Untitled', True)
  );
end;

initialization
  RegisterTest(TFPViewHelpersTests);

end.
