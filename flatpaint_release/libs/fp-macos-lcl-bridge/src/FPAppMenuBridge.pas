unit FPAppMenuBridge;

{$mode objfpc}{$H+}

interface

uses
  Menus;

procedure ConfigureSystemAppMenu(AAboutItem, APreferencesItem: TMenuItem);

implementation

{$IFDEF DARWIN}
uses
  CocoaConfig;
{$ENDIF}

procedure ConfigureSystemAppMenu(AAboutItem, APreferencesItem: TMenuItem);
begin
  {$IFDEF DARWIN}
  CocoaConfigMenu.appMenu.aboutItem := AAboutItem;
  CocoaConfigMenu.appMenu.preferencesItem := APreferencesItem;
  {$ENDIF}
end;

end.
