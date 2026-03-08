unit FPExportDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, FPSurface, FPIO;

type
  TExportFormat = (efJPEG, efPNG, efBMP, efTIFF, efPCX, efPNM, efXPM);

function TryExportFormatForExtension(const AExtension: string; out AFormat: TExportFormat): Boolean;
function RunExportOptionsDialog(
  AOwner: TComponent;
  AFormat: TExportFormat;
  ASourceSurface: TRasterSurface;
  var AOptions: TSaveSurfaceOptions
): Boolean;

implementation

uses
  SysUtils, Math, Controls, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  FPImage, FPColor, FPReadJPEG, FPReadPNG, FPReadBMP, FPReadTiff,
  FPReadPCX, FPReadPNM, FPReadXPM, FPLCLBridge, FPi18n;

const
  ExportDialogWidth = 760;
  ExportDialogHeight = 420;
  PreviewMaxWidth = 320;
  PreviewMaxHeight = 220;

type
  TExportOptionsDialog = class(TForm)
  private
    FUpdating: Boolean;
    FFormat: TExportFormat;
    FOptions: TSaveSurfaceOptions;
    FPreviewSource: TRasterSurface;

    FOptionsHost: TPanel;
    FPreviewHost: TPanel;
    FPreviewImage: TImage;
    FPreviewInfoLabel: TLabel;
    FPreviewSizeLabel: TLabel;

    { JPEG }
    FQualityTrack: TTrackBar;
    FQualityEdit: TEdit;
    FProgressiveCheck: TCheckBox;
    FGrayCheck: TCheckBox;
    FSubsamplingCombo: TComboBox;

    { PNG }
    FCompressionTrack: TTrackBar;
    FCompressionEdit: TEdit;
    FAlphaCheck: TCheckBox;
    FPngGrayCheck: TCheckBox;
    FPngIndexedCheck: TCheckBox;
    FPngWordSizedCheck: TCheckBox;
    FPngCompressedTextCheck: TCheckBox;

    { BMP }
    FBmpBitsCombo: TComboBox;
    FBmpXPelsEdit: TEdit;
    FBmpYPelsEdit: TEdit;

    { TIFF }
    FTiffSaveCMYKCheck: TCheckBox;

    { PCX }
    FPcxCompressedCheck: TCheckBox;

    { PNM }
    FPnmBinaryCheck: TCheckBox;
    FPnmDepthCombo: TComboBox;
    FPnmFullWidthCheck: TCheckBox;

    { XPM }
    FXpmColorSizeEdit: TEdit;
    FXpmPalCharsEdit: TEdit;

    function BoolCaption(AValue: Boolean): string;
    function ParseIntFromEdit(AEdit: TEdit; ADefault, AMin, AMax: Integer): Integer;
    function BuildPreviewSurface(ASource: TRasterSurface): TRasterSurface;
    function DecodeSurfaceFromStream(const AExtension: string; AStream: TStream): TRasterSurface;
    function FormatExtension: string;
    function CurrentFormatSummary: string;
    procedure ShowPreviewSurface(ASurface: TRasterSurface);
    procedure SyncControlsFromOptions;
    procedure SyncOptionsFromControls;
    procedure UpdatePreview;

    procedure QualityTrackChanged(Sender: TObject);
    procedure QualityEditDone(Sender: TObject);
    procedure CompressionTrackChanged(Sender: TObject);
    procedure CompressionEditDone(Sender: TObject);
    procedure OptionChanged(Sender: TObject);

    procedure BuildCommonUI;
    procedure BuildJPEGUI;
    procedure BuildPNGUI;
    procedure BuildBMPUI;
    procedure BuildTIFFUI;
    procedure BuildPCXUI;
    procedure BuildPNMUI;
    procedure BuildXPMUI;
  public
    constructor CreateDialog(
      AOwner: TComponent;
      AFormat: TExportFormat;
      ASourceSurface: TRasterSurface;
      const AOptions: TSaveSurfaceOptions
    );
    destructor Destroy; override;
    property Options: TSaveSurfaceOptions read FOptions;
  end;

function TryExportFormatForExtension(const AExtension: string; out AFormat: TExportFormat): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(AExtension);
  if (Ext <> '') and (Ext[1] <> '.') then
    Ext := '.' + Ext;
  if (Ext = '.jpg') or (Ext = '.jpeg') then
  begin
    AFormat := efJPEG;
    Exit(True);
  end;
  if Ext = '.png' then
  begin
    AFormat := efPNG;
    Exit(True);
  end;
  if Ext = '.bmp' then
  begin
    AFormat := efBMP;
    Exit(True);
  end;
  if (Ext = '.tif') or (Ext = '.tiff') then
  begin
    AFormat := efTIFF;
    Exit(True);
  end;
  if Ext = '.pcx' then
  begin
    AFormat := efPCX;
    Exit(True);
  end;
  if (Ext = '.pnm') or (Ext = '.pbm') or (Ext = '.pgm') or (Ext = '.ppm') then
  begin
    AFormat := efPNM;
    Exit(True);
  end;
  if Ext = '.xpm' then
  begin
    AFormat := efXPM;
    Exit(True);
  end;
  Result := False;
end;

function TExportOptionsDialog.BoolCaption(AValue: Boolean): string;
begin
  if AValue then
    Result := TR('On', '开')
  else
    Result := TR('Off', '关');
end;

function TExportOptionsDialog.ParseIntFromEdit(
  AEdit: TEdit;
  ADefault,
  AMin,
  AMax: Integer
): Integer;
begin
  if AEdit = nil then
    Exit(ADefault);
  Result := StrToIntDef(Trim(AEdit.Text), ADefault);
  Result := EnsureRange(Result, AMin, AMax);
end;

function TExportOptionsDialog.BuildPreviewSurface(ASource: TRasterSurface): TRasterSurface;
var
  ScaleX: Double;
  ScaleY: Double;
  Scale: Double;
  NewWidth: Integer;
  NewHeight: Integer;
begin
  Result := nil;
  if (ASource = nil) or (ASource.Width <= 0) or (ASource.Height <= 0) then
    Exit;

  ScaleX := PreviewMaxWidth / Max(1, ASource.Width);
  ScaleY := PreviewMaxHeight / Max(1, ASource.Height);
  Scale := Min(1.0, Min(ScaleX, ScaleY));
  if Scale >= 0.999 then
    Exit(ASource.Clone);

  NewWidth := Max(1, Round(ASource.Width * Scale));
  NewHeight := Max(1, Round(ASource.Height * Scale));
  Result := ASource.ResizeBilinear(NewWidth, NewHeight);
end;

function TExportOptionsDialog.DecodeSurfaceFromStream(
  const AExtension: string;
  AStream: TStream
): TRasterSurface;
var
  Reader: TFPCustomImageReader;
  Image: TFPMemoryImage;
  Pixel: TFPColor;
  X: Integer;
  Y: Integer;
  Ext: string;
begin
  Result := nil;
  if AStream = nil then
    Exit;

  Ext := LowerCase(AExtension);
  if (Ext <> '') and (Ext[1] <> '.') then
    Ext := '.' + Ext;

  if (Ext = '.jpg') or (Ext = '.jpeg') then
    Reader := TFPReaderJPEG.Create
  else if Ext = '.png' then
    Reader := TFPReaderPNG.Create
  else if Ext = '.bmp' then
    Reader := TFPReaderBMP.Create
  else if (Ext = '.tif') or (Ext = '.tiff') then
    Reader := TFPReaderTiff.Create
  else if Ext = '.pcx' then
    Reader := TFPReaderPCX.Create
  else if (Ext = '.pnm') or (Ext = '.pbm') or (Ext = '.pgm') or (Ext = '.ppm') then
    Reader := TFPReaderPNM.Create
  else if Ext = '.xpm' then
    Reader := TFPReaderXPM.Create
  else
    Exit(nil);

  Image := TFPMemoryImage.Create(0, 0);
  try
    AStream.Position := 0;
    Image.LoadFromStream(AStream, Reader);
    Result := TRasterSurface.Create(Image.Width, Image.Height);
    for Y := 0 to Image.Height - 1 do
      for X := 0 to Image.Width - 1 do
      begin
        Pixel := Image.Colors[X, Y];
        Result[X, Y] := Premultiply(RGBA(Pixel.Red shr 8, Pixel.Green shr 8, Pixel.Blue shr 8, Pixel.Alpha shr 8));
      end;
  finally
    Image.Free;
    Reader.Free;
  end;
end;

function TExportOptionsDialog.FormatExtension: string;
begin
  case FFormat of
    efJPEG: Result := '.jpg';
    efPNG: Result := '.png';
    efBMP: Result := '.bmp';
    efTIFF: Result := '.tif';
    efPCX: Result := '.pcx';
    efPNM: Result := '.pnm';
    efXPM: Result := '.xpm';
  else
    Result := '.png';
  end;
end;

function TExportOptionsDialog.CurrentFormatSummary: string;
begin
  case FFormat of
    efJPEG:
      Result := Format(
        TR('JPEG: quality %d, progressive %s, grayscale %s',
          'JPEG：质量 %d，渐进 %s，灰度 %s'),
        [FOptions.JpegQuality, BoolCaption(FOptions.JpegProgressive), BoolCaption(FOptions.JpegGrayscale)]
      );
    efPNG:
      Result := Format(
        TR('PNG: compression %d, alpha %s, grayscale %s, indexed %s, 16-bit %s, text-compress %s',
          'PNG：压缩 %d，Alpha %s，灰度 %s，索引 %s，16位 %s，文本压缩 %s'),
        [
          FOptions.PngCompressionLevel,
          BoolCaption(FOptions.PngUseAlpha),
          BoolCaption(FOptions.PngGrayscale),
          BoolCaption(FOptions.PngIndexed),
          BoolCaption(FOptions.PngWordSized),
          BoolCaption(FOptions.PngCompressedText)
        ]
      );
    efBMP:
      Result := Format(
        TR('BMP: true-color %d bpp, RLE Off, X/Y ppm %d/%d',
          'BMP：真彩 %d bpp，RLE 关，X/Y ppm %d/%d'),
        [FOptions.BmpBitsPerPixel, FOptions.BmpXPelsPerMeter, FOptions.BmpYPelsPerMeter]
      );
    efTIFF:
      Result := Format(
        TR('TIFF: Save CMYK as RGB %s',
          'TIFF：CMYK 按 RGB 保存 %s'),
        [BoolCaption(FOptions.TiffSaveCMYKAsRGB)]
      );
    efPCX:
      Result := Format(
        TR('PCX: compressed %s',
          'PCX：压缩 %s'),
        [BoolCaption(FOptions.PcxCompressed)]
      );
    efPNM:
      Result := Format(
        TR('PNM: binary %s, depth mode %d, full-width %s',
          'PNM：二进制 %s，深度模式 %d，全宽 %s'),
        [BoolCaption(FOptions.PnmBinaryFormat), FOptions.PnmColorDepthMode, BoolCaption(FOptions.PnmFullWidth)]
      );
    efXPM:
      Result := Format(
        TR('XPM: chars/pixel %d, palette chars %d',
          'XPM：每像素字符 %d，调色板字符 %d'),
        [FOptions.XpmColorCharSize, Length(FOptions.XpmPalChars)]
      );
  else
    Result := TR('Export options', '导出选项');
  end;
end;

procedure TExportOptionsDialog.ShowPreviewSurface(ASurface: TRasterSurface);
var
  Bitmap: TBitmap;
begin
  if not Assigned(FPreviewImage) or (ASurface = nil) then
    Exit;
  Bitmap := TBitmap.Create;
  try
    CopySurfaceToBitmap(ASurface, Bitmap);
    FPreviewImage.Picture.Bitmap.Assign(Bitmap);
  finally
    Bitmap.Free;
  end;
end;

procedure TExportOptionsDialog.SyncControlsFromOptions;
const
  BmpBits: array[0..1] of Integer = (24, 32);
var
  Index: Integer;
begin
  FUpdating := True;
  try
    if Assigned(FQualityTrack) then
      FQualityTrack.Position := EnsureRange(FOptions.JpegQuality, 1, 100);
    if Assigned(FQualityEdit) then
      FQualityEdit.Text := IntToStr(EnsureRange(FOptions.JpegQuality, 1, 100));
    if Assigned(FProgressiveCheck) then
      FProgressiveCheck.Checked := FOptions.JpegProgressive;
    if Assigned(FGrayCheck) then
      FGrayCheck.Checked := FOptions.JpegGrayscale;

    if Assigned(FCompressionTrack) then
      FCompressionTrack.Position := EnsureRange(FOptions.PngCompressionLevel, 0, 9);
    if Assigned(FCompressionEdit) then
      FCompressionEdit.Text := IntToStr(EnsureRange(FOptions.PngCompressionLevel, 0, 9));
    if Assigned(FAlphaCheck) then
      FAlphaCheck.Checked := FOptions.PngUseAlpha;
    if Assigned(FPngGrayCheck) then
      FPngGrayCheck.Checked := FOptions.PngGrayscale;
    if Assigned(FPngIndexedCheck) then
      FPngIndexedCheck.Checked := FOptions.PngIndexed;
    if Assigned(FPngWordSizedCheck) then
      FPngWordSizedCheck.Checked := FOptions.PngWordSized;
    if Assigned(FPngCompressedTextCheck) then
      FPngCompressedTextCheck.Checked := FOptions.PngCompressedText;

    if Assigned(FBmpBitsCombo) then
    begin
      FBmpBitsCombo.ItemIndex := 0;
      for Index := Low(BmpBits) to High(BmpBits) do
        if BmpBits[Index] = FOptions.BmpBitsPerPixel then
        begin
          FBmpBitsCombo.ItemIndex := Index;
          Break;
        end;
    end;
    if Assigned(FBmpXPelsEdit) then
      FBmpXPelsEdit.Text := IntToStr(Max(1, FOptions.BmpXPelsPerMeter));
    if Assigned(FBmpYPelsEdit) then
      FBmpYPelsEdit.Text := IntToStr(Max(1, FOptions.BmpYPelsPerMeter));

    if Assigned(FTiffSaveCMYKCheck) then
      FTiffSaveCMYKCheck.Checked := FOptions.TiffSaveCMYKAsRGB;

    if Assigned(FPcxCompressedCheck) then
      FPcxCompressedCheck.Checked := FOptions.PcxCompressed;

    if Assigned(FPnmBinaryCheck) then
      FPnmBinaryCheck.Checked := FOptions.PnmBinaryFormat;
    if Assigned(FPnmDepthCombo) then
      FPnmDepthCombo.ItemIndex := EnsureRange(FOptions.PnmColorDepthMode, 0, 3);
    if Assigned(FPnmFullWidthCheck) then
      FPnmFullWidthCheck.Checked := FOptions.PnmFullWidth;

    if Assigned(FXpmColorSizeEdit) then
      FXpmColorSizeEdit.Text := IntToStr(EnsureRange(FOptions.XpmColorCharSize, 1, 8));
    if Assigned(FXpmPalCharsEdit) then
      FXpmPalCharsEdit.Text := FOptions.XpmPalChars;
  finally
    FUpdating := False;
  end;
end;

procedure TExportOptionsDialog.SyncOptionsFromControls;
const
  BmpBits: array[0..1] of Integer = (24, 32);
begin
  if Assigned(FQualityTrack) then
    FOptions.JpegQuality := EnsureRange(FQualityTrack.Position, 1, 100);
  if Assigned(FProgressiveCheck) then
    FOptions.JpegProgressive := FProgressiveCheck.Checked;
  if Assigned(FGrayCheck) then
    FOptions.JpegGrayscale := FGrayCheck.Checked;

  if Assigned(FCompressionTrack) then
    FOptions.PngCompressionLevel := EnsureRange(FCompressionTrack.Position, 0, 9);
  if Assigned(FAlphaCheck) then
    FOptions.PngUseAlpha := FAlphaCheck.Checked;
  if Assigned(FPngGrayCheck) then
    FOptions.PngGrayscale := FPngGrayCheck.Checked;
  if Assigned(FPngIndexedCheck) then
    FOptions.PngIndexed := FPngIndexedCheck.Checked;
  if Assigned(FPngWordSizedCheck) then
    FOptions.PngWordSized := FPngWordSizedCheck.Checked;
  if Assigned(FPngCompressedTextCheck) then
    FOptions.PngCompressedText := FPngCompressedTextCheck.Checked;

  if Assigned(FBmpBitsCombo) then
    FOptions.BmpBitsPerPixel := BmpBits[EnsureRange(FBmpBitsCombo.ItemIndex, 0, High(BmpBits))];
  FOptions.BmpRLECompress := False;
  FOptions.BmpXPelsPerMeter := ParseIntFromEdit(FBmpXPelsEdit, FOptions.BmpXPelsPerMeter, 1, 200000);
  FOptions.BmpYPelsPerMeter := ParseIntFromEdit(FBmpYPelsEdit, FOptions.BmpYPelsPerMeter, 1, 200000);

  if Assigned(FTiffSaveCMYKCheck) then
    FOptions.TiffSaveCMYKAsRGB := FTiffSaveCMYKCheck.Checked;

  if Assigned(FPcxCompressedCheck) then
    FOptions.PcxCompressed := FPcxCompressedCheck.Checked;

  if Assigned(FPnmBinaryCheck) then
    FOptions.PnmBinaryFormat := FPnmBinaryCheck.Checked;
  if Assigned(FPnmDepthCombo) then
    FOptions.PnmColorDepthMode := EnsureRange(FPnmDepthCombo.ItemIndex, 0, 3);
  if Assigned(FPnmFullWidthCheck) then
    FOptions.PnmFullWidth := FPnmFullWidthCheck.Checked;
  if FOptions.PnmFullWidth then
    FOptions.PnmBinaryFormat := True;

  FOptions.XpmColorCharSize := ParseIntFromEdit(FXpmColorSizeEdit, FOptions.XpmColorCharSize, 1, 8);
  if Assigned(FXpmPalCharsEdit) then
    FOptions.XpmPalChars := Trim(FXpmPalCharsEdit.Text);
end;

procedure TExportOptionsDialog.UpdatePreview;
var
  Encoded: TMemoryStream;
  Decoded: TRasterSurface;
  Extension: string;
  SizeKB: Double;
begin
  if FUpdating then
    Exit;
  if not Assigned(FPreviewSource) then
    Exit;

  SyncOptionsFromControls;
  Extension := FormatExtension;

  Encoded := TMemoryStream.Create;
  try
    SaveSurfaceToStreamWithOpts(Encoded, Extension, FPreviewSource, FOptions);
    SizeKB := Encoded.Size / 1024.0;
    if Assigned(FPreviewSizeLabel) then
      FPreviewSizeLabel.Caption := Format(TR('Sample encoded size: %.1f KB',
        '预览编码大小：%.1f KB'), [SizeKB]);
    if Assigned(FPreviewInfoLabel) then
      FPreviewInfoLabel.Caption := CurrentFormatSummary;

    Decoded := DecodeSurfaceFromStream(Extension, Encoded);
    try
      if Decoded <> nil then
        ShowPreviewSurface(Decoded)
      else
        ShowPreviewSurface(FPreviewSource);
    finally
      Decoded.Free;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FPreviewInfoLabel) then
        FPreviewInfoLabel.Caption := TR('Preview unavailable: ',
          '预览不可用：') + E.Message;
      if Assigned(FPreviewSizeLabel) then
        FPreviewSizeLabel.Caption := '';
      ShowPreviewSurface(FPreviewSource);
    end;
  end;
  Encoded.Free;
end;

procedure TExportOptionsDialog.QualityTrackChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    if Assigned(FQualityEdit) then
      FQualityEdit.Text := IntToStr(EnsureRange(FQualityTrack.Position, 1, 100));
  finally
    FUpdating := False;
  end;
  UpdatePreview;
end;

procedure TExportOptionsDialog.QualityEditDone(Sender: TObject);
var
  Parsed: Integer;
begin
  if FUpdating then
    Exit;
  Parsed := ParseIntFromEdit(FQualityEdit, FQualityTrack.Position, 1, 100);
  FUpdating := True;
  try
    FQualityTrack.Position := Parsed;
    FQualityEdit.Text := IntToStr(Parsed);
  finally
    FUpdating := False;
  end;
  UpdatePreview;
end;

procedure TExportOptionsDialog.CompressionTrackChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    if Assigned(FCompressionEdit) then
      FCompressionEdit.Text := IntToStr(EnsureRange(FCompressionTrack.Position, 0, 9));
  finally
    FUpdating := False;
  end;
  UpdatePreview;
end;

procedure TExportOptionsDialog.CompressionEditDone(Sender: TObject);
var
  Parsed: Integer;
begin
  if FUpdating then
    Exit;
  Parsed := ParseIntFromEdit(FCompressionEdit, FCompressionTrack.Position, 0, 9);
  FUpdating := True;
  try
    FCompressionTrack.Position := Parsed;
    FCompressionEdit.Text := IntToStr(Parsed);
  finally
    FUpdating := False;
  end;
  UpdatePreview;
end;

procedure TExportOptionsDialog.OptionChanged(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TExportOptionsDialog.BuildCommonUI;
var
  OKButton: TButton;
  CancelButton: TButton;
begin
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;
  Width := ExportDialogWidth;
  Height := ExportDialogHeight;
  ClientWidth := ExportDialogWidth;
  ClientHeight := ExportDialogHeight;

  FOptionsHost := TPanel.Create(Self);
  FOptionsHost.Parent := Self;
  FOptionsHost.SetBounds(12, 12, 332, 356);
  FOptionsHost.BevelOuter := bvNone;
  FOptionsHost.Caption := '';

  FPreviewHost := TPanel.Create(Self);
  FPreviewHost.Parent := Self;
  FPreviewHost.SetBounds(356, 12, 392, 356);
  FPreviewHost.BevelOuter := bvLowered;
  FPreviewHost.Caption := '';

  FPreviewImage := TImage.Create(FPreviewHost);
  FPreviewImage.Parent := FPreviewHost;
  FPreviewImage.SetBounds(12, 12, 368, 268);
  FPreviewImage.Stretch := True;
  FPreviewImage.Proportional := True;
  FPreviewImage.Center := True;

  FPreviewInfoLabel := TLabel.Create(FPreviewHost);
  FPreviewInfoLabel.Parent := FPreviewHost;
  FPreviewInfoLabel.SetBounds(12, 286, 368, 30);
  FPreviewInfoLabel.AutoSize := False;
  FPreviewInfoLabel.WordWrap := True;

  FPreviewSizeLabel := TLabel.Create(FPreviewHost);
  FPreviewSizeLabel.Parent := FPreviewHost;
  FPreviewSizeLabel.SetBounds(12, 318, 368, 18);
  FPreviewSizeLabel.AutoSize := False;

  OKButton := TButton.Create(Self);
  OKButton.Parent := Self;
  OKButton.Caption := TR('OK', '确定');
  OKButton.SetBounds(ClientWidth - 150, ClientHeight - 40, 64, 26);
  OKButton.ModalResult := mrOK;
  OKButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', '取消');
  CancelButton.SetBounds(ClientWidth - 78, ClientHeight - 40, 64, 26);
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;
end;

procedure TExportOptionsDialog.BuildJPEGUI;
var
  LabelCtrl: TLabel;
  HelpLabel: TLabel;
begin
  Caption := TR('JPEG Export Options', 'JPEG 导出选项');

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Quality (1-100):', '质量 (1-100)：');
  LabelCtrl.SetBounds(6, 12, 140, 18);

  FQualityEdit := TEdit.Create(FOptionsHost);
  FQualityEdit.Parent := FOptionsHost;
  FQualityEdit.SetBounds(148, 8, 56, 24);
  FQualityEdit.OnEditingDone := @QualityEditDone;

  FQualityTrack := TTrackBar.Create(FOptionsHost);
  FQualityTrack.Parent := FOptionsHost;
  FQualityTrack.SetBounds(6, 36, 312, 42);
  FQualityTrack.Min := 1;
  FQualityTrack.Max := 100;
  FQualityTrack.Frequency := 5;
  FQualityTrack.OnChange := @QualityTrackChanged;
  FQualityTrack.ShowSelRange := False;

  FProgressiveCheck := TCheckBox.Create(FOptionsHost);
  FProgressiveCheck.Parent := FOptionsHost;
  FProgressiveCheck.Caption := TR('Progressive encoding', '渐进式编码');
  FProgressiveCheck.SetBounds(6, 84, 220, 24);
  FProgressiveCheck.OnChange := @OptionChanged;

  FGrayCheck := TCheckBox.Create(FOptionsHost);
  FGrayCheck.Parent := FOptionsHost;
  FGrayCheck.Caption := TR('Grayscale output', '灰度输出');
  FGrayCheck.SetBounds(6, 110, 220, 24);
  FGrayCheck.OnChange := @OptionChanged;

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Chroma subsampling:', '色度子采样：');
  LabelCtrl.SetBounds(6, 146, 220, 18);

  FSubsamplingCombo := TComboBox.Create(FOptionsHost);
  FSubsamplingCombo.Parent := FOptionsHost;
  FSubsamplingCombo.Style := csDropDownList;
  FSubsamplingCombo.SetBounds(6, 166, 220, 24);
  FSubsamplingCombo.Items.Add('4:4:4');
  FSubsamplingCombo.Items.Add('4:2:2');
  FSubsamplingCombo.Items.Add('4:2:0');
  FSubsamplingCombo.ItemIndex := 0;
  FSubsamplingCombo.Enabled := False;
  FSubsamplingCombo.Hint := TR('Current FPC JPEG writer does not expose subsampling control.',
    '当前 FPC JPEG 编码器暂不暴露子采样控制。');
  FSubsamplingCombo.ShowHint := True;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 196, 312, 90);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('Subsampling is fixed by the current encoder backend. ' +
      'Quality/progressive/grayscale are fully applied.',
      '当前编码后端的子采样方式固定。质量/渐进/灰度选项会完整生效。');
end;

procedure TExportOptionsDialog.BuildPNGUI;
var
  LabelCtrl: TLabel;
  HelpLabel: TLabel;
begin
  Caption := TR('PNG Export Options', 'PNG 导出选项');

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Compression (0-9):', '压缩 (0-9)：');
  LabelCtrl.SetBounds(6, 12, 140, 18);

  FCompressionEdit := TEdit.Create(FOptionsHost);
  FCompressionEdit.Parent := FOptionsHost;
  FCompressionEdit.SetBounds(148, 8, 56, 24);
  FCompressionEdit.OnEditingDone := @CompressionEditDone;

  FCompressionTrack := TTrackBar.Create(FOptionsHost);
  FCompressionTrack.Parent := FOptionsHost;
  FCompressionTrack.SetBounds(6, 36, 312, 42);
  FCompressionTrack.Min := 0;
  FCompressionTrack.Max := 9;
  FCompressionTrack.Frequency := 1;
  FCompressionTrack.OnChange := @CompressionTrackChanged;
  FCompressionTrack.ShowSelRange := False;

  FAlphaCheck := TCheckBox.Create(FOptionsHost);
  FAlphaCheck.Parent := FOptionsHost;
  FAlphaCheck.Caption := TR('Preserve alpha channel', '保留 Alpha 通道');
  FAlphaCheck.SetBounds(6, 84, 220, 24);
  FAlphaCheck.OnChange := @OptionChanged;

  FPngGrayCheck := TCheckBox.Create(FOptionsHost);
  FPngGrayCheck.Parent := FOptionsHost;
  FPngGrayCheck.Caption := TR('Force grayscale', '强制灰度');
  FPngGrayCheck.SetBounds(6, 110, 220, 24);
  FPngGrayCheck.OnChange := @OptionChanged;

  FPngIndexedCheck := TCheckBox.Create(FOptionsHost);
  FPngIndexedCheck.Parent := FOptionsHost;
  FPngIndexedCheck.Caption := TR('Indexed palette mode', '索引色调色板模式');
  FPngIndexedCheck.SetBounds(6, 136, 220, 24);
  FPngIndexedCheck.OnChange := @OptionChanged;

  FPngWordSizedCheck := TCheckBox.Create(FOptionsHost);
  FPngWordSizedCheck.Parent := FOptionsHost;
  FPngWordSizedCheck.Caption := TR('16-bit channel output', '16 位通道输出');
  FPngWordSizedCheck.SetBounds(6, 162, 220, 24);
  FPngWordSizedCheck.OnChange := @OptionChanged;

  FPngCompressedTextCheck := TCheckBox.Create(FOptionsHost);
  FPngCompressedTextCheck.Parent := FOptionsHost;
  FPngCompressedTextCheck.Caption := TR('Compress PNG text chunks', '压缩 PNG 文本块');
  FPngCompressedTextCheck.SetBounds(6, 188, 260, 24);
  FPngCompressedTextCheck.OnChange := @OptionChanged;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 220, 312, 80);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('PNG is lossless: compression affects size and speed, not quality. ' +
      'Grayscale/indexed/16-bit affect encoding model.',
      'PNG 为无损格式：压缩仅影响体积与速度，不影响质量。灰度/索引/16位设置会影响编码模型。');
end;

procedure TExportOptionsDialog.BuildBMPUI;
var
  LabelCtrl: TLabel;
  HelpLabel: TLabel;
begin
  Caption := TR('BMP Export Options', 'BMP 导出选项');

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Bits per pixel:', '每像素位数：');
  LabelCtrl.SetBounds(6, 12, 140, 18);

  FBmpBitsCombo := TComboBox.Create(FOptionsHost);
  FBmpBitsCombo.Parent := FOptionsHost;
  FBmpBitsCombo.Style := csDropDownList;
  FBmpBitsCombo.SetBounds(148, 8, 88, 24);
  FBmpBitsCombo.Items.Add('24');
  FBmpBitsCombo.Items.Add('32');
  FBmpBitsCombo.OnChange := @OptionChanged;

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('X pixels/meter:', 'X 像素/米：');
  LabelCtrl.SetBounds(6, 46, 140, 18);

  FBmpXPelsEdit := TEdit.Create(FOptionsHost);
  FBmpXPelsEdit.Parent := FOptionsHost;
  FBmpXPelsEdit.SetBounds(148, 42, 88, 24);
  FBmpXPelsEdit.OnEditingDone := @OptionChanged;

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Y pixels/meter:', 'Y 像素/米：');
  LabelCtrl.SetBounds(6, 76, 140, 18);

  FBmpYPelsEdit := TEdit.Create(FOptionsHost);
  FBmpYPelsEdit.Parent := FOptionsHost;
  FBmpYPelsEdit.SetBounds(148, 72, 88, 24);
  FBmpYPelsEdit.OnEditingDone := @OptionChanged;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 112, 312, 96);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('Current save pipeline supports true-color BMP only (24/32 bpp). ' +
      'Pixels-per-meter stores output resolution metadata.',
      '当前仅支持真彩 BMP 保存（24/32 bpp）。每米像素数用于存储输出分辨率元数据。');
end;

procedure TExportOptionsDialog.BuildTIFFUI;
var
  HelpLabel: TLabel;
begin
  Caption := TR('TIFF Export Options', 'TIFF 导出选项');

  FTiffSaveCMYKCheck := TCheckBox.Create(FOptionsHost);
  FTiffSaveCMYKCheck.Parent := FOptionsHost;
  FTiffSaveCMYKCheck.Caption := TR('Save CMYK as RGB', 'CMYK 按 RGB 保存');
  FTiffSaveCMYKCheck.SetBounds(6, 12, 220, 24);
  FTiffSaveCMYKCheck.OnChange := @OptionChanged;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 50, 312, 84);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('This affects CMYK conversion behavior in TIFF output.',
      '该选项会影响 TIFF 导出时的 CMYK 转换行为。');
end;

procedure TExportOptionsDialog.BuildPCXUI;
var
  HelpLabel: TLabel;
begin
  Caption := TR('PCX Export Options', 'PCX 导出选项');

  FPcxCompressedCheck := TCheckBox.Create(FOptionsHost);
  FPcxCompressedCheck.Parent := FOptionsHost;
  FPcxCompressedCheck.Caption := TR('Enable compression', '启用压缩');
  FPcxCompressedCheck.SetBounds(6, 12, 220, 24);
  FPcxCompressedCheck.OnChange := @OptionChanged;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 50, 312, 84);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('Compressed output is smaller and is usually preferred.',
      '压缩输出文件更小，通常更推荐。');
end;

procedure TExportOptionsDialog.BuildPNMUI;
var
  LabelCtrl: TLabel;
  HelpLabel: TLabel;
begin
  Caption := TR('PNM Export Options', 'PNM 导出选项');

  FPnmBinaryCheck := TCheckBox.Create(FOptionsHost);
  FPnmBinaryCheck.Parent := FOptionsHost;
  FPnmBinaryCheck.Caption := TR('Binary output', '二进制输出');
  FPnmBinaryCheck.SetBounds(6, 12, 220, 24);
  FPnmBinaryCheck.OnChange := @OptionChanged;

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Color depth:', '颜色深度：');
  LabelCtrl.SetBounds(6, 46, 120, 18);

  FPnmDepthCombo := TComboBox.Create(FOptionsHost);
  FPnmDepthCombo.Parent := FOptionsHost;
  FPnmDepthCombo.Style := csDropDownList;
  FPnmDepthCombo.SetBounds(128, 42, 160, 24);
  FPnmDepthCombo.Items.Add(TR('Auto', '自动'));
  FPnmDepthCombo.Items.Add(TR('Black/White', '黑白'));
  FPnmDepthCombo.Items.Add(TR('Grayscale', '灰度'));
  FPnmDepthCombo.Items.Add(TR('RGB', 'RGB'));
  FPnmDepthCombo.OnChange := @OptionChanged;

  FPnmFullWidthCheck := TCheckBox.Create(FOptionsHost);
  FPnmFullWidthCheck.Parent := FOptionsHost;
  FPnmFullWidthCheck.Caption := TR('16-bit channel output (P5/P6)',
    '16 位通道输出 (P5/P6)');
  FPnmFullWidthCheck.SetBounds(6, 72, 260, 24);
  FPnmFullWidthCheck.OnChange := @OptionChanged;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 104, 312, 84);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('Binary off writes ASCII (portable but larger). ' +
      'Color depth controls whether PBM/PGM/PPM style data is forced. ' +
      '16-bit output auto-enables binary mode.',
      '关闭二进制时将输出 ASCII（兼容性更好但文件更大）。颜色深度决定是否强制使用 PBM/PGM/PPM 样式数据。16 位输出会自动启用二进制模式。');
end;

procedure TExportOptionsDialog.BuildXPMUI;
var
  LabelCtrl: TLabel;
  HelpLabel: TLabel;
begin
  Caption := TR('XPM Export Options', 'XPM 导出选项');

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Chars per pixel (1-8):', '每像素字符数 (1-8)：');
  LabelCtrl.SetBounds(6, 12, 160, 18);

  FXpmColorSizeEdit := TEdit.Create(FOptionsHost);
  FXpmColorSizeEdit.Parent := FOptionsHost;
  FXpmColorSizeEdit.SetBounds(172, 8, 64, 24);
  FXpmColorSizeEdit.OnEditingDone := @OptionChanged;

  LabelCtrl := TLabel.Create(FOptionsHost);
  LabelCtrl.Parent := FOptionsHost;
  LabelCtrl.Caption := TR('Palette chars (optional):', '调色板字符（可选）：');
  LabelCtrl.SetBounds(6, 46, 180, 18);

  FXpmPalCharsEdit := TEdit.Create(FOptionsHost);
  FXpmPalCharsEdit.Parent := FOptionsHost;
  FXpmPalCharsEdit.SetBounds(6, 66, 312, 24);
  FXpmPalCharsEdit.OnEditingDone := @OptionChanged;

  HelpLabel := TLabel.Create(FOptionsHost);
  HelpLabel.Parent := FOptionsHost;
  HelpLabel.SetBounds(6, 98, 312, 84);
  HelpLabel.WordWrap := True;
  HelpLabel.Caption :=
    TR('Chars-per-pixel controls index width. Palette chars can be left empty ' +
      'to let the writer use defaults.',
      '每像素字符数决定索引宽度。调色板字符可留空，使用编码器默认值。');
end;

constructor TExportOptionsDialog.CreateDialog(
  AOwner: TComponent;
  AFormat: TExportFormat;
  ASourceSurface: TRasterSurface;
  const AOptions: TSaveSurfaceOptions
);
begin
  inherited CreateNew(AOwner, 0);
  FFormat := AFormat;
  FOptions := AOptions;
  FPreviewSource := BuildPreviewSurface(ASourceSurface);

  BuildCommonUI;
  case FFormat of
    efJPEG: BuildJPEGUI;
    efPNG: BuildPNGUI;
    efBMP: BuildBMPUI;
    efTIFF: BuildTIFFUI;
    efPCX: BuildPCXUI;
    efPNM: BuildPNMUI;
    efXPM: BuildXPMUI;
  end;

  SyncControlsFromOptions;
  if FPreviewSource <> nil then
    ShowPreviewSurface(FPreviewSource);
  UpdatePreview;
end;

destructor TExportOptionsDialog.Destroy;
begin
  FPreviewSource.Free;
  inherited Destroy;
end;

function RunExportOptionsDialog(
  AOwner: TComponent;
  AFormat: TExportFormat;
  ASourceSurface: TRasterSurface;
  var AOptions: TSaveSurfaceOptions
): Boolean;
var
  Dialog: TExportOptionsDialog;
begin
  Dialog := TExportOptionsDialog.CreateDialog(AOwner, AFormat, ASourceSurface, AOptions);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
      AOptions := Dialog.Options;
  finally
    Dialog.Free;
  end;
end;

end.
