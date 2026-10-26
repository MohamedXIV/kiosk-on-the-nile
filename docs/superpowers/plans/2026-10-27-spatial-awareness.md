# Spatial awareness and quiet player meetings

**Goal:** approved first slice: visitors remember only observed locations and may approach the player for an existing Ink topic, then wait or give up after losing sight.
**Execution:** inline on isolated `work`; the user approved the presented bounded experiment with “عظيم جدا يلا نبدأ”. Continue without another approval gate. No automated tests unless requested; import/export and bounded runtime observations only.

## Design and decisions

- Retain AStarGrid2D and existing path recovery. No NavMesh, Rust, workers or new population/spawn scheduling.
- Separate `SpatialAwareness` (observations/last seen positions/ages) from `VisitorMeetings` (one optional player meeting per visit). Both belong to VisitorService and persist there. PhysicalWorldController supplies same-location visibility using current ground-space solids, including furniture and closed doors. This deliberately conservative first 2D model treats solid furniture as opaque; no FOV, hearing or communicated sightings yet.
- Observe player and current other visitors nominally every 0.5 real seconds per observer, staggered one observer per callback, within 7 ground units and clear sight. Knowledge expires after 45 real seconds; records never update from an unseen target's current pose.
- Youssef is the first enabled meeting actor: he can approach only for an eligible existing automatic social topic, while staying, with no order/purchase/conversation. Independent deterministic timing/chance does not consume purchase RNG. Wait 20–45 seconds, chance 0.35, at most one attempt per visit and one active meeting globally. Authored JSON controls all values. Farid retains existing near-player invitations: his 15–22.5 minute visit is too short for this approach delay, so do not alter his schedule just to demonstrate the feature.
- Meeting movement is an overlay; original visit destination, purchase state and social receipts remain domain-owned. Suspend purchase/leisure while approaching. Stop at conversational distance, retarget only after observed movement >=0.65 units and a 0.75 second cooldown. With lost sight keep last observed goal, wait up to 8 seconds after reaching it, total attempt <=35 seconds, then return to normal leisure. Existing companionship/Ink owns invitations, consent and dialogue. No new dialogue graph or invented facts.
- Never interrupt active dialogue, accepted orders, departure or sleep/travel; never teleport or chase into another location. Inaccessible goals end the attempt through existing bounded recovery. Layout updates invalidate physical paths without rewriting an active meeting goal.
- Schema4 revision14 adds empty awareness/meetings to revision13 saves without fabricating observations, changing original destinations, money, clock, purchase RNG, Ink or social receipts. Validate saved refs, ages, state and bounds before publication.
- A saved active meeting whose actor is removed/disabled by the current content policy is safely cancelled during restore; its attempted flag remains. The same guard runs before the runtime actor filter, preventing a stranded overlay/global lock. This also handles malformed unsupported-actor intents without making an innocent JSON policy edit invalidate the entire save.

## Approaches

Keep pathfinding and add domain memory/intent (chosen in conversation); moving to NavMesh now adds unrelated migration risk; omniscient pursuit contradicts the approved behavior. Seat discovery and local avoidance remain subsequent slices.

## Work

- [x] Implement finite geometry sight checks, bounded observer memory, separately owned meeting intent and configuration validation.
- [x] Integrate physical providers, social topic eligibility, movement overlay and quiet interruption/cleanup paths.
- [x] Add revision13→14 migration and atomic save validation/restore.
- [ ] Import/export, observe visible/lost/occluded/other-location/timeout/order/dialogue/save paths and inspect performance counters. No automated suite.
- [ ] One fresh whole-diff review, one material fix pass, package and publish pinned complete Web preview.

## Review focus

Unseen updates or cross-location disclosure; one-attempt limits surviving save/Continue; pending orders/departure/dialogue taking priority; inaccessible/furniture-changed goals; malformed or orphan saved memory/intent; no purchase RNG/Ink side effects; no every-frame paths or repeated auto-dialogue.
