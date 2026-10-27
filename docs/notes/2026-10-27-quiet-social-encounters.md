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

## Final whole-branch review and material fix pass

A fresh independent reviewer examined `63b6a09..24f1ce5` read-only (no independent runtime). Its earlier attempt was unavailable; the resumed review completed. No Critical findings; three Important findings were reproduced and addressed in one pass:

- A saved greeting/near-arrival approach could lose its intent while transient visibility was still awaiting its staggered refresh. Native before: first observer target caused cancellation. After: intent survives the unsampled frame and fresh initiator sight issues the greeting. Existing memory/displacement/deadline guards still bound waiting.
- Location travel canceled NPC speech through the legacy global cancel handler. Native before: travel removed the peer graph and owner. After: both travel paths detach player participation and retain NPC graphs; actual `life.travel(rooftop)` completed the offscreen dialogue and released its owner. Sleep still explicitly clears visits and dialogue.
- Author validation previously allowed missing autonomous metadata until the choice beat, after earlier world effects. Each configured peer encounter now declares a required default `autonomous` top-level Ink knot in external JSON; the Ink adapter validates that default and all local autonomous declarations against the compiled story before activation. Untagged choice frames use this validated default; local tags may override it. Invalid declared paths now reject content load. A fixture removing all local football autonomous tags completed join/save/disabled-policy/order checks through the default. This is an explicit default continuation contract, rather than requiring duplicate tags on every choice beat.

Additional native edge observations: approach save/restore preserves owner/wallet/purchase RNG; a consumed player football topic does not prevent the NPC encounter; disabling policy releases optional dialogue while preserving two visits and wallet; walkaway detaches manual reading; a newly accepted tea order cancels optional peer talk and remains pending; sleep signal clears peer owners/visits/dialogue. The first edge fixture used an invalid visit scope for a day-scoped history record; corrected fixture, no product change.

Deferred review minors: shipped scenes each have one player choice window; a future second choice during joined peer reading still meets the single-person acquisition gate and needs group-specific handling before authoring that shape. Search remains bounded at8 hardcoded candidates; exposing this cap in JSON is deferred. These are not claims of arbitrary multi-choice peer-story support or a fully configurable planner. Universal corridor arbitration remains epic#3.

## Final Release and ordinary browser persistence

Release source `706d7d0d8a4dee3ec56625db112cc0488ee7c120`, unique engine stem `kiosk-706d7d0d8a4d`. Build-only gate completed Ink compilation,324 localization-reference checks, editor import and Release export; all external shipping content files matched the source byte-for-byte. Native final river chain repeated approach/participation/disabled-policy/order/sleep outcomes. Farid was eligible through existing social topics and began an approach at7.45seconds with the unchanged15-minute base visit (fixture chance1, not a shipping frequency guarantee).

The previous temporary browser profile did not survive environment renewal. Downloaded the immutable prior HUD ZIP, verified SHA256 `201f8541fc6431c27d11a9767f82be724a0a83dc0c7ab2fcca90178ce1273c82`, and used actual Chrome New Game/Save to create a genuine revision15 save. The exact new export at the same origin loaded it through actual Continue, retaining EGP45, rooftop position and16:36 saved time. Actual new Save/reload/Continue retained EGP45, rooftop and16:54 saved time. No synthetic save or gameplay bridge was injected. Screenshots: evidence/2026-10-27-quiet-social/web-rev15-save.png, web-rev15-continue.png, web-rev16-save.png, web-rev16-continue.png. This proves that bounded save path, not every historical narrative branch.


## Implementation decisions and costs

- Explicit world effects currently support NPC-to-NPC relationships only. Other world actions require a new validated effect type.
- V1 has one authored target per initiator and one globally active pair. Multiple-target weighting needs a future policy.
- NPC dialogue selection is independent of player topic history; overhearing a scene does not forbid the characters discussing it again on a later eligible visit.
- Controlled visual fixtures arrange nearby markers and longer choice windows; shipping schedules/geometry/pacing do not force these scenes. A particular ordinary visit may produce no encounter.
- Joined group reading has separate focus/ownership from the one-person hub. Current authored group scenes have a single choice window; a second branching window needs the deferred acquisition change.
- A required, validated default autonomous knot covers untagged choice frames; authors must explicitly tag a different continuation when the common fallback is inappropriate.
- Per developer constraints, no automated gameplay suite was added/run. Build checks, read-only review and bounded native/browser observations provide evidence with narrower coverage than a full regression suite. The finite candidate cap remains8 in implementation; exposing it in JSON is deferred.

## Controlled browser scenes and storage boundary

Exact706d7d0 engine/PCK in Chrome software WebGL960×540: English football offered real choices and entered manual reading with Continue/Leave. Arabic river offered choices, entered manual reading, saved, reloaded and continued at the identical Hassan sentence; Enter advanced to Amgad and Escape detached. Native proofs cover both stories' owner/order/receipt state. Screenshots and console records are under the evidence directory. No page/script error, content/save-candidate rejection or unexpected graph fallback was logged; favicon404 is harmless.

These were copied external-JSON fixtures: seed17, two weighted visitors/capacity2,2-second first arrival/3-second next, no purchases/seating/leisure/player meetings, long300-minute visits, max-wait600, peer chance1/delay1/deadline180, nearby leisure markers(-8,2.7)/(-6.5,2.7), spawn-west(-10,2.7), player(-5.5,3.4), choice expiry120. An earlier fixture placed the player in the approach space; moving away allowed the physical encounter. The fixtures do not establish ordinary shipping frequency or hardware performance and never enter the published content directory.

Important observed existing Web-storage limitation: the English group Save toast was followed by reload after about1.4seconds; Continue was then absent. Read-only IndexedDB inspection found only the language file. The Arabic group run waited12seconds after Save and restored successfully. Ordinary persistence succeeded as recorded above. This bounds an asynchronous durability race; it does not establish a universal safe wait. SaveStore requests browser synchronization and has no durable acknowledgment; rapid navigation must not be represented as guaranteed safe. Tracked as [Web save acknowledgment follow-up#10](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/10) before main integration. The native graph/owner restore itself passed; this is not a rejected saved-story cursor. No storage writes were injected by browser diagnostics.

## Published delivery

[Release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/quiet-social-706d7d0) · [complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/fcb340545b29f6a760d4334cef6750662ccdd103/quiet-social-706d7d0/kiosk-on-the-nile-quiet-social.zip). Artifact commit `fcb340545b29f6a760d4334cef6750662ccdd103`, source706d7d0, 12393457 bytes, SHA256 `b01ae721da310628662a7fe9e6e02ef9e545c4126284c65a62348fca2f05cd12`. Independent GitHub download matched size/hash/CRC, one WASM/PCK, BUILD source/revision16, every external content file and12 authored stories. Previous35 manifest entries/history were retained. No shipping fixture overrides, new build branch or main merge. Detailed download proof is included in the source evidence. Main integration remains gated by#10 and preview acceptance.
