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
  SysUtils, Controls, StdCtrls, ComCtrls, FPI18n, FPHueSaturationHelpers;

type
  THueSaturationDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FHueDelta: Integer;
    FSaturationDelta: Integer;
    FHueEdit: TEdit;
    FHueTrack: TTrackBar;
    FSaturationEdit: TEdit;
    FSaturationTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure HueEdited(Sender: TObject);
    procedure HueTrackChanged(Sender: TObject);
    procedure SaturationEdited(Sender: TObject);
    procedure SaturationTrackChanged(Sender: TObject);
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
  Caption := TR('Hue / Saturation', #$E8#$89#$B2#$E7#$9B#$B8' / '#$E9#$A5#$B1#$E5#$92#$8C#$E5#$BA#$A6);
  Position := poScreenCenter;
  Width := 360;
  Height := 240;
  ClientWidth := 360;
  ClientHeight := 240;

  FHueDelta := ClampHueDelta(AHueDelta);
  FSaturationDelta := ClampSaturationDelta(ASaturationDelta);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('Hue shift:', #$E8#$89#$B2#$E7#$9B#$B8#$E5#$81#$8F#$E7#$A7#$BB':');

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
  LabelCtrl.Caption := '-180 .. 180';

  FHueTrack := TTrackBar.Create(Self);
  FHueTrack.Parent := Self;
  FHueTrack.Left := 14;
  FHueTrack.Top := 40;
  FHueTrack.Width := 332;
  FHueTrack.Min := -180;
  FHueTrack.Max := 180;
  FHueTrack.Frequency := 30;
  FHueTrack.LineSize := 1;
  FHueTrack.PageSize := 10;
  FHueTrack.ShowSelRange := False;
  FHueTrack.OnChange := @HueTrackChanged;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 90;
  LabelCtrl.Caption := TR('Saturation:', #$E9#$A5#$B1#$E5#$92#$8C#$E5#$BA#$A6':');

  FSaturationEdit := TEdit.Create(Self);
  FSaturationEdit.Parent := Self;
  FSaturationEdit.Left := 104;
  FSaturationEdit.Top := 86;
  FSaturationEdit.Width := 70;
  FSaturationEdit.OnEditingDone := @SaturationEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 184;
  LabelCtrl.Top := 90;
  LabelCtrl.Caption := '-100 .. 100';

  FSaturationTrack := TTrackBar.Create(Self);
  FSaturationTrack.Parent := Self;
  FSaturationTrack.Left := 14;
  FSaturationTrack.Top := 112;
  FSaturationTrack.Width := 332;
  FSaturationTrack.Min := -100;
  FSaturationTrack.Max := 100;
  FSaturationTrack.Frequency := 20;
  FSaturationTrack.LineSize := 1;
  FSaturationTrack.PageSize := 10;
  FSaturationTrack.ShowSelRange := False;
  FSaturationTrack.OnChange := @SaturationTrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 162;
  FPreviewLabel.Width := 332;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 200;
  OkButton.Top := 196;
  OkButton.Width := 68;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 278;
  CancelButton.Top := 196;
  CancelButton.Width := 68;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure THueSaturationDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FHueEdit.Text := IntToStr(FHueDelta);
    FHueTrack.Position := FHueDelta;
    FSaturationEdit.Text := IntToStr(FSaturationDelta);
    FSaturationTrack.Position := FSaturationDelta;
    FPreviewLabel.Caption := TR('Hue: ', #$E8#$89#$B2#$E7#$9B#$B8': ') + IntToStr(FHueDelta)
      + '  ' + TR('Saturation: ', #$E9#$A5#$B1#$E5#$92#$8C#$E5#$BA#$A6': ') + IntToStr(FSaturationDelta);
  finally
    FUpdating := False;
  end;
end;

procedure THueSaturationDialogForm.HueEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FHueDelta := ClampHueDelta(ParseDeltaText(FHueEdit.Text, FHueDelta, -180, 180));
  SyncFields;
end;

procedure THueSaturationDialogForm.HueTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FHueDelta := ClampHueDelta(FHueTrack.Position);
  SyncFields;
end;

procedure THueSaturationDialogForm.SaturationEdited(Sender: TObject);
begin
  if FUpdating then Exit;
  FSaturationDelta := ClampSaturationDelta(
    ParseDeltaText(FSaturationEdit.Text, FSaturationDelta, -100, 100));
  SyncFields;
end;

procedure THueSaturationDialogForm.SaturationTrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FSaturationDelta := ClampSaturationDelta(FSaturationTrack.Position);
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
