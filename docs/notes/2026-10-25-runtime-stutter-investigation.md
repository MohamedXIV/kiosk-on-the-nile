# Runtime stutter: initial source investigation

2026-10-25 (Africa/Cairo). Source baseline: `03f9391` (product `0ea4572`).

## Scope and evidence limits

Player reports intermittent hangs/frame drops, more noticeable after recent additions. This pass traces current code, not the older pre-localization audit. No gameplay code changed and no automated tests or runtime benchmarks ran. Findings below establish repeated or synchronous work, **not measured attribution of the player's stalls**. Real GPU/browser traces remain required. Earlier cloud SwiftShader timings are not a player hardware baseline.

## Candidates in order of investigation

| Path | Established source behavior | Expected distinguishing observation |
| --- | --- | --- |
| `Main._physics_process` → `Soundscape.present` → `RecipeWorkflow.snapshot` | Every physics tick deep-copies all workflow jobs, including their definitions/evidence, to find active heat sources. No visible audio change is required. Snapshot includes retained completed jobs. | CPU cost increases with retained job count; compare a fresh session with a genuine older save. |
| `Main._physics_process` → `InteractionRouter.nearest`, `Hud.present`, `StatusStrip.present` | Reconstructs targets, formats translated prompts and inventory/status text each physics tick. Some target checks inspect possible narrative topics. Label setters may avoid unchanged text internally, but application queries/formatting still run. | Compare idle/movement, kiosk/rooftop and active personal conversation; time router and HUD separately. |
| `Hud.present` → `PersonalConversations.view` → `InteractionJournal.entries` | While a personal conversation exists, scans entire journal for its chapter, copies matching entries, then retains only two preceding events. Cost scales with total history even when the displayed beat is unchanged. | Same conversation beat with different journal sizes; inspect projection time, not only Ink continuation. |
| `LocationView._process`, `HygieneView._process`, `EquipmentView._process` | Setting a room invisible does not disable its processing. Both room views keep polling; hygiene/equipment nodes request redraw each frame. Equipment copies its active job; its draw reads a copied atmosphere section. | Compare presentation CPU time with invisible-room processing disabled in an isolated measurement, without disabling world simulation. |
| `InnerMonologue._speak`, `InkRuntime.open` | A thought copies/stringifies/hashes story JSON, constructs a new player and creates a story. Ink player explicitly uses `loads_in_background = false`; awaiting its loaded signal does not move that construction off the main thread. Ordinary story starts share this creation boundary. | Stall aligns with thought appearance or first story beat; distinguish story open, advance and UI layout timings. |
| `SaveCoordinator.save_at_boundary` → `SaveStore.write` | Explicit/deferred save synchronously encodes, normalizes/stringifies, writes/reads back and validates existing save before replacement/backup, then requests Web filesystem sync. Boundary polling alone does **not** save every tick. | Stall aligns with save request/deferred completion and scales with save size. No evidence of periodic autosave here. |
| `FatigueOverlay` / `fatigue_blur.gdshader` | When visible, a full-screen screen-texture effect samples five times per pixel. Visibility is driven by fatigue pulses. | Compare same scene/resolution at fatigue visual scales 1 and 0; correlate with pulse. This is a GPU hypothesis, not evidence the effect is broken. |

## Web-specific context

Both Web export presets explicitly set `variant/thread_support=false`. This does not mean every browser subsystem runs on one thread, but game-side synchronous work can occupy the browser's main thread. Browser/GPU/driver, viewport resolution and background tab behavior matter. A native comparison on the **same machine**, same content/save and comparable resolution is useful; Web overhead alone cannot explain a particular recurring hang. Offline bundled localization has no translation network request; its repeated presentation work can still cost CPU.

## Next measurement pass

### Player follow-up: prioritize actor transitions

Player reports stalls while stationary, especially when characters enter the scene or begin an action, movement or speech. Walking can coincide but is not necessary; dialogue correlation is less certain. Browser/device remain unspecified. This makes actor transitions the first capture target, ahead of generic walking/rendering load.

The traced boundaries are distinct:

- **Physical spawn:** `VisitorService.spawn` creates visit data. On the next `VisitorController.step`, a new `ActorMotor` and `CharacterView` are attached/configured and a path is calculated.
- **Destination change:** `VisitorController.step` calls `KioskNavigation.path` only when the destination changes. The AStar grid is built in location configuration; it is **not rebuilt for every visitor spawn or movement tick**. Profile path lookup separately from node/physics/render setup.
- **Arrival at destination:** `VisitorService._arrived` emits an encounter request. The encounter handler may reach `NarrativeDirector.start`, creating a fresh Ink runtime, constructing its story and advancing its first beat. Physical entry and narrative arrival must have separate timestamps; they need not occur in the same frame.
- **Subsequent speech:** measure `NarrativeDirector._advance` and caption/dialogue control creation/layout, separately from story initialization. Do not infer that every spoken line constructs another story.

Capture visitor ID, transition type and story/encounter ID alongside bounded durations, without writing full actor/history snapshots every frame. Correlate stalled frames to spawn, destination change, arrival, story open, first beat and caption creation. Node setup, pathfinding and synchronous Ink construction are candidates, not confirmed measured culprits. Do not reduce the authored population, slow the simulation or remove conversations as a workaround.

1. Capture Release Web on player-class hardware: browser/OS/GPU, viewport, build identity, save age/job/history size. Record warm idle, movement, first dialogue beat, subsequent beat, thoughts, notebook and explicit save separately. Include a cold start separately from steady state.
2. Use browser Performance recording with frame intervals/long tasks and Godot CPU/GPU profiling where supported. Instrument bounded aggregate durations around session tick, router, HUD/captions, audio projection, story creation/advance, save encode/write. Avoid per-frame logging, whole-state serialization or a callable gameplay debug bridge in the measured release.
3. Report p50/p95/p99/max frame interval, stalls above 50/100/250 ms and corresponding action/time. A 60 Hz target has approximately 16.7 ms per frame; an average FPS alone hides spikes. Browser frame intervals do not alone identify GDScript versus GPU cost.
4. Change one confirmed source at a time. Likely narrow remedies: active-workflow audio query; revision/beat-keyed dialogue view; cached immutable presentation definitions; visibility-gated rendering queries; cached compiled story definitions. Preserve world simulation outside the visible room, defensive save/transaction copies, Ink cursor/effect ownership and history semantics. Do not pool/reset live Ink cursors casually or enable threads as a blanket fix.
5. Repeat the identical measurement and genuine-save behavior checks before claiming a gain. No frame-rate improvement or resolved player hang is claimed by this source-only report.
