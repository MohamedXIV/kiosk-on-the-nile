# Actor/dialogue stutter runtime fixes

**Goal:** reduce measured recurring Ink initialization and repeated presentation work.
**Baseline:** `c8719e8`; player capture from product `1f090e8`, 140.515 seconds. Visitors open473–625ms; interaction projection grows to7.171ms/tick while presentation falls to100–142 frames/10seconds but physics remains581–604 ticks.
**Execution:** inline, authorized by “تمام اعمل اللازم”. Use executing-plans. Current `work` checkout is already isolated from main; no main merge.

## Constraints and review focus

- Keep Godot4.7.2, canonical Ink/context/effect ownership, offline catalogs and save schema unchanged.
- Idle player reuse is session-scoped, bounded to8, exact story ID/hash keyed. Never lend an active player twice. Reset before new context. Drop errored/unready players. Archives must not mix with current versions.
- First use/concurrent cache miss may still cost a cold story open. No hidden warm-up stalls during play and no global pool across sessions.
- Update UI once per rendered process callback; physical simulation and save boundaries remain in physics. Input executes a fresh query. Never cache eligibility across domain state changes.
- Early range filtering must preserve nearest/secondary selection and default full location-target API.
- Measurement scripts, build/import/export and browser interaction only; no automated test suite added/run without an explicit user request.

## Tasks

- [x] Measure cold open versus Ink reset before adding reuse. Native same-process visitors284ms vs reset12.4ms median; orders149ms vs8.1ms; amgad102ms vs7.6ms. Treat as microbenchmark, not Web FPS.
- [x] Move presentation out of fixed physics tick and prune distant interaction projections; measure the same scene before/after.
- [x] Add session-owned idle player cache; integrate director/inner opens and close/error paths; measure repeated opens and observe reset, simultaneous borrowers, archive keys and save/restore behavior.
- [ ] Build Release, exercise actual Web UI/profiling and fresh final code review, address material findings once.
- [ ] Publish a complete diagnostic Web package on GitHub, pinned ZIP digest and honest measured limits.

## Rulings

- Existing user authorization covers implementation and the established GitHub preview delivery workflow; no additional approval gate.
- No pooling of live story state/containers between active conversations. Reuse only an exclusively released player after upstream `reset()` allocates new InkStoryState/reset globals.
- No broad UI topic eligibility cache: invalidation spans many independent systems. Range pruning and render cadence avoid stale gameplay decisions.
