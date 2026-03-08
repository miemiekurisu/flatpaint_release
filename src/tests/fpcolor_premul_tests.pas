unit fpcolor_premul_tests;

{$mode objfpc}{$H+}

interface

uses
  Types, fpcunit, testregistry, FPColor, FPSelection, FPSurface;

type
  TFPColorPremulTests = class(TTestCase)
  published
    procedure PremultiplyOpaqueIsIdentity;
    procedure PremultiplyTransparentIsAllZeros;
    procedure PremultiplyHalfAlphaHalvesChannels;
    procedure UnpremultiplyRoundTripsWithinTolerance;
    procedure RGBAPremulMatchesPremultiply;
    procedure BlendNormalSourceOverOpaqueSrc;
    procedure BlendNormalSourceOverTransparentSrc;
    procedure BlendNormalSourceOverPartialAlpha;
    procedure EllipseSDFInteriorPixelsAreFullOpacity;
    procedure EllipseSDFExteriorPixelsAreTransparent;
    procedure EllipseSDFEdgePixelsHavePartialAlpha;
    procedure RoundedRectEdgePixelsHavePartialAlpha;
    procedure SelectEllipseEdgeHasFractionalCoverage;
    procedure SelectPolygonEdgeHasFractionalCoverage;
    procedure FilledPolygonEdgeHasPartialAlpha;
    procedure ResizeBilinearNoDarkHaloOnTransparentBorder;
  end;

implementation

uses
  Math;

procedure TFPColorPremulTests.PremultiplyOpaqueIsIdentity;
var
  C, P: TRGBA32;
begin
  C := RGBA(200, 100, 50, 255);
  P := Premultiply(C);
  AssertEquals('R unchanged at A=255', 200, P.R);
  AssertEquals('G unchanged at A=255', 100, P.G);
  AssertEquals('B unchanged at A=255', 50, P.B);
  AssertEquals('A unchanged', 255, P.A);
end;

procedure TFPColorPremulTests.PremultiplyTransparentIsAllZeros;
var
  C, P: TRGBA32;
begin
  C := RGBA(200, 100, 50, 0);
  P := Premultiply(C);
  AssertEquals('R zero at A=0', 0, P.R);
  AssertEquals('G zero at A=0', 0, P.G);
  AssertEquals('B zero at A=0', 0, P.B);
  AssertEquals('A zero', 0, P.A);
end;

procedure TFPColorPremulTests.PremultiplyHalfAlphaHalvesChannels;
var
  C, P: TRGBA32;
begin
  C := RGBA(200, 100, 50, 128);
  P := Premultiply(C);
  { (200 * 128 + 127) / 255 = 100 }
  AssertTrue('R approximately halved', Abs(P.R - 100) <= 1);
  AssertTrue('G approximately halved', Abs(P.G - 50) <= 1);
  AssertTrue('B approximately halved', Abs(P.B - 25) <= 1);
  AssertEquals('A preserved', 128, P.A);
end;

procedure TFPColorPremulTests.UnpremultiplyRoundTripsWithinTolerance;
var
  R, G, B, A: Integer;
  Original, Premul, RoundTripped: TRGBA32;
begin
  { At A >= 128, 8-bit premul round-trip error stays within ±1.
    Lower alpha values have progressively worse quantization — this is
    inherent to 8-bit premultiplied alpha (GIMP/Krita have the same limit). }
  for A := 128 to 255 do
    for R := 0 to 5 do
      for G := 0 to 5 do
        for B := 0 to 5 do
        begin
          Original := RGBA(R * 51, G * 51, B * 51, A);
          Premul := Premultiply(Original);
          RoundTripped := Unpremultiply(Premul);
          AssertTrue('R round-trip within tolerance',
            Abs(Integer(RoundTripped.R) - Integer(Original.R)) <= 1);
          AssertTrue('G round-trip within tolerance',
            Abs(Integer(RoundTripped.G) - Integer(Original.G)) <= 1);
          AssertTrue('B round-trip within tolerance',
            Abs(Integer(RoundTripped.B) - Integer(Original.B)) <= 1);
          AssertEquals('A exact', Original.A, RoundTripped.A);
        end;
end;

procedure TFPColorPremulTests.RGBAPremulMatchesPremultiply;
var
  Direct, Indirect: TRGBA32;
begin
  Direct := RGBA_Premul(200, 100, 50, 128);
  Indirect := Premultiply(RGBA(200, 100, 50, 128));
  AssertTrue('R matches', RGBAEqual(Direct, Indirect));
end;

procedure TFPColorPremulTests.BlendNormalSourceOverOpaqueSrc;
var
  Src, Dst, Res: TRGBA32;
begin
  Src := Premultiply(RGBA(255, 0, 0, 255));
  Dst := Premultiply(RGBA(0, 0, 255, 255));
  Res := BlendNormal(Src, Dst);
  { Opaque source fully covers destination }
  AssertEquals('R fully covered', 255, Res.R);
  AssertEquals('G zero', 0, Res.G);
  AssertEquals('B zero', 0, Res.B);
  AssertEquals('A opaque', 255, Res.A);
end;

procedure TFPColorPremulTests.BlendNormalSourceOverTransparentSrc;
var
  Src, Dst, Res: TRGBA32;
begin
  Src := TransparentColor;
  Dst := Premultiply(RGBA(0, 255, 0, 255));
  Res := BlendNormal(Src, Dst);
  AssertTrue('destination unchanged', RGBAEqual(Res, Dst));
end;

procedure TFPColorPremulTests.BlendNormalSourceOverPartialAlpha;
var
  Src, Dst, Res: TRGBA32;
begin
  Src := Premultiply(RGBA(255, 0, 0, 128));
  Dst := Premultiply(RGBA(0, 0, 255, 255));
  Res := BlendNormal(Src, Dst);
  { Result should be blend of red and blue }
  AssertTrue('R > 0 from source', Res.R > 0);
  AssertTrue('B > 0 from dest', Res.B > 0);
  AssertEquals('A fully opaque', 255, Res.A);
end;

procedure TFPColorPremulTests.EllipseSDFInteriorPixelsAreFullOpacity;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(21, 21);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawEllipse(2, 2, 18, 18, 1, RGBA(255, 0, 0, 255), True);
    { Center pixel should be fully opaque }
    AssertEquals('center pixel fully opaque', 255, Surface[10, 10].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPColorPremulTests.EllipseSDFExteriorPixelsAreTransparent;
var
  Surface: TRasterSurface;
begin
  Surface := TRasterSurface.Create(21, 21);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawEllipse(5, 5, 15, 15, 1, RGBA(255, 0, 0, 255), True);
    { Corner pixel should be transparent }
    AssertEquals('corner pixel transparent', 0, Surface[0, 0].A);
  finally
    Surface.Free;
  end;
end;

procedure TFPColorPremulTests.EllipseSDFEdgePixelsHavePartialAlpha;
var
  Surface: TRasterSurface;
  HasPartial: Boolean;
  X, Y: Integer;
begin
  Surface := TRasterSurface.Create(51, 51);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawEllipse(5, 5, 45, 45, 1, RGBA(255, 0, 0, 255), True);
    { At least some edge pixels should have partial alpha (AA fringe) }
    HasPartial := False;
    for Y := 0 to 50 do
      for X := 0 to 50 do
        if (Surface[X, Y].A > 0) and (Surface[X, Y].A < 255) then
        begin
          HasPartial := True;
          Break;
        end;
    AssertTrue('ellipse edge has partial alpha pixels from SDF AA', HasPartial);
  finally
    Surface.Free;
  end;
end;

procedure TFPColorPremulTests.RoundedRectEdgePixelsHavePartialAlpha;
var
  Surface: TRasterSurface;
  HasPartial: Boolean;
  X, Y: Integer;
begin
  Surface := TRasterSurface.Create(51, 51);
  try
    Surface.Clear(TransparentColor);
    Surface.DrawRoundedRectangle(5, 5, 45, 45, 1, RGBA(0, 255, 0, 255), True);
    HasPartial := False;
    for Y := 0 to 50 do
      for X := 0 to 50 do
        if (Surface[X, Y].A > 0) and (Surface[X, Y].A < 255) then
        begin
          HasPartial := True;
          Break;
        end;
    AssertTrue('rounded rect corner has partial alpha pixels from SDF AA', HasPartial);
  finally
    Surface.Free;
  end;
end;

procedure TFPColorPremulTests.SelectEllipseEdgeHasFractionalCoverage;
var
  Selection: TSelectionMask;
  HasPartial: Boolean;
  X, Y: Integer;
begin
  Selection := TSelectionMask.Create(51, 51);
  try
    Selection.SelectEllipse(5, 5, 45, 45);
    HasPartial := False;
    for Y := 0 to 50 do
      for X := 0 to 50 do
        if (Selection.Coverage(X, Y) > 0) and (Selection.Coverage(X, Y) < 255) then
        begin
          HasPartial := True;
          Break;
        end;
    AssertTrue('ellipse selection edge has fractional coverage', HasPartial);
    { Center must be fully selected }
    AssertEquals('center fully selected', 255, Selection.Coverage(25, 25));
  finally
    Selection.Free;
  end;
end;

procedure TFPColorPremulTests.SelectPolygonEdgeHasFractionalCoverage;
var
  Selection: TSelectionMask;
  Points: array[0..2] of TPoint;
  HasPartial: Boolean;
  X, Y: Integer;
begin
  Selection := TSelectionMask.Create(51, 51);
  try
    Points[0] := Point(25, 5);
    Points[1] := Point(5, 45);
    Points[2] := Point(45, 45);
    Selection.SelectPolygon(Points);
    HasPartial := False;
    for Y := 0 to 50 do
      for X := 0 to 50 do
        if (Selection.Coverage(X, Y) > 0) and (Selection.Coverage(X, Y) < 255) then
        begin
          HasPartial := True;
          Break;
        end;
    AssertTrue('polygon selection edge has fractional coverage', HasPartial);
  finally
    Selection.Free;
  end;
end;

procedure TFPColorPremulTests.FilledPolygonEdgeHasPartialAlpha;
var
  Surface: TRasterSurface;
  Points: array[0..2] of TPoint;
  HasPartial: Boolean;
  X, Y: Integer;
begin
  Surface := TRasterSurface.Create(51, 51);
  try
    Surface.Clear(TransparentColor);
    Points[0] := Point(25, 5);
    Points[1] := Point(5, 45);
    Points[2] := Point(45, 45);
    Surface.FillPolygon(Points, RGBA(0, 0, 255, 255));
    HasPartial := False;
    for Y := 0 to 50 do
      for X := 0 to 50 do
        if (Surface[X, Y].A > 0) and (Surface[X, Y].A < 255) then
        begin
          HasPartial := True;
          Break;
        end;
    AssertTrue('filled polygon edge has partial alpha from SDF AA', HasPartial);
  finally
    Surface.Free;
  end;
end;

procedure TFPColorPremulTests.ResizeBilinearNoDarkHaloOnTransparentBorder;
var
  Surface, Resized: TRasterSurface;
  Pixel: TRGBA32;
begin
  { Create a surface with a red square on transparent background.
    When resized with bilinear interpolation on premultiplied data,
    border pixels should NOT have dark halos. }
  Surface := TRasterSurface.Create(10, 10);
  try
    Surface.Clear(TransparentColor);
    Surface[4, 4] := Premultiply(RGBA(255, 0, 0, 255));
    Surface[5, 4] := Premultiply(RGBA(255, 0, 0, 255));
    Surface[4, 5] := Premultiply(RGBA(255, 0, 0, 255));
    Surface[5, 5] := Premultiply(RGBA(255, 0, 0, 255));
    Resized := Surface.ResizeBilinear(20, 20);
    try
      { Check a pixel at the boundary of the red area.
        In straight alpha, this would produce dark fringing (R blended with 0).
        In premultiplied, unpremultiplied result should have R near 255. }
      Pixel := Unpremultiply(Resized[9, 9]);
      if Pixel.A > 10 then
        AssertTrue('no dark halo: red channel stays near 255 at boundary',
          Pixel.R > 200);
    finally
      Resized.Free;
    end;
  finally
    Surface.Free;
  end;
end;

initialization
  RegisterTest(TFPColorPremulTests);

end.
