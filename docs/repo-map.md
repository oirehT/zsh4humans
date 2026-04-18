---
summary: Full repository map covering top-level files, support directories, and the major function families under fn/.
read_when:
  - You need to know where a behavior lives before editing.
  - You want a contributor-friendly inventory of the whole repository.
---

# Repository Map

## Top Level

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Repo-specific instructions for agent workflows, docs, verification, dependency policy, and safety constraints. |
| `README.md` | Primary user-facing guide for installation, usage, customization, and updates. |
| `tips.md` | Advanced user documentation with configuration examples and troubleshooting notes. |
| `changelog.md` | Project change log. When merging contributor work, this is the place that may need the thank-you note required by repo policy. |
| `LICENSE` | Project license. |
| `version` | Small version marker used by the project and release flow. |
| `install` | Interactive POSIX `sh` installer downloaded and executed by end users. |
| `update` | POSIX `sh` updater used by `z4h update` and managed snapshot refreshes. |
| `z4h.zsh` | Bootstrap entrypoint sourced from `~/.zshenv`; validates the environment and either runs or installs the managed checkout. |
| `main.zsh` | Main interactive runtime; defines the `z4h` command, initializes dependencies, starts tmux when configured, and loads all shell features. |
| `.zshenv` | Shipped template for users' login bootstrap. It sets `Z4H`, fetches `z4h.zsh` when missing, and sources it. |
| `.zshrc` | Shipped PC-oriented interactive config template. |
| `.zshrc.mac` | Shipped macOS-oriented interactive config template with Mac-specific key bindings. |
| `.zshrc.shared` | Shared additions sourced by both `.zshrc` variants, including history settings and zoxide integration. |
| `.tmux.conf` | Minimal tmux config used when z4h launches its managed tmux session. |
| `.gitignore`, `.gitattributes` | Git metadata and ignored runtime artifacts such as `.zwc` files. |

## Directories

| Path | Purpose |
| --- | --- |
| `docs/` | Contributor-facing documentation for architecture, repo layout, feature ownership, and verification. |
| `fn/` | Autoloaded zsh functions, widgets, command helpers, completion glue, and post-install hooks. This is where most feature work lands. |
| `sc/` | POSIX `sh` helper scripts used during bootstrap, remote SSH setup, tmux installation, and fallback zsh startup. |
| `zb/` | Small bootstrap shims used by early startup. |
| `tests/` | Focused regression scripts for update, upgrade, and SSH bootstrap behavior. |
| `.vscode/` | Editor-local project settings. |

## Root Templates And Entry Points

The runtime starts in this order:

1. `~/.zshenv` based on the shipped [`.zshenv`](../.zshenv).
2. [`z4h.zsh`](../z4h.zsh) for bootstrap, validation, and recovery-mode setup.
3. [`main.zsh`](../main.zsh) for the interactive shell runtime.
4. `~/.zshrc` based on either [`.zshrc`](../.zshrc) or
   [`.zshrc.mac`](../.zshrc.mac), which calls `z4h init`.
5. [`.zshrc.shared`](../.zshrc.shared) and optional `~/.zshrc.local`.

Use [`runtime-flow.md`](./runtime-flow.md) for the detailed lifecycle.

## `fn/` Function Families

The `fn/` directory is intentionally broad, but the files group into a handful
of stable responsibilities.

| Area | Representative files | What lives there |
| --- | --- | --- |
| Core init and orchestration | `-z4h-init`, `-z4h-init-zle`, `-z4h-main-complete`, `-z4h-compinit`, `-z4h-check-rc-zwcs` | Startup sequencing, ZLE initialization, completion setup, and validation of generated artifacts. |
| `z4h` command implementations | `-z4h-cmd-bindkey`, `-z4h-cmd-help`, `-z4h-cmd-ssh`, `-z4h-cmd-sudo`, `-z4h-cmd-docker`, `-z4h-cmd-update`, `-z4h-cmd-upgrade`, `-z4h-cmd-compile` | Subcommands dispatched by the top-level `z4h` function in `main.zsh`. |
| Installation and post-install hooks | `-z4h-install-one`, `-z4h-install-many`, `-z4h-postinstall-*` | Cloning, refreshing, and post-processing bundled tools and plugin dependencies. |
| Completion and fuzzy selection | `-z4h-fzf`, `-z4h-present-files`, `-z4h-comp-files`, `-z4h-comp-words`, `-z4h-comp-insert-all`, `-z4h-complete-*`, `z4h-fzf-*` | `fzf` integration, command/file completion helpers, and command-specific completion glue. |
| History, navigation, and editing widgets | `-z4h-update-dir-history`, `-z4h-read-dir-history`, `-z4h-write-dir-history`, `z4h-cd-down`, `z4h-backward-word`, `z4h-forward-zword`, `z4h-accept-line`, `z4h-stash-buffer` | Custom widgets for movement, history search, directory traversal, and editing behavior. |
| Terminal integration and display | `-z4h-set-term-title`, `-z4h-vte-osc7`, `-z4h-osc9`, `-z4h-enable-iterm2-integration`, `-z4h-reset-kitty-keyboard`, `-z4h-save-screen`, `-z4h-restore-screen` | Title updates, shell integration metadata, terminal-specific escape sequences, and screen preservation. |
| SSH and remote execution | `-z4h-ssh-maybe-update`, `-z4h-help-ssh`, `-z4h-start-ssh-agent`, `-z4h-tmux-bypass` | Runtime support around SSH teleportation and remote shell behavior. |
| Utilities | `-z4h-string-diff`, `-z4h-run-process-tree`, `-z4h-fix-locale`, `-z4h-find`, `-z4h-replace-buf`, `_z4h_err` | Shared helpers used across multiple features. |

## Special Files Under `fn/`

| Path | Purpose |
| --- | --- |
| `fn/notes.md` | Historical notes, design ideas, backlog items, and experiments. Useful for context, but not authoritative documentation. |
| `fn/bracketed-paste-magic` | Vendored bracketed paste helper integrated into the interactive shell. |
| `fn/ssh-teleportation.asciinema` | Recording asset for the SSH feature shown in user-facing docs. |

## `sc/` Scripts

| Path | Purpose |
| --- | --- |
| `sc/exec-zsh-i` | Finds or installs a suitable interactive zsh and `exec`s into it. Used when bootstrap starts in an unsuitable shell or zsh version. |
| `sc/install-tmux` | Installs a bundled tmux binary from released archives with checksum support and interactive destination selection. |
| `sc/ssh-bootstrap` | Self-contained remote bootstrap payload for z4h SSH teleportation, including send/receive staging and bypass behavior. |
| `sc/setup` | Prepares the managed cache/install directory layout and preserves sticky cache state across refreshes. |

## `tests/`

| Path | Purpose |
| --- | --- |
| `tests/update-regression.sh` | Covers update template merging, `.zshrc.local` migration, snapshot refreshes, backup directory handling, and current-working-directory preservation. |
| `tests/upgrade-command-regression.sh` | Verifies that `-z4h-cmd-upgrade` resolves the managed repository and forwards `ZDOTDIR` and `Z4H` correctly. |
| `tests/ssh-bootstrap-regression.sh` | Guards the SSH bootstrap tar option fix and checks POSIX shell syntax for `sc/ssh-bootstrap`. |

## Where To Start For Common Changes

- Bootstrap bugs: start in [`z4h.zsh`](../z4h.zsh),
  [`main.zsh`](../main.zsh), and [`sc/exec-zsh-i`](../sc/exec-zsh-i).
- Installer or updater issues: inspect [`install`](../install),
  [`update`](../update), and the matching regression scripts in `tests/`.
- Widget, completion, or shell UX work: start in `fn/`, especially
  `-z4h-init-zle`, `-z4h-fzf`, `-z4h-comp*`, and `z4h-*` widgets.
- SSH behavior: read [`runtime-flow.md`](./runtime-flow.md) and then
  [`sc/ssh-bootstrap`](../sc/ssh-bootstrap) plus `fn/-z4h-cmd-ssh`.
