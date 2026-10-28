# Hospitality and payment choice

## Implemented scope

Based on main0e6bdb8, on `feat/hospitality-payment-choice`. `ServiceSystem.deliver` owns actual item handover; `settle` owns payment disposition and the one-time wallet credit. Orders retain recipient character, served item, paid/gift/pending disposition, promised gift and actual amount. Production uses `complete` after an explicit choice before handover: validate both actions, consume the real item, commit the order and money, then notify observers. Repeated completion returns a duplicate receipt; conflicting settlement cannot charge again. A promised gift cannot be changed into a paid sale.

Actual handover, not payment, triggers the existing service memory, experience and good-service mood once. Financial settlement only updates its receipt. Gifts consume the same real ingredients/item and credit zero price/tip. There are no extra numerical rewards for choosing a different generous wording.

## Authored episode and memory

Optional `visitors.hospitality` JSON enables one authored money-short episode for Youssef from his second counted visit. This is a bounded authored circumstance, not a general NPC wallet simulation. Before creating an order, Ink offers three natural acceptance phrasings, a humane refusal about the player's own rent/expenses, and truthful ingredient/business-unavailable alternatives. Refusal leaves the independent visit intact. A resolved episode is not automatically repeated.

Accepted promises and declined requests have durable character/visit receipts; actual gifts also have service/order receipts. A later manual topic reads an actual gift or prior refusal, rather than treating a promise/cancelled meal as delivered. A gift episode's accepted-order receipt remains verifiable after its visit disappears or recent service memory rotates. Generic recent paid/gift service memory retains the existing two-service bound.

## Player interface

E with a matching prepared order opens a service-choice sheet. A paid choice shows the actual frozen base-price/quality-tip amount; eligible known people can be treated, and promised gifts expose only the gift choice. Closing or postponing consumes no food and changes no money. The active recipient's waiting clock is held during the decision; the transient hold releases when the sheet closes. Normal movement/social control resumes afterward.

Split API handover can also be saved before settlement; recovery text correctly says the item was already served and offers only settlement, rather than another handover. The production UI normally avoids creating this intermediate obligation. Every final choice revalidates order, recipient availability/proximity, promise, eligibility, business policy and held item identity. Arabic/English labels and authored text ship offline.

## Save impact

**Schema4/revision17 requires a new game for earlier pre-alpha saves, including the revision16 numbered baseline.** Loading an unsupported revision returns an explicit message; files/backups are not silently removed, reset or rewritten. Existing migration code is retained as historical code; no new migration or archived Ink graph was added for this batch. VERSION stays at the existing development target until a separate release decision; this is not another formal numbered release.

Current save validation checks settlement arithmetic, item/recipe/food/sugar/quality consistency, durable recipient ownership, visit/order/promise/history links, duplicate delivered item identities and absence of delivered food from live inventory. This is integrity validation, not an anti-cheat signature scheme.

## Evidence and review

[Retained evidence](evidence/2026-10-28-hospitality/) contains bounded manually invoked runtime logs and component screenshots. No automated test suite was added/run.

- Real compiled service-request Ink and real tea workflow: paid completion moved wallet4500→5300 once for quality3/base500+tip300. Gift completion and all three acceptance phrasings left it4500; consumed item disappeared. Repeated input/restore did not duplicate money or food; a conflicting paid choice on a promised gift was rejected.
- Actual refusal left phase=staying/shopping=declined and no order. A later manual topic produced the authored refusal follow-up; actual gift produced gratitude only after real delivery.
- Current revision17 paid/gift/refusal and split-unsettled receipts restored. Split handover left wallet4500; subsequent settlement credited800 once. The recovery sheet described settlement, not another delivery. A large calendar-elapsed observation kept the active decision recipient's elapsed time and staying phase unchanged, then released the hold.
- Canceling the sheet retained the same held item, wallet and pending order. A resealed impossible food receipt and reassigned historical gift receipt were rejected. A current historical receipt with its original owner restored successfully.
- Actual SaveCoordinator loading of an unsupported revision16 envelope left both primary and backup SHA256 values unchanged. This is a rejection/preservation observation, not historical-save compatibility acceptance.
- Headless Chromium opened an isolated Web component fixture using shipped content and actual GameSession/tea workflow/PaymentPanel. Native button clicks switched Arabic/English, then gift kept wallet4500 and paid gave5300, with held item gone. Screenshots show the actual component; this is not a full production new-game/browser playthrough or a persistence-injection bridge. The temporary fixture is not included in the product export.
- The independent read-only reviewer found two Important integrity gaps: fabricated served-item metadata and historical receipt reassignment. Both were addressed; the native observations above verify rejection. Its inherited delivered-ID/live-item gaps were also tightened. No Critical ordinary-play duplicate payment defect was found. The reviewer did not run builds or gameplay.

The tracked draft build-only Release gate passed with Godot4.7.2, verified toolchain/templates,339 stable Ink localization references, editor import and Web export. `work/*` is explicitly excluded from both export presets, keeping local scratch/fixtures out of PCKs. Exact committed-source build, CI and complete export artifact links are recorded on the PR/issue after publication; the earlier draft export is not relabeled with a later source identity.

## Limits and integration

The shortage episode currently covers Youssef only, and generic hospitality uses the existing familiarity threshold. Wider authored circumstances and continuing arcs belong to subsequent work. Native scratch teardown emitted ObjectDB/resource-retention warnings similar to earlier full-session fixtures; no general leak-free/performance/regression claim is made. Browser storage acknowledgment remains the already shipped Godot4.7.2-pinned adapter.

Issue#4 stays open for source/preview acceptance. This feature request does not merge main, delete branches, rewrite tags/assets or publish another numbered release. #5 continuing stories/messages follows after this coherent batch.
