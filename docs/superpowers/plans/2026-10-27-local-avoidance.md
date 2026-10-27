# Local character avoidance with cached grid paths

**Goal:** approved next slice: NPCs pass around people or wait/yield at narrow passages, retaining AStarGrid2D and the quiet visit/dialogue/seat systems.
**Execution:** inline on existing isolated `work`, user approved continuation. No repeated approval gate. No automated gameplay suite without request; bounded native runtime experiments, import/export and actual Web observations. One fresh final reviewer and one material fix pass.

## Architecture and decisions

- Keep grid pathfinding and ActorMotor physics. Add a per-location Node owning NavigationServer2D avoidance-only map/agent RIDs. No NavMesh, NavigationAgent path queries, Rust, workers, physics layer rewrite or gameplay RNG.
- Feed solver ground-space positions/speeds (not anisotropically projected screen coordinates). Register player as external high-priority motion; standing/conversation/seated NPCs are fixed obstacles to moving people. Seated agents use their seat anchor, not the visual/access proxy. Pause/arrival always means zero actual motion, regardless of old solver output.
- Motion filters receive desired ground velocity, publish it to RVO and apply a fresh compatible bounded safe sample. Samples have simulation-step age (not wall-clock age, to avoid starving low-FPS Web frames). New/teleported/sharply changed/old samples wait for fresh results. Physics remains authoritative; proposed movement must stay inside navigable bounds and clear authored solids with physical clearance.
- Hold a deterministic right-hand passing side through the encounter, with goal-aware conflict lookahead, only for a nearby predicted person conflict; keep passing/yield decisions separate from domain goals. Thin passages need a stable right-of-way/retreat policy if the controlled observation demonstrates symmetric solver deadlock. Never push a speaker/sitter, teleport, fabricate arrival, cancel an order or change knowledge/Ink.
- Reuse cached paths while waiting for a person: intentional dynamic yielding does not consume static stuck recovery attempts. When the blocker moves, resume without requiring furniture/layout changes. Physical/static obstruction still uses the existing bounded follower recovery.
- Allow bounded forward waypoint advancement after a local detour when the next segment is geometrically clear; never request an AStar path each frame or cut through furniture. Preserve ordinary path following when avoidance is absent/disabled.
- JSON `spatial.avoidance` controls radius0.24, neighbor distance2.5, max8neighbors, agent horizon1.0, sample age0.25 simulation seconds, passing margin0.12, conflict lookahead1.2 and detour skip distance0.75. Tune only from observation; values are implementation choices, not user-supplied balances.
- RID agents/maps are transient and explicitly freed on actor/world teardown. Reconstruct after Continue; schema4/revision15 and all saved domain state remain unchanged. Missing optional block disables the new behavior for old external content.

## Approaches

Chosen in conversation: native local avoidance above the existing grid. NavMesh migration is unnecessary for these requirements and not a proven performance win. Pure custom crowd solving would duplicate engine work; use a small passing policy only for game-specific coordination.

## Work

- [x] Implement avoidance-only RID lifecycle/steering, motion filtering and finite segment clearance/config validation.
- [x] Integrate visitors, residential actor, player location changes and stationary seated/dialogue state.
- [x] Preserve cached paths during yielding and safely advance waypoints after detours; observe narrow passage arbitration.
- [x] Observe same-path/crossing/opposing/stationary/wall/door/clear-blocker/pause/cleanup/disabled/load cases and bounded costs; import/export and actual Web coverage.
- [x] Attempt fresh final review (service usage limit; documented self-review fallback), publish verified complete pinned preview and update documentation/README.

## Review focus

Stale safe velocities on pause/goal/layout/teleport; low-FPS sample starvation; stationary and seated pose protection; narrow symmetric deadlock; geometry corner cutting; dynamic wait vs genuine static failure; no path-query storm or ever-growing RID registry; old save/domain/Ink/payment/RNG continuity; map isolation and actor/player cleanup.
