unit fptabhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPTabHelpers;

type
  TFPTabHelpersTests = class(TTestCase)
  published
    procedure TabStripMetricsStayStable;
    procedure TabCardLeftUsesFixedStride;
    procedure DropIndexRoundsToNearestSlot;
    procedure ActiveIndexTracksForwardReorder;
    procedure ActiveIndexTracksBackwardReorder;
  end;

implementation

procedure TFPTabHelpersTests.TabStripMetricsStayStable;
begin
  AssertEquals('tab strip height', 52, TabStripHeight);
  AssertEquals('tab card width', 170, TabCardWidth);
  AssertEquals('tab thumbnail width', 40, TabThumbnailWidth);
  AssertEquals('tab thumbnail height', 28, TabThumbnailHeight);
end;

procedure TFPTabHelpersTests.TabCardLeftUsesFixedStride;
begin
  AssertEquals('first tab left', TabStripInset, TabCardLeft(0));
  AssertEquals(
    'second tab left',
    TabStripInset + TabCardWidth + TabCardSpacing,
    TabCardLeft(1)
  );
end;

procedure TFPTabHelpersTests.DropIndexRoundsToNearestSlot;
begin
  AssertEquals('left edge stays on first tab', 0, TabDropIndexAtX(0, 4));
  AssertEquals('middle of first tab stays first', 0, TabDropIndexAtX(TabCardLeft(0) + (TabCardWidth div 2) - 2, 4));
  AssertEquals('past midpoint targets next tab', 1, TabDropIndexAtX(TabCardLeft(0) + (TabCardWidth div 2) + 8, 4));
  AssertEquals('far right clamps to last tab', 3, TabDropIndexAtX(TabCardLeft(10), 4));
end;

procedure TFPTabHelpersTests.ActiveIndexTracksForwardReorder;
begin
  AssertEquals('moved active follows its tab', 3, MoveIndexAfterReorder(1, 1, 3));
  AssertEquals('tabs shifted left update active index', 1, MoveIndexAfterReorder(2, 0, 3));
end;

procedure TFPTabHelpersTests.ActiveIndexTracksBackwardReorder;
begin
  AssertEquals('moved active follows backward move', 1, MoveIndexAfterReorder(4, 4, 1));
  AssertEquals('tabs shifted right update active index', 3, MoveIndexAfterReorder(2, 4, 1));
end;

initialization
  RegisterTest(TFPTabHelpersTests);

end.
