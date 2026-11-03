# Game-wide cozy UI implementation plan

**Goal:** Give every existing player interface a cohesive, usable native Godot redesign for one integrated playtest (#48, superseding its original three-screen scope).
**Architecture:** UiText supplies one shared CozyTheme; SheetControls supplies responsive sheet shells, headers, cards, action roles and adaptive columns. Existing panels keep commands, snapshots, revisions and save/time boundaries. No new gameplay owners.
**Tech stack:** Godot 4.7.2, GDScript, Cairo, existing Arabic/English catalogs.
**Spec:** Issue #48 (updated 2026-11-03), Epic #47 and PR #56 design docs, docs/GAME_VISION.md; policy: AGENTS.md and docs/RELEASING.md.

## Constraints and decisions
- Ivory/sage/warm neutrals; readable dark text; clear primary, hover, focus, disabled states; 44 px controls. No ornamental illustrations, fictional meters, unit relabeling or future gameplay prerequisites.
- Work on feat/cozy-game-wide-ui from c7622bb. Commit checkpoints, open one PR to main, do not merge/release/bump VERSION.
- User explicitly authorized autonomous design/implementation; routine design approvals and plan handoff pauses are waived. Use the dedicated branch in this fresh cloud checkout; no additional worktree needed.
- Preserve gameplay/save semantics and all actions/content. Change presentation only. Add Unreleased changelog.
- Render actual controls in both locales at 1280x720 and narrower; run import/parsing, regressions and a bounded populated-scene observation. Report environment limitations explicitly.

## Shared interfaces
- CozyTheme.make() -> Theme: shared cached native theme, semantic variations Sheet/Card/Inset, Heading/Muted, PrimaryButton/QuietButton/DangerButton.
- SheetControls.shell(panel: Control, width: float=1100, top: float=122, bottom: float=18): viewport-aware sizing; no gameplay side effects.
- SheetControls.header(parent, heading, text, close): hierarchy + close, safe focus.
- SheetControls.columns(parent: Control, breakpoint: float=760) -> BoxContainer: responsive columns, collapse without shrinking type.
- SheetControls.primary(button: Button), muted(label: Label), title(label: Label), card(parent: VBoxContainer) -> VBoxContainer.
- Existing SheetControls/UiText signatures remain supported. Controls use automatic paragraph text direction with locale-based alignment; user-entered numbers stay LTR.

## Tasks
- [ ] 1. Foundation: add semantic native theme, responsive shells/columns, keyboard focus and RTL helpers. Test shared focus, locale changes and narrow bounds using real Controls before screen work; import + core regressions. Commit.
- [ ] 2. Commerce/work: convert shop/product selection/review, inventory/storage, recipe care/work/serving; retain existing quote and command semantics. Clear hierarchy, real item glyphs, responsive actions and stable scroll. Test visible screen bounds and purchase review/dismiss semantics. Commit.
- [ ] 3. Social/knowledge: convert dialogue/topics, visitors, notebook notes/people/history/accounts, payment choices. Preserve authored text, provenance and literal history; keep rich text scrollable and bilingual. Commit.
- [ ] 4. Daily life/navigation: convert title/continue/language, HUD/actions/settings/help, sleep, journeys, district, supplier schedule/contracts, arrangement and diagnostics. Preserve specialized placement and development tools; isolate diagnostics from normal menu. Commit.
- [ ] 5. Integration: inspect real rendered native and Web UI where possible, both locales and narrow sizes; fix clipping, focus/back, scroll and modal stacking. Run pinned parsing/import, full regressions, release metadata and short populated-scene observation. Add evidence, coverage checklist and testing guide, Unreleased change; final independent review and one PR. No auto-merge.

## Review focus
- Long Arabic labels, mixed Latin IDs/numbers and live locale switching.
- Narrow sheets and multi-control rows: no offscreen confirm or inaccessible horizontal scroll.
- Dismissing or replacing panels: no purchase/payment, input leakage or time freeze.
- Domain-driven refresh: preserve source lots/quotes and avoid widget reconstruction every frame.
- Continue and unsupported-save/error surfaces remain truthful; no hidden destructive reset.
