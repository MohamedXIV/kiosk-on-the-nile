# First combined-playtest corrections

User feedback, 2026-10-29 (Africa/Cairo): obvious dropped frames after presentation polish; recipes, messages and home invitations exposed too early or without heard knowledge. Source baseline:fc65ba353236a30670adaaa24991ac42ba6b2cb3.

## Grounded social progression

The existing relationship owner already stores directional familiarity/trust. Personal SocialLife gains and notebook stages use **NPC→player**, which now also determines social eligibility. The defect was missing conditions, not missing Ink or an absent relationship system. Before-fix observation exposed shawarma basics even before introduction, home invitation immediately after introduction, and Farid's request about unknown Youssef.

Three authored tuning profiles in social_life.json query the existing introduction receipt, relationship and meaningful-social-day ledger:

| Profile | Calendar days since heard introduction | Familiarity / trust | Meaningful social days |
| --- | ---: | ---: | ---: |
| Personal | 1 | 4 / 1 | 1 |
| Relaying | 2 for both people | 8 / 2 each | 2 each |
| Home | 3 | 30 / 6 | 3 |

Home is guarded both in the menu and at the actual invitation effect/encounter. High scores alone cannot bypass time/companionship. Relationship thresholds are developer tuning for this correction, not numbers specified by the user.

New optional Ink company topics award3 familiarity/1 trust once per calendar day within the existing daily cap. Repeating/selecting the same day's company gives no extra gain. No purchase, paid service, gift or workshop referral is required: bounded actual-Ink observations reached home eligibility on day9 with the food reminiscence and daily company, without sales/workshop. This fixture advances the clock directly and retains one visit; it does not claim nine natural playable days or financial/needs acceptance.

Farid's neutral food reminiscence commits FARID_SHAWARMA_STORY with actual speaker/source/time. Only that heard connection reveals the recipe question; attempt/result follow-ups also require taught basics. Personal workshop/study openings wait until a later day. Relay requests require both introductions to have aged, both relationships, and the actual exam/radio story fact. Reply/delivery dependencies and once-only source lineage remain.

## Bounded verification

- dialogue-before.log records the actual early menu/eligibility failures.
- dialogue-after.log and dialogue-observation.gd.txt record compiled Ink introductions, withheld early topics, high-score/day bypass rejection, actual reminiscence and recipe teaching, daily/no-repeat growth, mature invitation, sourced request→reply→delivery, and current-save restore. Arabic and English labels were observed. FAILURES0, no script errors in the final run.
- Direct clock fixtures need accounts.tick before save; an initial fixture omitted it and was rejected with missing_obligation. A second fixture initially reused start_new instead of constructing a fresh configured GameSession and could not respawn the same actor. Those fixture mistakes were corrected; no production save/spawn workaround was made.
- Native disposable-session exit still reports123 ObjectDB instances /23 resources in use. No clean-shutdown, memory-leak or natural-play performance claim.
- Independent read-only review found no Critical gameplay blockers, and one Important malformed-save issue: repeat-moment validation read a daily entry before validating its type. Daily ledger validation now precedes moment grounding so malformed entries reject cleanly.

No automated suite was added or run. Performance evidence and final build/download provenance are recorded separately/live on the delivery PR. Save schema4/revision20 explicitly requires a new game for previous pre-alpha previews, preserving files. No migration, archived Ink graph, published tag rewrite or branch deletion.
