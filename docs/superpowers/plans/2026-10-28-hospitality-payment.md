# Hospitality and payment implementation plan

> Execute inline under superpowers:executing-plans. Read AGENTS.md/docs/RELEASING.md; independent execution is authorized. User prohibits automated suites: use tracked build-only checks and bounded runtime/UI observations instead of TDD/suite steps.

**Goal:** Real paid/gift/refusal outcomes with natural choices, without fictitious money or repeated rewards.

**Architecture:** ServiceSystem owns separate handover and settlement state/operations. Production UI chooses disposition before handover and completes both synchronously, committing both owners before observers; split operations can represent/recover an unsettled receipt. VisitorHistory owns actual outcome receipts, and Ink requests can bind a gift promise before order creation.

**Spec:** Issue#4 execution checklist and docs/GAME_VISION.md. Baseline main0e6bdb8. Godot4.7.2/GDScript/Ink/external JSON; offline Arabic/English. No population, navigation or unrelated economic rebalance.

## Review focus

One-time handover/settlement across repeated input and current-save restore; promise cannot become a paid sale; refusal keeps independent visit; actual food/financial memory and observer rewards remain coherent; strict current-save links and clear rejection of old unsupported saves; no fictional cash, automatic historical migration or archived Ink additions.

## Tasks

- [x] ServiceSystem/OrderState: handed_over versus settled signals, stored item/disposition/amount, separate deliver/settle and atomic complete operations; validate current-save receipt invariants. No wallet/reward mutation before successful validation.
- [x] VisitorService/VisitState/VisitorHistory: optional data-driven authored once-per-character affordability episode, needs_hospitality projection, gift promise on accepted order, refusal/actual service receipts and save validation. Bind gameplay observers to actual handover once; settlement only updates financial outcome.
- [x] Ink/context/locales: natural three acceptance phrasings and humane refusal before order creation, gift and refusal memory follow-up, true promise/eligibility conditions. Modify current stories only; compile without adding historical archived graphs.
- [x] UI/session/router: one payment-choice sheet, paid or eligible hospitality, promise-bound gift, current-language feedback and recovery of an unsettled handover. No automatic sale on E; cancellation consumes no food/money.
- [x] Save revision17: require a new game for earlier pre-alpha saves, preserve bytes/backups, reject unsupported revision clearly; no new migration. Validate cross-component outcome/food/history links. Add Unreleased save impact and delivery evidence.
- [x] Verify build-only import/Ink/localization/Release export and bounded actual paid/gift/refusal/repeated-input/current-save/UI observations. Obtain independent read-only review; prepare PR/CI and complete Web preview, leaving main integration separate.

## Decisions

- Production chooses before handover so ordinary play never leaves a customer with an accidental unresolved financial obligation. Handover and settlement still have independent domain state/APIs; atomic completion commits both before callbacks.
- The initial money-short episode is authored/data-driven for Youssef after a repeat visit, not a claim of a general NPC budget simulation. Accepted/refused episode and actual gift are separate receipts.
- Historical pre-alpha saves are intentionally unsupported for revision17. Cost: starting a new game for this batch; no existing save is silently deleted or overwritten on load.

## Execution and review rulings

- Production service choice precedes handover, with both commits before callbacks; independent deliver/settle can persist an unsettled receipt. This keeps ordinary play free of accidental debt while retaining real separation.
- Durable character ownership was added to orders and hospitality receipts after independent review demonstrated possible historical gift reassignment; recipe/food/sugar/quality metadata is now checked against current definitions. Current native restore observations reject both malformed cases.
- Also reject duplicate delivered IDs and delivery IDs still live in inventory; these were inherited gaps directly relevant to the new receipt invariants. Handover must actually consume the item before mutating order/money or notifying observers.
- Verification uses tracked build-only gates and bounded native/Web-component observations, as explicitly requested; no automated suite or historical-save migration was added. Current revision17 saves restore; revision16 and older require a documented new game.
- PR/CI/exact committed-source build and source acceptance are recorded separately after source publication. No main merge is part of this feature request.
