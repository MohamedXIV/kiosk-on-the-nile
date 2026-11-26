# Small-screen UI polish — implementation checklist

User review of the actual 640×540 Arabic contact sheet: oversized menus and text, excessive negative space, clipped-looking dialogue. 640×540 is a compact logical viewport, not a qualified mobile device. Keep desktop presentation and all game commands. No new gameplay, no save changes, no release.

- [x] Fix prior capture preflight parse failure (workflow 45764894396; typed tracks explicitly; actual startup passed before capture preflight failed).
- [x] Separate compact Theme profile, reduced panel/heading/tab padding, shared spacing, preserved 44 px interactive button targets; no blanket font scaling.
- [x] Compact bottom dialogue sheet: current line first, choices scroll, leave beside speaker, optional earlier lines accessible through a disclosure, no changes to Ink or domain history. Desktop retains recent lines and footer leave. Minimum reading region 144 logical px.
- [x] Smaller clock and compact HUD badges; retain shortcuts and actual meters. Compact storage toolbar shares a row when space permits, smaller item tiles, more reading space in shop, cooking and notebook, wider arrangement dock.
- [x] Add geometry assertions for compact dialogue current-line visibility, bottom placement, reading height, history disclosure, HUD icon/touch targets and clock size. Existing 56-case matrix retained.
- [ ] Verify exact-head CI and inspect compact screenshots in both locales; review long dialogue and choice lists, resize between layouts, scrolling, touch and actual browser/mobile behavior. Add representative landscape phone aspect ratio tests after the compact baseline is verified.
- [ ] Full interaction suite, cleanup diagnostics and visual acceptance. Prior 42fd818 passed 56/56 geometry cases; 5d1f7e5 did not pass fixture preflight. The current source changes are not yet tested.

Density decisions: width <740 or height <580 logical pixels; normal body 15 vs 16, dialogue 16, compact HUD clock 86 vs 104, maintain existing 44 logical px action targets. These are provisional based on user screenshot, not claimed physical touch sizes. No portrait phone support claim. Long speech remains scrollable; the deterministic fixture checks its current line is fully visible for the existing short authored beat. No merge until user accepts.
