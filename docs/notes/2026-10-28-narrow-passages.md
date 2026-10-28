# Bounded narrow-passage coordination

## Scope

Implementation on `feat/narrow-passage-coordination`, based on merged main `f623e5d`. A per-location transient coordinator assigns a stable winner and a yielding NPC after sustained lack of goal progress. A brief side oscillation is not treated as forward progress. It checks at most ten nearby candidate endpoints, each within2.5 ground units, with a separate3.5-unit grid-route length budget. The selected route is cached and followed as a temporary physical target; visit/meeting/domain goals remain owned by their services.

Only unprotected NPCs may retreat. Speakers, seated people, active peer/meeting participants and the externally controlled player cannot be displaced. The winner waits for the refuge before proceeding. Goal, protection, despawn, teleport and layout changes cancel transient coordination. Acquired pairs expire after8 simulation seconds; retries have a3-second cooldown. If no safe refuge exists, cached movement waits and rechecks on the cooldown. Such a corridor may remain blocked until its occupant or layout changes; there is no universal deadlock-free guarantee.

## Configuration and paths

`spatial.avoidance.passages` is optional; missing/disabled retains ordinary local avoidance. Shipped settings: delay0.9s, max8s, retry3s, detection1.8 units, radial retreat2.5, route distance3.5, pocket margin0.15, arrival0.12, progress ratio0.15, candidate cap10. Progress resets the wait only after the goal-distance improvement exceeds speed × delay × ratio. Arrival radius must match the follower's navigation radius; invalid finite/bounds/geometry/timing combinations reject content.

Grid routes and native RVO remain, without a NavMesh. A retreat path's initial grid center is skipped only when the next segment is statically and physically clear; the follower receives that exact validated cached route. This matters behind the real kiosk: `(3.5,-2.85)` maps first to `(3.5,-2.75)`, which approaches the blocker, whereas the next grid waypoint escapes safely. Endpoints retain passing margin; route segments allow physical-diameter clearance near an existing contact. RVO remains approximate and is not a hard minimum-separation guarantee.

Dynamic coordinated waits do not trigger the existing domain fallback that could discard meeting/seat intent. Ordinary static route recovery outside coordination remains unchanged. No narrative content, localization text, save schema, migration, population, economy, version or release asset changes are introduced.

## Environment and verification

The stale initial checkout and apparent proxy failure were resolved by using the execution tool's network permission. The tracked `tools/setup.sh` installed SHA256-verified Godot4.7.2, Web templates, Ink and dependencies under the project's cache. `tools/godot.sh --version` reports `4.7.2.stable.official.ed1daf0bf`; `release.py toolchain` verifies the actual installed bytes against the pinned upstream archives. The unrelated global executable need not be replaced; project commands always select the pinned cache binary.

The tracked build-only Release gate completed on the implementation draft (324 stable Ink localization references, verified engine/templates, editor import and Web export). The final committed-source build and PR CI are recorded separately after execution. No automated test suite was added/run, and no historical-save acceptance work was performed.

## Bounded runtime observations

These are manually invoked scratch runtime scenes, not a shipped gameplay suite. Logs retained under `evidence/2026-10-28-passages/` identify individual runs.

- Before coordination, two opposing actors in a0.7-unit raw corridor remained at the bottleneck through15 simulated seconds. With cached retreat coordination, both reached their original goals. A final run used one acquisition and four total grid path queries (one candidate search); maximum per-step displacement stayed at speed ×1/60s.
- An idle blocker stepped aside, then returned within ordinary arrival tolerance; the mover reached its goal. A protected speaker/player fixture kept the protected point fixed. An open-space observation needed no coordination and retained two domain path queries.
- In a corridor with no refuge, both actors held their cached routes with bounded retry work, rather than continuing the old RVO drift. No refuge can mean persistent waiting; safe movement is not fabricated.
- A real `GameSession`/`PhysicalWorldController` fixture uses shipped content and actual placed kiosk walls. Near railing_2, an idle visitor at `(3.5,-2.85)` yielded for a visitor approaching from `(2.5,-2.85)` toward `(6,-2.85)`, then returned. One pair was acquired with four bounded candidate route searches; both domain destinations were unchanged. A more central long-wall fixture had no nearby legal refuge and held its route without changing its domain goal.
- Separate goal/layout/despawn observations exercise cancellation and cached-route reconstruction. These are bounded observations, not broad gameplay regression or hardware FPS acceptance. Existing native RVO may briefly compress visual separation during conflict/reconfiguration.
- The production-session scratch teardown reported46 ObjectDB instances/21 resources still in use. No general lifecycle leak fix or leak-free claim is made; focused standalone movement observations freed their maps without that session warning.

## Independent review

A read-only reviewer found no Critical issue. Its Important configurable arrival-radius mismatch was fixed by matching the validated follower/coordinator thresholds; a native content observation rejects0.08 vs0.12. Its diagonal candidate coverage minor was corrected by fitting the forward component within the configured radial bound. Further production observations motivated retaining the exact validated retreat path and measuring sustained net progress. Targeted review of the final path integration found one further Important issue: replaying the original retreat prefix after a static stall could create an unvalidated connecting segment. The follower now preserves its retreat cursor on such stalls; pair expiry/layout/protection still owns cancellation. A bounded held-motor observation retained cursor2 through ten simulated seconds with no retry/path replay. Both Important findings and the candidate coverage minor are addressed. The reviewer ran no builds or gameplay checks.

## Acceptance status

Source integration and playable preview acceptance are still pending for#3. No merge to main, source branch deletion, tag/version bump or replacement archive is part of preparing this PR. Player control and immutable `v0.1.0-prealpha.2` remain as published.
