unit FPCurvesDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunCurvesDialog(AOwner: TComponent; var AGamma: Double): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, ComCtrls, FPCurvesHelpers, FPi18n;

type
  TCurvesDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FGamma: Double;
    FGammaEdit: TEdit;
    FGammaTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure GammaEdited(Sender: TObject);
    procedure GammaTrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; AGamma: Double);
    property Gamma: Double read FGamma;
  end;

constructor TCurvesDialogForm.CreateDialog(AOwner: TComponent; AGamma: Double);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := TR('Curves', #$E6#$9B#$B2#$E7#$BA#$BF);
  Position := poScreenCenter;
  Width := 352;
  Height := 190;
  ClientWidth := 352;
  ClientHeight := 190;

  FGamma := ClampGammaValue(AGamma);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('Gamma:', #$E4#$BC#$BD#$E9#$A9#$AC#$EF#$BC#$9A);

  FGammaEdit := TEdit.Create(Self);
  FGammaEdit.Parent := Self;
  FGammaEdit.Left := 72;
  FGammaEdit.Top := 14;
  FGammaEdit.Width := 66;
  FGammaEdit.OnEditingDone := @GammaEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 150;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('0.10 to 5.00', '0.10 '#$E5#$88#$B0' 5.00');

  FGammaTrack := TTrackBar.Create(Self);
  FGammaTrack.Parent := Self;
  FGammaTrack.Left := 14;
  FGammaTrack.Top := 44;
  FGammaTrack.Width := 320;
  FGammaTrack.Min := 10;
  FGammaTrack.Max := 500;
  FGammaTrack.Frequency := 45;
  FGammaTrack.LineSize := 5;
  FGammaTrack.PageSize := 25;
  FGammaTrack.ShowSelRange := False;
  FGammaTrack.OnChange := @GammaTrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 104;
  FPreviewLabel.Width := 320;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 126;
  LabelCtrl.Caption := TR('Current baseline uses one shared RGB gamma curve.', #$E5#$BD#$93#$E5#$89#$8D#$E5#$9F#$BA#$E7#$BA#$BF#$E4#$BD#$BF#$E7#$94#$A8#$E5#$8D#$95#$E4#$B8#$80#$E5#$85#$B1#$E4#$BA#$AB' RGB '#$E4#$BC#$BD#$E9#$A9#$AC#$E6#$9B#$B2#$E7#$BA#$BF#$E3#$80#$82);

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 198;
  OkButton.Top := 152;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 272;
  CancelButton.Top := 152;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TCurvesDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FGamma := ClampGammaValue(FGamma);
    FGammaEdit.Text := FormatGammaText(FGamma);
    FGammaTrack.Position := GammaToSliderPosition(FGamma);
    FPreviewLabel.Caption := TR('Midtones: ', #$E4#$B8#$AD#$E9#$97#$B4#$E8#$B0#$83#$EF#$BC#$9A) + FormatGammaText(FGamma) + TR(' gamma', ' '#$E4#$BC#$BD#$E9#$A9#$AC);
  finally
    FUpdating := False;
  end;
end;

procedure TCurvesDialogForm.GammaEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FGamma := ParseGammaText(FGammaEdit.Text, FGamma);
  SyncFields;
end;

procedure TCurvesDialogForm.GammaTrackChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FGamma := SliderPositionToGamma(FGammaTrack.Position);
  SyncFields;
end;

function RunCurvesDialog(AOwner: TComponent; var AGamma: Double): Boolean;
var
  Dialog: TCurvesDialogForm;
begin
  Dialog := TCurvesDialogForm.CreateDialog(AOwner, AGamma);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
      AGamma := Dialog.Gamma;
  finally
    Dialog.Free;
  end;
end;

end.
