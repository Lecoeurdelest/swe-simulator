#!/usr/bin/env bash
# The balancing harness (DECISIONS A56, A71): bots play whole careers through Sim.step, headless. From the repo root:
#   bash tools/headless/run_harness.sh bot=planner seeds=10000
# Arguments are key=value: bot (planner|coaster|grinder|lifestyle|random|all), seeds, first, run, bg, handbook, out.
# The harness script documents them. One RESULT line per bot, then the JSON report on a REPORT line.
set -e
. "$(dirname "$0")/lib.sh"
sync_project
"$GODOT" --headless --path "$(native "$P")" --script res://tests/harness/run_harness.gd -- "$@" 2>&1 | grep -v "^Godot Engine\|^$\|godot_ai\|^Content:"
