# Pre-alpha versioning implementation plan

> Execute inline using superpowers:executing-plans. User requested this foundational task before further gameplay. No repeated scope approval for routine naming/tooling choices.

**Goal:** A clear pre-alpha version/save policy and reproducible traceable releases.
**Architecture:** VERSION is authoritative; release.py checks/synchronizes Godot metadata, generates build provenance and packages formal tagged releases. Curated CHANGELOG.md and docs/RELEASING.md define the human workflow.
**Tech stack:** Godot4.7.2, Python standard library, shell/Git/GitHub Actions, SemVer2/Keep a Changelog1.1.
**Spec:** docs/superpowers/specs/2026-10-27-prealpha-versioning-design.md

## Constraints/review focus
No historical-save acceptance/migration work; no game behavior change; retain integrity guards. No invented past SemVer/date or overwritten tag. Separate engine/source/save-format IDs. Dirty/stale export cannot become a formal release. Validate source content/digest/engine filenames and constrain package paths. No automated test suite unless user asks. One fresh final review, one material fix pass, no main merge.

## Tasks
- [ ] 1. Record save/release policy, VERSION0.1.0-prealpha.1, baseline CHANGELOG and contributor instructions; link from README/roadmap.
- [ ] 2. Implement release.py check/set-version/check-tag/metadata/package; integrate export/build and CI. Commands must report clear errors and permit explicitly identified draft builds. Build-only execution/static checks rather than gameplay/save regression work.
- [ ] 3. Fresh whole-diff review and one material fix pass. Freeze source, create annotated first SemVer tag, exact Release export/package through the new tooling, independent GitHub archive verification and release/changelog links. Preserve legacy history and source isolation; record actual results/limitations.

Preflight: VERSION/Godot project/tag/changelog must agree; metadata describes actual export/source/content, package verifies rather than trusting filenames. Product stage is pre-alpha; save compatibility policy is independent of SemVer. First dated entry becomes true only when its release is actually published.
