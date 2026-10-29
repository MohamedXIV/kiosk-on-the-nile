# Generic social memory and relationship progression — #23

This extends the [policy](semantic-policy-runtime.md) and [knowledge/publication](semantic-knowledge.md) foundations. SocialLife owns source-backed social memory; RelationshipStore remains the score owner. All49 production encounters remain on inventoried legacy routes until#24. No production dialogue, seeds or tuning were changed.

## Authoring

The [validated three-section example](examples/semantic-social-v1.json) merges into an in-memory bundle. It has no manifest/encounter opt-in and grants no production relationships. An optional `narrative_social` section declares exactly `daily_gain_cap` (finite0..100); absent tuning uses existing `social_life.relationships.daily_cap`12.

Each `narrative_knowledge.actions[topic][action]` may add `social`, an array of at most16 declarations. `assertions` remains required but may be empty only when social effects are nonempty. The matching Ink `policy_action:id` plus `effect:semantic|id` commits the whole eligible-listener knowledge/social batch. Actor refs and typed bindings use the existing contract, including declared actual turn roles.

| Kind | Required fields besides `kind` | Source/meaning |
| --- | --- | --- |
| `introduction` | `observer`, `other` actor refs | Direct actual listener→speaker introduction; no automatic mutual acquaintance or absent third party |
| `company` | `observer`, `other` | Either authored direction of the actual speaker/listener pair; one distinct calendar date per pair, separate from gains |
| `relationship` | `from`, `to`, `axis`, finite `amount` in−10..10 | Explicit direction between actual speaker/listener; same topic/action/pair/axis/day gains once, with a shared positive daily budget |
| `consent` | `grantor`, `recipient`, literal `purpose`, string/ref `scope`, `decision`, `duration` | Actual speaker→listener `grant`, `refuse` or `revoke`; grant duration1..43200 game minutes, other decisions duration0 |
| `consume` | `scope`, nonempty `actors` array; optional `evidence` string/ref | Once/day/visit/evidence business consumption for actual participants; evidence scope requires evidence |

High scores, presence, knowledge and mere waiting do not establish introduction, meaningful company or consent. Introduction and shared dates are separate; company does not silently introduce actors. Calendar age counts floor(world_minutes/1440) boundaries from the actual introduction, not real24-hour durations. Shared dates count actual heard company independently; repeated speech on one date gives one shared day even after positive score gains are exhausted.

Positive gain caps use the existing numeric tuning. Negative authored gains also deduplicate per action/pair/axis/day. The budget delta is applied through RelationshipStore's existing bounds; reaching a score bound does not fabricate a new shared day. Compatibility bridges share NPC→player positive budget with unconverted SocialLife moments in either execution order. Each semantic event retains the validated legacy usage observed at preparation so later legacy events do not retroactively change its capped delta. Legacy candidate forks preserve complete knowledge/relationship metadata and the full visitor/household/supplier actor registry.

## Queries and consent

`SocialLife.memory.acquaintance(observer,other)` returns introduced, introduced_at, calendar_days, shared_days and source. Indexed data rebuilds from raw source-backed events, never saved allowed/day flags. Existing notebook people merge actual player introductions with legacy contacts, use full presence profiles, retain directional score stages and include history metadata. A numeric stage is not permission to invite someone.

Pure policy providers now implement `acquaintance`, `consent`, `unused` and finite `event` query `social.occurred` with typed `{kind:introduction|company, observer:ActorRef, other:ActorRef}`. Unknown event IDs/kinds/roles fail closed. Consent matches exact grantor/recipient/purpose/scope; latest explicit refusal or withdrawal blocks future use, and permission expires at its boundary. Historical grants remain recorded. No relationship score substitutes for it.

Consent on this heard route must come from the actual speaker. An NPC cannot grant the player's consent through narration. The explicit player-choice/request/booking adapter remains#24 along with family conversion; this foundation does not claim a home reservation or message delivery happened. Money/workshop/home commands still require prepared domain adapters.

Consumption keys retain stable topic/bindings/roles and ordered actor subjects. Day scope adds current calendar date; evidence scope adds exact evidence; visit scope adds canonical actual non-player visit handles. Missing handles are invalid, never actor-name fallback. Declared turn-role actors receive the same validated participant handles as stable roles. Returning actors can reopen a new visit scope, while once/evidence consumption stays committed. The episode can continue after its own consumption invalidates a start/action rule.

## Atomic state and save integrity

NarrativeEffects validates all KnowledgeBook, SocialLife memory and RelationshipStore candidates/revisions before synchronous publication with no await/callback/signal. A failed second effect, invalid participant or stale owner ticket leaves all owners unchanged. Source proofs retain actual committed frame, explicit declarations, capped events and an independently captured participant actor→handle view. Restored receipt visits must equal the canonical stable/turn-role projection of that actual presence evidence; editing both receipt copies alone cannot retarget a consumed visit.

SocialLife adds optional `semantic_memory:{events}` only for an active social catalog. RelationshipStore adds optional `semantic_gains`; common hearing receipts can have no assertions but must contain actual social effects. NPC-only social hearing consumes start evidence without asserting player facts, Journal speech or heard_beat. On restore raw events rebuild indexes and caps, reconcile actual source/frame/catalog/actor/role/scope evidence and gain receipts, and reject malformed/future/dangling/retargeted data. Source checking is authoritative-owner consistency, not cryptographic protection against rewriting every owner/checksum.

Production empty catalogs retain legacy serialized shapes. Active metadata must be present/valid; source inputs and unsupported save files are not reset or deleted. No historical migration/archived Ink graph was introduced. VERSION0.2.1-prealpha.1, schema4/revision20 and CHANGELOG remain unchanged; final coherent save/version/new-game decision is#26/#27.

Queries use per-pair/date/consent/scope indexes without full-history snapshots or Boolean caches. Actual consequence preparation/rebuild validates recorded state; no destructive history pruning is claimed. Long-session memory and integrated player-device performance remain#26.

Next: #24 converts invitations/relays/recipe families and explicit player request/consent/domain adapters, preserving actual scopes and one authority per converted topic; #25 author tools; #26 integrated acceptance; #27 final version/changelog/one coherent preview.
