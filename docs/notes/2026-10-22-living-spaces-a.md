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
