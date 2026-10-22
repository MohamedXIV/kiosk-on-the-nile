# HTML → Godot parity and evidence

> Port parity is historical evidence, not acceptance of the intended experience.
> [The game vision](GAME_VISION.md), clarified on 2026-10-23, takes priority over
> inherited visitor/service behavior. Independent corniche life, quiet company,
> sustained personal stories, hospitality and social connections remain explicit
> design gaps; the current cooking/shopping cycle does not establish those goals.

Reference: unchanged `kiosk_on_the_nile_2d_three_quarter_top_down.html` at
`705de5ace833b47361ce76b43bf4aad410153df5`. Intended design and execution details:
[spec](superpowers/specs/2026-10-21-godot-html-port-design.md),
[plan](superpowers/plans/2026-10-21-godot-html-port.md).

## Implementation mapping

| Area | Implementation | Acceptance state |
| --- | --- | --- |
| Latest pinned engine, offline Arabic/RTL, real Ink | `tools/setup.sh`, `assets/fonts`, `game/narrative/ink_runtime.gd` | Earlier qualification: native and real Web pending-choice hard reload passed. Latest integration needs regression. |
| Native 3/4 mapping, swept movement and depth sorting | `game/world/actor_motor.gd`, `game/world/spatial_mapping.gd`, `game/presentation/character_view.gd` | Earlier native spatial and browser occlusion qualification passed. Initial-pose fix reviewed statically. |
| Recognizable kiosk/rooftop, props, boat and fan | `content/locations.json`, `game/world/location_view.gd`, `game/presentation/` | Earlier room captures visually compared with HTML. Final lighting/combined gameplay captures pending. |
| Single time frame, causal order, deadlines | `game/time/`, `content/time.json` | Earlier clock/coordinator/scheduler cases passed. Integrated motion/narrative phases need regression. |
| Needs, wallet, rent, sleep and fan state | `game/life/`, `game/economy/`, `content/needs.json`, `content/balance.json` | Earlier life core cases passed. Complete new service/home action chain remains unverified. |
| Manual tea and kebda, quality, sugar and held items | `game/cooking/`, `content/recipes.json` | Cooking cases exist; newest restore/next-recipe corrections have not been rerun. |
| Quoted orders, exactly-once delivery, purchases | `game/service/`, `game/life/life_actions.gd` | Implemented; end-to-end regression pending. |
| Amgad first, football pair, quiet day-two window, ambient visitors | `game/actors/`, `content/visitors.json` | Implemented; arrival-race fix and navigation integration reviewed statically. Timing/complete-day acceptance pending. |
| Repeat memory and real paid quality | `VisitorService.record_service`, `ServiceSystem.settled` | Implemented through settlement signal; complete chain pending. |
| Independent spoken dialogue, optional football join, replies | `content/stories/`, `game/narrative/narrative_director.gd` | Real sources compile. Runtime concurrency and final text/choice acceptance pending. |
| Knowledge/hidden directional relationships and gates | `knowledge_book.gd`, `relationship_store.gd`, `condition_evaluator.gd`, `content/encounters.json` | Implemented; familiarity conditional text and known-fan variants authored. Integration coverage pending. |
| Versioned whole-session save, candidate load, backup | `game/persistence/` | Implemented with envelope/Ink integrity checks. Real complete-game native/Web resume acceptance pending. |
| Title/New/Continue, Arabic HUD, notebook, input and fades | `game/app/main.tscn`, `game/ui/`, `game/world/location_transition.gd` | Title launches. Actual interaction, compact viewport and reload acceptance pending. |
| Isolated systems check | `game/ui/diagnostics.gd` | Disposable session/Ink owners, no player save store. Runtime action acceptance pending. |
| Audio layers, steam/smoke, warm pools and time shading | `content/atmosphere.json`, `soundscape.gd`, `station_vapour.gd`, `warm_light.gd`, `atmosphere.gd` | Original PCM generated. Subjective listening and final scene comparison pending. |
| External data independent of engine builds | `ContentStore`, feature validators, native `--content-dir`, Web sidecar | Earlier time-rate sidecar replacement passed. New definition domains need regression. |
| Developer probe and release isolation | `game/app/qa_probe.gd`, debug routing in `main.gd` | Implemented; release behavior/browser inspection pending. |

## What the latest integration does and does not establish

Native import, compilation of authored Ink and Web export are build evidence.
The independent static review identified and prompted fixes to motor setup,
football arrival ordering, missing cross-feature validation, exported-audio
resource lookup, focus mute, diagnostics, camera smoothing and content URL
resolution. Static review does not replace playing the build.

No new gameplay acceptance suites or browser scenarios were added or run during
the latest integration pass. In particular, do not infer a passing full-day
routine, exactly-once settlement after reload, safe rejected complete saves,
compact UI geometry, audible parity or full visual parity from older isolated
qualification results.

## Remaining acceptance work

1. Native complete-day and two-day fan-referral/service/sleep paths, including
   insufficient funds, wrong/departed orders and duplicate requests.
2. Whole-session round-trip during cooking and concurrent pending Ink choices;
   corrupt/future/story-incompatible files, failed writes, backup recovery and
   deferred saves across a fade.
3. Real keyboard/browser gameplay followed by a hard reload on the same origin,
   including storage-unavailable behavior and completed browser filesystem sync.
4. Source/Godot captures for both rooms afternoon/night, active stations, the
   football speakers, counter occlusion and owned fan; review 960×540, 1280×720
   and 1920×1080, then listen to contextual layers and cues.
5. Release browser interaction with QA parameters ignored, external tuning/Ink
   replacement, station/visitor variants and a repeatable CI acceptance gate. The existing
   GitHub workflow currently covers compilation/import/release export only.

The prototype remains untouched. Experimental Web ZIPs are published as GitHub prereleases; this is not a main-branch merge or a hosted deployment.

## Approved sleep/mood update — 2026-10-22

The player explicitly replaced the prototype sleep contract: 1–12 selected
hours, calendar rollover at midnight, no extra rent for same-day naps, recovery
proportional to sleep duration, bounded mood/rest-based oversleep with a visible
preview, and a mood modifier on preparation quality. These are intentional
changes to HTML parity.

`MoodPolicy` reads `content/wellbeing.json`; `DailyRoutine` handles waking and
once-per-day rent; `NeedsService` applies hourly recovery. `SleepPanel` supplies
the duration and preview. Cooking captures its mood penalty on starting a job,
persists it, and applies it to the technique result when the food is prepared.
Unattended cooking and both clock domains consume elapsed sleep time; visitors
and their orders end before the skip while same-day encounter flags persist.

Save schema 2 records rent assessment and job modifiers. `SaveMigrations` reads
schema 1 without writing or charging on load. `StableJson` normalizes JSON number
types and preserves floating-point precision for persistent checksums. The old
checksum issue was reproduced as a version-1 save rejection plus a format probe:
Godot stringifies an integer as `1` and its JSON-parsed value as `1.0`. Legacy
files are verified against the exact original compact payload before upgrading;
legacy displayed Ink frames recover their declared numeric types for validation.

Existing daily-life assertions were adapted to the approved sleep signature and
calendar result. No automated suites were added or run in this update. Current
manual browser observations and any remaining acceptance limits are recorded in
`docs/notes/2026-10-22-playtest-feedback.md`.

## Approved social/HUD follow-up — 2026-10-22

Tracked daily visit quotas and time windows, four additional named visitors,
actual paid-service memories, persistent Ink topic consumption and rotating
authored lines intentionally replace the prototype's repeated random visitors
and endlessly restartable topics. A compact top status strip and contextual
footer replace the tall left HUD. Schema 3 migrates older saves and retains
previous compiled Ink for already-open matching sessions. Design sources,
external content knobs, manual observations and limits are recorded in
[the social follow-up notes](notes/2026-10-22-social-visitors-and-hud.md).
Full multi-day pacing and complete-game acceptance remain separate.


## Living spaces extension — 2026-10-22

The approved extension is implemented with canonical item identities, venue storage,
shared player/editor grid rules, developer-only structure authoring, world-running
shopping journeys and confirmed catalogue purchases. Equipment capabilities feed
world-minute workflows: real cold-marinated shawarma batches and finite slicing,
assembly and alternative fried/baked potatoes. Farid's Ink reads actual learning
evidence. Hygiene captures food contact at preparation; customer summaries use
observed surroundings, actual food and service wait to derive reputation.
Schema 4/revision 4 migrates earlier saves and retains matching archived Ink.

Manual evidence includes arrangement/save/Continue, a confirmed market purchase,
new Farid teaching and a source-backed dirt comment, running cooking/customers
during a shop journey, and actual schema-3 held food + active tea + pending Ink
Continue/reply. The continued manual cycle also covered real cold preparation, all three slices,
partial batch Continue, same-ID surface transfers, assembly and paid shawarma
service, interrupted cleaning Continue/resume and dirty-bed recovery. Interactive
editor authoring and adversarial geometry/default multi-day acceptance remain open. See [the evidence and limits](notes/2026-10-22-living-spaces-d.md).
