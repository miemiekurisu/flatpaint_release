unit FPSettingsDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms;

function RunSettingsDialog(AOwner: TComponent; var ADefaultResolutionDPI: Double; var ADisplayUnitIndex: Integer): Boolean;

implementation

uses
  Controls, StdCtrls, Math, FPNewImageHelpers;

type
  TSettingsDialogForm = class(TForm)
  private
    FResolutionEdit: TEdit;
    FUnitsCombo: TComboBox;
  public
    constructor CreateDialog(AOwner: TComponent; ADefaultResolutionDPI: Double; ADisplayUnitIndex: Integer);
    function ResolutionDPI: Double;
    function DisplayUnitIndex: Integer;
  end;

constructor TSettingsDialogForm.CreateDialog(AOwner: TComponent; ADefaultResolutionDPI: Double; ADisplayUnitIndex: Integer);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Settings';
  Position := poScreenCenter;
  ClientWidth := 260;
  ClientHeight := 132;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 12;
  LabelCtrl.Top := 16;
  LabelCtrl.Caption := 'Default New Image DPI:';

  FResolutionEdit := TEdit.Create(Self);
  FResolutionEdit.Parent := Self;
  FResolutionEdit.Left := 148;
  FResolutionEdit.Top := 12;
  FResolutionEdit.Width := 84;
  FResolutionEdit.Text := FormatFloat('0.00', ClampResolutionDPI(ADefaultResolutionDPI));

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 12;
  LabelCtrl.Top := 50;
  LabelCtrl.Caption := 'Display Units:';

  FUnitsCombo := TComboBox.Create(Self);
  FUnitsCombo.Parent := Self;
  FUnitsCombo.Left := 148;
  FUnitsCombo.Top := 46;
  FUnitsCombo.Width := 84;
  FUnitsCombo.Style := csDropDownList;
  FUnitsCombo.Items.Add('Pixels');
  FUnitsCombo.Items.Add('Inches');
  FUnitsCombo.Items.Add('Centimeters');
  FUnitsCombo.ItemIndex := EnsureRange(ADisplayUnitIndex, 0, 2);

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 82;
  OkButton.Top := 90;
  OkButton.Width := 76;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 164;
  CancelButton.Top := 90;
  CancelButton.Width := 76;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;
end;

function TSettingsDialogForm.ResolutionDPI: Double;
var
  ParsedValue: Double;
begin
  ParsedValue := StrToFloatDef(Trim(FResolutionEdit.Text), 96.0);
  Result := ClampResolutionDPI(ParsedValue);
end;

function TSettingsDialogForm.DisplayUnitIndex: Integer;
begin
  Result := EnsureRange(FUnitsCombo.ItemIndex, 0, 2);
end;

function RunSettingsDialog(AOwner: TComponent; var ADefaultResolutionDPI: Double; var ADisplayUnitIndex: Integer): Boolean;
var
  DialogForm: TSettingsDialogForm;
begin
  DialogForm := TSettingsDialogForm.CreateDialog(AOwner, ADefaultResolutionDPI, ADisplayUnitIndex);
  try
    Result := DialogForm.ShowModal = mrOK;
    if not Result then
      Exit;
    ADefaultResolutionDPI := DialogForm.ResolutionDPI;
    ADisplayUnitIndex := DialogForm.DisplayUnitIndex;
  finally
    DialogForm.Free;
  end;
end;

end.
