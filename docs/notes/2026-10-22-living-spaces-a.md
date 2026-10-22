# Living Spaces A — execution evidence

- Baseline: `49c241a`; Native execution approved 2026-10-22.
- A1 introduces canonical ItemStore ownership, transactional candidates, inventory projections and owned fan instances. Supply purchases validate capacity before payment.
- Build: `bash tools/build.sh --out /tmp/kiosk-living-a1` completed successfully. Subsequent dependency adjustment passed native Godot import.
- Automated tests were neither added nor run, per session instruction.
- Manual cooking/serving/reload and viewport acceptance are pending; import/export success is not gameplay acceptance.
- A2: shared grid placement, structural door state, six counters, mounted legacy stations, kiosk fridge and owned home furniture wired to rendered geometry and navigation. Moved standing markers invalidate NPC paths without replaying arrival dialogue/orders.
- A2 builds `/tmp/kiosk-living-a2` and native application boot succeeded. A real Chromium Web session reached title and New Game; screenshot `/tmp/kiosk-living-home-a2.png` shows the home/partition/HUD. No script error appeared in browser console during this observation. Placement/trap/door acceptance remains pending until A4 exposes player arrangement.
- A3: editor dock and shared layout document added. Godot import/Web export `/tmp/kiosk-living-a3` succeeded with plugin enabled and excluded from player pack. Interactive editor add/undo/export/reopen acceptance not yet performed.
- A4: player arrangement menu, placement preview/rotation/storage, mounted equipment selection and counter food transfers now use shared services. Food on a surface retains the same item ID/quality and has a world visual. Explicit surface access checks prevent remote pickup; confirming placement rechecks current actors.
- A4 build `/tmp/kiosk-living-a4` succeeded. Manual arrangement/surface cases remain open for the integrated A5 build.
- A4/A5 live observation at 1280×720: moved the bed from its initial grid position to `[-10,1]`, confirmed the geometry moved, exited arrangement, and saved through the normal menu. Screenshots `/tmp/kiosk-living-bed-move-a.png` and `/tmp/kiosk-living-saved-a.png` record the action and save acknowledgement.
- The arrangement panel initially clipped its close button at 720p; changed vertical growth and layout direction. Mounted devices/food now render as children of their supporting counter so depth sorting does not hide them.
- A5: final import/export `/tmp/kiosk-living-a-final` succeeded. Schema 4/revision 1 restores canonical items/layout before jobs and narrative; legacy 1–3 flow and raw-byte digest support retained.
- Migration ruling: previously valid excess stock goes into `legacy_purchase_bag` rather than being dropped or granting extra permanent storage. It requires unpacking through B1 when storage has room.
- Still pending: full legacy active-job/Ink restore, food surface transfer cycle, NPC obstruction and interactive editor authoring evidence. These remain open acceptance items; no automated suites run.
