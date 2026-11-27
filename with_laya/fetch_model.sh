#!/bin/sh
# Downloads Laya's weights for the Laya build into laya/models/laya-multilingual
# at the project root, where the game finds them whatever folder it is started
# from. Uses Laya's own fetch script, from https://github.com/jockofcode/laya.
# Already-downloaded files are skipped, so it is safe to run again.
set -e
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
DEST="$PROJECT_DIR/laya/models/laya-multilingual"
SCRIPT=$(mktemp)
trap 'rm -f "$SCRIPT"' EXIT
curl -fsSL https://raw.githubusercontent.com/jockofcode/laya/main/bin/fetch_model.sh -o "$SCRIPT"
sh "$SCRIPT" "$DEST"
echo "Laya's weights are in $DEST"
