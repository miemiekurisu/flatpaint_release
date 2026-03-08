unit FPAboutDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes;

procedure ShowAboutDialog(AOwner: TComponent);

implementation

uses
  Forms, Controls, StdCtrls, ExtCtrls, Math, FPAboutContent, FPi18n;

type
  TAboutDialogBinder = class
  public
    SectionCombo: TComboBox;
    ContentMemo: TMemo;
    procedure SectionChanged(Sender: TObject);
  end;

function LocalizedAboutSectionTitle(ASection: TAboutSection): string;
begin
  case ASection of
    absAppInfo:
      Result := TR('App Info', #$E5#$BA#$94#$E7#$94#$A8#$E4#$BF#$A1#$E6#$81#$AF);
    absAuthor:
      Result := TR('Author', #$E4#$BD#$9C#$E8#$80#$85);
    absAcknowledgments:
      Result := TR('Acknowledgments', #$E8#$87#$B4#$E8#$B0#$A2);
    absThirdPartyLicenses:
      Result := TR('Third-Party Licenses', #$E7#$AC#$AC#$E4#$B8#$89#$E6#$96#$B9#$E8#$AE#$B8#$E5#$8F#$AF);
  else
    Result := TR('About', #$E5#$85#$B3#$E4#$BA#$8E);
  end;
end;

procedure TAboutDialogBinder.SectionChanged(Sender: TObject);
var
  SectionIndex: Integer;
begin
  if (SectionCombo = nil) or (ContentMemo = nil) then
    Exit;
  SectionIndex := EnsureRange(
    SectionCombo.ItemIndex,
    Ord(Low(TAboutSection)),
    Ord(High(TAboutSection))
  );
  ContentMemo.Lines.Text := AboutSectionText(TAboutSection(SectionIndex));
end;

procedure ShowAboutDialog(AOwner: TComponent);
var
  Dialog: TForm;
  SectionLabel: TLabel;
  SectionCombo: TComboBox;
  ContentMemo: TMemo;
  CloseButton: TButton;
  Binder: TAboutDialogBinder;
  Section: TAboutSection;
begin
  Dialog := TForm.CreateNew(AOwner);
  Binder := TAboutDialogBinder.Create;
  try
    Dialog.Caption := TR('About FlatPaint', #$E5#$85#$B3#$E4#$BA#$8E' FlatPaint');
    Dialog.Width := 760;
    Dialog.Height := 540;
    Dialog.Position := poMainFormCenter;
    Dialog.BorderStyle := bsSizeable;

    SectionLabel := TLabel.Create(Dialog);
    SectionLabel.Parent := Dialog;
    SectionLabel.Caption := TR('Section:', #$E5#$88#$86#$E8#$8A#$82#$EF#$BC#$9A);
    SectionLabel.Left := 12;
    SectionLabel.Top := 14;

    SectionCombo := TComboBox.Create(Dialog);
    SectionCombo.Parent := Dialog;
    SectionCombo.Left := 72;
    SectionCombo.Top := 10;
    SectionCombo.Width := 260;
    SectionCombo.Style := csDropDownList;
    for Section := Low(TAboutSection) to High(TAboutSection) do
      SectionCombo.Items.Add(LocalizedAboutSectionTitle(Section));
    SectionCombo.ItemIndex := 0;

    ContentMemo := TMemo.Create(Dialog);
    ContentMemo.Parent := Dialog;
    ContentMemo.Left := 12;
    ContentMemo.Top := 42;
    ContentMemo.Width := Dialog.ClientWidth - 24;
    ContentMemo.Height := Dialog.ClientHeight - 92;
    ContentMemo.Anchors := [akLeft, akTop, akRight, akBottom];
    ContentMemo.ReadOnly := True;
    ContentMemo.ScrollBars := ssBoth;
    ContentMemo.WordWrap := False;

    CloseButton := TButton.Create(Dialog);
    CloseButton.Parent := Dialog;
    CloseButton.Caption := TR('Close', #$E5#$85#$B3#$E9#$97#$AD);
    CloseButton.Width := 92;
    CloseButton.Height := 30;
    CloseButton.Left := Dialog.ClientWidth - CloseButton.Width - 12;
    CloseButton.Top := Dialog.ClientHeight - CloseButton.Height - 12;
    CloseButton.Anchors := [akRight, akBottom];
    CloseButton.ModalResult := mrOK;
    Dialog.ActiveControl := CloseButton;

    Binder.SectionCombo := SectionCombo;
    Binder.ContentMemo := ContentMemo;
    SectionCombo.OnChange := @Binder.SectionChanged;
    Binder.SectionChanged(nil);

    Dialog.ShowModal;
  finally
    Binder.Free;
    Dialog.Free;
  end;
end;

end.
