# Dynamic chairs and visitor seating

## Behavior

Seats are derived from actual placed item instances. Moving or rotating an empty chair changes its access point and sitting direction; a newly owned/placed chair uses the same definition automatically. A visitor independently decides whether to seek a seat, reserves an available slot before walking, and sits after reaching its clear access point. Other visitors cannot reserve the same slot. A nearby table can be associated with a chair; a table is optional for this first sitting/drink prototype.

VisitorSeating owns reservations and per-visit decisions; SeatCatalog owns cached derived geometry. Ink still owns conversations and ServiceSystem owns orders and payment. A visitor with a seat can request/await service there. Moving/storing/disappearing furniture does not cancel an accepted order. An order placed without a seat is not silently relocated to a new one.

Occupied chairs and their associated table cannot be moved, stored or cleaned under a sitter. Empty reservations may move and their destination follows; removing one releases it. Social approach releases the chair; after the meeting the person has an ordinary leisure destination and may seek another available seat after cooldown. Departure, sleep and removal release/prune reservations. If no chair or route is available, standing is valid; nobody is spawned to demonstrate a seat.

## Physical and visual position

ActorPose remains the real reachable feet/access point outside solid furniture. CharacterView smoothly moves the hips/torso over the authored seat anchor and bends legs toward those feet. No actor is teleported into a collider, and the existing navigation/physical save checks still apply. Idle blinking/breathing remain. This is a geometric placeholder sitting pose, not a finished animation/art set. Captions and order badges use the seat anchor when seated; interaction/hearing retain the real feet point.

The grid placement system is unchanged. The catalog can derive seats in either physical location; visitor seating currently runs for corniche/kiosk visitors. Player sitting and residential guest seating are not implemented in this slice. Local NPC avoidance remains a separate next step; AStarGrid2D is retained.

## Authoring

Bundled external JSON loads offline on content/session load. Reload after edits; no new live-reload control.

`content/items.json` supports a furniture `seats` array (up to8 slots). The chair ships with:

```json
{"id":"seat","access":[0,0.6],"anchor":[0,0],"facing":[0,1],"height":0.45,"table_radius":2.0}
```

Offsets are ground units relative to the footprint center at rotation0, then rotated with placement in quarter turns. `access` is the clear feet/reachable point, `anchor` is the seat center, `height` is sitting surface height. Stable identity is `<item instance>:<slot id>`. A furniture definition with `gathering_surface:true` can be associated as the nearest table in range. Chairs need no per-instance marker or character binding. The existing table/standing markers remain valid standing alternatives.

| `content/visitors.json` setting | Default |
|---|---|
| `seating.enabled` | true |
| `seating.delay_seconds` | `[2,5]` eligible real seconds |
| `seating.retry_seconds` | 8 real seconds |
| `seating.max_searches` | 3 per visit |
| `seating.max_candidates` | 8 nearest slots per search |
| `seating.search_radius` | 12 ground units |
| `seating.arrival_radius` | 0.15 ground units |
| Character `seating_chance` | Per-person0–1; passer0, others0.15–0.8 |

Independent deterministic samples preserve existing purchase RNG. Seat searches require same location, sight, personal space, exclusive ownership and a reachable access point. A chair/table being cleaned is skipped. Searches run only when due, not every physics tick. Catalog geometry rebuilds only on SpaceService revision changes; no furniture snapshot/path scan on ordinary cached reads. `spatial.character.sit_transition_seconds` defaults to0.35.

Absent optional metadata/policy keeps old external content without seating. Save4/revision14 migrates to revision15 with empty seating state, preserving clock, money, poses, orders, Ink, spatial memory and purchase RNG. Revision15 stores slot identity and per-visit timers/flags, not trusted geometry. Restore validates visit references, unique slot ownership, state/finite bounds and seated feet proximity. Removed/disabled slots safely lose their reservation; existing order/destination stays. Keep backups when returning to older builds.

## Evidence and limits

Bounded native experiments are recorded under `evidence/2026-10-27-dynamic-seating/`; no automated gameplay suite is added or run. Fixture-only overrides used chance1 and short selection delay; shipped values above remain intact.

- Two visitors reserved different slots with purchase RNG unchanged; physical ActorMotor movement reached both access points and set seated state, with feet outside furniture.
- Production SpaceService placement moved an unoccupied reserved chair and rotated another; destinations and facing followed the derived slot. Occupied chair move/store was rejected with the existing localized busy reason.
- Pending order stayed at a seated visitor's access point. Revision15 roundtrip preserved seating and pending order; revision14 migration preserved wallet/clock/purchase RNG/order and added empty seating state.
- Duplicate reservation restore was rejected. Released chair could be stored. An owned-item grant plus production placement (not a browser shopping acceptance) discovered a new chair instance without marker bindings.
- Moving an empty table near that chair associated it; a physical sitter then made table storage busy. Explicit seat release preserved the pending order. Clearing visits emptied seating state.600 cached catalog reads caused0 rebuilds.
- One fresh final review found the hygiene busy callback did not include seated furniture: a dirty occupied chair accepted cleaning before the fix, then rejected it with `equipment_busy` after the fix. The callback now includes seating without including its own active cleaning status (which would self-interrupt). An approaching reservation yields if cleaning starts first; the controlled run confirmed release, standing fallback and continued cleaning.
- Authoring rejects a seated arrival radius smaller than the path follower stopping radius, avoiding an actor stopping just before it could sit.
- Headless short-run teardown warnings99 ObjectDB instances /23 resources were observed. Prior fixtures reported94/21 with different session/object counts; no leak improvement or diagnosis is claimed here.

`?profile=1` adds `seat_catalog`, `seat_search`, `seat_reserved` and `seat_released` spans/counters. Existing spatial/Ink/path diagnostics remain. No universal FPS improvement or exhaustive layout/social/order acceptance claim.
