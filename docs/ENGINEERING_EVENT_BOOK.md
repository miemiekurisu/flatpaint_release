# Engineering Event Book

Use one short block per issue.

## Template
- Problem: what failed from the user or developer perspective
- Core error: the main error text or direct symptom
- Investigation: how the issue was located
- Fix: what changed to resolve it
- Repeat count: `This issue has occurred N time(s)`

## 2026-02-28
- Problem: `swift test` could not run in the default workspace sandbox
- Core error: `sandbox-exec: sandbox_apply: Operation not permitted`
- Investigation: ran `swift test`, then checked the failure output and saw SwiftPM manifest compilation and cache setup failing under the sandbox
- Fix: reran `swift test` with elevated execution so SwiftPM could use its required system facilities
- Repeat count: This issue has occurred 1 time(s)

- Problem: the app target failed to compile because the module had two entry points
- Core error: `'main' attribute can only apply to one type in a module`
- Investigation: inspected `Sources/FlatPaintApp` after the build failed and found the generated `FlatPaint.swift` still present next to the new `FlatPaintApp.swift`
- Fix: deleted the leftover generated `Sources/FlatPaintApp/FlatPaint.swift` file
- Repeat count: This issue has occurred 1 time(s)

## 2026-03-05
- Problem: Drawing tools (pencil, rectangle, etc.) appeared to work (visual feedback during drag) but strokes never "landed" on canvas. Undo history only showed 0 and 1 entries, never growing to 2, 3, 4.
- Core error: `FHistory.Count` reset to 0 between every `PushHistory` call despite no explicit `ClearHistory` invocation.
- Investigation: Created `TDebugObjectList` subclass overriding `Notify` to log all ADDED/EXTRACTED/DELETED events with stack traces. Caught an EXTRACTED notification immediately after ADDED — proving `Undo` was called right after `PushHistory`. Stack trace led to `RefreshHistoryPanel` → `FHistoryList.ItemIndex := UndoCount` → macOS Cocoa fires `OnClick` → `HistoryListClick` → `FDocument.Undo`. The Cocoa widgetset fires `TListBox.OnClick` when `ItemIndex` is set programmatically (unlike Win32/GTK). Tests never caught this because `CreateForTesting` sets `FHistoryList := nil`, so `RefreshHistoryPanel` exits early.
- Fix: In `RefreshHistoryPanel`, disconnect `FHistoryList.OnClick` (set to nil) before programmatic `ItemIndex` update, reconnect in `finally` block. One-line root cause, ~5-line fix.
- Repeat count: This issue has occurred 1 time(s)

## Note
- `docs/EXPERIENCES.md` is now the primary cumulative issue log. This file remains only as the earlier session-local record.
