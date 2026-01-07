#!/usr/bin/env nix-shell
#!nix-shell -i bash -p tree findutils

set -euo pipefail

DIR="${1:-.}"
shift 2>/dev/null || true  # Remove first arg, ignore error if no args

EXCLUDES=("$@")

# Build tree exclusion pattern (pipe-separated basenames)
TREE_EXCLUDE=""
for pattern in "${EXCLUDES[@]}"; do
    basename=$(basename "$pattern")
    if [[ -n "$TREE_EXCLUDE" ]]; then
        TREE_EXCLUDE="$TREE_EXCLUDE|$basename"
    else
        TREE_EXCLUDE="$basename"
    fi
done

# Build find exclusion arguments
FIND_EXCLUDES=()
for pattern in "${EXCLUDES[@]}"; do
    # Normalize: remove leading ./ and trailing /
    normalized="${pattern#./}"
    normalized="${normalized%/}"
    FIND_EXCLUDES+=(-not -path "./$normalized" -not -path "./$normalized/*")
done

echo "=== DIRECTORY STRUCTURE ==="
echo ""
if [[ -n "$TREE_EXCLUDE" ]]; then
    tree -a --noreport -I "$TREE_EXCLUDE" "$DIR"
else
    tree -a --noreport "$DIR"
fi
echo ""
echo "=== FILE CONTENTS ==="

(
    cd "$DIR"
    find . -type f "${FIND_EXCLUDES[@]}" -print0 | sort -z | while IFS= read -r -d '' file; do
        echo ""
        echo "--- FILE: $file ---"
        echo ""
        cat "$file"
        echo ""
    done
)
