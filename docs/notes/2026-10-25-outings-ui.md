# Shopping, travel and visitor conversation UI delivery

2026-10-25, Africa/Cairo. Product source `07bb9a11ca2084ed356c7eb95b521b4bea8c8a0e`, Godot4.7.2. Save schema4/revision12 unchanged. Native UI and bundled catalogs only; gameplay prices, stock, timings, quiet independent visitors, Ink logic and historical text remain owned by their existing systems.

## What changed

- Searchable offer list and independently scrollable selected-product details, contents, size, mounting/capabilities, quantity, reviewed total and separate confirmation. Both language variants match search when the authored source is known. Empty search lists all available offers.
- Locale switch retains selection/quantity/quote/request identity; changing product/quantity/stock invalidates review. Editing the SpinBox draft invalidates immediately, and applying input precedes review/confirmation. Purchase ownership/idempotence remains in ShopService.
- Scalar ShopService revision query avoids copying complete stock/receipt/delivery history every visible frame. No measured FPS improvement is claimed.
- Guarded shopping descriptions, route/phase text, visitor topic/order labels and actual personal conversation hub speaker/topic headings. Unknown/externally changed source labels retain original wording. Topic keys identify their real social action or encounter/topic; labels do not grant eligibility.
- Focusable localized sheet actions and dialogue buttons; native scrolling at960×540/1280×720. Physical interaction prompts/dialogue are suppressed while away. Time continues and return takes the existing configured time.
- The older standalone VisitorPanel remains compatible but normal gameplay currently calls PersonalConversations and DialoguePanel. The active hub now receives the translated presentation; E still opens the existing continuous dialogue directly. Most character Ink conversation content and some HUD/system labels remain Arabic. No claim of full English coverage.

## Review and material fix pass

One fresh read-only reviewer inspected `30e3781..709451b`; no tests/edits/subagents. Important: EN returning message introduced an unmatched place placeholder and prevented catalog validation/startup; root independently reproduced and fixed matching parameters without relaxing validation. Important: key buttons inherited FOCUS_NONE; localized SheetControls.key_button now gives keyboard focus/wrapping. Minor: no-topics wording offered chat while talk could be disabled; wording is neutral.

Root actual input additionally caught empty query hiding all cards, obsolete world prompt underneath nonphysical sheets, and verified quantity drafts need immediate invalidation. Root integration tracing found the old visitor sheet unused and applied guarded topic/speaker rendering/focus to the existing active hub. These rulings were handled in the single material fix pass (`bf5d8f7`, then active-hub correction `07bb9a1`); no second review. The provisional `outings-bf5d8f7` release is marked superseded and remains immutable.

## Actual acceptance evidence

No automated tests added/run. Build-only Ink localization check, Godot import and Debug Web export succeeded; exact final Release export succeeded with no script/parse/compile errors. Real Chromium/SwiftShader mouse/keyboard, no injected saves/positions or callable command bridge; Debug observations are serialized read-only QaProbe state. Software rendering does not establish player-device FPS.

- Genuine Continue at origin8844 restored existing cup/completed/cancelled preparation state. Actual market departure, outbound display, browsing/search, quote, purchase, save/Continue, return and final Release appliance visit. World clock advanced through browsing and travel.
- Arabic960 market search `tea` matched tea and bundle. Switching to English retained query, selected item and reviewed total. Whole ShopService observation identical before/after locale: revision1, next_quote2, no receipt, tea stock20. [Observation](evidence/2026-10-25-outings-ui/shopping-observation.json).
- Explicit new review bought tea2 for200minor: wallet4500→4300, stock20→18, one receipt1 and grant item18quantity2 in journey2 bag. Genuine saved shopping state restored with those balances/items; return completed at original kiosk pose. No duplicate receipt observed.
- First draft attempt crossed scheduled restock and therefore alone did not isolate draft behavior; this limitation is preserved in evidence. Repeated away from restock at1280: reviewed one tea, typed2 without Enter, clicked Confirm. Button disabled/total cleared; entire ShopService snapshot identical, no debit/grant/receipt. [Isolated observation](evidence/2026-10-25-outings-ui/quantity-draft-observation.json).
- Empty search after correction displayed the full list at960 and1280. Final Release appliance product showed translated fridge description, capacity, footprint and capability; Arabic1280 mirrored the content with no obsolete physical prompt.
- Final exact07bb9a1 Release boot and genuine Continue from a stock new-game save on8845 succeeded. Actual walking through the right room door/stairs and around the kiosk reached Mona; E opened the real personal hub with “Mona”, “What shall we talk about?”, “How have you been?” and Leave. Screenshot: [active hub](evidence/2026-10-25-outings-ui/final-conversation-hub.png). Actual mouse selection then opened Mona’s authored Arabic spoken line with English Continue/Leave controls ([spoken frame](evidence/2026-10-25-outings-ui/final-mona-spoken.png)). This is the active gameplay route, not a manually exposed legacy sheet. A Tab/Enter attempt did not visibly open the topic; mouse selection was used, so complete keyboard navigation is not claimed.

Screenshots from earlier709/bf5 iterations document specific acceptance/failures; `release-appliances*` use bf5 Release and `final-*` use exact07bb9a1 Release. They are not all from one identical build. No temporary content fixtures or altered gameplay data are in the package.

## Limits and remaining coverage

No exhaustive commerce matrix: insufficient funds/full bag/stock-zero/unique knowledge-gated fan, every equipment purchase/homeware return placement, every visitor/social topic, old paused Ink choices, custom labels and all keyboard/controller paths were not manually exercised. Inactive standalone visitor sheet is inspected/compiled, not claimed reachable. Full narrative English adaptation, remaining HUD/build/tuning UI cleanup and real-GPU performance measurement remain later work. Existing historical heard text and signed receipts stay as recorded. No main merge.

## Download

- [Final prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/outings-07bb9a1)
- [Complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/outings-07bb9a1/builds/kiosk-on-the-nile-outings.zip)
- Source preview `preview/outings-07bb9a1`; artifact branch `build/outings-07bb9a1`, commit `aa0893d129bcbfc7308ea6a5fe1ba6cd6581c489`.
- SHA256 `64ae411c6415580dec73b0d1c8de69ef999847cf05899525390a9f049917c545`,11795955bytes.

Complete stock Release export, external content, both catalogs/fonts, licenses, RUN.txt, LOCALIZATION.md and BUILD.json with source07bb9a1/schema4/revision12/debug_probe=false. Downloaded GitHub archive is independently SHA checked and BUILD/assets inspected. Extract all files into a fresh folder; `py -m http.server 8765 --bind 127.0.0.1`, open `http://127.0.0.1:8765/`. Keep content/ and all kiosk-* assets together. Browser saves belong to exact origin/port. Bundled offline assets do not promise hosted PWA caching.
