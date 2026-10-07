#!/usr/bin/env bash
# Headless test runner (DECISIONS A71). From the repo root:
#   bash tools/headless/run_tests.sh          every suite in tests/test_*.gd
#   bash tools/headless/run_tests.sh odds     one suite (its suite_name())
#   bash tools/headless/run_tests.sh parse    load every .gd and .tscn: parse errors print as SCRIPT ERROR
# The last line of a test run is "RESULT passed=N failed=N total=N suites=N"; failures are listed above it.
set -e
. "$(dirname "$0")/lib.sh"
sync_project

if [ "$1" = "parse" ]; then
  "$GODOT" --headless --path "$(native "$P")" --script res://__check_all.gd 2>&1 | grep -v "^Godot Engine\|^$" | tail -80
  exit 0
fi

ARG=""
if [ -n "$1" ]; then
  ARG="suite=$1"
fi
"$GODOT" --headless --path "$(native "$P")" --script res://__run_all.gd -- $ARG 2>&1 | grep -v "^Godot Engine\|^$" | tail -80
