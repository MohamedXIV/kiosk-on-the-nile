# Project conventions

These instructions apply throughout this repository, including work delegated to subagents. Before editing, read this file and `docs/RELEASING.md`; include both paths in delegated task handoffs. Nested instructions may add detail but must not silently override these project-wide policies. If an older plan conflicts with the pre-alpha save policy below, follow this policy and the user's latest instructions.

- The game is **unpublished pre-alpha**. Read `docs/GAME_VISION.md` for design and `docs/RELEASING.md` for release policy.
- Historical save compatibility is optional during pre-alpha. Do not add migrations, archived Ink graphs or old-save regression work solely to preserve unpublished saves unless explicitly requested or justified by a concrete current need.
- Preserve save integrity and clear unsupported/corrupt-save handling. Never silently delete or reset a user's save.
- `VERSION` is the project-version authority. Synchronize Godot metadata with `python3 tools/release.py set-version <version>`; do not duplicate the version in code.
- Add user-facing changes to `CHANGELOG.md` under `Unreleased`; record each release's save impact explicitly. Internal save schema, engine version and game version are separate.
- Follow the prospective Conventional Commit style described in `docs/RELEASING.md`; do not rewrite legacy history. Published tags/assets are immutable.
- Build/package through the tracked tools. Keep all playable archives on the existing `artifacts` branch; do not merge artifact history into source or create a branch per build.
