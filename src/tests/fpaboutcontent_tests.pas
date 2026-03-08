unit fpaboutcontent_tests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, FPAboutContent;

type
  TFPAboutContentTests = class(TTestCase)
  published
    procedure AboutSectionsExposeNonEmptyTitlesAndText;
    procedure AboutTextHasNoTemplatePlaceholders;
  end;

implementation

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

initialization
  RegisterTest(TFPAboutContentTests);

end.
