# Companionship and Workshop Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Native inline execution is already selected.

**Goal:** Quiet companionship and a consented, saved workshop trial with meaningful follow-up.
**Architecture:** A SocialLife service owns semantic actions, shared moments and the world activity. Ink owns speech, JSON owns authored rules, and existing knowledge/relationships retain their ownership. UI derives topics and relationships without revealing unlearned events.
**Tech Stack:** Godot 4.7.2, GDScript, Ink, external JSON.
**Spec:** `docs/superpowers/specs/2026-10-23-companionship-and-workshop-trial-design.md`

## Global Constraints

- Preserve existing stories, topic IDs and active Ink saves; schema4/revision7 migration adds empty social state.
- No forced visits, maximum four people, independent purchases, shared GameClock, no permanent employment economy.
- Do not add or run automated tests. Compile/import/export and actual UI review provide evidence; disclose unreviewed cases.
- Continue in the authorized `work` checkout. Existing preview publication authorization applies; do not merge main.

## Review Focus

- Sleep/time jumps and an occupied participant must never create simultaneous corniche/workshop presence.
- One consent, declined invitations and unseen world results must not become knowledge or agreement.
- Active choice saves and old saves retain their exact speech and semantic receipts.
- Both disclosure orders and late schedule agreement converge without repeating the trial or rewards.
- Failed content/action/save candidates must not partially publish state, knowledge or relationships.

### Task 1: Social state, activity and persistence

**Files:** create `game/social/social_life.gd`, `game/content/social_life_validation.gd`, `content/social_life.json`; modify session wiring, finite conditions, migration/save validation and time dependencies.
**Interfaces:** `SocialLife.configure(session)`, `available(action_id)`, `apply(action_id, source) -> ActionResult`, `tick(frame)`, `snapshot/restore`, `reserved(actor_id)`, `people()`.

- [x] Author finite action IDs, provenance, separate consents and day agreements, candidate transactions, once-only relationship moments and daily caps.
- [x] Implement next-day coordination, lead-window reservation, delayed start until both physically absent, actual start/end/outcome and late agreement.
- [x] Integrate save revision7, migration and strict state/reference validation; build/import.

### Task 2: Authored dialogue and companionship

**Files:** new `content/stories/companionship.ink`, encounter/topic declarations; modify InkRuntime, NarrativeEffects, NarrativeDirector and VisitorPanel.
**Interfaces:** finite `effect:social|action_id`; topic listing and explicit encounter start; invitation wait uses shared frame and saved per-visit state.

- [x] Author acquaintance, disclosure, referrals, individual consents, days and truthful first-day/study follow-ups for both voices.
- [x] Implement invitation separate from disclosure consumption; silence listens, refusal/walkaway consumes no personal information.
- [x] Preserve order recall and old personal topics; reject failed effects before displaying their claimed event; compile Ink and export.

### Task 3: Relationship notebook and manual acceptance

**Files:** notebook/main/probe, evidence notes and delivery docs.

- [ ] Show heard people, affinity and authored stages; expose only learned connection evidence.
- [ ] Review both story orders, refusal/silence, coordination, trial/result/late days, saved choices and legacy migration via actual UI; record exact coverage and limitations.
- [ ] One fresh whole-branch reviewer; address material findings, rebuild and commit exact product.
- [ ] Publish preview source and downloadable artifact on GitHub with source SHA and checked ZIP digest.
