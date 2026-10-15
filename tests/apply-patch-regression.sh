#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "${0%/*}/.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/z4h-apply-patch-test.XXXXXXXXXX")

cleanup() {
  rm -rf -- "$tmp_dir"
}

trap cleanup EXIT INT TERM

src=$tmp_dir/src
mkdir -p -- "$src/sub"
cd -- "$src"
git init -q
printf '%s\n' one two three '' four five six seven eight nine ten eleven twelve >edit
printf '%s\n' a b c '' '' >sub/blank-tail
git add -A
git -c user.name=t -c user.email=t@t commit -qm base
cp -R -- "$src" "$tmp_dir/base"

printf '%s\n' zero one 2 three '' four five six seven eight nine ten eleven twelve '+ x' >edit
printf '%s\n' a c '' '' '' >sub/blank-tail
printf '%s\n' new '-- dashes' ' leading space' >sub/new-file
git add -A
git diff --cached --no-renames >"$tmp_dir/test.patch"

apply() {
  zsh -fc '
    zmodload -F zsh/files b:zf_mkdir
    _z4h_opt="emulate -L zsh && setopt typeset_silent pipe_fail extended_glob no_aliases"
    autoload -Uz -- "$1/fn/-z4h-apply-patch"
    -z4h-apply-patch "$2" "$3"
  ' zsh "$repo_dir" "$1" "$2"
}

apply "$tmp_dir/base" "$tmp_dir/test.patch"
diff -r -x .git -- "$src" "$tmp_dir/base"

# The tree is already patched, so the same patch must not apply again.
if apply "$tmp_dir/base" "$tmp_dir/test.patch" 2>/dev/null; then
  echo 'patch applied twice' >&2
  exit 1
fi

# The bundled zsh-syntax-highlighting patch must stay parseable by git.
git apply --stat -- "$repo_dir/patches/zsh-syntax-highlighting.patch" >/dev/null

echo 'apply-patch regression: ok'
