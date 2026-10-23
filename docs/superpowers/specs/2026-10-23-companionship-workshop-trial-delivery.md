# Companionship / workshop trial preview

Product: `669f9de871f788d7615a838bc24e147ee1a01857`, Godot4.7.2, release Web, schema4/revision7.

[Release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/godot-preview-companionship-669f9de) · [Complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/companionship-669f9de/builds/kiosk-on-the-nile-companionship.zip)

ZIP SHA256 `5926353229fde81557d5665f9d65eb22bc52f73d5bc7c997c24a27706bd88d6d`, size11446839 bytes. Downloaded from GitHub and matched the locally exported ZIP. Default external content included; manual fixture overrides are not packaged. Full40-character source SHA is in BUILD.json; engine/PCK filenames share its version. Release has no debug probe.

## Scope delivered

- Saved proximity invitations for Farid/Youssef; listening can be silent, sharing and agreement are explicit.
- Acquaintance, either-order personal disclosures, individual referral/contact consents, separately agreed study days.
- Real offscreen activity with schedule, reservation window, delayed actual start while participants remain, 120-minute default interval and one completion receipt.
- Specific first-day/study follow-up topics, late days agreement, directional familiarity/trust, shared moments and daily caps, notebook people tab.
- Old knowledge, relationships, visits/orders, cooking, economy and active Ink ownership retained. Schema1–6 revision migrations add empty new social state.

## Verification evidence

No automated tests added or run (session developer instruction and approved spec). Ink compile/check, Godot headless editor import and release export completed without script/parse errors; exact release booted through title and New Game with stock content. Browser inspection confirmed the release has no `gameStatus` probe.

Manual UI controls and read-only debug snapshots were used, without game commands or fabricated saves. A temporary external content fixture placed Farid/Youssef near the player, restricted other actors, shortened arrivals and initially used 3-second proximity/70-second visits. Later the fixture used60 world minutes per simulation second and4500-minute return gaps to review the offscreen lifecycle. Release retains normal time, randomized pacing and default content.

Observed:

- A declined Farid invitation left no semantic receipt, moment or relationship reward. A saved open Youssef invitation continued and silence listened; explicit work-consent choices held across many world hours without auto-acceptance.
- Heard Youssef's need/study constraint before Farid's opportunity; facts recorded actual speaker, source occurrence and world time. One consent left the case idle. Two explicit consents entered coordination without giving the player an appointment/result fact. Relaying both directions retained one shared referral moment.
- Sleep after both consents cleared physical visits and coordinated a next-day16:00 appointment (`not_before24000`). At the due time, an existing participant kept the activity waiting. Subsequent sleep advanced the actual interval `24752.500000001` → `24872.500000001`; completion recorded once at25232.500000001, outcome `days_pending`. Player knowledge still contained only the two disclosures.
- Returned and heard both Youssef and Farid's first-day reports, including that continued days still needed agreement. Explicitly relayed/confirmed the two-day arrangement with Farid and then Youssef after the completed trial: outcome changed to `week_trial` with the same start/end and one completion receipt. Saved and continued this completed/late-agreement state under strengthened validation.
- Manual review found an obsolete appointment topic offering future plans after completion; added authored topic phase filters. Historical appointment facts/cursors remain compatible, but completed cases offer actual follow-ups.
- Actual schema4/revision4 save restored under the new product: money38200, Farid's pending kebda/order4, Amgad's tea/order5, running tea and shawarma_batch/item23, paused floor cleaning and previous visit memories retained; social receipts remained empty and activity idle.
- A new revision7 saved consent/disclosure state restored under strengthened provenance validation.

Remaining manual coverage: the opposite disclosure order, agreement before the first trial, exhaustive saves during every activity phase, a held choice exactly at the trial appointment, and long-term default pacing. Code review/build evidence does not claim these UI paths were exercised.

## Review and execution decisions

One fresh whole-branch reviewer (`gpt-6-astra`) found no Critical issues. Important findings fixed: automatic referrals sharing without explicit choice, and unsupported social facts/early completion timestamps passing save validation. Follow-up integration also preserves the E target when old smalltalk is exhausted.

Rulings, in execution order:

1. Manual UI/build evidence instead of automated tests follows the explicit developer instruction; narrower regression coverage is the tradeoff.
2. Continued from the approved concrete design without a redundant plan approval round, following the higher-priority autonomy instruction; implementation details remain reviewable in the plan.
3. Treated declined pending-topic consumption as material because the approved listening contract preserves unheard content; fixed actual-hearing tracking. Otherwise an optional follow-up could disappear for a day.
4. Treated premature workshop connection wording as material because it claimed participation before a heard result; notebook now distinguishes coordination from an actual reported trial. Otherwise the UI would tell a false event.

No reviewer minors remain deferred. Preview branches are separate from main; no main merge was performed. Workshop scene, wages/permanent employment and further stories remain out of this approved slice.
