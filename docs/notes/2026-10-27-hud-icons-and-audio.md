# HUD icons and reported missing audio

## Requested changes

Remove the legacy tea/liver inventory summary from the status strip, add needs/time-of-day icons, investigate audio silence and check that performance work has not removed gameplay. Leave the reported stationary-person bottleneck behind the kiosk for a later coordinated-passage slice if it needs more than a small proven fix.

The stock row removal is presentation only: actual ingredients, inventory, shopping, recipes and orders remain. Needs keep their existing names, colors and values, with bundled SVG icons rather than platform emoji/fonts. A clock-adjacent icon represents night/morning/noon/afternoon/evening; tooltips are localized in both shipped languages. `content/ui.json` → `hud.icons` authors paths/size/period start minutes and labels. Textures load once during configuration; the phase texture changes only at a phase boundary. An omitted optional block retains text-only presentation. Invalid paths, missing need entries, unordered starts, missing midnight coverage or invalid labels reject the content bundle.

## Audio investigation

The reported public source is `d17a4978adfe2a524f10109a879adffc6684689f`. Its navigation change did not edit Soundscape, application sound calls, audio configuration, WAV imports/assets or export policy. Relative to the earlier performance source `f5da764`, no game/content/asset files were deleted. All11 current authored Ink stories and prior systems remain present; this file/source audit does not establish complete behavioral regression coverage.

The existing Release was served at the same QA origin/profile in Chromium with SwiftShader. Browser Web Audio instrumentation recorded **all** nodes connected directly to AudioContext.destination via a parallel zero-output analyser branch; normal output connections remained. No game state bridge or injected save was used. After an actual Continue click, the context was running and the sample/master output had peak0.0501/RMS0.0207; the separate stream/worklet output was zero. Recording only the last destination connection initially gave a misleading zero, so that observation was discarded in favor of measuring every destination input. The WAV source files also have nonzero PCM amplitudes.

Thus complete silence was not reproduced here and no speculative audio/backend/volume change is shipped. This proves a nonzero signal inside Chromium's graph, not audible output on the user's Windows/device or Chrome site-mute state. The user confirmed Chrome and silence from the start; the user subsequently confirmed that sound works again and withdrew the report (possibly a transient/local issue). [Browser measurements](evidence/2026-10-27-hud-icons/audio-chrome-before.log). No code fix or root cause is claimed for the transient user-side silence.

## Navigation and compatibility

The real report behind the kiosk confirms the existing limitation: a fixed person may occupy the only traversable width. Robust retreat/right-of-way needs coordination beyond RVO steering. Navigation is unchanged in this slice; no extra per-frame paths or global player-pushing workaround was added. Save schema4/revision15 remains unchanged.

No automated gameplay suite was added or run. Build and actual browser observations will be recorded below. The source audit and bounded observations are not a guarantee that every prior feature has no defect.

## Native observations

Content loaded with all new SVG resources. Phase boundaries at0/359/360/719/720/900/1080/1260/1439 selected the expected authored texture and localized label. An actual locale change refreshed the tooltip without a time change. HUD presentation left the ingredient inventory equal. Missing midnight coverage and missing SVG path were rejected; old external UI without the optional icons block was accepted. The production physical-world lifecycle observation still removed the player from old/travel maps and freed maps at teardown. These short native fixtures reported46 ObjectDB instances/21 resources still in use at exit; they are recorded, not presented as a general leak diagnosis.
