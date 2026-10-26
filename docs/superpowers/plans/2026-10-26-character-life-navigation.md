# Character life and bounded navigation recovery

**Goal:** approved quiet character presentation, reliable movement and rare leisure changes without NPC bustle.
**Execution:** inline on existing isolated `work` branch; user approved the four-step proposal with “عظيم ابدأ”. No further design gate or main merge.

## Decisions

- Keep AStarGrid2D and CharacterBody2D. A shared NPC path follower caches destinations, observes actual waypoint progress, pauses during conversations and replans after an authored timeout/cooldown with bounded attempts. Layout revision or a new destination resets the budget.
- Exhausted routes request a domain-owned alternative: another valid leisure marker/exit, or abandon an unplaced purchase approach. Never teleport, fabricate arrival, cancel a paid order, or retry every frame. If all routes are obstructed, wait until a layout/destination change.
- CharacterView owns blink, breathing and small idle eye glances, using a separate cosmetic RNG and render time. It never mutates saved ActorPose or consumes gameplay RNG. Stationary feet remain anchored; hidden visuals stop updating. All timing/amplitude controls live in spatial JSON.
- Quiet leisure changes are rare and capped per visit, only while settled, not purchasing/awaiting service/in conversation. Select an unoccupied reachable authored marker. Persist its small schedule/selection state and retain old saves through explicit revision13 migration.
- Configuration readers retain safe disabled defaults for external old content; optional new blocks are validated when present.

## Work

- [x] Implement and validate data-driven character idle presentation.
- [x] Add cached NPC path following, recovery and domain fallback for visitors/residential actor; invalidate on arrangement changes.
- [x] Add rare quiet leisure policy and revision12→13 migration preserving existing destinations and existing gameplay RNG.
- [ ] Inspect runtime observations, import/build, actual Web movement/idle/save/Continue and bounded performance captures. No automated tests/suites without user request.
- [ ] One fresh final code review and one material fix pass, then publish a complete pinned GitHub Web preview.

## Review focus

Pause versus blockage; empty/truncated routes and unreachable endpoints; unchanged goal/layout after retry exhaustion; successful fallback/exit semantics; layout invalidation; cosmetic versus gameplay randomness; hidden/reduced frame-rate visual updates; pending orders and conversation holds; persisted leisure schedules and legacy save migration.
