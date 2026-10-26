# Runtime performance fixes after player capture

2026-10-26, Africa/Cairo. Baseline product1f090e8 / source c8719e8. User authorized implementation after analysis of140.515seconds of actual player measurements.

## Findings and changes

- Repeated visitor Ink opens took473–625ms wall time in the player capture; individual advances55–96ms. Physical actor creation at most5.3ms and path lookups at most0.9ms in that sample. These bounds do not rule out other future scenarios.
- Presentation intervals rose from16.7ms to70–101ms while physics continued about60ticks/second. Interaction projection reached7.171ms/tick. This shows overlapping presentation/physics cadence pressure, not a standalone GPU diagnosis.
- Main now presents UI, interaction prompts, captions and audio targets once per process/render callback. World simulation/motion/dependencies and deferred-save boundaries stay on the original physics clock. Input still recomputes interaction selection at execution time. No coarse timer or stored eligibility cache.
- Location targets, people and phones outside interaction range skip expensive label/topic eligibility projections. Full `LocationView.interaction_targets()` remains its default API; only router asks for nearby targets. Nearest and secondary-person selection rules remain unchanged.
- InkRuntime may borrow an idle player from a **session-owned**, maximum8-entry cache keyed by exact story ID+SHA256. A borrowed player is exclusive, reset through upstream InkPlayer.reset/new InkStoryState before applying a new context. Its error callback belongs to the current borrower only. Healthy loaded players may return; errored/unready players are discarded. Active conversations keep independent players, and old archive hashes never borrow current graph versions. Cache is transient and never saved; standalone and paused-save validation paths may still use uncached players.
- Notebook and supplier periodic refreshes track elapsed ticks rather than testing tick modulo60. This keeps periodic account/cash-delivery controls updating when render frames skip exact physics ticks, and avoids rebuilding them multiple times on the same tick at high frame rates.

## Measurements (native, headless cloud CPU)

Cold-open versus reset measured before implementation in the same process: visitors284.123ms vs reset12.412ms median; orders148.763ms vs8.088ms; amgad101.998ms vs7.611ms.

After implementation, repeated warm open medians across11 current stories ranged1.089–9.654ms. Visitors8.433ms, orders7.549ms, amgad7.006ms. These are bounded microbenchmarks, **not player Web timings, a before/after FPS claim, or a promise about every open**.

Paired old/new router calls against the same synthetic three-person scene,120 observations per position:

| Player ground | Previous median | New median | Selection/text differences |
| --- | ---: | ---: | ---: |
| (0,0) |2.197ms|0.321ms|0|
| (-3,2.5) |2.295ms|0.916ms|0|
| (4,-2) |2.304ms|0.282ms|0|
| (-5,4) |2.211ms|0.426ms|0|

This isolates query cost; it is not a genuine gameplay save, same-machine Web/native comparison or full high-population rendering benchmark.

## State/lifecycle observations and review

-11 stories ×6 opens: canonical first-frame values/types and restoration of baseline runtime snapshots had zero observed differences/failures. A day variable was changed before return; reset plus new context gave the same first frame on reuse.
-Two simultaneous borrowers of one graph had distinct players; advancing one left the other serialized state unchanged.
-20 archived graphs requested under the same identity: zero wrong graph observations, idle count remained8 and all leases returned. Unhealthy player was discarded.
-These observations do not cover every branch, variable, random sequence, malformed save, financial action or future external Ink function. No automated gameplay suite was added/run.
-One fresh final reviewer checked lifecycle/hash isolation, render/input and teardown paths. Found one material supplier modulo-tick refresh regression caused by the cadence move; fixed with elapsed-tick tracking in one pass. No other material findings. No re-review.
-Native session benchmark shutdown emitted the same46 ObjectDB/21-resource warnings seen in prior boot observations; this work does not diagnose or claim to fix those warnings.

Raw observations: [evidence](evidence/2026-10-26-runtime-fixes/). Current product content, Ink source/compiled graphs, catalog keys and save schema/revision are unchanged.

## Remaining limits

**First open of a graph, a concurrent cache miss and reopening an evicted graph still perform a cold load.** No hidden warm-up was added during play. Ink continuation itself can still take time; it was instrumented but not rewritten. The cache trades bounded idle graph memory for less repeated construction. Other unmeasured rendering/driver/save costs and historical journal projection work remain candidates. Player-machine confirmation should repeat `?profile=1` capture; new `ink_reset` span identifies reuse. No claim that all stutter is eliminated.
