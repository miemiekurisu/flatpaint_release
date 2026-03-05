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
  SysUtils, Controls, StdCtrls, ComCtrls, FPI18n, FPLevelsHelpers;

type
  TLevelsDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FLevels: TLevelsSettings;
    FInputLowEdit: TEdit;
    FInputLowTrack: TTrackBar;
    FInputHighEdit: TEdit;
    FInputHighTrack: TTrackBar;
    FOutputLowEdit: TEdit;
    FOutputLowTrack: TTrackBar;
    FOutputHighEdit: TEdit;
    FOutputHighTrack: TTrackBar;
    procedure SyncFields;
    procedure InputLowEdited(Sender: TObject);
    procedure InputLowTrackChanged(Sender: TObject);
    procedure InputHighEdited(Sender: TObject);
    procedure InputHighTrackChanged(Sender: TObject);
    procedure OutputLowEdited(Sender: TObject);
    procedure OutputLowTrackChanged(Sender: TObject);
    procedure OutputHighEdited(Sender: TObject);
    procedure OutputHighTrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; const ALevels: TLevelsSettings);
    property Levels: TLevelsSettings read FLevels;
  end;

constructor TLevelsDialogForm.CreateDialog(AOwner: TComponent; const ALevels: TLevelsSettings);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
  RowTop: Integer;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := TR('Levels', #$E8#$89#$B2#$E9#$98#$B6);
  Position := poScreenCenter;
  Width := 400;
  Height := 360;
  ClientWidth := 400;
  ClientHeight := 360;

  FLevels := ALevels;
  NormalizeLevels(FLevels);

  RowTop := 14;

  { Input Low }
  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := TR('Input low:', #$E8#$BE#$93#$E5#$85#$A5#$E4#$BD#$8E':');

  FInputLowEdit := TEdit.Create(Self);
  FInputLowEdit.Parent := Self;
  FInputLowEdit.Left := 110;
  FInputLowEdit.Top := RowTop;
  FInputLowEdit.Width := 60;
  FInputLowEdit.OnEditingDone := @InputLowEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 180;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := '0..254';

  FInputLowTrack := TTrackBar.Create(Self);
  FInputLowTrack.Parent := Self;
  FInputLowTrack.Left := 14;
  FInputLowTrack.Top := RowTop + 28;
  FInputLowTrack.Width := 372;
  FInputLowTrack.Min := 0;
  FInputLowTrack.Max := 254;
  FInputLowTrack.Frequency := 16;
  FInputLowTrack.LineSize := 1;
  FInputLowTrack.PageSize := 8;
  FInputLowTrack.ShowSelRange := False;
  FInputLowTrack.OnChange := @InputLowTrackChanged;

  RowTop := RowTop + 72;

  { Input High }
  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := TR('Input high:', #$E8#$BE#$93#$E5#$85#$A5#$E9#$AB#$98':');

  FInputHighEdit := TEdit.Create(Self);
  FInputHighEdit.Parent := Self;
  FInputHighEdit.Left := 110;
  FInputHighEdit.Top := RowTop;
  FInputHighEdit.Width := 60;
  FInputHighEdit.OnEditingDone := @InputHighEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 180;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := '1..255';

  FInputHighTrack := TTrackBar.Create(Self);
  FInputHighTrack.Parent := Self;
  FInputHighTrack.Left := 14;
  FInputHighTrack.Top := RowTop + 28;
  FInputHighTrack.Width := 372;
  FInputHighTrack.Min := 1;
  FInputHighTrack.Max := 255;
  FInputHighTrack.Frequency := 16;
  FInputHighTrack.LineSize := 1;
  FInputHighTrack.PageSize := 8;
  FInputHighTrack.ShowSelRange := False;
  FInputHighTrack.OnChange := @InputHighTrackChanged;

  RowTop := RowTop + 72;

  { Output Low }
  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := TR('Output low:', #$E8#$BE#$93#$E5#$87#$BA#$E4#$BD#$8E':');

  FOutputLowEdit := TEdit.Create(Self);
  FOutputLowEdit.Parent := Self;
  FOutputLowEdit.Left := 110;
  FOutputLowEdit.Top := RowTop;
  FOutputLowEdit.Width := 60;
  FOutputLowEdit.OnEditingDone := @OutputLowEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 180;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := '0..254';

  FOutputLowTrack := TTrackBar.Create(Self);
  FOutputLowTrack.Parent := Self;
  FOutputLowTrack.Left := 14;
  FOutputLowTrack.Top := RowTop + 28;
  FOutputLowTrack.Width := 372;
  FOutputLowTrack.Min := 0;
  FOutputLowTrack.Max := 254;
  FOutputLowTrack.Frequency := 16;
  FOutputLowTrack.LineSize := 1;
  FOutputLowTrack.PageSize := 8;
  FOutputLowTrack.ShowSelRange := False;
  FOutputLowTrack.OnChange := @OutputLowTrackChanged;

  RowTop := RowTop + 72;

  { Output High }
  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := TR('Output high:', #$E8#$BE#$93#$E5#$87#$BA#$E9#$AB#$98':');

  FOutputHighEdit := TEdit.Create(Self);
  FOutputHighEdit.Parent := Self;
  FOutputHighEdit.Left := 110;
  FOutputHighEdit.Top := RowTop;
  FOutputHighEdit.Width := 60;
  FOutputHighEdit.OnEditingDone := @OutputHighEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 180;
  LabelCtrl.Top := RowTop + 4;
  LabelCtrl.Caption := '1..255';

  FOutputHighTrack := TTrackBar.Create(Self);
  FOutputHighTrack.Parent := Self;
  FOutputHighTrack.Left := 14;
  FOutputHighTrack.Top := RowTop + 28;
  FOutputHighTrack.Width := 372;
  FOutputHighTrack.Min := 1;
  FOutputHighTrack.Max := 255;
  FOutputHighTrack.Frequency := 16;
  FOutputHighTrack.LineSize := 1;
  FOutputHighTrack.PageSize := 8;
  FOutputHighTrack.ShowSelRange := False;
  FOutputHighTrack.OnChange := @OutputHighTrackChanged;

  RowTop := RowTop + 60;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 232;
  OkButton.Top := RowTop;
  OkButton.Width := 68;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 310;
  CancelButton.Top := RowTop;
  CancelButton.Width := 68;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TLevelsDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FInputLowEdit.Text := IntToStr(FLevels.InputLow);
    FInputLowTrack.Position := FLevels.InputLow;
    FInputHighEdit.Text := IntToStr(FLevels.InputHigh);
    FInputHighTrack.Position := FLevels.InputHigh;
    FOutputLowEdit.Text := IntToStr(FLevels.OutputLow);
    FOutputLowTrack.Position := FLevels.OutputLow;
    FOutputHighEdit.Text := IntToStr(FLevels.OutputHigh);
    FOutputHighTrack.Position := FLevels.OutputHigh;
  finally
    FUpdating := False;
  end;
end;

procedure TLevelsDialogForm.InputLowEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.InputLow := ClampInputLow(
    ParseLevelText(FInputLowEdit.Text, FLevels.InputLow, 0, 254),
    FLevels.InputHigh);
  FLevels.InputHigh := ClampInputHigh(FLevels.InputHigh, FLevels.InputLow);
  SyncFields;
end;

procedure TLevelsDialogForm.InputLowTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.InputLow := ClampInputLow(FInputLowTrack.Position, FLevels.InputHigh);
  FLevels.InputHigh := ClampInputHigh(FLevels.InputHigh, FLevels.InputLow);
  SyncFields;
end;

procedure TLevelsDialogForm.InputHighEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.InputHigh := ClampInputHigh(
    ParseLevelText(FInputHighEdit.Text, FLevels.InputHigh, 1, 255),
    FLevels.InputLow);
  FLevels.InputLow := ClampInputLow(FLevels.InputLow, FLevels.InputHigh);
  SyncFields;
end;

procedure TLevelsDialogForm.InputHighTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.InputHigh := ClampInputHigh(FInputHighTrack.Position, FLevels.InputLow);
  FLevels.InputLow := ClampInputLow(FLevels.InputLow, FLevels.InputHigh);
  SyncFields;
end;

procedure TLevelsDialogForm.OutputLowEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.OutputLow := ClampOutputLow(
    ParseLevelText(FOutputLowEdit.Text, FLevels.OutputLow, 0, 254));
  SyncFields;
end;

procedure TLevelsDialogForm.OutputLowTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.OutputLow := ClampOutputLow(FOutputLowTrack.Position);
  SyncFields;
end;

procedure TLevelsDialogForm.OutputHighEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.OutputHigh := ClampOutputHigh(
    ParseLevelText(FOutputHighEdit.Text, FLevels.OutputHigh, 1, 255));
  SyncFields;
end;

procedure TLevelsDialogForm.OutputHighTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FLevels.OutputHigh := ClampOutputHigh(FOutputHighTrack.Position);
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
