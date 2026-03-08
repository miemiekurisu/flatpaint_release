unit FPRulerHelpers;

{$mode objfpc}{$H+}

interface

type
  TRulerOrientation = (
    roHorizontal,
    roVertical
  );

function RulerThickness: Integer;
function RulerBackgroundColor: LongInt;
function RulerBorderColor: LongInt;
function RulerTickColor: LongInt;
function RulerTextColor: LongInt;
function RulerMajorStep(AScale: Double): Integer;
function RulerMinorStep(AScale: Double): Integer;

implementation

uses
  Math;

const
  RulerStepCandidates: array[0..11] of Integer = (
    1, 2, 5, 10, 25, 50, 100, 200, 500, 1000, 2000, 5000
  );
  MinimumMajorScreenSpacing = 56.0;

function RulerThickness: Integer;
begin
  Result := 18;
end;

function RulerBackgroundColor: LongInt;
begin
  Result := $00E4E4E4;
end;

function RulerBorderColor: LongInt;
begin
  Result := $00B9B9B9;
end;

function RulerTickColor: LongInt;
begin
  Result := $00686868;
end;

function RulerTextColor: LongInt;
begin
  Result := $00464646;
end;

function RulerMajorStep(AScale: Double): Integer;
var
  CandidateIndex: Integer;
  EffectiveScale: Double;
begin
  EffectiveScale := Max(0.01, AScale);
  for CandidateIndex := Low(RulerStepCandidates) to High(RulerStepCandidates) do
    if RulerStepCandidates[CandidateIndex] * EffectiveScale >= MinimumMajorScreenSpacing then
      Exit(RulerStepCandidates[CandidateIndex]);
  Result := RulerStepCandidates[High(RulerStepCandidates)];
end;

function RulerMinorStep(AScale: Double): Integer;
begin
  Result := Max(1, RulerMajorStep(AScale) div 5);
end;

end.
