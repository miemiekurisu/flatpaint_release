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
  Classes, SysUtils, Math, Graphics, FPLCLBridge;

function RenderTextToSurface(const AResult: TTextDialogResult;
  AColor: TRGBA32): TRasterSurface;
var
  Bitmap: TBitmap;
  TextW: Integer;
  TextH: Integer;
  MaxLineWidth: Integer;
  LineWidth: Integer;
  LineHeight: Integer;
  DrawX: Integer;
  DrawY: Integer;
  LineIndex: Integer;
  LineText: string;
  Lines: TStringList;
  NormalizedText: string;
  Clr: TColor;
begin
  Result := nil;
  if AResult.Text = '' then
    Exit;

  Bitmap := TBitmap.Create;
  Lines := TStringList.Create;
  try
    NormalizedText := StringReplace(AResult.Text, #13#10, #10, [rfReplaceAll]);
    NormalizedText := StringReplace(NormalizedText, #13, #10, [rfReplaceAll]);
    Lines.Text := NormalizedText;
    if Lines.Count = 0 then
      Lines.Add('');

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

    LineHeight := Max(1, Bitmap.Canvas.TextHeight('Ag'));
    MaxLineWidth := 1;
    for LineIndex := 0 to Lines.Count - 1 do
    begin
      LineWidth := Bitmap.Canvas.TextWidth(Lines[LineIndex]);
      if LineWidth > MaxLineWidth then
        MaxLineWidth := LineWidth;
    end;
    TextW := MaxLineWidth + 2;
    TextH := (LineHeight * Max(1, Lines.Count)) + 2;
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
    for LineIndex := 0 to Lines.Count - 1 do
    begin
      LineText := Lines[LineIndex];
      LineWidth := Bitmap.Canvas.TextWidth(LineText);
      case EnsureRange(AResult.Alignment, 0, 2) of
        1:
          DrawX := 1 + Max(0, (MaxLineWidth - LineWidth) div 2);
        2:
          DrawX := 1 + Max(0, MaxLineWidth - LineWidth);
      else
        DrawX := 1;
      end;
      DrawY := 1 + (LineIndex * LineHeight);
      Bitmap.Canvas.TextOut(DrawX, DrawY, LineText);
    end;

    Result := BitmapToSurface(Bitmap);
    { Make white pixels transparent so only the text is opaque }
    TransparentizeSurface(Result, RGBA(255, 255, 255), 20);
  finally
    Lines.Free;
    Bitmap.Free;
  end;
end;

end.
