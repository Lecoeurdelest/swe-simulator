#!/usr/bin/env bash
# Prepare a project copy once, so many harness runs can reuse it (tools/headless/sweep.py): PROJ=<dir> bash sync_project.sh
set -e
. "$(dirname "$0")/lib.sh"
sync_project
echo "$P ready"
