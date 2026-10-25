# Offline localization pilot

All catalogs, Ink JSON and fonts ship with the game. No translation API or language download is used. The Web package still needs a local HTTP server as before; it does not require Internet. Hosted PWA/installable offline caching is a separate deployment feature.

Choose العربية/English on the title or in the game menu. Current bilingual slice: title/menu actions, Fathi's new connected calls and supplier sheet/terms. Other characters, some HUD/system labels and old recorded history retain their original text. This is not a fully English game yet.

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
