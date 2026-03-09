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
    Alignment: Integer; { 0=Left, 1=Center, 2=Right }
  end;

function RunTextDialog(AOwner: TComponent; var AResult: TTextDialogResult): Boolean;

implementation

uses
  SysUtils, Math, Controls, StdCtrls, ComCtrls, ExtCtrls, FPi18n;

type
  TTextDialogForm = class(TForm)
  private
    FTextEdit: TEdit;
    FFontCombo: TComboBox;
    FSizeEdit: TEdit;
    FSizeTrack: TTrackBar;
    FBoldCheck: TCheckBox;
    FItalicCheck: TCheckBox;
    FAlignCombo: TComboBox;
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
  Caption := TR('Add Text', #$E6#$B7#$BB#$E5#$8A#$A0#$E6#$96#$87#$E6#$9C#$AC);
  Position := poScreenCenter;
  Width := 380;
  Height := 280;
  ClientWidth := 380;
  ClientHeight := 312;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 16;
  LabelCtrl.Caption := TR('Text:', #$E6#$96#$87#$E6#$9C#$AC#$EF#$BC#$9A);

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
  LabelCtrl.Caption := TR('Font:', #$E5#$AD#$97#$E4#$BD#$93#$EF#$BC#$9A);

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
  LabelCtrl.Caption := TR('Size:', #$E5#$A4#$A7#$E5#$B0#$8F#$EF#$BC#$9A);

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
  FBoldCheck.Caption := TR('Bold', #$E7#$B2#$97#$E4#$BD#$93);
  FBoldCheck.Checked := AResult.Bold;

  FItalicCheck := TCheckBox.Create(Self);
  FItalicCheck.Parent := Self;
  FItalicCheck.Left := 90;
  FItalicCheck.Top := 154;
  FItalicCheck.Caption := TR('Italic', #$E6#$96#$9C#$E4#$BD#$93);
  FItalicCheck.Checked := AResult.Italic;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 170;
  LabelCtrl.Top := 156;
  LabelCtrl.Caption := TR('Align:', '对齐：');

  FAlignCombo := TComboBox.Create(Self);
  FAlignCombo.Parent := Self;
  FAlignCombo.Left := 214;
  FAlignCombo.Top := 152;
  FAlignCombo.Width := 116;
  FAlignCombo.Style := csDropDownList;
  FAlignCombo.Items.Add(TR('Left', '左对齐'));
  FAlignCombo.Items.Add(TR('Center', '居中'));
  FAlignCombo.Items.Add(TR('Right', '右对齐'));
  FAlignCombo.ItemIndex := EnsureRange(AResult.Alignment, 0, 2);

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 188;
  FPreviewLabel.Width := 350;
  FPreviewLabel.AutoSize := False;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 230;
  OkButton.Top := 274;
  OkButton.Width := 64;
  OkButton.Height := 28;
  OkButton.Default := True;
  OkButton.ModalResult := mrOk;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 302;
  CancelButton.Top := 274;
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
  if Assigned(FAlignCombo) then
    Result.Alignment := EnsureRange(FAlignCombo.ItemIndex, 0, 2)
  else
    Result.Alignment := 0;
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
