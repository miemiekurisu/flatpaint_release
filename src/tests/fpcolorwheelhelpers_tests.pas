unit fpcolorwheelhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpcunit, testregistry, FPColorWheelHelpers;

type
  TFPColorWheelHelpersTests = class(TTestCase)
  published
    procedure SVSquareRebuildsWhenHueChangesOrCacheMissing;
    procedure SVSquareSkipsRebuildForStableHueAndSize;
  end;

implementation

procedure TFPColorWheelHelpersTests.SVSquareRebuildsWhenHueChangesOrCacheMissing;
begin
  AssertTrue(
    'uninitialized rendered hue should force first SV bitmap render',
    ShouldRebuildSVSquare(-1.0, 0.25, 120, 120, 120)
  );
  AssertTrue(
    'size change should force SV bitmap rebuild',
    ShouldRebuildSVSquare(0.25, 0.25, 96, 96, 120)
  );
  AssertTrue(
    'hue change should force SV bitmap rebuild',
    ShouldRebuildSVSquare(0.25, 0.41, 120, 120, 120)
  );
end;

procedure TFPColorWheelHelpersTests.SVSquareSkipsRebuildForStableHueAndSize;
begin
  AssertFalse(
    'same hue and same size should reuse cached SV bitmap',
    ShouldRebuildSVSquare(0.25, 0.25, 120, 120, 120)
  );
  AssertFalse(
    'tiny hue drift under epsilon should still reuse cached bitmap',
    ShouldRebuildSVSquare(0.2500, 0.2508, 120, 120, 120)
  );
end;

initialization
  RegisterTest(TFPColorWheelHelpersTests);
end.
