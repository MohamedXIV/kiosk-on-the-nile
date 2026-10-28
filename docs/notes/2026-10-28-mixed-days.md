# Mixed days: bounded sustained pacing observation

Recorded2026-10-28 for the combined playtest preview, following [quiet days](2026-10-28-quiet-days.md), [GAME_VISION](../GAME_VISION.md) and [world direction](../art/WORLD_DIRECTION.md). The preview adopts paid base prices of12EGP for tea and28EGP for kebda. These are stylized game values, not a claim about historical Egyptian2000s prices. Opening savings remain240EGP; needs, snacks, rents, deadlines, tips, visitor schedules/capacity and preparation timing remain unchanged.

This is an actual-owner simulation observation over three weekly bills, **not three weeks of natural human play**, a statistical balance verdict or approval of the final visual/audio feel. The user's single combined trial and feedback remain the next human acceptance step. Home guests and player seating were being implemented separately; these observations do not cover those features.

## Conditions and actual owners

A one-off native Godot4.7.2 script advances a real `GameSession` from day1 15:30 through day22 20:00, finishing rent travel at20:20. Each awake step is one simulation second/one world minute. Ordinary eight-hour sleep uses `LifeActions.sleep`; snacks use the real300-minor wallet debit at hunger≤35. Sleep starts around midnight after household cleaning, so wake times vary slightly. Purchases use real outbound/return travel, shop quotes, wallet debits, bags and `unpack_purchase_bag`; no free replenishment or revenue credit is inserted. Tea and kebda use their actual workflow steps while the shared session continues ticking, followed by `accept_request` and `complete_service` with explicit paid/gift disposition. Starting stock is the ordinary6 tea/5 kebda.

The controlled parts are material:

- Visitor route completion and player interaction positioning are immediate fixtures; walking, collision, pathfinding duration and input effort are excluded. Arrival schedules, individual purchase chances, food selection, service availability, hunger, rest, mood, hygiene, reputation and prices otherwise remain owned by the session. Seed1701 fixes the initial RNG; changing participation still changes later RNG consumption.
- Dialogue is cancelled to isolate the calendar/economy; Ink/social story progression and time spent reading are excluded. Every visitor begins with familiarity30 to allow an occasional deliberate gift; this is a relationship fixture, not evidence of earning that familiarity. Hospitality requests are honored, with an additional gift considered every sixth service when eligible.
- Both locations are cleaned through actual `HygieneService.begin_clean` and elapsed session time when a target is below95 at the daily maintenance opportunity. No cleanliness value is assigned. The full trace spent390 world minutes cleaning over the observation, roughly18 minutes per observed day. Long unattended no-cleaning play is not treated as competent upkeep.
- Housing payment uses a labelled present/staying landlord beside the player solely for the creditor channel. Actual account quotes, finance transactions, receipts and wallet debits settle bills. District payment uses real office travel. This does not observe naturally meeting the landlord or choosing financial dialogue.
- Supplies are bought as15EGP packs of4 tea/4 kebda when either stock is below4 during the morning shopping window and the wallet has at least20EGP. All stock consumption and replenishment is real. The fan branch buys an ordinary45EGP fan on day9; it remains stored, so no installed-fan sleep benefit is claimed.

The six-hour policy checks16:00–22:00 before starting a batch of available service requests, allowing other requests to pass. A short preparation batch accepted before closing can finish just after22:00. Its final observation was rerun on the combined source after `VisitorService._consider_purchase` and `_arrived` began consulting the kiosk-open callback before starting a new shopping approach/request. Existing accepted service and independent arrivals/leisure remain separate. This is a **service-window policy**, not a strict sign-input boundary exercise: the scratch policy restores the sign after sleep and sets the daily service window after upkeep/travel. The window governs when the service batch is selected; preparation continues to advance the shared clock. Root observes the actual closing/no-new-request boundary separately. The other three policies stay open while at the kiosk, so their price/upgrade comparison does not require repeating for this gate.

## Results

Amounts below are EGP. All rows start with240EGP and ordinary stock. “Empty” counts awake one-minute step samples with no kiosk visitors; sleep is advanced by its actual owner and excluded from this sampling. Peak counts actual actor presence at the kiosk, including any residential presence during ticks; the synchronous landlord payment fixture is not ticked or used to claim a natural crowd measurement.

| Three-week policy | Prior5/12 prices, daily upkeep | Adopted12/28 prices, daily upkeep | Adopted,16:00–22:00 service | Adopted,45EGP optional fan |
| --- | ---: | ---: | ---: | ---: |
| Paid services / gifts |30 /5|30 /5|30 /6|30 /5|
| Tea / kebda prepared |16 /19|16 /19|16 /20|16 /19|
| Actual service receipts |359|722|722|722|
| Snacks / food spending |77 /231|77 /231|77 /231|77 /231|
| Ingredient purchases |75|75|75|75|
| Rent actually paid |290|360|360|360|
| Remaining rent debt |70|0|0|0|
| Optional purchase |0|0|0|45|
| Final wallet |3|296|296|251|
| Arrival reservations |194|194|204|194|
| Empty awake samples |12387|12387|11874|12387|
| Peak scene people |3|3|4|3|
| Hunger<10 samples / refused snack attempts |0 /0|0 /0|0 /0|0 /0|
| Reported action/system failures |0|0|0|0|

Every final wallet reconciles exactly:240 + actual receipts − snacks − ingredient purchases − actual rents − optional purchase. Remaining debt is not subtracted from the cash balance or forgiven. The old-price trace paid both first and second weekly rent pairs, but at the third bill could pay only the district's50EGP, leaving70EGP housing debt and3EGP cash. The adopted full-service trace paid all six obligations through real finance owners. Its wallet after the first rent cycle was258EGP on day9 morning,306EGP on day16 morning, and296EGP after the third cycle. The final gated six-hour branch ended296EGP after all three rent pairs, with six gifts and peak presence4. Different RNG consumption produced more paid service than its earlier pre-gate run; this is not evidence that closing a sign inherently improves income. Neither branch establishes guaranteed indefinite solvency.

The matched full-service price comparison has identical arrivals, preparation counts, gifts, cleaning duration and empty samples. The additional363EGP is committed paid-service income from the price change, not faster arrivals, more work, or an unexplained cash grant. At the sampled density there were about1.4 paid services/day in the full policy. Weekly rents120EGP plus roughly77EGP food already require about197EGP/week before ingredients and gifts. At the old base prices, even excellent paid tea contributes at most7EGP after its1EGP portion, and kebda11EGP after its4EGP portion. That mismatch motivates the two-price tuning. At adopted prices the corresponding excellent-service margins are14 and27EGP before other costs; roughly ten mixed paid services/week can approach that budget while retaining empty time. Lower quality, different food mix, extra gifts, other spending and time away can still draw down the finite reserve.

An exploratory trace initially omitted cleaning. Its reputation/demand declined, with only14 paid services and2 gifts, hunger pressure from day17 onward, and190EGP rent debt by the endpoint. It is preserved as [superseded-no-cleaning.log](evidence/2026-10-28-mixed-days/superseded-no-cleaning.log); it is not the basis for attributing the shortfall solely to prices. Correcting that observation policy produced the matched upkeep comparison above.

## Evidence and limits

- [Prior prices with upkeep](evidence/2026-10-28-mixed-days/current-prices-clean.log)
- [Adopted prices with upkeep](evidence/2026-10-28-mixed-days/adopted-prices-clean.log)
- [Final six-hour service policy with sign gate](evidence/2026-10-28-mixed-days/adopted-prices-six-hours.log)
- [Superseded six-hour observation before sign gate](evidence/2026-10-28-mixed-days/superseded-six-hours-before-sign-gate.log):25 paid/4 gifts,647EGP receipts,60EGP supplies,236EGP final wallet, all360EGP rent paid, peak3; retained to make the changed source/evidence explicit.
- [Optional fan purchase](evidence/2026-10-28-mixed-days/adopted-prices-fan.log)
- [One-off observation source](evidence/2026-10-28-mixed-days/observation.gd.txt)

The adopted-price runs override only those two food prices in the in-memory content fixture; the preview applies the corresponding tracked content/balance changes separately. The original unclean exploratory script predated the added maintenance/reporting code. A scratch-only class-name typo was corrected before the successful observations. Native exits retain ObjectDB/resource cleanup diagnostics; zero reported owner failures does not mean clean shutdown. No automated suites, historical-save compatibility campaign, build/export claim or current-save roundtrip is included here.

These observations cover finite new-game savings, mixed service/gifts, ingredient replenishment, food/sleep, daily hygiene, three rent cycles, actual unpaid debt under the prior policy, and an optional purchase. Loan/extension dialogue, debt recovery after default, human preparation/input difficulty, meaningful time reading/socializing, long periods away, unassisted navigation, multiple seeds and indefinite economy stability are not observed. The optional fan is purchased, not placed or switched on. Quiet arrival density is preserved: peaks of3 in the matched full-price/upgrade policies and4 in the final gated six-hour run accompany substantial empty time. The final gated run spent438 world minutes on actual cleaning; its reputation ended94.99. The earlier pre-gate six-hour run spent374 cleaning minutes and ended236EGP, so the earlier near-break-even outcome remains visible rather than being overwritten by the more favorable rerun. Whether the combined preview feels warm, legible and unhurried is for the single human trial and feedback.
