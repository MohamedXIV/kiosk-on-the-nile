# Kiosk on the Nile: modular Godot port

> Vision clarification, 2026-10-23: [GAME_VISION](../../GAME_VISION.md) governs
> experience and pacing. This document records the historical port scope. HTML
> behavior does not override independent corniche life, quiet companionship,
> character relationships, knowledge or mutual help.

Date: 2026-10-21

Status: written design approved by the user on 2026-10-21; implementation authorized 2026-10-21 with the review amendments below.

## 1. Agreed outcome and authority

Rebuild the current HTML experience as a maintainable Godot game. Preserve its three-quarter top-down presentation, Arabic content, atmosphere, controls, cooking, social encounters and home–kiosk loop. Use real Ink-authored dialogue from the first playable version. Future features must fit clear component boundaries without expanding one central gameplay script.

The behavioral and visual reference is `kiosk_on_the_nile_2d_three_quarter_top_down.html` at repository commit `705de5ace833b47361ce76b43bf4aad410153df5`. Keep that file intact as a comparison reference.

The vision and experience documents in `MohamedXIV/nile-kiosk` explain the broader intent: a quiet Egyptian life, familiar people, satisfying work and modest comfort. Its application code, module structure, event-sourcing architecture, implementation milestones and previously deferred localization decisions are not templates for this port. HTML supplies the historical presentation and spatial reference for this milestone; its balance and social behavior are subordinate to the owner's latest game vision.

Success means a player can recognize and play the HTML experience in Godot, including its small atmospheric details. A runnable set of abstract systems or a room containing placeholder circles does not satisfy the port.

## 2. Scope and parity contract

| Area | Required behavior in the first complete port |
| --- | --- |
| Entry and controls | Arabic title and invitation to start; WASD/arrows movement, E primary interaction, F secondary action/personal consumption, N notebook; mouse-operated UI. |
| Rooftop room | Current room composition, bed, desk/snack, rug, exit, warm lighting; fan appears after purchase and visibly spins/oscillates when running. |
| Kiosk and river | Current kiosk layout and right-side access, counter, shelves, telephone, sign, kettle, grill, stools, outdoor table, railing, streetlamp, water shimmer, moving felucca and its lantern/reflection. |
| Spatial play | Smooth follow camera, current relative character/prop scale, directional characters, walk animation, ground shadows, held tray/item, grounded depth sorting and solid furniture. |
| Daily life | Start day 1 at 15:30 in the rooftop room; travel, open/close freely, return home and sleep into the next day at 15:00; daily rent and current insufficient-rent behavior. |
| Needs | Hunger, rest and mood HUD, current decay and consumption effects, hidden wellbeing baseline and current fan-assisted sleep result. Preserve the prototype balance rather than importing the reference project's newer needs model. |
| Tea | Empty → heating → boiled → brewing → ready → poured; three sugar settings, stock use, busy-hands rejection, timing-dependent quality, station status and spatial gauge. |
| Kebda | Empty → first side → second side → seasoned → sandwich; manual flip/season/assemble actions, early-flip rejection, stock use, current quality thresholds and grill feedback. |
| Service | One held item, matching order/type validation, paid delivery once, quality-dependent tip, customer response and personal consumption with F. |
| Supply and home purchase | Telephone buys four tea and four kebda portions for EGP 15; learned referral unlocks the EGP 35 used fan; insufficient funds and duplicate purchase are handled. |
| Visitors | Uncle Amgad, Mahmoud and Samir; Hasan, Nadia and the non-buying passerby; current arrival destinations, orders, lingering, ambient remarks and departure behavior. |
| Memory and knowledge | Amgad's repeat visits and last served quality; day-two fan referral; unique knowledge and notebook entries; persistent home ownership/use. |
| Conversation | Existing Arabic greetings, repeat-visit recognition, service reactions, ambient remarks, player replies and football debate are authored in Ink. Work and movement continue during conversation. |
| Pacing | Current spawn priorities, football encounter after 17:00, and day-two 19:00–20:15 ambient-spawn quiet window. The quiet window does not erase existing visitors or cancel authored encounters. |
| Presentation | Warm dark HUD, Arabic labels, needs bars, time/money/stock, notebook, save feedback, short notifications, speech at speakers and cooking feedback at stations; afternoon/night changes, steam and smoke. |
| Audio | Procedural river, kettle, sizzling and fan layers; contextual fades, interaction chimes, pour cue and payment cue. No external streaming or licensed soundtrack dependency. |
| Diagnostics | The systems-check action remains available, but operates on isolated fixtures and never changes the active game or its save. |

The initial resource data preserves the HTML's starting EGP 45, EGP 15 rent, stock 6/5, needs 80/90/75, baseline 70, tea price EGP 5, sandwich price EGP 12 and quality tips EGP 0/1/3. Fan-assisted sleep retains the current baseline 82/rest 100 behavior. These are port defaults, not a claim of final balancing.

New recipes, a housing upgrade, markets, vehicles, furniture rearrangement, sophisticated social simulation, AI dialogue, a different projection and a new art pipeline are later features. Their possible existence informs boundaries without adding their implementation now.

## 3. Architecture choice

Three viable approaches were considered:

| Approach | Strength | Cost | Decision |
| --- | --- | --- | --- |
| Godot scene scripts own gameplay directly | Straightforward editor authoring and low initial plumbing | Shared rules and saves become coupled to scene lifetimes | Use for presentation and physical components, not cross-scene gameplay ownership. |
| Feature modules with explicit dependencies, native scenes and typed state | Rules survive scene changes; features can be tested and extended separately | Requires small controllers and explicit composition | Selected. |
| Custom ECS or event-sourced world framework | Useful for large-scale simulation or comprehensive historical replay | Introduces framework, tooling and migration work beyond this port | Not required for this scope. |

Build feature modules, not a generalized game framework. Prefer composition, normal typed method calls and local typed signals. A dependency must be visible in construction/configuration. Avoid a global event bus, service locator, per-feature autoloads and an application-wide string-command dispatcher.

`GameSession` is the lifetime/composition owner. It creates the clock, feature services and state, binds their dependencies, coordinates new/load/save and connects scenes. It must not implement recipes, price rules, NPC behavior or dialogue internally. A small root application scene retains the session across location changes; no singleton is necessary for that lifetime.

## 4. Modules and ownership

| Module | Owns | Dependencies and public interactions |
| --- | --- | --- |
| Life | World day/time, needs, sleep and home fan state/use | Receives simulation delta; calls the economy for rent; exposes read-only readings and validated life actions. |
| Economy | Integer money balance and atomic affordability/payment operations | Receives authored prices; accepts purchase/settlement requests; reports typed success/failure. |
| Cooking | Ingredient quantities, station jobs, stage progress, quality and prepared/held items | Reads recipe definitions; accepts stage actions and delta; emits completion/status changes. |
| Service | NPC order lifecycle and exactly-once delivery/payment | Validates a cooked item against an order; coordinates cooking, economy and visitor memory. |
| Actors | Visitor identity, visit lifecycle, destinations, order intention and memory | Uses life time, service outcomes and authored encounter definitions; requests movement and narrative episodes. |
| Narrative | Ink runtime adaptation, individual conversation sessions, line timing, choices and knowledge/notes | Reads an explicit world context; routes a finite set of allowed effects into the owning feature. |
| World | Location scenes, physical movement, navigation, interaction selection and camera | Reads session state and calls feature APIs through small controllers; never owns money/recipe/dialogue truth. |
| Presentation | Actor/prop visuals, HUD, spatial captions, VFX and contextual sound | Receives state/read models and local signals; cannot grant items, charge money or advance recipes. |
| Persistence | Save schema, validation, serialization and native/Web storage | Collects/restores feature snapshots through the session; contains no gameplay rules. |

Each piece of mutable state has one owner. For example, a kettle view reads the cooking job; it cannot maintain a second cooking timer. An Ink variable may expose a copy of a game fact for a condition; it cannot become a second authoritative knowledge store.

Cross-feature actions are explicit small transactions. Serving validates the waiting order and held item before consuming it, pays once, closes the order and records visitor memory. Buying stock validates payment and applies both quantities together. UI and dialogue call these same paths. Rejected actions leave the participating state unchanged.

## 5. Project organization and authoring

Use a feature-oriented layout, independently designed for this port:

```text
project.godot
game/
  app/          # entry scene, composition and session lifecycle
  life/
  economy/
  cooking/
  service/
  actors/
  narrative/
  world/        # location scenes, movement and interaction components
  presentation/ # reusable actor/prop visuals, lighting and audio
  ui/
  persistence/
content/
  balance/
  recipes/
  characters/
  encounters/
  locations/
  stories/      # authored .ink sources and generated story assets
assets/fonts/   # bundled Arabic font files and licenses
addons/inkgd/   # upstream dependency, isolated from game code
tools/
tests/
docs/
```

A feature keeps its scripts, scenes and resource classes together when they serve the same feature. Shared presentation components exist only when there is an actual shared use. Do not create a base class or interface for every file.

Use typed GDScript, `RefCounted` runtime state/services where scene access is unnecessary, and typed read models loaded from external JSON for authored configuration. Treat definitions as immutable: create separate runtime instances for mutable jobs, visitors and sessions. Stable content IDs are used in saves; node paths and live Resource/Node references are not serialized.

Recipes describe their actual required steps, timings, sugar options and quality parameters. A small explicit step/action vocabulary supports the two current foods; adding an ordinary recipe should be data work, while a genuinely new cooking action adds a focused handler. Avoid a generic scripting language for recipes.

Represent money as integer piastres internally and display EGP. The defaults above retain identical player-visible amounts. Store balance, tuning and layout in authored resources rather than distributing constants through UI and controllers.

## 6. Spatial and visual contract

Keep the HTML's axis-aligned three-quarter projection. This is not a switch to diamond-isometric rendering. The baseline mapping is 68 pixels per logical X unit, 54 per logical ground-depth unit and 48 per height unit at camera zoom 1. Camera framing follows the current center/54%-height composition.

A single spatial-mapping component owns conversions. Actor foot position determines depth; height only offsets visual children. Ground coordinates, elevation, screen coordinates and UI coordinates remain distinct. Use native `CharacterBody2D`, collision shapes and Y sorting, with projected footprints derived consistently from location definitions. Do not nonuniformly scale a physics hierarchy to fake the projection.

The movement adapter commits the actual physics result to the actor pose. Interactions, captions, hearing checks that already exist, saved positions and visuals consume that same pose. A hidden second movement simulation cannot disagree with the visible character. Preserve logical movement speed and diagonal normalization through the mapping. NPC routes use Godot pathfinding around the actual solid furniture, with approach markers at valid service/lingering spots.

Match the source layout and room scale in this milestone, including its existing rooftop dimensions; do not substitute the older reference project's 24 m² plan. Keep NPC arrival lanes separate from the narrower player movement bounds: source NPCs arrive at X ±14.5 while the player is restricted near X ±9.5.

Recreate the current procedural visual language in small Godot visual scenes/components: character, oblique prop, kettle, grill, fan, river, boat and location dressing. Polygon/drawing components are acceptable final parity assets for this milestone. Their anchor, silhouette and state-driven appearance should allow later Sprite2D replacement without changing gameplay. Do not put the entire world into a single large `_draw()` script.

Use Godot-native particles, lights/modulation and shaders only as needed to match the source smoke, shimmer and warm light pools. Retain visible depth occlusion at the counter. The phone, grill, tea, fan and sign must visibly correspond to their real state. Compare both rooms in afternoon/evening at a common viewport, with additional widescreen and compact-window checks. Automated gameplay success does not establish visual equivalence.

## 7. Ink integration

Use Godot Standard 4.7.2, GDScript, Compatibility rendering, official inklecate 1.2.1 and upstream `ephread/inkgd`'s Godot-4 implementation. Start qualification with pinned commit `fea9098ee18d6cdbe9a5e25f8f0296bcdf0fd96a`, identified in the reference project's compatibility report; verify it in this project. Record exact versions and verify downloaded compiler archives against an authoritative checksum. The upstream Godot-4 branch lacks a formal stable release, so native and browser qualification is an early gate, not an assumed result.

Only the narrative adapter imports plugin types. Other modules see application-owned line, speaker, choice and session records. The Ink compiler runs during setup/build and authoring, never as a player-runtime requirement. Keep reproducible compiled story JSON available to exports, and check that generated content matches the authored sources. Preserve third-party licenses separately from original game code.

Move the existing spoken content and player replies into authored Ink: Amgad first/repeat visits, order/service remarks, fan referral, Mahmoud/Samir's football exchange and ambient visitor remarks. Group stories by coherent encounter; avoid a separate runtime per individual bark. UI action labels and station status strings remain localized presentation content rather than narrative programs.

Each active encounter has its own Ink story/session. An encounter involving two people still has one narrative session with explicit speaker tags. A presenter follows the tagged speaker's actual pose and displays lines for the authored duration. Several encounters can coexist without sharing a single mutable Ink cursor.

Expose only explicit world queries and a finite tag/effect vocabulary: speaker identity, line duration, allowed interjection boundary, note/knowledge acquisition and the current mood consequences. A tag cannot execute arbitrary GDScript or name an unrestricted method. Ink does not spawn visitors, cook food, award payment or purchase the fan; those remain feature actions.

At authored boundaries, synchronize the needed day/visit/quality/fact context. Validate that participants and choices are still applicable before accepting a choice. Apply knowledge and note effects once per causal occurrence, including across save/load. A new player-initiated conversation can still have the source's repeatable response effects; deduplication must not suppress a genuinely new encounter.

Retain the source's football participation range and ordinary same-location speech presentation. More elaborate privacy, line-of-sight hearing or familiarity gates from the reference vision are not newly required mechanics. A choice panel does not stop movement, world time or cooking; one visible choice panel has explicit focus, and another encounter cannot silently replace it. NPC background conversation may continue while an unselected optional interjection expires into its authored listening branch. Player-initiated choices remain available until chosen, cancelled or their participants leave.

Persist the actual Ink runtime state together with encounter IDs, participants, current line/duration, offered choice context and applied-effect IDs. Include a story content revision/hash. A save whose story assets are incompatible reports that clearly rather than loading a cursor into unrelated content. Changing narrative content later requires an explicit migration or a documented safe session reset.

## 8. Time, transitions and persistence

One session simulation step drives feature updates using fixed-physics delta. Keep units explicit: the prototype advances 2.5 game minutes per real simulation second; cooking, walking, visit durations and dialogue pauses use simulation seconds. A presentation animation cannot advance world time. Inject controllable time and seeded random sources into tests; cosmetic randomness is separate from visitor randomness.

The title screen does not run the simulation. During play, the notebook captures gameplay action keys without silently pausing the world; conversation choices leave movement available. Location fades have an input lock and commit each transition once. Preserve cooking progress while away from the kiosk and across sleep, as the current continuously updated station behavior permits. Sleeping clears held food, resets the day encounter flags and clears visitors as in the HTML.

Use a versioned JSON save envelope composed from feature snapshots. Include day/time, location/player pose, money, needs/baseline, ingredients, held item, station stages/timers/options, home state, knowledge/notes, NPC identities/poses/lifecycle/orders/memory, spawn countdown/RNG state, daily encounter flags and narrative sessions. Complete a simulation step before taking a snapshot; do not save half of a service transaction or fade transition.

Validate a save fully into a candidate session before replacing the current one. Use temporary-write/replace and a recoverable previous save on native platforms. Use Godot's supported `user://` browser persistence and verify actual IndexedDB-backed reload behavior. Do not report persistent success in a browser context that cannot retain user storage. Corrupt/incompatible saves produce an understandable message and never overwrite themselves automatically. The menu offers new game and continue where a valid save exists; preserve the existing manual save action.

The old HTML localStorage format is not imported in this milestone. Native and Web builds use the same logical schema, while browser storage persistence remains dependent on the browser/profile/origin.

## 9. Deliberate implementation cleanups

These corrections preserve the intended experience while removing prototype limitations:

- Full resume, including mid-cook and pending Ink choice, rather than the HTML's partial state dump and unwired normal-load path.
- Simulation starts on entering play, not behind the title screen.
- Navigation respects furniture; NPCs do not walk straight through solid objects.
- Input actions trigger deliberately rather than duplicating interactions from keyboard auto-repeat or modal click-through.
- Active dialogue choices have explicit lifetime/focus instead of being overwritten by the next spawned conversation.
- The diagnostics action uses disposable fixtures/storage, not the player's live save or notifications.
- Fonts ship with the game, removing a Google Fonts runtime dependency; Arabic shaping, mixed Arabic/numbers/Latin labels, RTL containers and viewport wrapping are checked in the actual game.

Other balance or behavior changes require a separately identified decision. In particular, do not replace current mood/fan formulas, invent rent debt, add a recipe progression ladder or fill every quiet interval with customers.

## 10. Failure handling and extensibility checks

Return typed action outcomes for insufficient funds/stock, busy hands, invalid stage, wrong order, unavailable participant and invalid choice. UI renders those outcomes and audio reacts afterward. Expected rejection must not leave partially consumed resources.

Missing required definitions, unknown Ink effects and invalid story IDs fail visibly in development and are checked before export. A narrative failure ends or suspends that encounter with a useful diagnostic while leaving the ordinary game loop usable. Save failures retain the previous good save and report failure instead of success.

Extensibility is demonstrated concretely: add a second resource instance of a cooking station; vary a recipe's timings without editing its UI; add a visitor/ambient encounter through definitions and Ink; change a price through balance data; swap an actor visual without changing service rules. A fundamentally new mechanic can require a new handler. Unlimited zero-code extensibility is not promised.

## 11. Acceptance and delivery sequence

Build in dependency order while retaining the complete parity matrix as the delivery target:

1. Qualify the pinned Godot/Ink toolchain on native and real Web runtime: compile a real story, render Arabic, continue/select and restore a pending choice.
2. Establish session composition, data definitions, spatial mapping, physical movement, both recognizable location scenes and HUD/interaction presentation.
3. Integrate clock/needs/economy, the two tactile cooking jobs, service, supplier and home actions with their real visuals and feedback.
4. Integrate visitors, memory, all authored Ink encounters, optional participation and source pacing.
5. Complete combined persistence, title/continue behavior, procedural sound, atmosphere and parity review. Individual steps above do not constitute the completed port.

Meaningful automated checks cover a successful and rejected purchase, on-time/late/burnt cooking, stock depletion and occupied hands, exactly-once paid service, the repeat-visit → knowledge → paid fan → sleep chain, day/quiet-window rules, independent conversations while cooking, and complete save/restore during cooking and a pending Ink choice without duplicate effects.

Native scene checks exercise collision/interaction/actor positions. Web checks use actual exported gameplay in a browser, keyboard actions and a real reload; exporting or opening a port alone is insufficient. Compare current-run outcomes and preserve command exit codes. Keep isolated diagnostics separate from normal player storage.

Capture the unchanged HTML and Godot at comparable scene/time/viewport states for both rooms, with the counter in front of/behind the player, visible cooking, an NPC exchange, the moving boat and fan state. Screenshots can be reviewed here; final visual/audio feel requires user review and is distinct from automated test results.

## 12. Review and next step

This document defines the whole port, not its detailed task-by-task execution plan. The user approved this written design on 2026-10-21. Write the implementation plan against this parity matrix, obtain its review and execution-method selection, then implement and verify the complete selected scope. No product scaffolding or dependency installation has been performed as part of this design step.


## Authorized review amendments — 2026-10-21

These user changes supersede older Resource-authoring paths and the simpler clock above. Execution is authorized; no additional design gate is pending.

1. **Latest stable engine:** Godot 4.7.2, confirmed via the official godotengine/godot-builds latest stable release API. Pin it and matching templates with official asset digests; qualify actual Ink/native/Web behavior before accepting compatibility.
2. **Data independent of builds:** Store balance, initial state, needs, clock rate, recipes/quality, actors, schedules, location/prop layout, interaction definitions, UI/localization, audio mix and dialogue eligibility as JSON under content/. Replace .tres authoring deliverables with corresponding .json data. ContentStore loads the bundled default or an external --content-dir bundle; Web exports deploy a sidecar content/ directory fetched from the same origin. Validate a complete candidate before activation; reload at the title/session boundary, never halfway through a transaction. Existing behavior handlers stay in typed GDScript; a new behavior may require code. Ink compilation produces replaceable story JSON without rebuilding Godot. Content fingerprints protect saved active stories/jobs from incompatible data.
3. **Independent shared time and dependency order:** game/time/game_clock.gd publishes one authoritative frame (tick, simulation seconds, day and world minutes). simulation_coordinator.gd validates and topologically orders registered systems using allowlisted IDs and declared dependencies. Reject missing dependencies/cycles before play. world_scheduler.gd stores stable due jobs with explicit clock domains, prerequisites, deadline and status; blocked jobs remain visible/retryable or expire, never freeze world time or execute ahead of prerequisites. Bootstrap also has a readiness barrier. Cooking, visits, needs and narrative use this shared step; presentation time remains noncanonical.
4. **Knowledge and relationship foundation:** Canonical KnowledgeBook and hidden directional RelationshipStore feed a finite ConditionEvaluator: all/any/not, fact_known, relationship_at_least, visit_count_at_least, day_at_least, time_window, participants_available and distance_at_most. Validate all IDs/operators/thresholds. Narrative context exposes read-only canonical queries/projections to real Ink. Gate encounter starts, optional interjections and offered choices; revalidate at selection and after load. Default content preserves HTML encounters while tests exercise knowledgeable/unknown and familiar/unfamiliar variants. Persist relations, fact provenance and pending conditions; no visible friendship meter or invented progression grind.

Implementation mapping: Task 1 adds ContentStore/JSON reload tests and latest-engine qualification; Task 2 adds game/time coordinator/scheduler with dependency-cycle, prerequisite and deterministic-order tests; Task 8 adds RelationshipStore/ConditionEvaluator plus real conditional Ink tests; Task 9 persists those additions; Task 12 verifies external JSON and compiled Ink changes take effect without an engine rebuild. UI .tscn and reusable code-only visual scenes remain native Godot assets; gameplay definitions and all tuning values live in JSON.
