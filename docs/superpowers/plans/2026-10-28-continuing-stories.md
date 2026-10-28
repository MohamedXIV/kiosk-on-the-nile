# Continuing stories and messages Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline; one independent whole-branch review after implementation.

**Goal:** Two multi-day stories with optional sourced questions and replies.
**Architecture:** Extend SocialLife's existing action ledger and companionship Ink, retaining one save owner and the personal conversation hub.
**Tech Stack:** Pinned Godot4.7.2, GDScript, Ink, external JSON.
**Spec:** docs/superpowers/specs/2026-10-28-continuing-stories-design.md

## Global Constraints
Read AGENTS.md, docs/GAME_VISION.md and docs/RELEASING.md. No automated suites; bounded observations/build gates only. User authorized autonomous inline execution; no additional design approval round. Preserve saves; revision18 reset notice. No home guests, increased attendance, migration/archive work, navigation change or permanent-release rewrite.

## Review Focus
- Wrong speaker/unheard predecessor must not deliver a message.
- Same-day follow-up and present-subject inquiry must remain unavailable.
- Duplicate/restore must not repeat delivery or rewards.
- Resealed mismatched endpoints, timestamps or knowledge provenance must reject.
- Both languages must name the correct source and topic.

### Task 1: Durable gates and messages
Files: game/social/social_life.gd, game/content/social_life_validation.gd.
- [x] Add optional next_day_after, absent_actor, message metadata gates and authoring validation.
- [x] Copy typed message metadata into action receipts; validate dependencies/time/endpoints/provenance on restore.
- [x] Observe unavailable early/wrong-speaker paths and current-save restore.

### Task 2: Two authored arcs
Files: content/social_life.json, content/social.json, content/encounters.json, content/stories/companionship.ink(.json), content/locales/{ar_EG,en}.json.
- [x] Add exam and radio opening/follow-up/request/reply/delivery actions, distinct sourced topic labels and postponement choices.
- [x] Compile shipping Ink and validate localization; observe both arcs with actual Ink over separate days, cancellation and repeats.

### Task 3: Delivery
Files: game/persistence/save_codec.gd, CHANGELOG.md, docs/RELEASING.md, docs/roadmap/STATUS.md, docs/notes/2026-10-28-continuing-stories.md.
- [x] Document revision18/new game without deleting saves; record PR14 integration and evidence.
- [x] Independent read-only review, resolve material findings; exact-source Release Web build/package and CI preview.
- [x] Open source PR and update #4/#5/#8 truthfully. Do not merge new PR automatically.

## Execution ledger
Task1 complete: typed receipts/day gates/authoring validation and native rejected-input observations.
Task2 complete: actual Ink arcs in both languages, postponement and explicit reply delivery, restored pending/completed receipts.
Task3 source/review complete: no Critical/Important findings; final exact-source build and PR/CI delivery recorded in the PR.
Ruling: reuse existing ledger rather than introduce a second message owner; this keeps ownership coherent but does not add a general inbox UI.
Ruling: no automated suites/TDD or historical migrations: user policy overrides skill defaults; verification is bounded native observation plus tracked build gates.
Ruling: fixed two minor source-attribution labels during delivery because clear source identity is this batch's explicit narrative requirement; observed their actual localized values, no extra suite.
