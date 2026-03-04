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

## 2026-03-04 (a visual icon overlay must not become the real click surface)
- Problem: after the icon-overlay pass, manual UAT could still make tools and panel actions feel dead or inconsistent even though the underlying handlers existed.
- Core error: the UI had started treating the overlay image as the clickable control instead of keeping the real button as the interaction source.
- Investigation: re-read the earlier “selected tool but nothing happens” issues, then re-audited the button chrome path and found that `AttachButtonIconOverlay(...)` placed a sibling `TImage` on top of the button and wired it as an active click proxy. That created a second, partially aligned hit surface that could drift from the real button bounds.
- Root cause: the icon layer and the interaction layer had been collapsed together. A decorative overlay was promoted into a stateful input surface, which is brittle in Cocoa and easy to misalign when button sizes change after creation.
- Fix: restored the proper split of responsibilities. Overlay images are now display-only again (`Enabled := False`), command/utility buttons get their final toolbar height before overlay placement, and tool-button overlays are explicitly realigned after the larger tool-button height is applied.
- Reuse note: when adding UI chrome on top of an interactive control, keep the visual layer passive and let the original control remain the single click target. If an overlay must exist, bind its bounds to the final control geometry instead of assuming the creation-time size is final.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (command menus can interrupt stroke state just as badly as palette controls)
- Problem: even after sealing pending strokes across the most obvious UI controls, document-mutating menu commands could still be triggered while a brush-like snapshot was live.
- Core error: the first repair focused on visible interactive controls (`tools`, `layers`, `colors`, `history`), but the transform/adjustment/effect commands use the same document state and can cause the same mismatch if they run first.
- Investigation: reviewed the remaining handlers that call `FDocument.PushHistory` or mutate pixels directly and found that resize, rotate, adjustments, effects, and repeat-effect handlers were still able to run without first sealing a pending stroke.
- Root cause: the interruption rule had been applied by UI surface category instead of by the more correct rule: “any command that mutates the document must not run while a brush snapshot is still pending.”
- Fix: extended the same `SealPendingStrokeHistory` preamble to the remaining transform, adjustment, and effect handlers, plus `RepeatLastEffectClick`.
- Reuse note: when protecting in-flight drawing state, classify by mutation behavior, not by where the command lives in the UI. Menus, palette controls, toolbar buttons, and keyboard commands all belong to the same guard set if they mutate the document.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (pending-stroke fixes must cover UI mutations, not just pointer events)
- Problem: after the first pending-stroke repair, manual UAT could still make brush-like edits feel inconsistent by interrupting the active stroke through UI actions such as changing layers, switching tools, using undo/history, or changing color targets.
- Core error: the stroke state machine had been repaired for “new mouse-down” and document replacement, but other non-drawing UI paths could still mutate app state while a brush snapshot was live.
- Investigation: re-audited handlers that change active layer, history position, tool, color target, palette state, or close state. The common pattern was simple: these handlers could alter what the UI was pointing at without first sealing the in-flight stroke.
- Root cause: the original fix was scoped to pointer-driven continuation cases, while several UI-driven interruption paths were still missing the same pre-mutation guard.
- Fix: standardized those handlers on the existing `SealPendingStrokeHistory` gate before they mutate state. `HistoryListClick`, `UndoClick`, `RedoClick`, tool switches, layer actions, layer property controls, color-target changes, palette toggles, and form close now all seal the stroke first. `LayerBlendModeChanged` was also corrected to behave like a tracked layer edit instead of a silent direct assignment.
- Reuse note: if a tool has an in-flight snapshot, every UI path that can change the active target or rewind document state belongs in the same seal-before-mutate set. Do not stop at pointer events.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (a missing brush MouseUp can silently collapse many visible strokes into one history entry)
- Problem: manual UAT exposed that repeated pencil strokes could stop reading as independent edits: pixels looked pending or inconsistent, and the History list only showed one new entry after multiple separate draws.
- Core error: a fresh mouse-down could start a new brush-like stroke while the previous stroke's region-history snapshot was still pending, which let the new stroke overwrite the pending-stroke state instead of sealing it first.
- Investigation: traced the pencil/brush/eraser path through `PaintBoxMouseDown`, `BeginStrokeHistory`, and `CommitStrokeHistory`, then compared that against the existing "button-state disappeared before MouseUp" safeguard. The gap was a new press with no intervening move: the old stroke could still be pending, and `BeginStrokeHistory` would previously discard that snapshot.
- Root cause: the earlier fallback only finalized drag tools when a later `MouseMove` noticed the button flag had dropped. If the next event was a new `MouseDown` instead of a move, brush-like strokes had no equivalent seal-before-restart guard.
- Fix: brush-like strokes now carry their own `FStrokeTool` label, and a new mouse-down first commits any pending stroke snapshot before starting the next one. `BeginStrokeHistory` also stopped silently throwing away an unfinished snapshot and now seals it instead. The same seal-before-discard rule now also applies before document replacement and tab switching, so an old pending stroke cannot leak across documents.
- Reuse note: for stroke tools, "release" cannot be the only commit trigger. If a new press arrives while a stroke snapshot is still alive, seal the old stroke first or History and visible commit semantics will drift immediately.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (before touching tool logic again, separate “raster mutation failed” from “UI chrome is lying about state”)
- Problem: manual UAT again produced the familiar “it looks like the tool or panel action did not really take effect” symptom after a UI-heavy pass, even though the earlier tool paths had already been repaired.
- Core error: the old prepared-bitmap invalidation class of bug was treated as the default suspect before confirming that the current regression still lived in the raster path.
- Investigation: re-read the existing visual-feedback lessons, then re-audited the live paint/shape/fill/effect commit paths and confirmed they still invalidate the prepared canvas and/or go through the shared mutation-sync helpers. The remaining breakage clustered around button chrome, overlay hit surfaces, and palette-header icon rendering instead.
- Root cause: multiple visible UI issues can masquerade as “the tool is broken”: overlay icons can steal the button feel, command labels can overlap their icons, and palette header icons can render through the wrong asset path even while the underlying tool mutation code is still correct.
- Fix: kept the tool logic untouched, tightened only the visible chrome: widened the file buttons, shrank and repositioned their overlay icons, aligned the zoom combo vertically with the zoom buttons, and forced palette-header icons onto the built-in line-glyph path instead of the problematic rendered-asset path.
- Reuse note: when a fresh UI pass makes the app feel “not applied” again, first verify whether the raster mutation chain still invalidates the canvas before touching tool code. If that path is intact, fix the lying UI surface, not the already-working tool.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (Cocoa `TSpeedButton.Glyph` can report “icon path wired” while the live button still renders blank)
- Problem: the icon asset chain was present and tests said the icons could load, but the live toolbar and visible button surfaces still showed empty buttons in manual UAT.
- Core error: the code treated “glyph bitmap successfully built” as equivalent to “the Cocoa button will actually paint that glyph.”
- Investigation: compared the running app screenshot against the icon-loading code and saw the contradiction directly: captions were being cleared because the glyph path returned success, but the visible button face still had no icon.
- Root cause: on this Lazarus/Cocoa path, `TSpeedButton.Glyph` is not a trustworthy rendering surface for the most visible button chrome. It can succeed as data while still failing as a visible paint path.
- Fix: moved the visible icon rendering for the main command/tool/utility button surfaces to dedicated overlay image controls that sit on top of the buttons and forward clicks back to the real button handlers.
- Reuse note: on Cocoa, do not treat “glyph assigned” as proof of visible UI. Verify the live widget actually paints it; if not, keep the button for interaction and render the icon on a separate surface.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (a masked magenta glyph bitmap is not safe to reuse as a general-purpose overlay icon)
- Problem: after the overlay icon pass, several palette icons still showed red/purple fringes even though the source SVGs and rendered PNGs were neutral dark icons.
- Core error: the same masked bitmap prepared for `TSpeedButton.Glyph` was reused as if it were a clean image asset.
- Investigation: the purple tint matched the transparency-key color rather than any color in the Lucide assets, which narrowed the bug to the masked bitmap path instead of the source SVG or rendered PNG files.
- Root cause: the magenta transparency key is a control-specific bitmap trick. It is acceptable as a masked glyph source, but if that bitmap is reused in a plain overlay image path the key color can leak into the visible result.
- Fix: the overlay path now loads the rendered PNG assets directly into `TPicture` first and only falls back to the masked bitmap path when a rendered asset is unavailable.
- Reuse note: keep “masked bitmap for legacy button glyphs” and “plain image for overlay rendering” as separate paths. A transparency-key bitmap is not a generic reusable icon surface.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (right-aligned toolbar clusters should anchor to the actual toolbar host width, not a broader form width guess)
- Problem: the top-right utility button cluster and zoom controls existed in code but could still launch partially or fully off-screen.
- Core error: the right-cluster geometry was being calculated from a wider outer window measurement instead of the actual top-toolbar host width.
- Investigation: the controls were present in code and created successfully, but they were absent in the live screenshot until the bounds calculation was rechecked against the real toolbar parent.
- Root cause: anchoring math used a width that did not match the control host used for placement.
- Fix: the right-side toolbar geometry now computes from `FTopPanel.ClientWidth` (with fallbacks only when that host is not yet sized), which restores the expected visible top-right cluster on first build.
- Reuse note: for right-aligned clusters, derive placement from the actual parent surface that owns the controls. Using a broader container width is an easy way to create “control exists but is off-screen” bugs.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (small parity toggles are cheap wins when the state model already exists)
- Problem: the History panel already tracked current, past, and future states, but one small paint.net-style interaction still remained missing: clicking the current row did nothing instead of toggling to the "before" state for a quick before/after comparison.
- Core error: the UI had enough state to support the interaction, but the click handler exited early on the current row and left the behavior unimplemented.
- Investigation: re-read the history-row index model and confirmed the current row is always `UndoDepth`, so “before current” is just one undo when `UndoDepth > 0`.
- Root cause: the handler treated “clicked current row” as a no-op case instead of a parity shortcut case.
- Fix: clicking the current history row now performs a single undo; the same row can then be clicked again immediately to redo back to the original state.
- Reuse note: when the state model already distinguishes past/current/future, small comparison shortcuts are often one-condition handlers, not new subsystem work. Close them when they can be added without touching the data model.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (stable icon pipelines separate “source SVG truth” from “runtime icon format”)
- Problem: the UI needed crisp Lucide-style icons without introducing a fragile runtime SVG stack or repeated on-build regeneration.
- Core error: source-format correctness and runtime-format stability were treated as one decision, which caused churn between raw SVG ambitions, rough fallback glyphs, and bad font-outline assets.
- Investigation: validated the local `./icons` drop as the correct Lucide stroke source, then tested the available local raster paths. Runtime SVG parsing still was not in place, but `qlmanage` plus post-normalization produced clean anti-aliased transparent glyphs when used as an explicit one-time render step.
- Root cause: the project was missing a stable split between “authoritative editable source assets” and “boring runtime assets optimized for the current Lazarus shell.”
- Fix: standardized on `./icons` as the canonical source set, mirrored the mapped subset into `assets/icons/lucide`, added a dedicated manual refresh script for the checked-in rendered PNG assets, and kept runtime on PNG loading with fallback glyphs instead of adding live SVG parsing.
- Reuse note: for desktop UI chrome, the stable pattern is often source SVGs in-repo plus pre-rendered PNG runtime assets. Keep the vector source authoritative, but keep runtime on the simplest already-proven format until the GUI stack truly needs live SVG.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (a font-outline sprite is not a faithful substitute for a stroke-icon set)
- Problem: the UI could technically show icon assets for tool and utility buttons, but the result still looked chunky and not genuinely "SVG-like" in UAT.
- Core error: the rendered tool/palette assets were treated as if they were canonical Lucide icons, even though they were extracted from `lucide-font/lucide.symbol.svg`, which is a font-outline export.
- Investigation: compared the checked-in `assets/icons/lucide/*.svg` files against the `lucide-font` sprite and re-read the runtime icon path in `FPIconHelpers`. The trusted local Lucide files are stroke icons (`fill=\"none\"`, `stroke=\"currentColor\"`), while the font sprite symbols are filled glyph outlines.
- Root cause: "vector file exists" was conflated with "visual source fidelity is correct." A symbol/font sprite can still be valid SVG, but its outlines do not match the original icon family's stroke language.
- Fix: stopped treating the font-derived rendered assets as the default for tool and utility chrome. The live app now limits rendered assets to command surfaces and keeps tool/utility buttons on the built-in line-glyph renderer until proper stroke SVG exports exist.
- Reuse note: do not promote a font-conversion sprite into the main UI icon source just because it is convenient to extract. Verify that the source preserves the intended visual language, not just that it can be parsed.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (UI layout literals drift unless the live form and the tests share one metric layer)
- Problem: the top toolbar could keep regressing in small but visible ways because positions, widths, and gaps were embedded as disconnected literals in `mainform`.
- Core error: layout correctness depended on manual visual memory. Even when the UI still compiled, spacing could drift by a few pixels and there was no direct test that the live geometry still matched expectations.
- Investigation: reviewed `BuildToolbar` and found separate hard-coded numbers for group positions, divider positions, row heights, and zoom-control bounds. Some gaps were already inconsistent (`Edit -> Undo` was narrower than the other top-row gaps).
- Root cause: the code and the tests did not share one geometry source-of-truth, so layout invariants were implicit rather than encoded.
- Fix: extracted toolbar geometry into `FPToolbarHelpers`, switched `mainform` to consume that helper, and added direct regression tests for row alignment, group spacing, right anchoring, and zoom-cluster fit.
- Reuse note: for visible UI chrome, do not leave geometry as “just literals in the form builder.” Put repeatable metrics in one helper and test that helper, then build the form from it.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (one-time asset generation should not be a hard dependency of every local build)
- Problem: a routine local build failed because the icon-refresh step tried to import `PIL`, but the local Python environment did not have Pillow installed.
- Core error: the normal `build` path was made to depend on the temporary icon-generation toolchain instead of only on already-checked-in assets.
- Investigation: traced the failure to `scripts/common.sh -> prepare_icon_assets()` and confirmed the build was invoking the Python extraction/normalization pipeline every time even though the rendered assets were already committed.
- Root cause: asset preparation and ordinary compilation were coupled. The one-time resource-generation script had been promoted into a mandatory step of the normal build flow.
- Fix: changed the build flow to treat Lucide extraction/normalization as a manual asset-prep path only, while routine builds simply reuse the checked-in rendered icon assets.
- Reuse note: if a resource is already versioned in the repository, default builds should consume it directly. Regeneration should be explicit, not implicit, unless the project intentionally depends on that generator in every developer environment.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (Lucide sprite files can look blank even when they are valid icon sources)
- Problem: the provided `lucide.symbol.svg` looked like an empty white file when opened directly, which made it look unusable at first glance.
- Core error: the file was treated like a normal standalone SVG illustration instead of what it actually is: a hidden SVG symbol sprite.
- Investigation: inspected the root tag and the symbol entries directly. The root had `width="0"`, `height="0"`, and `display:none`, while the required `icon-*` symbols were still present with real path data inside.
- Root cause: a hidden symbol-sprite container is meant to be referenced or extracted, not viewed as a standalone picture. Opening it directly in a viewer produces a misleading “blank” result.
- Fix: switched the icon pipeline to extract required `symbol` entries into standalone `assets/icons/extracted/*.svg` files first, then generated runtime assets from those extracted SVGs instead of treating the sprite file itself as a direct visual artifact.
- Reuse note: when a design pack ships `*.symbol.svg`, check whether it is a sprite sheet before judging it by direct preview. A blank preview does not mean the icon data is missing.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (Quick Look thumbnail generation is not a reliable icon pipeline unless its output is normalized)
- Problem: the first Quick Look based icon pass either produced tiny unusable shapes or white square tiles instead of stable toolbar glyphs.
- Core error: `qlmanage` was treated as if it emitted ready-to-use transparent icons, but it actually emits document thumbnails with an opaque white page-style background and output behavior that is sensitive to how it is invoked.
- Investigation: compared direct `qlmanage` runs against the produced PNGs, checked pixel bounds, and confirmed the raw thumbnail output was not a clean transparent icon asset. It also failed when stdout/stderr were fully redirected, which made the initial scripted calls look broken.
- Root cause: Quick Look is a thumbnailer, not a purpose-built SVG icon rasterizer. Its raw output needs post-processing before it can be used as a button glyph.
- Fix: kept Quick Look only as the rasterization step from the extracted standalone SVGs, then normalized the PNGs into a fixed transparent 18x18 black-on-alpha asset set before the app loads them.
- Reuse note: if `qlmanage` is used as a fallback rasterizer, always validate the real pixel output and normalize it. Do not assume the raw thumbnail is directly suitable as a UI icon.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (having source SVGs in the repo is not the same as the app actually using them)
- Problem: the project had a clean `assets/icons/lucide/` source set, but the running app could still show none of those icons because the runtime path never touched those files.
- Core error: the repository asset layer and the Lazarus button-rendering path were treated as if they were already connected, when in reality the app was still using only generated fallback glyphs.
- Investigation: re-read `TryBuildButtonGlyph(...)`, checked the runtime code paths, and confirmed there was no file-loading branch at all even though the SVG files were already checked in.
- Root cause: the asset work stopped at source creation. There was no rendered runtime format, no runtime asset lookup, and no bundle-copy step, so the app had nothing concrete to load.
- Fix: rendered the SVGs into checked-in PNGs, added a runtime asset resolver in `FPIconHelpers` that loads those PNGs before falling back to generated glyphs, and updated the bundle staging path to copy the rendered icon directory into `Contents/Resources`.
- Reuse note: do not count design/source assets as “implemented” until the runtime path, the packaged path, and the fallback path are all wired. Source files alone do not change the visible product.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (tool buttons silently fell back to placeholder text because the shared icon helper excluded the tool context)
- Problem: even after the shared icon pass improved the toolbar, the `Tools` palette could still look cheap and inconsistent because it was showing the old compact Unicode placeholders instead of the intended line icons.
- Core error: the shared `CreateButton(...)` helper only enabled generated glyphs for command and utility buttons; `bicTool` still bypassed that path and then `BuildSidePanel` explicitly put the raw `PaintToolGlyph(...)` character back into the caption.
- Investigation: re-read the tool-button creation path and compared it against the command/utility button path. The icon set already existed in `FPIconHelpers`; the live tool surface simply was not allowed to use it.
- Root cause: the project had treated tool buttons as a special text-only surface long after the shared icon system was expanded enough to cover them, so the fallback placeholder route had become the de facto live UI.
- Fix: re-enabled shared glyph generation for `bicTool`, removed the explicit Unicode caption overlay from the tool buttons, and resized the two-column tool grid around icon-first buttons instead of text surrogates.
- Reuse note: once a shared icon pipeline exists, keep every visible button family on it unless there is a deliberate exception. Leaving one surface on a fallback placeholder path will make the UI look partially broken even though the icon system itself is present.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (opaque glyph backgrounds make otherwise-correct icons read like broken tiles)
- Problem: even when the command buttons were wired and the icon shapes existed, the toolbar could still look broken because each glyph looked like it sat on a tiny square tile.
- Core error: the shared glyph renderer filled the whole bitmap with a solid background color and then handed that opaque bitmap to `TSpeedButton`.
- Investigation: re-read the shared `PrepareGlyphBitmap(...)` path and compared the visual effect of the bitmap-backed buttons against the symbol-only fallback path. The icon outlines were not the only issue; the bitmap itself was carrying an unwanted rectangle.
- Root cause: the glyph path was treating the icon bitmap as a mini background plate, not as a transparent icon surface.
- Fix: the shared glyph bitmap now renders on a transparent key color and marks that color as transparent before the glyph is attached to the button, so the host control background shows through instead of a visible square.
- Reuse note: for toolbar glyphs, an icon bitmap should normally provide shape only, not its own background tile. If the host surface already owns the button background, opaque icon bitmaps will make the UI look broken even when the outline drawing is correct.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (asset-source SVGs and runtime icon rendering do not have to be the same layer)
- Problem: the project needed better icon fidelity and a real reusable icon source, but adding a brand-new runtime SVG stack in the same pass would have raised regression risk in the GUI shell.
- Core error: it is easy to conflate "we need SVG assets in the repository" with "the app must start parsing SVG files at runtime immediately."
- Investigation: checked the current Lazarus shell for existing SVG runtime support, then weighed that against the user's explicit requirement to avoid fresh backend and GUI regressions during the same UI pass.
- Root cause: the repo had no stable existing runtime SVG button path, but it also lacked a proper checked-in icon source set.
- Fix: added a local `assets/icons/lucide/` SVG source set for the visible top-toolbar icons, while keeping the live UI on the already-tested Lazarus glyph pipeline for this pass.
- Reuse note: separate asset-source modernization from runtime-rendering stack changes when stability matters. It is often safer to introduce source assets first and switch the renderer only after the UI contract is already stable.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (visible tool surfaces must share one filter, or the UI contradicts itself)
- Problem: `Zoom` had already been removed from the floating `Tools` palette, but it was still present in the top `Tool:` combo, so the app simultaneously treated it as hidden and visible.
- Core error: the left palette and the top combo were both built from the same display-order metadata, but only the palette path had the "skip `tkZoom`" rule.
- Investigation: re-read `BuildSidePanel`, then compared it against `BuildToolbar`, `MakeTestSafe`, and every `FToolCombo.ItemIndex := PaintToolDisplayIndex(...)` sync path.
- Root cause: the UI had no single "visible tools" synchronization rule; one surface filtered the tool list while the other still assumed raw display-order indexes.
- Fix: the top `Tool:` combo now skips `tkZoom` during construction too, and tool-combo state is now synchronized by scanning the combo's actual object payloads instead of assuming raw display-order indexes.
- Reuse note: if one visible surface filters a shared enum, every other visible selector must either use the same filter or switch to object-based synchronization. Shared raw indexes only stay valid while all surfaces expose the exact same subset.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (stability beats bitmap ambition on Cocoa command strips)
- Problem: the top quick-action strip could degrade into white blocks or dead-feeling controls even though the handlers themselves were still wired.
- Core error: the most visible command strip was still leaning on the fragile bitmap-glyph button path in the part of the UI where rendering glitches are most obvious.
- Investigation: traced the top quick-action buttons through `BuildToolbar` and `CreateButton`, then compared the more stable symbol-first tool/utility buttons against the command-button rendering branch.
- Root cause: the command strip was still paying the reliability cost of bitmap glyphs while the rest of the UI had already proven that text-symbol rendering was the safer fallback on this Cocoa/Lazarus shell.
- Fix: the top grouped command buttons now prefer stable symbol/text captions instead of bitmap glyphs, while the deeper command surfaces can still keep bitmap support where it is less fragile.
- Reuse note: for high-frequency chrome like a main toolbar, use the most boring reliable rendering path first. Fragile icon pipelines belong behind explicit validation, not on the most visible control strip.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (dragging floating UI must target the real panel root, not whichever child got the mouse event)
- Problem: only some floating palettes could be moved reliably, even though all of them had the same visible title-bar drag affordance.
- Core error: drag start was using the immediate parent panel of the clicked header control as the thing to move. For labels inside palette headers, that meant the code was dragging the aligned header strip instead of the outer palette window.
- Investigation: re-read the shared palette drag handlers and traced the actual sender chain for header labels versus the outer palette panels. The drag path was using the sender's parent if it was a panel, which is correct for some shallow controls and wrong for nested header controls.
- Root cause: the drag logic assumed one fixed control depth. Once the header gained nested labels, "parent panel" stopped meaning "palette root".
- Fix: drag start now resolves the true owning palette by walking up the parent chain, and drag motion converts child-control coordinates into the palette's local coordinates before applying movement.
- Reuse note: for draggable composite UI, always resolve an interaction to the true movable root and normalize coordinates into that root's space. Using the event sender or its immediate parent will break as soon as the chrome gets another wrapper control.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (generated glyphs must respect the host surface, or UI polish regresses into white boxes)
- Problem: the UI had broader icon coverage, but multiple visible button surfaces still looked broken because the buttons read as white slabs or square blocks instead of integrated toolbar/palette controls.
- Core error: icon work had focused on coverage and shape, but not on how those glyph bitmaps blended with their host controls. At the same time, some command/utility buttons were still being forced into raised native button chrome that visually fought the grouped toolbar/palette surfaces.
- Investigation: re-read the shared `TryBuildButtonGlyph(...)` path and the main `CreateButton(...)` helper, then traced the remaining direct tab close/add glyph calls. The problem was not missing icons; it was the rendering assumptions around glyph background and button chrome.
- Root cause: the glyph path still depended on transparent-mask assumptions instead of the actual host panel color, and the button helper still mixed otherwise-flat grouped surfaces with explicitly raised native buttons. That combination makes a partially polished UI look worse than an honestly plain one.
- Fix: changed the glyph builder to render against an explicit host background color, routed the main visible button paths through host-aware glyph generation, and removed the forced raised-button styling from the visible toolbar/utility controls so the buttons stay visually integrated with the surfaces around them.
- Reuse note: when adding bitmap-backed UI icons, treat host-surface blending and button chrome as part of the feature. “Icon exists” is not enough; if the glyph/background assumptions are wrong, the result regresses into white blocks even though coverage improved.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (UI polish is safest when it reuses existing controls and centralizes geometry)
- Problem: the app needed a more finished toolbar/tool-palette look, but the highest risk path would have been replacing working controls or splitting event handling across new wrapper controls.
- Core error: UI polish passes can easily create regressions when they mix visual goals with control-structure rewrites, especially in a form that already has many shortcut and sync paths.
- Investigation: compared the React design reference against the current Lazarus `BuildToolbar` / `BuildSidePanel` code and separated "needs new visual structure" from "already working command wiring".
- Root cause: the prototype feel mostly came from inconsistent layout rhythm and raw default control styling, not from missing handlers. The risky part was not functionality; it was the temptation to rebuild working widgets just to change their appearance.
- Fix: the pass kept the same live controls and handlers, introduced shared row-position constants for toolbar geometry, added a separate title band, and adjusted tool-button visual state through the existing `SyncToolButtonSelection` path instead of inventing new wrapper logic.
- Reuse note: when polishing a mature UI surface, change layout constants, grouping, and state styling first. Replacing working controls should be the later option, not the default.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (a white base layer that is not truly special will make multiple tools feel randomly wrong)
- Problem: `Eraser`, `Cut`, `Erase Selection`, and move-selected-pixels could all appear inconsistent in UAT because the visible white base behaved like a normal transparent layer under destructive edits.
- Core error: the app created a layer named `Background` and filled it white, but the document model still treated it as an ordinary alpha-capable `TRasterLayer`, so destructive operations kept erasing to transparency.
- Investigation: traced destructive edit paths across `ApplyImmediateTool`, `CutSelectionToSurface`, `EraseSelection`, and `MoveSelectedPixelsBy`, then compared that against the document constructor and confirmed the only "background" behavior was a one-time white fill in `NewBlank`.
- Root cause: the project had implemented "background" as an initial pixel state, not as a persistent layer semantic. Once that happened, every tool path had to guess from pixels or names and none of them had a reliable contract for special-case behavior.
- Fix: added a real `IsBackground` flag to `TRasterLayer`, persisted it through snapshots and native save/load, locked the background layer to the bottom of the stack, and updated destructive tool/edit routes so they restore an opaque replacement color on the background layer instead of punching transparency.
- Reuse note: if the UX depends on a special base layer, represent that in the document model directly. A filled-white ordinary layer is not enough; destructive tools will drift into contradictory behavior unless the layer type is explicit.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (transparent-color sampling can make every later paint tool look broken)
- Problem: multiple tools (`Pencil`, `Brush`, shapes, text) could all look like they had stopped committing even though the same previews still rendered correctly.
- Core error: sampling a transparent pixel copied `A=0` into the active swatch, while the visible swatch UI still rendered only the RGB channels and looked like an opaque black/colored paint.
- Investigation: compared preview rendering against committed raster writes and re-read the color-pick and Colors-panel paint paths; previews used RGB-only chrome, but committed pixels still respected alpha.
- Root cause: the app treated sampled RGBA as the new paint swatch even when the user intent was only "pick the visible color", and the swatch preview hid that zero-alpha state.
- Fix: the color picker now preserves the current active alpha when adopting sampled RGB, the system color button now resets the chosen swatch to opaque alpha, and the Colors panel now renders both swatches through a checkerboard alpha preview.
- Reuse note: if a sampled color is reused for future painting, never silently import transparent alpha unless the UI explicitly exposes alpha sampling as a user choice; otherwise one transparent sample can masquerade as a cross-tool rendering failure.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (eraser and drag-commit logic need their own semantics, not paint-tool assumptions)
- Problem: the eraser could do nothing at all, and drag-shape tools could get stuck in a preview state when release delivery was unreliable.
- Core error: the eraser was reusing normal alpha blending with a fully transparent source color (a no-op), and drag finalization depended too heavily on receiving an explicit `MouseUp` event.
- Investigation: re-read `BlendNormal`, confirmed `Src.A = 0` returns the destination unchanged, then traced the shape/line drag lifecycle and identified the single-event dependency on `PaintBoxMouseUp`.
- Root cause: two different interaction classes had been forced through paint-tool defaults: "erase" is not the same as "paint transparent", and "drag finished" is not the same as "we definitely received MouseUp on the same control".
- Fix: added dedicated raster erase-brush/erase-line paths that reduce destination alpha directly, enabled mouse capture during drags, and added button-state fallback finalization in the move path when the pressed-button flag disappears before a formal mouse-up arrives.
- Reuse note: if a tool removes pixels or ends a gesture, do not assume the regular paint blend path or the happy-path event sequence is enough; destructive tools and drag tools need explicit semantics.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (UI labels can accidentally break drag affordances)
- Problem: adding more visible metadata to panel chrome can quietly break interaction if the new label controls sit on top of the original drag surface and stop forwarding pointer events.
- Core error: palette headers rely on shared mouse handlers for drag movement, but newly added title-bar labels are separate controls and can intercept the mouse by default.
- Investigation: while extending palette headers with visible glyphs and shortcut badges, re-checked `CreatePaletteHeader(...)` and compared it against the existing drag wiring on the header panel itself.
- Root cause: decorative controls inside a draggable region are still interactive controls; unless they explicitly forward events, they can create "dead" zones in what used to be a continuous drag surface.
- Fix: the new glyph, title, and shortcut labels in palette headers now forward `OnMouseDown` / `OnMouseMove` / `OnMouseUp` to the same palette drag handlers as the header panel.
- Reuse note: any time visible chrome is added inside a draggable title region, treat hit-testing as part of the feature, not as a post-polish detail.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (tool state is part of UI truth, not optional chrome)
- Problem: even when tool switching worked internally, the visible tool palette could still look inert because the buttons did not clearly show which tool was active and the shortcut surface stayed hidden in docs/tooltips.
- Core error: tool state had been treated as a logic concern (`FCurrentTool`, combo selection, keyboard routing) instead of a visible product concern, so the palette grid itself lagged behind the actual interaction state.
- Investigation: re-read the tool-switch paths (`ToolButtonClick`, combo changes, single-key shortcuts, temporary pan) and confirmed they all updated `FCurrentTool`, but the visible tool buttons were not kept as a synchronized UI state surface.
- Root cause: the palette buttons were created as anonymous controls without a shared selection-sync path or shared shortcut metadata, so the UI had no explicit contract for reflecting the active tool.
- Fix: added shared tool-shortcut helpers, stored tool-button references, synchronized button `Down` state through a dedicated `SyncToolButtonSelection`, surfaced shortcut badges on the buttons and combo labels, and extended the same idea to utility palette toggles.
- Reuse note: if a control is the user's primary affordance for mode changes, its selected state and shortcut affordance are part of feature completeness; keeping that metadata only in internal state or docs is not enough.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (selection overlays are part of the cached canvas, so selection changes need cache invalidation too)
- Problem: several selection-family interactions could succeed logically and still look broken because the marquee or moved pixels would not visibly update until some later unrelated repaint happened.
- Core error: the prepared canvas bitmap already includes the composited image plus the selection outline, but some selection mutations were still treating `RefreshCanvas` as sufficient without first invalidating that cached bitmap.
- Investigation: re-audited `BuildDisplaySurface(...)` and confirmed the selection outline is rendered into the same cached display surface as the image, then traced selection commands and tool gestures that still only did `SetDirty(True); RefreshCanvas;`.
- Root cause: selection state had been mentally treated as "overlay-only UI state", while the actual render path bakes it into the cached display bitmap, making cache invalidation mandatory for visible correctness.
- Fix: added a shared `SyncSelectionOverlayUI(...)` path and routed selection-only commands, wand picks, selection commits, move-selection drags, and move-selected-pixels drags through it.
- Reuse note: when a UI overlay is baked into a cached composite, any mutation of that overlay must follow the same invalidation discipline as pixel edits; otherwise "state changed" and "what the user sees" will diverge.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (interactive helpers can bypass the standard mutation-sync path)
- Problem: some live interaction helpers were still mutating pixels or document order correctly but not refreshing all the same visible surfaces that the primary command handlers already kept in sync.
- Core error: helper methods like staged line-segment commit and layer-list drag reorder were outside the usual menu-command flow, so they were easier to leave on older partial refresh code paths.
- Investigation: after the main command handlers were already on `SyncImageMutationUI(...)`, re-scanned the remaining gesture helpers and found `CommitPendingLineSegment(...)` and layer drag reorder still using older manual refresh tails.
- Root cause: central command handlers had been normalized first, while secondary interactive helpers kept legacy refresh snippets that no longer matched the main UI contract.
- Fix: staged line-segment commit now invalidates the prepared bitmap and refreshes tab previews before the next paint, and layer drag reorder now uses `SyncImageMutationUI(True, True)` instead of a partial manual refresh.
- Reuse note: after introducing a shared post-mutation UI helper, explicitly audit non-menu helper paths too; the hard bugs tend to survive in gesture-specific helpers, not in the obvious command handlers.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (recolor tolerance silently corrupts magic wand tolerance when switching tools)
- Problem: changing the tolerance spin while `Recolor` was active would silently overwrite the `Magic Wand` tolerance, and vice versa, because both tools wrote into the same `FWandTolerance` field.
- Core error: the tolerance spin's change handler and the `UpdateToolOptionControl` display path both used `FWandTolerance` regardless of whether the active tool was Recolor or Magic Wand.
- Investigation: traced `FillTolSpinChanged` and `UpdateToolOptionControl`; found `FFillTolSpin.Value := FWandTolerance` for Recolor read-back and `FWandTolerance := ...` for Recolor write-back, confirming the shared-field bug.
- Root cause: when the tolerance spin was generalized across tools, the Recolor path was grafted onto the existing Magic Wand field instead of introducing a dedicated backing field.
- Fix: added `FRecolorTolerance` as a separate field, initialized to 32 (same default as wand), and rerouted `UpdateToolOptionControl`, `FillTolSpinChanged`, and `ApplyImmediateTool` to use `FRecolorTolerance` when the active tool is `tkRecolor`.
- Reuse note: when multiple tools share one visible spin control, each tool must still own its own backing field; using one field for "whichever tool is active" silently corrupts the dormant tool's value when the user switches.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (anti-alias toggle does not disable the dependent feather spin)
- Problem: unchecking the `Anti-alias` checkbox for selection tools left the `Feather` spin visually enabled, making it look like feathering was still available when it was not.
- Core error: `SelAntiAliasChanged` wrote the boolean state but did not propagate the enabled/disabled state to the dependent control.
- Investigation: compared `UpdateToolOptionControl` (which correctly sets `FSelFeatherSpin.Enabled := FSelAntiAlias`) with `SelAntiAliasChanged` and saw the sync was missing.
- Root cause: the initial setup path propagated the dependent state, but the runtime change handler was added later without copying the sync logic.
- Fix: added `FSelFeatherSpin.Enabled := FSelAntiAlias` to `SelAntiAliasChanged`.
- Reuse note: when a control has a dependent enable/disable relationship established in the initial layout, make sure the runtime change handler mirrors the same dependency; the two paths evolve separately and drift apart.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (mouse-move stroke path calls SetDirty causing per-pixel tab-strip churn)
- Problem: dragging with `Recolor` or `Clone Stamp` was noticeably heavier than dragging with `Pencil`/`Brush`/`Eraser` because every pixel movement triggered a full `SetDirty(True)` call.
- Core error: `SetDirty(True)` calls `InvalidatePreparedBitmap` + `UpdateCaption` + `RefreshTabStrip`/`RefreshTabCardVisuals` on every state change, which is correct for discrete commands but excessive inside a tight per-pixel mouse-move loop.
- Investigation: compared the `PaintBoxMouseMove` handlers for `tkPencil`/`tkBrush`/`tkEraser` (which use `InvalidatePreparedBitmap`) against `tkRecolor`/`tkCloneStamp` (which used `SetDirty(True)`) and confirmed the asymmetry.
- Root cause: the Recolor and CloneStamp tools were added in later passes and their mouse-move handlers copied a more conservative pattern instead of matching the lightweight cache-invalidation-only contract that the original paint tools had already established.
- Fix: replaced `SetDirty(True)` with `InvalidatePreparedBitmap` in the mouse-move handlers for `tkRecolor` and `tkCloneStamp`; the dirty flag is still set correctly on initial mouse-down and committed through `CommitStrokeHistory` on mouse-up.
- Reuse note: per-pixel mutation loops during continuous painting should do the minimum display-cache work during the drag and defer heavier UI-state work (caption, tab strip, dirty flags) to the mouse-up commit; copying the "safe" pattern from discrete command handlers into drag loops creates unnecessary churn.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (line segment commit does not refresh layer thumbnails)
- Problem: committing a Bézier segment in a multi-segment line path left the Layers palette thumbnails showing the pre-segment state until an unrelated event forced a layer-list refresh.
- Core error: `CommitPendingLineSegment` called `SetDirty(True)` (which refreshes the tab strip) but did not call `RefreshAuxiliaryImageViews`, so layer thumbnails lagged behind.
- Investigation: compared `CommitPendingLineSegment` with `CommitStrokeHistory` (which does call `RefreshAuxiliaryImageViews`) and found the missing call.
- Root cause: the line segment commit path was written as a lighter-weight alternative to the full `SyncImageMutationUI` path, but the layer-list refresh was omitted as part of that simplification.
- Fix: added `RefreshAuxiliaryImageViews(False)` at the end of `CommitPendingLineSegment`.
- Reuse note: any code path that commits visible pixel changes needs to refresh all surfaces that display document state: canvas, tab strip, and layer thumbnails; forgetting one secondary view surface is an easy oversight when the commit path is hand-built instead of going through a shared mutation-sync helper.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (live stroke tools still look broken if the first dab misses cache invalidation)
- Problem: users could still report that `Pencil` "did not draw" even when the layer pixels had already changed, especially on a single click or the first dab of a stroke.
- Core error: the mouse-down path for immediate paint tools wrote into the layer surface and refreshed the canvas, but it did not always invalidate the prepared display bitmap first, so the repaint could still show stale cached pixels.
- Investigation: traced `PaintBoxMouseDown(...)` and compared it with the drag path in `PaintBoxMouseMove(...)`; the move path already called `InvalidatePreparedBitmap`, while the initial mouse-down path for `Pencil` / `Brush` / `Eraser` / `Clone Stamp` / `Recolor` did not.
- Root cause: the live stroke logic was split across "initial dab" and "drag continuation", and only the continuation path had the full display-cache invalidation step.
- Fix: added `InvalidatePreparedBitmap` to the immediate mouse-down mutation path for the affected live paint tools so the first visible dab uses the same cache-dirty contract as later stroke segments.
- Reuse note: when a tool paints on both mouse-down and mouse-move, treat those as two mutation entry points that both need the full visible-refresh contract; it is easy to fix only the drag path and leave single-click behavior visually stale.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (shared iconography stalls if panel chrome keeps its own text-only buttons)
- Problem: even after the main toolbars moved onto generated glyphs, parts of the live UI still looked inconsistent because floating palette chrome and some palette actions were still text buttons.
- Core error: "icon support" was being counted on the major strips, but visible panel sub-actions like `Swap` / `Mono` and palette close controls still bypassed the shared glyph path.
- Investigation: re-audited the remaining visible `CreateButton(...)` and non-`CreateButton(...)` controls and found that the Colors panel actions and palette header close buttons were still rendered as ad-hoc text/caption controls.
- Root cause: iconography work had improved the shared button factory, but not all visible panel actions had been migrated onto it.
- Fix: added dedicated `Swap` / `Mono` glyphs in `FPIconHelpers`, moved those Colors actions onto the command-glyph path, and converted palette close controls onto the same shared `TSpeedButton` glyph route.
- Reuse note: once a shared icon pipeline exists, finish each visible UI band end-to-end; mixed "some glyph, some caption" chrome makes the app look less complete than the underlying icon work really is.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (document replacement still looks broken if old transient canvas state leaks through)
- Problem: even when a new/open/replace-style command correctly swapped in a new document, the app could still feel visually unreliable because old drag state, hover state, or stale prepared-bitmap assumptions could survive longer than they should.
- Core error: full-document replacement was being treated as "just swap the document pointer" in too many places, so the visible follow-up work was inconsistent and could make the fresh document look like it had not fully taken over the workspace.
- Investigation: traced the user-facing replacement flows (`New`, `Open`, `Paste into New Image`, clipboard acquire replacement) and found several slightly different tails for viewport fitting, cache invalidation, layer refresh, and transient tool cleanup.
- Root cause: document replacement had no single post-swap contract, so every route rebuilt only part of the required visible state.
- Fix: added `ResetTransientCanvasState` and `SyncDocumentReplacementUI(...)`, then routed the replacement-family handlers through that shared path so transient tool state, viewport, cache invalidation, layer previews, and canvas repaint all converge on one predictable follow-up sequence.
- Reuse note: in editors with a cached canvas and staged tool interactions, replacing the active document is a whole-workspace state transition, not just a pointer assignment; always centralize the reset + refresh contract.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (headless widget construction is a poor first choice for LCL UI verification)
- Problem: the natural first attempt at stronger UI testing was to instantiate `TMainForm` and drive simulated events directly, but the current headless test harness still crashed before that path became reliable.
- Core error: treating "real form construction in CI" as the only meaningful way to test UI-facing behavior would have produced unstable tests and delayed coverage for the actual user complaint: visible image feedback.
- Investigation: added temporary test-oriented hooks in `TMainForm`, then tried form construction in the existing test runner and hit `EAccessViolation` during headless execution.
- Root cause: the current LCL/widgetset test environment is good enough for helper-level and document-level assertions, but it is not yet a dependable full-form construction environment for this app.
- Fix: kept the useful test hooks, but moved the new coverage to a stable `TMainFormIntegrationTests` layer that asserts shortcut gating and visible composite-pixel changes through document/composite contracts instead of forcing a brittle full-form path.
- Reuse note: when desktop UI harnesses are unstable, do not abandon UI-facing coverage; move one layer down and test the visible-output contract (composite pixels, cache revision, command gating) until the widget harness is strong enough.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (iconography does not really move until the button factory emits actual glyphs)
- Problem: the app had become more readable through shorter labels and symbol captions, but `Iconography` still stayed artificially low because the visible buttons were still fundamentally text-driven.
- Core error: counting compact captions as "icon support" made the UI look improved in code review while still leaving the major button surfaces dependent on caption rendering instead of a real shared glyph path.
- Investigation: re-read the current `Iconography` gap in `docs/FEATURE_MATRIX.md`, then traced `CreateButton(...)` in `mainform.pas` and confirmed the construction path still treated captions as the primary rendering surface even where the UI was supposed to be icon-first.
- Root cause: the icon language had not been centralized into a shared bitmap/image pipeline; each button still started from text and only approximated icons through compact glyph-like captions.
- Fix: added `FPIconHelpers`, made `CreateButton(...)` prefer generated bitmap glyphs, and routed the high-visibility button families through explicit icon contexts so the visible tool/action surfaces now share one real glyph path.
- Reuse note: when a desktop UI needs to count as icon-driven, do not stop at shorter labels or Unicode symbols; first move the shared button factory onto a real bitmap/image path, then refine asset polish later.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (flattened foreign import stops being enough once the editor already has layers)
- Problem: `.xcf` support looked practical because files could open, but the app still threw away layer structure in the main document flow even though the native document model already supported layers.
- Core error: a flattened compatibility fallback was still being treated as the main success path for a layered foreign project format, which made the feature look more complete than it really was.
- Investigation: re-audited the shared file-open path and confirmed that `.xcf` still ended at `LoadSurfaceFromFile(...)` in the main document flow, so the loader always collapsed the file into one raster before the tab/document shell ever saw it.
- Root cause: compatibility IO had only a surface-return path; there was no document-return branch for foreign formats that could map onto the existing `TImageDocument` layer model.
- Fix: added `TryLoadDocumentFromFile(...)`, implemented layered `.xcf` loading through `TryLoadXCFDocument(...)`, and routed the document open flow through that path while keeping flattened imports for surface-only cases such as import-as-layer.
- Reuse note: once the app already has a stable layer model, foreign project support should try a document-return path first; flattened import should be the fallback, not the only success case.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (image-processing feedback still feels incomplete if the busy state is invisible)
- Problem: even after routing mutations back into the canvas and preview surfaces, longer image-processing commands could still feel ambiguous in manual use because the UI had no explicit "rendering in progress" signal while the command was running.
- Core error: the app could mutate pixels correctly and refresh the result afterward, but adjustments/effects still looked like synchronous black boxes from the user's point of view because the status bar kept showing static labels during processing.
- Investigation: re-read the remaining explicit `Status bar: Progress bar` gap in `docs/FEATURE_MATRIX.md`, then inspected the live status-strip layout and found that the existing layer/units segment was the safest place to surface progress without creating another detached indicator.
- Root cause: post-mutation correctness had been treated as the only feedback contract, while "the command is currently rendering" was still missing from the live shell.
- Fix: added a real progress label + progress bar inside the status strip, reserved it inside the existing status-bar layout helpers, and routed the adjustments/effects handlers through `BeginStatusProgress(...)` / `EndStatusProgress` so the busy state is visible before the mutation lands.
- Reuse note: for editor commands that can visibly change the image, the UI contract should cover both phases: show that the command is running, then show that the new pixels have landed; a correct final repaint alone still leaves the feature harder to trust during manual UAT.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (live previews should not force full control-tree rebuilds)
- Problem: a visible preview surface can become functionally correct but still unnecessarily heavy if every small content refresh rebuilds the entire widget tree instead of updating the changed card in place.
- Core error: the tab strip already had live thumbnails, but the old "always rebuild" refresh model meant even same-state dirty updates could recreate the full strip when only the active document preview actually changed.
- Investigation: re-read the tab-strip implementation after tightening document-mutation UI sync and noticed the code path was now using `RefreshTabStrip` frequently enough that the remaining coarse refresh granularity itself became the next bottleneck.
- Root cause: structural refresh (adding/removing/reordering tabs) and content refresh (updating one tab's thumbnail/title) were still treated as the same operation.
- Fix: kept `RefreshTabStrip` for structural changes, added `RefreshTabCardVisuals(...)` for in-place card refresh, and routed same-state dirty updates plus stroke-finalization preview refresh through the lighter path.
- Reuse note: when a UI surface becomes part of the live feedback loop, split "rebuild the control structure" from "refresh the current content" as early as possible; otherwise correctness fixes can quietly turn into avoidable UI churn.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (save-option records are still fake if the writer path ignores them)
- Problem: export can look "configurable" in code and docs while still behaving like a fixed pipeline if the UI collects format options but the actual image writer ignores them.
- Core error: the save path had a partially real options record, but `PngCompressionLevel` was documented as reserved and PNG alpha was not explicitly enabled on the writer, which meant a major export expectation could still fail despite the presence of a save-options abstraction.
- Investigation: re-read `SaveToPath(...)` and `SaveSurfaceToFileWithOpts(...)`, then checked the local FPC writer sources to confirm `TFPWriterPNG` really exposes `UseAlpha` and `CompressionLevel`, and `TFPWriterJPEG` exposes `ProgressiveEncoding`.
- Root cause: the abstraction stopped one layer too early; the app had begun modeling save options, but the concrete writer configuration was only wired for JPEG quality and left the other real writer capabilities unused.
- Fix: extended `TSaveSurfaceOptions`, wired the PNG and JPEG writer properties in `SaveSurfaceToFileWithOpts(...)`, and exposed matching session-persisted prompts in the GUI save flow.
- Reuse note: whenever an export option is added, verify the full chain in one pass: persistent UI state, option object, concrete writer property, and a round-trip regression that proves the file on disk actually reflects the setting.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-04 (image mutation is not fully testable until every visible surface refreshes)
- Problem: some image-processing and draw flows could mutate the document correctly while still feeling unreliable in manual testing because only part of the UI visibly updated right away.
- Core error: treating "canvas repaint" as the only required post-mutation feedback left secondary visible surfaces behind; tabs, layer thumbnails, and history-driven image jumps could lag the real document state even when the pixels had already changed.
- Investigation: re-audited the main mutation handlers in `mainform.pas` after the user's repeated feedback about "function works but does not visibly land on the image", then compared the different post-mutation code paths and found too many hand-written combinations of `InvalidatePreparedBitmap`, `SetDirty`, `RefreshLayers`, and `RefreshCanvas`.
- Root cause: post-mutation UI sync was not modeled as one contract. The code had multiple partially overlapping refresh patterns, so new effects and tools could easily refresh the canvas but forget the other visible surfaces that help the user verify the result.
- Fix: added a shared `SyncImageMutationUI(...)` path for mutation handlers, routed the adjustments/effects/history/property paths through it, and updated stroke-finalization to refresh tab and layer previews after brush-like operations complete.
- Reuse note: for editor features, "the operation ran" is not the completion condition; define one shared post-mutation path that covers every user-visible surface that represents current document state, then route new image-changing features through that path by default.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (build verification can still fail after tests pass if GUI-only APIs differ)
- Problem: the layer pass initially passed the shared CI test suite but still failed the Lazarus GUI build because the key-state API used in a GUI-only handler was not available through the current unit imports in the app target.
- Core error: relying on the test suite alone missed a GUI compile break; `GetKeyState` compiled conceptually against LCL internals but was not visible in the current `MainForm` unit, so the app build broke even though the core tests stayed green.
- Investigation: after the layer-properties and jump-to-edge move changes, reran `build.sh`, read the Lazarus compile error, and checked the local LCL sources to confirm the safer public helper already exposed by `Controls`.
- Root cause: the first implementation reached for a lower-level key-state symbol instead of using the higher-level `GetKeyShiftState` helper that matches the unit's existing dependencies.
- Fix: replaced the direct `GetKeyState(...)` calls with `GetKeyShiftState`, keeping the same `Ctrl+Click` behavior while restoring GUI build compatibility.
- Reuse note: when adding GUI-only modifier behavior, always rerun the full GUI build even if core tests pass, and prefer public LCL helpers already available from the unit's imported surface over lower-level API calls.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (recognized format is still a gap if it only raises a nicer error)
- Problem: a compatibility format can look "supported" in filters and docs while still being functionally missing if the only real behavior is a descriptive exception.
- Core error: recognizing `.kra` in the open dialog but always failing on load improved messaging, yet it still left a major user-facing gap because the format had no successful pixel-return path at all.
- Investigation: re-read the compatibility row in `docs/FEATURE_MATRIX.md`, then traced `LoadSurfaceUsingKnownReaders(...)` in `fpio.pas` and confirmed `.kra` short-circuited into an unconditional exception before any attempt to inspect the ZIP container.
- Root cause: the earlier pass optimized for clearer failure messages but stopped short of a practical fallback import path, even though Krita archives often contain a directly usable merged PNG preview.
- Fix: added `FPKRAIO` with ZIP-based extraction of `mergedimage.png` / `preview.png` (or another fallback PNG entry), routed `.kra` through that loader first, and kept the descriptive error only as the fallback when no readable flattened preview exists.
- Reuse note: when a foreign format is marked partial, prefer a real flattened fallback path whenever the source container exposes one; a nicer error is still not "support" if common files can be flattened automatically.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (startup defaults should be shared state, not duplicated literals)
- Problem: the startup active tool needed to change from a paint tool to `Rectangle Select`, but the current code held that default in more than one constructor path and the first test approach tried to instantiate the full form in a headless environment.
- Core error: duplicated startup literals are easy to update incompletely, and GUI construction is a brittle way to verify a simple default-state contract in CI.
- Investigation: traced the duplicate `FCurrentTool := ...` assignments in both `TMainForm.Create(...)` branches, then hit a headless `EAccessViolation` when a new regression test tried to verify the startup tool by constructing `TMainForm` directly.
- Root cause: the startup default was not modeled as shared configuration; it was copied into multiple constructor branches, and the test layer had no stable non-GUI source of truth to assert against.
- Fix: added a shared `DefaultStartupTool` helper in `fpuihelpers.pas`, switched both `TMainForm` constructor paths to use it, and changed the regression test to assert the helper directly instead of building the full form.
- Reuse note: if a default value matters to real UX, expose it as a shared helper or constant that both runtime code and tests can consume; do not force GUI construction just to verify a default.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (image effects are incomplete until the menu route and repaint path exist)
- Problem: adding a new image-processing primitive in the surface core does not help users validate it unless it is reachable from the visible `Effects` menu and the canvas cache is invalidated immediately after application.
- Core error: effect work can look "done" in code review while still feeling missing in real use if the function exists only in the core layer or if the effect mutates pixels without forcing the prepared bitmap to rebuild.
- Investigation: re-audited the existing effect handlers in `mainform.pas` and confirmed the real user-facing contract is a three-part chain: visible menu item, document mutation call, then `InvalidatePreparedBitmap` + `RefreshCanvas`.
- Root cause: image-processing features span core math plus UI routing plus canvas cache invalidation, and skipping any one of those leaves the effect either undiscoverable or visually stale.
- Fix: added the missing `Unfocus`, `Surface Blur`, `Bulge`, `Dents`, and `Relief` paths in both `fpsurface.pas` and `fpdocument.pas`, wired them into the grouped `Effects` menu, and kept the same invalidate-and-refresh flow used by the existing effect handlers.
- Reuse note: treat every new effect as incomplete until it satisfies the full visible loop: reachable command, immediate pixel mutation, and immediate canvas feedback after the command returns.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (multi-step tool states need explicit finish and repaint paths)
- Problem: a multi-step canvas tool can still feel broken even after the core interaction exists if the user has no clear way to continue, finish, or cancel the state, or if idle previews do not repaint while the state is active.
- Core error: after the first two-handle line-curve pass, the tool could edit one richer segment, but the next segment was still a documented gap because the state machine ended too early and the non-hover line preview path was not guaranteed to repaint on plain mouse move.
- Investigation: re-read the `tkLine` branches in `PaintBoxMouseDown(...)`, `PaintBoxMouseMove(...)`, `FormKeyDown(...)`, and `PaintCanvasTo(...)`, then compared that against the remaining gap notes in `docs/TOOL_OPTIONS_BASELINE.md` and the user requirement that the active tool must visibly react on the canvas while it is in use.
- Root cause: the first pass treated the richer line interaction as a single edited segment instead of a reusable state loop, and it still relied on the generic hover-overlay invalidation path even though `Line` uses its own preview drawing instead of the shared hover overlay classification.
- Fix: split full line-state reset from per-segment reset, kept the last endpoint active after each committed segment, added explicit `Enter` / right-click / `Escape` exit paths, and forced line-path preview invalidation on mouse move while the tool is in its open-path states.
- Reuse note: when a tool grows from one gesture into a staged workflow, audit four things together: continue-state reuse, explicit finish/cancel gestures, repaint triggers for idle preview states, and whether each completed stage lands visible output immediately.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (preview path must match committed path)
- Problem: staged curve tools become misleading fast if the on-canvas edit flow suggests a richer curve than the raster backend can actually write to the layer.
- Core error: once the line tool moved from a single-handle bend to a two-handle edit flow, the previous quadratic-only raster path would have made the preview and the committed stroke disagree.
- Investigation: before expanding the line-tool state machine, re-checked the existing `DrawQuadraticBezier(...)` commit path in `mainform.pas` and the matching preview helper, then compared that against the new two-handle interaction the tool now exposes.
- Root cause: the interaction model and the raster model had diverged; the tool could stage two handles, but the surface core still only knew how to rasterize a one-control-point curve.
- Fix: added a matching `DrawCubicBezier(...)` path in `fpsurface.pas`, switched the line tool to a staged first-handle / second-handle state machine, and kept the preview layer visually aligned with the same cubic control points that the final stroke uses.
- Reuse note: any time a canvas tool gets a deeper staged edit mode, promote the raster primitive in the same pass; do not ship a richer preview on top of an older commit path.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (modal-only tool trap)
- Problem: a tool can technically "work" while still feeling broken if its only real interaction happens in a detached dialog instead of on the canvas where the user clicked
- Core error: the text pipeline had real raster output, but the visible tool surface still behaved like a settings command because every placement immediately jumped to a modal dialog
- Investigation: re-audited the explicit remaining gaps in `docs/TOOL_OPTIONS_BASELINE.md`, then traced the `tkText` mouse path in `mainform.pas` and confirmed it never created any on-canvas editing state
- Root cause: the implementation stopped at the rendering backend and skipped the intermediate interaction layer, so the tool had output but no direct canvas editing phase
- Fix: added a real inline text editor anchored to the canvas, wired commit/cancel/focus-loss behavior into document and tool transitions, and kept the older dialog only as a style editor on right-click / `Option`-click
- Reuse note: when a tool's expected interaction is spatial and canvas-driven, do not treat a modal dialog as equivalent just because the backend can already render the final result; the interaction stage is part of the feature, not optional glue
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (selection feather contract)
- Problem: toggling an "anti-alias" option that never changes the actual mask made the UI promise feel fake because paint bucket/fill/gradient still met a hard edge.
- Core error: the selection mask was purely Boolean (`0`/`1`), so even a correctly wired top bar control could not soften pixel output unless the mask itself stored coverage values.
- Investigation: audited each selection commit path in `mainform.pas` (`SelectRectangle`, `SelectEllipse`, `SelectLasso`, `SelectMagicWand`) and checked that none of them ever softened the shared `TSelectionMask` instance before we wired the UI to it.
- Root cause: the core mask only tracked `Selected[X,Y]` as `Boolean`, so there was no place to store the feather radius coverage that the checkbox and spinner suggested.
- Fix: added `TSelectionMask.Feather` plus the new `ApplySelectionFeather` helper so every selection naturally runs the gradient mask pass, and exposed the anti-alias checkbox and feather spinner to the tool bar so UI/behavior stay in sync.
- Reuse note: whenever a UI option claims to change geometric coverage, follow the value down to the mask/bitmap and make sure that data structure actually stores the updated coverage; otherwise the option is just a visual effect.
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (preview/output shape drift)
- Problem: adding a new tool shape option can still leave the app feeling broken if the visible preview changes but the raster path keeps using the old shape, or vice versa
- Core error: shape options are easy to wire into one layer of the stack only, which creates a mismatch between what the canvas promises and what the pixels actually do
- Investigation: while adding square-tip eraser support, audited the tool-option control, the hover overlay path, and the actual eraser drawing branch together instead of treating them as separate tasks
- Root cause: tool-shape behavior spans at least three layers (visible control, canvas preview, raster operation), and any one-layer-only change creates a false sense of completion
- Fix: added the eraser `Shape` combo, a square hover overlay, and a separate square raster brush/line path in the surface core so all three layers move together
- Reuse note: whenever a tool changes geometric shape, verify control state, hover preview, and final pixel output as one contract; do not close the task when only one or two of those layers are wired
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (single-gesture tool assumption)
- Problem: the original line tool looked "implemented" because it painted pixels, but it still missed a major expected behavior: bending a line into a curve without switching tools or opening another mode
- Core error: the interaction model assumed every canvas tool should finish in one drag, which made the line tool stop at the straight-line subset only
- Investigation: re-checked the current `tkLine` mouse-down / move / up flow in `mainform.pas`, then compared it against the explicit remaining-gap notes in the feature matrix and the user's repeated reports that advanced tools still felt incomplete
- Root cause: the tool state model tracked only immediate strokes and drag previews, but it did not preserve a second-stage "pending shape edit" state for tools that need multiple pointer gestures
- Fix: added a dedicated pending-curve state for `tkLine`, rendered a second-stage curve preview on the canvas, and backed it with a real quadratic-curve raster path in `fpsurface.pas`
- Reuse note: for paint-editor tools, do not assume one gesture equals one tool; some tools need explicit staged state machines, and that state must be tracked as a first-class part of the implementation instead of patched in late
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (tool option repaint lag)
- Problem: even after adding canvas-hover feedback, several tool options still felt disconnected because changing the visible control did not immediately change the canvas preview
- Core error: option state was being updated in memory, but the canvas repaint depended on a later mouse move or drag instead of the option change itself
- Investigation: re-audited the tool-option handlers in `mainform.pas` after the canvas-feedback pass and compared them against the preview paths in `PaintCanvasTo(...)`
- Root cause: the option handlers mostly changed fields only, and `UpdateToolOptionControl(...)` did not keep the programmatic sync guard active for the full control refresh, so repainting there would have been noisy without first fixing the guard boundary
- Fix: moved the `FUpdatingToolOption` guard to cover the full control-sync path, added guard checks across the tool-option handlers, and made user-driven option changes explicitly call `RefreshCanvas` so the visible preview updates immediately
- Reuse note: whenever a tool option changes anything the canvas can preview, treat "repaint now" as part of the feature contract, and separate programmatic control-sync from user edits before wiring repaint side effects
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (backend-only tool illusion)
- Problem: several tool passes had real behavior in code, but they still felt broken in manual use because the canvas often gave no visible feedback until after a click, drag, or unrelated repaint
- Core error: tool work was being counted as "implemented" when the raster path existed, even if the user could not reliably see that the active tool was attached to the canvas
- Investigation: re-read the `PaintCanvasTo(...)`, `PaintBoxMouseMove(...)`, and tool-switch paths in `mainform.pas`, then compared the current visible tool set against which ones actually drew hover or drag feedback on the canvas
- Root cause: implementation status had drifted toward backend capability and option wiring, while the minimal UX contract for canvas tools ("the pointer should show what the tool will do") had not been tracked as a first-class requirement
- Fix: added shared hover-feedback classification in `fpuihelpers.pas`, routed that into the main canvas paint path, added live brush/point overlays plus a clone-source marker, refreshed the canvas on tool switches and mouse-leave, and documented the "visible canvas feedback" rule in `docs/TOOL_OPTIONS_BASELINE.md`
- Reuse note: for any tool that acts on the canvas, do not stop at "the pixel operation exists"; verify that hover, click, or drag produces immediate visible feedback on the canvas itself before calling the tool pass usable
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (LCL color control boundary)
- Problem: the requested color-panel direction needed to feel more native, but the first implementation had drifted into a fully custom picker surface that duplicated the platform color dialog instead of working with it
- Core error: the UI exposed both a custom in-panel picker and the system color dialog path, which made the colors workflow feel redundant and less aligned with the intended macOS behavior
- Investigation: checked the local Lazarus sources directly (`lcl/colorbox.pas`, `lcl/include/colorbutton.inc`, and `lcl/interfaces/cocoa/cocoawsdialogs.pas`) to separate pure-LCL color controls from the Cocoa widgetset bridge for `TColorDialog`
- Root cause: `TColorButton` / `ColorBox` are reusable pure-LCL controls, but `TColorDialog` on Cocoa is a widgetset-backed wrapper around `NSColorPanel.sharedColorPanel`, so it is not the same kind of embeddable/customizable control surface
- Fix: moved the live app to a slimmer companion-panel model built around `TColorButton` plus our own stacked swatches and slider strips, instead of keeping a larger standalone custom picker; documented the native-dialog boundary explicitly in the project logs
- Reuse note: when a Lazarus control request mixes "native dialog" and "embedded custom UI", verify whether the target piece is pure LCL or widgetset-backed before committing to a design; if it is widgetset-backed, prefer a companion-panel pattern unless a platform-specific bridge is truly justified
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (FPC parallel build collision)
- Problem: trying to run the Lazarus app build and the FPC test build in parallel in the same workspace caused a false-negative test failure even though the source changes were valid
- Core error: the test-side link step failed with `ppaslink.sh: line 10: paint/symbol_order.fpc: No such file or directory`
- Investigation: compared the failing parallel run against the immediately successful standalone `build.sh` run and traced the failure to both commands generating and consuming FPC link-script artifacts in the same working tree at the same time
- Root cause: FPC/Lazarus writes transient linker-script files (`ppaslink.sh` and related inputs) into shared locations during builds, so concurrent compile/link jobs in one tree can overwrite each other's temporary link inputs
- Fix: re-ran the verification serially instead of in parallel; the test suite then passed cleanly at 151 tests and the GUI build linked normally
- Reuse note: do not parallelize independent FPC/Lazarus compile pipelines in the same workspace unless they are isolated into separate build/output roots; treat them as mutually interfering jobs by default
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (Native button icon fidelity limit)
- Problem: the new Figma-like control direction called for icon buttons, but the current standard Lazarus `TButton` path does not natively match that design language closely enough on its own
- Core error: a stock `TButton` gives a text caption surface, so keeping the implementation on standard controls made exact vector-style icon parity impossible without a heavier control rewrite
- Investigation: re-read the current button-construction path in `mainform.pas`, compared it against the design's icon-only buttons, and kept the pass constrained to controls that already exist in the live app so functionality and layout stayed stable
- Root cause: the current UI layer is built around standard native button controls, not owner-drawn/image-backed controls or a dedicated image-list icon pipeline
- Fix: switched the existing buttons to compact symbol glyphs as an interim icon-like surface while preserving the same click targets, hints, and layout; documented that full asset-backed icon parity remains a separate remaining task
- Reuse note: when exact icon parity matters in Lazarus/LCL, plan for image-backed or owner-drawn controls explicitly; do not assume a stock `TButton` caption can reproduce a modern Figma icon system exactly
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (Panel density pass)
- Problem: deepening the color and layer panels risked adding more controls without keeping the panel surfaces readable or keeping the new controls synchronized with the existing state
- Core error: if the new controls reused ad hoc conversions or only updated one representation, the UI would drift into conflicting RGB/HSV/hex values or duplicate opacity semantics across the layer panel
- Investigation: traced the existing color-update path through `UpdateColorSpins`, `ColorSpinChanged`, and `ColorHexChanged`, then checked the active-layer refresh path and found the missing reusable opacity-percentage mapping before adding more inline controls
- Root cause: the earlier panel implementation exposed only one branch of each control family (RGB/hex for colors, modal byte opacity for layers), so there was no shared mapping layer ready for denser controls
- Fix: added shared layer-opacity percent/byte helpers, made the color panel use one synchronized RGB/HSV/hex update path, and only then added the extra inline controls and panel-height changes
- Reuse note: when deepening an existing desktop panel, add the shared state-mapping helpers first and make every new control write through the same path; otherwise the panel becomes denser but less reliable
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-03 (Theme pass)
- Problem: moving the app from the older dark chrome to the new light Figma-derived style risked leaving a mixed dark/light UI because the old theme values were spread across several unrelated code paths
- Core error: color and chrome decisions were duplicated across `mainform.pas` labels, list surfaces, owner-draw handlers, tab rebuilding, and palette creation, so a surface-level restyle could easily miss secondary controls
- Investigation: traced the theme-facing code through `FPPaletteHelpers`, toolbar/palette construction, history/layer owner-draw paths, and tab-strip rebuild logic, then added tests around shared chrome values before touching the form code
- Root cause: the earlier dark theme grew incrementally inside the form instead of being expressed as a reusable theme token set, so style changes depended on scattered literals
- Fix: centralized the reusable light-theme tokens in `FPPaletteHelpers`, rewired the main form to consume those shared values for chrome/list surfaces/text, and added both backend and UI-side theme assertions before rerunning the full test/build flow
- Reuse note: when restyling a desktop UI, centralize reusable theme tokens first and test them before editing control construction; otherwise the form code becomes a brittle patchwork of stale visual constants
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-02 (Test infrastructure)
- Problem: two test suites (`TCLIIntegrationTests`, `TFormatCompatTests`) failed on every clean checkout with `CLI binary exists` / `Executable not found` errors
- Core error: `run_tests_ci.sh` compiled only the test runner and never compiled `flatpaint_cli`, so the binary was absent unless manually pre-built
- Investigation: read the failing assertion (`AssertTrue('CLI binary exists', FileExists(CliPath))`) and traced back to the CI script — it had no step for building `src/cli/flatpaint_cli.lpr`
- Root cause: the CLI build step was added to the manual `build.sh` path but was never integrated into `run_tests_ci.sh`, creating a hidden dependency on a manually-produced artifact
- Fix: added CLI compilation (`fpc ... src/cli/flatpaint_cli.lpr && cp flatpaint_cli dist/flatpaint_cli`) as the first step in `run_tests_ci.sh` so the binary is always fresh before tests run
- Reuse note: any test that requires an external binary must have that binary's build step inside the same CI script; never rely on a pre-built artifact from a separate manual flow
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: two test units (`ui_prototype_tests`, `perf_snapshot_tests`) existed in `src/tests/` and registered test classes but never ran
- Core error: neither unit was listed in the `uses` clause of `flatpaint_tests.lpr`, so both were invisible to the FPCUnit runner
- Investigation: diffed the files under `src/tests/` against the `uses` clause in `flatpaint_tests.lpr` and found `ui_prototype_tests.pas` and `perf_snapshot_tests.pas` missing
- Root cause: the units were added as standalone test files but the test-runner program file was not updated at the same time
- Fix: added both `ui_prototype_tests` and `perf_snapshot_tests` to the `uses` clause in `flatpaint_tests.lpr`; test count rose from 103 to 105, all passing
- Reuse note: whenever a new test unit is added to `src/tests/`, update `flatpaint_tests.lpr` in the same commit; the compiler will then catch any unit that is referenced but missing
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-02
- Problem: the codebase claimed broad selection-tool coverage, but one of the most practical combine behaviors was still missing
- Core error: geometric selection tools and magic-wand selection only supported replace/add/subtract, so there was no core or input-path support for `Intersect`
- Investigation: after the tool-options audit explicitly listed `Intersect` as a required selection mode, re-read `TSelectionCombineMode`, the selection-mask primitives, and the document-level magic-wand path to confirm the omission existed in both the mask layer and the wand special case
- Root cause: the early selection implementation stopped at the minimum add/subtract baseline and then duplicated combine handling in the magic-wand path instead of centralizing the full combine family
- Fix: added `scIntersect`, introduced a reusable selection-mask intersection helper, routed rectangle/ellipse/polygon selection through it for intersect mode, updated magic-wand composition to honor the same mode, and mapped `Shift+Option` to intersect in the current GUI input path
- Reuse note: if a tool family already supports multiple combine modes, finish the full set in the shared enum and shared helpers first; do not let one route (like magic wand) carry a partial hand-rolled combine implementation that drifts from the rest of the selection stack
- Repeat count: `This issue has occurred 1 time(s)`

## 2026-03-02 (Zoom/Pan validation)
- Problem: need verification that viewport zoom and pan behave consistently across entry points (toolbar, zoom tool clicks, anchor-preserving zoom, and panning drags).
- Core error: potential drift between different zoom/pan entry points can make viewport feel inconsistent (anchor vs center vs pointer focus).
- Investigation: audited `ApplyZoomScaleAtViewportPoint`, `ApplyZoomScale`, `ViewportImageCoordinate`, `ScrollPositionForAnchor`, and the `tkZoom` / `tkPan` handlers in `src/app/mainform.pas`; verified existing helper tests in `TFPViewportHelpersTests` and `TFPZoomHelpersTests` cover the low-level math.
- Root cause: no single issue — verification gap (missing QA entry) left this area assumed correct rather than explicitly validated against the product baseline.
- Fix: exercised the viewport helpers and the full test suite; ensured `tkZoom` uses `ApplyZoomScaleAtViewportPoint` with pointer anchor, and `tkPan` routes to the panning helper that updates scrollbars; ran full tests and rebuilt app. No behavior changes were required; tests and build passed.
- Reuse note: when multiple UI entry points control the same spatial transform, keep one authoritative anchor-preserving helper (as this project does) and test that helper directly rather than re-testing every UI route.
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: adding more real tools made the left-side palette layout regress even though the adaptive workspace layout helper already existed
- Core error: the `Tools` palette became taller after adding `Pan` and `Pencil`, but the legacy hard-coded fallback `Colors` rectangle still started too high, so the static default rectangles overlapped again in tests
- Investigation: ran the existing palette regression suite immediately after the tool-catalog expansion and used the failing non-overlap test to compare the new `Tools` height against the old absolute `Colors` top coordinate
- Root cause: the workspace-aware layout path had been corrected earlier, but the code still kept an older absolute fallback rectangle for `Colors`, so changing tool-count-driven palette height re-broke the pre-workspace baseline
- Fix: increased the `Tools` palette baseline height and replaced the stale absolute `Colors` Y position with one derived from `ToolsPaletteHeight + PaletteGap`, so both the static default rects and the workspace-aware layout stay consistent
- Reuse note: when a tool catalog grows, treat palette geometry as data that must derive from tool-count-sensitive constants instead of preserving stale absolute fallback rectangles
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the child utility palettes could still launch stacked together even after their nominal default rectangles had been defined
- Core error: startup positioning still depended on an early workspace clamp, so a zero or not-yet-final client size could collapse multiple palettes to the same corner before the first real paint cycle
- Investigation: re-read the palette creation path, checked when `CreatePalette` and `ClampPaletteToWorkspace` run relative to aligned-control sizing, and compared that sequence against the user's report that the default launch layout still looked piled up
- Root cause: the code applied hard clamping before the workspace bounds were guaranteed to be stable, so the "default" rectangles were being corrected against placeholder dimensions instead of the final usable workspace
- Fix: added a deferred first-idle layout pass plus a workspace-aware default-rectangle helper, and changed startup palette placement to skip premature clamping until the real workspace bounds are available
- Reuse note: for desktop layouts that depend on aligned host dimensions, do not treat constructor-time client sizes as authoritative; defer any bounds-dependent placement until the container has a real layout
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the status-bar zoom control could visually drift into neighboring status text even though a zoom panel already existed conceptually
- Core error: the zoom slider and percentage readout still behaved like loosely placed child controls inside the status bar instead of a reserved right-edge cluster, so the percentage label could overlap adjacent content
- Investigation: re-read the status-bar panel partition helper and the child-control bounds math, then compared it against the user's report that the zoom strip was not reliably pinned to the far right
- Root cause: the layout logic derived the zoom controls from the last panel width but still positioned the label relative to the track width instead of anchoring the whole cluster from the right edge inward
- Fix: changed the helper to reserve a bounded right-side zoom panel, added an explicit zoom-label width helper, and laid out the label and slider from the right edge of the status bar inward
- Reuse note: if a status bar has mixed text panels plus an interactive zoom control, reserve the zoom cluster explicitly at the trailing edge instead of treating it as just another flowing text segment
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: manual local rebuilds still depended on the user noticing and closing a running FlatPaint process before the output binary or app-bundle executable could be replaced
- Core error: rebuild steps could fail on open executable replacement or leave the local process-management burden on the user instead of the repository's own maintenance tooling
- Investigation: re-read the current build notes, checked the missing `scripts/` directory against the older doc references, and confirmed the workspace still had no canonical clean/build/release scripts even though the docs already treated repeatable bundle refresh as a requirement
- Root cause: the repository had accumulated one-off build commands in logs and memory, but it never consolidated them into checked-in scripts with explicit process-kill behavior for replacement-sensitive outputs
- Fix: added checked-in `clean`, `build`, `build-release`, and compatibility bundle wrapper scripts, centralized the lazbuild lookup plus app-bundle staging logic, and made the scripts kill running `flatpaint` / `FlatPaint` processes before rebuilds and retry copy steps if replacement is blocked
- Reuse note: if a desktop app writes its primary executable into the workspace, treat process shutdown as part of the checked-in build workflow instead of expecting developers to manually close the app before every rebuild
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the `Add Noise...` command still used a raw prompt even after the adjacent effect routes had started moving onto bounded slider dialogs
- Core error: users had to type a noise amount into `InputQuery`, which made the effect feel inconsistent with the newer modal pattern and less controllable for common trial-and-adjust use
- Investigation: after upgrading `Blur...`, re-read the remaining effect handlers and isolated `Add Noise...` as the last obvious single-value prompt holdout in `Effects`
- Root cause: the initial noise path correctly prioritized exposing the shared-core operation, but it stayed on the minimal text-entry route after the UI standards had already moved beyond that baseline
- Fix: added a dedicated `Add Noise` dialog with a numeric field plus a slider, moved parsing/clamping/slider mapping into a shared helper unit, and routed the menu command through that dialog instead of inline prompt parsing
- Reuse note: when one effect in a command family has already moved to a bounded slider-backed modal, finish the same treatment for the neighboring single-value effects so the whole menu family reads as one coherent surface
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the `Blur...` command was usable, but its parameter entry still lived on a raw prompt box even after the project had established a better modal pattern for bounded adjustments
- Core error: users had to type a blur radius into `InputQuery`, which made a frequently used effect feel inconsistent with the newer slider-backed adjustment surfaces
- Investigation: after upgrading the adjacent single-value adjustment routes, re-read the remaining effect handlers and treated `Blur...` as the next bounded-range prompt holdout
- Root cause: the first effect pass prioritized getting the shared-core box blur wired end-to-end, but the UI never got the second-step upgrade into a bounded control surface
- Fix: added a dedicated `Blur` dialog with a numeric field plus a slider, moved parsing/clamping/slider mapping into a shared helper unit, and routed the menu command through that dialog instead of inline prompt parsing
- Reuse note: once a bounded effect command is stable, align it with the same slider-backed modal pattern used by adjustment commands so parameterized flows stop feeling randomly mixed
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the `Posterize...` command was implemented, but the macOS interaction still exposed it as a raw one-line prompt instead of a stable adjustment dialog
- Core error: users had to type a level count into `InputQuery`, which made a common tonal adjustment feel unfinished and hid the valid range behind a fragile text-only entry path
- Investigation: after moving the other adjustment routes off prompt boxes, re-read the remaining `Adjustments` handlers and identified `Posterize...` as the next single-parameter holdout with a clear bounded range
- Root cause: the first pass stopped at the minimum functional prompt collector and never promoted the command into a dedicated parameter surface once the underlying shared-core operation was stable
- Fix: added a dedicated `Posterize` dialog with a numeric field plus a slider, moved parsing/clamping/slider mapping into a shared helper unit, and routed the menu command through that dialog instead of inline prompt parsing
- Reuse note: for bounded single-parameter adjustment commands, replace long-lived prompt boxes with a small modal that exposes both direct entry and slider control once the supported range is stable
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: refreshing `dist/FlatPaint.app` exposed that the current local Cocoa build path is still less stable than the compile-only GUI check used for source validation
- Core error: a real linked GUI build failed first on unresolved `UserNotifications` symbols and then on a `cocoawsextctrls.o` malformed method-list linker error even after adding the missing framework
- Investigation: after the `Curves...` UI follow-up passed unit tests and the existing `-Cn` Cocoa compile check, attempted a direct linked build into `dist/FlatPaint.app` and then retried with an explicit `UserNotifications` framework link flag
- Root cause: the current local Lazarus/FPC Cocoa widgetset path in this environment still has a linker-level issue beyond the project source itself, so compile-only success does not yet guarantee a runnable linked app bundle
- Fix: no source change in this pass; kept the source-validation path on the existing compile-only Cocoa check and left full bundle refresh as a tracked local toolchain blocker
- Reuse note: do not treat `-Cn` Cocoa compile success as equivalent to a verified macOS app bundle on this toolchain; validate at least one real linked GUI build separately before assuming `dist/FlatPaint.app` is current
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the `Curves...` command existed, but the macOS flow still reduced it to a single raw prompt despite the project already having a documented adjustment-dialog baseline
- Core error: users had to type one gamma number into `InputQuery`, which made the command feel unfinished and hid the actual supported range/midtone behavior behind a placeholder interaction
- Investigation: re-read the `Adjustments` handlers after the recent modal upgrades and compared the remaining prompt-based `Curves...` route against the current shared-core reality, which is a one-value RGB gamma curve rather than a full point-curve editor
- Root cause: the earlier implementation correctly limited backend scope to a simple gamma curve, but the UI never moved past the first minimal prompt collector, so the visible interaction undersold the real supported behavior
- Fix: added a dedicated `Curves` dialog with a gamma slider plus numeric field, moved gamma parsing/clamping/slider mapping into a shared helper unit, and routed the menu command through that dialog while explicitly keeping the backend as the existing one-value RGB gamma path
- Reuse note: even when backend scope is intentionally narrower than the target product, build a task-specific dialog that honestly reflects the real supported subset; do not leave long-lived core commands on raw prompt boxes once the behavior is stable
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the code claimed to support the paint.net brightness/contrast baseline, but the visible command surface had drifted into two separate menu commands that do not match the expected workflow
- Core error: users saw `Brightness...` and `Contrast...` as unrelated actions instead of one `Brightness / Contrast...` adjustment task, which broke 1:1 command-surface parity even though the underlying raster operations already existed
- Investigation: re-read the `Adjustments` menu against the command-surface baseline after the recent modal work and compared the current split handlers with the PRD's explicit `Brightness / contrast baseline`
- Root cause: the initial implementation surfaced the two shared-core raster operations directly and stopped there, so the menu structure reflected implementation convenience instead of the product-level workflow target
- Fix: replaced the two separate `Adjustments` menu items with one `Brightness / Contrast...` command, added a dedicated dual-parameter modal plus a shared helper unit, and routed the command through a single history entry that applies brightness and then contrast in sequence through the existing shared core
- Reuse note: when the target product treats multiple low-level operations as one user-facing adjustment task, preserve the product's command shape first and adapt the backend under it; do not let internal primitive granularity leak into the menu surface
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the first practical `Levels...` implementation made the command real, but the UI still spread one adjustment task across four generic prompt boxes
- Core error: users had to answer four sequential `InputQuery` prompts to apply one tonal remap, which is weak desktop UX on macOS and made the feature feel materially less complete than the shared-core implementation behind it
- Investigation: re-read the `Adjustments` handlers after the `Hue / Saturation...` follow-up, treated `Levels...` as the next obvious prompt-based holdout, and compared it against the current `New`, `Resize Image`, and `Hue / Saturation` dialog patterns
- Root cause: the earlier `Levels` pass correctly prioritized command coverage first, but it stopped at the minimal prompt-based collection path and never got the second-step UI upgrade into a task-specific modal
- Fix: added a dedicated `Levels` dialog plus a shared helper unit for parsing and clamping its four bounds, preserved ordered input limits while intentionally keeping output bounds independent, and routed the menu command through that dialog instead of four inline prompt calls
- Reuse note: when an adjustment needs multiple related numeric bounds, do not let it stay as a chain of `InputQuery` calls after the first functional pass; move the full parameter set into one dialog and push the validation policy into a pure helper so later UI iterations do not duplicate rules in event handlers
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the `Hue / Saturation...` command technically existed, but the UI still split one adjustment task across two generic prompt boxes
- Core error: users had to answer two unrelated `InputQuery` prompts in sequence, which is not a credible desktop adjustment flow on macOS and made the command feel less complete than the underlying shared-core implementation
- Investigation: re-read the `Adjustments` handlers against the development rules and compared the existing route with the already-upgraded `New` and `Resize Image` dialog paths to isolate where this adjustment surface was still lagging behind
- Root cause: earlier parity work prioritized making the command real end-to-end, but the route stopped at the first minimally functional prompt-based input path and never got upgraded into a task-specific modal
- Fix: added a dedicated `Hue / Saturation` dialog plus a shared helper unit for signed adjustment parsing/clamping, then routed the menu command through that dialog instead of chaining `InputQuery` calls inline in `mainform.pas`
- Reuse note: once an adjustment command needs more than one user input, stop using serial prompt boxes; move the parameters into one dedicated dialog and push the parsing/clamping rules into a pure helper so the bounds stay testable
- Repeat count: `This issue has occurred 1 time(s)`

- Problem: the current Lazarus shell still allowed several normal document-replacement actions to destroy unsaved work with no confirmation at all
- Core error: `New`, `Open`, `Open Recent`, `Close`, and `Quit` all replaced or discarded the live document immediately even when `FDirty` was true, which is a direct desktop-UX safety failure and especially jarring on macOS
- Investigation: re-read the real `mainform.pas` handlers instead of the optimistic progress notes, then treated the issue as one document-lifecycle policy gap rather than five isolated button/menu bugs
- Root cause: early command-surface passes prioritized wiring routes and parity labels, but the main form still had no shared "document replacement" guard before mutating or clearing the current session
- Fix: added one shared confirmation helper, routed every destructive document-replacement path plus the real form-close path through it, made the `Save` menu caption use an ellipsis only when it truly opens a save-location prompt, aligned the visible palette/view shortcuts with the documented macOS policy, switched the checked-in Lazarus project paths over to `$(LazarusDir)` macros, and removed one extra intermediate `TBitmap` allocation from the prepared-canvas refresh path while tightening the same standards pass
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

## 2026-03-03

- CI infrastructure mismatch: `run_tests_ci.sh` hardcodes a Lazarus directory under `/Users/chrischan` which breaks test compilation on other machines. The script also lacked full set of WSRegister stubs, leading to dozens of undefined symbols during linking of the test runner. Added note to update CI script or centralize stub definitions before broadening GUI test coverage.

- Problem: Move tools (`Move Selection` / `Move Pixels`) were not covered by tests and had subtle semantics that risked regressions (selection vs pixels movement and history integration).
- Core error: no unit tests validated that selection-only moves leave pixels unchanged and that pixel-moves both relocate pixel data and update the selection mask.
- Investigation: reviewed `TImageDocument` methods `MoveSelectionBy` and `MoveSelectedPixelsBy`, inspected the `PaintBox` drag handlers in `mainform.pas`, and added focused unit tests to lock the expected semantics.
- Root cause: earlier UI wiring implemented the live drag behavior but lacked automated coverage for the two distinct semantics (mask-only vs pixel+mask move), leaving regressions to appear only during manual QA.
- Fix: added `src/tests/tools_move_tests.pas` with tests for selection shifting and pixel movement; registered the new test in the test runner; verified the existing `PaintBox` handlers call the correct document APIs and that tests pass.
- Reuse note: when UI implements dual semantics (modify mask vs modify pixels), add small, focused unit tests that exercise both operations and their edge cases (bounds, history push, and selection coherence) immediately.
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

## 2026-03-02 (FPC optimization pass — compiler flags and hot-path allocation)

### Observation: project had zero explicit optimization flags
- Problem: the `.lpi` had no `-O2` in `CustomOptions`, so every build used the FPC default optimization level (effectively -O1 or unoptimized depending on the version); this is fine for debug output but is a poor everyday default for a pixel-manipulation app
- Core error: no `Optimization` block and no `-O2` in `CustomOptions Value`
- Investigation: read `FPC_MACOS_PERFORMANCE_GUIDE.md` against the actual LPI content by grepping for `OptimizationLevel`, `Optimization`, and `CustomOptions`; confirmed neither the LPI nor any build script had an explicit level
- Root cause: the project was bootstrapped without explicitly setting a level, relying on the FPC default
- Fix: added `-O2` to `CustomOptions` in `flatpaint.lpi` so all builds (debug and release) use the documented FPC release baseline; `-O3`/`-O4` remain reserved for profiling-directed escalation per the guide
- Reuse note: always set `-O2` in the base project file from the start; a missing optimization level is invisible but real — FPC does not warn that optimization is absent
- Repeat count: This issue has occurred 1 time(s)`

### Observation: release build had no dead-code removal (smartlinking)
- Problem: `build_release_artifacts` in `common.sh` called `lazbuild -B` without any smartlink flags; the binary was stripped by `strip -x` but FPC-level dead code was never removed
- Core error: no `-CX` (unit-level smartlink) or `-XX` (program-level smartlink) in the release command; binary contained all compiled code regardless of reachability
- Investigation: cross-referenced `FPC_MACOS_PERFORMANCE_GUIDE.md` (smartlinking section) against `common.sh` and measured debug vs release binary sizes before the fix: both were the same size, confirming no dead code was being removed
- Root cause: smartlinking requires both `-CX` at unit compilation time and `-XX` at link time; neither was passed to lazbuild
- Fix: added `--opt="-O2 -CX -XX"` to the `run_lazbuild` call inside `build_release_artifacts`; after the fix the stripped release binary shrank from 6.8 MB to 5.1 MB (a 25% reduction)
- Reuse note: **the correct lazbuild flag for passing extra FPC options is `--opt=`, not `--compiler-options=`**; the latter is rejected by lazbuild with "Invalid option" — always check `lazbuild --help` when adding pass-through flags on a new environment; smartlinking must be in the release build script, not in the base LPI, so day-to-day debug builds keep full symbols
- Repeat count: This issue has occurred 1 time(s)

### Observation: `BuildDisplaySurface` allocated and freed a large surface on every repaint
- Problem: `BuildDisplaySurface` created a new `TRasterSurface` (via `FDocument.Composite`) and returned it as the sole output, so `PaintCanvasTo` allocated and freed a ~3 MB buffer on every render-revision change; at 1024×768 this is 3,145,728 bytes of heap churn per stroke
- Core error: the function had no persistent cache; `Result := CompositeSurface` transferred a freshly-allocated surface to the caller, which immediately freed it after copying to `FPreparedBitmap`
- Investigation: read `PaintCanvasTo` and `BuildDisplaySurface` and noted the `try … finally DisplaySurface.Free` pattern; the revision guard already prevented redundant recomposites, but the allocation was still unconditional on every version change
- Root cause: the function was designed as a pure factory — it built and returned a new object — rather than as a mutator on a cached buffer; this matches the natural writing order for correctness proofs but creates avoidable allocation pressure in paint hot paths
- Fix: added `FDisplaySurface: TRasterSurface` as a persistent private field; changed `BuildDisplaySurface` to reallocate `FDisplaySurface` only when document dimensions change and to write composite+checkerboard results into the existing buffer otherwise; updated `PaintCanvasTo` to not call `Free` on the returned surface (it no longer owns it); added `FDisplaySurface.Free` to the destructor
- Reuse note: for any display-pipeline function that runs on every mutation and returns a large heap object, introduce a cached field with a dimension-mismatch guard as early as possible; the allocation cost is proportional to image area and is paid silently on every brush stroke
- Repeat count: This issue has occurred 1 time(s)

### Observation: inner checkerboard loop computed tile colour unconditionally for every pixel
- Problem: the transparency-checker tile color was computed with `(X div 8 + Y div 8) mod 2` for every pixel in `BuildDisplaySurface`, even for fully-opaque pixels that are the dominant case; `div` and `mod` are integer division instructions and the branch was still taken on every pixel regardless of alpha
- Core error: `TileColor` was computed before reading `PixelColor.A`, so the common case (opaque artwork) paid the checkerboard cost with no benefit
- Investigation: read the inner loop in `BuildDisplaySurface` and noted that the `TileColor` assignment always preceded the `if PixelColor.A = 0 / < 255` check
- Root cause: natural top-to-bottom writing order: "compute tile color, then read pixel, then branch" — readable but not branch-prediction friendly for the common case
- Fix: moved the `TileColor` computation inside the `PixelColor.A < 255` branch, added an early-exit path for fully opaque pixels (`if PixelColor.A = 255 then FDisplaySurface[X, Y] := PixelColor`), and replaced `div 8 … mod 2` with a single `shr 3 … and 1` per axis (the compiler may already fold this with -O2 but making it explicit is clearer intent)
- Reuse note: in pixel-iteration hot paths, read the discriminating field first and gate all auxiliary computations behind it; the fully-opaque case is almost always the dominant branch for paint-editor canvases and should be the shortest code path
- Repeat count: This issue has occurred 1 time(s)

## 2026-03-04

### Observation: `with TObject.Create do begin … Self … end` reads the enclosing class instance as Self in Free Pascal
- Problem: a `with TMenuItem.Create(FMainMenu) do begin … CreateMenuItem(Self, …) end` block was expected to build a sub-menu and then register child items under the newly created item; instead `CreateMenuItem` received the enclosing `TMainForm` instance as its parent because `Self` inside a `with` block refers to the nearest enclosing class method context, not to the object named in the `with` head
- Core error: child menu items were being added to the main form rather than to the intended sub-menu `TMenuItem`
- Investigation: compiler did not error on this code; the problem was silent misbehavior at runtime where all child items ended up on the form object instead of the sub-menu; traced by adding a local named variable and comparing parents
- Root cause: Free Pascal's `with` scoping rule for `Self` — `Self` is always the implicit receiver of the enclosing method, not the `with` target; the `with` block only promotes the target's members into scope, it never changes `Self`
- Fix: replaced `with TMenuItem.Create(FMainMenu) do begin … end` with an explicit local variable (`SubMenu := TMenuItem.Create(FMainMenu); SubMenu.Caption := …; EffectsMenu.Add(SubMenu); CreateMenuItem(SubMenu, …)` etc.) so the parent reference is unambiguous at every call site
- Reuse note: in Free Pascal, never rely on `Self` inside a `with SomeNewObject.Create do` block to mean the newly created object; `Self` is immutable within a method and always refers to the enclosing class instance; use an explicit named local variable whenever the newly-created object must be passed or referenced by name inside the same block
- Repeat count: This issue has occurred 1 time(s)

### Observation: Cocoa native bridge pattern is confirmed reusable for new UI capabilities
- Problem: adding palette drag-translucency required calling `setAlphaValue:` on an Objective-C NSView; the LCL abstraction does not expose this property, so there was no Pascal-level API path
- Core error: no LCL or RTL entry point exists for per-view alpha in the Cocoa widgetset
- Investigation: reviewed the existing `fp_magnify.m` / `fpmagbridge.pas` bridge structure and confirmed the pattern was self-contained: one `.m` source, one compilation block in `common.sh`, one Pascal bridge unit with a `{$IFDEF TESTING}` no-op guard, and one `{$LINK fp_xxx.o}` directive in the bridge unit's implementation section
- Root cause: the LCL Cocoa widgetset wraps only the intersection of all widgetsets; any macOS-specific visual property requires a native extension
- Fix: applied the same pattern — `src/native/fp_alpha.m` exports `void FPSetViewAlpha(void *nsViewHandle, double alpha)`, `src/app/fpalphabridge.pas` wraps it with a TESTING guard, `common.sh` compiles it with `clang -c -O2 -arch $(uname -m) -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa`; wired into `ApplyPaletteVisualState` with alpha 0.60 on drag start and 1.0 on drop
- Reuse note: for any new macOS-only visual capability, follow this four-part pattern: `.m` file with a plain C entry point → `common.sh` compilation block → Pascal bridge unit with `{$IFDEF TESTING}` no-op → `{$LINK}` directive; the TESTING guard ensures CI tests compile cleanly without the Objective-C object; the native handle is obtained from `TWinControl.Handle` cast to `Pointer`
- Repeat count: This issue has occurred 1 time(s)

### Observation: owner-draw listbox `ItemHeight` must be set at construction time before the first paint
- Problem: layer thumbnails in the `Layers` panel were clipped to the default row height even though `Style := lbOwnerDrawFixed` had been set and `OnDrawItem` was assigned
- Core error: the default `ItemHeight` for `lbOwnerDrawFixed` in LCL is 16 pixels; the first repaint used 16 before the form-layout pass ran and the larger value assignment was overwritten by an implicit layout reset
- Investigation: set `ListBox.ItemHeight := 36` at various points and confirmed it was only respected when set immediately after `Style` assignment in the same construction block
- Root cause: Lazarus LCL resets `ItemHeight` to a widgetset default during control initialization unless the property is explicitly committed before the control receives any paint or resize events
- Fix: set `FLayerList.Style := lbOwnerDrawFixed` and `FLayerList.ItemHeight := 36` consecutively in the same control-creation block inside `BuildPalettes`, immediately after the control is constructed; moving either assignment later caused the value to be ignored
- Reuse note: in Lazarus, always assign `lbOwnerDrawFixed` and `ItemHeight` together in the control's construction sequence; do not defer `ItemHeight` to a later layout pass — the first paint will have already committed the default before the deferred assignment runs
- Repeat count: This issue has occurred 1 time(s)

### Observation: effects menu grows unwieldy past ~10 items; sub-menu categorization matches paint.net structure
- Problem: the flat `Effects` menu had grown to over a dozen items with no grouping, making discoverability poor and the menu inconsistent with paint.net's categorized structure
- Core error: items were appended to a flat list as effects were implemented, following implementation order rather than product intent
- Investigation: compared the current flat list against the paint.net effects menu hierarchy (Blurs, Distort, Noise, Photo, Render, Stylize) and counted 17 items that map to those six categories
- Root cause: each new effect was wired to the effects menu directly using `CreateMenuItem(EffectsMenu, …)` without a category layer; the menu structure reflected source code addition order
- Fix: introduced six `TMenuItem` sub-menu items (Blurs, Distort, Noise, Photo, Render, Stylize) as local named variables and routed every effect through the appropriate sub-menu parent; used the explicit `SubMenu := TMenuItem.Create(FMainMenu)` pattern (see `with` Self lesson above) to avoid the parent-confusion bug
- Reuse note: categorize effects menus from the start using named sub-menu variables so items naturally land in the right group; retrofitting a flat list is error-prone because the order of additions is no longer visible; the sub-menu variable pattern (`SubMenu := …; EffectsMenu.Add(SubMenu); CreateMenuItem(SubMenu, …)`) is the safe idiom in this codebase
- Repeat count: This issue has occurred 1 time(s)

### Observation: zsh shell interprets unmatched quotation characters in multi-line `-m` git commit strings as an open string literal — terminal hangs
- Problem: a `git commit -m "…"` command containing em-dashes, colons inside quotes, and embedded line breaks caused the zsh session to wait indefinitely because the shell treated the message as an unclosed string
- Core error: zsh multi-line string handling: any `"` inside a `-m` value that contains special characters zsh interprets as string terminators can produce an ambiguous parse; the terminal appeared to hang waiting for a closing `"`
- Investigation: interrupted the hanging terminal with Ctrl-C, then attempted the commit with a shorter single-line message — it succeeded immediately
- Root cause: the commit message literal contained characters zsh parsed as parts of a quoting sequence rather than as plain text inside the outer double-quote delimiters
- Fix: used a short single-line `-m` message or wrote the message to a temporary file and used `git commit -F <file>`; alternatively, replaced em-dashes and multi-line content with plain ASCII and single-line phrasing
- Reuse note: when constructing git commit messages in zsh that contain colons, em-dashes, parentheses, or embedded newlines, keep the `-m` value to one concise plain-ASCII line; use `git commit -F <tempfile>` for rich multi-line messages to avoid shell quoting ambiguity
- Repeat count: This issue has occurred 1 time(s)

### Observation: 28-color swatch grid as a `TPaintBox` owner-drawn control gives clean color-palette UX with minimal code
- Problem: the Colors panel had a color wheel and value bar but no quick-access swatches for common colors, making color selection require multiple drag interactions even for a simple black-to-red change
- Core error: no swatch surface existed; primary/secondary color picking relied entirely on the continuous hue wheel gesture
- Investigation: compared against paint.net's Colors panel swatches and counted 28 standard colors as a reasonable first-pass palette grid
- Root cause: the initial Colors panel was built around the hue wheel and left swatches as a deferred feature
- Fix: added `FSwatchBox: TPaintBox` with `FSwatchColors: array[0..27] of TRGBA32` initialized in the constructor (2 rows of 14: a dark/earth row and a bright/saturated row); `OnPaint` renders 2×14 cells; `OnMouseDown` routes left-click → primary color and right-click → secondary color, then forces a hue-wheel repaint to sync the indicator; `ColorsPaletteHeight` raised from 306 to 346 to accommodate the new 40 px strip
- Reuse note: a `TPaintBox` with fixed-array color data is the lowest-overhead swatch surface in LCL; owner-draw gives full style control without a custom control class; always widen the palette height constant when adding a new strip to the Colors panel so the strip is not cropped on first display
- Repeat count: This issue has occurred 1 time(s)

### Observation: WSRegister stubs are the key to compiling LCL-dependent units in headless FPCUnit tests
- Problem: every new test file that transitively imported an LCL unit (Forms, Controls, etc.) triggered linker errors — `Undefined symbols: _WSRegisterCustomButton`, `_WSRegisterCustomForm`, etc. — even though those symbols are only meaningful at runtime on Cocoa
- Core error: the FPCUnit runner links against compiled LCL units but does not link the Cocoa widgetset objects that define the `WSRegister*` symbols; the linker expects those entry points to exist in the final binary
- Investigation: saw the symbol flood immediately after adding `Forms` to the test runner `uses` clause; read `WSRegisterStubs.pas` and found ~80 stub declarations that each just return `False`; cross-referenced with `-dTESTING` define used throughout the project and the `-k-undefined -kdynamic_lookup` linker flags in `run_tests_ci.sh`
- Root cause: the LCL registers every control type at program startup by calling a widgetset-specific `WSRegisterXxx` function; for headless test builds those functions must exist as no-op stubs or the linker fails
- Fix: `WSRegisterStubs.pas` provides the complete stub set, included in the test runner `uses` clause; `-k-undefined -kdynamic_lookup` defers any residual undefined symbols to runtime where they are never called in a headless run; `-Fl"$WIDGETDIR"` + `-Fl"$OBJDIR"` pull in the widgetset precompiled objects for the symbols that are resolved
- Reuse note: whenever a new LCL unit is added to the test compilation path, check whether it introduces new `WSRegister*` symbols; if so, add their stubs to `WSRegisterStubs.pas`; the stub body is always `begin Result := False; end;` — adding one takes under a minute; missing even one stub stops the link cold with a wall of `Undefined symbols` messages
- Repeat count: This issue has occurred 3 time(s)

### Observation: one helper unit → one dedicated test unit; keeps FPCUnit compile-rebuild cascades small and failures instantly attributable
- Problem: early tests grouped unrelated helper coverage into shared files; any change to one helper forced recompilation of unrelated tests, and test failures were harder to isolate because a single test class covered multiple feature areas
- Core error: no rule existed for mapping helper units to test units; tests grew organically into large files (`fpsurface_tests.pas` reached 525 lines, `fpuihelpers_tests.pas` reached 385 lines)
- Investigation: reviewed the suite layout when the test count first exceeded 50; the recently-added per-helper files (`fpblurhelpers_tests.pas`, `fpnoisehelpers_tests.pas`, `fpzoomhelpers_tests.pas`, etc.) were all under 50 lines and trivially readable; failures in them were instantly attributable
- Root cause: the initial structure followed "add to the nearest open test file" instead of enforcing a one-to-one ownership rule
- Fix: adopted a strict convention: one `fp<topic>helpers.pas` helper unit → one `fp<topic>helpers_tests.pas` test unit; each test unit imports only the helper it validates; `flatpaint_tests.lpr` adds both in the same commit; aim for 3–5 boundary-condition tests per helper covering clamp-low, clamp-high, and one midpoint
- Reuse note: when adding a pure helper unit (blur radius clamping, zoom step mapping, status-bar width partition), create its test file in the same commit; this keeps every test file under 100 lines and adds less than 5 minutes to the session; never add new tests to the large legacy files unless the test belongs specifically to `TRasterSurface` or `TImageDocument`
- Repeat count: This issue has occurred 1 time(s)

### Observation: `-dTESTING` compile flag is the correct binary switch for all test-vs-production divergence
- Problem: multiple files needed to behave differently during unit tests — native Objective-C bridges must not dereference real NSView handles; GUI-touching code must not call `Application.ProcessMessages` — without polluting production paths with mutable global state
- Core error: early attempts used runtime `if <some-global-flag>` guards which left dead test code in the production binary and introduced a mutable global that tests could accidentally pollute
- Investigation: reviewed `fpalphabridge.pas` and `fpmagnifybridge.pas`; both already used `{$IFDEF TESTING}` to substitute a no-op body; confirmed `{$DEFINE TESTING}` is injected only via `-dTESTING` in `run_tests_ci.sh` and is never set in the Lazarus project file
- Root cause: no documented rule existed; some new code used runtime flags instead of compile-time defines
- Fix: established the rule — all test-vs-production divergence uses `{$IFDEF TESTING} … {$ELSE} … {$ENDIF}`; the production Lazarus project never sets `TESTING`; this guarantees test stubs are compiled out entirely from the shipped binary
- Reuse note: for any new code path that must behave differently in tests (native handles, modal dialogs, clipboard access), wrap the production implementation in `{$IFNDEF TESTING}` and provide a no-op `{$ELSE}` branch; never use a runtime boolean for this; the compile-time approach is zero-cost in production and prevents test state from leaking
- Repeat count: This issue has occurred 2 time(s)

### Observation: CI test script must compile all binary dependencies before running tests that shell out to them
- Problem: `TCLIIntegrationTests` and `TFormatCompatTests` both invoke `flatpaint_cli` as a subprocess; on a clean checkout the binary may be absent or stale, so those test classes failed with a process-launch error before any assertion ran
- Core error: `run_tests_ci.sh` originally compiled only the test runner, not the CLI binary that integration tests depended on
- Investigation: failure was silent on the original developer's machine (always had a current binary) but reproducible on clean checkout; traced by reading `cli_integration_tests.pas` and finding `P.Executable := 'dist/flatpaint_cli'` with no pre-existence check
- Root cause: the CI script build order was compile-tests → run-tests; the prerequisite binary was assumed present
- Fix: added an explicit `fpc … -oflatpaint_cli …` and `cp flatpaint_cli dist/flatpaint_cli` step at the top of `run_tests_ci.sh` before the test runner compilation; the CLI is now always the first build target in CI regardless of what's on disk
- Reuse note: when a test class shells out to a binary, that binary must be an explicit build step at the top of the CI script before even the test runner is compiled; never assume a checked-in or previously built artifact is fresh enough to satisfy the current test suite
- Repeat count: This issue has occurred 1 time(s)

### Observation: "assert structural invariants after N operations" is the right test class for rolling-buffer and eviction-based data structures
- Problem: the region-based undo history introduced rolling snapshot eviction; there was no cheap way to assert that 20 consecutive paint→push-history cycles did not corrupt the snapshot stack without comparing exact pixel values for every intermediate frame
- Core error: fully asserting pixel state after 20 operations would require storing 20 expected surfaces and would make the test brittle whenever brush behavior changed
- Investigation: reviewed `perf_snapshot_tests.pas` — the single assertion `AssertTrue('History depth >= 20', Doc.UndoDepth >= 20)` verifies that the rolling eviction did not silently discard live entries, without dictating which specific snapshots survive eviction
- Root cause: no established test pattern existed for "this code path should handle N iterations without crashing or losing the structural invariant"
- Fix: `Test_PushHistory_MultipleSnapshots_NoException` creates a document, runs 20 paint+push cycles, then asserts `UndoDepth >= 20`; stack overflow, corruption, or silent entry loss all trip the assertion while the test remains stable across brush algorithm changes; the eviction boundary itself is tested separately in `fpdocument_tests.pas`
- Reuse note: for rolling-buffer or eviction-based structures, pair two test types: (1) structure-invariant test — "after N insertions, depth = min(N, maxDepth)"; (2) eviction-boundary test — "when depth reaches maxDepth+1, the oldest entry is gone"; do not try to assert exact element values unless the test is specifically about correctness of one particular operation
- Repeat count: This issue has occurred 1 time(s)

### Observation: history timeline tests should simulate row-click semantics through a pure document helper, not through the form event handler
- Problem: `HistoryTimeline_NavigateViaRowClickSimulation` and `HistoryTimeline_ClickInitialStateUndoesAll` needed to test "user clicks row N → document pixel state reverts to that point" without instantiating `TMainForm`
- Core error: wiring these tests through the form's `ListBox.OnClick` handler would force full LCL application initialization and mouse-event simulation — far too heavy for unit tests
- Investigation: read the existing `NavigateHistoryTo(Doc, ClickedRow)` helper in `fpdocument_tests.pas`; it translates a row index into the correct number of `Doc.Undo` / `Doc.Redo` calls directly on the document model, bypassing the form entirely; pixel state is then asserted on the document surface
- Root cause: timeline navigation is pure document-model logic (compute delta from current row to target row, apply N undos or M redos) but was originally exposed only through a `ListBox1.OnClick` handler in the form
- Fix: extracted the "how many undos/redos to reach row R from current position?" calculation into a test-private `NavigateHistoryTo` helper; the form's click handler delegates to the same index math; tests drive the model directly and assert pixel state, the form handler just calls the same function with the selected index
- Reuse note: any document-model operation triggered by a UI event should have its core logic expressible as `procedure DoSomething(Doc: TImageDocument; Param: …)`; test the pure function; let the event handler be a one-line call site; this pattern also makes the feature testable before the UI that exposes it is built
- Repeat count: This issue has occurred 1 time(s)

### Observation: a tool-enum count assertion is the cheapest way to enforce metadata-table completeness at CI time
- Problem: every new `TToolKind` enum value requires a corresponding entry in the tool-metadata array in `mainform.pas`; without a coverage assertion, a new enum value added without its metadata row caused a runtime access violation that only surfaced during manual QA
- Core error: adding an enum value and forgetting its metadata row is a silent compile-time success but a runtime failure
- Investigation: reviewed `fpdocument_tests.pas` after a tool-routing bug; found `NewToolKindCountIsCorrect` — it asserts `Ord(High(TToolKind)) + 1 = <expected count>`; any addition to the enum that does not also update the expected count breaks CI immediately
- Root cause: the metadata table was manually maintained and the enum could grow independently of it
- Fix: `NewToolKindCountIsCorrect` asserts the exact expected tool count; updating it is mandatory in the same commit as the enum addition, which forces the developer to also update tool descriptions, icon labels, cursor assignments, and menu routing before the commit can land
- Reuse note: for any `packed enum` that drives a parallel metadata table, add `AssertEquals('tool count', <N>, Ord(High(TToolKind)) + 1)` and update the expected value atomically with every enum addition; this converts a category of silent runtime access violations into an immediate CI assertion failure with a one-line fix
- Repeat count: This issue has occurred 1 time(s)

### Observation: `TProcess`-based FPCUnit tests are the right scope for "does this OS-level dependency exist?" checks
- Problem: features depending on `osascript` and the app bundle needed automated verification that the external tool or path was present, without requiring a full GUI automation harness
- Core error: adding these checks as `{$IFDEF DARWIN}` blocks in production code would mix environment probing with application logic; a GUI automation framework was too heavy for a simple reachability assertion
- Investigation: read `ui_prototype_tests.pas` and `ui_applescript_tests.pas`; both use `TProcess` to run a shell command and assert the exit code; the applescript test exits early with a pass if `flatpaint.app` is not present on disk, keeping the suite green on clean checkouts
- Root cause: no lightweight pattern existed for "assert OS-level prerequisite reachability" in this project
- Fix: create a `TProcess`, set `Executable` + `Parameters`, set `poWaitOnExit`, call `Execute`, then `AssertEquals('exit code', 0, P.ExitStatus)`; for optional filesystem prerequisites add an early `Exit` (implicit pass) when the file is absent
- Reuse note: use `TProcess` + `poWaitOnExit` for any test that validates an external command's availability or exit behavior; always add an early-exit guard when the test only makes sense with a specific artifact present; never use `Shell()` because its exit-code semantics are less explicit and platform-dependent
- Repeat count: This issue has occurred 1 time(s)

### Observation: region-based undo (dirty-rect snapshot) reduces per-stroke snapshot cost from O(W×H×LayerCount) to O(dirtyW×dirtyH)
- Problem: the full-document snapshot model stored a complete copy of all layer pixel data on every `PushHistory`; for a 1024×768 three-layer document a single brush stroke triggered ~9 MB of allocation even when only a 30×30 region changed
- Core error: `TDocumentSnapshot` called `TImageDocument.Clone` unconditionally; snapshot size was proportional to total canvas area × layer count, not to actual change area
- Investigation: the `perf_snapshot_tests` loop made heap pressure measurable; each `PushHistory` call in a steady-state paint loop cost `W × H × 4 × LayerCount` bytes of allocation and an equal deallocation on eviction
- Root cause: the initial undo model correctly prioritized correctness over efficiency; the clone-everything approach was the simplest honest implementation but became the dominant GC pressure source during painting
- Fix: introduced `TSnapshotKind` (`skFullDocument` / `skLayerRegion`); `PushHistory` now computes the current tool's dirty rect (brush bounding box expanded by radius), saves only that sub-surface in `(FRegionLayerIndex, FDirtyRect, FRegionSurface)`, and restores by stamping the saved region back into the correct layer; operations that affect multiple layers or document structure (merge, flatten, resize) still use `skFullDocument`
- Reuse note: implement region snapshots as a `(LayerIndex: Integer; DirtyRect: TRect; RegionSurface: TRasterSurface)` triple alongside the existing full snapshot path; always test the region restore path separately from the full-document restore path — a dirty-rect off-by-one leaves visible single-pixel ghost artifacts that are easy to miss in a "no exception" test
- Repeat count: This issue has occurred 1 time(s)
