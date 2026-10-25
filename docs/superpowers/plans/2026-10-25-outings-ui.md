# Outings UI implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline; one fresh final review.

**Goal:** Clean offline bilingual shopping, travel and visitor action sheets.
**Architecture:** Native existing panels plus pure source-guarded OutingText projections, bounded ShopService revision getter and shared SheetControls. Owners keep all gameplay commands/state.
**Tech Stack:** Godot4.7.2, GDScript, bundled ar_EG/en JSON, Ink, schema4/revision12.
**Spec:** ../specs/2026-10-25-outings-ui-design.md

## Global constraints

Established user authorization: continue rollout and publish preview without main merge. No automated tests added/run; compile/export and actual input observations. Preserve quote identities/amounts, visitor availability, canonical Ink/history, quiet population and world time. Custom labels retain source fallback.

## Review focus

Locale switching must preserve reviewed quote/quantity without issuing a quote or purchase. Stock changes invalidate review. Search and current selection must not purchase. Disabled recall/talk remain bound to actual owner eligibility; visitor departure closes sheet. Guarded data labels use actual stable IDs; custom definitions retain source. Panels wrap/scroll at both target viewports.

### Task1: Projections and shopping
- [ ] Add OutingText guarded offer/route/topic projections and paired catalogs; scalar shop revision query.
- [ ] Rework shopping list/search/details with explicit review/confirm and locale-safe quote state; native wrapping product cards.
### Task2: Travel and visitor sheets
- [ ] Localize journey/menu actions and visitor topic/order presentation; bounded polling, retained owner commands and modal contracts.
- [ ] Compile/import, Debug and Release export; actual browser actions and read-only observations, record gaps.
### Task3: Review and delivery
- [ ] Fresh read-only whole-change reviewer, one material fix pass; exact exports/Release boot.
- [ ] Stock offline ZIP and verified GitHub source/artifact/prerelease; delivery record with evidence/limits.
