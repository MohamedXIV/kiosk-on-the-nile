# Continuous dialogue and journal — delivery

Product commit: `7e3818da0419c1fe0f9d6a8f3325a0e88259fc96`; base `2b68547`. Increment1 of the approved everyday-life plan. Godot4.7.2, Ink, external JSON, save schema4/revision8.

[Preview release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/dialogue-journal-7e3818d) · [Complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/dialogue-journal-7e3818d/builds/kiosk-on-the-nile-dialogue-journal.zip)

ZIP SHA256: `f16468040b786d6b120d46ead1e25eb3a9d8638ca14bb1373b3e99760e2e8f30`. The ZIP downloaded from GitHub matched the local digest. Release branch `build/dialogue-journal-7e3818d`; source/documentation branch `preview/dialogue-journal-7e3818d`. No main merge.

## Delivered

- One personal hub owns a nearby conversation. Actual Ink chapters keep their own cursor, branching, effects and occurrence IDs. Continue/Enter reads the next line; completing a chapter returns to currently eligible topics, including real order recall. E is unnecessary between chapters. The panel includes recent preceding text.
- Leaving/walking away/travel/sleep pauses eligible personal chapters by actor with their actual Ink snapshot/hash. Resuming rebinds the participant to that actor's current visit without replaying effects. Order and service-availability chapters deliberately do not resume against a later visit's different order.
- Automatic one-frame Ink thoughts use saved once/cooldown rules and a separate presentation channel. They defer while the personal hub/choices/modal UI owns attention.
- Heard speech, successfully accepted player replies and thoughts enter append-only history. Notebook filters by person/day/chapter and includes player replies in the person's chapters. Known notes link to their recorded source when present. The chapter selector means an individual Ink chapter; grouping several chapters into a named multi-chapter sitting remains a UI refinement.
- The open/closed sign affects wording. A visitor asks a present player and becomes `requesting`; no order exists until explicit acceptance succeeds. Declines return to leisure. Purchase eligibility is independent of the sign. Independent world visits and kitchen timers remain on their existing coordinator.
- Revision7 migration adds empty history rather than fabricating old dialogue. Existing orders, Ink runtime hashes/cursors, facts and semantic receipts remain authoritative. Restore validates references/counters before installing the candidate.

## Review and build evidence

No automated tests were added or run. Ink compilation, Godot import and debug/release Web exports succeeded. `git diff --check` was clean. Earlier integrated UI compilation caught the old notebook signature; it was corrected before subsequent successful builds.

One fresh independent read-only review of the full increment reported three Important findings and no Critical findings. One material-fix pass addressed all three:

1. A failed response effect could leave an accepted player choice in history and report success. Choice text is now staged; successful response effects commit it before response speech. Failure discards the staged event and returns failure.
2. Restored next-ID counters could reuse existing semantic IDs. Canonical active/paused conversation IDs, journal events, thought IDs, effect receipts and conversation provenance are now cross-validated against their sequence bounds. Empty migrated history remains valid.
3. A timed invitation or simultaneous service start could leave a hidden second manual chapter. Manual starts reserve ownership across Ink loading, invitation acceptance rechecks ownership, and failed adoption cannot publish the manual response. Save link validation rejects orphan/multiple manual owners.

The minor preceding-text observation was also addressed. No second reviewer was used. Counter tampering and invitation/start race rejection were inspected and compiled, not driven through a manual corruption/race scenario.

## Actual mouse/keyboard observations

Chromium/WebGL over local HTTP, 960×540; stock release also resized to1280×720. Read-only debug snapshots supplemented the UI; no game-command bridge was used.

- Downloaded the actual published `669f9de` ZIP and created a genuine revision7 save through its UI: Amgad's introduction held three choices while `visit_1/order_1/tea` existed. Continued that save in the new debug build with matching external scenario content. It restored the same `conversation_2/beat1` choice, pending order and wallet4500; new journal count0. [Migrated choice](evidence/2026-10-24-dialogue-journal/migrated-choice.png).
- Accepted the introduction reply. Journal order was player choice then Amgad response, mood75→79. The same beat2/no-choice reply stayed visible while the world clock progressed. Enter completed it and returned to the hub without another E. Selected actual order recall (`conversation_3`) and ordinary smalltalk (`conversation_4`) inside that hub.
- Escape paused smalltalk. Its saved actual Ink/hash and chapter ID resumed on E in the same visit; heard history did not grow from resuming. A quiet player thought began after leaving, appeared once in the journal and was hidden during renewed personal focus. Later-visit rebinding was not manually exercised.
- Opened the notebook history and observed game timestamps, accepted player reply, Amgad response, recall and thought events. Reading history retained wallet/order/effects state; ordinary ambient speech could still add newly heard entries while time advanced. [History UI](evidence/2026-10-24-dialogue-journal/history.png).
- Separate fresh closed-sign scenario: Amgad reached the service position and asked for tea; state was `requesting`, empty order ID, journal count1. [Closed-sign request](evidence/2026-10-24-dialogue-journal/closed-request.png). Accepting produced exactly `order_1/tea`, pending state and three journal events (request, accepted choice, response).
- Saved that service reply through the UI, reloaded and continued revision8. Same `conversation_1/beat2`, `order_1/tea`, wallet4500 and journal count3 restored with no system failures; the service effect/history were not replayed.
- The exact product release export started a new game using untouched repository content and no debug probe. [Stock release](evidence/2026-10-24-dialogue-journal/stock-release.png). It also opened the genuine old introduction save at the same choice under default content. Default waiting limits can naturally expire a legacy order whose manually extended waiting period already exceeds current defaults; the matching-content debug migration above isolates preservation from that ordinary timeout.

Manual scenario overrides lived only in `/tmp` exports: initial kiosk position[-1.5,3.2], Amgad-only eligibility, seed1437, initial/purchase delay1, subsequent arrival90, stay/maximum wait600, fixed stay multiplier1, nearby leisure marker, and thought delay1 for the thought observation. The old-release migration fixture used an open sign; the new service fixture used closed. Published content has none of these overrides.

## Limits and next work

Active cooking-job migration, both workshop disclosure orders, complete work-trial progression, walking-away/out-of-range hearing races, cross-visit paused dialogue, simultaneous invitation/service races, every notebook filter combination and a statistical pacing/balance pass were not manually exercised in this increment. The software WebGL browser emitted resize-related buffer warnings without an observed crash; native-editor/real-GPU inspection remains useful.

The approved clock/needs/live tweaks, people-backed rent/district payment (weekly50EGP, configurable prepayment discounts) and supplier plans remain subsequent increments. They are not included in this build. No unsolicited needs/finance behavior was folded into dialogue delivery.

Execution rulings retained: native inline implementation plus one fresh final reviewer; no automated tests under the session instruction; integrated UI checks followed Task2 because Task1's service-only changes had no independent manual presentation yet. Build evidence exists for both stages; the narrower manual coverage is listed above.
