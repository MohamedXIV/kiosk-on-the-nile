# Offline narrative authoring — #25

Run `bash tools/godot.sh --headless --path . --script tools/narrative-authoring.gd --` to validate shipped semantic content. Optional `--content DIR` reads a different external manifest; errors/warnings resolve section filenames from that manifest, including shared compiled stories. Output is JSON after the engine banner. Exit1 means content/restore failure; warnings do not reject content.

For a chosen current save: append `--save FILE --encounter home_invite --participants visit_1 --stage offer`. Optional `--key ID` selects a choice/action. The save is read, validated into a disposable session, never rewritten. Handle IDs must match that saved state. No save means a fresh state, not invented actors/history. Missing bindings produce an invalid decision. Explanation evaluates the same compiled policy and actual providers twice (normal/explain), reports stable reason paths/evidence and parity. This is a pure policy explanation; domain publication and conversation lifecycle can separately reject an action. It does not bypass start proofs or manufacture consent.

Diagnostics use existing strict compilation for typed actors/roles/facts/profiles/operators/scopes, unknown fields and cycles. Compiled Ink choice/action/effect IDs are checked against the corresponding story catalog. Shared stories emit `shared_story_binding_unproven`: finding an ID somewhere in the story catalog does not prove that its reachable branch belongs to every active topic. The analyzer deliberately does not prove arbitrary Ink control flow. It never labels this uncertainty validated. Split a story per topic, or retain a documented shared branch and inspect each actual encounter as the #24 examples do.

Supported conservative warnings:

- `contradictory_direct_all`: direct relationship bounds within one `all` cannot simultaneously hold. Nested `any` alternatives are not combined and valid alternatives are not rejected. No claim about all other sources of unreachability.
- `no_declared_fact_source`: a queried fact type has no explicit initial seed or heard/relayed action source. This is fact-type-level analysis, not role substitution or a complete proof of reachability. Runtime/world adapters and future authored paths may justify reviewing rather than rejecting this warning.
- `shared_story_binding_unproven`: branch-to-topic attribution remains uncertain as described above.

Adding an actor/topic: declare the actor in the existing visitor data; bind generic roles/recipe/subject/thread in an encounter; author typed topic stages/choices/actions and matching knowledge/social declarations; compile Ink with literal stable `policy_choice`, `policy_action` and `effect:semantic` IDs. Use docs/architecture/examples/semantic-social-v1.json and retained #24 Nadia/tea/thread evidence for examples. Keep finite message instances and actual request/reply/delivery consent.

A justified override is authored data, never an evaluator bypass: if the story establishes that a teacher already knows a recipe, add an explicit seed such as `{"id":"teacher_tea","knower":"nadia","fact":{"type":"recipe_basics","args":{"recipe":"tea"}}}`. Do not seed the player's heard connection or create high scores to impersonate days/consent. An intentional shared-story warning is documented in author notes with observed branch bindings; it is not suppressed globally or changed into permission.

The CLI/analysis are developer-only, offline and not invoked by player UI or frame-time eligibility. VERSION/CHANGELOG remain deferred to#27. No automated suite added/run.
