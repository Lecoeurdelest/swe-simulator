#!/usr/bin/env bash
# Every bot at once, one process and one project copy each (DECISIONS A56). From the repo root:
#   bash tools/headless/run_bots.sh seeds=10000 out=.project/evidence/STEP-14/2026-10-08-r1
# Takes the harness's key=value arguments except bot=. Prints each bot's RESULT line when all have finished.
set -e
. "$(dirname "$0")/lib.sh"
BASE="$P"
for bot in planner coaster grinder lifestyle random; do
  ( PROJ="$BASE-$bot" bash "$HL/run_harness.sh" bot=$bot "$@" > "$BASE-$bot.out" 2>&1 ) &
done
wait
for bot in planner coaster grinder lifestyle random; do
  grep -a "^RESULT\|UNKNOWN\|ERROR" "$BASE-$bot.out" || { echo "no result for $bot:"; tail -5 "$BASE-$bot.out"; }
done
