# Notebook UI and offline localization

User approved starting with the notebook/history and their translation, retaining the quiet slice-of-life game. Implement within existing Godot controls and locale catalogs; preserve gameplay/Ink/save state and signed historic names/text.

## Approach

Keep four familiar tabs: notes, people, conversations, this week's accounts. Split financial summary/receipts within the accounts tab. Use focused history UI and pure notebook projections rather than extending the existing giant joined string. A broad UI framework or save/schema migration adds no value here. Existing user instruction to start authorizes implementation; routine layout/filter choices below are implementer decisions.

## Behavior

- Responsive modal sheet with localized title, clear close button, readable scroll regions and empty states in Arabic/English.
- Heard history remains exactly as recorded, including language and name snapshots. Localized wrappers explain this. Filter by conversation participant (retaining replies), day and channel; search actual heard text; newest/oldest order, bounded pages. Retain selections across reopening and locale changes. Links from facts open the genuine source conversation.
- Translate current note summaries only by a stable known-fact reference and an exact match to that reference's authored Arabic source. Unknown/custom/changed old notes stay as recorded. No invented provenance, new facts or retrospectively translated dialogue.
- People cards show existing known people, localized default names/stages and existing connections, retaining custom names. No hidden social state is newly exposed.
- Weekly accounts distinguish covered/upcoming/overdue items, enforcement dates, promises, loans and supplier balance. Receipts are separate, newest first. Display wrappers may translate; signed creditor names, amounts, IDs and recorded receipt narrative stay unchanged. No payment commands or quote preparation.
- Refresh visible notebook periodically; only copy journal when its derived revision changes. World time continues. Locale/filter/tab selection is UI state, not saved game truth.

## Boundaries / validation

No new gameplay, Ink graph edits, full-game translation or full UI redesign. No automated tests added/run per session instruction. Use compilation/import/export and actual browser input; record coverage gaps. Existing work checkout and authorized preview publication retained; no main merge. One fresh final review following inline execution.
