# Body, clock and tweaks — delivery

Product `2fd604824ca3ac147635f0cd5a4a6c749f4c749b`, base `a8e158e`. Increment2 of the approved everyday-life plan; Godot4.7.2, Ink, external JSON, schema4/revision9. [Values and usage](../BODY_AND_TUNING.md).

[Preview release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/body-clock-2fd6048) · [Complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/body-clock-2fd6048/builds/kiosk-on-the-nile-body-clock.zip)

ZIP SHA256: `2e637fc6f5d9151a42f571ff739a987e54c95c464a1591df9440381c404f4c88`. Source branch `preview/body-clock-2fd6048`, artifact branch `build/body-clock-2fd6048`; no merge into main. Earlier5c89ec0/8d0a1a3 preview branches are superseded, without a published release.

## Delivered

- Default calendar speed1minute/second. Need decay uses world minutes (hunger6/hour, rest4/hour), with quiet visitor arrival/stay durations on that calendar. Movement, readable speech and physical cooking reaction windows use simulation time. Existing recipes retain frozen quality/ingredients/timing; long cold waits and batch heating remain calendar based.
- Needs and temporary focus are separate owners. Tea boosts focus without restoring rest, with diminishing cups, expiry, cap and recovery-cycle budget. The actual ItemStore consumption receipt grounds each dose; insufficient sleep accounts for elapsed stimulation before retaining the budget. Sufficient sleep resets the cycle.
- Finite action classes check eligibility before spending/reserving. Hunger permits conversation, preparation and care routes. Severe fatigue can stop new focus/work while personal-use cooking, eating, travel/sleep and practical requests remain available. Timed work and open choices finish without random interruption; tired personal conversations stop at the chapter boundary.
- Low mood retains quality penalties and may refuse a new work opportunity. The decision, cooldown/day limits and effort sources survive saves. Actual preparation steps/cleaning/placement cost effort once. Personal-use portions cannot be sold to bypass commercial policy.
- Saved deterministic intermittent blur is below HUD/captions; normal/reduced/off visual strength does not alter eligibility. The HUD distinguishes true rest/effective focus.
- Validated developer tuning imports/exports JSON, saves local Web overrides and applies the whole candidate at a simulation boundary. Invalid proposals leave good state intact; names are display overrides, never actor IDs. The opt-in flag and F8/menu instructions are in BODY_AND_TUNING.md.

## Evidence and review

No automated tests were added or run. Ink compilation, Godot import and debug/release Web exports succeeded, including exact product exports `/tmp/kiosk-body-ship-debug` and `/tmp/kiosk-body-ship-release`. `git diff --check` was clean.

One fresh independent read-only whole-increment reviewer found four P2 issues: migrating elapsed visit duration without its maximum waiting limit; insufficient dose/budget provenance validation; short sleep dropping active stimulation time; and unavailable automatic invitation listening retrying forever. All were addressed. Its batch slicing timing observation was regraded Important because the physical timing guarantee includes that action; slicing now uses frozen simulation timing separately from batch heat. Existing started steps, hunger-exempt preparation and deferred rent/help/payment were accepted as intentional. No second reviewer was used.

The same acceptance/fix pass added selected-pulse consistency checks, persistent non-cooking effort IDs, a tuning-panel ordering correction, live sleep-duration preview and an integer normalization fix for restored refusal-day keys. Actual UI caught the latter by rejecting a genuine save containing a refused attempt; validation remained enabled, and the same save was reopened after regeneration. The narrow mismatch diagnostic remains for invalid candidates.

### Actual UI observations

Chromium/WebGL over local HTTP, ordinary mouse/keyboard and read-only snapshots; no callable gameplay command bridge.

- Genuine revision8 saved service response resumed in the new product with `conversation_1/beat2`, the same pending `visit_1/order_1/tea`, journal count3 and wallet4500. Migrated maximum waiting duration was400world minutes. The held speaker/order/history stayed intact. [Migration UI](evidence/2026-10-24-body-clock/revision8.png).
- At true rest8/hunger5, ordinary preparation was denied with its fatigue reason, while the recipe panel's personal-care route started real tea. Preparation steps produced `cook_1`, consumed one portion and recorded two effort sources, reducing true rest8→7.2 and mood15→13.8. [Denial](evidence/2026-10-24-body-clock/fatigue-denial.png).
- Drinking the actual `food_17` recorded consumption, boost12/deadline90minutes, mood recovery and unchanged true rest7.2. Later wear-off removed the temporary eligibility. A genuine save with this dose and an active second cooking job reloaded without resetting their sources/elapsed contract.
- In a separate forced-probability scenario, self-care cooking at hunger0/rest8 still worked. After drinking, two commercial clicks retained one refused opportunity, daily count1, no new cooking job and no additional ingredient debit. [Refusal](evidence/2026-10-24-body-clock/mood-refusal.png). The same saved refusal/dose subsequently reopened with daily count1 and its original timestamps; a JSON numeric-key normalization defect found during this gate was fixed.
- A well-formed tuning proposal with speed1000 was rejected while speed1 remained active. A valid mood-threshold/probability proposal applied; exported JSON downloaded and a real JSON file import populated the editor. Applying it preserved current needs/items and exposed its actor-name override. [Invalid proposal](evidence/2026-10-24-body-clock/invalid-tuning.png) · [Imported file](evidence/2026-10-24-body-clock/imported-tuning.png).
- Blur visibly affected world geometry/character while HUD and prompts stayed sharp. [World-only blur](evidence/2026-10-24-body-clock/world-only-blur.png).
- With low rest, the player travelled home, obtained a paid snack and used the bed. A full sleep restored rest to100, cleared doses/budget, advanced across midnight and charged the existing legacy daily rent once. Typing duration originally failed to update the old SpinBox value until submission; update-on-text-change was added before final export.

Scenario overrides were only in `/tmp` exports: initial kiosk positions near tea, initial rest8/hunger0 or5/mood15, seed1437 with no eligible visitors for isolated care checks, decay rates0, developer panel enabled, and threshold50/probability1 to force refusal. These are NOT release defaults. An attempted pre-granted prepared item fixture was rejected by content validation and discarded; accepted drink evidence came from actual cooking.

## Limits

The fifth cup, full180-minute stimulation cap, active-dose short-sleep overlap, true-rest floor3 under caffeine, midnight refusal-cap reset, speed changes during every active recipe/slice, corrupt/resealed save variants, invitation expiry race, reduced/off visuals, all pre-revision8 migrations and statistical pacing/balance were not manually exercised. The relevant policy/provenance/timing cases were inspected and compiled. Native editor and real-GPU inspection remain unperformed. A headless download operator lost its context once; later single-browser export/import succeeded. Expected invalid-candidate/early fixture diagnostics were recorded rather than treated as passing gameplay.

## Execution decisions retained

1. Existing managed checkout stayed on `work`, isolated from main by branch rather than a second worktree; this preserves setup/caches but offers less filesystem isolation.
2. Developer/session no-tests instruction overrides skill TDD steps; build and manual coverage are narrower than an automated regression suite.
3. Developer panel is enabled by external data flag, default false. Visual accessibility remains available separately; browser export/import never claims server-file writes. Enabling development options is deliberate.
4. Legacy `_seconds` visit field names remain with explicit world-minute domain for compatibility; old residuals and maximum wait convert once using historic2.5min/sec. Historical saves did not freeze custom maximum-wait overrides, so migration uses the configured limit for that missing term.
5. Short preparation uses frozen presentation rate × simulation delta; long cold/batch heat uses the world calendar, and sleep advances unattended work using its shared elapsed frame. This preserves reaction windows and requires authors to distinguish the domains.
6. Documentation evidence has `.gdignore` to avoid importing screenshots into the game; no gameplay data is affected.
7. Task1 and Task2 foundations were integrated because whitelist consumers must agree before content can activate; UI acceptance followed the integrated persistence/presentation work.

Legacy rent remains until increment3 replaces it explicitly; new housing/district accounts and suppliers were not included. The approved next increment is weekly obligations, real counterparties and payment/receipt flows, followed by suppliers.

## Final artifact gate

The exact release product opened with untouched repository content at960×540 and1280×720. Typing1 updated the sleep preview immediately to one hour; confirming later used the then-current world time, and the wake message reported18:00 after the one-hour sleep. World time continued while the menu was read. The release exposed no read-only debug probe. [One-hour preview](evidence/2026-10-24-body-clock/one-hour-preview.png) · [Release after waking](evidence/2026-10-24-body-clock/release-awake.png).

The final GitHub ZIP was downloaded again and matched SHA256 `2e637fc6f5d9151a42f571ff739a987e54c95c464a1591df9440381c404f4c88` exactly. All intermediate artifact branches are superseded by `body-clock-2fd6048`.
