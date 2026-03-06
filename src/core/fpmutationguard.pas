unit FPMutationGuard;

{$mode objfpc}{$H+}

interface

type
  TMutationScope = (
    msActiveLayerPixels,
    msDocumentPixels
  );

  TMutationState = record
    HasActiveLayer: Boolean;
    ActiveLayerLocked: Boolean;
    HasAnyLayer: Boolean;
    AnyLayerLocked: Boolean;
  end;

function MutationAllowed(const AState: TMutationState; AScope: TMutationScope): Boolean;

implementation

function MutationAllowed(const AState: TMutationState; AScope: TMutationScope): Boolean;
begin
  case AScope of
    msActiveLayerPixels:
      Result := AState.HasActiveLayer and (not AState.ActiveLayerLocked);
    msDocumentPixels:
      Result := AState.HasAnyLayer and (not AState.AnyLayerLocked);
  else
    Result := False;
  end;
end;

end.
