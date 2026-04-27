# AGENTS.md

Use `README.md` as the source of truth for this repository.

Repo-specific notes for agents:
- Keep `README.md`, `action.yml`, and `swift-syntax-compatibility-check.sh` in sync when changing inputs or behavior.
- `.github/workflows/update-swift-syntax-versions.yml` rewrites the tracked version arrays in `swift-syntax-compatibility-check.sh` and the generated version matrix block in `README.md`.

Release strategy:
- Treat changes to the tracked `swift-syntax` version matrix as minor releases, because they change the observable behavior of the action for consumers.
- Use patch releases for fixes that do not change the action inputs or tracked compatibility matrix.
- For each release, create the exact SemVer tag (for example `v1.1.0`) and the matching minor tag (for example `v1.1`).
- Move the floating major tag (for example `v1`) to the latest release in that major line so users pinned to the major tag receive updates.
