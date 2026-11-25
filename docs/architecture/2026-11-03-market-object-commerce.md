# Market, physical products and object-centric cooking — integration/authority audit
Recorded 2026-11-03 (Africa/Cairo). Architectural direction for [Epic #47](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/47), not implemented behavior. Companion documents: [gameplay UX](../roadmap/2026-11-03-cozy-gameplay-ux.md), [menu UI](../ui/2026-11-03-cozy-menu-design.md). Evidence: reviewed default-branch 0.4.0-prealpha.1 source. **Any engineering choice below marked “proposed” must be validated against the exact implementation branch before being coded.**

## 1. Existing source reality
| Owner / data | Observed | Extension boundary |
| --- | --- | --- |
| TravelService + content/travel.json | Market, appliances, homewares are currently separate routes; a shopping route identifies one shop_id; browsing is a journey phase; return restores original pose. A journey has one purchase bag and a returned signal. | Keep **one market journey**, allow authorized multiple shop_ids at the same destination, and support explicit return home/kiosk while respecting the clock, bag, origin, safe arrival and save validation. Do not implement UI-only teleportation. |
| ShopService + content/shops.json | Three shop catalogs (“market”, “appliances”, “homewares”) exist. quote(shop_id, lines) already supports multiple distinct offers; purchase is one-store, rechecks revision/stock/wallet and issues an inventory-backed receipt. | Reuse **per-shop multi-line quotes**, retain independent stock/revisions/receipts. Add shop IDs/catalogs and a market-hub selector without a second purchasing owner. |
| ShopPanel | Current UI selects a single product and quotes one line, despite backend accepting multiple. | Add ephemeral editable basket with line quantities, totals, search/category continuity, one review and purchase per store. No cross-store settlement API. |
| ItemStore, InventoryService + content/items.json | Unique items, containers, integer quantity, candidate validation, reservations, stamped ingredient lots, grade/source and freshness exist. | Use these actual owners for net quantities, real packages/stock, reusable objects and display contents. No SnackInventory/BrandInventory or UI-held permanent stock. |
| IngredientLots + RecipeWorkflow / RecipeProcesses | Ingredient family/grade source proof, frozen recipe steps/quality, prep/soak/transfer/passive heat/batch hold/serve exist. First-step capability controls where available_recipes appears; process v2 creates a batch vessel during the job. | Interaction host can be the pot/kettle/pan, while execution still follows the **real** stations and one workflow owner. Explicitly represent persistent reusable cookware; don't confuse owned vessel with ephemeral batch content. |
| MenuService, ServiceSystem, CustomerExperience, Wallet | Authored menu variants, prices, accepted quotes and paid/gift delivery are already owned. Customer memories require observed experience. | Treat ready-to-sell packets as legitimate catalog/sale variants and extend service ownership deliberately. A low-friction retail sale consumes physical stock once and pays once; no timer-based income. |
| Narrative/knowledge/social owners | Source-backed per-knower facts, relationships and semantic policy lifecycle exist. ShopService already has eligibility_provider for required_fact, but its current quote price is authored static offer.price_minor. | Use fact/relationship providers for shop offers; **discount calculation is new work**, must be reflected in authoritative quote, receipt, UI and eligibility. No UI-only discount or invented knowledge. |
| UiText, LocaleService, SheetControls, ModalCoordinator | Shared theme/localization primitives and panel management exist; shop/inventory/recipe panels are currently broad control-heavy sheets. | Evolve shared native Godot UI primitives, not a separate stateful frontend framework. |

Relative source paths live under game/travel, game/commerce, game/items, game/cooking, game/service, game/narrative and game/ui. Validate the exact paths by repository search before implementation; this table is an architecture map rather than a complete file manifest.

## 2. Market hub contract
**Authorized behavior**: outward trip from kiosk or rooftop → arrival at non-physical market destination → static clickable shop selection → per-shop menu with basket → authoritative shop checkout → close to market hub → optional other shop → explicit return destination (kiosk or rooftop).

- Six initial shop slots: wholesaler, attar, cookware, homewares/furnishings, appliances, second-hand.
- One market destination and one journey bag should cover the whole outing. **Do not** create six separate travel legs, re-charge outbound minutes per clicked shop, or require a moving character.
- Shop selectors bind to validated shop IDs; shop entry only available during market browsing. The source route currently has one shop_id; proposed data contract can introduce a validated list of supported shop IDs. Do not loosen arbitrary shop purchase permissions.
- A per-shop basket is a temporary collection of offer_id → quantity. It may survive closing/reopening the shop during this one outing; discard safely on end of journey. Durable stock, purchases, quotes and receipts remain at their existing owners.
- On “Review”, ShopService.quote(shop_id, all_lines) creates the **single-shop** quote. On “Pay”, ShopService.purchase(quote, request_id) remains all-or-nothing for that store. Never independently debit wallet then grant ItemStore goods in UI.
- Account for changes in offer revision/stock, existing bag capacity, sufficient funds, exact retry identity, paused/browsing state and duplicate purchase requests. A failed purchase must not spend money, consume stock or fabricate a receipt. UI should keep editable cart selections and explain why checkout failed.
- For return destinations, propose a validated destination choice at begin_return rather than overloading the origin_pose or the shop ID. Resolve physical safe arrival, proper duration (not currently configured for alternate return), delivered items and resumption consistently. Source return-to-origin remains a valid option. Future routes to other shops remain untouched until explicitly integrated.
- If there are existing active/saved shop journeys from before the new market routes, define migration or intentional revision-reset policy before shipping; never silently reinterpret a route ID as a new destination.

## 3. Products, packages, material amounts and fictional brands
Do not change “1 unit of tea” into “100 g” only on the label. The canonical material quantity and recipe consumption must agree.

### Proposed separation (within existing owners)
- **Product offer**: what is sold (seller, brand/loose variant, net content, price, discount eligibility, package illustration). Authored with catalogs/offers and validated material definitions.
- **Owned item/lot**: the actual received physical stock in ItemStore, with count or material amount, provenance, per-unit cost, grade and actual age. Do not merge different source lots/grades by UI convenience.
- **Recipe requirement**: amount of a compatible ingredient family (e.g. grams of tea, milliliters of oil), resolving exact owned lots through the current reservation/consumption path.
- **Use/display**: show readable names and g/kg/ml/L/each/packs/cans; resolve locale-aware formatting, without changing the source item identity.

### Decisions to implement incrementally
1. Select an integer-based canonical smallest quantity for each material dimension to avoid float drift. Existing integer ItemStore quantity provides a starting point; introduce measurement metadata and validation at the existing definition/offer boundaries. Handle discrete items (bread, eggs, cans) as count; weighed meat/tea by mass; liquids by volume.
2. Package sizes are deliberate net contents and optional outer packs. Example “100 g pack of tea” grants the corresponding **actual** material stock; brewing one cup consumes an authored small number of grams, not a full fictional “tea unit”. Do not ship illustrative recipe numbers as approved balancing.
3. Fictional brands are authored variants with labels, packaging identity and meaningful price/quality/flavor properties, mapped to compatible existing ingredient families. Loose tea may be high quality too; packaged versus loose is not a forced grade ladder.
4. Shop/wholesale pack count, material quantity, ingredient lot unit-cost attribution, supplier baskets and world consumption must all agree. The ShopService offers/receipts currently count ItemStore units; adjust in one coherent batch with negative tests before exposing UI labels.
5. Existing recipe IDs, personal/commercial distinction, saved source proofs, freshness and purchased equipment must be audited for conversion. Avoid a wholesale item migration that inadvertently creates extra food or doubles priced lots.

## 4. Reusable cookware versus food batches
The current process v2 creates a cooking_vessel **batch item** as a consequence of the recipe; this is not yet the same thing as an **owned, empty, reusable pot**. The chosen play experience needs that distinction.

- Purchase a placeable pot/kettle/pan as an ordinary owned ItemStore equipment/furniture instance where applicable, via the existing shop flow.
- Interacting with the physical object asks the existing workflow for valid actions and available recipes; it does **not** own a second cooking state or recalculate freshness.
- Map a recipe's natural entry object independently of the first required capability: choosing ful from an empty pot may direct the player to a prep surface. The prep/soak/transfer/heat/hold/serve steps still consume resources at the actual authorized devices.
- Associate active job/batch identity with its physical pot by a validated stable link, preserving reservations, location, occupied surfaces, save/restore and failure semantics. Choose an integration with ItemStore + RecipeWorkflow ownership; do not duplicate batch identity in a separate PotCookingManager.
- At zero remaining portions remove/finish the food batch according to current rules; **retain** the owned physical vessel. Expose “empty → prepare → active → ready → empty” through the UI.
- Preserve v1 tea and other existing recipe support while migrating relevant interactions incrementally. No Cooking v3 rewrite.

## 5. Stock-backed kiosk retail and truthful passive sales
- Display shelves, snack stands and beverage fridges are owned movable/placeable objects with **validated storage/display capabilities** and actual contained ItemStore goods. Reuse existing container/placement limits, or extend those validators intentionally.
- Supplier or retail shopping adds tangible goods with purchase-cost provenance. “Restock” transfers them between **real** containers; no magic refill from the catalog.
- Sales are triggered by eligible **real visitor** purchase decisions under the existing low-volume quiet world; no fictitious sale every N seconds. Selling while the player is doing something else is acceptable if supported by actual simulated visitor behavior.
- One retail sale must have atomic stock decrement, price quote/payment and a deduplicable receipt recorded by an existing accountable service/economy owner. ServiceSystem currently focuses on prepared order handover; expand a coherent sale pathway rather than keeping a second independent sales wallet ledger.
- Respect current one paid/gift service-per-visit default and cancellation/hospitality boundaries unless separately designed and explicitly revised. No multiplying transaction count just to make “passive income” larger.
- Cooler electricity/condition, expired product, merchandising, vending hours and remote automated sales are **future options**, not first-slice promises.

## 6. Sourced discount and recommendation rules
- A merchant relationship, personal recommendation or trusted actor can surface an eligible seller/offer or price modifier only if actual source/recipient lineage allows the player to know it. Use existing semantic policy/knowledge/social owners as truth.
- Discount computation belongs at ShopService quote-time, must be reflected in the quoted unit/total price and purchase validation, and recorded in receipt/provenance. It cannot be a label that contradicts actual wallet charge.
- Decide stacking/cap, expiry and whether same offer remains available after leaving the market. No price mutation after accepted quote except explicit stale-quote rejection, as with current purchase semantics.
- Preserve the supplier contract domain and its deposit/credit/delivery rules: market outing is **not** a replacement for the existing phone supplier.

## 7. Save, time, validation and test gates
Each coherent implementation issue must explicitly state:
- **Saves:** which owner snapshot changes, old/current save restore strategy, schema/revision result, and preservation of unsupported/corrupt primary+backup bytes. See RELEASING; do not assume 0.4.0 saves can be read after changing ingredient quantity meanings.
- **Time:** world minutes while browsing, passive cooking during travel/sleep, one outbound/return per journey, no extra timer-based commercial income.
- **Atomicity:** duplicate requests, stale quotes, out of stock, insufficient wallet, bag/container capacity, blocked placement, canceled/failed cooking and sale retries.
- **Observability:** one real story and paid/gift scenario, no fabricated customer tasting or source-only discounts.
- **UI:** native 1280×720 + Web New/Continue and actual Arabic/English screen interactions including Escape, focus, touch-appropriate sizing. Capture screenshots and human review where practical.
- **Performance:** short representative populated scene check; only investigate more if regression evidence warrants.
- **Release:** version/tag/archive only for coherent completed milestones, not for this document-only PR. Preserve immutable artifact branch.

## 8. Dependency-ready implementation order
A. UI primitives and one ShopPanel slice → B. Multi-line per-shop basket with transactional tests → C. MarketHub + authorized multi-shop journey/return + newly authored shops → D. Canonical material amounts/packaging/brands (one deliberate save/recipe compatibility gate) → E. Object-centric persistent cookware integration → F. Retail shelves and display fridges using actual sales → G. Source-based merchant prices/referrals → H. Full acceptance and release. Cross-dependencies may be adjusted after exact-head review, but domain ownership must remain unique.
