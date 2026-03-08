unit FPPosterizeDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms;

function RunPosterizeDialog(AOwner: TComponent; var ALevels: Integer): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, ComCtrls, FPPosterizeHelpers, FPi18n;

type
  TPosterizeDialogForm = class(TForm)
  private
    FUpdating: Boolean;
    FLevels: Integer;
    FLevelsEdit: TEdit;
    FLevelsTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure LevelsEdited(Sender: TObject);
    procedure LevelsTrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; ALevels: Integer);
    property Levels: Integer read FLevels;
  end;

constructor TPosterizeDialogForm.CreateDialog(AOwner: TComponent; ALevels: Integer);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := TR('Posterize', #$E8#$89#$B2#$E8#$B0#$83#$E5#$88#$86#$E7#$A6#$BB);
  Position := poScreenCenter;
  Width := 332;
  Height := 186;
  ClientWidth := 332;
  ClientHeight := 186;

  FLevels := ClampPosterizeLevels(ALevels);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('Levels:', #$E7#$BA#$A7#$E5#$88#$AB#$EF#$BC#$9A);

  FLevelsEdit := TEdit.Create(Self);
  FLevelsEdit.Parent := Self;
  FLevelsEdit.Left := 68;
  FLevelsEdit.Top := 14;
  FLevelsEdit.Width := 56;
  FLevelsEdit.OnEditingDone := @LevelsEdited;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 136;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := TR('2 to 64', '2 '#$E5#$88#$B0' 64');

  FLevelsTrack := TTrackBar.Create(Self);
  FLevelsTrack.Parent := Self;
  FLevelsTrack.Left := 14;
  FLevelsTrack.Top := 44;
  FLevelsTrack.Width := 304;
  FLevelsTrack.Min := 2;
  FLevelsTrack.Max := 64;
  FLevelsTrack.Frequency := 6;
  FLevelsTrack.LineSize := 1;
  FLevelsTrack.PageSize := 4;
  FLevelsTrack.ShowSelRange := False;
  FLevelsTrack.OnChange := @LevelsTrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 106;
  FPreviewLabel.Width := 304;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 128;
  LabelCtrl.Caption := TR('Higher values preserve more tones.', #$E6#$95#$B0#$E5#$80#$BC#$E8#$B6#$8A#$E9#$AB#$98#$EF#$BC#$8C#$E4#$BF#$9D#$E7#$95#$99#$E7#$9A#$84#$E8#$89#$B2#$E8#$B0#$83#$E8#$B6#$8A#$E5#$A4#$9A#$E3#$80#$82);

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 178;
  OkButton.Top := 148;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 252;
  CancelButton.Top := 148;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TPosterizeDialogForm.SyncFields;
begin
  FUpdating := True;
  try
    FLevels := ClampPosterizeLevels(FLevels);
    FLevelsEdit.Text := IntToStr(FLevels);
    FLevelsTrack.Position := PosterizeLevelsToSliderPosition(FLevels);
    FPreviewLabel.Caption := TR('Current tonal steps: ', #$E5#$BD#$93#$E5#$89#$8D#$E8#$89#$B2#$E8#$B0#$83#$E7#$BA#$A7#$E6#$95#$B0#$EF#$BC#$9A) + IntToStr(FLevels);
  finally
    FUpdating := False;
  end;
end;

procedure TPosterizeDialogForm.LevelsEdited(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FLevels := ParsePosterizeText(FLevelsEdit.Text, FLevels);
  SyncFields;
end;

procedure TPosterizeDialogForm.LevelsTrackChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FLevels := SliderPositionToPosterizeLevels(FLevelsTrack.Position);
  SyncFields;
end;

function RunPosterizeDialog(AOwner: TComponent; var ALevels: Integer): Boolean;
var
  Dialog: TPosterizeDialogForm;
begin
  Dialog := TPosterizeDialogForm.CreateDialog(AOwner, ALevels);
  try
    Result := Dialog.ShowModal = mrOK;
    if Result then
      ALevels := Dialog.Levels;
  finally
    Dialog.Free;
  end;
end;

end.
