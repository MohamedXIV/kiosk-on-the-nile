# Ingredient lots and grades — 2026-10-30

Epic#35/task#38, feature-branch work after the approved shared contract and
CharacterLife foundation. No playable v2 delivery/version/changelog yet.

Raw material definitions declare family, grade and bounded quality. Initial
scope: standard existing raw ingredients; better/premium tea, better liver and
better potatoes, available from both market and supplier. True ingredient types
can retain different families; grades of the same type can satisfy the same
recipe while preserving their actual source definition. Existing derived
shawarma filling is a processed ingredient, not a newly acquired raw lot.

ItemStore stamps actual grants with immutable lot origin/acquisition game time,
grade/quality, source kind/reference and cost evidence. Starter stock is an
explicit free source; generic grants have unknown cost rather than pretending
that their source was a paid shop. Market/supplier quotes retain original money
authority. Bundle costs use equal-unit rational allocation (cost_minor/cost_units)
so the exact original integer price is retained without per-unit rounding;
this allocation is a builder default, not individual retail valuations.

Bag split/move/packing preserves source attributes. Inventory family queries use
actual matching item instances and deterministic older-first selection, without
copying the entire inventory/history for every requirement. Explicit item_id
selection remains supported by inventory; recipe UI selection is part of the
process/serving work. Reservations distinguish actual definition from required
family and validate both; partial consumption cannot consume an unrelated family.
Cooking records actual reserved quantities independently of original stack size,
so later quality averages don't accidentally weigh an entire unconsumed stack.

Current save candidates validate lot grade/source/time/cost and the owner
counterparts in actual shop/supplier receipts, including aggregate original-lot
conservation across current stock and consumed workflow inputs. Actual source
metadata remains immutable during ItemStore commits. This is consistency with
owner receipts, not a cryptographic guarantee against rewriting a whole save.

Arabic/English item/offer labels and inventory grade/received-day/approximate-unit
cost feedback are supplied. Higher grade's final food-quality contribution is
not claimed implemented here: process/output composition belongs to#39. No
freshness/expiry claim is inferred from acquisition time before#40 exists.

## Bounded evidence

[Inputs/logs](evidence/2026-10-30-ingredient-lots/) use real owners and disposable
controlled observations, not permanent suites:

- Baseline raw tea had no lot attributes. Current starter grant is standard,
  sourced and timestamped.
- Actual market journey bought2 premium tea +2 better potatoes, debiting860minor
  exactly as quoted. Padding fixture left one real rooftop storage unit; actual
  unpack split the purchased quantity while preserving origin/grade/time/cost.
- Real family reservation selected older premium stock before newer standard
  stock; partial consumption and release succeeded. Attempted acquisition-time
  mutation was rejected without changing live stock.
- Actual tea preparation consumed one unit and retained original six-unit stack
  evidence with consumed_quantity1. Full current JSON SaveCodec candidate passed.
- Resealed tampered cost rejected against the actual quote; duplicated origin
  quantity rejected by aggregate source conservation, not a generic parse error.
- Actual supplier phone/quote/agreement and credit delivery produced the chosen
  premium/better lots; source validation and complete current candidate passed.
  Controlled31-world-minute jump evaluated the recorded due delivery later;
  no natural walking/scheduling or long-term economy claim is made.
- English inventory projection showed premium grade, received day and2.80EGP
  approximate unit cost. Both locale catalogues pass existing validation.
- Pinned Godot4.7.2 tracked Ink/localisation/import/Web Release build passed,
 389 stable Ink references. No automated suites added/run. Native disposal
  ObjectDB/resource warnings remain recorded; no memory-leak acceptance claim.

Mandatory development save fields changed; no intermediate build is an old-save
upgrade. Preserve earlier files and finalise the actual schema/new-game guide,
version/changelog and verified preview at coherent completion#44. Final fresh
whole-feature-branch review remains after integration, not per owner task.

A follow-up groups frozen input quantities by material family (including repeated
requirements), validates frozen recipe shape before reading its inputs, and
rejects a resealed non-array input definition as invalid_workflow_definition
without an exception. Actual market/tea/current candidate and duplicate-origin
rejection remain observed with the shared12-actor registry. This fixes a
validation-order gap in the new input-evidence path.
