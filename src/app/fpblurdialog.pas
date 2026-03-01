unit FPBlurDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunBlurDialog(AOwner: TComponent; var ARadius: Integer): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, ComCtrls, FPBlurHelpers;

type
  TBlurDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FRadius: Integer;
    FRadiusEdit: TEdit;
    FRadiusTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure RadiusEdited(Sender: TObject);
    procedure RadiusTrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; ARadius: Integer);
    property Radius: Integer read FRadius;
  end;

constructor TBlurDialogForm.CreateDialog(AOwner: TComponent; ARadius: Integer);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Blur';
  Position := poScreenCenter;
  Width := 332;
  Height := 186;
  ClientWidth := 332;
  ClientHeight := 186;

  FRadius := ClampBlurRadius(ARadius);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := 'Radius:';

  FRadiusEdit := TEdit.Create(Self);
  FRadiusEdit.Parent := Self;
  FRadiusEdit.Left := 68;
  FRadiusEdit.Top := 14;
  FRadiusEdit.Width := 56;
  FRadiusEdit.OnEditingDone := @RadiusEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 136;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := '1 to 64';

  FRadiusTrack := TTrackBar.Create(Self);
  FRadiusTrack.Parent := Self;
  FRadiusTrack.Left := 14;
  FRadiusTrack.Top := 44;
  FRadiusTrack.Width := 304;
  FRadiusTrack.Min := 1;
  FRadiusTrack.Max := 64;
  FRadiusTrack.Frequency := 6;
  FRadiusTrack.LineSize := 1;
  FRadiusTrack.PageSize := 4;
  FRadiusTrack.ShowSelRange := False;
  FRadiusTrack.OnChange := @RadiusTrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 106;
  FPreviewLabel.Width := 304;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 128;
  LabelCtrl.Caption := 'Higher values soften edges more strongly.';

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 178;
  OkButton.Top := 148;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 252;
  CancelButton.Top := 148;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TBlurDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FRadius := ClampBlurRadius(FRadius);
    FRadiusEdit.Text := IntToStr(FRadius);
    FRadiusTrack.Position := BlurRadiusToSliderPosition(FRadius);
    FPreviewLabel.Caption := 'Current blur radius: ' + IntToStr(FRadius);
  finally
    FUpdating := False;
  end;
end;

procedure TBlurDialogForm.RadiusEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FRadius := ParseBlurText(FRadiusEdit.Text, FRadius);
  SyncFields;
end;

procedure TBlurDialogForm.RadiusTrackChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FRadius := SliderPositionToBlurRadius(FRadiusTrack.Position);
  SyncFields;
end;

function RunBlurDialog(AOwner: TComponent; var ARadius: Integer): Boolean;
var
  Dialog: TBlurDialogForm;
begin
  Dialog := TBlurDialogForm.CreateDialog(AOwner, ARadius);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
      ARadius := Dialog.Radius;
  finally
    Dialog.Free;
  end;
end;

end.
