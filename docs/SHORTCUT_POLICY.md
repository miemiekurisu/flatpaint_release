# Shortcut Policy

## Purpose
This document defines how FlatPaint maps paint.net-style shortcut expectations from Windows onto native macOS behavior.
The goal is paint.net workflow parity, not literal Windows key-for-key duplication.

## Governing rules
- paint.net remains the source of command intent.
- macOS remains the source of modifier-key convention.
- When the same command exists on both platforms, keep the command meaning the same and translate the modifier to the closest native macOS equivalent.
- If a literal Windows shortcut would feel wrong or conflict strongly on macOS, preserve the paint.net command intent and use the most predictable native macOS mapping.

## Modifier translation baseline
| Windows expectation | macOS mapping | Rationale |
| --- | --- | --- |
| `Ctrl` | `Command` | Primary application command modifier on macOS |
| `Alt` | `Option` | Secondary modifier / alternate action modifier |
| `Shift` | `Shift` | Same semantic role on both platforms |
| `Ctrl+Shift` | `Command+Shift` | Standard macOS secondary command variant |
| `Ctrl+Alt` | `Command+Option` | Tertiary command variant when needed |
| `Delete` | `Delete` for pixel removal, `Command+D` for deselect | macOS delete key and desktop app conventions diverge from Windows selection-clear habits |
| `Enter` | `Return` | Native keyboard labeling difference |

## Selection combine modifier mapping
For selection combine behavior (add/subtract/intersect), follow Adobe Photoshop user expectations adapted to macOS modifier keys:

- Add to selection: `Shift` (hold Shift while selecting)
- Subtract from selection: `Option` (Alt) (hold Option while selecting)
- Intersect selection: `Shift + Option` (hold both Shift and Option)

These map the Windows/Photoshop `Shift/Alt` model into the macOS modifier set (Option is the macOS name for Alt). This mapping must be used for any selection-related tool (rectangle, ellipse, lasso, magic wand) unless a platform-specific conflict requires explicit documentation and approval.

## Command intent rules
- `Undo` / `Redo` use standard macOS `Command+Z` and `Command+Shift+Z`.
- `Cut`, `Copy`, and `Paste` use standard macOS `Command+X/C/V`.
- `Deselect` should use `Command+D` on macOS in this project, because plain `Delete` is reserved for destructive pixel-clearing behavior.
- Commands that are alternate variants of the same family should group by modifier escalation:
  - primary: `Command`
  - secondary: `Command+Shift`
  - tertiary: `Command+Option`
- `Command+S` is reserved for true save-to-current-path behavior.
- `Command+Shift+S` is used for Save As behavior.

## Current implemented shortcut map
| Command | macOS shortcut | Notes |
| --- | --- | --- |
| New | `Command+N` | Native equivalent of Windows `Ctrl+N` |
| Open | `Command+O` | Native equivalent of Windows `Ctrl+O` |
| Import as Layer | `Command+Shift+I` | Secondary import action |
| Close | `Command+W` | Native close document |
| Save | `Command+S` | Saves to the bound native document path when available |
| Save As | `Command+Shift+S` | Prompts for the output path and format |
| Save All Images | `Command+Option+S` | Current single-document shell saves the active document through the same path policy |
| Print | `Command+P` | Routes to native print panel |
| Exit | `Command+Q` | Quit application |
| Cut | `Command+X` | Selection-aware when a selection exists |
| Copy | `Command+C` | Selection-aware when a selection exists |
| Copy Merged | `Command+Shift+C` | Explicit composite copy |
| Paste | `Command+V` | Pastes as a new layer |
| Undo | `Command+Z` | Standard macOS |
| Redo | `Command+Shift+Z` | Standard macOS |
| Select All | `Command+A` | Selects entire canvas |
| Deselect | `Command+D` | Replaces earlier incorrect delete-key mapping |
| Invert Selection | `Command+Option+I` | Inverts the current selection mask |
| Erase Selection Pixels | `Delete` | Destructive pixel clear, not deselect |
| Swap Colors | `X` | Bare key swap of primary/secondary colors |
| Reset Colors | `D` | Bare key reset to black/white defaults |
| Zoom In | `Command+=` | Standard macOS zoom-in key path (`+` on shifted `=`) |
| Zoom Out | `Command+-` | Standard macOS zoom-out |
| Actual Size | `Command+0` | Reset zoom to 100% |
| Zoom to Window | `Command+9` | Fit image to window |
| Show Tools | `Command+1` | Opens or focuses the tools utility window |
| Show Colors | `Command+2` | Opens or focuses the colors utility window |
| Show Layers | `Command+3` | Opens or focuses the layers utility window |
| Show History | `Command+4` | Opens or focuses the history utility window |
| Show/Hide Rulers | `Command+Option+R` | View-layer toggle |
| Show/Hide Pixel Grid | `Command+'` | View-layer toggle |
| Add New Layer | `Command+Shift+N` | Layer creation |
| Duplicate Layer | `Command+Shift+D` | Current parity approximation |
| Merge Layer Down | `Command+Shift+M` | Current parity approximation |
| Delete Layer | `Command+Delete` | Keeps plain delete free for pixel operations |
| Flatten | `Command+Shift+F` | Flatten all layers to single raster |
| Repeat Last Effect | `Command+F` | Re-applies the most recently used effect |
| Next Tab | `Ctrl+Tab` | Cycle to next open document tab (wraps) |
| Previous Tab | `Ctrl+Shift+Tab` | Cycle to previous open document tab (wraps) |

## Known deviations still open
- Shortcut coverage is not yet exhaustive relative to paint.net.
- Exact parity for some layer, image, and effect commands still needs a dedicated audit against the paint.net command surface.
- Native document save state is only tracked for current `.fpd` document workflows; richer document-state management can expand later.
- View coverage is still partial beyond zoom/actual-size; richer view and tool-toggle shortcuts still need expansion.
- Palette visibility shortcuts now exist for the four core utility windows, but broader parity still needs a fuller command-surface audit.

## Pre-integration checklist for shortcuts
1. Compare every visible menu shortcut in code against this document.
2. Verify destructive actions do not overload selection-management shortcuts.
3. Verify macOS-standard system commands (`Cut/Copy/Paste`, `Undo/Redo`) remain standard.
4. Document every intentional deviation from paint.net Windows literals.
5. Update `docs/FEATURE_MATRIX.md`, `docs/PROGRESS_LOG.md`, and `docs/TEST_LOG.md` when shortcut behavior changes.
