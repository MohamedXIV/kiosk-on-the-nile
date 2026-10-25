# Structure, performance, UI and localization audit

2026-10-25, Africa/Cairo. Audited source `70d035f051450685fd059f0cec0a1b64e1fcb850` (runtime product38396bb plus delivery docs). This change is a report/proposal only. No gameplay, save, Ink, dependency or UI implementation was changed.

## ملخص المراجعة

- اتأكدت من الواجهة مشكلة في جمع أحداث الإيجار والتوريد بعد النوم؛ قد تترك التوريد معلقًا وتوقف الأنظمة التابعة بينما الساعة مستمرة. لا خصم أو بضاعة جزئية في الحالة المرصودة.
- مسار النوم لا يرفع فشل الأنظمة بوضوح؛ إصلاح هذين الأمرين يسبق التجميل والترجمة.
- توجد إعادة فحص للتاريخ ونسخ للحالة تستحق تحسينًا مضبوطًا، لكن قياسات المتصفح هنا برسم برمجي وليست حكمًا على جهاز اللاعب.
- تداخل ورقة المورد مع الحوار ظاهر فعلًا، واللغة/RTL والنصوص الموزعة تحتاج أساسًا موحدًا مع الحفاظ على Ink والحفظ.
- ترتيب التنفيذ المقترح: صحة الزمن والأحداث، ثم العمل الدوري والملكية، ثم تجربة UI/ترجمة أوفلاين صغيرة، وبعدها التعميم.

## Intent and decisions already made

Pause features and stabilize the existing game before hospitality/new stories. Improve structure and performance from evidence, then clean UI with localization infrastructure. Ship language content/fonts with the game; no translation API, language download or online dependency. English narrative is authored adaptation of intent/voice, not literal replacement. Preserve one narrative logic graph and stable localization identities; do not copy branches into independently maintained language stories.

## Method and limits

Targeted first-pass audit of high-risk integration paths, not an independent review of every application file. Read composition, time/coordinator, accounts/supply publication, persistence, narrative frames/journal, UI focus/layout and content ownership. Fresh Ink check, Godot import and Web debug/release exports succeeded. No automated tests were added or run. Browser interaction uses actual mouse/keyboard; debug observations are read-only. Browser-only instrumentation sampled rendering cadence and CDP task metrics, without a callable game command bridge.

Baseline inventory:162 application GDScript files,12127 lines,22 UI scripts,11 authored Ink stories and153 top-level UI JSON keys. These are scope indicators, not quality thresholds. Ten forced RTL constants and163 `.snapshot(` call sites were counted; not every one is a problem or a measured hot path.

## Findings, by action priority

### A01 — P1: Backdated catch-up deliveries conflict with append-only journal ordering

Source trace: `game/app/game_session.gd:377` assesses accounts/finance before delivery on sleep; AccountTransactions `_system` at119 stamps wake/current time. `game/commerce/supply_transactions.gd:100` stamps unattended receipts with scheduled time; `_publish` at133 appends that receipt. `game/narrative/interaction_journal.gd:15` rejects any event before its last timestamp. Thus a delivery scheduled before wake can be rejected after a wake-time bill/promise event. A skipped older occurrence also appends wake time and can block a later successful catch-up occurrence.

The candidate transaction correctly avoids partial goods/cash publication on rejection. However, that occurrence remains scheduled. Retrying encounters the same journal ordering problem. Coordinator failure dependencies can then block needs/body/cooking/motion/visitors/narrative while clock/travel/accounts advance. This is a gameplay correctness issue, not a cosmetic chronological sort issue.

Required correction: distinguish domain occurrence time, processing/observed time and stable append sequence. Preserve actual due dates and heard-only dialogue without backdating events into a journal that forbids them. Define how old receipts cross-validate before changing the schema. Do not merely ignore append failures, erase the scheduled timestamp or disable validation.

**Confirmed through actual UI.** Temporary external content: start1130/18:50, player[0.6,-0.4], wallet10000minor, leases1440minutes/due07:00, supplier quote1440minutes. No game code or save state was injected. Called Fathi, deposited1000minor and explicitly signed daily tea2/07:00/prepaid/leave-permitted into kiosk_dry. First12-hour sleep delivered occurrence1860 successfully; after two sleeps, clock2683.0333 and failures{} were observed and a genuine save was made. Third12-hour sleep crossed the first lease assessment and occurrence3300. Finance appended two bills at3494.1333; delivery3300 remained scheduled with no new grants/receipt and prepaid700/wallet9000 unchanged. At3496.0833 and3499.8167, deliveries reported invalid_interaction_journal and11 dependent systems remained dependency_failed. Clock still advanced. This proves the collision and persistent block for that authored timing, not every possible default-calendar timing. [Observed fields](evidence/2026-10-25-audit/catchup-observation.json) · [Before](evidence/2026-10-25-audit/before-collision.png) · [After](evidence/2026-10-25-audit/catchup-failure.png).

### A02 — P1: Sleep outcomes do not propagate failures

`game/app/game_session.gd:367–383` calls workflow, finance and delivery through a second handwritten orchestration path and drops ActionResult failures. `LifeActions.sleep` at31 returns the sleep preview/recovery result; the ordinary coordinator only reports later failures. The wake action can appear successful after an unattended subsystem refused its work.

Required correction: explicit shared advance/catch-up orchestration with outcome collection and deliberate skip/pause policies. Keep physical visits/sleep recovery semantically distinct from continuous walking; don't replay physics or speech through skipped hours. A subsystem failure must be surfaced with enough context and must not create a permanently silent retry loop.

### A03 — P2: Historical scans and copies run even when nothing is due

`DeliveryService.tick:10–20` enumerates each version from first_at on every simulation tick, including already final occurrences. `AccountBook.tick:27–33` similarly revisits prior lease periods. `AccountTransactions.tick:42–44` deep-copies accounts/commitments/relations before finding out there are no new events. Cost grows with played history, independent of whether any event is due.

Required correction: persisted/reconstructible next occurrence/assessment cursors and due-time checks; deterministic chronological merge for simultaneous owners; generate candidates lazily once work is due. Preserve idempotence and legacy identity. Source complexity proves repeated work exists; no per-method CPU saving is claimed without profiling.

### A04 — P2: UI has no common modal/focus owner

`Main:148–152` duplicates visibility lists for motion and conversation eligibility; `_unhandled_input:251+` independently encodes panel priority. `Hud:144–146` hides dialogue only for notebook/sleep, so supplier and dialogue can remain visible simultaneously. Observed at960×540 and1280×720: the supplier sheet overlays still-visible conversation text/buttons, producing competing visual layers. Escape/back, focus restoration and movement policy cannot be inferred consistently from one place.

Required correction: a small explicit screen/modal coordinator with one active blocking sheet, optional intentional overlays, common back/close/focus restoration and world-time policy. Each domain panel keeps its own controls/view model. Do not build a global event bus or another gameplay state owner.

### A05 — P2: Localization changes must preserve canonical Ink and historical events

`InkRuntime:54` accepts a finite metadata tag set without localization IDs. Its restore at131–135 compares actual Ink choice text with the saved canonical frame. `InteractionJournal` stores frozen displayed strings and names, not locale-independent text references. `UiText:40,46` forces RTL; several finance/panel strings and date/currency formats are inline in code. Translating a saved frame in place would break the current restore contract; re-running Ink to obtain new text could repeat effects.

Required correction: introduce a presentation projection over canonical narrative frames. Stable line/choice/variant IDs, captured named parameters and authored catalogs live outside business logic. Keep an immutable localized snapshot of what was actually shown plus optional text-reference metadata for future re-rendering; never claim old journal strings have recoverable IDs when they do not. Archive published Ink before adding tags, and migrate legacy frames/journal conservatively. Translation catalogs must not contain executable Ink branches or effect tags. In particular, `GameSession.supplier_context` currently passes an Arabic emergency_reason into Ink; replace such human-language state inputs with semantic reason/variant references and captured structured parameters, not literal string substitution. Choice indexes remain cursor-local identities, not stable global translation IDs.

### A06 — P2: Composition and narrative projections are mixed

`GameSession` has566 lines and `Main`417, but size alone isn't the finding. `GameSession.financial_context:455+` creates quotes and writes chapter state while projecting narrative inputs, and supplier context also freezes terms. Main owns input policy, view construction and multiple modal eligibility decisions. Extract coherent financial/contact narrative adapters and presentation coordination; retain GameSession as the composition/lifetime owner. Separate pure queries from explicit chapter preparation. Avoid a replacement ECS/kernel/DI framework and cosmetic file splitting.

### A07 — P3: Authored supplier defaults are partly ignored by UI

`content/suppliers.json` exposes delivery_minute, but `SupplierPanel:41–42` fixes the initial controls at07:00. Quantity controls use hardcoded maximum20 despite per-item daily stock, and one-off descriptive text hardcodes two minutes rather than reading extra_delay_minutes. Domain validation still checks the submitted terms; this is authoring/UI consistency debt. Read defaults/limits from validated definitions and localize the labels. A capacity limit need not equal daily stock, but the chosen policy must be explicit rather than accidental.

### A08 — P2: Snapshot and definition access need bounded read models

`SessionConfig.section:12` deep-copies whole sections, and `ActorPresence.profiles:10–12` rebuilds the entire merged actor catalog for individual profile lookup. Snapshot APIs are correctly defensive at save/transaction boundaries, but UI and frequent pure queries also use them. Keep those safety boundaries; add narrow read models/revision-based projections or frozen typed definitions for hot readers. Do not return mutable internal dictionaries merely to remove copies.

## What is already sound and should be preserved

- Godot/Ink dependency boundary is concentrated in InkRuntime; UI does not own recipe or wallet truth.
- Candidate supply/account transactions avoid emitting half a monetary/inventory update.
- Stable actor/item/contract/occurrence identities, explicit time dependencies and archived story support are useful foundations.
- External JSON can be shipped and validated offline; language catalogs can follow the existing content-loading contract.
- Quiet independent visitor intent, physical population cap, practical care paths, directional social state and actual item provenance must remain unchanged by cleanup.
- Existing defensive snapshots and restore validators have real value; optimizing them requires equivalent ownership guarantees.

## Release baseline measurements

Actual untouched Release Web, headless Chromium,960×540 and1280×720, Chromium154.0.8037.57 on Debian13, Godot4.7.2, SwiftShader software WebGL, single browser,8-second samples. Data: [raw summaries](evidence/2026-10-25-audit/release-browser-metrics.jsonl).

| Scene | Viewport | Samples | Median rAF interval | p95 interval | Main-thread task time |
|---|---:|---:|---:|---:|---:|
| Rooftop idle |960×540|81|100.0ms|133.3ms|8.29s|
| Active call |960×540|109|66.7ms|83.4ms|8.17s|
| Supplier sheet |960×540|88|99.9ms|100.1ms|8.19s|
| Supplier sheet |1280×720|56|133.4ms|183.4ms|8.18s|

These are browser rendering intervals, not Godot physics frame times or proof of a specific GDScript bottleneck. Samples are short, scene population/time evolves, and CDP counters bracket the sample plus instrumentation overhead. JS heap was approximately10.3–12.0MB and DOM nodes44; this excludes a complete accounting of WASM/GPU/native memory and is not a memory-leak result. Software rendering strongly limits portability to real devices. No claim of a player-device FPS, function-level attribution or before/after improvement is made. Obtain a real-GPU/native profiler baseline during implementation; distinguish debug QaProbe's full-state serialization from Release, which omits that probe.

## Proposed execution order

1. **Correctness first:** A01/A02, explicit cross-owner occurrence/observation semantics, stable save compatibility and recoverable failures. Reproduce before changing code; preserve a genuine save around the collision. Re-export and repeat the same UI case.
2. **Bound historical work:** A03/A08 after recording representative history sizes. Cursor migration must not reschedule fulfilled/skipped occurrences or recreate money/items. Measure the same scenarios before/after; accept no claimed gain based only on less code.
3. **Clarify ownership:** A06 and minimal modal foundation from A04. Extract along real responsibilities while keeping public contracts/identities; avoid a broad rename/move-only rewrite in the same commit as a financial fix.
4. **Offline localization vertical slice:** one connected Fathi dialogue (including two choices and a named amount) plus title/settings and supplier sheet. Bundled ar_EG/en catalogs and fonts; one Ink logic graph; idiomatic English written for intent/voice. Validate choice/line ID coverage, named parameters and locale fallbacks. Canonical Ink state remains unchanged by a locale switch. Review saved active choices and frozen finance/history with both languages.
5. **UI cleanup with both languages:** common typography/spacing/theme tokens, one active modal sheet, responsive content/scroll boundaries, visible action priority, input/back behavior, number/direction handling and readable dialogue/history. Preview at960×540 and1280×720 before generalizing.
6. **Broader translation:** adapt the remaining dialogue/UI/system text only after the slice proves its authoring/save flow. Product release and documented coverage come before new hospitality/story features.

This is a proposed ordered backlog, not a claim that refactoring/localization has been implemented or that every case has passed. No new product ZIP or main merge is part of this audit-only change. Findings A01/A02 remain present in the audited published runtime; this report is not a fix release.

## Constraints for the localization/UI slice

- Source writing remains readable Ink with authored source text and explicit stable localization metadata on complete lines, choices and alternative variants. Do not key catalogs by the evaluated Arabic sentence, line number or choice index. Do not translate compiled JSON using search/replace.
- Catalog entries include translation context (speaker, interlocutor, intent, tone, situation) and named structured parameters. Translator wording may differ substantially while preserving the actual offer, price, consent and outcome. Catalogs never change conditions, add effects or grant items.
- One locale service owns supported locales, deterministic fallback, offline catalogs, font/direction/number policy and change notifications. Godot TranslationServer is a presentation integration; it does not become a narrative state owner. Existing local HTTP Web packaging is compatible with offline shipped content; hosted-browser offline caching/PWA is a separate deployment concern, not promised by bundling alone.
- Keep canonical Ink output/choices untouched for restore and effects. A localized view model resolves metadata plus captured arguments. Switching locale cannot advance a story, create a new quote, redraw random state, change a historical paid amount or repeat a heard event.
- Keep the heard snapshot of historic dialogue/receipts as recorded. New entries may additionally carry text_ref/parameters/catalog revision/original locale. Existing entries with no reliable identity retain their text fallback; no retrospective invented speech or fabricated translation IDs. Any choice to display translated history should be a read projection over known references, not rewriting original receipts.
- Archive old published stories before changing their hashes. Declare save revision changes for additive persisted references/cursors. Preserve actor/item/source IDs, existing signed terms and original amount/name snapshots. UI language/name display settings must not alter a signed counterparty name.
- Scope the first slice to Fathi's connected call and the title/settings/supplier UI. Validate the authoring/extraction/import path and active-choice saves before expanding to all11 stories and arbitrary financial system messages.
- Use existing Godot Control/Container/Theme capabilities. Build one small modal coordinator and reusable rows/sheets/tokens, not a UI framework replacement. The world clock still runs in ordinary menus; menu visibility is not a hidden pause mechanism.

## Deferred decisions

Full visual redesign/mockups, final typeface selection, hosted offline installation/PWA, broader translated narrative content, controller focus conventions and any gameplay/economy changes are outside this audit. They require their own concrete design/review. This report does not authorize discarding saves, replacing the architecture wholesale or claiming all legacy cases are verified.
