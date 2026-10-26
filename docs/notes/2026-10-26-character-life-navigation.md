# Character life and bounded navigation recovery

2026-10-26, Africa/Cairo. Baseline `abf3a11`. Implements the approved quiet idle/navigation/leisure proposal on Godot4.7.2; AStarGrid2D remains the path planner.

## Runtime ownership

`CharacterIdle` owns cosmetic breathing/blinking/micro gaze and its private RNG; `CharacterView` advances/draws it on render callbacks only while visible in the scene tree. Feet remain anchored during breathing; head/torso/held item move subtly. Actual simulation ActorPose/facing is not modified. It is not a full skeletal animation/art replacement; characters facing away may naturally have no visible eyes. Hidden-room animation timers pause rather than catching up. Input/world time policy is unchanged.

`NpcNavigation` is the transient follower shared by VisitorController and ResidentialController. It calculates a path only for a new destination, layout revision or a bounded recovery attempt, replacing residential per-physics-step pathfinding. Actual progress toward successive waypoints resets its stall timer. Conversation pauses stop motion and reset stall accumulation; intentional arrival is not treated as failure. After2seconds without progress, retries use0.75seconds cooldown, maximum2 replans beyond the initial path. Empty/truncated routes are refused, not treated as arrived. After exhaustion an owner can request up to2 valid alternative goals per actor/layout. No per-frame retry loop, teleport or fabricated arrival. If no accessible alternative exists, the actor waits for a layout/destination change. A completely sealed exit cannot be made traversable by pathfinding.

Visitors may choose another reachable/unoccupied leisure marker or exit; only an unplaced purchase approach may be abandoned. Existing orders are not cancelled by recovery. Residential visitors use authored standing/exit alternatives. Layout rebuilds invalidate both follower types through the navigation revision. ActorMotor only advances its walk cycle when physical movement actually occurs; collision no longer displays walking in place indefinitely. Waypoint tolerance respects domain arrival thresholds, including legacy content without new navigation settings.

`QuietLeisure` changes a settled visitor's leisure destination rarely: default30–65game-minute interval,30% chance at a check, at most1 move per visit and5.5ground-unit displacement. It only runs for undecided/declined, stationary visits without a pending order or conversation. Authored marker availability and a valid complete route are checked first. It does not add people, orders or arrival/speech events. Purchase/conversation RNG remains independent; schedule variation uses visit-specific deterministic hashes. It is a small policy, not a general behavior tree or crowd avoidance system. Actors still use the existing collision policy toward other actors.

## Data and persistence

- `content/spatial.json`: `character.idle` timings/amplitudes, `navigation` progress/recovery limits.
- `content/visitors.json`: `leisure` interval/chance/cap/distance/markers.
- `content/residential_visits.json`: standing/exit alternatives.
- Optional blocks are validated when supplied; old external content may omit them. Content changes apply at content/session load, not through a new live-reload feature.
- Save schema stays4, revision advances12→13. Migration initializes an empty leisure schedule while preserving existing positions/destinations, clocks, wallet, knowledge and gameplay RNG. New saves persist leisure countdown/check/move/marker data; cosmetic and follower runtime state stay transient and start afresh on load. Revision13 saves are not promised to open in older revision12 builds; retain backups when switching back.

## Bounded observations and review

Native headless runtime observations, not an automated gameplay suite:

- Simulated60seconds intentional idle/paused: no path queries/failure; normal route1 query. Unmodelled collision and impossible route: exactly3 queries, attempts2, failure reported once, no further loop. Removing obstruction and incrementing layout revision resumed movement. Blocked walk phase became0.
- Simulated60seconds cosmetic progression:11 blinks in the recorded run, breathing within±0.85pixels; separate gameplay RNG unchanged. This is a timing/state observation, not evidence of every browser draw.
- Revision12 candidate restored with clock/wallet/RNG preserved. Revision13 round trip preserved leisure schedule and destination. A forced in-memory policy exercised a reachable leisure change without consuming purchase RNG; shipping defaults were not accelerated.
- One fresh independent final code review identified2 material issues. Departure previously left an orphan leisure record between removal and next tick; reproduced save rejection before fix and successful0-visit/0-schedule restore after fix. Legacy domain arrival0.1 could stop at0.12 without optional settings; derived stopping radius and finer waypoint tolerance now reach valid0.1 and0.05 domain thresholds in the observation.
- Both issues addressed in one fix pass; no re-review. Build/import/Ink/localization/export gate completed without script errors. No automated gameplay tests/suites were added or run. Native early-exit resource/ObjectDB warnings remain undiagnosed, as in previous observations.

[Evidence](evidence/2026-10-26-character-life/). Default recovery counts/timing are demonstrated on controlled fixtures; actual player layouts, all orders/social branches and every legacy save are not exhaustively qualified. Physical blocker changes need a matching navigation/layout refresh to retry an exhausted route; ordinary arrangement changes provide it.

## Diagnostics

Existing `?profile=1` reports now include `npc_path` durations and zero-duration event counters `character_blink`, `npc_route_exhausted`, `npc_route_fallback`. Event counters are counts, not CPU-duration/FPS measurements. Profiling remains off with the ordinary URL. No callable game-state bridge was added.


## Actual Web observations and delivery

Final product `c1c799770aa9434c50f3332e95194d7d20b35791`, Godot4.7.2 Release. Chromium/SwiftShader,960×540, persistent dedicated QA profile at the same local origin used by the previous runtime preview. Actual mouse/keyboard Continue restored the genuine previous revision12 save into the new content; player position/wallet remained present and world time resumed. Captured raw browser clips show both open and closed player eyes while standing. Cosmetic blink event counts appeared alongside normal simulation/path observations. Saved through the actual menu, allowed filesystem sync time, reloaded and Continue resumed the revision13 session as well. No game-state/pose injection or callable game command bridge was used.

[Legacy Continue](evidence/2026-10-26-character-life/web-legacy-continue.png) · [Eyes closed](evidence/2026-10-26-character-life/web-blink-closed.png) · [Eyes open](evidence/2026-10-26-character-life/web-blink-open.png) · [Saved13](evidence/2026-10-26-character-life/web-saved13.png) · [Continued13](evidence/2026-10-26-character-life/web-continued13.png) · [Selected counter windows](evidence/2026-10-26-character-life/web-counter-windows.json).

This is visual/state-path coverage, not a controlled GPU benchmark or an FPS improvement claim. The software renderer became slow during the long capture/screenshot burst; one full screenshot exceeded its30second capture timeout and a retry succeeded while simulation continued. No page/script errors or save fallback/rejection warnings were logged. Actual residential fallback, every pending-order/furniture arrangement, default-probability leisure relocation and controller/high-FPS behavior were not exhaustively exercised through browser UI; domain/follower fixtures and fresh code review provide the bounded evidence described above.

[GitHub prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/character-life-c1c7997) · [Pinned complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/2d69935e3ee7a5086e072edc7d2ab96d43cfc36a/builds/kiosk-on-the-nile-character-life.zip). ZIP11915073bytes, SHA256 `7d7205bf32aa74afa3f5800678ce5ec270419306c43a20a3136d7eeda2474685`. Independently downloaded pinned artifact and checked SHA256, ZIP integrity, source/revision metadata, single WASM/PCK and both locale catalogs. Source preview branch may advance with documentation-only commits; product/export stays c1c7997. No main merge.
