unit FPLayerPropertiesDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, FPDocument;

type
  TLayerPropertiesResult = record
    Name: string;
    Visible: Boolean;
    Opacity: Byte;
    BlendMode: TBlendMode;
  end;

function RunLayerPropertiesDialog(AOwner: TComponent;
  var AResult: TLayerPropertiesResult): Boolean;

implementation

uses
  SysUtils, Math, Controls, StdCtrls, ComCtrls, FPi18n;

function BlendModeDisplayName(AMode: TBlendMode): string;
begin
  case AMode of
    bmMultiply:
      Result := TR('Multiply', #$E6#$AD#$A3#$E7#$89#$87#$E5#$8F#$A0#$E5#$BA#$95);
    bmScreen:
      Result := TR('Screen', #$E6#$BB#$A4#$E8#$89#$B2);
    bmOverlay:
      Result := TR('Overlay', #$E5#$8F#$A0#$E5#$8A#$A0);
    bmDarken:
      Result := TR('Darken', #$E5#$8F#$98#$E6#$9A#$97);
    bmLighten:
      Result := TR('Lighten', #$E5#$8F#$98#$E4#$BA#$AE);
    bmDifference:
      Result := TR('Difference', #$E5#$B7#$AE#$E5#$80#$BC);
    bmSoftLight:
      Result := TR('Soft Light', #$E6#$9F#$94#$E5#$85#$89);
  else
    Result := TR('Normal', #$E6#$AD#$A3#$E5#$B8#$B8);
  end;
end;

type
  TLayerPropertiesForm = class(TForm)
  private
    FNameEdit: TEdit;
    FVisibleCheck: TCheckBox;
    FOpacityEdit: TEdit;
    FOpacityTrack: TTrackBar;
    FBlendCombo: TComboBox;
    FUpdating: Boolean;
    procedure SyncOpacityFields;
    procedure OpacityEditDone(Sender: TObject);
    procedure OpacityTrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent;
      const AResult: TLayerPropertiesResult);
    function GetResult: TLayerPropertiesResult;
  end;

constructor TLayerPropertiesForm.CreateDialog(AOwner: TComponent;
  const AResult: TLayerPropertiesResult);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
  BM: TBlendMode;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := TR('Layer Properties', #$E5#$9B#$BE#$E5#$B1#$82#$E5#$B1#$9E#$E6#$80#$A7);
  Position := poScreenCenter;
  Width := 320;
  Height := 248;
  ClientWidth := 320;
  ClientHeight := 248;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('Name:', #$E5#$90#$8D#$E7#$A7#$B0#$EF#$BC#$9A);

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := Self;
  FNameEdit.Left := 80;
  FNameEdit.Top := 14;
  FNameEdit.Width := 220;
  FNameEdit.Text := AResult.Name;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 52;
  LabelCtrl.Caption := TR('Blend:', #$E6#$B7#$B7#$E5#$90#$88#$EF#$BC#$9A);

  FBlendCombo := TComboBox.Create(Self);
  FBlendCombo.Parent := Self;
  FBlendCombo.Left := 80;
  FBlendCombo.Top := 48;
  FBlendCombo.Width := 220;
  FBlendCombo.Style := csDropDownList;
  for BM := Low(TBlendMode) to High(TBlendMode) do
    FBlendCombo.Items.Add(BlendModeDisplayName(BM));
  FBlendCombo.ItemIndex := Ord(AResult.BlendMode);

  FVisibleCheck := TCheckBox.Create(Self);
  FVisibleCheck.Parent := Self;
  FVisibleCheck.Left := 80;
  FVisibleCheck.Top := 82;
  FVisibleCheck.Width := 220;
  FVisibleCheck.Caption := TR('Visible', #$E5#$8F#$AF#$E8#$A7#$81);
  FVisibleCheck.Checked := AResult.Visible;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 116;
  LabelCtrl.Caption := TR('Opacity:', #$E4#$B8#$8D#$E9#$80#$8F#$E6#$98#$8E#$E5#$BA#$A6#$EF#$BC#$9A);

  FOpacityEdit := TEdit.Create(Self);
  FOpacityEdit.Parent := Self;
  FOpacityEdit.Left := 80;
  FOpacityEdit.Top := 112;
  FOpacityEdit.Width := 56;
  FOpacityEdit.OnEditingDone := @OpacityEditDone;

  FOpacityTrack := TTrackBar.Create(Self);
  FOpacityTrack.Parent := Self;
  FOpacityTrack.Left := 14;
  FOpacityTrack.Top := 140;
  FOpacityTrack.Width := 286;
  FOpacityTrack.Min := 0;
  FOpacityTrack.Max := 255;
  FOpacityTrack.Frequency := 25;
  FOpacityTrack.LineSize := 1;
  FOpacityTrack.PageSize := 16;
  FOpacityTrack.ShowSelRange := False;
  FOpacityTrack.OnChange := @OpacityTrackChanged;
  FOpacityTrack.Position := AResult.Opacity;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 170;
  OkButton.Top := 210;
  OkButton.Width := 64;
  OkButton.Height := 28;
  OkButton.Default := True;
  OkButton.ModalResult := mrOk;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 242;
  CancelButton.Top := 210;
  CancelButton.Width := 64;
  CancelButton.Height := 28;
  CancelButton.ModalResult := mrCancel;

  SyncOpacityFields;
end;

procedure TLayerPropertiesForm.SyncOpacityFields;
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    FOpacityEdit.Text := IntToStr(FOpacityTrack.Position);
  finally
    FUpdating := False;
  end;
end;

procedure TLayerPropertiesForm.OpacityEditDone(Sender: TObject);
var
  V: Integer;
begin
  if FUpdating then Exit;
  if TryStrToInt(FOpacityEdit.Text, V) then
  begin
    FOpacityTrack.Position := Max(0, Min(255, V));
    SyncOpacityFields;
  end;
end;

procedure TLayerPropertiesForm.OpacityTrackChanged(Sender: TObject);
begin
  SyncOpacityFields;
end;

function TLayerPropertiesForm.GetResult: TLayerPropertiesResult;
begin
  Result.Name := FNameEdit.Text;
  Result.Visible := Assigned(FVisibleCheck) and FVisibleCheck.Checked;
  Result.Opacity := Byte(FOpacityTrack.Position);
  if FBlendCombo.ItemIndex >= 0 then
    Result.BlendMode := TBlendMode(FBlendCombo.ItemIndex)
  else
    Result.BlendMode := bmNormal;
end;

function RunLayerPropertiesDialog(AOwner: TComponent;
  var AResult: TLayerPropertiesResult): Boolean;
var
  Form: TLayerPropertiesForm;
begin
  Form := TLayerPropertiesForm.CreateDialog(AOwner, AResult);
  try
    Result := Form.ShowModal = mrOk;
    if Result then
      AResult := Form.GetResult;
  finally
    Form.Free;
  end;
end;

end.
