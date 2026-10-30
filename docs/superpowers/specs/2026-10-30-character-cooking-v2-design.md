# Character life, cooking and customer experience v2

Implements the direction approved by the user on 2026-10-30, following
[the requirements intake](../../notes/2026-10-30-character-cooking-v2-intake.md)
and epic #35/tasks #36–#44. The implementation choices below are engineering
decisions within that direction, not additional statements attributed to the
user. Runtime details are verified incrementally; this document is not a
delivery claim.

## Intent, approaches and scope

Keep the Egyptian corniche a quiet place to live and meet people. A person can
come without buying, favour a dish without always ordering it, and notice what
they actually experience. The player can prepare small batches, choose how to
serve them and set a price, while food and memories retain their history.

The chosen approach extends existing data-driven services with coarse-time
state and feasible weighted choices. Extending fixed per-person purchase rolls
would multiply exceptions and leave preferences disconnected from experience.
A full agent simulation/planner for off-screen daily lives would cost more,
change the requested scope and threaten the quiet pacing. No language model,
network service or new dependency is introduced.

First coherent slice: existing tea, shawarma and potato recipes remain usable;
Alexandrian-style liver becomes a cooked batch with later serving; a breaded
liver variant shares raw liver but uses another process; ful demonstrates a
soak/slow-cook overnight process; fried potatoes demonstrate earlier texture
decline. Coffee is an optional grounded suggestion for future content, not a
promised recipe in this slice. Existing illustrations in the intake are not a
universal claim about Egyptian culinary practice.

No seasons, physical thermodynamics, illness, fuel/fire simulation, actual
minigames, permanent new cast, automatic quest generator, global live economy,
forced crowd or universal migration of the remaining 29 narrative encounters.

## Authority and stable identities

| Data/state | Authority | Stable identity |
| --- | --- | --- |
| Authored traits/need policy | `character_life` content | registered character ID |
| Temporary needs, decisions, satisfaction sources | `CharacterLife` | character + actual visit/order ID |
| Food descriptors/flavour/category | `foods` content / `FoodRegistry` | food ID |
| Ingredient variants/grades | ingredient content / item definition | definition ID + grade ID |
| Owned ingredient lot, vessel, portion | `ItemStore` | item ID; immutable source-lot/batch ancestry |
| Recipe, process and device reservation | `RecipeWorkflow` | recipe ID/version + job ID |
| Current menu and price revision | `MenuService` | food/serving variant ID + menu revision |
| Agreed order/quote/handover/payment | `ServiceSystem` | order ID, exact offered variant/quote |
| Personal tasted/value/place memory | `CustomerExperience` | character + actual experience/order ID |
| Heard words and social eligibility | existing semantic/Ink owners | actor roles + observation/experience evidence |

Do not copy authoritative state into Ink flags. Read projections may reference
another owner's identity but must not mutate it. New content validates before
bundle activation. Saved authoritative data validates before candidate install.
Prepare all affected owners, recheck revisions, then publish synchronously with
notifications deferred; failure must not spend stock/money or leave half a
quote/portion. No awaits or user callbacks inside publication.

## Character profiles and lightweight state

`character_life` contains `policy` and `profiles`. Every existing visitor has a
profile. A profile includes typed `food_weights`, `category_weights`,
`temperature_weights` (`hot`, `cold`, `ambient`), preferred spice range,
preferred daily window, future `thermal_affinity`, price sensitivity and
bounded initial ranges/rates for `hunger`, `thirst`, `tiredness`, `social`.
Preferences are authored biases; diet/spice hard limits are explicit and never
inferred from a small weight. Initial anonymous non-buying actors remain valid.

State per stable character: four needs in [0,1], last observed world minute,
initialised flag, most recent visit/decision, next decision boundary, decision
count and deduplicated satisfaction sources. `profile(actor)` exposes authored
self traits to domain/semantic queries, not an automatic player notebook entry.
`state(actor)` advances analytically to now then returns a copy.

Initialise once using the visitor RNG, not on every entry. Off-screen changes
use capped elapsed-time arithmetic: hunger/thirst rise, overnight/rest context
reduces tiredness, quiet time gently changes social inclination. No per-frame
simulation of every registered character and no wall-clock/offline aging.

At a meaningful buying boundary, obtain feasible menu candidates and include a
positive quiet/no-purchase alternative. Weight each candidate by actual need,
authored food/category/temperature/spice fit, expected remembered value and
price sensitivity. Untried quality uses authored neutral expectation, never
hidden actual stock grade. Remembered favourites bias without guaranteeing.
One weighted selection replaces both fixed purchase/reputation rolls; do not
multiply several independent chances that silently suppress all custom.

Decision identity is `(character, visit, index)` with a bounded reconsideration
cooldown. Store the chosen result and next boundary, including no purchase.
Loading does not reroll; different visits do not erase satiety. Menu changes may
invalidate an unaccepted candidate and schedule later reconsideration, not an
immediate retry storm. Keep pending requests/orders stable. One paid/gift
service per current visit remains the default cap.

Food/drink satisfaction is source-backed and once-only; hunger is not reduced
by merely choosing or accepting a request. Social/quiet intentions bias existing
companionship eligibility and leaving/rest choices without inventing dialogue,
teleporting the actor or forcing a conversation.

An environment provider returns neutral thermal context initially. Hot/cold
drink preferences work without weather. Unknown/invalid inputs fail closed,
not silently become another person's profile.

## Ingredient lots and grade

Grade is category-defined, not a compulsory four-step ladder. Use standard/good
produce/liver and a richer authored tea range initially. Different definition
IDs can represent true ingredient types; grade IDs describe quality within one
type. A recipe input can accept an authored family while preserving the exact
source definition/grade consumed. UI lets the player choose available lot/type;
a deterministic default uses suitable older stock before newer stock.

Every acquired ingredient carries a lot record with origin item ID, acquired
game minute, grade, original unit cost and purchase/grant reference. Initial
stock has explicit starter source and neutral standard grade. Shops/suppliers
grant actual chosen grade; affordability uses the displayed integer-minor price.
Splitting/unpacking/moving copies origin and acquisition age; differently graded
or aged lots never silently coalesce. Reservations identify item ID/quantity,
and all quality calculations use consumed evidence, not present catalogue price.

Input grade and freshness are separate. Better material can improve attainable
preparation quality but never repairs burning, wrong method or excessive age.
Quality composition is bounded, explainable and data-configured: technique,
input quality and existing hygiene/mood consequences remain distinct evidence.

## Recipe processes, batches and serving

Keep `RecipeWorkflow.start/act/tick` as public commands. Add reusable typed
process-step data for preparation/soak, passive cook, batch hold and assembly.
Method is an authored enum (`saute`, `fry`, `grill`, `boil`, `simmer`, `roast`,
`brew`); heat level (`off`, `low`, `medium`, `high`) is a separate choice with a
recipe-defined good range. Equipment capability remains the actual feasibility
gate, not a decorative recipe label. A neutral passive timer cannot use a
device already reserved by another batch.

Raw inputs produce one persistent batch/vessel with job/source evidence,
initial quality, ready time, yield and remaining portions. Serving consumes
one portion and real bread/sauce/cheese/packaging quantities. A batch does not
become an entire inventory stack of independent portions at every read. Final
portion is consumed exactly once; cancellation never recreates consumed raw
material. Definition/version is frozen at start as in the current workflow.

Separate base recipe, serving format (`sandwich`, `plate`, `cup`), consumption
mode (`here`, `takeaway`) and compatible additions. Authored combinations only;
do not enumerate the cross-product every frame. Cooked-in spice is immutable;
extra serving spice can raise it, and cannot make a hot batch mild. Existing
sugar selection becomes the drink's serving modifier with actual provenance.

New liver processes use raw liver family + researched additional ingredients;
the batch recipe is not the former two-sided flip-on-demand sandwich. Breaded
liver has an explicit preparation/fry path and food identity. Ful soaks before a
low slow-cook stage; soaking changes final technique potential. Small batches
are valid; authored yields/costs must not force cooking a whole day's sales.

`PreparedItem` gains optional production fields once their producers exist:
source batch/lot evidence, initial quality, prepared/ready time, holding history
and serving variant/additions. Keep legacy read views for untouched callers
only while their equivalent owner data is canonical, never two quality truths.

## Clocks, freshness and comfortable interaction

World time is the sole age clock. Passive soaking/slow cooking/holding spans
sleep/travel by analytic elapsed intervals. Interactive steps use the existing
reaction-time domain and comfortable windows; a midnight boundary neither
resets nor ruins a batch. A sleep jump processes each relevant phase boundary
once; do not replay every skipped frame. The last passive stage can finish and
enter holding without requiring the player to wake at an exact second.

For this slice, unattended slow cooking is an abstract supported process on
usable equipment; no house fire, fuel or illness simulation is implied.
Equipment remains occupied during the authored active/holding phase, unless a
batch is explicitly moved to suitable storage. Moving an active cook pauses or
rejects according to the process; it does not silently continue without heat.

Freshness records accumulated age/exposure segments with storage context.
Recipe curves have a generous fresh interval, gradual quality decline and a
later unservable boundary. Fried potatoes lose crispness sooner than a held pot
meal, but crossing the first texture boundary does not immediately forbid sale.
The existing one-world-minute-per-second speed must be part of play balancing.
Exact initial durations are builder balance choices, recorded with observation
evidence; do not copy the illustrative ten minutes as ten real seconds.

Cold/hot holding modifies future age rate, without undoing accumulated exposure.
Splits/portions/reheat inherit age and original quality ceiling. Derived quality
is computed at interaction/visible UI refresh; never rewrite every item every
frame. An unservable item gives clear localised feedback and deliberate discard,
not silent deletion. Palatability and actual kitchen safety are different;
game curves are not food safety instructions.

## Menu, quotes and payments

`MenuService` owns current enabled authored variants and integer-minor prices.
The player can change any displayed price within the supported nonnegative
integer range; cost/margin is advisory. Zero is an advertised free price, while
personal hospitality remains a distinct deliberate settlement with its existing
relationship rules. High prices can attract nobody; there is no guaranteed
profit, forced order or automatic price optimiser.

At request acceptance, ServiceSystem snapshots food, variant, additions,
base/final price, menu revision and quote identity. A menu edit affects only new
quotes. Revalidate inventory and ability to fulfil at the appropriate command,
without silently substituting another meal or retroactively changing price.
Handed item must match food/format/modifiers and sellability; payment uses the
accepted quote. Tips retain an explicit bounded policy, never an unannounced
price change caused by quality. Owner receipts retain the actual final payment.

A small menu/pricing panel and recipe/stock controls expose these choices in
Arabic/English. Detailed implementation names/layout are builder decisions;
implementation labels, internal IDs and diagnostic reasons stay out of normal
player flows. No modal micro-management or repetitive required confirmation.

## Personal experience, return demand and narrative

Extend CustomerExperience rather than parallel reputation. Record the actual
order/portion/variant, price paid and initial/present quality, individual fit and
observed environment. A gift can be tasted and liked, but is not a zero-price
paid value sample. Ignore hidden material grade/margins when choosing before a
first taste. A bounded mean/recency history can form or soften a learned food
favourite; a single gift does not overwrite authored identity permanently.

This slice abstracts tasting after a short coarse game-time delay on actual
here-service while the recipient is still present. Leaving before that point
records handover, not taste. Takeaway records service and only grants taste if
a later authored feedback/experience event confirms it; no automatic omniscient
memory of off-screen eating. Satisfaction and learned preference commit from
the same once-only tasting source. A malformed/repeated event cannot feed the
NPC twice or grant another experience. Saved source links revalidate the actual
order, recipient, handed item and chronology.

Arrival scoring may include a modest bounded personal return bias, alongside
existing availability/day limits and fresh/quiet independent visit reasons.
It must not fill capacity or turn all visits into commerce. Recovery from poor
experience is possible; failed early sales cannot permanently lock out demand.

Observation records identify a placed item and meaningful appearance revision,
first actual seen date and last consumed comment evidence. Merely purchasing an
item, moving the same chair or loading a save does not create new novelty.
Reuse spatial awareness/CustomerExperience visibility instead of a new global
per-frame scan. Food callbacks refer to the actor's own confirmed taste source.

Extend generic semantic provider/query data for self traits/state, observed
addition, own taste and optional missing-menu suggestion. Appropriate relation,
acquaintance, context and cooldown gate authored Ink families. Ink owns the
words and player responses; runtime owns eligibility and once evidence. A
suggestion never grants recipe knowledge or forces a quest/purchase. Keep
silence, postponing, walking away and existing deeper-story priority. One short
autonomous comment opportunity at a time, with per-actor and global cooldown.

## Persistence, validation and verification

Persist each new owner's state and RNG/decision deadlines. Restore under a
candidate session; validate typed finite/bounded values, actor/catalog/grade
references, source chronology, quote/receipt consistency, conservation and
cross-owner links before activation. Data changes require a new pre-alpha game
where current schema cannot honestly represent them; no historical migrations
or archived Ink graphs solely for this unpublished batch. Preserve unsupported
primary/backup bytes and clear new-game feedback.

New owner data may be integrated with mandatory fields before the final schema
revision bump; no intermediate candidate is delivered as an accepted old-save
upgrade. Decide the actual revision and game version once the coherent batch is
verified, and update changelog, guide and metadata then, not per task.

No automated suites added/run under the user's existing policy. Use tracked
Ink/localisation/import/Web build gates and bounded disposable native/browser
observations with retained inputs/logs. One final fresh whole-branch review and
one material fix pass. A short matching populated-scene draw-call/frame-time
and existing opt-in counter sample guards the user-confirmed smoothness;
deeper profiling only for a material reproducible regression. No renderer
changes are required by these features.

Acceptance connects real purchased grades, actual batch processing, compatible
serving at a fixed player price, confirmed personal tasting, later callback and
optional return. Also observe no-purchase visits, overnight progression,
graceful texture decline, last portion, low stock, busy equipment, pending-price
edits, new current Continue and preserved rejected saves. Existing social/home/
workshop/cooking routes retain relevant acceptance coverage. Natural feel and
indefinite economy remain the user's judgment, not a script's guarantee.
