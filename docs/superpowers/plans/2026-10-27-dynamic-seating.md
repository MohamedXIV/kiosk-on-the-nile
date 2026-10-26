# Dynamic seats and visit reservations

**Goal:** approved next slice: visitors discover, reserve, reach and sit on actual placed chairs, and can order there; furniture movement updates these behaviors.
**Execution:** inline on existing isolated `work`, following the user's “عظيم كمل”. No repeated approval gate. No automated gameplay suites unless requested; bounded runtime observations, build and actual Web interaction instead. One fresh whole-diff review and one material fix pass before preview delivery.

## Design

- Keep AStarGrid2D. `SeatCatalog` derives stable item/slot identities, access/seat anchor/facing/height and optional nearby gathering table from item metadata, placement/rotation and current layout. Cache by layout revision. New purchased chairs work through the same metadata; no per-instance/character hardcoded bindings. Missing optional metadata/policy leaves legacy content unchanged.
- `VisitorSeating` owns exclusive reservations and saved per-visit decisions, separate from paths, meetings, purchase state and Ink. Author optional chair `seats` array and table `gathering_surface`; visitor JSON controls delay2–5 real seconds, retry8seconds, max3 searches, radius12, max8 nearest candidates and per-character chances. Use independent deterministic samples, never purchase RNG.
- Select only same-location, visible, unoccupied, personally available and reachable access points. Reserve before walking; stand if unavailable. Arriving/leisure visitors may reserve; an existing order without a seat is never relocated to a newly found seat. Existing reservations support requesting/pending/served states and keep order identity. Social approach releases seat; return may seek another after cooldown. Departure/sleep/removal release reservations and prune records before snapshots.
- Arrival at a clear access/collision point sets seated state. CharacterView smoothly poses the torso/hips over the authored seat and bends legs and positions the visual feet/shadow at the chair, retaining idle blink/breath. ActorPose remains the reachable collision/access anchor, outside the solid chair, so physics/pathfinding/save position rules remain valid. Presentation offsets never teleport the actor or advance game state. Rotation changes access and sitting direction. Placeholder geometric pose only, not a full animation/art system.
- Empty reserved chairs may move: rebuild catalog and destination, invalidate physical routes. Occupied chairs and their associated gathering table are busy and cannot be moved/stored/cleaned under the sitter; movement after departure works normally. If an unoccupied reservation disappears/route fails, release and return to leisure; keep accepted order and its existing clear destination. No furniture or conversation operation cancels a paid/pending order.
- Requesting at a reserved seat uses its access point rather than authored service marker. Existing Ink/order UI/food icons stay responsible for the request and response. No new story text or translations.
- Schema4/revision15 adds empty seating state to revision14 without changing clock, money, visit poses, pending orders, Ink, memory or purchase RNG. Candidate restore validates visit/slot refs, uniqueness, seated proximity/lifecycle and finite bounded schedule state. Layout-derived data is recomputed, not trusted from save.

## Approaches

Chosen: data-derived seats plus visit-owned reservations, as agreed in the previous conversation. More marker bindings would leave purchased/moved chairs inert; allowing actors to enter chair colliders would require unrelated collision/save exceptions. Reachable feet points plus seated presentation fit the current geometric actors and preserve physical rules.

## Work

- [x] Implement cached SeatCatalog, optional content validation and authored chair/table/policy metadata.
- [x] Implement exclusive reservation/decision lifecycle and integrate visit arrival, purchase, leisure, meetings, route failure and busy furniture rules.
- [x] Add seated visual pose and rotated chair access/direction; keep presentation separate from the canonical access anchor.
- [x] Add revision14→15 migration and validate candidate state atomically.
- [x] Observe live placement/rotation/new chair/store, competition, physical arrival, order continuity, release, save/Continue and bounded costs; build/import/export and inspect actual Web UI.
- [x] One fresh final review, one material fix pass, publish complete pinned Web ZIP and update source preview docs/README.

## Review focus

Duplicate/phantom seat ownership; stale layout/rotation after move/store; pending order preservation when losing a chair; seated pose vs physical feet and saved position; meeting/departure/dialogue priority; route failure retry bounds; no every-frame layout copies/path scans; legacy optional content and revision14 active-dialogue/order saves.
