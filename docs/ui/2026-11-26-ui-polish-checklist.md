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
