unit FPTextRenderer;

{$mode objfpc}{$H+}

{ Renders a text string to a TRasterSurface using the LCL Canvas.
  The primary color is used for the text; the background is transparent. }

interface

uses
  FPSurface, FPColor, FPTextDialog;

function RenderTextToSurface(const AResult: TTextDialogResult;
  AColor: TRGBA32): TRasterSurface;

implementation

uses
  Graphics, FPLCLBridge;

function RenderTextToSurface(const AResult: TTextDialogResult;
  AColor: TRGBA32): TRasterSurface;
var
  Bitmap: TBitmap;
  TextW, TextH: Integer;
  Clr: TColor;
begin
  Result := nil;
  if AResult.Text = '' then
    Exit;

  Bitmap := TBitmap.Create;
  try
    { Configure font on a temporary Bitmap so TextWidth/Height work }
    Bitmap.Width := 4;
    Bitmap.Height := 4;
    Bitmap.Canvas.Font.Name := AResult.FontName;
    Bitmap.Canvas.Font.Size := AResult.FontSize;
    if AResult.Bold then
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style + [fsBold]
    else
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style - [fsBold];
    if AResult.Italic then
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style + [fsItalic]
    else
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style - [fsItalic];

    TextW := Bitmap.Canvas.TextWidth(AResult.Text) + 2;
    TextH := Bitmap.Canvas.TextHeight(AResult.Text) + 2;
    if TextW < 1 then TextW := 1;
    if TextH < 1 then TextH := 1;

    Bitmap.SetSize(TextW, TextH);
    Bitmap.Canvas.Font.Name := AResult.FontName;
    Bitmap.Canvas.Font.Size := AResult.FontSize;
    if AResult.Bold then
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style + [fsBold]
    else
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style - [fsBold];
    if AResult.Italic then
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style + [fsItalic]
    else
      Bitmap.Canvas.Font.Style := Bitmap.Canvas.Font.Style - [fsItalic];

    { White background (will become transparent) }
    Bitmap.Canvas.Brush.Color := clWhite;
    Bitmap.Canvas.FillRect(0, 0, TextW, TextH);

    { Draw text with requested color }
    Clr := RGBToColor(AColor.R, AColor.G, AColor.B);
    Bitmap.Canvas.Font.Color := Clr;
    Bitmap.Canvas.TextOut(1, 1, AResult.Text);

    Result := BitmapToSurface(Bitmap);
    { Make white pixels transparent so only the text is opaque }
    TransparentizeSurface(Result, RGBA(255, 255, 255), 20);
  finally
    Bitmap.Free;
  end;
end;

end.
