# Character-life foundation — 2026-10-30

Epic#35 / task#37, following the approved character/cooking direction and
[shared contract](../superpowers/specs/2026-10-30-character-cooking-v2-design.md).
This is feature-branch implementation, not a delivered playable v2 milestone.

`character_life.json` defines all10 existing visitor profiles: separate food,
category, temperature and spice preferences/limit, day window, price sensitivity,
future neutral thermal affinity and initial hunger/thirst/tiredness/social ranges.
Food descriptors are typed and validated before content activation. Disabled
buying remains an explicit trait for the existing non-buying actors.

CharacterLife owns lazy-initialised per-actor state and saved RNG. Pure state and
profile reads do not mutate or reroll. Actual arrival retains prior needs; bounded
elapsed arithmetic replaces off-screen simulation. Meaningful purchase boundaries
now select once between feasible foods/drinks and quiet/company/rest intentions,
using needs, soft taste/price biases and optional known personal experience.
A20-world-minute decision cache survives re-entry/current Continue; decisions
are not re-rolled each frame. VisitorService preserves pending/served requests
and permits later consideration after an initial quiet choice. The separate fixed
purchase and reputation chance rolls and expanded repeated-food-ID pool are gone.
Existing arrival limits/capacity are unchanged.

The price reference is the authored catalogue expectation until player menu quotes
and actual personal value experience are connected in tasks#41/#42. Social/rest
intent currently remains a quiet non-purchase projection within existing leisure
behavior; grounded dialogue scheduling is#43. Thermal affinity has no invented
weather effect. `satisfy` is a source-deduplicating boundary for confirmed tasting;
production handover/request does not invoke it. Actual taste provenance and
cross-owner consumption publication belong to#42, not this foundation.

SaveCodec now requires/restores the new owner and validates actor→visit counters
and active visit links. Exact current JSON restore succeeds. Existing old files
lack this mandatory state; no intermediate build is delivered as an old-save
upgrade. Final revision/new-game wording, version/changelog and complete preview
remain#44. Unsupported/corrupt bytes are preserved by the existing coordinator.

## Bounded evidence

[Inputs and logs](evidence/2026-10-30-character-life/) are disposable actual-domain
observations, not a permanent automated suite. Baseline confirms no temporary
character owner. Current observation confirms pure reads, same-visit no reroll,
same chosen food/intent/index/deadline and unchanged RNG after actual JSON restore,
invalid need rejection without changing the prior choice, and a complete current
SaveCodec candidate. Numeric comparisons account for JSON integer/float parsing
and insignificant last-bit diagnostic weights; selected identity/RNG are exact.

A48-seed bounded comparison with the same offers selected4 purchases/44 quiet
at0.05 hunger/thirst and35 purchases/13 quiet at0.95 in the retained run. This
shows contextual influence, not a natural-session sales frequency or balance
acceptance claim. Other profile state in this run was randomised once at actual
arrival. Both user-visible feel and economy still need the coherent integrated
slice. Initial quiet weight2.4 and20-minute reconsideration are builder balance
choices, not targets supplied by the user.

Pinned Godot4.7.2 tracked Ink/localisation/import/Web Release build passed;
389 stable Ink localisation references. No automated suites added/run. Native
shutdown reports ObjectDB/resource warnings (73/22 in this disposable fixture);
no leak-free or long-session-memory claim. Renderer/batching unchanged. One fresh
whole-feature-branch review follows the complete slice, not each task.

## Shared actor registry follow-up

The same ActorPresence authored registry now validates all12 registered NPC
profiles, including the existing supplier/landlord, without making them kiosk
buyers or adding arrivals. Their neutral, non-buying profiles are explicit data.
`ensure(actor)` samples private state once on actual phone contact/residential
spawn; the world arrival adapter additionally binds the real visit identity.
Pure reads never initialise state. Non-commercial actors can retain state with
no world visit/decision, and current Continue validates that form. Real supplier
contact/delivery/current candidate passed after this change. No new cast/visuals.
