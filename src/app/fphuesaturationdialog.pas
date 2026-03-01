unit FPHueSaturationDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunHueSaturationDialog(
  AOwner: TComponent;
  var AHueDelta, ASaturationDelta: Integer
): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, FPHueSaturationHelpers;

type
  THueSaturationDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FHueDelta: Integer;
    FSaturationDelta: Integer;
    FHueEdit: TEdit;
    FSaturationEdit: TEdit;
    procedure SyncFields;
    procedure HueEdited(Sender: TObject);
    procedure SaturationEdited(Sender: TObject);
  public
    constructor CreateDialog(
      AOwner: TComponent;
      AHueDelta, ASaturationDelta: Integer
    );
    property HueDelta: Integer read FHueDelta;
    property SaturationDelta: Integer read FSaturationDelta;
  end;

constructor THueSaturationDialogForm.CreateDialog(
  AOwner: TComponent;
  AHueDelta, ASaturationDelta: Integer
);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Hue / Saturation';
  Position := poScreenCenter;
  Width := 294;
  Height := 152;
  ClientWidth := 294;
  ClientHeight := 152;

  FHueDelta := ClampHueDelta(AHueDelta);
  FSaturationDelta := ClampSaturationDelta(ASaturationDelta);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := 'Hue shift:';

  FHueEdit := TEdit.Create(Self);
  FHueEdit.Parent := Self;
  FHueEdit.Left := 104;
  FHueEdit.Top := 14;
  FHueEdit.Width := 70;
  FHueEdit.OnEditingDone := @HueEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 184;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := '-180 to 180';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 52;
  LabelCtrl.Caption := 'Saturation:';

  FSaturationEdit := TEdit.Create(Self);
  FSaturationEdit.Parent := Self;
  FSaturationEdit.Left := 104;
  FSaturationEdit.Top := 48;
  FSaturationEdit.Width := 70;
  FSaturationEdit.OnEditingDone := @SaturationEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 184;
  LabelCtrl.Top := 52;
  LabelCtrl.Caption := '-100 to 100';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 82;
  LabelCtrl.Caption := 'Use positive values to intensify the effect.';

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 140;
  OkButton.Top := 112;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 214;
  CancelButton.Top := 112;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure THueSaturationDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FHueEdit.Text := IntToStr(FHueDelta);
    FSaturationEdit.Text := IntToStr(FSaturationDelta);
  finally
    FUpdating := False;
  end;
end;

procedure THueSaturationDialogForm.HueEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FHueDelta := ClampHueDelta(ParseDeltaText(FHueEdit.Text, FHueDelta, -180, 180));
  SyncFields;
end;

procedure THueSaturationDialogForm.SaturationEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FSaturationDelta := ClampSaturationDelta(
    ParseDeltaText(FSaturationEdit.Text, FSaturationDelta, -100, 100)
  );
  SyncFields;
end;

function RunHueSaturationDialog(
  AOwner: TComponent;
  var AHueDelta, ASaturationDelta: Integer
): Boolean;
var
  Dialog: THueSaturationDialogForm;
begin
  Dialog := THueSaturationDialogForm.CreateDialog(AOwner, AHueDelta, ASaturationDelta);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
    begin
      AHueDelta := Dialog.HueDelta;
      ASaturationDelta := Dialog.SaturationDelta;
    end;
  finally
    Dialog.Free;
  end;
end;

end.
