#!/bin/sh

set -eu

# Resolve the repository root from this script location so the check can run
# from anywhere without relying on the caller's current working directory.
repo_dir=${0%/*}
repo_dir=${repo_dir%/*}
bootstrap=$repo_dir/sc/ssh-bootstrap

# Keep this guard explicit: the retrieval path prepares GNU tar ownership flags
# in _z4h_ssh_tar_opt and the tar invocation must consume that exact variable.
# A previous typo used $tar_opt instead, silently dropping the prepared flags.
awk '
  /_z4h_ssh_tar_opt='\''--owner=0 --group=0'\''/ { saw_assignment = 1 }
  /'\''command'\'' '\''tar'\'' '\''-C'\'' "\$_z4h_ssh_tmp" \$_z4h_ssh_tar_opt '\''-czhf'\''/ { saw_usage = 1 }
  /\$tar_opt/ { saw_legacy = 1 }
  END {
    if (!saw_assignment) {
      print "missing _z4h_ssh_tar_opt assignment" > "/dev/stderr"
      exit 1
    }
    if (!saw_usage) {
      print "missing _z4h_ssh_tar_opt tar usage" > "/dev/stderr"
      exit 1
    }
    if (saw_legacy) {
      print "legacy $tar_opt reference still present" > "/dev/stderr"
      exit 1
    }
  }
' "$bootstrap"

# The regression check should fail fast on broken shell syntax before it is ever
# used as part of manual SSH verification.
sh -n "$bootstrap"
