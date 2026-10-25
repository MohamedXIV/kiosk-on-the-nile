# HUD and arrangement UI delivery

Continue the approved offline UI rollout in existing work checkout. Scope: bilingual status strip, held item labels, fatigue/status tooltips; source-guarded arrangement piece/host labels, translated controls and placement policy, bounded scroll. Preserve preview request/host/rotation/position when locale changes. No gameplay/schema/Ink/economy changes. No main merge; preview publication already authorized.

- [x] Implement native controls and paired catalogs.
- [x] Compile/export and real browser Arabic/English HUD, arrangement selection/preview/locale switch at960×540 and1280×720.
- [x] One fresh final read-only reviewer; one material fix pass, no re-review.
- [x] Exact Release export, complete offline ZIP, publish source/artifact/prerelease and independently verify downloaded SHA/BUILD.

No automated tests added/run per developer instruction. Actual UI/read-only observations and build commands establish bounded coverage; document unexercised paths. Hidden sheets do not pause world time or mutate selection on language changes.

Review: one fresh read-only hud_build_review found no Critical/Important/Minor defects. Requested manual acceptance focus: long HUD at960, action row width, mounted-host locale switch, coordinate drafts/Enter. Treat unexercised cases as limitations, not passing claims.

Root UI finding/fix pass: shared wrapping key button collapsed menu width and inflated HUD height to~230px on960 Arabic. Restore nonwrapping localized menu button, minimum80px and shrink-center; retain keyboard focus. Reproduce/fix through actual screenshot; no automated tests or second review.
Root additional actual finding: arrangement HBox wrapping buttons collapsed into tall narrow strips. Minimum90×44 logical dimensions per action restore readable wrapping within bounded scroll. This and menu fix are one material fix pass; no re-review. Before-fix screenshots retained only as failure evidence.

Delivery: productc2dae7d. See docs/notes/2026-10-25-hud-build-ui.md for evidence and explicit manual coverage limits. Checkboxes refer to that bounded coverage, not an exhaustive matrix.
