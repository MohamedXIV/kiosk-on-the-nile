# Dynamic chairs and visitor seating

## Behavior

Seats are derived from actual placed item instances. Moving or rotating an empty chair changes its access point and sitting direction; a newly owned/placed chair uses the same definition automatically. A visitor independently decides whether to seek a seat, reserves an available slot before walking, and sits after reaching its clear access point. Other visitors cannot reserve the same slot. A nearby table can be associated with a chair; a table is optional for this first sitting/drink prototype.

VisitorSeating owns reservations and per-visit decisions; SeatCatalog owns cached derived geometry. Ink still owns conversations and ServiceSystem owns orders and payment. A visitor with a seat can request/await service there. Moving/storing/disappearing furniture does not cancel an accepted order. An order placed without a seat is not silently relocated to a new one.

Occupied chairs and their associated table cannot be moved, stored or cleaned under a sitter. Empty reservations may move and their destination follows; removing one releases it. Social approach releases the chair; after the meeting the person has an ordinary leisure destination and may seek another available seat after cooldown. Departure, sleep and removal release/prune reservations. If no chair or route is available, standing is valid; nobody is spawned to demonstrate a seat.

## Physical and visual position

ActorPose remains a reachable locomotion/collision access anchor outside solid furniture. When seated, CharacterView smoothly places hips/torso over the authored seat and draws bent knees, nearby visual feet and shadow relative to it. The collision/access anchor is intentionally separate from the seated visual feet. No actor is teleported into a collider, and the existing navigation/physical save checks still apply. Idle blinking/breathing remain. This is a geometric placeholder sitting pose, not a finished animation/art set. Captions and order badges use the seat anchor when seated; interaction/hearing retain the collision/access point.

The grid placement system is unchanged. The catalog can derive seats in either physical location; visitor seating currently runs for corniche/kiosk visitors. Player sitting and residential guest seating are not implemented in this slice. Local NPC avoidance remains a separate next step; AStarGrid2D is retained.

## Authoring

Bundled external JSON loads offline on content/session load. Reload after edits; no new live-reload control.

`content/items.json` supports a furniture `seats` array (up to8 slots). The chair ships with:

```json
{"id":"seat","access":[0,0.6],"anchor":[0,0],"facing":[0,1],"height":0.45,"table_radius":2.0}
```

Offsets are ground units relative to the footprint center at rotation0, then rotated with placement in quarter turns. `access` is the clear locomotion/collision point, `anchor` is the seat center, `height` is sitting surface height. Stable identity is `<item instance>:<slot id>`. A furniture definition with `gathering_surface:true` can be associated as the nearest table in range. Chairs need no per-instance marker or character binding. The existing table/standing markers remain valid standing alternatives.

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

- Two visitors reserved different slots with purchase RNG unchanged; physical ActorMotor movement reached both access points and set seated state, with collision anchors outside furniture.
- Production SpaceService placement moved an unoccupied reserved chair and rotated another; destinations and facing followed the derived slot. Occupied chair move/store was rejected with the existing localized busy reason.
- Actual VisitorService purchase decision while seated switched to `approaching` at the same seat, then `requesting` and emitted `service_request`; owner `accept_request` created the pending order. The existing Ink delivery interface is reused.
- Pending order stayed at a seated visitor's access point. Revision15 roundtrip preserved seating and pending order; revision14 migration preserved wallet/clock/purchase RNG/order and added empty seating state.
- Duplicate reservation restore was rejected. Released chair could be stored. An owned-item grant plus production placement (not a browser shopping acceptance) discovered a new chair instance without marker bindings.
- Moving an empty table near that chair associated it; a physical sitter then made table storage busy. Explicit seat release preserved the pending order. Clearing visits emptied seating state.600 cached catalog reads caused0 rebuilds.
- One fresh final review found the hygiene busy callback did not include seated furniture: a dirty occupied chair accepted cleaning before the fix, then rejected it with `equipment_busy` after the fix. The callback now includes seating without including its own active cleaning status (which would self-interrupt). An approaching reservation yields if cleaning starts first; the controlled run confirmed release, standing fallback and continued cleaning.
- Authoring requires the seated radius to lie between the path follower stopping radius and the visit arrival radius. Smaller values could stop just before sitting; larger values could sit/pause before the visit registers arrival. Both invalid boundaries were rejected in the controlled observation.
- Headless short-run teardown warnings99 ObjectDB instances /23 resources were observed. Prior fixtures reported94/21 with different session/object counts; no leak improvement or diagnosis is claimed here.

`?profile=1` adds `seat_catalog`, `seat_search`, `seat_reserved` and `seat_released` spans/counters. Existing spatial/Ink/path diagnostics remain. No universal FPS improvement or exhaustive layout/social/order acceptance claim.

## Web observations

Godot4.7.2 Release, Chromium with SwiftShader software WebGL at960×540 and a dedicated QA profile. The ordinary preview at `http://127.0.0.1:8867/?profile=1` opened the genuine previous revision14 save with wallet45 and Amgad's active choices. Actual menu Save, reload and Continue resumed revision15 with wallet/choices/visitor positions present. This began on product80ef915; final70afef0 adds only authoring-radius validation (default gameplay/geometry unchanged). Final-code checks and the controlled visible pose are recorded below. No browser gameplay command bridge or injected browser save/pose was used.

The separate visual fixture at port8869 copies external JSON only: seed17/capacity2, short arrivals, west spawning, Nadia/Hassan weights100 (others0.01), their availability windows0–1440 and stay120, purchase0, all seating chance1/delay0.5, kiosk start(-6.5,1.8), chair1 moved and chair2 rotated. The fixture uses the final70afef0 engine code. Its accelerated scheduling is never packaged as shipping data. The final2ab7f73 product corrects the initial pose’s long-looking legs by deriving bent thighs/lower legs and the shadow from the sitting surface elevation; canonical collision/movement/save state is unchanged.

The final2ab7f73 controlled Web image shows both a forward-facing sitter and a rotated side-facing sitter on their actual chairs; knees/feet/shadow are placed at the sitting surface rather than stretched to the access collider. [Seated/rotated pose](evidence/2026-10-27-dynamic-seating/web-seated-rotated.png) · [Initial pose before correction](evidence/2026-10-27-dynamic-seating/web-pose-before.png). The collider is still at the clear access anchor; this deliberate visual separation is a placeholder-art compromise, not full sitting physics/animation.

The ordinary final2ab7f73 export at port8867 also opened the saved revision15 session through actual Continue, with wallet45 and the same Amgad choices present. No page/script errors or save rejection/fallback warnings were logged. [Revision14 Continue](evidence/2026-10-27-dynamic-seating/web-continued14.png) · [Saved15](evidence/2026-10-27-dynamic-seating/web-saved15.png) · [Final Continue15](evidence/2026-10-27-dynamic-seating/web-final-continued15.png). Native physical/request/order/migration observations were rerun on final2ab7f73 as well. Software rendering/controlled fixture evidence does not establish player-hardware FPS or exhaustive furniture/social coverage.

## Published preview

[GitHub prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/dynamic-seating-2ab7f73) · [Pinned complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/17177907446518a126f01da12e6c911cbb863b3f/builds/kiosk-on-the-nile-dynamic-seating.zip). ZIP12231543 bytes, SHA256 `e6956774a60da86d5065ae61c4876366b9cc1af0e57101bf688abb03fa2be3e1`. Independently downloaded pinned artifact and checked SHA256, ZIP integrity, source/revision metadata, single WASM/PCK, both locale catalogs, evidence and ordinary shipping policy/start/layout (not the visual fixture). Source preview branch may advance with documentation-only commits; product/export remains `2ab7f731a332f2e5b6178870bad8f379c222608a`.
