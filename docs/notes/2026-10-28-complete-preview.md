# Combined playtest preview — 2026-10-28 (Africa/Cairo)

The user requested **all remaining scope, including previously deferred home guests**, in one preview before judging the experience. That instruction supersedes earlier exclusions/asset-approval pauses. PR#16 integrated the first quiet-days milestone as `422adb93e3c472a22e883912040f2afadb86bccf`; post-merge build [40649107406](https://github.com/MohamedXIV/kiosk-on-the-nile/actions/runs/40649107406) passed.

Current development target is **0.2.0-prealpha.1**, not a new formal tagged release. The combined preview includes prior hospitality/payment, continuing stories/messages and bounded passage work plus the #6/#7 additions below. No branch deletion or published tag/asset rewrite.

## Player and home seating

SeatCatalog remains the sole source of slots derived from actual placed furniture. SeatUse owns only player/home reservations; VisitorSeating consults those claims before taking a kiosk chair. Player E-sit requires nearby clear feet/access and a clear short segment; feet are not forced along a route. Existing CharacterView posture is reused. Movement/Esc/travel/sleep stands the player; held items and nearby conversation can continue while seated. Occupied chair/table guards participate in placement/storage/hygiene. Two ordinary movable starter chairs are provided inside the home, using the same chair definition and existing transfer rules.

ResidentialVisits remains the one-current-guest owner. Existing landlord visits can sit and keep their payment channel. After actual acquaintance, Farid/Youssef can be invited through authored Ink for the next afternoon/evening; postpone/cancel/goodbye are explicit. Arrival requires the player home, the actual actor absent from the kiosk and no workshop reservation. Landlord agenda takes priority. A guest chooses an available reachable chair or stands. Blocked/failed seating is relinquished with a safe standing/navigation fallback, without repetitive reclaims. Furniture occupancy is not a fictional purchase/order. Home episodes cancel on departure rather than rebind an obsolete home action to a later kiosk visit.

Workshop absence now includes physical household presence. An existing home conversation may finish while a scheduled trial waits; it cannot make the same actor work offscreen at the same time. A reserved actor cannot start a new home visit.

## Pacing and presentation

Opening savings remain240EGP. Paid base tea/kebda prices become12/28EGP, with tips/inputs/needs/rents/attendance/cooking windows unchanged. [Mixed-week observations](2026-10-28-mixed-days.md) cover real owner transactions over three weekly bills, gifts, ingredient purchases, upkeep, food/sleep and optional fan spending. A six-hour-service policy on the final sign gate finished with296EGP after all360EGP rents,30 paid services/6 gifts, peak4 people and no reported owner failure. This is controlled one-seed evidence, not guaranteed indefinite income or natural human balance acceptance. Prices are stylized game values, not historical price claims.

Closed signs now prevent new shopping approaches/requests while independent arrival/leisure continues; existing accepted orders can still be served. A separate150-minute closed-sign observation recorded4 arrivals, no shopping approach/request samples, no orders and unchanged240EGP.

[Presentation record](2026-10-28-world-presentation.md) covers warmer worn paving/timber, roof corrugation, readable ordinary props/signs/lights and restrained river/boat/far bank. Source-based appliance sounds respect actual location/heat; original PCM, radio ownership and gain mix remain. Native component sheets and source-audio selection are evidence, not human listening approval. The user judges final feel after playing.

## Independent review and concrete fix observations

Fresh whole-branch read-only review found three Important areas and one minor date wording issue; all addressed in one pass:

1. Before: workshop became active while Farid was still home, then an ordinary save rejected. After: phase remained `waiting` and the current save restored.
2. Before: a legal second-chair placement blocked seat access yet sit succeeded; a guest kept its blocked reservation. After: sit rejected and the guest released the claim. Failed-route abandonment preserves a safe fallback rather than overwriting it next tick.
3. Before: Continue showed only generic failure for revision18. After: the actual title label displayed the localized new-game/preserved-file explanation, and primary/backup SHA256 remained identical through rejection.
4. Cancellation's “keep tomorrow” became date-neutral in both languages.

Retained [before](evidence/2026-10-28-complete-preview/review-before.log) / [after](evidence/2026-10-28-complete-preview/review-after.log) observations use explicit legal-layout, social-ledger and household fixtures. They are bounded reproductions, not a suite. The reviewer did not independently execute observations/builds or assess audible quality.

## Runtime evidence and limits

[Native owner observation](evidence/2026-10-28-complete-preview/seating-home-save.log) used actual compiled Ink for acquaintance/invite/postpone/home greeting/goodbye. It covers player seat, exclusive furniture/clean rejection, pending invitation/current restore, no duplicate kiosk/home actor, distinct player/guest seats, seated landlord/payment-channel eligibility, sleep stand, released restore and invalid seat rejection. Visit route completion and calendar positioning are controlled fixtures; actual UI rent payment is covered only by the separately qualified mixed-week owner observations.

[Native input](evidence/2026-10-28-complete-preview/native-input.log) instantiated the real Main scene on pinned Godot4.7.2/llvmpipe: parsed native E input seated the player and movement stood them. Staged household rendering uses the actual landlord/seat owners; photos do not claim a naturally scheduled guest arrival. Main/HUD screenshots include Arabic/English home seating and0/1/3 kiosk NPCs at afternoon/dusk/night. The normal camera/labels and staged people are real rendered nodes, not image edits. One scene appearance is not statistical population acceptance.

No automated test suite or historical-save compatibility campaign was added/run. Native scratch exits report ObjectDB/resource cleanup diagnostics; successful observations do not prove clean shutdown, leak freedom or performance. Human audible quality, natural long play, unassisted path coverage and all devices remain for feedback.

## Save and one-package delivery

**Schema4/revision19 requires a new game for all earlier pre-alpha saves, including18.** The title screen explains this and retains primary/backup files. Current19 validates/restores seat claims, household invitations, current guest and dependency/provenance links. No migrations or archived Ink graphs were added.

Tracked build gates validate version/toolchain,374 Ink localization references, editor import and Release Web export. CI also packages one complete development ZIP with BUILD.json, VERSION, changelog, licenses, RUN.txt and [Arabic playtest guide](../PLAYTEST_GUIDE_AR.md). Exact source/CI/archive digest and browser observations are recorded on the source PR/final delivery, avoiding a self-referential source identifier here. GitHub Actions retains the development preview; this is not a new immutable formal release or permanent archive publication. Existing artifacts-branch history is unchanged.

Implementation for the remaining roadmap scope is present in this combined preview. Issues#6/#7/#8 retain user playtest/feedback acceptance rather than treating the user's request to build as prior approval of visual/audio/balance feel.
