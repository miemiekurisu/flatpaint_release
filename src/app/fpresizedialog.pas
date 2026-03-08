unit FPResizeDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, FPSurface;

function RunResizeImageDialog(
  AOwner: TComponent;
  var AWidth, AHeight: Integer;
  var AResampleMode: TResampleMode
): Boolean;
function RunResizeCanvasDialog(
  AOwner: TComponent;
  var AWidth, AHeight: Integer
): Boolean;

implementation

uses
  Controls, StdCtrls, ExtCtrls, FPResizeHelpers, FPi18n;

type
  TResizeDialogMode = (
    rdmImage,
    rdmCanvas
  );

  TResizeImageDialogForm = class(TForm)
  private
    FDialogMode: TResizeDialogMode;
    FUpdating: Boolean;
    FBaseWidth: Integer;
    FBaseHeight: Integer;
    FPixelWidth: Integer;
    FPixelHeight: Integer;
    FWidthEdit: TEdit;
    FHeightEdit: TEdit;
    FMaintainAspectBox: TCheckBox;
    FResampleCombo: TComboBox;
    procedure SyncFields;
    procedure WidthEdited(Sender: TObject);
    procedure HeightEdited(Sender: TObject);
    function ParsePixelValue(const AText: string; AFallback: Integer): Integer;
  public
    constructor CreateDialog(
      AOwner: TComponent;
      AWidth, AHeight: Integer;
      AResampleMode: TResampleMode;
      ADialogMode: TResizeDialogMode = rdmImage
    );
    function SelectedResampleMode: TResampleMode;
    property PixelWidth: Integer read FPixelWidth;
    property PixelHeight: Integer read FPixelHeight;
  end;

constructor TResizeImageDialogForm.CreateDialog(
  AOwner: TComponent;
  AWidth, AHeight: Integer;
  AResampleMode: TResampleMode;
  ADialogMode: TResizeDialogMode
);
var
  LabelCtrl: TLabel;
  SectionBevel: TBevel;
  OkButton: TButton;
  CancelButton: TButton;
  ButtonTop: Integer;
begin
  inherited CreateNew(AOwner, 0);
  FDialogMode := ADialogMode;
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  if FDialogMode = rdmCanvas then
    Caption := TR('Resize Canvas', #$E8#$B0#$83#$E6#$95#$B4#$E7#$94#$BB#$E5#$B8#$83#$E5#$A4#$A7#$E5#$B0#$8F)
  else
    Caption := TR('Resize Image', #$E8#$B0#$83#$E6#$95#$B4#$E5#$9B#$BE#$E5#$83#$8F#$E5#$A4#$A7#$E5#$B0#$8F);
  Position := poScreenCenter;
  Width := 272;
  ClientWidth := 272;
  if FDialogMode = rdmCanvas then
  begin
    Height := 156;
    ClientHeight := 156;
    ButtonTop := 122;
  end
  else
  begin
    Height := 188;
    ClientHeight := 188;
    ButtonTop := 154;
  end;

  FBaseWidth := ClampResizePixels(AWidth);
  FBaseHeight := ClampResizePixels(AHeight);
  FPixelWidth := FBaseWidth;
  FPixelHeight := FBaseHeight;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 10;
  LabelCtrl.Top := 12;
  LabelCtrl.Caption := TR('Pixel Size', #$E5#$83#$8F#$E7#$B4#$A0#$E5#$A4#$A7#$E5#$B0#$8F);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 22;
  LabelCtrl.Top := 38;
  LabelCtrl.Caption := TR('Width:', #$E5#$AE#$BD#$E5#$BA#$A6#$EF#$BC#$9A);

  FWidthEdit := TEdit.Create(Self);
  FWidthEdit.Parent := Self;
  FWidthEdit.Left := 86;
  FWidthEdit.Top := 34;
  FWidthEdit.Width := 72;
  FWidthEdit.OnEditingDone := @WidthEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 166;
  LabelCtrl.Top := 38;
  LabelCtrl.Caption := TR('pixels', #$E5#$83#$8F#$E7#$B4#$A0);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 22;
  LabelCtrl.Top := 66;
  LabelCtrl.Caption := TR('Height:', #$E9#$AB#$98#$E5#$BA#$A6#$EF#$BC#$9A);

  FHeightEdit := TEdit.Create(Self);
  FHeightEdit.Parent := Self;
  FHeightEdit.Left := 86;
  FHeightEdit.Top := 62;
  FHeightEdit.Width := 72;
  FHeightEdit.OnEditingDone := @HeightEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 166;
  LabelCtrl.Top := 66;
  LabelCtrl.Caption := TR('pixels', #$E5#$83#$8F#$E7#$B4#$A0);

  FMaintainAspectBox := TCheckBox.Create(Self);
  FMaintainAspectBox.Parent := Self;
  FMaintainAspectBox.Left := 10;
  FMaintainAspectBox.Top := 92;
  FMaintainAspectBox.Caption := TR('Maintain aspect ratio', #$E4#$BF#$9D#$E6#$8C#$81#$E9#$95#$BF#$E5#$AE#$BD#$E6#$AF#$94);
  FMaintainAspectBox.Checked := True;

  if FDialogMode = rdmImage then
  begin
    SectionBevel := TBevel.Create(Self);
    SectionBevel.Parent := Self;
    SectionBevel.Shape := bsTopLine;
    SectionBevel.Left := 8;
    SectionBevel.Top := 116;
    SectionBevel.Width := 256;
    SectionBevel.Height := 2;

    LabelCtrl := TLabel.Create(Self);
    LabelCtrl.Parent := Self;
    LabelCtrl.Left := 10;
    LabelCtrl.Top := 124;
    LabelCtrl.Caption := TR('Resampling:', #$E9#$87#$8D#$E9#$87#$87#$E6#$A0#$B7#$EF#$BC#$9A);

    FResampleCombo := TComboBox.Create(Self);
    FResampleCombo.Parent := Self;
    FResampleCombo.Left := 86;
    FResampleCombo.Top := 120;
    FResampleCombo.Width := 130;
    FResampleCombo.Style := csDropDownList;
    FResampleCombo.Items.Add(ResampleModeCaption(rmNearestNeighbor));
    FResampleCombo.Items.Add(ResampleModeCaption(rmBilinear));
    if AResampleMode = rmBilinear then
      FResampleCombo.ItemIndex := 1
    else
      FResampleCombo.ItemIndex := 0;
  end
  else
  begin
    SectionBevel := TBevel.Create(Self);
    SectionBevel.Parent := Self;
    SectionBevel.Shape := bsTopLine;
    SectionBevel.Left := 8;
    SectionBevel.Top := 114;
    SectionBevel.Width := 256;
    SectionBevel.Height := 2;
    FResampleCombo := nil;
  end;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 110;
  OkButton.Top := ButtonTop;
  OkButton.Width := 70;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 186;
  CancelButton.Top := ButtonTop;
  CancelButton.Width := 70;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

function TResizeImageDialogForm.ParsePixelValue(const AText: string; AFallback: Integer): Integer;
begin
  Result := ClampResizePixels(StrToIntDef(Trim(AText), AFallback));
end;

procedure TResizeImageDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FWidthEdit.Text := IntToStr(FPixelWidth);
    FHeightEdit.Text := IntToStr(FPixelHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TResizeImageDialogForm.WidthEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FPixelWidth := ParsePixelValue(FWidthEdit.Text, FPixelWidth);
  if FMaintainAspectBox.Checked then
    FPixelHeight := LinkedResizeValue(FPixelWidth, FBaseWidth, FBaseHeight)
  else
    FPixelHeight := ParsePixelValue(FHeightEdit.Text, FPixelHeight);
  SyncFields;
end;

procedure TResizeImageDialogForm.HeightEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FPixelHeight := ParsePixelValue(FHeightEdit.Text, FPixelHeight);
  if FMaintainAspectBox.Checked then
    FPixelWidth := LinkedResizeValue(FPixelHeight, FBaseHeight, FBaseWidth)
  else
    FPixelWidth := ParsePixelValue(FWidthEdit.Text, FPixelWidth);
  SyncFields;
end;

function TResizeImageDialogForm.SelectedResampleMode: TResampleMode;
begin
  if not Assigned(FResampleCombo) then
    Exit(rmNearestNeighbor);
  if FResampleCombo.ItemIndex = 1 then
    Result := rmBilinear
  else
    Result := rmNearestNeighbor;
end;

function RunResizeImageDialog(
  AOwner: TComponent;
  var AWidth, AHeight: Integer;
  var AResampleMode: TResampleMode
): Boolean;
var
  Dialog: TResizeImageDialogForm;
begin
  Dialog := TResizeImageDialogForm.CreateDialog(AOwner, AWidth, AHeight, AResampleMode);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
    begin
      AWidth := Dialog.PixelWidth;
      AHeight := Dialog.PixelHeight;
      AResampleMode := Dialog.SelectedResampleMode;
    end;
  finally
    Dialog.Free;
  end;
end;

function RunResizeCanvasDialog(
  AOwner: TComponent;
  var AWidth, AHeight: Integer
): Boolean;
var
  Dialog: TResizeImageDialogForm;
begin
  Dialog := TResizeImageDialogForm.CreateDialog(
    AOwner,
    AWidth,
    AHeight,
    rmNearestNeighbor,
    rdmCanvas
  );
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
    begin
      AWidth := Dialog.PixelWidth;
      AHeight := Dialog.PixelHeight;
    end;
  finally
    Dialog.Free;
  end;
end;

end.
