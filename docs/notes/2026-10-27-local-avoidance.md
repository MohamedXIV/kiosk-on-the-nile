# Local person avoidance with cached grid paths

## Scope

NPC movement retains AStarGrid2D and ActorMotor collision. Each physical location owns a NavigationServer2D map used only for native local RVO avoidance. No NavMesh or navigation region is required, and the player remains directly controlled. Fixed speakers, seated visitors and standing people yield no ground to moving NPCs. This adds movement coordination, not NPC–NPC conversation decisions or knowledge of unseen actors.

A small policy predicts nearby conflicts and keeps a consistent right-hand passing side until clear. It limits prediction to the remaining goal distance, so a valid stop before another person does not cause an unnecessary detour. People behind authored solid walls do not trigger the local passing policy. Physics and cached finite-segment clearance remain authoritative for geometry; there are no static RVO obstacle RIDs in this slice.

The first controlled run passed opposing/crossing actors but stalled beside a stationary person. A small angular bias changed side as heading changed. Holding the encounter direction/side and steering beyond the person resolved that case. Goal-aware lookahead then removed excess passing near an endpoint. Near-wall clearance allows a legal pose already inside a conservative navigation margin to escape/slide without crossing the actual solid.

Motion feedback is transient and aged by simulation steps. Paused actors always output zero; teleport/despawn clears passing state. External player motion has higher priority. Each room owns/frees its map and agents, including world replacement. Solver samples are bounded by configured speed and rejected when old or incompatible with the preferred heading. A local detour may advance up to six already-passed grid waypoints only through a clear segment; the final goal remains.

Dynamic yielding does not consume static stuck retries or request a path every frame. After six seconds it emits one existing owner fallback notification without permanently failing the follower. If the blocker leaves, the cached route can resume. Genuine static stalls retain bounded recovery. This is not a reservation/priority system for every possible one-person corridor; unusually constrained layouts can still wait or take an existing domain fallback.

## Authoring

`content/spatial.json` has optional `avoidance` settings. Missing/disabled policy keeps old movement and allocates no avoidance map. Values load with content/session load, offline; reload after changing JSON.

| Setting | Default |
|---|---|
| enabled | true |
| radius | 0.24 ground units |
| neighbor_distance / max_neighbors | 2.5 / 8 |
| time_horizon_agents | 1 second |
| sample_age_seconds | 0.25 simulation seconds |
| conflict_lookahead | 1.2 seconds |
| passing_margin | 0.12 ground units |
| path_skip_distance | 0.75 ground units |
| max_wait_seconds | 6 seconds |

Validation enforces finite bounds and compatible neighbor/diameter/skip/fixed-step limits. No balance RNG, Ink, orders, relationships, payments or domain save fields change. Save schema4/revision15 remains; maps, samples and passing contacts reconstruct after Continue.

## Bounded native observations

Logs in [evidence](evidence/2026-10-27-local-avoidance/) are temporary runtime experiments, not an automated gameplay suite. No gameplay suite was added or run.

- Opposing and crossing pairs reached their goals with about0.48 minimum center separation and one path per actor. A stationary person stayed fixed while the mover passed and arrived.
- A narrow0.65-unit passage observation reached both goals, with three total path queries (one bounded static retry). This fixture does not prove every narrow layout is deadlock-free.
- Removing a temporary corridor blocker resumed the same cached route with one total path query. Active pause stopped exactly; a reversed goal then arrived without stale forward drift.
- Real-speed2.6 passing, near-wall start, legacy coincident starts and disabled policy completed. Coincident starts separate gradually; no teleport is introduced. All native observation maps were freed.
- Production physical/session integration retained exclusive seats, seated requests, pending orders, occupied-table protection and revision15 restore. Revision14 migration preserved wallet, clock, RNG and pending order. Integration teardown reported99 ObjectDB instances/23 resources still in use, as the previous seating fixture did; this is not a general leak diagnosis.

`?profile=1` includes `avoidance_steer` (script bridge duration), `avoidance_sample`, `npc_detour_skip` and `npc_yield_timeout`. The script span excludes native solver time. No claim of improved player-hardware FPS or elimination of all existing stutters is made. Web observations and delivery details are appended after the final export.

## Review and final code

Product source `d17a4978adfe` (full hash in delivered BUILD.json). A fresh independent final reviewer was dispatched, but the service rejected the turn due its usage limit before any review. The implementer performed a separate complete-diff review instead. This is weaker than independent review; none is claimed. No automated gameplay tests were run.

Final-source native opposing/crossing/stationary/narrow/goal/blocker/pause observations completed without script errors, with maps freed. A separate production-world lifecycle observation moved the player between rooftop, kiosk and a nonphysical travel location: the previous room lost the player agent, travel removed it from both maps, and freeing the world returned the native map count to baseline. These fixture pose switches exercise owner cleanup, not a full travel-menu acceptance. Godot4.7.2 import/Release export and all311 shipped stable Ink localization references passed the build-only gate.

## Web observation

The exact `d17a4978adfe` Release export opened the existing revision15 browser save through actual Continue on the same QA origin/profile. Wallet45, Amgad's active choices and existing people were present. [Continued save](evidence/2026-10-27-local-avoidance/web-continued15.png). No browser gameplay bridge or injected save/pose was used. Chromium uses SwiftShader software WebGL at960×540 on the cloud host; its frame intervals are not a representative hardware benchmark. Native controlled movement provides the focused avoidance evidence above.

Actual choice input continued the saved Amgad exchange; subsequent keyboard movement changed the player's position and camera while the dialogue/nearby people remained present. [Movement](evidence/2026-10-27-local-avoidance/web-moved.png). This does not by itself demonstrate every passing encounter in WebGL.

The actual menu Save, browser reload and Continue resumed the newly saved revision15, with wallet45, moved player position and the next Amgad choices retained. [Resumed save](evidence/2026-10-27-local-avoidance/web-resumed15.png). No page/script errors or save rejection/fallback warnings were logged. Engine WASM/PCK served successfully; favicon404 is harmless.

## Published preview

[GitHub prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/local-avoidance-d17a497) · [Pinned complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/45c4474eb3a4508b4960cd75ace811f48ed45e53/builds/kiosk-on-the-nile-local-avoidance.zip). ZIP12145486 bytes, SHA256 `8891fe1268367f06b80b8bcac62c511737d2f7d109d5a2bdf9e2e7cf0fc3abc4`. Independently downloaded and verified SHA256, ZIP CRC, single WASM/PCK set, product/schema metadata, every bundled shipping content file (including both locale catalogs and all11 Ink stories), and Web evidence. No fixture overrides are packaged. Product remains `d17a4978adfe2a524f10109a879adffc6684689f`; preview source branch may advance with documentation only. Main is unchanged.

## Execution decisions and limits

- Native avoidance-only agents retain AStarGrid2D; no Rust/workers/NavMesh backend was added. Simulation-step feedback age was chosen to avoid starving slow Web frames. Cost if unsuitable: native solving still needs measurement on real player hardware. No gameplay suite was added/run per developer instruction; bounded runtime/build/Web observations are recorded instead.
- Held encounter steering replaced the insufficient angular bias; prediction respects remaining goal distance, and legal near-wall poses may escape a conservative margin without entering raw solids. Unusual tight layouts can still wait or take the existing bounded owner fallback.
- Authorized isolated preview/artifact delivery was retained, with no main merge or repeated integration gate. The fresh review could not run because of the service limit; self-review is weaker and broad gameplay acceptance remains unproven. No deferred minor review findings were reported (the independent review never ran).
