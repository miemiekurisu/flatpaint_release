unit fpiconhelpers_tests;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, FPIconHelpers, FPUIHelpers, FPUtilityHelpers, FPDocument;

type
  TFPIconHelpersTests = class(TTestCase)
  published
    procedure ToolIconsCoverEveryDisplayedTool;
    procedure UtilityIconsCoverEveryUtilityButton;
    procedure CommandIconsCoverMainToolbarAndLayerActions;
    procedure CommandIconsCoverColorPanelAndPaletteChrome;
    procedure TopToolbarCaptionAliasesStayMapped;
    procedure RepresentativeLucideSourceAssetsExist;
    procedure RepresentativeRenderedAssetsExist;
    procedure RepresentativeRetinaAssetsExist;
    procedure ToolIconsCanLoadRenderedAssets;
    procedure ToolIconsPreferRetinaRenderedAssets;
  end;

implementation

function FindProjectDir: string;
var
  BaseDir: string;
  Candidate: string;
  Depth: Integer;
begin
  Candidate := ExpandFileName(GetCurrentDir + PathDelim + 'assets' + PathDelim + 'icons');
  if DirectoryExists(Candidate) then
    Exit(ExpandFileName(GetCurrentDir));

  BaseDir := ExpandFileName(ExtractFileDir(ParamStr(0)));
  for Depth := 0 to 6 do
  begin
    Candidate := ExpandFileName(BaseDir + PathDelim + 'assets' + PathDelim + 'icons');
    if DirectoryExists(Candidate) then
      Exit(BaseDir);
    Candidate := ExpandFileName(BaseDir + PathDelim + '..');
    if Candidate = BaseDir then
      Break;
    BaseDir := Candidate;
  end;

  Result := '';
end;

procedure TFPIconHelpersTests.ToolIconsCoverEveryDisplayedTool;
var
  ToolIndex: Integer;
begin
  for ToolIndex := 0 to PaintToolDisplayCount - 1 do
    AssertTrue(
      'tool icon should exist for display index ' + IntToStr(ToolIndex),
      ButtonIconSupported(
        PaintToolGlyph(PaintToolAtDisplayIndex(ToolIndex)),
        bicTool
      )
    );
end;

procedure TFPIconHelpersTests.UtilityIconsCoverEveryUtilityButton;
var
  CommandIndex: Integer;
begin
  for CommandIndex := 0 to UtilityCommandDisplayCount - 1 do
    AssertTrue(
      'utility icon should exist for display index ' + IntToStr(CommandIndex),
      ButtonIconSupported(
        UtilityCommandGlyph(UtilityCommandAtDisplayIndex(CommandIndex)),
        bicUtility
      )
    );
end;

procedure TFPIconHelpersTests.CommandIconsCoverMainToolbarAndLayerActions;
const
  CommandCaptions: array[0..19] of string = (
    'New', 'Open', 'Save', 'Cut', 'Copy', 'Paste', 'Undo', 'Redo', '+', '-',
    'Dup', 'Del', 'Mrg', 'Vis', 'Up', 'Dn', 'Fade', 'Flat', 'Name', 'Props'
  );
var
  Index: Integer;
begin
  for Index := Low(CommandCaptions) to High(CommandCaptions) do
    AssertTrue(
      'command icon should exist for "' + CommandCaptions[Index] + '"',
      ButtonIconSupported(CommandCaptions[Index], bicCommand)
    );
end;

procedure TFPIconHelpersTests.CommandIconsCoverColorPanelAndPaletteChrome;
const
  CommandCaptions: array[0..1] of string = (
    'Swap', 'Mono'
  );
var
  Index: Integer;
begin
  for Index := Low(CommandCaptions) to High(CommandCaptions) do
    AssertTrue(
      'command icon should exist for "' + CommandCaptions[Index] + '"',
      ButtonIconSupported(CommandCaptions[Index], bicCommand)
    );
end;

procedure TFPIconHelpersTests.TopToolbarCaptionAliasesStayMapped;
begin
  AssertTrue('Zoom+ alias should resolve to a command icon',
    ButtonIconSupported('Zoom+', bicCommand));
  AssertTrue('Zoom- alias should resolve to a command icon',
    ButtonIconSupported('Zoom-', bicCommand));
  AssertTrue('Tools alias should resolve to a utility icon',
    ButtonIconSupported('Tools', bicUtility));
  AssertTrue('Colors alias should resolve to a utility icon',
    ButtonIconSupported('Colors', bicUtility));
  AssertTrue('History alias should resolve to a utility icon',
    ButtonIconSupported('History', bicUtility));
  AssertTrue('Layers alias should resolve to a utility icon',
    ButtonIconSupported('Layers', bicUtility));
end;

procedure TFPIconHelpersTests.RepresentativeLucideSourceAssetsExist;
const
  RepresentativeAssets: array[0..9] of string = (
    'file-plus-2',
    'circle-help',
    'pencil',
    'paintbrush',
    'wrench',
    'wand',
    'paint-bucket',
    'type',
    'pointer',
    'grid-2x2'
  );
var
  ProjectDir: string;
  Index: Integer;
begin
  ProjectDir := FindProjectDir;
  AssertTrue('project dir with assets/icons should be discoverable', ProjectDir <> '');

  for Index := Low(RepresentativeAssets) to High(RepresentativeAssets) do
    AssertTrue(
      'lucide source SVG asset should exist for ' + RepresentativeAssets[Index],
      FileExists(
        IncludeTrailingPathDelimiter(ProjectDir) + 'assets' + PathDelim + 'icons' +
        PathDelim + 'lucide' + PathDelim + RepresentativeAssets[Index] + '.svg'
      )
    );
end;

procedure TFPIconHelpersTests.RepresentativeRenderedAssetsExist;
const
  RepresentativeAssets: array[0..9] of string = (
    'file-plus-2',
    'copy',
    'undo',
    'circle-help',
    'wrench',
    'pencil',
    'paintbrush',
    'wand',
    'pointer',
    'grid-2x2'
  );
var
  ProjectDir: string;
  Index: Integer;
begin
  ProjectDir := FindProjectDir;
  AssertTrue('project dir with assets/icons should be discoverable', ProjectDir <> '');

  for Index := Low(RepresentativeAssets) to High(RepresentativeAssets) do
  begin
    AssertTrue(
      'extracted SVG asset should exist for ' + RepresentativeAssets[Index],
      FileExists(
        IncludeTrailingPathDelimiter(ProjectDir) + 'assets' + PathDelim + 'icons' +
        PathDelim + 'extracted' + PathDelim + RepresentativeAssets[Index] + '.svg'
      )
    );
    AssertTrue(
      'rendered PNG asset should exist for ' + RepresentativeAssets[Index],
      FileExists(
        IncludeTrailingPathDelimiter(ProjectDir) + 'assets' + PathDelim + 'icons' +
        PathDelim + 'rendered' + PathDelim + RepresentativeAssets[Index] + '.svg.png'
      )
    );
  end;
end;

procedure TFPIconHelpersTests.RepresentativeRetinaAssetsExist;
const
  RepresentativeAssets: array[0..9] of string = (
    'file-plus-2',
    'copy',
    'undo',
    'circle-help',
    'wrench',
    'pencil',
    'paintbrush',
    'wand',
    'pointer',
    'grid-2x2'
  );
var
  ProjectDir: string;
  Index: Integer;
begin
  ProjectDir := FindProjectDir;
  AssertTrue('project dir with assets/icons should be discoverable', ProjectDir <> '');

  for Index := Low(RepresentativeAssets) to High(RepresentativeAssets) do
    AssertTrue(
      'retina rendered PNG asset should exist for ' + RepresentativeAssets[Index],
      FileExists(
        IncludeTrailingPathDelimiter(ProjectDir) + 'assets' + PathDelim + 'icons' +
        PathDelim + 'rendered' + PathDelim + RepresentativeAssets[Index] + '.svg@2x.png'
      )
    );
end;

procedure TFPIconHelpersTests.ToolIconsCanLoadRenderedAssets;
begin
  AssertTrue(
    'pencil tool icon should load its rendered asset successfully',
    ButtonIconCanLoadRenderedAsset(PaintToolGlyph(tkPencil), bicTool)
  );
  AssertTrue(
    'brush tool icon should load its rendered asset successfully',
    ButtonIconCanLoadRenderedAsset(PaintToolGlyph(tkBrush), bicTool)
  );
  AssertTrue(
    'tools utility icon should load its rendered asset successfully',
    ButtonIconCanLoadRenderedAsset('Tools', bicUtility)
  );
  AssertTrue(
    'move pixels tool icon should load its rendered asset successfully',
    ButtonIconCanLoadRenderedAsset(PaintToolGlyph(tkMovePixels), bicTool)
  );
  AssertTrue(
    'mosaic tool icon should load its rendered asset successfully',
    ButtonIconCanLoadRenderedAsset(PaintToolGlyph(tkMosaic), bicTool)
  );
end;

procedure TFPIconHelpersTests.ToolIconsPreferRetinaRenderedAssets;
var
  Width: Integer;
  Height: Integer;
begin
  AssertTrue(
    'pencil tool icon should resolve to a rendered raster asset',
    ButtonIconRenderedAssetPixelSize(PaintToolGlyph(tkPencil), bicTool, Width, Height)
  );
  AssertEquals(
    'retina rendered icon width should be preferred when @2x is available',
    40,
    Width
  );
  AssertEquals(
    'retina rendered icon height should be preferred when @2x is available',
    40,
    Height
  );
end;

initialization
  RegisterTest(TFPIconHelpersTests);
end.
