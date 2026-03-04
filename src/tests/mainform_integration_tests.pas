unit mainform_integration_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpcunit, testregistry, FPColor, FPDocument, FPSelection, FPSurface, FPUIHelpers;

type
  TMainFormIntegrationTests = class(TTestCase)
  published
    procedure MetaModifiedShortcutsStayReservedForCommands;
    procedure PencilStyleStrokeChangesVisibleCompositePixel;
    procedure BucketMaskIntersectedWithSelectionOnlyFillsInsideSelection;
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

initialization
  RegisterTest(TMainFormIntegrationTests);
end.
