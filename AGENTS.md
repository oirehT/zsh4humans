# Repository Guidelines

## Project Structure & Module Organization
- `z4h.zsh`: bootstrap sourced from `~/.zshenv`; validates env and installs/loads.
- `main.zsh`: interactive init; sets paths, loads plugins, widgets.
- `fn/`: zsh functions. Internal names start with `-z4h-`; user-facing helpers/widgets start with `z4h-`. Private vars use `_z4h_*`, public config uses `Z4H_*`.
- `sc/`: POSIX sh utilities (e.g., `setup`, `install-tmux`, `ssh-bootstrap`).
- `zb/`: small shims used during bootstrap.
- Root: `install`, `.zshenv`, `.zshrc`, `.tmux.conf`, `README.md`, `tips.md`, `changelog.md`.

## Build, Test, and Development Commands
- Run locally from checkout:
  `Z4H=$PWD Z4H_URL="https://raw.githubusercontent.com/romkatv/zsh4humans/v5" zsh -ic '. ./z4h.zsh'`
- Syntax check zsh: `zsh -n main.zsh fn/<file>`
- Lint POSIX sh (optional): `shellcheck sc/install-tmux`
- No build step; `.zwc` files are generated at runtime and ignored by git.

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

