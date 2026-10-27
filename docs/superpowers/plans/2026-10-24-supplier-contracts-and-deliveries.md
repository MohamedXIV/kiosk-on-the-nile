# Supplier Contracts and Deliveries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans; native implementation, one final fresh reviewer.

**Goal:** Agree with a real supplier on goods, schedule, storage and payment, then receive actual deliveries while away or asleep.
**Architecture:** SupplierContracts owns frozen signed terms; DeliveryService owns due occurrence scheduling/results; SupplyTransactions coordinates item/financial candidates. Existing AccountBook owns invoices/debts, existing journal records actual system events, and Ink owns contact/negotiation.
**Tech Stack:** Godot4.7.2/GDScript/Ink/JSON; revision11 after accounts revision10.
**Spec:** `docs/superpowers/specs/2026-10-23-everyday-life-dialogue-and-obligations-design.md`, sections8–12. Prerequisites: increments1–3 delivered.

## Global Constraints

- No automated tests. Actual UI/save evidence and compiler/import/export gate.
- Supplier leaves goods in an authorized storage location even with player absent. No full shop/route scene is required for logistics.
- Absent-player delivery uses prepaid funds or expressly agreed credit, never cash teleported from the player's carried wallet.
- Full batch or explicit skip for that occurrence; no hidden substitutions/partial delivery/failure charge.
- A failed or duplicate occurrence changes neither half the inventory nor half the financial state.

## Review Focus

- Sleep spans several scheduled deliveries with limited storage/credit: process in timestamp order without overflow/double-charge.
- Destination storage/host moved or removed after agreement: reject delivery safely, preserve items/money and explain why.
- Editing/canceling a contract must preserve already fulfilled invoices and not reschedule the same occurrence under a fresh ID.
- Supplier presence/dialogue must not be fabricated from an offscreen system-delivery event.
- Emergency-food credit must work while hungry/fatigued/district-suspended, with a bounded actual creditor debt.

### Task1: Signed supplier terms and contact

**Files:** create `game/commerce/supplier_contracts.gd`, `content/suppliers.json`, `content/stories/supplier.ink`, `game/ui/supplier_panel.gd`, `game/content/supplier_validation.gd`; modify actor profile registry from increment3, encounters, phone interactions, manifest, UI/notebook and GameSession.
**Interfaces:** `SupplierContracts.quote(terms:Dictionary)->ActionResult`, `accept(quote_id:String,request_id:String)->ActionResult`, `amend(contract_id:String,quote_id:String,request_id:String)->ActionResult`, `pause(contract_id:String,request_id:String)->ActionResult`, `snapshot/restore`.

- [x] Define supplier actor `fathi`, editable nameعم فتحي, authorized phone-contact presence/channel for setup and account conversation. Reuse personal dialogue/journal ownership; phone speech requires actual player-initiated call through a valid in-world contact point. Offscreen delivery never invents a call/transcript or adds a physical person beyond scene capacity.
- [x] Quote finite catalog items/quantities, weekdays, delivery minute (default07:00), destination container and explicit permission to leave goods, frozen unit prices/delivery fee/payment policy/credit cap. Start first occurrence strictly after acceptance. Resolve stable container/host IDs, not screen coordinates. Reject invalid references or capacity-impossible signed batch.
- [x] Author starting service fee100minor/delivery, prepaid normal mode or expressly agreed credit up to2000minor, configurable supplier stock per game day. Cash-on-delivery is valid only with player present and explicit payment; absent cash-only mode without prepaid/credit skips with clear reason. All amounts/rules are author defaults.
- [x] Accept/amend/pause through semantic requests, not mere option display. Freeze signed prices; amendments affect future undelivered occurrences only. Unspent prepaid balance remains recorded/usable when a contract is paused; do not invent a cancellation fee/refund mechanism.
- [ ] Build `/tmp/kiosk-supplier-t1`; UI: review/decline/accept/edit/cancel, active versus historical terms, contact absence and journal attribution. Expected no stock/payment effect before actual delivery. Commit.

### Task2: Due occurrence and atomic supply transactions

**Files:** create `game/commerce/delivery_service.gd`, `supply_transactions.gd`; modify AccountBook/AccountTransactions candidate staging, ItemStore integration, shared scheduler dependencies, sleep catch-up and journal/system receipt UI.
**Interfaces:** `DeliveryService.tick(frame:Dictionary)->ActionResult`, `occurrences(filters:Dictionary={})->Array[Dictionary]`, `snapshot/restore`; `SupplyTransactions.deliver(occurrence_id:String)->ActionResult`; `deposit(supplier_id:String,amount_minor:int,request_id:String)->ActionResult` records actual prepaid funds. Account/item candidate publication occurs only after all validations succeed.

- [x] Occurrence IDs encode contract/version/scheduled timestamp; statuses scheduled/delivered/skipped with reason and evaluated_at. Use world_minutes and chronological due order, including sleep jumps. Do not retry failed same-day occurrences automatically; an explicit extra order creates its own new identity/quote.
- [x] Validate currently existing destination/capacity, full required stock and frozen terms; finance stage checks prepaid funds or authorized remaining credit (or explicit present-player cash confirmation). Stage full item grants/stock deduction, charge/prepaid deduction or debt invoice, delivery status and journal receipt. No awaits or early signals between candidate publications; emit success only after all owners accept.
- [x] Record separate goods and delivery fee, exact actual quantities and invoice/receipt IDs. Missing capacity/stock/funds/credit records a skipped occurrence with no goods/fee; deletion or movement of storage cannot leave orphan grants. Subsequent scheduled delivery evaluates anew against remaining capacity/credit.
- [x] Deposit is an explicit wallet→supplier-prepaid transaction with an idempotent receipt; no free balance created by enabling a contract. Supplier credit becomes an actual AccountBook liability; future payments settle its remaining principal only once.
- [ ] Build `/tmp/kiosk-supplier-t2`; UI: away/travel/sleep delivery, two due batches competing for last storage slot/credit, duplicate save/reload, removed host, failed delivery, amended time and paused contract. Expected whole transaction or explicit no-charge skip. Commit.

### Task3: Emergency food, revision11 and final integrated review

**Files:** modify supplier/contact Ink, ActionPolicy/practical-talk integration, notebook account/journal views, SaveCodec/migrations/validation, validators, GameSession and QaProbe. Reuse existing food/item definitions; do not create a gratuitous new recipe.
**Interfaces:** supplier contact exposes an explicit bounded emergency-food quote; actual acceptance and fulfillment use the same AccountBook/SupplyTransactions contracts, not an ad-hoc hunger credit.

- [x] Author initial emergency option one existing edible portion worth300minor on account, outstanding emergency principal capped300minor, available before personal-lending affinity threshold. The exact existing edible item/definition must be identified from delivered content; record its stable ID in the task ledger before editing. Requires actual contact and acceptance, grants real food item into accessible personal storage, records Fathi's debt and remains available through practical-care action classes while district trading is suspended. No free/daily money generation or invisible need refill.
- [x] Show next scheduled delivery, frozen basket/fee, prepaid balance, credit used and failed occurrence reason in notebook; link actual delivery/account event to history without attributing NPC dialogue. Bound practical UI effort: care transaction must be reachable even if focused conversation is fatigue-blocked.
- [x] Add revision11 migration with no fabricated supplier contract, stock grants, past deliveries or debt. Preserve revisions7–10 histories/financial coverage/workshop/actor references and frozen ongoing terms. Validate unique occurrence/invoice/item-source linkage and journal provenance before candidate activation.
- [ ] Build debug and exact release. UI gates: signed contract saved before due, pending return trip, player asleep/away, failing/working storage and credit, emergency care with zero cash/ingredients, paused delivery and overdue supplier bill, legacy active dialogue/jobs plus prepaid district periods. Review default pacing separately from accelerated external fixtures and disclose uncovered paths.
- [x] One fresh whole-increment review, material fix pass, exact-SHA release boot, authorized source/artifact preview and downloaded ZIP digest. Update the parent execution status only after this playable increment is delivered; list any material limits in user-facing delivery notes.

## Delivery status

Playable increment delivered as38396bb. Implementation, one fresh review/material fix pass, builds, exact release boot and preview publication completed. Build/UI matrix bullets remain open for cases not manually exercised; [delivery evidence and explicit coverage limits](../../notes/2026-10-24-supplier-contracts-and-deliveries.md) distinguish implemented behavior from manual proof. No automated tests, no main merge.
