# Complete playtest preview Implementation Plan

> **For agentic workers:** Inline root integration with independent parallel presentation and bounded pacing tasks; one fresh whole-branch read-only review.

**Goal:** Complete remaining #6/#7 scope and deliver one combined preview for user feedback.
**Architecture:** Existing social/finance/grid/native UI owners; SeatCatalog stays sole seat geometry source. SeatUse adds only player/home reservations and VisitorSeating external ownership checks. ResidentialVisits remains sole home visit owner.
**Tech Stack:** Godot4.7.2, GDScript, Ink, JSON, Arabic/English.
**Spec:** docs/superpowers/specs/2026-10-28-complete-preview-design.md

## Global Constraints
Read AGENTS.md, GAME_VISION.md, RELEASING.md. Latest user includes deferred home guests and delegates implementation choices; no further design permission round. No automated suites, old-save campaign, NavMesh, crowded background or silent save reset. New-game requirement19, immutable releases and existing artifacts branch.

## Review Focus
Exclusive seats across player/kiosk/home; occupied item movement/cleaning; interruption/stand safety; save validation and no duplicated actor across venues; invitation truth/Ink effects; final source/archive provenance; honest visual/audio/economy evidence.

### Task1: Root seating/home visits
- [x] Shared slot availability, explicit player sit/stand, occupied furniture guards and actual presentation.
- [x] Optional known-friend invitation/cancel and grounded home conversation; landlord/friend seating with safe fallbacks and lifecycle.
- [x] Strict current-save19 restoration and human old-version message; localized UI/Ink and bounded observations.

### Task2: Parallel presentation and mixed pacing
- [x] Tangible procedural world/prop polish and source-based existing sound review; no geometry change from drawing.
- [x] Actual-owner multi-week mixed play observations; narrow grounded tuning if necessary, evidence/limits.

### Task3: One combined delivery
- [x] Integrate, fresh independent code review and one material fix pass; no automated suites.
- [ ] Build exact committed source, complete Web package and native/browser interaction observations.
- [ ] One downloadable preview, guide, roadmap/issues synchronized. Retain human feel acceptance for user's single playtest.

## Rulings
User no-suite policy overrides skill TDD/suite defaults. User all-scope request supersedes prior exclusions and presentation approval gates. Player feet stay at a nearby clear access position while body adopts seat pose; movement stands immediately. One existing home-visit owner avoids duplicate population and save owners.

## Execution ledger
Task1 complete: actual Ink/seat/invitation/current-save19 owner observations, seated landlord channel, native E/movement, explicit unsupported save UI/file-preservation.
Task2 complete: scoped presentation and mixed-week agents delivered source/evidence; root verified final import and native rendering. Adopted tea12/kebda28 to support low-volume economy without more arrivals.
Review: three Important areas plus minor wording fixed in one pass; before/after logs demonstrate blocked-access rejection, released guest claim, waiting workshop/current restore and visible new-game message with unchanged files.
Ruling: when a guest seat route fails, abandon that seat attempt for the visit and preserve safe standing fallback; this avoids endless reclaim and does not force speaking people to move.
Ruling: development target0.2.0-prealpha.1 and one complete CI playtest package; no formal release/tag/archive rewrite implied. Final exact-source delivery is recorded in the PR/roadmap.
