# FPC macOS Performance Guide

## Purpose
This document captures the current performance baseline for FlatPaint on macOS when using Free Pascal plus Lazarus.
Use it as the project-local checklist before changing hot paths, build flags, or canvas rendering behavior.

## Source policy
- Use official Free Pascal documentation and official Lazarus documentation first.
- If a recommendation below is a project inference rather than a direct documentation statement, it is marked explicitly.

## Official-source baseline
1. Compiler optimization level
- Use `-O2` as the default release optimization baseline.
- Free Pascal documents `-O3` and `-O4` as trading compile time for potentially better code; do not assume they help without measurement.
- Practical rule for this project: keep everyday iteration builds conservative, and only raise optimization beyond `-O2` after profiling a real hot path.

2. Dead-code removal and binary size
- Free Pascal documents smartlinking at both the unit and program levels.
- Compile units with `-CX` and link the final program with `-XX` for release-oriented builds so unused code can be removed.
- Free Pascal also documents `-Xs` to strip symbols from the linked binary when shipping a release build.

3. LCL repaint behavior
- Lazarus documents `TWinControl.DoubleBuffered` as the standard way to reduce flicker for child controls.
- Project rule: keep custom-drawn canvas and ruler controls double-buffered, and prefer reusing prepared bitmaps over rebuilding visual buffers on every paint.

4. Text IO buffering
- Free Pascal documents `SetTextBuf` for assigning a larger text buffer to `Text` files.
- This is not a current GUI hot path, but if FlatPaint grows heavier text-based import/export logs or parsers, increase buffer size before repeated text IO instead of leaving the small default buffer in place.

## Project inferences
1. Separate release tuning from day-to-day debug builds
- Inference: on macOS, aggressive link-time stripping and smartlinking are useful for shipping builds but are a poor default for daily debugging because they reduce observability and can hide symbol-level diagnostics.
- Project rule: keep release-only flags in explicit release commands or release build modes, not in every default edit-compile-run cycle.

2. Optimize measured hot paths before broad compiler escalation
- Inference: FlatPaint's current performance risk is dominated by repeated raster composition, bitmap bridging, and redundant invalidation, not by a lack of maximum compiler flags.
- Project rule: remove redundant allocations and redraws first, then revisit compiler flags only if profiling still shows CPU-bound inner loops.

## Current FlatPaint priorities
1. Avoid rebuilding the composited display surface on view-only changes.
2. Avoid temporary `TBitmap` churn in the canvas-prepare path.
3. Keep scroll/zoom/status updates from triggering redundant full-canvas work.
4. Add release-only build flags deliberately once a dedicated release build path is formalized.

## Primary sources
- Free Pascal Programmer's Guide, optimization levels: `https://www.freepascal.org/docs-html/current/prog/progsu157.html`
- Free Pascal Programmer's Guide, smartlinking: `https://www.freepascal.org/docs-html/current/prog/progsu179.html`
- Free Pascal FAQ, reducing executable size: `https://www.freepascal.org/faq.var#size`
- Free Pascal RTL reference, `SetTextBuf`: `https://www.freepascal.org/docs-html/rtl/system/settextbuf.html`
- Lazarus LCL reference, `TWinControl.DoubleBuffered`: `https://lazarus-ccr.sourceforge.io/docs/lcl/controls/twincontrol.doublebuffered.html`
