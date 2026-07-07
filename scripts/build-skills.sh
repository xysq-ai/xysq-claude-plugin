#!/bin/sh
# Regenerate the plugin's flat skills/ layout from the .skills-src submodule.
# Source layout: .skills-src/<skill>/<platform>/SKILL.md
# Plugin layout: skills/<dirname>/SKILL.md   (claude-code variant)
# core -> skills/xysq/ (preserve the established memory-skill name); others keep their name.
set -e
SRC=.skills-src
DST=skills
copy() {  # $1 = source skill dir, $2 = plugin dir name
  if [ -f "$SRC/$1/claude-code/SKILL.md" ]; then
    mkdir -p "$DST/$2"
    cp "$SRC/$1/claude-code/SKILL.md" "$DST/$2/SKILL.md"
    echo "  $1/claude-code -> $DST/$2/SKILL.md"
  else
    echo "  WARN: no claude-code variant for $1" >&2
  fi
}
echo "Building plugin skills/ from $SRC:"
copy core xysq
for s in recap decisions actionables blockers prep xysq-goal wrap-up auto-mem social-howto; do copy "$s" "$s"; done
echo "Done."
