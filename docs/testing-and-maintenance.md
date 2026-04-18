---
summary: Verification guide for the repository, including automated regression scripts, syntax checks, manual smoke tests, and doc maintenance expectations.
read_when:
  - You are preparing or reviewing a change and need the right verification scope.
  - You are updating docs, templates, or bootstrap code and want to know what else should move with it.
---

# Testing And Maintenance

## Automated Regression Scripts

The repository keeps a small but useful regression suite under [`tests/`](../tests).

| Script | What it protects |
| --- | --- |
| [`tests/compinit-regression.sh`](../tests/compinit-regression.sh) | Completion dump invalidation behavior, including reuse when only completion file mtimes change and refresh when completion files are added. |
| [`tests/update-regression.sh`](../tests/update-regression.sh) | Template merge behavior, `.zshrc.local` migration, snapshot refresh logic, backup naming, and working-directory preservation during update. |
| [`tests/upgrade-command-regression.sh`](../tests/upgrade-command-regression.sh) | The `z4h upgrade` command wrapper and its propagation of `ZDOTDIR` and `Z4H`. |
| [`tests/ssh-bootstrap-regression.sh`](../tests/ssh-bootstrap-regression.sh) | The SSH bootstrap tar-option regression and shell syntax validity for `sc/ssh-bootstrap`. |

Run them from the repository root with plain POSIX `sh`:

```sh
sh tests/compinit-regression.sh
sh tests/update-regression.sh
sh tests/upgrade-command-regression.sh
sh tests/ssh-bootstrap-regression.sh
```

## Fast Static Checks

For changes that touch zsh or POSIX shell files, the repo guidance calls out
these quick checks:

```sh
zsh -n main.zsh fn/<file>
shellcheck sc/install-tmux
```

There is no build step. `.zwc` files are runtime artifacts and should stay out
of commits.

## Manual Verification Areas

When a change affects runtime behavior, prefer end-to-end validation over only
reading code. The repo's own guidance highlights these manual paths:

- Every shipped code path must work on both macOS and Linux. Platform-specific
  behavior is only acceptable when the other platform keeps a supported path.
- Startup on macOS and Linux.
- First-run install flow.
- Update and upgrade flow.
- Completion and `fzf` pickers.
- SSH teleportation.
- tmux startup and prompt behavior.

Useful local startup command from the repo instructions:

```sh
Z4H=$PWD Z4H_URL="https://raw.githubusercontent.com/oirehT/zsh4humans/v5" \
  zsh -ic '. ./z4h.zsh'
```

## When To Expand Verification

Use broader verification when you touch:

- [`z4h.zsh`](../z4h.zsh), [`main.zsh`](../main.zsh), or [`sc/exec-zsh-i`](../sc/exec-zsh-i):
  these affect the earliest startup path.
- [`install`](../install) or [`update`](../update):
  these change user onboarding or template refresh safety.
- [`sc/ssh-bootstrap`](../sc/ssh-bootstrap) or `fn/-z4h-cmd-ssh`:
  these deserve at least the existing regression script plus a manual SSH smoke
  test when practical.
- [`.zshrc`](../.zshrc), [`.zshrc.mac`](../.zshrc.mac), or [`.zshrc.shared`](../.zshrc.shared):
  these are user-owned templates, so update docs and verify merge/update paths.

## Documentation Maintenance

The repo's workflow expectations are straightforward:

- Run `docs-list` before coding when it is available.
- Keep durable contributor guidance in `docs/` with concise `summary` and
  `read_when` frontmatter.
- Follow links until the domain context makes sense before changing code.
- Update the relevant docs when behavior or an API changes.

In practice, that usually means:

- User-facing behavior changes update [`README.md`](../README.md) or
  [`tips.md`](../tips.md).
- Architecture, ownership, or workflow changes update files under `docs/`.
- Shipped changes are reflected in [`changelog.md`](../changelog.md) when
  appropriate.

## Change Safety Reminders

A few repo conventions matter during maintenance:

- Only accept code that works on both macOS and Linux. If a change needs
  platform-specific handling, keep both paths implemented and verified.
- Prefer the existing shell/runtime choices already in the repo.
- Do not delete `.zwc` or cache files from the user's machine unless the task
  explicitly calls for it.
- Avoid destructive git commands and do not push without explicit approval.
- If the worktree contains unrelated edits, leave them alone unless they create
  a real conflict.
