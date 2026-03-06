# Reference Baseline

## Current source-of-truth order
1. Implemented code behavior in this repository (`src/core`, `src/app`, `src/cli`).
2. Automated tests and current test status (`src/tests`, `docs/TEST_LOG.md`).
3. Product docs (`docs/PRD.md`, `docs/FEATURE_MATRIX.md`, and related baselines).

If docs conflict with code, docs must be corrected to match code-first reality.

## Baseline roles
- Visual/UI authority: `flatpaint_design/` plus `docs/UI_PARITY_AUDIT.md`.
- Functional intent reference: paint.net command semantics and naming (secondary to code-first behavior).
- Backend architecture/algorithm reference: GIMP/Krita concepts only (selection, compositing, IO decomposition, tool-behavior modeling).

## Reference points
- Product docs root: `docs/PRD.md`
- Visual audit: `docs/UI_PARITY_AUDIT.md`
- Shortcut policy: `docs/SHORTCUT_POLICY.md`
- paint.net product page: `https://www.getpaint.net/`
- paint.net docs root: `https://docs.getpaint.net/`
- paint.net feature overview: `https://www.getpaint.net/features.html`
- paint.net release metadata: `https://github.com/paintdotnet/release`

## Baseline interpretation
- FlatPaint is not targeting paint.net source-level parity.
- Visual/layout decisions default to the active Figma-derived baseline, with explicit intentional deltas documented in `docs/UI_PARITY_AUDIT.md`.
- paint.net remains a command-intent reference (naming, workflow expectations, menu/tool semantics), not the active visual authority.
- GIMP/Krita references do not override product naming or UX intent unless explicitly documented as a fallback.

## GPL-safety guardrails for architecture referencing
- Architecture patterns may be studied; GPL code must not be copied, translated, or mechanically rewritten.
- Do not copy identifiers (type names, function names, variable names), comments, or code structure verbatim from GPL sources.
- Derive behavior via neutral design notes first, then implement original code from those notes.
- Keep external reference code out of build/link paths and out of shipped artifacts.

## Optional local reference checkout
- If needed, place third-party reference sources under `reference/` (for example `reference/gimp-src/`) strictly for architecture study.
- Treat that tree as read-only reference input; do not import code, names, or comments into FlatPaint source files.
