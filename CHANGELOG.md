# Changelog

Notable changes are recorded here for people, following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Project versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html), with the pre-alpha conventions in [the release policy](docs/RELEASING.md).

## [Unreleased]

### Added
- Two quiet multi-day conversations: Youssef's exam preparation and Farid's old radio. Optional questions about an absent friend and explicitly sourced replies have durable, single-delivery receipts in Arabic and English.

### Changed
- Continuing-story follow-ups require a later calendar day; private progress is learned from its speaker. Message endpoints and dependencies are validated when loading.
- **Save compatibility:** schema4/revision18 requires a new game for previous pre-alpha saves (including revision17). Unsupported saves are explained and their files remain intact; no migration or historical Ink graph is added.


**Save compatibility:** Hospitality changes the format to schema4/revision17. Earlier pre-alpha saves require a new game and are rejected clearly; their files/backups are not silently removed. No historical migration is added. Passage coordination itself remains transient.

### Added

- Deliberate paid service or hospitality, separate handover/settlement ownership and one-time financial receipts. A promised gift cannot become a paid sale.
- An authored money-short request for Youssef on a repeat visit, three natural acceptance phrasings, humane refusal without eviction, and actual gift/refusal memory follow-up in offline Arabic/English.
- A service-choice sheet before handover; its active recipient waits while the player decides.

- NPCs coordinate a stable right of way and a bounded nearby retreat when a narrow passage stays blocked. Speaking/seated people and the player keep control of their position; traffic does not replace visit goals or consume domain fallback while coordinated.
- Optional validated spatial JSON settings bound retreat search, route length, wait duration and retry work. If no refuge is safe, people wait and periodically reconsider rather than forcing a passage.

## [0.1.0-prealpha.2] - 2026-10-27

First published numbered pre-alpha baseline, including the complete candidate1 feature/policy baseline below.

**Save compatibility:** No save-format change in this batch (schema4/revision16). Pre-alpha backward compatibility remains optional; future reset requirements will be explicit.

### Fixed

- Tagged CI now fetches the actual annotated tag object for a shallow checkout before enforcing source/tag consistency.


## [0.1.0-prealpha.1] - 2026-10-27

Tagged validation candidate; not published as a GitHub release. Its local build/package passed, while tag CI stopped because shallow checkout omitted the annotation. Candidate2 records the CI correction; the original tag and bytes are retained.

First numbered pre-alpha baseline. Earlier technical previews used descriptive/hash tags; this entry records the current baseline rather than assigning invented versions to those previews.

**Save compatibility:** This release batch does not change the existing save format (schema4/revision16). Pre-alpha releases have no ongoing backward-compatibility guarantee; future releases may require a new game, stated explicitly in their notes. Historical-save migrations/Ink archives are no longer a default development obligation.

### Added

- The current Godot/Ink slice-of-life baseline: shared time and needs, home/kiosk arrangement, shopping/equipment/recipes/hygiene, accounts and suppliers, knowledge/relationships/journal, and offline Arabic/English.
- Quiet independent visitor life, observed peer meetings and optional participation in autonomous Ink conversations.
- Canonical project version, versioned build provenance, a reusable release packager and release consistency checks in CI.
- Contributor and release policy separating project versions, Godot versions and save-format identifiers.

### Fixed

- The baseline includes the reviewed Web save acknowledgment fix: confirmation of actual stored bytes, pending/error/retry feedback, queued saves and a pending-navigation warning.

### Changed

- Release notes become curated changelog entries; commit hashes remain provenance and cache identifiers.
- Future pre-alpha save compatibility is optional, while integrity checks and explicit reset requirements remain important.

### Known limitations

- Pre-alpha placeholder presentation/content/balance and bounded acceptance coverage.
- General narrow-passage coordination is pending; current group scenes use one player choice window, and candidate search is capped internally.
- The Web acknowledgment adapter pins Godot4.7.2's backend and requires revalidation on engine upgrades. Browser/OS termination or overriding its leave warning cannot guarantee save completion.

## Legacy previews

Historical notes, descriptive tags and immutable downloads remain in the [archive index](https://github.com/MohamedXIV/kiosk-on-the-nile/tree/artifacts). They are not retroactively renamed or assigned SemVer numbers.

[Unreleased]: https://github.com/MohamedXIV/kiosk-on-the-nile/compare/v0.1.0-prealpha.2...HEAD
[0.1.0-prealpha.2]: https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/v0.1.0-prealpha.2
[0.1.0-prealpha.1]: https://github.com/MohamedXIV/kiosk-on-the-nile/tree/v0.1.0-prealpha.1
