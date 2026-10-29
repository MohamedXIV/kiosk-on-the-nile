# SDD ledger — plan: docs/superpowers/plans/2026-10-29-semantic-policy-runtime.md
Base: 1a6d17e48d287f88078584d3d04015e3ebcc0b75
Pre-flight A->B: compiler owns typed expanded nodes; evaluator consumes only compiled nodes and bound contexts.
Pre-flight B->C: one stage-aware service binds topics; Director only opts in encounters with semantic_topic metadata, all49 production encounters remain legacy until#24.
Ruling: keep existing task workspace on isolated feature branch; no concurrent implementation agents.
Ruling: no automated suites per user; use retained bounded one-off engine observations instead of suite/TDD scripts.
Ruling: empty optional policy catalog supports future content; strict runnable schema is documented separately from selected design fragments.
Ruling: optional semantic start proof lives in existing context_extra; legacy envelope/schema20 unchanged; validate semantic proofs only on opted-in topics. Future per-knower/history representation is#22/#23.
Task A: complete — compiler/bind core native observations FAILURES0, including actual profile and distinct-role binding.
Task B: complete — invalid propagation/explain equality; actual directional/time/presence/provider observations; no Boolean cache.
Task C: complete — compiled disposable Ink manual/automatic/stale offer/choice/hearing/current-save/paused/actor-return paths FAILURES0; all49 production encounters stay legacy.
Ruling: one hearing-scoped effect per opted-in beat; reject world/multiple effects until#22 atomic preparation — avoids pretending partial batches are atomic; full content conversion remains#24.
Ruling: literal compiled choice target-path map belongs in InkRuntime because inkgd drops choice tags on restore; dynamic/ambiguous tags reject — future compiler/inkgd upgrades must revalidate this boundary.
Ruling: most-capable review attempt hit usage cap; use available fresh-context reviewer rather than omit review — review model differs, scope remains whole branch.
Final review: no Critical; two Important; no deferred minors. Fresh reviewer read-only, no engine contention.
Final: fixed profile insertion-order dependency — core-before FAILURES1 -> core final FAILURES0; selected actual-profile missing-field still rejects.
Final: fixed wrong-participant hearing and missing speaker — hearing-before false + speakerless-before FAILURES2 -> lifecycle/speakerless final FAILURES0. Attributed actual speaker hearing required only on semantic path; safe speakerless control frames remain effectless.
Final: Ruling: reviewer declined shipping performance/full acceptance from original lightweight timing — use populated four-present-actor/5-provider/240frame CPU fixture instead; no player-device FPS or integrated-epic claim.
Task D: complete — tracked build.sh --release succeeds (Ink,377 localization refs, import, Web export); evidence retained in docs/notes/evidence. Exact committed-source CI and guarded merge follow.
