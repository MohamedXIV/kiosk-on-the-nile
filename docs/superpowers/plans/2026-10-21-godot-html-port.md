# Modular Godot HTML Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking. Execution: Native, authorized 2026-10-21 with the four review amendments below.

**Goal:** Deliver the existing Arabic three-quarter HTML game in Godot, with its recognizable presentation and complete gameplay loop, modular features, real Ink conversations and reliable native/Web resume.

**Architecture:** Compose typed feature services inside a retained session and bind them to native Godot scenes through small controllers. Feature owners expose explicit actions and snapshots; visuals read their state. Ink owns authored narrative flow, while gameplay services own its consequences.

**Tech Stack:** Godot Standard 4.7.2, typed GDScript, Compatibility renderer, inklecate 1.2.1, pinned Godot-4 inkgd, custom Godot headless test runner, Playwright 1.62.1 and Chromium for Web verification.

**Spec:** `docs/superpowers/specs/2026-10-21-godot-html-port-design.md` — approved 2026-10-21. Read it and the unchanged HTML before implementing. This is one cohesive port plan: its feature deliverables are separately testable, but share transaction, session and save interfaces and are not independent product projects.

## Global Constraints

- Preserve `kiosk_on_the_nile_2d_three_quarter_top_down.html` at `705de5ace833b47361ce76b43bf4aad410153df5` intact as the visual and behavioral reference.
- Godot Standard 4.7.2, GDScript, Compatibility rendering, official inklecate 1.2.1; begin qualification with upstream `ephread/inkgd` commit `fea9098ee18d6cdbe9a5e25f8f0296bcdf0fd96a`.
- Preserve the HTML's three-quarter mapping: 68 pixels/logical X unit, 54 pixels/ground-depth unit, 48 pixels/height unit at zoom 1, center/54%-height camera framing.
- Initial EGP 45, rent EGP 15, stock 6/5, needs 80/90/75, baseline 70, tea EGP 5, kebda EGP 12, quality tips EGP 0/1/3; internal money is integer piastres.
- World time advances 2.5 game minutes per simulation second; cooking, dialogue and visits use simulation seconds. One session simulation step drives feature updates using fixed-physics delta.
- Preserve day 1 15:30 rooftop entry, next-day 15:00 sleep result, existing fan-assisted baseline 82/rest 100, source encounter priorities and day-two quiet window.
- Each piece of mutable state has one owner. Authoring data is external validated JSON; typed runtime records are separate and read-only to consumers. Serialize stable IDs and values, never Nodes or live Resources.
- Only the narrative adapter imports plugin types. Real `.ink` sources provide all spoken narrative and player replies; gameplay services apply validated effects.
- Arabic, RTL and bundled fonts are required now. The game works offline after assets load; no Google Fonts, AI provider or streaming dependency.
- Do not copy application code or module structure from `MohamedXIV/nile-kiosk`; do not import its event-sourced world architecture, alternative balance or deferred Arabic policy.
- Keep the implementation feature-oriented. No global string-command bus, service locator, custom ECS, unnecessary autoloads or monolithic world-drawing script.
- Retain the current checkout in the already isolated cloud workspace. Do not create a worktree unless the user explicitly requests one.
- Keep secrets out of files/output. Dependency installation preserves TLS, package signatures and authoritative checksums; use writable caches rather than changing protected system locations.
- Stop for diagnosis if an early Ink/native/Web qualification fails. Do not substitute a fake narrative engine or describe exported-but-unplayed Web builds as verified.

## Review Focus

1. A repeated E press or duplicate delivery after reload must not charge, grant or pay twice; pin this in Tasks 6, 9 and 10.
2. A corrupt, truncated, future-version or story-incompatible save must leave the good session and previous save intact; pin this in Task 9.
3. An unknown Ink tag, stale choice or departing speaker must not crash the game, execute arbitrary methods or leak a choice into another encounter; pin this in Tasks 1 and 8.
4. Mixed Arabic/Latin/numerals and a compact viewport must retain shaping, order, wrapping and operable controls; pin this in Tasks 1, 10 and 12.
5. Lost window focus, a long frame, title-screen idle or a save during transition must not fast-forward cooking unpredictably or snapshot half a transition; pin this in Tasks 2, 9 and 10.

## File and interface map

Paths below are relative to the checkout. Every task lists exact additions and existing files it may change. Scripts in feature directories have the matching `class_name` used in their Interfaces blocks, except leaf views which need not be globally named. Each feature service implements `snapshot() -> Dictionary` and `restore(data: Dictionary) -> ActionResult`; restore validates into a candidate and leaves the receiver unchanged on rejection.

| Area | Responsibility | Tasks |
| --- | --- | --- |
| `game/app/` | Action outcomes, config/session composition, entry and read-only development probe | 1, 2, 10 |
| `game/life/`, `game/economy/` | Clock, needs, home actions, wallet | 2, 6 |
| `game/world/`, `game/presentation/` | Mapping, movement, location scenes and reusable visuals | 3, 4, 5, 11 |
| `game/cooking/`, `game/service/` | Recipe/station runtime and validated settlement/supply | 5, 6 |
| `game/actors/`, `game/narrative/` | Visits, orders/memory, actual Ink sessions, effects and notes | 1, 2, 7, 8 |
| `game/persistence/`, `game/ui/` | Candidate-load/commit, storage, Arabic HUD/input | 9, 10 |
| `content/`, `assets/` | Authored definitions, original Ink, compiled stories, licensed fonts and generated sound | By consuming task |
| `tools/`, `tests/`, `.github/workflows/` | Repeatable setup/build and meaningful native/browser checks | 1, 12 |

`ActionResult` is the shared action value: `ok: bool`, `code: Code`, `message_key: StringName`, `details: Dictionary`. Define codes `OK`, `INSUFFICIENT_FUNDS`, `OUT_OF_STOCK`, `HANDS_BUSY`, `TOO_EARLY`, `INVALID_STAGE`, `WRONG_ORDER`, `NOT_AVAILABLE`, `INVALID_CHOICE`, `INVALID_CONTENT`, `INVALID_SAVE`, `IO_ERROR`. `success(details = {})` and `failure(code, message_key, details = {})` construct it. Use typed values inside features and dictionaries at context/snapshot boundaries.

`SessionConfig` is a typed runtime projection of a validated external JSON bundle. Add feature definition fields as their types are introduced, preserving `GameSession.configure(config: SessionConfig) -> ActionResult`. `GameSession` starts inactive; `start_new()` enables simulation only after setup is complete. Later tasks extend its composition without moving their rules into it.

Test commands assume the runner created in Task 1: `godot --headless --path . --script res://tests/run.gd -- --suite <name>`. Each suite returns nonzero on any failed assertion and reports executed counts. `--suite all` discovers only implemented suites. Run Godot import after introducing globally named classes. `TestCheck` in `tests/support/check.gd` provides `equal(actual, expected)`, `near(actual, expected, epsilon = 0.00001)` and `is_true(value)` and records case/assertion failures; failed GDScript assertions alone must not accidentally leave the runner successful. Inject temporary absolute storage roots under `/tmp` into fixtures, and give browser tests a fresh isolated profile/origin. Godot 4.7.2 has no `--user-data-dir` CLI option; do not invent one. The assertions below show the essential expectations after arranging the named fixture.

### Task 1: Qualify real Ink, Arabic and browser runtime

**Files:** Create `project.godot`, `export_presets.cfg`, `.gitignore`, `tools/setup.sh`, `tools/dependencies.lock.json`, `tools/compile-ink.sh`, `tools/export-web.sh`, `tools/package.json`, `tools/package-lock.json`, `tools/web/serve.py`, `tools/web/check.mjs`, `game/app/action_result.gd`, `game/narrative/story_definition.gd`, `game/narrative/narrative_types.gd`, `game/narrative/ink_runtime.gd`, `tests/run.gd`, `tests/support/check.gd`, `tests/qualification/ink_boot.tscn`, `tests/qualification/ink_boot.gd`, `tests/test_ink_runtime.gd`, `tests/fixtures/qualification.ink`, `tests/fixtures/qualification.ink.json`, `assets/fonts/Cairo.ttf`, `assets/fonts/OFL.txt`. Install the pinned upstream dependency under `addons/inkgd/` with its license; do not edit upstream internals.

**Interfaces:** `StoryDefinition` has `id: StringName`, `source_path: String`, `compiled_path: String`, `sha256: String`. `NarrativeTypes.Frame` contains `result: ActionResult`, `text: String`, `speaker_id: StringName`, `duration: float`, `effects: Array[Dictionary]`, `choices: Array[Dictionary]`, `ended: bool`. `InkRuntime extends Node`: asynchronous `open(definition: StoryDefinition, context: Dictionary) -> ActionResult`, `advance() -> NarrativeTypes.Frame`, `choose(index: int) -> ActionResult`, `snapshot() -> Dictionary`, `restore(data: Dictionary) -> ActionResult`. Initialization completes before advance/restore; only this adapter references upstream types. A choice record has stable session-local `id`, `index` and `text`. Invalid metadata is reported through `Frame.result`, with no effects emitted.

- [x] **Step 1 — Write qualification failures:** Bootstrap the small runner and test scene alongside project settings. Add `test_pending_choice_resume` which opens real compiled Ink, advances to two choices, snapshots/recreates the adapter and asserts the choices match; choose once and assert an authored Arabic reply, not a hardcoded application reply. Add `test_invalid_choice_and_unknown_tag` asserting negative/out-of-range choices do not advance and unsupported metadata produces `INVALID_CONTENT`.

  ```gdscript
  check.equal(frame.choices.size(), 2)
  check.equal(restored_frame.choices, frame.choices)
  check.equal(runtime.choose(-1).code, ActionResult.Code.INVALID_CHOICE)
  check.equal(unknown_tag_frame.result.code, ActionResult.Code.INVALID_CONTENT)
  ```
- [x] **Step 2 — Record red:** Run `godot --headless --editor --path . --import`, then the `ink_runtime` suite. Expected red is a missing adapter/dependency or failed real-story assertions, not an unrelated syntax error in the runner. Keep the output and diagnose import issues separately.
- [x] **Step 3 — Implement the qualification deliverable:** Pin the exact tool versions above and Playwright 1.62.1 with npm lockfile. Setup uses writable caches, installs Godot/templates only if the pinned versions are absent, obtains the official compiler asset and authoritative digest, and records the digest before verifying/unpacking. Use `npm ci`. Compile the fixture and load it through the adapter. Bundle Cairo from its licensed upstream font repository. The browser scenario `ink` shows mixed text `كشك ع النيل — E — 45 ج.م`, selects a real choice and restores its saved runtime after an actual reload. Keep this qualification scene separate from the eventual game entry.
- [x] **Step 4 — Verify:** Run `bash tools/setup.sh` twice, the `ink_runtime` suite, `bash tools/compile-ink.sh --check`, `bash tools/export-web.sh --out /tmp/kiosk-port-web`, and `node tools/web/check.mjs --build /tmp/kiosk-port-web --scenario ink`. Expect nonzero test counts, native PASS and `INK_BROWSER_PASS`, with a current Arabic screenshot and real reload evidence. If the browser persistently reports unavailable storage, record a blocker rather than weakening the test.
- [x] **Step 5 — Commit:** Stage only Task 1 paths and verified dependency/license files; commit `build: qualify Godot Ink and Arabic on native and Web`.

### Task 2: Own daily life, money and shared session state

**Files:** Create `game/app/session_config.gd`, `game/app/game_session.gd`, `game/life/game_clock.gd`, `game/life/needs_service.gd`, `game/life/home_service.gd`, `game/economy/balance_definition.gd`, `game/economy/wallet_service.gd`, `game/narrative/knowledge_book.gd`, `content/balance/html_defaults.tres`, `tests/test_daily_life.gd`. Modify `tests/run.gd` for suite registration if required.

**Interfaces:** `GameClock`: `day: int`, `minutes: float`, `advance(delta: float)`, `next_day()`. `WalletService`: `balance: int`, `try_spend(amount: int) -> ActionResult`, `credit(amount: int) -> ActionResult`. `NeedsService`: `hunger/rest/mood/baseline: float`, `tick(delta: float, kiosk_open: bool)`, `apply_delta(hunger: float, rest: float, mood: float)`, `after_sleep(fan_running: bool)`. `HomeService`: `has_fan/fan_on: bool`, `toggle_fan() -> ActionResult`, `install_fan() -> ActionResult`. `KnowledgeBook`: `has(fact: StringName) -> bool`, `learn(fact: StringName, note: String) -> bool`, `notes() -> PackedStringArray`. `GameSession`: `configure(config)`, `start_new()`, `tick(delta: float)`, `running: bool`, `location_id: StringName`, `kiosk_open: bool`, `player_ground: Vector2`, and owned `clock: GameClock`, `wallet: WalletService`, `needs: NeedsService`, `home: HomeService`, `knowledge: KnowledgeBook`. Later tasks add typed `cooking`, `service`, `supply`, `life_actions`, `visitors` and `narrative` fields as their classes are introduced. IDs are `rooftop` and `kiosk`.

- [x] **Step 1 — Write failures:** `test_initial_day_and_inactive_title` asserts day 1, minutes 930, balance 4500, needs 80/90/75 and no advancement before start; after one active second assert minutes 932.5, hunger 79.72 and rest 89.85 while closed. `test_rent_and_fan_sleep` asserts next day 900 minutes, a 1500-piastre rent debit, baseline 82/rest 100 with a running installed fan; an insufficient balance is retained without invented debt. `test_money_rejects_negative_and_failed_spend_is_atomic` asserts rejection leaves balance unchanged. `test_unique_knowledge` asserts one fact/note per learned ID.

  ```gdscript
  check.equal(session.clock.day, 1)
  check.near(session.clock.minutes, 932.5) # after one active second
  check.equal(session.wallet.balance, 4500)
  check.near(session.needs.hunger, 79.72)
  check.near(session.needs.rest, 89.85)
  ```
- [x] **Step 2 — Record red:** Run the `daily_life` suite; expect assertions/classes missing, preserving the earlier Ink result.
- [x] **Step 3 — Implement:** Create immutable balance defaults and separate runtime services using the HTML formulas, including hunger/rest clamps, low-needs mood decay, EGP 3 snack effects and existing sleep formulas. `GameSession.tick` calls only the composed services when running; it does not own their calculations. UI/focus loss will use fixed steps rather than wall-clock catch-up. Add snapshot/restore with rejection of nonfinite/negative invalid state.
- [x] **Step 4 — Verify:** Run `daily_life` and `ink_runtime`. Add a ten-minute simulated routine with a seeded time source and assert the sum of executed fixed steps, not elapsed wall time; title idle remains unchanged. All actual executed cases must pass.
- [x] **Step 5 — Commit:** Stage Task 2 files; commit `feat: add authoritative daily life and wallet services`.

### Task 3: Establish ground mapping, physical movement and character presentation

**Files:** Create `game/world/spatial_mapping.gd`, `game/world/actor_motor.gd`, `game/world/interaction_target.gd`, `game/world/interaction_selector.gd`, `game/actors/actor_pose.gd`, `game/presentation/character_view.gd`, `game/presentation/character_view.tscn`, `game/presentation/held_item_view.gd`, `tests/test_spatial.gd`, `tests/fixtures/spatial_room.tscn`. Modify `game/app/game_session.gd` only to accept the authoritative player pose update.

**Interfaces:** `SpatialMapping.to_canvas(ground: Vector2, height: float = 0.0) -> Vector2`, `to_ground(canvas: Vector2) -> Vector2`; fixed scales 68/54/48. `ActorPose`: `location_id: StringName`, logical `ground: Vector2`, `facing: Vector2` and `walk_phase: float`. `GameSession.player_pose` becomes the player pose owner; its existing location/ground properties delegate to that pose rather than duplicating storage. `ActorMotor extends CharacterBody2D`: `configure(mapping: SpatialMapping, speed: float)`, `step_input(direction: Vector2, delta: float)`, `step_path(path: PackedVector2Array, delta: float)`, signal `pose_changed(pose: ActorPose)`. `InteractionTarget` is a runtime value with stable ID, logical anchor, radius and computed primary/secondary availability. `InteractionSelector.nearest(ground: Vector2, targets: Array[InteractionTarget]) -> InteractionTarget`. `CharacterView.present(pose: ActorPose, color: Color, is_player: bool)`; `HeldItemView.present(item: Variant)` accepts a presentation record initially and is narrowed to `PreparedItem` in Task 5, with null hiding it.

- [ ] **Step 1 — Write failures:** `test_projection_round_trip` asserts `(1,2), height 1` maps to `(68,60)` and ground mapping round-trips at zero height. `test_normalized_speed_and_collision` moves cardinally/diagonally at 4.5 logical units/sec and asserts a body cannot cross a solid test counter. `test_nearest_available_target` checks source-style nearest selection and out-of-range rejection. `test_caption_pose_uses_physics_result` compares the committed pose to the actual body position converted through the mapping after sliding.

  ```gdscript
  check.equal(mapping.to_canvas(Vector2(1, 2), 1.0), Vector2(68, 60))
  check.equal(mapping.to_ground(Vector2(68, 108)), Vector2(1, 2))
  check.near(diagonal_ground_distance, 4.5) # one unobstructed second
  check.equal(committed_pose.ground, mapping.to_ground(motor.position))
  ```
- [ ] **Step 2 — Record red:** Run the `spatial` suite on an actual SceneTree with physics frames; a geometric mock alone is insufficient.
- [ ] **Step 3 — Implement:** Use native bodies and unscaled collision hierarchies in the projected plane, with actor visuals offset above the foot anchor. Define the ground pose update once after physics and use it everywhere. Recreate the source's torso/head/legs, apron, directional eyes and shadow as a small component; future art replacement preserves its foot anchor. Use Y sorting, not hand-maintained per-frame global z indices.
- [ ] **Step 4 — Verify:** Run `spatial` and earlier native suites. Capture the fixture with a character both behind and in front of the counter; assert unchanged collision placement and correct Y-sort ordering, then inspect the image.
- [ ] **Step 5 — Commit:** Stage Task 3 paths; commit `feat: add grounded movement and reusable character presentation`.

### Task 4: Build both recognizable locations and contextual interaction points

**Files:** Create `game/world/location_definition.gd`, `game/world/location_view.gd`, `game/world/kiosk.tscn`, `game/world/rooftop.tscn`, `game/world/kiosk_navigation.gd`, `game/presentation/oblique_prop.gd`, `game/presentation/oblique_prop.tscn`, `game/presentation/kettle_view.gd`, `game/presentation/grill_view.gd`, `game/presentation/fan_view.gd`, `game/presentation/river_view.gd`, `game/presentation/boat_view.gd`, `content/locations/kiosk.tres`, `content/locations/rooftop.tres`, `tests/test_locations.gd`. Modify `game/world/interaction_target.gd` for authored prompt keys.

**Interfaces:** `LocationDefinition` provides ground bounds, solid footprints, prop definitions, spawn/approach markers and typed interaction definitions. `LocationView.configure(definition: LocationDefinition, session: GameSession)`, `interaction_targets() -> Array[InteractionTarget]`. `KioskNavigation.configure(definition, mapping)`, `path(start: Vector2, goal: Vector2) -> PackedVector2Array`. Visual components receive presentation values rather than invoking services. Kettle/grill/fan expose `present(state: Dictionary)` until feature-specific typed views are wired.

- [ ] **Step 1 — Write failures:** `test_rooftop_and_kiosk_markers` checks source bed `(-1.65,-1.2)`, exit `(0,2.05)`, tea `(-1.3,0.65)`, grill `(0.35,0.65)` and phone `(-1.95,-1.15)`. `test_counter_right_access_and_furniture` tests the passable right opening and solid counter/bed/desk/table. `test_visitor_lanes_are_not_player_bounds` asserts valid routes from X ±14.5 while the player retains X ±9.5 limits.

  ```gdscript
  check.equal(kiosk_definition.marker(&"tea"), Vector2(-1.3, 0.65))
  check.equal(rooftop_definition.marker(&"exit"), Vector2(0, 2.05))
  check.is_true(navigation.path(Vector2(-14.5, 3.6), counter_approach).size() > 1)
  check.is_true(counter_blocked and right_opening_reachable)
  ```
- [ ] **Step 2 — Record red:** Run `locations`; expect missing definitions/scenes or failed physical routes.
- [ ] **Step 3 — Implement:** Read the HTML's source layout/draw routines to reproduce both scene compositions with independent prop components, the current rooftop floor from X -3 to 3 and depth -2.2 to 2.25, counter at depth 0.7 and the listed source destinations. `LocationDefinition.marker(id: StringName) -> Vector2` resolves logical anchors. Keep both rooms retained, with kiosk root at canvas origin and rooftop root offset by `(4096,0)` pixels, so hidden NPC physics can continue without colliding with the player in another room; logical coordinates remain room-local. Share footprints between native colliders and AStarGrid2D navigation; provide actor clearance and reachable approach points. Draw the river, boat, railing, streetlamp, shelves, phone, sign, rug, desk, bed, stools and table. Camera follows with the specified offset/smoothing. Fan visibility reads home ownership.
- [ ] **Step 4 — Verify:** Run `locations` and `spatial`. Capture both locations at a common 1280×720 viewport and inspect relative character scale, prop readability and counter occlusion against the HTML. These scenes must already be recognizable before proceeding to the integrated product.
- [ ] **Step 5 — Commit:** Stage Task 4 paths; commit `feat: recreate kiosk and rooftop locations with solid navigation`.

### Task 5: Implement tactile cooking, held food and deterministic quality

**Files:** Create `game/cooking/recipe_definition.gd`, `game/cooking/station_definition.gd`, `game/cooking/cooking_job.gd`, `game/cooking/prepared_item.gd`, `game/cooking/cooking_service.gd`, `game/cooking/tea_rules.gd`, `game/cooking/kebda_rules.gd`, `game/cooking/station_controller.gd`, `content/recipes/tea.tres`, `content/recipes/kebda.tres`, `content/recipes/tea_station.tres`, `content/recipes/kebda_station.tres`, `tests/test_cooking.gd`. Modify `game/app/session_config.gd`, `game/app/game_session.gd`, `game/presentation/held_item_view.gd`, `game/presentation/kettle_view.gd`, `game/presentation/grill_view.gd` and both location scenes to bind actual jobs.

**Interfaces:** `RecipeDefinition` has `id`, `rules_id`, `food_id`, `ingredient_id` as StringNames, `portion_cost: int`, and typed exported timing/quality parameters. `StationDefinition` has `id: StringName`, `recipe: RecipeDefinition`; configuration holds `Array[StationDefinition]`. `PreparedItem`: `id: StringName`, `food_id: StringName`, `sugar_id: StringName`, `quality_score: int`, `quality_key: StringName`. `CookingJob` contains station/recipe IDs, stage, stage timers and options. `CookingService.act(station_id: StringName) -> ActionResult`, `cycle_sugar(station_id: StringName) -> ActionResult`, `tick(delta: float)`, `job(station_id: StringName) -> CookingJob`, `held_item() -> PreparedItem`, `take_held(expected_id: StringName) -> PreparedItem`, `restock(tea: int, kebda: int)`. Item IDs use a saved monotonic counter. `StationController` routes actions and reads job status; no scene timer owns cooking.

- [ ] **Step 1 — Write failures:** `test_good_tea` heats 3.5 seconds, starts brewing, advances 3 seconds and pours score 3; sugar cycles `مظبوط → زيادة → سادة`. `test_tea_overbrewed` checks brew timers above 8.5/12 give scores 2/1. `test_good_kebda` cooks side A/B for 3 seconds each, seasons and assembles score 3; `test_early_flip_and_burnt` rejects a flip before 1.8 seconds without mutation and gives score 0 beyond total 15. `test_out_of_stock_and_busy_hands` asserts no stock loss on rejected actions and no duplicate items.

  ```gdscript
  check.equal(good_tea.quality_score, 3)
  check.equal(overbrewed_tea.quality_score, 1) # brew timer above 12
  check.equal(early_flip.code, ActionResult.Code.TOO_EARLY)
  check.equal(burnt_kebda.quality_score, 0)
  check.equal(rejected_snapshot, before_action_snapshot)
  ```
- [ ] **Step 2 — Record red:** Run `cooking`; confirm each recipe's success and failure assertions actually execute.
- [ ] **Step 3 — Implement:** Preserve the source stage transitions, thresholds and consumption moments. Tea reaches boiled at 3.2 seconds, brewing readiness at 2.5 seconds, and uses the same cumulative brew timer after readiness; quality is 3 through 8.5 seconds, 2 above 8.5 through 12, 1 above 12. Stock is spent on starting the brew and sugar resets to مظبوط after pouring. Kebda stock is spent on starting side A; score 0 if total time exceeds 15, otherwise 3 if side A is 2.2–7 and side B is 1.8–7 and seasoned, otherwise 2 if total is 3.5–12.5, otherwise 1. Use authored recipe families with focused tea/kebda rules and separate jobs; definition data can vary timings without editing UI. Keep cooking ticking when another location is shown. Bind real item/tray and station visuals/status.
- [ ] **Step 4 — Verify:** Run `cooking` and native regressions. Add a second tea station using another resource instance and assert independent jobs share the intended stock but not mutable definition state. Restore a job at mid-brew using its snapshot and assert matching completion/quality.
- [ ] **Step 5 — Commit:** Stage Task 5 paths; commit `feat: add tactile tea and kebda cooking with real item state`.

### Task 6: Make service, supplies and home actions transactional

**Files:** Create `game/service/order_state.gd`, `game/service/service_system.gd`, `game/service/supply_service.gd`, `game/life/life_actions.gd`, `tests/test_service_and_home.gd`. Modify `game/app/session_config.gd`, `game/app/game_session.gd` and the relevant world interaction bindings.

**Interfaces:** `OrderState`: ID, visit ID, food ID, status and delivered item ID. `ServiceSystem.configure(wallet: WalletService, cooking: CookingService, is_visit_available: Callable)`, `place_order(visit_id: StringName, food_id: StringName) -> OrderState`, `deliver(order_id: StringName) -> ActionResult`, signal `settled(order_id, visit_id, item: PreparedItem, payment: int)`. `SupplyService.buy_stock() -> ActionResult`, `buy_fan() -> ActionResult` uses injected wallet/cooking/home/knowledge. `LifeActions.snack() -> ActionResult`, `consume_held() -> ActionResult`, `sleep() -> ActionResult`, `travel(destination: StringName) -> ActionResult`, `toggle_kiosk() -> ActionResult`. Inject concrete dependencies; do not use a service locator.

- [ ] **Step 1 — Write failures:** `test_delivery_once` delivers score-3 tea for 800 piastres, clears the item and rejects repeated delivery with balance unchanged; kebda uses 1200 plus the correct tip. `test_wrong_order_and_absent_visit` keeps the item/order/balance unchanged. `test_supply_atomic` buys +4/+4 for 1500 and rejects insufficient funds without partial stock. `test_referral_fan_sleep_chain` learns the real fact, spends 3500, installs/enables the fan once and sleeps into baseline 82/rest 100. Assert snack costs 300, personal food consumes only the held item and F-secondary priority follows the source.

  ```gdscript
  check.equal(wallet.balance - before_delivery, 800) # score-3 tea
  check.equal(cooking.held_item(), null)
  check.is_true(not service.deliver(order.id).ok) # duplicate
  check.equal(wallet.balance, after_first_delivery)
  check.equal(rejected_purchase_snapshot, before_purchase_snapshot)
  ```
- [ ] **Step 2 — Record red:** Run `service_and_home` with a fake availability predicate that rejects a departed visit; no real NPC implementation is needed yet.
- [ ] **Step 3 — Implement:** Validate every prerequisite before synchronously committing related state. Match source price/tip and need formulas. Use `KnowledgeBook.has(&"KNOWN_CHEAP_FAN")` for the offer; a UI-supplied assertion is not evidence of knowledge. Sleep pays affordable rent once, clears held food, asks actors to reset daily visits through a signal wired in Task 7, and preserves cooking jobs. Travel to kiosk opens it; returning home closes it. Emit outcomes after commit so audio/UI cannot cause partial transactions.
- [ ] **Step 4 — Verify:** Run `service_and_home`, `cooking` and `daily_life`. Add `test_repeated_action_cannot_duplicate_purchase_or_settlement` with the same order/item IDs and duplicate fan request; inspect snapshots before/after rejection for equality.
- [ ] **Step 5 — Commit:** Stage Task 6 paths; commit `feat: integrate paid service supplies and home life actions`.

### Task 7: Add visitors, memory and source encounter pacing

**Files:** Create `game/actors/character_definition.gd`, `game/actors/visitor_catalog.gd`, `game/actors/visit_schedule_definition.gd`, `game/actors/visit_state.gd`, `game/actors/visitor_service.gd`, `game/actors/visitor_controller.gd`, `content/characters/visitors.tres`, `content/encounters/html_schedule.tres`, `tests/test_visitors.gd`. Modify `game/app/session_config.gd`, `game/app/game_session.gd`, `game/world/location_view.gd`, `game/life/life_actions.gd` and the kiosk scene to connect real visitors and settlement memory.

**Interfaces:** `VisitorCatalog` is a Resource with `characters: Array[CharacterDefinition]`; `VisitScheduleDefinition` holds cooldown, quiet-window and authored-encounter parameters. `VisitState` includes unique visit ID, stable character ID, pose, destination, lifecycle/timers, order ID and pending encounter flags. `VisitorService.tick(delta: float)`, `reset_day()`, `is_available(visit_id: StringName) -> bool`, `commit_pose(visit_id: StringName, pose: ActorPose)`, `record_service(visit_id: StringName, item: PreparedItem)`, signal `encounter_requested(kind: StringName, visit_ids: PackedStringArray, context: Dictionary)`. Inject a `RandomNumberGenerator` separate from cosmetic RNG. `VisitorController` drives native path following and commits the same pose used for interaction and speech; it never creates another order or memory store.

- [ ] **Step 1 — Write failures:** `test_amgad_first_and_returning_visit` checks arrival increments memory once and real settlement changes remembered quality. `test_football_and_quiet_window` checks source priorities: Amgad first; football pair after 1020 minutes with the source `count <= 2` condition; ambient visits stop only on day 2 from 1140 through 1215 inclusive. Test that existing visitors remain and authored encounters are not suppressed. `test_nonbuyer_and_departure` checks the non-buyer never gets an order and a departed visit is unavailable.

  ```gdscript
  check.equal(memory_after_arrival.amgad_visits, memory_before.amgad_visits + 1)
  check.equal(memory_after_service.last_served_quality, served_item.quality_key)
  check.equal(new_ambient_visits_during_quiet, 0)
  check.is_true(not visitor_service.is_available(departed_visit_id))
  ```
- [ ] **Step 2 — Record red:** Run `visitors`; use the actual service API for remembered paid food and a seeded RNG for spawn selection.
- [ ] **Step 3 — Implement:** Author the named visitors, colors, destinations, food intentions and source stay times 32/36/20/8/15 seconds. Preserve initial cooldown 2 seconds and subsequent ambient delay 14–24 seconds; do not reinterpret the source's asymmetric capacity rules as a new universal maximum. Emit narrative requests without hardcoding spoken text. Native navigation follows real paths; public pose is its actual result, including when visitors are offscreen. Restore RNG state and daily flags to avoid duplicate arrivals after load.
- [ ] **Step 4 — Verify:** Run `visitors`, `locations` and `service_and_home`. Assert a route avoids the table/counter and speech/interaction anchors use that same resulting pose. Snapshot/recreate the visitor service and advance both with equal deltas; compare future visit IDs, intentions and spawn choices.
- [ ] **Step 5 — Commit:** Stage Task 7 paths; commit `feat: add independent visitors regular memory and quiet pacing`.

### Task 8: Author all conversation in Ink and integrate independent sessions

**Files:** Create `game/narrative/encounter_definition.gd`, `game/narrative/conversation_session.gd`, `game/narrative/narrative_director.gd`, `game/narrative/narrative_effects.gd`, `content/stories/amgad.ink`, `content/stories/football.ink`, `content/stories/visitors.ink`, their corresponding `.ink.json` files, `content/encounters/amgad.tres`, `content/encounters/football.tres`, `content/encounters/visitors.tres`, `tests/test_conversations.gd`. Modify `tools/compile-ink.sh`, `game/app/session_config.gd`, `game/app/game_session.gd` and visitor interaction bindings. Generated story definitions record their source/compiled hashes.

**Interfaces:** `EncounterDefinition` has ID, StoryDefinition, participant rules, initial knot and optional-join duration; SessionConfig holds `Array[EncounterDefinition]`. `ConversationSession` owns encounter/session IDs, participants, current Frame/timing, offered choices and applied-effect IDs. `NarrativeDirector` asynchronously starts with `start(encounter_id: StringName, participants: PackedStringArray, context: Dictionary) -> ActionResult`, returning `details.session_id`, then `tick(delta: float)`, `choose(session_id: StringName, choice_id: StringName) -> ActionResult`, `cancel(session_id: StringName)`, `focused_session() -> ConversationSession`; it emits line/choice changes and does not stop the game clock. `NarrativeEffects.apply(effect: Dictionary, occurrence_id: StringName) -> ActionResult` recognizes only `{kind:learn, fact_id, note}` and `{kind:mood, amount}` records. Deduplicate by persisted `session_id/beat_ordinal/effect_index`, allowing a new session's effects. Context keys are `day`, `amgad_visits`, `last_served_quality`, `known_cheap_fan`; supply them from owning services. Story metadata keys are `speaker`, `duration`, `effect`, `join`; validate speakers, finite positive duration and the effect schema.

- [ ] **Step 1 — Write failures:** `test_concurrent_ink_while_cooking` runs the Amgad and football sessions independently while tea advances and movement remains enabled. `test_repeat_memory_and_real_referral` supplies actual remembered quality/day and asserts authored text/choices and one learned fan note, not a free fan. `test_stale_choice_departure_and_unknown_effect` rejects cross-session/stale choices, cancels departed participants and suspends invalid metadata without gameplay effects. `test_focused_choice_is_not_replaced` starts another encounter and asserts the original focus remains.

  ```gdscript
  check.equal(director.focused_session().id, originally_focused_id)
  check.equal(knowledge.notes().size(), notes_before_referral + 1)
  check.is_true(not home.has_fan) # dialogue teaches; purchase installs
  check.equal(cross_session_choice.code, ActionResult.Code.INVALID_CHOICE)
  ```
- [ ] **Step 2 — Record red:** Run `conversations` with the real pinned adapter, not a fake Ink-shaped object.
- [ ] **Step 3 — Implement:** Transcribe the existing Arabic spoken lines and replies into original Ink stories; include first/repeat greetings, requests, quality reactions, fan referral and ambient remarks. Preserve the football 3.4-second exchange delay and 2.5-second follow-up timing where applicable. Optional football join uses the source 8.5-unit range around `(6,1.6)` and an authored 8-second offer expiry before its listening branch; keep this cleanup tunable in encounter data. Player-initiated choices persist until chosen/cancelled/participant departure. Read actual day/memory/knowledge at boundaries and apply permitted effects through feature owners. No dialogue directly spawns, pays or cooks.
- [ ] **Step 4 — Verify:** Run `conversations`, `ink_runtime`, `visitors` and `cooking`. Snapshot a pending two-person choice and another active session; recreate adapters, choose once and assert unchanged participant identity, no duplicate knowledge/mood effect and correct reconvergence. Scan game scripts for player reply/spoken text accidentally left outside `.ink`.
- [ ] **Step 5 — Commit:** Stage Task 8 paths and generated story JSON; commit `feat: author game conversations in Ink with independent sessions`.

### Task 9: Save and restore one complete validated session

**Files:** Create `game/persistence/save_envelope.gd`, `game/persistence/save_codec.gd`, `game/persistence/save_store.gd`, `game/persistence/save_coordinator.gd`, `tests/test_persistence.gd`, `tests/fixtures/invalid_saves.json`. Modify `game/app/game_session.gd` and feature snapshot/restore methods only as needed to honor their existing contracts.

**Interfaces:** Schema version is integer `1`. `SaveEnvelope` contains schema/content revisions and composed feature snapshots. `SaveCodec.encode(session: GameSession) -> Dictionary`, `validate(data: Dictionary, config: SessionConfig) -> ActionResult`, asynchronous `create_candidate(data: Dictionary, config: SessionConfig) -> ActionResult` returns the fully initialized candidate session in `details.session`. `SaveStore` is configured with a storage root: `write(data: Dictionary) -> ActionResult`, `read() -> ActionResult`, `has_save() -> bool`. `SaveCoordinator.save_at_boundary(session: GameSession) -> ActionResult` and asynchronous `load_candidate(config) -> ActionResult`; replacing the live session is the application's explicit final commit, never the decoder's side effect.

- [ ] **Step 1 — Write failures:** `test_full_session_resume_mid_cook_and_choice` round-trips player pose, clock, money, needs, inventory/held item, jobs/options, fan, notes/knowledge, NPC poses/orders/memory, spawn RNG/cooldown, day flags and two real Ink sessions. Continue both sessions and assert matching quality/payment without duplicate effects. `test_invalid_save_preserves_live_state` covers truncated JSON, wrong types, nonfinite/negative timers, unknown IDs, future version and changed story hash. `test_write_failure_keeps_previous_save` uses a failing storage fixture and verifies no success result or loss of the previous file.

  ```gdscript
  check.equal(codec.encode(restored_session), codec.encode(original_session))
  check.equal(invalid_load.code, ActionResult.Code.INVALID_SAVE)
  check.equal(codec.encode(live_session), before_invalid_load)
  check.equal(previous_good_bytes_after_failure, previous_good_bytes)
  ```
- [ ] **Step 2 — Record red:** Run `persistence` with temporary isolated storage and actual initialized Ink adapters; compare the saved envelope, not just money.
- [ ] **Step 3 — Implement:** Collect snapshots at a completed simulation boundary after pending initialization settles; defer a save requested during a fade until the transition commits and the next completed simulation boundary is available. Decode and validate all components before accepting a candidate. Native storage writes a temporary file, retains the previous good save and replaces only after successful close/validation. Web uses supported `user://` persistence, requests the engine-supported filesystem sync and reports unavailable persistent storage accurately; the harness waits for the supported flush before testing reload. A corrupt primary can offer a valid previous save without overwriting it. No legacy HTML save import.
- [ ] **Step 4 — Verify:** Run `persistence` and earlier suites. Add `test_duplicate_delivery_after_reload` and `test_save_during_fade_is_deferred` asserting exactly-once payment and a coherent before/after location snapshot. Extend the real Web harness with scenario `resume`, hard reload and `SESSION_BROWSER_RESUME_PASS`; test a separately isolated storage-disabled context for truthful failure feedback.
- [ ] **Step 5 — Commit:** Stage Task 9 paths; commit `feat: persist and validate complete native and Web game sessions`.

### Task 10: Wire the actual entry, Arabic HUD and deliberate input

**Files:** Create `game/app/main.tscn`, `game/app/main.gd`, `game/app/qa_probe.gd`, `game/world/location_transition.gd`, `game/world/location_transition.tscn`, `game/ui/game_theme.tres`, `game/ui/title_screen.tscn`, `game/ui/title_screen.gd`, `game/ui/hud.tscn`, `game/ui/hud.gd`, `game/ui/dialogue_panel.tscn`, `game/ui/dialogue_panel.gd`, `game/ui/notebook.tscn`, `game/ui/notebook.gd`, `game/ui/spatial_caption.gd`, `game/ui/toast_stack.gd`, `game/ui/ui_text.gd`, `game/ui/diagnostics.gd`, `content/default_session.tres`, `tests/test_game_entry.gd`. Modify `project.godot`, both location scenes and `game/app/game_session.gd` only for final dependency composition.

**Interfaces:** `Main` creates/injects services and connects views; `Main.begin_new_game()`, asynchronous `Main.continue_game()`. `Hud.bind(session: GameSession)`, `DialoguePanel.present(session: ConversationSession)`, signal `choice_selected(session_id, choice_id)`; `Notebook.present(notes: PackedStringArray)`. `LocationTransition.travel(destination: StringName) -> ActionResult` locks input and commits once during its fade. InputMap actions: `move_left/right/up/down`, `interact_primary`, `interact_secondary`, `notebook`. The development probe is read-only and excluded/disabled in release: it exposes state snapshots to tests, not grant/move/pay shortcuts.

- [ ] **Step 1 — Write failures:** `test_title_has_no_simulation_and_continue_is_real` idles the title, starts/loads and observes the actual session. `test_repeat_key_and_notebook_do_not_leak_actions` sends repeated key events and modal input, then asserts one deliberate interaction. `test_choices_leave_movement_and_cooking_running` uses the real choice panel. `test_arabic_compact_layout` instantiates the HUD at 960×540 with mixed Arabic/EGP/Latin keys and asserts no clipped controls or overlapped panels; capture for shaping/order inspection. `test_diagnostics_isolation` compares live state/save before/after diagnostics.

  ```gdscript
  check.equal(title_clock_after_idle, title_clock_before_idle)
  check.equal(deliberate_interactions_after_echo_events, 1)
  check.equal(snapshot_after_diagnostics, snapshot_before_diagnostics)
  check.is_true(all_required_controls_inside_viewport)
  ```
- [ ] **Step 2 — Record red:** Run `game_entry` against real Controls and input dispatch; don't replace the UI with direct service calls.
- [ ] **Step 3 — Implement:** Set the actual main scene, route keyboard actions through `_unhandled_input`/InputMap and ignore key echo, keep notebook focus distinct from nonblocking choices, and preserve F-secondary priority. Match the source warm dark cards, headers, needs bars, station gauges, notebook and toasts with the bundled font and explicit RTL/container layouts. Add New/Continue, accurate save outcomes and source transitions with 0.65-second fade-out/0.35-second fade-in. Use fixed simulation steps; do not calculate background-tab wall-clock catch-up. Handle lost focus by clearing input and resuming without stuck movement. Diagnostics use isolated fixture services/storage. Debug-only `?qa=ink` boots the dedicated qualification scene so the original `ink` browser scenario remains usable after changing the project entry; release builds ignore QA queries and expose no probe. Normal gameplay scenarios use the actual main scene.
- [ ] **Step 4 — Verify:** Run `game_entry` plus all native suites. Extend Web scenario `gameplay` to walk through real home→kiosk controls, prepare/serve food, open notes, save/reload and continue. Assert `GAMEPLAY_BROWSER_PASS` and capture compact/wide views. Check movement does not trigger while typing/focusing UI, and choices do not freeze station progress.
- [ ] **Step 5 — Commit:** Stage Task 10 paths; commit `feat: connect the playable Arabic game entry and HUD`.

### Task 11: Restore procedural sound and atmospheric motion

**Files:** Create `game/presentation/soundscape.gd`, `game/presentation/soundscape.tscn`, `game/presentation/default_bus_layout.tres`, `game/presentation/atmosphere.gd`, `game/presentation/steam.tscn`, `game/presentation/smoke.tscn`, `tools/generate_audio.py`, `assets/audio/river.wav`, `assets/audio/sizzle.wav`, `assets/audio/kettle.wav`, `assets/audio/fan.wav`, `assets/audio/pour.wav`, `assets/audio/coin.wav`, `assets/audio/chime.wav`, `tests/test_atmosphere.gd`. Modify boat/fan/river visual components, location scenes and application bindings for state-driven feedback.

**Interfaces:** `Soundscape.present(location_id: StringName, cooking: CookingService, home: HomeService)`, `play_action(outcome: ActionResult)`, `set_muted(muted: bool)`. `Atmosphere.present(minutes: float, location_id: StringName)`, `tick(delta: float)`. Sound generation is a deterministic standard-library Python tool producing short procedural PCM loops/cues; Godot consumes ordinary imported audio assets to keep Web runtime simple. Cosmetic time/RNG never changes simulation state.

- [ ] **Step 1 — Write failures:** `test_contextual_audio_layers` verifies river gain 0.12 at kiosk/0.02 at home, sizzle only for nonempty cooking at kiosk, kettle only heating/brewing there, and fan only running at home. `test_failed_action_has_no_success_cue` checks rejected payment/cooking does not emit success audio. `test_cosmetics_do_not_change_gameplay` runs boat/fan/particle updates and compares the authoritative snapshot. `test_generated_loops_are_nonempty_and_repeatable` checks PCM format, deterministic bytes and nonzero audio samples.

  ```gdscript
  check.near(kiosk_river_target_gain, 0.12)
  check.near(rooftop_river_target_gain, 0.02)
  check.equal(gameplay_snapshot_after_cosmetics, gameplay_snapshot_before)
  check.equal(second_generation_wav_bytes, first_generation_wav_bytes)
  ```
- [ ] **Step 2 — Record red:** Run `atmosphere`, including a scene instance with actual bus/player state; audible feel remains a separate human check.
- [ ] **Step 3 — Implement:** Generate source-like filtered noise/tone audio without external music, bind action outcomes after successful commits and smoothly fade contextual layers. Animate the boat at 0.45 logical units/sec with the source wrap, fan using delta rather than frame count, river shimmer, smoke/steam and warm local light pools. Match source time-of-day darkening at 18:00–20:00 and night. Do not add a new needs/comfort system through audio or VFX.
- [ ] **Step 4 — Verify:** Run `atmosphere` and native regressions, then browser `gameplay` with an actual audio context started by the user's Start click. Capture active tea/grill/fan and compare daytime/night scenes. Review audible source and port locally where possible; record any unavailable subjective listening separately from automated layer checks.
- [ ] **Step 5 — Commit:** Stage Task 11 paths; commit `feat: restore Nile cooking and rooftop atmosphere`.

### Task 12: Prove full parity, publish repeatable instructions and add lean CI

**Files:** Create `tests/test_full_day.gd`, `tests/test_extensibility.gd`, `tools/web/capture-parity.mjs`, `tools/check_all.sh`, `docs/PORT_PARITY.md`, `.github/workflows/verify.yml`. Modify `README.md`, `tools/setup.sh`, `tools/web/check.mjs`, `tools/compile-ink.sh` and `export_presets.cfg` to match the completed workflow. Do not modify the reference HTML.

**Interfaces:** `bash tools/check_all.sh` preserves underlying failure statuses and executes import, compiled-story freshness, all nonzero-count native suites, Web export and the `ink`, `gameplay`, `resume` scenarios. `node tools/web/capture-parity.mjs --build <dir> --out <dir>` serves the unchanged HTML and exported game locally and captures named comparable states. Test fixtures may boot a deterministic debug scenario; gameplay verification uses actual keyboard/buttons, not the read-only probe as a command API.

- [ ] **Step 1 — Write failures:** `test_complete_two_day_routine` plays day 1 work, closes early, returns/sleeps, receives the real day-2 Ink referral, buys the fan with earned funds and verifies the next sleep. `test_quiet_day_is_valid` explicitly closes/ignores opportunities without invented loss conditions. `test_extensible_resource_variants` adds another station, timing/price variants and an authored ambient visitor without UI edits; assert the original defaults remain unchanged. Browser checks verify equivalent outcomes after hard reload, pending choice and mid-cook, plus duplicate-action rejection.

  ```gdscript
  check.equal(session.clock.day, 3) # following the day-2 purchase and sleep
  check.is_true(session.home.has_fan and session.home.fan_on)
  check.near(session.needs.baseline, 82.0)
  check.near(session.needs.rest, 100.0)
  check.equal(default_recipe_after_variant_test, default_recipe_before)
  ```
- [ ] **Step 2 — Record red:** Run the new suites/scenarios and record any missing end-to-end wiring rather than changing expectations to match a broken result.
- [ ] **Step 3 — Complete integration and instructions:** Fix only diagnosed gaps within the accepted spec. Add setup/run/test/export instructions, exact pins/licenses and save-location/compatibility notes to README. CI reuses these same scripts with dependency caches and cancellation, runs native and real browser checks once per relevant change, and uploads current screenshots/reports even on failure. No distribution upload or deployment is required. `docs/PORT_PARITY.md` maps every spec table row to the implemented files, current checks and any explicitly unverified subjective outcome.
- [ ] **Step 4 — Final verification and comparison:** Run `bash tools/check_all.sh` and `node tools/web/capture-parity.mjs --build /tmp/kiosk-port-web --out /tmp/kiosk-port-parity`. These functional scenarios use debug exports of the actual gameplay scene; also export release, verify it boots the ordinary title and ignores QA queries, and inspect a real interaction/screenshot there. Capture rooftop/kiosk at afternoon and night, player behind/in front of counter, tea/grill active, both NPC speakers, boat and owned fan, at 1280×720 plus 960×540 and 1920×1080 layout checks. Review actual images, source-file hash and clean diff. Report test counts and genuine browser reload results. User visual/audio approval is separate; missing tooling/access is a blocker to report, never a passing result.
- [ ] **Step 5 — Commit and review handoff:** Stage Task 12 paths; commit `test: verify complete Godot port and document development workflow`. Run a final whole-branch review using the user-selected execution method, resolve findings, rerun only affected checks and prepare a concise completion report with verified capability, remaining subjective review and no publication claim.

## Spec coverage and execution handoff

| Approved design area | Implementing tasks |
| --- | --- |
| Authority, original structure, typed ownership and immutable definitions | Global constraints, Tasks 1–2 and all feature Interfaces blocks |
| Complete visual/gameplay parity table | Tasks 3–8, 10–12; final row-by-row `PORT_PARITY.md` |
| Projection, real physics/navigation and independently replaceable art | Tasks 3–4, 7, 11–12 |
| Real Ink, concurrent spatial dialogue and guarded consequences | Tasks 1, 7–8, 10 |
| Time, daily loop, manual cooking, service and home chain | Tasks 2, 5–7, 10, 12 |
| Full native/Web save and truthful failures | Tasks 1, 8–10, 12 |
| All deliberate prototype cleanups and Arabic/RTL | Tasks 1–4, 8–10 |
| Procedural audio, day/night, steam, smoke, boat and fan | Tasks 4, 11–12 |
| Concrete extensibility checks and final acceptance | Tasks 5, 12 |

Self-review checks: all specified areas map to tasks; all cross-task names/types above are the contracts; all five Review Focus cases have owning tests; no runtime implementation is authorized merely by this plan's existence. Task paths are additions unless explicitly listed as modifications. A task's commit includes its own documented integration edits, not unrelated user changes.

Execution has been authorized with the amendments below. Selected method: **Native** — one implementer maintains the shared interfaces across these dependent tasks, with a fresh independent review of the complete branch afterward. Alternative: **Subagent-driven** — a fresh implementer and reviewer per task, plus final branch review, trading additional context/cost for earlier independent checks. Execute inline continuously; use one independent whole-branch review at the end.


## Authorized review amendments — 2026-10-21

These user changes supersede older Resource-authoring paths and the simpler clock above. Execution is authorized; no additional design gate is pending.

1. **Latest stable engine:** Godot 4.7.2, confirmed via the official godotengine/godot-builds latest stable release API. Pin it and matching templates with official asset digests; qualify actual Ink/native/Web behavior before accepting compatibility.
2. **Data independent of builds:** Store balance, initial state, needs, clock rate, recipes/quality, actors, schedules, location/prop layout, interaction definitions, UI/localization, audio mix and dialogue eligibility as JSON under content/. Replace .tres authoring deliverables with corresponding .json data. ContentStore loads the bundled default or an external --content-dir bundle; Web exports deploy a sidecar content/ directory fetched from the same origin. Validate a complete candidate before activation; reload at the title/session boundary, never halfway through a transaction. Existing behavior handlers stay in typed GDScript; a new behavior may require code. Ink compilation produces replaceable story JSON without rebuilding Godot. Content fingerprints protect saved active stories/jobs from incompatible data.
3. **Independent shared time and dependency order:** game/time/game_clock.gd publishes one authoritative frame (tick, simulation seconds, day and world minutes). simulation_coordinator.gd validates and topologically orders registered systems using allowlisted IDs and declared dependencies. Reject missing dependencies/cycles before play. world_scheduler.gd stores stable due jobs with explicit clock domains, prerequisites, deadline and status; blocked jobs remain visible/retryable or expire, never freeze world time or execute ahead of prerequisites. Bootstrap also has a readiness barrier. Cooking, visits, needs and narrative use this shared step; presentation time remains noncanonical.
4. **Knowledge and relationship foundation:** Canonical KnowledgeBook and hidden directional RelationshipStore feed a finite ConditionEvaluator: all/any/not, fact_known, relationship_at_least, visit_count_at_least, day_at_least, time_window, participants_available and distance_at_most. Validate all IDs/operators/thresholds. Narrative context exposes read-only canonical queries/projections to real Ink. Gate encounter starts, optional interjections and offered choices; revalidate at selection and after load. Default content preserves HTML encounters while tests exercise knowledgeable/unknown and familiar/unfamiliar variants. Persist relations, fact provenance and pending conditions; no visible friendship meter or invented progression grind.

Implementation mapping: Task 1 adds ContentStore/JSON reload tests and latest-engine qualification; Task 2 adds game/time coordinator/scheduler with dependency-cycle, prerequisite and deterministic-order tests; Task 8 adds RelationshipStore/ConditionEvaluator plus real conditional Ink tests; Task 9 persists those additions; Task 12 verifies external JSON and compiled Ink changes take effect without an engine rebuild. UI .tscn and reusable code-only visual scenes remain native Godot assets; gameplay definitions and all tuning values live in JSON.
