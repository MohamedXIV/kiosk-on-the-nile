# Supplier agreements and deliveries

## Calling Fathi

Stand near the rooftop desk or the last kiosk counter (`counter_6`) and use **Menu → Call Fathi**. These are landline contact points attached to the furniture. Moving away, travelling or sleeping ends the call; offscreen delivery never creates spoken dialogue or another visible person.

The call uses Ink. Choose the account/agreement topic to open the supplier sheet. Practical contact and food help remain available when personal conversation is blocked by exhaustion or district trading is suspended.

## Reviewing an agreement

Choose item quantities, delivery hour/minute, days in the game's seven-day cycle, a valid dry/cold container, permission to leave goods, and payment policy. Review the exact basket and total before accepting. A quantity of zero omits an item. Cold ingredients require a placed fridge; dry goods use dry storage. A single batch targets one container, so make a compatible basket.

Current defaults: delivery07:00, fee1EGP/batch, explicit normal credit ceiling20EGP. A daily stock limit is authored per ingredient. Quote life is60world minutes. Extra orders arrive once after2world minutes; recurring agreements start strictly after acceptance. Ordinary world time continues while reading the sheet.

Accepting a revised recurring offer replaces future terms only. Pausing stops later deliveries and retains unspent prepaid funds. Past terms, fulfilled invoices, item sources and receipts remain recorded. No cancellation fee or automatic refund is invented. Manual market trips remain available.

## Paying and receiving

- **Prepaid:** explicitly deposit carried cash during the call. A delivered batch uses that supplier balance, not cash carried elsewhere.
- **Credit:** explicitly agree to the ceiling in the signed offer. An actual delivered batch becomes Fathi's invoice, normally due7days later. Settle outstanding principal through his account sheet, without interest.
- **Cash:** be at the destination at the scheduled time and explicitly confirm payment through the account sheet. An absent/sleeping player cannot pay remotely. The local confirmation window is30world minutes; missing it skips that batch.

Delivery grants the complete basket into its agreed storage and records goods/fee separately. Missing space, moved/removed storage, insufficient stock/funds/credit, or missing permission skips that occurrence without goods or any delivery charge. No same-day retry happens automatically. Place an explicit extra order if desired.

The notebook's Accounts tab shows current terms, next time, prepaid balance, outstanding invoices and recent delivery results. History records system receipts/skips, not imaginary calls. Existing ingredients may be packed/moved normally.

## Emergency food

Ask Fathi for a bite on account, then explicitly accept. One existing kebda sandwich costs3EGP, no delivery fee, and becomes a real personal-use item in your empty hand. Eat it using the existing secondary-use action. Outstanding emergency principal is capped at3EGP until repaid; no relationship threshold or invisible hunger refill. The emergency allowance is independent of normal supply eligibility; both are actual debts to the same creditor.

## Data and saves

`content/suppliers.json` contains the display name, phone hosts/radius, catalog/unit prices/daily stock, schedule/quote/cash windows, fee, credit limits and emergency-food defaults. JSON is external to the build and reloads on startup. Editing templates affects future agreements; signed prices/names/policies remain frozen. Stable actor/item/container IDs are not display names.

`content/stories/supplier.ink` authors the heard call and explicit effects; compile Ink after editing it. Services own inventory and money. Schema4/revision11 adds no historical supplier debt, stock grants or agreements to earlier saves. Back up preview saves and keep the same HTTP origin/port when continuing.
