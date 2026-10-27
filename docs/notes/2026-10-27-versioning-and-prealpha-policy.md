# Versioning and pre-alpha release foundation

User policy: the game is unpublished pre-alpha. Historical-save backward compatibility is optional; routinely adding migrations/archived Ink/old-save acceptance work is no longer required. Save integrity and explicit reset requirements remain. Existing migration code was not removed as unrelated cleanup; no game/save-format behavior changed in this batch.

## Canonical records

VERSION is authoritative, mirrored to Godot config/version by the tracked CLI. SemVer2 project convention uses0.x prereleases and annotated immutable v-tags; Keep a Changelog1.1 supplies curated dated entries with explicit save impact. Conventional Commit guidance applies prospectively. RootAGENTS and docs/RELEASING.md carry the ongoing user instruction. Legacy descriptive/hash versions remain historical and are not retroactively renumbered. Channel promotion uses a higher base to preserve SemVer precedence.

## Tooling and review

release.py checks/synchronizes project versions and annotated tag/date/source/save-impact consistency, records export context and BUILD.json, and packages version/platform ZIPs plus SHA256. Dirty/untagged optimized builds are explicitly development builds. Formal packaging requires clean matching tagged source; source/context changes, modified export bytes, changed canonical content, mismatched metadata/templates or stale engine filenames are rejected. The package bundles version/changelog/run guide/licenses; output must be outside Web root and existing package/checksum files are not overwritten.

Fresh read-only review609e7a5..dda3a8c found one Important provenance defect: engine identity was merely copied from the lock. The material pass verifies actual cached editor/Web templates against SHA256-verified authoritative archives, checks launcher-reported version and exported WASM against the selected verified template, and records these identities. Launcher/installer derive the pinned version; installer repairs stale extracted cache. Minor cross-platform run instructions and stale progress text were corrected. No deferred findings remain from that review. These are traceable/repeatable build checks, not a claim of bit-for-bit identical exports across hosts/timestamps.

## Candidate history and CI

Candidate1 (`v0.1.0-prealpha.1`, sourcef861e9e) passed local formal build/package but CI's shallow checkout omitted the annotation and correctly failed the formal tag guard. The remote tag and binary were retained. CI now refreshes only its ephemeral local tag ref from the authoritative remote annotated tag; it does not rewrite the remote tag. Candidate2 source `51c5b0de7411f3b0a74934ab0a491342144d5a7b` passed the full tagged workflow, including tag check, pinned setup, import/export, package and artifact retention: https://github.com/MohamedXIV/kiosk-on-the-nile/actions/runs/40562637988 . Candidate1 has no GitHub release publication and remains an explicitly labeled validation record.

No automated gameplay suite or historical-save acceptance work was added/run. Standard build/localization324/import/export/package/CI checks were executed. No new gameplay or compatibility guarantee is inferred from these results.

## Published baseline

[First published numbered preview v0.1.0-prealpha.2](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/v0.1.0-prealpha.2) · [complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/c52c952db2468e6203851a2b75544cc2032a1a94/v0.1.0-prealpha.2/kiosk-on-the-nile-0.1.0-prealpha.2-web.zip) · [SHA256](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/c52c952db2468e6203851a2b75544cc2032a1a94/v0.1.0-prealpha.2/kiosk-on-the-nile-0.1.0-prealpha.2-web.zip.sha256).

Source51c5b0d, artifact commit `c52c952db2468e6203851a2b75544cc2032a1a94`, 11939692 bytes/SHA256 `2daaebb5e5afce3320b9c3914b66c161fca4bda9ff3559bd6e910277a1dddabe`. Independent GitHub download matched ZIP/sidecar/hash/CRC, canonical VERSION/tag/source/clean metadata, every recorded export digest, every external content file, one WASM/PCK and12 authored stories. The existing schema4/revision16 is recorded separately and unchanged. All37 legacy entries/history remain unchanged; candidate1 is retained and candidate2 appended (39 archived playable packages total). No new build branch, historical tag rewrite or main merge.

CI keeps repository permissions read-only and does not publish/merge automatically. Source integration remains separate from this release foundation. Future gameplay proceeds under the new pre-alpha policy.
