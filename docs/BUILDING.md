# Build and Clean Scripts

## Purpose
- Use the repository-local scripts for manual cleanup and rebuilds.
- They are the canonical local maintenance path for this Lazarus/FPC tree.
- They kill running FlatPaint processes before replacing binaries or bundle executables, so local rebuilds do not get stuck on open-file replacement failures.

## Requirements
- `lazbuild` must be available either on `PATH` or through `LAZBUILD=/absolute/path/to/lazbuild`.
- The scripts target the checked-in Lazarus project file `flatpaint.lpi`.

## Scripts
- `./scripts/clean.sh`
  - Kills running `flatpaint` / `FlatPaint` processes for this workspace.
  - Removes generated outputs: `dist`, `lib`, `flatpaint`, `flatpaint.app`, and `src/cli/flatpaint_cli`.
- `./scripts/build.sh`
  - Kills running FlatPaint processes first.
  - Runs an incremental `lazbuild flatpaint.lpi`.
  - Refreshes `flatpaint.app` and `dist/FlatPaint.app`.
- `./scripts/build-release.sh`
  - Runs a clean rebuild (`lazbuild -B flatpaint.lpi`).
  - Publishes a stripped release binary at `dist/release/flatpaint`.
  - Refreshes `dist/FlatPaint.app` using the stripped release binary.
- `./scripts/build_app_bundle.sh`
  - Compatibility wrapper kept for older docs and habits.
  - Currently delegates to `./scripts/build.sh`.

## Output paths
- Default binary: `flatpaint`
- Local app bundle: `flatpaint.app`
- Refreshed repository bundle: `dist/FlatPaint.app`
- Release binary: `dist/release/flatpaint`

## Notes
- The scripts intentionally favor reliable local replacement over preserving a running editor instance.
- If `lazbuild` is missing, set `LAZBUILD` explicitly and rerun.
