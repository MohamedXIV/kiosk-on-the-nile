# Semantic narrative contract v1

Design deliverable for [#20](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/20), parent [#19](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/19). Recorded2026-10-29, Africa/Cairo. Audited source:10143f7973bfea84332025241049621f85d13475. **This is a proposed implementation contract, not an implemented runtime or a published release.** The user selected reusable deterministic semantics over case-by-case character fixes. Developer tuning below remains revisable through documented authoring changes.

## 1. Audit and ownership

The baseline contains49 encounters,22 encounter topics,31 SocialLife topics,30 social actions and6 message actions. These are distinct catalogs, not114 independent conversations. No encounter currently authors nonempty `choice_conditions`, although the runtime supports them.

| Existing owner / code | Reuse | Gap / conversion boundary |
| --- | --- | --- |
| `game/narrative/condition_evaluator.gd:validate,permits` | Finite declarative operators, world adapters | Every query revalidates its rule. `acquaintance` accepts named Farid/Youssef/player-participant profiles; numeric visit count defaults to Amgad; `fact_known` queries only the player's book. Replace these semantic branches with compiled typed role queries. |
| `knowledge_book.gd:has,learn,learn_from` | Catalog, notes, source metadata, snapshot validation | One player-facing fact map; first-learn wins. Generic learn tags retain a source but no speaker/time; social actions add them. Extend this owner to per-knower assertions/provenance, retaining player notebook adapters. Do not create a second knowledge ledger. |
| `relationship_store.gd:value,adjust` | Generic directional familiarity/trust and bounds | Already role-independent. Keep it as the sole score owner. Social eligibility uses NPC→player; some legacy speech/hospitality uses player→NPC. Bind direction explicitly; do not globally reverse existing behavior. |
| `game/social/social_life.gd` | Receipts, meaningful moments, daily cap, consent/message lineage, staged knowledge/relationship changes | Introductions are inferred from `meet_`+actor; meaningful days from positive daily gains; named workshop/consent/result branches coexist with generic actions. Generalize social memory inside this owner; retain workshop activity as its domain behavior. Its transaction currently constructs a relationship actor set from visitors+player; generalization must use the full validated actor view (presence profiles plus player), including household/supplier actors where authored. A day of meaningful company must not disappear merely because its score gain hit a cap. |
| `conversation_history.gd:select,commit,restore` | Once/day/visit/evidence consumption, consumed only by heard speech | VisitState-typed selector and special service/recipe evidence. Keep repetition ownership, add actor/role bindings and typed evidence queries. Do not duplicate consumption in a new policy ledger. |
| `narrative_director.gd:start,manual_topics_for,choices,choose,_advance,_hear_current,restore,resume_record` | Ink lifecycle, hearing receipt, focus, choice identity | Decision logic is spread across encounter/topic/action rules, hardcoded home/social mappings and Ink context projections. Centralize semantic decisions while preserving lifecycle and domain guards. Automatic choice fallback currently bypasses authored choice filters: conversion must apply the same semantic guard to automatic choices. |
| `personal_conversations.gd` | One focus, actor-keyed paused Ink | Home/payment-specific pause exclusions remain lifecycle/domain decisions. Persist stable actor roles; rebind visit handles on resume without changing actor identity. |
| `narrative_effects.gd`, `ink_runtime.gd` | Validated finite effect tags, occurrence dedup, world/hearing distinction | Social/home effects have separate eligibility; multiple line effects apply sequentially. Introduce validated semantic action references and staged consequence batches; keep financial/service providers authoritative. |
| `game/actors/actor_presence.gd`, `residential_visits.gd` | Presence over kiosk/home/supplier owners, actual availability, invitation/spawn/priority | Presence is an adapter, not acquaintance/knowledge. Residential visit owner retains reservation/window/landlord/exclusivity/seat rules; its semantic maturity checks become policy queries. No duplicate populations. |
| `game/content/{feature_content_validation,social_life_validation,story_message_validation,account_validation}.gd` | Shape checks, references, action-cycle and message lineage validation | Add contract/policy/role checks once at load/build. Current cycle check cannot prove arbitrary Ink reachability. AccountValidation currently restricts home friend IDs to Farid/Youssef and at most two configured candidates; #24 must remove the name whitelist for converted content while preserving one actual household guest. |
| `game/app/game_session.gd`, `game/persistence/save_codec.gd` | Owner wiring, candidate restore, cross-links, corruption/reset feedback | Wire providers once; validate current candidate links before install. Save20 remains unchanged in this documentation task. Future representation/save impact is decided after implementation. |

Files are relative to the repository; narrative filenames above are under `game/narrative/`. World truth remains in service/cooking/learning/accounts/travel/visit owners. Locale services retain stable text IDs and captured historical wording. No policy engine owns movement, placement, money, recipe completion or attendance.

## 2. Approach and non-goals

Three approaches were considered: keep adding actor-specific conditions (low initial effort, repeated gaps); replace Ink with generated freeform dialogue (changes authorship/offline guarantees and does not ensure grounded consequences); compile a small semantic contract over existing owners (chosen direction from the conversation). The last preserves authored Egyptian speech and supports new combinations without engine-name checks.

Semantic categories describe intent and requirements, not an automatic source of story content. NPC assertions are attributed knowledge, not a theorem that the asserted world fact is true. v1 does not add probability, NLP inference, embeddings, unrestricted code/expression evaluation, or an autonomous conversation generator. Existing world-event outcomes can confirm an assertion through a declared source; contradiction/belief-revision storytelling is explicitly outside v1.

## 3. Identity, bindings and facts

- Actor IDs are stable catalog identities; a visit/residential ID is an ephemeral presence handle. Saved role bindings retain actors, never only an array position or current speaker name.
- Each topic declares typed bindings (`actor`, `recipe`, `location`, `event` as needed). An actor reference is exactly one of `{"role":"guest"}`, `{"actor":"player"}`, or `{"binding":"guest_actor"}`. No interpolation, string concatenation or executable lookup.
- Stable episode roles include `initiator`, `partner`, `host`, `guest`, `teacher`, `student`, `sender`, `recipient`, `courier`, `subject`. The author declares only those used, with any equality/inequality requirements. `speaker` and `listener` are turn-local roles resolved from validated speech/hearing; they are unavailable to a start rule unless explicitly bound for that stage. A missing role is invalid, not an absent fact.
- `bindings` provide typed catalog values; `roles` resolve actor bindings. Persist the concrete binding values and role actors with the episode's contract/content identity. Rebinding a returning visit must resolve to that same actor.
- A fact term is `{"type":"recipe_connection","args":{"person":ActorRef,"recipe":{"binding":"recipe_id"}}}`. Each fact type declares argument types. Canonical identity is its type plus sorted typed resolved arguments, not localized text.
- The extended KnowledgeBook stores assertions by `(knower, fact-term, provenance-id)`, with origin kind, immediate speaker/source, learned time and parent provenance when relayed. Multiple independently sourced assertions can coexist; notebook projection need not repeat text. Initial knowledge has an explicit authored seed source, not fabricated speech.
- `knows(knower,term)` means an accepted, attributed assertion exists. Rules may restrict provenance kinds (`initial`, `heard`, `relayed`, `observed`). World-state predicates query their domain owner separately. Knowing a speaker's recipe connection does not establish that the student knows the recipe or has cooked it.
- Heard effects target each actually eligible listener independently. A scene participant, player fact, journal entry or same-venue actor does not implicitly teach every NPC. Per-listener hearing must use the applicable distance/visibility/channel rules, extending current player hearing deliberately rather than equating presence with hearing.

## 4. Policy shape and finite queries

Authoring examples live in [examples/semantic-narrative-v1.json](examples/semantic-narrative-v1.json). They are contract examples, **not files consumed by the current game**. Top-level catalogs: `fact_types`, `profiles`, `policies`, `actions`, `topics`, `instances`. Every ID is unique within its catalog. Unknown keys/operators, wrong types, absent bindings and invalid catalog references are errors.

Rules are an AST with `op` and operator-specific fields. All/any children are nonempty. Proposed v1 operators:

| Operator | Inputs and semantics |
| --- | --- |
| `all`, `any`, `not` | Ordered rule children; invalid propagates through every logical operator, including `not`. A valid unknown fact is false; an invalid role is never turned into permission by negation. |
| `policy` | Named policy plus an explicit role map; checked finite references, no cycles. Profiles supply data thresholds, not an engine enum of three fixed categories. |
| `relationship` | Explicit `from`, `to`, axis, comparison and numeric threshold/profile field. Reads RelationshipStore only. |
| `acquaintance` | Observer/other plus minimum calendar-day boundaries since heard introduction and distinct meaningful shared days. Reads the generalized SocialLife memory. Scores, age and company are separate conditions. |
| `knowledge` | Knower, typed fact term and allowed provenance kinds. Reads KnowledgeBook assertions, not world truth. |
| `event` | Typed occurred event/action, bound actor roles, scope/evidence and optional chronological predecessor. A domain event adapter returns a source receipt, not a synthetic claim. |
| `consent` | Grantor, recipient, purpose, scope; requires an actual unexpired, unretracted consent receipt. Relationship strength never substitutes for consent. |
| `domain` | A finite registered query ID with typed arguments; domain owner supplies the decision/evidence. No content method names or arbitrary callbacks. |
| `available`, `near`, `time_window` | Current presence/interaction/channel/time reads with explicit participants/clock; independent of relationship. |
| `unused` | ConversationHistory once/day/visit/evidence consumption, including the resolved roles/fact subject in its scope key. |

Literal comparisons use a finite validated comparison enum, never expression strings. Profile references are typed numeric fields. Parameterized policy calls explicitly map their caller roles and typed parameters; a numeric profile reference is `{"parameter":"profile","field":"familiarity"}` resolved from the caller-supplied validated profile catalog. Initial safety limits:24 AST levels,256 expanded nodes per policy,8 named-policy expansion levels; cycles and overflow reject at compilation. These are implementation limits to verify in #21, not measured runtime capability.

Decision: `status=allowed|blocked|invalid`, `allowed`, stable `reason_ids`, typed evidence/source references and relevant state revisions. Invalid is always blocked and separately diagnosable. Evaluation is pure: no randomness, learning, relationship gain, topic consumption or domain commands. Every potentially invalid leaf is evaluated before permission is granted, even under an `any` whose earlier child is true. There is no Boolean short-circuit in v1; normal mode may omit extended explanation formatting, but must produce the same status/permission as explain mode. Developer `explain` mode reports the ordered failed leaves without exposing future story details in player UI. Reason IDs are stable/localizable; state revision is not permission evidence.

## 5. Lifecycle: one evaluator, different stages

One decision contract does **not** mean applying the topic's start rule again at every beat.

| Boundary | Required checks / consequence |
| --- | --- |
| Offer/menu | Binding validity, start eligibility, channel/presence and unused scope. No mutation; developer explanation optional. |
| Start | Re-evaluate start eligibility and physical/domain guards. Capture stable bindings and verifiable start evidence; opening alone does not consume or teach. |
| Choice | Re-evaluate declared choice and continuity rules against current state; use the same guard for manual and automatic choices. A stale choice cannot execute consequences. If no authored valid fallback exists, stop/wait safely, not choose a filtered-out option. |
| Continuation | Recheck continuity requirements such as same actors, hearing/focus/channel and valid domain reservation. Do not invalidate the episode just because its own introduction/teaching/once receipt is now committed. |
| Heard consequence | Verify actual speaker and each intended listener, fresh action requirements and domain preconditions. Commit the authored action once only after eligible speech or explicitly authorized world event. |
| Unheard/cancelled | No hearing-derived knowledge, meaningful-company receipt or topic consumption. Already committed effects remain; cancellation is not a rewind. |
| Pause/load/resume | Validate current content identity, roles, provenance/start evidence and committed progress; rebind presence handles to the same actors. Recheck continuity/choices/uncommitted actions. Never replay heard effects, trust a saved allowed flag, or grant effects to make a saved cursor eligible. |

Start evidence records resolved roles, policy identity, time and source receipt IDs, including the pre-consumption scope. Validators reconcile it with the current owners, heard receipts and chronology. A bare cached decision or unverified author flag is not a start proof. Unconsumed openings whose start conditions have changed must be re-evaluated; consumed episodes can continue under continuity rules. Where a historical absence predicate cannot be independently reconstructed, the verified heard-start receipt and current content/cursor consistency are the authority; do not fabricate a historical world snapshot.

For example, recipe teaching starts only while the student does not know the basics. After hearing the teaching line the student knows them: the same episode/choices remain valid, while a fresh teaching episode is unavailable. This distinction is mandatory for #21/#24/#26 and must cover full save/load and actor-return resume.

## 6. Consequences, shared history and consent

Authored Ink retains speech, choices, localization and branches. A proposed finite tag `effect:semantic|<action_id>` refers to a validated action definition; no arbitrary field assignment. Existing tags remain only until their individual conversions are recorded. Choice guards use stable authored choice identities mapped by the Ink adapter, not mutable rendered indices.

NarrativeEffects coordinates action authorization and idempotence. SocialLife remains the social receipt/history owner; KnowledgeBook owns assertions; RelationshipStore owns scores; ConversationHistory owns topic scopes. Commit protocol:

1. Resolve roles/source and validate the complete consequence batch against current owners, including duplicate keys and consent.
2. Prepare candidate social/knowledge/relationship/history changes and any domain command. No publication or signals during preparation.
3. Recheck changed preconditions, then synchronously publish the prepared result and receipt under a reentrancy guard; emit presentation signals afterward. No await inside commit. Failure publishes no narrative reward/knowledge/consumption.

A semantic action may address at most one mutating domain provider in v1; reject authored bundles requiring an unimplemented distributed rollback. That provider must expose prepare/commit semantics with validated tickets, an idempotency key, and failure-without-mutation. Do not assume existing callbacks already provide this. Unsupported providers remain explicit domain actions until adapted; a policy evaluator never takes ownership of money/cooking. If preparation awaits, reauthorize when it returns.

Occurrence identity includes episode/beat/action/target; business scopes (once/day/evidence/message) are also checked so a new menu/session cannot duplicate a reward. Preserve the original recipient and upstream provenance through request→reply→delivery. A user choosing a promise is an explicit consent/request event, not evidence that a reply or delivery already happened. Refusal/postponement has its own authored outcome; expiry/retraction affects future use, not recorded history.

Meaningful introduction/company is recorded from actual eligible speech/events separately from score gain. It is once per pair/day for day counting, with capped authored gains; repeated clicks, one-day grinding and waiting alone do not create additional shared days. A capped gain does not erase a real shared encounter. Player→NPC and NPC→player gains are separate explicit consequences. NPC→NPC changes need actual authorized participants/events. Existing numeric tuning is retained initially unless a conversion documents a reason to alter it.

## 7. Three representative families

The example JSON uses only authored instance IDs/bindings; runtime predicates contain no Farid/Youssef or topic-name branches.

| Family | Start / evidence | Choices and commit | Original domain owner |
| --- | --- | --- | --- |
| Home invitation | Guest→host familiarity/trust plus host's heard introduction/meaningful company; host/guest valid and available | Offer, decline/postpone, explicit accept grants invitation-scoped consent; actual booking rechecks slot/window/reservation. Do not require an acceptance receipt before presenting the acceptance choice. | ResidentialVisits retains one household guest, landlord priority, travel/workshop/population exclusivity and seating. |
| Relay | Courier knows both sender/recipient with aged/shared history and the actual relevant subject; sender's actual request/consent heard | Request, reply and delivery each reference their exact predecessor and intended recipients. Only the actual listener learns that message stage; optional decline does not create a request. | SocialLife message receipt lineage; world/workshop outcomes stay in their owners. |
| Recipe | Student heard teacher's recipe connection; teacher has authored/source-backed recipe knowledge; no taught-basics assertion yet | Heard explanation teaches the student; continuation survives learning it. Attempts/results require the student's taught basics and actual RecipeLearning/Cooking evidence. | KnowledgeBook for learning; RecipeLearning/workflow for actual cooking evidence, not a speech claim of success. |

The illustrative home profile keeps30 familiarity/6 trust/3 elapsed calendar days/3 shared days; personal and relay tuning also remain data. Calendar days are floor(world_minutes/1440) boundaries; elapsed real24-hour durations require a separately named predicate. Introduction/history is observer-specific; a speaker saying a name once is not automatically mutual friendship.

## 8. Acceptance matrix for later implementation

| State / action | Expected |
| --- | --- |
| New actor bound through authored data/Ink | Uses all three families without engine-name edits. |
| Unknown role under `not knowledge` | Invalid/blocked, never allowed. |
| NPC knows a recipe, player only meets NPC | Recipe question unavailable until player hears the connection. |
| Player learns a fact, unrelated NPC nearby/out of hearing | NPC does not automatically learn it. |
| Two valid independent sources / relayed assertion | Both provenance paths retained; relay parent/recipient verified. |
| High score, introduction today / three idle days alone | Mature-home policy blocked. |
| Repeated same-day company / capped daily gains | No duplicate gain/day; genuinely heard company still counts independently of capped score. |
| A→B strong, B→A weak | Direction-specific policy can differ. |
| Consent missing, expired, retracted or for a different purpose/recipient | Consequential action blocked; refusal/leave stays possible. |
| Sender/recipient known in either order, subject unheard | Relay blocked until the actual subject/request is heard. |
| Valid request then reply/delivery repeated or retargeted | First authorized commit only; duplicate idempotent, retarget rejected. |
| Valid teaching start, own teaching line changes knowledge | Continue/save/resume succeeds; fresh teaching start is blocked. |
| Menu visible then actor leaves/domain slot disappears | Start/choice/action recheck blocks stale consequence. |
| Start outside hearing then cancel | No learning, company or consumption. |
| Returning actor gets a new visit ID / different actor reuses a slot | Same actor may resume under continuity; identity substitution rejected. |
| Automatic choice is filtered by policy | No bypass; valid authored fallback or safe wait/stop. |
| Malformed source/time/role/scope or current-save receipt | Clean rejection; current session and existing save files retained. |
| Domain prepare fails / second effect invalid | No partial narrative knowledge/reward/consumption. |
| Arabic/English switching and historical captured text | Stable source/choice/effect IDs; wording never becomes an eligibility key. |
| Four nearby actors / world clock boundary | Matched bounded policy/frame measurement; no full-world validation/snapshot copy in hot queries and no stale time-cache permission. |

These are acceptance scenarios, not a new automated suite. Use bounded disposable observations plus tracked content/Ink/localization/import/build gates and independent review under the standing user constraint.

## 9. File/API boundaries and performance

Proposed additions under `game/narrative/`: `narrative_context.gd` (typed bindings/stage resolution), `narrative_policy.gd` (compiled pure evaluator), `policy_decision.gd` (decision/reasons/evidence). Add `game/content/narrative_policy_validation.gd` for compilation/reference checks. Exact names may change in #21 with a recorded mapping; responsibilities must not merge into a second game session.

Proposed contract interfaces:

```text
compile(catalogs, actor/fact/domain schemas) -> ActionResult {compiled policies}
bind(topic_id, authored bindings, presence handles, stage) -> ActionResult {NarrativeContext}
evaluate(policy_id, context, stage, explain=false) -> PolicyDecision
prepare(action_id, context, occurrence, hearing_evidence) -> ActionResult {prepared transaction}
commit(prepared transaction) -> ActionResult {receipt/source IDs}
```

ConditionEvaluator becomes a compatibility/world-query facade over the shared evaluator while remaining legacy policies are inventoried. Director, SocialLife and domain adapters call that same contract; they may still reject an action for lifecycle/physical/domain reasons. Decision reasons compose those denials, not falsely claim a pure social policy guarantees successful seating/payment.

Start with compiled immutable rules and indexed reads; no persistent decision cache until measured need. If frame-local memoization is introduced, keys include concrete roles/bindings/stage and all consulted revisions. Cross-frame caching additionally needs clock next-boundary invalidation and live position/presence/consent/domain revisions; never cache a bare Boolean. Revisions are invalidated at owner mutation points, not inferred from localized text. Whole-state deep copies are reserved for effect preparation/save, not eligibility checks.

Initial acceptance CPU target for #26: aggregate semantic decision evaluation at four nearby actors ≤1ms mean /≤2ms p95 on a recorded reference fixture, with matched old/new conditions and invocation counts. This is a proposed engineering budget, not a measured claim or a player-device FPS guarantee. If unmet, inspect calls/allocations and document the resolution rather than silently relaxing the target. Preserve the existing render batching; avoid binding all topic scans to every HUD redraw.

## 10. Authoring, conversion and decisions still open

Compile once at content load/build. Validate typed roles/terms, operator fields, bounded expansions, declared initial/world/heard sources, action/choice/Ink references and dependency cycles. Warn on analyzable contradictory thresholds or missing source paths; distinguish errors from incomplete reachability analysis. Arbitrary Ink reachability is not statically proven. Explain mode is developer-only and uses the same evaluated rules.

Execution sequence: #21 context/evaluator/boundaries; #22 per-knower provenance and staged effects; #23 social memory/relationship semantics; #24 three families and an extra data-only actor; #25 authoring validation/diagnostics; #26 integrated evidence/review; #27 final delivered changelog, version/save decision and one verified complete preview. Shared interfaces must settle before dependent tasks; #25 can develop alongside #24 once the contract/runtime interfaces exist.

Keep old adapters only for explicitly inventoried unmigrated topics. Record every remaining character-specific branch and whether it is an authored domain responsibility or unfinished semantic conversion; do not claim all finance/service/workshop code becomes generic in #24. No indefinite duplicate eligibility paths. The new actor demonstration is disposable authoring evidence, not an unsolicited permanent character/story addition.

Open authoring decisions for implementation review: which existing NPCs receive initial knowledge seeds; which current disclosures intentionally remain first-day casual talk; final role/choice IDs on converted Ink; retention/compaction of long social/provenance histories while preserving dependent receipts. Defaults: only explicitly authored initial knowledge, preserve currently documented social tuning, never infer unknown NPC knowledge, no destructive history pruning. These do not block the generic evaluator but must be resolved before declaring #24/#26 complete.

Save representation is likely to change when assertions/start proofs/general social history are implemented; the actual revision/reset decision belongs to that change and final closeout. Prefer explicit new-game handling for unsupported unpublished saves; preserve bytes and corruption safeguards. No historical migrations/archived Ink graphs by default. **Do not change VERSION, CHANGELOG, schema constants, tags or releases for this design-only delivery.** The user's instruction defers version/changelog closeout until the coherent work is finished.

## 11. Review record

Independent read-only review compared this document, examples and #21 plan with baseline source. One Important ambiguity was corrected: invalid propagation cannot coexist with Boolean short-circuiting that ignores an invalid `any` branch. v1 now evaluates every potentially invalid leaf, and normal/explain decisions must agree. No other blocker was reported. JSON/link/inventory checks are documentation checks, not runtime acceptance.
