# Delivery status and roadmap

## Semantic narrative architecture — 2026-10-29

Next architectural work is [epic#19](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/19), with ordered tasks#20–#27. Task#20 records a [source-grounded contract and acceptance matrix](../architecture/semantic-narrative.md), [selected authoring examples](../architecture/examples/semantic-narrative-v1.json) and the [#21 runtime plan](../superpowers/plans/2026-10-29-semantic-policy-runtime.md). These documents are design, not delivered gameplay. Roles, per-knower provenance, directional history and start/continuation/commit/resume semantics are separated while existing owners retain authority. Runtime implementation follows through#21–#26; final changelog/version/save decision and one verified preview remain#27 after coherent completion, per the user's instruction. No version, changelog, save-format or release change in this documentation task. Existing first-playtest feedback on#6/#7 remains open.

## Semantic runtime foundation — 2026-10-29

Issue#21 now has a typed compiled evaluator, stable role/presence binding, ordered fail-closed decisions and an opt-in lifecycle path. [Runnable API](../architecture/semantic-policy-runtime.md) and [delivery/evidence](../notes/2026-10-29-semantic-policy-runtime.md) describe native compiled-Ink/save/resume observations, independent review fixes and a four-present-actor provider timing fixture. All49 production encounters remain on their inventoried legacy paths until#24. Per-knower knowledge/transaction adapters#22 and generalized social history#23 are next; absent capabilities remain invalid, without substituting player knowledge. No version/changelog/schema/release change; final coherent delivery remains#27. Source PR/CI/integration state is recorded live on#21/#19.

## Per-character knowledge foundation — 2026-10-29

Issue#22 adds typed assertions indexed per knower, explicit seeds, attributed heard/relayed sources and atomic prepared hearing batches. Intended listeners are checked independently; an NPC can learn without granting player knowledge or player Journal speech. Current JSON save/load, paused actor return, exact relay lineage and malformed source/order rejection have bounded native evidence. Independent review findings were reproduced/corrected; production legacy save shape remains unchanged. [API](../architecture/semantic-knowledge.md), [validated authoring example](../architecture/examples/semantic-knowledge-v1.json) and [delivery/evidence](../notes/2026-10-29-semantic-knowledge.md) record limits. All49 production encounters remain unconverted until#24. #23 generalized social history is next; #27 final version/changelog/preview still last. Source integration/CI state is recorded live on#22/#19.

## Generic social history foundation — 2026-10-29

Issue#23 adds SocialLife-owned directional introductions/distinct meaningful dates, data-capped RelationshipStore candidates, purpose/scope-specific consent/refusal/revoke/expiry and once/day/visit/evidence consumption. Shared days remain independent of gains; old/new paths share positive NPC→player budget. Three-owner publication validates before mutation; current JSON restore checks actual source/frame/presence proofs. [API](../architecture/semantic-social.md), [validated example](../architecture/examples/semantic-social-v1.json) and [delivery/evidence](../notes/2026-10-29-semantic-social.md) retain native observations and independent review fixes. All49 production encounters remain legacy until#24, which now converts complete families and explicit player-choice/domain adapters. #25 tools/#26 integrated acceptance/#27 final version/changelog/preview remain. Source integration/CI state is recorded live on#23/#19.

Recorded 2026-10-28 (Africa/Cairo). Main source baseline before the combined preview: `422adb93e3c472a22e883912040f2afadb86bccf`. Latest numbered preview: **v0.1.0-prealpha.2**, source `51c5b0de7411f3b0a74934ab0a491342144d5a7b` (source integrated through PR#12). This overview supersedes historical unchecked plan boxes as a delivery-status index, while individual notes retain evidence and limits.

## Delivered

- Shared clock, needs/sleep/mood/action consequences and configurable tuning.
- Continuous Ink conversations, inner thoughts, knowledge, directional relationships, notebook/history and workshop trial with actual outcome/follow-up.
- Weekly accounts, landlord, deferrals/loans, district rent/prepayment/suspension, supplier contracts and deliveries.
- Shopping journeys, shared home/kiosk grid placement, developer-only structures, storage, equipment-dependent recipes and hygiene.
- Offline Arabic/English UI and all12 current preview authored Ink stories; historical captured text retains its language.
- Cached grid navigation, idle animation, observed-location memory, bounded Youssef approach, dynamic visitor seating and local person avoidance.
- HUD cleanup and bundled needs/day icons. Audio report withdrawn after user confirmed sound works.

Evidence: see dated delivery notes under `docs/notes/`. Delivered does not imply exhaustive regression acceptance or final art/balance.

## Planned and proposed epics

- [Integration cleanup](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/1)
- [Quiet social encounters](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/2)
- [Narrow passage coordination](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/3)
- [Hospitality and payment choice](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/4)
- [Continuing stories and relayed messages](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/5)
- [Multi-day pacing and world identity](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/6)
- [Player and residential seating — proposal](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/7)

## Execution order

Integration cleanup first. Then quiet social encounters with bounded passage coordination; hospitality/payment; continuing stories/messages; combined multi-day pacing and presentation work. Player/residential seating remains a proposal until designed. No gameplay implementation starts as part of this documentation task.

Current action: deliver one combined playtest preview at development target0.2.0-prealpha.1, including previously deferred player/home seating and home friends as explicitly authorized by the user. PR#16 integrated as422adb9; main build40649107406 passed. #6 mixed-week pacing/presentation and #7 seating/invitations are implemented on the combined branch, with bounded evidence and independent review fixes. Human playtest/feedback is the next acceptance step; do not interpret older home-guest exclusions as current scope.


## Integration completed

PR#9 merged into main after successful checks; post-merge build passed. Epic#1 is complete. Permanent remote branches are now main and artifacts, with35 preserved playable archive versions. Historical66-branch audit is retained as evidence; see INTEGRATION.md for outcome and guarded deletion manifest. Next planned batch: quiet social encounters (epic#2), with narrow-passage coordination (#3) considered within that design. No new gameplay work was performed during cleanup.

## Quiet social preview delivered; integration pending

Epic#2 now has a complete [playable preview](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/quiet-social-706d7d0): two observed NPC pairs, autonomous Ink, first-audibility receipts, optional manual participation, broadened Farid approach and revision16 compatibility. Fresh review findings were addressed in one pass; bounded native/Chrome evidence is in the delivery notes.35 old archives plus this preview are retained on the single artifacts branch (36 total). Main remains unchanged.

Before integration: [durable Web save acknowledgment#10](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/10), preview acceptance, and review of the recorded group multi-choice/candidate-config limits. A rapid reload during pending synchronization lost a requested save in one fixture; longer-wait group persistence and ordinary migration/Continue succeeded. No exact safe delay is established. Epic#2 remains open until integration/acceptance. Narrow-passage coordination#3 remains separate; no universal third-person displacement was added.

Next planned gameplay batch after those gates: narrow-passage coordination, hospitality/payment#4, continuing stories/messages#5, multi-day pacing#6. Player/residential seating#7 remains proposed.

## Web save fix preview delivered

[Corrected full preview](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/web-save-ack-e8cfa15) includes quiet-social plus issue10's implemented acknowledgment fix: exact persisted bytes, pending/error/retry HUD, serialized/coalesced requests and pending beforeunload warning. Native save/backups and revision16 remain. Fresh review's BOM edge was reproduced and corrected; exact Release Chrome fault/retry/immediate-after-ack reload/Continue and native observations are recorded in docs/notes/2026-10-27-web-save-acknowledgment.md.37 playable archive versions are preserved.

The earlier technical storage gate now has an implemented fix. Source integration and preview acceptance remain pending, so#10/#2 stay open; main is unchanged. Browser/OS termination or overriding the navigation warning is outside a durable completion guarantee. The adapter's4.7.2 backend pin requires revalidation on engine upgrades. Next gameplay work remains bounded passage coordination#3; the group multi-choice/candidate-config limits remain recorded.

## Versioning foundation before further gameplay

User policy clarified: unpublished pre-alpha; do not spend routine development effort on historical-save compatibility. SemVer/Keep a Changelog and a first numbered baseline0.1.0-prealpha.1 are being established before epic3. VERSION/project metadata/build provenance/annotated tags and package consistency are tracked together. Future breaking save changes may require a new game and must say so; existing integrity guards remain. See docs/RELEASING.md and CHANGELOG.md.

## Versioning foundation delivered

The first published numbered baseline is v0.1.0-prealpha.2, source51c5b0d. Canonical VERSION/Godot metadata, SemVer prerelease tags, curated changelog/save-impact entries, verified actual toolchain/export provenance and reusable packaging are in place. Tagged CI passed40562637988; independent archive checks completed. Candidate1 remains a labeled validation record, with no rewritten tag.39 packages are preserved, including all37 legacy versions.

User policy is now explicit in AGENTS.md/docs/RELEASING.md: unpublished pre-alpha saves do not receive routine backward-compatibility/migration work. Future resets are allowed and documented; integrity guards remain. No gameplay/save-format changes in this foundation batch. This priority precedes the next gameplay epic3; source integration/acceptance is still separate.

## Passage coordination implementation — 2026-10-28

PR#12 merged as f623e5d with preserved source ancestry; post-merge push build40609338097 passed. Issues#2/#10/#11 are closed for their bounded delivered batches; their recorded limits remain. The later PR-event run40568964552 also passed on final source HEAD88817d4. No release/tag/archive was rewritten.

Epic#3 now has an implementation on feat/narrow-passage-coordination: transient pair priority, bounded validated retreat routes, safe no-refuge waiting/retry, explicit speaker/seat/player protection and JSON limits. The local network/toolchain blocker was resolved using network-enabled commands and the tracked SHA256-pinned Godot4.7.2 installer. See [delivery record](../notes/2026-10-28-narrow-passages.md). PR#13 was subsequently accepted and merged as 00a1d95; see the latest checkpoint below. No automated test suite was added or run.

## Passage source integration and next batch — 2026-10-28

The user explicitly approved merging PR#13 if safe. Fresh RepoPilot prepare_merge reported ready=true with no blockers on0d32154, successful Web/GitGuardian checks and no stale reviews. GitHub proposed merge tree matched the locally checked source exactly. PR#13 merged with preserved commits as00a1d95d0f324eb05d5e8d7caf6be6114f9f198d. Post-merge build outcome is recorded in docs/notes/2026-10-28-narrow-passages.md and GitHub issue#3. The bounded #3 source batch is integrated; impossible-refuge/RVO limitations remain. No source branch was deleted and no release/tag/asset was rewritten.

Next: #4, hospitality and payment choice. Initial code inspection confirms ServiceSystem.deliver consumes the item, credits price/tip and emits settled in one operation. OrderState/history do not yet retain a hospitality/payment disposition. The next design must separate actual handover from settlement, keep each one-time, support natural acceptance/refusal before an unaffordable order, and remember actual paid/gift/refusal outcomes. UI, Ink effects and Arabic/English content need to describe the same committed state. No #4 feature code, save migration or automated suite was added during this integration.

## Hospitality/payment preview implementation — 2026-10-28

Issue#4 implemented on feat/hospitality-payment-choice: separate one-time handover/settlement, atomic production completion after player choice, gift promise binding, repeat-visit Youssef money-short request/three acceptance phrasings/humane refusal, actual service/refusal memory and a bilingual choice sheet. Explicit current-save receipt ownership/metadata/link validation is included. Schema4/revision17 intentionally requires a new game for earlier pre-alpha saves; unsupported files are retained. No migration/archived Ink graph was added.

Tracked draft Release build/339 stable localization references and bounded paid/gift/refusal/current-save/native/Web-component observations passed; independent material findings were addressed. See [delivery note](../notes/2026-10-28-hospitality-payment.md) for evidence and limits. Exact committed-source build/PR CI are tracked with the source PR. #4 stays open for source/preview acceptance; #5 continuing stories/messages remains next.

## Continuing stories implementation — 2026-10-28

PR#14 integrated hospitality/payment as4bcdfcb with successful main build40643790857. The next isolated #5 batch adds two multi-day exam/radio arcs and optional absent-friend question/reply delivery with strict provenance and once-only receipts. Native Arabic/English observations cover postponement, day/absence gates, pending/completed restore, repeats and malformed-state rejection. See [delivery record](../notes/2026-10-28-continuing-stories.md). Save revision18 requires a new game for earlier pre-alpha saves; old files remain. Source/preview acceptance remains pending; #6 next, home guests excluded.

## Quiet-days milestone — 2026-10-28

New games receive240EGP finite savings rather than45EGP, addressing the first-week no-sales shortfall without changing rents, needs, arrivals, preparation or existing saved wallets. Controlled native day1→first-rent observations with sleep/food leave162EGP before120 rent (42 arithmetic headroom), with empty intervals, independent closed/away visits and no orders. This excludes actual walking/UI rent payment and does not claim sustained balance. Existing revision18 saves remain; actual1234-minor restored wallets received no grant. [Delivery/evidence](../notes/2026-10-28-quiet-days.md) and [art/audio direction](../art/WORLD_DIRECTION.md) document the bounded scope. No new production assets or home guests; #6 stays open.

## Combined preview — 2026-10-28

The user's latest instruction includes all remaining/deferred work before one trial. [Combined delivery record](../notes/2026-10-28-complete-preview.md), [Arabic guide](../PLAYTEST_GUIDE_AR.md), [mixed weeks](../notes/2026-10-28-mixed-days.md) and [presentation](../notes/2026-10-28-world-presentation.md) record player/home seating, optional known-friend invitations, actual household/workshop exclusivity, source-correct sound, procedural polish, closed-sign purchasing and12/28EGP paid prices. Save19/new game is explicit; prior files remain. Final source/preview integration and human acceptance are recorded live on #6/#7/#8. No production-final feel claim, automated suites, published tag rewrite or branch deletion.

## First combined-playtest feedback — 2026-10-29

The user observed dropped frames and premature/unheard social topics in fc65ba3. Correction target0.2.1-prealpha.1 groups floor/roof rendering batches and gates social progression through the existing directional familiarity/trust, elapsed acquaintance days and heard knowledge. Optional daily company builds relationships without commerce. See [correction record](../notes/2026-10-29-playtest-fixes.md) and [render measurements](../notes/2026-10-29-render-batching.md). Schema4/revision20 requires a new game, preserving earlier files. Independent review finding corrected; bounded observations pass. Final clean-source CI/integration and retained corrected preview are recorded live on the delivery PR and issues#6/#7/#8. Player-device smoothness and human feel remain user acceptance.
