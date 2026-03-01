unit FPNewImageDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms;

function RunNewImageDialog(AOwner: TComponent; var AWidth, AHeight: Integer; var AResolutionDPI: Double): Boolean;

implementation

uses
  Controls, StdCtrls, ExtCtrls, Math, FPNewImageHelpers;

type
  TNewImageDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FPixelWidth: Integer;
    FPixelHeight: Integer;
    FResolutionDPI: Double;
    FPixelWidthEdit: TEdit;
    FPixelHeightEdit: TEdit;
    FResolutionEdit: TEdit;
    FPrintWidthEdit: TEdit;
    FPrintHeightEdit: TEdit;
    FSizeLabel: TLabel;
    FMaintainAspectBox: TCheckBox;
    FPrintUnitCombo: TComboBox;
    function CurrentPrintUnit: TPrintMeasurementUnit;
    function ParseFloatValue(const AText: string; AFallback: Double): Double;
    procedure SyncFields;
    procedure PixelWidthEdited(Sender: TObject);
    procedure PixelHeightEdited(Sender: TObject);
    procedure ResolutionEdited(Sender: TObject);
    procedure PrintWidthEdited(Sender: TObject);
    procedure PrintHeightEdited(Sender: TObject);
    procedure PrintUnitChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; AWidth, AHeight: Integer; AResolutionDPI: Double);
    property PixelWidth: Integer read FPixelWidth;
    property PixelHeight: Integer read FPixelHeight;
    property ResolutionDPI: Double read FResolutionDPI;
  end;

constructor TNewImageDialogForm.CreateDialog(AOwner: TComponent; AWidth, AHeight: Integer; AResolutionDPI: Double);
var
  SectionBevel: TBevel;
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'New';
  Position := poScreenCenter;
  Width := 244;
  Height := 290;
  ClientWidth := 244;
  ClientHeight := 290;

  FPixelWidth := Max(1, AWidth);
  FPixelHeight := Max(1, AHeight);
  FResolutionDPI := ClampResolutionDPI(AResolutionDPI);

  FSizeLabel := TLabel.Create(Self);
  FSizeLabel.Parent := Self;
  FSizeLabel.Left := 10;
  FSizeLabel.Top := 12;
  FSizeLabel.Width := 210;

  SectionBevel := TBevel.Create(Self);
  SectionBevel.Parent := Self;
  SectionBevel.Shape := bsTopLine;
  SectionBevel.Left := 8;
  SectionBevel.Top := 30;
  SectionBevel.Width := 226;
  SectionBevel.Height := 2;

  FMaintainAspectBox := TCheckBox.Create(Self);
  FMaintainAspectBox.Parent := Self;
  FMaintainAspectBox.Left := 10;
  FMaintainAspectBox.Top := 38;
  FMaintainAspectBox.Caption := 'Maintain aspect ratio';
  FMaintainAspectBox.Checked := True;

  SectionBevel := TBevel.Create(Self);
  SectionBevel.Parent := Self;
  SectionBevel.Shape := bsTopLine;
  SectionBevel.Left := 8;
  SectionBevel.Top := 62;
  SectionBevel.Width := 226;
  SectionBevel.Height := 2;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 10;
  LabelCtrl.Top := 68;
  LabelCtrl.Caption := 'Pixel Size';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 24;
  LabelCtrl.Top := 92;
  LabelCtrl.Caption := 'Width:';

  FPixelWidthEdit := TEdit.Create(Self);
  FPixelWidthEdit.Parent := Self;
  FPixelWidthEdit.Left := 78;
  FPixelWidthEdit.Top := 88;
  FPixelWidthEdit.Width := 56;
  FPixelWidthEdit.OnEditingDone := @PixelWidthEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 142;
  LabelCtrl.Top := 92;
  LabelCtrl.Caption := 'pixels';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 24;
  LabelCtrl.Top := 118;
  LabelCtrl.Caption := 'Height:';

  FPixelHeightEdit := TEdit.Create(Self);
  FPixelHeightEdit.Parent := Self;
  FPixelHeightEdit.Left := 78;
  FPixelHeightEdit.Top := 114;
  FPixelHeightEdit.Width := 56;
  FPixelHeightEdit.OnEditingDone := @PixelHeightEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 142;
  LabelCtrl.Top := 118;
  LabelCtrl.Caption := 'pixels';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 10;
  LabelCtrl.Top := 146;
  LabelCtrl.Caption := 'Resolution:';

  FResolutionEdit := TEdit.Create(Self);
  FResolutionEdit.Parent := Self;
  FResolutionEdit.Left := 78;
  FResolutionEdit.Top := 142;
  FResolutionEdit.Width := 56;
  FResolutionEdit.OnEditingDone := @ResolutionEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 142;
  LabelCtrl.Top := 146;
  LabelCtrl.Caption := 'pixels/inch';

  SectionBevel := TBevel.Create(Self);
  SectionBevel.Parent := Self;
  SectionBevel.Shape := bsTopLine;
  SectionBevel.Left := 8;
  SectionBevel.Top := 170;
  SectionBevel.Width := 226;
  SectionBevel.Height := 2;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 10;
  LabelCtrl.Top := 176;
  LabelCtrl.Caption := 'Print Size';

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 24;
  LabelCtrl.Top := 200;
  LabelCtrl.Caption := 'Width:';

  FPrintWidthEdit := TEdit.Create(Self);
  FPrintWidthEdit.Parent := Self;
  FPrintWidthEdit.Left := 78;
  FPrintWidthEdit.Top := 196;
  FPrintWidthEdit.Width := 56;
  FPrintWidthEdit.OnEditingDone := @PrintWidthEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 24;
  LabelCtrl.Top := 226;
  LabelCtrl.Caption := 'Height:';

  FPrintHeightEdit := TEdit.Create(Self);
  FPrintHeightEdit.Parent := Self;
  FPrintHeightEdit.Left := 78;
  FPrintHeightEdit.Top := 222;
  FPrintHeightEdit.Width := 56;
  FPrintHeightEdit.OnEditingDone := @PrintHeightEdited;

  FPrintUnitCombo := TComboBox.Create(Self);
  FPrintUnitCombo.Parent := Self;
  FPrintUnitCombo.Left := 142;
  FPrintUnitCombo.Top := 209;
  FPrintUnitCombo.Width := 82;
  FPrintUnitCombo.Style := csDropDownList;
  FPrintUnitCombo.Items.Add('Inches');
  FPrintUnitCombo.Items.Add('Centimeters');
  FPrintUnitCombo.ItemIndex := 0;
  FPrintUnitCombo.OnChange := @PrintUnitChanged;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 74;
  OkButton.Top := 255;
  OkButton.Width := 70;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 150;
  CancelButton.Top := 255;
  CancelButton.Width := 70;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

function TNewImageDialogForm.CurrentPrintUnit: TPrintMeasurementUnit;
begin
  if FPrintUnitCombo.ItemIndex = 1 then
    Result := pmCentimeters
  else
    Result := pmInches;
end;

function TNewImageDialogForm.ParseFloatValue(const AText: string; AFallback: Double): Double;
var
  ParsedValue: Double;
  FormatSettings: TFormatSettings;
  NormalizedText: string;
begin
  NormalizedText := Trim(AText);
  if NormalizedText = '' then
    Exit(AFallback);

  FormatSettings := DefaultFormatSettings;
  if FormatSettings.DecimalSeparator = ',' then
    NormalizedText := StringReplace(NormalizedText, '.', ',', [rfReplaceAll])
  else
    NormalizedText := StringReplace(NormalizedText, ',', '.', [rfReplaceAll]);

  if not TryStrToFloat(NormalizedText, ParsedValue, FormatSettings) then
    Exit(AFallback);
  Result := ParsedValue;
end;

procedure TNewImageDialogForm.SyncFields;
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    FPixelWidthEdit.Text := IntToStr(FPixelWidth);
    FPixelHeightEdit.Text := IntToStr(FPixelHeight);
    FResolutionEdit.Text := FormatFloat('0.00', FResolutionDPI);
    FPrintWidthEdit.Text := FormatFloat(
      '0.00',
      PixelsToPrintValue(FPixelWidth, FResolutionDPI, CurrentPrintUnit)
    );
    FPrintHeightEdit.Text := FormatFloat(
      '0.00',
      PixelsToPrintValue(FPixelHeight, FResolutionDPI, CurrentPrintUnit)
    );
    FSizeLabel.Caption := 'New Size: ' + FormatEstimatedImageSize(FPixelWidth, FPixelHeight);
  finally
    FUpdating := False;
  end;
end;

procedure TNewImageDialogForm.PixelWidthEdited(Sender: TObject);
var
  NewWidth: Integer;
  OldWidth: Integer;
begin
  if FUpdating then
    Exit;
  OldWidth := FPixelWidth;
  NewWidth := Max(1, StrToIntDef(Trim(FPixelWidthEdit.Text), FPixelWidth));
  if FMaintainAspectBox.Checked and (OldWidth > 0) then
    FPixelHeight := Max(1, Round(NewWidth * (FPixelHeight / OldWidth)));
  FPixelWidth := NewWidth;
  SyncFields;
end;

procedure TNewImageDialogForm.PixelHeightEdited(Sender: TObject);
var
  NewHeight: Integer;
  OldHeight: Integer;
begin
  if FUpdating then
    Exit;
  OldHeight := FPixelHeight;
  NewHeight := Max(1, StrToIntDef(Trim(FPixelHeightEdit.Text), FPixelHeight));
  if FMaintainAspectBox.Checked and (OldHeight > 0) then
    FPixelWidth := Max(1, Round(NewHeight * (FPixelWidth / OldHeight)));
  FPixelHeight := NewHeight;
  SyncFields;
end;

procedure TNewImageDialogForm.ResolutionEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FResolutionDPI := ClampResolutionDPI(ParseFloatValue(FResolutionEdit.Text, FResolutionDPI));
  SyncFields;
end;

procedure TNewImageDialogForm.PrintWidthEdited(Sender: TObject);
var
  NewPixelWidth: Integer;
  OldWidth: Integer;
begin
  if FUpdating then
    Exit;
  OldWidth := FPixelWidth;
  NewPixelWidth := PrintValueToPixels(
    ParseFloatValue(FPrintWidthEdit.Text, PixelsToPrintValue(FPixelWidth, FResolutionDPI, CurrentPrintUnit)),
    FResolutionDPI,
    CurrentPrintUnit
  );
  if FMaintainAspectBox.Checked and (OldWidth > 0) then
    FPixelHeight := Max(1, Round(NewPixelWidth * (FPixelHeight / OldWidth)));
  FPixelWidth := NewPixelWidth;
  SyncFields;
end;

procedure TNewImageDialogForm.PrintHeightEdited(Sender: TObject);
var
  NewPixelHeight: Integer;
  OldHeight: Integer;
begin
  if FUpdating then
    Exit;
  OldHeight := FPixelHeight;
  NewPixelHeight := PrintValueToPixels(
    ParseFloatValue(FPrintHeightEdit.Text, PixelsToPrintValue(FPixelHeight, FResolutionDPI, CurrentPrintUnit)),
    FResolutionDPI,
    CurrentPrintUnit
  );
  if FMaintainAspectBox.Checked and (OldHeight > 0) then
    FPixelWidth := Max(1, Round(NewPixelHeight * (FPixelWidth / OldHeight)));
  FPixelHeight := NewPixelHeight;
  SyncFields;
end;

procedure TNewImageDialogForm.PrintUnitChanged(Sender: TObject);
begin
  SyncFields;
end;

function RunNewImageDialog(AOwner: TComponent; var AWidth, AHeight: Integer; var AResolutionDPI: Double): Boolean;
var
  DialogForm: TNewImageDialogForm;
begin
  DialogForm := TNewImageDialogForm.CreateDialog(AOwner, AWidth, AHeight, AResolutionDPI);
  try
    Result := DialogForm.ShowModal = mrOK;
    if not Result then
      Exit;
    AWidth := DialogForm.PixelWidth;
    AHeight := DialogForm.PixelHeight;
    AResolutionDPI := DialogForm.ResolutionDPI;
  finally
    DialogForm.Free;
  end;
end;

end.
