# Web save durability implementation plan

> Execute inline using superpowers:executing-plans; the user's next-work instruction authorizes this bounded bug fix. Preserve native execution and do not repeat approval prompts.

**Goal:** Report Web save success only after the requested snapshot is present in browser storage.
**Architecture:** Existing SaveStore remains the sole writer; a small Web-only readonly acknowledgment adapter informs SaveCoordinator and localized feedback.
**Tech stack:** Godot4.7.2/GDScript, JavaScriptBridge, browser IndexedDB, offline JSON locales.
**Spec:** docs/superpowers/specs/2026-10-27-web-save-durability-design.md

## Global constraints
No game/save schema/Ink changes, new save authority or patched engine bundle. Explicitly pin/validate backend assumptions. Existing native backup behavior. External validated timing, no fixed safe-wait claim. No automated suite; bounded runtime/browser observations and build only. One final fresh reviewer, one material fix pass. One final artifact on existing artifacts, no main merge.

## Review focus
Never acknowledge stale/different bytes or a failed transaction. Never create an absent backend by probing it. Serialize repeated/deferred saves, including retries after failure. Keep unload warning through unconfirmed failures and release it only for confirmed bytes. Preserve native completion and avoid double notifications.

## Tasks
- [ ] 1. Reproduce boundary and record engine/API evidence. Inspect actual persisted bytes around a real Save before product changes; record narrower claims if the timing race varies.
- [ ] 2. Add game/persistence/web_save_ack.gd as isolated Web-only observer. Integrate SaveCoordinator in-flight/pending state and signals; preserve Store writer/native behavior. Observe exact acknowledgment, wrong bytes, error/timeout and retry through bounded temporary fixtures.
- [ ] 3. Add validated external UI timing and Arabic/English pending/failed feedback. Wire one notification path in main.gd; allow persistent ToastStack feedback. Build-only gate, then actual Chrome rapid Save/ack/reload/Continue and delayed-ack unload warning. No gameplay bridge or synthetic save.
- [ ] 4. Fresh whole-diff review, one material fix pass, exact-source Release, complete ZIP, independent download/content/hash/CRC checks, issue10/roadmap/notes. Keep source and artifacts separate; record limitations.

Preflight/self-review: Store returns after MEMFS rename, coordinator owns a single durable request, adapter acknowledgment must refer to the exact captured bytes; UI success occurs only through coordinator.completed. All spec requirements map above. Native observer availability must never change native SaveStore paths.
