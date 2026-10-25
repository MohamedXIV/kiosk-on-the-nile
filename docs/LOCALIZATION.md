# Offline localization pilot

All catalogs, Ink JSON and fonts ship with the game. No translation API or language download is used. The Web package still needs a local HTTP server as before; it does not require Internet. Hosted PWA/installable offline caching is a separate deployment feature.

Choose العربية/English on the title or in the game menu. Current bilingual coverage includes title/menu actions, notebook/history/accounts, inventory/care/preparation, shopping/travel/visitor action sheets, and Fathi's new connected calls and supplier sheet/terms. Other characters, some HUD/system labels and old recorded history retain their original text. This is not a fully English game yet.

## Writing and translating

Keep one authored Ink story and one logic/effect graph. Complete lines and choice-only text have stable tags, for example `# loc:story.supplier.greeting`. Never use a choice index, evaluated Arabic string or file line number as a translation identity. Author each language for intent, voice and the situation; preserve actual prices, consent and outcomes.

- `content/locales/ar_EG.json` and `en.json`: shipped catalogs. English may reorder named parameters but must retain them.
- `tools/extract-localization.py --out /tmp/dialogue-localization.json`: exports stable references, source file/line, choice/line type and paired text for a translator. File line is context, not identity.
- `python3 tools/extract-localization.py --check`: build-time content validation for duplicate/missing authored IDs and parameter mismatch. It is not a gameplay test.
- Keep speaker/interlocutor, intent and tone in translator notes; the Fathi example is a practical, warm supplier call. English is authored adaptation, not literal Egyptian phrase substitution.

Catalogs are plain text and named parameters. They cannot execute Ink or financial effects. Add behavior to typed services/Ink logic, never catalogs. Arabic is the fallback for missing English entries; unknown story references retain their canonical source text. Malformed catalogs or mismatched named parameters are rejected before installation.

## State and history

Canonical Ink text, choices, cursor and effects remain unchanged by locale selection. LocalizedNarrative projects a display view. Captured offer amounts/reason references belong to the beat; switching language does not advance/re-randomize it or prepare another quote.

New heard translated lines/choices retain their displayed snapshot plus optional original canonical text, locale, text_ref and named parameters. Historic entries without proven references stay as recorded. Financial receipts preserve their signed names/amounts and original recorded text. Language preference is a local user setting, separate from contractual/gameplay state.

Published supplier Ink is archived before adding tags, so old active choices complete through their original story; they may remain Arabic until the next newly started call. No cursor is transplanted into a changed graph.

## Notebook and history

The notebook now has bilingual notes, people, conversation filters and weekly financial views. Open with N or the HUD menu. Search and participant/day/conversation/channel filters combine; selecting a participant retains your replies in that same conversation. Newest/oldest order and bounded pages help navigate history. Tabs, filters and the summary/receipts selector persist while reopening within a session; these preferences are UI state, not game-save fields.

History is always the actual heard snapshot, including original names and language. Changing the interface language does not translate or rewrite those records. Financial receipt names/narratives likewise stay as signed/recorded; their surrounding labels and dates may translate.

Current note summaries use stable fact IDs in `ui.notebook_layout.note_refs`. A translation is shown only when the known fact is the unique source candidate and the recorded note exactly matches that reference's authored Arabic catalog text. Ambiguous, custom or changed old text stays unchanged without an inferred source link. The source button opens only a genuinely present conversation.

Relationship stages have explicit `text_ref` values in `social_life.relationships.stages`; keep those identities when adjusting numerical thresholds. Default actor names can translate only when they still match their authored Arabic default; custom names remain intact.

`ui.notebook_layout.history_page_size` sets history/receipt page length (10–100, shipped40). Content validation checks these bindings and stage references against both bundled catalogs. No gameplay/save schema or Ink graph changes are needed for this UI increment. Broader HUD/character/system adaptation is still pending.

## Storage, care and preparation

Inventory now has bilingual search/storage-kind filters, container capacity, held-item context and reserved-ingredient indicators. A bag's Unpack action applies to the whole bag, including items hidden by a search, and moves only what the existing storage rules accept. Search uses exact-source-guarded names from both bundled languages; custom names retain their source text. Locale/filter refresh never transfers items.

Item sheets separate use/care, active preparation and existing eligible recipes. Starting a preparation selects its progress tab. Active kettle/griddle workflow F options reopen that read-only sheet; primary cooking actions remain unchanged. Closing a sheet does not cancel work. Requirements and disabled controls explain existing eligibility; they do not unlock recipes or bypass equipment, ingredients, knowledge or action-policy checks.

Item, food, recipe and step catalogs use stable existing IDs (`item.<id>`, `food.<id>.label`, `recipe.<id>`, `recipe.<id>.step.<step-id>`). Frozen active-job labels translate only when the exact authored source still matches. Parameterized food names resolve the guarded source and captured sugar argument together. Unsupported/custom wording remains unchanged; canonical saved definitions, reaction timing, quality evidence and heard history are not rewritten.

Inventory reads current storage without consumption history. Job progress uses a narrow scalar projection; structural changes coalesce and visible progress updates periodically, while the world continues. This is an ownership/allocation improvement, not a real-device FPS claim. Shop/travel/visitor UI and broader character/HUD translation still have work remaining.

Older active jobs owned by the retained legacy adapter keep their original primary station controls; they are not presented as empty workflow progress cards. The new inspection shortcut applies to workflow-backed jobs without changing save data.

## Shopping, travel and visitor actions

Shopping offers/descriptions, travel phases/destinations and visitor action/topic/order headings have bundled Arabic/English presentation. `shop.<shop_id>.offer.<offer_id>.*`, `route.<route_id>`, `topic.<topic_id>` and `food.<food_id>.menu` use stable identities with exact authored-source guards. External custom wording stays truthful as source text. The active personal dialogue hub resolves `manual_topic.<encounter>/<topic>` and stable social-topic keys; it keeps the existing continuous conversation flow and offers focusable choices. The older standalone VisitorPanel is currently unused by the normal interaction route and does not replace the hub. Topic headings are UI labels; most resulting character Ink conversations still use their authored Arabic. No Ink branches or historical speech are translated by this sheet rollout.

The shop has cross-language offer search, selected product contents/size/capabilities, quantity, explicit reviewed total and separate confirmation. Locale switches preserve reviewed quote identity and amounts. Product/quantity/stock changes invalidate review; editing a quantity draft does so immediately. Search is presentation only. Stock prices/availability and grants stay owned by ShopService. Travel and cooking continue while browsing. Return takes the existing configured journey time; purchased ingredients remain in the purchase bag until unpacked, while equipment/furniture use existing return storage rules.

## HUD and arrangement

Status strip time/cash/sign/stock/needs/held names and fatigue tooltips have bundled Arabic/English labels. Held-item names use the same guarded item/prepared-food projection as storage. Sign wording is an indication, not an added business gate. Arrangement controls, policy hints, piece and host names translate; custom item labels retain source fallback. Locale switching rebuilds option captions without selecting/preparing/placing an item; the actual preview request, rotation, coordinates and host stay owned by BuildController. The sheet scrolls inside viewport bounds. Remaining world interaction hints and narrative/system text are not all translated.
