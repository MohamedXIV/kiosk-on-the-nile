# Standard prompts and sleep UI

2026-10-25, Africa/Cairo. Product46a26af57f039c1d5f79bcd29678e8e5eb478073, Godot4.7.2, schema4/revision12 unchanged. No main merge.

## Scope

Paired offline catalogs for standard talk/serve hints, input help, save/load, travel, cleaning, sign, diagnostics and sleep messages. Names in talk/serve use guarded current actor/item presentation; canonical IDs and heard history unchanged. Native sleep sheet scrolls; title/confirm/cancel follow locale, hours suffix updates on locale signal, existing requested duration/wake preview/recovery policy stays authoritative. No Ink branches/effects/time/needs/sleep/save-policy changes. Station-specific prompts, room data hints, many errors, district/developer UI and most character dialogue remain partly Arabic; this does not complete full-game localization.

## Review/build/actual checks

One fresh read-only prompts_review found Important: locale-bound help lacked input substitution args, falling back to previous-language text on locale change. One material fix pass binds captured configured move/primary/secondary/notebook keys. Root also moves suffix updates from every frame to locale signal to avoid needless field text rewriting. No second review. No automated tests added/run.

Ink/reference build checks, Godot import and Debug export succeeded; exact final Release build/export succeeded. Actual Chromium/SwiftShader mouse/keyboard in stock new game, no injected state/commands. Debug English sleep at960 showed8-hour preview and readable recovery/timing, with scroll reaching controls. Typed2 and Tab updated requested duration/expected wake without sleeping. Attempt to use HUD menu while sleep modal was active did not open it; Escape closed the sleep modal. Do not claim that attempt proves language switching inside an open sleep sheet.

Final exact Release boot/new game succeeded. Menu at960 displayed configured movement/interact/notebook keys in English, fatigue setting and travel controls. Locale switched through normal menu; final Arabic menu/sleep captures record actual result. No sleep confirmation, payment, item transfer or narrative choice was performed. Software WebGL does not establish player-device FPS. Most game-system message variants are translated by catalog inspection/build validation, not individually triggered. Serving an order, custom labels, old raw legacy prepared items, old active saves, full keyboard navigation, arbitrary resolutions and every sleep policy/error case remain unexercised.

Debug screenshots predate final help binding/suffix-signal fix; release-* use exact final product. Package has stock content, not QA fixtures. Existing story/history strings remain original.

## Delivery

- [Prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/prompts-46a26af)
- [Complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/prompts-46a26af/builds/kiosk-on-the-nile-prompts.zip)
- Source preview/prompts-46a26af; artifact build/prompts-46a26af, commit9df91c1173c882b4d9bf4b3368079f9b59ec8184.
- SHA2567d5775e851042692e735e443bc26176aa948cbb113856ccbe3ede683aa58128a,11802758bytes.

Complete Release assets, external stock content/catalogs/fonts, licenses, RUN.txt, LOCALIZATION.md and BUILD.json source/schema/revision/debug_probe=false. GitHub ZIP independently downloaded/SHA checked and BUILD/bundled assets inspected. Extract everything into fresh folder; `py -m http.server 8765 --bind 127.0.0.1`, open http://127.0.0.1:8765/ . Keep content/ and all kiosk-* files together. No file://; exact origin/port owns saves. Bundling offline content does not promise hosted PWA caching.
