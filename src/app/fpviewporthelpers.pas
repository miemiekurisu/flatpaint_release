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
function PannedScrollPosition(
  ACurrentScrollPosition,
  ACurrentPointerCoordinate,
  APreviousPointerCoordinate: Integer
): Integer;
function ZoomWheelUsesViewportZoom(const AShift: TShiftState): Boolean;

implementation

uses
  Math, FPZoomHelpers;

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

end.
