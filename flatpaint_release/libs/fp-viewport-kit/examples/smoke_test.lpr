program smoke_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Types,
  FPZoomHelpers,
  FPViewportHelpers,
  FPMagnifierHelpers,
  FPRulerHelpers;

var
  SrcRect: TRect;
  DstRect: TRect;
  ZoomScale: Double;
begin
  ZoomScale := NextZoomInScale(1.0);
  if ZoomScale <= 1.0 then
    raise Exception.Create('zoom step failed');

  if not ComputeZoomLoupeRects(Point(30, 30), 4.0, 200, 200, 8, 120, 24, SrcRect, DstRect) then
    raise Exception.Create('loupe rect failed');

  if RulerMajorStep(1.0) <= 0 then
    raise Exception.Create('ruler major step invalid');
end.
