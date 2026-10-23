#!/bin/sh
# Export all print sets from openclaw.scad into stl/<set>/.
set -e
cd "$(dirname "$0")"

export_part() {  # <dir> <part> <file> [extra openscad args...]
    dir=$1; part=$2; file=$3; shift 3
    mkdir -p "stl/$dir"
    echo "stl/$dir/$file.stl"
    openscad -q -D "part=\"$part\"" "$@" -o "stl/$dir/$file.stl" openclaw.scad
}

rm -rf stl

# 1) Multicolor, one piece: needs supports under the body. Parts touch (no glue gap).
export_part multicolor-one-piece body   openclaw_body   -D glue_gap=0
export_part multicolor-one-piece eyes   openclaw_eyes   -D glue_gap=0
export_part multicolor-one-piece pupils openclaw_pupils -D glue_gap=0

# 2) Multicolor, split in halves: no supports. Eyes/pupils placed to match the front half.
export_part multicolor-split front        openclaw_front        -D glue_gap=0
export_part multicolor-split front_eyes   openclaw_front_eyes   -D glue_gap=0
export_part multicolor-split front_pupils openclaw_front_pupils -D glue_gap=0
export_part multicolor-split back         openclaw_back

# 3) Single color, split in halves: eyes and pupils printed separately and glued in.
export_part single-color-split front        openclaw_front
export_part single-color-split back         openclaw_back
export_part single-color-split eyes_glued   openclaw_eyes
export_part single-color-split pupils_glued openclaw_pupils
