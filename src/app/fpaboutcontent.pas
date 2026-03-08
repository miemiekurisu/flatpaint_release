unit FPAboutContent;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TAboutSection = (
    absAppInfo,
    absAuthor,
    absAcknowledgments,
    absThirdPartyLicenses
  );

function AboutSectionTitle(ASection: TAboutSection): string;
function AboutSectionText(ASection: TAboutSection): string;

const
  AboutAppInfoText =
    'FlatPaint' + LineEnding +
    'Version 1.0' + LineEnding +
    '' + LineEnding +
    'A lightweight raster image editor for macOS.' + LineEnding +
    '' + LineEnding +
    'Copyright (c) 2026 FlatPaint Contributors. All rights reserved.';

  AboutAuthorText =
    'FlatPaint Contributors' + LineEnding +
    'https://github.com/flatpaint' + LineEnding +
    'Community-driven raster editor project focused on practical daily workflows.';

  AboutAcknowledgmentsText =
    'ACKNOWLEDGMENTS' + LineEnding +
    '' + LineEnding +
    'FlatPaint was made possible by the following projects and people.' + LineEnding +
    '' + LineEnding +
    '-- Toolchain --' + LineEnding +
    '' + LineEnding +
    'Free Pascal Compiler (FPC)' + LineEnding +
    '  Compiler and runtime library for the Pascal language.' + LineEnding +
    '  https://www.freepascal.org/' + LineEnding +
    '' + LineEnding +
    'Lazarus IDE and LCL' + LineEnding +
    '  The cross-platform IDE and component library that powers the UI.' + LineEnding +
    '  https://www.lazarus-ide.org/' + LineEnding +
    '' + LineEnding +
    '-- Icons --' + LineEnding +
    '' + LineEnding +
    'Lucide Icons' + LineEnding +
    '  Beautiful and consistent open-source icon set.' + LineEnding +
    '  https://lucide.dev/' + LineEnding +
    '' + LineEnding +
    '-- Testing --' + LineEnding +
    '' + LineEnding +
    'FlatPaint user community - bug reports, regression repro cases, and UX feedback' + LineEnding +
    '' + LineEnding +
    '-- Special Thanks --' + LineEnding +
    '' + LineEnding +
    'Everyone who tested, reviewed, and improved FlatPaint.';

  AboutThirdPartyLicensesText =
    'THIRD-PARTY LICENSES' + LineEnding +
    '' + LineEnding +
    'FlatPaint includes or links against the following open-source software.' + LineEnding +
    'Their licenses require the following notices to be distributed with' + LineEnding +
    'the application.' + LineEnding +
    '' + LineEnding +
    '========================================================================' + LineEnding +
    'FREE PASCAL COMPILER RUNTIME LIBRARY (RTL) AND FREE COMPONENT LIBRARY (FCL)' + LineEnding +
    '========================================================================' + LineEnding +
    '' + LineEnding +
    'Copyright (c) 1993-2021 by Florian Klaempfl and others.' + LineEnding +
    '' + LineEnding +
    'Licensed under the GNU Lesser General Public License v2 or later,' + LineEnding +
    'with the following static linking exception:' + LineEnding +
    '' + LineEnding +
    '  As a special exception, the copyright holders of this library give' + LineEnding +
    '  you permission to link this library with independent modules to' + LineEnding +
    '  produce an executable, regardless of the license terms of these' + LineEnding +
    '  independent modules, and to copy and distribute the resulting' + LineEnding +
    '  executable under terms of your choice, provided that you also meet,' + LineEnding +
    '  for each linked independent module, the terms and conditions of the' + LineEnding +
    '  license of that module. An independent module is a module which is' + LineEnding +
    '  not derived from or based on this library. If you modify this' + LineEnding +
    '  library, you may extend this exception to your version of the' + LineEnding +
    '  library, but you are not obligated to do so. If you do not wish to' + LineEnding +
    '  do so, delete this exception statement from your version.' + LineEnding +
    '' + LineEnding +
    'Source: https://www.freepascal.org/' + LineEnding +
    '' + LineEnding +
    '========================================================================' + LineEnding +
    'LAZARUS COMPONENT LIBRARY (LCL)' + LineEnding +
    '========================================================================' + LineEnding +
    '' + LineEnding +
    'Copyright (c) the Lazarus Development Team.' + LineEnding +
    '' + LineEnding +
    'Licensed under the GNU Lesser General Public License v2 or later,' + LineEnding +
    'with the following linking exception:' + LineEnding +
    '' + LineEnding +
    '  As a special exception, the copyright holders of this library give' + LineEnding +
    '  you permission to link this library with independent modules to' + LineEnding +
    '  produce an executable, regardless of the license terms of these' + LineEnding +
    '  independent modules, and to copy and distribute the resulting' + LineEnding +
    '  executable under terms of your choice, provided that you also meet,' + LineEnding +
    '  for each linked independent module, the terms and conditions of the' + LineEnding +
    '  license of that module. An independent module is a module which is' + LineEnding +
    '  not derived from or based on this library. If you modify this' + LineEnding +
    '  library, you may extend this exception to your version of the' + LineEnding +
    '  library, but you are not obligated to do so. If you do not wish to' + LineEnding +
    '  do so, delete this exception statement from your version.' + LineEnding +
    '' + LineEnding +
    'Source: https://www.lazarus-ide.org/' + LineEnding +
    '' + LineEnding +
    '========================================================================' + LineEnding +
    'LUCIDE ICONS' + LineEnding +
    '========================================================================' + LineEnding +
    '' + LineEnding +
    'ISC License' + LineEnding +
    '' + LineEnding +
    'Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022' + LineEnding +
    'as part of Feather (MIT). All other copyright (c) for Lucide are held' + LineEnding +
    'by Lucide Contributors 2022.' + LineEnding +
    '' + LineEnding +
    'Permission to use, copy, modify, and/or distribute this software for' + LineEnding +
    'any purpose with or without fee is hereby granted, provided that the' + LineEnding +
    'above copyright notice and this permission notice appear in all copies.' + LineEnding +
    '' + LineEnding +
    'THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL' + LineEnding +
    'WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED' + LineEnding +
    'WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE' + LineEnding +
    'AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL' + LineEnding +
    'DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR' + LineEnding +
    'PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER' + LineEnding +
    'TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR' + LineEnding +
    'PERFORMANCE OF THIS SOFTWARE.' + LineEnding +
    '' + LineEnding +
    'Source: https://lucide.dev/' + LineEnding +
    '' + LineEnding +
    '========================================================================' + LineEnding +
    'ZLIB COMPRESSION LIBRARY' + LineEnding +
    '========================================================================' + LineEnding +
    '' + LineEnding +
    'Copyright (c) 1995-2024 Jean-loup Gailly and Mark Adler.' + LineEnding +
    '' + LineEnding +
    'This software is provided ''as-is'', without any express or implied' + LineEnding +
    'warranty. In no event will the authors be held liable for any damages' + LineEnding +
    'arising from the use of this software.' + LineEnding +
    '' + LineEnding +
    'Permission is granted to anyone to use this software for any purpose,' + LineEnding +
    'including commercial applications, and to alter it and redistribute it' + LineEnding +
    'freely, subject to the following restrictions:' + LineEnding +
    '' + LineEnding +
    '  1. The origin of this software must not be misrepresented; you must' + LineEnding +
    '     not claim that you wrote the original software. If you use this' + LineEnding +
    '     software in a product, an acknowledgment in the product' + LineEnding +
    '     documentation would be appreciated but is not required.' + LineEnding +
    '  2. Altered source versions must be plainly marked as such, and must' + LineEnding +
    '     not be misrepresented as being the original software.' + LineEnding +
    '  3. This notice may not be removed or altered from any source' + LineEnding +
    '     distribution.' + LineEnding +
    '' + LineEnding +
    'Source: https://zlib.net/' + LineEnding +
    '' + LineEnding +
    'Note: FlatPaint uses the PasZLib Pascal translation by Jacques Nomssi Nzali,' + LineEnding +
    'Copyright (C) 1998-2000, distributed under the same zlib license terms.' + LineEnding +
    '' + LineEnding +
    '========================================================================' + LineEnding +
    'JPEG COMPRESSION LIBRARY' + LineEnding +
    '========================================================================' + LineEnding +
    '' + LineEnding +
    'Based on the Independent JPEG Group (IJG) library release 6b.' + LineEnding +
    'Pascal translation (PasJPEG) by Jacques Nomssi Nzali.' + LineEnding +
    'Copyright (C) 1996-1998 Jacques Nomssi Nzali.' + LineEnding +
    '' + LineEnding +
    'This software is provided ''as-is'', without any express or implied' + LineEnding +
    'warranty. In no event will the authors be held liable for any damages' + LineEnding +
    'arising from the use of this software.' + LineEnding +
    '' + LineEnding +
    'Permission is granted to anyone to use this software for any purpose,' + LineEnding +
    'including commercial applications, and to alter it and redistribute it' + LineEnding +
    'freely, subject to the following restrictions:' + LineEnding +
    '' + LineEnding +
    '  1. The origin of this software must not be misrepresented; you must' + LineEnding +
    '     not claim that you wrote the original software. If you use this' + LineEnding +
    '     software in a product, an acknowledgment in the product' + LineEnding +
    '     documentation would be appreciated but is not required.' + LineEnding +
    '  2. Altered source versions must be plainly marked as such, and must' + LineEnding +
    '     not be misrepresented as being the original software.' + LineEnding +
    '  3. This notice may not be removed or altered from any source' + LineEnding +
    '     distribution.';

implementation

function AboutSectionTitle(ASection: TAboutSection): string;
begin
  case ASection of
    absAppInfo:
      Result := 'App Info';
    absAuthor:
      Result := 'Author';
    absAcknowledgments:
      Result := 'Acknowledgments';
    absThirdPartyLicenses:
      Result := 'Third-Party Licenses';
  else
    Result := 'About';
  end;
end;

function AboutSectionText(ASection: TAboutSection): string;
begin
  case ASection of
    absAppInfo:
      Result := AboutAppInfoText;
    absAuthor:
      Result := AboutAuthorText;
    absAcknowledgments:
      Result := AboutAcknowledgmentsText;
    absThirdPartyLicenses:
      Result := AboutThirdPartyLicensesText;
  else
    Result := AboutAppInfoText;
  end;
end;

end.
