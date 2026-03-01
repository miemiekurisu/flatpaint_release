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

implementation

uses
  Controls, StdCtrls, ExtCtrls, FPResizeHelpers;

type
  TResizeImageDialogForm = class(TForm)
  private
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
      AResampleMode: TResampleMode
    );
    function SelectedResampleMode: TResampleMode;
    property PixelWidth: Integer read FPixelWidth;
    property PixelHeight: Integer read FPixelHeight;
  end;

constructor TResizeImageDialogForm.CreateDialog(
  AOwner: TComponent;
  AWidth, AHeight: Integer;
  AResampleMode: TResampleMode
);
var
  LabelCtrl: TLabel;
  SectionBevel: TBevel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Resize Image';
  Position := poScreenCenter;
  Width := 272;
  Height := 188;
  ClientWidth := 272;
  ClientHeight := 188;

  FBaseWidth := ClampResizePixels(AWidth);
  FBaseHeight := ClampResizePixels(AHeight);
  FPixelWidth := FBaseWidth;
  FPixelHeight := FBaseHeight;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 10;
  LabelCtrl.Top := 12;
  LabelCtrl.Caption := 'Pixel Size';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 22;
  LabelCtrl.Top := 38;
  LabelCtrl.Caption := 'Width:';

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
  LabelCtrl.Caption := 'pixels';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 22;
  LabelCtrl.Top := 66;
  LabelCtrl.Caption := 'Height:';

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
  LabelCtrl.Caption := 'pixels';

  FMaintainAspectBox := TCheckBox.Create(Self);
  FMaintainAspectBox.Parent := Self;
  FMaintainAspectBox.Left := 10;
  FMaintainAspectBox.Top := 92;
  FMaintainAspectBox.Caption := 'Maintain aspect ratio';
  FMaintainAspectBox.Checked := True;

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
  LabelCtrl.Caption := 'Resampling:';

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

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 110;
  OkButton.Top := 154;
  OkButton.Width := 70;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 186;
  CancelButton.Top := 154;
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

end.
