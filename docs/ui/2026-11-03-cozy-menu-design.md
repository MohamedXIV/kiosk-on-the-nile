# Cozy UI system and object-first interaction — design contract v0.1
Recorded 2026-11-03 (Africa/Cairo) for [Epic #47](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/47). Proposal for the next UI implementation, **not** a completed style migration. Follow [product direction](../roadmap/2026-11-03-cozy-gameplay-ux.md) and [GAME_VISION](../GAME_VISION.md).

## Visual direction and anti-goals
Reference: the second approved **menus-only** cozy UI concept, with shop, inventory, recipe, dialogue and shared atoms shown on a neutral canvas. It was accepted as a *first direction*; exact artwork, layout and every pictured stat were **not** approved game features.

We want an inviting interface that looks like a deliberately designed cozy game rather than:
- raw Godot editor controls;
- visually busy AI-generated images, maximal ornament, fake wood signs, faux market-scene backgrounds or “Egyptian bazaar” cliché styling;
- business-app dashboards with too many competing panels;
- decorative coins, hearts or energy meters invented by the UI where no authoritative game quantity exists.

Prefer a restrained palette of warm ivory/sand surfaces, muted sage/olive accents and a secondary warm neutral. Use one unmistakable primary action per panel, quiet secondary controls, strong text contrast and gentle, consistent elevation. Avoid a card nested inside a card inside a card merely for decoration. **Colors, spacing and fonts are design targets to validate in Godot screenshots, not magic numbers to freeze prematurely.**

## Design system and component ownership
Build **one** coherent Godot Control/Theme family for:
- panel/sheet shell: title, context subtitle, close/back, correct default focus;
- primary/secondary/destructive buttons, icon-button and disabled/“later” states;
- tab/segmented category selection, searchable item rows/cards, quantities and input;
- wallet/price/units, basket subtotal/total and capacity indicators;
- recipe stage/status, requirement list (owned/missing), action controls and feedback;
- dialogue/choices, lightweight notices and confirmation/validation messages;
- responsive scroll regions, stable keyboard selection and mobile-size hit areas.

Shared components should centralize styling/interaction behavior **without** becoming a massive all-purpose widget manager. Use existing UiText, SheetControls, LocaleService and ModalCoordinator where possible, evolve them rather than layering a competing UI library. Presentation reads domain snapshots/commands; it does not own business truth.

## Content and information hierarchy
1. **What am I interacting with?** (shop/vendor, kettle, batch pot, storage shelf, person).
2. **What can I do right now?** (“Add to basket”, “Prepare”, “Stir/transfer”, “Serve portion”, “Restock”).
3. **What do I have and what is missing?** (real quantity, price, stock, ingredients, equipment, free space).
4. **What happens when I commit?** (one reviewed shop charge, consume ingredient, initiate real cooking stage).
5. **What feedback confirms the result?** (exact charged amount, stock delta, selected recipe stage, reason for refusal).

Keep world visibility high. Avoid occupying most of the game viewport with large HUD meters; show relevant context when focused. Respect the existing deliberate time progression: opening a menu does not silently freeze, advance or complete any authoritative job unless the current owner explicitly does so.

## Per-screen behavior
### Market hub
- Static illustrated shop selection (not a playable movement scene). Six shops may be irregularly arranged like the agreed sketch, with clear clickable affordances.
- No mandatory storefront walk animations or new character controller.
- Selected shop opens a single shop menu; close returns to the same hub. Home/kiosk exit options have clear travel intent and confirmation if needed.
- Never pretend an unimplemented shop is open. A “later” sign is optional and unobtrusive.

### Shop
- Product list: recognizable product image/icon, brand/variant, **net quantity** (e.g. 100 g), price, availability, and unit-equivalent comparison where it matters.
- Search + meaningful categories. Quantity change and remove actions must not require reselecting a product.
- **Editable basket for the current shop**, with subtotal, expected balance after purchase, capacity/stock warnings and one clear “Review/Pay” transaction. Existing ShopService quote/purchase remains the authority.
- “Close shop” or “Back to market” never buys anything. A purchase returns a receipt/confirmation and refreshes actual stock/balance.
- Multi-line basket should survive category navigation; determine session-only persistence when re-entering a shop. Do not introduce global checkout across shops.

### Inventory
- Show real owned items, location/container and remaining amounts rather than generic “unit” labels.
- Distinguish material stock by weight/volume/count, packaged products, placeable equipment and prepared portions.
- Allow location/storage filtering and useful inspection of origin/quality/freshness without obscuring basic “what do I own?”.
- Keep current reservations, lot provenance and container permissions authoritative. Do not silently coalesce differently sourced/graded lots or invent capacity.

### Object-centric cooking
- Interaction prompt names the object and status: “empty kettle”, “ful pot soaking”, “fryer heating”, “batch ready: 3 servings”.
- Context panel shows actions possible **at that object**, not every possible recipe from an arbitrary counter.
- Recipe workflow can still direct player to a proper prep surface, fridge or heat device when a later step needs it; UI provides the next appropriate location rather than bypassing capability checks.
- Show waiting/heating progress, current heat, real available ingredient grades where applicable and serving options with the existing RecipeWorkflow/RecipeProcesses and MenuService, not a new recipe state machine.
- Empty persistent pot after all food served remains the player's object. Preserve legacy tea, liver, ful, shawarma etc. regardless of the launch-visible recipe assortment.

### Dialogue
- Preserve continuous world/time flow and existing Ink focus, interruptions, listen/leave and authored choice semantics.
- Put speech and options in legible compact panels, not enormous fixed overlays; retain Arabic conversational cadence and natural localization.
- No imagined relationship boost, referral or sale merely because a decorative button is shown.

## Localization/accessibility
- Arabic-first natural colloquial text, correctly ordered prices and numbers; equally complete English text. RTL/LTR mirrored where appropriate, but money, units and quantities remain unambiguous.
- Explicit focused/hover/pressed/disabled states; do not convey ownership/shortage only by hue.
- Keyboard, mouse, touch navigation, predictable Escape/back and modal stacking. Touch targets and typography must be tested against actual Web/mobile viewports, not inferred from the 16:9 image.
- 1280×720 current project viewport is a required first inspection size; verify smaller layouts through scroll/column reduction rather than shrinking text until illegible.
- Avoid hard-coded English fallback text becoming the primary Arabic player experience; use project locale keys.

## Implementation acceptance
1. A reusable style/theme and interaction pattern passes actual screenshot review in **shop, inventory and cooking**, Arabic and English.
2. Shop user can search, switch category, change multiple basket lines, see authoritative total and complete **one** valid purchase, with proper failure feedback.
3. Inventory values and recipe requirements match canonical state before/after a purchase and a preparation.
4. Back/Escape closes only the intended layer; purchase must never trigger accidentally by dismissing the panel.
5. No regression to slow frame patterns; limited representative Web/native observation is sufficient unless a real regression appears.
6. Existing features remain accessible or honestly marked for later exposure; no gameplay owner is duplicated in UI code.

## Explicit non-goals
No walkable market simulation, generic web-front-end replacement, costly high-resolution texture UI, new survival meters or premium currency, new narrative authoring tool, animated shopping minigame or full artistic sign-off. Those require separate approval. This file describes the intended surface; source specs and screenshots must validate its feasibility.
