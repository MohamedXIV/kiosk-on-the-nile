# Player feedback — 2026-10-22

- Possible delay between E and a conversation opening: **observation only**.
  Do not change timing or preload behavior until the player supplies measured
  reproduction details. Reported latency is not confirmed as a separate defect.
- Confirmed sticky dialogue panel after a reply/travel: browser reproduction
  found Hud.present passed an untyped empty array to a typed dialogue view when
  focus was absent. The update aborted before hiding the old panel. Use the
  director's consistently typed choices result for both active and absent focus.
- Sleep/mood proposal is awaiting the player's response in chat: selectable
  duration, calendar midnight/day changes, daily rather than per-nap rent,
  duration-based recovery, bounded oversleep based on mood/rest and a mood
  modifier for preparation quality. Do not silently implement unconfirmed
  numerical thresholds or randomness. New requested behavior supersedes the
  original prototype parity requirement once agreed.
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
