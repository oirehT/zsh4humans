---
summary: Contributor-oriented index for the internal architecture, file map, feature ownership, and verification workflows in this repository.
read_when:
  - You are new to the repository and need a fast way to find the right doc.
  - You need contributor-facing context that is more detailed than README.md and tips.md.
---

# Docs Index

This `docs/` tree is for contributors and maintainers. It complements the
project's user-facing docs instead of replacing them.

Use the existing top-level docs for end users:

- [`README.md`](../README.md) explains installation, day-to-day usage,
  customization, and update basics.
- [`tips.md`](../tips.md) collects advanced usage and configuration examples.
- [`changelog.md`](../changelog.md) records shipped changes.

Use the docs in this directory for codebase navigation:

- [`repo-map.md`](./repo-map.md) is the quickest way to understand what every
  top-level file and directory is responsible for.
- [`runtime-flow.md`](./runtime-flow.md) explains how startup, install, update,
  tmux boot, and SSH teleportation fit together.
- [`feature-map.md`](./feature-map.md) maps user-visible features and `z4h`
  commands to the files that implement them.
- [`testing-and-maintenance.md`](./testing-and-maintenance.md) lists automated
  checks, manual verification paths, and the repo's maintenance habits.

## Reading Order

If you only need a quick orientation:

1. Start with [`repo-map.md`](./repo-map.md).
2. Continue with [`runtime-flow.md`](./runtime-flow.md).
3. Jump to [`feature-map.md`](./feature-map.md) for the area you plan to edit.

If you are preparing a change:

1. Confirm the ownership area in [`feature-map.md`](./feature-map.md).
2. Read the matching execution path in [`runtime-flow.md`](./runtime-flow.md).
3. Use [`testing-and-maintenance.md`](./testing-and-maintenance.md) to choose
   verification and doc updates.
