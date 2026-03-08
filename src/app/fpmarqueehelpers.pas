unit FPMarqueeHelpers;

{$mode objfpc}{$H+}

interface

uses
  FPDocument;

const
  { Photoshop/GIMP-style "marching ants":
    continuous 1px outline with alternating dark/light segments. }
  MarqueeSegmentLength = 4;
  MarqueeColorPeriod = MarqueeSegmentLength * 2;
  MarqueePhaseWrap = MarqueeColorPeriod * 16;

function MarqueeStepVisible(AStep, APhase: Integer): Boolean;
function MarqueeStepUsesDarkColor(AStep, APhase: Integer): Boolean;
function NextMarqueePhase(APhase: Integer): Integer;
function ShouldAnimateMarqueeOverlay(
  ATool: TToolKind;
  AHasSelection: Boolean;
  AHasCloneSource: Boolean;
  APointerInCanvas: Boolean
): Boolean;

implementation

function MarqueeStepVisible(AStep, APhase: Integer): Boolean;
begin
  Result := True;
end;

function MarqueeStepUsesDarkColor(AStep, APhase: Integer): Boolean;
begin
  Result := (((AStep + APhase) div MarqueeSegmentLength) and 1) = 0;
end;

function NextMarqueePhase(APhase: Integer): Integer;
begin
  Result := APhase + 1;
  if Result >= MarqueePhaseWrap then
    Result := 0;
end;

function ShouldAnimateMarqueeOverlay(
  ATool: TToolKind;
  AHasSelection: Boolean;
  AHasCloneSource: Boolean;
  APointerInCanvas: Boolean
): Boolean;
begin
  if AHasSelection then
    Exit(True);
  if not APointerInCanvas then
    Exit(False);
  if (ATool = tkCloneStamp) and AHasCloneSource then
    Exit(True);
  Result := ATool in [tkSelectRect, tkSelectEllipse, tkSelectLasso, tkMagicWand];
end;

end.
