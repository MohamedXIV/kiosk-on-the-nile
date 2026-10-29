# Per-character knowledge and heard consequences — #22 implementation plan

> Execute inline with superpowers:executing-plans. Read AGENTS.md, docs/RELEASING.md and docs/GAME_VISION.md. The user's no-suite and delayed version/changelog instructions override generic workflow defaults.

**Goal:** KnowledgeBook owns typed assertions per knower, explicit provenance and once-only heard receipts; one prepared batch publishes all eligible listeners' knowledge atomically.

**Architecture:** Extend KnowledgeBook through a focused KnowledgeAssertions store. NarrativeKnowledge validates optional authored seeds/actions, resolves stable refs and each intended actual listener, and prepares immutable candidates. NarrativeEffects coordinates synchronous guarded publication. Existing player facts/domain owners remain unchanged; no production content converts before#24.

**Tech:** Offline Godot4.7.2, GDScript, compiled Ink and external JSON. **Spec:** [semantic contract](../../architecture/semantic-narrative.md), especially sections3/5/6; [#21 runtime API](../../architecture/semantic-policy-runtime.md).

## Global constraints and review focus

- No VERSION/CHANGELOG/tag/release work. Preserve files and reject corrupt/unsupported saves explicitly; no historical migrations/archive Ink.
- No automated suite. Bounded disposable native observations plus tracked content/Ink/localization/import/Web build gates.
- No invented NPC seeds; explicit authored intended audiences, per-listener distance/location and finite channel rules. Participant membership is not hearing.
- Partial batch failure, stale prepared revisions or reentrant publication must grant no assertions/receipts.
- Relay parent must belong to actual speaker, match the exact term, precede learning and retain original/upstream source; independent paths coexist.
- Missing/forged sources, future timestamps, unknown actors/term arguments, changed content/action identity and cyclic/dangling parents reject restore.
- NPC-only speech can consume start evidence without teaching player; player Journal/heard_beat remain player-only. Save/resume never replays.

## A — canonical owner and authoring

Create `game/narrative/knowledge_assertions.gd` and `game/content/narrative_knowledge_validation.gd`; extend `knowledge_book.gd` and policy reference helpers. Optional `narrative_knowledge` catalog has `initial` seeds and nested `actions[topic][action]`, each with explicit `listeners` and `assertions`. Effects use the approved `effect:semantic|action` Ink tag. Terms use declared fact types and typed literal/resolved arguments. Initial seeds are literal authored knowledge, never synthesized from the player's legacy facts.

- [x] Observe missing per-knower API on base; implement indexed `query`, canonical term keys, separate assertion IDs and provenance paths.
- [x] `prepare(receipts,assertions)` validates candidates without publication; `commit(ticket)` requires matching owner revision. Restore requires exact optional metadata for active catalogs, matching authored seed set and valid records.
- [x] Observe two knowers differ; multiple sources retained; duplicate no-op; bad types/actors/time/parent and stale ticket reject without mutation.

## B — staged hearing and pure query adapter

Create `game/narrative/narrative_knowledge.gd`; wire GameSession and NarrativeEffects. Validate literal `effect:semantic|id`, declared action matches policy_action; reject mixed/unsupported effect batches. Each action has exact authored audience and one or more heard/relayed assertion declarations. Resolve listener per actual eligible actor; use current action/continuation decisions and fresh source identity. Stage all eligible listeners' records, then synchronously recheck and publish under reentrancy guard, no awaits/signals. Unsupported distributed/domain/world effects stay blocked.

- [x] Knowledge policy reads requested knower/typed term/provenance; valid absent assertion is false. Explicit legacy player adapter remains separate.
- [x] Observe unheard/canceled no grant, nearby intended NPC learns while far player does not, out-of-range/other-location/unintended NPC learns nothing; blocked listener does not get effects.
- [x] Observe valid relay to exact listener, upstream retained, wrong-speaker/dangling parent rejects entire batch, all candidate mutations absent on preparation failure.

## C — lifecycle, save integrity and handoff

Adapt Director hearing before player-only early return, semantic proof validation, and SaveCodec cross-links after restoring owners. Canonical semantic receipt can consume episode start; player journal/heard_beat are independent. Validate action declarations, stable role identities, story/catalog hashes and effect receipt ownership. No actual production encounter converts; inventories stay explicit.

- [x] Observe actual compiled Ink with NPC-only hearing, self-invalidating teaching continuation, same-beat repetition, pause/actor-return and current-save restore without replay.
- [x] Corrupt copies with missing receipts/applied IDs, changed recipient, future time, malformed term/parent/action/actor reject; preserve source input bytes.
- [x] One fresh whole-branch independent review; reproduce/fix material findings once. Run tracked Release build; retain raw bounded evidence and #23/#24 API handoff. Close#22 only after exact-source checks and safe integration. No release/version bookkeeping until#27.

Execution/evidence: [delivery record](../../notes/2026-10-29-semantic-knowledge.md). Checkmarks describe #22 foundation; production conversion/social/domain adapters remain separate.
