# Independent visits and readable orders — 2026-10-23

Product source `b97b532`, Godot4.7.2. Approved [design](../superpowers/specs/2026-10-23-independent-visits-and-orders-design.md), [plan](../superpowers/plans/2026-10-23-independent-visits-and-orders.md). No main merge.

## Behavior

Visitors arrive independently of kiosk opening, choose a leisure destination and may later consider a purchase. No compulsory Amgad spawn, scheduled football-pair arrival, fixed new-game RNG seed or scripted day2 quiet window. Eligible characters are weighted using authored weights, time windows and previous visits. The total cap is4 including arriving/leaving people; it is not a target to fill. Arrival time is independent of demand/opening, and opening does not reset purchase timers. A purchase can be declined, unavailable, postponed while its destination is occupied, or delayed by an active conversation.

JSON controls initial delay12–24 simulation seconds, later gaps16–34 (30–60 and40–85 world minutes at current clock rate), purchase consideration5–12, retries8–18, personal space0.65, stay variation and per-character probabilities. These are preview defaults, not an accepted economy/pacing balance. New games randomize the visitor RNG; Continue restores its saved state.

Orders remain authoritative in ServiceSystem. A new separate Ink story announces the actual food, provides character-specific recall variants and explicit-food reminders. Venue dirt comments cannot replace an order announcement. If an announcement occurred out of hearing, the pending order remains available through its nearby badge and “كنت طالب إيه؟” action. A small drawn cup/sandwich/plate icon plus food name appears near a pending customer's speech, stays within hearing range, and disappears when the order ceases to be pending. Close badges stack vertically. No icon assets or extra saved UI state.

Talking to a pending customer opens separate recall/personal-talk choices. Recall never creates an order or consumes personal topic memory; its last variant is saved per visit to avoid consecutive repetition. Active speech/choices finish before another manual response starts. Purchase movement and dwell timeout pause during dialogue; the world clock and other people continue. Occupied destinations include served/leisure/departing people, not just pending buyers. Formatting-only Ink lines no longer create invisible default-duration pauses; tagged timing/effects and choices are retained.

Save schema remains4, revision6. Migration preserves existing pending orders, arriving intentions, visit IDs/counts, money, work and archived story cursors. Existing Amgad/visitors story files were not rewritten. Legacy arrivals increment their count once on actual arrival. Invalid candidates do not overwrite the previous save.

## Evidence

No automated tests were added or run. Ink compilation, Godot import and debug/release Web export passed. One fresh whole-branch static review completed; its three Important findings (dialogue interruption, occupied service positions, simultaneous personal/recall speech) were addressed in the fix pass. Opening-timer, legacy-count and stale-caption observations were also addressed. No second agent review.

Ordinary mouse/keyboard review observed:

- With default content and the kiosk closed, Salma arrived and stayed at her leisure position with no food/order while the player was still home. Later Amgad, Hassan and Mahmoud spent time outside without orders. Opening retained the existing people, with no forced Amgad spawn; a later purchase happened through the visit lifecycle. This is one observed run, not statistical balance acceptance.
- A genuine old4/4 save continued a returning journey with money38200, Farid's `order_4/kebda`, Amgad's `order_5/tea` and active shawarma vessel `item_23` intact. Both pending badges appeared; adjacent badges and the action menu were reviewed at1280×720 and960×540. Later departure removed the pending badges.
- Farid's recall replies changed variant2→0 and both named the actual kebda order; no personal topic selection was added by recall.
- In a separate external JSON manual scenario, only Nadia was eligible, purchase probability1, seed1437, initial/purchase delays1, waiting timeout600, and her preference was tea. The player started near the service window with the kiosk open. Nadia independently walked to leisure, considered buying, then requested tea. Her icon/name and recall said tea despite her historical kebda dialogue. These overrides are NOT in the release.
- That scenario saved and continued revision6 with the same `visit_1/order_1/tea`, money4500 and last recall variant2. Replacing the manual content with repository defaults did not change the pending order to Nadia's default preference.

## Remaining acceptance

A full statistical pacing/balance pass, native-editor inspection, every destination/door race, legacy arriving-person migration case, exact RNG continuation comparison, and complete cooking/payment/badge-removal-through-delivery cycle were not manually exercised here. The larger social-life goals (deep follow-ups, relationship UI, hospitality, job referrals) remain separate work.

Additional manual conversation case used external Amgad-only eligibility, seed1437, purchase delay120, longer stay and a nearby leisure marker. His real introduction opened three Ink choices. Across world972.958→986.208, remaining purchase time110.2, position, undecided state and conversation_1/beat1/choices stayed unchanged while the world clock advanced. This checks the reported purchase-interrupt case without automated assertions.

Final release source `b97b532` was exported and opened over HTTP with default repository content (new game at1280×720/960×540). Export log contains no tests, native editor addon or command bridge. ZIP SHA256: `4e44def4c904c561bca2eee578ddc5609437cb9326fcfdf13bde021b4f3f3444`.

Saved that active introduction and continued revision6: the same conversation_1/beat1, three choices, no order and purchase time110.2 restored. Across world1016.125→1034.292 the saved choices and paused purchase time remained intact, with no system failures.

Selected the first restored introduction choice through the UI: conversation advanced to beat2, displayed its expected reply and applied mood+4 (75→79), with no duplicate order or system failure. Final release also continued the saved Nadia tea order and displayed its badge at960×540.
