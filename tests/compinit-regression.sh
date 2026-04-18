#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/z4h-compinit-regression.XXXXXX")
trap 'rm -rf -- "$tmpdir"' EXIT HUP INT TERM

REPO_DIR=$repo_dir TMPDIR_FOR_TEST=$tmpdir zsh -f <<'ZSH'
emulate -L zsh
setopt no_unset pipe_fail extended_glob

zmodload -F zsh/files b:{zf_mkdir,zf_mv,zf_rm}
zmodload -F zsh/stat b:zstat
zmodload zsh/datetime
zmodload zsh/system

typeset -g _z4h_opt='emulate -L zsh && setopt typeset_silent pipe_fail extended_glob no_aliases'
typeset -gi _z4h_dangerous_root=0
typeset -gA _z4h_use=()
typeset -ga _z4h_compdef=()
typeset -g LS_COLORS=

function -z4h-compile() {
  local -a stat
  zstat +mtime -A stat -- "$1" || return 1
  local t
  strftime -s t '%Y%m%d%H%M.%S' $((stat[1] + 1))
  : > "$1".zwc || return 1
  command touch -t "$t" -- "$1".zwc || return 1
}
function complete() { return 0 }
function compdef() { return 0 }
function -z4h-compinit-impl() {
  local -a dumpopt
  zparseopts -D -E d:=dumpopt
  local dump=${dumpopt[2]-}
  [[ -n $dump ]] || return 1
  [[ -e $dump ]] || print -r -- '# fake compdump payload' >$dump
  function compdef() { return 0 }
}

local runtime=$TMPDIR_FOR_TEST/runtime
local completion_dir=$runtime/test-completions

zf_mkdir -p -- $runtime/{cache,tmp} $completion_dir
print -r -- '#compdef foo' >$completion_dir/_foo
print -r -- '#compdef bar' >$completion_dir/_bar

Z4H=$runtime
fpath=($REPO_DIR/fn $completion_dir)
autoload -Uz -- -z4h-compinit

-z4h-compinit

local dump=$runtime/cache/zcompdump-$EUID-$ZSH_VERSION
[[ -r $dump ]] || {
  print -ru2 -- "expected compdump at $dump"
  return 1
}

local -a stat
zstat -A stat +mtime -- $dump
local first_mtime=$stat[1]

sleep 1
command touch -- $completion_dir/_foo
-z4h-compinit
zstat -A stat +mtime -- $dump
local second_mtime=$stat[1]

[[ $second_mtime == $first_mtime ]] || {
  print -ru2 -- "touching an existing completion file unexpectedly regenerated compdump"
  return 1
}

sleep 1
print -r -- '#compdef baz' >$completion_dir/_baz
-z4h-compinit
zstat -A stat +mtime -- $dump
local third_mtime=$stat[1]

(( third_mtime > second_mtime )) || {
  print -ru2 -- "adding a completion file failed to regenerate compdump"
  return 1
}
ZSH
