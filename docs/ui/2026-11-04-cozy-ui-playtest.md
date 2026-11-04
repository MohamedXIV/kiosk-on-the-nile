# Integrated cozy UI playtest

Implements the updated all-screen scope of #48 against main c7622bb, guided by Epic #47 and PR #56. This is a development PR, not a release. VERSION and save schema/revision are unchanged.

## Coverage

- [x] Title, New/Continue, language selection, loading and load-error feedback.
- [x] HUD clock, wallet, existing needs, held item, contextual prompts, world captions/order badges.
- [x] Action navigation, outings, language/accessibility/help, separated development tools.
- [x] Shop catalog, product glyphs, selection/details, quantity, review/confirm, purchase feedback and return.
- [x] Inventory containers, search/filter, source lots/freshness/reservations, pack/unpack, held food and storage actions.
- [x] Recipe care, preparation, active jobs/progress, heat, grade, personal cooking, serving variants/additions and cancellation.
- [x] Menu prices and additions, explicit apply with draft preservation.
- [x] Dialogue, authored choices, leave/listen, visitor actions and hospitality/payment decisions.
- [x] Notebook notes/people, relationships, heard history/search/filters/paging, accounts and receipts.
- [x] Supplier account, basket, schedule, delivery options, quote/accept/decline and cash confirmation.
- [x] District offers, quote/receipt/payment and return.
- [x] Journey progress, sleep duration/wake preview and confirmation.
- [x] Furniture/equipment placement dock, coordinates/host/rotation/store and validation.
- [x] Toasts, empty/error/disabled states, transition veil and developer tuning.

## Implementation

UiText delegates to one cached CozyTheme. SheetControls supplies native responsive shells, headers/cards, semantic action roles, focus-following scroll regions and adaptive columns. Panels still read existing owners and invoke the same commands. No replacement inventory, cooking, commerce, travel or narrative state exists.

Colors use ivory, sage and quiet warm neutrals with Cairo typography. Explicit mirrored semantic styles keep primary buttons readable in RTL. Labels use logical leading alignment to avoid double mirroring; heard paragraphs preserve their own direction. Controls retain 44px targets and visible keyboard focus. Shop checkout stays separate from the scrollable product/detail regions; small screens can scroll long descriptions. Refreshes retain existing event/revision boundaries rather than rebuilding every frame.

## Verification and limits

- Pinned Godot 4.7.2 editor/templates verified by repository tools. Import, Ink/localization checks and Web export ran.
- Current complete suite: 58 cases, 881 assertions, zero assertion failures. The wrapper still exits nonzero because configured gameplay fixtures retain 22 resources at shutdown. This diagnostic also occurs on unchanged main; it is not hidden or described as a clean suite.
- Unchanged main originally had 11 stale assertion failures plus an obsolete CookingService.configure call. Tests now exercise current content/API contracts without changing production gameplay/balance.
- Native GL Compatibility/llvmpipe captured 76 deterministic production-control scenarios in Arabic/English at 1280×720 and 640×540. Representative screenshot review found and corrected mirrored primary contrast, text alignment and short-shop layout issues. The included short-shop screenshot is after those fixes.
- A deterministic preview is available in debug Web builds using `?qa=cozy&area=shop&lang=ar_EG`; replace area with title, hud, inventory, recipe, recipe_v2, dialogue, notes, people, history, accounts, receipts, visitor, payment, supplier, district, sleep, journey, build, menu or tuning. These use actual controls and domain fixtures; no player save is read or written. V2 recipes truthfully show initial missing ingredients and initial receipts are empty.
- A 12-second native populated-scene observation ran with three real visitors at 1280×720 using GL Compatibility/llvmpipe and existing opt-in counters. This was a bounded software-renderer observation, not a matched device benchmark. See the retained log.
- Web Chromium rendered title, shop and inventory previews from the actual export; the retained Web shop image is from that run. Broader browser flow validation is not claimed complete.
- Preview captures do not establish long-session gameplay acceptance, physical touch/device performance or save persistence across browser/storage environments. No device FPS guarantee is made.
- Future multi-line carts, six-shop hub, material units/brands, persistent cookware and retail/referrals (#49–#54) remain separate. Current shopping stays the existing single-selection reviewed purchase; all existing recipes and routes remain accessible.

## Playtest

1. Install the pinned toolchain with `bash tools/setup.sh`; run `bash tools/run-tests.sh`, noting the teardown diagnostic above.
2. Launch `bash tools/godot.sh --path .`, or build into a fresh directory with `bash tools/build.sh --out /tmp/cozy-ui-web` and serve it using `python3 tools/web/serve.py /tmp/cozy-ui-web`.
3. Try New and Continue, switch Arabic/English, visit the kiosk, open each action-menu tab and notebook tab. Resize the viewport. Use Tab/Shift-Tab, Enter, Escape and the mouse; confirm offscreen focused controls scroll into view.
4. Visit each existing shop: select/search, change quantity, review, cancel/return without paying, then purchase deliberately. Check wallet, stock and bag against the shown quote.
5. Inspect inventory, prepare tea and a learned recipe, change heat/serving options, inspect freshness/storage, edit menu prices, talk and choose hospitality/payment.
6. Open supplier terms and district quotes, arrange furniture, preview/cancel sleep and save/Continue. Confirm world time follows existing rules and every refused action explains itself.

No merge, release, archive publication or version bump is authorized by completion of this playtest PR.

## Follow-up Web check

Actual normal Chromium startup entered gameplay using Enter, opened the notebook with N and dismissed it with Escape. Wallet and inventory snapshots remained unchanged. Screenshots and machine-readable results are retained under the evidence directory. This verifies that specific interaction, not all browser persistence or touch flows.
