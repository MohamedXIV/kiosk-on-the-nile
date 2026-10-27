# Notebook UI implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline; one fresh whole-change reviewer at end.

**Goal:** Make the notebook readable and searchable in Arabic/English while preserving heard history and financial truth.
**Architecture:** Pure NotebookView projections over existing owners; NotebookHistory owns filters/paging, NotebookAccounts owns financial subviews, Notebook composes these and refreshes only visible content. Locale catalogs own presentation text.
**Tech Stack:** Godot4.7.2, GDScript, shipped JSON catalogs, existing Ink/save schema4/revision12.
**Spec:** `docs/superpowers/specs/2026-10-25-notebook-ui-design.md`.

## Global Constraints

- Existing work checkout, no main merge; offline shipped language/fonts. Preserve custom names, signed historical names/amounts, heard text and canonical Ink state.
- User said start; continue inline without repeat design/permission questions. No automated tests added/run; build and actual UI checks only.
- Search/filter/paging/tab state is local UI, no schema change. Unknown history/notes retain truthful source fallback.

## Review Focus

- Selecting a person includes player replies in their conversation; day/channel/query combine predictably.
- Filter metadata, page and selected tab survive locale refresh/reopen; empty results and removed values do not index invalid items.
- Locale changes do not mutate canonical receipt/history/knowledge, prepare quotes or replay effects.
- Long history/receipts are bounded per page and entries copied only on journal revision; active world clock refreshes account deadlines.
- Custom actor names and unmatched source notes stay unchanged; unknown tabs/empty lists remain usable at960×540/1280×720.

### Task1: Pure localized notebook views

Files: new `game/ui/notebook_view.gd`; locales ar_EG/en, ui notebook_layout; LocaleService source-matched resolver; InteractionJournal derived revision.
- [x] Add validated layout/page-size/reference bindings to content; paired semantic catalogs for notes, names, stages, empty states, history and financial wrappers.
- [x] Project learned notes/source links/known people and financial summary/receipts without mutating owners. Preserve AccountText.date used in canonical Ink; never localize it globally.
- [x] Build import/export; inspect errors, fix and commit with Task2 if shared UI interfaces require it.

### Task2: Focused notebook components

Files: new NotebookHistory/NotebookAccounts, rewrite Notebook, Hud/Main binding.
- [x] History participant/day/channel/search/order filters and bounded pages; stable metadata and original heard text. Source links select real chapter.
- [x] Native four-tab sheet, fact/people cards and summary/receipt selector. Explicit empty states, focusable local controls and locale-aware directions.
- [x] Bind once per session; refresh visible notebook, retain filters/tab, copy journal only when changed. Remove old frequent AccountText ledger rendering.
- [x] Build and actual UI: Arabic/English, empty/new session and real saved dialogue/effect history, filter/search/reset, source navigation if available, reopen, changing world time, summary/receipts,960×540/1280×720. Record unsupported cases.

### Task3: Review and delivery

- [x] One fresh review, one material fix pass; no re-review. Exact Debug/Release export and actual Release boot/Continue.
- [x] Commit product; package full stock external content/offline catalogs/licenses/run guide, publish authorized preview source/artifact/prerelease, download verify SHA/source. Record evidence/limits. No main merge.

## Execution result

Implemented inline with one fresh review and one material fix pass. Exact product source420cfe0; [delivery notes](../../notes/2026-10-25-notebook-ui.md) record actual UI/build coverage and the unexercised cases. No automated tests, main merge or full-game English claim. Completion checks represent the recorded coverage, not an exhaustive UI/state matrix.
