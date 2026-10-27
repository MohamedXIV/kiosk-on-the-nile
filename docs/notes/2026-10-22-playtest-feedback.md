# Player feedback — 2026-10-22

- Possible delay between E and a conversation opening: **observation only**.
  Do not change timing or preload behavior until the player supplies measured
  reproduction details. Reported latency is not confirmed as a separate defect.
- Confirmed sticky dialogue panel after a reply/travel: browser reproduction
  found Hud.present passed an untyped empty array to a typed dialogue view when
  focus was absent. The update aborted before hiding the old panel. Use the
  director's consistently typed choices result for both active and absent focus.
- Sleep/mood rules approved by the player: 1–12 requested hours, calendar days,
  rent once per new day, proportional recovery, visible bounded mood/rest-based
  oversleep and a mood modifier on preparation quality. Implementation replaces
  the original prototype's fixed 15:00 next-day sleep behavior.
- Current authored UI/dialogue language is Arabic. English localization has not
  been requested for implementation yet; the player asked whether it exists.

## Sticky-panel reproduction and fix evidence

A debug Web run reproduced a per-frame error at `Hud.present`:
`The array of argument 2 (Array) does not have the same element type as the expected typed array argument.`
The untyped `[]` branch was evaluated exactly when there was no focused
conversation, preventing `DialoguePanel.present(null, ...)` from clearing the UI.
The fix calls `NarrativeDirector.choices()` even with null focus; that method
returns its declared `Array[Dictionary]` empty value.

After rebuilding, the same actual mouse/keyboard flow opened Amgad's authored
choices, clicked the first reply, displayed his reply without the choice panel,
and returned to the rooftop without leftover choices. Screenshots inspected:
`/tmp/kiosk-dialogue-choice2.png`, `/tmp/kiosk-dialogue-replied.png`,
`/tmp/kiosk-dialogue-home.png`. The corrected run reported no script errors in
that flow; Chromium/SwiftShader emitted WebGL warnings. Opening delay was not
changed or presented as resolved. No new automated test suite was added/run.

## Approved sleep/mood implementation

- `content/wellbeing.json` stores duration limits and deterministic oversleep/
  quality rules. Defaults: mood <35/rest <35 adds 2 hours; otherwise mood <55/
  rest <60 adds 1 hour. Good mood preserves the requested duration.
- A batch captures its mood penalty at preparation start: mood <35 costs up to
  2 quality grades, otherwise mood <60 costs up to 1. Technique still determines
  the base result, unburnt food stays at least grade 1 and burnt food remains 0.
- `needs.sleep` restores rest/mood and consumes hunger per actual hour. Fan
  multipliers are external data. Midnight changes the calendar date and assesses
  rent once, independently of sleep. No rent is charged just for taking a nap.
- Sleep ends current visits/orders/conversations but retains same-day spawn
  flags. Both clock domains and unattended cooking advance by elapsed sleep
  time. The modal previews the resulting wake date/time and any extra hours.
- Schema 2 saves include the last rent day and batch penalty. Version 1 is
  validated from its original compact JSON before migration in a candidate;
  loading itself never charges or overwrites the save.

Manual browser observations in the actual game (no service-command probe):

1. Saved a version-1 game using its existing Save button, then replaced the
   served build while retaining the browser origin/profile. After the checksum
   correction, Continue restored the old rooftop game with 4500 piastres and
   zero penalties on old empty stations.
2. Selected 2 hours by keyboard in the sleep control; the preview showed 15:37
   to 17:37, same day. After sleep, the displayed time advanced accordingly and
   the balance stayed 4500. Saved schema 2 and hard-reloaded; Continue preserved
   the resulting time, needs, day and balance.
3. An 8-hour evening sleep crossed midnight, reached the shown next-day time
   rather than 15:00, and charged exactly 1500 piastres.
4. For isolated manual observation only, changed the deployed temporary copy's
   initial needs to mood 20/rest 10. A new game showed a two-hour oversleep
   warning for a requested two-hour sleep, with a four-hour wake estimate.
   Recovery reflected actual hours. Canonical source defaults were not changed.
5. In that low-mood game, used E to boil/brew/pour tea. The active job retained
   penalty 2 while BOILED/READY; the held item had final grade 1 (okay), and the
   UI explained mood's contribution. No script errors occurred in these flows;
   Chromium/SwiftShader emitted WebGL warnings.

Screenshots inspected under `/tmp`: `kiosk-sleep-picker.png`,
`kiosk-sleep-two-hours.png`, `kiosk-sleep-woke.png`,
`kiosk-sleep-v2-continued.png`, `kiosk-sleep-poor-mood.png`, and
`kiosk-sleep-mood-tea.png`. Existing affected assertions were adapted to the new
contract; no automated suites were added or run. Complete game acceptance
remains tracked separately in PORT_PARITY.md. E-opening latency was not changed,
and English localization is not part of this update.

The low-mood run was also left awake across midnight: the observed clock reached
calendar day 2 at 03:35, `last_rent_day` was 2 and the balance was 3000, consistent
with exactly one daily rent assessment. Source initial needs remain mood 75/rest
90; the low-needs authoring copy existed only in `/tmp/kiosk-sleep-live`.

A small HUD follow-up lets the interaction card grow upward and wraps station/
mood text, so the new hint does not push help below the viewport. Actual browser
captures at 1280x720 and 960x540 were inspected with primary/secondary tea prompts
and the two-grade mood hint: `/tmp/kiosk-sleep-footer-wide.png` and
`/tmp/kiosk-sleep-footer-compact.png`.
