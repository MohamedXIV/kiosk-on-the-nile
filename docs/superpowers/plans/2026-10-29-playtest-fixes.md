# Playtest frame pacing and grounded conversation fixes

**Goal:** Correct the user's two observed regressions while preserving quiet optional company.
**Architecture:** Measure rendering/frame spans before changing presentation. Keep social eligibility in the existing SocialLife ledger and ConditionEvaluator; authored Ink speech commits knowledge and relationship receipts.
**Scope:** Bug corrections requested directly on 2026-10-29; no additional design approval gate. Values below are implementation tuning, not user-specified numbers.

- [x] Reproduce premature menu topics/home invitation/unknown-friend request before fixes.
- [x] Profile full Main and isolate presentation cost; retain comparable before/after evidence.
- [x] Add shared personal/relay/home acquaintance gates using NPC-to-player familiarity/trust, elapsed days since heard introduction, and distinct meaningful social days.
- [x] Personal: one elapsed calendar day, familiarity4/trust1. Relay: both introductions at least two days old, familiarity8/trust2 each, plus the actual relevant story knowledge. Home: three elapsed days, familiarity30/trust6 and three meaningful social days.
- [x] Author once-per-day optional quiet company (3 familiarity/1 trust, existing daily cap); no spending/workshop requirement to build home eligibility and no repeated same-day gains.
- [x] Author Farid's neutral recipe reminiscence; recipe question requires actually heard provenance; follow-ups require the taught basics.
- [x] Verify negative and positive eligibility through actual compiled Ink, same-day repetition, next-day growth, multi-day gate boundaries, provenance and current-save restore. No automated suites; bounded disposable observations only.
- [ ] Independent review, tracked Ink/localization/import/Release build, exact-source CI, current Web observation, safe integration and retained complete corrected preview. Pre-alpha reset allowed; preserve unsupported save bytes.

Review focus: unreachable relationship thresholds without purchases; same-day grinding; actor identity and unknown third-party knowledge; loaded invitation/action chronology; equivalent scene/profile conditions for performance comparisons. No guaranteed user-device FPS inferred from software rendering.

Execution checkpoint: independent narrative review found one malformed-daily-ledger validation ordering issue, corrected and observed cleanly rejected. Independent presentation review found no blocker. Final exact-source build/CI/integration/archive provenance is recorded on the delivery PR to avoid modifying an already identified build.
