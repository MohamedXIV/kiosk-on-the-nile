# Notebook UI and offline localization

Product source `420cfe0ecb4ff1e503755c875ff92f112863e63c`, Godot4.7.2, schema4/revision12. No gameplay/save/Ink graph migration or main merge.


[Preview release](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/notebook-420cfe0) · [Complete Web ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/refs/heads/build/notebook-420cfe0/builds/kiosk-on-the-nile-notebook.zip)

Downloaded the GitHub ZIP and matched its digest, BUILD.json product SHA/schema/revision, bundled English catalog and Release-without-probe metadata.

ZIP SHA256: `aa981f5f6fe985aa78bd977672e198f615652ec0f47bc88c787b1b9852b8ac7e`.

## Delivered

- Native four-tab notebook: notes, people, heard conversations, weekly accounts. Readable cards, explicit empty states, close button and scroll regions at960×540/1280×720.
- Search actual heard words/names; combine participant/day/conversation/channel filters, newest/oldest order and paged rendering. A participant filter retains replies in their conversation. Tab/filter/subview state survives reopening within the session and locale refresh; it is not persisted game truth.
- Current notes have stable known-fact references and guarded Arabic/English summaries. Only a unique fact candidate with matching authored source can translate/link. Ambiguous/custom/changed old notes keep original text without invented provenance. Source links require a genuinely present journal chapter.
- People display existing familiar faces, current stages and existing connections. Default names translate only with exact authored source match; custom names and historical heard name snapshots remain intact. Relationship stage text_ref is independent of numerical tuning thresholds.
- Account summary separates deadlines/balances, housing promises, loans and supplier debt from original receipts. Signed creditor names/IDs/amounts and recorded narratives are retained. Canonical AccountText.date, used in Ink context, stays unchanged; display dates localize separately.
- Journal revision and actor-existence index are derived from validated append history. The notebook copies history only after revision changes; the People tab no longer scans/copies it to detect the landlord. Financial summaries omit unused receipt copies; receipt projection is cached and paged.
-93 paired catalog entries added. Bundled offline catalogs/fonts; no translation service. Remaining game HUD/character/system adaptation is outside this increment.

Usage/authoring details: [LOCALIZATION.md](../LOCALIZATION.md).

## Review and decisions

One independent read-only review of5c75714..562a956, one material fix pass, no re-review. Three Important issues fixed: indirect recurring journal copy from People, ambiguous note-to-fact inference, locale refresh overriding original-language rich-text direction. Numeric stage-based translation identity was regraded Important because changing data-driven balance thresholds must not change translation identity; explicit stable authored references replaced it. No deferred review minors.

Existing isolated work checkout and prior authorization to publish a preview retained; no repeated confirmation after “ابدأ”. Unknown source/signed receipt narrative intentionally stays in its original language. First Escape from a focused search may leave text editing before sheet cancellation; Close provides a direct return. This is not a promise of exhaustive controller navigation.

## Validation

No automated tests added/run, per developer/session constraint. Ink/catalog compilation, Godot import and exact product Debug/Release Web exports passed. Actual browser mouse/keyboard with read-only QA observations supplied runtime evidence; no injected game commands/saves.

- Genuine old Continue showed translated initial note/empty People and original heard history. English search `fathi` filtered2 entries to1. Arabic1280 retained the query and Conversations tab. Original journal snapshots remained byte-for-byte equivalent as structured JSON.
- Participant Fathi filter selected5 of7 entries, retaining both player replies; adding My replies reduced these5 events to the2 actual player replies.
- Real Fathi consent produced one sandwich/receipt and one300minor invoice. Reading financial summary/receipt and reopening the notebook left the whole financial snapshot and canonical active Ink runtime unchanged. Selected receipt subview remained selected across close/reopen. The world clock continued.
- [Read-only observations](evidence/2026-10-25-notebook/history-observation.json), [English notes](evidence/2026-10-25-notebook/notes-en.png), [history/search](evidence/2026-10-25-notebook/search-en.png), [account summary](evidence/2026-10-25-notebook/accounts-en.png), [original receipt](evidence/2026-10-25-notebook/receipt-ar.png).

Not exhaustive runtime coverage: very long histories/multiple pages, ambiguous custom note saves, custom renamed actors, every relationship stage/source link/financial combination or every keyboard/focus path. Those guards were inspected in the independent review and fix pass. No real-GPU/native performance evidence and no FPS improvement claim. Full English-game translation, persistent notebook view preferences across game restarts, and broader UI redesign remain separate work.

Exact stock Release boot/Continue restored the genuine supplier receipt/history. Native paragraph direction/alignment now keeps Arabic right-to-left and the earlier English heard line left-to-right within Arabic UI. This uses native rich-text paragraphs with literal add_text, not parsed historical BBCode. Summary/receipt text is not reshaped when unchanged.

Release English1280 account summary, original Arabic receipt under English wrappers, and empty People state were also exercised through the actual tabs/dropdown. [Receipt](evidence/2026-10-25-notebook/release-receipt-en-1280.png) · [Empty People](evidence/2026-10-25-notebook/release-people-empty.png). Some older development screenshots document the pre-fix direction finding; the release-prefixed captures show the shipped result.
