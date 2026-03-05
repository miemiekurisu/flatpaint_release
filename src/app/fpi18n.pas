unit FPI18n;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

type
  TAppLanguage = (
    alEnglish,
    alChinese
  );

{ Current application language — defaults to English }
var
  AppLanguage: TAppLanguage = alEnglish;

{ Returns the appropriate string for the current AppLanguage.
  Pass both the English and Chinese text inline at the call site. }
function TR(const AEnglish, AChinese: string): string; inline;

{ Human-readable name for a language }
function AppLanguageName(ALang: TAppLanguage): string;

{ Total number of supported languages }
function AppLanguageCount: Integer;

{ Load / save language preference to a simple file next to the app }
function LanguagePreferencePath: string;
procedure LoadLanguagePreference;
procedure SaveLanguagePreference;

implementation

uses
  SysUtils;

function TR(const AEnglish, AChinese: string): string; inline;
begin
  case AppLanguage of
    alChinese:
      Result := AChinese;
  else
    Result := AEnglish;
  end;
end;

function AppLanguageName(ALang: TAppLanguage): string;
begin
  case ALang of
    alEnglish:
      Result := 'English';
    alChinese:
      Result := #$E4#$B8#$AD#$E6#$96#$87;  { 中文 in UTF-8 }
  else
    Result := 'English';
  end;
end;

function AppLanguageCount: Integer;
begin
  Result := Ord(High(TAppLanguage)) - Ord(Low(TAppLanguage)) + 1;
end;

function LanguagePreferencePath: string;
begin
  Result := GetAppConfigDir(False) + 'language.conf';
end;

procedure LoadLanguagePreference;
var
  Path: string;
  LangStr: string;
  F: TextFile;
begin
  Path := LanguagePreferencePath;
  if not FileExists(Path) then
    Exit;
  try
    AssignFile(F, Path);
    Reset(F);
    try
      ReadLn(F, LangStr);
    finally
      CloseFile(F);
    end;
    LangStr := Trim(LangStr);
    if LangStr = 'cn' then
      AppLanguage := alChinese
    else
      AppLanguage := alEnglish;
  except
    { Ignore read errors — keep default }
  end;
end;

procedure SaveLanguagePreference;
var
  Path: string;
  Dir: string;
  F: TextFile;
begin
  Path := LanguagePreferencePath;
  Dir := ExtractFileDir(Path);
  if not DirectoryExists(Dir) then
    ForceDirectories(Dir);
  try
    AssignFile(F, Path);
    Rewrite(F);
    try
      case AppLanguage of
        alChinese:
          WriteLn(F, 'cn');
      else
        WriteLn(F, 'en');
      end;
    finally
      CloseFile(F);
    end;
  except
    { Ignore write errors }
  end;
end;

end.
