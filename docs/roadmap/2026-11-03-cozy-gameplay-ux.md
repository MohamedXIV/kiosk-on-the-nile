# Cozy gameplay UX, market and launch-facing scope — design direction
Recorded 2026-11-03 (Africa/Cairo). Parent tracking issue: [#47](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/47). This document records **approved conversation direction and proposed implementation boundaries**, not finished gameplay or a release. The authoritative experience remains [GAME_VISION](../GAME_VISION.md); [RELEASING](../RELEASING.md) controls version, changelog and saves.

## Why this phase exists
The 0.4.0-prealpha.1 preview has substantial gameplay owners: recipes, ingredient lots/freshness, exact orders, social memories, visits, supplier contracts and travel. The next phase should make these systems feel like a cozy lived-in game **from the player's perspective**. Building more complex cooking before approachable interaction, a convincing shopping loop and coherent UI is not a prerequisite for a valuable first public experience.

**Do not remove, reset or replace completed work.** A small *visible* menu or limited first-release assortment is not a smaller backend. Keep recipes, equipment capabilities, narrative knowledge and data for later. Show an honest “coming later” state only when it adds clarity; do not fill screens with disabled features or imply a feature works before it does.

## Product rules — decided
1. A world-first, calm and readable UI. Design language: modern premium/cozy interface best practices, soft surfaces, clear type, restrained warmth, understandable icons and spacing. **Avoid obvious AI-art clutter and heavy local-market clichés in the menus.** The game world retains its Egyptian identity; the UI need not imitate a traditional bazaar. The latest accepted UI concept is **directional visual inspiration**, not pixel-perfect implementation or proof that depicted HUD stats/features exist.
2. Players interact with tangible devices/objects: pot, kettle, pan/fryer, fridge and display shelf. The counter is for preparation, cutting, assembling and placement. Backend workflows continue to own cooking; the object merely becomes the natural context/entry point.
3. A **static market selection screen** (illustrated shops or static selectable pictures), not a walkable level. No market movement/pathfinding or added NPCs required in this slice.
4. A single market **outing** can visit multiple shopfronts. Choose shop → open its purchase interface → select products into its **own editable basket** → review and settle → close shop → market screen. Repeat for another shop or leave the market.
5. The market screen offers **return to kiosk** and **return home**. Respect world travel, inventory delivery, time, positional safety and saving; current return-to-origin behavior must be extended, not bypassed by UI teleportation.
6. Six initial shopfront **slots**, intentionally expandable without new permanent routes:
   - Wholesaler: cartons/packaged snacks, drinks, packaged tea and coffee, restock for the kiosk.
   - Herbalist/attar: loose tea, coffee, herbs, spices sold by weight, with multiple price/quality options.
   - Cookware: reusable pots (including ful pot), pans, kettles, trays and cooking utensils.
   - Homewares and furnishings: shelves, furnishings, containers and practical everyday items.
   - Appliances: cooker, fryer, oven, refrigerators and cold display equipment.
   - Second-hand seller: used appliances/furnishings, variable price/condition, possible introductions or recommendations.
   They may be introduced progressively **without changing the hub interaction contract**. The three original market/appliances/homewares shop catalogs must be preserved during migration.
7. A customer basket is **per shop**. There is no whole-market combined checkout or pre-authorized multi-shop transaction. One store is charged/committed at a time. The player can return to the hub after shopping, and retain a truthful record of spending and remaining balance.
8. Fictional product brands, pack identity and quantity: loose by weight; packaged tea/coffee in weights; poultry/meat in weight; liquids in volume; eggs/bread/bags/bottles/appliances by count with net amount when appropriate. “Unit of X” must not be cosmetically renamed unless recipes, inventory, supplier and shop quantities reflect the same material amount.
9. Kiosk retail: purchase shelf-ready packets (chips, cakes, biscuits), bottled/canned drinks and display containers; place and restock them. Sales are low-friction/partly unattended, **never free passive money**: they consume actual stock and require actual buyers/events in the existing quiet world. Vending machines are a later extension of this mechanism.
10. Social recommendations can enable a seller, an offer or a genuine quote-time discount through existing per-knower provenance, relationship/social rules and authoritatively recorded commerce. A player must have heard/earned the referral; a UI tooltip cannot grant a discount.

## Launch-facing experience — scope, not a deletion list
- Center the initial economy around prepared tea/coffee and a few simple drinks, prepared food such as fried potatoes and optionally taameya, plus stocked packaged goods. Coffee and taameya are **new content/work**, not existing 0.4.0-prealpha.1 features. Burger is an optional later step, not a prerequisite.
- The broader cooking v2 recipe set (ful, liver variants, shawarma, baked potatoes and future recipes) remains in the project. Which recipes appear in the launch menu is a content/UX gate, not a call to delete code or historical saves.
- Non-buying visits, quiet conversation, shared memories and deliberate hospitality remain first-class. Neither a wholesaler nor a display fridge justifies turning the corniche into a customer conveyor belt.
- Source-based social talk and real customer experience remain independent of instant purchases; avoid inventing taste observations for takeaways or off-screen unobserved eating.

## Intended player journeys
### Market outing
From an allowed starting location, pick “Market”; existing travel/wait state advances; arrive at the static hub with six selectable shopfronts. Selecting a shop opens that shop’s catalog. Select multiple products/quantities, see price per package and useful unit-equivalent cost, wallet and basket total, correct quantities or remove lines, review stock/cost/carrying limits, and confirm that shop’s purchase once. Close to hub. Shop elsewhere or choose a destination (home/kiosk) and travel there with purchased goods. At every step, no new purchase is implied by closing a window.

### Making ful
Interact with the empty persistent pot (not a recipe index on the counter). See what ingredients and equipment are required. Perform actual prep/soaking at the appropriate existing prep surface, transfer the real pot/batch to its heat device, wait and adjust heat using the existing workflow, then serve actual portions from the pot, with stock/freshness/serving inputs unchanged. Pot remains an owned, placeable object after portions finish.

### Keeping the kiosk stocked
Buy packaged items from the wholesaler, return with them in the existing purchase inventory, place or replenish tangible shelves/coolers and observe levels. An eligible visitor may choose an item (or choose not to buy). Confirmed sales adjust stock and wallet once with receipts; closing the kiosk respects existing visit/purchase separation. Display equipment only holds and presents stock; it does not create products.

## Functional acceptance for design slices
- All market shops are reachable from **one** trip, checkout is independent in each shop, no extra travel time/fee for selecting a different shop within the hub.
- An empty or over-budget basket cannot debit; stale quote, sold-out item and insufficient carrying room are understandable without partial ownership changes.
- Closing shop does not charge. Returning from a trip delivers everything to the correct existing containers or presents a safe failure; cannot lose purchased objects.
- UI text, navigation, prices, brand and product measurements survive switching Arabic/English and ordinary screen sizes. Maintain keyboard, mouse and mobile-friendly targets.
- Devices expose states relevant to them (empty, preparing, waiting, heating, ready, empty again); counter continues to handle actual preparation tasks.
- No duplicate authoritative source of quantity, quote, ingredient source lot, cooking job, relationship or stock sale.

## Open engineering choices — do not silently treat as decided
- Exact colors, component sizing and illustration style; acceptance image shows overall mood only.
- How long a draft basket survives closing/reopening a shop within one outing (prefer session-local only).
- Shopfront images: authored static sprites/illustrations vs composition of layered art; no need for a walkable scene.
- Exact per-material canonical small units and pack-to-stock representation; balance/cost/portion counts are not yet approved.
- Whether first playable market has all six fully stocked or some honest future indicators.
- How seller discounts stack with other price rules; seller identity and permissions must have source-backed authoring.
- Carrying/delivery rules for choosing a different return destination than the origin.
- Whether a packaged self-service sale is fulfilled through an extension of ServiceSystem or a narrowly integrated command; **one payment/stock owner**, not a second parallel economy.

## Delivery approach
Implement incremental, reviewed, testable slices. UI foundation and the existing per-shop multi-line checkout should be proven before changing travel semantics. Then implement the hub and routes, product weights/brands with a deliberate save contract, object-centric equipment UX, stock-backed retail and social discounts. Finish each coherent milestone with actual native/Web bilingual checks and save/resume cases; bump VERSION/CHANGELOG only under release policy when delivery is coherent. This design-only proposal changes neither gameplay nor versions.
