# Pre-alpha versioning and release records

User-directed priority before the next gameplay batch. The game is unpublished pre-alpha; historical save compatibility is not an ongoing requirement. Routine tooling choices below are implementer decisions under that instruction.

## Policy and choices
Use Semantic Versioning2.0.0 with a project prerelease label, starting0.1.0-prealpha.1; use Keep a Changelog1.1.0 for curated human-readable notes and annotated immutable `v<version>` Git tags. VERSION is the sole project-version source. Commit hashes remain build provenance/cache identifiers. Godot4.7.2 and internal save schema4/revision16 are distinct identifiers.

Game-facing features normally increment the0.x minor base, fixes increment patch; successive candidates of a single target use prerelease.N. Channel labels are project policy, not a SemVer-defined lifecycle. Promote prealpha→alpha on a higher minor base (e.g.0.2.0-alpha.1) to avoid SemVer lexical ordering accidentally decreasing precedence. No1.0/stable promise yet. Conventional Commit prefixes are a prospective authoring convention, not a reason to rewrite historical commits.

A date/hash-only policy lacks readable milestones; automated commit-message-derived changelogs obscure game changes. Chosen approach: one plain VERSION, curated changelog, small standard-library Python tooling, build/CI consistency checks. Existing legacy tags/archives remain historical and are not renumbered. First numbered release is a current-state baseline, not an invented historical release date.

## Save policy
During pre-alpha, saves are disposable across releases and a new game may be required. Do not routinely add migrations or archived Ink graphs solely for unpublished old saves. Each release explicitly says whether its batch changes save format/requires reset. Existing migration code is not removed as incidental cleanup; save integrity/error reporting remains valuable. Never silently delete/reset a save. Version identifiers do not themselves decide save compatibility; internal format identifiers do.

## Tooling
Synchronize project.godot config/version from VERSION and reject drift during build. Export matching version+commit engine filenames and automatic BUILD.json (project version/stage/source/dirty/build mode/engine/save format/content digest). A reusable packager checks export provenance/content/one engine, bundles changelog/run guide/licenses and emits a versioned platform ZIP. Formal packaging requires a clean source and matching annotated tag + dated changelog entry; draft optimized builds remain allowed and explicitly marked development. Output ZIP stays outside the Web root.

CI checks consistency and tagged releases without granting publication permissions; build artifacts remain available. Publish one complete first numbered pre-alpha archive on the existing artifacts branch, independently download/hash/CRC/content-check it, and record the result. No gameplay behavior/save migration work or automated test suite, no main merge or historical tag rewrite.
