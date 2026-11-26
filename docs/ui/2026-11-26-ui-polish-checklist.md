# UI polish acceptance checklist — user review, 2026-11-26

Scope: #48 / PR #57, existing UI only. The user's three screenshots and four observations are the source of this checklist. Keep all game commands, save semantics, both locales and game-first direction. Do not accept an export alone.

| Observation | Required acceptance | Status at this checkpoint |
|---|---|---|
| Storage and bags search/filter consume excessive vertical space | Compact toolbar; fields 44–64 px at 1280×720, content scroll owns remaining height | Prior head 77718d2: rendered captures and geometry gate passed. Retest after new changes. |
| Text visibly sits low/off-center in buttons and other containers | Center button text on painted face rather than shadow-inclusive cell, vertically align labels, keep intended left/right reading alignment for prose and dropdowns, align inventory/product action rows. Inspect RTL/LTR screenshots; no global forced horizontal centering of reading text. | Source changes in this pass; visual acceptance pending. |
| Dialogue speaker becomes a narrow vertical strip and obscures speech | Speaker readable on a horizontal line, separate speech area at least 80 px high, leave action accessible, real conversation text and choices | Prior head 77718d2: rendered captures and geometry gate passed. Retest after new changes. |
| Arrangement interface looks broken and form-like | Compact bottom dock, real selected object preview, readable coordinates and host selector, persistent rotate/place/store row and one close control, no accidental world movement or placement, no dead empty selector | Source changes in this pass; selected-object fixture and action-bound geometry assertions added. Visual and interaction acceptance pending. |

| Icons sit below or above the visual center even when text alignment improves (additional user review) | Normalize transparent artwork bounds within atlas cells; center icon-only HUD shortcuts on painted face, not shadow-inclusive control bounds; keep mixed native button icons vertically centered unless intentionally stacked (destination tiles). Confirm both locales via actual captures and inspect text/icon pairs wherever used. | Source changes in this pass; nine existing icon bounds measured offline, runtime geometry/atlas checks added. Exact-head review pending. |

## Verification
- Run existing real-main startup smoke and rendered capture matrix in Arabic and English.
- Review all 16 shots, then test 640×540 and other remaining screens. Verify selection, placement/rotation/store, keyboard and controller focus as appropriate, and live Web behavior. Existing teardown diagnostics (48 ObjectDB instances / 22 resources on 77718d2) remain tracked, not waived.
- No merge or version change until actual acceptance; these corrections do not imply the final game art is complete.

## Review checkpoint: 19f4792

Workflow 45746471688 succeeded. All sixteen native 1280×720 captures were downloaded and reviewed as bilingual contact sheets; the startup completion marker was present. The compact search row, horizontal speaker, selected chair preview, fixed arrangement actions and icon placement are visible in actual captures. These are meaningful improvements, not final visual acceptance. Main title/world art, recipe presentation, notebook character and content density need further polish. Resource diagnostics remain 48 ObjectDB instances and 22 resources at shutdown. This checkpoint expands qualification to 40 wide and 16 narrow captures (56 cases), retains each result in matrix.tsv, checks actual requested panel visibility and viewport bounds, and continues after individual failures. The new matrix has not yet run at this head. Empty receipts or other explicit fixture limitations remain labeled and do not establish transaction acceptance.

## Matrix runner correction — 2026-11-26

Workflow 45748157480 (d84ed85) was cancelled at its 20-minute limit. Startup passed, but every attempted capture failed to load the shared fixture due to duplicate bounds declaration at line 275. The manifest records 19 completed timeout rows; the twentieth log exists without a completed manifest row. No responsive or secondary layout result was obtained. Corrected the duplicate declaration, added a compile preflight and early exit on shared compilation errors, shortened per-case timeout to 25 seconds, and retain screenshots of geometry failures with a nonzero exit. The 56-case matrix is still pending successful execution; do not infer screen failures from the cancelled run.

## Expanded matrix result and art pass

Workflow 45756465872 at 42fd818 completed successfully: matrix.tsv has 56 passing rows, 40 wide and 16 compact, with actual PNGs. Reviewed wide English and compact Arabic contact sheets. The bounds checks passed but visual review shows restricted reading space at compact size, especially recipe and shop; notebook people remains sparse. Receipt fixture explicitly has no signed records, and v2 liver fixture uses initial availability, not injected progress. Startup still reports 48 ObjectDB instances and 22 resources at exit. This pass introduces a compact station summary and recipe-step markers derived from the real active job, reduces redundant compact shop preview chrome, and uses notebook index cards and localized-name initials rather than invented portraits. It adds assertions for active recipe markers and compact illustration sizes. The exact new head still requires captures and interaction testing; no visual acceptance, merge or release.

## Core gameplay surface acceptance (new user direction)

[Gameplay-first overlay budget](2026-11-26-gameplay-overlay-budget.md) is the current acceptance requirement for dialogue and active cooking. Both must occupy at most 25% of viewport area, preserving readable speech and all existing actions. Management sheets are exempt. Diagnostic baseline first; implementation and hard acceptance tests remain open.
