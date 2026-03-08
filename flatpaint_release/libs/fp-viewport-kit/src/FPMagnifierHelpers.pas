unit FPMagnifierHelpers;

{$mode objfpc}{$H+}

interface

uses
  Types;

function ComputeZoomLoupeRects(
  const AImagePoint: TPoint;
  AZoomScale: Double;
  ADocumentWidth, ADocumentHeight: Integer;
  ASourceRadius, ALoupeSize, ALoupeOffset: Integer;
  out ASourceRect, ADestRect: TRect
): Boolean;

implementation

uses
  Math;

function ComputeZoomLoupeRects(
  const AImagePoint: TPoint;
  AZoomScale: Double;
  ADocumentWidth, ADocumentHeight: Integer;
  ASourceRadius, ALoupeSize, ALoupeOffset: Integer;
  out ASourceRect, ADestRect: TRect
): Boolean;
var
  ContentRect: TRect;
  ContentWidth: Integer;
  ContentHeight: Integer;
  DestWidth: Integer;
  DestHeight: Integer;
begin
  Result := False;
  ASourceRect := Rect(0, 0, 0, 0);
  ADestRect := Rect(0, 0, 0, 0);
  if (AImagePoint.X < 0) or (AImagePoint.Y < 0) then
    Exit;
  if (ADocumentWidth <= 0) or (ADocumentHeight <= 0) then
    Exit;
  if AZoomScale <= 0.0 then
    Exit;

  ASourceRect := Rect(
    Max(0, AImagePoint.X - ASourceRadius),
    Max(0, AImagePoint.Y - ASourceRadius),
    Min(ADocumentWidth, AImagePoint.X + ASourceRadius + 1),
    Min(ADocumentHeight, AImagePoint.Y + ASourceRadius + 1)
  );
  if (ASourceRect.Right - ASourceRect.Left < 2) or
     (ASourceRect.Bottom - ASourceRect.Top < 2) then
    Exit;

  ADestRect := Rect(
    Round((AImagePoint.X + 0.5) * AZoomScale) + ALoupeOffset,
    Round((AImagePoint.Y + 0.5) * AZoomScale) + ALoupeOffset,
    Round((AImagePoint.X + 0.5) * AZoomScale) + ALoupeOffset + ALoupeSize,
    Round((AImagePoint.Y + 0.5) * AZoomScale) + ALoupeOffset + ALoupeSize
  );

  ContentRect := Rect(
    0,
    0,
    Max(1, Round(ADocumentWidth * AZoomScale)),
    Max(1, Round(ADocumentHeight * AZoomScale))
  );
  ContentWidth := Max(1, ContentRect.Right - ContentRect.Left);
  ContentHeight := Max(1, ContentRect.Bottom - ContentRect.Top);
  DestWidth := Min(Max(1, ALoupeSize), ContentWidth);
  DestHeight := Min(Max(1, ALoupeSize), ContentHeight);
  ADestRect.Right := ADestRect.Left + DestWidth;
  ADestRect.Bottom := ADestRect.Top + DestHeight;
  if ADestRect.Right > ContentRect.Right then
    OffsetRect(ADestRect, ContentRect.Right - ADestRect.Right, 0);
  if ADestRect.Bottom > ContentRect.Bottom then
    OffsetRect(ADestRect, 0, ContentRect.Bottom - ADestRect.Bottom);
  if ADestRect.Left < ContentRect.Left then
    OffsetRect(ADestRect, ContentRect.Left - ADestRect.Left, 0);
  if ADestRect.Top < ContentRect.Top then
    OffsetRect(ADestRect, 0, ContentRect.Top - ADestRect.Top);

  Result := True;
end;

end.
