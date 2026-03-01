unit FPPosterizeHelpers;

{$mode objfpc}{$H+}

interface

function ClampPosterizeLevels(AValue: Integer): Integer;
function ParsePosterizeText(const AText: string; AFallback: Integer): Integer;
function PosterizeLevelsToSliderPosition(ALevels: Integer): Integer;
function SliderPositionToPosterizeLevels(APosition: Integer): Integer;

implementation

uses
  SysUtils, Math;

function ClampPosterizeLevels(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, 2, 64);
end;

function ParsePosterizeText(const AText: string; AFallback: Integer): Integer;
begin
  Result := ClampPosterizeLevels(StrToIntDef(Trim(AText), AFallback));
end;

function PosterizeLevelsToSliderPosition(ALevels: Integer): Integer;
begin
  Result := ClampPosterizeLevels(ALevels);
end;

function SliderPositionToPosterizeLevels(APosition: Integer): Integer;
begin
  Result := ClampPosterizeLevels(APosition);
end;

end.
