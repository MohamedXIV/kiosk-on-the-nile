# Narrow passage coordination implementation plan

> Execute inline with superpowers:executing-plans. Read AGENTS.md and docs/RELEASING.md. User requests independent execution and no automated test suites; use tracked build-only checks and bounded runtime observations instead of TDD/suite steps.

**Goal:** Let blocked NPCs agree on a stable right of way and a nearby safe retreat without moving speakers, seated people or the player.

**Architecture:** A transient per-location coordinator consumes actor snapshots, detects sustained nearby blockage, and chooses one bounded retreat target. Controllers overlay that physical target on the cached follower without changing domain goals. Existing grid, collision and RVO remain authoritative; no save fields or NavMesh.

**Tech stack:** Godot 4.7.2, GDScript, external spatial JSON.

**Spec:** Issue #3 and docs/GAME_VISION.md. User authorized starting this batch after PR #12; merged baseline f623e5d. Requested independent execution supersedes repeated design approval prompts.

## Constraints and review focus

- No teleport, per-frame path searches, forced speaker/player movement, save reset, historical-save work or automated suites.
- Stable pair ownership, cancellation on protection/despawn/layout/goal change, and bounded retries when no refuge exists.
- Check temporary targets cannot trigger domain arrival or unrelated failure effects; original domain goals remain owned by service systems.
- Multiple actors must not reserve the same refuge; candidates and their routes must avoid other people and raw solids.
- Finite timing/geometry settings and old missing/disabled configuration must remain safe.

## Tasks

- [x] Implement PassageCoordinator in game/world/passage_coordinator.gd: configure/settings, step(snapshots, navigation, delta), target(id, original), route(id), waiting(id), active(id), forget(id), clear(), status(). Cache pair selection and failed-search cooldowns. Search a fixed bounded candidate list, reject unsafe/long routes, hold winner until loser reaches refuge, then release when winner clears.
- [x] Integrate at NpcAvoidanceWorld/controller snapshot boundary. Explicit protected flag defaults to true; only known unpaused NPCs opt in. Apply temporary movement targets and suppress dynamic fallback during active coordination; existing static failures outside traffic remain unchanged. Preserve cached paths on wait and replan only on target transitions.
- [x] Add optional data-driven passage settings to spatial avoidance configuration and bounded content validation. Add changelog/save-impact and delivery notes.
- [x] Verify pinned toolchain and tracked Release build; observe narrow opposing, idle blocker, protected speaker/player, no-refuge, goal/protection/revision cancellation and ordinary passing. Record actual outcomes, not general regression/FPS claims.
- [x] Obtain one independent whole-branch read-only review; address material findings, prepare a reviewable PR with exact evidence (PR publication/CI tracked separately after this source commit). Keep main, published tags/assets and artifacts history intact.

## Execution decisions

- User-authorized independent execution and the explicit no-suite policy supersede skill approval/TDD prompts. Verification is build/content/import/export plus bounded native observations.
- A separate route_distance budget bounds grid detours independently of radial retreat_distance; all work remains cooldown/candidate bounded. Cost if too conservative: waiting where a farther refuge exists.
- No-refuge holds may persist until the blocker/layout changes; they do not fabricate passage or displace protected people. RVO remains approximate, without a hard global minimum separation guarantee.
- Independent whole-branch plus targeted new-route review returned two Important findings and one minor; all addressed. Source acceptance and main integration remain separate.
