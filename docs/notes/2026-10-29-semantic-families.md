# Semantic family conversion — #24, 2026-10-29

Base9fdbd96. [Implementation/API/inventory](../architecture/semantic-families.md), [plan](../superpowers/plans/2026-10-29-semantic-families.md), [bounded evidence](evidence/2026-10-29-semantic-families/).

22/51 encounter entries now use shared semantic rules, including introductions/company, personal disclosures, two exact check-in threads, home invitation/cancel/company/goodbye and the recipe connection/basics/attempt/result family. The remaining29 entries and their owner-specific reasons are explicitly inventoried. No complete-game migration claim.

## Verification

- Production lifecycle: unknown/early topics hidden; actual introduction and distinct-day company; next-day disclosure followup; heard recipe connection, source-backed teaching and self-consumed continuation; request/postpone/reply/delivery; actual home booking/cancel. Current JSON candidate restore at each milestone. FAILURES0.
- Negative observation: automatic promise produces no consent/knowledge; actual recipient learns request, sender remains unaware of reply until delivery; removal of a used choice proof, changed party and invalid message parent reject without changing input; stale prepared home ticket preserves owner state. FAILURES0. Earlier negative fixture removed an unused listen proof, which correctly had no effect on a committed consequence; corrected to remove a receipt-linked proof.
- Additional actor/topic demonstration: disposable authored Nadia/tea/check-in bindings; generic policies, no engine branch naming Nadia. Real workflow.start/add_tea/pour produces canonical attempt/result evidence, observed by the generic followups. Home booking, real next-day arrival/company/goodbye and JSON restores pass. Production adds no new actor or tea-teaching dialogue.
- Personal return: same actor with a different visit handle resumes taught Ink choices without replay. Actual stable reply executes. Arabic/English notebook notes resolve to shipped text. Automatic intro timeout postpones without introduction; actual guarded listen joins personal conversation. FAILURES0.
- Final fresh read-only reviewer families_final_review (gpt-6.1-terra/high): one P2 missing notebook recipe instructions; no other finding reported. Single focused fix pass: notebook-before printed missing note; NotebookView now derives existing localized note and source chapter from canonical assertion aliases; notebook-after PASS0. No second reviewer requested.
- Tracked Ink/localization/import/Web Release gate is recorded in build.log with engine logs/toolchain evidence. These are build gates and bounded observations, not an automated suite.

Native disposable exits report existing ObjectDB/resource warnings (e.g.153/24 on home-arrival,228/24 on return-auto); no leak-free claim. Expected intentional automatic-promise rejection warnings are retained. Integrated player-device rendering, long-session performance, complete pacing and human playtest are#26, not inferred from these runs.

## Decisions and limits

- Standing user prohibition on suites overrides the skill test workflow; retained scripts are text evidence, executed only as bounded disposable observations. Cost: bounded behavioral coverage.
- Existing approved contract/repeated execution and safe-merge authorization carry forward; no repeated approval prompt. Existing managed checkout/feature branch retains verified toolchain caches.
- Generic AccountValidation guest-name whitelist was removed after the data-only demonstration exposed it; any declared visitor is valid while roster<=2 and actual one household slot remain. This changes authoring eligibility, not population density.
- Retain workshop/finance/service/peer owner-specific paths, with explicit read adapters for canonical intro/recipe prerequisites. Cost: additional family conversions remain separate work, not falsely marked complete.
- Preserve source history and current-save integrity; no historical Ink graph archive or migration. Current content identity changes and unsupported old content is rejected while bytes remain intact. Final save/new-game/version/changelog/preview decision remains#26/#27.
- Reviewer declined independent runtime judgement of auto pacing, localization, actual cooking and performance. Root observed the first three in the bounded evidence above; integrated performance/pacing remains#26.

VERSION0.2.1-prealpha.1, save schema4/revision20 and CHANGELOG untouched. No tag, release, package archive or artifact-branch write.
