# Quiet peer encounters — implementation record

Approved spec and plan: docs/superpowers/specs/2026-10-27-quiet-social-encounters-design.md and docs/superpowers/plans/2026-10-27-quiet-social-encounters.md. Feature branch only; no main merge. Delivery is a single coherent batch, not individual internal commits.

## Ownership and behavior

PeerEncounters owns a bounded globally exclusive pair intent; VisitorService retains visits, purchases and seating. Observations, not unseen current positions, select an approach goal. Eligibility requires settled, available actors; validation of a stale observed point prevents accepting a moving target as stationary. One role per authored initiator, one attempt per visit and an independent deterministic chance/variant sample. No spawned pair, extended availability, extra crowd or purchase-RNG use. Physical goal overlays never replace the visit's destination or pending order. Target waits; a seated target can remain seated. The initiator releases its seat before approaching. Domain/service/personal/workshop/departure/timeout/route failure and sleep clearing release optional intent safely. Moving third parties aside and universal corridor arbitration remain epic#3.

NarrativeDirector/Ink own the conversation. Peer eligibility/variant selection bypasses player topic history so unheard/heard topics do not control NPC life. Two authored pairs: Mahmoud/Samir football and Amgad/Hassan public river chat. Farid joins the existing player-approach policy through his existing eligible social topics, using a5–9second delay override for his unchanged short visit; Youssef retains20–45seconds. Nothing guarantees that the pair will be present/visible/available in any particular visit.

## Hearing, effects and participation

Saved heard_beat receipts process a frame at first actual hearing, including entering midway, once per conversation/beat. Player history/facts are not granted for missed earlier frames. Legacy effects remain hearing-scoped. Explicit world effects are currently limited to finite peer_relation changes between the two participants, exclude the player and apply once through RelationshipStore. New world action kinds require explicit implementation; arbitrary finance/service/player-knowledge effects cannot be relabeled world. Participant/type validation precedes world publication.

Ink's `autonomous:<top_level_knot>` metadata supplies the no-player continuation at a choice opportunity. Paths are validated and serialized only when present, preserving old frame hashes. A timeout jumps to that authored knot; it never chooses a player answer. All peer choice frames require an autonomous path. New peer optional definitions omit the legacy numeric listen_choice convention. Old active football graphs keep their previous semantics through an exact archive.

A real player choice adopts group manual reading, separate from PersonalConversations' single-person hub. Continue/Leave and Enter/Escape use the same current frame. Reading pauses the meeting deadline. Missing hearing range or exhaustion detaches the player; NPC conversation resumes autonomously. Modal/other personal ownership blocks offers and focus is recovered when safe. No hearing is inferred from merely having a panel open. Both languages ship offline; current count is12 authored Ink stories/324 stable line-choice references.

## Data, save and compatibility

`visitors.peer_encounters`: enabled, delay_seconds, chance, max_seconds, cooldown_seconds, stop_distance, arrival_radius, target_tolerance, pairs. V1 permits up to8 pairs with a unique initiator per pair. `meetings.delay_overrides` provides validated per-actor timing for existing player approaches. Data applies on content/session load. Optional policy may be absent/disabled. Deleting referenced story/encounter IDs still needs an explicit migration; disabling/removing a pair policy cancels its optional conversation without cancelling the underlying visit/order.

Schema4/revision16 adds peer owner state and hearing receipts. Revision15 migration starts empty optional intent and treats old active/paused frames as already processed, avoiding retroactive effects. PeerSaveLinks checks participant/conversation identity, encounter and exclusive claims, bounded approach data and remembered intent. Old graph archive7bce28b3e7b946cf3c3c79567c1a13717e2fa721fcfa5919f4d4c4071980b7f4 preserves previous football cursors. Maps/solver samples remain transient.

## Bounded native evidence and limitations

No automated gameplay suite was added/run. Temporary runtime fixtures and build-only checks provide bounded evidence; source and shipping policy remain distinct from fixture overrides. Evidence folder: evidence/2026-10-27-quiet-social/.

- First hearing adds exactly one journal line; repeated ticks/restore do not replay it. Offscreen peer relation change occurred without changing player mood; hearing-only mood applied once upon entry. Invalid world/player mood effect was rejected.
- Real session clock/ActorMotor/navigation produced physical peer approach, conversation, owner restore and clear. A stale moving-target observation was found during development; settled eligibility/observation validation corrected that case.
- Football player participation preserved manual frame/deadline, saved/restored revision16 with matching peer state/wallet/clock/purchase RNG, rejected an orphan conversation and released cleanly on Leave.
- River conversation exercised the same join/save/leave chain using a controlled clear-area fixture: seating/leisure off and two explicit nearby leisure markers. An earlier ordinary-layout fixture correctly produced no encounter because actors settled outside mutual sight. Shipping geometry and schedules were not changed to force it.
- Unattended football completed with zero heard peer lines and a real peer relationship change.
- Structural revision15 migration preserved wallet/clock/RNG. Exact archived previous football graph preserved hash, text and choices without new hearing. These native envelopes are fixtures, not a claim of genuine old-browser-save acceptance; final Web evidence is recorded separately.
- Native teardown warnings (fixture-dependent46/21,51/23,70/21,99/23,123/23 ObjectDB/resources) remain recorded. No general leak fix, universal FPS improvement, exhaustive story/layout acceptance or final art claim.

`?profile=1` adds peer_update, peer_search, peer_started and peer_finished alongside existing Ink/path diagnostics. Candidate search is capped at8 and runs only on an eligible attempt; ordinary ticks do not request paths. Current source-review/final-export/Web/delivery status will be appended after their actual results.
