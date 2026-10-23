# Body, Clock and Tweaks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans; native implementation, one final fresh reviewer.

**Goal:** One game minute per simulation second, needs with understandable consequences and safely editable balancing values.
**Architecture:** Needs owns true rest/hunger/mood, Alertness owns temporary stimulation, ActionPolicy owns pre-action decisions and effort receipts. TuningStore stages validated overrides; the shared clock stays authoritative. UI/shader render these states only.
**Tech Stack:** Godot4.7.2/GDScript/JSON/Ink; revision9 after dialogue/journal revision8.
**Spec:** `docs/superpowers/specs/2026-10-23-everyday-life-dialogue-and-obligations-design.md`, sections4–5,9–12. Prerequisite: increment1 delivered.

## Global Constraints

- No automated tests; build and actual UI evidence. No local replacement timers or reset clock on tuning/load.
- Hunger never blocks dialogue; critical fatigue can block focused conversation, while short care/help/payment requests remain available.
- True extreme exhaustion cannot be bypassed by caffeine; no forced blackout or death added.
- Tuning never silently rewrites active jobs/contracts or existing need values; no release gameplay debug commands.

## Review Focus

- Faster clock or sleep advances calendar effects once without shrinking physical reaction windows.
- Tea must have real temporary effect on eligibility and diminishing returns, without curing true sleep debt.
- Repeated clicks/reload must not reroll a work refusal or drain ingredients on rejected actions.
- Compound gating must preserve a route to eat, sleep, ask help and repay even at zero needs.
- Invalid override/save leaves the good live session, settings and disk save intact.

### Task1: Explicit units and mutable validated tuning

**Files:** create `game/config/tuning_store.gd`, `game/ui/tuning_panel.gd`, `content/tuning.json`, `game/content/tuning_validation.gd`; modify `game/time/game_clock.gd`, `game/life/needs_service.gd`, `game/actors/visitor_service.gd`, `game/app/game_session.gd`, `main.gd`, `content/time.json`, `needs.json`, `visitors.json`, `ui.json`, manifest/required sections/validators.
**Interfaces:** `GameClock.set_speed(minutes_per_second:float)->ActionResult`; `TuningStore.propose(overrides:Dictionary)->ActionResult`, `apply_at_boundary()->ActionResult`, `snapshot/restore`; phase2 tuning keys have numeric bounds and explicit units.

- [ ] Set default clock speed1. Convert need decay to per-world-minute rates; author initial hunger6/hour and rest4/hour as adjustable starting values. Visitor arrival/stay policy becomes authored world-minute ranges preserving quiet capacity; physical movement and preparation reaction seconds stay simulation seconds.
- [ ] Add dev-only tuning UI for time speed, decay/thresholds, refusal parameters, fatigue visuals and display names. Import/export JSON and local Web overrides; never promise writing server files from browser. Apply whole candidate at a simulation boundary after validation, with rollback on rejection; clear override returns defaults without resetting actor state.
- [ ] Freeze active preparation timing/quality contracts and existing scheduled world deadlines when changing rates. New day/week calendars derive from current world_minutes, not restarting time. Reuse parent-loop focus/pause policy.
- [ ] Build `/tmp/kiosk-body-t1`; expected success. UI: clock1:1, change speed mid-job, invalid tuning rejection, export/import, reload; record actual need/visit calendar behavior and physical reaction timing. Commit coherent task.

### Task2: Alertness, fatigue policy and actual work effort

**Files:** create `game/life/alertness_service.gd`, `action_policy.gd`, `content/action_policy.json`; modify `needs_service.gd`, `mood_policy.gd`, `life_actions.gd`, `game/cooking/cooking_service.gd`, `recipe_workflow.gd`, `game/items/inventory_service.gd`, `game/world/interaction_router.gd`, `game/narrative/personal_conversations.gd`, `inner_monologue.gd`, content validators/foods/narration.
**Interfaces:** `ActionPolicy.preview(action_id:StringName,context:Dictionary={})->ActionResult`, `attempt(action_id:StringName,attempt_key:String,context:Dictionary={})->ActionResult`, `record_effort(source_id:String,kind:StringName,amount:float)->ActionResult`; `business_allowed:Callable` defaults true (increment3 consumes it). `AlertnessService.consume(food_id:StringName,source_id:String)->ActionResult`, `effective_focus()->float`, `tick(frame:Dictionary)`, `snapshot/restore`.

- [ ] Author finite action classes: personal_focus, practical_talk, cooking_for_self, commercial_preparation, eating, supply_access, return_home, sleep, payment, help and ordinary_effort. Gate before any actual spend/reservation. Practical care/help/payment is exempt from conversational fatigue; hunger never blocks either dialogue class. Later government suspension applies only commercial classes.
- [ ] Author starting thresholds: fatigue warningrest25, focus denial10, absolute rest floor3; hunger denial10; mood refusal below20. These are implementer balancing defaults. Caffeine raises effective focus temporarily but cannot bypass true rest≤3. Allow leaving/suspending a tired conversation at a natural authored boundary, never selecting/erasing an open choice.
- [ ] Tea starting boost12 focus for90world minutes; repeated doses within6world hours multiply1/0.6/0.3/0.1/0. Sleep4hours resets response. Clamp aggregate boost12 and a continuous effective-focus exemption to180world minutes before sufficient sleep; true rest is never increased by tea. Persist dose sources, deadlines and cap consumption across saves.
- [ ] Work effort derives from actual started/completed actions or active effort duration, not sign/open state. Apply mood/rest costs once per source/step; expose costs as JSON. Low mood keeps existing quality penalty and can reject a new work attempt with initial probability0.2, cooldown30world minutes and at most2 refusals per game day. Persist each attempt's result/semantic key; rejected work spends no material or money. Do not reroll while button repeats.
- [ ] Build `/tmp/kiosk-body-t2`; UI: caffeine delays focus block then wears off, repeated cups diminish, floor3 requires sleep, self-care at low hunger, food/supply/travel paths, refused versus started preparation, Continue during refusal/dose. Record limits and commit.

### Task3: Fatigue presentation and revision9 persistence

**Files:** create `game/presentation/fatigue_overlay.gd`, `assets/shaders/fatigue_blur.gdshader`; modify HUD/main, journal/inner-monologue integrations, GameSession/simulation dependencies, SaveCodec/migrations/save validation and QaProbe.
**Interfaces:** `FatigueOverlay.present(view:Dictionary)->void`; Alertness/ActionPolicy state follows standard snapshot/restore; fatigue state stores scheduled pulse selection, not wall-clock time.

- [ ] Render bounded intermittent blur on world layer only. Warning interval5–10simulation seconds; severe authored range2–5, bounded strength/duration. Keep text/history/choices sharp and offer reduced/off visual strength separately from fatigue gameplay. Persist selected next pulse so Continue doesn't reroll.
- [ ] Add readable thought/eligibility cues with cooldown; no spam or interruption of personal choices. Sleep updates needs, alertness recovery and elapsed policies from the same clock frame; no simulation of missed dialogues.
- [ ] Add revision9 candidate migration: existing need amounts/deadlines/items/jobs unchanged, empty caffeine/refusal history, validated tuning state and pulse/effort references. Reject inconsistent pulse time/dose/attempt provenance without partial install.
- [ ] Build debug/release and manually review actual saved rev8 choice/jobs, maximum/minimum needs, rest→tea→work→wear-off→sleep, speed changes, blocked invalid settings. Expected no runtime errors, food/sleep paths remain accessible; record uncovered balance cases.
- [ ] Commit/review/fix and publish exact-SHA preview through parent delivery rules. This increment retains legacy rent behavior until increment3 explicitly migrates its assessment; do not accidentally charge old and new systems together.
