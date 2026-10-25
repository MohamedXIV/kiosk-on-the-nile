# Stutter first pass implementation plan

**Goal:** measure actor transitions and reduce confirmed avoidable Ink parsing work.
**Architecture:** opt-in bounded observation; preserve simulation, story ownership and saves.
**Spec:** `docs/notes/2026-10-25-runtime-stutter-investigation.md` and player follow-up.
**Execution:** inline, as authorized by “تمام ابدأ”. No further design decision required.

- [x] Record native headless story-open and parser baselines, separate from Web FPS.
- [x] Optimize unescaped JSON strings only; retain existing escape/numeric behavior.
- [x] Compare parsed values/types on shipped stories/archives, repeat timing.
- [x] Add opt-in bounded timings for frame intervals, simulation, presentation, visitor spawn/path and story opening/advance. Default off; no gameplay commands, story text or save dumps.
- [x] Import/build Web release and document measurements, usage and remaining limits.

Review focus: escaped strings and numeric types; first use versus repeated use; dormant profiling; async story-open wall time versus CPU time; invisible-world simulation remains running. No pooling/shared live Ink state, save schema change, content/rule change or population workaround.
