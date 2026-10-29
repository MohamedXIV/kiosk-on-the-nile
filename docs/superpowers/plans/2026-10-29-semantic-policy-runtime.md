# Shared semantic policy runtime — implementation plan for #21

> Implementer: read AGENTS.md, docs/RELEASING.md and the contract below. This is a future implementation plan; no runtime is implemented by this document. The user's standing no-automated-suites constraint overrides generic test-suite workflow instructions.

**Goal:** Add reusable typed role binding, compiled pure decisions and phase-aware entry points, ready for the knowledge/history adapters and content conversion in #22–#24.

**Contract:** [semantic-narrative.md](../../architecture/semantic-narrative.md), with its selected JSON examples. Resolve review findings on #20 before treating that contract as settled. Baseline10143f7; do not presume it is still the branch head when executing.

**Architecture:** Existing owners retain state. New context/evaluator/decision modules compile validated authored rules and query typed read-only providers. NarrativeDirector routes explicitly converted policies through that contract; unconverted legacy topics stay inventoried on their existing path until #24. There is no actor-name fallback inside the new engine.

## Global constraints / review focus

- Offline Godot4.7.2, GDScript, Ink/external JSON, Arabic/English. No runtime inference service or arbitrary content code.
- Preserve renderer batching, quiet pacing, focus/hearing and one-time receipts. No automated suites; retain bounded disposable observation evidence and appropriate tracked checks.
- No VERSION/CHANGELOG/tag/release work during this task. Actual final save/version impact and one complete delivery belong to #26/#27.
- Missing roles under negation; changed actors on resume; self-invalidating teaching/introduction start rules; automatic-choice bypass; stale cached time/domain decisions are priority failure modes.

## Task A — compile and bind

Files: create `game/content/narrative_policy_validation.gd`, `game/narrative/narrative_context.gd`, `game/narrative/policy_decision.gd`; adapt content loading only for the approved contract catalog/schema.

Interfaces: `compile(catalogs, schemas) -> ActionResult`; `bind(topic_id, bindings, presence_handles, stage) -> ActionResult {context}`. Context exposes stable actor roles and typed values separately from ephemeral presence. Decision has allowed/blocked/invalid status, reasons and evidence; it never mutates owners.

- [ ] Implement strict schemas and bounded named-policy/AST expansion (24 levels/256 expanded nodes/8 named levels), reference/role/parameter validation and cycle rejection.
- [ ] Resolve explicit actor/role/binding refs; reject unknown actors, wrong value types, unavailable turn-local roles and substitutions of persisted actor identity.
- [ ] Bounded observations: valid instances resolve; missing/extra bindings, unknown fields, cyclic policies, conflicting role constraints and oversized expansion reject with source/topic/reason information. JSON examples are selected fragments; do not silently accept commentary fields as runtime schema.

## Task B — pure evaluation

File: create `game/narrative/narrative_policy.gd`; adapt `condition_evaluator.gd` as the explicit compatibility/world-query facade. Registered providers are read-only and finite; no method names supplied by content.

Interface: `evaluate(policy_id, context, stage, explain=false) -> PolicyDecision`. Provider capabilities are explicit. An absent per-NPC knowledge/history provider remains invalid/blocked until #22/#23; it never substitutes player knowledge. Initial providers for generic relationship, world clock, presence/channel and existing domain evidence read their current owners.

- [ ] Implement all/any/not with invalid propagation; typed predicates and explicit role/parameter maps; stable ordered reason IDs and evidence refs.
- [ ] Keep compilation out of queries. Begin with indexed reads and no cross-frame Boolean cache. Record call counts/allocations before considering memoization.
- [ ] Bounded observations: a valid absent fact is false, missing role under not is invalid, asymmetric relation differs by direction, clock boundaries and moved actors update decisions, explain and normal modes agree on permission.

## Task C — lifecycle routing without partial content migration

Files: adapt `narrative_director.gd`, `conversation_session.gd`, `personal_conversations.gd`, `ink_runtime.gd` and the approved choice/tag mapping where required. Wiring belongs in `game/app/game_session.gd`.

Interfaces: stage-aware offer/start/choice/continuation/action authorization; stable authored choice IDs; stable binding/start-evidence storage. Transactional effect preparation/knowledge/social implementation remains #22/#23, and actual family conversion #24.

- [ ] Route an explicitly authored disposable converted topic through menu/direct start/automatic offer/manual and automatic choices/resume using the same decision contract. Keep a recorded compatibility list for unconverted paths; never evaluate two conflicting authorities for the same converted topic.
- [ ] Start checks grant no effects. Continuation checks do not rerun consumed start-only predicates; resume verifies role/content/source identity and uncommitted current requirements without replay.
- [ ] No automatic fallback bypasses the converted choice guard. Safe wait/stop when every authored candidate is blocked. Keep refusal/leaving paths available where authored.
- [ ] Bounded compiled-Ink observations: open-unheard-cancel, stale offer/choice, teaching-like start condition changed by its own heard result, current save/load and actor-return resume, wrong-actor binding, repeated effect identity and automatic filtered choice. Any save representation change is explicit, preserving unsupported bytes; no historical migration by default.

## Task D — review and dependency handoff

- [ ] Independently review compiled schema/evaluation and lifecycle routing against the contract matrix; correct material findings with focused observations.
- [ ] Run tracked content/Ink/localization/import/build checks appropriate to actual code changes. Observe aggregate policy work on a recorded four-actor reference fixture; compare against the proposed ≤1ms mean/≤2ms p95 evaluation budget without claiming user-device FPS.
- [ ] Publish exact-source evidence and API/provider handoff for #22/#23; mark remaining knowledge/history/content adapters and diagnostics explicitly. Do not close #24/#26 or produce a release just because the evaluator compiles.

The plan deliberately does not prescribe future NPC knowledge seeds or rewrite finances/workshop simulation. Those are authored/provider decisions tracked by the corresponding issues and the contract's open-decision register.
