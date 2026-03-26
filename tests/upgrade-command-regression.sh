#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "${0%/*}/.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/z4h-upgrade-test.XXXXXXXXXX")

cleanup() {
  rm -rf -- "$tmp_dir"
}

trap cleanup EXIT INT TERM

test_repo=$tmp_dir/repo
zdotdir=$tmp_dir/zdotdir

mkdir -p -- "$test_repo/.git" "$zdotdir"
printf '%s\n' "$test_repo" >"$zdotdir/.z4h-repo"

cat >"$test_repo/update" <<'EOF'
#!/bin/sh
printf 'upgrade-script:%s:%s\n' "$ZDOTDIR" "$Z4H"
EOF
chmod +x "$test_repo/update"

out=$(
  ZDOTDIR=$zdotdir Z4H=$tmp_dir/cache zsh -fc '
    _z4h_opt=:
    typeset -gi _z4h_dangerous_root=0
    function -z4h-check-core-params() { return 0 }
    function _z4h_err() { return 1 }
    source "'"$repo_dir"'/fn/-z4h-cmd-upgrade"
    -z4h-cmd-upgrade
  '
)

[ "$out" = "upgrade-script:$zdotdir:$tmp_dir/cache" ]
