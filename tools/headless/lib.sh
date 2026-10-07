#!/usr/bin/env bash
# Shared by run_tests.sh, run_harness.sh and run_bots.sh: source it, don't run it.
# Sets GODOT, SRC and P, and defines native() and sync_project().
#
#   GODOT  the Godot 4.7.2 editor binary. The default is the Steam build on the Windows PC, then the
#          MacBook's app bundle, then `godot` on the PATH; set GODOT to override.
#   SRC    the repo (default: two folders up from here). Never written to.
#   PROJ   the project copy the run works on (default: a temp folder). Never the repo itself, so the
#          copy's .godot cache can't fight an open editor. Give each parallel run its own PROJ.

HL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SRC:-$(cd "$HL/../.." && pwd)}"
P="${PROJ:-${TMPDIR:-/tmp}/swe-simulator-proj}"

if [ -z "${GODOT:-}" ]; then
  for candidate in \
    "C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" \
    "/Applications/Godot.app/Contents/MacOS/Godot"; do
    if [ -x "$candidate" ]; then
      GODOT="$candidate"
      break
    fi
  done
  GODOT="${GODOT:-godot}"
fi

# Godot is a native exe: on Git Bash it needs C:/... paths, not /tmp/... ones.
native() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s' "$1"
  fi
}

# Copy the game folders into $P and build its import cache and class_name table.
sync_project() {
  mkdir -p "$P"
  local d
  for d in addons autoload core data features tests ui art audio; do
    rm -rf "$P/$d"
    if [ -d "$SRC/$d" ]; then
      cp -r "$SRC/$d" "$P/$d"
    fi
  done
  cp "$SRC/project.godot" "$P/project.godot"
  cp "$HL/run_all.gd" "$P/__run_all.gd"
  cp "$HL/check_all.gd" "$P/__check_all.gd"
  "$GODOT" --headless --path "$(native "$P")" --import > "$P.import.log" 2>&1 || true
}
