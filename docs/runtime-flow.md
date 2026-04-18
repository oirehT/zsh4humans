---
summary: Startup and lifecycle guide for bootstrap, installation, interactive init, updates, tmux startup, and SSH teleportation.
read_when:
  - You are changing startup behavior or debugging init order.
  - You need to understand how install, update, tmux, or SSH bootstrap flows interact.
---

# Runtime Flow

## 1. User Bootstrap From `~/.zshenv`

The shipped [`.zshenv`](../.zshenv) is intentionally small:

- It keeps customization warnings at the top because user edits outside the
  marked section are not meant to survive template refreshes.
- It defines `Z4H_URL` and `Z4H`.
- It fetches `"$Z4H"/z4h.zsh` with `curl` or `wget` if the bootstrap file is
  missing.
- It sources `"$Z4H"/z4h.zsh`.

This keeps the user bootstrap independent from `git` and from a preinstalled
zsh binary.

## 2. Repository Bootstrap In `z4h.zsh`

[`z4h.zsh`](../z4h.zsh) is the earliest repository-owned runtime.

Its main jobs are:

- Normalize terminal-related environment such as `TERM`, `COLORTERM`,
  `TMPPREFIX`, and `TERMINFO`.
- Refuse incorrect usage, such as sourcing the wrong startup file directly.
- Set recovery-mode defaults when interactive zle is available.
- Validate `Z4H` and `Z4H_URL`.
- Reuse an already-present managed checkout when `main.zsh` is available.
- Fall back to installation or recovery behavior when the managed checkout is
  missing or out of shape.

The bootstrap is designed so it can run in reduced environments before the full
feature set is installed.

## 3. Shell Promotion In `sc/exec-zsh-i`

If the current shell is not a suitable interactive zsh, startup pivots through
[`sc/exec-zsh-i`](../sc/exec-zsh-i).

That script:

- Searches common locations for a usable zsh.
- Verifies version and module availability.
- Downloads and installs `zsh 5.8` when needed.
- `exec`s into the chosen binary so the rest of startup runs in a supported
  interactive shell.

This is why the project can start from plain `sh`, `bash`, or older zsh
installations.

## 4. Interactive Runtime In `main.zsh`

[`main.zsh`](../main.zsh) is the steady-state runtime.

It is responsible for:

- Establishing path, manpath, infopath, `fpath`, and Homebrew discovery.
- Autoloading every function under `fn/`.
- Defining core helper commands such as `z4h source`, `z4h load`,
  `z4h init`, and `z4h install`.
- Defining the public `z4h` dispatcher.
- Triggering SSH follow-up updates when needed.

### `z4h init`

`z4h init` is the key transition from user config into the managed shell
environment. During that call, z4h:

- Checks whether the login shell should be updated with `chsh`.
- Decides whether to install or launch tmux.
- Queues and installs bundled dependencies such as `fzf`, `zoxide`,
  `powerlevel10k`, completion packages, syntax highlighting, autosuggestions,
  and optional tmux support.
- Initializes tty access, screen save/restore support, direnv integration,
  Powerlevel10k instant prompt, ZLE widgets, completion behavior, and runtime
  shell hooks.

After `z4h init`, the rest of the user's `.zshrc` runs with console I/O mostly
unavailable until initialization finishes. That is why the shipped template
places network and interactive operations above `z4h init`.

## 5. The Shipped `.zshrc` Templates

The repository ships two variants:

- [`.zshrc`](../.zshrc) for PC-style key bindings.
- [`.zshrc.mac`](../.zshrc.mac) for macOS-style key bindings.

Both files follow the same structure:

1. Configure `zstyle` knobs for update cadence, keyboard style, shell
   integration, autosuggestions, recursion in `fzf` completion, direnv, and SSH.
2. Optionally `z4h install` extra repositories such as Oh My Zsh.
3. Call `z4h init`.
4. Apply ordinary shell customization: `PATH`, env vars, aliases, functions,
   key bindings, and options.
5. Source [`.zshrc.shared`](../.zshrc.shared).
6. Source `~/.zshrc.local`, which is the updater's stable home for migrated
   user tail customizations.

## 6. Install Flow

[`install`](../install) is a standalone interactive POSIX `sh` wizard for first
time setup.

It:

- Validates platform, TTY availability, `$HOME`, and privilege assumptions.
- Asks the user about keyboard type, key bindings, tmux, and direnv.
- Detects an existing checkout when launched from a git clone so upgrades can
  keep using the real repository.
- Backs up any existing zsh startup files.
- Writes the managed `.zshenv` and the chosen `.zshrc` template.
- Seeds or refreshes the managed upgrade bundle used later by `z4h upgrade`.

The installer is intentionally self-contained so end users can run it from a
downloaded script without preinstalled tooling.

## 7. Update And Upgrade Flow

There are two closely related maintenance paths:

### `update`

[`update`](../update) refreshes the shipped templates and, when possible, the
 owning repository itself.

It supports two repository modes:

- `git`: the updater pulls the latest checkout with `git pull --ff-only`.
- `snapshot`: the updater refreshes a managed bundle containing `update`,
  `.zshenv`, `.zshrc`, and `.zshrc.mac`.

The update script also:

- Refuses to pull over tracked changes in a real git checkout.
- Creates timestamped backups.
- Preserves in-place edits to managed sections.
- Migrates appended user customizations into `~/.zshrc.local`.
- Repairs previously broken `.zshrc.local` hook placement.

### `z4h upgrade`

`z4h upgrade` is the command-facing wrapper around the managed repository or
bundle refresh. The dedicated regression test ensures it resolves the right repo
and forwards `ZDOTDIR` and `Z4H` correctly.

## 8. Managed tmux Startup

When tmux integration is enabled, `z4h init` can launch a managed tmux session
using [`.tmux.conf`](../.tmux.conf).

The flow decides between:

- `integrated` or `isolated` managed tmux sessions,
- a system tmux command,
- or no tmux at all.

The managed config keeps tmux minimal and mostly invisible so z4h can control
terminal title handling, clipboard support, and prompt-at-bottom behavior
without a larger user-managed tmux profile.

## 9. SSH Teleportation

SSH support spans runtime helpers and a standalone bootstrap payload:

- `fn/-z4h-cmd-ssh` and related helpers decide when teleportation is enabled and
  how local and remote environment details should be mapped.
- [`sc/ssh-bootstrap`](../sc/ssh-bootstrap) is the remote bootstrap script. It
  stages files, unpacks a tar payload, runs remote setup, and optionally
  retrieves files back to the client.

The bootstrap contains an explicit bypass mode for minimal remote environments
where required tools or supported platform assumptions are missing.

## 10. Generated And Cached State

The repository itself does not commit runtime caches. During execution, z4h
creates and uses managed state under `"$Z4H"` such as:

- cached downloads and plugin checkouts,
- sticky cache markers,
- `.zwc` compiled files,
- terminfo and tmux installs,
- Powerlevel10k cache data.

Contributor changes should treat these as runtime artifacts rather than source.
