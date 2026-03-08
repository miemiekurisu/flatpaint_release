# Development Rules

1. Read `docs/PRD.md`, `docs/FEATURE_MATRIX.md`, `docs/PROGRESS_LOG.md`, `docs/DEVELOPMENT_RULES.md`, and `docs/SHORTCUT_POLICY.md` before starting implementation.
2. Do not implement undocumented scope.
3. Every code change must map to a feature row and a progress entry.
4. Every core behavior change requires unit tests.
5. Run unit tests after implementation and log pass/fail.
6. Record every issue and fix in `docs/EXPERIENCES.md` using the minimal template.
7. Before marking a feature done, compare it against the active baseline set and note any deliberate gaps: code-first implemented behavior, active Figma-derived UI baseline (`flatpaint_design/`, `docs/UI_PARITY_AUDIT.md`), and paint.net functional intent baseline.
8. Run integration and regression checks once the relevant vertical slice exists.
9. Treat modal sheet content (open/save/export options, compatibility prompts) as part of feature completeness, not optional polish.
10. Before integration testing, compare visible menu shortcuts in code against `docs/SHORTCUT_POLICY.md` and resolve any mismatch first.
11. Keep `dist/FlatPaint.app` refreshed to the latest build that has passed compilation and regression, so a runnable bundle is always present in the repository.
12. Keep entries short, factual, and traceable.
13. Keyboard and shortcut policy: adopt Adobe Photoshop keyboard/selection habits as the UX baseline when mapping user interactions and modifiers (e.g., Shift = add selection, Alt/Option = subtract, Shift+Alt = intersect). Translate Windows modifiers to native macOS equivalents using `docs/SHORTCUT_POLICY.md` as the authoritative mapping table.
14. Use GIMP (and Krita) as the backend architecture/algorithm reference where paint.net lacks implementation detail; record such fallback usage in docs before relying on it.
15. Whenever Photoshop, GIMP, or Krita is used as a fallback reference for unclear behavior, record that fallback in the relevant docs in the same change window.
16. GPL-safety rule: treat GPL projects as architecture references only. Do not copy code, comments, data tables, or identifier names into FlatPaint. Write neutral behavior notes first, then implement original code.
17. For performance-sensitive work, review the official Lazarus and FPC documentation available in the local toolchain first, then apply those recommendations in code and record concrete optimization decisions in `docs/PROGRESS_LOG.md` and `docs/EXPERIENCES.md`.
18. Follow Lazarus/LCL painting guidance in practice: keep `DoubleBuffered` enabled for custom-drawn controls, prefer prepared bitmap reuse over rebuilding image buffers on every paint, and avoid unnecessary redraw work inside scrolling surfaces.
19. For macOS/FPC performance-sensitive changes, also review `docs/FPC_MACOS_PERFORMANCE_GUIDE.md` before editing code so release-flag changes and repaint optimizations stay consistent with the documented baseline.
20. Use `scripts/clean.sh`, `scripts/build.sh`, and `scripts/build-release.sh` for manual local maintenance; these scripts intentionally kill running FlatPaint binaries before rebuilds so output replacement does not fail on open executables.
21. If analysis reveals that a desired effect or feature cannot be achieved with the current language, framework, or widgetset, report the limitation immediately with a clear explanation of why it is infeasible. Do not force an implementation, produce a non-functional stub, or pretend the feature has been implemented.
22. A feature is not complete until the visible UI proves it: any tool, filter, or edit command that changes document state must also invalidate the relevant canvas/layer/tab preview surfaces and show an immediate on-screen result, not just mutate data silently.
23. Any color-sampling path that feeds a future paint action must preserve a visible paint alpha unless the UI explicitly exposes alpha sampling as a separate user choice; sampling a transparent pixel must not silently turn the next stroke into invisible paint.
24. Treat the default `Background` layer as a special non-transparent base layer, not as an ordinary alpha layer: any destructive tool or edit command that would normally punch transparency (`Eraser`, `Cut`, `Erase Selection`, moving selected pixels, equivalent clear paths) must restore an opaque background-color result on that layer instead of creating transparent holes.
25. Every development pass must end with `bash ./scripts/build.sh` and a successfully regenerated `dist/FlatPaint.app`; this app bundle is the only valid object for manual acceptance and release-go/no-go decisions.
