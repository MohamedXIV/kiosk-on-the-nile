# Semantic policy runtime foundation — #21

Recorded2026-10-29, Africa/Cairo. Base1a6d17e48d287f88078584d3d04015e3ebcc0b75; isolated `feat/semantic-policy-runtime` source batch. Exact source/PR/check/merge identities are recorded live on issue#21. This record is implementation evidence, not a playable release or full semantic content conversion.

## Delivered boundary

The [runnable API](../architecture/semantic-policy-runtime.md) implements bounded typed catalog compilation, named policy/profile expansion, stable actor roles separately from presence handles, pure allowed/blocked/invalid decisions with ordered reasons, and phase-aware optional Director routing. Every logical child evaluates for invalid propagation. Queries read current owners; no cross-frame decision cache or content-selected executable callbacks exist. Source/topic/group/rule diagnostics accompany compiled-rule failures.

The optional route covers offers, direct/manual starts, guarded manual/automatic choices, actual heard actions, continuation, current restore and returning-actor resume. Start-only predicates are consumed only by actual heard evidence, so a teaching effect does not invalidate its own continuation. Concrete roles/bindings, catalog identity and Journal receipt are verified in existing context_extra metadata. Literal Ink policy choice IDs are checked against compiled source target paths, including after inkgd restore loses choice tags. Third-party addon files are unchanged.

All49 production encounters remain unconverted. Generic relationship/time/presence/domain adapters are available; the sole knowledge adapter is explicitly player-only attributed legacy facts. NPC fact terms, acquaintance/history/consent/event/consumption providers remain invalid until their owners exist in#22/#23. This boundary has no invented actor knowledge or actor-specific evaluator branch. Semantic beats reject multiple/world effects until transactional preparation#22; content family migration is#24. No production manifest/story/localization text changes.

## Bounded observations

[Evidence directory](evidence/2026-10-29-semantic-policy-runtime/) retains native logs, disposable observation inputs as `.gd.txt`/`.ink.txt`, build logs, toolchain and review/decision ledger. These are records, not an automated suite. Scratch scripts were run from ignored `work/semantic-runtime/` with pinned `bash tools/godot.sh --headless --path . --script ...`; temporary Ink compiled with the pinned cached inklecate. No automated suite was added or run.

- `core.log`: missing role under negation stays invalid; any allowed child plus missing provider stays invalid; explain/normal permission agree; unknown actors/extra bindings/saved actor swap/unknown operator/field/cycle/depth/node overflow reject. Selected named profiles work independently of catalog order; actual missing profile fields reject. Conflicting distinct-role binding rejects with topic diagnostics.
- `lifecycle.log`: actual production content config plus in-memory-only opt-in Ink. Stale offer/start and stale choice recheck; optional automatic choice cannot bypass filtering; all choices blocked yields an empty safe candidate set. Far speaker plus nearby bystander does not teach. Actual heard learn blocks a new start but preserves current continuation/save/load. Wrong actor and paused role swaps reject. Returning actor resumes without hearing/effect replay. Live clock boundary/movement changes affect decisions; opposite directional relationship rules differ.
- `speakerless.log`: effect-bearing speech without an attributed speaker rejects before learning, with expected `semantic_effect_requires_speaker` warning. Effectless control frames are not assigned fabricated speakers.
- Four actual present actors (Farid/Youssef/Amgad/Nadia), 240 native process frames, four binds plus evaluations per frame, each continuation with five leaves: availability, personal proximity, directional familiarity, time window and kiosk domain. Final recorded aggregate CPU mean0.404375ms/p950.558ms, inside proposed ≤1/≤2ms fixture budget. Host: x86_64 Intel Xeon Platinum8573C; pinned Godot4.7.2 headless. Includes binding and evaluation; excludes rendering, Ink opening, full gameplay scheduling and player hardware. No GPU FPS/smoothness claim. No allocation profiling claim; call/node/time counters are available.

Native disposal logs report existing inkgd/ObjectDB resources still in use at process exit (lifecycle75 objects/23 resources; speakerless46/21). No script/parse/compile errors in final observations/import/export; these observations do not establish leak-free shutdown or long-session memory behavior.

## Review, build and rulings

One fresh whole-branch read-only review found no Critical and two Important issues. Both were reproduced before correction: profile dictionary-order rejection (`core-before.log`) and hearing another participant's far speech/speakerless teaching (`hearing-before.log`, `speakerless-before.log`). One fix pass corrected both; final focused observations report FAILURES0. No deferred minor findings. Initial most-capable reviewer was unavailable due usage cap; an available fresh reviewer supplied the completed review.

Tracked `bash tools/build.sh --release --out /tmp/kiosk-semantic-runtime-web` succeeded: pinned Ink compilation,377 stable localization references, Godot import and Web export. This local development build was not packaged or published. Final source CI and guarded merge evidence belong to the live PR/issue to avoid claiming a future commit identity in this note.

Execution rulings: retain the existing isolated branch/workspace; honor the user's no-suite constraint with bounded observations; distinguish strict runnable schema from selected design fragments; use optional existing context_extra proof without changing legacy saves; fail closed on unsupported transactions/providers; keep compiled Ink identity handling in its adapter; substitute an available fresh reviewer when the preferred model is unavailable; replace the weak timing fixture with actual present actors/providers and retain limited performance claims. Full decision ledger is retained in evidence.

## Next and save/version impact

#22 supplies per-knower assertions/provenance and atomic preparation; #23 supplies generalized directional introductions/shared days/history. #24 converts complete authored families; #25 adds developer tooling; #26 integrates acceptance. #27 alone closes the coherent batch with actual save/version/changelog decision and one verified preview. #6/#7 human playtest acceptance remains open.

VERSION0.2.1-prealpha.1, Godot4.7.2 and save schema4/revision20 remain unchanged. Legacy serialized frames omit new optional fields; no migration, old-story archive, release/tag or permanent artifact package was added. The future converted topic's proof is optional metadata, not a blanket compatibility promise for future#22/#23 owner changes. Unsupported/corrupt saves retain the existing explicit rejection/byte preservation policy.
