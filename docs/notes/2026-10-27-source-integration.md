# Completed preview source integration

## Scope and order

Following the user's request to proceed in logical order, prepare one integration of the already delivered quiet-social, Web-save acknowledgment and pre-alpha versioning batches before gameplay epic #3. `chore/prealpha-versioning` descends from both earlier source branches; do not replay or squash their commits, rewrite release tags, or merge the `artifacts` branch.

Baseline main: `63b6a09aac7e4fa6b2d2344f72035596714c5963`. Numbered product baseline: `v0.1.0-prealpha.2`, source `51c5b0de7411f3b0a74934ab0a491342144d5a7b`. Later integration documentation is not a replacement source identity for that immutable package. No new version/tag/archive is needed solely for this integration.

## Gates

- Confirm remote main is an ancestor and inspect the aggregate diff for unrelated removal/artifact history.
- Preserve the explicit repository-wide AGENTS.md policy and delegated-task reading instructions. Historical-save compatibility is optional during unpublished pre-alpha; do not add/run historical-save acceptance work for this integration.
- Fresh read-only integration review focuses on conflicts among the three independently reviewed batches and current shipping behavior.
- Run the tracked build-only Release export (version/toolchain/Ink/localization/import/export/provenance), inspect its result and require PR CI before merging.
- Prepare a reviewable PR with the actual evidence and remaining limits. Source integration approval remains distinct from automatically publishing another release.
- Record the merge and post-merge CI only after they actually occur. Preserve source branches while integration is pending; no blanket branch deletion.

## Explicit limits carried forward

The two shipped peer scenes each contain one player choice window. Supporting another choice window while already participating requires a later group-acquisition change; do not author that unsupported shape meanwhile. Peer search has an internal candidate cap of eight. Neither limit is a claim of fully generic/configurable group storytelling. Both remain visible follow-up work, alongside narrow-passage coordination #3.

The Web-save observer is pinned to the verified Godot4.7.2 backend. Previously recorded bounded native/Chrome evidence remains evidence for those source changes; a fresh build does not imply exhaustive gameplay regression or hardware performance acceptance. No automated gameplay suite or historical-save migration work is part of integration.

## Execution record

- Remote main refreshed and confirmed to be an ancestor of the integration branch. The three source batches form a single descendant chain; the aggregate source diff does not include the artifacts archive.
- Version consistency and whitespace checks of the integration-preparation edits passed. The aggregate diff retains trailing whitespace in historical fixture/browser evidence logs; those records are not rewritten as unrelated cleanup.
- Fresh independent read-only integration review of `63b6a09..7ddf812` plus preparation commit `cc64e0c` found no Critical/Important blocker, artifact-history merge, deleted files or accidental feature pruning. Its minor evidence-whitespace wording finding is corrected here. The reviewer did not independently run builds/gameplay/browser/archive checks.
- `bash tools/build.sh --release --out /tmp/kiosk-integration-cc64e0c-web` completed with exit0 on clean source `cc64e0c4515e17fbc4d483da96c8056b24186e2f`: verified pinned toolchain,324 stable Ink localization references, editor import and Web export. Generated BUILD.json reports version0.1.0-prealpha.2, source_dirty=false, build_mode=release, publication_state=development and schema4/revision16. This is an integration build, not a new tagged/published package. The subsequent evidence-only commit changes provenance; PR CI must build that final proposed source independently.
- PR/CI and merge outcomes will be recorded after completion. No gameplay or historical-save suite was added/run for this integration.

## Completed integration — 2026-10-28 (Africa/Cairo)

PR#12 merged as `f623e5d96069bdc361b0a251cb0160cae4109708` after direct user confirmation in this chat. Parents are main63b6a09 and checked source88817d4; merge tree367eaf71ed12be7103fea52cd51b12dc035caa4e equals the checked source tree. Initial automatic approval review did not accept authorization embedded in the pasted handoff; the user then confirmed the exact merge directly, and it succeeded.

Final source workflow_dispatch40568745443 passed. A later pull_request-event build40568964552 also passed on88817d4; the earlier absence of a PR build was a historical snapshot. Post-merge push build[40609338097](https://github.com/MohamedXIV/kiosk-on-the-nile/actions/runs/40609338097) passed pinned tooling/import/Release Web export/artifact retention. Issues#2/#10/#11 were closed with the exact integration evidence and carried limits. No branch deletion, artifact merge, new release or published tag/asset change was performed.
