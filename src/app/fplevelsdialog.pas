unit FPLevelsDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunLevelsDialog(
  AOwner: TComponent;
  var AInputLow, AInputHigh, AOutputLow, AOutputHigh: Integer
): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, FPLevelsHelpers;

type
  TLevelsDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FLevels: TLevelsSettings;
    FInputLowEdit: TEdit;
    FInputHighEdit: TEdit;
    FOutputLowEdit: TEdit;
    FOutputHighEdit: TEdit;
    procedure SyncFields;
    procedure InputLowEdited(Sender: TObject);
    procedure InputHighEdited(Sender: TObject);
    procedure OutputLowEdited(Sender: TObject);
    procedure OutputHighEdited(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; const ALevels: TLevelsSettings);
    property Levels: TLevelsSettings read FLevels;
  end;

constructor TLevelsDialogForm.CreateDialog(AOwner: TComponent; const ALevels: TLevelsSettings);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Levels';
  Position := poScreenCenter;
  Width := 332;
  Height := 188;
  ClientWidth := 332;
  ClientHeight := 188;

  FLevels := ALevels;
  NormalizeLevels(FLevels);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := 'Input low:';

  FInputLowEdit := TEdit.Create(Self);
  FInputLowEdit.Parent := Self;
  FInputLowEdit.Left := 96;
  FInputLowEdit.Top := 14;
  FInputLowEdit.Width := 66;
  FInputLowEdit.OnEditingDone := @InputLowEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 174;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := '0 to 254';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 50;
  LabelCtrl.Caption := 'Input high:';

  FInputHighEdit := TEdit.Create(Self);
  FInputHighEdit.Parent := Self;
  FInputHighEdit.Left := 96;
  FInputHighEdit.Top := 46;
  FInputHighEdit.Width := 66;
  FInputHighEdit.OnEditingDone := @InputHighEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 174;
  LabelCtrl.Top := 50;
  LabelCtrl.Caption := '1 to 255';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 82;
  LabelCtrl.Caption := 'Output low:';

  FOutputLowEdit := TEdit.Create(Self);
  FOutputLowEdit.Parent := Self;
  FOutputLowEdit.Left := 96;
  FOutputLowEdit.Top := 78;
  FOutputLowEdit.Width := 66;
  FOutputLowEdit.OnEditingDone := @OutputLowEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 174;
  LabelCtrl.Top := 82;
  LabelCtrl.Caption := '0 to 254';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 114;
  LabelCtrl.Caption := 'Output high:';

  FOutputHighEdit := TEdit.Create(Self);
  FOutputHighEdit.Parent := Self;
  FOutputHighEdit.Left := 96;
  FOutputHighEdit.Top := 110;
  FOutputHighEdit.Width := 66;
  FOutputHighEdit.OnEditingDone := @OutputHighEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 174;
  LabelCtrl.Top := 114;
  LabelCtrl.Caption := '1 to 255';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 144;
  LabelCtrl.Caption := 'Input low/high stay ordered.';

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 178;
  OkButton.Top := 156;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 252;
  CancelButton.Top := 156;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TLevelsDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FInputLowEdit.Text := IntToStr(FLevels.InputLow);
    FInputHighEdit.Text := IntToStr(FLevels.InputHigh);
    FOutputLowEdit.Text := IntToStr(FLevels.OutputLow);
    FOutputHighEdit.Text := IntToStr(FLevels.OutputHigh);
  finally
    FUpdating := False;
  end;
end;

procedure TLevelsDialogForm.InputLowEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FLevels.InputLow := ClampInputLow(
    ParseLevelText(FInputLowEdit.Text, FLevels.InputLow, 0, 254),
    FLevels.InputHigh
  );
  FLevels.InputHigh := ClampInputHigh(FLevels.InputHigh, FLevels.InputLow);
  SyncFields;
end;

procedure TLevelsDialogForm.InputHighEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FLevels.InputHigh := ClampInputHigh(
    ParseLevelText(FInputHighEdit.Text, FLevels.InputHigh, 1, 255),
    FLevels.InputLow
  );
  FLevels.InputLow := ClampInputLow(FLevels.InputLow, FLevels.InputHigh);
  SyncFields;
end;

procedure TLevelsDialogForm.OutputLowEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FLevels.OutputLow := ClampOutputLow(
    ParseLevelText(FOutputLowEdit.Text, FLevels.OutputLow, 0, 254)
  );
  SyncFields;
end;

procedure TLevelsDialogForm.OutputHighEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FLevels.OutputHigh := ClampOutputHigh(
    ParseLevelText(FOutputHighEdit.Text, FLevels.OutputHigh, 1, 255)
  );
  SyncFields;
end;

function RunLevelsDialog(
  AOwner: TComponent;
  var AInputLow, AInputHigh, AOutputLow, AOutputHigh: Integer
): Boolean;
var
  Dialog: TLevelsDialogForm;
  Levels: TLevelsSettings;
begin
  Levels.InputLow := AInputLow;
  Levels.InputHigh := AInputHigh;
  Levels.OutputLow := AOutputLow;
  Levels.OutputHigh := AOutputHigh;

  Dialog := TLevelsDialogForm.CreateDialog(AOwner, Levels);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
    begin
      Levels := Dialog.Levels;
      AInputLow := Levels.InputLow;
      AInputHigh := Levels.InputHigh;
      AOutputLow := Levels.OutputLow;
      AOutputHigh := Levels.OutputHigh;
    end;
  finally
    Dialog.Free;
  end;
end;

end.
