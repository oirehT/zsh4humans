# Repository Guidelines

## Project Structure & Module Organization
- `z4h.zsh`: bootstrap sourced from `~/.zshenv`; validates env and installs/loads.
- `main.zsh`: interactive init; sets paths, loads plugins, widgets.
- `fn/`: zsh functions. Internal names start with `-z4h-`; user-facing helpers/widgets start with `z4h-`. Private vars use `_z4h_*`, public config uses `Z4H_*`.
- `sc/`: POSIX sh utilities (e.g., `setup`, `install-conda`, `install-tmux`, `ssh-bootstrap`).
- `patches/`: patches applied to downloaded dependencies by their postinstall hooks.
- `zb/`: small shims used during bootstrap.
- Root: `install`, `.zshenv`, `.zshrc`, `.tmux.conf`, `README.md`, `tips.md`, `changelog.md`.

## Build, Test, and Development Commands
- Run locally from checkout:
  `Z4H=$PWD Z4H_URL="https://raw.githubusercontent.com/oirehT/zsh4humans/v5" zsh -ic '. ./z4h.zsh'`
- Syntax check zsh: `zsh -n main.zsh fn/<file>`
- Lint POSIX sh (optional): `shellcheck sc/install-conda sc/install-tmux`
- No build step; `.zwc` files are generated at runtime and ignored by git.

## Dependency Pins
- Bundled plugins and tools are pinned in `fn/-z4h-install-one`: release tags for fzf, zoxide, terminfo and systemd, commit SHAs for zsh-users plugins and powerlevel10k. The `dev` channel follows upstream default branches, except zoxide, whose binary release must match its source tag.
- zoxide's binary release version is read from the pinned `Cargo.toml`; bumping the source tag is enough.
- systemd completions are fetched file by file (`fn/-z4h-fetch-systemd-completions`). Its file list must match `shell-completion/zsh` of the pinned tag, and `fn/-z4h-postinstall-systemd` fails on unknown `{{...}}` placeholders in `_systemctl.in`.
- zsh and tmux come from conda-forge through `sc/install-conda`, which pins micromamba by version and per-platform sha256. The zsh version lives in `sc/exec-zsh-i`, the tmux version in `sc/install-tmux`. Conda bakes the install prefix into files, so zsh is installed straight into its final prefix outside `$Z4H` (users may `chsh` to it). tmux survives being moved because it only needs terminfo from `~/.terminfo`, which z4h installs first.
- zsh-syntax-highlighting is upstream at a pinned commit plus `patches/zsh-syntax-highlighting.patch`, which carries romkatv's performance work and the minimal driver that `fn/-z4h-init-zle` relies on (the stock driver binds its own ZLE hooks on zsh 5.9+). `fn/-z4h-apply-patch` applies it without fuzz on every channel, so a drifted base fails loudly. To bump: check out upstream at the new commit, `git apply --3way` the patch, resolve conflicts, run upstream's test suite with `zmodload zsh/parameter` and `ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern regexp)` set before sourcing `tests/test-highlighting.zsh` (the minimal driver loads highlighters at source time), then regenerate with `git diff --no-renames <base> -- . ':!changelog.md' ':!release.md'` and keep the header.

## Coding Style & Naming Conventions
- Shells: zsh in `fn/`, POSIX sh in `sc/`.
- Indentation: 2 spaces; keep lines under ~120 chars.
- Functions: internal `-z4h-foo`, public `z4h-foo`. Vars: public `Z4H_*`, private `_z4h_*`.
- In zsh, prefer `emulate -L zsh` and explicit `setopt`.

## Testing Guidelines
- Manual verification on macOS/Linux: init, update, completions, fzf pickers, SSH teleportation, tmux.
- Do not commit caches/bytecode (`.zwc`). See `.gitignore`.

## Commit & Pull Request Guidelines
- Commits: imperative, concise; reference issues when relevant (e.g., `#357`).
- PRs: include rationale, repro steps, and before/after; update docs (`README.md`, `tips.md`) as needed.

## Security & Configuration Tips
- Avoid `sudo` in interactive paths; installers handle privilege checks.
- Quote inputs; treat `Z4H*` vars as untrusted.
