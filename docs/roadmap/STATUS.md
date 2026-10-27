# Delivery status and roadmap

Recorded 2026-10-27 (Africa/Cairo). Main baseline product: `131642326d4dfab4f1eb105411415e29c2e28e88`. New isolated preview product: `e8cfa150e1a02ef3f47b96b8f0268e5ac127309f` (feature branch; not merged). This overview supersedes historical unchecked plan boxes as a delivery-status index, while individual notes retain evidence and limits.

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
