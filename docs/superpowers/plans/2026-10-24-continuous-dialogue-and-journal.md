# Continuous Dialogue and Journal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans; native implementation, one final fresh reviewer.

**Goal:** A connected personal conversation can branch and switch topics without repeated E presses, with player-controlled reading and a faithful history.
**Architecture:** PersonalConversations owns the ongoing encounter with a person; NarrativeDirector owns each real Ink chapter. InteractionJournal records committed heard/selected events, InnerMonologue owns independent automatic thoughts. Presentation derives from those services.
**Tech Stack:** Godot4.7.2/GDScript/Ink/external JSON.
**Spec:** `docs/superpowers/specs/2026-10-23-everyday-life-dialogue-and-obligations-design.md`, sections1–4 and10–12. Parent: `2026-10-24-everyday-life-execution.md`.

## Delivery status

Implemented and published as preview `dialogue-journal-7e3818d`. See [delivery evidence and acceptance limits](../../notes/2026-10-24-continuous-dialogue-and-journal.md). Checklist items below retain their original intended gates; unexercised manual cases are explicitly listed in that record.

## Global Constraints

- User approved manual progression for personal speech, automatic ambient/thoughts; world keeps running.
- No automated tests. All checks below are build tools, read-only inspection or actual UI interaction.
- Schema4/revision8. No fabricated old history; published Ink state/hash archive mechanism remains authoritative.
- No early transfer of another person's information or automatic work consent. Existing referral semantic receipts still govern.
- This increment leaves clock speed/body/finance changes for their plans.

## Review Focus

- Holding an unread line must neither rerun effects nor move the speaker away; other actors/jobs still advance.
- Choice text inside Ink square brackets is not necessarily printed by Ink: record the accepted player text exactly once.
- Switching chapters can collide occurrence IDs or silently discard a cursor; chapter IDs and actual Ink sessions remain unique.
- Declining/walking away must leave unheard disclosure available; the journal must never reveal remote speech.
- A legacy active choice plus pending customer order must restore without creating a second order or a fake old transcript.

### Task1: Heard journal and manual chapter progression

**Files:** create `game/narrative/interaction_journal.gd`, `content/narration.json`, `game/content/narration_validation.gd`; modify `game/narrative/narrative_director.gd`, `conversation_session.gd`, `narrative_types.gd`, `game/app/game_session.gd`, `content/manifest.json`, `content/encounters.json`.
**Interfaces:** `InteractionJournal.append_once(event:Dictionary)->ActionResult`, `entries(filters:Dictionary={})->Array[Dictionary]`, `snapshot/restore`; `NarrativeDirector.advance_manual(id:StringName)->ActionResult`; signal `chapter_finished(id:StringName,reason:StringName)`.

- [ ] Add validated event IDs, conversation/chapter ID, speaker ID and display-name-at-time, final text, world timestamp and channel (`speech`,`choice`,`thought`,`system`). Reject duplicate ID with changed payload. Append heard speech only after its effects commit and hearing is confirmed; append accepted choice after successful choice execution, not on button display. Preserve order of choice before its response in journal staging.
- [ ] Add authored advancement policy to encounters. Manual chapters display their current line until explicit advance; choices are never advanced by a timer. Ambient chapters retain timed progression; optional invitation silence only selects listening, never work consent.
- [ ] Validate manual advance eligibility and hearing range; use the existing Ink session/cursor, never re-advance a displayed line. Guard speaker dwell/purchase while manual speech is held. Record chapter-finish reasons for completion, cancellation and departure separately.
- [ ] Run `bash tools/compile-ink.sh --check` then `bash tools/build.sh --out /tmp/kiosk-dialogue-t1`. Expected: compiler/import/export success, no script errors. UI: hold a line and an explicit work-consent choice; verify world/jobs advance and semantic receipts do not repeat. Commit journal/progression task.

### Task2: Connected personal topics and thought channel

**Files:** create `game/narrative/personal_conversations.gd`, `inner_monologue.gd`, `content/stories/inner_monologue.ink`; modify `game/narrative/conversation_history.gd`, `narrative_director.gd`, `condition_evaluator.gd`, `game/social/social_life.gd`, `game/app/game_session.gd`, `game/ui/dialogue_panel.gd`, `visitor_panel.gd`, `game/world/interaction_router.gd`, `content/encounters.json`, `content/social_life.json`, `content/ui.json`.
**Interfaces:** `NarrativeDirector.manual_topics_for(visit_id:StringName)->Array[Dictionary]` returns stable topic key/label/canonical eligible selection; `start_manual_topic(visit_id:StringName,key:String)->ActionResult`; `PersonalConversations.open_for/advance/select_topic/leave`, `view()->Dictionary`, `snapshot/restore`; `InnerMonologue.tick(frame:Dictionary)`, `snapshot/restore`.

- [ ] Implement one focused personal hub with the current participant and Ink session reference. A completed chapter returns to eligible topics inside the hub after its last line is read. Topic selection rechecks exact history/conditions instead of injecting topic_id or silently choosing the first eligible topic. Keep ordinary personal topics, order recall and meaningful social follow-ups available.
- [ ] UI always shows a manual chapter, including lines with no choices, with Continue/choice/topic/leave controls. Hub use does not require E per chapter. Existing order badge and recall remain actual order data; recall must not count as a personal relationship reward.
- [ ] Permit only one personal hub. Close/suspend gracefully on walkaway/travel/sleep; don't consume unheard topics. Paused personal chapters are stored by actor ID with their actual runtime snapshot/hash and topic selection, separate from active visit IDs. On a later visit rebind only to that same actor and validate current encounter/choice safety; heard once-only history is not itself a reason to discard a legitimate paused cursor. Never resume a former customer order against a new visit. Old one-time history remains evidence of actual heard text.
- [ ] Add authored inner monologue on current needs/known situations with once/cooldown rules stored in state. Use a separate automatic presentation channel/runtime, never personal choice focus; no new unknown facts or NPC speaker attribution. Defer thoughts while personal choices would be obscured.
- [ ] Compile Ink (`bash tools/compile-ink.sh` for the new story), build `/tmp/kiosk-dialogue-t2`. Expected: no old story JSON changes unless first archived. UI: acquaintance→disclosure→eligible follow-up in one hub; leave/re-enter, overheard versus out-of-range speech, thought during manual choice. Record receipt/journal behavior and commit.

### Task3: Advisory sign, notebook and persistence

**Files:** modify `game/actors/visitor_service.gd`, `game/life/life_actions.gd`, `needs_service.gd`, `game/ui/notebook.gd`, `hud.gd`, `game/app/main.gd`, `qa_probe.gd`, `game/persistence/save_codec.gd`, `living_spaces_migration.gd`, `living_spaces_save_validation.gd`, `game/content/feature_content_validation.gd`; create `content/stories/service_availability.ink` and its encounter/content definitions.
**Interfaces:** participant-bound explicit service acceptance creates one existing ServiceSystem order; journal/hub/thought components implement the standard `snapshot/restore` contract consumed by SaveCodec.

- [ ] Remove purchase gating by the sign and its work-drain implication. Only a present available player can explicitly accept a queried order. Author direct requests/availability questions/declines by character and actual ingredients; keep independent visits, kitchen timers and no ghost service during absence. Sign can affect wording, not eligibility.
- [ ] Expose journal by day/person/conversation and distinguish thoughts/system entries. Retain knowledge summaries/people tab and link known notes to their new journal source when one exists; old facts retain old provenance and no invented transcript. Show timestamps as game time, not host time.
- [ ] Add revision8 migration with empty journal/inner state and compatible current chapter/hub state. Restore old Ink frames exactly; do not replay effects or retroactively log past speech. Cross-validate participant/session/event references and semantic sequence before installing a save candidate.
- [ ] Build debug and release with `bash tools/build.sh --out /tmp/kiosk-dialogue-final-debug` and `bash tools/build.sh --out /tmp/kiosk-dialogue-final-release --release`. Expected: success. UI gates: old rev7 saved active choice/order/jobs, new hub at line/choice/topic selection, advisory closed sign requests, absence, journal replay without side effects. Include both workshop disclosure orders where feasible; report uncovered cases.
- [ ] Commit exact product, final fresh review and material-fix pass, then exact-SHA export/stock-content release boot and authorized GitHub preview/digest check. Record source, evidence, limits and future-plan interfaces in delivery notes. No main merge.
