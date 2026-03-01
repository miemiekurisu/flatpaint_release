unit FPViewHelpers;

{$mode objfpc}{$H+}

interface

function PixelGridMinScale: Double;
function PixelGridColor: LongInt;
function ShouldRenderPixelGrid(AEnabled: Boolean; AScale: Double): Boolean;
function SaveCommandCaption(AHasBoundFileName: Boolean): string;
function NeedsDiscardConfirmation(AIsDirty: Boolean): Boolean;
function WindowCaptionForDocument(const ADisplayFileName: string; AIsDirty: Boolean): string;

implementation

function PixelGridMinScale: Double;
begin
  Result := 8.0;
end;

function PixelGridColor: LongInt;
begin
  Result := $009A9A9A;
end;

function ShouldRenderPixelGrid(AEnabled: Boolean; AScale: Double): Boolean;
begin
  Result := AEnabled and (AScale >= PixelGridMinScale);
end;

function SaveCommandCaption(AHasBoundFileName: Boolean): string;
begin
  if AHasBoundFileName then
    Result := '&Save'
  else
    Result := '&Save...';
end;

function NeedsDiscardConfirmation(AIsDirty: Boolean): Boolean;
begin
  Result := AIsDirty;
end;

function WindowCaptionForDocument(const ADisplayFileName: string; AIsDirty: Boolean): string;
begin
  if AIsDirty then
    Result := 'FlatPaint - ' + ADisplayFileName + ' (Edited)'
  else
    Result := 'FlatPaint - ' + ADisplayFileName;
end;

end.
