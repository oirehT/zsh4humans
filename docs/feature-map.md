---
summary: Map of user-visible features and z4h commands to the files that implement them, with notes on configuration surfaces.
read_when:
  - You know the feature you want to change but not the code path.
  - You need to connect README-level behavior to concrete implementation files.
---

# Feature Map

## Public Command Surface

The public entrypoint is the `z4h` function defined in [`main.zsh`](../main.zsh).
It dispatches to `fn/-z4h-cmd-*` helpers plus a few built-ins defined directly in
`main.zsh`.

| Command | Primary implementation |
| --- | --- |
| `z4h init` | `main.zsh` via `-z4h-cmd-init` |
| `z4h install` | `main.zsh` via `-z4h-cmd-install` plus `fn/-z4h-install-one` and `fn/-z4h-install-many` |
| `z4h source` | `main.zsh` via `-z4h-cmd-source` |
| `z4h load` | `main.zsh` via `-z4h-cmd-load` |
| `z4h bindkey` | `fn/-z4h-cmd-bindkey` and `fn/-z4h-help-bindkey` |
| `z4h help` | `fn/-z4h-cmd-help` plus feature-specific help helpers |
| `z4h ssh` | `fn/-z4h-cmd-ssh`, `fn/-z4h-help-ssh`, and `sc/ssh-bootstrap` |
| `z4h sudo` | `fn/-z4h-cmd-sudo` |
| `z4h docker` | `fn/-z4h-cmd-docker` |
| `z4h update` | `fn/-z4h-cmd-update` and [`update`](../update) |
| `z4h upgrade` | `fn/-z4h-cmd-upgrade` and the managed repo/bundle pointed to by `~/.z4h-repo` |
| `z4h compile` | `fn/-z4h-cmd-compile`, `fn/-z4h-compile`, and `fn/-z4h-help-compile` |

## Startup And Bootstrap

| Feature | Primary files |
| --- | --- |
| Bootstrapping from `~/.zshenv` | [`.zshenv`](../.zshenv), [`z4h.zsh`](../z4h.zsh) |
| Finding or installing a suitable zsh | [`sc/exec-zsh-i`](../sc/exec-zsh-i) |
| Main interactive runtime | [`main.zsh`](../main.zsh), `fn/-z4h-init`, `fn/-z4h-init-zle` |
| Managed template selection | [`install`](../install), [`.zshrc`](../.zshrc), [`.zshrc.mac`](../.zshrc.mac), [`update`](../update) |

## Completion, `fzf`, And Widgets

| Feature | Primary files |
| --- | --- |
| Core completion bootstrapping | `fn/-z4h-compinit`, `fn/-z4h-main-complete` |
| Ambiguous completion through `fzf` | `fn/-z4h-fzf`, `fn/z4h-fzf-complete`, `fn/-z4h-present-files` |
| File/word completion helpers | `fn/-z4h-comp-files`, `fn/-z4h-comp-words`, `fn/-z4h-comp-insert-all`, `fn/-z4h-insert-all` |
| Command-specific completions | `fn/-z4h-complete-gh`, `fn/-z4h-complete-kubectl`, `fn/-z4h-complete-helm`, `fn/-z4h-complete-oc`, `fn/-z4h-complete-cargo`, `fn/-z4h-complete-rustup`, `fn/-z4h-complete-kitty`, `fn/-z4h-complete-bw` |
| History search and directory pickers | `fn/z4h-fzf-history`, `fn/z4h-fzf-dir-history`, `fn/-z4h-update-dir-history`, `fn/-z4h-read-dir-history`, `fn/-z4h-write-dir-history` |
| Editing and motion widgets | `fn/-z4h-init-zle`, `fn/z4h-backward-word`, `fn/z4h-forward-zword`, `fn/z4h-accept-line`, `fn/z4h-stash-buffer`, `fn/z4h-cd-down` |

## Prompt, Terminal, And Shell Integration

| Feature | Primary files |
| --- | --- |
| Powerlevel10k setup and instant prompt | [`main.zsh`](../main.zsh), `fn/-z4h-postinstall-powerlevel10k` |
| Prompt redraw and buffer redraw helpers | `fn/-z4h-redraw-prompt`, `fn/-z4h-redraw-buffer`, `fn/-z4h-prompt-length` |
| Terminal title updates | `fn/-z4h-set-term-title`, `fn/-z4h-init-zle` |
| Shell integration escape sequences | `fn/-z4h-osc9`, `fn/-z4h-vte-osc7`, `fn/-z4h-enable-iterm2-integration`, `fn/-z4h-error-iterm2-integration` |
| Kitty and terminal-specific recovery helpers | `fn/-z4h-reset-kitty-keyboard`, `fn/-z4h-save-screen`, `fn/-z4h-restore-screen` |

## History, Autosuggestions, And Syntax Highlighting

| Feature | Primary files |
| --- | --- |
| Shared history defaults | [`.zshrc.shared`](../.zshrc.shared), [`z4h.zsh`](../z4h.zsh) |
| Autosuggestion fetch and accept behavior | `fn/-z4h-autosuggest-fetch`, `fn/z4h-autosuggest-accept`, `fn/-z4h-postinstall-zsh-autosuggestions` |
| History substring search dependency | `fn/-z4h-postinstall-zsh-history-substring-search` |
| Syntax highlighting dependency | `fn/-z4h-postinstall-zsh-syntax-highlighting` |

## SSH, tmux, And Remote Execution

| Feature | Primary files |
| --- | --- |
| SSH teleportation command path | `fn/-z4h-cmd-ssh`, `fn/-z4h-help-ssh`, [`sc/ssh-bootstrap`](../sc/ssh-bootstrap) |
| SSH follow-up checks | `fn/-z4h-ssh-maybe-update`, `fn/-z4h-start-ssh-agent` |
| Managed tmux bootstrap | [`main.zsh`](../main.zsh), [`sc/install-tmux`](../sc/install-tmux), [`.tmux.conf`](../.tmux.conf), `fn/-z4h-tmux-bypass` |
| `sudo` and `docker` terminal normalization | `fn/-z4h-cmd-sudo`, `fn/-z4h-cmd-docker` |

## Dependency Installation And Refresh

| Area | Primary files |
| --- | --- |
| Queueing installs | [`main.zsh`](../main.zsh), `fn/-z4h-install-many`, `fn/-z4h-install-one` |
| Plugin-specific post-install actions | `fn/-z4h-postinstall-*` |
| Self-update of managed checkout | `fn/-z4h-postinstall-self`, [`update`](../update) |
| Terminfo and locale handling | `fn/-z4h-postinstall-terminfo`, `fn/-z4h-fix-locale` |

## Configuration Surfaces

There are three main configuration surfaces to keep in mind while editing:

| Surface | Notes |
| --- | --- |
| `zstyle ':z4h:...' ...` | Most user-visible knobs are expressed as `zstyle` settings. The shipped `.zshrc` files show the intended examples. |
| Public shell variables | Public config follows `Z4H_*` naming. These are more stable than private helpers and may be user-visible. |
| Private runtime helpers | Internal functions are prefixed with `-z4h-` and private state uses `_z4h_*`. Treat these as implementation details unless you are doing internal refactoring. |

## Existing User Docs To Update When Behavior Changes

If a behavior change affects users, the likely top-level docs to update are:

- [`README.md`](../README.md) for installation, usage, customization, and
  update flow.
- [`tips.md`](../tips.md) for advanced options, SSH, tmux, prompt, completion,
  and dotfile examples.
- [`changelog.md`](../changelog.md) for shipped change notes.

The `docs/` tree is primarily for maintainers, so user-facing changes usually
need an update both here and in the appropriate top-level doc.
