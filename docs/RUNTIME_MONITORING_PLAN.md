# Runtime Monitoring Plan (macOS, 8GB baseline)

## Why those two issues were missed

- Existing automated coverage is primarily headless/unit/integration (`src/tests/*`), which validates data-path correctness but not Cocoa runtime paint behavior.
- `Marquee overlay hung` was a GUI runtime complexity issue (`O(N)` draw calls on Cocoa bridge), not a pure core algorithm error.
- `Native CG double-offset` was an LCL/Cocoa CTM contract issue (`SetWindowOrgEx` already translates CGContext), and we had no runtime assertion for native bridge coordinate invariants.

## Monitoring goals

- Detect main-thread stalls early (high CPU streaks + stack sample evidence).
- Detect memory spikes and unexpected growth on long editing sessions.
- Produce repeatable artifacts (`csv`, `summary`, `sample`, `vmmap`) so PRs can be compared against baseline.

## Tooling

- Script: `scripts/profile_runtime_macos.sh`
- System tools used by script:
  - `ps` for periodic `rss/vsz/%cpu/thread/state` sampling
  - `sample` for stack capture around suspected hang windows
  - `vmmap -summary` for memory region profile

## Scenarios (recommended)

1. Idle baseline (60s):
- Launch app and do nothing.
- Target: establish normal resident-memory floor and idle CPU.

2. Marquee stress (manual or scripted, 60s):
- Repeated lasso/selection operations on medium-large canvas.
- Target: no multi-second high-CPU streak; no abrupt RSS surge.

3. Large-canvas edit stress (120s):
- 4K or larger canvas, brush/shape/undo-redo loops.
- Target: peak RSS remains within guardrail for 8GB machines.

## Suggested guardrails (initial, tune with data)

- Idle peak RSS: `< 700 MB`
- Interactive peak RSS: `< 1200 MB`
- Consecutive high CPU (`>=95%`) streak: `< 3s`

These are initial project heuristics for 8GB machines, not hard product limits yet.
Adjust after collecting several runs on representative workloads.

## Commands

```bash
# Idle baseline, fail if peak RSS > 700MB
bash ./scripts/profile_runtime_macos.sh --duration 60 --max-rss-mb 700

# Interactive run with a custom workload command (example)
bash ./scripts/profile_runtime_macos.sh \
  --duration 60 \
  --max-rss-mb 1200 \
  --workload-cmd "osascript ./scripts/workloads/lasso_stress.scpt"
```

## Output artifacts

By default the script writes to:

- `dist/runtime_profile/<timestamp>/process_samples.csv`
- `dist/runtime_profile/<timestamp>/summary.txt`
- `dist/runtime_profile/<timestamp>/sample.txt`
- `dist/runtime_profile/<timestamp>/vmmap_summary.txt`

Use `summary.txt` as the quick regression signal and keep the other files for root-cause analysis.
