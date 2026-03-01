# Reference Baseline

## Source policy
- Official current `paint.net` application source is not publicly available.
- GitHub release artifacts expose installers and packaging metadata, not the editable app source tree.
- Feature parity decisions in this project therefore use official documentation and release notes as the reference baseline.
- The target remains a macOS recreation of paint.net behavior, not a generic paint app inspired by multiple tools.

## Reference points
- Product page: `https://www.getpaint.net/`
- Official docs root: `https://docs.getpaint.net/`
- Feature overview: `https://www.getpaint.net/features.html`
- Menus and behavior docs: `https://docs.getpaint.net/` pages for File, Edit, Image, Layers, Adjustments, Effects, Utilities, and the Tools window
- Main window docs: `https://docs.getpaint.net/MainWindow.html`
- Menu bar docs: `https://docs.getpaint.net/MenuBar.html`
- Tool bar docs: `https://docs.getpaint.net/Toolbar.html`
- Status bar docs: `https://docs.getpaint.net/StatusBar.html`
- Utility window docs: `https://docs.getpaint.net/ToolsWindow.html`, `https://docs.getpaint.net/HistoryWindow.html`, `https://docs.getpaint.net/LayersWindow.html`, `https://docs.getpaint.net/ColorsWindow.html`
- UI parity audit: `docs/UI_PARITY_AUDIT.md` converts the official paint.net docs and screenshots into concrete FlatPaint layout requirements
- Shortcut translation in FlatPaint is documented separately in `docs/SHORTCUT_POLICY.md` to account for Windows versus macOS modifier differences while preserving paint.net command intent
- Public release metadata: `https://github.com/paintdotnet/release`
- Backend algorithm reference (non-UX): GIMP and Krita concepts may be consulted for selection, fill, filter, and compatibility-adapter implementation details where paint.net source is unavailable

## Baseline interpretation
- Target parity means practical parity for the end-user workflows exposed by paint.net on Windows, not code-level parity.
- Interaction model, workspace layout, feature naming, and user expectations should stay aligned to paint.net even when backend implementation borrows algorithm ideas from GIMP or Krita.
- The official main-window documentation is also used to guide toolbar placement, floating utility-window expectations, status-bar information density, and large-image initial viewport behavior.
- Official docs and screenshots are also used as the visual-layout baseline; functional parity alone is not enough if the default arrangement still reads unlike paint.net.
- GIMP and Krita are implementation references only; they do not override paint.net on UX, command naming, or workflow decisions.
- Plugin APIs, Direct2D internals, and Windows shell integrations are out of scope for the first implementation unless explicitly called out later.
