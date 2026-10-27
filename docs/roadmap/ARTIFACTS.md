# Consolidated release archives

2026-10-27 (Africa/Cairo). Release asset upload was retried and failed with HTTP401 from uploads.github.com; normal repository and release-metadata access work. The authorized fallback uses one `artifacts` branch.

- [Version index](https://github.com/MohamedXIV/kiosk-on-the-nile/tree/artifacts)
- [Immutable manifest](https://github.com/MohamedXIV/kiosk-on-the-nile/blob/c1b9ca36853aacc5d989d30899db6093b559b901/manifest.json)
- Consolidation commit: `c1b9ca36853aacc5d989d30899db6093b559b901`.
- All30 original artifact branch heads are direct parents of this commit. Original blobs and histories remain reachable, preserving old pinned commit URLs. This history must never be merged into the source branch.
- Each of30 archived versions has a version folder, byte count, SHA256 and original branch/commit provenance. Every ZIP passed CRC inspection and contains a WASM engine.
- All32 existing release descriptions retain their original text/links and gain a consolidated archive index; matching versions gain a new immutable direct link.
- Latest HUD archive was independently downloaded from its new immutable URL and checked against the recorded SHA256/ZIP CRC. All30 old heads passed ancestry checks.

Only duplicate `build/*` branch refs are eligible for this cleanup, with expected-head leases. Source branches remain for PR#9 review. Historical branch audit is a pre-cleanup snapshot, not a live count. No game code/build was changed and no gameplay tests were run in this archive maintenance task.

Cleanup completed:30 duplicate build branch refs removed atomically with expected-head leases. Remote heads now total38 (includes artifacts and integration branch). Source branches and main remain unchanged.

Five early preview branches were subsequently found to contain ZIP-only unique commits. They were added with original history/provenance at612203028ce317e86cafdd7c9f38951d55fa5219, bringing the archive to35 versions. See INTEGRATION.md.

Final source consolidation completed through PR#9. Only main/artifacts remain; the earlier38-head count is an intermediate snapshot.
