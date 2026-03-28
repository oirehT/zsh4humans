#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "${0%/*}/.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/z4h-update-test.XXXXXXXXXX")
real_chmod=$(command -v chmod)

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

# Managed snapshot bundles, as created by the GitHub installer, should refresh
# templates without requiring a git checkout. Simulate that path with a local
# refresh directory so the test stays offline and deterministic.
snapshot_repo=$tmp_dir/snapshot-repo
snapshot_home=$tmp_dir/snapshot-home
snapshot_base=$tmp_dir/snapshot-base
snapshot_refresh=$tmp_dir/snapshot-refresh
snapshot_fake_bin=$tmp_dir/snapshot-bin
snapshot_pwd_home=$tmp_dir/snapshot-pwd-home

mkdir -p -- "$snapshot_repo" "$snapshot_home" "$snapshot_base" "$snapshot_refresh" "$snapshot_fake_bin" \
  "$snapshot_pwd_home"
cp -p -- "$repo_dir/update" "$snapshot_repo/update"
cp -p -- "$base_dir/.zshenv" "$snapshot_repo/.zshenv"
cp -p -- "$base_dir/.zshrc" "$snapshot_repo/.zshrc"
cp -p -- "$repo_dir/.zshrc.mac" "$snapshot_repo/.zshrc.mac"
printf '%s\n' 'snapshot' >"$snapshot_repo/.z4h-managed-repo"

cp -p -- "$base_dir/.zshenv" "$snapshot_base/.zshenv"
cp -p -- "$base_dir/.zshrc" "$snapshot_base/.zshrc"
cp -p -- "$base_dir/.zshenv" "$snapshot_home/.zshenv"
cp -p -- "$base_dir/.zshrc" "$snapshot_home/.zshrc"

printf '\n# snapshot customization\nalias snap='\''printf snapshot\\n'\''\n' >>"$snapshot_home/.zshrc"

cp -p -- "$repo_dir/update" "$snapshot_refresh/update"
printf '\n# snapshot refresh marker\n' >>"$snapshot_refresh/update"
cp -p -- "$repo_dir/.zshenv" "$snapshot_refresh/.zshenv"
cp -p -- "$repo_dir/.zshrc" "$snapshot_refresh/.zshrc"
cp -p -- "$repo_dir/.zshrc.mac" "$snapshot_refresh/.zshrc.mac"

cat >"$snapshot_fake_bin/chmod" <<EOF
#!/bin/sh
if [ "\${2-}" = '--' ]; then
  printf '%s\n' 'chmod received unsupported --' >&2
  exit 1
fi
exec "$real_chmod" "\$@"
EOF
chmod +x "$snapshot_fake_bin/chmod"

HOME=$snapshot_home Z4H_UPDATE_SKIP_Z4H=1 Z4H_UPDATE_BASE_DIR=$snapshot_base \
  Z4H_UPDATE_REFRESH_DIR=$snapshot_refresh PATH="$snapshot_fake_bin:$PATH" "$snapshot_repo/update"

grep -q "z4h source ~/.zshrc.local" "$snapshot_home/.zshrc"
grep -q "alias snap='printf snapshot\\\\n'" "$snapshot_home/.zshrc.local"
grep -q "snapshot refresh marker" "$snapshot_repo/update"

# The full update path replaces the current shell with `z4h update`. That
# shell should stay in the caller's working directory instead of unexpectedly
# landing in the upgrade bundle directory.
cat >"$snapshot_fake_bin/zsh" <<EOF
#!/bin/sh
pwd >"$tmp_dir/snapshot-pwd.out"
exit 0
EOF
chmod +x "$snapshot_fake_bin/zsh"

(
  cd -- "$snapshot_pwd_home"
  HOME=$snapshot_home PATH="$snapshot_fake_bin:$PATH" Z4H_UPDATE_BASE_DIR=$snapshot_base \
    Z4H_UPDATE_REFRESH_DIR=$snapshot_refresh "$snapshot_repo/update" >/dev/null 2>&1
)

[ "$(cat "$tmp_dir/snapshot-pwd.out")" = "$snapshot_pwd_home" ]

# Repeated updates in the same second must not reuse the same backup directory,
# or later runs can overwrite the earlier safety copy.
cat >"$snapshot_fake_bin/date" <<'EOF'
#!/bin/sh
printf '%s\n' '20260326-120000'
EOF
chmod +x "$snapshot_fake_bin/date"

backup_collision_home=$tmp_dir/backup-collision-home
backup_collision_base=$tmp_dir/backup-collision-base
mkdir -p -- "$backup_collision_home" "$backup_collision_base"
cp -p -- "$base_dir/.zshenv" "$backup_collision_home/.zshenv"
cp -p -- "$base_dir/.zshrc" "$backup_collision_home/.zshrc"
cp -p -- "$base_dir/.zshenv" "$backup_collision_base/.zshenv"
cp -p -- "$base_dir/.zshrc" "$backup_collision_base/.zshrc"

HOME=$backup_collision_home PATH="$snapshot_fake_bin:$PATH" Z4H_UPDATE_SKIP_Z4H=1 Z4H_UPDATE_BASE_DIR=$backup_collision_base \
  Z4H_UPDATE_REFRESH_DIR=$snapshot_refresh "$snapshot_repo/update" >/dev/null
HOME=$backup_collision_home PATH="$snapshot_fake_bin:$PATH" Z4H_UPDATE_SKIP_Z4H=1 Z4H_UPDATE_BASE_DIR=$backup_collision_base \
  Z4H_UPDATE_REFRESH_DIR=$snapshot_refresh "$snapshot_repo/update" >/dev/null

[ -d "$backup_collision_home/zsh-backup/update-20260326-120000" ]
[ -d "$backup_collision_home/zsh-backup/update-20260326-120000.1" ]
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
