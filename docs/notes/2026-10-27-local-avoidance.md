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
