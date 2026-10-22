# Social visitors, Ink topic memory and compact HUD

Player approved this bounded follow-up in chat on 2026-10-22. The original
HTML remains unchanged. This extends the current Godot services and does not
copy implementation or structure from the reference project.

## Design sources

Read reference game-design documents and issue discussions:
- https://github.com/MohamedXIV/nile-kiosk/blob/main/docs/GAME_VISION.md
- https://github.com/MohamedXIV/nile-kiosk/blob/main/docs/design/SOCIAL_SPACE_AND_NARRATIVE.md
- https://github.com/MohamedXIV/nile-kiosk/issues/59
- https://github.com/MohamedXIV/nile-kiosk/issues/120

The adopted experience is people first, customers second: optional conversation,
quiet gaps, regulars remembering actual service, and authored offline Ink that
reacts to canonical knowledge and hidden directional relationships. The full
reference vision is broader than this slice; private acoustics, a large social
network and additional economic referrals are not claimed here.

## Implemented rules and ownership

- `VisitorHistory` records reservations on spawn, so sleeping/closing/reloading
  cannot reset a tracked daily quota. `VisitorService` excludes any already
  present identity (including leaving visitors) and occupied destination marker.
  Eligible ambient visitors with the oldest prior visit are selected first,
  with the existing persisted RNG breaking ties. No eligible visitor means quiet.
- All named characters default to one visit per calendar day and at least 480
  world minutes between visits. Individual time windows are authored in
  `content/visitors.json`. Ambient spacing is 22–42 simulation seconds. These
  values are tuning choices, not final pacing acceptance.
- Added Salma (teacher, tea/counter), Mona (neighbor, social visit/no purchase),
  Farid (mechanic, takeaway food) and Youssef (student, tea/counter), alongside
  the original cast. Shared destinations are reserved while occupied.
- Unserved buyers leave after the authored 95 simulation seconds; their pending
  orders cancel through the existing service owner. Each visit gets at most one
  waiting reminder. Ambient remarks are at most once per character/day.
- `ConversationHistory` consumes an authored topic only on a committed spoken
  line. Topic definitions specify modes, participants, conditions, visit counts,
  prior paid service, once/day/visit scope and a finite variation count. The
  latest occurrence per topic/character persists without an unlimited chatter log.
- The fan referral requires day two and unknown fan knowledge. Learning it blocks
  later referral starts. Buying the fan enables a separate once-only follow-up.
  First introduction and first paid-service recollection are also once-only;
  everyday small talk rotates across three authored variants, at most once/day.
  With no available topic there is no Talk prompt. Serving remains available.
- Actual settled orders create customer-specific quality/food memories (up to two
  receipts per character). The memory dialogue requires a later visit and reads
  that prior real paid service, never an invented favorable result. Receipt/order
  links are checked on candidate load. No arbitrary friendship points are granted.
- Ink receives time, familiarity, actual visit count, prior service quality/food,
  current facts and the selected topic/variant. Content stays authored/offline.
  The football pair has three rotating exchanges, optional replies, reconvergence
  and its existing ignore continuation. World time and cooking continue.
- Spatial captions use actual visitor/player positions and an external hearing
  radius. The focused choice panel suppresses a duplicate copy of its own caption.
  This is proximity hearing, not a private/occluded acoustic model.

## UI

`StatusStrip` presents clock, money, kiosk state, stock, three small need meters
and the held item in two horizontal rows at the top. Save, notebook, diagnostics
and the keyboard legend are inside the menu. The bottom card shows contextual
prompts/active cooking, without a permanent controls legend. Choice cards sit
below the strip, size to content and scroll when needed; speech avoids the strip.
Layout sizes/colors live in `content/ui.json`; dialogue remains in Ink.

## Save compatibility

Schema 3 adds visit/service and topic histories. Versions 1 and 2 migrate in a
candidate without charges or writes. Active older visits reserve their identity
on migration; unknown historical visit dates and service quality are not invented.
Restored candidates are created beneath their final scene owner: reparenting a
live session would invoke InkRuntime tree-exit cleanup and discard its player.
Older compiled Ink is retained in `content/legacy/` solely for resuming a matching
already-open previous-preview session. New starts always use current Ink.

A real Web save revealed another JSON precision case: original
`932.1249999999981` parsed as `932.124999999998`. Its original byte checksum was
valid. The decoder now verifies the exact original compact payload for supported
schemas before normalizing the parsed envelope in memory, as already done for
version 1. A mismatching original checksum remains rejected.

## Build and manual observations

Debug and release exports completed via `tools/build.sh`; no automated gameplay
suites were added or run. Actual browser keyboard/mouse observations:

- Opened Amgad's introduction, selected a reply, then saved through the new menu.
  Reload/Continue retained its consumed topic, visit reservation, wallet and pose.
- A temporary sidecar copy started at day two to reach the fan encounter directly;
  canonical source still starts at day one. Heard the referral, replied, and later
  E selected small talk rather than repeating it. After another save/hard reload,
  referral and small-talk consumption remained present, without regranting mood.
- Saved the previous published schema-2 build with Amgad's original reply pending,
  replaced its served files with the new build on the same browser origin, and
  used Continue. The original text/choices resumed through archived Ink. Clicking
  the first response advanced to its original reply, cleared focus and applied
  its mood effect once. The lifecycle repair was necessary for the resumed
  choice to remain actionable, rather than merely looking restored.
- Prepared tea with the ordinary E controls and delivered it to Amgad. The
  observed wallet changed from 4500 to 5300 and his service memory contained
  `order_1`, `visit_1`, tea and actual final quality 3. No manufactured memory
  fixture or gameplay command bridge was used. A full multi-day returning
  customer acceptance pass remains separate.
- Inspected top strip and contextual footer at 1280x720 and 960x540. Choices fit
  below the strip. Initial anchor-size warnings were corrected by setting offsets.
- Chromium/SwiftShader emitted WebGL warnings. These observations are bounded
  evidence, not full multi-day acceptance or human approval of the final pacing.

The previously reported E-opening delay remains recorded separately and was not
retuned. Current UI/dialogue remains Arabic; English localization is separate.
