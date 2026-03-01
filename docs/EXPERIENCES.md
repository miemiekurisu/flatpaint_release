# Experiences

Keep this file as the cumulative issue log for this project and for similar future image-editor projects.
Use the same compact structure every time.

## Template
- Problem: what failed
- Core error: main error or direct symptom
- Investigation: how the problem was located
- Root cause: the real cause
- Fix: what changed
- Reuse note: what to watch next time
- Repeat count: `This issue has occurred N time(s)`

## 2026-03-02
- Problem: the current Lazarus shell still allowed several normal document-replacement actions to destroy unsaved work with no confirmation at all
- Core error: `New`, `Open`, `Open Recent`, `Close`, and `Quit` all replaced or discarded the live document immediately even when `FDirty` was true, which is a direct desktop-UX safety failure and especially jarring on macOS
- Investigation: re-read the real `mainform.pas` handlers instead of the optimistic progress notes, then treated the issue as one document-lifecycle policy gap rather than five isolated button/menu bugs
- Root cause: early command-surface passes prioritized wiring routes and parity labels, but the main form still had no shared "document replacement" guard before mutating or clearing the current session
- Fix: added one shared confirmation helper, routed every destructive document-replacement path through it, made the `Save` menu caption use an ellipsis only when it truly opens a save-location prompt, and removed one extra intermediate `TBitmap` allocation from the prepared-canvas refresh path while tightening the same standards pass
- Reuse note: once a desktop editor has real save state, treat unsaved-change confirmation as baseline correctness, not polish; centralize the policy in one helper so new document-replacement routes do not silently bypass it later
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-02-28
- Problem: the UI had "implemented" major surfaces, but fixed-size layout assumptions made the product feel broken in normal use because controls visibly overlapped and repeated each other
- Core error: the toolbar duplicated the tool-icon surface, the default palette rectangles overlapped at launch, and the status-bar zoom cluster was positioned from stale hard-coded widths instead of the real status-panel partition
- Investigation: re-read the user's bug report against the actual `BuildToolbar`, `PaletteDefaultRect`, and `LayoutStatusBarControls` code paths, then treated the issue as one layout-model problem instead of three unrelated cosmetic complaints
- Root cause: several early UI passes added controls incrementally with fixed coordinates, but the project still lacked shared layout rules for status-bar partitioning and had not re-audited whether duplicated controls were still justified once the floating tool palette existed
- Fix: removed the duplicate top-toolbar tool-button strip, made the status bar use a shared width-partition helper, corrected the default palette rectangles so the left and right stacks do not overlap, and added tests for both palette non-overlap and status-bar width partitioning
- Reuse note: in UI-heavy desktop work, treat repeated controls and overlapping default rectangles as layout bugs, not polish; once a primary surface exists, delete redundant duplicates instead of preserving them "just in case"
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: a missing visible tool (`Freeform Shape`) could have been "completed" quickly by drawing directly in the form, but that would have created another UI-only algorithm branch for shape rendering
- Core error: implementing a visible shape tool only in the GUI layer would make the feature harder to test, harder to reuse, and likely inconsistent with the existing shared shape primitives
- Investigation: checked the existing shape pipeline and verified that line, rectangle, rounded rectangle, and ellipse already converge on shared raster methods plus one GUI commit path
- Root cause: the tempting shortcut was to treat freeform shape as only an interaction problem, when it is actually another raster primitive that should live beside the other shapes
- Fix: added a shared polygon-outline primitive in `FPSurface`, then routed `Freeform Shape` through the same tool metadata, preview, and commit structure as the other shape tools
- Reuse note: when a new visible drawing tool is conceptually "just another shape," add the raster primitive first and let the GUI remain a thin interaction shell; that keeps route-level parity from fragmenting the drawing engine
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: zoom behavior had already grown across multiple surfaces, but the anchor math still lived inline in the form code and one route (`Zoom` tool clicks) was still bypassing the newer focal-point logic
- Core error: even after adding centering and a status-bar slider, any zoom route that directly mutated `FZoomScale` could still drift away from the pointer/viewport focus and make the UI feel internally inconsistent
- Investigation: re-read the new cross-editor viewport baseline, then audited every real zoom entry point in `mainform.pas` (`menu`, `toolbar`, `status bar`, and `Zoom` tool click) to find which paths still set scale directly instead of sharing one anchor-preserving route
- Root cause: zoom behavior had been improved incrementally, but the coordinate transforms were still duplicated inside the form instead of being defined as one shared viewport rule
- Fix: moved the viewport image-coordinate and anchored-scroll math into `FPViewportHelpers`, routed the main zoom paths through one `ApplyZoomScaleAtViewportPoint` helper, synchronized the status-bar slider with the rest of the zoom controls, and added a modifier-wheel zoom path as the practical cross-editor fallback while native pinch remains open
- Reuse note: when one interaction exists in several UI surfaces, move the geometry math into a pure helper unit early and test that math directly; otherwise every new control quietly creates another slightly different behavior
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the current UI audit path was still too paint.net-only and left important layout rules implicit, which let obvious cross-editor conventions remain under-specified
- Core error: canvas centering, bottom-right zoom-slider priority, and pinch-zoom behavior were all visible gaps in the current code, but they were not called out as explicit implementation requirements in one authoritative place
- Investigation: compared the current Lazarus code path against paint.net docs and then broadened the reference set to Photoshop, GIMP, Photopea, and Pixlr-class editors to isolate the UI rules that are common regardless of product branding
- Root cause: previous UI guidance focused too heavily on one product screenshot checklist and not enough on the stable editor conventions shared across serious image editors
- Fix: added `docs/UI_REQUIREMENTS_BASELINE.md` as a separate normalized UI requirements document, and explicitly recorded the current code-level deltas for canvas centering, status-bar zoom slider, pinch zoom, and document surfacing
- Reuse note: when a UI target is a clone of one app but the missing behavior is actually a cross-editor convention, document the shared convention explicitly so implementation priorities stay stable even if one reference app changes detail
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the file-open surface still made users think about file classes first, and the project had no real GIMP route even though compatibility parity was already being claimed as a target
- Core error: `Open...` and `Import as Layer...` split project files and images into separate mental buckets in the filter text, while `.xcf` remained unsupported and therefore violated a baseline compatibility expectation the user explicitly called out
- Investigation: audited the real open/import handlers in `mainform.pas`, checked the shared loader in `fpio.pas`, and then treated the problem as one IO-boundary issue: unify the dialog surface first, then add the missing parser path behind it
- Root cause: the original loader focused on flat raster readers only, and the UI kept hand-maintained filter strings that drifted from the actual compatibility roadmap
- Fix: centralized the dialog filter strings in shared IO helpers, switched both `Open...` and `Import as Layer...` to start from one unified "all supported" filter, added a first-pass flattened XCF loader for common 8-bit uncompressed/RLE files, and allowed `.fpd` documents to flatten into a new layer during import
- Reuse note: when compatibility work spans multiple menus, move the supported-format list into one shared source of truth first; then add parsers behind that list so the UI and loader stop drifting apart
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: reusing the existing generic blend helper for XCF flattening produced visibly wrong semi-transparent pixels
- Core error: the current shared `BlendNormal` path attenuates RGB against alpha immediately, so flattening a half-transparent layer over an empty background changed the stored color values instead of preserving straight-alpha pixel data
- Investigation: the first minimal XCF regression passed dimensions but failed on the second pixel, so the failure was traced through the new loader rather than the parser structure itself; the tile bytes were correct, but the compositing helper was not
- Root cause: the general editing path currently uses a simplified blend model that is acceptable for many interactive operations, but it is the wrong primitive for importing already-authored project pixels that should stay in straight-alpha form
- Fix: kept the parser and layer traversal, but changed XCF flattening to use a dedicated straight-alpha compositing helper instead of calling `TRasterSurface.BlendPixel`
- Reuse note: importers that flatten authored layer data should not automatically reuse the app's interactive paint blend helper; verify first whether that helper preserves straight-alpha semantics
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: a first naive rounded-rectangle implementation could easily look "present" in menus while still drawing the wrong geometry on the canvas
- Core error: approximating a rounded rectangle by stitching together a plain rectangle with small corner circles would create extra inner arcs and visibly wrong corners, even though the shape route itself would technically exist
- Investigation: reviewed the missing draw-tool gap, checked the existing rectangle and ellipse primitives, and rejected the quick composition approach before wiring the new tool through the GUI
- Root cause: rounded rectangles are not just a rectangle plus four full ellipses; the corners need a single continuous rounded-rect boundary, and the existing primitives do not express that contour directly
- Fix: added a dedicated rounded-rectangle containment test in the raster core, used that for the outline draw path so hard corners stay open, and then wired the same tool through the shared tool metadata, drag preview, and shape-commit route
- Reuse note: when a missing shape tool has geometry that existing primitives only approximate badly, add the actual primitive in the raster core first; do not let menu parity hide incorrect drawing math
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: adding a better image-resize workflow risked desynchronizing one feature into three different behaviors (menu command, toolbar/status zoom conventions, and the raster backend)
- Core error: the project already had nearest-neighbor resize in the core, a prompt-only `Resize Image` UI path, and a separate `* 1.25` zoom-tool stepping rule, which would have made the editor feel internally inconsistent even if each piece compiled on its own
- Investigation: inspected the real resize and zoom code paths in `mainform.pas`, `fpdocument.pas`, and `fpsurface.pas`, then treated "resize quality" and "zoom stepping consistency" as one integration issue instead of unrelated polish items
- Root cause: the original implementation added baseline functionality incrementally, but the first pass never consolidated those image-scale behaviors into a shared model once the UI surface grew beyond a simple prompt
- Fix: added a shared bilinear resize path in the raster core, routed document resize through an explicit resample mode, replaced the prompt-only `Resize Image` flow with a dedicated modal that exposes aspect lock plus nearest/bilinear selection, and switched the visible zoom-tool click path onto the same preset ladder used everywhere else
- Reuse note: when an editor has multiple "change image scale" surfaces, unify the underlying stepping / interpolation policy before adding more UI chrome; otherwise the product drifts into internally inconsistent resize behavior that users notice immediately
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the command-surface checklist still needed `Curves...`, but a literal paint.net-style multi-point curve editor would have been too much UI mass for the current stage of the shell
- Core error: trying to make the first `Curves` pass visually complete would have burned time in a custom editor surface before the project even had the basic route implemented end-to-end
- Investigation: compared the remaining command-surface gaps against the current adjustment stack, then chose the smallest honest implementation that would close the missing menu route while staying testable in the shared raster core
- Root cause: the project still has broader UI parity debt, so the right immediate goal was "make `Curves...` real" rather than "finish an exact clone of paint.net's full curve editor in one pass"
- Fix: implemented `Curves...` as a gamma-based shared-core adjustment, wired it through the document model and GUI command path, and documented explicitly that the richer multi-point curve editor is still deferred
- Reuse note: when parity work is blocked by a missing command, close the route with the narrowest honest implementation first, provided the remaining fidelity gap is recorded precisely in docs
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first practical `Levels` pass needed to increase command coverage without pretending the product already had paint.net's richer per-channel dialog
- Core error: trying to jump straight to a full paint.net-style `Levels` surface would have added UI complexity faster than the current command-surface parity justified
- Investigation: reviewed the current adjustment stack and existing prompt-driven parameter flows, then chose the smallest real implementation that would still close the missing command path in code
- Root cause: the project still has broader UI parity debt, so a full custom levels dialog would overfit one command while larger visible gaps remain
- Fix: implemented a shared RGB remap with unified input/output bounds, wired it through the document model and `Adjustments -> Levels...`, and kept the GUI collection path prompt-based for now so the command is real before its dialog is polished
- Reuse note: when a missing command is blocking parity, prefer a minimal honest implementation that can be tested end-to-end, then iterate the UI fidelity once the route exists and the surrounding shell is stronger
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first `Hue / Saturation` regression test failed even though the underlying algorithm was not the immediate culprit
- Core error: the test expected the hue-shifted red pixel to stay green after the same pixel had already been desaturated in a second operation
- Investigation: reran the full suite immediately after adding the adjustment, read the failing assertion, and checked the test sequence rather than changing the HSV math first
- Root cause: the test mixed two separate behavioral expectations (hue rotation and full desaturation) onto the same pixel state, so the second step intentionally erased the first step's color evidence
- Fix: split the regression into separate surfaces so hue rotation and desaturation are asserted independently while still checking alpha preservation
- Reuse note: when validating chained color adjustments, isolate each expected visual outcome unless the test is explicitly about composition order; otherwise the second transform can invalidate the first assertion by design
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: a literal always-on pixel grid made the canvas unreadable at ordinary zoom levels even though the command itself existed
- Core error: drawing the pixel grid unconditionally would turn the overlay into visual clutter at normal editing zoom, which misses how mature image editors reserve that aid for deep zoom
- Investigation: implemented the first grid pass against the existing canvas renderer, then constrained it against the current zoom-control ladder instead of treating it as a simple boolean overlay
- Root cause: the feature requirement is “pixel-boundary aid,” not “always visible grid,” and the first naive interpretation ignored the interaction between overlay density and zoom
- Fix: moved the policy into a shared view helper so the pixel grid only renders when the user enables it and the zoom has reached a practical threshold, while still keeping the route live in both menu and toolbar
- Reuse note: when a view aid becomes useful only at certain scales, make that threshold explicit in shared logic and test it; do not bury that decision in ad hoc paint code
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the project docs had started to read ahead of the real code, which made any completion estimate unreliable
- Core error: the written status implied document-tab progress and broader command-surface parity that do not exist in the actual Lazarus GUI source, where the main form still owns a single `TImageDocument` and no image-list control is present
- Investigation: audited the real code paths instead of only the docs, checked the `TMainForm` fields, inspected `BuildMenus`, and compared the visible route list against the command-surface baseline
- Root cause: repeated progress logging focused on incremental wins, but there was not a matching periodic code-level reconciliation pass against the authoritative command-surface checklist
- Fix: reset the completion estimate to a code-derived range, corrected the feature matrix away from the optimistic tab claim, and resumed tracking visible gaps from the real source path rather than the prior narrative
- Reuse note: for parity work, never estimate completion from docs alone; periodically reconcile the implementation against the actual form fields, route handlers, and visible-control construction code
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: fixed viewport rulers needed to stay aligned with canvas scrolling, but the current embedded Lazarus scroll-host path does not hand out an obvious reliable high-level scroll event
- Core error: a ruler drawn as a separate control can fall out of sync with the canvas origin if it only repaints on zoom or document mutations and never notices scrollbar movement
- Investigation: wired the first ruler controls against the existing `TScrollBox` host, reviewed the LCL event surface, and confirmed that the current shell did not have a direct route that reliably fires for every viewport scroll adjustment in this setup
- Root cause: the current architecture uses an embedded `TScrollBox` inside the main workspace, and that widget path is convenient for canvas scrolling but awkward for synchronizing independent fixed ruler controls
- Fix: kept the fixed ruler controls, added a lightweight idle-time watcher for scroll-position changes, and invalidated the rulers only when the scroll offsets actually change so the ruler origin tracks the viewport without forcing a constant repaint loop
- Reuse note: when a Lazarus child control needs to stay fixed while a sibling `TScrollBox` scrolls, verify the real event surface first; if the widgetset path does not provide a clean scroll callback, use a bounded idle-state comparison instead of overcomplicating the canvas architecture
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first paint.net-style palette launchers were technically functional but still looked wrong because they were mixed into the normal action row instead of reading as a separate utility cluster
- Core error: window-management commands (`Tools`, `History`, `Layers`, `Colors`) were rendered as ordinary toolbar buttons, which contradicts the user-supplied screenshot and makes the command surface read unlike paint.net even though the routes exist
- Investigation: compared the current top strip against the screenshot and the command-surface baseline, then traced those routes back to the generic toolbar button calls in `BuildToolbar`
- Root cause: the initial implementation treated utility-window commands like standard edit actions instead of respecting the screenshot's dedicated right-side utility-icon grouping
- Fix: extracted shared utility metadata, moved those routes into their own compact top-right strip, and used that same pass to attach real `Settings` and `Help` actions instead of leaving the utility area under-specified
- Reuse note: when a reference UI separates “workspace utilities” from “document actions,” mirror that separation structurally in code instead of just adding more buttons to the same strip
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the user-provided paint.net screenshot made it clear that the current `New` command flow was still using the wrong interaction model
- Core error: the app was collecting width and height through generic `InputQuery` prompts, which breaks the paint.net expectation of one dedicated dialog that shows size, resolution, and print-size relationships together
- Investigation: compared the screenshot directly against the current `NewDocumentClick` path and confirmed the code still went through `PromptForSize`, with no single modal surface for the full new-image workflow
- Root cause: the first implementation optimized for minimal functionality and never replaced the placeholder prompt flow with a real task-specific dialog
- Fix: added a dedicated `FPNewImageDialog` modal plus shared `FPNewImageHelpers` math, and switched `NewDocumentClick` to use that dialog so the workflow now keeps estimated RGBA size, aspect lock, resolution, and derived print-size values on one screen
- Reuse note: once a user provides a concrete product screenshot, treat any remaining placeholder interaction that contradicts it as an implementation bug, not as optional polish
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the documentation and the visible open flow overstated file support, while the actual shared loader still only accepted a short hard-coded extension list
- Core error: files with unsupported or mismatched extensions failed at the very first extension gate even when the bundled FPC image stack could decode the content, and the docs incorrectly implied `.pdn` / `.xcf` / `.kra` compatibility was already done
- Investigation: checked the current `fpio.pas` implementation against the local FPC image units, verified that the code only constructed readers for four raster extensions, and then compared that against the feature docs that claimed broader compatibility coverage
- Root cause: the first implementation used an extension-only dispatch table and the docs drifted ahead of the actual Lazarus/FPC code path
- Fix: expanded the loader to use the available FPC readers (`PSD`, `GIF`, `PCX`, `PNM`, `TGA`, `XPM`, `XWD` in addition to the original formats), added content-based fallback probing when the extension is unknown or wrong, widened the GUI filters, and corrected the feature docs so only `PSD` is marked as implemented among the foreign-format paths
- Reuse note: for file compatibility work, verify the real reader/writer units present in the toolchain before claiming support in docs, and avoid extension-only routing when the underlying image library can safely probe by content
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the paint.net reference expects utility-window movement translucency, but the current in-window Lazarus palette model is built from child controls rather than independent forms
- Core error: there is no practical per-control alpha-blend path for these embedded palette panels in the current LCL setup, so a literal semi-transparent drag state is not available the way it would be for a separate top-level window
- Investigation: checked the local Lazarus/LCL sources before coding the drag-feedback pass and confirmed that alpha-blend support is exposed on custom forms, not on the embedded child controls used for the current palette layer
- Root cause: the current architecture intentionally keeps palettes inside the main editor window for paint.net-style layering, but that same choice removes the simplest top-level-window alpha route
- Fix: kept the in-window palette model and implemented a drag-state tint/brightness shift as the anti-obstruction feedback path during movement, while leaving true per-control translucency deferred unless the palette architecture changes
- Reuse note: in Lazarus, verify whether a visual effect belongs to top-level forms or child controls before promising an exact parity effect; when the effect is unavailable on embedded controls, use a bounded visual fallback and document the architectural reason
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the new `History` palette needed to show meaningful action names, but the document model previously stored only anonymous snapshots
- Core error: without a parallel label path, the UI could only report undo/redo counts and every history entry collapsed to a non-actionable generic state
- Investigation: reviewed the shared `TImageDocument` undo/redo implementation and compared what the palette needed (action labels) against what the snapshot objects currently preserve (document state only)
- Root cause: the original history stack modeled state transitions only; it did not preserve user-facing action metadata or keep that metadata aligned when snapshots move between undo, redo, and max-history trimming
- Fix: added parallel `TStringList` label stacks for undo and redo, moved labels in lockstep with snapshot pushes/undo/redo transitions, and trimmed labels together with snapshot eviction so the `History` palette can show the newest undo/redo action names without inflating snapshot payloads
- Reuse note: if a UI history surface needs labels but the snapshot payload is already stable, keep lightweight metadata in a parallel stack and move it in the exact same code paths as the snapshots; do not couple presentation labels to the heavy snapshot object unless persistence really requires it
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first floating-palette refactor failed even though the layout helper logic itself was valid
- Core error: `Duplicate identifier "BoundsRect"` while compiling `mainform.pas`
- Investigation: reran `lazbuild`, checked the exact failing line inside the new `CreatePalette` helper, and compared the local identifier against the imported LCL surface
- Root cause: `BoundsRect` is already a known identifier in the current LCL context, so reusing it as a local variable name in this method triggered a naming collision
- Fix: renamed the local helper variable from `BoundsRect` to `PaletteRect`
- Reuse note: in Lazarus UI units, avoid generic geometry names like `BoundsRect` for local variables when working inside form/control code; prefer more specific names that won't collide with common control members
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first attempt to add a visible `Print` route assumed Lazarus exposed `TPrintDialog` through the currently imported LCL units in this project
- Core error: `Identifier not found "TPrintDialog"` during the `mainform.pas` compile after wiring `File -> Print`
- Investigation: reran `lazbuild`, then searched the local Lazarus tree and confirmed the dialog type exists only through printer-specific dialog units that are not already on this project's current compile path
- Root cause: the current workspace uses a narrower LCL import set than the first implementation assumed, so the print dialog type was not directly available in `mainform.pas`
- Fix: kept the explicit `Print` menu/toolbar routes but changed the implementation to render directly to the default printer through `Printers`, with a message dialog on failure, instead of blocking the feature on the missing dialog type
- Reuse note: when adding Lazarus printing paths, verify whether dialog types come from the current imported unit set before coding against them; if the dialog layer is unavailable, keep the visible route and fall back to a simpler direct-printer path
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first repository-local FPCUnit runner failed even though the test source files existed
- Core error: the compiler could not resolve `FPSurfaceTests`, and the first runner pass also treated `DefaultFormat` / `DefaultRunAllTests` like object members instead of the globals exposed by `consoletestrunner`
- Investigation: compiled the new test runner directly, read the exact unit-resolution and member errors, and inspected the local FPCUnit installation metadata
- Root cause: Free Pascal expects unit declarations to match filenames for simple source resolution, and the console runner's default settings are package-level globals, not `TTestRunner` instance properties
- Fix: renamed the test unit declarations to match `fpsurface_tests.pas` and `fpuihelpers_tests.pas`, then set `DefaultFormat` and `DefaultRunAllTests` as globals before initializing the runner
- Reuse note: when bootstrapping FPCUnit in a fresh repo, make the unit name match the file name exactly and inspect the installed runner API before assuming example code maps one-to-one onto the current package build
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first new blur/convolution pass added an extra clamp helper in the pixel-sampling hot path, and Free Pascal kept leaving that helper as a real call inside the inner loops
- Core error: the effects rebuild emitted repeated `Call to subroutine "function ClampIndex(...)" marked as inline is not inlined` notes across the new blur and kernel code
- Investigation: rebuilt the CLI immediately after the first effects pass, saw the note count spike, and traced the repeated non-inlined calls back to the helper used by `PixelAtClamped`
- Root cause: the current FPC optimizer accepts `inline` annotations but still may refuse to inline small helpers in hot raster loops, so adding one more abstraction layer can still cost repeated call overhead
- Fix: removed the separate clamp helper, folded the boundary clamp logic directly into `PixelAtClamped`, and reran the build until the new effects path was back down to the pre-existing note baseline
- Reuse note: in Free Pascal raster hot paths, do not assume `inline` guarantees code shape; if a helper lives in the innermost loop and the compiler keeps it as a call, collapse it into the caller and recheck the compile output
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: a defensive pre-initialization pass still did not silence the native-document magic-header compiler hint
- Core error: even after adding and then removing a `FillChar`, FPC still reports `Local variable "MagicRead" does not seem to be initialized` around the fixed-size header buffer
- Investigation: rebuilt both the CLI and the Lazarus project after each variation and traced the remaining hint back to the fixed array used immediately before `ReadBuffer` / `CompareMem`
- Root cause: this is a conservative FPC definite-assignment hint around a fixed local array passed through low-level IO calls, not a demonstrated runtime bug in the actual read path
- Fix: removed the unnecessary pre-clear, kept the direct `ReadBuffer` path, and treated the remaining message as a compiler-hint limitation unless a stronger code reason appears
- Reuse note: do not cargo-cult extra buffer initialization just to silence a Free Pascal hint; if `ReadBuffer` fully populates the array and the runtime logic is sound, document the false-positive and move on
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first GUI color-picker routing could update the wrong target color even when the user clicked the correct mouse button
- Core error: primary and secondary picks were distinguished by comparing color values instead of remembering which button initiated the pick
- Investigation: reviewed the `tkColorPicker` path while expanding the GUI tool surface and traced the target choice back to `RGBAEqual(FStrokeColor, FSecondaryColor)`
- Root cause: the initial implementation inferred intent from current color equality instead of preserving the real input event context
- Fix: stored whether the pick started from the right mouse button and routed the sampled color using that explicit flag
- Reuse note: when input semantics depend on the initiating button or modifier, preserve that event context explicitly; do not infer user intent later from mutable state values
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the GUI paint path was doing full image recomposition and bitmap rebuilding on every repaint, which would scale badly with window exposes, scrolling, and large documents
- Core error: the old `PaintCanvasTo` path rebuilt the display surface and called `SurfaceToBitmap` every time the control painted, even when no document pixels had changed
- Investigation: reviewed the current canvas hot path after the user's repeated performance warnings and compared it against the local Lazarus documentation for `DoubleBuffered` controls and scrolling repaint behavior
- Root cause: the initial GUI pass treated paint events like draw commands instead of separating "document changed" from "control needs repaint"
- Fix: enabled `DoubleBuffered` on the custom canvas control, added a prepared-bitmap cache keyed by document render revisions, and kept the expensive surface-to-bitmap conversion on the content-change path instead of the raw paint path
- Reuse note: in Lazarus custom painting, follow the documented prepared-bitmap pattern; if repaint frequency can exceed mutation frequency, cache the rendered bitmap and invalidate it only on real content changes
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first `View` menu shortcut pass assumed Windows-style virtual-key constants that are not actually available in this Lazarus/LCL context
- Core error: `Identifier not found "VK_EQUAL"` and `Identifier not found "VK_MINUS"`
- Investigation: rebuilt the Lazarus project immediately after wiring zoom shortcuts and traced the compile stop to the new `ShortCut(...)` calls in `mainform.pas`
- Root cause: the current LCL keycode set in this build context does not expose `VK_EQUAL` and `VK_MINUS` constants the way some other UI stacks do
- Fix: changed the shortcut definitions to use the actual character codes (`Ord('=')` and `Ord('-')`) instead of relying on missing constants
- Reuse note: when adding keyboard shortcuts in Lazarus, verify the specific key constants exist in the current LCL target; for printable keys, raw character codes are often the safer portable path
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first GUI clipboard pass copied selection-shaped pixels but still behaved unlike a real editor when pasting
- Core error: copied selections were stored as full-canvas rasters and pasted back at `0,0`, so pasted content ignored its original placement and wasted memory on large documents
- Investigation: reviewed the new `Cut` / `Copy` / `Paste` handlers after wiring them into the toolbar and compared the behavior against practical editor expectations
- Root cause: the initial pass reused the simplest shared-core selection export path without preserving the selection bounds as explicit clipboard metadata
- Fix: switched the GUI clipboard flow to crop copies to the selection bounds, store the source top-left separately, add a shared-core merged-copy path, and paste the copied block back at the preserved offset
- Reuse note: clipboard data in an image editor is not just pixels; if a selection is copied, preserve both the minimal raster bounds and the placement origin or paste behavior will feel broken even when the pixels are technically correct
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first magic-wand GUI pass reused the same numeric control as brush size without separating the stored values
- Core error: changing wand tolerance would overwrite the next brush/shape size, and changing brush size would silently alter the next wand selection tolerance
- Investigation: reviewed the current toolbar control semantics while improving everyday GUI usability and traced the shared state back to a single `FBrushSize` field being used for two unrelated tool families
- Root cause: the initial implementation shared one persisted numeric field across incompatible tool-option semantics
- Fix: split the state into separate brush-size and wand-tolerance fields and made the visible option control switch meaning based on the active tool
- Reuse note: if one visible control is reused across tools, split the stored state by semantic domain even if the UI control itself is shared
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: Lazarus builds failed immediately in the current shell even though the local Lazarus tree was present
- Core error: `zsh:1: command not found: lazbuild`
- Investigation: reran the known build command in the workspace shell, then checked the checked-out binary directly with `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild --version`
- Root cause: this environment does not export the local Lazarus binary directory on `PATH`
- Fix: switched current build invocations to the explicit local binary path `/Users/kurisu/Documents/workspace.nosync/lazarus/lazbuild`
- Reuse note: in this repository, call Lazarus tools through the checked-out tree path first; do not assume `PATH` is configured
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: some GUI edits were mutating serialized document state without participating in dirty-state or history bookkeeping
- Core error: selection changes could alter the persisted `.fpd` selection mask without marking the document dirty, and layer-visibility toggles bypassed the normal history path
- Investigation: reviewed `mainform.pas` while wiring lasso selection and clipboard commands, then compared the GUI handlers against what the shared document model actually persists and snapshots
- Root cause: early GUI handlers treated selection and visibility more like transient UI state than real document mutations
- Fix: routed selection and visibility changes back through the same mutation bookkeeping as other edits by marking selection changes dirty, pushing history for visibility changes, and using the shared setter path consistently
- Reuse note: if a UI action affects state that is serialized or undoable, it must follow the same dirty/history path as pixel edits instead of being treated like viewport-only state
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: a new shared-core method failed to compile because the interface declaration grouped defaulted parameters the C-style way
- Core error: `Default value can only be assigned to one parameter`
- Investigation: rebuilt the CLI after adding `PasteAsNewLayer` and traced the compile stop to the grouped `OffsetX, OffsetY: Integer = 0` signature
- Root cause: Free Pascal does not allow one default-value clause to cover multiple identifiers in the same parameter group
- Fix: split the declaration so each defaulted parameter has its own slot (`OffsetX: Integer = 0; OffsetY: Integer = 0`)
- Reuse note: in Free Pascal, if multiple adjacent parameters need defaults, declare them separately instead of sharing one default clause across a comma-separated group
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: a new CLI helper returning polygon points triggered a managed-result warning on every build
- Core error: `function result variable of a managed type does not seem to be initialized`
- Investigation: rebuilt `flatpaint_cli` after adding lasso parsing and traced the compiler warning to `ParsePolygonPoints`
- Root cause: the function could raise during argument validation before `Result` had been assigned, so Free Pascal could not prove the dynamic array result started in a safe state
- Fix: initialized the function result to `nil` before any validation branches
- Reuse note: when a Free Pascal function returns a dynamic array or string and may exit early through validation errors, initialize `Result` first so the compiler and runtime both see a defined managed state
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: native-document layer import was still rejecting mismatched raster sizes instead of behaving like a practical editor import path
- Core error: the old `addlayerdoc` path raised `Layer image size must match the native document canvas`
- Investigation: reviewed the native-doc CLI commands while expanding layer management and compared the behavior against the still-open layer-size adaptation gap
- Root cause: the first implementation treated a layer image as if it had to be a pre-sized full-canvas bitmap, which is too strict for normal import workflows
- Fix: added a shared surface-paste path and changed layer import to place the source raster into a transparent document-sized layer at the top-left, clipping overflow instead of failing
- Reuse note: layer import in a paint-style editor should default to a predictable placement strategy; hard-failing on size mismatch should be the exception, not the baseline
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first selected-region erase path reused normal alpha blending
- Core error: erasing a selected region with a transparent source color would leave the original pixels intact instead of clearing them
- Investigation: reviewed the new selection-editing code path and checked how `BlendPixel` treats a source pixel with zero alpha
- Root cause: standard alpha compositing correctly treats an alpha-0 source as "no contribution", which is not the same thing as destructive erase
- Fix: changed selection erase to write fully transparent pixels directly instead of routing through the normal blend path
- Reuse note: in raster editors, erase semantics and paint-with-transparent semantics are not interchangeable; verify destructive paths bypass normal compositing when the expected result is actual pixel removal
- Repeat count: This issue has occurred 1 time(s)

- Problem: compiling a core unit directly with `fpc -FU...` failed before it even reached the source error being checked
- Core error: `Can't create assembler file: ./lib/corecheck/fpcolor.s`
- Investigation: ran a no-link compile of `fpdocument.pas` and saw the compiler stop while trying to emit assembly output into the chosen unit-output directory
- Root cause: FPC does not create the `-FU` output directory automatically for this command path
- Fix: created `lib/corecheck` explicitly before rerunning the compile
- Reuse note: when using ad hoc FPC compile commands with `-FU`, create the output directory first instead of assuming the compiler will do it
- Repeat count: This issue has occurred 1 time(s)

- Problem: a document-transform pass failed to compile after adding 90-degree rotation helpers
- Core error: `Identifier not found "Exchange"`
- Investigation: reran a direct compile on `fpdocument.pas` after the new methods were added and traced the failure to the width/height swap lines
- Root cause: the code assumed a generic integer `Exchange` helper would exist in this FPC context, but it does not
- Fix: replaced the call with an explicit temporary-variable swap
- Reuse note: in Free Pascal, prefer explicit swaps for scalar fields unless a known local helper is already present
- Repeat count: This issue has occurred 1 time(s)

- Problem: the Lazarus project could not reuse the prebuilt LCL units with the currently installed Free Pascal compiler
- Core error: `Can't find unit InterfaceBase used by Interfaces` after the compiler reported a checksum change against the RTL `types.ppu`
- Investigation: attempted a normal `lazbuild`, then traced the failure to stale widgetset PPUs and missing source/include paths during automatic recompilation
- Root cause: the local Lazarus tree carried precompiled LCL units built against a different FPC RTL snapshot than the active `/usr/local/bin/fpc`
- Fix: added the Lazarus source/include directories to the project search paths so the compiler can rebuild missing LCL units from source into the repository-local `lib` directory
- Reuse note: when Lazarus and FPC are version-skewed, assume the packaged widgetset PPUs are disposable and switch quickly to a source-rebuild path
- Repeat count: This issue has occurred 1 time(s)

- Problem: the Lazarus Cocoa app still failed at final link even after the project and widgetset sources compiled
- Core error: `ld: malformed method list atom 'ltmp5' (.../cocoawsextctrls.o), fixups found beyond the number of method entries`
- Investigation: pushed the build all the way through application-unit compilation and confirmed the failure remained in the Cocoa widgetset object, not in project units
- Root cause: the current Lazarus Cocoa widgetset output is not link-compatible with this toolchain combination, so the failure is in the UI stack below the application layer
- Fix: stopped treating the GUI linker fault as an app-code bug, split the editing core away from LCL-only dependencies, and added a separate CLI front-end so the rewrite can deliver real image processing while the Cocoa issue is isolated
- Reuse note: if the build reaches app-code completion and then dies inside widgetset objects, isolate the engine immediately instead of stalling the whole rewrite on UI packaging
- Repeat count: This issue has occurred 1 time(s)

- Problem: `swift test` could not run in the default workspace sandbox
- Core error: `sandbox-exec: sandbox_apply: Operation not permitted`
- Investigation: ran `swift test`, then inspected the manifest/cache failure output
- Root cause: SwiftPM needed system cache and sandbox facilities not available in the default workspace sandbox
- Fix: reran `swift test` with elevated execution permissions
- Reuse note: for SwiftPM-based macOS desktop projects, expect the build/test toolchain to need broader system access than simple file-only tasks
- Repeat count: This issue has occurred 1 time(s)

- Problem: the app target failed to compile because the module had two entry points
- Core error: `'main' attribute can only apply to one type in a module`
- Investigation: inspected `Sources/FlatPaintApp` after the build failed
- Root cause: the generated package starter entry point remained alongside the real app entry point
- Fix: deleted the leftover generated `Sources/FlatPaintApp/FlatPaint.swift`
- Reuse note: after package scaffolding changes, always re-scan the executable target for stale bootstrapping files
- Repeat count: This issue has occurred 1 time(s)

- Problem: tests crashed during concurrent execution after pixel-editing APIs were added
- Core error: `Simultaneous accesses ... modification requires exclusive access`
- Investigation: reran `swift test` and read the exclusivity stack traces around `mutateSelectedLayer`
- Root cause: closures mutating a selected layer also read `document` state inside the same exclusive mutation window
- Fix: copied color and selection inputs into local constants before entering the mutating closure
- Reuse note: in Swift, never read the owning aggregate inside a closure that mutates one of its inout members
- Repeat count: This issue has occurred 1 time(s)

- Problem: tests crashed again after adding selected-pixel move support
- Core error: `Simultaneous accesses ... modification requires exclusive access`
- Investigation: reran `swift test` and traced the conflict to `moveSelectedPixelsBy`
- Root cause: the mutation closure still read `document.size` while mutating the selected layer
- Fix: copied `document.size` into a local constant before entering the mutation closure
- Reuse note: after fixing one exclusivity case, re-check every new mutation closure for hidden reads of the owning store
- Repeat count: This issue has occurred 2 time(s)

- Problem: the first integration undo assertion failed after adding zoom state into the same history stack
- Core error: `Expectation failed: (store.document.layers.count -> 1) == 2`
- Investigation: checked the integration test sequence and counted the last two history-producing operations
- Root cause: the most recent undo reverted viewport zoom before reverting the prior merge operation
- Fix: updated the integration test to undo twice and assert each intermediate state explicitly
- Reuse note: when UI state and document state share one history stack, integration tests must assert the exact mutation sequence
- Repeat count: This issue has occurred 1 time(s)

- Problem: manual startup smoke emitted LaunchServices connection warnings
- Core error: `Connection invalid` and `Connection Invalid error for service com.apple.hiservices-xpcservice`
- Investigation: launched `./.build/debug/FlatPaintApp` from the terminal session and watched stderr
- Root cause: the current execution environment's LaunchServices/Desktop session is partially restricted, even though the app process itself stayed alive
- Fix: no code change; treated as an environment warning and verified the process remained running until manual interruption
- Reuse note: separate true app crashes from desktop-session warnings when launching GUI apps from an automated terminal context
- Repeat count: This issue has occurred 1 time(s)

- Problem: menu bar commands, quick actions, and tool configuration were under-specified relative to actual usability expectations
- Core error: missing first-class product requirements for system menus, shortcut surfaces, and config surfaces
- Investigation: reviewed the current PRD and implementation documents against the active app shell and identified that these surfaces were implied but not explicitly required
- Root cause: it is easy to treat command surfaces as polish instead of core workflow functionality in desktop apps
- Fix: promoted menus, quick actions, and tool/config option surfaces into explicit PRD scope, implementation milestones, and SOW acceptance
- Reuse note: in desktop productivity tools, document command discoverability and configuration surfaces as core requirements from the start
- Repeat count: This issue has occurred 1 time(s)

- Problem: app compilation failed after adding layer property controls
- Core error: `'BlendMode' is ambiguous for type lookup in this context` and `the compiler is unable to type-check this expression in reasonable time`
- Investigation: ran `swift test` after adding the inspector controls and read the compiler diagnostics in `FlatPaintApp.swift`
- Root cause: the app view referenced `BlendMode` without qualifying it against `SwiftUI.BlendMode`, and the inspector view became too large for the type checker
- Fix: explicitly used `FlatPaintCore.BlendMode` and split the inspector into smaller computed subviews
- Reuse note: in SwiftUI-heavy files, prefer explicit type qualification and smaller view fragments before the compiler starts timing out
- Repeat count: This issue has occurred 1 time(s)

- Problem: hidden save/open-sheet capabilities were still under-modeled even after the primary menu surfaces were defined
- Core error: export controls and compatibility import paths were not explicitly exposed where users expect them in desktop file dialogs
- Investigation: compared the existing menu coverage against actual save/open flows and checked the current PRD/feature matrix for missing dialog-level requirements
- Root cause: desktop workflow details hidden inside sheets are easy to miss when feature tracking stops at top-level menu commands
- Fix: added explicit PRD/SOW/plan scope for format-specific export options and compatibility import, then implemented save-panel accessory controls and a dedicated project import flow
- Reuse note: for desktop tools, audit both the visible menu commands and the option surfaces inside the modal sheets they trigger
- Repeat count: This issue has occurred 1 time(s)

- Problem: the first file-panel filtering pass introduced avoidable platform deprecation warnings
- Core error: `'allowedFileTypes' was deprecated in macOS 12.0: Use -allowedContentTypes instead`
- Investigation: reran `swift test` and read the compiler warnings emitted from `FlatPaintApp.swift`
- Root cause: the initial implementation used the older extension-string API as the quickest path to support multiple file types
- Fix: switched raster/native file panels to `allowedContentTypes` and kept the external project picker unconstrained with explicit user guidance text
- Reuse note: after wiring AppKit panels quickly, always rerun the build and pay down deprecation warnings before they become baseline noise
- Repeat count: This issue has occurred 1 time(s)

- Problem: the GUI smoke-test launch path left the app attached to a non-interactive session without a clean stdin shutdown path
- Core error: `write_stdin failed: stdin is closed for this session`
- Investigation: launched the app for a smoke run, then attempted to stop it through the session handle and checked the running process list
- Root cause: the app was launched without a TTY, so the session could not receive an interrupt and required process-level cleanup
- Fix: verified the live PID with `ps`, then stopped the app with an explicit `kill`
- Reuse note: for GUI smoke tests that may need manual teardown, prefer a controllable launch path or be ready to clean up by PID
- Repeat count: This issue has occurred 1 time(s)

- Problem: the first expanded clipboard regression run crashed the test process
- Core error: `error: Exited with unexpected signal code 11`
- Investigation: reran `swift test`, saw two pasteboard-using tests start concurrently, and confirmed the attempted `@Test(.serialized)` trait emitted a warning that it had no effect
- Root cause: multiple tests were touching the global macOS pasteboard in parallel, and the chosen serialization trait did not apply to that test shape
- Fix: collapsed all pasteboard coverage into a single integration test that owns composite-copy, selection-copy, cut, and paste assertions sequentially
- Reuse note: for global OS resources like the system pasteboard, prefer one consolidated integration test or a suite-level serialization mechanism that actually applies
- Repeat count: This issue has occurred 1 time(s)

- Problem: shortcut behavior had drifted into a Windows-literal mindset instead of a macOS-native translation of paint.net intent
- Core error: `Command+S` still behaved like Save As, and deselection was incorrectly attached to plain `Delete`
- Investigation: audited the menu command layer against actual desktop conventions and compared it to the newly documented shortcut intent rules
- Root cause: shortcut intent and shortcut key mapping had not been formalized as a separate product rule, so provisional bindings stayed in place too long
- Fix: added `docs/SHORTCUT_POLICY.md`, split `Save` and `Save As`, moved deselect to `Command+D`, and reserved plain `Delete` for destructive pixel clearing
- Reuse note: on cross-platform desktop recreations, define command intent separately from physical key mapping as soon as menus become real
- Repeat count: This issue has occurred 1 time(s)

- Problem: the original unified Open flow behaved like Import for normal image files
- Core error: opening a raster file added a layer into the existing workspace instead of replacing it with a new document
- Investigation: reviewed the file workflow against paint.net expectations during the completion audit and traced the behavior to `openDocumentOrImport`
- Root cause: the first implementation optimized for reuse by routing all non-native files through layer import instead of distinguishing open-versus-import intent
- Fix: split raster/project opening into document-replacing paths and kept explicit Import commands as layer-add flows
- Reuse note: when a product has both Open and Import, never share the same document mutation path unless the UX explicitly matches
- Repeat count: This issue has occurred 1 time(s)

- Problem: the first rulers/grid UI pass failed to compile
- Core error: `binary operator '*' cannot be applied to operands of type 'Int' and 'Double'`
- Investigation: ran `swift test` immediately after adding the new view-layer UI and read the compiler error in `FlatPaintApp.swift`
- Root cause: the new canvas-size calculation mixed integer pixel dimensions with floating-point zoom without an explicit conversion
- Fix: converted the raster dimensions to `Double` before multiplying by zoom
- Reuse note: in SwiftUI layout code, cast pixel counts at the view boundary so zoom math stays consistently floating-point
- Repeat count: This issue has occurred 1 time(s)

- Problem: the freshly built `.app` bundle crashed when its inner executable was launched directly from the terminal
- Core error: `Program crashed: Signal 6` when running `./dist/FlatPaint.app/Contents/MacOS/FlatPaintApp`
- Investigation: compared direct binary launch with a LaunchServices launch and checked the resulting process state
- Root cause: the bundle was valid for LaunchServices startup, but direct terminal execution did not replicate the expected app-launch environment for this GUI target
- Fix: validated the bundle using `open dist/FlatPaint.app`, confirmed the app process stayed alive, and kept the bundle-generation script while treating `open` as the correct smoke path
- Reuse note: for macOS GUI bundles, validate the `.app` with LaunchServices rather than assuming direct execution of the inner Mach-O is equivalent
- Repeat count: This issue has occurred 1 time(s)

- Problem: major desktop-UI expectations around detachable palettes and visual icon cues were still missing even after substantial functional progress
- Core error: the workspace remained too text-heavy and too rigid to feel like a credible paint.net-style desktop editor
- Investigation: compared the current shell against paint.net-style desktop usage expectations and reviewed the remaining feature-matrix gaps called out by user feedback
- Root cause: the implementation had prioritized functional breadth over workspace ergonomics, leaving panel mobility and iconography under-specified
- Fix: promoted detachable floating palettes and coherent iconography into PRD/SOW scope, then added floating tools/layers/history windows and an icon-backed tool palette
- Reuse note: in desktop recreation projects, treat workspace ergonomics as core product scope once the main editing loop becomes usable
- Repeat count: This issue has occurred 1 time(s)

- Problem: very large images opened at a default 1:1 zoom and destabilized the workspace layout
- Core error: the canvas expanded visually enough to make the UI feel squeezed and hide practical control surfaces
- Investigation: traced the issue to two combined factors: opened raster documents kept a 1.0 zoom by default, and the workspace layout previously let panels compete with the canvas for width
- Root cause: large-image initial viewport behavior and desktop overlay layout had not yet been treated as first-class UX requirements
- Fix: added proportional fit-to-view behavior for large opened images, introduced an explicit fit-to-view command, and changed the side control surfaces to float above the canvas instead of consuming the main layout width
- Reuse note: in canvas-heavy desktop apps, large-document defaults and overlay layout strategy are inseparable usability decisions
- Repeat count: This issue has occurred 1 time(s)

- Problem: functional progress was being mistaken for visual parity with paint.net
- Core error: the app had many matching commands, but the default layout and control placement still looked materially different from paint.net
- Investigation: compared the current workspace against official paint.net main-window, toolbar, status-bar, tools, layers, history, and colors documentation after user feedback highlighted the mismatch
- Root cause: feature tracking had been stronger than visual-layout tracking, so the project lacked a dedicated UI parity baseline
- Fix: created `docs/UI_PARITY_AUDIT.md`, promoted it into the PRD and feature matrix, and made it the binding checklist for future workspace-layout work
- Reuse note: in desktop recreation projects, maintain a separate visual-parity audit; a complete feature matrix does not prove the UI feels correct
- Repeat count: This issue has occurred 1 time(s)

- Problem: the floating-palette cleanup path failed to compile after actor isolation was tightened
- Core error: `call to main actor-isolated instance method 'detachObservers()' in a synchronous nonisolated context`
- Investigation: reran `swift test` after the documentation pass and read the compiler error in `FlatPaintApp.swift`
- Root cause: `deinit` is nonisolated, but it called an `@MainActor` helper method directly
- Fix: moved the final observer-removal and delayed-selector cancellation calls inline inside `deinit` instead of routing through the actor-isolated helper
- Reuse note: in `@MainActor` AppKit coordinators, treat `deinit` as a special nonisolated cleanup path and avoid calling actor-isolated helpers from it
- Repeat count: This issue has occurred 1 time(s)

- Problem: the docked tools surface had drifted into an oversized quick-action sidebar instead of a paint.net-like tool palette
- Core error: the left panel contained too many stacked action buttons, making the default workspace read like a generic utility app instead of a compact editor
- Investigation: compared the current tools panel against the UI parity audit and identified that the longest mismatch was the docked tools panel shape, not just icon choice
- Root cause: convenience actions were added directly into the default tools surface without a separate check against paint.net palette density
- Fix: compressed the docked tools surface, moved palette access into compact launcher buttons, added a dedicated floating `Colors` window, and tightened the top toolbar so utility windows are easier to treat as the primary control model
- Reuse note: in UI-parity work, do not let debug convenience controls stay embedded in the default layout once they start changing the workspace silhouette
- Repeat count: This issue has occurred 1 time(s)

- Problem: the main canvas still read like it contained an extra content pane because the full history list was embedded directly under the image
- Core error: even after shrinking the side panels, the bottom-of-canvas history block kept the main workspace from feeling like a canvas-first editor
- Investigation: reviewed the updated layout after the colors-window work and identified the bottom history block as the next strongest source of "app shell" visual weight
- Root cause: a useful history feed had been left embedded in the main window instead of being reduced to a utility-window summary
- Fix: replaced the large embedded history block with a compact floating-style history summary card and shifted more live context into the status bar
- Reuse note: when chasing desktop-editor parity, strip secondary document metadata out of the primary canvas column unless it is truly part of the editing surface
- Repeat count: This issue has occurred 1 time(s)

- Problem: the docked inspector still duplicated too much of the `Colors` window, weakening the desktop-palette mental model
- Core error: the main window and the floating colors palette both looked like primary edit surfaces for the same job
- Investigation: reviewed the post-colors-window layout and saw that the inspector still carried full color editing controls, which diluted the role of the dedicated palette
- Root cause: new floating utility windows had been added before the embedded equivalents were demoted
- Fix: reduced the docked color section to a summary/launcher view, kept detailed color editing in the dedicated `Colors` palette, and added frame autosave so floating palettes behave more like persistent desktop tools
- Reuse note: once a control becomes a true utility window, the docked copy should usually become a summary or launcher instead of remaining a full duplicate editor
- Repeat count: This issue has occurred 1 time(s)

- Problem: even with separate palette windows implemented, the default launch still felt too manual because the user had to open the core palette set themselves
- Core error: the app technically had the right windows, but the first-launch composition still did not resemble paint.net until after extra clicks
- Investigation: reviewed the post-persistence workspace flow and identified that the remaining gap was the default open state, not just palette visuals
- Root cause: the palette windows existed as optional companions, but there was no default session behavior to assemble the palette cluster automatically
- Fix: added a session-scoped palette launch tracker and auto-opened the core palette set on first workspace appearance
- Reuse note: on desktop recreation projects, matching the default visible window set matters almost as much as matching the windows themselves
- Repeat count: This issue has occurred 1 time(s)

- Problem: the main window still looked too bulky because it duplicated full detailed editors that now already existed as floating palette windows
- Core error: even after auto-opening palette windows, the docked inspector and zoom controls still consumed more space than the paint.net-style default composition should
- Investigation: reviewed the updated first-launch layout and identified the remaining width/height pressure as a proportion problem, not a missing-feature problem
- Root cause: once floating palettes became primary, the docked surfaces had not been reduced aggressively enough
- Fix: tightened floating palette target sizes and default frames, shifted zoom emphasis further into the status bar, added explicit `View` commands for palette windows, and reduced the docked layer area to a compact summary/launcher
- Reuse note: when recreating a palette-based desktop editor, once a floating palette becomes primary, continue trimming the docked duplicate until it reads as a summary, not a second full editor
- Repeat count: This issue has occurred 1 time(s)

- Problem: palette-window commands still behaved too much like document windows because repeated opens could create duplicates
- Core error: the app had the right palette windows, but their scene model still allowed repeated spawning instead of consistent utility-window focus behavior
- Investigation: reviewed the palette launch path after adding auto-open and menu commands, and identified the scene type as the remaining mismatch
- Root cause: the palettes were defined as `WindowGroup`, which favors repeated window creation semantics
- Fix: converted the core palettes to single-instance `Window` scenes and assigned direct `Command+1...4` shortcuts to focus them from `View`
- Reuse note: for desktop utility panels, prefer single-instance window scenes once the intended behavior is "open or focus" rather than "create another window"
- Repeat count: This issue has occurred 1 time(s)

- Problem: continuous viewport interaction felt rough because zoom controls were using the same history-recording path as deliberate command actions
- Core error: smooth zoom interactions such as a slider or trackpad pinch would churn state in a way that made the UI feel sticky and cluttered history
- Investigation: reviewed the current viewport APIs and found that `setZoomScale()` recorded a history entry on every change, which is inappropriate for continuous input
- Root cause: command-style viewport mutations and interactive viewport mutations were sharing the same state path
- Fix: added a no-history interactive zoom path, moved continuous zoom controls to it, and wired a baseline pinch-to-zoom gesture onto the canvas
- Reuse note: continuous viewport gestures should almost never share the exact same mutation path as discrete menu commands
- Repeat count: This issue has occurred 1 time(s)

- Problem: the main workspace still showed overlapping tool surfaces and the inspector obscured part of the UI
- Core error: docked `Tools` and `Inspector` overlays visually fought with the rest of the main window and created avoidable obstruction
- Investigation: compared the current launch state against the reported overlap and confirmed that the main window was still rendering large docked overlays even though floating utility windows were already the primary model
- Root cause: the project had retained the old docked overlays after introducing auto-opened floating palettes, creating duplicate and competing surfaces
- Fix: removed the large docked `Tools` and `Inspector` overlays from the main workspace and kept the floating palette set as the primary detailed tool surface
- Reuse note: once floating utility windows become the primary workflow, remove old docked duplicates instead of trying to keep both visible
- Repeat count: This issue has occurred 1 time(s)

- Problem: zoom still felt unsmooth even after history churn was removed
- Core error: the SwiftUI `MagnificationGesture` path still felt less direct than native macOS image zoom, and the app visually regressed into showing two history surfaces while the inspector role became unclear
- Investigation: compared the workspace after the first smoothness pass against the reported behavior, then traced zoom handling to the SwiftUI gesture layer and verified the bottom dock card was still the wrong summary surface
- Root cause: the first smoothness fix removed history churn but still routed pinch through a higher-level SwiftUI gesture path, and a later dock-summary change left the bottom card mislabeled in product terms
- Fix: replaced the pinch path with an AppKit-backed `NSScrollView` viewport that handles magnify events directly, converted the bottom dock card into a compact `Inspector` launcher summary, and attached floating palette windows to the main editor window as child windows at normal level so they no longer feel globally topmost
- Reuse note: for macOS image editors, treat trackpad zoom and palette ordering as AppKit-level concerns early; SwiftUI-only gesture layers and loosely owned utility windows are adequate for prototypes but not for desktop-feel polish
- Repeat count: This issue has occurred 1 time(s)

- Problem: viewport-only zoom changes still felt heavier than they should because preview conversion work kept recurring
- Core error: continuous zoom still rebuilt expensive preview objects often enough to feel sluggish
- Investigation: traced the remaining cost path in `WorkspaceView` and found that viewport-only changes were still recomputing the composited raster and recreating the `NSImage` bridge during view updates
- Root cause: preview rendering was tied too closely to SwiftUI body recomputation instead of being cached across content-stable viewport changes
- Fix: cached both the composited `RasterImage` and its `NSImage` bridge behind a history-timestamp token, so viewport-only changes reuse the existing preview image
- Reuse note: after separating interactive input from history, also check whether preview conversion layers are still being rebuilt during every frame
- Repeat count: This issue has occurred 1 time(s)

- Problem: standalone palette windows and ad hoc default placement drifted away from paint.net's main-window model
- Core error: utility surfaces were opening in the wrong relationship and wrong default positions, which made the main workspace read unlike paint.net
- Investigation: compared the implemented launch layout against paint.net references and checked whether panel placement was being treated as a fixed product baseline or as a freeform window system
- Root cause: the UI model left too much freedom in windowing and default placement instead of enforcing the product's canonical launch layout
- Fix: kept the utility surfaces inside the main editor window as child panels and reset their default launch positions to a fixed paint.net-style arrangement on every run
- Reuse note: if the target product has a canonical default layout, treat it as a product rule, not a preference
- Repeat count: This issue has occurred 1 time(s)

- Problem: new tool cases were added to the shared enum before the app-layer switches were updated
- Core error: `switch must be exhaustive` in `FlatPaintApp.swift` after adding `panCanvas` and `cropCanvas`
- Investigation: reran `swift test` immediately after extending `ToolIdentifier` and read the compiler diagnostics
- Root cause: the enum changed first, but the UI routing and tool metadata switches were still assuming the older tool set
- Fix: completed the app-layer switch coverage at the same time as the enum expansion and added a catalog-completeness unit test so the tool surface cannot silently omit a core tool
- Reuse note: when expanding a shared tool enum, patch the metadata and routing switches in the same change and backstop it with a coverage test
- Repeat count: This issue has occurred 1 time(s)

- Problem: the lasso gesture looked present in the UI but behaved like a rectangle drag
- Core error: drag-based lasso input collapsed to a four-corner bounding box instead of preserving the user path
- Investigation: reviewed the canvas gesture code after tool complaints and found that the lasso branch rebuilt a rectangle from drag start/end instead of recording intermediate points
- Root cause: the first tool-gesture pass focused on getting every tool routed, but freeform path capture was never implemented for lasso
- Fix: added gesture-time lasso point capture, preserved the freeform path when enough points exist, and added a dedicated polygon-selection unit test
- Reuse note: freeform tools need path-state coverage, not just a final start/end dispatch path
- Repeat count: This issue has occurred 1 time(s)

- Problem: a new Swift Testing assertion failed to compile in the added tool-coverage tests
- Core error: `errors thrown from here are not handled` at `try #require(...)`
- Investigation: reran `swift test` immediately after adding the new test file and read the compile diagnostic for the specific test function
- Root cause: `#require` can throw, but the test function signature was not marked `throws`
- Fix: marked the affected test as `throws` and reran the full suite
- Reuse note: when using `#require` in `swift-testing`, treat the enclosing test as throwing unless you unwrap another way
- Repeat count: This issue has occurred 1 time(s)

- Problem: command-surface tracking was still too coarse even after menu-category tests were added
- Core error: visible controls could exist in the UI while only a subset of them had true one-to-one implementation and route-level coverage
- Investigation: compared the current test counts against the actual number of visible menu items, toolbar icons, and tool icons, then reviewed the feature docs and found they were still grouped too broadly
- Root cause: menu-level and tool-group-level coverage was being treated as if it proved per-control completion, which overstates readiness for a desktop editor
- Fix: added `docs/COMMAND_SURFACE_BASELINE.md` and `docs/COMMAND_SURFACE_BREAKDOWN.md`, and raised the documentation baseline so every visible control must be tracked and tested individually before UAT
- Reuse note: in UI-heavy desktop apps, count visible controls, not just menu categories, when deciding whether coverage is credible
- Repeat count: This issue has occurred 1 time(s)

- Problem: the app shell architecture was still single-document, which blocked a faithful paint.net-style image list
- Core error: `Open` could only replace one active workspace, and there was no stable way to switch or close multiple open images
- Investigation: reviewed the current app state model after the command-surface audit and found that the app still held exactly one `CanvasDocumentStore` plus one URL slot
- Root cause: the first shell implementation optimized for getting editing running at all, but it hard-coded a single-document model
- Fix: introduced `WorkspaceDocumentController` and `WorkspaceDocumentSession` in the core layer, then rebuilt the shell around a real tab strip with activate, close, drag reorder, and unsaved markers
- Reuse note: if the reference app is tabbed, do not let the shell stay single-document past the prototype stage
- Repeat count: This issue has occurred 1 time(s)

- Problem: adding save-baseline tracking exposed a dirty-state regression in `Save As`
- Core error: the document could become "unsaved" again immediately after a successful save
- Investigation: traced the save path after introducing revision tracking and found that the title change happened after writing the file
- Root cause: `Save As` changed the document title after persisting, which counted as a fresh mutation after the save baseline
- Fix: moved the title normalization ahead of the file write and only marked the save baseline after both the title and file contents were aligned
- Reuse note: once you track unsaved state, audit every post-save mutation in the save path
- Repeat count: This issue has occurred 1 time(s)

- Problem: once the tab strip existed, image-list navigation was still weaker than the reference app
- Core error: users could click tabs, but there was no quick previous/next image traversal path and no contextual tab actions
- Investigation: reviewed the new tabbed shell against the command-surface checklist and found the image-list row was still only partially satisfied
- Root cause: the first tab implementation focused on getting multi-document state in place, but it left navigation affordances underpowered
- Fix: added next/previous session navigation in the controller, exposed it in the tab strip and `View`, and added a baseline tab context menu
- Reuse note: when adding a new shell surface, audit not just existence but also its key navigation affordances immediately after the first implementation
- Repeat count: This issue has occurred 1 time(s)

- Problem: the `Image` menu still contained a fake "resize by 25%" command long after the rest of the menu was becoming real
- Core error: a visible geometry command existed, but it was a convenience placeholder instead of a real `Resize...` / `Canvas Size...` workflow
- Investigation: reviewed the menu against the command-surface checklist and identified the hardcoded size multiplier as an obvious parity break
- Root cause: an early placeholder survived because it was "good enough" for manual testing, even though it did not match the product requirement
- Fix: added real image resampling and separate canvas-size dialogs, then replaced the placeholder route with explicit `Resize...` and `Canvas Size...`
- Reuse note: any visible placeholder command should be treated as debt immediately once command-surface parity becomes a tracked requirement
- Repeat count: This issue has occurred 1 time(s)
- Reuse note: for UI parity work, treat default panel placement as product behavior, not as a convenience detail
- Repeat count: This issue has occurred 1 time(s)

- Problem: a small number of broad smoke tests made it too easy for menu-command gaps to hide in plain sight
- Core error: the suite could pass while individual menu items still lacked direct, named verification
- Investigation: compared the visible menu surface against the test inventory and counted how many commands had only indirect coverage through larger regression tests
- Root cause: early testing optimized for broad workflow confidence, not for one-to-one traceability with the menu surface
- Fix: added individually named command-equivalent tests for the menu surface and separated file-command branches into explicit integration tests
- Reuse note: for desktop editors, keep a command inventory and force the test list to mirror it; broad smoke tests are not enough once the menu bar becomes real
- Repeat count: This issue has occurred 1 time(s)
