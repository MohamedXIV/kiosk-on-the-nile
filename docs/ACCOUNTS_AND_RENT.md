# Accounts, rent and agreements

Open **Notebook → Accounts** for upcoming periods, carried debt, accepted promises, loans and receipts. All prices below are current defaults in Egyptian pounds; the wallet stores integer piastres.

## Housing

Abdul Karim is a person who visits the rooftop near the rent date, normally19:00–22:00. Stand nearby and he can greet you; E also opens the conversation. You can pay assessed housing rent, pay part, request a new date even while solvent, decline an offer, discuss his family, and later ask about them. An offer only becomes a promise after explicit acceptance. The original principal stays due; personal promises affect the relationship separately.

Housing defaults to70/week. The first complete period starts at the next20:00 after activation, and is due one week later. New and migrated games receive no invented earlier debt. There is no automatic cash deduction.

A sufficiently familiar/trusted Abdul Karim can lend10/20/30 from his own100 budget. One loan can remain outstanding; repayment returns the same principal, without interest. Accepted agreements retain their signed names/terms if display names or future prices change.

## District

Use **Menu → District** to travel offscreen, choose a quote, explicitly pay and return. The world keeps running. Weekly rent is50; buying a full unstarted week in advance costs45, or four consecutive weeks160. Discounts do not stack; overdue periods settle at face value. Read the exact period dates and receipt. Returning does not pay anything.

After the authored three-day grace period, unpaid district rent suspends commercial work until all enforced debt is cleared. Conversation, self-care, travel and payment remain available. Housing debt does not trigger that suspension.

## Authoring

- `content/accounts.json`: stable creditor/lease IDs, prices, periods, grace, offers, loan budget/eligibility and relationship outcomes.
- `content/residential_visits.json`: real household presence, window/delay/dwell and display profile.
- `content/stories/landlord.ink`: branching speech; compile with `tools/compile-ink.sh` after editing Ink. Financial truth belongs to account services, not story variables.
- `content/travel.json`: district travel legs; `content/ui.json`: labels/statuses.

External JSON ships beside the Web build and can be edited before a new session/reload without rebuilding. Existing accepted terms, receipts and period coverage deliberately remain frozen. Keep IDs stable. Follow BODY_AND_TUNING.md for the existing in-game tuning/import flow; arbitrary account JSON is not a live tuning whitelist.

Save schema4/revision10 migrates earlier saves, retaining jobs, heard history and archived active Ink. Back up your save before switching preview builds. Browser saves are tied to the HTTP origin, including port. Serve the whole extracted folder over HTTP, rather than opening index.html as a local file.
