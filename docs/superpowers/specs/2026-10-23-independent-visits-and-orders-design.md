# Independent visits and readable orders

Approved in conversation: 2026-10-23. Builds on GAME_VISION.md.

People visit the corniche independently of kiosk opening. Arrival uses weighted, bounded randomness with quiet gaps, character time windows, visit memory and a maximum four people including arrivals/departures. No guaranteed Amgad arrival, fixed football arrival or scripted first-day sequence. During a visit, a separate delayed purchase decision may be made if the kiosk is open and an appropriate product exists. Closing/opening cannot force a new arrival or an immediate wave of orders. Nonbuyers and served visitors retain leisure time.

Pending orders have one authoritative ServiceSystem record. Ink order announcements, reminders and a small nearby icon/name badge read that record, including newer foods. Dirt remarks cannot replace an order announcement. A contextual “كنت طالب إيه؟” choice while an order is pending uses varied character-specific Ink replies without consecutive repetition. Asking does not place another order or consume personal story topics. Icon/name remains visible within hearing distance for a pending order even after its short spoken caption ends, disappearing on delivery/cancellation/departure.

Approach chosen: implement independent visits and purchase decisions together, with the same actual-order projection used for speech/UI. An arrival-delay-only patch would leave the approved independence requirement unmet; a full daily-life simulation is beyond this bounded change. Existing Godot/GDScript, external JSON and Ink remain. Values are author choices in JSON, not final balance acceptance. Existing save identities/jobs/pending orders/story cursors survive explicit revision6 migration.

No new social quest system, generosity/payment redesign or art pipeline. No automated tests without a user request. Build/import, static review and actual mouse/keyboard review are separate evidence; unobserved acceptance remains documented.
