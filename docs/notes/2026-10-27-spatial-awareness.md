# Observed locations and quiet player meetings

## Shipped behavior

The simulation still knows live poses. `SpatialAwareness` records a visitor's observation only when a player/other visitor is in the same physical location, within range and has a clear ground-space sight segment. The record stores location, observed point and age; unseen movement never refreshes it. Memory expires. No player knowledge/name/story fact is granted merely by seeing someone.

`VisitorMeetings` owns one optional player meeting overlay. Youssef is the first enabled actor, and only when an existing automatic social topic is eligible. Normal arrival counts/population/schedules stay independent. One attempt per visit, at most one active approach globally. The original visit destination is unchanged; the physical controller follows the overlay until it ends. Visible movement can update the goal after a movement threshold/cooldown; hidden movement cannot. After reaching the last observed approach point he waits briefly, then returns to normal visit behavior. All attempts have a total timeout. Existing companionship invitation and Ink handle the actual conversation and consent.

Purchases, pending orders, speech, departure, personal interactions and unreachable routes take priority. Accepted orders are never cancelled by meeting intent. Disabling/removing an actor from the meeting policy cancels an active saved overlay safely; its attempt remains consumed. No fabricated arrival or teleport.

Farid still has existing near-player invitations. His short default visits do not fit the 20–45 second approach delay, so his schedule is not extended to force this experiment.

## Authoring

External `content/visitors.json` is bundled and read on content/session load. No build required for edits; restart/reload the content to apply them. There is no new live-reload control.

| Block / key | Default | Meaning |
|---|---|---|
| `awareness.enabled` | true | Enable observation memory and LOS gate for automatic companionship |
| `awareness.sample_seconds` | 0.5 | Nominal real seconds between each visitor’s scans (staggered across callbacks) |
| `awareness.sight_radius` | 7 | Ground-space range, 360 degrees |
| `awareness.memory_seconds` | 45 | Real seconds until last sighting expires |
| `meetings.enabled` / `actors` | true / `["youssef"]` | Enabled meeting policy and actors |
| `meetings.delay_seconds` | `[20,45]` | Eligible real seconds before considering an approach |
| `meetings.chance` | 0.35 | Deterministic per-visit chance, separate from purchase RNG |
| `meetings.stop_distance` | 1.25 | Desired distance from observed target |
| `meetings.retarget_seconds` / `retarget_distance` | 0.75 / 0.65 | Minimum update interval and observed movement threshold |
| `meetings.max_seconds` | 35 | Maximum active attempt duration |
| `meetings.lost_wait_seconds` | 8 | Wait after reaching a lost target's approach point |

Observer scans are staggered: at most one visitor per callback, approximately one full round per `sample_seconds` at normal frame rates. Low frame rates stretch the sampling interval; expired visibility is not treated as current. Finite segment/rectangle clipping avoids building edge arrays per query.

Goal selection considers up to eight nearby approach points, checking personal space and reachability. Path following remains cached AStarGrid2D with the existing bounded recovery. New counters/spans with `?profile=1`: `spatial_observation`, `meeting_goal`, `meeting_started`, `meeting_finished`. No every-frame path requests just because the player is moving.

## Saves

Schema4/revision14. Revision13 migration adds empty memory/intent without changing poses, destination, clock, money, purchase RNG, Ink state or social receipts. Continue retains remembered positions, ages, attempt flags and active goal. Visibility is transient and reobserved after loading. New records validate references, shapes and finite ranges before candidate publication. Records are pruned after visit removal, so immediate save cannot retain orphan visits. Keep backups when returning to older builds: revision13 builds cannot read revision14.

## Evidence and limits

Evidence lives in `evidence/2026-10-27-spatial-awareness/`. These are bounded native runtime experiments and build/browser observations, not a new automated suite or exhaustive gameplay acceptance.

- Revision13 Continue preserved clock, wallet, purchase RNG and empty initial observations; revision14 active memory/intent roundtrip matched.
- Observed player and peer positions; moved the player to another location at a new point: last seen point and goal stayed unchanged.
- Reached lost goal, waited, finished, resumed original destination; no second attempt. Expiry removed memory.
- A native physical-controller run advanced actual ActorMotor movement for90 physics frames: moved0.65 ground units to within0.10 of the approach goal. After moving the target to another location,600 further physics frames ended the attempt and brought the visitor back within0.087 of the original leisure destination. This is a controlled fixture, not an observed default-probability browser meeting.
- Rectangle and circle occlusion blocked sight. Sampling delayed retargeting; a subsequent visible observation updated the goal.
- Actual physical providers recorded a player; pending service order interrupted optional approach while preserving the order; conversation guard, timeout and unreachable goal ended intent. Layout refresh retained the navigation object and advanced its revision.
- Review found an unsupported-actor saved intent could bypass its timeout by being skipped in the actor loop. Before observation: still active after 100 seconds. After fix: safely inactive immediately on restore; runtime guard also precedes the filter. Current policy edits remain loadable rather than rejecting the entire save.
- In-memory experiments deliberately set chance=1 and short delay to exercise rare paths. Shipping defaults above remain unchanged.
- A four-visitor native observation initially scanned every observer in one burst: 120 batches, max12.8ms. After staggering and allocation reduction, 120 individual observer scans peaked at3.515ms (22.371ms accumulated inside the scan span); these are different work units, not an FPS comparison or equal-work speedup. Player/browser hardware and simultaneous new Ink work remain unmeasured.
- Existing short-run teardown warnings (46/94 ObjectDB instances and 21 resources) remain; this work does not diagnose or claim to fix them.

First visibility model is deliberately conservative: all current ground-space solids, including furniture, block sight. No height/window transparency, facing cone, hearing, reported sightings, home pursuit, general NPC-to-NPC meeting decisions, seat discovery/reservation or local avoidance yet. Other visitors' sightings are stored as a foundation only. A nearby automatic companionship invitation now also requires sight when awareness is enabled; manual conversation behavior is unchanged. No new dialogue text/graph/catalog changes.

An ordinary visit may not produce a meeting: no eligible topic, purchase, short stay, chance, obstruction, other active conversation or player absence can all prevent it. No guaranteed scripted demo arrival, and no general FPS improvement claim.

## Web delivery observation

Product source `8fa96b573146f522463259246c84f8f53c04ebcb`, Godot4.7.2 Release. The build-only gate completed Ink/localization validation, import and export without script/parse/compile errors. Actual Chromium with SwiftShader software WebGL at960×540, dedicated existing QA profile and local origin `http://127.0.0.1:8867/?profile=1`: clicked Continue on genuine previous revision13 save. Wallet45 and active Amgad service dialogue remained present. New `spatial_observation` counters were emitted during normal play; two inspected windows showed33/38 scans with maxima3.4/1.0ms, and one cached path query0.2ms. This cloud software renderer is slow and not a player hardware/FPS comparison. The browser did not demonstrate a natural default-chance Youssef meeting; the controlled native physical run covers that motion/last-seen behavior. No callable gameplay bridge or injected browser save/pose was used.

Saved through the actual menu, waited for filesystem sync, reloaded and clicked Continue again: revision14 save resumed with wallet45, the same Amgad choices and visitor positions present. No page/script errors or save-rejection/fallback warnings were logged; favicon404 was harmless. [Old Continue](evidence/2026-10-27-spatial-awareness/web-continued13.png) · [Saved14](evidence/2026-10-27-spatial-awareness/web-saved14.png) · [Continued14](evidence/2026-10-27-spatial-awareness/web-continued14.png) · [Counter windows](evidence/2026-10-27-spatial-awareness/web-counter-windows.json).

## Published preview

[GitHub prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/spatial-awareness-8fa96b5) · [Pinned complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/12dcdaa4fb5749c2ec5c79786af11936270bbe2f/builds/kiosk-on-the-nile-spatial-awareness.zip). ZIP11928023 bytes, SHA256 `633d37e096ea0ebc1c7ed5171ea7e1b140b6afb42c4d313591094ecfe822ccd4`. Independently downloaded pinned artifact and checked SHA256, ZIP integrity, source/revision metadata, single WASM/PCK, both locale catalogs and shipping Youssef/chance policy. Source preview branch may advance with documentation-only commits; product/export remains `8fa96b573146f522463259246c84f8f53c04ebcb`.
