#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "${0%/*}/.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/z4h-update-test.XXXXXXXXXX")

cleanup() {
  rm -rf -- "$tmp_dir"
}

trap cleanup EXIT INT TERM

test_repo=$tmp_dir/repo
base_dir=$tmp_dir/base
home_dir=$tmp_dir/home

mkdir -p -- "$test_repo" "$base_dir" "$home_dir"
cp -R -- "$repo_dir"/. "$test_repo"/

# Build an "old" template set that predates the new local customization hook.
cp -p -- "$repo_dir/.zshenv" "$base_dir/.zshenv"
cp -p -- "$repo_dir/.zshrc" "$base_dir/.zshrc"
awk '
  /Load personal customizations that should survive template refreshes\./ { skip = 1; next }
  skip && /z4h source ~\/\.zshrc\.local/ { skip = 0; next }
  { print }
' "$base_dir/.zshrc" >"$base_dir/.zshrc.tmp"
mv -- "$base_dir/.zshrc.tmp" "$base_dir/.zshrc"

cp -p -- "$base_dir/.zshenv" "$home_dir/.zshenv"
cp -p -- "$base_dir/.zshrc" "$home_dir/.zshrc"

# Simulate user edits in both managed files: one in-place edit and one appended
# customization block. The updater should carry both onto the fresh template.
awk '
  /export GOPATH=\$HOME\/go/ { print; next }
  /Do not change anything else in this file\./ {
    print
    print "  export GOPATH=$HOME/go"
    next
  }
  { print }
' "$home_dir/.zshenv" >"$home_dir/.zshenv.tmp"
mv -- "$home_dir/.zshenv.tmp" "$home_dir/.zshenv"

sed -i.bak -E "/direnv.*enable/ s/'no'/'yes'/" "$home_dir/.zshrc"
rm -f -- "$home_dir/.zshrc.bak"
printf '\n# user customization\nalias ll='\''ls -lah'\''\n' >>"$home_dir/.zshrc"

HOME=$home_dir Z4H_UPDATE_SKIP_GIT=1 Z4H_UPDATE_SKIP_Z4H=1 Z4H_UPDATE_BASE_DIR=$base_dir \
  "$test_repo/update"

grep -q "export GOPATH=\$HOME/go" "$home_dir/.zshenv"
grep -q "zstyle ':z4h:direnv'         enable 'yes'" "$home_dir/.zshrc"
grep -q "z4h source ~/.zshrc.local" "$home_dir/.zshrc"
grep -q "alias ll='ls -lah'" "$home_dir/.zshrc.local"

# A second run must keep the hook in ~/.zshrc instead of re-migrating it into
# ~/.zshrc.local on every update.
printf '\n# second user customization\nalias gs='\''git status -sb'\''\n' >>"$home_dir/.zshrc"

HOME=$home_dir Z4H_UPDATE_SKIP_GIT=1 Z4H_UPDATE_SKIP_Z4H=1 Z4H_UPDATE_BASE_DIR=$base_dir \
  "$test_repo/update"

grep -q "z4h source ~/.zshrc.local" "$home_dir/.zshrc"
! grep -q "z4h source ~/.zshrc.local" "$home_dir/.zshrc.local"
grep -q "alias gs='git status -sb'" "$home_dir/.zshrc.local"

# Simulate a previously broken run that moved the hook block into ~/.zshrc.local
# and removed it from ~/.zshrc. The updater must repair that shape.
awk '
  /Load personal customizations that should survive template refreshes\./ { skip = 1; next }
  skip && /z4h source ~\/\.zshrc\.local/ { skip = 0; next }
  { print }
' "$home_dir/.zshrc" >"$home_dir/.zshrc.tmp"
mv -- "$home_dir/.zshrc.tmp" "$home_dir/.zshrc"
printf '\n# Load personal customizations that should survive template refreshes.\nz4h source ~/.zshrc.local\n' \
  >>"$home_dir/.zshrc.local"

HOME=$home_dir Z4H_UPDATE_SKIP_GIT=1 Z4H_UPDATE_SKIP_Z4H=1 Z4H_UPDATE_BASE_DIR=$base_dir \
  "$test_repo/update"

grep -q "z4h source ~/.zshrc.local" "$home_dir/.zshrc"
! grep -q "z4h source ~/.zshrc.local" "$home_dir/.zshrc.local"
