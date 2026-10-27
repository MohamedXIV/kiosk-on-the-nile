# Inventory, care and preparation UI

Product source `a07aedb4e5c311dc65da9d1cb81444c2934e9808`, Godot4.7.2, schema4/revision12 unchanged. Continues the approved UI/offline-localization rollout after notebook. No main merge, new recipes or altered cooking/learning rules.


[Preview release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/items-a07aedb) · [Complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/items-a07aedb/builds/kiosk-on-the-nile-items.zip)

ZIP SHA256: `92da69374b6774e9058cb9ccef142adc0e65b74c29267d9e75b3ab6ee0bf4e37`. Downloaded the GitHub artifact and matched digest, BUILD.json source/schema/revision, bundled catalogs and disabled Release debug probe.

## Delivered

- Searchable storage sheet with stable storage-kind filters, container capacities, empty states, held-item context and reserved-ingredient indicators. Search includes exact-source-guarded names in both bundled languages. Same pack/unpack/bowl commands and owner validation; whole-bag unpack explicitly includes everything that fits, including filtered-out items.
- Item sheet separates use/care, active preparation and existing eligible recipes. Ingredient amounts and required capabilities are visible; starting a job selects its active view. Active kettle/griddle workflow F now opens read-only options so progress remains accessible after closing. Primary cooking actions and empty-station routes stay unchanged.
- Stable item/food/recipe/step catalog references with exact source guards. Frozen/custom labels remain source text when not provably the authored translation source. Parameterized tea names resolve source and sugar argument together; canonical item/job definitions and historic records stay unchanged.
- Current-storage projection excludes consumption history. Job progress uses scalar snapshots; structural updates coalesce, while progress/care update at a bounded interval. No per-frame full frozen-job copies in RecipePanel. Closing sheets does not cancel jobs or cleaning.
- Bundled Arabic/English labels, item names, steps, care statuses and relevant errors. No translation API/download. Broader shop/travel/visitor/HUD/character adaptation remains pending; this is not a fully English game.

[Authoring and localization boundaries](../LOCALIZATION.md).

## Review and decisions

One fresh read-only review87c6e0d..2538f30 and one material fix pass; no re-review. Important fixes: parameterized prepared-tea label resolved too early, successful start left progress hidden, feedback survived switching target. Actual UI exposed collapsed wrapped action-button widths, also fixed with explicit native control sizing and minimum title line height. No Critical or deferred Minor findings.

Ruling: old interaction routing removed secondary options while a legacy station was busy. Keeping a visible read-only F inspection path is necessary to return to the new progress sheet. It does not advance cooking or interrupt it. Existing work checkout and previously authorized preview publication retained after user's “كمل”; no additional permission gate. Unknown/custom text keeps truthful source fallback. These are UI/API ownership changes, not a device-FPS claim.

## Validation and limits

No automated tests added/run per developer/session instruction. Catalog/Ink compilation, Godot import and exact Debug/Release Web exports passed. Actual mouse/keyboard browser input and read-only QA snapshots; no injected saves/commands.

- Stock new game: English empty home storage and desk care/non-recipe state; walked through the real right-side door/stairs and normal10-minute journey to the kiosk.
- Actual pack/search/unpack moved `item_1` tea6 from kiosk_dry→player_bag→kiosk_dry. Whole ItemStore snapshot restored exactly, including same ID/quantity and next_id17. [Observation](evidence/2026-10-25-inventory-preparation/transfer-observation.json).
- Actual tea self-preparation selected In progress, with live elapsed time/action visible. After waiting for browser save synchronization, genuine Continue restored cook_1 active with identical frozen definition/sugar/input evidence; F reopened its progress sheet. Completed it through the actual water/brew actions: one food_17, tea6→5, no reservations left, fully English “Cup of tea (regular sugar)”. [Active restore/completion](evidence/2026-10-25-inventory-preparation/active-restore-observation.json).
- Started cleaning the kettle, closed the sheet and waited9s: cleanliness100, no pending cleaning and action inactive, without a movement/interrupt command.
- Started a second self-preparation, then searched tea in inventory. Reserved1 of5 was visible and Pack disabled. Switching English→Arabic kept the query/results and the exact frozen job definition; job IDs/counters/reservation stayed unchanged. Arabic1280 showed the same prepared item in hand. No repeated start/effect.

Not exhaustive runtime coverage: full/partial transfer capacity, marinating-bowl cold storage, all six recipes/capabilities, cancellation after consumed inputs, custom/frozen changed labels, large inventories, every focus/input path or old legacy active-job migration. No real-device performance measurements. Some development captures intentionally record pre-fix layout; release-prefixed captures document the shipped result.

An early fast-close Save attempt while the toast still reported pending browser synchronization did not retain the latest active job. It is not counted as a pass; the successful save/Continue case allowed the pending Web synchronization to drain before reloading. This increment does not add a synchronization-completion UI to the existing save system.

Exact stock Release boot/Continue restored the held prepared tea plus the second active preparation; F reopened its Arabic active sheet at960×540. [Release Continue](evidence/2026-10-25-inventory-preparation/release-active-continue.png). The package is the complete stock bundle; no QA fixture overrides or debug probe are shipped.

Compatibility ruling: older raw legacy-adapter cooking jobs have no workflow card. Their original primary station controls and hidden secondary behavior are retained; the new F inspection shortcut applies to workflow-backed jobs. The final source adds only this guard to the already exercised modern UI path; older active migration is still not an exhaustive runtime matrix. Earlier previewa338d83 remains available as superseded, with its original immutable source/artifact.

In the Release UI, explicit cancellation before consuming the second job's inputs released its reserved unit: the HUD returned tea4→5 available, inventory still showed quantity5, Pack enabled and the original prepared cup remained held. [After cancel](evidence/2026-10-25-inventory-preparation/release-unreserved-stock.png). This does not cover cancellation after consumption or a marinating vessel.

Final sourcea07aedb Debug/Release exports passed; actual final Release Continue retained the prepared cup and completed/cancelled jobs. Started a fresh self-preparation, closed the sheet and reopened it through F: the active modern workflow view remained reachable after the older-adapter compatibility guard. [Final active options](evidence/2026-10-25-inventory-preparation/final-release-active-options.png). Earlier a338d83 observations remain evidence for the same modern UI/owner behavior before that two-line compatibility guard.
