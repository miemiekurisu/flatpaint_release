unit FPNoiseDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunNoiseDialog(AOwner: TComponent; var AAmount: Integer): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, ComCtrls, FPNoiseHelpers;

type
  TNoiseDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FAmount: Integer;
    FAmountEdit: TEdit;
    FAmountTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure AmountEdited(Sender: TObject);
    procedure AmountTrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; AAmount: Integer);
    property Amount: Integer read FAmount;
  end;

constructor TNoiseDialogForm.CreateDialog(AOwner: TComponent; AAmount: Integer);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Add Noise';
  Position := poScreenCenter;
  Width := 340;
  Height := 186;
  ClientWidth := 340;
  ClientHeight := 186;

  FAmount := ClampNoiseAmount(AAmount);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := 'Amount:';

  FAmountEdit := TEdit.Create(Self);
  FAmountEdit.Parent := Self;
  FAmountEdit.Left := 72;
  FAmountEdit.Top := 14;
  FAmountEdit.Width := 56;
  FAmountEdit.OnEditingDone := @AmountEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 140;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := '0 to 255';

  FAmountTrack := TTrackBar.Create(Self);
  FAmountTrack.Parent := Self;
  FAmountTrack.Left := 14;
  FAmountTrack.Top := 44;
  FAmountTrack.Width := 312;
  FAmountTrack.Min := 0;
  FAmountTrack.Max := 255;
  FAmountTrack.Frequency := 25;
  FAmountTrack.LineSize := 5;
  FAmountTrack.PageSize := 20;
  FAmountTrack.ShowSelRange := False;
  FAmountTrack.OnChange := @AmountTrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 106;
  FPreviewLabel.Width := 312;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 128;
  LabelCtrl.Caption := 'Higher values add stronger grain.';

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 186;
  OkButton.Top := 148;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 260;
  CancelButton.Top := 148;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TNoiseDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FAmount := ClampNoiseAmount(FAmount);
    FAmountEdit.Text := IntToStr(FAmount);
    FAmountTrack.Position := NoiseAmountToSliderPosition(FAmount);
    FPreviewLabel.Caption := 'Current noise amount: ' + IntToStr(FAmount);
  finally
    FUpdating := False;
  end;
end;

procedure TNoiseDialogForm.AmountEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FAmount := ParseNoiseText(FAmountEdit.Text, FAmount);
  SyncFields;
end;

procedure TNoiseDialogForm.AmountTrackChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FAmount := SliderPositionToNoiseAmount(FAmountTrack.Position);
  SyncFields;
end;

function RunNoiseDialog(AOwner: TComponent; var AAmount: Integer): Boolean;
var
  Dialog: TNoiseDialogForm;
begin
  Dialog := TNoiseDialogForm.CreateDialog(AOwner, AAmount);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
      AAmount := Dialog.Amount;
  finally
    Dialog.Free;
  end;
end;

end.
