unit FPBrightnessContrastDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunBrightnessContrastDialog(
  AOwner: TComponent;
  var ABrightness, AContrast: Integer
): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, FPBrightnessContrastHelpers;

type
  TBrightnessContrastDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FSettings: TBrightnessContrastSettings;
    FBrightnessEdit: TEdit;
    FContrastEdit: TEdit;
    procedure SyncFields;
    procedure BrightnessEdited(Sender: TObject);
    procedure ContrastEdited(Sender: TObject);
  public
    constructor CreateDialog(
      AOwner: TComponent;
      const ASettings: TBrightnessContrastSettings
    );
    property Settings: TBrightnessContrastSettings read FSettings;
  end;

constructor TBrightnessContrastDialogForm.CreateDialog(
  AOwner: TComponent;
  const ASettings: TBrightnessContrastSettings
);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Brightness / Contrast';
  Position := poScreenCenter;
  Width := 308;
  Height := 152;
  ClientWidth := 308;
  ClientHeight := 152;

  FSettings := ASettings;
  FSettings.Brightness := ClampBrightnessDelta(FSettings.Brightness);
  FSettings.Contrast := ClampContrastAmount(FSettings.Contrast);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := 'Brightness:';

  FBrightnessEdit := TEdit.Create(Self);
  FBrightnessEdit.Parent := Self;
  FBrightnessEdit.Left := 98;
  FBrightnessEdit.Top := 14;
  FBrightnessEdit.Width := 74;
  FBrightnessEdit.OnEditingDone := @BrightnessEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 184;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := '-255 to 255';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 52;
  LabelCtrl.Caption := 'Contrast:';

  FContrastEdit := TEdit.Create(Self);
  FContrastEdit.Parent := Self;
  FContrastEdit.Left := 98;
  FContrastEdit.Top := 48;
  FContrastEdit.Width := 74;
  FContrastEdit.OnEditingDone := @ContrastEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 184;
  LabelCtrl.Top := 52;
  LabelCtrl.Caption := '-255 to 254';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 84;
  LabelCtrl.Caption := 'Applies brightness, then contrast.';

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 154;
  OkButton.Top := 112;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 228;
  CancelButton.Top := 112;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TBrightnessContrastDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FBrightnessEdit.Text := IntToStr(FSettings.Brightness);
    FContrastEdit.Text := IntToStr(FSettings.Contrast);
  finally
    FUpdating := False;
  end;
end;

procedure TBrightnessContrastDialogForm.BrightnessEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FSettings.Brightness := ClampBrightnessDelta(
    ParseAdjustmentText(FBrightnessEdit.Text, FSettings.Brightness, -255, 255)
  );
  SyncFields;
end;

procedure TBrightnessContrastDialogForm.ContrastEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FSettings.Contrast := ClampContrastAmount(
    ParseAdjustmentText(FContrastEdit.Text, FSettings.Contrast, -255, 254)
  );
  SyncFields;
end;

function RunBrightnessContrastDialog(
  AOwner: TComponent;
  var ABrightness, AContrast: Integer
): Boolean;
var
  Dialog: TBrightnessContrastDialogForm;
  Settings: TBrightnessContrastSettings;
begin
  Settings.Brightness := ABrightness;
  Settings.Contrast := AContrast;

  Dialog := TBrightnessContrastDialogForm.CreateDialog(AOwner, Settings);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
    begin
      Settings := Dialog.Settings;
      ABrightness := Settings.Brightness;
      AContrast := Settings.Contrast;
    end;
  finally
    Dialog.Free;
  end;
end;

end.
