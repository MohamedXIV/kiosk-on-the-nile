# World direction: a quiet Nile corner in the Egyptian 2000s

Design baseline recorded2026-10-28 (Africa/Cairo), under [GAME_VISION](../GAME_VISION.md). This directs subsequent work; it is not a claim that new artwork/audio has shipped or that the user has approved final art. Existing procedural visuals, assets and sounds remain in this increment.

## What the place should feel like

A small, slightly out-of-the-way place people return to, with room to look at the water. The kiosk belongs to this life. The composition should carry warmth and familiarity before the player opens it. An empty scene is a valid scene; usually no more than3–4 people total includes buyers, companions and passersby. Do not fill the frame to make it feel alive.

Keep a broad uninterrupted river/horizon, a modest kiosk and legible paths between the entrance, counter, railing and a few places to sit. Separate foreground interaction silhouettes from the far bank with value/depth, not labels floating over every object. Keep usable space visible; props do not justify obstructing existing doors, approach points or passage refuges. Navigation remains derived from placed furniture and grid footprints.

## Materials, palette and period

Use sun-faded paint, dull metal, worn timber, concrete paving, a simple kettle, glass cups, paper signs and small repaired objects. Wear should show use and care rather than turning the place into a wreck. A few specific Egyptian details are stronger than a catalogue of decorations. Use natural Egyptian Arabic with clear Cairo-font shaping; English is a complete alternate interface.

Current palette anchors, not a new asset palette already implemented:

| Role | Existing anchor | Direction |
| --- | --- | --- |
| River depth | `#091824` / `#153a50` | Muted blue; restrained reflections, visible quiet surface |
| Pavement | `#38332e` | Warm, low contrast ground; preserve feet/path readability |
| Timber | `#4e3b2b` | Worn brown with modest variations |
| Practical light | `#ffc46b` | Small warm pools at dusk; no blanket orange filter |
| Cloth | `#dfd5c6` | Off-white contrast against the counter and evening |

Aim for the early2000s through objects and everyday habits: paper notes, basic workshop tools, a small radio, inexpensive practical clothing. Avoid smartphones, QR ordering, contemporary app signage, neon café branding and postcard crowds. Do not introduce a physical story object solely because a character mentions owning it elsewhere: Farid's radio story is not proof that his radio is in the kiosk.

## Motion and attention

Small breaths, occasional looks/blinks, a slow distant boat, subtle water movement and steam are enough. Let stretches of the frame stay still. Do not add constant entrance traffic, idle speech spam or new blinking indicators to fill quiet time. Furniture and people must remain readable at the actual gameplay camera; no close-up-only asset detail at the expense of silhouette and interaction clarity.

## Sound direction

The withdrawn “no sound” report is not an open defect. Keep existing sounds. The current `content/atmosphere.json` and `Soundscape` remain the mix authority until a separately reviewed audio change.

- River is a quiet environmental bed, not a loud surf loop. Indoor/rooftop perspective remains different from the corniche.
- Kettle, griddle/sizzle, oven and fan belong to actual active equipment. An idle appliance does not keep cooking noise running.
- Radio belongs to an enabled, physically placed radio in the current location. Do not turn it into a compulsory soundtrack or imply Farid's offscreen repair enables the player's radio.
- Pour/coin/chime cues identify actual committed actions. Keep them brief and avoid a reward-jingle feeling on every social line.
- Preserve natural quiet gaps. No persistent market chatter, traffic/horn loop or unseen crowd to manufacture activity. Do not add unlicensed period songs; any future recording needs a recorded license/source.

Retain player/browser mute and autoplay constraints. Numerical gains are not loudness acceptance: listen on speakers and headphones, with browser audio activated by real input, before signing off a future mix.

## Next production gate

Before replacing assets, review a small scene sheet of the same place in afternoon/dusk/night, at the normal camera and with0,1 and3 people. Show the counter, water, player feet and actual approach routes. Compare one modest prop set rather than changing every material at once. Capture the same gameplay view in Arabic/English to check signs and silhouettes.

For sound, compare a short real-input capture of empty river, active preparation, conversation and rooftop rest. The person reviewing should be able to hear the source, leave it behind and experience silence without a warning or music filling the gap. These are future human acceptance criteria, not automated suites or completed evidence in this batch.
