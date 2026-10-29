# Changelog

Notable changes are recorded here for people, following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Project versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html), with the pre-alpha conventions in [the release policy](docs/RELEASING.md).

## [Unreleased]

### Playtest correction target: 0.2.1-prealpha.1

- Batch static kiosk floor and roof fills before line details, removing the primitive alternation introduced by the combined preview. Matched rendered kiosk observations reduced draw calls2497→235 with pixel-identical frozen scenes; user-device FPS remains to be judged in play.
- Personal topics now require prior-day acquaintance; messages require knowing both people for multiple days and hearing the relevant story. Home invitations require familiarity/trust and meaningful company across several days.
- Quiet optional daily company builds the existing relationship without spending, gifts or workshop participation; repeating it on the same day adds no gain.
- Farid first mentions his shawarma connection in heard Ink speech; only that knowledge opens the recipe question, and taught basics gate its follow-ups.

**Save compatibility (correction):** schema4/revision20 requires a new game for earlier pre-alpha saves (including revision19); files are preserved. No migration or archived Ink graph added.

Current development target: **0.2.1-prealpha.1**, correcting the combined playtest. An optimized development package is not a new formal tagged release.

The following combined-playtest features were first delivered in development preview0.2.0-prealpha.1.

**Previous combined preview save impact:** schema4/revision19 required a new game for earlier pre-alpha saves, including revisions16–18. Unsupported saves show the localized requirement; their primary/backup files are retained. No historical migration or archived Ink graph is added. That revision restored active seats, invitations and visits; the current correction uses revision20 as stated above.

### Added

- Deliberate paid service or hospitality, separate handover/settlement receipts, three natural gift-acceptance phrasings and humane refusal; actual outcomes can be remembered later. The recipient waits while the player decides.
- Two new multi-day conversations about Youssef's studying and Farid's old radio, with optional sourced questions/replies and once-only delivery receipts.
- Explicit player sit/stand in both venues using the actual furniture-derived seats. Occupied chairs/tables cannot be moved, stored or cleaned; movement/Esc/travel/sleep releases the player seat.
- Optional next-day home invitations to known Farid/Youssef, postponement/cancellation and a grounded home conversation/goodbye. The existing one-person household visit owner and furniture seats also serve the landlord. Actors cannot be physically present at home and in the workshop/kiosk simultaneously.
- Two ordinary starter home chairs, transferable through existing furniture rules, and a bundled Arabic playtest guide. CI retains one complete versioned development package with guide/licenses/source metadata.
- Bounded narrow-passage priority/retreat coordination; speaking/seated people and player keep control of position. Impossible refuges wait/reconsider safely; domain visit goals remain owned by their systems.

### Changed

- New-game finite savings240EGP (previously45); paid base prices tea12EGP/kebda28EGP. Three-week bounded mixed service/food/ingredients/rent/upkeep observations support quieter low-volume play with gifts. Rents, needs, tips, attendance and cooking windows stay unchanged; no indefinite solvency guarantee.
- Closed kiosk signs prevent new shopping approaches/requests while independent visits continue. Already accepted orders can still be served deliberately.
- Warmer worn paving/timber, corrugated roofs, clearer ordinary furniture/lights/signs and restrained river/far-bank/boat rendering. Existing original audio/mix remain; appliance sounds now follow actual local jobs/heat state.
- Home presence participates in workshop scheduling. A scheduled trial waits until its participants really leave, including an ongoing home conversation.

### Fixed

- Duplicate financial input does not consume another item, repeat income or reward; promised gifts cannot be changed to paid sales. Receipt item/recipient/provenance links are validated.
- Blocked seat access is rejected. A home guest relinquishes failed/obstructed seat routes and keeps a safe standing fallback instead of endlessly overwriting navigation recovery.
- Earlier-save rejection is displayed on the title screen, including the preserved-file/new-game explanation.

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
