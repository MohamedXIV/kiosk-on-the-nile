# Kiosk on the Nile — Game UI Bible v0.1
Approved direction: 2026-11-25 (Africa/Cairo). Status: design contract, not implemented or shipped.
Tracking: [Epic #47](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/47), [Issue #48](https://github.com/MohamedXIV/kiosk-on-the-nile/issues/48), [implementation candidate PR #57](https://github.com/MohamedXIV/kiosk-on-the-nile/pull/57).

## 1. Why the direction changed
Human playtesting of the first game-wide cozy UI candidate exposed a fundamental problem: a consistent ivory/sage theme and native controls are useful infrastructure, but the resulting screens still feel like a web application or management dashboard rather than an authored cozy game. The user also rejected the oversized typography, single long side menu, repetitive colors/text treatment, and generic-looking split-page title art in subsequent visual experiments.

This document is the **current visual and interaction design authority**. It supersedes the visual interpretation of the November 3 [cozy menu contract](2026-11-03-cozy-menu-design.md) wherever they conflict. Its functional, accessibility, ownership and safety requirements remain valid, as do the [game vision](../GAME_VISION.md), [product direction](../roadmap/2026-11-03-cozy-gameplay-ux.md) and [integration audit](../architecture/2026-11-03-market-object-commerce.md). No existing gameplay feature is deleted or replaced by this decision.

The accepted earlier menus-only reference and the five game screenshots supplied on November 25 are complementary inspiration: the former demonstrates clear illustrated product tiles, layered panels, readable hierarchy and warm colors; the latter demonstrate characterful speech bubbles, a circular time HUD, object-specific care screens, a physical map, blueprint-like screen composition and a receipt that looks like a real receipt. These are **reference principles, not assets to copy**, not a request for bike upgrades or animal care, and not proof of any gameplay mechanic in this project. Reference images remain in the design conversation; no third-party screenshots or artwork are redistributed in this repository.

## 2. Core visual rules
- **Game-first, not web-first.** Do not build a web dashboard with a cozy reskin. Avoid giant sidebars, full-width administrative status strips, identical card stacks, generic forms, uniform text treatment and unnecessary nested panels.
- **Screen identity.** Every screen has a composition appropriate to its purpose: notebook, bag, recipe station, shop, map, receipt, speech bubble. Shared visual vocabulary does not require identical panel layout.
- **World-first.** The Nile, kiosk, people and quiet moments remain central. Keep normal play unobstructed; show secondary information in context.
- **Authored character.** Use illustrated icons, tangible frames, short offset shadows suggesting thickness, intentional color accents, subtle animation and varied text weights. Prefer legible, restrained charm to noisy decoration, AI-looking generic imagery or stereotypical Egyptian motifs. Wood/paper textures can be appropriate when motivated by the screen, not as mandatory decoration.
- **Truthful UI.** Never invent resources, currencies, relationships, progress, discounts or available features from a reference image. No cosmetic substitute for actual stock, consumption, time or payment.
- **Preservation.** Evolve the existing native Godot UI infrastructure; retain all gameplay, recipes, capabilities, existing route access, data ownership and save semantics. Do not introduce a second UI/gameplay state owner.

## 3. Visual vocabulary and proposed tokens
These are approved starting directions, not final color/size mandates. Adjust after native rendered review, maintaining contrast and accessibility.

| Token | Starting color | Intended role |
| --- | --- | --- |
| Cream | #F5E8CE | Paper and warm light surfaces |
| Sand | #E4C99F | Secondary surfaces, tabs and quiet controls |
| Caramel | #B48A5D | Frames, physical object details |
| Dark brown | #543C2B | Ink, outlines, strong text |
| Olive | #78964B | Positive action and healthy state |
| Nile blue | #37818A | Navigation, information, differentiated screens |
| Terracotta | #C45D36 | Back/cancel or attention where semantically appropriate |
| Mustard | #E5B94E | Highlights, time, selected details |

Use color selectively, not every accent at once. Primary action, neutral/back, attention/error, disabled and selected controls require visually distinct states; use symbols/text as well as color. Adjust foreground/background pairings for contrast rather than assuming white text is legible on every accent.

Provisional logical-pixel scale at 1280x720:

| Role | Size (px) |
| --- | --- |
| Main game title | 36–44 |
| Screen title | 22–26 |
| Section heading | 18–20 |
| Body and buttons | 14–17 |
| Compact HUD labels | 12–14 |

The user specifically asked for a smaller, calmer type scale than the existing build. Use varied weights and ink/secondary/muted/accent colors; preserve Arabic shaping and comfortable reading. Do not shrink hit targets with font sizes (retain touch-friendly target sizes, e.g. existing 44px baseline). Evaluate smaller logical viewports with reflow, scrolling or alternative layouts, not indiscriminate scaling.

## 4. HUD and navigation
A compact game HUD composed of several independent pieces, not a single web-like header:
- A distinctive circular or similarly crafted clock/day element. Sky appearance can follow existing day periods; show actual day and time, without inventing an energy resource or modifying time.
- Wallet as a compact independent piece with an appropriate money icon and actual balance.
- Small differentiated hunger/satiety, rest and mood indicators mapped to actual needs; secondary details/tooltip on demand; meaningful warnings remain visible and understandable.
- Direct illustrated shortcuts for inventory/bag, notebook, outings and settings. Other legitimate actions should remain reachable through appropriate contextual controls or a small grouped secondary menu. Do not force all actions through one giant sidebar.
- Kiosk open/closed state and critical business/sleep warnings remain truthful; held item information appears when relevant, with existing consume action available.
- Contextual prompts near the interaction where practical; avoid unnecessary permanent station status lists covering the world. Retain actionable cooking/cleaning status and existing input/availability rules.
- Respect occlusion, RTL/LTR positioning, existing modal priority and focus. Do not let the navigation cover the world by default.

The earlier HUD sketch is a layout illustration only. Exact anchor positions, icon appearance, clock dimensions and the small-screen arrangement require rendered testing.

## 5. Screen-by-screen design
### Main menu / title
Prefer a real scene from the game's world: the kiosk and Nile at a pleasant time of day, with a carefully composed game title and a small set of readable actions. Avoid a split landing page, generic geometric sunset/postcard or stock-style AI art. Use genuine game resources and a non-mutating presentation of the world, if feasible; do not start or overwrite a save merely to show the title. Preserve New, Continue, language, loading and error behavior. Exact staging and final title artwork remain open.

### Notebook / journal (الكشكول)
A physical notebook metaphor: page surfaces, colored page markers and recognizable character entries/portraits when available. Distinct sections for people, learned facts, stories/history, accounts and receipts; clear page navigation and meaningful empty states. Keep actual source-backed knowledge, filters, paging, relationship information and records. Do not present invented portraits or relationships as canonical facts.

### Inventory / bag
An illustrated item grid with visible actual quantities, readable selection and distinct container identities. Details and actions appear for the selected item/lot; avoid dumping every attribute into every cell. Retain container selection, search/filter, reservations, location, grade/source/freshness, packing, held items and storage actions. Do not merge different lots or display new measurement semantics before #51 delivers them.

### Cooking / recipe station
Make the device/utensil the focus of its own screen: illustrated ingredient requirements with real amounts, a clear preparation sequence or current stage, heating/waiting/progress, and contextual serving actions. A kettle, fryer, oven and ful pot may have distinct layouts and shared components. Present existing workflow honestly; actual persistent empty cookware, new object-entry semantics and changes to recipe execution are #52 (and related quantity work), not silently shipped by UI #48. The counter remains intended for actual preparation in the target design. Preserve all existing cooking pathways.

### Shopping
Recognizable illustrated products, price tags, actual availability, meaningful categories and an uncluttered selection/review area. Use a tangible shopping/ordering metaphor rather than a database form. The eventual basket is a distinct visual object with editable lines and real total per store (#49); do not simulate a cart or multiple purchases in the UI while the existing single-selection backend-facing flow is still being used. Preserve current quote validation, receipt, wallet/stock feedback and return.

### Outings / travel
A small illustrated destination board or map-like composition for the currently available routes, with recognizable kiosk/home/market/district and existing store destinations. Only expose routes that are valid in actual state. Later #50 introduces the already agreed static clickable six-shop market scene, independent per-shop checkout, one trip, explicit return home/kiosk, no character movement in the hub. Do not conflate the current outing UI with implementation of that future hub.

### Dialogue
Compact, soft, characterful speech bubbles with colored speaker-name pieces, short readable choices and clear continuation/leave affordances. Keep the world visible and, where practical, relate speech to the speaker without sacrificing legibility or screen safety. Preserve authored Ink choices, interruptions, listen/leave, speaker identity and existing world-time behavior. No fake conversation history or invented relationship gain.

### Receipts and feedback
A small receipt-like paper surface for actual settled purchases/charges with true lines, total and confirmation. The existing accounts/journal remains the record. Toasts, notices, error and confirmation prompts should have character, clear meanings, concise text and predictable dismissal. No new transaction or receipt owner.

### Arrangement / furniture
World-visible placement mode with illustrated item strip or tray near an edge (e.g. bottom), contextual rotate/move/store controls and real placement validation. Keep sufficient room to see the location being arranged; preserve current position/host/rotation rules.

### Remaining existing screens
Supplier, district/payment, menu pricing, sleep, needs/help/settings, journey, hospitality/visitor actions, title/loading, tuning and diagnostics must retain functionality and participate in the same visual vocabulary. Design purpose-specific compositions: e.g. supplier order sheet, payment slip, sleep/wake preview. These are proposed metaphors, not new gameplay behavior. Development diagnostics stay accessible but separate from ordinary player navigation.

## 6. UI Asset Kit and Godot implementation
Create an original, reusable, modest-size asset kit appropriate for the existing 2D game and Compatibility renderer. Use the native engine, not HTML/CSS or a parallel framework:
- NinePatchRect and StyleBoxTexture for scalable illustrated frames and button states, with correct patch margins.
- TextureRect and original SVG/PNG illustrations for recognizable items, objects, navigation icons and ornaments.
- TextureProgressBar or equivalent custom control for actual needs, time and progress.
- Existing Theme/CozyTheme, UiText and SheetControls for shared tokens, typography and input behaviors; evolve instead of adding competing themes.
- Existing LocaleService and ModalCoordinator for RTL/LTR, focus, modal priority and navigation.
- Small custom Controls for specialized clock, page/book and speech-bubble presentation where useful; no new domain state owners.
- Short restrained Tween transitions where appropriate; avoid input interference, per-frame tree rebuilding and unnecessary textures/shaders. Preserve accessibility and performance.

Asset kit needs: frame/paper variants, tabs/page markers, button states, close/back controls, small status icons, clock/day artwork, item glyphs and grid slots, selected/disabled indicators, speech/receipt surfaces. Exact asset count, art production method, licensing and final typography remain implementation decisions. Use original or verified licensed assets; do not copy reference game art or commit unlicensed font/art files. Current Cairo font may remain while typography is evaluated; any alternative must support Arabic and English and have appropriate licensing.

## 7. Delivery sequence
1. UI Asset Kit + shared visual vocabulary.
2. HUD, clock, direct shortcuts and contextual prompts.
3. Main menu using real game-world presentation.
4. Notebook, dialogue and inventory.
5. Shop, cooking and outing interfaces.
6. Remaining existing UI, receipts, feedback, arrangement, settings and specialized screens.
7. Integrated playtest and visual acceptance in Arabic and English.

These are internal implementation checkpoints, **not a reduced three-screen scope**. The user previously explicitly requested the complete existing UI in one integrated batch. Continue the existing #48/PR #57 work or use a clearly related review branch if needed; keep coherent checkpoints, no auto-merge of implementation, and preserve all existing systems. No implementation or version bump is authorized by this documentation commit itself.

## 8. Acceptance gates
- Human visual review is mandatory; a unified Theme, zero assertion failures or screenshots alone do not establish acceptance. Compare real gameplay before/after with the design references, not an isolated mockup.
- Show actual rendered title, HUD and every existing player-facing screen at 1280x720 and representative smaller logical sizes, in Arabic and English. Verify no clipping, overlap, unreadably small text, ambiguous RTL money/numbers or hidden critical information. Screenshots are evidence, not a substitute for interaction testing.
- Test direct shortcuts, focus, mouse/keyboard/touch where available, Escape/back, scroll, modal priority and safe cancellation; keep all existing actions reachable. Confirm underlying commands, wallet, stock, cooking, time, save/continue and knowledge remain authoritative.
- Reuse real project source and pinned Godot 4.7.2 for reproducible checks. Clearly distinguish exported-build playtest, local script-overlay prototype, full source build and Web/native evidence. Do not claim unperformed checks. Record existing resource-teardown diagnostics separately from assertion results.
- Keep future #49–#54 scope explicit; no fabricated completion or new backend. Review performance in a representative actual world scene and investigate regressions if observed.
- Record remaining issues, implementation decisions, exact commit/build, and coverage in the PR. Issue #48 stays open until the owner accepts the integrated experience.

## 9. Decisions still open
Exact font families/weights, final palette adjustments, art production and asset dimensions, title scene framing, HUD micro-layout, animations, individual page compositions and small-screen reflow. These may be chosen during implementation consistent with the approved direction and checked visually. The references and initial palette/type scale are not pixel-perfect specs. No new screenshots are claimed or attached by this documentation-only change.
