# Accounts, Landlord and District Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans; native implementation, one final fresh reviewer.

**Goal:** Money is owed to real counterparties, personal promises matter, and district rent is paid in an offscreen trip with receipts and advance coverage.
**Architecture:** AccountBook owns obligations/coverage/receipts; CommitmentService owns explicit promises and bounded lending budgets. AccountTransactions validates wallet/account/relationship/journal candidates before publishing. ResidentialVisits owns the landlord's real presence; Ink authors negotiations without owning balances.
**Tech Stack:** Godot4.7.2/GDScript/Ink/external JSON; revision10 after body/tuning revision9.
**Spec:** `docs/superpowers/specs/2026-10-23-everyday-life-dialogue-and-obligations-design.md`, sections6–7,10–12 and district/prepayment amendments. Prerequisite: increments1–2 delivered.

## Global Constraints

- No automated tests. Quiet scenes≤4, no forced teleport onto player, no invented speech during absence/sleep.
- Housing and district are separate creditors. AbdulKarim owns housing only; no personal trust axis for government institution.
- No automatic midnight deduction, interest, eviction, prison or game over. Commercial suspension is the explicit district-specific consequence after grace.
- Weekly district nominal5000minor; weekly advance10%, four-week advance20%, discounts not stacked; terms adjustable for future agreements.
- Failed payment/negotiation must not say it succeeded or partially mutate wallet/relationship/ledger.

## Review Focus

- Prepaid periods being billed/deducted again, overlapping discounted purchases or stale-price acceptance.
- A promise created by an offered/declined Ink choice rather than mutual acceptance.
- An overdue housing bill being confused with district suspension or an NPC's lending budget.
- Due events during sleep/travel applying penalties twice or trapping player behind work gates.
- Renaming a creditor or changing rent/tuning rewriting historical obligations, receipts or coverage.

### Task1: Account candidates and prepayment coverage

**Files:** create `game/economy/account_book.gd`, `account_transactions.gd`, `content/accounts.json`, `game/content/account_validation.gd`; modify GameSession, DailyRoutine, clock dependencies, validators/manifest and notebook.
**Interfaces:** `AccountBook.tick(frame:Dictionary)->ActionResult`, `summary(from_at:float,to_at:float)->Dictionary`, `quote(contract_id:String,offer_id:String,at:float)->ActionResult`, `snapshot/restore`; `AccountTransactions.pay(quote_id:String,request_id:String)->ActionResult`; transaction quote includes exact version/period coverage/gross/discount/net.

- [x] Author stable creditor IDs `abdul_karim` and `district`, leases `housing_lease` and `kiosk_lease`. Housing default7000minor/week; district5000minor/week, end-of-week20:00, grace3world days as implementer default. Anchor new contracts at migration/new-game time with first full future period; never backfill unrecorded historical debt.
- [x] Implement one obligation per contract/period, persistent paid/remaining state and no midnight auto-spend. Weekly notebook shows future/current and carried overdue separately. Disable DailyRoutine's old rent charging on activation, preserving old assessment history and already paid cash without refund/double billing.
- [x] Implement district quote offers: settle assessed obligations at face value, buy next full unstarted week4500minor, buy four consecutive unstarted weeks16000minor. Paid coverage follows actual period IDs; cannot repurchase/overlap, stack discounts or use advance credit to erase assessed arrears. Price/offer mutations reject stale quotes; signed/paid terms remain frozen.
- [x] AccountTransactions privately stages wallet and accounts; commit only if every candidate validates, then publish journal system receipt. Request IDs make retries idempotent. Receipts list creditor, exact periods, gross/discount/net and world timestamp. Partial housing payments allowed only per authored agreement; district unlock depends on all enforced remaining amounts, not merely any payment.
- [x] Build `/tmp/kiosk-accounts-t1`; UI review ordinary due/insufficient/partial payments, week45 and four-week160 quotes, expiry/duplicate request, future due on already covered period, sleep across multiple periods. Expected exact totals and one receipt per actual payment. Commit.

### Task2: Person presence, negotiation and first real loan

**Files:** create `game/actors/actor_presence.gd`, `residential_visits.gd`, `game/economy/commitment_service.gd`, `content/residential_visits.json`, `content/stories/landlord.ink`; modify physical world adapter, NarrativeDirector/conditions/participant resolution, PersonalConversations, accounts transactions, journal, encounters/social/locations data.
**Interfaces:** `ActorPresence.resolve(presence_id:StringName)->Dictionary` returns actor_id/location_id/ground/availability, adapting existing corniche visits and landlord visits; `actor_ids()->Array[String]` and `profile(actor_id:StringName)->Dictionary` merge existing visitor profiles with residential/contact profiles without forcing household actors into kiosk marker rules; `ResidentialVisits.tick(frame)`, `snapshot/restore`; `CommitmentService.offer/accept/pay_loan` return ActionResult with explicit offer/request IDs. It owns `snapshot/restore` and period-sensitive promise receipts.

- [x] Adapt narrative speaker/context/restore checks to ActorPresence without changing corniche VisitState/order ownership. Relationship/knowledge/content-validation actor catalogs use its merged stable IDs; notebook display resolves profiles rather than assuming every actor is a kiosk visitor. Place AbdulKarim on rooftop via legal entrance/exit, only when player is present in window19–22 and an agenda exists; author saved10–30world-minute arrival delay. Respect scene cap; travel/sleep cancels/defer encounter, not the debt. No speech/visit fabricated while player absent.
- [x] Author connected landlord dialogue: pay, negotiate even while solvent, offer a partial payment/new deadline, explicit accept/refuse, ask about his own circumstances, repair broken promise. Default offer choices1/3/7days; data rules consider familiarity/trust and fulfilled/broken promises. Acceptance freezes actual terms; revised accepted deadline supersedes earlier social promise timing without erasing principal.
- [x] Assess breach/fulfillment once per accepted promise version. Separate positive shared moments from repeat discussion; no automatic shared knowledge with district/other people. Pending personal choices remain saved and do not imply agreement or payment.
- [x] First loan: AbdulKarim, budget10000minor, offered amounts1000/2000/3000, familiarity≥30 and trust≥10, one outstanding loan per lender, due7days; values are author defaults. Validate ability to lend, player request and accepted terms. Move actual amount lender budget→player; repayment reverses remaining principal with no interest and records its own commitment/receipt. No cash is created by dialogue or duplicate accept.
- [x] Build `/tmp/kiosk-accounts-t2`; UI: landlord actual arrival/absence, money available but request extension, explicit refusal/acceptance, sleep past promise once, borrow/repay/duplicate and denied lending. Preserve legacy corniche conversations, hearing and workshop reservations. Commit.

### Task3: District trip, suspension and persistence

**Files:** create `game/commerce/district_office.gd`, `game/ui/district_panel.gd`; modify TravelService, routes/locations/UI content, AccountBook, ActionPolicy, PersonalConversations, SaveCodec/migrations/validation and QaProbe.
**Interfaces:** `DistrictOffice.open/journey_context()->ActionResult`, `quote/pay` delegates account transaction APIs; `AccountBook.business_allowed()->bool` feeds increment2 ActionPolicy.business_allowed callback. Payment valid only during actual district travel transaction phase, never just from a URL/UI call.

- [x] Add offscreen district route with authored10world-minute outbound/return legs. Show ledger/offer selection and receipt at the office stop; existing world/jobs continue. Paying/accepting alone does not teleport home; returning alone does not pay. Insufficient wallet leaves liability unchanged and permits returning.
- [x] At enforcement deadline derive suspended eligibility from account state. Block commercial preparation/acceptance/delivery while suspended; sign cannot bypass. Allow visits/talk, self-food preparation, travel, supply care, assistance and repayment. Actual unattended jobs continue under their existing rules. Clearing all enforced remaining principal restores business eligibility immediately from ledger truth.
- [x] Revision10 migration validates account/promise/lender/presence/receipt references and ensures no historical arrears invented. Retain old clock/job/Ink/loan-free state and already deducted rent history. Cross-check every discounted coverage receipt against cash transaction and period total; stage candidate before install.
- [x] Build debug/release. UI gates: saved published Ink choice and jobs; new landlord choice, accepted promise, current loan and district quote/return save; suspended after sleep while absent; pay arrears to unlock; full quote figures/receipts and no double-charge on next due. Record every unreviewed gate explicitly.
- [x] Commit/review/fix/export exact product and authorized GitHub preview/digest. Expose AccountBook and AccountTransactions contracts to increment4; don't move financial truth into supplier Ink.

## Delivery status

Implementation delivered as product930c928; [evidence and explicit manual coverage gaps](../../notes/2026-10-24-accounts-landlord-and-district.md). Checklist completion records implementation/build/review delivery, not every suggested manual scenario passing. One final fresh reviewer and one ongoing material/acceptance fix pass; no automated tests. Preview published, main untouched. Next: increment4 suppliers.
