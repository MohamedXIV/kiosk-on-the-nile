# Stutter first pass: measured Ink parsing and opt-in runtime observation

2026-10-25, Africa/Cairo. Baseline source `03f9391`, Godot 4.7.2, native Linux headless cloud CPU. This is an initial mitigation/diagnostic pass, **not a claim that player Web stalls are resolved**.

## Measured findings

Twenty fresh Ink opens per story, no gameplay commands/effects committed. Wall time from `InkRuntime.open` to its loaded return (includes deferred initialization scheduling): visitors median223417µs, orders122299µs, venue_comments29578µs, inner_monologue12264µs. These are long enough to justify examining synchronous story construction. They do not establish the same durations on the player's Web build.

A paired comparison in one process alternated the exact previous reader and patched reader30 times per story, rather than comparing separate CPU runs:

| Story | Previous parser median | Patched parser median |
| --- | ---: | ---: |
| visitors |24.200ms|16.271ms|
| orders |13.928ms|9.378ms|
| venue_comments |3.134ms|2.130ms|
| inner_monologue |1.235ms|0.911ms|

This is26–33% less **parser time**, not26–33% more FPS. Other unpaired runs varied substantially in story-open wall time; no end-to-end improvement is claimed. Story object construction still costs time and remains a priority. No live Ink pooling, shared state, background threading, population reduction or world pause was introduced.

Reader changes preserve the original escape decoder and numeric typing. Compared exact `var_to_bytes` parsed output (including numeric types) against the baseline reader for35 shipped current/archive/legacy story sections, plus empty/escaped/number probes: identical. This is bounded content comparison, not comprehensive testing of every JSON input or save. Existing upstream Unicode escape behavior was not redesigned.

Evidence and throwaway measurement scripts: [evidence directory](evidence/2026-10-25-stutter/). To reproduce paired script, extract `git show 03f9391:addons/inkgd/runtime/ink_simple_json.gd` to `/tmp/kiosk-old-simple-json.gd`, rename its `class_name` to `PreviousInkSimpleJSON`, copy the recorded `.gd.txt` script to a `.gd` in `/tmp`, then run through `bash tools/godot.sh --headless --path . --script /tmp/<script>.gd`. No automated gameplay suite was added or run.

## Optional runtime capture

Default **off**, including Release. Enable explicitly:

- Web: open the served game as `http://127.0.0.1:8765/?profile=1` (append `&profile=1` when query parameters already exist).
- Native: append `-- --profile-performance` to Godot command arguments.

Browser DevTools Console receives `KIOSK_PERF` JSON approximately every10 seconds. Preserve log, play until a stall, then copy those lines. Capture browser/version, viewport, OS/GPU and whether it coincided with entry, destination change, speech or save. Disable with the ordinary URL/reload after collecting; profiler observations themselves have overhead. Background-tab/throttled intervals can be large without a gameplay bottleneck. Current frame interval span is engine process cadence, **not GPU render time or browser rAF**; pair it with browser Performance recordings.

Scopes: simulation tick, audio projection, interaction projection, HUD, captions, visitor node spawn, visitor path lookup, story-open wall time keyed by story ID, and Ink advance. Scope counts, total/max µs and counts above16/50/100/250ms are reported; the most recent32 observations above50ms have monotonic timestamps. Max64 labels. Buffers reset per reporting window; no per-frame logging, story transcript, player state/save dump or callable game bridge. Nested spans overlap: do not add them together. Story open wall time includes deferred wait and should not be interpreted as isolated CPU construction time. Startup/title frames are also counted. It does not yet time every save/room-layout rebuild/driver operation.

## Verification and remaining work

Godot import and `tools/build.sh --release` completed (Ink compilation/localization coverage/import/export; not gameplay tests). Native scripted boot/new-session profiling emitted all main scopes with no script errors. Its early exit emitted ObjectDB/resource shutdown warnings; no clean full-session teardown claim. Release Web was also booted in Chromium/SwiftShader and emitted the opt-in report; this checks capture plumbing, not real GPU performance. No same-machine Web/native comparison or actual player stutter reproduction yet. The earlier unmodified cloud parser benchmark initially failed due a measurement cleanup bug (freeing during a signal), corrected before recorded evidence; it was not a product failure.

Next use the capture to distinguish physical spawn/path cost from deferred Ink initialization and text layout. The parser reduction alone does not solve all initialization work. Remaining audio/history copies, invisible rendering queries and per-tick UI work from the investigation report stay candidates, not measured fixes.

Web capture plumbing evidence: [six report windows](evidence/2026-10-25-stutter/web-capture.json), [actual new game](evidence/2026-10-25-stutter/web-new-game.png). Chromium software WebGL at1280×720; cold content load and concurrent build activity contaminate cadence, so these values are **not** a performance baseline or before/after result. Confirms Release query opt-in and main scopes during actual clicked new game; actor transition scopes were not exercised by this rooftop capture. Browser page/script error logs were empty. Web activation uses the explicit query string value rather than relying on JavaScript boolean bridging.

Product commit: `1f090e850f2ed09717a998f156f23fc2af0c4996`. [Diagnostic prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/performance-1f090e8). This delivery leaves the remaining candidates open for measured follow-up.
