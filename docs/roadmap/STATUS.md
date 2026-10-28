# Delivery status and roadmap

Recorded 2026-10-28 (Africa/Cairo). Main source baseline: `4bcdfcbf4f95c1a369e2d91ac2f6bb2d0698da50`. Latest numbered preview: **v0.1.0-prealpha.2**, source `51c5b0de7411f3b0a74934ab0a491342144d5a7b` (source integrated through PR#12). This overview supersedes historical unchecked plan boxes as a delivery-status index, while individual notes retain evidence and limits.

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

Current action: continuing stories/messages #5 on an isolated branch. Hospitality/payment #4 integrated through PR#14 as `4bcdfcb`; exact-head readiness/proposed merge tree matched checked source and post-merge build40643790857 passed. No branch deletion or formal release. User explicitly leaves home guests aside. Next after this bounded #5 delivery: combined multi-day pacing/world identity #6.


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
