# Comfortable freshness checkpoint (#40)

Development branch only. No final preview/version/changelog/save-reset milestone yet; #41–44 remain.

FoodFreshness derives present quality and eligibility without changing immutable preparation quality/time. Per-food curves pass through fresh, past its freshest, declined but still servable, then unservable. Fried foods lose texture sooner; the sale cutoff is much later. Initial curves in equivalent ambient game minutes: fried/pane30/180/720, tea90/240/720, other cooked dishes180/480/1440. Existing clock speed is one world minute per simulation second. These are initial builder balancing values, not user-confirmed targets or real food-safety instructions.

Stored exposure is settled only at context changes: ambient1, warm0.5, working cold storage0.25. Entering storage or changing heat changes future ageing, never age already accumulated. A portion inherits the batch's original ready time and settled exposure; tea retains brew readiness through late pouring, and shawarma filling retains roast readiness through assembly. The old shawarma heat phase now automatically stops at readiness and holds, avoiding a burnt batch merely because sleep/travel crossed its former reaction window. Its explicit cancel and slicing actions remain.

ItemStore owns live food and deliberate-discard receipts, separately from player consumption. RecipeWorkflow owns process/result proofs. Current source validation preserves preparation identity and prevents a live command resetting exposure. The final handover and player eating boundaries refuse unservable food; serving quality is calculated at handover, not copied from the preparation label. Pending accepted price/menu contracts remain #41. Inventory/recipe views show the stage; prepared portions can enter/leave an actual fridge, whose power toggle changes future context. An unpowered fridge does not trap its contents. No per-frame food-history scan or mutable freshness tick was added.

The bounded actual-owner observation includes the #39 roster, exact overnight readiness, current JSON candidates and:

- A prepared potato portion aged60, moved into powered cold storage without changing that age, then reached120 after240 more minutes (not300). Power off/retrieval/on/return succeeded.
- At equivalent age520 it remained servable with present quality78.15 from initial90; Continue preserved it. An attempted reset was refused with `food_rejuvenation`.
- Reheating the remaining batch did not reset age; a later portion retained original ready_at1782 at world2682, exposure800. At1500 it was unservable, eating failed without consuming it, it was excluded from available foods, and deliberate discard plus current Continue worked.
- Delayed tea pouring kept original readiness3387.7 rather than pour time3391.7.
- Actual heard Ink introductions, next-day company, the shawarma hint and teaching unlocked the existing recipe. Real marination/cold storage/spit/slicing/assembly then kept ready_at4869.7 through assembly at5352.7, exposure483, present quality79.12125, and current JSON restoration succeeded.

Fixture stock, nearby player/device placement and coarse time jumps were explicit; this is not a natural arrival/pacing or human UI acceptance claim. No suite was added/run. Final native process retained228 ObjectDB/24 resource exit warnings; no leak-free claim. The tracked build covers Ink/localisation/Godot import/Web, not gameplay correctness.

Evidence: [commands](evidence/2026-10-30-freshness/observation.gd.txt), [output](evidence/2026-10-30-freshness/observation.log), [build](evidence/2026-10-30-freshness/build.log).
