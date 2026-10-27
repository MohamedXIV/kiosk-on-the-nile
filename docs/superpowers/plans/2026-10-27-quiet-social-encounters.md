# Quiet social encounters implementation plan

> Execute inline using superpowers:executing-plans. User approved the design; preserve the established native execution method and proceed without a second scope approval.

**Goal:** Purposeful peer meetings, autonomous Ink conversation, truthful listening/participation and compatible persistence in one complete preview.
**Architecture:** Separate peer intent/reservations, narrative progression, heard receipts and presentation; existing owners retain domain transactions.
**Tech stack:** Godot4.7.2/GDScript, offline Ink, external JSON, Arabic/English.
**Spec:** docs/superpowers/specs/2026-10-27-quiet-social-encounters-design.md

## Global constraints
No forced visits or increased four-person cap. Preserve orders, seats, shared time and legacy Ink. No automated gameplay tests without request: bounded native runtime observations, build-only gate and actual Web input. One fresh final whole-diff review, one material fix pass. No main merge without reviewable completed result. One playable archive at the end.

## Review focus
First-audibility receipts and effects must not duplicate after restore; legacy effects remain hearing-gated. Never choose a player answer offscreen. Meetings must not orphan reservations on sleep/departure/failed opening. Preserve purchase RNG and pending order priority. Avoid per-frame path/Ink/query bursts and unpublished saved graph hashes.

## Tasks and interfaces

- [x] 1. Narrative hearing and autonomy. Modify narrative_director.gd, conversation_session.gd, narrative_types.gd, ink_runtime.gd and narrative_effects.gd. Add a focused hearing helper if needed. Frame metadata declares autonomous continuation by stable Ink knot, not numeric choice. Explicit world/hearing scopes; legacy defaults hearing. Saved per-beat hearing receipt, initialized safely for existing active frames. Observe entering mid-line, unseen effects, repeated tick/restore, timed-out participation and old graph continuity before committing.
- [x] 2. Peer meeting owner. Create game/actors/peer_encounters.gd and content validator. Configure optional JSON under visitors; consume visits/observations/eligibility/reachable/free-point callbacks; expose goal(visit), active(id), conversation linkage, tick/snapshot/restore/clear. One globally active pair, deterministic independent sampling and exclusive claims. Integrate VisitorService, physical goal selection and service/personal/sleep/departure priorities. Remove new-start arrival football trigger while preserving old active sessions. Observe blocked approach, target loss, sitting target, service interruption and disabled policy.
- [x] 3. Persistence and domain wiring. Add revision16 migration/validation preserving revision15 and archived Ink. Validate peer/conversation linkage and heard receipts in staged session restore. Sleep/clear cancels before removal. Observe save/restore during approach, autonomous speech, participation and old active dialogue; preserve wallet/clock/RNG/items/orders.
- [x] 4. Author complete bilingual scenes and participation UI. Update football Ink with autonomous continuation and preserve previous compiled graph archive; add Amgad/Hassan scene, finite peer configuration and manifest/locale references. Add contextual participation to existing dialogue/captions without stealing modals/focus. Broaden player approach through eligible existing topics only. Compile Ink and check stable localization IDs. Observe no-player scene, joining midway, silence, walkaway and live player reply. No third-actor displacement policy.
- [ ] 5. Integrate and deliver. Complete native observations/build, one fresh reviewer and one material fix pass. Actual Release Web normal Continue and controlled public-content fixture for both pairs/participation. Compare shipping JSON, publish one verified archive on artifacts; update epic2/roadmap/notes with real evidence and limitations. Keep feature branch ephemeral; no per-task build branches.

## Task gates
Each task records its concrete outcomes/commands and rulings in .superpowers/sdd/2026-10-27-quiet-social-encounters/progress.md, commits coherent source, and leaves domain compatibility explicit. Plan self-review: intent, native/legacy narrative, hearing, interruption, save, bilingual content, bounded performance and final delivery all mapped above. Coordinator consumes the same effective-goal/availability interfaces that physical/service owners produce; changing their priority must be implemented together.
