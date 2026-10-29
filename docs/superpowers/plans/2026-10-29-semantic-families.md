# Semantic content families implementation plan — #24

> **For agentic workers:** Use superpowers:executing-plans inline, with one fresh whole-branch reviewer at the end. Continue the approved #19 contract; no new design approval round.

**Goal:** Move complete invitation, personal relay and recipe families onto the shared semantic authority.

**Architecture:** Keep Ink speech/choices and existing domain owners. Add explicit manual-choice proofs, at most one prepared domain command per batch, then authored knowledge/social families. Do not grant player consent through NPC narration.

**Tech Stack:** Offline Godot4.7.2/GDScript, Ink, external JSON.

**Spec:** `docs/architecture/semantic-narrative.md`, GitHub#24; APIs in semantic-policy-runtime.md, semantic-knowledge.md and semantic-social.md.

## Global constraints

- Read AGENTS.md, docs/GAME_VISION.md, docs/RELEASING.md. Preserve quiet pacing, Arabic/English and save bytes on rejection.
- Standing user instruction: no automated suites added/run. Use bounded disposable native observations retained as text plus tracked content/Ink/localization/import/Web Release gates.
- Existing managed checkout/new feature branch; scratch only ignored `work/semantic-families/`.
- No VERSION/CHANGELOG/tag/archive/release changes until #27; save decision after integrated acceptance.
- No new permanent character; additional actor demonstration is disposable data/Ink only.

## Review focus

- Automatic fallback, stale choice, cursor return and restored choice evidence must never fabricate a player promise.
- Domain failure or stale owner must leave all knowledge/social/reward owners unchanged.
- Hearing, not opening a menu, establishes knowledge; requests/replies/delivery preserve their original parties and subject.
- Own teaching/consumption may block a new episode without invalidating the current continuation.
- Old and converted topics must remain reachable, have one eligibility authority each, and share the daily gain cap.

## Tasks

- [x] 1. Explicit manual-choice evidence: capture stable authored choice ID and source frame on successful actual player choice; recheck it at consequence publication; retain and validate against Journal/content on current-save restore. Add optional action `choice` requirement. Automatic choices cannot supply consent. Observe missing/automatic/stale proofs blocked and accepted proof restored without replay.
- [x] 2. Prepared home adapter: owner exposes readonly capacity/booking query, prepare/can_commit/publish with idempotency/source receipt; coordinator validates every candidate before publishing. Adapt invitation/cancel/company/goodbye; keep landlord/travel/workshop/seating authority and reject stale booking without narrative mutation.
- [x] 3. Convert whole authored invitation, exam/radio relay and recipe families, including actual introductions/company/disclosures feeding them. Explicit source seeds only from existing stories. Preserve exact request→reply→delivery lineage and refusal/postpone; keep unconverted workshop/business routes explicitly inventoried and reachable without duplicate converted gates. Demonstrate extra data-only bindings.
- [ ] 4. Bounded native observations, JSON saves/return, alternate order, Arabic/English, content/build gates and one fresh final review; fix material findings in one focused pass. Safe exact-head merge, update #24/#19/#8 and next #25; report remaining acceptance honestly.

## Interface preflight

1→2: optional choice evidence must travel in common receipt/source, so home owner can require actual player decision independently of NPC speech.
2→3: domain command belongs to exactly one canonical listener; multi-listener domain actions reject rather than publishing the command repeatedly.
3→4: active catalogs change current content identities; no inferred legacy semantic history, archived graphs or silent save reset.
