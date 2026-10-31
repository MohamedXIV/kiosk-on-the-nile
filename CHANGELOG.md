# Changelog

Notable changes are recorded here for people, following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Project versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html), with the pre-alpha conventions in [the release policy](docs/RELEASING.md).

## [Unreleased]

### Character and cooking v2 preview target: 0.4.0-prealpha.1

- Add authored preferences for all12 current characters and lightweight saved hunger, thirst, tiredness and company intentions. Contextual weighted choices preserve quiet visits; rest/company affect existing social behaviour without increasing the four-person cap. Weather remains a neutral interface.
- Track ingredient lots, category-specific grades and actual purchase costs. Prepare liver/pane/ful/potato batches through shared preparation, soaking, transfer, heat and holding commands, including overnight ful. Learned shawarma retains its sourced teaching path.
- Choose real plate/sandwich, here/takeaway and compatible additions; consume their actual ingredients and packaging. Set menu prices freely. Accepted orders retain their chosen content and price after menu edits; gifts remain distinct and prices gain no implicit tip.
- Let freshness decline gradually with a comfortable grace period. Storage affects future decline; splitting, pouring or reheating does not make old food new. Clearly refuse unservable food and allow deliberate disposal.
- Remember only a person's confirmed on-site taste, personal fit and paid value. Takeaway and departure do not invent eating. Bounded own memories can influence future choices/returns under existing quiet arrival limits.
- Add reusable relationship-gated Ink comments about personally noticed additions, actual tastes, optional requests and observed cleanliness changes. Heard sources/cooldowns prevent repeats and knowledge inheritance; suggestions do not unlock recipes or create quests.
- Add bilingual recipe/serving and price controls. Correct double bread consumption in shawarma and exclude personal-only food from commercial offers while preserving self-use.

**Save compatibility (character/cooking batch):** schema4/revision22 requires a new game for all earlier unpublished saves, including revision21. Unsupported/corrupt primary and backup files are retained; no historical migration is added.

This is an optimized development preview, not a formal tagged release. Connected native observations, normal Web startup/Continue checks and a brief matched populated render observation are bounded evidence; natural long-session pacing, economy, device FPS and broader human acceptance remain open. See [integration evidence](docs/notes/2026-10-31-character-cooking-integration.md).

### Previous semantic narrative preview target: 0.3.0-prealpha.1

- Add typed shared narrative policies, directional acquaintance and meaningful shared days, per-character source-backed knowledge, scoped consent, and once-only message lineage.
- Convert home invitations/cancellation/company/goodbye, personal check-in request/reply/delivery and recipe connection/teaching/followups onto shared rules. Explicit player choices establish promises and delivery; domain owners retain actual home/workshop/cooking outcomes.
- Preserve teaching continuation and saved/returning choices after their own learning or consumption; restore localized notebook recipe instructions from canonical assertions.
- Add offline author diagnostics with actual manifest paths, conservative source/contradiction warnings, explicit shared-story uncertainty and same-provider saved-state explanations.
- Retain quiet no-commerce company, shared old/new gain caps and the prior floor/roof batching correction. The remaining29 owner-specific encounters are explicitly inventoried; full universal conversion and human pacing/visual/audio acceptance are not claimed.

**Save compatibility (semantic batch):** schema4/revision21 requires a new game for all earlier unpublished revisions, including20. Current coherent saves are validated with their source proofs; unsupported/corrupt primary and backup files are retained. No historical migration or archived Ink graph added.

This is a clean-source development preview candidate, not a formal tagged release. Integrated bounded observations do not establish user-device FPS or human feel.


### Earlier playtest correction target: 0.2.1-prealpha.1

- Batch static kiosk floor and roof fills before line details, removing the primitive alternation introduced by the combined preview. Matched rendered kiosk observations reduced draw calls2497→235 with pixel-identical frozen scenes; user-device FPS remains to be judged in play.
- Personal topics now require prior-day acquaintance; messages require knowing both people for multiple days and hearing the relevant story. Home invitations require familiarity/trust and meaningful company across several days.
- Quiet optional daily company builds the existing relationship without spending, gifts or workshop participation; repeating it on the same day adds no gain.
- Farid first mentions his shawarma connection in heard Ink speech; only that knowledge opens the recipe question, and taught basics gate its follow-ups.

**Save compatibility (correction):** schema4/revision20 requires a new game for earlier pre-alpha saves (including revision19); files are preserved. No migration or archived Ink graph added.

Previous development target: **0.2.1-prealpha.1**, correcting the combined playtest. An optimized development package is not a new formal tagged release.

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
