unit FPAboutDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes;

procedure ShowAboutDialog(AOwner: TComponent);

implementation

uses
  Forms, Controls, StdCtrls, ExtCtrls, Math, FPAboutContent;

type
  TAboutDialogBinder = class
  public
    SectionCombo: TComboBox;
    ContentMemo: TMemo;
    procedure SectionChanged(Sender: TObject);
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
    Dialog.Caption := 'About FlatPaint';
    Dialog.Width := 760;
    Dialog.Height := 540;
    Dialog.Position := poMainFormCenter;
    Dialog.BorderStyle := bsSizeable;

    SectionLabel := TLabel.Create(Dialog);
    SectionLabel.Parent := Dialog;
    SectionLabel.Caption := 'Section:';
    SectionLabel.Left := 12;
    SectionLabel.Top := 14;

    SectionCombo := TComboBox.Create(Dialog);
    SectionCombo.Parent := Dialog;
    SectionCombo.Left := 72;
    SectionCombo.Top := 10;
    SectionCombo.Width := 260;
    SectionCombo.Style := csDropDownList;
    for Section := Low(TAboutSection) to High(TAboutSection) do
      SectionCombo.Items.Add(AboutSectionTitle(Section));
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
    CloseButton.Caption := 'Close';
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
