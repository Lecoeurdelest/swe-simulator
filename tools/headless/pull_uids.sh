#!/usr/bin/env bash
# Copy the .uid files Godot generated in the project copy back into the repo, for scripts that have none yet
# (the editor would create them on its next scan; committing them keeps resource ids stable across machines).
# Run a test or parse pass first so the copy is current. Never overwrites a .uid the repo already has.
set -e
. "$(dirname "$0")/lib.sh"
n=0
for d in autoload core data features tests ui; do
  [ -d "$P/$d" ] || continue
  while IFS= read -r f; do
    rel="${f#"$P"/}"
    if [ ! -e "$SRC/$rel" ] && [ -e "$SRC/${rel%.uid}" ]; then
      cp "$f" "$SRC/$rel"
      echo "added $rel"
      n=$((n + 1))
    fi
  done < <(find "$P/$d" -name '*.gd.uid')
done
echo "pulled $n uid file(s)"
