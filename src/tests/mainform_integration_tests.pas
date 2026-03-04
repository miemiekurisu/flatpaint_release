unit mainform_integration_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, Controls, Types, fpcunit, testregistry, FPColor, FPDocument, FPSelection, FPSurface, FPUIHelpers;

type
  TMainFormIntegrationTests = class(TTestCase)
  published
    procedure MetaModifiedShortcutsStayReservedForCommands;
    procedure PencilStyleStrokeChangesVisibleCompositePixel;
    procedure BucketMaskIntersectedWithSelectionOnlyFillsInsideSelection;
    procedure ColorPickerKeepsVisiblePaintAlphaWhenSamplingTransparentPixel;
    procedure DefaultLineToolCommitsStraightSegmentOnRelease;
    procedure DragToolsCommitWhenMouseButtonStateDropsBeforeMouseUp;
  end;

implementation

procedure TMainFormIntegrationTests.MetaModifiedShortcutsStayReservedForCommands;
begin
  AssertTrue('plain key should still be a direct tool shortcut', ToolShortcutUsesPlainKeyOnly([]));
  AssertTrue('Shift-only should still allow reverse cycling', ToolShortcutUsesPlainKeyOnly([ssShift]));
  AssertFalse('Cmd-modified keys should stay reserved for menu commands', ToolShortcutUsesPlainKeyOnly([ssMeta]));
  AssertFalse('Ctrl-modified keys should stay reserved for command flows', ToolShortcutUsesPlainKeyOnly([ssCtrl]));
  AssertFalse('Alt-modified keys should stay reserved for tool gestures', ToolShortcutUsesPlainKeyOnly([ssAlt]));
end;

procedure TMainFormIntegrationTests.PencilStyleStrokeChangesVisibleCompositePixel;
var
  Doc: TImageDocument;
  BeforeComposite: TRasterSurface;
  AfterComposite: TRasterSurface;
  BeforePixel: TRGBA32;
  AfterPixel: TRGBA32;
begin
  Doc := TImageDocument.Create(64, 64);
  try
    BeforeComposite := Doc.Composite;
    try
      BeforePixel := BeforeComposite[20, 20];
    finally
      BeforeComposite.Free;
    end;

    Doc.ActiveLayer.Surface.DrawLine(
      20, 20,
      24, 20,
      3,
      RGBA(0, 0, 0, 255),
      255,
      255,
      nil
    );

    AfterComposite := Doc.Composite;
    try
      AfterPixel := AfterComposite[20, 20];
    finally
      AfterComposite.Free;
    end;

    AssertFalse(
      'pencil-style hard stroke should change the visible composite pixel',
      RGBAEqual(AfterPixel, BeforePixel)
    );
  finally
    Doc.Free;
  end;
end;

procedure TMainFormIntegrationTests.BucketMaskIntersectedWithSelectionOnlyFillsInsideSelection;
var
  Doc: TImageDocument;
  FillMask: TSelectionMask;
  BeforeComposite: TRasterSurface;
  AfterComposite: TRasterSurface;
  InsideBefore: TRGBA32;
  OutsideBefore: TRGBA32;
  InsideAfter: TRGBA32;
  OutsideAfter: TRGBA32;
begin
  Doc := TImageDocument.Create(64, 64);
  try
    Doc.SelectRectangle(20, 20, 29, 29, scReplace);

    BeforeComposite := Doc.Composite;
    try
      InsideBefore := BeforeComposite[25, 25];
      OutsideBefore := BeforeComposite[35, 25];
    finally
      BeforeComposite.Free;
    end;

    FillMask := Doc.ActiveLayer.Surface.CreateContiguousSelection(25, 25, 8);
    try
      FillMask.IntersectWith(Doc.Selection);
      Doc.ActiveLayer.Surface.FillSelection(FillMask, RGBA(0, 0, 0, 255), 255);
    finally
      FillMask.Free;
    end;

    AfterComposite := Doc.Composite;
    try
      InsideAfter := AfterComposite[25, 25];
      OutsideAfter := AfterComposite[35, 25];
    finally
      AfterComposite.Free;
    end;

    AssertFalse(
      'bucket fill should change pixels inside the active selection',
      RGBAEqual(InsideAfter, InsideBefore)
    );
    AssertTrue(
      'bucket fill should leave pixels outside the active selection untouched',
      RGBAEqual(OutsideAfter, OutsideBefore)
    );
  finally
    Doc.Free;
  end;
end;

procedure TMainFormIntegrationTests.ColorPickerKeepsVisiblePaintAlphaWhenSamplingTransparentPixel;
var
  CurrentColor: TRGBA32;
  SampledColor: TRGBA32;
  ResultColor: TRGBA32;
begin
  CurrentColor := RGBA(25, 50, 75, 255);
  SampledColor := TransparentColor;

  ResultColor := AdoptSampledRGBPreservingAlpha(CurrentColor, SampledColor);

  AssertEquals('sampled alpha should not zero out the active swatch alpha', 255, ResultColor.A);
  AssertEquals('sampled red should still come from the picked pixel', 0, ResultColor.R);
  AssertEquals('sampled green should still come from the picked pixel', 0, ResultColor.G);
  AssertEquals('sampled blue should still come from the picked pixel', 0, ResultColor.B);
end;

procedure TMainFormIntegrationTests.DefaultLineToolCommitsStraightSegmentOnRelease;
begin
  AssertFalse(
    'default line release should stay in straight-line mode',
    LineReleaseStartsBezier(False, Point(20, 20), Point(28, 20))
  );
  AssertTrue(
    'explicit Bezier mode should still enter staged handle editing on drag release',
    LineReleaseStartsBezier(True, Point(20, 20), Point(28, 20))
  );
end;

procedure TMainFormIntegrationTests.DragToolsCommitWhenMouseButtonStateDropsBeforeMouseUp;
begin
  AssertTrue(
    'left-button drags should stay active while the left-button shift flag is present',
    DragButtonIsStillPressed(mbLeft, [ssLeft])
  );
  AssertFalse(
    'left-button drags should finalize when the widgetset no longer reports the button',
    DragButtonIsStillPressed(mbLeft, [])
  );
  AssertFalse(
    'right-button drags should also finalize once the right-button flag disappears',
    DragButtonIsStillPressed(mbRight, [])
  );
end;

initialization
  RegisterTest(TMainFormIntegrationTests);
end.
