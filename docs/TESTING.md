# Testing Overview

This repository includes a comprehensive FPCUnit-based test suite covering unit, integration, format compatibility, and lightweight performance tests.

Test categories and what they map to (Photoshop-like behaviors):

- Unit tests: core pixel operations and helpers (`fpsurface_tests`, `fpselection_tests`, etc.) — maps to per-filter, per-tool correctness.
- Integration tests: document flow and native-document roundtrips (`integration_document_flow_tests`, `integration_native_roundtrip_tests`) — maps to open/edit/save fidelity.
- CLI integration tests: `integration_cli_tests` — maps to scripted batch workflows (export, new, apply filter).
- Format compatibility tests: `format_compat_tests` — maps to import/export fidelity (PNG/TARGA/XCF/PSD where implemented).
- Performance/stress tests: `perf_snapshot_tests` — maps to undo/snapshot memory and performance on larger canvases.
- UI prototype tests: `ui_prototype_tests` — initial checks for macOS UI automation tool availability (osascript); full UI behavior tests require an automation harness (AX/UI scripting or image-based verification).

How to run locally:

```bash
./scripts/run_tests_ci.sh
```

CI notes:
- The `run_tests_ci.sh` script compiles and runs the full test suite and exits with non-zero on failure.
- For macOS UI automation, extend `ui_prototype_tests` with AppleScript or use an external runner (Sikuli, PyAutoGUI) for image-based assertions.

Runtime profiling (macOS):

```bash
# 60s runtime monitor, enforce RSS budget
bash ./scripts/profile_runtime_macos.sh --duration 60 --max-rss-mb 1200
```

- Runtime profiling output is stored under `dist/runtime_profile/<timestamp>/`.
- Use this for GUI-path stall/memory regression checks that headless tests cannot cover.
