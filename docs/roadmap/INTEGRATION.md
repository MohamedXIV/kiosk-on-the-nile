# Source consolidation gate — 2026-10-27

Authorized continuation of repository cleanup before new gameplay work. PR#9 consolidates the accumulated source; archive histories are not merged into source.

## Review and evidence

- Main was an ancestor of the candidate, with no divergent main-only commits. The accumulated increment notes retain their earlier reviews/limits.
- Runtime source/config/tools/assets at candidate28b099a are byte-identical in Git to published product1316423; later commits contain documentation only. This is an integration-boundary review, not a new independent exhaustive1012-file code audit.
- Current build-only gate completed311 Ink localization references, Godot4.7.2 import and Release Web export. No script/parse/compile errors. GitHub Web build and security checks also passed on28b099a; final-head checks are required before merge.
- Bounded native runtime observation loaded content/session, exclusive physical seating, actual seated request/order, occupied chair/table protection, revision15 restore and revision14 migration preserving wallet/clock/RNG/order.600 cached reads caused0 catalog rebuilds.
- Native short-run teardown still reports99 ObjectDB instances/23 resources in use, matching that fixture's earlier documented observation; no general leak fix is claimed. No automated gameplay suite was added/run. See evidence/integration-runtime.log and integration-build.log.
- Historical evidence contains trailing whitespace; no production-code diff-check issue was found. Evidence output was retained without rewriting old logs.

## Branch disposition

The five apparently divergent source previews each add only one old ZIP, with no unique gameplay code. They are now preserved with CRC/SHA256/provenance in artifact commit612203028ce317e86cafdd7c9f38951d55fa5219, which retains the prior consolidation plus all five original heads as parents. The archive now contains35 versions. All other obsolete source heads must be ancestors of merged main before deletion. Cleanup uses exact expected-head leases; unexpected concurrent changes stop the deletion.

Existing permanent heads after approved cleanup: main and artifacts. The integration branch is removed only after merge. Use issue branches for future work, keep permanent build downloads in artifacts, and preserve immutable release references. The prior66-branch audit remains a historical snapshot.

## Retained known limitations

Narrow stationary-person bottlenecks, player/home guest seating proposal, broader social stories/encounters and source vision gaps remain on roadmap#8. No gameplay implementation is included in this maintenance task. No universal regression/performance claim.
