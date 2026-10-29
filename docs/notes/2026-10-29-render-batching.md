# Rendering investigation, 2026-10-29

The combined preview added surface detail to floor and roof cells. The kiosk
building contains 448 authored quarter-metre cells. Drawing each cell's fill and
then its lines repeatedly switches primitive types in the Compatibility renderer.
The resulting cached canvas commands still incur rendering work every frame;
these static nodes were not repeatedly running their `_draw` functions.

The correction groups kiosk timber and roof fills before their line details and
groups pavement fills before seam/scuff lines. It retains the authored cells,
colours, marks, roof cutaway and layout refresh path. The rooftop room's existing
translucent cell outlines retain their original ordering, which matters where
adjacent outlines overlap.

## Bounded native observations

These were one-off rendered observations, not an automated suite. They used the
pinned `bash tools/godot.sh` Godot 4.7.2, Xorg dummy display, Mesa llvmpipe,
Compatibility renderer, 1280×720, dummy audio and requested disabled VSync
(the driver reported VSync switching unsupported). Each sample allowed 60 warmup
frames and measured 240 frames. Samples ran serially.

The full Main scene ran with its clock/simulation stopped after setup. The kiosk
player stood at (-4, 1.8), with four staying visitors (Farid, Youssef, Amgad and
Samir) nearby to include interaction projection. The pre-fix comparison loaded
presentation scripts from fc65ba3 into the same current gameplay/content setup;
422adb9 supplied the separate pre-polish comparison. This isolates presentation,
not every difference between those source commits.

| Kiosk with four nearby visitors | Draw calls/frame | Mean ms | Median ms | p95 ms |
| --- | ---: | ---: | ---: | ---: |
| Pre-polish presentation, 422adb9 | 609 | 35.79 | 28.88 | 53.29 |
| Polished presentation, fc65ba3 | 2497 | 49.77 | 48.07 | 65.48 |
| Grouped floor/roof rendering | 235 | 44.19 | 39.86 | 58.94 |
| Rooftop idle, polished baseline | 1378 | 42.91 | 36.36 | 58.95 |
| Rooftop idle, corrected | 948 | 41.98 | 35.32 | 58.30 |

The matched fix reduced draw calls 90.6%, mean frame time 11.2% and median frame
time 17.1%. Both matched samples reported 8512 rendered objects; this change
reorders existing detail instead of removing it. In a separate isolation sample,
hiding only the floor removed 1372 draw calls; hiding only the roof removed 896.
Main's observed interaction projection was around 1 ms per frame, HUD around
0.3 ms, and audio around 0.06 ms; none of those spans reached 16 ms in this setup.

Frozen-frame screenshots of the original polished and corrected geometry were
byte-identical for both kiosk and rooftop. Kiosk PNG SHA256:
`847836932a3a8ea9394255eeb4efbd8ad2a81cdd10e47408b09c7540a3aba07c`.
Rooftop PNG SHA256:
`c7916707797a7db6df1c7d9045c77b0a3903bb864798ba0bf94f956bcfe7a0e7`.
The retained raw logs, observation fixture text and screenshot hashes are in
[evidence/2026-10-29-render-batching](evidence/2026-10-29-render-batching/).
Scratch scripts and PNGs stay under ignored `work/perf-2026-10-29/` with
`work/.gdignore`. Initial scratch observations that started a travel journey
instead of activating the kiosk, a three-visitor setup, and a sample overlapping
another engine startup were discarded; the table uses clean serial samples.
Temporary multiline grouping of timber/roof details provided no material gain
and was discarded. Rooftop fill/outline reordering changed overlapping border
pixels and was discarded before the retained final observation.

## Limits

llvmpipe is software rendering, not the player's GPU or browser. The remaining
geometry still costs time there, and these observations do not establish a
particular target FPS or eliminate every possible simulation, save, navigation
or browser stall. No Web build or device-level performance claim is made.
The one-off fixture exited successfully but reported ObjectDB/resource cleanup
warnings; those were also present before the change. No automated suite was
added or run.
