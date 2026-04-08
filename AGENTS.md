# AGENTS.md

Use `README.md` as the source of truth for this repository.

Repo-specific notes for agents:
- Keep `README.md`, `action.yml`, and `swift-syntax-compatibility-check.sh` in sync when changing inputs or behavior.
- `.github/workflows/update-swift-syntax-versions.yml` rewrites the tracked version arrays in `swift-syntax-compatibility-check.sh` and the generated version matrix block in `README.md`.
