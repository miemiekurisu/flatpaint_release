unit FPTextDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Graphics;

type
  TTextDialogResult = record
    Text: string;
    FontName: string;
    FontSize: Integer;
    Bold: Boolean;
    Italic: Boolean;
  end;

function RunTextDialog(AOwner: TComponent; var AResult: TTextDialogResult): Boolean;

implementation

uses
  SysUtils, Math, Controls, StdCtrls, ComCtrls, ExtCtrls;

type
  TTextDialogForm = class(TForm)
  private
    FTextEdit: TEdit;
    FFontCombo: TComboBox;
    FSizeEdit: TEdit;
    FSizeTrack: TTrackBar;
    FBoldCheck: TCheckBox;
    FItalicCheck: TCheckBox;
    FPreviewLabel: TLabel;
    FUpdating: Boolean;
    procedure SyncSizeFields;
    procedure SizeEditDone(Sender: TObject);
    procedure SizeTrackChanged(Sender: TObject);
    procedure TextEditChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; const AResult: TTextDialogResult);
    function GetResult: TTextDialogResult;
  end;

constructor TTextDialogForm.CreateDialog(AOwner: TComponent; const AResult: TTextDialogResult);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := 'Add Text';
  Position := poScreenCenter;
  Width := 380;
  Height := 280;
  ClientWidth := 380;
  ClientHeight := 280;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 16;
  LabelCtrl.Caption := 'Text:';

  FTextEdit := TEdit.Create(Self);
  FTextEdit.Parent := Self;
  FTextEdit.Left := 68;
  FTextEdit.Top := 12;
  FTextEdit.Width := 296;
  FTextEdit.Text := AResult.Text;
  FTextEdit.OnChange := @TextEditChanged;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 50;
  LabelCtrl.Caption := 'Font:';

  FFontCombo := TComboBox.Create(Self);
  FFontCombo.Parent := Self;
  FFontCombo.Left := 68;
  FFontCombo.Top := 46;
  FFontCombo.Width := 196;
  FFontCombo.Style := csDropDownList;
  FFontCombo.Items.Assign(Screen.Fonts);
  if AResult.FontName <> '' then
    FFontCombo.ItemIndex := FFontCombo.Items.IndexOf(AResult.FontName);
  if FFontCombo.ItemIndex < 0 then
    FFontCombo.ItemIndex := 0;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 84;
  LabelCtrl.Caption := 'Size:';

  FSizeEdit := TEdit.Create(Self);
  FSizeEdit.Parent := Self;
  FSizeEdit.Left := 68;
  FSizeEdit.Top := 80;
  FSizeEdit.Width := 56;
  FSizeEdit.OnEditingDone := @SizeEditDone;

  FSizeTrack := TTrackBar.Create(Self);
  FSizeTrack.Parent := Self;
  FSizeTrack.Left := 14;
  FSizeTrack.Top := 108;
  FSizeTrack.Width := 350;
  FSizeTrack.Min := 6;
  FSizeTrack.Max := 120;
  FSizeTrack.Frequency := 10;
  FSizeTrack.LineSize := 1;
  FSizeTrack.PageSize := 6;
  FSizeTrack.ShowSelRange := False;
  FSizeTrack.OnChange := @SizeTrackChanged;
  FSizeTrack.Position := Max(6, Min(120, AResult.FontSize));

  FBoldCheck := TCheckBox.Create(Self);
  FBoldCheck.Parent := Self;
  FBoldCheck.Left := 14;
  FBoldCheck.Top := 154;
  FBoldCheck.Caption := 'Bold';
  FBoldCheck.Checked := AResult.Bold;

  FItalicCheck := TCheckBox.Create(Self);
  FItalicCheck.Parent := Self;
  FItalicCheck.Left := 90;
  FItalicCheck.Top := 154;
  FItalicCheck.Caption := 'Italic';
  FItalicCheck.Checked := AResult.Italic;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 182;
  FPreviewLabel.Width := 350;
  FPreviewLabel.AutoSize := False;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Left := 230;
  OkButton.Top := 242;
  OkButton.Width := 64;
  OkButton.Height := 28;
  OkButton.Default := True;
  OkButton.ModalResult := mrOk;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 302;
  CancelButton.Top := 242;
  CancelButton.Width := 64;
  CancelButton.Height := 28;
  CancelButton.ModalResult := mrCancel;

  SyncSizeFields;
  TextEditChanged(nil);
end;

procedure TTextDialogForm.SyncSizeFields;
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    FSizeEdit.Text := IntToStr(FSizeTrack.Position);
    FPreviewLabel.Font.Size := FSizeTrack.Position;
  finally
    FUpdating := False;
  end;
end;

procedure TTextDialogForm.SizeEditDone(Sender: TObject);
var
  V: Integer;
begin
  if FUpdating then Exit;
  if TryStrToInt(FSizeEdit.Text, V) then
  begin
    FSizeTrack.Position := Max(6, Min(120, V));
    SyncSizeFields;
  end;
end;

procedure TTextDialogForm.SizeTrackChanged(Sender: TObject);
begin
  SyncSizeFields;
end;

procedure TTextDialogForm.TextEditChanged(Sender: TObject);
begin
  if FPreviewLabel <> nil then
    FPreviewLabel.Caption := FTextEdit.Text;
end;

function TTextDialogForm.GetResult: TTextDialogResult;
begin
  Result.Text := FTextEdit.Text;
  if FFontCombo.ItemIndex >= 0 then
    Result.FontName := FFontCombo.Items[FFontCombo.ItemIndex]
  else
    Result.FontName := 'Arial';
  Result.FontSize := FSizeTrack.Position;
  Result.Bold := FBoldCheck.Checked;
  Result.Italic := FItalicCheck.Checked;
end;

function RunTextDialog(AOwner: TComponent; var AResult: TTextDialogResult): Boolean;
var
  Form: TTextDialogForm;
begin
  Form := TTextDialogForm.CreateDialog(AOwner, AResult);
  try
    Result := Form.ShowModal = mrOk;
    if Result then
      AResult := Form.GetResult;
  finally
    Form.Free;
  end;
end;

end.
