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
    procedure AnimationPolicy_SelectionAlwaysAnimates;
    procedure AnimationPolicy_NoSelectionOffCanvasStops;
    procedure MarqueeSegmentConstantsAreConsistent;
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

procedure TFPMarqueeHelpersTests.AnimationPolicy_SelectionAlwaysAnimates;
begin
  { When a committed selection exists, marching ants must animate
    regardless of pointer position or active tool. }
  AssertTrue('selection + off-canvas brush',
    ShouldAnimateMarqueeOverlay(tkBrush, True, False, False));
  AssertTrue('selection + off-canvas select rect',
    ShouldAnimateMarqueeOverlay(tkSelectRect, True, False, False));
  AssertTrue('selection + on-canvas eraser',
    ShouldAnimateMarqueeOverlay(tkEraser, True, False, True));
end;

procedure TFPMarqueeHelpersTests.AnimationPolicy_NoSelectionOffCanvasStops;
begin
  { Without committed selection and pointer off-canvas, no selection-tool
    marquee should animate. This is the scenario that caused the
    mouse-dependent animation bug during edge-adjustment mode. }
  AssertFalse('select rect off-canvas without selection',
    ShouldAnimateMarqueeOverlay(tkSelectRect, False, False, False));
  AssertFalse('select ellipse off-canvas without selection',
    ShouldAnimateMarqueeOverlay(tkSelectEllipse, False, False, False));
  AssertFalse('magic wand off-canvas without selection',
    ShouldAnimateMarqueeOverlay(tkMagicWand, False, False, False));
end;

procedure TFPMarqueeHelpersTests.MarqueeSegmentConstantsAreConsistent;
begin
  { MarqueeColorPeriod must be exactly 2x segment length for proper
    dark/light alternation. PhaseWrap must be a multiple of period
    so wrap-around is seamless. }
  AssertEquals('period = 2 * segment', MarqueeSegmentLength * 2, MarqueeColorPeriod);
  AssertEquals('wrap is multiple of period', 0, MarqueePhaseWrap mod MarqueeColorPeriod);
  AssertTrue('wrap > 0', MarqueePhaseWrap > 0);
end;

initialization
  RegisterTest(TFPMarqueeHelpersTests);
end.
