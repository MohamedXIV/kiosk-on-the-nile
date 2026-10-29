# Generic acquaintance, shared history and relationship progression — #23

> Execute inline with superpowers:executing-plans; read AGENTS.md, docs/RELEASING.md and docs/GAME_VISION.md. Approved contract/repeated continue authorization supplies scope. No automated suites or redundant approval pauses.

**Goal:** Introductions, distinct meaningful days, capped directional gains and purpose-specific consent become generic source-backed state, without character-name branches or commerce requirements.

**Spec:** [semantic contract](../../architecture/semantic-narrative.md), [knowledge/publication API](../../architecture/semantic-knowledge.md). Offline Godot4.7.2/GDScript/Ink/external JSON. Keep existing owners and current tuning. No VERSION/CHANGELOG/release work; no production family conversion until#24.

## A — social owner and directional score preparation

Create `game/social/semantic_social_memory.gd` owned by SocialLife, and `game/content/semantic_social_validation.gd`. Add read-only indexed acquaintance/company/consent/scoped consumption queries. Persist source-backed raw events and rebuild indexes, not trusted saved day/score flags. Calendar days count floor(world_minutes/1440) boundaries from actual direct heard introduction. Company counts distinct meaningful dates independently from capped gains. No initial acquaintance seeds inferred from actor presence/knowledge/score.

- [x] Observe missing generic memory API; implement introduction/company/relationship/consent/consume declarations and strict validation.
- [x] RelationshipStore prepares directional gain candidates using the full actor registry, with revision guards and optional semantic gain receipts. Positive daily cap comes from data; same action/pair/axis/day gain is once only. Company still counts after cap.
- [x] Retain legacy social behavior only on unconverted paths. Fix candidate cloning to preserve new optional knowledge/relationship metadata; notebook uses generic actually introduced player contacts without visitor-only name assumptions.

## B — one atomic heard publication and query providers

Extend optional `narrative_knowledge.actions` with `social` array; allow zero assertions only with nonempty social effects. Resolve actual listener/speaker and typed stable roles. Direct introduction is listener->speaker; company/gains require actual speaker/listener pair; consent requires speaker grantor/listener recipient, exact purpose/scope and explicit grant/refuse/revoke. Player-choice consent must not be inferred from an NPC line; its explicit family adapter belongs#24.

- [x] Stage complete KnowledgeBook hearing receipt, SocialLife memory and RelationshipStore score candidates. Validate every owner/revision before synchronous publication; no await/signals/reentrant or partial effect.
- [x] Add pure acquaintance/consent/unused and finite social-event providers; no cross-frame Boolean cache. Support exact once/day/visit/evidence consumption identities with bound actor/topic/subject context.
- [x] Validate actual beat/source/catalog/role/scope links on current restore; canonical source proof and chosen receipt lineage remain authoritative. Refusal/revocation/expiry block future permission without deleting history.

## C — bounded evidence, review and handoff

- [x] Native observations: directional/new actor identities, high scores vs missing history, midnight calendar boundary, repeated same-day company, idle days alone, capped gains with real company, no-commerce maturation, exact-purpose consent/refusal/revoke/expiry, scoped consumption and stale revisions/partial failures.
- [x] Actual temporary compiled Ink: NPC-only social hearing, independent listener eligibility, self-invalidating consumption continuation, actual JSON current save/paused actor return without replay, malformed actor/source/order/day/scope/gain rejection and ordinary production legacy save shape.
- [x] One fresh whole-branch review and one material fix pass; tracked pinned Ink/localization/import/Web Release build; retained evidence/decision ledger, exact-source PR CI and safe integration. All49 production encounters remain legacy until#24; #25 author tools/#26 integrated acceptance/#27 final closeout remain explicit.

Review focus: social-only receipt must not fabricate assertions/player hearing; whole-batch failure cannot leave scores changed; directions/full household/supplier actor view; capped scores must not erase a shared day; refusal/revoke/expired/wrong-purpose consent never bypassed by high scores; repeated/resumed/retargeted occurrence must retain exact source and business scope; malformed saved event types must reject cleanly before field access.

Execution/evidence: [delivery record](../../notes/2026-10-29-semantic-social.md). Checkmarks cover #23 foundation, not #24 family conversion or final epic acceptance.
