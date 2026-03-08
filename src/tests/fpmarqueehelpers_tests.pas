unit fpmarqueehelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPDocument, FPMarqueeHelpers;

type
  TFPMarqueeHelpersTests = class(TTestCase)
  published
    procedure MarqueeStepVisibilityFollowsDashPattern;
    procedure MarqueeStepColorAlternatesByPhase;
    procedure NextMarqueePhaseWrapsDeterministically;
    procedure MarqueeAnimationPolicyMatchesToolIntent;
  end;

implementation

procedure TFPMarqueeHelpersTests.MarqueeStepVisibilityFollowsDashPattern;
begin
  AssertTrue('marching ants should render continuously at step 0', MarqueeStepVisible(0, 0));
  AssertTrue('marching ants should render continuously at step 3', MarqueeStepVisible(3, 0));
  AssertTrue('marching ants should render continuously at step 4', MarqueeStepVisible(4, 0));
end;

procedure TFPMarqueeHelpersTests.MarqueeStepColorAlternatesByPhase;
begin
  AssertTrue('first segment starts dark', MarqueeStepUsesDarkColor(0, 0));
  AssertTrue('same segment keeps color within segment length', MarqueeStepUsesDarkColor(3, 0));
  AssertFalse('next segment switches to light', MarqueeStepUsesDarkColor(4, 0));
  AssertFalse('phase offset by one full segment flips leading color', MarqueeStepUsesDarkColor(0, 4));
end;

procedure TFPMarqueeHelpersTests.NextMarqueePhaseWrapsDeterministically;
begin
  AssertEquals('phase increments by one', 1, NextMarqueePhase(0));
  AssertEquals('phase wraps at configured span', 0, NextMarqueePhase(MarqueePhaseWrap - 1));
end;

procedure TFPMarqueeHelpersTests.MarqueeAnimationPolicyMatchesToolIntent;
begin
  AssertTrue('selection should always animate',
    ShouldAnimateMarqueeOverlay(tkBrush, True, False, False));
  AssertTrue('clone tool animates when sampled source exists under cursor',
    ShouldAnimateMarqueeOverlay(tkCloneStamp, False, True, True));
  AssertTrue('selection tools animate while pointer is on canvas',
    ShouldAnimateMarqueeOverlay(tkSelectRect, False, False, True));
  AssertTrue('magic wand should use marquee-style animation while hovering on canvas',
    ShouldAnimateMarqueeOverlay(tkMagicWand, False, False, True));
  AssertFalse('non-marquee tools without selection should not animate',
    ShouldAnimateMarqueeOverlay(tkBrush, False, False, True));
  AssertFalse('off-canvas pointer should suspend clone-only animation',
    ShouldAnimateMarqueeOverlay(tkCloneStamp, False, True, False));
end;

initialization
  RegisterTest(TFPMarqueeHelpersTests);
end.
