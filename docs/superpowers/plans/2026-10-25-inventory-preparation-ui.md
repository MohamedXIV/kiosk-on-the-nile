# Inventory and preparation UI implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline; one fresh final whole-change review.

**Goal:** Organize and localize inventory, care and recipe sheets without changing gameplay or saved definitions.
**Architecture:** ItemText pure source-guarded projections plus small native SheetControls helpers; inventory owns storage/search rendering, RecipePanel composes separate care/job/recipe sections. RecipeWorkflow exposes a narrow read-only progress view, preserving existing commands and frozen snapshots.
**Tech Stack:** Godot4.7.2, GDScript, shipped Arabic/English JSON, existing Ink/save schema4/revision12.
**Spec:** `docs/superpowers/specs/2026-10-25-inventory-preparation-ui-design.md`.

## Global constraints

- User says continue approved UI rollout; retain isolated work checkout, offline catalogs/fonts and preview publication authorization. No main merge or repeated approval.
- No automated tests added/run. Use compile/import/export and actual UI/read-only observations; no fabricated saves/command bridge.
- Canonical item/recipe/step IDs, reservations, gameplay timings/actions, knowledge gates and historical text unchanged. Unknown/custom/frozen labels retain source fallback.

## Review focus

- Locale/search/filter refresh must not transfer items, start/cancel cooking, reselect sugar or interrupt cleaning.
- Every command targets stable actual item/container/job IDs; reserved ingredients cannot be offered for packing, stale state still validated by owners.
- Active frozen recipe/step labels keep their identity/source rather than indexes or mutable numeric thresholds; labels/requirements never grant eligibility.
- Live progress/time updates without rebuilding buttons every physics frame or copying complete job definitions; hidden sheets do not freeze the world.
- Empty home desk/storage, missing ingredients/equipment, full/partial bag transfer, held bowls, custom labels and both languages/resolutions retain readable fallback.

### Task1: Presentation catalog and shared read helpers

Files: locales, LocaleService guarded search variants, UiText translated errors, new ItemText/SheetControls; RecipeWorkflow progress view.
- [x] Add paired IDs for items/foods/recipes/stable steps/capabilities/care/actions/errors, with source guards for authored labels.
- [x] Pure item name/details/requirements/missing-reason helpers, cross-language guarded search variants. Narrow job progress query returns copies of scalar fields only; no save/schema change.

### Task2: Native inventory and preparation sheets

Files: InventoryPanel/RecipePanel, existing command connections retained.
- [x] Inventory search/storage-kind selection, container cards/capacity/empty states and reserved indicators. Stable callbacks, dirty refresh only on item/location/locale changes, retained scroll/filter/query.
- [x] Separate care, active job and eligible-recipe cards; ingredient/capability details, localized frozen labels and progress. Dirty structural refresh coalesced; bounded progress updates. No changed preparation/learning behavior.
- [x] Compile/import/Web export; actual UI on genuine save plus stock new session, Arabic/English,960×540/1280×720, pack/unpack, empty/non-recipe desk, active preparation if reachable. Record gaps.

### Task3: Review and delivery

- [x] One fresh read-only review, one material fix pass; no re-review. Exact Debug/Release exports and actual Release boot/Continue.
- [x] Full stock offline ZIP/licenses/run guide; publish preview source/artifact/prerelease, download verify SHA/BUILD. Record coverage/limits and no main merge.

## Execution result

Implemented at producta07aedb with one fresh review and one material fix pass. [Delivery notes](../../notes/2026-10-25-inventory-preparation-ui.md) contain actual UI/build coverage, genuine active-save observations and explicit remaining cases. Checked items represent recorded coverage, not an exhaustive matrix; no automated tests or main merge.
