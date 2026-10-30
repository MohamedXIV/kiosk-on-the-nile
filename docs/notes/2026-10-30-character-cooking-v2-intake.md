# Character life and cooking v2 — requirements intake

Recorded 2026-10-30, Africa/Cairo. Source inspected: main
`ae643b33fff2e9951deed114db47dd64a5b8ca5d` (0.3.0-prealpha.1,
save schema4/revision21). Parent: [epic #35](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/35).

**Status: direction and roadmap approved by the user on2026-10-30.** Detailed engineering contract: [character/cooking v2 design](../superpowers/specs/2026-10-30-character-cooking-v2-design.md); [execution plan](../superpowers/plans/2026-10-30-character-cooking-v2.md).

Historical intake status: This is not an
approved detailed design, implementation plan or claim that v2 already exists.
The playable preview remains unchanged. Version/changelog/save decisions belong
at the end of a coherent implemented batch, as the user requested.

## Feedback and decisions from the user

- Rendering now feels clearly smooth in the user's actual playtest. Preserve
  that result with a short representative check, investigating deeply only when
  necessary. This accepts the specific smoothness correction, not every remaining
  pacing, visual, world-identity or seating criterion in issues #6/#7.
- Purchases feel rare. Do not immediately increase arrival/purchase rates: this
  may suit the opening, and contextual character intentions are replacing the
  present purchasing model.
- Named characters need authored metadata and temporary state, with lightweight
  contextual weighted choices rather than realistic full-life simulation.
- Preferences include particular foods/drinks, spice, hot/cold drinks, day/night
  and future hot/cold-weather affinities. State includes hunger, thirst,
  tiredness and inclination for talk or a quiet sit. Preferences and state are
  different; wanting a cold drink is not the same as feeling hot.
- Comments should fit existing systems: notice actual kiosk additions when the
  relationship/context allows, discuss food/drink experiences, and occasionally
  suggest an optional addition such as coffee.
- Weather/seasons can wait; provide an input boundary for later use.
- Recipes need known instructions, ingredients, preparation equipment and time,
  cooking equipment/method/heat and time, and serving. Shared ingredients may
  produce different recipes through processing, additions or presentation.
- Support dishes versus sandwiches, eat-in versus takeaway, and compatible
  sauce/spice/cheese additions. Initially use buttons; retain a boundary for
  future minigames to submit the same commands/results.
- Cooked batches have portions and declining eating quality. Long preparation
  such as soaked beans and overnight slow cooking should be possible.
- Ingredient types/grades vary by category, bought at market or from supplier.
  A uniform economy/premium/luxury ladder for every ingredient is not required.
- The player freely chooses selling prices. Food quality, price/value,
  cleanliness, the place and relationships influence optional return custom.
- A person's own good food experiences can become learned favourites and later
  dialogue; they should remember what they actually ate.
- **Explicit follow-up answer:** prefer gradual decline and a comfortable grace
  before blocking sale, rather than short spoilage windows and demanding waste
  management. Balance batch sizes/windows with rare buyers and a quiet game.

## What already exists, and what does not

| Concern | Inspected foundation | Missing generalisation |
| --- | --- | --- |
| Profiles | `content/visitors.json`: named actors, food weights, visit windows, purchase/seating chances | Typed flavour/category preferences, budget sensitivity, separate temporary state and learned favourites |
| Buying | `VisitorService._consider_purchase`, `GameSession._choose_food`: fixed purchase roll, available food, authored food weights, second reputation roll | One contextual choice with useful no-purchase alternatives and bounded reconsideration |
| Memory | `VisitorHistory`: bounded service records; `CustomerExperience`: actual food receipt, observed environment/wait, last food/visit, reputation | Variant-specific repeated taste/value memories that influence personal future decisions |
| Cooking | `RecipeWorkflow`: equipment/knowledge/inputs, steps, reservations, input evidence; shawarma prepare/cold-wait/batch-heat and assembly | Reusable preprocessing, method/heat axes, varied batches and yields, separate serving |
| Stock | `ItemStore`, inventory reservations, source grants, shops/suppliers | Lot/grade/freshness persistence through purchasing, moving, splitting, consuming and output evidence |
| Prepared food | `PreparedItem`: food/recipe/sugar and four quality grades | Batch/portion ancestry, serving variant/additions, age/holding and present eating quality |
| Pricing | `ServiceSystem.place_order` snapshots catalogue price/tips | Player-owned menu and exact accepted variant quote, protected from later price edits |
| Dialogue | Semantic policies, per-knower provenance, scoped social memory; existing venue/order Ink | Reusable observation/taste/suggestion families grounded in the right evidence |

The current purchase path can mark a visitor `declined` after a failed fixed
roll or no selected food, normally ending buying consideration for that visit.
Selection also restricts candidates to currently available authored preferences
and applies a reputation probability. These are concrete contributors worth
reviewing; they are not a measured diagnosis of every rare purchase seen by the
user. No chance or arrival values are changed in this intake.

The game currently advances one world minute per real second by default.
Consequently an illustrative ten-minute freshness window must not blindly become
ten real seconds of sales pressure. Existing short cooking interactions already
distinguish presentation/simulation time from passive calendar waits.

## Recommended direction to turn into a detailed design

Use data-driven profiles and recipe processes, small runtime state and
event/coarse-time decisions. First reject infeasible actions, then weight
feasible food, drink, social company, quiet rest and doing nothing. Preserve the
existing distinction between coming to the corniche and choosing to buy.
Full simulation of off-screen daily lives is outside the requested scope.
Extending fixed per-food/per-person rules would leave the same maintenance
problem as new recipes and characters arrive.

Reuse existing owners. Profiles describe; runtime state remembers; inventory
owns lots/batches/portions; workflows own processing; the menu owns current
offers; service owns an accepted quote/receipt; customer experience owns actual
observed/tasted results; semantic providers expose those facts to authored Ink.
The detailed design must settle each boundary and atomic publication before
implementation, rather than maintaining duplicate truths in dialogue flags.

Separate four things that a single quality number cannot explain: input and
preparation quality, present freshness/holding, fit to the person's taste, and
value for the price they accepted. Ingredient grade is not freshness, an
expensive ingredient is not everybody's favourite, and someone cannot know a
new dish's actual quality without trying it or hearing a grounded report.
An NPC can query their own authored preferences/state; that does not reveal
their profile to the player or other NPCs. The existing service receipt records
handover, not a separate simulated eating action: the detailed contract must
define the lightweight event that counts as tasting, including truthful handling
of takeaway or refused food, before granting a taste memory.

Separate the recipe, batch, served portion and menu offer. A mild request cannot
remove chilli already in the cooked batch. Sauce/cheese/bread/packaging use real
stock, with authored compatible combinations rather than every imaginable
permutation. Freeze the final quote when an offer is accepted; later menu edits
apply to new offers. Personal gifts remain explicit.

Proposed defaults, **not user decisions**: aging uses game time, not time while
the app is closed; inactive people are updated analytically at meaningful
boundaries rather than ticked everywhere; heat/weather input is neutral until
implemented; blocked food has clear localised feedback and deliberate disposal,
without medical/illness simulation. Cold/hot holding is an abstract capability,
and splitting, portioning, moving or reheating must not reset accumulated age.
Sleep/travel and long passive cooking need explicit boundary handling, not
replaying thousands of simulated frames. Pending action windows stay humane.

Comments and suggestions must require actual sight/taste/hearing evidence,
relationship/context and cooldown/consumption rules. Buying furniture elsewhere
does not make every NPC aware of it. Repositioning an already noticed chair must
not create infinite novelty. A coffee suggestion is optional conversation, not
automatic recipe knowledge, an enforced quest or an unlock trigger. Ink owns
the authored words; runtime selects eligible opportunities with bounded chatter.

## Proposed coherent work groups

1. Detailed contract and first playable slice: owners, data, clock domains,
   recipe scope, serving/quote semantics, memories and acceptance examples.
2. Foundations that can be developed independently once that contract settles:
   character profiles/state and contextual intentions; ingredient lots/grades;
   process/batch extensions; menu/quote model where its interfaces are stable.
3. Connect freshness/holding/overnight work and actual serving/customisation;
   personal taste/value memory and return demand; grounded Ink comments.
4. One connected playable delivery, including day-to-night progression,
   remembered custom, optional buying, current saves, Arabic/English and a short
   representative performance comparison. Final version/changelog/save-impact
   decision and immutable preview follow verification.

Representative candidates are tea, two researched liver variants sharing core
ingredients, an overnight bean process and a fried batch with earlier texture
decline. This roster is a proposal to agree in the detailed design, not a claim
that coffee, sausage, taameya and all regional liver variants are already in
scope or implemented. Candidate breadth should exercise real differences rather
than merely renaming the same workflow.

The 29 remaining unconverted narrative encounters from the previous epic remain
working and inventoried. Convert relevant venue/service families coherently
when this work touches them; do not claim an unrelated universal migration.

## Culinary research and gameplay abstraction

The user's recipes are explanatory examples, not immutable instructions. Sources
already show meaningful regional/household variation:

- The [Bibliotheca Alexandrina community recipe](https://www.bibalex.org/alexmed/gastronomy/CommunityRecipes/RecipeDetails.aspx?id=%2BpNzCVdF5YaNaTICbo59RQ%3D%3D)
  uses an onion/garlic/pepper preparation and a lower-heat liver stage.
- [Middle Eats' own Alexandrian liver recipe](https://www.youtube.com/watch?v=jNg2B0sMH48)
  describes a quicker pan method. Search-returned creator description was read;
  direct video fetching failed, and the video was not watched. Do not standardise
  all liver recipes as a fixed half-hour cook or describe either variant as the
  sole correct recipe.
- [Colette Rossant's ful recipe](https://www.foodnetwork.com/recipes/ful-medames-recipe-2015121)
  supports overnight soaking and prolonged simmering as a useful process family.
- [USDA hot-holding guidance](https://ask.fsis.usda.gov/article/At-what-temperature-should-I-hold-hot-foods)
  distinguishes controlled hot holding from leaving cooked food out. Palatability
  decline and food safety are not the same variable. No universal several-hour
  room-temperature safety claim is adopted; gameplay holding windows remain
  explicitly balanced abstractions, not real kitchen instructions.

## Lightweight performance and completion boundaries

Keep the existing floor/roof batching and cache invalidation discipline. New
character choice and comment selection should react to changes or coarse
deadlines; no per-frame world scans, random rerolls or expanding variant trees.
Update visible freshness labels coarsely; derive age from stored timestamps.

Use one brief matched populated scene per coherent batch: draw calls, frame-time
sample and existing runtime counters, plus an ordinary interactive smoke. Deep
profiling is conditional on a meaningful reproducible regression or player
feedback. No new always-on telemetry/performance platform, long benchmark
campaign or blanket browser/GPU FPS guarantee is requested.

Existing tracked build/Ink/localisation/import gates and bounded disposable
observations remain appropriate; do not add/run automated suites against the
user's established preference. Preserve current save integrity and unsupported
file bytes. New-game/reset impact is decided when the actual new data contract
is known; unpublished historical migrations are not routine work.

Success is one connected observed loop: purchase a real ingredient lot, prepare
and cook a batch, serve a compatible variant at an accepted player-set price,
record actual eating/value, hear an eligible later callback, and permit an
optional return/order. It also includes long passive preparation, gradual
quality decline without pressure, meaningful silent visits and no price/portion
duplication. Machine evidence cannot close the user's natural pacing judgment.
