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
  SysUtils, Controls, StdCtrls, ComCtrls, FPI18n, FPBrightnessContrastHelpers;

type
  TBrightnessContrastDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FSettings: TBrightnessContrastSettings;
    FBrightnessEdit: TEdit;
    FBrightnessTrack: TTrackBar;
    FContrastEdit: TEdit;
    FContrastTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure BrightnessEdited(Sender: TObject);
    procedure BrightnessTrackChanged(Sender: TObject);
    procedure ContrastEdited(Sender: TObject);
    procedure ContrastTrackChanged(Sender: TObject);
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
  Caption := TR('Brightness / Contrast', #$E4#$BA#$AE#$E5#$BA#$A6' / '#$E5#$AF#$B9#$E6#$AF#$94#$E5#$BA#$A6);
  Position := poScreenCenter;
  Width := 360;
  Height := 240;
  ClientWidth := 360;
  ClientHeight := 240;

  FSettings := ASettings;
  FSettings.Brightness := ClampBrightnessDelta(FSettings.Brightness);
  FSettings.Contrast := ClampContrastAmount(FSettings.Contrast);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('Brightness:', #$E4#$BA#$AE#$E5#$BA#$A6':');

  FBrightnessEdit := TEdit.Create(Self);
  FBrightnessEdit.Parent := Self;
  FBrightnessEdit.Left := 104;
  FBrightnessEdit.Top := 14;
  FBrightnessEdit.Width := 74;
  FBrightnessEdit.OnEditingDone := @BrightnessEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 188;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := '-255 .. 255';

  FBrightnessTrack := TTrackBar.Create(Self);
  FBrightnessTrack.Parent := Self;
  FBrightnessTrack.Left := 14;
  FBrightnessTrack.Top := 40;
  FBrightnessTrack.Width := 332;
  FBrightnessTrack.Min := -255;
  FBrightnessTrack.Max := 255;
  FBrightnessTrack.Frequency := 32;
  FBrightnessTrack.LineSize := 1;
  FBrightnessTrack.PageSize := 16;
  FBrightnessTrack.ShowSelRange := False;
  FBrightnessTrack.OnChange := @BrightnessTrackChanged;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 90;
  LabelCtrl.Caption := TR('Contrast:', #$E5#$AF#$B9#$E6#$AF#$94#$E5#$BA#$A6':');

  FContrastEdit := TEdit.Create(Self);
  FContrastEdit.Parent := Self;
  FContrastEdit.Left := 104;
  FContrastEdit.Top := 86;
  FContrastEdit.Width := 74;
  FContrastEdit.OnEditingDone := @ContrastEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 188;
  LabelCtrl.Top := 90;
  LabelCtrl.Caption := '-255 .. 254';

  FContrastTrack := TTrackBar.Create(Self);
  FContrastTrack.Parent := Self;
  FContrastTrack.Left := 14;
  FContrastTrack.Top := 112;
  FContrastTrack.Width := 332;
  FContrastTrack.Min := -255;
  FContrastTrack.Max := 254;
  FContrastTrack.Frequency := 32;
  FContrastTrack.LineSize := 1;
  FContrastTrack.PageSize := 16;
  FContrastTrack.ShowSelRange := False;
  FContrastTrack.OnChange := @ContrastTrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 162;
  FPreviewLabel.Width := 332;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 200;
  OkButton.Top := 196;
  OkButton.Width := 68;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 278;
  CancelButton.Top := 196;
  CancelButton.Width := 68;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TBrightnessContrastDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FBrightnessEdit.Text := IntToStr(FSettings.Brightness);
    FBrightnessTrack.Position := FSettings.Brightness;
    FContrastEdit.Text := IntToStr(FSettings.Contrast);
    FContrastTrack.Position := FSettings.Contrast;
    FPreviewLabel.Caption := TR('Brightness: ', #$E4#$BA#$AE#$E5#$BA#$A6': ') + IntToStr(FSettings.Brightness)
      + '  ' + TR('Contrast: ', #$E5#$AF#$B9#$E6#$AF#$94#$E5#$BA#$A6': ') + IntToStr(FSettings.Contrast);
  finally
    FUpdating := False;
  end;
end;

procedure TBrightnessContrastDialogForm.BrightnessEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FSettings.Brightness := ClampBrightnessDelta(
    ParseAdjustmentText(FBrightnessEdit.Text, FSettings.Brightness, -255, 255));
  SyncFields;
end;

procedure TBrightnessContrastDialogForm.BrightnessTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FSettings.Brightness := ClampBrightnessDelta(FBrightnessTrack.Position);
  SyncFields;
end;

procedure TBrightnessContrastDialogForm.ContrastEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FSettings.Contrast := ClampContrastAmount(
    ParseAdjustmentText(FContrastEdit.Text, FSettings.Contrast, -255, 254));
  SyncFields;
end;

procedure TBrightnessContrastDialogForm.ContrastTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FSettings.Contrast := ClampContrastAmount(FContrastTrack.Position);
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
