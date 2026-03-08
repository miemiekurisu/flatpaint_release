unit FPEffectDialog;

{$mode objfpc}{$H+}

{ Generic slider-based parameter dialogs for image effects.
  Provides RunEffectDialog1 (single parameter) and RunEffectDialog2 (dual parameter),
  following the same UI pattern as FPBlurDialog:
    Label + Edit + range hint
    TTrackBar slider
    Help text / preview label
    OK / Cancel buttons }

interface

uses
  Classes, Forms;

{ Single-parameter effect dialog with slider.
  ATitle   — dialog window caption (e.g. 'Gaussian Blur')
  ALabel   — parameter label     (e.g. 'Radius')
  AMin/Max — value range
  ADefault — initial slider value
  Returns True and sets AValue on OK, False on Cancel. }
function RunEffectDialog1(
  AOwner: TComponent;
  const ATitle, ALabel: string;
  AMin, AMax, ADefault: Integer;
  var AValue: Integer
): Boolean;

{ Dual-parameter effect dialog with two sliders.
  Returns True and sets AValue1/AValue2 on OK. }
function RunEffectDialog2(
  AOwner: TComponent;
  const ATitle: string;
  const ALabel1: string; AMin1, AMax1, ADefault1: Integer;
  const ALabel2: string; AMin2, AMax2, ADefault2: Integer;
  var AValue1, AValue2: Integer
): Boolean;

implementation

uses
  SysUtils, Controls, StdCtrls, ComCtrls, Math, FPi18n;

{ ====== Single-parameter dialog ====== }

type
  TEffectDialog1 = class(TForm)
  private
    FUpdating: Boolean;
    FValue: Integer;
    FMin: Integer;
    FMax: Integer;
    FEdit: TEdit;
    FTrack: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure EditDone(Sender: TObject);
    procedure TrackChanged(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent;
      const ATitle, ALabel: string;
      AMin, AMax, ADefault: Integer);
    property Value: Integer read FValue;
  end;

constructor TEffectDialog1.CreateDialog(AOwner: TComponent;
  const ATitle, ALabel: string;
  AMin, AMax, ADefault: Integer);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := ATitle;
  Position := poScreenCenter;
  Width := 360;
  Height := 190;
  ClientWidth := 360;
  ClientHeight := 190;

  FMin := AMin;
  FMax := AMax;
  FValue := EnsureRange(ADefault, AMin, AMax);

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := ALabel + ':';

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Left := 14 + LabelCtrl.Canvas.TextWidth(ALabel + ':') + 12;
  FEdit.Top := 14;
  FEdit.Width := 56;
  FEdit.OnEditingDone := @EditDone;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := FEdit.Left + FEdit.Width + 10;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := Format(TR('%d to %d', '%d '#$E5#$88#$B0' %d'), [AMin, AMax]);

  FTrack := TTrackBar.Create(Self);
  FTrack.Parent := Self;
  FTrack.Left := 14;
  FTrack.Top := 44;
  FTrack.Width := 332;
  FTrack.Min := AMin;
  FTrack.Max := AMax;
  FTrack.Frequency := Max(1, (AMax - AMin) div 10);
  FTrack.LineSize := 1;
  FTrack.PageSize := Max(1, (AMax - AMin) div 5);
  FTrack.ShowSelRange := False;
  FTrack.OnChange := @TrackChanged;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 108;
  FPreviewLabel.Width := 332;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 206;
  OkButton.Top := 150;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 280;
  CancelButton.Top := 150;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TEffectDialog1.SyncFields;
begin
  FUpdating := True;
  try
    FValue := EnsureRange(FValue, FMin, FMax);
    FEdit.Text := IntToStr(FValue);
    FTrack.Position := FValue;
    FPreviewLabel.Caption := TR('Current value: ', #$E5#$BD#$93#$E5#$89#$8D#$E5#$80#$BC#$EF#$BC#$9A) + IntToStr(FValue);
  finally
    FUpdating := False;
  end;
end;

procedure TEffectDialog1.EditDone(Sender: TObject);
begin
  if FUpdating then Exit;
  FValue := EnsureRange(StrToIntDef(Trim(FEdit.Text), FValue), FMin, FMax);
  SyncFields;
end;

procedure TEffectDialog1.TrackChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  FValue := FTrack.Position;
  SyncFields;
end;

function RunEffectDialog1(
  AOwner: TComponent;
  const ATitle, ALabel: string;
  AMin, AMax, ADefault: Integer;
  var AValue: Integer
): Boolean;
var
  Dlg: TEffectDialog1;
begin
  Dlg := TEffectDialog1.CreateDialog(AOwner, ATitle, ALabel, AMin, AMax, ADefault);
  try
    Result := Dlg.ShowModal = mrOK;
    if Result then
      AValue := Dlg.Value;
  finally
    Dlg.Free;
  end;
end;

{ ====== Dual-parameter dialog ====== }

type
  TEffectDialog2 = class(TForm)
  private
    FUpdating: Boolean;
    FValue1: Integer;
    FValue2: Integer;
    FMin1: Integer;
    FMax1: Integer;
    FMin2: Integer;
    FMax2: Integer;
    FEdit1: TEdit;
    FEdit2: TEdit;
    FTrack1: TTrackBar;
    FTrack2: TTrackBar;
    FPreviewLabel: TLabel;
    procedure SyncFields;
    procedure Edit1Done(Sender: TObject);
    procedure Edit2Done(Sender: TObject);
    procedure Track1Changed(Sender: TObject);
    procedure Track2Changed(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent;
      const ATitle: string;
      const ALabel1: string; AMin1, AMax1, ADefault1: Integer;
      const ALabel2: string; AMin2, AMax2, ADefault2: Integer);
    property Value1: Integer read FValue1;
    property Value2: Integer read FValue2;
  end;

constructor TEffectDialog2.CreateDialog(AOwner: TComponent;
  const ATitle: string;
  const ALabel1: string; AMin1, AMax1, ADefault1: Integer;
  const ALabel2: string; AMin2, AMax2, ADefault2: Integer);
var
  LabelCtrl: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 0);
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Caption := ATitle;
  Position := poScreenCenter;
  Width := 360;
  Height := 296;
  ClientWidth := 360;
  ClientHeight := 296;

  FMin1 := AMin1; FMax1 := AMax1;
  FMin2 := AMin2; FMax2 := AMax2;
  FValue1 := EnsureRange(ADefault1, AMin1, AMax1);
  FValue2 := EnsureRange(ADefault2, AMin2, AMax2);

  { Parameter 1 }
  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := ALabel1 + ':';

  FEdit1 := TEdit.Create(Self);
  FEdit1.Parent := Self;
  FEdit1.Left := 14 + LabelCtrl.Canvas.TextWidth(ALabel1 + ':') + 12;
  FEdit1.Top := 14;
  FEdit1.Width := 56;
  FEdit1.OnEditingDone := @Edit1Done;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := FEdit1.Left + FEdit1.Width + 10;
  LabelCtrl.Top := 18;
  LabelCtrl.Caption := Format(TR('%d to %d', '%d '#$E5#$88#$B0' %d'), [AMin1, AMax1]);

  FTrack1 := TTrackBar.Create(Self);
  FTrack1.Parent := Self;
  FTrack1.Left := 14;
  FTrack1.Top := 44;
  FTrack1.Width := 332;
  FTrack1.Min := AMin1;
  FTrack1.Max := AMax1;
  FTrack1.Frequency := Max(1, (AMax1 - AMin1) div 10);
  FTrack1.LineSize := 1;
  FTrack1.PageSize := Max(1, (AMax1 - AMin1) div 5);
  FTrack1.ShowSelRange := False;
  FTrack1.OnChange := @Track1Changed;

  { Parameter 2 }
  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := 14;
  LabelCtrl.Top := 110;
  LabelCtrl.Caption := ALabel2 + ':';

  FEdit2 := TEdit.Create(Self);
  FEdit2.Parent := Self;
  FEdit2.Left := 14 + LabelCtrl.Canvas.TextWidth(ALabel2 + ':') + 12;
  FEdit2.Top := 106;
  FEdit2.Width := 56;
  FEdit2.OnEditingDone := @Edit2Done;

  LabelCtrl := TLabel.Create(Self);
  LabelCtrl.Parent := Self;
  LabelCtrl.Left := FEdit2.Left + FEdit2.Width + 10;
  LabelCtrl.Top := 110;
  LabelCtrl.Caption := Format(TR('%d to %d', '%d '#$E5#$88#$B0' %d'), [AMin2, AMax2]);

  FTrack2 := TTrackBar.Create(Self);
  FTrack2.Parent := Self;
  FTrack2.Left := 14;
  FTrack2.Top := 136;
  FTrack2.Width := 332;
  FTrack2.Min := AMin2;
  FTrack2.Max := AMax2;
  FTrack2.Frequency := Max(1, (AMax2 - AMin2) div 10);
  FTrack2.LineSize := 1;
  FTrack2.PageSize := Max(1, (AMax2 - AMin2) div 5);
  FTrack2.ShowSelRange := False;
  FTrack2.OnChange := @Track2Changed;

  FPreviewLabel := TLabel.Create(Self);
  FPreviewLabel.Parent := Self;
  FPreviewLabel.Left := 14;
  FPreviewLabel.Top := 218;
  FPreviewLabel.Width := 332;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := TR('OK', #$E7#$A1#$AE#$E5#$AE#$9A);
  OkButton.Left := 206;
  OkButton.Top := 256;
  OkButton.Width := 64;
  OkButton.ModalResult := mrOK;
  OkButton.Default := True;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.Caption := TR('Cancel', #$E5#$8F#$96#$E6#$B6#$88);
  CancelButton.Left := 280;
  CancelButton.Top := 256;
  CancelButton.Width := 64;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  SyncFields;
end;

procedure TEffectDialog2.SyncFields;
begin
  FUpdating := True;
  try
    FValue1 := EnsureRange(FValue1, FMin1, FMax1);
    FValue2 := EnsureRange(FValue2, FMin2, FMax2);
    FEdit1.Text := IntToStr(FValue1);
    FEdit2.Text := IntToStr(FValue2);
    FTrack1.Position := FValue1;
    FTrack2.Position := FValue2;
    FPreviewLabel.Caption := TR('Values: ', #$E5#$8F#$82#$E6#$95#$B0#$EF#$BC#$9A) + IntToStr(FValue1) + ', ' + IntToStr(FValue2);
  finally
    FUpdating := False;
  end;
end;

procedure TEffectDialog2.Edit1Done(Sender: TObject);
begin
  if FUpdating then Exit;
  FValue1 := EnsureRange(StrToIntDef(Trim(FEdit1.Text), FValue1), FMin1, FMax1);
  SyncFields;
end;

procedure TEffectDialog2.Edit2Done(Sender: TObject);
begin
  if FUpdating then Exit;
  FValue2 := EnsureRange(StrToIntDef(Trim(FEdit2.Text), FValue2), FMin2, FMax2);
  SyncFields;
end;

procedure TEffectDialog2.Track1Changed(Sender: TObject);
begin
  if FUpdating then Exit;
  FValue1 := FTrack1.Position;
  SyncFields;
end;

procedure TEffectDialog2.Track2Changed(Sender: TObject);
begin
  if FUpdating then Exit;
  FValue2 := FTrack2.Position;
  SyncFields;
end;

function RunEffectDialog2(
  AOwner: TComponent;
  const ATitle: string;
  const ALabel1: string; AMin1, AMax1, ADefault1: Integer;
  const ALabel2: string; AMin2, AMax2, ADefault2: Integer;
  var AValue1, AValue2: Integer
): Boolean;
var
  Dlg: TEffectDialog2;
begin
  Dlg := TEffectDialog2.CreateDialog(AOwner, ATitle,
    ALabel1, AMin1, AMax1, ADefault1,
    ALabel2, AMin2, AMax2, ADefault2);
  try
    Result := Dlg.ShowModal = mrOK;
    if Result then
    begin
      AValue1 := Dlg.Value1;
      AValue2 := Dlg.Value2;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
