# Stabilization and offline localization slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans; native inline implementation, one final fresh whole-branch reviewer.

**Goal:** Fix the confirmed catch-up failure, bound repeated work, clarify owners and ship a bilingual offline UI/Ink slice before broader translation/new gameplay.
**Architecture:** Journal append order uses observation time while receipts preserve domain time. Derived due cursors avoid rescanning history. A focused financial dialogue adapter prepares chapters explicitly; a small modal coordinator owns screen focus. LocaleService resolves bundled catalogs over canonical Ink frames without advancing stories or modifying their effects.
**Tech Stack:** Godot4.7.2, GDScript, Ink/inkgd, external shipped JSON. Schema4/revision12.
**Spec:** `docs/notes/2026-10-25-structure-performance-ui-audit.md`, approved by user “تمام اعمل اللازم”; prior offline/intent-based localization decisions are binding.

## Global Constraints

- Preserve existing managed `work` checkout, no main merge. User authorization for source/artifact preview release persists.
- No automated tests added/run; compile/import/export and real UI/read-only observations, explicitly recorded gaps.
- No translation service/download dependency; ship ar_EG/en catalogs and fonts. English adapts intent while keeping financial offers/outcomes exact.
- Preserve canonical Ink frame/state, stable gameplay IDs, signed names/prices, historical heard text and archived published cursors.
- Keep world time running in menus. No global bus/ECS/kernel/UI framework replacement.

## Review Focus

- Legacy supply receipt+journal linkage after observation/domain timestamps separate; resume a blocked revision11 save without duplicate money/items.
- Derived cursors across pause/amend/old terminal occurrences and pending cash confirmation.
- Locale switch during a live choice must not advance Ink/create quotes/reapply effects or corrupt saved frame hashes.
- Modal replacement/back must restore focus without stopping world time or leaving hidden controls interactive.
- Missing/invalid translation IDs/parameters fall back safely; translated catalogs never own conditions or executable effects.

### Task1: Correct catch-up and bounded due work

**Files:** InteractionJournal, SupplierLedger, SupplyTransactions, SaveCodec/LivingSpacesMigration, SessionAdvance new time service, GameSession/LifeActions/Main, DeliveryService/AccountBook/AccountTransactions, ActorPresence.
**Interfaces:** `SessionAdvance.catch_up(frame)->ActionResult`; supplier receipt adds recorded_at, journal uses at=recorded_at and occurred_at=receipt.at; array position/unique event ID remain append sequence. Due cursors are derived caches, rebuilt on restore/contract revision, not new financial truth.

- [x] Migrate11→12 by locating original supply journal events, retain their at/text, attach receipt.recorded_at and event.occurred_at. Validate domains/recorded bounds and linkage. New supply transactions record observed time explicitly; preserve due dates.
- [x] Replace handwritten sleep orchestration with outcome-collecting SessionAdvance; surface failures without claiming time rolled back. Isolate unrelated motion/needs from supply failures in dependency graph, report new system failure signatures once.
- [x] Derive lease next-period and supplier next-due caches from validated history; invalidate contracts on sign/pause/restore, retain pending cash retries. Avoid financial candidate copying on no-event ticks. Cache merged actor definitions at configuration while preserving defensive copies and tuning labels.
- [x] Build `/tmp/kiosk-stability-core`; repeat audit collision through UI and save/Continue. Expected first and second deliveries each once, rent events plus supply event append cleanly, motion/needs continue, receipt due time unchanged. Commit.

### Task2: Clarify composition and modal ownership

**Files:** FinancialDialogue new narrative adapter; GameSession/NarrativeDirector, ModalCoordinator new UI service, Main/Hud/panels, SupplierPanel defaults.
**Interfaces:** `FinancialDialogue.prepare(chapter,actor)` mutates only on explicit chapter start; `context(chapter,actor)` pure view; effect delegates validated commands. `ModalCoordinator.activate(id)`, `close_active()`, `blocking()`, registered panel visibility/close callback.

- [x] Extract financial/supplier chapter preparation/context/effects, leaving session wrappers for existing consumers. Restore never prepares new quotes.
- [x] One blocking modal visible; hide dialogue/thought/interaction behind it, use common motion/participation/back policy. Supplier closure restores same call. Common UI theme/spacing remains Godot-native; fix supplier defaults/limits from content.
- [x] Build/UI overlay and Escape/focus checks at960×540/1280×720; clock continues. Commit.

### Task3: Bundled localization and canonical Ink presentation

**Files:** LocaleService/LocalizedNarrative new, locale JSON+manifest, supplier Ink archive/tags, InkRuntime/Frame, UiText/Title/Hud/SupplierPanel, NarrativeDirector journal metadata, settings preference.
**Interfaces:** `LocaleService.text(id,args,fallback)`, `set_locale(id)`, `changed`; canonical frames add optional loc_id/loc_args and per-choice loc_id, never translated text. LocalizedNarrative renders a copy for UI; journal stores actual shown snapshot with canonical text/ref/locale metadata when known.

- [x] Ship two validated offline catalogs; Godot TranslationServer integration with Arabic fallback and per-locale direction. Preserve setting in user preferences; Cairo font already shipped for both pilot locales.
- [x] Archive current supplier story using engine-normalized hash before tags. Add stable line/choice IDs and named captured amount/refusal reason parameters; English is authored adaptation. Choice tags remain presentation metadata; finite allowed tags stay validated.
- [x] Localize title/settings language selector, supplier sheet/terms/actions and live Fathi dialogue. Locale changes rebuild labels/view signatures only, preserve edited basket/quote/canonical Ink and signed terms. Older stories/history remain original-language fallback, explicitly not full English release.
- [x] Build/UI switch active choice ar→en→ar, accept exactly one real effect, save/Continue, fallback/RTL/LTR, no runtime translation service. Commit.

### Task4: Review, exact artifact and evidence

- [x] One fresh read-only whole-increment review; regrade/material fix pass only, no second review.
- [x] Exact debug/release export and actual release boot/Continue. Repeat the audit's release-browser samples with same limitations; no unmeasured speed claims.
- [x] Publish authorized preview source/artifact/prerelease, download ZIP and verify digest. Record delivered slice/coverage limits and unresolved broader translation separately. No main merge.

## Execution result

Completed as the bilingual pilot at product e9b816d. Single review/material fix pass; exact Debug/Release exports and GitHub digest verification recorded in [delivery note](../../notes/2026-10-25-stabilization-and-localization.md). Checked items record implementation plus the explicitly documented manual coverage, not exhaustive case verification. No automated tests or real-GPU/native profiling; full English and visual redesign remain subsequent work.
