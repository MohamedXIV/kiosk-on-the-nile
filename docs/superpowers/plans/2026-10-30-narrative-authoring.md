# Narrative authoring diagnostics — #25

Use executing-plans inline with one final fresh read-only review. Spec: #25 and docs/architecture/semantic-narrative.md. Follow AGENTS.md, GAME_VISION.md and RELEASING.md. No automated suites; bounded disposable observations and tracked build gates. No version/changelog/release until#27.

- [x] Add offline structured diagnostics: canonical validation errors with file/topic paths, conservative direct-all contradictions and missing source warnings. Do not claim arbitrary Ink reachability or reject alternatives based on warnings.
- [x] Add developer-only CLI validation and chosen-state policy explanation through the same compiler/providers; no frame-time content analysis or player UI leaks.
- [x] Author examples, bounded invalid/alternate-order/explain-parity observations, fresh review and tracked build; safe PR/merge and handoff#26.

Review focus: false rejection of alternate paths; mismatched explanation/permissions; untrusted malformed input; source/Ink references across shared branches; no full catalog work in hot queries.
