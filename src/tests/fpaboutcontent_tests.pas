unit fpaboutcontent_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, FPAboutContent;

type
  TFPAboutContentTests = class(TTestCase)
  published
    procedure AboutSectionsExposeNonEmptyTitlesAndText;
    procedure AboutTextHasNoTemplatePlaceholders;
    procedure AboutSectionsMatchAssetSourceFiles;
  end;

implementation

function LoadTextFileAsLineEndingString(const AFileName: string): string;
var
  Lines: TStringList;
  DelimLen: SizeInt;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    Result := StringReplace(Lines.Text, sLineBreak, LineEnding, [rfReplaceAll]);
  finally
    Lines.Free;
  end;

  DelimLen := Length(LineEnding);
  if (DelimLen > 0) and (Length(Result) >= DelimLen) and
     (Copy(Result, Length(Result) - DelimLen + 1, DelimLen) = LineEnding) then
  begin
    Delete(Result, Length(Result) - DelimLen + 1, DelimLen);
  end;
end;

function ResolveAboutAssetsDir: string;
var
  CandidateRoot: string;
begin
  Result := '';

  CandidateRoot := ExpandFileName(IncludeTrailingPathDelimiter(GetCurrentDir));
  if DirectoryExists(CandidateRoot + 'assets' + PathDelim + 'about') then
  begin
    Result := CandidateRoot + 'assets' + PathDelim + 'about' + PathDelim;
    Exit;
  end;

  CandidateRoot := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + '..');
  if DirectoryExists(CandidateRoot + PathDelim + 'assets' + PathDelim + 'about') then
  begin
    Result := IncludeTrailingPathDelimiter(CandidateRoot) + 'assets' + PathDelim + 'about' + PathDelim;
  end;
end;

procedure TFPAboutContentTests.AboutSectionsExposeNonEmptyTitlesAndText;
var
  Section: TAboutSection;
begin
  for Section := Low(TAboutSection) to High(TAboutSection) do
  begin
    AssertTrue('about section title should not be empty', AboutSectionTitle(Section) <> '');
    AssertTrue('about section text should not be empty', AboutSectionText(Section) <> '');
  end;
end;

procedure TFPAboutContentTests.AboutTextHasNoTemplatePlaceholders;
var
  Combined: string;
begin
  Combined := AboutSectionText(absAppInfo) + AboutSectionText(absAuthor) + AboutSectionText(absAcknowledgments);
  AssertTrue('about text should not keep template placeholders', Pos('[', Combined) = 0);
  AssertTrue('about text should not keep template placeholders', Pos(']', Combined) = 0);
  AssertTrue('license section should include LGPL mention for FPC/LCL', Pos('GNU Lesser General Public License', AboutSectionText(absThirdPartyLicenses)) > 0);
end;

procedure TFPAboutContentTests.AboutSectionsMatchAssetSourceFiles;
var
  BaseDir: string;
begin
  BaseDir := ResolveAboutAssetsDir;
  AssertTrue('assets/about directory should exist for about-content sync checks', DirectoryExists(BaseDir));

  AssertEquals('App info text should match assets/about/APP_INFO.txt',
    LoadTextFileAsLineEndingString(BaseDir + 'APP_INFO.txt'),
    AboutSectionText(absAppInfo));
  AssertEquals('Author text should match assets/about/AUTHOR.txt',
    LoadTextFileAsLineEndingString(BaseDir + 'AUTHOR.txt'),
    AboutSectionText(absAuthor));
  AssertEquals('Acknowledgments text should match assets/about/ACKNOWLEDGMENTS.txt',
    LoadTextFileAsLineEndingString(BaseDir + 'ACKNOWLEDGMENTS.txt'),
    AboutSectionText(absAcknowledgments));
  AssertEquals('Third-party licenses text should match assets/about/THIRD_PARTY_LICENSES.txt',
    LoadTextFileAsLineEndingString(BaseDir + 'THIRD_PARTY_LICENSES.txt'),
    AboutSectionText(absThirdPartyLicenses));
end;

initialization
  RegisterTest(TFPAboutContentTests);

end.
