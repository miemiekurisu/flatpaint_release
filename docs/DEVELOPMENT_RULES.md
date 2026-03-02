# Development Rules

1. Read `docs/PRD.md`, `docs/FEATURE_MATRIX.md`, `docs/PROGRESS_LOG.md`, `docs/DEVELOPMENT_RULES.md`, and `docs/SHORTCUT_POLICY.md` before starting implementation.
2. Do not implement undocumented scope.
3. Every code change must map to a feature row and a progress entry.
4. Every core behavior change requires unit tests.
5. Run unit tests after implementation and log pass/fail.
6. Record every issue and fix in `docs/EXPERIENCES.md` using the minimal template.
7. Before marking a feature done, compare it against the paint.net reference baseline and note any deliberate gaps.
8. Run integration and regression checks once the relevant vertical slice exists.
9. Treat modal sheet content (open/save/export options, compatibility prompts) as part of feature completeness, not optional polish.
10. Before integration testing, compare visible menu shortcuts in code against `docs/SHORTCUT_POLICY.md` and resolve any mismatch first.
11. Keep `dist/FlatPaint.app` refreshed to the latest build that has passed compilation and regression, so a runnable bundle is always present in the repository.
12. Keep entries short, factual, and traceable.
13. Keyboard and shortcut policy: adopt Adobe Photoshop keyboard/selection habits as the UX baseline when mapping user interactions and modifiers (e.g., Shift = add selection, Alt/Option = subtract, Shift+Alt = intersect). Translate Windows modifiers to native macOS equivalents using `docs/SHORTCUT_POLICY.md` as the authoritative mapping table.
14. Use GIMP (and Krita) as the primary backend algorithm/reference where paint.net lacks implementation detail; record any such fallbacks in documentation before relying on them.
15. Whenever Photoshop, GIMP, or Krita is used as a fallback reference for an unclear behavior, record that fallback in the relevant docs before relying on it.
16. For performance-sensitive work, review the official Lazarus and FPC documentation available in the local toolchain first, then apply those recommendations in the code and record the concrete optimization decisions in `docs/PROGRESS_LOG.md` and `docs/EXPERIENCES.md`.
16. Follow the Lazarus/LCL painting guidance in practice: keep `DoubleBuffered` enabled for custom-drawn controls, prefer prepared bitmap reuse over rebuilding image buffers on every paint, and avoid unnecessary redraw work inside scrolling surfaces.
17. For macOS/FPC performance-sensitive changes, also review `docs/FPC_MACOS_PERFORMANCE_GUIDE.md` before editing code so release-flag changes and repaint optimizations stay consistent with the project's documented baseline.
18. Use `scripts/clean.sh`, `scripts/build.sh`, and `scripts/build-release.sh` for manual local maintenance; these scripts intentionally kill running FlatPaint binaries before rebuilds so output replacement does not fail on open executables.
19. If analysis reveals that a desired effect or feature cannot be achieved with the current language, framework, or widgetset, report the limitation immediately with a clear explanation of why it is infeasible. Do not force an implementation, produce a non-functional stub, or pretend the feature has been implemented.
