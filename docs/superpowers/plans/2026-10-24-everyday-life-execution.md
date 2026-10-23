# Everyday Life Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Native inline execution is preserved from this session; do not dispatch implementers.

**Goal:** Deliver the approved daily-life design as four independently reviewable, playable increments.
**Architecture:** Each increment owns its state, exposes explicit interfaces and participates in the shared clock/save candidate. Ink speaks; services own actual actions; the notebook projects heard events and real accounts.
**Tech Stack:** Godot4.7.2, GDScript, Ink, external JSON; Web preview.
**Spec:** `docs/superpowers/specs/2026-10-23-everyday-life-dialogue-and-obligations-design.md` (including district-rent amendments).

## Global Constraints

- Existing authorized `work` checkout; no main merge. Base before these plans: `6ddee46`.
- No automated tests added or run without user request. Compile/import/export and actual mouse/keyboard UI reviews are separate evidence.
- Quiet Egyptian slice of life, maximum four people per scene, independent visits, no forced story arrivals.
- Existing story cursors, semantic receipts, workshop activity, orders, items, relationships and money remain compatible.
- Time1world minute/real simulation second begins in increment2; no system-local replacement clock.
- Real financial transactions; district rent50EGP/week, advance10% for1week/20% for4weeks (author default month28days), data-driven and revisable for future contracts.
- No product work for later increments is claimed delivered by an earlier preview.

## Review Focus

- Increments disagreeing on whether a statement was heard, an action occurred or a promise was accepted.
- Legacy save with an active published Ink choice and running jobs across several schema revisions.
- Clock-speed changes/sleep producing duplicate charges, deliveries, refusals or missed reservations.
- Hunger/exhaustion/district suspension closing the path to food, sleep or repayment.
- Changing content prices/names/thresholds rewriting signed contracts, paid periods or historical speech.

## Sequence and interfaces

| Increment | Plan | Deliverable | Save revision |
|---|---|---|---|
| 1 | `2026-10-24-continuous-dialogue-and-journal.md` | Personal conversation hub, manual reading, thought channel, heard history, advisory sign | 8 |
| 2 | `2026-10-24-body-clock-and-tweaks.md` | 1:1 clock, actual work costs, alertness/action policy, fatigue visuals, live dev tuning | 9 |
| 3 | `2026-10-24-accounts-landlord-and-district.md` | Accounts/weekly notebook, landlord and promises/loans, district travel/payment/receipts/prepayment/suspension | 10 |
| 4 | `2026-10-24-supplier-contracts-and-deliveries.md` | Supplier agreement, prepaid/credit delivery in absence, actual inventory/charges and emergency food route | 11 |

Record product commit and fresh verification for each increment before the next plan starts. Revisions above are the intended additive chain; if an independently necessary intermediate revision is introduced, ledger the reason and update all later migrations consistently.

## Execution rules

- [ ] Read each plan/spec; pre-flight its consumed interfaces against the preceding delivered implementation. Ledger any necessary ruling before editing.
- [ ] Implement each plan natively, commit coherent tasks, record actual commands/UI observations and unreviewed cases.
- [ ] One fresh most-capable whole-increment reviewer at completion, not reviewer/implementer pairs for every task. Explicitly authorized by executing-plans; no other delegation needed.
- [ ] Fix material findings, compile/export exact product, manually boot release, publish authorized preview source/artifact branches and prerelease, download ZIP and compare digest.
- [ ] Keep overview status honest: checked means delivered, not merely written or compiled.

## Status

- [ ] Increment1 delivered.
- [ ] Increment2 delivered.
- [ ] Increment3 delivered.
- [ ] Increment4 delivered.

Planning is complete for the approved scope; implementation starts at increment1. Implementation quantities marked as author defaults in the individual plans are adjustable JSON, not newly asserted user requirements.
