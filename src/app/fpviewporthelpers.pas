unit FPViewportHelpers;

{$mode objfpc}{$H+}

interface

uses
  Classes;

function CenteredContentOffset(AViewportSize, AContentSize: Integer): Integer;
function ZoomSliderMin: Integer;
function ZoomSliderMax: Integer;
function ZoomSliderPositionForScale(AScale: Double): Integer;
function ZoomScaleForSliderPosition(APosition: Integer): Double;
function ClampZoomScale(AScale: Double): Double;
function ZoomScaleEffectivelyEqual(AScaleA, AScaleB: Double): Boolean;
function ViewportImageCoordinate(
  AScrollPosition,
  AViewportCoordinate,
  ACanvasOffset: Integer;
  AScale: Double;
  AImageExtent: Integer
): Integer;
function ScrollPositionForAnchor(
  AAnchorImageCoordinate: Double;
  AScale: Double;
  ACanvasOffset: Integer;
  AViewportCoordinate: Integer
): Integer;
function MaxViewportScrollPosition(
  ACanvasOffset,
  AContentSize,
  AViewportSize: Integer
): Integer;
function ClampViewportScrollPosition(
  ADesiredPosition,
  ACanvasOffset,
  AContentSize,
  AViewportSize: Integer
): Integer;
function ClampViewportScrollDelta(
  ACurrentPosition,
  ADelta,
  ACanvasOffset,
  AContentSize,
  AViewportSize: Integer
): Integer;
function PannedScrollPosition(
  ACurrentScrollPosition,
  ACurrentPointerCoordinate,
  APreviousPointerCoordinate: Integer
): Integer;
function ZoomWheelUsesViewportZoom(const AShift: TShiftState): Boolean;
function WheelScrollPixels(AWheelDelta: Integer; ABaseStep: Integer = 48): Integer;

implementation

uses
  Math, FPZoomHelpers;

const
  ZoomScaleEpsilon = 0.000001;

function CenteredContentOffset(AViewportSize, AContentSize: Integer): Integer;
begin
  Result := Max(0, (Max(0, AViewportSize) - Max(0, AContentSize)) div 2);
end;

function ZoomSliderMin: Integer;
begin
  Result := 0;
end;

function ZoomSliderMax: Integer;
begin
  Result := Max(0, ZoomPresetCount - 1);
end;

function ZoomSliderPositionForScale(AScale: Double): Integer;
begin
  Result := EnsureRange(NearestZoomPresetIndex(AScale), ZoomSliderMin, ZoomSliderMax);
end;

function ZoomScaleForSliderPosition(APosition: Integer): Double;
begin
  Result := ZoomPresetScale(EnsureRange(APosition, ZoomSliderMin, ZoomSliderMax));
end;

function ClampZoomScale(AScale: Double): Double;
begin
  Result := Max(0.1, Min(16.0, AScale));
end;

function ZoomScaleEffectivelyEqual(AScaleA, AScaleB: Double): Boolean;
begin
  Result := Abs(ClampZoomScale(AScaleA) - ClampZoomScale(AScaleB)) <= ZoomScaleEpsilon;
end;

function ViewportImageCoordinate(
  AScrollPosition,
  AViewportCoordinate,
  ACanvasOffset: Integer;
  AScale: Double;
  AImageExtent: Integer
): Integer;
begin
  if AImageExtent <= 0 then
    Exit(0);
  Result := EnsureRange(
    Trunc((AScrollPosition + AViewportCoordinate - ACanvasOffset) / Max(0.01, AScale)),
    0,
    AImageExtent - 1
  );
end;

function ScrollPositionForAnchor(
  AAnchorImageCoordinate: Double;
  AScale: Double;
  ACanvasOffset: Integer;
  AViewportCoordinate: Integer
): Integer;
begin
  Result := Max(
    0,
    ACanvasOffset + Round((AAnchorImageCoordinate + 0.5) * Max(0.01, AScale)) - AViewportCoordinate
  );
end;

function MaxViewportScrollPosition(
  ACanvasOffset,
  AContentSize,
  AViewportSize: Integer
): Integer;
begin
  Result := Max(
    0,
    (Max(0, AContentSize) + ACanvasOffset) - Max(0, AViewportSize)
  );
end;

function ClampViewportScrollPosition(
  ADesiredPosition,
  ACanvasOffset,
  AContentSize,
  AViewportSize: Integer
): Integer;
begin
  Result := EnsureRange(
    ADesiredPosition,
    0,
    MaxViewportScrollPosition(ACanvasOffset, AContentSize, AViewportSize)
  );
end;

function ClampViewportScrollDelta(
  ACurrentPosition,
  ADelta,
  ACanvasOffset,
  AContentSize,
  AViewportSize: Integer
): Integer;
var
  MaxPosition: Integer;
begin
  MaxPosition := MaxViewportScrollPosition(
    ACanvasOffset,
    AContentSize,
    AViewportSize
  );
  if ADelta < 0 then
    Result := Max(ADelta, 0 - ACurrentPosition)
  else if ADelta > 0 then
    Result := Min(ADelta, MaxPosition - ACurrentPosition)
  else
    Result := 0;
end;

function PannedScrollPosition(
  ACurrentScrollPosition,
  ACurrentPointerCoordinate,
  APreviousPointerCoordinate: Integer
): Integer;
begin
  Result := Max(
    0,
    ACurrentScrollPosition - (ACurrentPointerCoordinate - APreviousPointerCoordinate)
  );
end;

function ZoomWheelUsesViewportZoom(const AShift: TShiftState): Boolean;
begin
  Result := (ssCtrl in AShift) or (ssMeta in AShift);
end;

function WheelScrollPixels(AWheelDelta: Integer; ABaseStep: Integer): Integer;
var
  WheelNotches: Integer;
  StepSize: Integer;
begin
  if AWheelDelta = 0 then
    Exit(0);
  WheelNotches := Max(1, Abs(AWheelDelta) div 120);
  StepSize := Max(1, ABaseStep) * WheelNotches;
  if AWheelDelta > 0 then
    Result := -StepSize
  else
    Result := StepSize;
end;

end.
