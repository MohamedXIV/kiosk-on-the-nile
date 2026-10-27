# Versions, changelog and pre-alpha save policy

Current product stage: **unpublished pre-alpha**. GitHub prereleases are technical previews, not a claim that the game is publicly launched or feature-complete. This policy supersedes older plans that routinely require preserving historical saves/Ink cursors.

## Identifiers

| Identifier | Authority | Meaning |
| --- | --- | --- |
| Game version, e.g.0.1.0-prealpha.1 | `VERSION` | Human release/candidate identity |
| Godot config/version | Synchronized by release.py | Runtime/editor version metadata, never independently edited |
| Git tag v0.1.0-prealpha.1 | Annotated tag at the source commit | Immutable published source identity |
| Git commit and source_dirty | Generated BUILD.json | Exact source provenance; dirty builds are development builds |
| Godot4.7.2 | tools/dependencies.lock.json | Engine/toolchain identity |
| Save schema4/revision16 | SaveCodec constants | Internal data shape, not the game's version |
| build_manifest_version1 | BUILD.json | Build metadata format |

## SemVer project conventions

SemVer defines version syntax/precedence and0.x as initial development; it does not standardize game production stages. Our first numbered baseline is0.1.0-prealpha.1. For coherent published batches:

- New gameplay/capability milestone or intentional breaking change: increment the0.x minor base, e.g.0.2.0-prealpha.1.
- Correction to a released milestone: increment patch, e.g.0.1.1-prealpha.1.
- Further candidates for the same target: increment the prerelease counter, e.g.0.1.0-prealpha.2.
- Individual commits/CI builds do not automatically create a release or bump a version. BUILD.json and engine filenames include the commit as well.
- Channel changes must increase precedence. In particular, `prealpha` sorts after `alpha` lexically: promote on a higher base, e.g.0.2.0-alpha.1, rather than decreasing the same base's prerelease label.
- Project-owned channels are prealpha, alpha, beta and rc. VERSION omits build metadata; the generated build ID adds commit provenance separately.
- Never move/delete/reuse a published tag or replace its archive bytes. Corrections after publication get a new version. Draft packaging before publication can be corrected.

VERSION describes the current target/candidate in source; a dated changelog entry and annotated tag become a published release only when publication actually occurs. An optimized Godot Release build can still be a development build: it does not automatically constitute a formal release.

## Changelog and commits

Use Keep a Changelog's curated Added/Changed/Deprecated/Removed/Fixed/Security sections as applicable. Add changes to `Unreleased` while working; before tagging, move that batch into `## [version] - YYYY-MM-DD` (release date in Africa/Cairo) and leave a fresh Unreleased section. Add compare/release links. Write what changed for the player/developer and relevant limitations; do not dump every commit or describe unimplemented proposals as delivered.

Every dated release entry contains `**Save compatibility:**` with this batch's actual impact: no format change, reset required (which versions), or a deliberately supported migration. No blanket guarantee is inferred from a patch number.

Use prospective Conventional Commit prefixes (`feat:`, `fix:`, `perf:`, `refactor:`, `docs:`, `build:`, `ci:`, `chore:`); use `!`/a BREAKING CHANGE footer for an intentional breaking contract. Changelog entries and version decisions stay reviewed, rather than being inferred automatically from prefixes. Legacy history is not rewritten.

## Pre-alpha saves

Saves may be incompatible across pre-alpha releases. Prefer a documented new-game requirement over spending routine development effort on migrations and archived narrative graphs for unpublished old saves. Add a migration only when explicitly requested or a concrete current need justifies its cost. Existing migration code is not removed as unrelated cleanup.

Keep corruption detection, coherent writes/backups and truthful storage feedback. Reject an unsupported save clearly; never silently delete/reset it. Internal format identifiers decide actual acceptance, not comparisons of game version strings. This batch introduces no format change; future changes state their reset/migration impact explicitly. A later public alpha/beta support commitment requires a deliberate policy revision.

## Workflow

1. Add a curated Unreleased entry while implementing. When choosing the next candidate, run:
   `python3 tools/release.py set-version 0.1.1-prealpha.1`.
2. Before release, date that batch in CHANGELOG.md and record its save impact. Run `python3 tools/release.py check`, commit a clean source tree and create an annotated tag:
   `git tag -a v0.1.1-prealpha.1 -m 'Pre-alpha 0.1.1 preview'`.
3. Run `python3 tools/release.py check-tag --tag v0.1.1-prealpha.1` and build into a fresh Web directory:
   `bash tools/build.sh --release --out /tmp/kiosk-versioned-web`.
4. Package the tagged clean export with:
   `python3 tools/release.py package --release --web-root /tmp/kiosk-versioned-web --out /tmp/kiosk-packages`.
   This emits a platform/version ZIP and its SHA256 sidecar. Package output must be outside the Web root.
5. Inspect the coherent result, push the source/tag and publish a GitHub prerelease using the changelog batch. Append the complete archive to the existing artifacts branch (immutable commit URL/size/SHA256 in its manifest); independently download/check it before reporting delivery. Retain source isolation/integration approvals already established for the task.

`tools/build.sh` checks version consistency, existing Ink/localization/import/export gates, then writes BUILD.json automatically. The packager verifies recorded export hashes, source commit/version/mode/save-format/toolchain/content, expected engine files and clean/tagged source for a formal package. It bundles this changelog, a run guide and third-party licenses. It does not infer gameplay correctness from these checks.

Drafts can use `package` without `--release`; they retain explicit development/source_dirty metadata and a commit-qualified filename. Do not publish them as the formal numbered release. Source changes after an export require rebuilding; a docs-only commit also changes provenance and is not silently relabeled as the earlier build.

CI validates versions and v-tags, exports the Web build and retains artifacts/diagnostics. CI has read-only repository permissions and does not automatically publish releases or merge branches. Normal task instructions govern gameplay observations/tests; versioning is not a reason to re-run historical-save acceptance work.
