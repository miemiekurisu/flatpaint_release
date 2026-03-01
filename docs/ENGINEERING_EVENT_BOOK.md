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

## Note
- `docs/EXPERIENCES.md` is now the primary cumulative issue log. This file remains only as the earlier session-local record.
