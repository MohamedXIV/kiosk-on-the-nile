# Character life and cooking v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Use checkbox steps and one final fresh whole-branch review, not implementer/reviewer agents per task.

**Goal:** A quiet, connected ingredient-to-batch-to-priced-portion-to-personal-memory loop.

**Architecture:** Extend existing authoritative owners. New focused services expose typed read projections and commands, while character choices run at coarse meaningful boundaries. World-time passive processing/aging and comfortable deliberate interactions remain distinct.

**Tech Stack:** Godot4.7.2/GDScript, external JSON, Ink1.2.1/inkgd, offline Arabic/English Web export.

**Spec:** [2026-10-30-character-cooking-v2-design.md](../specs/2026-10-30-character-cooking-v2-design.md).

## Global Constraints

- User approved the direction/intake on2026-10-30; routine engineering decisions continue without another permission round.
- Read AGENTS.md, docs/RELEASING.md and docs/GAME_VISION.md; usual simultaneous population about3–4 and empty periods.
- No automated suites added/run. The user's existing policy replaces skill TDD/suite steps with bounded disposable actual-domain observations, retained inputs/logs, and tracked build gates.
- Use Godot4.7.2 via tools/godot.sh and tracked build/package tools; no dependencies or renderer changes.
- Gradual freshness decline with comfortable grace before sale rejection; no offline wall-time aging.
- Preserve unsupported/corrupt-save bytes; unpublished historical migrations are not routine work.
- Final version/changelog/save-impact/preview bookkeeping only after coherent completion, not per issue.

## Review Focus

1. A restored no-purchase choice or satiety must not reroll/reset on re-entry; observe actual JSON roundtrip plus changed visit.
2. Lot splits and final batch portion must conserve stock, grade/source and age; observe mixed-grade partial use and duplicate final serve.
3. Sleep/travel past passive completion must produce one ready/holding state, not skip or burn the batch at an interactive boundary.
4. A pending accepted price/variant survives a menu edit; wrong addition/food or stale candidate must publish no stock/payment change.
5. Mere sight/handover/takeaway cannot invent tasted food or shared NPC/player knowledge; observe actor-specific source and comment consumption across Continue.

## File and interface map

- New `game/actors/character_life.gd` owns lightweight actor state/decisions; `game/content/character_life_validation.gd` validates authored schema. Data: `content/character_life.json`, typed descriptors in `content/foods.json`.
- New `game/items/ingredient_lots.gd` handles source/grade matching/evidence; stock remains ItemStore. Extend inventory, shop/supplier transactions and item/content validation.
- New `game/cooking/recipe_processes.gd` and `food_freshness.gd` handle process-specific candidate operations and pure age/holding projections. Extend existing workflow/batch/prepared-item/equipment/recipe panel, not a parallel engine.
- New `game/service/menu_service.gd` owns player menu; extend order/service receipts and localised menu controls.
- Extend `game/social/customer_experience.gd`, using a focused taste helper if needed, with once-confirmed consumption/value/favourite records and source validation.
- Extend semantic domain/query contract and authored Ink for grounded place/food/suggestion families. Reuse observation/spatial/narrative priorities.
- Wire each owner in GameSession, SessionConfig/manifest/content validation and SaveCodec. Current-save candidates restore every active owner before cross-links validate.

### Task1 — shared contract (#36)

- [x] Inspect owners and record the detailed spec, initial roster, clock/quote/taste semantics.
- [x] Fresh read-only builder check: no materially blocking question. Routine balance/UI choices remain builder decisions.
- [x] Commit contract/plan with intake, verify reference/whitespace/source isolation, update PR#45 and issue#36; integrate safely with current checks. Do not claim v2 delivered.

### Task2 — profiles, state and real contextual decisions (#37)

**Interfaces:** `CharacterLife.configure(data: Dictionary, foods: FoodRegistry, clock: GameClock) -> ActionResult`; `arrive(actor: StringName, visit: StringName) -> ActionResult`; `state(actor: StringName) -> Dictionary` (pure projection); `consider(actor: StringName, visit: StringName, offers: Array[Dictionary], expected: Dictionary={}) -> Dictionary`; `satisfy(actor: StringName, source: String, food: StringName, at: float) -> ActionResult`; snapshot/restore. Offer contains food_id/price_minor and later variant identity; expected contains personal known experiences only. `environment_provider` defaults neutral.

- [x] Retain a disposable actual-content observation of existing fixed purchase decline/no temporary state. Record expected new behavior before code.
- [x] Add strict authored profile/food descriptors and owner, saved RNG and once source/deadline records; invalid actor/finite/bounds references reject.
- [x] Wire VisitorService arrival/decision and replace _choose_food's separate chance/expanded repeated-ID pool with a single constrained weighted intent. Quiet decisions have bounded reconsideration; pending/requested/served remain stable.
- [x] Wire current persistence and semantic self state projections as needed; no automatic player profile disclosure or taste on handover.
- [x] Observe pure reads, actual no-purchase/candidate decisions, cooldown/re-entry, exact JSON Continue and malformed state rejection, neutral weather and low/high need differences.
- [x] Import/build appropriate gates, commit and ledger actual limits.

### Task3 — material lots and category grades (#38)

**Interfaces:** `IngredientLots.matches(definitions: Dictionary, actual: String, required: String) -> bool`; `stamp(definition: Dictionary, source_id: String, at: float, cost_minor: int) -> Dictionary`; `validate(item: Dictionary, definitions: Dictionary, now: float) -> ActionResult`; `quality(evidence: Array) -> float`. Item attributes hold immutable lot origin, acquired time, grade and cost/source. Family matching uses registered recipe requirements; reservations retain actual definition/item identities.

- [ ] Add category-specific grade/family content and actual market/supplier offers, neutral starter provenance and clear labels/costs.
- [ ] Preserve lot identity/age/grade through grants, bag splits, reservation/partial consumption and cooking input evidence. Do not merge distinct lots or consume the wrong reserved family.
- [ ] Observe mixed lots, selected grade cost, partial use/split and insufficient-stock/stale-candidate atomicity via real owners; validate saved lot references.
- [ ] Build/record/commit without new version or migration work.

### Task4 — process and batch generalisation (#39)

**Interfaces:** Keep `RecipeWorkflow.start/act/tick/job/progress_view` and equipment candidate contracts. Add typed process data and candidate-only helpers to RecipeProcesses; ItemStore owns created batches/portions and reservations. `PreparedItem.snapshot/from_dict` carries actual source batch/lot and serving fields produced here.

- [ ] Extend strict recipe validation and reusable preprocessing, passive cooking/holding and method/heat selection. Use existing capability/resource reservations; freeze recipe version at start.
- [ ] Author tea, revised liver batch + breaded variant, ful soak/slow cook and preserved shawarma/potato paths, with compatible raw ingredients/devices/knowledge.
- [ ] Expose button actions/heat/state/yield in existing recipe UI and both locales; future minigame inputs use the same act command, no mini-game code now.
- [ ] Observe actual raw reservation/consumption, shared-ingredient differing processes, busy equipment, cancellation and last-portion conservation; one night-to-morning passive completion without frame replay.
- [ ] Build/record/commit and state any unmet roster requirement truthfully.

### Task5 — freshness/holding and humane passive time (#40)

**Interfaces:** `FoodFreshness.view(item: Dictionary, now: float, definitions: Dictionary) -> Dictionary` returns initial/present quality, stage and sellable status without mutation; `transition(item: Dictionary, context: String, now: float) -> Dictionary` accumulates exposure then changes future rate. All splits/portions inherit original origin and exposure.

- [ ] Author comfortable recipe/category curves and storage/holding modifiers; wire final eligibility, preparation display and deliberate discard.
- [ ] Integrate passive phase-boundary handling for sleep/travel and held equipment; interactive reaction steps remain humane.
- [ ] Observe fresh/texture-declined/still-edible/unservable states and split/move/reheat no rejuvenation; actual clock speed and rare demand inform numeric rulings.
- [ ] Build/record/commit; don't add weather/thermodynamics/illness.

### Task6 — real offered variants, free menu prices and fixed quotes (#41)

**Interfaces:** `MenuService.configure(data: Dictionary, foods: FoodRegistry) -> ActionResult`; `set_price(variant: StringName, amount_minor: int) -> ActionResult`; `offers(available: PackedStringArray) -> Array[Dictionary]`; `quote(variant: StringName, additions: PackedStringArray) -> ActionResult`; snapshot/restore. Service snapshots the accepted variant/additions/final price/revision, and validates the actual handed portion. Extend CharacterLife offers without another probability roll.

- [ ] Author compatible serving formats/modes/additions, actual portion/extra/packaging input costs and player controls in both languages.
- [ ] Fix order quote at acceptance, preserve gifts as distinct, and atomically validate/fulfil/settle exact ordered content. Menu edit affects new quotes only.
- [ ] Observe same order across a price edit/current Continue, unaffordable/no-purchase choices, incompatible modifiers, wrong portion, final stock and no partial settlement on error.
- [ ] Build/record/commit with full receipt/source validation.

### Task7 — tasted memories, personal value and optional returns (#42)

**Interfaces:** CustomerExperience remains owner. Add confirmed taste source keyed by actual order/item/actor and at-time, plus bounded per-food/variant memory and expected personal view for CharacterLife. CharacterLife satisfaction consumes the same once source. Existing reputation remains a separate observed projection.

- [ ] Add delayed actual here-tasting while recipient remains available; no taste for takeaway unless authored later feedback explicitly confirms it.
- [ ] Record personal fit/paid value/gift distinction and bounded learned favourites/recovery, without leaking hidden lot grade or other people's knowledge.
- [ ] Add modest bounded personal return bias under existing arrival limits/cap; quiet independent reasons remain.
- [ ] Observe one actual consumption changes only that actor's needs/memory once, duplicate/retarget/future source rejection, no-taste leave/takeaway and personal expected choice after Continue.
- [ ] Build/record/commit and validate owner cross-links.

### Task8 — grounded Ink comments/suggestions (#43)

**Interfaces:** Add registered semantic domain queries over CharacterLife and actual CustomerExperience observation/taste sources; no arbitrary actor-specific predicate branches. Scoped consumption references the selected observed item/experience, with normal start/continuation/hearing receipts.

- [ ] Extend actual observed-place identity/revision without another global frame scan; distinguish first notice from moving the same object.
- [ ] Author/localise reusable new-item/food-callback/optional-suggestion families with relationship/context/cooldown, shared dialogue priorities and refusal/silence/postpone.
- [ ] Migrate the touched legacy venue/order comment family coherently; keep unrelated remaining encounter inventory explicit.
- [ ] Observe unseen/unheard/untasted denial, actual positive lines, own-person lineage, once per meaningful evidence after reload/reposition and no simultaneous chatter burst.
- [ ] Ink/localisation/import/Web gates, record and commit.

### Task9 — one connected verified preview (#44)

- [ ] Run one connected domain/browser play observation: market/supplier grade → actual batch/night → priced custom portion → confirmed taste → later eligible callback/optional return.
- [ ] Observe bilingual/current Continue/rejected-byte preservation and relevant existing social/home/workshop routes. Record exact scope and human natural-feel limits.
- [ ] Brief matching populated render/counter sample; deepen only for a material reproducible regression. Preserve batching.
- [ ] One fresh whole-branch review on the strongest available reviewer, one material fix pass with reproduction and observation; ledger minors/rulings honestly.
- [ ] Finalise actual new version, curated changelog, save revision/reset impact, guide and metadata, then tracked clean build and verified immutable complete package. No formal release/tag unless deliberately part of delivery.
- [ ] Safe exact-head checks/merge, successful post-merge evidence, append artifacts without rewriting prior entries/archives; update epic/roadmap and delete only this plan's ignored scratch after retaining evidence.
