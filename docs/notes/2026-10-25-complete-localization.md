# Completed offline Arabic / English localization

2026-10-25, Africa/Cairo. Godot4.7.2; schema4/revision12 unchanged. Final product source/release details are listed below. No main merge.

## Completed scope

All11 current canonical authored Ink stories have311 stable line/choice/alternative localization identities. Both bundled catalogs contain1027 paired entries; no Arabic prose remains in the English catalog. English was authored for voice/intent: warmth, embarrassment, quiet companionship, boundaries and financial consent remain recognizable. One Arabic canonical logic graph owns all conditions/choices/effects; English catalogs never execute story logic. Localization IDs are authored stable identities, including numbered suffixes that must not be regenerated/renumbered when inserting text.

Current player presentation now covers title/menu/HUD/notebook/history/accounts, shopping/travel, inventory/care/preparation/recipes, arrangement, supplier/district/developer tuning, world/door/sign/station/sugar/order hints, captions, internal thoughts, standard messages/errors, all character dialogue/choices and newly created system records. Technical config keys/units/IDs remain literal. Historical heard text, signed names/text, custom source wording and already-open archived chapters intentionally retain their original wording. This completes authored current-content translation, not an exhaustive gameplay qualification or translation of arbitrary custom data.

## Structure and compatibility

- Stable source-guarded data projections preserve externally changed item/actor/world labels. World text caches immutable authored definitions per LocationView instead of copying full location/space definitions for every target each frame. No measured FPS claim.
- Captured primitive/nested text references resolve dynamic food labels, appointment/financial dates and durations. An eight-level resolver bound and dictionary check protect nested references. Locale changes read captured presentation state; they do not prepare a quote, change canonical Ink or replay effects.
- Every previously current compiled story was archived before tags changed its hash. Manifest/index include Godot-canonical sorted-JSON hash aliases used by actual save restore, in addition to retained prior entries. Old active chapters resume the exact old graph; new starts use translated content.
- New financial/supply receipts freeze journal_name and journal_text. Reconstruction uses the original Arabic system-name fallback when an old receipt has no journal_name, preserving exact validate_links comparisons. Existing validators allow additive fields. Existing amounts, IDs, terms, request idempotence, chronology, names and historical text remain authoritative.
- New thoughts freeze heard text plus optional locale metadata. The current thought can re-render while the journal keeps what was heard; old thoughts without metadata remain original. Optional metadata validates against its recorded event.
- District/tuning locale refresh is read-only: no quote/payment/proposal. Canonical financial date inputs stay unchanged; presentation captures sibling dated references. Canonical learning note effects remain unchanged and existing notebook provenance projections translate known notes.
- Source fallbacks remain safe when qualification/native scenes omit the optional locale service; current UI initializes that service normally. No native qualification suite was run.

## Review and rulings

Independent story groups produced separate fragments; root integrated catalogs/runtime. A separate implementer owned district/tuning, another the new system-record projection. One fresh final read-only whole-change reviewer found no Critical/Important/Minor issue after inspecting tags/control flow, landlord conditional choices/compiled output, dynamic captures, archive routing, thought compatibility, frozen receipt names/exact validation, source guards and locale refresh. No edits/tests/subagents by reviewer, no re-review.

Root rulings in the material fix pass: retain old graph/history/signed/custom source text rather than fabricate translated provenance; freeze new receipt system names with exact legacy fallback; keep technical metadata literal; cache immutable world source definitions outside target rendering; preserve canonical source fallback for absent locale/malformed nested parameters. The latter optional-service issue was identified by reading existing qualification scene initialization, then corrected in source. Build/import/export verified compilation; no automated tests were added/run.

## Actual acceptance and its limits

Actual Chromium/SwiftShader mouse/keyboard and read-only serialized Debug observations, no callable game command bridge or injected save/pose/state. Stock content except the explicitly described archive-only external content fixture. Software rendering does not establish player-device FPS.

1. Genuine older shipping save Continue restored its cup, kiosk and4300minor balance with coordinator failures{}. [Evidence](evidence/2026-10-25-complete-localization/old-continue-observation.json).
2. Stock new English game, normal right room door/stairs/travel and walking to Youssef. English hub → English spoken introduction/caption, original canonical Arabic Ink frame remains. Saved mid-conversation using actual Save UI, allowed10-second browser filesystem drain, reloaded and Continue. Canonical runtime frame/Ink/hash remained exactly equal; social receipt meet_youssef and relationships/moments did not repeat. Locale switched to Arabic and back while active; captured runtime and social state stayed equal. [Observation](evidence/2026-10-25-complete-localization/conversation-observation.json).
3. Continued both introduction beats through the ordinary controls. Current thoughts/ambient frames, time and independent visitors continued; dialogs did not become separate one-shot starts. Repeated keyboard Enter can be consumed by retained menu focus; mouse controls remain available. Full keyboard navigation is not claimed.
4. Archive acceptance used an external Web content fixture: temporarily replaced ONLY served `stories/companionship.ink.json` with its actual pre-tag archived compiled graph, kept normal rules/content and current binary, started the next Youssef topic through the real UI and saved its first Arabic frame. Its actual observed story hash was467dcb6a91b3ebec3a8debdfecbfc6c6cd5a7b127d23c449a066827915589c11. Restored stock content and used stock Release Continue: that exact old passage resumed, advanced and completed. The next newly started visitor topic displayed English. No synthetic save was written and the fixture is not shipped.
5. Exact final Release build/export and real boot/Continue are recorded with final-* screenshots; earlier Debug/Release67 screenshots document the paths above and precede the final optional-locale fallback correction. Other metadata/logic/canonical stories are unchanged by that last correction.

Build-only gates: compiled Ink matches sources; duplicate/missing localization IDs, named-parameter parity and untagged authored Arabic prose rejected; Godot import and Debug/Release exports completed without script/parse/compile errors. Catalog key parity and English Arabic-residue audit were inspected. Removing loc tags and normalizing choice-edge whitespace leaves canonical story/control/effect content unchanged.

Not exhaustively exercised: all311 variants/choices (including landlord conditional branches and dated negotiations), every dynamic appointment/price/food path, complete workshop-trial outcomes, new financial/supply journal-name receipts through payment+restore, thoughts in every need state, every custom/old save, native qualification scene runtime, all controller/keyboard paths or real GPU performance. Reviewed/static coverage is distinguished from actual UI coverage. Existing historical/signed/custom text is an intentional exception, not an unfinished translation task.

## Final release

- [Final prerelease](https://github.com/MohamedXIV/kiosk-on-the-nile/releases/tag/localization-0ea4572)
- [Complete ZIP](https://github.com/MohamedXIV/kiosk-on-the-nile/raw/c70f3e585aec4f825b834c01989a4266eed0726d/builds/kiosk-on-the-nile-localization.zip)
- Product `0ea45729ee8094842c817ec72ce58e45493a6d5d`; source preview/localization-0ea4572; artifact build/localization-0ea4572, commit `c70f3e585aec4f825b834c01989a4266eed0726d`.
- SHA256 `e2d588b32e0ee67d02fec0922be9de50d0dc371c067964bb574c4a50ba8e2ba9`,11899194bytes.
- The interim67e8e69 prerelease is marked superseded, with its immutable tag/artifact retained. Untagged intermediate preview4e3876d was not final delivery.

Final artifact commit appends a corrected authoring guide to the initial artifact; ZIP comparison showed only LOCALIZATION.md changed, with engine/catalog/content bytes identical. Download link pins the immutable artifact commit.

Complete stock Release assets, external content and archive graphs, both catalogs/fonts, licenses, RUN.txt, LOCALIZATION.md and BUILD.json (schema4/revision12/debug_probe=false). Downloaded GitHub ZIP independently SHA checked and BUILD/source/assets/catalogs inspected. One WASM and one PCK; no mixed-build assets or QA fixtures. Extract all files into a fresh folder; run `py -m http.server 8765 --bind 127.0.0.1`, open http://127.0.0.1:8765/ . Keep content/ and every kiosk-* file together. No file://; saves belong to exact origin/port. Bundled offline assets do not promise hosted PWA caching.
