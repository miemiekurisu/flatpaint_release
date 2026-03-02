unit FPLayerPropertiesDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, FPDocument;

type
  TLayerPropertiesResult = record
    Name: string;
    Opacity: Byte;
    BlendMode: TBlendMode;
  end;

function RunLayerPropertiesDialog(AOwner: TComponent;
  var AResult: TLayerPropertiesResult): Boolean;

implementation

uses
  SysUtils, Math, Controls, StdCtrls, ComCtrls;

const
  BlendModeNames: array[TBlendMode] of string = (
    'Normal',
    'Multiply',
    'Screen',
    'Overlay',
    'Darken',
    'Lighten',
    'Difference',
    'Soft Light'
  );

type
  TLayerPropertiesForm = class(TForm)
  private
    FNameEdit: TEdit;
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
  Caption := 'Layer Properties';
  Position := poScreenCenter;
  Width := 320;
  Height := 218;
  ClientWidth := 320;
  ClientHeight := 218;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := 'Name:';

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
  LabelCtrl.Caption := 'Blend:';

  FBlendCombo := TComboBox.Create(Self);
  FBlendCombo.Parent := Self;
  FBlendCombo.Left := 80;
  FBlendCombo.Top := 48;
  FBlendCombo.Width := 220;
  FBlendCombo.Style := csDropDownList;
  for BM := Low(TBlendMode) to High(TBlendMode) do
    FBlendCombo.Items.Add(BlendModeNames[BM]);
  FBlendCombo.ItemIndex := Ord(AResult.BlendMode);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 86;
  LabelCtrl.Caption := 'Opacity:';

  FOpacityEdit := TEdit.Create(Self);
  FOpacityEdit.Parent := Self;
  FOpacityEdit.Left := 80;
  FOpacityEdit.Top := 82;
  FOpacityEdit.Width := 56;
  FOpacityEdit.OnEditingDone := @OpacityEditDone;

  FOpacityTrack := TTrackBar.Create(Self);
  FOpacityTrack.Parent := Self;
  FOpacityTrack.Left := 14;
  FOpacityTrack.Top := 110;
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
  OkButton.Caption := 'OK';
  OkButton.Left := 170;
  OkButton.Top := 180;
  OkButton.Width := 64;
  OkButton.Height := 28;
  OkButton.Default := True;
  OkButton.ModalResult := mrOk;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := 'Cancel';
  CancelButton.Left := 242;
  CancelButton.Top := 180;
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
