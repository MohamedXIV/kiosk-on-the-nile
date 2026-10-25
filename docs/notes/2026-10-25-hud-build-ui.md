# HUD and arrangement UI delivery

2026-10-25, Africa/Cairo. Product `c2dae7d7e5cf049a79d7a1acdae085292281b1bc`, Godot4.7.2, schema4/revision12 unchanged. No main merge.

## Changes

HUD time/cash/sign/stock/needs, held item names and fatigue/status tooltips use bundled Arabic/English catalogs. Layout follows locale; held items use guarded ItemText projection. Arrangement labels and policy hints translate with guarded item/host names. Locale rebuilding does not invoke select/preview/place and retains request identity, coordinates/rotation and host. Native scrolling bounds the arrangement sheet; actions have minimum90×44 logical size and keyboard focus. Menu uses a nonwrapping localized button with minimum80px width.

Some world prompts/errors/system text and most character Ink dialogue remain Arabic. This is not full game English coverage or a comprehensive redesign of every HUD/prompt. Historical heard strings/receipts unchanged. No gameplay timings/prices/capabilities/placement rules/Ink logic/save migration.

## Review and observed fixes

One fresh read-only hud_build_review found no Critical/Important/Minor defects; requested manual checks of long HUD, action-row sizing, mounted-host locale switch, coordinate drafts/Enter. Root screenshots independently exposed wrapping buttons collapsing to thin tall strips: first menu inflated HUD height; then arrangement action row. One material fix pass restored nonwrapping menu/minimum width and explicit action minimums. No second review. No automated tests added/run.

Build-only Ink/reference checks, Godot import/Debug export and exact final Release export succeeded. Actual Chromium/SwiftShader mouse/keyboard from genuine saved game, no injected state/callable game bridge. Final Release Continue restored cup, balance and kiosk; Arabic960 HUD stayed compact with fatigue warning. English960/1280 showed time/money/sign/Need sleep, stock/needs and Cup of tea (regular sugar). Actual arrangement Tea kettle selection showed X−7/Y3 and Preparation worktop/counter_1, readable Rotate/Place/Store, interior-only policy and Finish arranging.

A Debug table preview locale switch left entire SpaceService snapshot identical ([observation](evidence/2026-10-25-hud-build/locale-placement-observation.json)). Outside-popup dismissal in that attempt also sent a world click, so the captured table preview moved from23/4 to−5/−19; do not interpret this as proof of numerical preview retention. Exact final Release mounted-kettle before/after locale screenshots provide the narrower UI check without that extra world click. No placement confirmation/storage action was performed in this UI-only acceptance.

Evidence filenames marked pre-action-width-fix show the earlier failure, not final shipping sizing. Final-* captures use exact final Release. Actual GUI keyboard End/Enter did not complete the dropdown selection; mouse selected the kettle. Full keyboard navigation, SpinBox drafts/Enter, long custom labels, suspended-business status, arbitrary resolutions/controller, confirm/store policy errors, all held types and real-device performance remain unexercised. Focus flags alone are not a full keyboard acceptance claim. No FPS claim from software rendering.

## Download

- [Prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/hud-c2dae7d)
- [Complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/hud-c2dae7d/builds/kiosk-on-the-nile-hud.zip)
- Source `preview/hud-c2dae7d`; artifact `build/hud-c2dae7d`, commit `363f8cf3ac47eaa732d78db76a7ea171eabfbf5d`.
- SHA256 `2475862b3a9ac3457c73c3ceb34b04e44b94c75ce651179fd41092c26627ccc6`,11798538bytes.

Downloaded GitHub ZIP independently SHA checked; BUILD.json source/schema/revision/debug_probe=false and bundled catalogs/run guide/licenses verified. Stock Release export includes external content/fonts/catalogs and all engine assets. Extract into fresh folder, keep all files together; `py -m http.server 8765 --bind 127.0.0.1`, open http://127.0.0.1:8765/ . Do not use file://. Browser saves depend on exact origin/port. Bundled offline assets do not imply hosted PWA caching.
