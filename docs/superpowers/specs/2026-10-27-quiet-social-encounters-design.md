# Quiet social encounters — proposed execution design

Status: concrete design for roadmap epic#2; user authorized starting the batch. Product implementation awaits review of the decisions below. No gameplay changes in this design commit.

## Intent and constraints

People independently visit the quiet Nile corniche, notice familiar people, approach them and talk. The player may listen, participate when invited, or leave. Never spawn participants, extend their availability or increase the four-person scene ceiling to demonstrate the feature. Existing clock, offline Ink/localization, data-driven definitions, orders, knowledge, relationships and save continuity remain authoritative. Deliver one coherent preview after integration review, rather than one preview per internal component.

## Approaches and author recommendations

1. Recommended: reuse VisitorService, SpatialAwareness, cached grid paths, NarrativeDirector and Ink. Add a separately owned peer encounter coordinator, presentation/listening adapters and strict persistence. This retains existing behavior while making intent explicit.
2. A general behavior-tree/planner rewrite could express more future behavior but would expand scope and replace working ownership/time/save boundaries. Defer it.

These are author recommendations, not separately approved user choices. Existing football Ink is the first migration target. Author-proposed second content pair: Amgad and Hassan, with ordinary public conversation and no invented personal secret/quest. No promises of permanent jobs or new economy features.

## Existing evidence

VisitorService._arrived currently starts football for Mahmoud/Samir when both stay, without a purposeful encounter. VisitorMeetings only targets the player (Youssef policy). SpatialAwareness records observed actor positions rather than unseen live positions. NarrativeDirector already advances timed automatic speech independently, but its optional-choice timeout finishes unheard conversations instead of authoring an NPC continuation. _can_hear currently reads location/radius; it must remain separate from peer visibility and participation eligibility. Conversations, journals and world effects already have independent owners; extend them instead of putting story effects in movement.

## Meeting lifecycle

PeerEncounterCoordinator owns bounded states: seeking → approaching → greeting → conversing → completed/interrupted → cooldown. JSON defines pairs/roles, eligibility, chance, delay, maximum attempts/duration, separation and cooldown. Sample independently of purchase RNG. One active peer encounter globally, two exclusive participant reservations; no nested player/peer conversation claims.

Both participants must exist, stay in the same place, be available, and have no pending order/request, personal conversation, workshop reservation or departure. An initiator uses its own observed target memory, never the live unseen position. Recheck availability/visibility and target displacement at bounded intervals. Meeting intent temporarily overlays the mover's destination; it never replaces the domain visit/order. Reachable free approach point is required. Sitting target may remain seated; initiator stands at a clear interaction point. Seated initiator may release its reservation to approach. Restore ordinary activity afterward without snapping to the old position.

Departure, explicit personal/service interaction, lost target, unreachable approach and total timeout interrupt cleanly and release reservations. Consumed/failed attempt markers prevent repeated invitations. Existing paid/pending orders are never cancelled by an encounter.

## Ink and participation

Peer conversation may start and continue without the player. Lines and autonomous branches belong to Ink; finite metadata identifies a participation opportunity and its authored no-player continuation. No magic numeric choice index, automatic player reply or simulated player consent. Existing old football cursors/choices continue on archived graphs; new starts use the new graph.

Register the current line at first actual audibility, including entering midway, exactly once per conversation/beat via a saved heard receipt. Scope metadata for new effects is explicit and validated: world/NPC effects versus player-hearing effects. Untagged legacy effects keep their existing hearing-gated meaning; never reinterpret old graphs globally. The player hears only the current audible speech; entering midway does not replay missed lines. Offscreen lines/knowledge never enter player history. World/NPC effects execute independently from player hearing, once only; hearing effects (player facts/history/topic consumption) require actual hearing. Participant reservations stop physical movement during speech. A player reply is available only while the window is live, in the same location and hearing range, and action/participation policy permits it. Waiting or walking away takes an authored autonomous continuation without penalties for the player. Participation temporarily uses existing dialogue focus; never opens over a blocking panel or steals an existing personal conversation. Once speaking directly with the player, existing manual reading/choices continue to apply, with explicit distance/interruption behavior.

Keep existing hearing-radius semantics in this batch; do not silently impose sight-only hearing. Screen captions and focused dialogue display the same localized frame/speaker. No transcript of unheard lines. Existing captured historical text remains in its recorded language.

## Content and tuning

Migrate Mahmoud/Samir football from arrival-triggered chat to observed, purposeful meeting with several existing-tone variants and an autonomous ending. Add one complete Amgad/Hassan public slice-of-life conversation with optional greeting/participation and a quiet autonomous ending. Broaden eligible player approach only through existing meaningful topics; no forced arrival or dialogue to prove an actor setting works. All new lines/choices receive stable loc IDs and intent-based Arabic/English text shipped offline.

Pair definitions, encounter metadata, timers/chance, cooldown and finite candidate counts are external JSON. Authors may disable the optional feature. Content changes apply at session/content load as today. Definitions with invalid roles/IDs, missing autonomous continuation, bad bounds or circular reservations are rejected before activation.

## Narrow passages

Keep local avoidance/grid backend. Recovery here is bounded waiting, release/abandon of peer intent and resumption of leisure. Never shove or interrupt a speaker/sitter/player. If no legal bypass exists, admit the blocked passage. Moving a third actor aside is outside this batch and belongs to epic#3. Comprehensive corridor right-of-way remains epic#3; this batch cannot claim universal deadlock elimination.

Sleep or any owner operation that clears visits/conversations interrupts peer meetings and releases reservations before clearing participants. Do not invent skipped speech, hearing or social completion during a sleep time jump. This differs from normal ongoing simulation while the player is elsewhere.

## Save and migration

Persist semantic meeting ID, visit references, roles, phase, elapsed/attempt/cooldown counters, observed goal and associated conversation identity. Physical solver samples remain transient. Reject duplicate claims, invalid participants/phases and orphan conversations. Stage and validate restore before publication. Extend save revision15 through an explicit additive migration; preserve clock/wallet/orders/items/knowledge/relationships/purchase RNG and active old Ink graphs. Disabled/removed authored policy releases only optional meeting intent safely, not the underlying visit/order. Save/Continue during approach, NPC speech and active player participation must resume without repeated effects or rewards.

## Completion evidence and boundaries

No automated gameplay suite without user request. Use build-only gate, bounded native runtime observations and actual Web mouse/keyboard observations; record limitations. Cover independent/no-player start, missed/unheard speech, join midway, expired choice, interrupted meeting, saved old dialogue, approach/speech/participation restore, chair movement, pending order priority and disabled policy. Include source-review and profiling observations (bounded candidates, no per-frame paths/Ink opens). No universal FPS claim. Preserve known teardown warnings as evidence until separately diagnosed. Publish one complete archive under artifacts only after coherent delivery.

## User-visible decisions to review

- First two authored pairs: Mahmoud/Samir and Amgad/Hassan.
- NPC talk continues out of hearing; the player's history includes only what was actually heard.
- Participation uses explicit, expiring opportunities; silence takes an NPC continuation, not a player answer.
- Comprehensive passage arbitration and player/home seating remain separately scoped roadmap work.

## Builder check

One fresh read-only design review completed. It identified first-audibility receipts, explicit effect scopes preserving legacy semantics, sleep/visit clearing, and passage scope. All were incorporated above as author decisions; no new unresolved user question was raised. No implementation or tests were performed during this design step.
