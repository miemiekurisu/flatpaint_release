unit FPSettingsDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, FPI18n;

function RunSettingsDialog(AOwner: TComponent; var ADefaultResolutionDPI: Double; var ADisplayUnitIndex: Integer; var ALanguage: TAppLanguage): Boolean;

implementation

uses
  Controls, StdCtrls, Math, FPNewImageHelpers;

type
  TSettingsDialogForm = class(TForm)
  private
    FResolutionEdit: TEdit;
    FUnitsCombo: TComboBox;
    FLanguageCombo: TComboBox;
  public
    constructor CreateDialog(AOwner: TComponent; ADefaultResolutionDPI: Double; ADisplayUnitIndex: Integer; ALanguage: TAppLanguage);
    function ResolutionDPI: Double;
    function DisplayUnitIndex: Integer;
    function SelectedLanguage: TAppLanguage;
  end;

constructor TSettingsDialogForm.CreateDialog(AOwner: TComponent; ADefaultResolutionDPI: Double; ADisplayUnitIndex: Integer; ALanguage: TAppLanguage);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
  LangIdx: TAppLanguage;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := TR('Settings', #$E8#$AE#$BE#$E7#$BD#$AE);
  Position := poScreenCenter;
  ClientWidth := 300;
  ClientHeight := 170;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 12;
  LabelCtrl.Top := 16;
  LabelCtrl.Caption := TR('Default New Image DPI:', #$E9#$BB#$98#$E8#$AE#$A4#$E6#$96#$B0#$E5#$BB#$BA#$E5#$9B#$BE#$E5#$83#$8F' DPI:');

  FResolutionEdit := TEdit.Create(Self);
  FResolutionEdit.Parent := Self;
  FResolutionEdit.Left := 188;
  FResolutionEdit.Top := 12;
  FResolutionEdit.Width := 84;
  FResolutionEdit.Text := FormatFloat('0.00', ClampResolutionDPI(ADefaultResolutionDPI));

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 12;
  LabelCtrl.Top := 50;
  LabelCtrl.Caption := TR('Display Units:', #$E6#$98#$BE#$E7#$A4#$BA#$E5#$8D#$95#$E4#$BD#$8D#$EF#$BC#$9A);

  FUnitsCombo := TComboBox.Create(Self);
  FUnitsCombo.Parent := Self;
  FUnitsCombo.Left := 188;
  FUnitsCombo.Top := 46;
  FUnitsCombo.Width := 84;
  FUnitsCombo.Style := csDropDownList;
  FUnitsCombo.Items.Add(TR('Pixels', #$E5#$83#$8F#$E7#$B4#$A0));
  FUnitsCombo.Items.Add(TR('Inches', #$E8#$8B#$B1#$E5#$AF#$B8));
  FUnitsCombo.Items.Add(TR('Centimeters', #$E5#$8E#$98#$E7#$B1#$B3));
  FUnitsCombo.ItemIndex := EnsureRange(ADisplayUnitIndex, 0, 2);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 12;
  LabelCtrl.Top := 84;
  LabelCtrl.Caption := TR('Language:', #$E8#$AF#$AD#$E8#$A8#$80#$EF#$BC#$9A);

  FLanguageCombo := TComboBox.Create(Self);
  FLanguageCombo.Parent := Self;
  FLanguageCombo.Left := 188;
  FLanguageCombo.Top := 80;
  FLanguageCombo.Width := 84;
  FLanguageCombo.Style := csDropDownList;
  for LangIdx := Low(TAppLanguage) to High(TAppLanguage) do
    FLanguageCombo.Items.Add(AppLanguageName(LangIdx));
  FLanguageCombo.ItemIndex := Ord(ALanguage);

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 122;
  OkButton.Top := 128;
  OkButton.Width := 76;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 204;
  CancelButton.Top := 128;
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

function TSettingsDialogForm.SelectedLanguage: TAppLanguage;
begin
  if (FLanguageCombo.ItemIndex >= 0) and (FLanguageCombo.ItemIndex <= Ord(High(TAppLanguage))) then
    Result := TAppLanguage(FLanguageCombo.ItemIndex)
  else
    Result := alEnglish;
end;

function RunSettingsDialog(AOwner: TComponent; var ADefaultResolutionDPI: Double; var ADisplayUnitIndex: Integer; var ALanguage: TAppLanguage): Boolean;
var
  DialogForm: TSettingsDialogForm;
begin
  DialogForm := TSettingsDialogForm.CreateDialog(AOwner, ADefaultResolutionDPI, ADisplayUnitIndex, ALanguage);
  try
    Result := DialogForm.ShowModal = mrOK;
    if not Result then
      Exit;
    ADefaultResolutionDPI := DialogForm.ResolutionDPI;
    ADisplayUnitIndex := DialogForm.DisplayUnitIndex;
    ALanguage := DialogForm.SelectedLanguage;
  finally
    DialogForm.Free;
  end;
end;

end.
