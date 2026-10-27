# Independent Visits and Orders Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline; one final fresh whole-branch review. No implementer agents. Design approved in conversation; proceed through the existing execution authorization.

**Goal:** Quiet independent corniche visits and visible, repeatable truthful orders.
**Architecture:** VisitorService owns visit/decision timers; ServiceSystem owns pending orders; Ink and nearby UI project the same order. Save migration extends visit state without replaying orders or story effects.
**Tech Stack:** Existing Godot4.7.2, GDScript, external JSON, Ink.
**Spec:** ../specs/2026-10-23-independent-visits-and-orders-design.md

## Global Constraints

- Preserve quiet gaps and at most four total people; opening is not an arrival trigger.
- Preserve old items/jobs/money/orders/Ink cursors; candidate restore never overwrites failed original.
- No automated tests added/run unless requested. Build/import and manual evidence only.
- Continue Native method in current work branch; publish separate preview under prior authorization, no main merge.

## Review Focus

1. Closed kiosk through time followed by opening: people may already exist; no timer reset or order wave.
2. Save during leisure, purchase consideration, pending order or active Ink: remaining time/identity/order/cursor preserved.
3. Actual preferred food differs from old fixed food: announcement, badge and recall agree; no duplicate order.
4. Furniture nearer than visitor, personal topic exhausted, out-of-hearing original announcement: pending order remains discoverable and askable.
5. Delivery, cancellation, departure, UI resize: no stale badge/choice or unintended story-topic consumption.

### T1 — Visit lifecycle and persistence

Files: visitor_service.gd, visit_state.gd, content/visitors.json, visitor validation, game_session.gd, save_codec/living_spaces_migration/living_spaces_save_validation.
Interface: visit shopping_state and decision_remaining; VisitorService.consider purchase only after independent arrival/delay; leisure marker distinct from service marker. Existing food_selector supplies currently available preferences at decision time. Saved revision6 explicitly initializes legacy visits, preserving all existing pending/served intentions. Weighted pool all eligible characters, random seed for new sessions, saved RNG for Continue.
- [ ] Replace forced spawns and open gate with elapsed independent bounded arrival clock and weighted pool; route nonbuyers to leisure markers.
- [ ] Add delayed, one-per-visit probabilistic purchase with no action on opening itself; preserve physical phase API and busy service-marker occupancy. No money/order until real decision.
- [ ] Migrate saved state to revision6; validate new state, cross-references and timer fields.
- [ ] Build/import, review closed/open and old Continue via ordinary UI. Commit.

### T2 — Truthful Ink and order recall

Files: narrative director, encounters/context Ink, visitors/amgad Ink, interaction router/target, new order conversation panel if needed.
Interface: common pending order context food_id/order_label. Explicit order announcement event cannot be substituted by venue comments; recall is a separate mode with pending-order precondition, character/variant memory saved through narrative topic history. Existing personal talk remains accessible.
- [ ] Use FoodRegistry menu_label for all order text, not old recipe stock labels or hardcoded intended foods. Preserve non-order arrival chatter.
- [ ] Add repeatable contextual ask-order selection with character-specific Ink variants and no consecutive repetition. Ensure exhausted personal topics do not hide recall. No new order placed by asking.
- [ ] Build/Ink compile and manual actual differing food / repeated ask / save Continue. Commit.

### T3 — Nearby badges and delivery

Files: spatial_captions.gd, content/foods.json/ui.json, README, notes, vision gaps.
Interface: nearby pending order badge keyed by visit ID, FoodRegistry presentation from actual order, no extra saved UI state.
- [ ] Draw compact icon + readable food name near character/captions, hearing-distance limited, valid while pending only, ignore mouse input, keep within viewport/HUD.
- [ ] Build debug/release; ordinary UI review at1280×720 and960×540, pending/asked/delivered and closed/open, actual old Continue. Record exact coverage and limitations.
- [ ] One final fresh review; fix material findings with build/manual evidence under no-tests constraint.
- [ ] Commit, export exact source, publish preview ZIP/release, download and match SHA256. No main merge.
