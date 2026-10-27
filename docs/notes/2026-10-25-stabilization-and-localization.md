# Stabilization and offline localization pilot

Product source: `e9b816d7c7cdfaf319f56377f9fe783d9ea51c14`, Godot4.7.2, schema4/revision12. This implements the approved structure/performance/UI audit's first increment. No main merge.

[Preview release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/stability-e9b816d) · [Complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/stability-e9b816d/builds/kiosk-on-the-nile-stability.zip)

ZIP SHA256: `b472a55edc4216624df7b144e1c2f13578089a4cb36d8df42ffaaa19b002a409`. Downloaded the GitHub artifact and independently matched its digest, source commit, schema/revision and bundled English catalog.

## Delivered

- Supplier receipts preserve scheduled/domain time and gain a separate observation timestamp. Journal append order stays chronological at observation time; migration retains old heard text and event times. The original audit collision now resumes with one receipt/item grant per occurrence.
- Sleep catch-up has an explicit owner and returns failures. Unrelated needs/motion are no longer blocked by a supplier failure. Consistent older analytical alertness state can account a past clock gap after validating actual consumption receipts.
- Lease/supplier due cursors derive from canonical history; contract revisions invalidate them. Idle account transactions avoid copying full financial history, and actor profiles are merged once per configuration. This bounds repeated historical work; it is not a measured device-FPS claim.
- Financial dialogue preparation/context/effects have a focused adapter. One modal coordinator owns inventory, recipe, visitor, notebook, sleep, supplier, tuning and arrangement sheets; Escape/cleanup and weak return-focus targets share one policy. World time keeps running.
- Bundled Arabic/English catalogs, persisted local language preference, stable Ink line/choice references, captured named parameters and a pure localized display projection. No online translation or language download. English is written for intent and voice.
- Bilingual pilot coverage: title, menu actions, Fathi's connected call/choices and supplier sheet. Other characters, parts of HUD/system text and old history remain in their original language. Full translation and broader visual redesign remain subsequent work.
- Published supplier Ink is archived. An old active cursor completes against its original graph; no cursor transplant. New heard lines retain actual displayed text with optional localization provenance; signed financial names/amounts and historical text remain unchanged.

Authoring and coverage: [LOCALIZATION.md](../LOCALIZATION.md).

## Review and fix decisions

One fresh whole-increment read-only review, followed by one material fix pass; no second review. Three Important findings fixed: offered choices dropped localization metadata; arrangement bypassed modal ownership; cash delivery could pass its signed deadline. Nested-reference fallback and focus restoration were regraded Important and fixed in the same pass. Actual UI also exposed an unsupported `%g` supplier label format, now replaced, and the English subtitle needed wrapping. No deferred review minors.

No automated tests were added or run, per the approved plan. Validation consists of Ink/content compilation, Godot import, Debug/Release Web exports and actual mouse/keyboard browser interactions with read-only debug observations. Attempts sent before boot or before popup rendering are not counted as successful interactions.

## Evidence and limits

See [recovery observation](evidence/2026-10-25-stabilization/recovery-observation.json), [English title](evidence/2026-10-25-stabilization/title-en.png), [Fathi call](evidence/2026-10-25-stabilization/fathi-en.png), [supplier sheet](evidence/2026-10-25-stabilization/supplier-en.png), and [sleep catch-up](evidence/2026-10-25-stabilization/catchup-success.png).

Actual recovered overdue occurrence3300 yielded `item_18`, quantity2, receipt3 once; prepaid400, wallet9000minor. Receipt due time3300 is retained with observation3575.31666666878. Two further12-hour sleeps crossed4740: receipt4/item19 once, wallet unchanged and no dependency failures. The genuine recovery profile had been saved during earlier diagnosis; which primary/backup candidate was used is not independently proven. Do not describe this as proof of recovering every malformed save.

Manual coverage does not exhaust pause/amend/cash deadlines, all fallback/catalog failures, every keyboard focus path, long histories or all screen sizes. There is no real-GPU/native profiler evidence in this cloud workspace. Shipped offline resources do not imply hosted PWA/installable caching. Browser saves remain origin/port-specific.

Actual exact Debug export: live English→Arabic choice preserved conversation1/beat1, full canonical frame and state hash `e46185b5294ad6bf330879959728b2541d827c7dacb87cb6611d91b233e5b733`. A deliberate Save/reload retained Arabic preference; switching title to English then Continue restored the same hash and English choices. One English consent granted one sandwich/receipt and one300minor invoice; actual heard English choice/reply snapshots carry their stable references. See [locale observations](evidence/2026-10-25-stabilization/locale-observation.json).

## Release-browser samples

Same Chromium/SwiftShader software WebGL, single browser,8-second rAF/CDP samples as the audit; stock Release, no debug probe. [Raw summaries](evidence/2026-10-25-stabilization/release-browser-metrics.jsonl).

| Scene | Viewport | Audit median/p95 | This export median/p95 |
| --- | --- | --- | --- |
| Rooftop |960×540|100.0/133.3ms|66.6/83.4ms|
| Active Fathi call |960×540|66.7/83.4ms|66.7/83.4ms|
| Supplier sheet |960×540|99.9/100.1ms|83.3/100.0ms|
| Supplier sheet |1280×720|133.4/183.4ms|116.7/133.4ms|

Main-thread task time remains around8.15–8.18s over each bracket. These short samples have evolving world state, no repeated statistical trials and no function-level attribution. Smaller rendering intervals in some samples do not establish a reproducible optimization gain or player-device FPS. JS heap excludes WASM/native/GPU memory. Two initially mislabeled supplier captures still showed the call because a coordinate missed the RTL button; excluded them and repeated after visually confirming the sheet.

Actual Release also opened arrangement with dialogue hidden; Escape removed the build grid/preview and restored movement. Supplier sheet/back and arrangement used the common modal path. No redesign or exhaustive controller-focus validation is implied.

Exact stock Release Save/reload/Continue restored the existing Fathi management beat and player position, with no debug bridge. [Release Continue](evidence/2026-10-25-stabilization/release-continued.png). The final ZIP contains the untouched stock external bundle; audit-only fast lease/time/balance overrides are not packaged.
